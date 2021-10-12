#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

#####
## Keychron
#####

#####
## xinput
## AppleTKL
#####

#####
## lsusb
## ID 05ac:024f Apple, Inc. Aluminium Keyboard (ANSI)
#####

cat <<EOF > /etc/modprobe.d/hid_apple.conf
options hid_apple fnmode=2
EOF
sudo modprobe -r hid_apple; sudo modprobe hid_apple
