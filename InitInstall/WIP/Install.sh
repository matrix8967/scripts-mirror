#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

dev=Dev.sh
comms=Comms.sh
gnome=Gnome.sh
apt=AptPacks.txt
dnf=DnfPacks.txt
osver=$(lsb_release -ds | cut -d " " -f 1)

if [ "$osver" == "Ubuntu" ];
then
  echo -e "Version is $osver."
  ./Ubuntu.sh
fi

# Prime the Sudo rights
sudo echo "Sudo Primed"

echo -e "Do you want to install Dev Tools?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$dev;;
        "No") break;;
    esac
done

echo -e "Do you want to install Chat Apps (Signal, Riot, Keybase)?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$comms;;
        "No") break;;
    esac
done

echo -e "Is this a Gnome Installation?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") ./$gnome;;
        "No") break;;
    esac
done
