#!/bin/bash


# Get the disk containing the root filesystem `/`
root_disk=$(df / | awk 'NR==2 {print $1}' | sed 's/[0-9]//g')
ssd_disk=""
hdd_disk=""
# List all disk devices
for disk in /sys/block/sd*; do
    disk_name=$(basename "$disk")
    device="/dev/$disk_name"

    # Get disk model (if available)
    model=$(lsblk -dn -o MODEL "$device" | sed 's/^[ \t]*//')
    
    # Check if the disk is an SSD (ROTA=0) or HDD (ROTA=1)
    rota=$(cat "$disk/queue/rotational")
    if [ "$rota" -eq 0 ]; then
        echo "$device is an SSD device"
        ssd_disk=device
    else
         if [[ "$device" == "$root_disk" ]]; then
            echo "$device is the root HDD device"
        else
            echo "$device is an HDD device"
            hdd_disk=device
        fi
    fi
done

if [ -z "$ssd_disk" ] || [ -z "$hdd_disk" ]; then
  echo "We need an HDD and SSD."
  exit 1;
fi

sudo parted -s -a optimal "$hdd_disk" mklabel gpt || failed "mklabel $hdd_disk"
echo "Creating osd device data label on $hdd_disk"
sudo parted -s -a optimal "$hdd_disk" mkpart osd-device-0-data 0G 20% || failed "mkpart 0-data"
sudo parted -s -a optimal "$hdd_disk" mkpart osd-device-0-block 20% 100% || failed "mkpart 0-block"

echo "Creating osd device journal label on $ssd_disk"
sudo lsblk
sudo fdisk -l "$ssd_disk"
sudo parted -s "$ssd_disk" mklabel gpt
sudo parted -s -a optimal "$ssd_disk" mkpart osd-device-0-wal 0G 20% || failed "mkpart 0-wal"
sudo parted -s -a optimal "$ssd_disk" mkpart osd-device-0-db 20% 100% || failed "mkpart 0-db"

echo "partitions by labels:"
sudo parted -s "$hdd_disk" print
sudo parted -s "$ssd_disk" print
