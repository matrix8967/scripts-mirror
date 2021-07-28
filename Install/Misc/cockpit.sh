#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo apt install -y cockpit cockpit-bridge cockpit-doc cockpit-networkmanager cockpit-pcp cockpit-system cockpit-ws cockpit-389-ds cockpit-dashboard cockpit-machines cockpit-packagekit cockpit-storaged cockpit-tests
