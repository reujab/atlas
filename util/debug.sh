#!/bin/bash -ex

clear

src=$(readlink -f -- "$(dirname -- "$0")/..")
dev=$(readlink -f -- "$src/../atlas.dev")

cleanup() {
	killall -CONT frontend || true
	# `killall` cannot be used because it does not find `dart` where pidof does
	# shellcheck disable=2046
	kill $(pidof mpv) $(pidof dart) $(pidof cargo) || true
	exit 0
}
trap cleanup EXIT

# Copy source files to new directory to prevent conflict with Snapcraft build.
rsync -av --delete --exclude={node_modules,target,dist,build,.dart_tool,ephemeral,.git}/ -- "$src/" "$dev/"

cd "$dev"

# Set variables.
# shellcheck disable=1091
. server.env
export TMDB_KEY
export SERVER=http://localhost:8000
export AUDIO_DEVICE=alsa
export DATABASE_URL=postgres://localhost/atlas
export PORT=8000
export RUST_BACKTRACE=1
export PATH="$dev/overlay/target/debug:$PATH"

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
