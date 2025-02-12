#!/bin/bash

set -a && source .env && set +a

setup_server() {
  server=$1
  server_name=$2
  key=$3
  echo "Setting up $server_name..."
  ssh "$user@$server" "echo '$key' >> ~/.ssh/authorized_keys"
  ssh "$user@$client" "ssh-keyscan -H $server_name >> ~/.ssh/known_hosts"
  authorized_keys=$(ssh "$user@$server" 'cat ~/.ssh/authorized_keys')
  if [[ $authorized_keys == *"$key"* ]]; then
    echo "$server_name is done."
  else
    echo "$server_name setup failed."
    exit 1
  fi
}

ssh "$user@$client" "rm -f ~/.ssh/id_rsa*"
ssh "$user@$client" "ssh-keygen -t rsa -q -N '' -f ~/.ssh/id_rsa"
rsa_key=$(ssh "$user@$client" 'cat ~/.ssh/id_rsa.pub')

setup_server "$client" "client0" "$rsa_key"

num=0
for osd in $osds; do
  setup_server "$osd" "osd$num" "$rsa_key"
  (( num++ ))
done
