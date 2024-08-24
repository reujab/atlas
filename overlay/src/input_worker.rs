use crate::mpv_worker::send_command;
use gtk::{glib::Propagation, EventControllerKey};
use log::{debug, info, warn};
use relm4::prelude::*;
use serde_json::Value;
use std::{
    os::unix::net::UnixStream,
    sync::{Arc, Mutex},
};

pub(crate) fn handle_keyboard(
    sender: ComponentSender<super::App>,
    mutex: Arc<Mutex<UnixStream>>,
    controller: &EventControllerKey,
) {
    info!("Starting keyboard worker");
    controller.connect_key_pressed(move |_, key, _, _| {
        let name = match key.name() {
            Some(name) => name,
            None => return Propagation::Stop,
        };
        debug!("key: {name}");
        let mut stream = mutex.lock().unwrap();
        match name.as_ref() {
            "Menu" => {
                try_send_command(vec!["cycle".into(), "sub-visibility".into()], &mut stream);
            }
            "HomePage" | "Back" | "AudioNext" | "Escape" => {
                sender.input(super::Msg::Quit);
            }
            "Return" | "AudioPlay" => {
                try_send_command(vec!["cycle".into(), "pause".into()], &mut stream);
            }
            "Left" | "AudioRewind" => {
                try_send_command(vec!["seek".into(), "-10".into()], &mut stream);
            }
            "Right" | "AudioForward" => {
                try_send_command(vec!["seek".into(), "10".into()], &mut stream);
            }
            "AudioLowerVolume" => {
                try_send_command(
                    vec!["add".into(), "volume".into(), "-5".into()],
                    &mut stream,
                );
            }
            "AudioRaiseVolume" => {
                try_send_command(vec!["add".into(), "volume".into(), "5".into()], &mut stream);
            }
            "AudioMute" => {
                try_send_command(vec!["cycle".into(), "mute".into()], &mut stream);
            }
            _ => {}
        }
        Propagation::Stop
    });
}

fn try_send_command(command: Vec<Value>, stream: &mut UnixStream) {
    if let Err(err) = send_command(&command, stream) {
        warn!(r#"Failed to "{}": {err}"#, command[0]);
    }
}
