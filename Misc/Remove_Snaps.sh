#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo snap remove bare
sudo snap remove core20
sudo snap remove firefox
sudo snap remove gnome-3-38-2004
sudo snap remove gtk-common-themes
sudo snap remove snap-store
sudo snap remove snapd
sudo snap remove snapd-desktop-integration
sudo apt autoremove --purge snapd

sudo rm -rf /var/cache/snapd/

cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.

Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
# Install Firefox via deb repo:
# sudo add-apt-repository ppa:mozillateam/ppa
# echo '\nPackage: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' | sudo tee /etc/apt/preferences.d/mozilla-firefox
# echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
# sudo apt install firefox
