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

make_server=${SERVER+0}
make_server=${make_server:-1}

. config/server.env
. config/client.env
export AUDIO_DEVICE=alsa
export GOOGLE_LOCATION_KEY
export PATH="$PWD/overlay/target/debug:$PWD/services:/opt/flutter/bin:$PATH"
export PORT=8000
export RUST_BACKTRACE=1
export SERVER=${SERVER:-http://localhost:$PORT}
export TMDB_KEY

(
	cd overlay
	cargo build
) &

if [[ "$1" != "--no-frontend" ]]; then
	export DATABASE_URL=sqlite:///tmp/atlas.db
	sqlx database create
	sqlx migrate run --source=migrations/client
	if [[ $make_server = 0 ]]; then
		cd frontend
		flutter pub get
		flutter run
		exit $?
	fi

	gnome-terminal -- sh -c "cd frontend && flutter pub get && flutter run || read"
fi

# Compile and launch server.
cd server
npm i
npm run build
DATABASE_URL=postgres://localhost/atlas node --enable-source-maps .
