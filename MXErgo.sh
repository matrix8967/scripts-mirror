#!/bin/bash

# xinput --set-prop 16 'libinput Accel Speed' 1
# The above sets the MXErgo to a higher Acceleration

DeviceID="$(xinput |grep MX| cut -d"=" -f 2| cut -d "[" -f 1)"

xinput --set-prop $DeviceID 'libinput Accel Speed' 1
