#!/bin/bash -e

if [[ ! $1 ]]; then
	echo "Usage: $0 <img>" 1>&2
	exit 1
fi

truncate -s +128M "$1"
sgdisk -e "$1"
sgdisk -N 0 -t 0:8300 -c 0:local "$1"
loopback=$(sudo losetup -fP --show "$1")
sudo mkfs.ext4 "${loopback}p3"
sudo mount "${loopback}p3" /mnt
sudo mkdir -pm700 /mnt/system-connections
sudo umount /mnt
sudo losetup -d "$loopback"
cd "$(dirname "$1")"
qemu-img convert -O qcow2 "$1" atlas.qcow2
