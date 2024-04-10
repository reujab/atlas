#!/bin/bash

if [[ ! "$1" ]]; then
	echo "Usage: push_server.sh <IP>"
	exit 1
fi
set -ex

src=$(readlink -f -- "$(dirname -- "$0")/..")

rsync -av -- "$src/server/src/" "atlas@$1:atlas/server/src/"
# Run build script, restart, and invalidate magnet cache
ssh "root@$1" "/home/atlas/atlas/util/update_server.sh && psql atlas -c 'DELETE FROM magnets'"
echo Success
