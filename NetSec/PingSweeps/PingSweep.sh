#!/bin/bash

for ip in $(seq 1 255); do
ping -c 1 192.168.0.$ip |grep "bytes from" |cut -d" " -f 4|cut -d":" -f1 &
done