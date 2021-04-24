#!/bin/sh

# Arguments:
# $1 - IP/hostname to connect and install k3s to

while true
do
  # install k3s over SSH
  ssh -i ./.temp/ssh_keys/terraform -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$1 'curl -sfL https://get.k3s.io | sh -' && break

  echo "Waiting for remote host..."
  sleep 10
done

# save kubeconfig to ./.temp/
scp -i ./.temp/ssh_keys/terraform -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$1:/etc/rancher/k3s/k3s.yaml ./.temp/kubeconfig
sed -i "s/localhost/$1/g" ./.temp/kubeconfig
sed -i "s/127.0.0.1/$1/g" ./.temp/kubeconfig

while true
do
  # wait until cluster responds to requests
  kubectl --kubeconfig ./.temp/kubeconfig version && break

  echo "Waiting for remote host..."
  sleep 10
done

echo "k3s setup complete, cluster is now available."