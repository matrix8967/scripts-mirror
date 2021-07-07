#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Docker Auto Script.
# curl -fsSL https://get.docker.com -o get-docker.sh
# sudo sh get-docker.sh
# 
# https://docs.docker.com/engine/security/rootless/
#
# https://docs.docker.com/engine/install/linux-postinstall/


sudo apt update
sudo apt install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io


# Install Docker Compose:

sudo curl -L "https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo groupadd docker

sudo usermod -aG docker $(whoami)
