### Prerequisites

1. A fresh **Ubuntu 16.04 LTS** (Xenial) vm

### Steps for k8s master node

(assume running as root, running from \root)
```
apt update; apt upgrade -y; apt install apt-transport-https -y;

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install docker.io -y

mkdir f8; cd f8

apt install kubelet kubeadm kubectl kubernetes-cni -y
source <(kubectl completion bash)
kubeadm init --pod-network-cidr 10.244.0.0/16

curl -OL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl create -f kube-flannel.yml

touch /root/K8_MASTER

curl -OL https://github.com/fabric8io/gofabric8/releases/download/v0.4.115/gofabric8-linux-amd64
chmod +x gofabric8-linux-amd64
ln gofabric8-linux-amd64 /usr/local/bin/gofabric8

kubectl get pods --all-namespaces

gofabric8 deploy --domain fabric8.coderobin.com -y --open-console false
gofabric8 volumes
gofabric8 validate
```

### Steps for k8s worker node
(assume running as root, running from \root)
```
apt update; apt upgrade -y; apt install apt-transport-https -y;

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install docker.io -y

apt install kubelet kubeadm kubectl kubernetes-cni -y
kubeadm join --token=89562f.0a74036b799f1572 10.4.66.71
```
(The token above is the output from previous step when you called ```kubeadm init```)

### Config dockerd to allow insecure repository

```
kubectl get svc fabric8-docker-registry --output template --template={{.spec.clusterIP}}
```

Check if you already have a /etc/docker/daemon.json, if not, create with this content:

```
{
    "insecure-registries": [
        "10.97.81.233:80"
    ]
}
```
Replace the ip with output from first command
