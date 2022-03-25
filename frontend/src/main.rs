#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use regex::Regex;
use std::{collections::HashMap, env};

const USER_AGENT: &str = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36";

fn main() {
    dotenv::dotenv().unwrap();
    tauri::Builder::default()
        .plugin(tauri_plugin_sql::TauriSql::default())
        .invoke_handler(tauri::generate_handler![get_db_url, get_video_url])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn get_db_url() -> String {
    env::var("DATABASE_URL").unwrap()
}

#[tauri::command]
async fn get_video_url(slug: String) -> String {
    let page = get(&format!("https://gomo.to/movie/{slug}"))
        .await
        .unwrap()
        .text()
        .await
        .unwrap();
    let token_regex = Regex::new(r#""_token": "(.*)","#).unwrap();
    let token = token_regex
        .captures(&page)
        .unwrap()
        .get(1)
        .unwrap()
        .as_str();
    let token_code_regex = Regex::new(r#"var tc = '(.*)';"#).unwrap();
    let token_code = token_code_regex
        .captures(&page)
        .unwrap()
        .get(1)
        .unwrap()
        .as_str();
    // let x_token = {
    //     let decode_fn_regex = Regex::new(r#"function _tsd_tsd_ds\(s\) \{.*\}"#).unwrap();
    //     let decode_fn = tsd_regex.captures(&page).unwrap().get(0).unwrap().as_str();
    //     let mut ctx = boa::Context::default();
    //     ctx.eval(decode_fn).unwrap();
    //     ctx.eval(format!("_tsd_tsd_ds("{token_code}")"))
    //         .unwrap()
    //         .as_string()
    //         .unwrap()
    //         .as_str()
    //         .to_owned()
    // };
    let x_token = "0VZJnVh9WbXFX14159515";
    println!("token: {token}\ntoken code: {token_code}\nx-token: {x_token}");

    let client = reqwest::ClientBuilder::new()
        .user_agent(USER_AGENT)
        .build()
        .unwrap();
    let url = "https://gomo.to/decoding_v3.php";
    let mut form = HashMap::new();
    form.insert("tokenCode", token_code.to_owned());
    form.insert("_token", token.to_owned());
    let mut i = 0;
    let res = loop {
        match client
            .post(url)
            .header("x-token", x_token)
            .form(&form)
            .send()
            .await
        {
            Ok(res) => break res,
            Err(err) => {
                if i >= 10 {
                    panic!("{err}");
                } else {
                    println!("Error getting {url}: {err}");
                }
            }
        }
        i += 1;
    };
    let embeds = res
        .json::<Vec<String>>()
        .await
        .unwrap()
        .into_iter()
        .filter(|e| e.starts_with("https://gomo.to/vid/"))
        .collect::<Vec<String>>();
    println!("{:#?}", embeds);

    let page = get(&embeds[0]).await.unwrap().text().await.unwrap();
    let encoded_regex = Regex::new(r"eval(\(.*\))").unwrap();
    let encoded = encoded_regex
        .captures(&page)
        .unwrap()
        .get(1)
        .unwrap()
        .as_str();
    println!("encoded: {encoded}");
    let decoded = {
        println!("getting context");
        let mut ctx = boa::Context::default();
        println!("evaluating naughty bits");
        ctx.eval(encoded)
            .unwrap()
            .as_string()
            .unwrap()
            .as_str()
            .to_owned()
    };
    println!("decoded: {decoded}");
    let src_regex = Regex::new(r"https://n\d{2}\.gomoplayer\.com/.*/v\.mp4").unwrap();
    let src = src_regex
        .captures(&decoded)
        .unwrap()
        .get(0)
        .unwrap()
        .as_str();

    src.to_owned()
}

async fn get(url: &str) -> Result<reqwest::Response, reqwest::Error> {
    let client = reqwest::ClientBuilder::new()
        .user_agent(USER_AGENT)
        .build()
        .unwrap();
    println!("Getting {url}");
    let mut i = 0;
    loop {
        match client.get(url).send().await {
            Ok(res) => break Ok(res),
            Err(err) => {
                if i >= 10 {
                    break Err(err);
                } else {
                    println!("Error getting {url}: {err}");
                }
            }
        }
        i += 1;
    }
}
