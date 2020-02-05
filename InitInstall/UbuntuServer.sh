#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/UbuntuAptHeadless.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# Remove default snaps that should be apps instead...
echo -e "Removing default ${RED}snaps${NC}, that should have been ${GREEN}packages${NC}..."
sudo snap remove gnome-calculator gnome-logs gnome-system-monitor gnome-characters

# Remove MOTD Ads... >:[
echo -e "Removing Default ${RED}MOTD that phones home.${NC}"
sudo systemctl disable motd-news.timer
sudo rm /etc/update-motd.d/*

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo apt install -y $apt
