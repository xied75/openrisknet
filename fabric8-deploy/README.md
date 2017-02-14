### Prerequisites

1. A fresh **Ubuntu 16.04 LTS** (Xenial) machine

### Steps for k8s master node, simpler way
(assume running as user *root*, running from path *\root*)
```
export F8_DOMAINNAME="fabric8.coderobin.com"
curl -s https://raw.githubusercontent.com/xied75/openrisknet/master/fabric8-deploy/kubeadm-master.sh | sh
```
If you don't have a domain ready, run the ```curl``` line only.

### Steps for k8s master node, manual

(assume running as user *root*, running from path *\root*)
```
mkdir /root/f8; cd /root/f8;

apt update; apt upgrade -y; apt install apt-transport-https jq -y;

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install docker.io kubelet kubeadm kubectl kubernetes-cni -y

source <(kubectl completion bash)
echo "" >> /root/.bashrc
echo 'source <(kubectl completion bash)' >> /root/.bashrc

# take a note of the output especially the token
kubeadm init --pod-network-cidr 10.244.0.0/16

curl -OL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl create -f kube-flannel.yml

# only run this if you allow regular pods on master
kubectl taint nodes --all dedicated-

touch /root/K8_MASTER

# k8s master deployment is done here, now we deploy fabric8.io

curl -OL $(curl -s https://api.github.com/repos/fabric8io/gofabric8/releases/latest | jq -r ".assets[] | select(.name | test(\"linux-amd64$\")) | .browser_download_url")
chmod +x gofabric8-linux-amd64
ln gofabric8-linux-amd64 /usr/local/bin/gofabric8

# if you don't have a domain to use, remove ```--domain example.yourdomain.com```
gofabric8 deploy --domain example.yourdomain.com -y --open-console=false
gofabric8 volumes
gofabric8 validate
```

### Steps for k8s worker node
(assume running as root, running from \root)
```
apt update; apt upgrade -y; apt install apt-transport-https jq -y;

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install docker.io kubelet kubeadm kubectl kubernetes-cni -y

kubeadm join --token=89562f.0a74036b799f1572 10.4.66.71
```
If you've taken note of the ```kubeadm init``` output, you can use the join line here, otherwise you can find the token by running this on the master node:
```
kubectl -n kube-system get secret clusterinfo -o json | jq -r ".data.\"token-map.json\"" | base64 -d | sed "s|{||g;s|}||g;s|:|.|g;s/\"//g;" | xargs echo
```
The ip address is your eth0 ip.

### Config dockerd to allow insecure repository

Use this to find out the service IP for registry service:
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
Replace the ip with output from first command, then run
```
systemctl restart docker.service
```
Note: this will trigger all pods on current node quit and start afresh. If you don't want this, you can change the file to this:
```
{
    "insecure-registries": [
        "10.96.0.0/12"
    ]
}
```
And run this plus the ```systemctl``` immediately after you've installed docker. No need to replace the IP cidr here.

### References

1. https://kubernetes.io/docs/getting-started-guides/kubeadm/
2. https://github.com/fabric8io/gofabric8/
