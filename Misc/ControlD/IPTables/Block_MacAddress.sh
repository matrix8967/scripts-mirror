#!/bin/bash

# Block IPv4 access to internal DNS server (192.168.1.1) for MAC AB:CD:EF:12:34:35
iptables -I FORWARD -m mac --mac-source AB:CD:EF:12:34:35 -d 192.168.1.1 -p udp --dport 53 -j DROP
iptables -I FORWARD -m mac --mac-source AB:CD:EF:12:34:35 -d 192.168.1.1 -p tcp --dport 53 -j DROP

# Block all IPv6 traffic to and from MAC AB:CD:EF:12:34:35
ip6tables -I INPUT -m mac --mac-source AB:CD:EF:12:34:35 -j DROP
ip6tables -I OUTPUT -m mac --mac-source AB:CD:EF:12:34:35 -j DROP
ip6tables -I FORWARD -m mac --mac-source AB:CD:EF:12:34:35 -j DROP
