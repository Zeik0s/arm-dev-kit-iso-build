#! /bin/bash

# Inside the livecd environment

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# set the hostname
echo "ubuntu-aarch64-live" > /etc/hostname

# create apt source list
cat <<EOF > /etc/apt/sources.list
deb http://ports.ubuntu.com/ubuntu-ports/ $RELEASE main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $RELEASE-security main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $RELEASE-updates main restricted universe multiverse
EOF

# update package list
apt-get update

apt-get -yq install \
    apt-utils \
    libterm-readline-gnu-perl \
    systemd-sysv

# machine-id and dpkg divert
dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id

dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# upgrade packages
apt-get -yq upgrade

# install necessary packages
apt-get -yq install \
    sudo \
    ubuntu-standard \
    casper \
    discover \
    laptop-detect \
    os-prober \
    network-manager \
    resolvconf \
    net-tools \
    wireless-tools \
    wpagui \
    locales \

# install gui frontend
apt-get -yq install \
   ubiquity \
   ubiquity-casper \
   ubiquity-frontend-gtk \
   ubiquity-slideshow-ubuntu \
   ubiquity-ubuntu-artwork

# set keyboard layout
cat <<EOF > /etc/default/keyboard
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
EOF

# setup console
cat <<EOF > /etc/default/console-setup
# CONFIGURATION FILE FOR SETUPCON

# Consult the console-setup(5) manual page.

ACTIVE_CONSOLES="/dev/tty[1-6]"

CHARMAP="UTF-8"

CODESET="guess"
FONTFACE="Fixed"
FONTSIZE="8x16"

VIDEOMODE=

# The following is an example how to use a braille font
# FONT='lat9w-08.psf.gz brl-8x8.psf'
EOF

# set locale
cat <<EOF > /etc/default/locale
#  File generated by update-locale
LANG="en_US.UTF-8"
EOF

# reconfigure network-manager
dpkg-reconfigure network-manager

# install everything else
apt-get -yq install \
    ubuntu-gnome-desktop \
    ubuntu-gnome-wallpapers \
    clamav-daemon \
    apt-transport-https \
    curl \
    vim \
    htop \
    lm-sensors \
    neofetch \
    chromium-browser \
    less \
    gdisk \
    gparted

# install chromium snap
snap install chromium

# install linux-firmware so we have sc8280xp platform firmware
apt-get -yq install linux-firmware

# copy required modules and hook to copy platform firmware to initramfs-tools
cp /modules_x13s /etc/initramfs-tools/modules
cp /qcom-soc-firmware /etc/initramfs-tools/hooks/

# install kernel copied from earlier
# install aarch64-laptops packages for Qualcomm platforms
dpkg -i /*.deb

# basic resolvconf
cat <<EOF > /etc/resolv.conf
nameserver 8.8.4.4
EOF

# configure network-manager
cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq

[ifupdown]
managed=false
EOF

# Enable unlock script for modem
ln -s /usr/share/ModemManager/fcc-unlock.available.d/105b /etc/ModemManager/fcc-unlock.d/105b

# clean up
apt-get -yq autoremove

cat /dev/null > /etc/machine-id

rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

apt-get clean

umount /dev/pts
umount /sys
umount /proc

printf "exiting chroot\n"

# exit the chroot environment
exit
