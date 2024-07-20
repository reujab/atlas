#!/bin/bash

for input in /dev/input/event*; do
	base=$(basename "$input")
	grep "Receiver Consumer Control" "/sys/class/input/$base/device/name" && break
done

while read -r event; do
	[[ $event != Event:*KEY_HOMEPAGE* ]] && continue
	if [[ $event == *"value 1"* ]]; then
		down=$(date +%s)
	elif (($(date +%s) - down > 1)); then
		systemctl restart weston frontend
	fi
done < <(evtest "$input")
