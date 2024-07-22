#!/bin/bash -e

if [[ ! $2 ]]; then
	echo "Usage: $0 <img> <dev>" 1>&2
	exit 1
fi
set -x

dd if="$1" of="$2" bs=64K status=progress
sgdisk -e "$2"
sgdisk -n 0:1GiB:0 -t 0:8300 -c local "$2"
if [[ ! $(lsblk --noheadings -o FSTYPE "${2}p3") ]]; then
	mkfs.ext4 "${2}p3"
fi
mount "${2}p3" /mnt
mkdir -pm700 /mnt/system-connections
umount /mnt
echo Success
