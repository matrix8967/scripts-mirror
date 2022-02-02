#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

node foundryvtt/resources/app/main.js --dataPath=$HOME/foundrydata
