#! /bin/sh

. $SNAP/.env
export SEEDBOX_HOST AUDIO_DEVICE

exec frontend
