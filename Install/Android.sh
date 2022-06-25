#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pkg=$(cat Pkglists/Termux.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
pkg update -y

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
pkg install -y $pkg

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone https://github.com/romkatv/powerlevel10k.git /data/data/com.termux/files/home/.oh-my-zsh/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /data/data/com.termux/files/home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions /data/data/com.termux/files/home/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/redxtech/zsh-kitty /data/data/com.termux/files/home/.oh-my-zsh/custom/plugins/zsh-kitty

# Install OhMyZsh, Powerlevel10K Configs:
cp ../Configs/Shell/Android_p10k.zsh /data/data/com.termux/files/home/.p10k.zsh
cp ../Configs/Shell/Android_zshrc /data/data/com.termux/files/home/.zshrc

# Install Tmux:
cp ../Configs/Shell/tmux.conf /data/data/com.termux/files/home/.tmux.conf
git clone https://github.com/tmux-plugins/tpm /data/data/com.termux/files/home/.tmux/plugins/tpm

# Install Vundle:
git clone https://github.com/VundleVim/Vundle.vim.git /data/data/com.termux/files/home/.vim/bundle/Vundle.vim
cp ../Configs/Shell/vimrc /data/data/com.termux/files/home/.vimrc
vim +PluginInstall +qall

touch /data/data/com.termux/files/home/.Xauthority
