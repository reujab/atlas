use crate::mpv_worker::get_command;
use gilrs::{ev::Button, Event, Gilrs};
use log::debug;
use relm4::prelude::*;
use std::{io::prelude::*, os::unix::net::UnixStream, thread::sleep, time::Duration};

pub(crate) fn handle_gamepad(sender: ComponentSender<super::App>, mut stream: UnixStream) {
    let mut gilrs = Gilrs::new().unwrap();
    let pause_command = get_command(0, vec!["cycle", "pause"]);
    let rewind_command = get_command(0, vec!["seek", "-10"]);
    let ffw_command = get_command(0, vec!["seek", "10"]);

    loop {
        while let Some(Event { event, .. }) = gilrs.next_event() {
            debug!("{:?}", event);
            if let gilrs::ev::EventType::ButtonPressed(button, _) = event {
                match button {
                    Button::South => {
                        stream.write_all(&pause_command).unwrap();
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
                stream.write_all(&rewind_command).unwrap();
            } else if gamepad.is_pressed(Button::DPadRight) {
                stream.write_all(&ffw_command).unwrap();
            }
        }

        sleep(Duration::from_millis(20));
    }
}
