#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

#####
## xinput list
## Apple Inc. Magic Keyboard
#####

#####
## lsusb
## Bus 001 Device 022: ID 05ac:0267 Apple, Inc. Magic Keyboard A1644
#####

cat <<EOF > /etc/modprobe.d/hid_apple.conf
options hid_apple fnmode=2
options hid_apple swap_fn_leftctrl=1
options hid_apple swap_opt_cmd=1
options hid_apple rightalt_as_rightctrl=1
EOF
sudo modprobe -r hid_apple; sudo modprobe hid_apple
