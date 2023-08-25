#!/bin/bash -e
. /snap/atlas/current/.env
export IP="$SEEDBOX_HOST"

version=$(</snap/atlas/current/VERSION)
echo Current version: "$version"

new_version=$(curl -s "$IP/update/version")
echo Latest version: "$new_version"

if [[ $version = $new_version ]]; then
	echo Up to date
	exit 0
fi

echo Updating
curl -s "$IP/update/update.sh" | bash -ex && echo Success
