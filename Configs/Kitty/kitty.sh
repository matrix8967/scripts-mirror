#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

mkdir -p ~/.config/kitty/kitty-themes

cp kitty.conf ~/.conf/kitty/kitty.conf
cp -r kitty-themes/ ~/.conf/kitty/
