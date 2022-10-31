use super::{Msg, TorrentdInfo};
use log::{debug, warn};
use relm4::prelude::*;
use serde::Serialize;
use std::{
    io::{prelude::*, BufReader},
    os::unix::net::UnixStream,
    thread::sleep,
    time::Duration,
};

#[derive(Serialize)]
struct Message {
    message: String,
}

pub(crate) fn start(sender: ComponentSender<super::App>) {
    let mut stream = UnixStream::connect("/tmp/torrentd").unwrap();
    let mut reader = BufReader::new(stream.try_clone().unwrap());
    let get_info = Message {
        message: "get_info".to_owned(),
    };
    let get_info = serde_json::to_string(&get_info).unwrap() + "\n";
    let get_info = get_info.as_bytes();

    loop {
        stream.write_all(get_info).unwrap();

        let mut res = String::new();
        if reader.read_line(&mut res).unwrap() == 0 {
            warn!("Socket closed");
            break;
        }
        debug!("{}", res.trim());
        let info = serde_json::from_str::<TorrentdInfo>(&res).unwrap();
        if let Some(speed) = info.speed {
            sender.input(Msg::SetSpeed(speed));
        }
        sender.input(Msg::SetTorrentdInfo(info));

        sleep(Duration::from_secs(1));
    }
}
