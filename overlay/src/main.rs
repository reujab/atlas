mod input_worker;
mod position_worker;

use gtk::{prelude::*, Align, ApplicationWindow, Box, Image, Label, Orientation, Revealer};
use relm4::{AppUpdate, Model, RelmApp, Sender, Widgets};
use std::{process::Command, thread};

const PROGRESS_BAR_WIDTH: i32 = 750;
const PROGRESS_BAR_HEIGHT: i32 = 48;

struct State {
    duration: u32,
    position: u32,
    status: Status,
}

#[derive(PartialEq)]
pub enum Status {
    Playing,
    Paused,
}

pub enum Msg {
    UpdateDuration(u32),
    UpdatePosition(u32),
    UpdateStatus(Status),
    Quit,
}

struct Format {
    hours: String,
    minutes: String,
    seconds: String,
}

#[relm4_macros::widget]
impl Widgets<State, ()> for AppWidgets {
    view! {
        main_window = ApplicationWindow {
            set_maximized: true,
            set_decorated: false,
            set_child = Some(&Box) {
                set_orientation: Orientation::Vertical,
                set_valign: Align::End,
                append = revealer = &Revealer {
                    set_transition_duration: 1000,
                    set_transition_type: gtk::RevealerTransitionType::SlideUp,
                    set_child = Some(&Box) {
                        add_css_class: "container",
                        set_orientation: Orientation::Horizontal,
                        append = position_hours = &Label {
                            add_css_class: "mono",
                            set_label: &format(model.position).hours,
                        },
                        append = &Label {
                            set_label: ":",
                        },
                        append = position_minutes = &Label {
                            add_css_class: "mono",
                            set_label: &format(model.position).minutes,
                        },
                        append = &Label {
                            set_label: ":",
                        },
                        append = position_seconds = &Label {
                            add_css_class: "mono",
                            set_label: &format(model.position).seconds,
                        },
                        append = &Box {
                            set_hexpand: true,
                        },
                        append = status_icon = &Image {
                            set_pixel_size: 100,
                            set_icon_name: Some("media-playback-start"),
                        },
                        append = &Box {
                            set_orientation: Orientation::Vertical,
                            set_valign: Align::Center,
                            append = progress_wrapper = &Box {
                                add_css_class: "progress-bar",
                                set_orientation: Orientation::Horizontal,
                                append = progress = &Box {
                                    add_css_class: "progress",
                                },
                            },
                        },
                        append = &Box {
                            set_hexpand: true,
                        },
                        // append = duration = &Label {
                        //     set_label: &format_secs(model.duration),
                        //     set_halign: Align::End,
                        // },
                        append = duration_hours = &Label {
                            add_css_class: "mono",
                            set_label: &format(model.duration).hours,
                            set_halign: Align::End,
                        },
                        append = &Label {
                            set_label: ":",
                            set_halign: Align::End,
                        },
                        append = duration_minutes = &Label {
                            add_css_class: "mono",
                            set_label: &format(model.duration).minutes,
                            set_halign: Align::End,
                        },
                        append = &Label {
                            set_label: ":",
                            set_halign: Align::End,
                        },
                        append = duration_seconds = &Label {
                            add_css_class: "mono",
                            set_label: &format(model.duration).seconds,
                            set_halign: Align::End,
                        },
                    },
                },
            },
        }
    }

    fn pre_init() {
        println!("pre_init");
        let sender_clone = sender.clone();
        thread::spawn(move || position_worker::update_position(sender_clone));
        let sender_clone = sender.clone();
        thread::spawn(move || input_worker::handle_gamepad(sender_clone));
    }

    fn post_init() {
        println!("post_init");
        relm4::set_global_css(include_bytes!("styles.css"));
    }

    fn post_view() {
        self.revealer
            .set_reveal_child(model.status == Status::Paused);
        let position_format = format(model.position);
        self.position_hours.set_label(&position_format.hours);
        self.position_minutes.set_label(&position_format.minutes);
        self.position_seconds.set_label(&position_format.seconds);
        self.status_icon.set_icon_name(Some(match model.status {
            Status::Paused => "media-playback-pause",
            _ => "media-playback-start",
        }));
        self.progress.set_size_request(
            PROGRESS_BAR_HEIGHT
                + (model.position as f64 / model.duration as f64
                    * (PROGRESS_BAR_WIDTH - PROGRESS_BAR_HEIGHT) as f64) as i32,
            0,
        );
        let duration_format = format(model.duration);
        self.duration_hours.set_label(&duration_format.hours);
        self.duration_minutes.set_label(&duration_format.minutes);
        self.duration_seconds.set_label(&duration_format.seconds);
    }
}

impl Model for State {
    type Msg = Msg;
    type Widgets = AppWidgets;
    type Components = ();
}

impl AppUpdate for State {
    fn update(&mut self, msg: Msg, _components: &(), _sender: Sender<Msg>) -> bool {
        match msg {
            Msg::UpdateDuration(duration) => {
                self.duration = duration;
            }
            Msg::UpdatePosition(position) => {
                self.position = position;
            }
            Msg::UpdateStatus(status) => {
                self.status = status;
            }
            Msg::Quit => return false,
        }
        true
    }
}

fn format(secs: u32) -> Format {
    let hours = secs / 3600;
    let minutes = secs % 3600 / 60;
    let seconds = secs % 60;
    Format {
        hours: hours.to_string(),
        minutes: format!("{minutes:02}"),
        seconds: format!("{seconds:02}"),
    }
}

fn main() {
    Command::new("killall")
        .args(&["-STOP", "atlas-frontend"])
        .output()
        .unwrap();

    let state = State {
        status: Status::Playing,
        duration: 0,
        position: 0,
    };
    let app = RelmApp::new(state);
    app.run();

    Command::new("killall")
        .args(&["-CONT", "atlas-frontend"])
        .output()
        .unwrap();
    Command::new("killall").arg("mpv").output().unwrap();
}
