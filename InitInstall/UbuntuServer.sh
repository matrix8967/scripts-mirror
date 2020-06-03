#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/UbuntuServer.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# Remove MOTD Ads... >:[
echo -e "Removing Default ${RED}MOTD that phones home.${NC}"
sudo systemctl disable motd-news.timer
sudo rm /etc/update-motd.d/*
sudo cp ../Misc/MOTD.sh /etc/update-motd.d/
sudo chmod +x /etc/update-motd.d/MOTD.sh

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo apt install -y $apt
