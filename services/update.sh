#!/bin/bash

# Because root is already mounted readonly, it should be safe to:
# 1. Unmount /boot/efi, /boot, and /var/local
# 2. Copy essential tools (bash, dd, libs, ...) to /dev/shm/root
# 3. chroot and flash the drive (or just partition)
# 4. Trigger an immediate reboot with `echo b > /proc/sysrq-trigger`
# TODO: test

# Unmount writable file systems
umount -R /boot
umount /var/local

live_env=/dev/shm/root
files=(/bin/busybox /bin/dd /bin/sync /lib/libc.so.6 /lib64/ld-linux-x86-64.so.2)
for file in "${files[@]}"; do
	dir=$(dirname "$file")
	mkdir -p "$live_env$dir"
	cp {,$live_env}"$file"
done

root_dev=$(findmnt --raw -o TARGET,SOURCE | grep '/ ' | cut -d' ' -f2)
chroot $live_env busybox sh << EOF
dd if=atlas.img of=$root_dev
sync
EOF

echo b > /proc/sysrq-trigger
