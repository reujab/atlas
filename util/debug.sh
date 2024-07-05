#!/bin/bash -ex

clear

cd "$(readlink -f -- "$(dirname -- "$0")/..")"

cleanup() {
	killall -CONT frontend || true
	# `killall` cannot be used because it does not find `dart` where pidof does
	# shellcheck disable=2046
	kill $(pidof mpv) $(pidof dart) $(pidof cargo) || true
	exit 0
}
trap cleanup EXIT

# Set variables.
# shellcheck disable=1091
. env/server.env
# shellcheck disable=1091
. env/client.env
export TMDB_KEY
export SERVER=http://localhost:8000
export AUDIO_DEVICE=alsa
export DATABASE_URL=postgres://localhost/atlas
export PORT=8000
export RUST_BACKTRACE=1
export PATH="$PWD/overlay/target/debug:$PWD/util:$PATH"
export GOOGLE_LOCATION_KEY

# Compile and install overlay.
(
	cd overlay
	cargo build
) &

if [[ "$1" != "--no-frontend" ]]; then
	gnome-terminal -- sh -c "cd frontend && flutter pub get && flutter run"
fi

# Compile and launch server.
cd server
npm i
npm run build
node --enable-source-maps .
