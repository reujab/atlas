use std::{
    thread::sleep,
    time::{Duration, Instant},
};

use log::{debug, error};
use reqwest::blocking::Client;

pub fn keepalive(uuid: &str) {
    let url = format!("{}/keepalive/{uuid}", std::env::var("SERVER").unwrap());
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
        let start = Instant::now();

        debug!("HEAD {url}");
        let res = match client.head(&url).send() {
            Err(err) => {
                error!("Failed to send keepalive, retrying: {err}");
                sleep(Duration::from_millis(100));
                continue;
            }
            Ok(res) => res,
        };
        debug!("Reply in {}ms", start.elapsed().as_millis());

        if !res.status().is_success() {
            error!("{url} responded with {}", res.status());
        }

        let elapsed = start.elapsed();
        let interval = Duration::from_secs(4);
        if elapsed < interval {
            sleep(interval - elapsed);
        }
    }
}
