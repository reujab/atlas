#! /bin/sh

. $SNAP/.env
export SEEDBOX_HOST SEEDBOX_KEY AUDIO_DEVICE

exec frontend
