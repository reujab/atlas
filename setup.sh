set -ex

# install dependencies
apt-get install -y unattended-upgrades systemd-timesyncd fontconfig plymouth resolvconf snapd network-manager curl evtest
systemctl start systemd-timesyncd
snap install ubuntu-frame
cp update/update.sh /usr/local/bin
cp update/update.{service,timer} /etc/systemd/system

# configure ntp
systemctl enable systemd-timesyncd
timedatectl set-ntp true

# configure grub
if grep echo /etc/default/grub > /dev/null; then
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

# configure network manager
systemctl enable NetworkManager
systemctl start NetworkManager

# configure updater
systemctl daemon-reload
systemctl enable update.timer
systemctl start update.timer

# start ubuntu-frame
snap set ubuntu-frame config=vt=1
snap set ubuntu-frame config=cursor=null
snap set ubuntu-frame daemon=true

# disable tty1
systemctl disable getty@tty1

rm -rf *.snap update
echo Success
