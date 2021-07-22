#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

for dir in ~/Git/Gitlab/*/; do
	git -C $dir pull
#	echo -e "This would pull for $dir"
done
