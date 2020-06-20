#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

dnf=$(cat Pkglists/Fedora.txt)

# Prime the Sudo rights
sudo echo -e ${GREEN}"Sudo Primed!"${NC}

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo dnf update

echo -e ${GREEN}"Installing RPM Fusion Repos..."${NC}
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install $dnf

# Install Flatpaks Repo...
echo -e ${GREEN}"Installing Flatpaks..."${NC}
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Radeon 5700XT Driver -- xorg-x11-drv-amdgpu
echo "Radeon 5700XT Driver for Xorg?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") sudo dnf install xorg-x11-drv-amdgpu -y ;;
        "No") exit;;
    esac
done
