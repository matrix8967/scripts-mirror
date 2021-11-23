#!/usr/bin/env bash

# set -euo pipefail

for i in $(adb shell pm list packages | awk -F':' '{print $2}'); do
  adb pull "$(adb shell pm path $i | awk -F':' '{print $2}')";
  mv base.apk $i.apk &> /dev/null
done
