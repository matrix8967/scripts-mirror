#!/bin/sh
sudo iptables -A OUTPUT -d 76.76.2.0/24 -j DROP
sudo iptables -A OUTPUT -d 147.185.34.0/24 -j DROP
