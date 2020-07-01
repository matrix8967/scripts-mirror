#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cargo install lsd bat bottom
cargo install -f --git https://github.com/cjbassi/ytop ytop
