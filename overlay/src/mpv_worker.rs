use super::{MPVInfo, Msg};
use log::{debug, error, info};
use regex::Regex;
use relm4::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{
    io::{prelude::*, BufReader},
    os::unix::net::UnixStream,
    sync::{Arc, Mutex},
    thread::sleep,
    time::Duration,
};

#[derive(Serialize)]
struct Command {
    pub command: Vec<Value>,
}

#[derive(Deserialize)]
struct Data {
    #[serde(rename = "request_id")]
    id: u32,
    #[serde(default)]
    data: serde_json::Value,
    error: String,
}

#[derive(Deserialize)]
struct Event {
    event: String,
}

pub(crate) fn start(sender: ComponentSender<super::App>, mutex: Arc<Mutex<UnixStream>>) {
    info!("Starting mpv info worker");

    let mut stream = mutex.lock().unwrap();
    let censor = Regex::new(r"(?i)fuck").unwrap();
    let key = Regex::new(r"\?key=.*").unwrap();
    let title = get_property("media-title", &mut stream)
        .unwrap()
        .as_str()
        .unwrap()
        .to_owned();
    let title = censor.replace_all(&title, "****").to_string();
    let title = key.replace_all(&title, "").to_string();
    sender.input(Msg::SetTitle(title));

    let duration = get_property("duration", &mut stream)
        .unwrap()
        .as_f64()
        .unwrap();
    sender.input(Msg::SetDuration(duration));
    drop(stream);

    loop {
        debug!("locking");
        let mut stream = mutex.lock().unwrap();
        debug!("locked");
        let mpv_info = match get_mpv_info(&mut stream) {
            Ok(mpv_info) => mpv_info,
            Err(err) => {
                error!("{err}");
                sender.input(Msg::Quit);
                break;
            }
        };

        sender.input(Msg::SetMPVInfo(mpv_info));

        debug!("unlocking");
        drop(stream);
        sleep(Duration::from_millis(200));
    }
}

pub(crate) fn send_command(
    command: Vec<Value>,
    stream: &mut UnixStream,
) -> Result<serde_json::Value, String> {
    let mut reader = BufReader::new(stream.try_clone().unwrap());
    let command_str = serde_json::to_string(&Command { command }).unwrap() + "\n";
    debug!("> {}", command_str.trim());
    if let Err(err) = stream.write_all(&command_str.into_bytes()) {
        return Err(err.to_string());
    }

    loop {
        let mut res = String::new();
        if reader.read_line(&mut res).unwrap() == 0 {
            return Err("socket closed".into());
        }

        debug!("< {}", res.trim());
        match serde_json::from_str::<Data>(&res) {
            Ok(data) => {
                if data.id == 0 {
                    if data.error != "success" {
                        return Err(data.error);
                    }
                    return Ok(data.data);
                } else {
                    debug!("wrong id");
                }
            }
            Err(err) => {
                debug!("parse error: {}", err);
            }
        }
    }
}

pub(crate) fn get_property(
    property: &'static str,
    stream: &mut UnixStream,
) -> Result<serde_json::Value, String> {
    debug!("getting property: {}", property);
    return send_command(vec!["get_property".into(), property.into()], stream);
}

pub(crate) fn wait_for_event(stream: &UnixStream, event: &str) {
    debug!("waiting for {}", event);
    let mut reader = BufReader::new(stream);

    loop {
        let mut res = String::new();
        if reader.read_line(&mut res).unwrap() == 0 {
            panic!("socket closed");
        }
        debug!("{}", res);
        match serde_json::from_str::<Event>(&res) {
            Ok(e) => {
                if e.event == event {
                    break;
                }
            }
            Err(err) => {
                debug!("parse error: {}", err);
            }
        }
    }
}

fn get_mpv_info(stream: &mut UnixStream) -> Result<MPVInfo, String> {
    let paused = get_property("pause", stream)?.as_bool().unwrap();
    let position = get_property("time-pos", stream)?.as_f64().unwrap();
    let buffering = get_property("paused-for-cache", stream)?.as_bool().unwrap();
    let buffered = match get_property("demuxer-cache-time", stream) {
        Ok(buffered) => buffered.as_f64().unwrap(),
        Err(_) => position,
    };
    let dropped = get_property("frame-drop-count", stream)?.as_u64().unwrap();
    let speed = get_property("cache-speed", stream)?.as_u64().unwrap() as u32;

    Ok(MPVInfo {
        position,
        paused,
        buffering,
        buffered,
        dropped,
        speed,
    })
}
