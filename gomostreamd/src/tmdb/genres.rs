use crate::get;
use serde::Deserialize;
use std::{env, time::Duration};
use tokio::time::sleep;

#[derive(Deserialize, Debug)]
struct Response {
    genres: Vec<Genre>,
}

#[derive(Deserialize, Debug)]
struct Genre {
    id: i16,
    name: String,
}

pub async fn insert(pool: &sqlx::Pool<sqlx::Postgres>) {
    let mut trans = pool.begin().await.unwrap();

    insert_category(&mut trans, "movie").await;
    insert_category(&mut trans, "tv").await;

    info!("Comitting transaction");
    trans.commit().await.unwrap();
}

async fn insert_category(trans: &mut sqlx::Transaction<'_, sqlx::Postgres>, category: &str) {
    let key = env::var("TMDB_KEY").unwrap();
    let url = format!("https://api.themoviedb.org/3/genre/{category}/list?api_key={key}");
    let genres = get(&url)
        .await
        .unwrap()
        .json::<Response>()
        .await
        .unwrap()
        .genres;

    for genre in genres {
        sqlx::query(
            r#"
                INSERT INTO genres (id, name)
                VALUES ($1, $2)
                ON CONFLICT (id)
                DO NOTHING
            "#,
        )
        .bind(genre.id)
        .bind(genre.name)
        .execute(&mut *trans)
        .await
        .unwrap();
    }

    sleep(Duration::from_secs(1)).await;
}
