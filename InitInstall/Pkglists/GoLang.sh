#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

go get github.com/cjbassi/gotop
go get github.com/charmbracelet/glow

sudo cp $GOPATH/bin/* /usr/bin/

