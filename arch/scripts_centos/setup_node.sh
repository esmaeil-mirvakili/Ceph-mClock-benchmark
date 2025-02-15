#!/bin/bash

if [ -z "$HOME_LOC" ]; then
  HOME_LOC="${HOME}"
fi

sudo yum check-update
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y screen libffi-devel python36-devel python3-pip targetcli librados2 librbd1

sudo rpm --import 'https://download.ceph.com/keys/release.asc' && \
	ulimit -n 1024 && \
  sudo yum install -y python3-rbd python3-rados

sudo groupadd "$USER_NAME"
sudo usermod -a -G "$USER_NAME" "$USER_NAME"

if [ -z "$HOME_LOC" ]; then
  HOME_LOC="${HOME}"
fi

cd "${HOME_LOC}" || exit

mkdir logs
mkdir data

bash mkpartition.sh sdc sdb

bash install_ceph.sh
printf 'export PATH="%s:$PATH"\n' "${HOME_LOC}/ceph/build/bin" >> "${HOME_LOC}/.bashrc"

bash cbt_setup.sh

curl --silent --remote-name --location https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm
sudo ./cephadm add-repo --release quincy
sudo ./cephadm install ceph-common
sudo ./cephadm install python3-rados
#sudo mkdir -p /usr/local/lib/ceph/erasure-code
#sudo cp -r "${HOME}/ceph/build/lib/*" "/usr/local/lib/ceph/erasure-code"


cd "${HOME_LOC}" || exit
bash register_commands.sh "$HOME_LOC"
rm -f *.sh


