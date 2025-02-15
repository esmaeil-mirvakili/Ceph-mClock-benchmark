#!/bin/bash

set -a && source .env && set +a

# List of required environment variables
REQUIRED_VARS=("client" "osds" "user")

# Flag to track missing variables
MISSING_VARS=()

# Check each variable
for VAR in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!VAR}" ]]; then
        echo "ERROR: Environment variable $VAR is not set!"
        MISSING_VARS+=("$VAR")
    fi
done

# If any variables are missing, exit with an error
if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
    echo -e "Missing environment variables: ${MISSING_VARS[*]}"
    echo "You can define them in a .env file."
    exit 1
fi

run_on_all() {
  command=$1
  echo "Running $command on client..."
  ssh "$user@$client" "$command"
  num=0
  for osd in $osds; do
    echo "Running $command on ods$num..."
    ssh "$user@$osd" "$command"
    (( num++ ))
  done
}

run_on_all_screen() {
  command=$1
  session_name=$2
  run_on_all "screen -dmS ${session_name} bash -c '${command}; exec bash'"
}

wait_for_node_reboot() {
  node=$1
  name=$2
  echo "Waiting for $name it to come back online..."

  # Wait for the node to come back online
  while ! ping -c 1 "$node" &>/dev/null; do
      sleep 2
  done

  echo "$name is back online! Waiting for SSH to be ready..."

  # Wait for SSH to be available
  while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes $user@$node "exit" 2>/dev/null; do
      sleep 5
  done

  echo "$name is fully back online with SSH access!"
}

scp_to_all() {
  file=$1
  echo "Sending $file to client..."
  scp "$file" "$user@$client:~"
  num=0
  for osd in $osds; do
    echo "Sending $file to osd$num..."
    scp "$file" "$user@$osd:~"
    (( num++ ))
  done
}

echo "Check the disks..."
run_on_all "lsblk -o NAME,ROTA"

echo "Installing screen on nodes..."
run_on_all "sudo yum install screen -y"

echo "Setting up ssh keys in the cluster..."
bash setup_ssh.sh

echo "Preparing scripts on all nodes..."
run_on_all "git clone https://github.com/esmaeil-mirvakili/Ceph-mClock-benchmark.git"
run_on_all "cp Ceph-mClock-benchmark/scripts_centos/*.sh ."
run_on_all "cp Ceph-mClock-benchmark/workloads/cbt.yaml ."
run_on_all "cp Ceph-mClock-benchmark/workloads/ceph.conf ."


echo "Resting the disks..."
run_on_all "bash reset_disk.sh /dev/sda"

sleep 10

wait_for_node_reboot "$client" "client0"
num=0
for osd in $osds; do
  wait_for_node_reboot "$osd" "osd$num"
  (( num++ ))
done

echo "Resizing the /dev/sda1..."
run_on_all "sudo resize2fs /dev/sda1"

echo "Nodes setup started..."
run_on_all_screen "USER_NAME=$user bash setup_node.sh" "install_node"

echo "Installation is running on nodes in screen named 'install_node'."