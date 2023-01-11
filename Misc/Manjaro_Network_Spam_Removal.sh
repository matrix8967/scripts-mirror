#!/bin/bash

cat EOF <<EOF > /usr/lib/NetworkManager/conf.d/20-connectivity.conf

[connectivity]
enabled=false
EOF
