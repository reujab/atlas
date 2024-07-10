#!/bin/bash

# Create image
img=${2:-atlas.img}
fallocate -l5G "$img"

# Create partition table
sgdisk -o "$img"

# Create ESP
esp_start=$(sgdisk -f)
esp_end=$((part1_start + 64*1024*1024))
sgdisk -n "1:$esp_start:$esp_end"
sgdisk -t 1:C12A7328-F81F-11D2-BA4B-00A0C93EC93B

# Create squashed root fs
mksquashfs "$1" root.sqfs
sqfs_bytes=$(wc -c < root.sqfs)
sector_size=512
root_start=$((esp_end+1))
root_end=$((sqfs_bytes/sector_size + 1))
sgdisk -n 1:$root_start:$root_end
