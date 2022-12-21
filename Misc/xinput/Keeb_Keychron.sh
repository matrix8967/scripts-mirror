#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

#####
## Keychron
#####

#####
## lsusb
## ID 05ac:024f Apple, Inc. Aluminium Keyboard (ANSI)
#####

#####
## Test if this can share the same code/config as the default Apple TK.
## Config File will be located at /usr/lib/modprobe.d/hid_apple.conf
## if installed via Package Manager.
#####

# cat <<EOF > /usr/lib/modprobe.d/hid_apple.conf
cat <<EOF > /etc/modprobe.d/hid_apple.conf
options hid_apple fnmode=2
options hid_apple swap_fn_leftctrl=0
options hid_apple swap_opt_cmd=0
options hid_apple rightalt_as_rightctrl=0
EOF
sudo modprobe -r hid_apple; sudo modprobe hid_apple
