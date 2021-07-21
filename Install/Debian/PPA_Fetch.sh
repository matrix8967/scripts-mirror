#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' 	# No Color

for APT in `find /etc/apt/ -name \*.list`; do
    grep -o "^deb http://ppa.launchpad.net/[a-z0-9\-]\+/[a-z0-9\-]\+" $APT | while read ENTRY ; do
        USER=`echo $ENTRY | cut -d/ -f4`
        PPA=`echo $ENTRY | cut -d/ -f5`
        echo sudo apt-add-repository ppa:$USER/$PPA
    done
done
