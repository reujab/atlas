#!/bin/bash

# Because root is already mounted readonly, it should be safe to:
# 1. Unmount /boot/efi, /boot, and /var/local
# 2. Copy essential tools (bash, dd, libs, ...) to /dev/shm/root
# 3. chroot and flash the drive (or just partition)
# 4. Trigger an immediate reboot with `echo b > /proc/sysrq-trigger`
# TODO: test

umount /var/local

live_env=/dev/shm/root
files=(/bin/{busybox,dd,sync} /lib/lib{c,gcc_s,m,popt,stdc++,resolv,uuid}.so* /lib64/ld-linux-x86-64.so.2)
for file in "${files[@]}"; do
	dir=$(dirname "$file")
	mkdir -p "$live_env$dir"
	cp {,$live_env}"$file"
done

root_dev=$(findmnt --raw -o TARGET,SOURCE | grep '^/ ' | cut -d' ' -f2)
chroot $live_env busybox sh -e << EOF
main() {
	dd if=atlas.img of=$root_dev bs=64K status=progress
	sgdisk -e $root_dev
	sgdisk -n 0:1GiB:0 -t 0:8300 -c 0:local $root_dev
	sync
	echo b > /proc/sysrq-trigger
}
main
EOF
