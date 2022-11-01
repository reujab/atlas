mod input_worker;
mod mpv_worker;
mod torrentd_worker;

use gtk::{prelude::*, Align, ApplicationWindow, Box, Image, Label, Orientation, Revealer};
use log::info;
use relm4::prelude::*;
use serde::Deserialize;
use std::{cmp::max, os::unix::net::UnixStream, process::Command, thread, time::Duration};

const PROGRESS_BAR_WIDTH: i32 = 750;
const PROGRESS_BAR_HEIGHT: i32 = 48;

pub(crate) struct App {
    is_torrent: bool,

    mpv: MPVInfo,
    torrentd: TorrentdInfo,

    title: String,
    duration: u32,
    speed: u32,

    buffered_width: i32,
    progress_width: i32,
}

#[derive(Debug, Default)]
pub struct MPVInfo {
    position: u32,
    paused: bool,
    buffering: bool,
    dropped: u64,
}

#[derive(Deserialize, Debug, Default)]
pub struct TorrentdInfo {
    peers: Option<u32>,
    buffered: Option<f64>,
    speed: Option<u32>,
}

#[derive(Debug)]
pub enum Msg {
    SetMPVInfo(MPVInfo),
    SetTorrentdInfo(TorrentdInfo),

    SetTitle(String),
    SetDuration(u32),
    SetSpeed(u32),

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
                        add_css_class: "top",
                        set_transition_duration: 1000,
                        set_transition_type: gtk::RevealerTransitionType::SlideDown,
                        #[watch]
                        set_reveal_child: model.mpv.paused || model.mpv.buffering,

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
                                    set_visible: model.is_torrent,
                                    #[watch]
                                    set_label: &format!("Peers: {}", model.torrentd.peers.unwrap_or(0)),
                                },

                                Label {
                                    #[watch]
                                    set_label: &(human_bytes::human_bytes(model.speed) + "/s"),
                                },

                                Label {
                                    #[watch]
                                    set_label: &format!("Dropped: {}", model.mpv.dropped),
                                },
                            },
                        },
                    },
                },

                Revealer {
                    add_css_class: "bottom",
                    set_transition_duration: 1000,
                    set_transition_type: gtk::RevealerTransitionType::SlideUp,
                    #[watch]
                    set_reveal_child: model.mpv.paused,

                    Box {
                        add_css_class: "container",
                        add_css_class: "bottom",
                        set_orientation: Orientation::Horizontal,

                        Label {
                            add_css_class: "mono",
                            #[watch]
                            set_label: &format(model.mpv.position).hours,
                        },

                        Label {
                            set_label: ":",
                        },

                        Label {
                            add_css_class: "mono",
                            #[watch]
                            set_label: &format(model.mpv.position).minutes,
                        },

                        Label {
                            set_label: ":",
                        },

                        Label {
                            add_css_class: "mono",
                            #[watch]
                            set_label: &format(model.mpv.position).seconds,
                        },

                        Box {
                            set_hexpand: true,
                        },

                        Image {
                            set_pixel_size: 100,
                            #[watch]
                            set_icon_name: Some(match model.mpv.paused {
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
        let is_torrent = &std::env::args().nth(1).unwrap_or("".to_owned()) == "--torrent";
        let model = App {
            is_torrent,

            mpv: MPVInfo::default(),
            torrentd: TorrentdInfo::default(),

            title: "Loading...".to_owned(),
            duration: 0,
            speed: 0,

            buffered_width: 0,
            progress_width: 0,
        };
        let widgets = view_output!();

        relm4::set_global_css(include_bytes!("styles.css"));

        let sender_clone = sender.clone();
        let stream_clone = stream.try_clone().unwrap();
        thread::spawn(move || input_worker::handle_gamepad(sender_clone, stream_clone));
        let sender_clone = sender.clone();
        thread::spawn(move || mpv_worker::start(sender_clone, stream));
        if is_torrent {
            thread::spawn(move || torrentd_worker::start(sender));
        }

        ComponentParts { model, widgets }
    }

    fn update(&mut self, msg: Self::Input, _sender: ComponentSender<Self>) {
        match msg {
            Msg::SetMPVInfo(info) => {
                self.mpv = info;
            }
            Msg::SetTorrentdInfo(info) => {
                self.torrentd = info;
            }
            Msg::SetTitle(title) => {
                self.title = title;
            }
            Msg::SetDuration(duration) => {
                self.duration = duration;
            }
            Msg::SetSpeed(speed) => {
                self.speed = speed;
            }
            Msg::Quit => {
                relm4::main_application().quit();
            }
        }

        self.buffered_width = PROGRESS_BAR_HEIGHT
            + (self.torrentd.buffered.unwrap_or(0.0)
                * (PROGRESS_BAR_WIDTH - PROGRESS_BAR_HEIGHT) as f64) as i32;
        self.progress_width = PROGRESS_BAR_HEIGHT
            + (self.mpv.position as f64 / self.duration as f64
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
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

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
    info!("Waiting for file to load");
    mpv_worker::wait_for_event(&stream, "file-loaded");

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
