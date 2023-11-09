#!/bin/bash

sudo dnf install dnf-plugin-system-upgrade
sudo dnf system-upgrade download --releasever=39
# Append `‐‐allowerasing` if broken packages stop the upgrade.
sudo dnf system-upgrade reboot

# Transaction saved to /var/lib/dnf/system-upgrade/system-upgrade-transaction.json.
# Download complete! Use 'dnf system-upgrade reboot' to start the upgrade.
# To remove cached metadata and transaction use 'dnf system-upgrade clean'
# The downloaded packages were saved in cache until the next successful transaction.
# You can remove cached packages by executing 'dnf clean packages'.
