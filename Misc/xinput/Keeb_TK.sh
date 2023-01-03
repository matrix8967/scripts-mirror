#!/usr/bin/env bash

#####
## xinput list
## Apple Inc. Magic Keyboard with Numeric Keypad
#####

#####
## lsusb
## Bus 001 Device 017: ID 05ac:026c Apple, Inc. Magic Keyboard with Numeric Keypad
#####

cat <<EOF > /etc/modprobe.d/hid_apple.conf
options hid_apple fnmode=2
options hid_apple swap_fn_leftctrl=0
options hid_apple swap_opt_cmd=1
options hid_apple rightalt_as_rightctrl=0
EOF
sudo modprobe -r hid_apple; sudo modprobe hid_apple
