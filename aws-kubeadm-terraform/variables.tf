locals {
  common_tags = "${map(
    "kubernetes.io/cluster/${var.cluster_id_tag}", "${var.cluster_id_value}"
  )}"
}

#############################
# Adjustable variables
#############################

variable number_of_etcd{
  description = "The number of etcd, only acts as etcd"
  default = 0
}

variable number_of_worker{
  description = "The number of worker nodes"
  default = 1
}

variable cluster_id_tag{
  description = "Cluster ID tag for kubeAdm"
  default = "code-challenge-2"
}

variable cluster_id_value{
  description = "Cluster ID value, it can be shared or owned"
  default = "owned"
}

##########################
# Default variables (you can change for customizing)
##########################

variable control_cidr {
  description = "CIDR for maintenance: inbound traffic will be allowed from this IPs"
  default = "0.0.0.0/0"
}

locals {
  default_keypair_public_key = "${file("tf-kube.pub")}"
}

/*
## It triggers interpolation. It is recommended to use another way.
## TODO : Replace default_keypair_public_key as output?
variable default_keypair_public_key {
  description = "Public Key of the default keypair"
  default = "${file("../keys/tf-kube.pub")}"
}
*/

variable default_keypair_name {
  description = "Name of the KeyPair used for all nodes"
  default = "tf-kube"
}

variable vpc_name {
  description = "Name of the VPC"
  default = "kubeadm-kubernetes"
}

variable elb_name {
  description = "Name of the ELB for Kubernetes API"
  default = "kubernetes"
}

variable owner {
  default = "code-challenge-2"
}

# Networking setup
variable region {
  default = "ap-southeast-2"
}

variable zone {
  default = "ap-southeast-2a"
}

### VARIABLES BELOW MUST NOT BE CHANGED ###
variable vpc_cidr {
  default = "10.43.0.0/16"
}

# Instances Setup
variable amis {
  description = "Default AMIs to use for nodes depending on the region"
  type = "map"
  default = {
    ap-northeast-2 = "ami-067c32f3d5b9ace91"
    ap-northeast-1 = "ami-0567c164"
    ap-southeast-1 = "ami-a1288ec2"
    ap-southeast-2 = "ami-0ec645db622b4411a"
  }
}

variable etcd_instance_type {
  default = "t2.medium"
}
variable controller_instance_type {
  default = "t2.medium"
}
variable worker_instance_type {
  default = "t2.medium"
}

# for Install KubeAdm Master / Worker / etcd
variable "master-userdata" {
    default = "master.sh"
}

variable "worker-userdata" {
    default = "worker.sh"
}

variable "etcd-userdata" {
    default = "etcd.sh"
}

variable "k8stoken" {}
