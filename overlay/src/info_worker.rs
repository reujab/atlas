use super::{Info, Msg};
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

pub(crate) fn update_info(sender: ComponentSender<super::App>) {
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
            eprintln!("read_line() returned 0");
            continue;
        }
        print!("{res}");
        let info = serde_json::from_str::<Info>(&res).unwrap();
        sender.input(Msg::UpdateInfo(info));

        sleep(Duration::from_secs(1));
    }
}
