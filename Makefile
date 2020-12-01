.DEFAULT_GOAL := help
.PHONY: help
docker-user := "jackyso"
docker-registry := "docker.io/$(docker-user)"
RELEASE_VERSION := "v1.0.0"
REGION := ap-southeast-2
RANDOM := $(shell od -An -N2 -i /dev/random | sed 's/^ *//g')
TYPE := patch
APPS := server.js
TAG := latest
IMAGE := node-web
TAG := $(shell grep version package.json | awk -F: '{ print $$2 }' | sed 's/[", ]//g')
CONTAINER := node-web
FLUX := https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml
GIT := https://github.com/JackySo-MYOB/code-challenge-3.git

## help: This help
help: Makefile
	@echo
	@echo " Choose a command run:"
	@echo
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'
	@echo

test: ## Testing
	@echo "$(TAG)"

install-dep: ## Intall nodejs dependencies in package.json
	@npm install || true

update-version: ## Update node pakage.json version in package.json and tag version in yaml file
	@npm version $(TYPE) || true
	@make -s update-tag

update-tag: ## Update tag version in yaml file
	@cp yaml/template.yaml yaml/node-web.yaml && sed -i '/image/s/latest/$(TAG)/g' yaml/node-web.yaml

run-node: ## Run nodejs application $(APPS)
	@node $(APPS) &
	@sleep 5; curl -s http://localhost:8080/version | jq

kill-node: ## Kill nodejs process
	@pkill node || true

docker-build: ## Build the docker image
	@docker build . -t $(docker-user)/$(IMAGE):$(TAG)

docker-shell: ## Run bash shell in docker
	@docker run --rm -it -p 8080:8080 $(docker-user)/$(IMAGE):$(TAG) bash

docker-registry-shell: ## Run bash shell in docker pull from registry
	@docker run --rm -it -p 8080:8080 $(docker-registry)/$(IMAGE):$(TAG) bash

docker-run: ## Run the docker
	@echo "Run docker container and use other terminal to validate app and stop container"
	@docker run --rm -p 8080:8080 $(docker-user)/$(IMAGE):$(TAG) || true

docker-stop: ## Stop the container $(CONTAINER)
	@docker stop $(shell docker container ls | grep $(CONTAINER) | awk '{ print $$1 }') || true

docker-image-rm: ## Remove local docker image
	@docker image rm $(docker-user)/$(IMAGE):$(TAG) || true

docker-registry-run: ## Run docker pull from registry
	@echo "Run docker container and use other terminal to validate app and stop container"
	@docker run --rm -it -p 8080:8080 $(docker-registry)/$(IMAGE):$(TAG) || true

docker-login: ## Logon docker registry docker.io
	@docker login -u $(docker-user)

docker-push: ## Build docker image and push to registry docker.io
	@docker login -u $(docker-user)
	@docker push $(docker-registry)/$(IMAGE):$(TAG)

validate-app: ## Validate docker run app by curl http://localhost:8080/version
	@curl -s http://localhost:8080/version | jq

kubeadm-terraform-shell: ## Run docker kubeadm-terraform and /bin/bash
	@docker-compose run --rm kubeadm-terraform /bin/bash 

kubeadm-terraform-genkey: ## Run docker kubeadm-terraform and generate key
	@docker-compose run --rm kubeadm-terraform ssh-keygen -t rsa -N "" -f tf-kube

kubeadm-terraform-token: ## Run docker kubeadm-terraform and generate k8s token
	@docker-compose run --rm kubeadm-terraform python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))'
	
kubeadm-terraform-state: ## Query terraform state
	@echo "--- Query terraform deploying status"
	@docker-compose run --rm kubeadm-terraform terraform state list || true

kubeadm-terraform-deploy: ## Run terraform init and deploy
	@echo "--- Terraform Deploy "
	@docker-compose run --rm kubeadm-terraform terraform init
	@docker-compose run --rm kubeadm-terraform terraform apply

kubeadm-terraform-undeploy: ## Run terraform init and destroy
	@echo "--- Terraform Undeploy"
	@docker-compose run --rm kubeadm-terraform terraform init
	@docker-compose run --rm kubeadm-terraform terraform destroy

master-ip: ## Run terraform output master node public IP
	@echo "--- Terraform output master public IP: \c";  docker-compose run --rm kubeadm-terraform terraform output kubernetes_master

worker-ip: ## Run terraform output worker node public IP
	@echo "--- Terraform output worker public IP: \c";  docker-compose run --rm kubeadm-terraform terraform output kubernetes_workers_public_ip

ssh-master: ## SSH into Kubernetes master node
	@echo "--- SSH into master node"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master)

ssh-worker: ## SSH into Kubernetes worker node
	@echo "--- SSH into worker node"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_workers_public_ip)

kubectl-nodes: ## SSH into Kubernetes master node and kubectl get nodes -o wide
	@echo "--- SSH into master node and kubectl get nodes -o wide"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl get nodes -o wide

kubectl-command: ## SSH into Kubernetes master node and kubectl $(COMMAND)
	@echo "--- SSH into master node and kubectl $(COMMAND)"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl $(COMMAND)

apply-node-web: ## Copy node-web file to master and apply into cluster
	@echo "--- SCP file into master node and kubectl apply"
	@sudo scp -i aws-kubeadm-terraform/tf-kube yaml/node-web.yaml ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master): 
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl apply -f node-web.yaml

validate-k8s-app: ## Validate K8s cluster run app by curl http://worker:8080/version
	@curl -s http://$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_workers_public_ip):8080/version | jq

delete-node-web: ## Delete node-web deployment from cluster
	@echo "--- kubectl delete -f node-web.yaml"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl delete -f node-web.yaml

get-pods: ## Get pods in default namespace
	@echo "--- kubectl get pods -o wide"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl get pods -o wide

kubectl-sa-tiller: ## SSH into Kubernetes master node and create service account tiller and rolebinding 
	@echo "--- SSH into master node and create service account and rolebinding"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl create sa tiller -n kube-system
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

helm-init: ## SSH into Kubernetes master node and run helm init
	@echo "--- SSH into master node and run helm init --service-account tiller --history-max 200"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) helm init --service-account tiller --history-max 200

kubectl-install-flux-crd: ## SSH into Kubernetes master node and install flux CRD
	@echo "--- SSH into master node and create service account and rolebinding"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl apply -f $(FLUX) || true
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl get crds | grep -i flux || true

helm-install-flux: ## SSH into Kubernetes master node and helm add repo plus install flux and kubectl get resources in namespace flux
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) helm repo add fluxcd https://charts.fluxcd.io
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) helm upgrade -i flux --set helmOperator.create=true --set helmOperator.createCRD=false --set git.url=$(GIT) --namespace flux fluxcd/flux
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl get all -n flux

kubectl-get-pod-flux: ## SSH into Kubernetes master node and get pod name in flux namespace
	@echo "--- SSH into master node and get pod name"
	@sudo ssh -i aws-kubeadm-terraform/tf-kube ubuntu@$(shell docker-compose run --rm kubeadm-terraform terraform output kubernetes_master) kubectl get pods -n flux | grep -v memcached

