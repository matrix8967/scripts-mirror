#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cargo install lsd bat bottom bandwhich

# Bandwhich requires `root` to probe NICs and capture packets:

sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(which bandwhich)

# cargo install -f --git https://github.com/cjbassi/ytop ytop
