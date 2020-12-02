# Bonus task
Code challenge documentation for GitOps based application deployment in k8s cluster

## Summary of work and menu operation use

Following highlighted GNU make targets will be used for this work and demonstration:

```diff
+validate-k8s-app                         Validate K8s cluster run app by curl http://worker:8080/version
delete-node-web                          Delete node-web deployment from cluster
get-pods                                 Get pods in default namespace
+kubectl-sa-tiller                        SSH into Kubernetes master node and create service account tiller and rolebinding 
+helm-init                                SSH into Kubernetes master node and run helm init
+kubectl-install-flux-crd                 SSH into Kubernetes master node and install flux CRD
+helm-install-flux                        SSH into Kubernetes master node and helm add repo plus install flux and kubectl get resources in namespace flux
+kubectl-get-pod-flux                     SSH into Kubernetes master node and get pod name in flux namespace
+kubectl-log-pod-flux                     SSH into Kubernetes master node and view logs of pod in flux namespace
deploy-flux-gitops                       Install and deploy FluxCD into k8s cluster and get pods
+get-flux-workloads                       List FluxCD workloads

```

### Install and run FluxCD for gitops to deploy nodejs to k8s cluster

```bash

$ make kubectl-sa-tiller
--- SSH into master node and create service account and rolebinding
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller-cluster-rule created

$ make helm-init
--- SSH into master node and run helm init --service-account tiller --history-max 200
Creating /home/ubuntu/.helm 
Creating /home/ubuntu/.helm/repository 
Creating /home/ubuntu/.helm/repository/cache 
Creating /home/ubuntu/.helm/repository/local 
Creating /home/ubuntu/.helm/plugins 
Creating /home/ubuntu/.helm/starters 
Creating /home/ubuntu/.helm/cache/archive 
Creating /home/ubuntu/.helm/repository/repositories.yaml 
Adding stable repo with URL: https://charts.helm.sh/stable 
Adding local repo with URL: http://127.0.0.1:8879/charts 
$HELM_HOME has been configured at /home/ubuntu/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://v2.helm.sh/docs/securing_installation/

$ make kubectl-install-flux-crd
--- SSH into master node and create service account and rolebinding
Warning: apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
customresourcedefinition.apiextensions.k8s.io/helmreleases.flux.weave.works created
helmreleases.flux.weave.works                         2020-12-02T11:06:20Z
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make helm-install-flux
"fluxcd" has been added to your repositories
Release "flux" does not exist. Installing it now.
NAME:   flux
LAST DEPLOYED: Wed Dec  2 11:06:48 2020
NAMESPACE: flux
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME              DATA  AGE
flux-kube-config  1     1s

==> v1/Deployment
NAME            READY  UP-TO-DATE  AVAILABLE  AGE
flux            0/1    1           0          0s
flux-memcached  0/1    1           0          0s

==> v1/Pod(related)
NAME                             READY  STATUS             RESTARTS  AGE
flux-d8fb5f899-zzl6s             0/1    ContainerCreating  0         0s
flux-memcached-5dbc947678-6nkcl  0/1    ContainerCreating  0         0s

==> v1/Secret
NAME             TYPE    DATA  AGE
flux-git-deploy  Opaque  0     1s

==> v1/Service
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)    AGE
flux            ClusterIP  10.97.80.124   <none>       3030/TCP   0s
flux-memcached  ClusterIP  10.111.164.17  <none>       11211/TCP  0s

==> v1/ServiceAccount
NAME  SECRETS  AGE
flux  1        1s

==> v1beta1/ClusterRole
NAME  CREATED AT
flux  2020-12-02T11:06:48Z

==> v1beta1/ClusterRoleBinding
NAME  ROLE              AGE
flux  ClusterRole/flux  0s


NOTES:
Get the Git deploy key by either (a) running

  kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

or by (b) installing fluxctl through
https://docs.fluxcd.io/en/latest/references/fluxctl#installing-fluxctl
and running:

  fluxctl identity --k8s-fwd-ns flux


NAME                                  READY   STATUS              RESTARTS   AGE
pod/flux-d8fb5f899-zzl6s              0/1     ContainerCreating   0          0s
pod/flux-memcached-5dbc947678-6nkcl   0/1     ContainerCreating   0          0s

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
service/flux             ClusterIP   10.97.80.124    <none>        3030/TCP    0s
service/flux-memcached   ClusterIP   10.111.164.17   <none>        11211/TCP   0s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/flux             0/1     1            0           0s
deployment.apps/flux-memcached   0/1     1            0           0s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/flux-d8fb5f899              1         1         0       0s
replicaset.apps/flux-memcached-5dbc947678   1         1         0       0s

$ make kubectl-get-pod-flux
--- SSH into master node and get pod name
NAME                   READY   STATUS    RESTARTS   AGE
flux-d8fb5f899-zzl6s   1/1     Running   0          5m42s

$ make get-flux-workloads
--- SSH into master node and get list of flux workloads
WORKLOAD                                        CONTAINER                IMAGE                                        RELEASE   POLICY
code-challenge:deployment/webapp1               webapp1                  docker.io/jackyso/node-web:2.0.0             updating  automated
flux:deployment/flux                            flux                     docker.io/fluxcd/flux:1.21.0                 ready     
flux:deployment/flux-memcached                  memcached                memcached:1.5.20                             ready     
kube-system:daemonset/canal                     calico-node              docker.io/calico/node:v3.17.0                ready     
                                                kube-flannel             quay.io/coreos/flannel:v0.12.0                         
                                                install-cni              docker.io/calico/cni:v3.17.0                           
                                                flexvol-driver           docker.io/calico/pod2daemon-flexvol:v3.17.0            
kube-system:daemonset/kube-proxy                kube-proxy               k8s.gcr.io/kube-proxy:v1.19.4                ready     
kube-system:deployment/calico-kube-controllers  calico-kube-controllers  docker.io/calico/kube-controllers:v3.17.0    ready     
kube-system:deployment/coredns                  coredns                  k8s.gcr.io/coredns:1.7.0                     ready     
kube-system:deployment/tiller-deploy            tiller                   ghcr.io/helm/tiller:v2.17.0                  ready     
```

### Validate running nodejs app in k8s cluster by curl command

```bash
$ make validate-k8s-app
{
  "myapplication": [
    {
      "version": "2.0.0",
      "lastcommitsha": "c7d2252",
      "description": "pre-interview technical test"
    }
  ]
}
```

### Capture log into running flux pod to validate interaction between running Flux and github repository

```bash
$ make kubectl-log-pod-flux
--- SSH into master node and view pod flux logs
ts=2020-12-02T11:38:18.696645956Z caller=warming.go:206 component=warmer updated=docker.io/calico/node successful=0 attempted=1
ts=2020-12-02T11:38:18.698266558Z caller=images.go:17 component=sync-loop msg="polling for new images for automated workloads"
ts=2020-12-02T11:39:12.098847778Z caller=warming.go:198 component=warmer info="refreshing image" image=docker.io/calico/node tag_count=4790 to_update=1 of_which_refresh=0 of_which_missing=1
ts=2020-12-02T11:39:12.33628655Z caller=repocachemanager.go:223 component=warmer canonical_name=index.docker.io/calico/node auth={map[]} warn="manifest for tag test missing in repository docker.io/calico/node" impact="flux will fail to auto-release workloads with matching images, ask the repository administrator to fix the inconsistency"
ts=2020-12-02T11:39:12.33635971Z caller=warming.go:206 component=warmer updated=docker.io/calico/node successful=0 attempted=1
ts=2020-12-02T11:39:12.337951724Z caller=images.go:17 component=sync-loop msg="polling for new images for automated workloads"
ts=2020-12-02T11:40:15.703978089Z caller=warming.go:198 component=warmer info="refreshing image" image=docker.io/calico/node tag_count=4790 to_update=1 of_which_refresh=0 of_which_missing=1
ts=2020-12-02T11:40:16.086198801Z caller=repocachemanager.go:223 component=warmer canonical_name=index.docker.io/calico/node auth={map[]} warn="manifest for tag test missing in repository docker.io/calico/node" impact="flux will fail to auto-release workloads with matching images, ask the repository administrator to fix the inconsistency"
ts=2020-12-02T11:40:16.086269605Z caller=warming.go:206 component=warmer updated=docker.io/calico/node successful=0 attempted=1
ts=2020-12-02T11:40:16.087791452Z caller=images.go:17 component=sync-loop msg="polling for new images for automated workloads"
ts=2020-12-02T11:40:27.012893475Z caller=loop.go:134 component=sync-loop event=refreshed url=ssh://git@github.com/JackySo-MYOB/code-challenge-3.git branch=main HEAD=de2ca938c3ae3b8f06dd12ae3a674e13773f9a3d
ts=2020-12-02T11:40:27.015087943Z caller=sync.go:61 component=daemon info="trying to sync git changes to the cluster" old=c7d2252d4913a3e91aad6676d2b93b72e2368dd0 new=de2ca938c3ae3b8f06dd12ae3a674e13773f9a3d
ts=2020-12-02T11:40:27.446272789Z caller=sync.go:540 method=Sync cmd=apply args= count=2
ts=2020-12-02T11:40:27.601932317Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=155.602959ms err=null output="namespace/code-challenge unchanged\ndeployment.apps/webapp1 unchanged"
ts=2020-12-02T11:40:32.395444893Z caller=loop.go:236 component=sync-loop state="tag flux-sync" old=c7d2252d4913a3e91aad6676d2b93b72e2368dd0 new=de2ca938c3ae3b8f06dd12ae3a674e13773f9a3d
ts=2020-12-02T11:40:34.994116384Z caller=loop.go:134 component=sync-loop event=refreshed url=ssh://git@github.com/JackySo-MYOB/code-challenge-3.git branch=main HEAD=de2ca938c3ae3b8f06dd12ae3a674e13773f9a3d

```

### Demonstrate git repository change and gitops automatic pickup in k8s cluster

```bash

$ make update-version TYPE=minor
v2.1.0

$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   package.json
	modified:   workloads/node-web.yaml

no changes added to commit (use "git add" and/or "git commit -a")

$ git add package.json workloads/node-web.yaml README.md

$ git commit -m 'Advance nodejs app version for Flux gitops pickup'
[main 96f37d4] Advance nodejs app version for Flux gitops pickup
 3 files changed, 160 insertions(+), 2 deletions(-)

$ git push
Enumerating objects: 11, done.
Counting objects: 100% (11/11), done.
Compressing objects: 100% (5/5), done.
Writing objects: 100% (6/6), 3.43 KiB | 1.71 MiB/s, done.
Total 6 (delta 4), reused 0 (delta 0)
remote: Resolving deltas: 100% (4/4), completed with 4 local objects.
To github.com:JackySo-MYOB/code-challenge-3.git
   de2ca93..96f37d4  main -> main


$ make validate-k8s-app 
{
  "myapplication": [
    {
      "version": "2.0.0",
      "lastcommitsha": "c7d2252",
      "description": "pre-interview technical test"
    }
  ]
}
jso@ubunu2004:~/myob-work/work/aws-cf/git-repo/code-challenge-3$ make validate-k8s-app 
{
  "myapplication": [
    {
      "version": "2.0.0",
      "lastcommitsha": "c7d2252",
      "description": "pre-interview technical test"
    }
  ]
}

$ make kubectl-log-pod-flux

ts=2020-12-02T11:45:29.573871777Z caller=loop.go:134 component=sync-loop event=refreshed url=ssh://git@github.com/JackySo-MYOB/code-challenge-3.git branch=main HEAD=96f37d4cd965584e26985d2b30dc3cb5e1fe9d92
ts=2020-12-02T11:45:29.576169997Z caller=sync.go:61 component=daemon info="trying to sync git changes to the cluster" old=de2ca938c3ae3b8f06dd12ae3a674e13773f9a3d new=96f37d4cd965584e26985d2b30dc3cb5e1fe9d92
ts=2020-12-02T11:45:29.988931595Z caller=sync.go:540 method=Sync cmd=apply args= count=2
ts=2020-12-02T11:45:30.331547397Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=342.556393ms err=null output="namespace/code-challenge unchanged\ndeployment.apps/webapp1 configured"
ts=2020-12-02T11:45:30.33361951Z caller=daemon.go:701 component=daemon event="Sync: 96f37d4, code-challenge:deployment/webapp1" logupstream=false
ts=2020-12-02T11:45:35.058954138Z caller=loop.go:236 component=sync-loop state="tag flux-sync" old=de2ca938c3ae3b8f06dd12ae3a674e13773f9a3d new=96f37d4cd965584e26985d2b30dc3cb5e1fe9d92
ts=2020-12-02T11:45:37.682505428Z caller=loop.go:134 component=sync-loop event=refreshed url=ssh://git@github.com/JackySo-MYOB/code-challenge-3.git branch=main HEAD=96f37d4cd965584e26985d2b30dc3cb5e1fe9d92

$ make validate-k8s-app 
{
  "myapplication": [
    {
      "version": "2.1.0",
      "lastcommitsha": "96f37d4",
      "description": "pre-interview technical test"
    }
  ]
}
```

