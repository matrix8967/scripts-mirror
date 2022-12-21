#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

cat <<EOF > /etc/modprobe.d/hid-magicmouse.conf
options hid-magicmouse \
            scroll_acceleration=1 \
            stop_scroll_while_moving=1 \
            scroll_speed=10 \
            middle_click_3finger=1 \
            scroll_delay_pos_x=300 \
            scroll_delay_pos_y=250
EOF
sudo modprobe -r hid_apple; sudo modprobe hid_apple
