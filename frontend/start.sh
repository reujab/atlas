#!/bin/bash

export WAYLAND_DISPLAY=wayland-99

rm -f $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY*

ubuntu-frame &

until [[ -S $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ]]; do
	sleep 0.05
done

. ~/.env
export POSTERS_PATH
atlas-frontend --enable-features=UseOzonePlatform --ozone-platform=wayland
