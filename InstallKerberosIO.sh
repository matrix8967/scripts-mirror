#!/bin/bash/


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Prime the Sudo rights
sudo echo ${GREEN}"Sudo Primed"${NC}

# Upgrade Exisiting Packages...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update

# Install New Packages...
echo -e ${GREEN}"Installing libav-tools libssl-dev..."${NC}
sudo apt install libav-tools libssl-dev

# Fetch Installer and Install...
echo -e ${GREEN}"Fetching Installer and Executing..."${NC}
wget https://github.com/kerberos-io/machinery/releases/download/v2.6.2/rpi3-machinery-kerberosio-armhf-2.6.2.deb
sudo dpkg -i rpi3-machinery-kerberosio-armhf-2.6.2.deb

# Prompt User to turn on Camera...
echo -e ${RED}"You will now need to enable the RPI Cam from the Raspi-Config utility."${NC}

select yn in "Yes" "No"; do
    case $yn in
        "Proceed...") break;;
        "Naw dude, fuck this.") exit;;
    esac
done

sudo raspi-config

echo -e ${GREEN}"Creating startup process for KerberosIO"${NC}
# Set Process to start on startup.
sudo systemctl enable kerberosio
sudo service kerberosio start

# Prompt User for Reboot.
echo -e ${RED}"Gotta Reboot. Cool?"${NC}
select yn in "Yes" "No"; do
    case $yn in
        "Proceed...") break;;
        "Naw dude, fuck this.") exit;;
    esac
done
sudo reboot