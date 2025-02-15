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


ssh_to_node() {
  local node=$1
  local command=$2
  local name=$3
  ssh "$user@$node" "$command"
}


run_on_all() {
  local command=$1
  echo "Running $command on client..."
  ssh_to_node "$client" "$command" "client0"
  num=0
  for osd in $osds; do
    echo "Running $command on ods$num..."
    ssh_to_node "$osd" "$command" "ods$num"
    (( num++ ))
  done
}

run_on_all_screen() {
  local command=$1
  local session_name=$2
  run_on_all "screen -dmS ${session_name} bash -c '${command}; exec bash'"
}

wait_for_node_reboot() {
  local node=$1
  local name=$2
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
  local file=$1
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
run_on_all "cp Ceph-mClock-benchmark/scripts_centos9/*.sh ."
run_on_all "cp Ceph-mClock-benchmark/workloads/cbt.yaml ."
run_on_all "cp Ceph-mClock-benchmark/workloads/ceph.conf ."

declare -A IPS
IPS["client0"]="10.10.1.2"
IPS["osd0"]="10.10.1.1"
IPS["osd1"]="10.10.1.3"
IPS["osd2"]="10.10.1.4"
IPS["osd3"]="10.10.1.5"

echo "Creating .env files on nodes..."
name="client0"
ip=${IPS[$name]}
cmd="echo IP_ADDRESS=$ip | sudo tee .env"
ssh_to_node "$client" "$cmd" "$name"
num=0
for osd in $osds; do
  name="osd$num"
  ip=${IPS[$name]}
  cmd="echo IP_ADDRESS=$ip | sudo tee .env"
  echo "Running $command on $name..."
  ssh_to_node "$osd" "$cmd" "$name"
  (( num++ ))
done

run_on_all "cat .env"

echo "Nodes setup started..."
run_on_all_screen "USER_NAME=$ceph_user bash setup_node.sh > install.log" "install_node"

echo "Installation is running on nodes in screen named 'install_node'."