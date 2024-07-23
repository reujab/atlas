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

. config/server.env
. config/client.env
export AUDIO_DEVICE=alsa
export GOOGLE_LOCATION_KEY
export PATH="$PWD/overlay/target/debug:$PWD/services:/opt/flutter/bin:$PATH"
export PORT=8000
export RUST_BACKTRACE=1
export SERVER=http://localhost:8000
export TMDB_KEY

(
	cd overlay
	cargo build
) &

if [[ "$1" != "--no-frontend" ]]; then
	export DATABASE_URL=sqlite:///tmp/atlas.db
	sqlx database create
	sqlx migrate run --source=migrations/client
	gnome-terminal -- sh -c "cd frontend && flutter pub get && flutter run"
fi

# Compile and launch server.
cd server
npm i
npm run build
DATABASE_URL=postgres://localhost/atlas node --enable-source-maps .
