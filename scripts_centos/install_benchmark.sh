#!/bin/bash

sudo yum check-update
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo dnf install -y libffi-devel
sudo dnf install -y python36-devel
sudo dnf install -y python3-pip
sudo dnf install -y git

bash install_ceph.sh

cd "${HOME}" || exit
git clone https://github.com/ceph/cbt.git
cd "${HOME}/cbt" || { echo "CBT clone failed (cbt directory not found)."; exit; }
pip3 install -r ../requirements.txt
bash setup.sh
#sudo mkdir -p /usr/local/lib/ceph/erasure-code
#sudo cp -r "${HOME}/ceph/build/lib/*" "/usr/local/lib/ceph/erasure-code"
