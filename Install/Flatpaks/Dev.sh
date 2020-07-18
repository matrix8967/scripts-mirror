#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# io.botfather.Botfather

flatpak install flathub -y com.bitwarden.desktop com.axosoft.GitKraken io.atom.Atom
