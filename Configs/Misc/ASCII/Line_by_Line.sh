#!/usr/bin/env bash

set -euo pipefail

# Line-by-line drop in. This is a one liner, but I never remember it.
awk '{print $0; system("sleep .3");}' filename.txt
