#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


# Install keybase.io
echo -e "Installing keybase.io"
curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
sudo apt install ./keybase_amd64.deb -y
run_keybase

# Update repos, install Signal, and Riot.
sudo apt update && sudo apt install signal-desktop riot-web -y
