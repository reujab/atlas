#!/bin/bash -e
set -o pipefail

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
	sudo umount root/boot/efi || true
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

# Bootstrap Debian 13.
# sudo debootstrap trixie root
	sudo cp -a ~/Downloads/trixie/ root/

# Create image.
if [[ $ATLAS_FS = ext ]]; then
	image_size=3G
else
	image_size=1G
fi
fallocate -l$image_size atlas.img

# Create partition table.
sgdisk -o atlas.img

# Create partitions.
sgdisk -n 0:0:+64MiB -t 0:ef00 -c 0:esp atlas.img

# Create loopback.
loopback=$(sudo losetup -fP --show atlas.img)

# Create filesystems.
sudo mkfs.fat "${loopback}p1"

# Mount filesystems.
sudo mount -t proc proc root/proc
sudo mount --rbind --make-rslave /sys root/sys
sudo mount --rbind --make-rslave /dev root/dev
sudo mkdir -p root/boot/efi
sudo mount "${loopback}p1" root/boot/efi

# Copy source code.
sudo rsync -a --exclude={.dart_tool,.git,build,node_modules,target} "$src/" root/root/atlas/

# Install Atlas.
sudo chroot root bash -e << EOF
ATLAS_DEBUG=$ATLAS_DEBUG ATLAS_FS=$ALTAS_FS BOOTSTRAP=1 ~/atlas/util/bootstrap.sh
EOF

unmount-filesystems

# Add root partition.
if [[ $ATLAS_FS = ext ]]; then
	# Make writable ext4 rootfs.
	sgdisk -n 0:0:+2GiB -t 0:8304 -c 0:root atlas.img
	sudo partprobe "$loopback"
	sudo mkfs.ext4 -F "${loopback}p2"
	mkdir -p mnt
	sudo mount "${loopback}p2" mnt
	sudo cp -a root/ mnt/
	sudo umount mnt
else
	# Make readonly squashfs root.
	sudo mksquashfs root root.sqfs
	sqfs_size_b=$(wc -c < root.sqfs)
	sqfs_size_kib=$(((sqfs_size_b+1023)/1024))
	sgdisk -n 0:0:+${sqfs_size_kib}KiB -t 0:8304 -c 0:root atlas.img
	sudo partprobe "$loopback"
	if [[ ! -e "${loopback}p2" ]]; then
		echo "${loopback}p2 does not exist after partprobe." 1>&2
		exit 1
	fi
	sudo dd if=root.sqfs of="${loopback}p2" bs=64K status=progress
fi

# Shrink partition table.
backup_header_size_s=34
sector_size=512
next_free_block=$(sgdisk -f atlas.img)
if [[ $next_free_block = "$backup_header_size_s" ]]; then
	echo Next free block is primary GPT header. Has the file already been truncated? 1>&2
	exit 1
fi
backup_header_start_s=$next_free_block
backup_header_end_s=$((backup_header_start_s + backup_header_size_s))
backup_header_end_b=$((backup_header_end_s * sector_size))
sgdisk -k "$backup_header_start_s" atlas.img

# Truncate image.
truncate -s "$backup_header_end_b" atlas.img

# Readd backup header.
sgdisk -e atlas.img

# Install bootloader.
sudo bootctl install --image=atlas.img || {
	sudo mkdir root/efi
	sudo mount "${loopback}p1" root/efi
	sudo bootctl install --root=root --no-variables
	sudo umount root/efi
}

mv atlas.img "$1"

sudo rm -rf "$tmp"

cleanup
trap - EXIT

echo Success
