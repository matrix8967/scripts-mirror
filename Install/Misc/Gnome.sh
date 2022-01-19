#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

mkdir /home/$USER/.themes
mkdir /home/$USER/.icons

# Download Eye Candy.

git clone https://github.com/EliverLara/Juno.git --branch ocean --single-branch ~/.themes/Juno
git clone https://github.com/EliverLara/Kripton.git ~/.themes/Kripton
git clone https://github.com/EliverLara/Sweet.git ~/.themes/Sweet
git clone https://github.com/EliverLara/Ant.git ~/.themes/Ant

gsettings set org.gnome.desktop.sound event-sounds false

firefox \
	-new-tab -url https://extensions.gnome.org/extension/3628/arcmenu/\
	-new-tab -url https://extensions.gnome.org/extension/779/clipboard-indicator/\
	-new-tab -url https://extensions.gnome.org/extension/1160/dash-to-panel/\
	-new-tab -url https://extensions.gnome.org/extension/1319/gsconnect/\
	-new-tab -url https://extensions.gnome.org/extension/545/hide-top-bar/\
	-new-tab -url https://extensions.gnome.org/extension/906/sound-output-device-chooser/\
	-new-tab -url https://extensions.gnome.org/extension/1460/vitals/\
	-new-tab -url https://extensions.gnome.org/extension/19/user-themes/\
	-new-tab -url https://extensions.gnome.org/extension/4679/burn-my-windows/\
	-new-tab -url https://extensions.gnome.org/extension/2950/compiz-alike-windows-effect/\
