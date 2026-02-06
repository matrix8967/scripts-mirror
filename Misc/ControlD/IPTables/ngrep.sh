#!/bin/bash

sudo ngrep -d wlan0 -q -W byline "ipv6.controld.io" udp and port 53
