#!/bin/bash

if [ -z "$1" ]; then
  HOME_LOC="${HOME}"
else
  HOME_LOC=$1
fi


if [ -z "$2" ]; then
  PART="/dev/sdc"
else
  PART=$2
fi

sudo ./discard_sectors.sh "$PART"
sudo LD_LIBRARY_PATH="$HOME_LOC/ceph/build/lib:$LD_LIBRARY_PATH" "$HOME_LOC/fio/fio prec.fio"
