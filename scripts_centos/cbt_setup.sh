#!/bin/bash

# script to install CBT dependencies and tools for active benchmarking

sudo yum -y install deltarpm
sudo yum check-update
sudo yum -y update
sudo yum install -y psmisc util-linux coreutils xfsprogs e2fsprogs findutils \
  git wget bzip2 make automake gcc gcc-c++ kernel-devel perf blktrace lsof \
  redhat-lsb sysstat screen python3-yaml ipmitool dstat zlib-devel ntp

MIRROR="http://mirror.math.princeton.edu/pub/fedora-archive/fedora/linux/releases/22/Everything/x86_64/os/Packages"

#wget ${MIRROR}/p/pdsh-2.31-3.fc22.x86_64.rpm
#wget ${MIRROR}/p/pdsh-2.31-3.fc22.x86_64.rpm
#wget ${MIRROR}/p/pdsh-rcmd-ssh-2.31-3.fc22.x86_64.rpm
wget ${MIRROR}/c/collectl-4.0.0-1.fc22.noarch.rpm
wget ${MIRROR}/i/iftop-1.0-0.9.pre4.fc22.x86_64.rpm
wget ${MIRROR}/i/iperf3-3.0.10-1.fc22.x86_64.rpm

sudo yum localinstall -y *.rpm

sudo yum install -y pdsh
sudo yum install -y pdsh-rcmd-ssh.x86_64

if [ -z "$1" ]; then
  HOME_LOC="${HOME}"
else
  HOME_LOC=$1
fi

cd ${HOME_LOC}

git clone https://github.com/axboe/fio.git
git clone https://github.com/andikleen/pmu-tools.git
git clone https://github.com/brendangregg/FlameGraph

cd ${HOME_LOC}/fio
#./configure
#make
export CEPH_HOME="${HOME_LOC}"/ceph
export FIO_HOME="$(pwd)"
LDFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH ./configure
EXTFLAGS=-I"$CEPH_HOME"/src/include LIBRARY_PATH="$CEPH_HOME"/build/lib:$LIBRARY_PATH make -j `nproc`
echo "FIO installed"

printf 'export LD_LIBRARY_PATH="$CEPH_HOME"/build/lib:$LD_LIBRARY_PATH"\n' >> .bashrc

# wget < Red Hat Ceph Storage ISO URL >
# sudo mount -o loop Ceph-*-dvd.iso /mnt
#sudo yum localinstall -y /mnt/{MON,OSD}/*.rpm
#sudo yum localinstall -y /mnt/Installer/ceph-deploy-*.rpm

sudo sed -i 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
sudo setenforce 0
( awk '!/SELINUX=/' /etc/selinux/config ; echo "SELINUX=disabled" ) > /tmp/x
sudo mv /tmp/x /etc/selinux/config
rpm -qa firewalld | grep firewalld && sudo systemctl stop firewalld && sudo systemctl disable firewalld
sudo systemctl stop irqbalance
sudo systemctl disable irqbalance
#sudo systemctl start ntpd.service
#sudo systemctl enable ntpd.service
sudo systemctl start chronyd.service
sudo systemctl enable chronyd.service