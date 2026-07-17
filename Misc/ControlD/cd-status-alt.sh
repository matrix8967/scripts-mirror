#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

# wget -q -O - https://dns.controld.com/info |jq && wget  -q -O - https://proxy-latency.controld.com:42069/info | jq && wget -q -O - https://api.controld.com/ip/nullroutecheck | jq

jq -s . < <(
  {
        wget -q -O - https://dns.controld.com/info
        wget  -q -O - https://proxy-latency.controld.com:42069/info
        wget -q -O - https://api.controld.com/ip/nullroutecheck
  }
)
