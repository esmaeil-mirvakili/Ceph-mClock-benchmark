#!/bin/bash

DISK=$1

if [[ -z "$DISK" ]]; then
    echo "Error: No argument provided!"
    echo "Expecting the disk path e.g.: /dev/sda"
    exit 1
fi

echo "Modifying partition table on $DISK..."
sudo fdisk $DISK <<EOF
o
n
p
1


w
EOF

echo "Partition table updated. The system may reboot now."

sudo reboot