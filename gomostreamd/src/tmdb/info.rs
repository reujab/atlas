use crate::get;
use futures::stream::StreamExt;
use serde::Deserialize;
use sqlx::Row;
use std::{env, time::Duration};
use tokio::{fs::File, io::AsyncWriteExt, time::sleep};

#[derive(Deserialize, Debug)]
struct Response {
    movie_results: Vec<Result>,
    tv_results: Vec<Result>,
}

#[derive(Deserialize, Debug)]
struct Result {
    poster_path: Option<String>,
    overview: String,
    #[serde(alias = "first_air_date")]
    release_date: Option<String>,
    #[serde(rename = "vote_average")]
    score: f64,
    #[serde(alias = "name")]
    title: String,
    #[serde(rename = "genre_ids")]
    genres: Vec<i16>,
    #[serde(rename = "original_language")]
    language: String,
    popularity: f64,
}

pub async fn start(pool: &sqlx::Pool<sqlx::Postgres>) {
    let mut conn = pool.acquire().await.unwrap();

    loop {
        let next = sqlx::query(
            r#"
                SELECT id FROM titles
                ORDER BY ts ASC NULLS FIRST
                LIMIT 1
            "#,
        )
        .fetch_optional(&mut conn)
        .await
        .unwrap();

        if let Some(next) = next {
            fetch(&mut conn, next.get::<String, _>(0)).await;
        }

        sleep(Duration::from_secs(1)).await;
    }
}

async fn fetch(conn: &mut sqlx::pool::PoolConnection<sqlx::Postgres>, id: String) {
    let key = env::var("TMDB_KEY").unwrap();
    let url =
        format!("https://api.themoviedb.org/3/find/{id}?api_key={key}&external_source=imdb_id");
    let res = get(&url).await.unwrap().json::<Response>().await.unwrap();
    let result = res.movie_results.get(0).or(res.tv_results.get(0));

    match result {
        Some(result) => {
            if let Some(poster_path) = &result.poster_path {
                let url = format!(
                    "https://www.themoviedb.org/t/p/w300_and_h450_bestv2{}",
                    poster_path
                );
                let path = format!("{}/{}", env::var("POSTERS_PATH").unwrap(), id);
                let mut file = File::create(&path).await.unwrap();
                let mut stream = get(&url).await.unwrap().bytes_stream();
                while let Some(chunk) = stream.next().await {
                    file.write_all(&chunk.unwrap()).await.unwrap();
                }
                info!("Downloaded poster to file://{path}");
            }

            let released = match &result.release_date {
                None => "NULL",
                Some(date) => {
                    if date.is_empty() {
                        "NULL"
                    } else {
                        "$6::date"
                    }
                }
            };

            sqlx::query(&format!(
                r#"
                    UPDATE titles
                    SET ts = now(), title = $1, genres = $2, language = $3, overview = $4,
                        popularity = $5, released = {released}, score = $7
                    WHERE id = $8
                "#
            ))
            .bind(&result.title)
            .bind(&result.genres)
            .bind(&result.language)
            .bind(&result.overview)
            .bind(&result.popularity)
            .bind(&result.release_date)
            .bind(&result.score)
            .bind(id)
            .execute(&mut *conn)
            .await
            .unwrap();
            info!("Updated {}", result.title);
        }
        None => {
            sqlx::query(
                r#"
                    UPDATE titles
                    SET ts = now()
                    WHERE id = $1
                "#,
            )
            .bind(&id)
            .execute(&mut *conn)
            .await
            .unwrap();
            warn!("Unable to fetch data for https://imdb.com/title/{id}");
        }
    }
}
