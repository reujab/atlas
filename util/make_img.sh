#!/bin/bash -e
# set -o pipefail

if [[ -z $1 ]]; then
	echo "Usage: $0 <output>"
	exit 1
fi

reqd_cmds=(bootctl debootstrap sgdisk mkfs.fat mkfs.ext4 rsync mksquashfs)
for cmd in "${reqd_cmds[@]}"; do
	which "$cmd" > /dev/null || missing_cmds+=("$cmd")
done
if (( ${#missing_cmds[@]} )); then
	echo Missing tools: "${missing_cmds[@]}" 2>&1
	exit 1
fi
set -x

unmount-filesystems() {
	sudo umount mnt || true
	sudo umount root/var/local
	sudo umount root/boot/efi
	sudo umount root/boot
	sudo umount -R root/dev
	sudo umount -R root/sys
	sudo umount root/proc
}

cleanup() {
	set +xe
	kill "$sudo_loop_pid"
	unmount-filesystems
	[[ -n $loopback ]] && sudo losetup -d "$loopback"
	sudo rm -rf "$tmp"
}
trap cleanup EXIT

# Make sure sudo doesn't timeout.
(
	set +x
	while true; do
		sleep 60
		sudo true
	done
) &
sudo_loop_pid=$!

src=$(readlink -f -- "$(dirname -- "$0")/..")
tmp=$(mktemp -dp ~/.cache)

cd "$tmp"

# Bootstrap Debian 12.
sudo debootstrap trixie root

# Create image.
fallocate -l8G atlas.img

# Create partition table.
sgdisk -o atlas.img

# Create partitions.
sgdisk -n 0:0:+64MiB -t 0:ef00 -c 0:esp atlas.img
sgdisk -n 0:0:+128MiB -t 0:8300 -c 0:boot atlas.img
sgdisk -n 0:0:+128MiB -t 0:8300 -c 0:local atlas.img

# Create loopback.
loopback=$(sudo losetup -fP --show atlas.img)

# Create filesystems.
sudo mkfs.fat "${loopback}p1"
sudo mkfs.ext4 -F "${loopback}p2"
sudo mkfs.ext4 -F "${loopback}p3"

# Mount filesystems.
sudo mount -t proc proc root/proc
sudo mount --rbind --make-rslave /sys root/sys
sudo mount --rbind --make-rslave /dev root/dev
sudo mount "${loopback}p2" root/boot
sudo mkdir -p root/boot/efi
sudo mount "${loopback}p1" root/boot/efi
sudo mount "${loopback}p3" root/var/local

# Copy source code.
sudo rsync -av --exclude={.dart_tool,.git,build,node_modules,target} "$src/" "root/root/atlas/"

# Install Atlas.
sudo chroot root bash -e << EOF
ATLAS_DEBUG=$ATLAS_DEBUG BOOTSTRAP=1 ~/atlas/util/bootstrap.sh
EOF

unmount-filesystems

# Add root partition.
if [[ $ATLAS_DEBUG = 1 ]]; then
	# Make writable ext4 rootfs.
	sgdisk -n 0:0:+6GiB -t 0:8304 -c 0:root atlas.img
	sudo partprobe "$loopback"
	sudo mkfs.ext4 -F "${loopback}p4"
	mkdir -p mnt
	sudo mount "${loopback}p4" mnt
	sudo rsync -ra root/ mnt/
	sudo umount mnt
else
	# Make readonly squashfs root.
	sudo mksquashfs root root.sqfs
	sqfs_size_b=$(wc -c < root.sqfs)
	sqfs_size_kib=$(((sqfs_size_b+1023)/1024))
	sgdisk -n 0:0:+${sqfs_size_kib}KiB -t 0:8304 -c 0:root atlas.img
	sudo partprobe "$loopback"
	sudo dd if=root.sqfs of="${loopback}p4" bs=64K status=progress
fi

# Shrink partition table.
backup_header_size_s=34
sector_size=512
next_free_block=$(sgdisk -f atlas.img)
backup_header_start_s=$next_free_block
backup_header_end_s=$((backup_header_start_s + backup_header_size_s))
backup_header_end_b=$((backup_header_end_s * sector_size))
sgdisk -k "$backup_header_start_s" atlas.img

# Truncate image.
truncate -s "$backup_header_end_b" atlas.img

# Readd backup header.
sgdisk -e atlas.img

# Install bootloader.
sudo bootctl install --image=atlas.img

mv atlas.img "$1"

sudo rm -rf "$tmp"
