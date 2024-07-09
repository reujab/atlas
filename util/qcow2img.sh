#!/bin/bash -ex

# Derived from https://github.com/Drewsif/PiShrink
# Patched to work with GPT partition tables

# Ensure scripts return English
export LANGUAGE=POSIX
export LC_ALL=POSIX
export LANG=POSIX

sudo true

# Convert qcow2 to raw data
img=${2:-atlas.img}
qemu-img convert "$1" "$img"

checkFilesystem() {
	code=0

	sudo e2fsck -pf "$loopback" || code=$?
	(( code < 4 )) && return

	echo Trying to recover corrupted filesystem
	sudo e2fsck -y "$loopback" || code=$?
	(( code < 4 )) && return

	exit 1
}

cleanup() {
	if losetup "$loopback" &>/dev/null; then
		sudo losetup -d "$loopback"
	fi
	trap - EXIT
}
trap cleanup EXIT

# Gather info.
size_before=$(ls -lh "$img" | cut -d' ' -f5)
last_part=$(parted -ms "$img" unit B print | tail -n1)
part_num=$(echo "$last_part" | cut -d: -f1)
part_start_b=$(echo "$last_part" | cut -d: -f2 | tr -d B)
loopback=$(sudo losetup -f --show -o "$part_start_b" "$img")
loopback_base=$(basename "$loopback")
sector_size=$(cat "/sys/block/$loopback_base/queue/hw_sector_size")
tune2fs_output="$(sudo tune2fs -l "$loopback")"
fs_block_count="$(echo "$tune2fs_output" | grep '^Block count:' | tr -d ' ' | cut -d: -f2)"
fs_block_size="$(echo "$tune2fs_output" | grep '^Block size:' | tr -d ' ' | cut -d: -f2)"

# Defrag filesystem.
checkFilesystem
mnt=$(mktemp -d)
sudo mount "$loopback" "$mnt"
sudo e4defrag "$mnt"
sudo umount "$mnt"
rmdir "$mnt"

# Shrink filesystem.
fs_min_block_count=$(sudo resize2fs -P "$loopback" | cut -d: -f2 | tr -d ' ')
(( fs_block_count <= fs_min_block_count )) && exit 1
checkFilesystem
sudo resize2fs -p "$loopback" "$fs_min_block_count"
cleanup

# Shrink partition.
part_new_size_b=$((fs_min_block_count * fs_block_size))
part_new_end_b=$((part_start_b + part_new_size_b))
parted -s -a minimal "$img" rm "$part_num"
parted -s "$img" unit B mkpart primary "$part_start_b" "$part_new_end_b"

# Shrink partition table.
part_new_end_s=$((part_new_end_b / sector_size))
part_table_start_s=$((part_new_end_s + 1))
# Add 34 sectors rather than 31 to make room for new backup header.
part_table_end_s=$((part_table_start_s + 34))
part_table_end_b=$((part_table_end_s * sector_size))
sgdisk -k "$part_table_start_s" "$img"

# Truncate image.
truncate -s "$part_table_end_b" "$img"

# Readd backup header.
sgdisk -e "$img"

# Compress image
zstd --rm "$img"

size_after=$(ls -lh "$img.zst" | cut -d' ' -f5)
echo "Shrunk $img from $size_before to $size_after"
