#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "Install custom Kitty.conf?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../Dotfiles/Kitty/* ~/.config/kitty/;;
        "No") break;;
    esac
done

echo -e "Install custom Vim?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../Dotfiles/Vim/* ~/;;
        "No") break;;
    esac
done

echo -e "Install custom Konsole?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../Dotfiles/Konsole/* ~/.local/share/konsole/;;
        "No") break;;
    esac
done

echo -e "Install custom Nano?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../Dotfiles/nanorc ~/.nanorc;;
        "No") break;;
    esac
done

echo -e "Install custom zshrc?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") cp ../Dotfiles/zshrc ~/.zshrc;;
        "No") break;;
    esac
done
