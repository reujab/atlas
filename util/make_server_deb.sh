#!/bin/bash -e

# Set $out before changing directory.
out=$PWD

. "$(dirname "$0")/common.sh"
usage
require cargo dpkg-deb npm sqlx

cd server
npm install
npm run build
npm install --omit=dev
cd ..

cd tmdbd
cargo build --release
cd ..

build=$(mkdir -p ~/.cache && mktemp -dp ~/.cache)
trap 'rm -rf "$build"' EXIT

mkdir -p "$build/etc/nginx/sites-enabled"
mkdir -p "$build/usr/bin"
mkdir -p "$build/usr/lib/atlas"
mkdir -p "$build/usr/lib/systemd/system"
mkdir -p "$build/usr/share/atlas"
mkdir -p "$build/usr/share/nodejs"

cp -r config/DEBIAN "$build"
cp config/server.env.default "$build/etc/atlas.env"
cp config/nginx.conf "$build/etc/nginx/sites-enabled/atlas"
cp tmdbd/target/release/tmdbd "$build/usr/bin"
cp -r migrations/server "$build/usr/share/atlas/migrations"
cp config/nginx.conf "$build/usr/share/atlas/nginx.conf.template"
cp "$(which sqlx)" "$build/usr/lib/atlas"
cp services/server/*.service "$build/usr/lib/systemd/system"
cp -r server/dist "$build/usr/share/nodejs/atlas-server"
cp -r server/node_modules "$build/usr/share/nodejs/atlas-server"

dpkg-deb --build "$build" "$out"

cd server
npm i
