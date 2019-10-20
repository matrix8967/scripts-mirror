#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "Attempting to install Gnome Extensions."

# s/o https://github.com/NicolasBernaerts/ubuntu-scripts/tree/master/ubuntugnome

sudo wget -O /usr/local/bin/gnomeshell-extension-manage "https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/ubuntugnome/gnomeshell-extension-manage"

sudo chmod +x /usr/local/bin/gnomeshell-extension-manage

gnomeshell-extension-manage --install --extension-id 1228 --user

gnomeshell-extension-manage --install --extension-id 307 --user

gnomeshell-extension-manage --install --extension-id 800 --user

gnomeshell-extension-manage --install --extension-id 19 --user

gnomeshell-extension-manage --install --extension-id 841 --user

gnomeshell-extension-manage --install --extension-id 826 --user

gnome-shell --replace &
