#!/bin/bash

# This script runs commands in parallel and kills all of them if one exits.

# Kill all jobs on exit
cleanup() {
	killall -CONT frontend
	kill -9 $(jobs -p) 2> /dev/null
}
trap cleanup EXIT

# Run commands
cmd=()
pids=()
for arg in "$@"; do
	if [[ $arg = --- ]]; then
		"${cmd[@]}" &
		pids+=($!)
		cmd=()
	else
		cmd+=("$arg")
	fi
done
sleep 0

# Wait for at least one job to finish
while true; do
	for pid in "${pids[@]}"; do
		if [[ ! -d /proc/$pid ]]; then
			# Exit with child's exit code
			wait "$pid"
			exit $?
		fi
	done
	sleep 0.5
done
