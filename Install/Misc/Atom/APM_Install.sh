#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

apms="apms.txt"

while read -a line; do
	apm install $line
done <"$apms"
