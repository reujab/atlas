# requires debian bookworm

apt install -y \
	dhcpcd5 \
	fonts-cantarell \
	fonts-noto \
	git \
	iptables \
	iw \
	libgtk-4-dev \
	mpv \
	mpv-mpris \
	netctl \
	npm \
	openvpn \
	playerctl \
	plymouth \
	postgresql-14 \
	snapd \
	sudo \
	tor \
	zlib1g:armhf

snap install ubuntu-frame

npm i -g webtorrent-cli

# dpkg -i windscribe.deb
# dpkg -i frontend.deb
# apt -f install

usermod -aG sudo atlas

systemctl start postgresql@14
systemctl enable postgresql@14
systemctl disable snapd
systemctl enable getty@tty1
systemctl enable tor
# systemctl enable windscribe

# edit gett@tty1 to autologin
# edit .bashrc to autostart

sed -i s/scram-sha-256/trust/g /etc/postgresql/*/*/pg_hba.conf
su postgres -c "createuser atlas"
su postgres -c "createdb atlas"

# TODO run migrations

# TODO copy .env

su atlas -c '
mkdir -p ~/posters/{movie,tv}
cat >> ~/.bashrc << EOF
if [[ $(tty) = /dev/tty1 ]]; then
	~/start.sh &> /tmp/atlas.log
fi
EOF
'

# psql -f migrations/init...
