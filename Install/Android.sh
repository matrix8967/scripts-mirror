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

cp ../Configs/Shell/Android_p10k.zsh ~/
cp ../Configs/Shell/Android_zshrc ~/
