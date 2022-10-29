use super::Msg;
use relm4::prelude::*;
use serde::{Deserialize, Serialize};
use std::{
    io::{prelude::*, BufReader},
    os::unix::net::UnixStream,
    thread::sleep,
    time::Duration,
};

#[derive(Serialize)]
struct Command {
    #[serde(rename = "request_id")]
    id: u32,
    command: Vec<&'static str>,
}

#[derive(Deserialize)]
struct Data {
    #[serde(rename = "request_id")]
    id: u32,
    data: serde_json::Value,
}

#[derive(Deserialize)]
struct Event {
    event: String,
}

pub(crate) fn mpv_worker(sender: ComponentSender<super::App>, mut stream: UnixStream) {
    let mut reader = BufReader::new(stream.try_clone().unwrap());

    let command = get_command(1, vec!["get_property", "media-title"]);
    stream.write_all(&command).unwrap();
    let data = get_data(1, &mut reader, &sender);
    sender.input(Msg::UpdateTitle(data.as_str().unwrap().to_owned()));

    let command = get_command(1, vec!["get_property", "duration"]);
    stream.write_all(&command).unwrap();
    let data = get_data(1, &mut reader, &sender);
    sender.input(Msg::UpdateDuration(data.as_f64().unwrap() as u32));

    loop {
        let command = get_command(1, vec!["get_property", "time-pos"]);
        stream.write_all(&command).unwrap();
        let data = get_data(1, &mut reader, &sender);
        sender.input(Msg::UpdatePosition(data.as_f64().unwrap() as u32));

        let command = get_command(1, vec!["get_property", "paused-for-cache"]);
        stream.write_all(&command).unwrap();
        let data = get_data(1, &mut reader, &sender);
        if data.as_bool().unwrap() {
            sender.input(Msg::UpdatePaused(true));
        } else {
            let command = get_command(1, vec!["get_property", "pause"]);
            stream.write_all(&command).unwrap();
            let data = get_data(1, &mut reader, &sender);
            sender.input(Msg::UpdatePaused(data.as_bool().unwrap()));
        }

        let command = get_command(1, vec!["get_property", "frame-drop-count"]);
        stream.write_all(&command).unwrap();
        let data = get_data(1, &mut reader, &sender);
        sender.input(Msg::UpdateDropped(data.as_u64().unwrap()));

        sleep(Duration::from_millis(200));
    }
}

pub fn get_command(id: u32, command: Vec<&'static str>) -> Vec<u8> {
    let command = Command { id, command };
    let str = serde_json::to_string(&command).unwrap() + "\n";
    str.into_bytes()
}

fn get_data<R: Read>(
    id: u32,
    reader: &mut BufReader<R>,
    sender: &ComponentSender<super::App>,
) -> serde_json::Value {
    loop {
        let mut res = String::new();
        if reader.read_line(&mut res).unwrap() == 0 {
            sender.input(Msg::Quit);
            panic!("socket closed");
        };
        match serde_json::from_str::<Data>(&res) {
            Ok(data) => {
                if data.id == id {
                    return data.data;
                }
            }
            Err(_) => continue,
        };
    }
}

pub(crate) fn wait_for_event<R: Read>(reader: &mut BufReader<R>, event: &str) {
    loop {
        let mut res = String::new();
        if reader.read_line(&mut res).unwrap() == 0 {
            panic!("socket closed");
        }
        match serde_json::from_str::<Event>(&res) {
            Ok(e) => {
                if e.event == event {
                    break;
                }
            }
            Err(_) => continue,
        }
    }
}
