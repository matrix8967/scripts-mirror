#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/UbuntuDesktop.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# Remove MOTD Ads... >:[
sudo rm /etc/update-motd.d/*
sudo cp ../Misc/MOTD.sh /etc/update-motd.d/10-motd
sudo chmod +x /etc/update-motd.d/10-motd

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo apt install -y $apt

# Install Flatpaks Repo...
echo -e ${GREEN}"Installing Flatpaks..."${NC}
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
