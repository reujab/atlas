use crate::{get, TitleType};
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

    insert_category(&mut trans, TitleType::Movie).await;
    insert_category(&mut trans, TitleType::Series).await;

    info!("Committing transaction");
    trans.commit().await.unwrap();
}

async fn insert_category(trans: &mut sqlx::Transaction<'_, sqlx::Postgres>, category: TitleType) {
    let key = env::var("TMDB_KEY").unwrap();
    let endpoint = match category {
        TitleType::Movie => "movie",
        TitleType::Series => "tv",
    };
    let url = format!("https://api.themoviedb.org/3/genre/{endpoint}/list?api_key={key}");
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
                INSERT INTO genres (id, name, movie, series)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (id)
                DO UPDATE
                SET movie = GREATEST(genres.movie, $3), series = GREATEST(genres.series, $4)
            "#,
        )
        .bind(genre.id)
        .bind(genre.name)
        .bind(category == TitleType::Movie)
        .bind(category == TitleType::Series)
        .execute(&mut *trans)
        .await
        .unwrap();
    }

    sleep(Duration::from_secs(1)).await;
}
