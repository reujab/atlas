#!/bin/bash -ex

if [[ $EUID != 0 ]]; then
	echo This script is intended to be run on the server as root. 1>&2
	exit 1
fi

su atlas << EOF
cd ~/atlas/server
git pull
npm i
npm run build

cd ~/atlas/tmdbd
cargo build --release
EOF

cp /home/atlas/atlas/{server,tmdbd}/*.service /etc/systemd/system
systemctl daemon-reload

systemctl restart atlas-server tmdbd
echo Success
