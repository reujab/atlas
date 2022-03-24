use crate::get;
use serde::Deserialize;
use std::env;

#[derive(Deserialize)]
struct Movie {
    #[serde(rename = "imdId")]
    id: String,
    slug: String,
    title: String,
    quality: i16,
}

pub async fn start(pool: &sqlx::Pool<sqlx::Postgres>) {
    let key = env::var("GOMOSTREAM_KEY").unwrap();

    for i in 1.. {
        let mut trans = pool.begin().await.unwrap();
        let url = format!("https://user.gomo.to/user-api/movies?key={key}&p={i}");
        let json = get(&url).await.unwrap().text().await.unwrap();
        if json.len() == 0 {
            break;
        }
        let movies = serde_json::from_str::<Vec<Movie>>(&json).unwrap();

        for movie in movies {
            debug!("Inserting {}", movie.title);
            sqlx::query(
                r#"
                    INSERT INTO movies (id, slug, title, quality)
                    VALUES ($1, $2, $3, $4)
                    ON CONFLICT (id)
                    DO NOTHING
                "#,
            )
            .bind(movie.id)
            .bind(movie.slug)
            .bind(movie.title)
            .bind(movie.quality)
            .execute(&mut trans)
            .await
            .unwrap();
        }

        info!("Comitting transaction");
        trans.commit().await.unwrap();
    }
}
