#!/bin/bash

export WAYLAND_DISPLAY=wayland-99

rm -f $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY*

ubuntu-frame &

until [[ -S $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ]]; do
	true
done

atlas-frontend --enable-features=UseOzonePlatform --ozone-platform=wayland
