#!/bin/bash

sudo yum check-update
sudo yum update -y
sudo yum install -y python3-routes
sudo yum install -y ninja-build
sudo yum install epel-release -y
sudo yum install dnf -y
#wget https://download-ib01.fedoraproject.org/pub/fedora/linux/updates/34/Everything/x86_64/Packages/d/dnf-utils-4.0.24-1.fc34.noarch.rpm
#sudo rpm -Uvh dnf-utils-4.0.24-1.fc34.noarch.rpm


if [ -z "$1" ]; then
  HOME_LOC="${HOME}"
else
  HOME_LOC=$1
fi


# install ceph
cd "$HOME_LOC"
git clone https://github.com/esmaeil-mirvakili/ceph.git
cd ceph
git checkout bluestore-bufferbloat-mitigation-old
git submodule update --init

CEPH_HOME="$HOME_LOC/ceph" bash install-deps.sh
CEPH_HOME="$HOME_LOC/ceph" bash do_cmake.sh
cd build
ninja

#../src/stop.sh && rm -rf out dev && MON=1 OSD=1 MGR=1 MDS=0 RGW=0 ../src/vstart.sh -n -x
#./bin/ceph osd pool create rados


# install useful packages
sudo yum install -y cscope
sudo pip3 install -U pyyaml