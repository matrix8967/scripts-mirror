#!/bin/bash

flatpak repair
flatpak uninstall --unused
sudo flatpak repair --system
sudo flatpak repair --user
flatpak update
flatpak remove org.freedesktop.Platform.html5-codecs
