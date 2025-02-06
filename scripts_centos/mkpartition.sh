#!/bin/bash

fast_storage=$1
slow_storage=$2


sudo parted -s -a optimal /dev/$slow_storage mklabel gpt || failed "mklabel $slow_storage"
echo "Creating osd device data label on $slow_storage"
sudo parted -s -a optimal /dev/$slow_storage mkpart osd-device-0-data 0G 20% || failed "mkpart 0-data"
sudo parted -s -a optimal /dev/$slow_storage mkpart osd-device-0-block 20% 100% || failed "mkpart 0-block"

echo "Creating osd device journal label on $fast_storage"
lsblk /dev/sdc
sudo fdisk -l /dev/sdc
sudo parted -s -a optimal /dev/$fast_storage mkpart osd-device-0-wal 0G 20% || failed "mkpart 0-wal"
sudo parted -s -a optimal /dev/$fast_storage mkpart osd-device-0-db 20% 100% || failed "mkpart 0-db"

echo "partitions by labels:"
sudo parted -s /dev/sdb print
sudo parted -s /dev/sdc print
