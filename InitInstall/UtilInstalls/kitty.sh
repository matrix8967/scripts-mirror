#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

mkdir -p ~/.config/kitty/themes

cp kitty.conf ~/.config/kitty/kitty.conf
cp -r themes/ ~/.config/kitty/
