#!/bin/bash

if [ -z "$1" ]; then
  nodes_path="nodes.txt"
else
  nodes_path=$1
fi
if [ -z "$2" ]; then
  ssh_key="id_rsa"
else
  ssh_key=$2
fi
if [ -z "$3" ]; then
  osd_devices="sdc"
else
  osd_devices=$3
fi

touch ~/.ssh/id_rsa
mv ~/.ssh/id_rsa ~/.ssh/id_rsa.bak
cp "${ssh_key}" ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa

cp ../benchmark/jobs/ceph.conf /etc/ceph/ceph.conf

nodes=$(cat "$nodes_path")
for node in $nodes; do
  echo "Node $node :"
  host_name=$(ssh "${node}" 'hostname')
  echo "setting up ssh keys on $host_name..."
  scp -p ~/.ssh/id_rsa "${node}":~/.ssh/
  ssh "${node}" 'chmod 0600 ~/.ssh/id_rsa'
  scp -p ~/.ssh/known_hosts "${node}":~/.ssh/

  echo "labeling partitions on $host_name..."
  scp -p mkpartition.sh "${node}":~
  ssh "${node}" "/bin/bash mkpartition.sh $osd_devices"

  echo "installing ceph on $host_name..."
  scp -p install_ceph.sh "${node}":~
  ssh "${node}" '/bin/bash install_ceph.sh'
  ssh "${node}" $'echo \'export PATH="~/ceph/build/bin:$PATH"\' >> .bashrc'

  scp -p ../benchmark/jobs/ceph.conf "${node}":/etc/ceph/ceph.conf
done
