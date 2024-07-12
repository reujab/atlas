#!/bin/bash -e
set -o pipefail

if [[ $BOOTSTRAP != 1 ]]; then
	echo Do not run this script manually. 2>&1
	exit 1
fi

# cd to source root.
cd "$(readlink -f -- "$(dirname -- "$0")/..")"

if [[ ! -f env/client.env ]]; then
	echo "Don't forget to copy your env file." 2>&1
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$HOME/flutter/bin:$HOME/.cargo/bin:$PATH

shopt -s extglob

# Error handling for concurrent operations
concurrently() {
	if [[ $ATLAS_DEBUG = 1 ]]; then
		"$@"
		return
	fi
	"$@" & pids+=($!); cmds+=("$1")
}
wait() {
	for i in "${!pids[@]}"; do
		echo Waiting for "${cmds[$i]}"
		builtin wait "${pids[$i]}"
	done
	pids=()
	cmds=()
}

add-sources() {
	sed -i 's/$/ non-free-firmware/' /etc/apt/sources.list
	apt update
}

install-services() {
	cp services/*.sh /usr/local/bin
	cp services/*.service /etc/systemd/system
}

install-build-deps() (
	apt-get install -y busybox clang cmake file git libgtk-3-dev libgtk-4-dev ninja-build \
		pkg-config > /dev/null
)

install-flutter() {
	curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz |
	tar xJof - -C/root
}

install-rust() { (
	cd
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
	sh -s -- -y --profile=minimal --no-modify-path
) }

install-frontend() { (
	cd frontend
	flutter pub get
	flutter build linux --dart-define=ATLAS_VERSION=0.0.0 --release -v
	mv build/linux/*/release/bundle /opt/frontend
) }

install-overlay() { (
	cd overlay
	cargo build --release
	mv target/release/atlas-overlay /usr/local/bin
) }

install-config() {
	cp env/client.env /opt/frontend/env
}

wipe-home() {
	mv config/weston.ini /tmp
	cd
	find /root -mindepth 1 -delete
	mkdir /root/.config
	mv /tmp/weston.ini /root/.config
}

install-dracut() {
	apt-get install -y dracut-squash
	kernel=$(ls /lib/modules)
	dracut --add-drivers virtio_gpu /boot/efi/initrd.img "$kernel"
}

install-runtime-deps() {
	apt-get install -y evtest libgtk-3-0 libgtk-4-1 linux-image-amd64 firmware-iwlwifi mpv \
		network-manager weston yt-dlp
	systemctl disable apparmor dpkg-db-backup.timer fstrim.timer getty@tty1 ModemManager \
		remote-fs.target
	if [[ $ATLAS_DEBUG = 1 ]]; then
		apt-get install -y ssh rsync strace
		return
	fi

	install-dracut

	apt-get purge -y apt-utils clang cmake cron cron-daemon-common dmidecode fdisk git \
		iputils-ping less libgtk-3-dev libgtk-4-dev ninja-build pkg-config logrotate nano nftables \
		sensible-utils tasksel vim-common whiptail
	apt-get autoremove -y

	rm -f /var/lib/dpkg/info/{console-setup,e2fsprogs,keyboard-configuration,sgml-base}*
	apt purge -y --allow-remove-essential apt bsdutils debconf-i18n debian-archive-keyring \
		e2fsprogs gpgv grep gzip ncurses-base ncurses-bin perl-base
}

configure-system() {
	systemctl daemon-reload
	systemctl enable NetworkManager weston frontend resetd

	# This logs the root user in on boot, creating the dbus runtime,
	# allowing weston to start on boot.
	# loginctl enable-linger root
	mkdir -p /var/lib/systemd/linger
	touch /var/lib/systemd/linger/root

	mv /boot/vmlinuz* /boot/efi/vmlinuz
	mkdir -p /boot/efi/loader/entries
	cat > /boot/efi/loader/entries/atlas.conf << EOF
title Atlas
options root=PARTLABEL=root rw loglevel=4
linux /vmlinuz
initrd /initrd.img
EOF
	cat > /etc/fstab << EOF
PARTLABEL=root	/	squashfs	defaults	0 1
PARTLABEL=boot	/boot	ext4	defaults	0 2
PARTLABEL=esp	/boot/efi	vfat	defaults	0 2
PARTLABEL=local	/var/local	ext4	defaults	0 2
EOF

	passwd --stdin <<< atlas

	# Remove symlink before overwriting.
	rm /etc/os-release
	cat > /etc/os-release << EOF
PRETTY_NAME="Atlas"
NAME="Atlas"
ID=debian
EOF
}

clean-fs() {
	[[ $ATLAS_DEBUG = 1 ]] && return
	ln -sf /bin/busybox /bin/rm
	rm -rf /!(bin|boot|dev|etc|lib*|opt|proc|root|run|sbin|sys|tmp|usr|var)
	rm -rf /etc/!(NetworkManager|alternatives|ca-certificates*|dbus*|dconf|default|dhcp|fonts|gl*|group|host*|ifplugd|iproute2|libnl*|local*|machine-id|magic*|mime*|net*|os-release|pam*|passwd|resolv.conf|security|services|*shadow|shells|ssl|sys*|timezone|udev|vulkan|wpa*|*tab)
	rm -rf /etc/alternatives/!(*.so*)
	rm -rf /usr/!(bin|lib*|local|sbin|share)
	rm -rf /usr/bin/!(bash|busybox|dbus*|evtest|file|find|hostname|journalctl|kmod|ldd|login*|mount|mpv|nmcli|python*|rm|run-parts|su|system*|udev*|weston|wpa*|yt-dlp)
	rm -rf /usr/lib/!(NetworkManager|dbus*|file|firmware|ifupdown|locale|mime|modules|pam.d|python*|systemd|udev|*-linux-gnu)
	rm -rf /usr/lib/*/{avahi,bluetooth}
	rm -rf /usr/lib/python*/apt*
	rm -rf /usr/sbin/!(NetworkManager|agetty|dhc*|fsck|getty|if*|init|ip|iucode*|mod*|pam*|reboot|sulogin|wpa*)
	rm -rf /usr/share/!(X11|alsa|ca-certificates|common-licenses|dbus*|dns|dri*|ffmpeg|file|font*|gl*|icons|libdrm|locale|mime|misc|pam*|systemd|vulkan|weston|zoneinfo)
	rm -rf /usr/share/X11/!(xkb)
	rm -rf /usr/share/icons/!(Adwaita)
	rm -rf /usr/share/icons/Adwaita/!(icon-theme.cache|scalable)
	rm -rf /var/!(lib|local|lock|run|tmp)
	rm -rf /var/lib/!(dbus|dhcp|NetworkManager|pam|systemd)
}

# Here, we replace coreutil's mount with BusyBox's, which defaults to readonly
install-busybox() {
	for cmd in $(busybox --list); do
		busybox which "$cmd" > /dev/null || busybox ln -s /bin/busybox "/bin/$cmd"
	done
}

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

remove-unused-libraries() {
	[[ $ATLAS_DEBUG = 1 ]] && return

	scanned=()

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
			if [[ $ATLAS_DEBUG = 1 ]]; then
				mkdir -p "/root/$(dirname "$object")"
				mv "$object" "/root/$object"
			else
				rm "$object"
			fi
		)
	done

	rm -rf /usr/bin/{file,ldd} /usr/lib/{file,mime} /usr/share/{file,misc} /tmp/*
	ln -sf /bin/busybox /bin/find
}

set -x

add-sources
install-services

apt-get install -y curl xz-utils
# concurrently install-build-deps
# concurrently install-flutter
# concurrently install-rust
wait

concurrently install-frontend
concurrently install-overlay
wait

install-config
wipe-home
install-runtime-deps
configure-system
clean-fs

set +x
install-busybox
remove-unused-libraries

echo Success
