use crate::get;
use futures::stream::StreamExt;
use serde::Deserialize;
use sqlx::Row;
use std::{env, time::Duration};
use tokio::{fs::File, io::AsyncWriteExt, time::sleep};

#[derive(Deserialize, Debug)]
struct Title {
    genres: Vec<Genre>,
    #[serde(rename = "original_language")]
    language: String,
    overview: Option<String>,
    popularity: f64,
    poster_path: Option<String>,
    #[serde(alias = "first_air_date")]
    release_date: Option<String>,
    #[serde(default)]
    runtime: Option<i16>,
    #[serde(default)]
    episode_run_time: Option<Vec<i16>>,
    tagline: Option<String>,
    #[serde(alias = "name")]
    title: String,
    // only appears on movies
    #[serde(default)]
    video: Option<bool>,
    #[serde(rename = "vote_average")]
    score: f64,
    #[serde(rename = "vote_count")]
    votes: i32,

    #[serde(default)]
    seasons: Option<Vec<Season>>,
}

#[derive(Deserialize, Debug)]
struct Genre {
    id: i16,
}

#[derive(Deserialize, Debug)]
struct Season {
    #[serde(rename = "season_number")]
    season: i16,
    #[serde(rename = "episode_count")]
    episodes: i16,
    name: String,
    overview: String,
    poster_path: Option<String>,
}

#[derive(Deserialize, Debug)]
struct Videos {
    results: Vec<VideoResults>,
}

#[derive(Deserialize, Debug)]
struct VideoResults {
    key: String,
    site: String,
}

pub async fn update(pool: &sqlx::Pool<sqlx::Postgres>, table: &str) {
    let mut conn = pool.acquire().await.unwrap();

    loop {
        let next = sqlx::query(&format!(
            r#"
                SELECT id FROM {table}
                ORDER BY ts ASC NULLS FIRST, popularity DESC
                LIMIT 1
            "#
        ))
        .fetch_optional(&mut conn)
        .await
        .unwrap();

        if let Some(next) = next {
            let endpoint = match table {
                "movies" => "movie",
                "series" => "tv",
                _ => panic!(),
            };
            fetch(&pool, next.get::<i32, _>(0), endpoint).await;
        }

        sleep(Duration::from_secs(1)).await;
    }
}

async fn fetch(pool: &crate::Pool, id: i32, endpoint: &str) {
    let mut conn = pool.acquire().await.unwrap();
    let key = env::var("TMDB_KEY").unwrap();
    let url = format!("https://api.themoviedb.org/3/{endpoint}/{id}?api_key={key}");
    let title = get(&url).await.unwrap().json::<Title>().await.unwrap();

    let trailer = if title.video.unwrap_or(true) {
        get_trailer(id, endpoint).await
    } else {
        None
    };

    if let Some(poster_path) = &title.poster_path {
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

    let released = match &title.release_date {
        None => "NULL",
        Some(date) => {
            if date.is_empty() {
                "NULL"
            } else {
                "$5::date"
            }
        }
    };

    if let Some(seasons) = title.seasons {
        for season in seasons {
            sqlx::query(
                r#"
                    INSERT INTO seasons (id, season, episodes, name, overview)
                    VALUES ($1, $2, $3, $4, $5)
                    ON CONFLICT (id, season, episodes)
                    DO NOTHING
                "#,
            )
            .bind(&id)
            .bind(season.season)
            .bind(season.episodes)
            .bind(season.name)
            .bind(season.overview)
            .execute(&mut conn)
            .await
            .unwrap();
        }
    }
    let runtime = title.runtime.or_else(|| {
        title
            .episode_run_time
            .and_then(|ert| if ert.is_empty() { None } else { Some(ert[0]) })
    });
    sqlx::query(&format!(
        r#"
            UPDATE titles
            SET ts = now(), genres = $1, language = $2, overview = $3, popularity = $4,
                released = {released}, runtime = $6, tagline = $7, title = $8, trailer = $9,
                score = $10, votes = $11
            WHERE id = $12
        "#
    ))
    .bind(&title.genres.iter().map(|g| g.id).collect::<Vec<i16>>())
    .bind(&title.language)
    .bind(&title.overview)
    .bind(&title.popularity)
    .bind(&title.release_date)
    .bind(runtime)
    .bind(&title.tagline)
    .bind(&title.title)
    .bind(trailer)
    .bind(title.score * 10.0)
    .bind(&title.votes)
    .bind(id)
    .execute(&mut *conn)
    .await
    .unwrap();
    info!("Updated {endpoint} {}", title.title);
}

async fn get_trailer(id: i32, endpoint: &str) -> Option<String> {
    sleep(Duration::from_secs(1)).await;
    let key = env::var("TMDB_KEY").unwrap();
    let videos = get(&format!(
        "https://api.themoviedb.org/3/{endpoint}/{id}/videos?api_key={key}"
    ))
    .await
    .unwrap()
    .json::<Videos>()
    .await
    .unwrap();

    for video in videos.results {
        if video.site == "YouTube" {
            return Some(video.key);
        }
    }

    None
}
