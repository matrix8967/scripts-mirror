#!/usr/bin/env bash

# set -euo pipefail

### Block Egress TCP/UDP port 53 for IP:

## Edgerouter:

sudo iptables -A OUTPUT -p udp --dport 53 -d 10.10.10.1 -j DROP
sudo iptables -A OUTPUT -p tcp --dport 53 -d 10.10.10.1 -j DROP

## Public DNS:

sudo iptables -A OUTPUT -p udp --dport 53 -d 9.9.9.9 -j DROP
sudo iptables -A OUTPUT -p tcp --dport 53 -d 9.9.9.9 -j DROP

### Block Ingress TCP/UDP port 53 for IP:

## Edgerouter

sudo iptables -A INPUT -p udp --dport 53 -d 10.10.10.1 -j DROP
sudo iptables -A INPUT -p tcp --dport 53 -d 10.10.10.1 -j DROP

## Public DNS:

sudo iptables -A INPUT -p udp --dport 53 -d 9.9.9.9 -j DROP
sudo iptables -A INPUT -p tcp --dport 53 -d 9.9.9.9 -j DROP

## Showing & Validating rules:

sudo iptables -L -v -n | grep 53
sudo iptables --verbose --numeric --list --line-numbers
