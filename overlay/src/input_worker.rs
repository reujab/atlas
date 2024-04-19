use crate::mpv_worker::send_command;
use gtk::{glib::Propagation, EventControllerKey};
use log::{debug, info};
use relm4::prelude::*;
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
                send_command(vec!["cycle".into(), "sub-visibility".into()], &mut stream).unwrap();
            }
            "HomePage" | "Back" | "AudioNext" | "Escape" => {
                sender.input(super::Msg::Quit);
            }
            "Return" | "AudioPlay" => {
                send_command(vec!["cycle".into(), "pause".into()], &mut stream).unwrap();
            }
            "Left" | "AudioRewind" => {
                send_command(vec!["seek".into(), "-10".into()], &mut stream).unwrap();
            }
            "Right" | "AudioForward" => {
                send_command(vec!["seek".into(), "10".into()], &mut stream).unwrap();
            }
            "AudioLowerVolume" => {
                send_command(
                    vec!["add".into(), "volume".into(), "-5".into()],
                    &mut stream,
                )
                .unwrap();
            }
            "AudioRaiseVolume" => {
                send_command(vec!["add".into(), "volume".into(), "5".into()], &mut stream).unwrap();
            }
            "AudioMute" => {
                send_command(vec!["cycle".into(), "mute".into()], &mut stream).unwrap();
            }
            _ => {}
        }
        Propagation::Stop
    });
}
