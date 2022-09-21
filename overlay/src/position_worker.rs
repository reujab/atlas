use relm4::{send, Sender};
use std::{process::Command, thread::sleep, time::Duration};

pub fn update_position(sender: Sender<super::Msg>) {
    let output = Command::new("playerctl").arg("metadata").output().unwrap();
    let duration = String::from_utf8(output.stdout)
        .unwrap()
        .split('\n')
        .find(|line| line.contains("mpris:length"))
        .expect("time not found in metadata")
        .split(' ')
        .last()
        .unwrap()
        .parse::<u64>()
        .unwrap()
        / 1000000;
    send!(sender, super::Msg::UpdateDuration(duration as u32));

    loop {
        let output = Command::new("playerctl").arg("position").output().unwrap();

        if String::from_utf8(output.stderr).unwrap().trim() == "No players found" {
            send!(sender, super::Msg::Quit);
            break;
        }

        let position = String::from_utf8(output.stdout)
            .unwrap()
            .trim()
            .parse::<f32>()
            .unwrap() as u32;
        send!(sender, super::Msg::UpdatePosition(position));

        let output = Command::new("playerctl").arg("status").output().unwrap();
        let status = String::from_utf8(output.stdout).unwrap().trim().to_owned();
        send!(
            sender,
            super::Msg::UpdateStatus(match status.as_str() {
                "Playing" => super::Status::Playing,
                "Paused" => super::Status::Paused,
                _ => panic!("invalid status: {status}"),
            })
        );

        sleep(Duration::from_millis(10));
    }
}
