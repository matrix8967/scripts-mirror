#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# net.daase.journable org.onlyoffice.desktopeditors net.rpdev.OpenTodoList com.github.alainm23.planner com.github.debauchee.barrier

flatpak install flathub -y me.kozec.syncthingtk org.nextcloud.Nextcloud org.gnome.FeedReader com.github.johnfactotum.Foliate io.github.wereturtle.ghostwriter com.github.marktext.marktext

# Copy Ghostwriter Theme.
cp -r ../../../Configs/Misc/Ghostwriter/Dracula $HOME/.var/app/io.github.wereturtle.ghostwriter/config/ghostwriter/themes/
