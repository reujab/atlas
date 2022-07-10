use crate::get;
use chrono::{Duration, Timelike, Utc};
use flate2::read::GzDecoder;
use serde::Deserialize;
use std::io::prelude::*;

#[derive(Deserialize)]
pub struct Title {
    id: i32,
    #[serde(alias = "original_name")]
    original_title: String,
    popularity: f64,
}

pub async fn insert(pool: &crate::Pool) {
    tokio::join!(
        insert_category(&pool, "movie"),
        insert_category(&pool, "tv_series"),
    );
}

async fn insert_category(pool: &crate::Pool, category: &str) {
    let mut trans = pool.begin().await.unwrap();
    let mut time = Utc::now();
    if time.hour() < 8 {
        time = time - Duration::days(1);
    }
    let date = time.format("%m_%d_%Y");
    let url = format!("https://files.tmdb.org/p/exports/{category}_ids_{date}.json.gz");
    let bytes = get(&url).await.unwrap().bytes().await.unwrap();
    let mut decoder = GzDecoder::new(bytes.as_ref());
    let mut s = String::new();
    decoder.read_to_string(&mut s).unwrap();

    let table = match category {
        "movie" => "movies",
        "tv_series" => "series",
        _ => panic!(),
    };
    for line in s.lines() {
        let title = serde_json::from_str::<Title>(line).unwrap();
        sqlx::query(&format!(
            r#"
                INSERT INTO {table} (id, title, popularity)
                VALUES ($1, $2, $3)
                ON CONFLICT (id)
                DO UPDATE
                SET popularity = $3
            "#
        ))
        .bind(title.id)
        .bind(title.original_title)
        .bind(title.popularity)
        .execute(&mut *trans)
        .await
        .unwrap();
    }

    info!("Committing transaction");
    trans.commit().await.unwrap();
}
