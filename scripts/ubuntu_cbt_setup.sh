#!/bin/bash

# script to install CBT dependencies and tools for active benchmarking on Ubuntu 20.04 LTS

sudo apt-get update -y
sudo apt-get install -y psmisc util-linux coreutils xfsprogs e2fsprogs findutils \
  git wget bzip2 make automake gcc gcc-c++ kernel-devel perf blktrace lsof \
  redhat-lsb sysstat screen python3-yaml ipmitool dstat zlib-devel ntp /
sudo apt-get install -y selinux-utils
sudo apt-get install -y pdsh
sudo apt-get install -y collectl
sudo apt-get install -y iftop
sudo apt-get install -y iperf

cd "${HOME}" || exit
git clone https://github.com/axboe/fio.git
git clone https://github.com/andikleen/pmu-tools.git
git clone https://github.com/brendangregg/FlameGraph

cd "${HOME}/fio" || exit
./configure
make

sudo sed -i 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
sudo setenforce 0
( awk '!/SELINUX=/' /etc/selinux/config ; echo "SELINUX=disabled" ) > /tmp/x
sudo mv /tmp/x /etc/selinux/config
rpm -qa firewalld | grep firewalld && sudo systemctl stop firewalld && sudo systemctl disable firewalld
sudo systemctl stop irqbalance
sudo systemctl disable irqbalance
sudo systemctl start ntpd.service
sudo systemctl enable ntpd.service
