use crate::mpv_worker::{send_command, Command};
use gilrs::{ev::Button, Event, Gilrs};
use log::debug;
use relm4::prelude::*;
use std::{os::unix::net::UnixStream, thread::sleep, time::Duration};

pub(crate) fn handle_gamepad(sender: ComponentSender<super::App>, mut stream: UnixStream) {
    let mut gilrs = Gilrs::new().unwrap();

    loop {
        while let Some(Event { event, .. }) = gilrs.next_event() {
            debug!("{:?}", event);
            if let gilrs::ev::EventType::ButtonPressed(button, _) = event {
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
            }
        }

        for (_, gamepad) in gilrs.gamepads() {
            if gamepad.is_pressed(Button::DPadLeft) {
                // stream.write_all(&rewind_command).unwrap();
                send_command(
                    Command {
                        id: 0,
                        command: vec!["seek", "-10"],
                    },
                    &mut stream,
                    &sender,
                )
                .unwrap();
            } else if gamepad.is_pressed(Button::DPadRight) {
                send_command(
                    Command {
                        id: 0,
                        command: vec!["seek", "10"],
                    },
                    &mut stream,
                    &sender,
                )
                .unwrap();
            }
        }

        sleep(Duration::from_millis(20));
    }
}
