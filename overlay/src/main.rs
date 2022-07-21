mod input_worker;
mod position_worker;

use gtk::{prelude::*, Align, ApplicationWindow, Box, Image, Label, Orientation, Revealer};
use relm4::{AppUpdate, Model, RelmApp, Sender, Widgets};
use std::thread;

const PROGRESS_BAR_WIDTH: i32 = 600;
const PROGRESS_BAR_HEIGHT: i32 = 48;

struct State {
    duration: u32,
    position: u32,
    status: Status,
}

#[derive(PartialEq)]
pub enum Status {
    Loading,
    Playing,
    Paused,
}

pub enum Msg {
    UpdateDuration(u32),
    UpdatePosition(u32),
    UpdateStatus(Status),
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
                        append = position = &Label {
                            set_label: &format_secs(model.position),
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
                        append = duration = &Label {
                            set_label: &format_secs(model.duration),
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
        thread::spawn(input_worker::handle_gamepad);
    }

    fn post_init() {
        println!("post_init");
        relm4::set_global_css(include_bytes!("styles.css"));
    }

    fn post_view() {
        println!("post_view");
        self.revealer
            .set_reveal_child(model.status == Status::Paused);
        self.position.set_label(&format_secs(model.position));
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
        self.duration.set_label(&format_secs(model.duration));
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
        }
        true
    }
}

fn format_secs(secs: u32) -> String {
    let hours = secs / 3600;
    let minutes = secs % 3600 / 60;
    let seconds = secs % 60;
    format!("{hours}:{minutes:02}:{seconds:02}")
}

fn main() {
    let state = State {
        status: Status::Loading,
        duration: 3600 * 2 + 42 * 60 + 42,
        position: 0,
    };
    let app = RelmApp::new(state);
    app.run();
}
