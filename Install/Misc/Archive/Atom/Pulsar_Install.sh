#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

Pulsar="Pulsar.txt"

while read -a line; do
	pulsar -p install $line
done <"$Pulsar"
