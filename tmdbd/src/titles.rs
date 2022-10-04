use crate::{get, TitleType};
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
    #[serde(alias = "name")]
    title: String,
    videos: Videos,
    // movies
    #[serde(rename = "vote_average")]
    score: f64,
    #[serde(rename = "vote_count")]
    votes: i32,
    #[serde(default)]
    release_dates: Option<ReleaseDates>,
    // shows
    #[serde(default)]
    content_ratings: Option<ReleaseDates>,
}

#[derive(Deserialize, Debug)]
struct Genre {
    id: i16,
}

#[derive(Deserialize, Debug)]
struct Videos {
    results: Vec<VideoResults>,
}

#[derive(Deserialize, Debug)]
struct VideoResults {
    key: String,
    site: String,
    r#type: String,
}

#[derive(Deserialize, Debug)]
struct ReleaseDates {
    results: Vec<ReleaseDate>,
}

#[derive(Deserialize, Debug)]
struct ReleaseDate {
    iso_3166_1: String,
    // movie
    release_dates: Option<Vec<Rating>>,
    // tv
    rating: Option<String>,
}

#[derive(Deserialize, Debug)]
struct Rating {
    certification: String,
}

pub async fn update(pool: &sqlx::Pool<sqlx::Postgres>, title_type: TitleType) {
    let mut conn = pool.acquire().await.unwrap();

    loop {
        let next = sqlx::query(&format!(
            r#"
                SELECT id FROM titles
                WHERE type = $1
                ORDER BY ts ASC NULLS FIRST, popularity DESC NULLS LAST
                LIMIT 1
            "#
        ))
        .bind(&title_type)
        .fetch_optional(&mut conn)
        .await
        .unwrap();

        if let Some(next) = next {
            fetch(&pool, next.get::<i32, _>(0), title_type.clone()).await;
        }

        sleep(Duration::from_millis(500)).await;
    }
}

async fn fetch(pool: &crate::Pool, id: i32, title_type: TitleType) {
    let mut conn = pool.acquire().await.unwrap();
    let key = env::var("TMDB_KEY").unwrap();
    let url = format!("https://api.themoviedb.org/3/{}/{id}?api_key={key}&append_to_response=videos,release_dates,content_ratings", title_type.to_string());
    let res = get(&url).await.unwrap();
    if res.status() != 200 {
        sqlx::query(
            r#"
                UPDATE titles
                SET ts = now()
                WHERE id = $1
                AND type = $2
            "#,
        )
        .bind(id)
        .bind(title_type)
        .execute(&mut conn)
        .await
        .unwrap();
        return;
    }
    let title = res.json::<Title>().await.unwrap();

    if let Some(poster_path) = &title.poster_path {
        let url = format!(
            "https://www.themoviedb.org/t/p/w300_and_h450_bestv2{}",
            poster_path
        );
        let path = format!(
            "{}/{}/{id}",
            env::var("POSTERS_PATH").unwrap(),
            title_type.to_string()
        );
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

    let trailer = title
        .videos
        .results
        .iter()
        .find(|video| video.site == "YouTube" && video.r#type.contains("Trailer"))
        .and_then(|video| Some(&video.key));

    let runtime = title.runtime.or_else(|| {
        title
            .episode_run_time
            .and_then(|ert| if ert.is_empty() { None } else { Some(ert[0]) })
    });

    let rating = if let Some(release_dates) = title.release_dates {
        release_dates
            .results
            .iter()
            .find(|res| res.iso_3166_1 == "US")
            .and_then(|res| {
                res.release_dates
                    .as_ref()
                    .unwrap()
                    .iter()
                    .find(|res| !res.certification.is_empty())
                    .and_then(|res| Some(res.certification.clone()))
            })
    } else if let Some(ratings) = title.content_ratings {
        ratings
            .results
            .iter()
            .find(|res| res.iso_3166_1 == "US")
            .and_then(|res| res.rating.clone())
    } else {
        None
    };

    sqlx::query(&format!(
        r#"
            UPDATE titles
            SET ts = now(), genres = $1, language = $2, overview = $3, popularity = $4,
                released = {released}, runtime = $6, title = $7, trailer = $8,
                score = $9, votes = $10, rating = $11::rating
            WHERE id = $12
            AND type = $13
        "#,
    ))
    .bind(title.genres.iter().map(|g| g.id).collect::<Vec<i16>>())
    .bind(title.language)
    .bind(title.overview)
    .bind(title.popularity)
    .bind(title.release_date)
    .bind(runtime)
    .bind(&title.title)
    .bind(trailer)
    .bind(title.score * 10.0)
    .bind(title.votes)
    .bind(rating)
    .bind(id)
    .bind(&title_type)
    .execute(&mut *conn)
    .await
    .unwrap();
    info!("Updated {} {}", title_type.to_string(), title.title);
}
