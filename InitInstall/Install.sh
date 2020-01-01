#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

dev=Dev.sh
comms=Comms.sh
gnome=Gnome.sh
apt=AptPacks.txt
dnf=DnfPacks.txt
osver=$(lsb_release -i -s)

if [ "$osver" == "Ubuntu" ];
then
  echo -e "Version is $osver."
  ./Ubuntu.sh
fi

echo -e "Do you want to install Dev Tools?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$dev;;
        "No") break;;
    esac
done

# Install Flatpaks Repo...
echo -e ${GREEN}"Installing Flatpaks..."${NC}
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo -e "Install Flatpaks?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./FlatPaks.sh;;
        "No") break;;
    esac
done
