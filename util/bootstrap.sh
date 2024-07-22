#!/bin/bash -e
set -o pipefail

if [[ $BOOTSTRAP != 1 ]]; then
	echo Do not run this script manually. 1>&2
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$HOME/flutter/bin:$HOME/.cargo/bin:$PATH

shopt -s dotglob extglob
cd

# Error handling for concurrent operations.
concurrently() { "$@" & pids+=($!); cmds+=("$1"); }
wait() {
	for i in "${!pids[@]}"; do
		echo Waiting for "${cmds[$i]}"
		builtin wait "${pids[$i]}"
	done
	pids=()
	cmds=()
}

add-sources() {
	sed -i '1 s/$/ non-free-firmware/' /etc/apt/sources.list
	apt-get update
}

install-services() {
	cp atlas/services/*.sh /usr/local/bin
	cp atlas/services/*.service /etc/systemd/system
}

install-build-deps() {
	apt-get install -y clang cmake git libgtk-{3,4}-dev ninja-build pkg-config
}

install-flutter() {
	curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz |
	tar xJof -
}

install-rust() {
	curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs |
	sh -s -- -y --profile=minimal --no-modify-path
}

# After install-build-deps, install-flutter
install-frontend() { (
	cd atlas/frontend
	flutter pub get
	flutter build linux --dart-define=ATLAS_VERSION=0.0.0 --release -v
	mv build/linux/*/release/bundle /opt/frontend
) }

# After install-build-deps, install-rust
install-overlay() { (
	cd atlas/overlay
	cargo build --release
	mv target/release/atlas-overlay /usr/local/bin
) }

# After install-rust
install-sqlx() {
	cargo install sqlx-cli
	mv ~/.cargo/bin/sqlx /usr/local/bin
}

# After install-build-deps
install-runtime-deps() {
	apt-get install -y evtest firmware-iwlwifi firmware-linux-free file \
		fonts-{cantarell,noto{,-cjk,-extra}} libgtk-3-0 libgtk-4-1 linux-image-amd64 mpv \
		network-manager weston yt-dlp > /dev/null
	[[ $ATLAS_DEBUG = 1 ]] && apt-get install -y openssh-server strace > /dev/null
	install-dracut
}
install-dracut() {
	apt-get install -y dracut-squash > /dev/null
	kernel=$(ls /lib/modules)
	dracut --add-drivers "button evdev i915 iwlmvm iwlwifi snd_hda_codec_hdmi snd_hda_intel virtio_gpu" \
		--filesystems "ext4 squashfs" --aggressive-strip /boot/efi/initrd.img "$kernel"
}

# After install-frontend
install-config() {
	cp atlas/config/client.env /opt/frontend/env

	cp -r atlas/migrations/client /opt/frontend/migrations

	mkdir -p /etc/xdg/weston
	cp atlas/config/weston.ini /etc/xdg/weston
}

# After install-runtime-deps
remove-packages() {
	extra_pkgs=()
	[[ $ATLAS_DEBUG != 1 ]] && extra_pkgs=(sensible-utils)
	apt-get purge -y --autoremove apt-utils clang cmake cron cron-daemon-common dmidecode \
		dracut-core fdisk git iputils-ping less libgtk-{3,4}-dev lvm2 ninja-build pkg-config \
		logrotate nano nftables tasksel vim-common whiptail "${extra_pkgs[@]}"

	rm -f /var/lib/dpkg/info/{console-setup*,keyboard-configuration}.postrm
	apt-get purge -y --allow-remove-essential --autoremove apt bsdutils debconf-i18n \
		debian-archive-keyring e2fsprogs gpgv grep gzip ncurses-base ncurses-bin perl-base
}

# After remove-packages
configure-system() {
	systemctl daemon-reload
	systemctl enable NetworkManager frontend resetd weston

	# This logs the root user in on boot, creating the dbus runtime, allowing weston to use
	# $XDG_RUNTIME_DIR on boot. This is equivalent to running `loginctl enable-linger root`.
	mkdir -p /var/lib/systemd/linger
	touch /var/lib/systemd/linger/root

	# Configure bootloader.
	mv /boot/vmlinuz* /boot/efi/vmlinuz
	mkdir -p /boot/efi/loader/entries
	cat > /boot/efi/loader/entries/atlas.conf << EOF
title Atlas
options root=PARTLABEL=root quiet splash systemd.gpt_auto=0 vt.cur_default=1
linux /vmlinuz
initrd /initrd.img
EOF
	cat > /etc/fstab << EOF
PARTLABEL=root	/	squashfs	defaults	0 1
PARTLABEL=local	/var/local	ext4	defaults	0 2
EOF

	passwd --stdin <<< atlas

	# Linux will not recognize this as a rootfs without this file.
	# Remove symlink before overwriting.
	rm /etc/os-release
	cat > /etc/os-release << EOF
PRETTY_NAME="Atlas"
NAME="Atlas"
ID=debian
EOF

	[[ $ATLAS_DEBUG = 1 ]] && cat > /etc/ssh/sshd_config << EOF
AuthorizedKeysFile /var/local/authorized_keys
PermitRootLogin yes
EOF

	echo atlas > /etc/hostname

	# Rebuild font cache
	rm -rf /usr/share/fonts/!(opentype|truetype)
	rm -rf /usr/share/fonts/opentype/!(cantarell|noto)
	rm -rf /usr/share/fonts/opentype/noto/!(NotoSansCJK-Regular.ttc)
	rm -rf /usr/share/fonts/truetype/!(noto)
	rm -rf /usr/share/fonts/truetype/noto/!(NotoSansMono-*.ttf)
	fc-cache -fv

	# Rebuild dynamic linker cache
	ldconfig -X
}

# After configure-system
clean-fs() {
	umount /boot/efi
	ln -sf /bin/busybox /bin/rm
	cd /

	rm -rf /!(bin|dev|etc|lib*|opt|proc|run|sbin|sys|tmp|usr|var)
	rm -rf /etc/!(NetworkManager|alternatives|ca-certificates*|dbus*|dconf|default|dhcp|fonts|gl*|group|host*|ifplugd|iproute2|ld.so.cache|libnl*|local*|machine-id|magic*|mime*|net*|os-release|pam*|passwd|resolv.conf|security|services|*shadow|shells|ssh|ssl|sys*|timezone|udev|vulkan|wpa*|xdg|*tab)
	rm -rf /etc/alternatives/!(*.db|*.so*)
	rm -rf /etc/systemd/system/!(multi-user.target.wants|*.service)
	rm -rf /etc/xdg/!(weston)
	rm -rf /usr/!(bin|lib*|local|sbin|share)
	rm -rf /usr/bin/!(bash|busybox|dbus*|evtest|file|find|hostname|journalctl|kmod|ldd|login*|mpv|nmcli|python*|rm|run-parts|strace|su|system*|udev*|weston|wpa*|yt-dlp)
	rm -rf /usr/lib/!(NetworkManager|dbus*|file|firmware|ifupdown|locale|mime|modules|pam.d|python*|systemd|udev|*-linux-gnu)
	rm -rf /usr/lib/systemd/system/{ModemManager,NetworkManager-,apparmor,capsule,crypt,dbus-,dpkg,fstrim,if,initrd,kmod,ldconfig,modprobe,networking,nm,pam,polkit,procps,quota,rc,seatd,system-,systemd-{ask,backlight,battery,binfmt,boot,bsod,confext,creds,firstboot,fsck-root,growfs,hostnamed,hwdb,init,kexec,localed,machine,modules,network,pcr,pstore,quota,random,remount,rfkill,storage,sys,time-wait,tpm,update,volatile},usb_modeswitch,x11}*
	rm -rf /usr/sbin/!(NetworkManager|agetty|dhc*|fsck|getty|if*|init|ip|iucode*|mod*|pam*|reboot|sshd|sulogin|wpa*)
	rm -rf /usr/share/!(X11|alsa|ca-certificates|common-licenses|dbus*|dns|dri*|ffmpeg|file|font*|gl*|icons|libdrm|locale|mime|misc|pam*|systemd|vulkan|weston|zoneinfo)
	rm -rf /usr/share/X11/!(xkb)
	rm -rf /usr/share/icons/!(Adwaita)
	rm -rf /usr/share/icons/Adwaita/!(icon-theme.cache|scalable)
	rm -rf /var/!(lib|local|lock|run|tmp)
	rm -rf /var/lib/!(dbus|dhcp|NetworkManager|pam|systemd)

	# Delete invalid symlinks.
	find / -xdev -xtype l -not '(' -name mtab -or -name locale ')' -delete
}

# After clean-fs
install-busybox() {
	for cmd in $(busybox --list); do
		busybox which "$cmd" > /dev/null || busybox ln -s /bin/busybox "/bin/$cmd"
	done
}

# After clean-fs, install-busybox
persist-files() {
	# Remember network configurations
	rmdir /etc/NetworkManager/system-connections
	ln -s /var/local/system-connections /etc/NetworkManager/

	ln -s /tmp /root
}

# After install-busybox
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
	grep -ivE '\/dri\/|mesa|NetworkManager|pam|python|weston|vdpau|vk|vulk' |
	grep -ivE 'libdrm|libedit|libelf|libgl|libigdgmm|libllvm|libpciaccess|libseat|libsensors|libxcb|libxshm|libz3' |
	while read -r object; do
		object=$(readlink -f "$object")
		hasItem "$object" "${scanned[@]}" || (
			if [[ $ATLAS_FS = ext ]]; then
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
hasItem() {
	local e test=$1
	# Shift parameters to left, replacing $1 with first array element
	shift
	# Iterate through remaining parameters
	for e; do [[ $e = "$test" ]] && return 0; done
	return 1
}

set -x

add-sources
install-services
apt-get install -y curl xz-utils

concurrently install-build-deps
concurrently install-flutter
concurrently install-rust
wait

concurrently install-frontend
concurrently install-overlay
concurrently install-sqlx
concurrently install-runtime-deps
wait

install-config
remove-packages
configure-system
clean-fs

set +x
install-busybox
persist-files
remove-unused-libraries

echo Success
