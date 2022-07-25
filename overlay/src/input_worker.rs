use gilrs::{ev::Button, Event, Gilrs};
use std::{process::Command, thread::sleep, time::Duration};

pub fn handle_gamepad() {
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
                        Command::new("killall")
                            .args(&["-CONT", "atlas-frontend"])
                            .output()
                            .unwrap();
                        Command::new("killall").arg("mpv").output().unwrap();
                        std::process::exit(0);
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
