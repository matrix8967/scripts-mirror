#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

flatpak install -y flathub \
org.gtk.Gtk3theme.Arc \
org.gtk.Gtk3theme.Arc-solid org.gtk.Gtk3theme.Arc-Darker \
org.gtk.Gtk3theme.Arc-Darker-solid \
org.gtk.Gtk3theme.Arc-Dark \
org.gtk.Gtk3theme.Arc-Dark-solid \
org.gtk.Gtk3theme.Ambiance \
org.gtk.Gtk3theme.Akwa \
org.gtk.Gtk3theme.Akwa-light \
org.gtk.Gtk3theme.Akwa-dark \
org.gtk.Gtk3theme.Adwaita-dark \
org.gtk.Gtk3theme.Adementary \
org.gtk.Gtk3theme.Adapta \
org.gtk.Gtk3theme.Adapta-Nokto \
org.gtk.Gtk3theme.Adapta-Nokto-Eta \
org.gtk.Gtk3theme.Adapta-Eta \
org.gtk.Gtk3theme.Adapta-Brila \
org.gtk.Gtk3theme.Adapta-Brila-Eta \
org.gtk.Gtk3theme.Numix \
org.gtk.Gtk3theme.Numix-Frost \
org.gtk.Gtk3theme.Numix-Frost-Light \
org.gtk.Gtk3theme.Mojave-light \
org.gtk.Gtk3theme.Pop \
org.gtk.Gtk3theme.Pop-slim-light \
org.gtk.Gtk3theme.Pop-slim-dark \
org.gtk.Gtk3theme.Pop-light \
org.gtk.Gtk3theme.Pop-dark \
org.gtk.Gtk3theme.Qogir-win-dark \
org.gtk.Gtk3theme.deepin-dark \
