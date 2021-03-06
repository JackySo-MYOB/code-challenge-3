#!/bin/bash -ve
touch /home/ubuntu/master.log

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
touch /etc/apt/sources.list.d/kubernetes.list

su -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> \
    /etc/apt/sources.list.d/kubernetes.list"

# Install Helm v2 binary
curl -s https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

# Install fluxctl binary
wget -O /usr/local/bin/fluxctl https://github.com/fluxcd/flux/releases/download/1.17.0/fluxctl_linux_amd64 && chmod a+x /usr/local/bin/fluxctl

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
echo '[Finished] Installing kubelet kubeadm kubectl kubernetes-cni docker' >> /home/ubuntu/master.log

# Install etcdctl for the version of etcd we're running
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=$${GOOGLE_URL}

ETCD_VER=v$(kubeadm config images list | grep etcd | cut -d':' -f2 | cut -d'-' -f1)
curl -L $${DOWNLOAD_URL}/$${ETCD_VER}/etcd-$${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1
rm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz

echo '[Finished] Installing etcdctl' >> /home/ubuntu/master.log

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
echo '[Finished] docker configure' >> /home/ubuntu/master.log

# Point kubelet at big ephemeral drive
mkdir /mnt/kubelet
echo 'KUBELET_EXTRA_ARGS="--root-dir=/mnt/kubelet --cloud-provider=aws"' > /etc/default/kubelet
echo '[Finished] kubelet configure' >> /home/ubuntu/master.log

# ----------------- from here same with worker.sh

cat >init-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: "${k8stoken}"
  ttl: "0"
nodeRegistration:
  name: "$(hostname -f)"
  taints: []
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServerExtraArgs:
  cloud-provider: aws
controllerManagerExtraArgs:
  cloud-provider: aws
networking:
  podSubnet: 10.244.0.0/16
EOF

kubeadm init --config=/init-config.yaml --ignore-preflight-errors=NumCPU
touch /tmp/fresh-cluster
echo '[Finished] created kubeadm cluster' >> /home/ubuntu/master.log

# Pass bridged IPv4 traffic to iptables chains (required by Flannel like the above cidr setting)
echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/60-flannel.conf
service procps start

# Set up kubectl for the ubuntu user
mkdir -p /home/ubuntu/.kube && cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config && chown -R ubuntu. /home/ubuntu/.kube
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo '[Finished] Now you can use kubectl, try : kubectl get nodes' >> /home/ubuntu/master.log

if [ -f /tmp/fresh-cluster ]; then
  # su -c 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml' ubuntu
  su -c 'kubectl apply -f https://docs.projectcalico.org/manifests/canal.yaml' ubuntu
  echo '[Finished] All nodes are ready' >> /home/ubuntu/master.log
  # su -c 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml' ubuntu
  # su -c 'kubectl apply -f https://raw.githubusercontent.com/graykode/aws-kubeadm-terraform/master/service-l7.yaml' ubuntu
  # su -c 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l4.yaml' ubuntu
fi
