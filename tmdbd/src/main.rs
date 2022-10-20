#[macro_use]
extern crate log;

mod genres;
mod ids;
mod titles;

use env_logger::Env;
use futures::StreamExt;
use sqlx::postgres::PgPoolOptions;
use sqlx::Row;
use std::{env, path::Path, time::Duration};
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

    check(&pool).await;

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

async fn check(pool: &Pool) {
    println!("Consistency check...");

    let posters = env::var("POSTERS_PATH").unwrap();
    let mut missing = Vec::new();
    let mut conn = pool.acquire().await.unwrap();
    let mut stream = sqlx::query(
        r#"
        SELECT type, id FROM titles
        WHERE ts IS NOT NULL
    "#,
    )
    .fetch_many(&mut conn);

    while let Some(title) = stream.next().await {
        let title = match title.unwrap() {
            sqlx::Either::Right(row) => row,
            _ => continue,
        };

        let title_type = title.get::<TitleType, _>(0);
        let id = title.get::<i32, _>(1);
        let path = format!("{posters}/{}/{id}", title_type.to_string());
        let path = Path::new(&path);
        if !path.exists() {
            println!("{:?} doesn't exist", path);
            missing.push(id);
        }
    }

    drop(stream);

    for id in missing {
        sqlx::query(
            r#"
                UPDATE titles
                SET ts = NULL
                WHERE id = $1
            "#,
        )
        .bind(id)
        .execute(&mut conn)
        .await
        .unwrap();
    }
}
