use crate::{get, TitleType};
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
        insert_category(&pool, TitleType::Movie),
        insert_category(&pool, TitleType::Series),
    );
}

async fn insert_category(pool: &crate::Pool, category: TitleType) {
    let mut trans = pool.begin().await.unwrap();
    let mut time = Utc::now();
    if time.hour() < 8 {
        time = time - Duration::days(1);
    }
    let date = time.format("%m_%d_%Y");
    let endpoint = match category {
        TitleType::Movie => "movie",
        TitleType::Series => "tv_series",
    };
    let url = format!("https://files.tmdb.org/p/exports/{endpoint}_ids_{date}.json.gz");
    let bytes = get(&url).await.unwrap().bytes().await.unwrap();
    let mut decoder = GzDecoder::new(bytes.as_ref());
    let mut s = String::new();
    decoder.read_to_string(&mut s).unwrap();

    for line in s.lines() {
        let title = serde_json::from_str::<Title>(line).unwrap();
        sqlx::query(
            r#"
                INSERT INTO titles (id, movie, title, popularity)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (id, movie)
                DO UPDATE
                SET popularity = $4
            "#,
        )
        .bind(title.id)
        .bind(category == TitleType::Movie)
        .bind(title.original_title)
        .bind(title.popularity)
        .execute(&mut *trans)
        .await
        .unwrap();
    }

    info!("Committing transaction");
    trans.commit().await.unwrap();
}
