#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

dev=Dev.sh
comms=Comms.sh
gnome=Gnome.sh
apt=$(cat AptPacks.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# remove default snaps that should be apps instead...
echo -e "Removing default apps that are ${RED}snaps${NC}, that should have been ${GREEN}packages${NC}..."
sudo snap remove gnome-calculator gnome-logs gnome-system-monitor gnome-characters

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo apt install -y $apt

# Install Flatpaks Repo...
echo -e ${GREEN}"Installing Flatpaks..."${NC}
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
./FlatPaks.sh

echo -e "Install Dev Tools?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$dev;;
        "No") break;;
    esac
done

echo -e "Install Comms?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$comms;;
        "No") break;;
    esac
done

echo -e "Install Gnome Mods?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$gnome;;
        "No") break;;
    esac
done
