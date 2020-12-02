## Sub-task-4
Code challenge sub-task-4 documentation

### Task requirements

4. Have your container deployed into a Kubernetes cluster.


### Operation and files used

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

### Operation and Demonstration

#### Generate ssh key pairs and token for passwordless SSH into built k8s nodes and kubeadm worker nodes registering/joining to k8s master 
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

```


#### Terraform deploy AWS infrastructure and provision master and worker k8s node configuration
```bash
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

```

#### Validate k8s cluster built - kubectl get nodes and pods

```bash
$ make kubectl-nodes
--- SSH into master node and kubectl get nodes -o wide
The authenticity of host '13.210.243.63 (13.210.243.63)' can't be established.
ECDSA key fingerprint is SHA256:WA9s7eEGjCvJ0xZIuQng8MYu4r4TdB2qj3DstNY6FkA.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '13.210.243.63' (ECDSA) to the list of known hosts.
NAME                                            STATUS     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP     OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
ip-10-43-0-30.ap-southeast-2.compute.internal   NotReady   <none>   8s    v1.19.4   10.43.0.30    13.236.85.185   Ubuntu 16.04.1 LTS   4.4.0-45-generic   docker://19.3.13
ip-10-43-0-40.ap-southeast-2.compute.internal   NotReady   master   32s   v1.19.4   10.43.0.40    13.210.243.63   Ubuntu 16.04.1 LTS   4.4.0-45-generic   docker://19.3.13

$ make kubectl-command COMMAND="get pods -A"
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
```

#### Deploy application by applying manifest yaml file and some validation

```bash
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

```

#### Validation up and running nodejs application in k8s cluster - curl node-IP:8080/version
```bash

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
```

#### Remove application deployment and prepare github repo code change for versioning demonstration
```bash
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

$ make update-version
v1.0.5

$ make docker-image-rm
Error: No such image: jackyso/node-web:1.0.5
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-build
Sending build context to Docker daemon  181.5MB
Step 1/9 : FROM node:10
 ---> 2db91b8e7c1b
Step 2/9 : WORKDIR /usr/src
 ---> Running in fd0f7f6ad08e
Removing intermediate container fd0f7f6ad08e
 ---> 6b8fa6007f01
Step 3/9 : RUN git clone https://github.com/JackySo-MYOB/code-challenge-3.git app
 ---> Running in 1a81c990c42d
Cloning into 'app'...
Removing intermediate container 1a81c990c42d
 ---> acc1f115e9b8
Step 4/9 : WORKDIR /usr/src/app
 ---> Running in c2b98b296230
Removing intermediate container c2b98b296230
 ---> e984a66f4d18
Step 5/9 : COPY package*.json ./
 ---> d91f65f33563
Step 6/9 : RUN npm install
 ---> Running in bd9dc5bbe4e3
npm WARN code_challenge_node_app@1.0.5 No repository field.
npm WARN code_challenge_node_app@1.0.5 No license field.

added 50 packages from 37 contributors and audited 50 packages in 1.674s
found 0 vulnerabilities

Removing intermediate container bd9dc5bbe4e3
 ---> 27c8e6f7c926
Step 7/9 : COPY . .
 ---> 7ca60b1ae626
Step 8/9 : EXPOSE 8080
 ---> Running in c50a1a6afe4d
Removing intermediate container c50a1a6afe4d
 ---> 012353e2ff2c
Step 9/9 : CMD [ "node", "server.js" ]
 ---> Running in 73c069cf9026
Removing intermediate container 73c069cf9026
 ---> 07d5f311b377
Successfully built 07d5f311b377
Successfully tagged jackyso/node-web:1.0.5
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-push
Password: 
WARNING! Your password will be stored unencrypted in /home1/jso/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
The push refers to repository [docker.io/jackyso/node-web]
418184180f9f: Pushed 
1209e69e75e2: Pushed 
e090bebe632a: Pushed 
92d79814b0dd: Pushed 
982ea30af730: Layer already exists 
a047f6fe27f5: Layer already exists 
f5211c608ae5: Layer already exists 
0c6d2a8d3a7e: Layer already exists 
6ad22fbe53ce: Layer already exists 
f04853d2d299: Layer already exists 
9f07fffa6fe1: Layer already exists 
6c5a5125b341: Layer already exists 
26711ab4f3b6: Layer already exists 
1.0.5: digest: sha256:78f51c6502736d75b1f826dfbe42f20fab3166ea5f5391828d7cdc6acc8f1ce2 size: 3056


$ make update-version
v1.0.10
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make docker-build
Sending build context to Docker daemon  181.6MB
Step 1/9 : FROM node:10
 ---> 2db91b8e7c1b
Step 2/9 : WORKDIR /usr/src
 ---> Using cache
 ---> 6b8fa6007f01
Step 3/9 : RUN git clone https://github.com/JackySo-MYOB/code-challenge-3.git app
 ---> Using cache
 ---> acc1f115e9b8
Step 4/9 : WORKDIR /usr/src/app
 ---> Using cache
 ---> e984a66f4d18
Step 5/9 : COPY package*.json ./
 ---> 53b7719c1225
Step 6/9 : RUN npm install
 ---> Running in acae90379279
npm WARN code_challenge_node_app@1.0.10 No repository field.
npm WARN code_challenge_node_app@1.0.10 No license field.

added 50 packages from 37 contributors and audited 50 packages in 2.286s
found 0 vulnerabilities

Removing intermediate container acae90379279
 ---> e3875b9ff3d2
Step 7/9 : COPY . .
 ---> ee8b9a7796f3
Step 8/9 : EXPOSE 8080
 ---> Running in 167e248f68b7
Removing intermediate container 167e248f68b7
 ---> fbc3252bc337
Step 9/9 : CMD [ "node", "server.js" ]
 ---> Running in 8a4ad287bfd3
Removing intermediate container 8a4ad287bfd3
 ---> 9306ba60716d
Successfully built 9306ba60716d
Successfully tagged jackyso/node-web:1.0.10

$ make docker-push
Password: 
WARNING! Your password will be stored unencrypted in /home1/jso/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
The push refers to repository [docker.io/jackyso/node-web]
20b6fe8baf63: Pushed 
c8965b543012: Pushed 
1c58a636482b: Pushed 
92d79814b0dd: Layer already exists 
982ea30af730: Layer already exists 
a047f6fe27f5: Layer already exists 
f5211c608ae5: Layer already exists 
0c6d2a8d3a7e: Layer already exists 
6ad22fbe53ce: Layer already exists 
f04853d2d299: Layer already exists 
9f07fffa6fe1: Layer already exists 
6c5a5125b341: Layer already exists 
26711ab4f3b6: Layer already exists 
1.0.10: digest: sha256:fd2d1a559a159f705bf217594e42beebdc62662861a1a7c61ad73e9dcfd98e84 size: 3056

$ make apply-node-web
--- SCP file into master node and kubectl apply
node-web.yaml                                                                                                                       100%  614    22.9KB/s   00:00    
deployment.apps/webapp1 created

$ make kubectl-command COMMAND="get pods -n default"
--- SSH into master node and kubectl get pods -n default
NAME                       READY   STATUS    RESTARTS   AGE
webapp1-7f8d89bcd6-pvnws   1/1     Running   0          7s

$ make validate-k8s-app 
{
  "myapplication": [
    {
      "version": "1.0.10",
      "lastcommitsha": "6d2237e",
      "description": "pre-interview technical test"
    }
  ]
}

```
