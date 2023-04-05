#!/bin/bash
while read -r event; do
	if [[ "$event" != Event:*KEY_HOMEPAGE* ]]; then
		continue
	fi
	if [[ "$event" == *"value 1"* ]]; then
		down=$(date +%s%3N)
	elif (($(date +%s%3N) - down >= 2000)); then
		systemctl restart snap.ubuntu-frame.daemon snap.atlas.frontend
	fi
done < <(evtest /dev/input/event5)
