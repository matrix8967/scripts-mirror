#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

./Comms.sh
./Dev.sh
./Games.sh
./Media.sh
./Productivty.sh
