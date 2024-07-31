#!/bin/bash -e

clear
. "$(dirname "$0")/common.sh"
require-server-env
require cargo gnome-terminal killall node sqlx

cleanup() {
	set +e
	killall -CONT frontend
	kill $(jobs -p) "$(cat /tmp/server.pid)"
	exit 0
}
trap cleanup EXIT

. config/server.env
export DATABASE_URL=sqlite:///tmp/atlas.db
export PATH="$PWD/overlay/target/debug:$PWD/services/client:/opt/flutter/bin:$PATH"
export PORT=1400
export RUST_BACKTRACE=1
export SERVER=${SERVER:-http://localhost:$PORT}
export TMDB_KEY

(
	cd overlay
	cargo build
) &

if [[ $SERVER = *localhost* ]]; then
	[[ $1 = --no-frontend ]] && opts=(--wait)
	gnome-terminal "${opts[@]}" -- sh -ec '
		trap read ERR
		echo $$ > /tmp/server.pid
		cd server
		npm i
		npm run build
		DATABASE_URL=postgres://localhost/atlas node --enable-source-maps .
	'
fi

sqlx database create
sqlx migrate run --source=migrations/client
printf %s "$SERVER" > /tmp/server

cd frontend
flutter pub get
flutter run --dart-define={ATLAS_VERSION=DEBUG,LOCAL_PATH=/tmp}
