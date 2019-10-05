#!/bin/bash
# vi:nowrap
# write iso with persistence
# kali-persistence.sh {iso}

# *** IMPORTANT *** edit DEVICE as needed ***

DEVICE=/dev/sdc

# .......1.........2.........3.........4.........5.........6....
if [ ! -e $DEVICE ] # device exists ?
then
  echo;echo "device $DEVICE ?";echo;exit 10
fi

ISO=${1}
if [ ! -e "$ISO" ] # iso exists ?
then
  echo;echo ".iso $ISO ?";echo;exit 10
fi

# .......1.........2.........3.........4.........5.........6....
# writing the iso creates 2 partitions
  echo;echo "Write $ISO to $DEVICE"
  sudo dd bs=1M if=$ISO of=$DEVICE oflag=direct status=progress && sync

  PERSIS=3 # write persistence to partition 3
  START=$(du -B1000000 $ISO | cut -f1)
  END=$(lsblk --noheadings --nodeps --bytes --output SIZE $DEVICE)
  END=$(($END / 1000000))
  echo;echo "Persistence on $DEVICE$PERSIS from $START to $END"
  sudo parted $DEVICE mkpart primary $START $END &&
  sleep 1
  sudo mkfs.ext3 -L persistence $DEVICE$PERSIS &&
  sudo mkdir -p /mnt/kaliUSB &&
  sudo mount $DEVICE$PERSIS /mnt/kaliUSB &&
  sudo sh -c "echo '/ union' > /mnt/kaliUSB/persistence.conf" &&
  sudo umount $DEVICE$PERSIS &&
  sudo rm -fr /mnt/kaliUSB/
  sudo fdisk -l $DEVICE
# .......1.........2.........3.........4.........5.........6....