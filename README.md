# code-challenge-3
Code challenge on CI pipeline and automation practices

## Task requirements

1. Create a simple application which has a single “/version” endpoint.
2. Containerise your application as a single deployable artefact, encapsulating all dependencies.
3. Create a CI pipeline for your application
4. Have your container deployed into a Kubernetes cluster.

## Start my work

### Design choices, short comings and assumptions section

#### Design

The design in this task delivery is simply use as much automation as possible and Infrastructure as code (IaC) to demonstrate devops practice.

See the following devops toolings i used for this task delivery
* GNU make for structured operational menu and automation
* Terraform plus kubeadm in docker for k8s infrastructure deployment plus shell scripts as userdata for various k8s nodes provisioning in AWS EC2 instances
* Docker and docker-compose to make work portable and less toolings installation as overhead
* Github action to make CI pipeline to build and publish docker image for application deployment
* FluxCD to watch over the github repository to deliver GitOps based continuous deployment (CD) of application into Kubernetes cluster

#### Versioning

There are versioning concept in this task work and coupling between:
* Nodejs application version
* Docker image TAG

#### Short comings

#### Assumptions

Key assumption for tooling installation in your work-box are
1. docker 
2. docker-compose 
3. GNU make
4. jq for readable output
Remarks: All other softwares and utilities required in task demonstration and automation will be included into IaC structures

On the other hand, you need AWS ID and credential for AWS infrastructure building to validate application deployment into k8s cluster

### IaC structures and summaried purpose of some key files 

```
.
.github
└── workflows
    └── docker.yml
├── aws-kubeadm-terraform
│   ├── variables.tf
│   ├── 0-aws.tf
│   ├── 1-vpc.tf
│   ├── 2-etcd.tf
│   ├── 3-workers.tf
│   ├── 4-controllers.tf
│   ├── 5-iam.tf
│   ├── 6-elb.tf
│   ├── 7-kubeadm.tf
│   ├── service-l7.yaml
│   ├── tf-kube
│   ├── tf-kube.pub
│   ├── etcd.sh
│   ├── master.sh
│   └── worker.sh
├── docker-compose.yml
├── terraform-Dockerfile
├── Dockerfile
├── images
│   └── github-action.PNG
├── Makefile
├── package.json
├── README.md
├── sub-tasks-1.md
├── sub-tasks-2.md
├── sub-tasks-3.md
├── sub-tasks-4.md
├── bonus-tasks-4.md
├── server.js
├── namespaces
│   └── app-namespace.yaml
├── workloads
│   └── node-web.yaml
└── yaml
    └── template.yaml
```

Files                  | Purposes
-----------------------|--------------------------------------
Makefile               | Menu based operation
Dockerfile             | Build docker for nodejs app
server.js              | nodejs app
aws-kubeadm-terraform/ | Terraform and userdata shell script
workloads/namespaces   | Kubernetes manifest yaml files
terraform-Dockerfile   | Build docker kubeadm-terraform
docker-compose.yml     | service kubeadm-terraform and awscli


### Work and demonstration menu

```diff
$ make

 Choose a command run:

install-dep                              Intall nodejs dependencies in package.json
update-version                           Update node pakage.json version in package.json and tag version in yaml file
update-tag                               Update tag version in yaml file
run-node                                 Run nodejs application $(APPS)
kill-node                                Kill nodejs process

docker-build                             Build the docker image
docker-shell                             Run bash shell in docker
docker-registry-shell                    Run bash shell in docker pull from registry
docker-run                               Run the docker
docker-stop                              Stop the container $(CONTAINER)
docker-image-rm                          Remove local docker image
docker-registry-run                      Run docker pull from registry
docker-login                             Logon docker registry docker.io
docker-push                              Build docker image and push to registry docker.io
validate-app                             Validate docker run app by curl http://localhost:8080/version

kubeadm-terraform-shell                  Run docker kubeadm-terraform and /bin/bash
kubeadm-terraform-genkey                 Run docker kubeadm-terraform and generate key
kubeadm-terraform-token                  Run docker kubeadm-terraform and generate k8s token
kubeadm-terraform-state                  Query terraform state
kubeadm-terraform-deploy                 Run terraform init and deploy
kubeadm-terraform-undeploy               Run terraform init and destroy
master-ip                                Run terraform output master node public IP
worker-ip                                Run terraform output worker node public IP
ssh-master                               SSH into Kubernetes master node
ssh-worker                               SSH into Kubernetes worker node
kubectl-nodes                            SSH into Kubernetes master node and kubectl get nodes -o wide
kubectl-command                          SSH into Kubernetes master node and kubectl $(COMMAND)
apply-node-web                           Copy node-web file to master and apply into cluster
validate-k8s-app                         Validate K8s cluster run app by curl http://worker:8080/version
delete-node-web                          Delete node-web deployment from cluster
get-pods                                 Get pods in default namespace

kubectl-sa-tiller                        SSH into Kubernetes master node and create service account tiller and rolebinding 
helm-init                                SSH into Kubernetes master node and run helm init
kubectl-install-flux-crd                 SSH into Kubernetes master node and install flux CRD
helm-install-flux                        SSH into Kubernetes master node and helm add repo plus install flux and kubectl get resources in namespace flux
kubectl-get-pod-flux                     SSH into Kubernetes master node and get pod name in flux namespace
kubectl-log-pod-flux                     SSH into Kubernetes master node and view logs of pod in flux namespace
deploy-flux-gitops                       Install and deploy FluxCD into k8s cluster and get pods
get-flux-workloads                       List FluxCD workloads

```

### Documentation for four sub-tasks as requirement plus GitOps using FluxCD
[Sub-tasks-1 Documentation](https://github.com/JackySo-MYOB/code-challenge-3/blob/main/sub-tasks-1.md)

[Sub-tasks-2 Documentation](https://github.com/JackySo-MYOB/code-challenge-3/blob/main/sub-tasks-2.md)

[Sub-tasks-3 Documentation](https://github.com/JackySo-MYOB/code-challenge-3/blob/main/sub-tasks-3.md)

[Sub-tasks-4 Documentation](https://github.com/JackySo-MYOB/code-challenge-3/blob/main/sub-tasks-4.md)

[Bonus tasks Documentation](https://github.com/JackySo-MYOB/code-challenge-3/blob/main/bonus.md)
