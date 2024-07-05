mod input_worker;
mod keepalive_worker;
mod mpv_worker;

use clap::Parser;
use gtk::{
    prelude::*, Align, ApplicationWindow, Box, EventControllerKey, Image, Label, Orientation,
    Revealer,
};
use log::info;
use mpv_worker::send_command;
use relm4::prelude::*;
use std::{
    cmp::max,
    fs::File,
    io::prelude::*,
    os::unix::net::UnixStream,
    sync::{Arc, Mutex},
    thread,
    time::Duration,
};

const PROGRESS_BAR_WIDTH: i32 = 750;
const PROGRESS_BAR_HEIGHT: i32 = 48;

#[derive(Parser, Debug)]
struct Args {
    #[arg(long)]
    title: String,
    #[arg(long)]
    uuid: Option<String>,
}

pub(crate) struct App {
    mpv: MPVInfo,

    title: String,
    duration: f64,

    buffered_width: i32,
    progress_width: i32,
}

#[derive(Debug, Default)]
pub struct MPVInfo {
    paused: bool,
    position: f64,
    buffering: bool,
    buffered: f64,
    speed: u32,
    dropped: u64,
}

#[derive(Debug)]
pub enum Msg {
    SetMPVInfo(MPVInfo),

    SetDuration(f64),

    Quit,
}

struct Format {
    hours: String,
    minutes: String,
    seconds: String,
}

struct AppInit {
    stream: Arc<Mutex<UnixStream>>,
    title: String,
}

#[relm4::component]
impl SimpleComponent for App {
    type Init = AppInit;
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
                                    #[watch]
                                    set_label: &(human_bytes::human_bytes(model.mpv.speed) + "/s"),
                                },

                                Label {
                                    #[watch]
                                    set_label: &format!("Dropped: {}", model.mpv.dropped),
                                },
                            },
                        },
                    },
                },

                // this is required for keyboard events
                // the window only spawns when there is a "visible" widget
                Label {
                    set_label: ".",
                    add_css_class: "invisible",
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

                        Box {
                            set_hexpand: true,
                        },

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

                        Box {
                            set_hexpand: true,
                        },
                    },
                },
            },
        }
    }

    fn init(
        init: Self::Init,
        root: Self::Root,
        sender: ComponentSender<Self>,
    ) -> ComponentParts<Self> {
        let model = App {
            mpv: MPVInfo::default(),

            title: init.title,
            duration: 0.0,

            buffered_width: 0,
            progress_width: 0,
        };
        let widgets = view_output!();

        let stream = init.stream;
        let sender_clone = sender.clone();
        let stream_clone = stream.clone();
        thread::spawn(move || mpv_worker::start(sender_clone, stream_clone));
        let sender_clone = sender.clone();
        let kbd_controller = EventControllerKey::new();
        input_worker::handle_keyboard(sender_clone, stream, &kbd_controller);
        root.add_controller(kbd_controller);

        ComponentParts { model, widgets }
    }

    fn update(&mut self, msg: Self::Input, _sender: ComponentSender<Self>) {
        match msg {
            Msg::SetMPVInfo(info) => {
                self.mpv = info;
            }
            Msg::SetDuration(duration) => {
                self.duration = duration;
            }
            Msg::Quit => {
                let percent = self.mpv.position / self.duration;
                let progress = format!("{percent}\n{}", self.mpv.position);
                let mut file = File::create("/tmp/progress").unwrap();
                file.write_all(progress.as_bytes()).unwrap();
                file.sync_all().unwrap();
                drop(file);
                relm4::main_application().quit();
            }
        }

        self.buffered_width = PROGRESS_BAR_HEIGHT
            + (self.mpv.buffered / self.duration
                * (PROGRESS_BAR_WIDTH - PROGRESS_BAR_HEIGHT) as f64) as i32;
        self.progress_width = PROGRESS_BAR_HEIGHT
            + (self.mpv.position / self.duration
                * (PROGRESS_BAR_WIDTH - PROGRESS_BAR_HEIGHT) as f64) as i32;
    }
}

fn format(secs: f64) -> Format {
    let secs = secs as u32;
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
    env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or("atlas_overlay=info"),
    )
    .init();

    let args = Args::parse();
    if let Some(uuid) = args.uuid {
        thread::spawn(move || keepalive_worker::keepalive(&uuid));
    }

    info!("Connecting to mpv");
    let mut stream = loop {
        match UnixStream::connect("/tmp/mpv") {
            Ok(stream) => break stream,
            Err(_) => {
                thread::sleep(Duration::from_millis(50));
                continue;
            }
        }
    };

    info!("Waiting for file to load");
    mpv_worker::wait_for_event(&stream, "file-loaded");
    info!("File loaded. Waiting for playback");
    send_command(
        vec!["set_property".into(), "pause".into(), false.into()],
        &mut stream,
    )
    .unwrap();
    let mut start = None;
    loop {
        let time = mpv_worker::get_property("time-pos", &mut stream)
            .unwrap()
            .as_f64()
            .unwrap();

        if time == 0.0 {
            continue;
        }

        match start {
            Some(start) => {
                if time >= start + 0.5 {
                    break;
                }
            }
            None => {
                start = Some(time);
            }
        }
        thread::sleep(Duration::from_millis(100));
    }

    info!("Starting overlay");
    let app = RelmApp::new("atlas.overlay").with_args(Vec::new());
    app.set_global_css(include_str!("styles.css"));
    app.run::<App>(AppInit {
        stream: Arc::new(Mutex::new(stream)),
        title: args.title,
    });
    info!("Quitting");
}
