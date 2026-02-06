#!/bin/sh

sudo tc qdisc add dev wlan0 root netem delay 2s
sudo tc qdisc del dev wlan0 root
