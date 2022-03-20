#!/bin/bash

if [ -z "$1" ]; then
  remote_home="~"
else
  remote_home=$1
fi

printf 'export PATH="%s:$PATH"' "$remote_home/ceph/build/bin" >> .bashrc
