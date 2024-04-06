use std::{thread::sleep, time::Duration};

use log::error;
use reqwest::blocking::Client;

pub fn keepalive(uuid: &str) {
    let url = format!(
        "{}/keepalive/{uuid}",
        std::env::var("SEEDBOX_HOST").unwrap()
    );
    let mut builder = Client::builder();
    // If https is being used, force HTTP/2 and set TCP keepalive to 10 seconds.
    // This allows debugging on localhost.
    if url.starts_with("https") {
        builder = builder
            .http2_prior_knowledge()
            .tcp_keepalive(Some(Duration::from_secs(10)));
    }
    let client = builder.build().unwrap();

    loop {
        let res = match client.head(&url).send() {
            Err(err) => {
                error!("Failed to send keepalive: {err}");
                sleep(Duration::from_millis(100));
                continue;
            }
            Ok(res) => res,
        };
        if !res.status().is_success() {
            error!("{url} responded with {}", res.status());
        }
        sleep(Duration::from_secs(5));
    }
}
