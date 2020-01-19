#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
CryptPart='3'

echo -e $RED"This script is going to wipe whatever drive you point it at."$NC
read -n 1 -s
echo -e $RED"It is your responsibility to make sure you understand the script."$NC
read -n 1 -s
echo -e $RED"I am not responsible for whatever eats shit from you using this script."$NC
read -n 1 -s
echo -e "Also for now, this needs to be run as root. Not a user with sudo priv. Actual root."
read -n 1 -s
echo -e
read -p 'Paste the full path, including ISO Name: ' ISO
echo -e
read -p 'Give the persistance partition a unique name: ' CryptName
lsblk
echo -e
read -p 'What is your Device ID? (sdX): ' DEVICEID
echo -e
dd if=$ISO of=/dev/$DEVICEID bs=512k status=progress
end=50gb
read start _ < <(du -bcm $ISO | tail -1); echo $start
parted /dev/$DEVICEID mkpart primary $start $end
cryptsetup --verbose --verify-passphrase luksFormat /dev/$DEVICEID$CryptPart
cryptsetup luksOpen /dev/$DEVICEID$CryptPart $CryptName
sleep 1
mkfs.ext4 -L persistence /dev/mapper/$CryptName
e2label /dev/mapper/$CryptName persistence
mkdir -p /mnt/$CryptName
mount /dev/mapper/$CryptName /mnt/$CryptName
echo "/ union" > /mnt/$CryptName/persistence.conf
umount /dev/mapper/$CryptName
cryptsetup luksClose /dev/mapper/$CryptName
