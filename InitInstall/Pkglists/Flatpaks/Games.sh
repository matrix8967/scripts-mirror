#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


flatpak install flathub -y org.libretro.RetroArch org.scummvm.ScummVM org.DolphinEmu.dolphin-emu com.dosbox.DOSBox org.zdoom.GZDoom com.mojang.Minecraft org.openmw.OpenMW com.eduke32.EDuke32 io.github.sharkwouter.Minigalaxy io.mgba.mGBA ca._0ldsk00l.Nestopia net.pcsx2.PCSX2 org.ppsspp.PPSSPP 
