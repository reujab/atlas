set -e

# install dependencies
apt-get install -y unattended-upgrades systemd-timesyncd fontconfig plymouth resolvconf snapd network-manager curl evtest
systemctl start systemd-timesyncd
snap install ubuntu-frame
snap install --dangerous atlas.snap
cp update/update.sh /usr/local/bin
cp update/update.{service,timer} /etc/systemd/system

# configure ntp
systemctl enable systemd-timesyncd
timedatectl set-ntp true

# configure grub
if [[ grep echo /etc/default/grub > /dev/null ]]; then
	sed -i 's/TIMEOUT=5/TIMEOUT=0/g' /etc/default/grub
	sed -i 's/LINUX_DEFAULT=.*/LINUX_DEFAULT="quiet splash vt.cur_default=1"/' /etc/default/grub
	cat >> /etc/default/grub << EOF
GRUB_RECORDFAIL_TIMEOUT=0
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
EOF
	update-grub
	sed -i 's/^\s*echo.*//g' /boot/grub/grub.cfg
fi

# configure plymouth
plymouth-set-default-theme -R tribar

# configure atlas
snap connect atlas:alsa
snap connect atlas:hardware-observe
snap connect atlas:joystick
snap connect atlas:network-manager
snap connect atlas:process-control
snap connect atlas:shutdown
snap connect atlas:wayland

# configure updater
systemctl daemon-reload
systemctl enable update.timer
systemctl start update.timer

# start ubuntu-frame
snap set ubuntu-frame config=vt=1
snap set ubuntu-frame config=cursor=null
snap set ubuntu-frame daemon=true

# start atlas
systemctl enable snap.atlas.frontend
systemctl restart snap.atlas.frontend

# disable tty1
systemctl disable getty@tty1

rm -rf *.snap update
echo Success
