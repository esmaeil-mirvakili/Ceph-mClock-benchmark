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
  osd_devices="sdc"
else
  osd_devices=$3
fi

mkdir /etc/ceph
cp ../benchmark/jobs/ceph.conf /etc/ceph/ceph.conf

nodes=$(cat "$nodes_path")
for node in $nodes; do
  echo "Node $node :"
  ssh -oStrictHostKeyChecking=no "$node" 'hostname'

  echo "labeling partitions on $node..."
  scp -p mkpartition.sh "${node}":"$remote_home"
  ssh "${node}" "cd $remote_home; /bin/bash mkpartition.sh $osd_devices"

  echo "installing ceph on $node..."
  scp -p install_ceph.sh "${node}":"$remote_home"
  ssh "${node}" "cd $remote_home; /bin/bash install_ceph.sh $remote_home"
  ssh "${node}" "sudo ln -s $remote_home/ceph/build/bin/* /usr/local/bin"

  echo "copying ceph config"
  ssh "${node}" "mkdir /etc/ceph"
  scp -p ../benchmark/jobs/ceph.conf "${node}":/etc/ceph/ceph.conf
done
