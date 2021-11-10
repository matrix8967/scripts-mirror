#!/bin/bash

# Raspbian Setup Jumpstart

sudo dpkg-reconfigure locales
sudo dpkg-reconfigure keyboard-configuration
sudo dpkg-reconfigure tzdata
mkdir -p /home/pi/Git/Gitlab/scrolls
git clone https://gitlab.com/matrix8967/scrolls.git /home/pi/Git/Gitlab/scrolls
echo -e "Hopefully nothing ate shit. Go to other setups."
