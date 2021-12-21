#!/bin/bash

sudo dnf install dnf-plugin-system-upgrade
sudo dnf system-upgrade download --releasever=34
# Append `‐‐allowerasing` if broken packages stop the upgrade.
sudo dnf system-upgrade reboot

