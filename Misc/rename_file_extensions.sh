#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

for file in *.txt
do
  mv "$file" "${file%.txt}.md"
done
