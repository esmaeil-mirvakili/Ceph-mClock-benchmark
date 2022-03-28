#!/bin/bash

arg=$1
IFS=', ' read -r -a partitions <<< "$arg"

i=0
for part in "${partitions[@]}"
do
  echo "Creating osd device data label on $part"
  sudo parted -s -a optimal /dev/$part mklabel gpt
  sudo parted -s -a optimal /dev/$part mkpart osd-device-$i-journal 0% 1000M
  sudo parted -s -a optimal /dev/$part mkpart osd-device-$i-data 1000M 100%
  (( i++ )) || true
done

echo "partitions by labels:"
ls -l /dev/disk/by-partlabel/
