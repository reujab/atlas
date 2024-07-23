#!/bin/bash -e

reqd_cmds=(cargo psql sqlx)
for cmd in "${reqd_cmds[@]}"; do
	which "$cmd" &> /dev/null || missing_cmds+=("$cmd")
done
if (( ${#missing_cmds[@]} )); then
	echo Missing tools: "${missing_cmds[@]}" 1>&2
	exit 1
fi
set -x

if ! pidof postgres > /dev/null; then
	echo PostgresQL must be running. 1>&2
	exit 1
fi

db=postgres://localhost/atlas

cd "$(readlink -f -- "$(dirname -- "$0")/..")"

if ! sudo test -d /var/lib/postgres/data; then
	sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data
	sudo -u postgres createuser -s "$USER"
fi

createdb atlas || true

psql atlas -f migrations/alter_system.sql
DATABASE_URL=$db sqlx migrate run --source=migrations/server

if [[ ! -d /opt/flutter ]]; then
	curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz |
	sudo tar xJ -C/opt
fi

. config/server.env
export TMDB_KEY
cd tmdbd
DATABASE_URL=$db cargo run

