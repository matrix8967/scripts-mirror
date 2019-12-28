#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "Install custom ASCII?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../../Dotfiles/ASCII/.* ~/;;
        "No") break;;
    esac
done

echo -e "Install Kitty Config?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") mkdir -p ~/.config/kitty/ && cp ../Dotfiles/Shell/Kitty/* ~/.config/kitty/;;
        "No") break;;
    esac
done

echo -e "Install custom Bat Config?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") mkdir -p ~/.config/bat/ && cp ../../Dotfiles/Bat/config ~/.config/bat/;;
        "No") break;;
    esac
done

echo -e "Install custom Vim?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../../Dotfiles/Vim/.* ~/ &&  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && vim +PluginInstall +qall ;;
        "No") break;;
    esac
done
