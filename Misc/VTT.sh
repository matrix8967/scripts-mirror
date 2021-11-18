#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

VTT_DOMAIN=

read -p 'Paste the URL for your VTT Timed Download: ' VTT_DOMAIN

sudo apt install -y libssl-dev
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
sudo apt install -y nodejs

cd $HOME
mkdir foundryvtt
mkdir foundrydata

# Install the software
cd foundryvtt
wget -O foundryvtt.zip $VTT_DOMAIN
unzip foundryvtt.zip

# Setup UFW Rules to Accept Proxy Traffic

sudo ufw allow from 10.6.0.0/24 to any port 30000
sudo ufw allow from 10.6.0.0/24 to any port 80
sudo ufw allow from 10.6.0.0/24 to any port 443

# Start running the server
node foundryvtt/resources/app/main.js --dataPath=$HOME/foundrydata
