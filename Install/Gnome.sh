#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo apt install -y gnome-shell-extension-no-annoyance gnome-shell-extension-remove-dropdown-arrows gnome-shell-extensions gnome-shell-extension-system-monitor gnome-shell-extension-top-icons-plus gnome-shell-extension-dash-to-panel

mkdir /home/$USER/.themes
mkdir /home/$USER/.icons

# Grab Gnome Themes.
echo -e "Downloading Themes."
wget -O /home/$USER/.themes/Ant-Dracula.zip https://github.com/EliverLara/Ant-Dracula/archive/master.zip
wget -O /home/$USER/.themes/Sweet.zip https://github.com/EliverLara/Sweet/archive/master.zip

# Grab Icon Sets.
echo -e "Downloading Icons."
wget -O /home/$USER/.icons/Candy-Icons.zip https://github.com/EliverLara/candy-icons/archive/master.zip

# Grab Cursors.
echo -e "Downloading Cursors."
git clone https://github.com/vinceliuice/Qogir-icon-theme.git /home/$USER/.icons/Qogir-Cursors
git clone https://github.com/KaizIqbal/Bibata_Cursor.git /home/$USER/.icons/Bibata-Cursors
git clone https://github.com/keeferrourke/capitaine-cursors.git /home/$USER/.icons/Captaine-Cursors

# Extract Zip Files.
unzip /home/$USER/.themes/'*.zip' -d /home/$USER/.themes/
unzip /home/$USER/.icons/'*.zip' -d /home/$USER/.icons/
