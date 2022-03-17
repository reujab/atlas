#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use rand::seq::IteratorRandom;
use std::fs;

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![get_image])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn get_image() -> String {
    let mut rng = rand::thread_rng();
    let files = fs::read_dir("/mnt").unwrap();
    let file = files.choose(&mut rng).unwrap().unwrap();
    let path = file.path();
    println!("img path: {:#?}", path);
    let bytes = fs::read(path).unwrap();
    let mime = match infer::get(&bytes[..4]) {
        Some(mime) => mime.mime_type(),
        None => "video/mp4",
    };
    let base64 = base64::encode(bytes);
    format!("data:{mime};base64,{base64}")
}
