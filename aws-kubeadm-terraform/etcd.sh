#!/bin/bash -ve
touch /home/ubuntu/etcd.log

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
touch /etc/apt/sources.list.d/kubernetes.list

su -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> \
    /etc/apt/sources.list.d/kubernetes.list"

# Install and start SSM agent 
curl "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb" -o "amazon-ssm-agent.deb"
apt-get install -y ./amazon-ssm-agent.deb && systemctl start amazon-ssm-agent.service
useradd -m -d /home/ec2-user -s /bin/bash ec2-user
useradd -m -d /home/ssm-user -s /bin/bash ssm-user
echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ssm-agent-users
echo "ec2-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ec2-user

# Install kubelet kubeadm kubectl kubernetes-cni docker
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
curl -sSL https://get.docker.com/ | sh
systemctl start docker
echo '[Finished] Installing kubelet kubeadm kubectl kubernetes-cni docker' >> /home/ubuntu/etcd.log

# Install etcdctl for the version of etcd we're running
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=$${GOOGLE_URL}

ETCD_VER=v$(kubeadm config images list | grep etcd | cut -d':' -f2 | cut -d'-' -f1)
curl -L $${DOWNLOAD_URL}/$${ETCD_VER}/etcd-$${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
echo '[Finished] Installing etcdctl' >> /home/ubuntu/etcd.log

systemctl stop docker
mkdir /mnt/docker
chmod 711 /mnt/docker
cat <<EOF > /etc/docker/daemon.json
{
    "data-root": "/mnt/docker",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "5"
    }
}
EOF
systemctl start docker
systemctl enable docker
echo '[Finished] docker configure' >> /home/ubuntu/etcd.log

# Point kubelet at big ephemeral drive
mkdir /mnt/kubelet
echo 'KUBELET_EXTRA_ARGS="--root-dir=/mnt/kubelet --cloud-provider=aws"' > /etc/default/kubelet
echo '[Finished] kubelet configure' >> /home/ubuntu/etcd.log

# ----------------- from here same with etcd.sh

# Pass bridged IPv4 traffic to iptables chains (required by Flannel)
echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/60-flannel.conf
service procps start

echo '[Wait] kubeadm join until kubeadm cluster have been created.' >> /home/ubuntu/etcd.log
for i in {1..50}; do sudo kubeadm join --token=${k8stoken} --discovery-token-unsafe-skip-ca-verification --node-name=$(hostname -f) ${masterIP}:6443 && break || sleep 15; done
