#!/bin/bash

if [ -z "$HOME_LOC" ]; then
  HOME_LOC="${HOME}"
fi

device_list=$(nmcli --terse --fields DEVICE device status)

# Initialize an associative array for storing IPs
declare -A device_ips

# Loop through each device and get its IP address
for device in $device_list; do
    ip_address=$(nmcli -g IP4.ADDRESS device show "$device" | awk -F'/' '{print $1}')

    # Store in associative array
    device_ips["$device"]=$ip_address
done
nmcli d
echo "Network Devices and their IP Addresses:"
for device in "${!device_ips[@]}"; do
    echo "$device -> ${device_ips[$device]:-No IP Assigned}"
done

sudo yum check-update
sudo yum update -y
sleep 10
nmcli d
disconnected_devices=$(nmcli device status | awk '$3 == "disconnected" {print $1}')

# Check if there are any disconnected devices
if [[ -z "$disconnected_devices" ]]; then
    echo "No disconnected devices found."
else
    echo "Disconnected Network Devices:"
    echo "$disconnected_devices"
    echo "Restoring the network"
    sudo nmcli con add type ethernet ifname "$disconnected_devices" con-name "$disconnected_devices"
    sudo nmcli con up enp6s0f1
    sudo nmcli con modify "$disconnected_devices" ipv4.method manual ipv4.addresses "${device_ips[$device]:-No IP Assigned}"/24 ipv4.gateway 10.10.1.1 ipv4.dns 8.8.8.8
    sudo nmcli con up enp6s0f1
    nmcli d
fi

sudo yum groupinstall -y "Development Tools"
sudo yum install -y libffi-devel python-devel python3-pip targetcli librados2 librbd1 sysstat

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


