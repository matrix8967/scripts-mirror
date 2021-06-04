#!/bin/bash

sudo snap remove snap-store
sudo snap remove gtk-common-themes
sudo snap remove gnome-3-34-1804
sudo snap remove core18
sudo snap remove snapd

# use `df` to show the subdirectory
# In 20.10+ this is /var/snap

sudo umount /snap/core/

sudo apt purge snapd

rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
