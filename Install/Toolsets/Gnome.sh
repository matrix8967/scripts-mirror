#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo apt install -y gnome-shell-extension-no-annoyance gnome-shell-extension-remove-dropdown-arrows gnome-shell-extensions gnome-shell-extension-system-monitor gnome-shell-extension-top-icons-plus gnome-shell-extension-dash-to-panel

mkdir /home/$USER/.themes
mkdir /home/$USER/.icons

# Download Eye Candy.

git clone https://github.com/dracula/gtk.git ~/.themes/Dracula
git clone https://github.com/EliverLara/Juno.git --branch ocean --single-branch ~/.themes/Juno
git clone https://github.com/EliverLara/Kripton.git ~/.themes/Kripton
git clone https://github.com/EliverLara/Sweet.git ~/.themes/Sweet
git clone https://github.com/EliverLara/Ant.git ~/.themes/Ant
git clone https://github.com/EliverLara/candy-icons.git ~/.icons/Candy-Icons
git clone https://github.com/vinceliuice/Qogir-icon-theme.git ~/.icons/Qogir-Cursors
git clone https://github.com/KaizIqbal/Bibata_Cursor.git ~/.icons/Bibata-Cursors
git clone https://github.com/keeferrourke/capitaine-cursors.git ~/.icons/Captaine-Cursors

# Open the browser to install Gnome Extensions because Gnome sucks.

firefox -new-tab -url https://extensions.gnome.org/extension/1228/arc-menu/ -new-tab -url https://extensions.gnome.org/extension/779/clipboard-indicator/ -new-tab -url https://extensions.gnome.org/extension/307/dash-to-dock/ -new-tab -url https://extensions.gnome.org/extension/545/hide-top-bar/ -new-tab -url https://extensions.gnome.org/extension/3357/material-shell/ -new-tab -url https://extensions.gnome.org/extension/800/remove-dropdown-arrows/ -new-tab -url https://extensions.gnome.org/extension/120/system-monitor/ -new-tab -url https://extensions.gnome.org/extension/1031/topicons/ -new-tab -url https://extensions.gnome.org/extension/19/user-themes/
