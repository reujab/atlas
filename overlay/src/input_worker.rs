use crate::mpv_worker::send_command;
use gilrs::{ev::Button, Event, Gilrs};
use gtk::{glib::Propagation, EventControllerKey};
use log::{debug, info};
use relm4::prelude::*;
use std::{
    os::unix::net::UnixStream,
    sync::{Arc, Mutex},
    thread::sleep,
    time::Duration,
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
            "HomePage" | "Back" | "AudioNext" => {
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

pub(crate) fn handle_gamepad(sender: ComponentSender<super::App>, mutex: Arc<Mutex<UnixStream>>) {
    info!("Starting gamepad worker");
    let mut gilrs = Gilrs::new().unwrap();

    loop {
        while let Some(Event { event, .. }) = gilrs.next_event() {
            if let gilrs::ev::EventType::ButtonPressed(button, _) = event {
                debug!("{:?}", button);
                debug!("locking");
                let mut stream = mutex.lock().unwrap();
                debug!("locked");
                match button {
                    Button::North => {
                        send_command(vec!["cycle".into(), "sub-visibility".into()], &mut stream)
                            .unwrap();
                    }
                    Button::East => {
                        sender.input(super::Msg::Quit);
                    }
                    Button::South => {
                        send_command(vec!["cycle".into(), "pause".into()], &mut stream).unwrap();
                    }
                    _ => {}
                }
                debug!("unlocking");
            }
        }

        for (_, gamepad) in gilrs.gamepads() {
            if gamepad.is_pressed(Button::DPadLeft) {
                debug!("locking");
                let mut stream = mutex.lock().unwrap();
                debug!("locked");
                send_command(vec!["seek".into(), "-10".into()], &mut stream).unwrap();
                debug!("unlocking");
            } else if gamepad.is_pressed(Button::DPadRight) {
                debug!("locking");
                let mut stream = mutex.lock().unwrap();
                debug!("locked");
                send_command(vec!["seek".into(), "10".into()], &mut stream).unwrap();
                debug!("unlocking");
            }
        }

        sleep(Duration::from_millis(20));
    }
}
