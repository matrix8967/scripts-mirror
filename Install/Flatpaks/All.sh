#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

flatpak install flathub -y com.bitwarden.desktop org.signal.Signal im.riot.Riot com.discordapp.Discord com.github.johnfactotum.Foliate io.github.wereturtle.ghostwriter com.github.marktext.marktext org.gnome.gitlab.somas.Apostrophe md.obsidian.Obsidian
