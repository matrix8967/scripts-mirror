#!/usr/bin/env bash

#####
## Xinput to find Built In Macbook Trackpad/Keyboard
#####

# xinput | grep -m 1 "Apple Inc. Apple Internal " | cut -d "=" -f 2 | cut -d "[" -f 1

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
