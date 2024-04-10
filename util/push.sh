#!/bin/bash

if [[ ! "$1" ]]; then
	echo "Usage: push.sh <IP>"
	exit 1
fi
set -ex

if ! systemctl is-active --quiet snapd; then
	sudo systemctl start snapd
fi

src=$(readlink -f -- "$(dirname -- "$0")/..")
root="root@$1"

cd "$src"
rm atlas*.snap
snapcraft -v --debug
scp atlas*.snap "$root:atlas.snap"
ssh "$root" "snap install --dangerous atlas.snap && systemctl restart snap.ubuntu-frame.daemon snap.atlas.frontend"
echo Success
