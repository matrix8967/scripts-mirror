#!/bin/bash/

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Prime the Sudo rights
sudo echo ${GREEN}"Sudo Primed"${NC}

# The Install Guide says to run Kerberos now...If this gets stuck, comment out the next two lines.
echo -e ${GREEN}"The Install Guide says to run Kerberos now...
If this gets stuck, comment out the next line and rerun."${NC}

kerberosio

# Download and install Nginx and PHP.
echo -e ${GREEN}"Downloading and Installing Nginx and PHP."${NC}

echo "deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi" | sudo tee --append /etc/apt/sources.list

sudo apt update && sudo apt upgrade

sudo apt-get install -t stretch nginx php7.0 php7.0-curl php7.0-gd php7.0-fpm php7.0-cli php7.0-opcache php7.0-mbstring php7.0-xml php7.0-zip php7.0-mcrypt

sudo rm -f /etc/nginx/sites-enabled/default

sudo cat <<EOF > /etc/nginx/sites-enabled/kerberosio.conf

server
{
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/web/public;
    server_name kerberos.rpi;
    index index.php index.html index.htm;
    location /
    {
            autoindex on;
            try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$
    {
            fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
    }
}

EOF

# Prompt user to restart Nginx...
echo -e "Restart NginX?"
select yn in "Yes" "No"; do
    case $yn in
        "Yes") service nginx restart; break;;
        "No") exit;;
    esac
done

# Create WWW Location.
echo -e ${GREEN}"Creating WWW Location..."${NC}

sudo mkdir -p /var/www/web && sudo chown www-data:www-data /var/www/web
cd /var/www/web

# Getting Source, Unpacking, and changing write permissions.
echo -e ${GREEN}"Getting Source, Unpacking, and changing write permissions."${NC}

sudo -u www-data wget https://github.com/kerberos-io/web/releases/download/v2.5.1/web.tar.gz
sudo -u www-data tar xvf web.tar.gz .
sudo chown www-data -R storage bootstrap/cache config/kerberos.php
sudo chmod -R 775 storage bootstrap/cache
sudo chmod 0600 config/kerberos.php

# Creating AutoRemoval Script..
echo -e ${GREEN}"Creating AutoRemoval Script."${NC}

sudo cat <<EOF > /home/pi/autoremoval.sh
partition=/dev/root
imagedir=/etc/opt/kerberosio/capture/
if [[ $(df -h | grep $partition | head -1 | awk -F' ' '{ print $5/1 }' | tr ['%'] ["0"]) -gt 90 ]];
then
    echo "Cleaning disk"
    find $imagedir -type f | sort | head -n 100 | xargs -r rm -rf;
fi;
EOF

chmod +x /home/pi/autoremoval.sh

# Prompt User for Cronjob.
echo -e ${GREEN}"For this next part, we'll create a cron job."${NC}
echo -e ${GREEN}"- Select Nano"${NC}
echo -e ${GREEN}"- Copy the following line to your clipboard and paste after the last line."${NC}
echo -e ${RED}"*/5 * * * * /bin/bash /home/pi/autoremoval.sh"${NC}
echo -e ${GREEN}"Press CTRL O then CTRL X to exit."${NC}

# Prompt User for Reboot.
echo -e ${RED}"Gotta Reboot. Cool?"${NC}
select yn in "Yeah! 👍" "Nah... 👎"; do
    case $yn in
        "Yeah! 👍") break;;
        "Nah... 👎") exit;;
    esac
done
sudo reboot