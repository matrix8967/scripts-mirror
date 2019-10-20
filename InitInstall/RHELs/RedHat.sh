#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

dev=Dev.sh
comms=Comms.sh
gnome=Gnome.sh
dnf=$(cat DnfPacks.txt)
flats=$(cat FlatPaks.txt)

# Prime the Sudo rights
sudo echo -e ${GREEN}"Sudo Primed!"${NC}

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo dnf update

echo -e ${GREEN}"Installing RPM Fusion Repos..."${NC}
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo -e ${GREEN}"Installing Kitty from COPR Repos..."${NC}
sudo dnf copr enable atim/kitty-terminal -y

sudo dnf install $dnf

echo -e ${GREEN}"Setting up FlatPaks..."${NC}
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo


echo -e "Is this a Gnome Installation?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$gnome;;
        "No") break;;
    esac
done
