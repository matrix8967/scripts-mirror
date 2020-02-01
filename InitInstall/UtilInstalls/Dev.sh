#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install Zsh, OhMyZsh, PowerLevel10K Theme, and NerdFonts...
echo -e "Installing ${GREEN}NerdFonts, OhMyZsh${NC} and ${GREEN}PowerLevel10K${NC} Theme..."
mkdir ~/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/AnonymousPro.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/FiraMono.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Hack.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Mononoki.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/RobotoMono.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Terminus.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Ubuntu.zip -P ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/UbuntuMono.zip -P ~/.fonts/
unzip ~/.fonts/'*.zip' -d ~/.fonts/
fc-cache

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

cp ../Configs/Shell/zshrc ~/.zshrc
cp ../Configs/Shell/p10k.zsh ~/.p10k.zsh

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
sed -i -e 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

#Install Rust.
echo -e "Installing ${GREEN}Rust. Compiling lsd and bat.${NC}..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source $HOME/.cargo/env