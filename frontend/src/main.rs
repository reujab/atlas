#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use std::{collections::HashMap, env};

// const USER_AGENT: &str = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36";

fn main() {
    dotenv::dotenv().unwrap();
    tauri::Builder::default()
        .plugin(tauri_plugin_sql::TauriSql::default())
        .invoke_handler(tauri::generate_handler![get_db_url])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn get_db_url() -> String {
    env::var("DATABASE_URL").unwrap()
}
