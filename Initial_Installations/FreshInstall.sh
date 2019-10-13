#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

dev=Dev.sh
comms=Comms.sh
gnome=Gnome.sh
packages=Packages.txt

# Prime the Sudo rights
sudo echo "Sudo Primed"

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# remove default snaps that should be apps instead...
echo -e "Removing default apps that are ${RED}snaps${NC}, that should have been ${GREEN}packages${NC}..."
sudo snap remove gnome-calculator gnome-logs gnome-system-monitor gnome-characters

while read -a line
do
  sudo apt install $line
done <"$packages"

# # Install packages from the default repos...
# echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
# sudo apt install -y git screenfetch neofetch unrar zsh steam htop iftop glances fonts-powerline wavemon vim vlc tilix tmux gparted fail2ban arc-theme curl steam-devices python-pip guake tldr ipcalc pwgen ncdu

echo -e "Do you want to install Dev Tools?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$dev;;
        "No") break;;
    esac
done

echo -e "Do you want to install Chat Apps (Signal, Riot, Keybase)?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$comms;;
        "No") break;;
    esac
done

echo -e "Is this a Gnome Installation?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$gnome;;
        "No") break;;
    esac
done
