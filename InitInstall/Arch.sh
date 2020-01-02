#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pac=$(cat PacmanPacks.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo pacman -Syu -y

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo pacman -S $pac -y

# Install Flatpaks Repo...
echo -e ${GREEN}"Installing Flatpaks..."${NC}
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo -e "Install FlatPaks?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./FlatPaks.sh;;
        "No") break;;
    esac
done

echo -e "Install Dev Tools?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./Dev.sh;;
        "No") break;;
    esac
done
