#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pip3 install bpytop paramiko mkdocs-material easy_install bdfr pipx protontricks bpytop --upgrade
pip3 install --user pmbootstrap
