#!/usr/bin/env bash
set -euo pipefail
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
flatpak install flathub com.bitwarden.desktop org.signal.Signal im.riot.Riot com.uploadedlobster.peek com.spotify.Client com.axosoft.GitKraken org.nextcloud.Nextcloud io.atom.Atom -y
