use super::{Info, Msg};
use relm4::prelude::*;
use serde::Serialize;
use std::{io::prelude::*, os::unix::net::UnixStream, thread::sleep, time::Duration};

#[derive(Serialize)]
struct Message {
    message: String,
}

pub(crate) fn update_info(sender: ComponentSender<super::App>) {
    let mut stream = UnixStream::connect("/tmp/torrentd").unwrap();
    let message = Message {
        message: "get_info".to_owned(),
    };
    let message = serde_json::to_string(&message).unwrap();

    loop {
        stream.write_all(message.as_bytes()).unwrap();
        stream.flush().unwrap();

        let mut res = [0; 1024];
        stream.read(&mut res).unwrap();
        let res = String::from_utf8(res.to_vec()).unwrap();
        let res = res.trim_matches(0 as char);
        println!("{res}");
        let info = serde_json::from_str::<Info>(&res).unwrap();
        sender.input(Msg::UpdateInfo(info));

        sleep(Duration::from_secs(1));
    }
}
