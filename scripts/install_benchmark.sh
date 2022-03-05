sudo apt update
sudo apt -y upgrade
sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
sudo apt install -y python3-pip
sudo apt-get install -y git
cp ubuntu_cbt_setup.sh "${HOME}"
cd "${HOME}" || exit
git clone https://github.com/ceph/cbt.git
mv ubuntu_cbt_setup.sh "${HOME}/cbt/"
cd "${HOME}/cbt" || { echo "CBT clone failed (cbt directory not found)."; exit; }
pip3 install -r requirements.txt
/bin/bash ubuntu_cbt_setup.sh
