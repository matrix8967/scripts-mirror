#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Raspbian Setup Jumpstart

read -p "Enter SSID: " SSID
read -p "Enter SSID Password: " SSIDPW

# sudo dpkg-reconfigure locales
# sudo dpkg-reconfigure keyboard-configuration
# sudo dpkg-reconfigure tzdata
sudo update-locale LC_ALL="en_US.UTF-8"

mkdir -p ~/Git/Gitlab/scrolls/
sudo apt update && sudo apt install git -y
git clone https://gitlab.com/matrix8967/scripts.git ~/Git/Gitlab/scrolls
sudo cat <<EOF > /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
        ssid=$SSID
        scan_ssid=1
        psk=$SSIDPW
}
EOF
# sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
sudo nmcli dev wifi list
sudo nmcli --ask dev wifi connect $SSID hidden yes

echo -e "Hopefully nothing ate shit. Go to other setups."
