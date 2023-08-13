#!/bin/bash

user="esmaeil"
osds="c220g2-010808.wisc.cloudlab.us c220g2-010804.wisc.cloudlab.us c220g2-010805.wisc.cloudlab.us c220g2-010810.wisc.cloudlab.us "
client="c220g2-010802.wisc.cloudlab.us"

ssh "$user@$client" 'ssh-keygen -t rsa -q -N '' -f ~/.ssh/id_rsa'
rsa_key=$(ssh "$user@$client" 'cat ~/.ssh/id_rsa.pub')
ssh "$user@$client" "echo '$rsa_key' >> ~/.ssh/authorized_keys"
ssh "$user@$client" 'ssh -o StrictHostKeyChecking=no client0'

num=0
for osd in $osds; do
  ssh "$user@$osd" "echo '$rsa_key' >> ~/.ssh/authorized_keys"
  ssh "$user@$client" "ssh -o StrictHostKeyChecking=no osd$num"
  (( num++ ))
done
