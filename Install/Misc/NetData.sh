#!/usr/bin/env bash

# set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SUBNET=

read -p "Enter Local Subnet: " SUBNET

bash <(curl -Ss https://my-netdata.io/kickstart.sh) --disable-cloud --disable-telemetry
sudo systemctl start netdata && sudo systemctl status netdata
sudo ufw allow from $SUBNET to any port 19999
