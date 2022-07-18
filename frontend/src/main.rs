#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use serde::{Deserialize, Serialize};
use std::{env, process::Command};

#[derive(Serialize, Deserialize)]
struct Torrent {
    name: String,
    info_hash: String,
    leechers: String,
    seeders: String,
    size: String,
}

fn main() {
    dotenv::dotenv().unwrap();
    tauri::Builder::default()
        .plugin(tauri_plugin_sql::TauriSql::default())
        .invoke_handler(tauri::generate_handler![get_db_url, get_sources, play])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn get_db_url() -> String {
    env::var("DATABASE_URL").unwrap()
}

#[tauri::command]
async fn get_sources(query: String) -> Vec<Torrent> {
    get(&format!("https://apibay.org/q.php?q={query}&cat=200"))
        .await
        .unwrap()
        .json::<Vec<Torrent>>()
        .await
        .unwrap()
}

#[tauri::command]
fn play(hash: String, name: String) {
    let magnet = format!("magnet:?xt=urn:btih:{hash}&dn={name}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2710%2Fannounce&tr=udp%3A%2F%2F9.rarbg.me%3A2780%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2730%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=http%3A%2F%2Fp4p.arenabg.com%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.tiny-vps.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce");
    Command::new("webtorrent")
        .args([
            "download",
            &magnet,
            "--vlc",
            "--player-args=--no-osd -I dummy",
        ])
        .spawn()
        .unwrap();

    loop {
        let output = Command::new("playerctl").arg("position").output().unwrap();
        let position = match String::from_utf8(output.stdout).unwrap().trim().parse::<f32>() {
            Ok(position) => position,
            Err(_) => continue,
        };
        if position >= 0.1 {
            break;
        }
    }
    Command::new("../overlay/target/release/overlay")
        .output()
        .unwrap();
}

async fn get(url: &str) -> reqwest::Result<reqwest::Response> {
    let mut tries = 0;
    loop {
        tries += 1;
        println!("Getting {url}");
        match reqwest::get(url).await {
            Ok(res) => {
                if res.status() != 200 {
                    eprintln!("{url}: {}", res.status());

                    if res.status().as_u16() >= 500 && tries <= 10 {
                        continue;
                    }
                }
                break Ok(res);
            }
            Err(err) => {
                eprintln!("{url}: {err}");
                if tries >= 10 {
                    break Err(err);
                }
            }
        }
    }
}
