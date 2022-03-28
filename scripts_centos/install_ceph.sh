#!/bin/bash

sudo yum check-update
sudo yum update -y
sudo dnf install -y python3-routes
sudo dnf --enablerepo=powertools install -y ninja-build

sudo echo "Acquire::https::Verify-Peer "false";" >> /etc/apt/apt.conf.d/20packagekit
sudo echo "Acquire::https::Verify-Host "false";" >> /etc/apt/apt.conf.d/20packagekit

sudo echo "Acquire::https::Verify-Peer "false";" >> /etc/apt/apt.conf.d/20auto-upgrades
sudo echo "Acquire::https::Verify-Host "false";" >> /etc/apt/apt.conf.d/20auto-upgrades

if [ -z "$1" ]; then
  home="${HOME}"
else
  home=$1
fi


# install ceph
cd "$home"
git clone https://github.com/esmaeil-mirvakili/ceph.git
cd ceph
git checkout bluestore-bufferbloat-mitigation
git submodule update --init

CEPH_HOME="$home/ceph" bash install-deps.sh
CEPH_HOME="$home/ceph" bash do_cmake.sh
cd build
ninja

../src/stop.sh && rm -rf out dev && MON=1 OSD=1 MGR=1 MDS=0 RGW=0 ../src/vstart.sh -n -x
./bin/ceph osd pool create rados


# install useful packages
sudo dnf install -y cscope
sudo pip3 install -U pyyaml