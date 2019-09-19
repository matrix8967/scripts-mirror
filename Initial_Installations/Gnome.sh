#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
#VERS=$(gnome-shell  | cut -d " " -f 3)

sudo apt isntall gnome-calculator gnome-logs gnome-system-monitor gnome-characters gnome-tweak-tool chrome-gnome-shell

# Install Gnome Shell Extensions...(Thanks https://github.com/NicolasBernaerts/)

echo -e "Attempting to install Gnome Extensions."

sudo wget -O /usr/local/bin/gnomeshell-extension-manage "https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/ubuntugnome/gnomeshell-extension-manage"

sudo chmod +x /usr/local/bin/gnomeshell-extension-manage

gnomeshell-extension-manage --install --extension-id 1228 --user

gnomeshell-extension-manage --install --extension-id 307 --user

gnomeshell-extension-manage --install --extension-id 800 --user

gnomeshell-extension-manage --install --extension-id 19 --user

gnomeshell-extension-manage --install --extension-id 841 --user

gnomeshell-extension-manage --install --extension-id 826 --user

gnome-shell --replace &

# Install Sweet-Dark (fix this)
# echo -e "Downloading and Installing Sweet-Dark Theme..."
# sudo mkdir -p /usr/share/themes/Sweet-Dark/
# git clone https://github.com/EliverLara/Sweet.git /usr/share/themes/Sweet-Dark/
# gsettings set org.gnome.desktop.interface gtk-theme "Sweet-Dark"
# gsettings set org.gnome.desktop.wm.preferences theme "Sweet-Dark"