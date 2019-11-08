#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install Zsh, OhMyZsh, PowerLevel9K Theme, and NerdFonts...
echo -e "Installing ${GREEN}NerdFonts, OhMyZsh${NC} and ${GREEN}PowerLevel9K${NC} Theme..."
mkdir /home/$USER/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/AnonymousPro.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Hack.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/RobotoMono.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Terminus.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Ubuntu.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/UbuntuMono.zip -P /home/$USER/.fonts/
unzip ~/.fonts/'*.zip' -d /home/$USER/.fonts/
fc-cache

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" -P /home/$USER/.fonts/

# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
sed -i -e 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel9k\/powerlevel9k"/' ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Setup NanoRC
cat <<EOF > ~/.nanorc
set constantshow
set linenumbers
set nonewlines
set softwrap
EOF
