#!/bin/bash -e
# shellcheck disable=1091
. /snap/atlas/current/.env

version=$(</snap/atlas/current/VERSION)
echo Current version: "$version"

new_version=$(curl -s "$SERVER/update/version")
echo Latest version: "$new_version"

if [[ $version = "$new_version" ]]; then
	echo Up to date
	exit 0
fi

echo Updating
curl -s "$SERVER/update/update.sh" | bash -ex && echo Success
