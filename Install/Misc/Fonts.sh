#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install Zsh, OhMyZsh, PowerLevel10K Theme, and NerdFonts...
echo -e "Installing ${GREEN}NerdFonts, OhMyZsh${NC} and ${GREEN}PowerLevel10K${NC} Theme..."
mkdir ~/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Agave.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/DroidSansMono.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/FiraCode.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/FiraMono.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/JetBrainsMono.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Mononoki.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/RobotoMono.zip -P~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/UbuntuMono.zip -P~/.fonts/
unzip ~/.fonts/'*.zip' -d ~/.fonts/
wget -O ~/.fonts/fira.tar.gz https://github.com/mozilla/Fira/archive/4.202.tar.gz
tar xf ~/.fonts/fira.tar.gz --wildcards "*.ttf" --directory=~/.fonts
fc-cache
