#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install Zsh, OhMyZsh, PowerLevel10K Theme, and NerdFonts...
echo -e "Installing ${GREEN}NerdFonts, OhMyZsh${NC} and ${GREEN}PowerLevel10K${NC} Theme..."
mkdir ~/.fonts

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Ubuntu.zip             -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/UbuntuSans.zip         -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/UbuntuMono.zip         -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Terminus.zip           -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/ShareTechMono.zip      -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/RobotoMono.zip         -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/ProggyClean.zip        -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Noto.zip               -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Mononoki.zip           -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Iosevka.zip            -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/IosevkaTerm.zip        -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraMono.zip           -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip           -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/ComicShannsMono.zip    -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Agave.zip              -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/3270.zip               -P ~/.fonts/

unzip ~/.fonts/'*.zip' -d ~/.fonts/
wget -O ~/.fonts/fira.tar.gz https://github.com/mozilla/Fira/archive/4.202.tar.gz
tar xf ~/.fonts/fira.tar.gz --wildcards "*.ttf" --directory=~/.fonts
fc-cache
