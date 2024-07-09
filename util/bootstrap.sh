#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

cp "$0" /tmp

# cd to source root.
cd "$(readlink -f -- "$(dirname -- "$0")/..")"

if ! grep -q ' hypervisor ' /proc/cpuinfo; then
	echo You must run this inside a Debian 12 VM.
fi
echo WARNING: This script will erase everything. Press enter to continue.
read -r

if [[ ! -f env/client.env ]]; then
	echo "Don't forget to copy your env file."
	exit 1
fi

set -x

# Install systemd-boot
rm -rf /boot/efi/*
apt-get purge -y grub2-common
apt-get autoremove -y
rm -rf /boot/grub
apt-get install -y systemd-boot
# sed -i '/^options/ s/$/ quiet splash vt.cur_default=1/' /boot/efi/loader/entries/*.conf

# Install build dependencies.
cd
apt-get install -y clang cmake curl libgtk-3-dev libgtk-4-dev ninja-build pkg-config
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz | tar xJof -
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile=minimal --no-modify-path
export PATH=$HOME/flutter/bin:$HOME/.cargo/bin:$PATH
cd -

# Install frontend.
cd frontend
flutter doctor
flutter pub get
flutter build linux --dart-define=ATLAS_VERSION=0.0.0 --release -v
pwd
mv build/linux/*/release/bundle /opt/frontend
cd ..

# Install overlay.
cd overlay
cargo build --release
mv target/release/atlas-overlay /usr/local/bin
cd ..

# Install services.
cp services/*.sh /usr/local/bin
cp services/*.service /etc/systemd/system

# Install configuration files.
cp env/client.env /opt/frontend/env

# Wipe home.
mv config/weston.ini /tmp
cd
find /root -mindepth 1 -delete
mkdir /root/.config
mv /tmp/weston.ini /root/.config

# Remove system packages
apt-get remove -y apt-utils bash-completion bind9-dnsutils bind9-host bzip2 clang cmake cron \
	cron-daemon-common curl debian-faq discover dmidecode doc-debian eject fdisk git gpgv \
	groff-base iamerican ibritish inetutils-telnet inetutils-telnet installation-report \
	iputils-ping keyboard-configuration krb5-locales laptop-detect less libgtk-3-dev libgtk-4-dev \
	logrotate lsof manpages netbase util-linux-locales netcat-traditional nftables ninja-build \
	openssh-client os-prober pciutils perl pkg-config qemu-guest-agent tasksel traceroute usbutils \
	vim-common wamerican wget whiptail xz-utils

# Install runtime dependencies.
apt-get install -y evtest libgtk-3-0 libgtk-4-1 firmware-iwlwifi mpv network-manager strace weston \
	yt-dlp
apt-get autoremove -y

# Enable/disable services
systemctl daemon-reload
systemctl disable apparmor dpkg-db-backup.timer fstrim.timer getty@tty1 ModemManager \
	remote-fs.target
systemctl enable NetworkManager weston frontend resetd

# Remove essential packages
apt-get --allow-remove-essential purge -y bsdutils debconf-i18n e2fsprogs gzip hostname \
	ncurses-base ncurses-bin apt

# Clean file system
ln -sf /bin/busybox /bin/rm
shopt -s extglob
rm -rf /!(bin|boot|dev|etc|lib*|opt|proc|root|run|sbin|sys|tmp|usr|var)
rm -rf /etc/!(NetworkManager|alternatives|ca-certificates*|dbus*|dconf|default|dhcp|fonts|gl*|group|host*|ifplugd|iproute2|libnl*|local*|machine-id|magic*|mime*|net*|pam*|passwd|resolv.conf|security|services|*shadow|shells|ssl|sys*|timezone|udev|vulkan|wpa*|*tab)
rm -rf /etc/alternatives/!(*.so*)
rm -rf /usr/!(bin|lib*|local|sbin|share)
rm -rf /usr/bin/!(bash|busybox|dbus*|evtest|file|find|journalctl|kmod|ldd|login*|mount|mpv|nmcli|python*|rm|run-parts|strace|su|system*|udev*|weston|wpa*|yt-dlp)
rm -rf /usr/lib/!(NetworkManager|dbus*|file|firmware|ifupdown|locale|mime|modules|pam.d|python*|systemd|udev|*-linux-gnu)
rm -rf /usr/lib/*/{avahi,bluetooth,perl*}
rm -rf /usr/lib/python*/apt*
rm -rf /usr/sbin/!(NetworkManager|agetty|dhc*|fsck|getty|if*|init|ip|iucode*|mod*|pam*|reboot|sulogin|wpa*)
rm -rf /usr/share/!(X11|alsa|ca-certificates|common-licenses|dbus*|dns|dri*|ffmpeg|file|font*|gl*|icons|libdrm|locale|mime|misc|pam*|systemd|vulkan|weston|zoneinfo)
rm -rf /usr/share/X11/!(xkb)
rm -rf /usr/share/icons/!(Adwaita)
rm -rf /usr/share/icons/Adwaita/!(icon-theme.cache|scalable)
rm -rf /var/!(lib|local|lock|run|tmp)
rm -rf /var/lib/!(dbus|dhcp|NetworkManager|pam|systemd)

# Install busybox
# Here, we replace coreutil's mount with BusyBox's, which defaults to readonly
for cmd in $(busybox --list); do
	busybox which "$cmd" > /dev/null || busybox ln -s /bin/busybox "/bin/$cmd"
done

# Remove unused libraries
scanned=()

hasItem() {
	local e test=$1
	# Shift parameters to left, replacing $1 with first array element
	shift
	# Iterate through remaining parameters
	for e; do [[ "$e" = "$test" ]] && return 0; done
	return 1
}

scan() {
	hasItem "$1" "${scanned[@]}" && return 0
	scanned+=("$1")

	echo Scanning "$1"
	while read -r object; do
		[[ "$object" = /* ]] || continue
		# Sometimes ldd returns ../../ in paths
		scan "$(readlink -f "$object")"
	done < <(ldd "$1" | sed -E -e '/^[^\t]/ d' -e 's/\t|.* => | \(.*//g')
}

# Cannot use pipe because scan must not run in subshell
while read -r file; do
	file "$file" | grep -q ": ELF" || continue
	scan "$file"
done < <((
	find / -type f -executable -not -path '/usr/lib/*' &
	find /usr/lib/{systemd,udev} -type f -executable &
	wait
) 2> /dev/null)

find /usr/lib -type f -regextype awk -regex '.*\.so(\.|$).*' |
grep -ivE '\/dri\/|mesa|NetworkManager|pam|weston|vdpau|vk|vulk' |
grep -ivE 'libdrm|libedit|libelf|libgl|libllvm|libpciaccess|libsensors|libxcb|libxshm|libz3' |
while read -r object; do
	object=$(readlink -f "$object")
	hasItem "$object" "${scanned[@]}" || (
		mkdir -p "/root/$(dirname "$object")"
		mv "$object" "/root/$object"
	)
done

rm -rf /usr/bin/{file,ldd} /usr/lib/{file,mime} /usr/share/{file,misc} /tmp/*
ln -sf /bin/busybox /bin/find

echo Success
