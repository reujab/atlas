#! /bin/sh

. $SNAP/.env
export SERVER AUDIO_DEVICE

exec frontend
