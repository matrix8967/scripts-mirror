#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

git -C ~/Git/Misc clone https://github.com/bartobri/no-more-secrets.git
cd /home/$USER/Git/Misc/no-more-secrets
make nms
make sneakers
sudo make install
