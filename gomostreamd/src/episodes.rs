use crate::get;
use serde::{Deserialize, Deserializer};
use std::env;

#[derive(Deserialize)]
struct Episode {
    #[serde(rename = "imdId")]
    id: String,
    slug: String,
    #[serde(rename = "seasonsNo", deserialize_with = "de_string_i16")]
    season: i16,
    #[serde(rename = "episodesNo", deserialize_with = "de_string_i16")]
    episode: i16,
}

pub async fn start(pool: &sqlx::Pool<sqlx::Postgres>) {
    let key = env::var("GOMOSTREAM_KEY").unwrap();

    for i in 1.. {
        let mut trans = pool.begin().await.unwrap();
        let url = format!("https://user.gomo.to/user-api/episodes?key={key}&p={i}");
        let json = get(&url).await.unwrap().text().await.unwrap();
        if json.len() == 0 {
            break;
        }
        let episodes = serde_json::from_str::<Vec<Episode>>(&json).unwrap();

        for episode in episodes {
            debug!(
                "Inserting {} S{:02}E{:02}",
                episode.slug, episode.season, episode.episode
            );
            sqlx::query(
                r#"
                    INSERT INTO series (id, slug)
                    VALUES ($1, $2)
                    ON CONFLICT (id)
                    DO NOTHING
                "#,
            )
            .bind(&episode.id)
            .bind(&episode.slug)
            .execute(&mut trans)
            .await
            .unwrap();
            sqlx::query(
                r#"
                    INSERT INTO episodes (id, season, episode)
                    VALUES ($1, $2, $3)
                    ON CONFLICT (id, season, episode)
                    DO NOTHING
                "#,
            )
            .bind(episode.id)
            .bind(episode.season)
            .bind(episode.episode)
            .execute(&mut trans)
            .await
            .unwrap();
        }

        info!("Comitting transaction");
        trans.commit().await.unwrap();
    }
}

fn de_string_i16<'de, D: Deserializer<'de>>(deserializer: D) -> Result<i16, D::Error> {
    let s = String::deserialize(deserializer)?;
    Ok(s.parse().unwrap())
}
