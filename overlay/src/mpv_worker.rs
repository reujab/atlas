use super::{MPVInfo, Msg};
use log::{debug, info};
use regex::Regex;
use relm4::prelude::*;
use serde::{Deserialize, Serialize};
use std::{
    io::{prelude::*, BufReader},
    os::unix::net::UnixStream,
    sync::{Arc, Mutex},
    thread::sleep,
    time::Duration,
};

#[derive(Serialize)]
pub struct Command {
    #[serde(rename = "request_id")]
    pub id: u32,
    pub command: Vec<&'static str>,
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
    let title = get_property("media-title", &mut stream, &sender)
        .unwrap()
        .as_str()
        .unwrap()
        .to_owned();
    let title = censor.replace_all(&title, "****").to_string();
    sender.input(Msg::SetTitle(title));

    let duration = get_property("duration", &mut stream, &sender)
        .unwrap()
        .as_f64()
        .unwrap() as u32;
    sender.input(Msg::SetDuration(duration));
    drop(stream);

    loop {
        debug!("locking");
        let mut stream = mutex.lock().unwrap();
        debug!("locked");
        let paused = get_property("pause", &mut stream, &sender)
            .unwrap()
            .as_bool()
            .unwrap();
        let position = get_property("time-pos", &mut stream, &sender)
            .unwrap()
            .as_f64()
            .unwrap() as u32;
        let buffering = get_property("paused-for-cache", &mut stream, &sender)
            .unwrap()
            .as_bool()
            .unwrap();
        let dropped = get_property("frame-drop-count", &mut stream, &sender)
            .unwrap()
            .as_u64()
            .unwrap();
        let speed = get_property("cache-speed", &mut stream, &sender)
            .unwrap()
            .as_u64()
            .unwrap() as u32;
        let buffered = match get_property("demuxer-cache-time", &mut stream, &sender) {
            Ok(buffered) => buffered.as_f64().unwrap(),
            Err(_) => position as f64,
        };

        sender.input(Msg::SetMPVInfo(MPVInfo {
            position,
            paused,
            buffering,
            buffered,
            dropped,
            speed,
        }));

        debug!("unlocking");
        drop(stream);
        sleep(Duration::from_millis(200));
    }
}

pub(crate) fn send_command(
    command: Command,
    stream: &mut UnixStream,
    sender: &ComponentSender<super::App>,
) -> Result<serde_json::Value, String> {
    let mut reader = BufReader::new(stream.try_clone().unwrap());
    let command_str = serde_json::to_string(&command).unwrap() + "\n";
    debug!("> {}", command_str.trim());
    if let Err(err) = stream.write_all(&command_str.into_bytes()) {
        sender.input(Msg::Quit);
        panic!("{err}");
    }

    loop {
        let mut res = String::new();
        if reader.read_line(&mut res).unwrap() == 0 {
            sender.input(Msg::Quit);
            panic!("socket closed, quitting");
        }

        debug!("< {}", res.trim());
        match serde_json::from_str::<Data>(&res) {
            Ok(data) => {
                if data.id == command.id {
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

fn get_property(
    property: &'static str,
    stream: &mut UnixStream,
    sender: &ComponentSender<super::App>,
) -> Result<serde_json::Value, String> {
    debug!("getting property: {}", property);
    return send_command(
        Command {
            id: 1,
            command: vec!["get_property", property],
        },
        stream,
        sender,
    );
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
