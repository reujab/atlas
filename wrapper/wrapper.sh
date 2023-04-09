#! /bin/sh

if grep -q "Pi 4" /proc/cpuinfo; then
  EXTRAOPTS="--disable-gpu"
fi

. $SNAP/.env
export SEEDBOX_HOST SEEDBOX_KEY AUDIO_DEVICE

exec $SNAP/frontend/frontend \
	--enable-features=UseOzonePlatform \
	--ozone-platform=wayland \
	--disable-dev-shm-usage \
	--enable-wayland-ime \
	--no-sandbox $EXTRAOPTS
