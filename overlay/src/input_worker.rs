use gilrs::{ev::Button, Event, Gilrs};
use relm4::{send, Sender};
use std::{process::Command, thread::sleep, time::Duration};

pub fn handle_gamepad(sender: Sender<super::Msg>) {
    let mut gilrs = Gilrs::new().unwrap();
    loop {
        while let Some(Event { event, .. }) = gilrs.next_event() {
            println!("{:?}", event);
            if let gilrs::ev::EventType::ButtonPressed(button, _) = event {
                match button {
                    Button::South => {
                        Command::new("playerctl")
                            .arg("play-pause")
                            .output()
                            .unwrap();
                    }
                    Button::East => {
                        send!(sender, super::Msg::Quit);
                    }
                    _ => {}
                }
            }
        }

        for (_, gamepad) in gilrs.gamepads() {
            if gamepad.is_pressed(Button::DPadLeft) {
                Command::new("playerctl")
                    .args(&["position", "10-"])
                    .output()
                    .unwrap();
            } else if gamepad.is_pressed(Button::DPadRight) {
                Command::new("playerctl")
                    .args(&["position", "10+"])
                    .output()
                    .unwrap();
            }
        }

        sleep(Duration::from_millis(10));
    }
}
