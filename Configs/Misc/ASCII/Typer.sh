#!/usr/bin/env bash

set -euo pipefail

function typer
{
    text="$1"
    delay="$2"

    for i in $(seq 0 $(expr length "${text}")) ; do
        echo -n "${text:$i:1}"
        sleep ${delay}
    done
}

# ===== Adjust decimal for speed. ===== #
typer "$(cat BMO.txt)" 0.0001
