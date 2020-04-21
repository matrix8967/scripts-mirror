#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

mkdir ~/.themes
mkdir ~/.icons

# Grab Gnome Themes.
echo -e "Downloading Themes."
wget -O ~/.themes/Ant-Dracula.zip https://github.com/EliverLara/Ant-Dracula/archive/master.zip
wget -O ~/.themes/Sweet.zip https://github.com/EliverLara/Sweet/archive/master.zip

# Grab Icon Sets.
echo -e "Downloading Icons."
wget -O ~/.icons/Candy-Icons.zip https://github.com/EliverLara/candy-icons/archive/master.zip

# Grab Cursors.
echo -e "Downloading Cursors."
git clone https://github.com/vinceliuice/Qogir-icon-theme.git ~/.icons/Qogir-Cursors
git clone https://github.com/KaizIqbal/Bibata_Cursor.git ~/.icons/Bibata-Cursors
git clone https://github.com/keeferrourke/capitaine-cursors.git ~/.icons/Captaine-Cursors

# Extract Zip Files.
unzip ~/.themes/'*.zip' -d ~/.themes/
unzip ~/.icons/'*.zip' -d ~/.icons/
