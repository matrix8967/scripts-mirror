#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


function msg {
  echo -e "\x1B[1m$*\x1B[0m" >&2
}

trap 'msg "\x1B[31mNo Worky."' ERR

source /etc/os-release


msg "Detecting Distro & Installing 1PW."
if [[ "${ID}" =~ "debian" ]] || [[ "${ID_LIKE}" =~ "debian" ]]; then

# Add 1PW Repo Public Key:
	curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
	
# Add 1PW Debian Repo:
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
	
# Add debsig-verify policy:
	sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
	
	curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
	
	sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
	
	curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# Install 1PW:
	sudo apt update && sudo apt install 1password


elif [[ "${ID}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then

# Add 1PW Public Key:
	sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc

# Add Repo:
	sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

# Install 1PW:
	sudo dnf install 1password

elif [[ "${ID}" =~ "arch" ]] || [[ "${ID_LIKE}" =~ "arch" ]]; then

# Add 1PW Signing Key:
	curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import

# Clone 1PW Repo:
	git clone https://aur.archlinux.org/1password.git

# Build & Install:
	cd 1password
	makepkg -si

else
  msg "Unknown system ID: ${ID}"
  msg "Please add support for your distribution to: $0"
  exit 1
fi
echo "¯\_(ツ)_/¯ Guess it works?" >&2
