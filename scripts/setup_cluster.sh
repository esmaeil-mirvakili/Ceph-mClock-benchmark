#!/bin/bash

if [ -z "$1" ]; then
  remote_home="~"
else
  remote_home=$1
fi
if [ -z "$2" ]; then
  nodes_path="nodes.txt"
else
  nodes_path=$2
fi
if [ -z "$3" ]; then
  ssh_key="id_rsa"
else
  ssh_key=$3
fi
if [ -z "$4" ]; then
  osd_devices="sdc"
else
  osd_devices=$4
fi

touch ~/.ssh/id_rsa
mv ~/.ssh/id_rsa ~/.ssh/id_rsa.bak
cp "${ssh_key}" ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
mkdir /etc/ceph
cp ../benchmark/jobs/ceph.conf /etc/ceph/ceph.conf

nodes=$(cat "$nodes_path")
for node in $nodes; do
  echo "Node $node :"
  host_name=$(ssh "${node}" 'hostname')
  echo "setting up ssh keys on $host_name..."
  scp -p ~/.ssh/id_rsa "${node}":"$remote_home"/.ssh
  ssh "${node}" "chmod 0600 $remote_home/.ssh/id_rsa"
  scp -p ~/.ssh/known_hosts "${node}":"$remote_home"/.ssh

  echo "labeling partitions on $host_name..."
  scp -p mkpartition.sh "${node}":"$remote_home"
  ssh "${node}" "/bin/bash mkpartition.sh $osd_devices"

  echo "installing ceph on $host_name..."
  scp -p install_ceph.sh "${node}":"$remote_home"
  ssh "${node}" '/bin/bash install_ceph.sh'

#  ssh "${node}" $'echo \'export PATH="~/ceph/build/bin:$PATH"\' >> .bashrc'
  scp -p register_ceph_commands.sh "${node}":"$remote_home"
  ssh "${node}" "/bin/bash register_ceph_commands.sh $remote_home"
  scp -p ../benchmark/jobs/ceph.conf "${node}":/etc/ceph/ceph.conf
done
