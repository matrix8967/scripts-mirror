#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/Kali.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

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
