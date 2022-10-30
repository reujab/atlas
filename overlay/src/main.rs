mod info_worker;
mod input_worker;
mod mpv_worker;

use gtk::{prelude::*, Align, ApplicationWindow, Box, Image, Label, Orientation, Revealer};
use log::info;
use relm4::prelude::*;
use serde::Deserialize;
use std::{
    cmp::max, io::BufReader, os::unix::net::UnixStream, process::Command, thread, time::Duration,
};

const PROGRESS_BAR_WIDTH: i32 = 750;
const PROGRESS_BAR_HEIGHT: i32 = 48;

pub(crate) struct App {
    title: String,
    info: Info,
    duration: u32,
    position: u32,
    paused: bool,
    dropped: u64,

    buffered_width: i32,
    progress_width: i32,
}

#[derive(Deserialize, Debug, Default, PartialEq)]
pub struct Info {
    peers: Option<u32>,
    speed: Option<u32>,
    buffered: Option<f64>,
}

#[derive(Debug)]
pub enum Msg {
    UpdateTitle(String),
    UpdateInfo(Info),
    UpdateDuration(u32),
    UpdatePosition(u32),
    UpdatePaused(bool),
    UpdateDropped(u64),
    Quit,
}

struct Format {
    hours: String,
    minutes: String,
    seconds: String,
}

#[relm4::component]
impl SimpleComponent for App {
    type Init = UnixStream;
    type Input = Msg;
    type Output = ();
    type Widgets = AppWidgets;

    view! {
        ApplicationWindow {
            set_maximized: true,
            set_decorated: false,

            Box {
                set_orientation: Orientation::Vertical,

                Box {
                    set_valign: Align::Start,
                    set_vexpand: true,

                    Revealer {
                        set_transition_duration: 1000,
                        set_transition_type: gtk::RevealerTransitionType::SlideDown,
                        #[watch]
                        set_reveal_child: model.paused,

                        Box {
                            add_css_class: "container",
                            add_css_class: "top",
                            set_orientation: Orientation::Horizontal,
                            set_hexpand: true,

                            Box {
                                set_orientation: Orientation::Vertical,
                                set_hexpand: true,
                                set_valign: Align::Center,
                                set_size_request: (500, -1),

                                Label {
                                    add_css_class: "title",
                                    set_wrap: true,
                                    set_wrap_mode: gtk::pango::WrapMode::WordChar,
                                    set_max_width_chars: 32,
                                    #[watch]
                                    set_label: &model.title,
                                },
                            },

                            Box {
                                add_css_class: "info",
                                set_orientation: Orientation::Vertical,
                                set_valign: Align::Center,

                                Label {
                                    #[watch]
                                    set_label: &format!("Peers: {}", model.info.peers.unwrap_or(0)),
                                },

                                Label {
                                    #[watch]
                                    set_label: &(human_bytes::human_bytes(model.info.speed.unwrap_or(0)) + "/s"),
                                },

                                Label {
                                    #[watch]
                                    set_label: &format!("Dropped: {}", model.dropped),
                                },
                            },
                        },
                    },
                },

                Revealer {
                    set_transition_duration: 1000,
                    set_transition_type: gtk::RevealerTransitionType::SlideUp,
                    #[watch]
                    set_reveal_child: model.paused,

                    Box {
                        add_css_class: "container",
                        add_css_class: "bottom",
                        set_orientation: Orientation::Horizontal,

                        Label {
                            add_css_class: "mono",
                            #[watch]
                            set_label: &format(model.position).hours,
                        },

                        Label {
                            set_label: ":",
                        },

                        Label {
                            add_css_class: "mono",
                            #[watch]
                            set_label: &format(model.position).minutes,
                        },

                        Label {
                            set_label: ":",
                        },

                        Label {
                            add_css_class: "mono",
                            #[watch]
                            set_label: &format(model.position).seconds,
                        },

                        Box {
                            set_hexpand: true,
                        },

                        Image {
                            set_pixel_size: 100,
                            #[watch]
                            set_icon_name: Some(match model.paused {
                                true => "media-playback-pause",
                                false => "media-playback-start",
                            }),
                        },

                        Box {
                            set_orientation: Orientation::Vertical,
                            set_valign: Align::Center,

                            Box {
                                add_css_class: "progress-bar",
                                set_orientation: Orientation::Horizontal,

                                Box {
                                    add_css_class: "buffered",
                                    #[watch]
                                    set_size_request: (max(model.buffered_width, model.progress_width), -1),

                                    Box {
                                        add_css_class: "progress",
                                        #[watch]
                                        set_size_request: (model.progress_width, -1),
                                    },
                                },
                            },
                        },

                        Box {
                            set_hexpand: true,
                        },

                        Label {
                            add_css_class: "mono",
                            set_halign: Align::End,
                            #[watch]
                            set_label: &format(model.duration).hours,
                        },

                        Label {
                            set_label: ":",
                            set_halign: Align::End,
                        },

                        Label {
                            add_css_class: "mono",
                            set_halign: Align::End,
                            #[watch]
                            set_label: &format(model.duration).minutes,
                        },

                        Label {
                            set_label: ":",
                            set_halign: Align::End,
                        },

                        Label {
                            add_css_class: "mono",
                            set_halign: Align::End,
                            #[watch]
                            set_label: &format(model.duration).seconds,
                        },
                    },
                },
            },
        }
    }

    fn init(
        stream: Self::Init,
        root: &Self::Root,
        sender: ComponentSender<Self>,
    ) -> ComponentParts<Self> {
        let model = App {
            title: "Loading...".to_owned(),
            info: Info::default(),
            duration: 0,
            position: 0,
            paused: false,
            dropped: 0,

            buffered_width: 0,
            progress_width: 0,
        };
        let widgets = view_output!();

        relm4::set_global_css(include_bytes!("styles.css"));

        let sender_clone = sender.clone();
        let stream_clone = stream.try_clone().unwrap();
        thread::spawn(move || mpv_worker::mpv_worker(sender_clone, stream_clone));
        let sender_clone = sender.clone();
        thread::spawn(move || info_worker::update_info(sender_clone));
        let sender_clone = sender.clone();
        thread::spawn(move || input_worker::handle_gamepad(sender_clone, stream));

        ComponentParts { model, widgets }
    }

    fn update(&mut self, msg: Self::Input, _sender: ComponentSender<Self>) {
        match msg {
            Msg::UpdateTitle(title) => {
                self.title = title;
            }
            Msg::UpdateInfo(info) => {
                self.info = info;
            }
            Msg::UpdateDuration(duration) => {
                self.duration = duration;
            }
            Msg::UpdatePosition(position) => {
                self.position = position;
            }
            Msg::UpdatePaused(paused) => {
                self.paused = paused;
            }
            Msg::UpdateDropped(dropped) => {
                self.dropped = dropped;
            }
            Msg::Quit => {
                relm4::main_application().quit();
            }
        }

        self.buffered_width = PROGRESS_BAR_HEIGHT
            + (self.info.buffered.unwrap_or(0.0)
                * (PROGRESS_BAR_WIDTH - PROGRESS_BAR_HEIGHT) as f64) as i32;
        self.progress_width = PROGRESS_BAR_HEIGHT
            + (self.position as f64 / self.duration as f64
                * (PROGRESS_BAR_WIDTH - PROGRESS_BAR_HEIGHT) as f64) as i32;
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
    info!("Connecting to mpv");
    let stream = loop {
        match UnixStream::connect("/tmp/mpv") {
            Ok(stream) => break stream,
            Err(_) => {
                thread::sleep(Duration::from_millis(100));
                continue;
            }
        }
    };
    let mut reader = BufReader::new(stream.try_clone().unwrap());
    info!("Waiting for file to load");
    mpv_worker::wait_for_event(&mut reader, "file-loaded");
    drop(reader);

    thread::sleep(Duration::from_secs(3));
    Command::new("killall")
        .args(&["-STOP", "atlas-frontend"])
        .output()
        .unwrap();

    info!("Starting overlay");
    let app = RelmApp::new("atlas.overlay");
    app.run::<App>(stream);

    Command::new("killall")
        .args(&["-CONT", "atlas-frontend"])
        .output()
        .unwrap();
    Command::new("killall").arg("mpv").output().unwrap();
}
