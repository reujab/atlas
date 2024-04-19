#!/bin/bash -ex

if [[ $UID != 0 ]]; then
	echo This script is intended to be run on the server as root.
fi

su atlas << EOF
cd ~/atlas/server
git pull
npm i
npm run build
EOF

systemctl restart atlas-server
echo Success
