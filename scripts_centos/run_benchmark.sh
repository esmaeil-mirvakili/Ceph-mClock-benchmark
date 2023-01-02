#!/bin/bash

HOME_LOC=/users/esmaeil

if [ "$1" = "wpq" ]; then
  queue="wpq"
else
  queue="mclock"
fi

algorithms=("codel" "no_cntrl" "vanilla_256k" "vanilla_512k")
profiles=("high_recov" "high_user")
arch="$HOME_LOC/arch"

for algorithm in ${algorithms[*]}; do
  for profile in ${profiles[*]}; do
    path="$HOME_LOC/benchmark/$queue/$algorithm/$profile"
    echo ">>> Experiment for $path ..."
    echo ""
    echo ""
    python3 "$HOME_LOC/cbt/cbt.py" --archive="$arch" --conf="$path/ceph_4osd.conf" "$path/cbt_conf_4osd.yaml"
    echo ""
    echo ""
    echo ">>> Collecting results for $path ..."
    echo ""
    echo ""
    cp "$HOME_LOC/benchmark/$queue/$algorithm/$profile/cbt_conf_4osd.yaml" "$arch"
    cp "$HOME_LOC/benchmark/$queue/$algorithm/$profile/ceph_4osd.conf" "$arch"
    mv "$arch" "$HOME_LOC/result-$queue-$algorithm-$profile"
  done
done

