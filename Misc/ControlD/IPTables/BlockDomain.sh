#!/bin/bash

echo -e "Displaying IPTables before block..."

sudo iptables -L -v -n | grep DROP

DOMAIN="controld.com"
IPS=$(dig +short $DOMAIN)

for IP in $IPS; do
    sudo iptables -A OUTPUT -d "$IP" -j DROP
    sudo iptables -A INPUT -s "$IP" -j DROP
    echo "Blocked $IP"
done

echo -e "Displaying IPTables AFTER block..."
