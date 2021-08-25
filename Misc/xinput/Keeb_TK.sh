#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

# Universal/Keychron:

cat <<EOF > /etc/modprobe.d/hid_apple.conf
options hid_apple fnmode=2
options hid_apple swap_fn_leftctrl=0
options hid_apple swap_opt_cmd=0
options hid_apple rightalt_as_rightctrl=0
EOF
sudo modprobe -r hid_apple; sudo modprobe hid_apple
