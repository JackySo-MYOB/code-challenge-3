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

### Create a simple application which has a single “/version” endpoint

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

### Containerize nodejs application

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


```
