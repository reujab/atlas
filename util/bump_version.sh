#!/bin/bash -e

. "$(dirname "$0")/common.sh"
usage "<new version>"
set -x

git tag "v$1"

sed -i "2 s/ .*/ $1-1/" config/DEBIAN/control
sed -i "s/^\(version:\).*/\1 $1/" frontend/pubspec.yaml
sed -i "s/^\(version =\).*/\1 \"$1\"/" overlay/Cargo.toml tmdbd/Cargo.toml
sed -i 's/^\(\s*"version":\).*/\1 "'"$1"'",/' server/package.json

cd overlay
# This command fails but updates Cargo.lock.
cargo build --lib || true
cd ..

cd tmdbd
cargo build --lib || true
cd ..

cd server
npm i
cd ..
