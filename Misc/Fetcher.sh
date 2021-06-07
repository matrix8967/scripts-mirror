#!/usr/bin/env bash

set -euo pipefail


mkdir Content

for U in $(cat urls.txt)
do
        wget --content-disposition Content/$U
done
