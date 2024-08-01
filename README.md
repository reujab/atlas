# Atlas (WIP)

Atlas is a Linux distribution and application that allows users to browse and watch movies and television series on their TV. The client is designed to run on a low-power computer and connect to a TV via HDMI. The client must be controlled using a USB remote (or keyboard); mouse mode will not be implemented any time soon.

[![Demo Video](https://github.com/user-attachments/assets/b1f202c6-6a03-48d8-bcb9-9cbae029c5e8)](https://youtu.be/6ZaPexEaSco)

## Features

- Browse, search, and watch movies and TV series
- Watch trailers
- Subtitles
- Add titles to "My list"
- Configure Wi-Fi network and audio device
- USB remote support (Rii MX3)

## Testing

If you'd like to test Atlas without installing anything, you can simply run two scripts.

```sh
git clone --depth=1 https://github.com/reujab/atlas
atlas/util/setup_dev_env.sh
atlas/util/debug.sh
```

## Installing

Atlas consists of a server and a client. They can be theoretically be installed on the same system, but for lower power systems such as the Raspberry Pi, this is not recommended.

### Installing the server

Downloads will eventually be available [here](https://github.com/reujab/atlas/releases), but building your own .deb file is easy.

```sh
sudo apt install cargo npm
cargo install sqlx-cli
export PATH=~/.cargo/bin:$PATH

git clone --depth=1 https://github.com/reujab/atlas
atlas/util/make_server_deb.sh ~/Downloads

# Skip to this step if you downloaded the .deb file.
sudo dpkg -i ~/Downloads/atlas-server_*_amd64.deb
sudo apt install -f
```

### Configuring the server

Edit /etc/atlas.env and set TMDB_KEY to an API key for [The Movie Database](https://developer.themoviedb.org/docs/getting-started), then start atlas-server and tmdbd.

```sh
vi /etc/atlas.env
sudo systemctl start atlas-server tmdbd
sudo systemctl enable atlas-server tmdbd
```

This will start populating the database with titles. Be patient; the server won't be ready for a couple of hours.

If you enabled nginx support while installing, be sure to install nginx: `sudo apt install nginx`.

### Installing the client

Currently, only building an image for an EFI target is supported. This means it won’t work for Raspberry Pis, but support is planned.

:warning: **WARNING:** Installing systemd-boot will replace grub with systemd-boot on your host system, but `bootctl` is required to install the bootloader on the image. This step can be done in a chroot or virtual machine to avoid interfering with the host system's bootloader.

```sh
sudo apt install debootstrap gdisk rsync squashfs-tools systemd-boot
atlas/util/make_img.sh ~/Downloads/atlas.img
```

Copy the image as well as atlas/util/flash.sh to a flash drive, boot into a live environment, and run

```sh
/mnt/flash.sh /mnt/atlas.img <device e.g. /dev/sda>
```

Congratulations, Atlas is now installed.

## Roadmap

- Client updating
- Raspberry Pi/general ARM support
- Localization
- Upgrade dependencies
- Factory reset
- Setting to normalize volume
- Search for subtitles when none are available
- Auto-play next episode
- Buffering animation
- Volume indicator
- "More like this"/"Recommended"
- Screensaver
- Mouse mode
