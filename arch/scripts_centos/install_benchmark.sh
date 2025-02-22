#!/bin/bash

sudo yum check-update
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y libffi-devel python36-devel python3-pip targetcli librados2 librbd1

sudo rpm --import 'https://download.ceph.com/keys/release.asc' && \
	ulimit -n 1024 && \
  sudo yum install -y python3-rbd python3-rados

sudo groupadd esmaeil
sudo usermod -a -G esmaeil esmaeil

if [ -z "$1" ]; then
  HOME_LOC="${HOME}"
else
  HOME_LOC=$1
fi

bash mkpartition.sh sdc sdb
bash install_ceph.sh
printf 'export PATH="%s:$PATH"\n' "${HOME_LOC}/ceph/build/bin" >> "${HOME_LOC}/.bashrc"
printf 'export PATH="%s:$PATH"\n' "${HOME_LOC}/fio" >> "${HOME_LOC}/.bashrc"
cp cbt_setup.sh "${HOME_LOC}"
cp preconditioning.sh "${HOME_LOC}"
cp discard_sectors.sh "${HOME_LOC}"
cp prec.fio "${HOME_LOC}"
cp run_benchmark.sh "${HOME_LOC}"
cp register_commands.sh "${HOME_LOC}"
cd "${HOME_LOC}" || exit
mkdir logs
git clone https://github.com/esmaeil-mirvakili/cbt.git
mv cbt_setup.sh cbt/
cd "${HOME_LOC}/cbt" || { echo "CBT clone failed (cbt directory not found)."; exit; }
pip3 install -r requirements.txt
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
bash preconditioning.sh "$HOME_LOC" "/dev/sdc"
rm -f register_commands.sh
rm -f preconditioning.sh
rm -f prec.fio
rm -f discard_sectors.sh