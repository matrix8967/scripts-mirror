#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

go get -u github.com/xxxserxxx/gotop/cmd/gotop
go get github.com/charmbracelet/glow
go get -u github.com/jingweno/ccat
go get github.com/jesseduffield/lazydocker

sudo cp $GOPATH/bin/* /usr/bin/
