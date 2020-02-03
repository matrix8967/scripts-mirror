#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/UbuntuAptPacks.txt)

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

# Install Flatpaks Repo...
echo -e ${GREEN}"Installing Flatpaks..."${NC}
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo -e "Install Flatpaks?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") Pkglists/./FlatPaks.sh;;
        "No") break;;
    esac
done

echo -e "Install Dev Tools? (Nerd Fonts, P10K, OhMyZSH.)"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") UtilInstalls/./Dev.sh;;
        "No") break;;
    esac
done

echo -e "Install Gnome Mods? (Risky...)"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") UtilInstalls/./Gnome.sh;;
        "No") break;;
    esac
done
