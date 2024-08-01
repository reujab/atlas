#!/bin/bash -e

. "$(dirname "$0")/common.sh"
usage
require-server-env
require cargo psql sqlx

if ! sudo test -d /var/lib/postgres/data; then
	sudo -u postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data
fi

pidof postgres > /dev/null || sudo systemctl start postgresql

sudo -u postgres createuser -s "$USER" || true

db=postgres://localhost/atlas

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
