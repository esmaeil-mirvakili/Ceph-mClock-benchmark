#!/bin/bash

if [ -z "$HOME_LOC" ]; then
  HOME_LOC="${HOME}"
fi

ip_address=$(nmcli -g IP4.ADDRESS device show enp6s0f1 | cut -d/ -f1)
nmcli d
echo "IP of enp6s0f1: $ip_address"

sudo yum check-update
sudo yum update -y
nmcli d
echo "restoring the network"
sudo nmcli con add type ethernet ifname enp6s0f1 con-name enp6s0f1
sudo nmcli con up enp6s0f1
sudo nmcli con modify enp6s0f1 ipv4.method manual ipv4.addresses "$ip_address"/24 ipv4.gateway 10.10.1.1 ipv4.dns 8.8.8.8
sudo nmcli con up enp6s0f1
nmcli d

sudo yum groupinstall -y "Development Tools"
sudo yum install -y libffi-devel python-devel python3-pip targetcli librados2 librbd1

#sudo rpm --import 'https://download.ceph.com/keys/release.asc' && \
#	ulimit -n 1024 && \
#  sudo yum install -y python3-rbd python3-rados
sudo dnf install -y centos-release-ceph-quincy
sudo dnf install -y python3-rados python3-rbd


sudo groupadd "$USER_NAME"
sudo usermod -a -G "$USER_NAME" "$USER_NAME"

if [ -z "$HOME_LOC" ]; then
  HOME_LOC="${HOME}"
fi

cd "${HOME_LOC}" || exit

mkdir logs
mkdir data

bash mkpartition.sh

bash install_ceph.sh
printf 'export PATH="%s:$PATH"\n' "${HOME_LOC}/ceph/build/bin" >> "${HOME_LOC}/.bashrc"

bash cbt_setup.sh

#curl --silent --remote-name --location https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
#chmod +x cephadm
#sudo ./cephadm add-repo --release quincy
#sudo ./cephadm install ceph-common
#sudo ./cephadm install python3-rados
#sudo mkdir -p /usr/local/lib/ceph/erasure-code
#sudo cp -r "${HOME}/ceph/build/lib/*" "/usr/local/lib/ceph/erasure-code"


cd "${HOME_LOC}" || exit
bash register_commands.sh "$HOME_LOC"
rm -f *.sh


