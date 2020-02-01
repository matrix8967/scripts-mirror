#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/UbuntuAptPacks.txt)
headless=$(cat Pkglists/UbuntuAptHeadless.txt)
server=$(sudo apt install $headless -y)
desktop=$(sudo apt install $apt -y)

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
echo -e ${GREEN}"Is this a headless server?"${NC}
select yn in "Yes" "No"; do
    case $yn in
        "Yes") $server;;
        "No") $desktop;;
    esac
done
