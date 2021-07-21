#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

apt=$(cat Pkglists/UbuntuServer.txt)

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# Install packages from the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo apt install -y $apt
