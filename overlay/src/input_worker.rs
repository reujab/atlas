use crate::mpv_worker::{send_command, Command};
use gilrs::{ev::Button, Event, Gilrs};
use log::{debug, info};
use relm4::prelude::*;
use std::{
    os::unix::net::UnixStream,
    sync::{Arc, Mutex},
    thread::sleep,
    time::Duration,
};

pub(crate) fn handle_gamepad(sender: ComponentSender<super::App>, mutex: Arc<Mutex<UnixStream>>) {
    info!("Starting input worker");
    let mut gilrs = Gilrs::new().unwrap();

    loop {
        while let Some(Event { event, .. }) = gilrs.next_event() {
            if let gilrs::ev::EventType::ButtonPressed(button, _) = event {
                debug!("{:?}", button);
                debug!("locking");
                let mut stream = mutex.lock().unwrap();
                debug!("locked");
                match button {
                    Button::South => {
                        send_command(
                            Command {
                                id: 0,
                                command: vec!["cycle", "pause"],
                            },
                            &mut stream,
                            &sender,
                        )
                        .unwrap();
                    }
                    Button::East => {
                        sender.input(super::Msg::Quit);
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
                send_command(
                    Command {
                        id: 0,
                        command: vec!["seek", "-10"],
                    },
                    &mut stream,
                    &sender,
                )
                .unwrap();
                debug!("unlocking");
            } else if gamepad.is_pressed(Button::DPadRight) {
                debug!("locking");
                let mut stream = mutex.lock().unwrap();
                debug!("locked");
                send_command(
                    Command {
                        id: 0,
                        command: vec!["seek", "10"],
                    },
                    &mut stream,
                    &sender,
                )
                .unwrap();
                debug!("unlocking");
            }
        }

        sleep(Duration::from_millis(20));
    }
}
