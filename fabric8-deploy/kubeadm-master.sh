#!/bin/bash

apt update; apt upgrade -y; apt install apt-transport-https jq -y;

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install docker.io -y

mkdir /root/f8; cd /root/f8;

apt install kubelet kubeadm kubectl kubernetes-cni -y

echo "" >> /root/.bashrc
echo 'source <(kubectl completion bash)' >> /root/.bashrc

kubeadm init --pod-network-cidr 10.244.0.0/16

curl -OL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl create -f kube-flannel.yml

touch /root/K8_MASTER

curl -OL $(curl -s https://api.github.com/repos/fabric8io/gofabric8/releases/latest | jq -r ".assets[] | select(.name | test(\"linux-amd64$\")) | .browser_download_url")
chmod +x gofabric8-linux-amd64
ln gofabric8-linux-amd64 /usr/local/bin/gofabric8

if [ -z $F8_DOMAINNAME ]; then
  gofabric8 deploy -y --open-console false;
else
  gofabric8 deploy --domain $F8_DOMAINNAME -y --open-console false;
fi

gofabric8 volumes
gofabric8 validate