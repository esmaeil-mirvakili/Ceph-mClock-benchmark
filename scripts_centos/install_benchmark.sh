#!/bin/bash

sudo yum check-update
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y libffi-devel
sudo yum install -y python36-devel
sudo yum install -y python3-pip
sudo yum install -y git
sudo yum install targetcli -y
sudo yum install -y librados2
sudo yum install -y librbd1

sudo rpm --import 'https://download.ceph.com/keys/release.asc' && \
	ulimit -n 1024 && \
	sudo yum install -y python3-rbd python3-rados

sudo groupadd esmaeil
sudo usermod -a -G esmaeil esmaeil

bash install_ceph.sh
printf 'export PATH="%s:$PATH"\n' "${HOME}/ceph/build/bin" >> .bashrc
printf 'export PATH="%s:$PATH"\n' "${HOME}/fio" >> .bashrc
cp cbt_setup.sh "${HOME}"
cd "${HOME}" || exit
mkdir logs
git clone https://github.com/ceph/cbt.git
mv cbt_setup.sh cbt/
cd "${HOME}/cbt" || { echo "CBT clone failed (cbt directory not found)."; exit; }
pip3 install -r requirements.txt
bash cbt_setup.sh

curl --silent --remote-name --location https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm
sudo ./cephadm add-repo --release quincy
sudo ./cephadm install ceph-common
sudo ./cephadm install python3-rados
#sudo mkdir -p /usr/local/lib/ceph/erasure-code
#sudo cp -r "${HOME}/ceph/build/lib/*" "/usr/local/lib/ceph/erasure-code"
