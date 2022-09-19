use serde::Deserialize;
use std::{fs::File, io::Write};

#[derive(Deserialize)]
struct Response {
    location: Location,
}

#[derive(Deserialize)]
struct Location {
    lat: f64,
    lng: f64,
}

fn main() {
    loop {
        let res = match reqwest::blocking::ClientBuilder::new()
            .user_agent("reqwest")
            .build()
            .unwrap()
            .get("https://location.services.mozilla.com/v1/geolocate?key=geoclue")
            .send()
        {
            Ok(res) => res,
            Err(err) => {
                eprintln!("{:?}", err);
                continue;
            }
        };
        let location = match res.json::<Response>() {
            Ok(res) => res.location,
            Err(err) => {
                eprintln!("{:?}", err);
                continue;
            }
        };

        let mut file = File::create("/tmp/geo.json").unwrap();
        file.write_all(format!("[{}, {}]", location.lat, location.lng).as_bytes())
            .unwrap();
        break;
    }
}
