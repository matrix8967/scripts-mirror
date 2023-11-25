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

msg "Installing Packages..."
if [[ "${ID}" =~ "debian" ]] || [[ "${ID_LIKE}" =~ "debian" ]]; then
	sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc && echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mullvad.list && sudo apt update && sudo apt install mullvad-vpn

elif [[ "${ID}" =~ "rhel" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then
	sudo dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo && sudo dnf install mullvad-vpn

elif [[ "${ID}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then
	sudo dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo && sudo dnf install mullvad-vpn

# elif [[ "${ID}" =~ "arch" ]] || [[ "${ID_LIKE}" =~ "arch" ]]; then
# 	sudo pacman -S $MANJARO

else
	msg "Unknown system ID: ${ID}"
	exit 1
fi
