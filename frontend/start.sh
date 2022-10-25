#!/bin/bash

export WAYLAND_DISPLAY=wayland-0
export GTK_USE_PORTAL=0

rm -f $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY*

ubuntu-frame &>> /tmp/atlas.log &

until [[ -S $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ]]; do
	sleep 0.05
done

. ~/.env
export POSTERS_PATH TMDB_KEY

while pidof frame > /dev/null; do
	atlas-frontend --enable-features=UseOzonePlatform --ozone-platform=wayland &>> /tmp/atlas.log
	sleep 1
done
