use serde::Deserialize;
use std::{fs::File, io::Write};

#[derive(Deserialize)]
struct Response {
    latitude: f64,
    longitude: f64,
}

fn main() {
    loop {
        let res = match reqwest::blocking::ClientBuilder::new()
            .user_agent("reqwest")
            .build()
            .unwrap()
            .get("https://ipapi.co/json/")
            .send()
        {
            Ok(res) => res,
            Err(err) => {
                eprintln!("{:?}", err);
                continue;
            }
        };
        let res = match res.json::<Response>() {
            Ok(res) => res,
            Err(err) => {
                eprintln!("{:?}", err);
                continue;
            }
        };

        let mut file = File::create("/tmp/geo.json").unwrap();
        file.write_all(format!("[{}, {}]", res.latitude, res.longitude).as_bytes())
            .unwrap();
        break;
    }
}
