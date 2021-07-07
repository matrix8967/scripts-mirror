#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo apt install apt-transport-https curl
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update

sudo apt install brave-browser

#Fedora 28+, CentOS/RHEL 8+

#sudo dnf install dnf-plugins-core

#sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/

#sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

#sudo dnf install brave-browser
