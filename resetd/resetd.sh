#!/bin/bash

for input in /dev/input/event*; do
	base=$(basename "$input")
	if grep "Receiver Consumer Control" "/sys/class/input/$base/device/name"; then
		break
	fi
done

while read -r event; do
	if [[ "$event" != Event:*KEY_HOMEPAGE* ]]; then
		continue
	fi
	if [[ "$event" == *"value 1"* ]]; then
		down=$(date +%s%3N)
	elif (($(date +%s%3N) - down >= 2000)); then
		systemctl restart snap.ubuntu-frame.daemon snap.atlas.frontend
	fi
done < <(evtest "$input")
