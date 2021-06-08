#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

export GO111MODULES=on

go get -u github.com/jingweno/ccat
go get github.com/jesseduffield/lazydocker
go get -u github.com/vultr/vultr-cli
go get -u github.com/sachaos/tcpterm

sudo cp $GOPATH/bin/* /usr/bin/

git -C /home/$USER/Git/Misc/ clone https://github.com/charmbracelet/glow.git

echo -e "I suck at GoLang, just *GO*...build it yourself..."
echo -e "cd /home/$USER/Git/Misc/glow/"
echo -e "go build"
echo -e "sudo cp glow /usr/bin/"
