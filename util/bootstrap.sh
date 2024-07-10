#!/bin/bash -e

if ! grep -q ' hypervisor ' /proc/cpuinfo; then
	echo You must run this inside a Debian 12 VM.
fi
echo WARNING: This script will erase everything. Press enter to continue.
read -r

# cd to source root.
cd "$(readlink -f -- "$(dirname -- "$0")/..")"

if [[ ! -f env/client.env ]]; then
	echo "Don't forget to copy your env file."
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$HOME/flutter/bin:$HOME/.cargo/bin:$PATH

shopt -s extglob

# Error handling for concurrent operations
go() {
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

install-bootloader() {
	rm -rf /boot/efi/*
	apt-get purge -y grub2-common
	apt-get autoremove -y
	rm -rf /boot/grub
	apt-get install -y systemd-boot
	if [[ $ATLAS_DEBUG != 1 ]]; then
		sed -i '/^options/ s/$/ quiet splash vt.cur_default=1/' /boot/efi/loader/entries/*.conf
	fi
}

install-services() {
	cp services/*.sh /usr/local/bin
	cp services/*.service /etc/systemd/system
}

install-build-deps() (
	apt-get install -y clang cmake libgtk-3-dev libgtk-4-dev ninja-build pkg-config
)

install-flutter() {
	curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz | tar xJof - -C/root
}

install-rust() { (
	cd
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile=minimal --no-modify-path
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

install-runtime-deps() {
	apt-get remove -y apt-utils bash-completion bind9-dnsutils bind9-host bzip2 clang cmake cron \
		cron-daemon-common curl debian-faq discover dmidecode doc-debian eject fdisk git gpgv \
		groff-base iamerican ibritish inetutils-telnet inetutils-telnet installation-report \
		iputils-ping keyboard-configuration krb5-locales laptop-detect less libgtk-3-dev \
		libgtk-4-dev logrotate lsof manpages netbase util-linux-locales netcat-traditional \
		nftables ninja-build openssh-client os-prober pciutils perl pkg-config qemu-guest-agent \
		tasksel traceroute usbutils vim-common wamerican wget whiptail xz-utils
	apt-get install -y evtest libgtk-3-0 libgtk-4-1 firmware-iwlwifi mpv network-manager weston \
		yt-dlp
	if [[ $ATLAS_DEBUG = 1 ]]; then
		apt-get install -y ssh rsync strace
	fi
	apt-get autoremove -y
}

configure-services() {
	systemctl daemon-reload
	systemctl disable apparmor dpkg-db-backup.timer fstrim.timer getty@tty1 ModemManager \
		remote-fs.target
	systemctl enable NetworkManager weston frontend resetd

	# This logs the root user in on boot, creating the dbus runtime,
	# allowing weston to start on boot.
	loginctl enable-linger root
}

remove-system-packages() {
	[[ $ATLAS_DEBUG = 1 ]] && return
	apt-get --allow-remove-essential purge -y bsdutils debconf-i18n e2fsprogs gzip hostname \
		ncurses-base ncurses-bin apt
}

clean-fs() {
	[[ $ATLAS_DEBUG = 1 ]] && return
	ln -sf /bin/busybox /bin/rm
	rm -rf /!(bin|boot|dev|etc|lib*|opt|proc|root|run|sbin|sys|tmp|usr|var)
	rm -rf /etc/!(NetworkManager|alternatives|ca-certificates*|dbus*|dconf|default|dhcp|fonts|gl*|group|host*|ifplugd|iproute2|libnl*|local*|machine-id|magic*|mime*|net*|pam*|passwd|resolv.conf|security|services|*shadow|shells|ssl|sys*|timezone|udev|vulkan|wpa*|*tab)
	rm -rf /etc/alternatives/!(*.so*)
	rm -rf /usr/!(bin|lib*|local|sbin|share)
	rm -rf /usr/bin/!(bash|busybox|dbus*|evtest|file|find|journalctl|kmod|ldd|login*|mount|mpv|nmcli|python*|rm|run-parts|su|system*|udev*|weston|wpa*|yt-dlp)
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
			if [[ $ATLAS_DEBUG = 0 ]]; then
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

install-bootloader
install-services

apt-get install -y curl
go install-build-deps
go install-flutter
go install-rust
wait

go install-frontend
go install-overlay
wait

install-config
wipe-home
install-runtime-deps
configure-services
remove-system-packages
clean-fs

set +x
install-busybox
remove-unused-libraries

echo Success
