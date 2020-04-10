#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


flatpak install flathub com.bitwarden.desktop org.signal.Signal im.riot.Riot org.libretro.RetroArch com.uploadedlobster.peek com.spotify.Client com.axosoft.GitKraken org.scummvm.ScummVM me.kozec.syncthingtk com.discordapp.Discord org.DolphinEmu.dolphin-emu com.dosbox.DOSBox org.zdoom.GZDoom org.kde.kdenlive tv.kodi.Kodi com.mojang.Minecraft org.nextcloud.Nextcloud org.openmw.OpenMW io.atom.Atom com.github.johnfactotum.Foliate -y
