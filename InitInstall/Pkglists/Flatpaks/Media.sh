#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# com.github.babluboy.bookworm

flatpak install flathub -y com.uploadedlobster.peek com.spotify.Client org.kde.kdenlive tv.kodi.Kodi com.github.z.Cumulonimbus org.musicbrainz.Picard
