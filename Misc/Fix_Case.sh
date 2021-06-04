#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

for file in *' '*
do
  if [ -e "${file// /_}" ]
  then
    echo Warning, skipping "$file" as the renamed version already exists.
    continue
  fi

  mv -- "$file" "${file// /_}"
done
