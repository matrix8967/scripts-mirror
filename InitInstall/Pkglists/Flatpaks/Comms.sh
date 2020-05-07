#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# com.mattermost.Desktop io.github.NhekoReborn.Nheko

flatpak install flathub -y org.signal.Signal im.riot.Riot com.discordapp.Discord ch.protonmail.protonmail-bridge
