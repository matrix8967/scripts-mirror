#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

flatpak install flathub com.bitwarden.desktop
flatpak install flathub org.signal.Signal
flatpak install flathub im.riot.Riot
