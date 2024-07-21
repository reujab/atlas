#!/bin/bash -ex

# configure environment
# shellcheck disable=1090
. ~/.env

# install dependencies
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs git libssl-dev postgresql nginx htop certbot

# configure swap file
if [[ ! -e /swap ]]; then
	fallocate -l 1G /swap
	mkswap /swap
	swapon /swap
	echo /swap none sw 0 0 >> /etc/fstab
fi

# configure atlas user
if ! grep atlas /etc/passwd; then
	adduser --disabled-password --gecos "" atlas
	mkdir -p /home/atlas/.ssh
	cp ~/.ssh/authorized_keys /home/atlas/.ssh
	chown -R atlas:atlas /home/atlas/.ssh
fi

# configure postgres
sed -i 's/md5/trust/g' /etc/postgresql/*/main/pg_hba.conf
su postgres <<< createuser -s atlas

# install server
su atlas << EOF
cd
git clone https://github.com/reujab/atlas
createdb atlas
psql -f migrations/server/*
cd atlas/server
npm i
npm run build
EOF

# start services
cp /home/atlas/{server/atlas-server.service,tmdbd/tmdbd.service} /etc/systemd/system
systemctl daemon-reload
systemctl enable atlas-server tmdbd
systemctl start atlas-server tmdbd

cat > /etc/nginx/sites-enabled/default << EOF
server {
	server_name http;

	listen 80 default_server;
	listen [::]:80 default_server;

	location / {
		return 301 https://\$host\$request_uri;
	}
}

server {
	server_name https;

	listen 443 ssl http2 default_server;
	listen [::]:443 ssl http2 default_server;

	ssl_certificate		/etc/letsencrypt/live/*/fullchain.pem;
	ssl_certificate_key		/etc/letsencrypt/live/*/privkey.pem;

	location / {
		proxy_pass http://127.0.0.1:8000;
	}
}
EOF

# TODO: configure sshd

echo Success
