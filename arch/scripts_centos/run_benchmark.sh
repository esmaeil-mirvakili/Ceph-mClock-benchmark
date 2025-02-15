#!/bin/bash

if [ -z "$1" ]; then
  HOME_LOC="${HOME}"
else
  HOME_LOC=$1
fi

if [ -z "$2" ]; then
  BENCH_PATH="$HOME_LOC/benchmarks"
else
  BENCH_PATH=$2
fi

arch="$HOME_LOC/arch"

find "$BENCH_PATH" -maxdepth 1 -mindepth 1 -type d | while read bench; do
  if [[ -d "$bench/arch" ]]; then
    echo "### $bench/arch exists"
    continue
  fi
  echo ">>> Experiment for $bench ..."
  echo ""
  echo ""
  python3 "$HOME_LOC/cbt/cbt.py" --archive="$arch" --conf="$bench/ceph.conf" "$bench/cbt.yaml" 2>&1 | tee  "$bench/cbt.log"
  echo ""
  echo ""
  echo ">>> Collecting results for $bench ..."
  echo ""
  echo ""
  cp -r "$arch" "$bench"
  rm -rf "$arch"
done

