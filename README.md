# code-challenge-3
Code challenge on CI pipeline and gitops practices

## Task requirements

1. Create a simple application which has a single “/version” endpoint.
2. Containerise your application as a single deployable artefact, encapsulating all dependencies.
3. Create a CI pipeline for your application
4. Have your container deployed into a Kubernetes cluster.

### Code structures

```
.
├── aws-kubeadm-terraform
│   ├── 0-aws.tf
│   ├── 1-vpc.tf
│   ├── 2-etcd.tf
│   ├── 3-workers.tf
│   ├── 4-controllers.tf
│   ├── 5-iam.tf
│   ├── 6-elb.tf
│   ├── 7-kubeadm.tf
│   ├── etcd.sh
│   ├── master.sh
│   ├── service-l7.yaml
│   ├── tf-kube
│   ├── tf-kube.pub
│   ├── variables.tf
│   └── worker.sh
├── Dockerfile
├── Makefile
├── package.json
├── README.md
├── server.js
└── yaml
    ├── node-web.yaml
    └── template.yaml
```

### Task: Create a simple application which has a single “/version” endpoint

#### Codes and files used in this section

```diff
├── package.json
├── server.js


+install-dep                              Intall nodejs dependencies in package.json
+update-version                           Update node pakage.json version in package.json
+run-node                                 Run nodejs application $(APPS)
+kill-node                                Kill nodejs process
```

#### Operation and demonstration

```bash
$ make install-dep
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN code_challenge_node_app@1.0.0 No repository field.
npm WARN code_challenge_node_app@1.0.0 No license field.

added 50 packages from 37 contributors and audited 50 packages in 3.374s
found 0 vulnerabilities

$ make run-node

{
  "myapplication": [
    {
      "version": "1.0.0",
      "lastcommitsha": "805a297",
      "description": "pre-interview technical test"
    }
  ]
}

$ ps -ef | grep node
jso        19518    1376  0 22:05 pts/0    00:00:00 node server.js
jso        19563   16478  0 22:08 pts/0    00:00:00 grep --color=auto node
$ make kill-node
$ ps -ef | grep node
jso        19575   16478  0 22:08 pts/0    00:00:00 grep --color=auto node

$ make update-version
v1.0.3

$ make run-node

{
  "myapplication": [
    {
      "version": "1.0.3",
      "lastcommitsha": "ebe7643",
      "description": "pre-interview technical test"
    }
  ]
}

$ git rev-parse --short HEAD
ebe7643

$ grep version package.json
  "version": "1.0.3",

$ make kill-node
```

### Task: Containerize nodejs application

#### Codes and files used
```diff
├── Dockerfile


+docker-build                             Build the docker image
+docker-shell                             Run bash shell in docker
+docker-registry-shell                    Run bash shell in docker pull from registry
+docker-run                               Run the docker
+docker-registry-run                      Run docker pull from registry
+docker-login                             Logon docker registry docker.io
+docker-push                              Build docker image and push to registry docker.io
```

#### Operation and demonstration

```bash

$ make docker-build
Sending build context to Docker daemon  2.128MB
Step 1/9 : FROM node:10
10: Pulling from library/node
7919f5b7d602: Pull complete 
0e107167dcc5: Pull complete 
66a456bba435: Pull complete 
5435318a0426: Pull complete 
8494dd328465: Pull complete 
3b01939c6506: Pull complete 
cea1862d3fdb: Pull complete 
3ff2b5bfcd35: Pull complete 
d8d433ddc7ef: Pull complete 
Digest: sha256:14fa22a8989cd64ce811db9d47e3ed2910e0f2d95323240e23bc928201bbf313
Status: Downloaded newer image for node:10
 ---> 2db91b8e7c1b
Step 2/9 : WORKDIR /usr/src
 ---> Running in 1c47dea75dea
Removing intermediate container 1c47dea75dea
 ---> 3a9b5eb002d3
Step 3/9 : RUN git clone https://github.com/JackySo-MYOB/code-challenge-3.git app
 ---> Running in cfea4b31a64e
Cloning into 'app'...
Removing intermediate container cfea4b31a64e
 ---> 1026458c18be
Step 4/9 : WORKDIR /usr/src/app
 ---> Running in adea452188d9
Removing intermediate container adea452188d9
 ---> dcd0f55d3938
Step 5/9 : COPY package*.json ./
 ---> c140d2b184c7
Step 6/9 : RUN npm install
 ---> Running in a26932131efb
npm WARN code_challenge_node_app@1.0.3 No repository field.
npm WARN code_challenge_node_app@1.0.3 No license field.

added 50 packages from 37 contributors and audited 50 packages in 1.828s
found 0 vulnerabilities

Removing intermediate container a26932131efb
 ---> d044dde08a8d
Step 7/9 : COPY . .
 ---> 7ab3f7e23126
Step 8/9 : EXPOSE 8080
 ---> Running in ae51806fffc7
Removing intermediate container ae51806fffc7
 ---> 9f04a794a279
Step 9/9 : CMD [ "node", "server.js" ]
 ---> Running in 5e2ab4c5c476
Removing intermediate container 5e2ab4c5c476
 ---> 32bfabc9944c
Successfully built 32bfabc9944c
Successfully tagged jackyso/node-web:1.0.3

$ make docker-shell
root@2955efedaf7b:/usr/src/app# ls
Dockerfile  Makefile  README.md  node_modules  package-lock.json  package.json	server.js  yaml
root@2955efedaf7b:/usr/src/app# exit
exit

$ make validate-app
{ "myapplication": [ {
      "version": "1.0.3",
      "lastcommitsha": "727a24b",
      "description": "pre-interview technical test"
    }
  ]
}
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-stop
fe963d2445c6

$ make docker-push
Password: 
WARNING! Your password will be stored unencrypted in /home1/jso/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
The push refers to repository [docker.io/jackyso/node-web]
a102875cd3bf: Pushed 
38d5e7104897: Pushed 
70e6a3a0c98e: Pushed 
497450c18c0d: Pushed 
982ea30af730: Layer already exists 
a047f6fe27f5: Layer already exists 
f5211c608ae5: Layer already exists 
0c6d2a8d3a7e: Layer already exists 
6ad22fbe53ce: Layer already exists 
f04853d2d299: Layer already exists 
9f07fffa6fe1: Layer already exists 
6c5a5125b341: Layer already exists 
26711ab4f3b6: Layer already exists 
1.0.3: digest: sha256:d80300e2337eca8af2dea8ba9a3d7b97c8e620136ff1c3abba51d915d164645c size: 3053

$ make docker-registry-run
Run docker container and use other terminal to validate app and stop container
Unable to find image 'jackyso/node-web:1.0.3' locally
1.0.3: Pulling from jackyso/node-web
7919f5b7d602: Already exists 
0e107167dcc5: Already exists 
66a456bba435: Already exists 
5435318a0426: Already exists 
8494dd328465: Already exists 
3b01939c6506: Already exists 
cea1862d3fdb: Already exists 
3ff2b5bfcd35: Already exists 
d8d433ddc7ef: Already exists 
da2cce1c8d04: Pull complete 
0046d185e8e2: Pull complete 
82444b6bbad8: Pull complete 
43fe5691178a: Pull complete 
Digest: sha256:d80300e2337eca8af2dea8ba9a3d7b97c8e620136ff1c3abba51d915d164645c
Status: Downloaded newer image for jackyso/node-web:1.0.3

$ make validate-app
{
  "myapplication": [
    {
      "version": "1.0.3",
      "lastcommitsha": "727a24b",
      "description": "pre-interview technical test"
    }
  ]
}
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-stop
0e579fdcbfa8

$ make docker-image-rm
Untagged: jackyso/node-web:1.0.3
Untagged: jackyso/node-web@sha256:d80300e2337eca8af2dea8ba9a3d7b97c8e620136ff1c3abba51d915d164645c
Deleted: sha256:3d8916137a6641e42714727b9a68a09a44742511624f3e4023f29a7700ad502b
Deleted: sha256:e022e23f6890e8a67621de8117592b00432a3b41e81924d58c6465131ed7eea0
Deleted: sha256:0c34b73e3a9b24eda9f2eb79af8a9cae7025e715bafdd21100a0b6834b6ec2c4
Deleted: sha256:c816fa3af0e3a8601a9dce828738e65a438df1822280db14c8bdf35af9319695
Deleted: sha256:3de39bd7828f6aa8b756c889e2d2abd9fc651e195490315aef3be6591078fd56


$ make update-version
v1.0.4

$ make docker-build
Sending build context to Docker daemon  2.159MB
Step 1/9 : FROM node:10
 ---> 2db91b8e7c1b
Step 2/9 : WORKDIR /usr/src
 ---> Running in 73718d3ac8fc
Removing intermediate container 73718d3ac8fc
 ---> 8f5de027a68a
Step 3/9 : RUN git clone https://github.com/JackySo-MYOB/code-challenge-3.git app
 ---> Running in dd459aa42173
Cloning into 'app'...
Removing intermediate container dd459aa42173
 ---> 8ef6f788a15f
Step 4/9 : WORKDIR /usr/src/app
 ---> Running in cd0c48e73a62
Removing intermediate container cd0c48e73a62
 ---> 27e9dcd9fde5
Step 5/9 : COPY package*.json ./
 ---> 166959f34f7c
Step 6/9 : RUN npm install
 ---> Running in 65bd31bbafda
npm WARN code_challenge_node_app@1.0.4 No repository field.
npm WARN code_challenge_node_app@1.0.4 No license field.

added 50 packages from 37 contributors and audited 50 packages in 1.793s
found 0 vulnerabilities

Removing intermediate container 65bd31bbafda
 ---> 2a78b8e01aba
Step 7/9 : COPY . .
 ---> 983c1266cf1d
Step 8/9 : EXPOSE 8080
 ---> Running in c204326b418f
Removing intermediate container c204326b418f
 ---> 65b7d7151a78
Step 9/9 : CMD [ "node", "server.js" ]
 ---> Running in 74c83f7716d9
Removing intermediate container 74c83f7716d9
 ---> 0eee0e91e84b
Successfully built 0eee0e91e84b
Successfully tagged jackyso/node-web:1.0.4
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-push
Password: 
WARNING! Your password will be stored unencrypted in /home1/jso/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
The push refers to repository [docker.io/jackyso/node-web]
f3bd23cf722f: Pushed 
3e6acc2d58db: Pushed 
6a9b0a4da5f2: Pushed 
2be3d60973dc: Pushed 
982ea30af730: Layer already exists 
a047f6fe27f5: Layer already exists 
f5211c608ae5: Layer already exists 
0c6d2a8d3a7e: Layer already exists 
6ad22fbe53ce: Layer already exists 
f04853d2d299: Layer already exists 
9f07fffa6fe1: Layer already exists 
6c5a5125b341: Layer already exists 
26711ab4f3b6: Layer already exists 
1.0.4: digest: sha256:fcb7695551556d90a2e062ca963abd408b5974b5c3847dc866aa7a51eb18d6a6 size: 3053

$ make docker-registry-run
Run docker container and use other terminal to validate app and stop container
Unable to find image 'jackyso/node-web:1.0.4' locally
1.0.4: Pulling from jackyso/node-web
7919f5b7d602: Already exists 
0e107167dcc5: Already exists 
66a456bba435: Already exists 
5435318a0426: Already exists 
8494dd328465: Already exists 
3b01939c6506: Already exists 
cea1862d3fdb: Already exists 
3ff2b5bfcd35: Already exists 
d8d433ddc7ef: Already exists 
51db6b5ca635: Pull complete 
0da20a5779e5: Pull complete 
cb788050c1d1: Pull complete 
a8024f994c40: Pull complete 
Digest: sha256:fcb7695551556d90a2e062ca963abd408b5974b5c3847dc866aa7a51eb18d6a6
Status: Downloaded newer image for jackyso/node-web:1.0.4

$ make validate-app
{
  "myapplication": [
    {
      "version": "1.0.4",
      "lastcommitsha": "6a8824f",
      "description": "pre-interview technical test"
    }
  ]
}
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-stop
f3876c164d43

```

### Task: Have your container deployed into a Kubernetes cluster.

#### Codes and files used

```diff
├── aws-kubeadm-terraform
│   ├── 0-aws.tf
│   ├── 1-vpc.tf
│   ├── 2-etcd.tf
│   ├── 3-workers.tf
│   ├── 4-controllers.tf
│   ├── 5-iam.tf
│   ├── 6-elb.tf
│   ├── 7-kubeadm.tf
│   ├── etcd.sh
│   ├── master.sh
│   ├── service-l7.yaml
│   ├── tf-kube
│   ├── tf-kube.pub
│   ├── variables.tf
│   └── worker.sh

kubeadm-terraform-shell                  Run docker kubeadm-terraform and /bin/bash
+kubeadm-terraform-genkey                 Run docker kubeadm-terraform and generate key
+kubeadm-terraform-token                  Run docker kubeadm-terraform and generate k8s token
+kubeadm-terraform-state                  Query terraform state
+kubeadm-terraform-deploy                 Run terraform init and deploy
+kubeadm-terraform-undeploy               Run terraform init and destroy
master-ip                                Run terraform output master node public IP
worker-ip                                Run terraform output worker node public IP
+ssh-master                               SSH into Kubernetes master node
+ssh-worker                               SSH into Kubernetes worker node
+kubectl-nodes                            SSH into Kubernetes master node and kubectl get nodes -o wide
kubectl-command                          SSH into Kubernetes master node and kubectl $(COMMAND)
+apply-node-web                           Copy node-web file to master and apply into cluster
+delete-node-web                          Delete node-web deployment from cluster
+get-pods                                 Get pods in default namespace

```

#### Operation and Demonstration

```bash

$ make kubeadm-terraform-genkey
Generating public/private rsa key pair.
Your identification has been saved in tf-kube.
Your public key has been saved in tf-kube.pub.
The key fingerprint is:
SHA256:hlvJSytFV+2n0cnQyWgW0OKlV5XJ5E4kSaI/I1Jdqg4 root@eb93ab0e17cb
The key's randomart image is:
+---[RSA 2048]----+
|           o=*Oo*|
|          oo+O=O |
|        .ooo*.++.|
|       +.ooo .=oo|
|      .ESo +.  = |
|       *+o. o .  |
|      o o.       |
|       .         |
|                 |
+----[SHA256]-----+

$ make kubeadm-terraform-token
d7dd14.55fbb69d581e8917



$ make kubeadm-terraform-deploy
--- Terraform Deploy 

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "template" (2.2.0)...
- Downloading plugin for provider "aws" (2.70.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.70"
* provider.template: version = "~> 2.2"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
var.k8stoken
  Enter a value: d7dd14.55fbb69d581e8917

data.template_file.master-userdata: Refreshing state...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

 <= data.template_file.etcd-userdata
      id:                                          <computed>
      rendered:                                    <computed>
      template:                                    "#!/bin/bash -ve\ntouch /home/ubuntu/etcd.log\n\ncurl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -\ntouch /etc/apt/sources.list.d/kubernetes.list\n\nsu -c \"echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> \\\n    /etc/apt/sources.list.d/kubernetes.list\"\n\n# Install and start SSM agent \ncurl \"https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb\" -o \"amazon-ssm-agent.deb\"\napt-get install -y ./amazon-ssm-agent.deb && systemctl start amazon-ssm-agent.service\nuseradd -m -d /home/ec2-user -s /bin/bash ec2-user\nuseradd -m -d /home/ssm-user -s /bin/bash ssm-user\necho \"ssm-user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/ssm-agent-users\necho \"ec2-user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/ec2-user\n\n# Install kubelet kubeadm kubectl kubernetes-cni docker\napt-get update\napt-get install -y kubelet kubeadm kubectl kubernetes-cni\ncurl -sSL https://get.docker.com/ | sh\nsystemctl start docker\necho '[Finished] Installing kubelet kubeadm kubectl kubernetes-cni docker' >> /home/ubuntu/etcd.log\n\n# Install etcdctl for the version of etcd we're running\nGOOGLE_URL=https://storage.googleapis.com/etcd\nGITHUB_URL=https://github.com/etcd-io/etcd/releases/download\nDOWNLOAD_URL=$${GOOGLE_URL}\n\nETCD_VER=v$(kubeadm config images list | grep etcd | cut -d':' -f2 | cut -d'-' -f1)\ncurl -L $${DOWNLOAD_URL}/$${ETCD_VER}/etcd-$${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz\ntar xzvf /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1\nrm -f /tmp/etcd-$${ETCD_VER}-linux-amd64.tar.gz\necho '[Finished] Installing etcdctl' >> /home/ubuntu/etcd.log\n\nsystemctl stop docker\nmkdir /mnt/docker\nchmod 711 /mnt/docker\ncat <<EOF > /etc/docker/daemon.json\n{\n    \"data-root\": \"/mnt/docker\",\n    \"log-driver\": \"json-file\",\n    \"log-opts\": {\n        \"max-size\": \"10m\",\n        \"max-file\": \"5\"\n    }\n}\nEOF\nsystemctl start docker\nsystemctl enable docker\necho '[Finished] docker configure' >> /home/ubuntu/etcd.log\n\n# Point kubelet at big ephemeral drive\nmkdir /mnt/kubelet\necho 'KUBELET_EXTRA_ARGS=\"--root-dir=/mnt/kubelet --cloud-provider=aws\"' > /etc/default/kubelet\necho '[Finished] kubelet configure' >> /home/ubuntu/etcd.log\n\n# ----------------- from here same with etcd.sh\n\n# Pass bridged IPv4 traffic to iptables chains (required by Flannel)\necho \"net.bridge.bridge-nf-call-iptables = 1\" > /etc/sysctl.d/60-flannel.conf\nservice procps start\n\necho '[Wait] kubeadm join until kubeadm cluster have been created.' >> /home/ubuntu/etcd.log\nfor i in {1..50}; do sudo kubeadm join --token=${k8stoken} --discovery-token-unsafe-skip-ca-verification --node-name=$(hostname -f) ${masterIP}:6443 && break || sleep 15; done\n"
      vars.%:                                      "2"
      vars.k8stoken:                               "d7dd14.55fbb69d581e8917"
      vars.masterIP:                               "10.43.0.40"

 <= data.template_file.worker-userdata
      id:                                          <computed>
      rendered:                                    <computed>
      template:                                    "#!/bin/bash -ve\ntouch /home/ubuntu/worker.log\n\ncurl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -\ntouch /etc/apt/sources.list.d/kubernetes.list\n\nsu -c \"echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> \\\n    /etc/apt/sources.list.d/kubernetes.list\"\n\n# Install and start SSM agent \ncurl \"https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb\" -o \"amazon-ssm-agent.deb\"\napt-get install -y ./amazon-ssm-agent.deb && systemctl start amazon-ssm-agent.service\nuseradd -m -d /home/ec2-user -s /bin/bash ec2-user\nuseradd -m -d /home/ssm-user -s /bin/bash ssm-user\necho \"ssm-user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/ssm-agent-users\necho \"ec2-user ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/ec2-user\n\n# Install kubelet kubeadm kubectl kubernetes-cni docker\napt-get update\napt-get install -y kubelet kubeadm kubectl kubernetes-cni\ncurl -sSL https://get.docker.com/ | sh\nsystemctl start docker\necho '[Finished] Installing kubelet kubeadm kubectl kubernetes-cni docker' >> /home/ubuntu/worker.log\n\nsystemctl stop docker\nmkdir /mnt/docker\nchmod 711 /mnt/docker\ncat <<EOF > /etc/docker/daemon.json\n{\n    \"data-root\": \"/mnt/docker\",\n    \"log-driver\": \"json-file\",\n    \"log-opts\": {\n        \"max-size\": \"10m\",\n        \"max-file\": \"5\"\n    }\n}\nEOF\nsystemctl start docker\nsystemctl enable docker\necho '[Finished] docker configure' >> /home/ubuntu/worker.log\n\n# Point kubelet at big ephemeral drive\nmkdir /mnt/kubelet\necho 'KUBELET_EXTRA_ARGS=\"--root-dir=/mnt/kubelet --cloud-provider=aws\"' > /etc/default/kubelet\necho '[Finished] kubelet configure' >> /home/ubuntu/worker.log\n\n# ----------------- from here same with worker.sh\n\n# Pass bridged IPv4 traffic to iptables chains (required by Flannel)\necho \"net.bridge.bridge-nf-call-iptables = 1\" > /etc/sysctl.d/60-flannel.conf\nservice procps start\n\necho '[Wait] kubeadm join until kubeadm cluster have been created.' >> /home/ubuntu/worker.log\nfor i in {1..50}; do sudo kubeadm join --token=${k8stoken} --discovery-token-unsafe-skip-ca-verification --node-name=$(hostname -f) ${masterIP}:6443 && break || sleep 15; done\n"
      vars.%:                                      "2"
      vars.k8stoken:                               "d7dd14.55fbb69d581e8917"
      vars.masterIP:                               "10.43.0.40"

  + aws_iam_instance_profile.kubernetes
      id:                                          <computed>
      arn:                                         <computed>
      create_date:                                 <computed>
      name:                                        "kubernetes"
      path:                                        "/"
      role:                                        "kubernetes"
      roles.#:                                     <computed>
      unique_id:                                   <computed>

  + aws_iam_role.kubernetes
      id:                                          <computed>
      arn:                                         <computed>
      assume_role_policy:                          "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Action\": \"sts:AssumeRole\"\n    }\n  ]\n}\n"
      create_date:                                 <computed>
      force_detach_policies:                       "false"
      max_session_duration:                        "3600"
      name:                                        "kubernetes"
      path:                                        "/"
      unique_id:                                   <computed>

  + aws_iam_role_policy.kubernetes
      id:                                          <computed>
      name:                                        "kubernetes"
      policy:                                      "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\" : [\"ec2:*\"],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\" : [\"elasticloadbalancing:*\"],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"route53:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ssm:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ssmmessages:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ec2messages:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ecr:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": \"*\"\n    }\n  ]\n}\n"
      role:                                        "${aws_iam_role.kubernetes.id}"

  + aws_instance.controller_etcd
      id:                                          <computed>
      ami:                                         "ami-0ec645db622b4411a"
      arn:                                         <computed>
      associate_public_ip_address:                 "true"
      availability_zone:                           "ap-southeast-2a"
      cpu_core_count:                              <computed>
      cpu_threads_per_core:                        <computed>
      ebs_block_device.#:                          <computed>
      ephemeral_block_device.#:                    <computed>
      get_password_data:                           "false"
      host_id:                                     <computed>
      iam_instance_profile:                        "${aws_iam_instance_profile.kubernetes.id}"
      instance_state:                              <computed>
      instance_type:                               "t2.medium"
      ipv6_address_count:                          <computed>
      ipv6_addresses.#:                            <computed>
      key_name:                                    "tf-kube"
      metadata_options.#:                          <computed>
      network_interface.#:                         <computed>
      network_interface_id:                        <computed>
      outpost_arn:                                 <computed>
      password_data:                               <computed>
      placement_group:                             <computed>
      primary_network_interface_id:                <computed>
      private_dns:                                 <computed>
      private_ip:                                  "10.43.0.40"
      public_dns:                                  <computed>
      public_ip:                                   <computed>
      root_block_device.#:                         <computed>
      security_groups.#:                           <computed>
      source_dest_check:                           "false"
      subnet_id:                                   "${aws_subnet.kubernetes.id}"
      tags.%:                                      "3"
      tags.Name:                                   "controller-etcd-0"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"
      tenancy:                                     <computed>
      user_data:                                   "c23f2d71e43302a9f245fbe91bcc0d96a3842427"
      volume_tags.%:                               <computed>
      vpc_security_group_ids.#:                    <computed>

  + aws_instance.worker
      id:                                          <computed>
      ami:                                         "ami-0ec645db622b4411a"
      arn:                                         <computed>
      associate_public_ip_address:                 "true"
      availability_zone:                           "ap-southeast-2a"
      cpu_core_count:                              <computed>
      cpu_threads_per_core:                        <computed>
      ebs_block_device.#:                          <computed>
      ephemeral_block_device.#:                    <computed>
      get_password_data:                           "false"
      host_id:                                     <computed>
      iam_instance_profile:                        "${aws_iam_instance_profile.kubernetes.id}"
      instance_state:                              <computed>
      instance_type:                               "t2.medium"
      ipv6_address_count:                          <computed>
      ipv6_addresses.#:                            <computed>
      key_name:                                    "tf-kube"
      metadata_options.#:                          <computed>
      network_interface.#:                         <computed>
      network_interface_id:                        <computed>
      outpost_arn:                                 <computed>
      password_data:                               <computed>
      placement_group:                             <computed>
      primary_network_interface_id:                <computed>
      private_dns:                                 <computed>
      private_ip:                                  "10.43.0.30"
      public_dns:                                  <computed>
      public_ip:                                   <computed>
      root_block_device.#:                         <computed>
      security_groups.#:                           <computed>
      source_dest_check:                           "false"
      subnet_id:                                   "${aws_subnet.kubernetes.id}"
      tags.%:                                      "3"
      tags.Name:                                   "worker-0"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"
      tenancy:                                     <computed>
      user_data:                                   "852a54d0e12960a650bed5b9a7f45a93f57a663b"
      volume_tags.%:                               <computed>
      vpc_security_group_ids.#:                    <computed>

  + aws_internet_gateway.gw
      id:                                          <computed>
      arn:                                         <computed>
      owner_id:                                    <computed>
      tags.%:                                      "3"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"
      vpc_id:                                      "${aws_vpc.kubernetes.id}"

  + aws_key_pair.default_keypair
      id:                                          <computed>
      arn:                                         <computed>
      fingerprint:                                 <computed>
      key_name:                                    "tf-kube"
      key_pair_id:                                 <computed>
      public_key:                                  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnqahQpnHuvkNl9HKXYku5RQ+ac/Yvu9TaU0Q4Pex39r1c28f7pmbu6qV9lhxCGYbybDXZB59j1VZdiEZZb0qA1JV7KSsF8WBK9s5dw6As4LGLTm6+wDHSAaNA5biyavxAMDjdTU8imGDANP/5PLEumDNk5Cc4O/fojzksXmZDOj8WsrMVxr98VTdeklAECfPgoBDG5oiscgWzu/gsstW9llQQdtgeXWXaKBSb+QAype/Q+JAGxRATGi+rVmF+VR+mWdIwha/n9us7yI4JahHnTOsj2B/UHG8fLS2hnamiuXVtoPgopyDujkqQu/4jKIobpxyYKZRNx3CZeHhqjrop root@8badf41c5c80"

  + aws_route_table.kubernetes
      id:                                          <computed>
      owner_id:                                    <computed>
      propagating_vgws.#:                          <computed>
      route.#:                                     "1"
      route.~966145399.cidr_block:                 "0.0.0.0/0"
      route.~966145399.egress_only_gateway_id:     ""
      route.~966145399.gateway_id:                 "${aws_internet_gateway.gw.id}"
      route.~966145399.instance_id:                ""
      route.~966145399.ipv6_cidr_block:            ""
      route.~966145399.nat_gateway_id:             ""
      route.~966145399.network_interface_id:       ""
      route.~966145399.transit_gateway_id:         ""
      route.~966145399.vpc_peering_connection_id:  ""
      tags.%:                                      "3"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"
      vpc_id:                                      "${aws_vpc.kubernetes.id}"

  + aws_route_table_association.kubernetes
      id:                                          <computed>
      route_table_id:                              "${aws_route_table.kubernetes.id}"
      subnet_id:                                   "${aws_subnet.kubernetes.id}"

  + aws_security_group.kubernetes
      id:                                          <computed>
      arn:                                         <computed>
      description:                                 "Managed by Terraform"
      egress.#:                                    "1"
      egress.482069346.cidr_blocks.#:              "1"
      egress.482069346.cidr_blocks.0:              "0.0.0.0/0"
      egress.482069346.description:                ""
      egress.482069346.from_port:                  "0"
      egress.482069346.ipv6_cidr_blocks.#:         "0"
      egress.482069346.prefix_list_ids.#:          "0"
      egress.482069346.protocol:                   "-1"
      egress.482069346.security_groups.#:          "0"
      egress.482069346.self:                       "false"
      egress.482069346.to_port:                    "0"
      ingress.#:                                   "3"
      ingress.2242829830.cidr_blocks.#:            "1"
      ingress.2242829830.cidr_blocks.0:            "10.43.0.0/16"
      ingress.2242829830.description:              ""
      ingress.2242829830.from_port:                "0"
      ingress.2242829830.ipv6_cidr_blocks.#:       "0"
      ingress.2242829830.prefix_list_ids.#:        "0"
      ingress.2242829830.protocol:                 "-1"
      ingress.2242829830.security_groups.#:        "0"
      ingress.2242829830.self:                     "false"
      ingress.2242829830.to_port:                  "0"
      ingress.3068409405.cidr_blocks.#:            "1"
      ingress.3068409405.cidr_blocks.0:            "0.0.0.0/0"
      ingress.3068409405.description:              ""
      ingress.3068409405.from_port:                "8"
      ingress.3068409405.ipv6_cidr_blocks.#:       "0"
      ingress.3068409405.prefix_list_ids.#:        "0"
      ingress.3068409405.protocol:                 "icmp"
      ingress.3068409405.security_groups.#:        "0"
      ingress.3068409405.self:                     "false"
      ingress.3068409405.to_port:                  "0"
      ingress.482069346.cidr_blocks.#:             "1"
      ingress.482069346.cidr_blocks.0:             "0.0.0.0/0"
      ingress.482069346.description:               ""
      ingress.482069346.from_port:                 "0"
      ingress.482069346.ipv6_cidr_blocks.#:        "0"
      ingress.482069346.prefix_list_ids.#:         "0"
      ingress.482069346.protocol:                  "-1"
      ingress.482069346.security_groups.#:         "0"
      ingress.482069346.self:                      "false"
      ingress.482069346.to_port:                   "0"
      name:                                        "kubernetes"
      owner_id:                                    <computed>
      revoke_rules_on_delete:                      "false"
      tags.%:                                      "3"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"
      vpc_id:                                      "${aws_vpc.kubernetes.id}"

  + aws_subnet.kubernetes
      id:                                          <computed>
      arn:                                         <computed>
      assign_ipv6_address_on_creation:             "false"
      availability_zone:                           "ap-southeast-2a"
      availability_zone_id:                        <computed>
      cidr_block:                                  "10.43.0.0/16"
      ipv6_cidr_block:                             <computed>
      ipv6_cidr_block_association_id:              <computed>
      map_public_ip_on_launch:                     "false"
      owner_id:                                    <computed>
      tags.%:                                      "3"
      tags.Name:                                   "kubernetes"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"
      vpc_id:                                      "${aws_vpc.kubernetes.id}"

  + aws_vpc.kubernetes
      id:                                          <computed>
      arn:                                         <computed>
      assign_generated_ipv6_cidr_block:            "false"
      cidr_block:                                  "10.43.0.0/16"
      default_network_acl_id:                      <computed>
      default_route_table_id:                      <computed>
      default_security_group_id:                   <computed>
      dhcp_options_id:                             <computed>
      enable_classiclink:                          <computed>
      enable_classiclink_dns_support:              <computed>
      enable_dns_hostnames:                        "true"
      enable_dns_support:                          "true"
      instance_tenancy:                            "default"
      ipv6_association_id:                         <computed>
      ipv6_cidr_block:                             <computed>
      main_route_table_id:                         <computed>
      owner_id:                                    <computed>
      tags.%:                                      "3"
      tags.Name:                                   "kubeadm-kubernetes"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"

  + aws_vpc_dhcp_options.dns_resolver
      id:                                          <computed>
      arn:                                         <computed>
      domain_name:                                 "ap-southeast-2.compute.internal"
      domain_name_servers.#:                       "1"
      domain_name_servers.0:                       "AmazonProvidedDNS"
      owner_id:                                    <computed>
      tags.%:                                      "3"
      tags.Name:                                   "kubeadm-kubernetes"
      tags.Owner:                                  "code-challenge-2"
      tags.kubernetes.io/cluster/code-challenge-2: "owned"

  + aws_vpc_dhcp_options_association.dns_resolver
      id:                                          <computed>
      dhcp_options_id:                             "${aws_vpc_dhcp_options.dns_resolver.id}"
      vpc_id:                                      "${aws_vpc.kubernetes.id}"


Plan: 14 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_role.kubernetes: Creating...
  arn:                   "" => "<computed>"
  assume_role_policy:    "" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Action\": \"sts:AssumeRole\"\n    }\n  ]\n}\n"
  create_date:           "" => "<computed>"
  force_detach_policies: "" => "false"
  max_session_duration:  "" => "3600"
  name:                  "" => "kubernetes"
  path:                  "" => "/"
  unique_id:             "" => "<computed>"
aws_key_pair.default_keypair: Creating...
  arn:         "" => "<computed>"
  fingerprint: "" => "<computed>"
  key_name:    "" => "tf-kube"
  key_pair_id: "" => "<computed>"
  public_key:  "" => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnqahQpnHuvkNl9HKXYku5RQ+ac/Yvu9TaU0Q4Pex39r1c28f7pmbu6qV9lhxCGYbybDXZB59j1VZdiEZZb0qA1JV7KSsF8WBK9s5dw6As4LGLTm6+wDHSAaNA5biyavxAMDjdTU8imGDANP/5PLEumDNk5Cc4O/fojzksXmZDOj8WsrMVxr98VTdeklAECfPgoBDG5oiscgWzu/gsstW9llQQdtgeXWXaKBSb+QAype/Q+JAGxRATGi+rVmF+VR+mWdIwha/n9us7yI4JahHnTOsj2B/UHG8fLS2hnamiuXVtoPgopyDujkqQu/4jKIobpxyYKZRNx3CZeHhqjrop root@8badf41c5c80"
aws_vpc_dhcp_options.dns_resolver: Creating...
  arn:                                         "" => "<computed>"
  domain_name:                                 "" => "ap-southeast-2.compute.internal"
  domain_name_servers.#:                       "" => "1"
  domain_name_servers.0:                       "" => "AmazonProvidedDNS"
  owner_id:                                    "" => "<computed>"
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "kubeadm-kubernetes"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
aws_vpc.kubernetes: Creating...
  arn:                                         "" => "<computed>"
  assign_generated_ipv6_cidr_block:            "" => "false"
  cidr_block:                                  "" => "10.43.0.0/16"
  default_network_acl_id:                      "" => "<computed>"
  default_route_table_id:                      "" => "<computed>"
  default_security_group_id:                   "" => "<computed>"
  dhcp_options_id:                             "" => "<computed>"
  enable_classiclink:                          "" => "<computed>"
  enable_classiclink_dns_support:              "" => "<computed>"
  enable_dns_hostnames:                        "" => "true"
  enable_dns_support:                          "" => "true"
  instance_tenancy:                            "" => "default"
  ipv6_association_id:                         "" => "<computed>"
  ipv6_cidr_block:                             "" => "<computed>"
  main_route_table_id:                         "" => "<computed>"
  owner_id:                                    "" => "<computed>"
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "kubeadm-kubernetes"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
aws_key_pair.default_keypair: Creation complete after 1s (ID: tf-kube)
aws_vpc_dhcp_options.dns_resolver: Creation complete after 1s (ID: dopt-060e57070fbd805ce)
aws_iam_role.kubernetes: Creation complete after 2s (ID: kubernetes)
aws_iam_role_policy.kubernetes: Creating...
  name:   "" => "kubernetes"
  policy: "" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\" : [\"ec2:*\"],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\" : [\"elasticloadbalancing:*\"],\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"route53:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ssm:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ssmmessages:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ec2messages:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": [\"*\"]\n    },\n    {\n      \"Action\": \"ecr:*\",\n      \"Effect\": \"Allow\",\n      \"Resource\": \"*\"\n    }\n  ]\n}\n"
  role:   "" => "kubernetes"
aws_iam_instance_profile.kubernetes: Creating...
  arn:         "" => "<computed>"
  create_date: "" => "<computed>"
  name:        "" => "kubernetes"
  path:        "" => "/"
  role:        "" => "kubernetes"
  roles.#:     "" => "<computed>"
  unique_id:   "" => "<computed>"
aws_vpc.kubernetes: Creation complete after 3s (ID: vpc-0f8bb34f327bde4d2)
aws_subnet.kubernetes: Creating...
  arn:                                         "" => "<computed>"
  assign_ipv6_address_on_creation:             "" => "false"
  availability_zone:                           "" => "ap-southeast-2a"
  availability_zone_id:                        "" => "<computed>"
  cidr_block:                                  "" => "10.43.0.0/16"
  ipv6_cidr_block:                             "" => "<computed>"
  ipv6_cidr_block_association_id:              "" => "<computed>"
  map_public_ip_on_launch:                     "" => "false"
  owner_id:                                    "" => "<computed>"
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "kubernetes"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
  vpc_id:                                      "" => "vpc-0f8bb34f327bde4d2"
aws_vpc_dhcp_options_association.dns_resolver: Creating...
  dhcp_options_id: "" => "dopt-060e57070fbd805ce"
  vpc_id:          "" => "vpc-0f8bb34f327bde4d2"
aws_internet_gateway.gw: Creating...
  arn:                                         "" => "<computed>"
  owner_id:                                    "" => "<computed>"
  tags.%:                                      "0" => "3"
  tags.Name:                                   "" => "kubernetes"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
  vpc_id:                                      "" => "vpc-0f8bb34f327bde4d2"
aws_security_group.kubernetes: Creating...
  arn:                                         "" => "<computed>"
  description:                                 "" => "Managed by Terraform"
  egress.#:                                    "" => "1"
  egress.482069346.cidr_blocks.#:              "" => "1"
  egress.482069346.cidr_blocks.0:              "" => "0.0.0.0/0"
  egress.482069346.description:                "" => ""
  egress.482069346.from_port:                  "" => "0"
  egress.482069346.ipv6_cidr_blocks.#:         "" => "0"
  egress.482069346.prefix_list_ids.#:          "" => "0"
  egress.482069346.protocol:                   "" => "-1"
  egress.482069346.security_groups.#:          "" => "0"
  egress.482069346.self:                       "" => "false"
  egress.482069346.to_port:                    "" => "0"
  ingress.#:                                   "" => "3"
  ingress.2242829830.cidr_blocks.#:            "" => "1"
  ingress.2242829830.cidr_blocks.0:            "" => "10.43.0.0/16"
  ingress.2242829830.description:              "" => ""
  ingress.2242829830.from_port:                "" => "0"
  ingress.2242829830.ipv6_cidr_blocks.#:       "" => "0"
  ingress.2242829830.prefix_list_ids.#:        "" => "0"
  ingress.2242829830.protocol:                 "" => "-1"
  ingress.2242829830.security_groups.#:        "" => "0"
  ingress.2242829830.self:                     "" => "false"
  ingress.2242829830.to_port:                  "" => "0"
  ingress.3068409405.cidr_blocks.#:            "" => "1"
  ingress.3068409405.cidr_blocks.0:            "" => "0.0.0.0/0"
  ingress.3068409405.description:              "" => ""
  ingress.3068409405.from_port:                "" => "8"
  ingress.3068409405.ipv6_cidr_blocks.#:       "" => "0"
  ingress.3068409405.prefix_list_ids.#:        "" => "0"
  ingress.3068409405.protocol:                 "" => "icmp"
  ingress.3068409405.security_groups.#:        "" => "0"
  ingress.3068409405.self:                     "" => "false"
  ingress.3068409405.to_port:                  "" => "0"
  ingress.482069346.cidr_blocks.#:             "" => "1"
  ingress.482069346.cidr_blocks.0:             "" => "0.0.0.0/0"
  ingress.482069346.description:               "" => ""
  ingress.482069346.from_port:                 "" => "0"
  ingress.482069346.ipv6_cidr_blocks.#:        "" => "0"
  ingress.482069346.prefix_list_ids.#:         "" => "0"
  ingress.482069346.protocol:                  "" => "-1"
  ingress.482069346.security_groups.#:         "" => "0"
  ingress.482069346.self:                      "" => "false"
  ingress.482069346.to_port:                   "" => "0"
  name:                                        "" => "kubernetes"
  owner_id:                                    "" => "<computed>"
  revoke_rules_on_delete:                      "" => "false"
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "kubernetes"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
  vpc_id:                                      "" => "vpc-0f8bb34f327bde4d2"
aws_vpc_dhcp_options_association.dns_resolver: Creation complete after 0s (ID: dopt-060e57070fbd805ce-vpc-0f8bb34f327bde4d2)
aws_subnet.kubernetes: Creation complete after 1s (ID: subnet-0da6f1d0ec1456f86)
aws_internet_gateway.gw: Creation complete after 1s (ID: igw-035de90bbe3e8fd04)
aws_route_table.kubernetes: Creating...
  owner_id:                                    "" => "<computed>"
  propagating_vgws.#:                          "" => "<computed>"
  route.#:                                     "" => "1"
  route.779267819.cidr_block:                  "" => "0.0.0.0/0"
  route.779267819.egress_only_gateway_id:      "" => ""
  route.779267819.gateway_id:                  "" => "igw-035de90bbe3e8fd04"
  route.779267819.instance_id:                 "" => ""
  route.779267819.ipv6_cidr_block:             "" => ""
  route.779267819.nat_gateway_id:              "" => ""
  route.779267819.network_interface_id:        "" => ""
  route.779267819.transit_gateway_id:          "" => ""
  route.779267819.vpc_peering_connection_id:   "" => ""
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "kubernetes"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
  vpc_id:                                      "" => "vpc-0f8bb34f327bde4d2"
aws_iam_role_policy.kubernetes: Creation complete after 2s (ID: kubernetes:kubernetes)
aws_security_group.kubernetes: Creation complete after 2s (ID: sg-015624bc7c6361d12)
aws_iam_instance_profile.kubernetes: Creation complete after 3s (ID: kubernetes)
aws_instance.controller_etcd: Creating...
  ami:                                         "" => "ami-0ec645db622b4411a"
  arn:                                         "" => "<computed>"
  associate_public_ip_address:                 "" => "true"
  availability_zone:                           "" => "ap-southeast-2a"
  cpu_core_count:                              "" => "<computed>"
  cpu_threads_per_core:                        "" => "<computed>"
  ebs_block_device.#:                          "" => "<computed>"
  ephemeral_block_device.#:                    "" => "<computed>"
  get_password_data:                           "" => "false"
  host_id:                                     "" => "<computed>"
  iam_instance_profile:                        "" => "kubernetes"
  instance_state:                              "" => "<computed>"
  instance_type:                               "" => "t2.medium"
  ipv6_address_count:                          "" => "<computed>"
  ipv6_addresses.#:                            "" => "<computed>"
  key_name:                                    "" => "tf-kube"
  metadata_options.#:                          "" => "<computed>"
  network_interface.#:                         "" => "<computed>"
  network_interface_id:                        "" => "<computed>"
  outpost_arn:                                 "" => "<computed>"
  password_data:                               "" => "<computed>"
  placement_group:                             "" => "<computed>"
  primary_network_interface_id:                "" => "<computed>"
  private_dns:                                 "" => "<computed>"
  private_ip:                                  "" => "10.43.0.40"
  public_dns:                                  "" => "<computed>"
  public_ip:                                   "" => "<computed>"
  root_block_device.#:                         "" => "<computed>"
  security_groups.#:                           "" => "<computed>"
  source_dest_check:                           "" => "false"
  subnet_id:                                   "" => "subnet-0da6f1d0ec1456f86"
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "controller-etcd-0"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
  tenancy:                                     "" => "<computed>"
  user_data:                                   "" => "c23f2d71e43302a9f245fbe91bcc0d96a3842427"
  volume_tags.%:                               "" => "<computed>"
  vpc_security_group_ids.#:                    "" => "1"
  vpc_security_group_ids.318654959:            "" => "sg-015624bc7c6361d12"
aws_route_table.kubernetes: Creation complete after 1s (ID: rtb-0b8dbb5c596dce38e)
aws_route_table_association.kubernetes: Creating...
  route_table_id: "" => "rtb-0b8dbb5c596dce38e"
  subnet_id:      "" => "subnet-0da6f1d0ec1456f86"
aws_route_table_association.kubernetes: Creation complete after 1s (ID: rtbassoc-013aece5cb623e850)
aws_instance.controller_etcd: Still creating... (10s elapsed)
aws_instance.controller_etcd: Still creating... (20s elapsed)
aws_instance.controller_etcd: Still creating... (30s elapsed)
aws_instance.controller_etcd: Still creating... (40s elapsed)
aws_instance.controller_etcd: Creation complete after 44s (ID: i-026c9f1572bb978da)
data.template_file.worker-userdata: Refreshing state...
data.template_file.etcd-userdata: Refreshing state...
aws_instance.worker: Creating...
  ami:                                         "" => "ami-0ec645db622b4411a"
  arn:                                         "" => "<computed>"
  associate_public_ip_address:                 "" => "true"
  availability_zone:                           "" => "ap-southeast-2a"
  cpu_core_count:                              "" => "<computed>"
  cpu_threads_per_core:                        "" => "<computed>"
  ebs_block_device.#:                          "" => "<computed>"
  ephemeral_block_device.#:                    "" => "<computed>"
  get_password_data:                           "" => "false"
  host_id:                                     "" => "<computed>"
  iam_instance_profile:                        "" => "kubernetes"
  instance_state:                              "" => "<computed>"
  instance_type:                               "" => "t2.medium"
  ipv6_address_count:                          "" => "<computed>"
  ipv6_addresses.#:                            "" => "<computed>"
  key_name:                                    "" => "tf-kube"
  metadata_options.#:                          "" => "<computed>"
  network_interface.#:                         "" => "<computed>"
  network_interface_id:                        "" => "<computed>"
  outpost_arn:                                 "" => "<computed>"
  password_data:                               "" => "<computed>"
  placement_group:                             "" => "<computed>"
  primary_network_interface_id:                "" => "<computed>"
  private_dns:                                 "" => "<computed>"
  private_ip:                                  "" => "10.43.0.30"
  public_dns:                                  "" => "<computed>"
  public_ip:                                   "" => "<computed>"
  root_block_device.#:                         "" => "<computed>"
  security_groups.#:                           "" => "<computed>"
  source_dest_check:                           "" => "false"
  subnet_id:                                   "" => "subnet-0da6f1d0ec1456f86"
  tags.%:                                      "" => "3"
  tags.Name:                                   "" => "worker-0"
  tags.Owner:                                  "" => "code-challenge-2"
  tags.kubernetes.io/cluster/code-challenge-2: "" => "owned"
  tenancy:                                     "" => "<computed>"
  user_data:                                   "" => "5d5f30678259e17cce15118590e789d8ef55b490"
  volume_tags.%:                               "" => "<computed>"
  vpc_security_group_ids.#:                    "" => "1"
  vpc_security_group_ids.318654959:            "" => "sg-015624bc7c6361d12"
aws_instance.worker: Still creating... (10s elapsed)
aws_instance.worker: Still creating... (20s elapsed)
aws_instance.worker: Still creating... (30s elapsed)
aws_instance.worker: Creation complete after 33s (ID: i-03716cc7e12244597)

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

kubernetes_master = 13.210.243.63
kubernetes_workers_public_ip = 13.236.85.185

$ make kubectl-nodes
--- SSH into master node and kubectl get nodes -o wide
The authenticity of host '13.210.243.63 (13.210.243.63)' can't be established.
ECDSA key fingerprint is SHA256:WA9s7eEGjCvJ0xZIuQng8MYu4r4TdB2qj3DstNY6FkA.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '13.210.243.63' (ECDSA) to the list of known hosts.
NAME                                            STATUS     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP     OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
ip-10-43-0-30.ap-southeast-2.compute.internal   NotReady   <none>   8s    v1.19.4   10.43.0.30    13.236.85.185   Ubuntu 16.04.1 LTS   4.4.0-45-generic   docker://19.3.13
ip-10-43-0-40.ap-southeast-2.compute.internal   NotReady   master   32s   v1.19.4   10.43.0.40    13.210.243.63   Ubuntu 16.04.1 LTS   4.4.0-45-generic   docker://19.3.13
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make kubectl-command COMMAND="get pods -A"
--- SSH into master node and kubectl get pods -A
NAMESPACE     NAME                                                                    READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-5dc87d545c-92zg7                                1/1     Running   0          59s
kube-system   canal-b7wg4                                                             2/2     Running   0          59s
kube-system   canal-wvlxn                                                             2/2     Running   0          56s
kube-system   coredns-f9fd979d6-g4gsm                                                 1/1     Running   0          59s
kube-system   coredns-f9fd979d6-w8fpd                                                 1/1     Running   0          59s
kube-system   etcd-ip-10-43-0-40.ap-southeast-2.compute.internal                      0/1     Running   0          75s
kube-system   kube-apiserver-ip-10-43-0-40.ap-southeast-2.compute.internal            1/1     Running   0          75s
kube-system   kube-controller-manager-ip-10-43-0-40.ap-southeast-2.compute.internal   0/1     Running   0          76s
kube-system   kube-proxy-5ddhh                                                        1/1     Running   0          59s
kube-system   kube-proxy-j9jrn                                                        1/1     Running   0          56s
kube-system   kube-scheduler-ip-10-43-0-40.ap-southeast-2.compute.internal            1/1     Running   0          76s

$ make apply-node-web
--- SCP file into master node and kubectl apply
node-web.yaml                                                                                                                       100%  613    19.6KB/s   00:00    
deployment.apps/webapp1 created

$ make kubectl-command COMMAND="get pods -n default"
--- SSH into master node and kubectl get pods -n default
NAME                       READY   STATUS              RESTARTS   AGE
webapp1-656886f8b8-gx2d8   0/1     ContainerCreating   0          11s

$ make kubectl-command COMMAND="get pods -n default"
--- SSH into master node and kubectl get pods -n default
NAME                       READY   STATUS    RESTARTS   AGE
webapp1-656886f8b8-gx2d8   1/1     Running   0          36s

$ make validate-k8s-app
{
  "myapplication": [
    {
      "version": "1.0.3",
      "lastcommitsha": "727a24b",
      "description": "pre-interview technical test"
    }
  ]
}

$ make delete-node-web
--- kubectl delete -f node-web.yaml
deployment.apps "webapp1" deleted

$ make kubectl-command COMMAND="get pods -n default"
--- SSH into master node and kubectl get pods -n default
NAME                       READY   STATUS        RESTARTS   AGE
webapp1-656886f8b8-gx2d8   1/1     Terminating   0          5m26s

$ make kubectl-command COMMAND="get pods -n default"
--- SSH into master node and kubectl get pods -n default
No resources found in default namespace.

```
