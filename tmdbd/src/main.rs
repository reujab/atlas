#[macro_use]
extern crate log;

mod genres;
mod ids;
mod titles;

use env_logger::Env;
use sqlx::postgres::PgPoolOptions;
use std::{env, time::Duration};
use tokio::time::sleep;

type Pool = sqlx::Pool<sqlx::Postgres>;

#[derive(sqlx::Type, Clone, PartialEq)]
#[sqlx(rename_all = "lowercase")]
#[sqlx(type_name = "type")]
pub enum TitleType {
    Movie,
    TV,
}

impl ToString for TitleType {
    fn to_string(&self) -> String {
        match self {
            TitleType::Movie => "movie",
            TitleType::TV => "tv",
        }
        .to_owned()
    }
}

#[tokio::main]
async fn main() {
    env_logger::init_from_env(Env::default().default_filter_or("tmdbd=info"));
    dotenv::dotenv().unwrap();

    let db_url = env::var("DATABASE_URL").unwrap();
    info!("Connecting to {db_url}...");
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&db_url)
        .await
        .unwrap();

    tokio::join!(genres::insert(&pool), ids::insert(&pool));
    info!("Done");

    tokio::join!(
        titles::update(&pool, TitleType::Movie),
        titles::update(&pool, TitleType::TV),
    );
}

async fn get(url: &str) -> Result<reqwest::Response, reqwest::Error> {
    let mut i = 0;
    loop {
        info!("Getting {url}");
        match reqwest::get(url).await {
            Ok(res) => {
                if res.status() != 200 {
                    error!("{url} returned {}", res.status());
                }
                if res.status().as_u16() >= 500 {
                    continue;
                }
                break Ok(res);
            }
            Err(err) => {
                if i >= 10 {
                    break Err(err);
                } else {
                    error!("Error getting {url}: {err}");
                    sleep(Duration::from_secs(1)).await;
                }
            }
        }
        i += 1;
    }
}
