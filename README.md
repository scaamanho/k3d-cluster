# K3D Persistence Cluster

## Install Software
### Install K3D

Firs install k3d on your system with:

```sh
> curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

### Install kubectl

Also need install kubernetes client in order to manage cluster

```sh
> curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
> chmod +x ./kubectl
> sudo mv ./kubectl /usr/local/bin/kubectl
> kubectl version --client
```

## Deploy persistence kubernetes cluster

Crete a directory in your host where Kubernetes cluster will be persist data

```sh
> mkdir ./k3dvol
```

### Create Kubernetes Cluster with LoadBalancer

**NOTE**: **`Master`** and **`Workers`** nodes are renamed to **`Server`** and **`Agents`** resp.

![LoadBalancer Cluster](assets/k3d-cluster.webp)

Create a Kubernetes Cluster.
For this sample will keep cluster simple but you can set "any number" of agents and workers, the limits is comon sense and your memory.

Note that we are pointing port 443 on host to Cluster Load Balancer's 443 port. If you want use http you can use port 80.  

```sh
> k3d cluster create dev-cluster \
--api-port 6553 \
--port 8443:443@loadbalancer  \
--port 8080:80@loadbalancer \
--volume $(pwd)/k3dvol:/shared \
--servers 1 --agents 1
```

#### Port Mapping

* `--port 8080:80@loadbalancer` will add a mapping of local host port 8080 to loadbalancer port 80, which will proxy requests to port 80 on all agent nodes

* `--api-port 6553` : by default, no API-Port is exposed (no host port mapping). It’s used to have k3s‘s API-Server listening on port 6553 with that port mapped to the host system. So that the load balancer will be the access point to the Kubernetes API, so even for multi-server clusters, you only need to expose a single api port. The load balancer will then take care of proxying your requests to the appropriate server node

* `-p "32000-32767:32000-32767@loadbalancer"`
You may as well expose a NodePort range (if you want to avoid the Ingress Controller).
**Warning**: Map a wide range of ports can take a certain amount of time, and your computer can freeze for some time in this process.

### Manage Clusters

Once cluster is created we can `start`, `stop` or even `delete` them

```sh
> k3d cluster start <cluster-name>
> k3d cluster stop <cluster-name>
> k3d cluster delete <cluster-name>`
```


### Mange cluser nodes

![LoadBalancer Cluster](assets/k3d-cluster-multi.webp)

#### List cluster nodes

```sh
> k3d node ls
NAME   ROLE   CLUSTER   STATUS
...
```

#### Add/Delete new nodes to cluster

Create new nodes (and add them to existing clusters)

```sh
> k3d node create <nodename> --cluster <cluster-name> --role <agent/server>
```

To delete nodes just use:

```sh
> k3d node delete <nodename>
```

#### Start/Stop nodes

Also can just stop or start nodes previously created with


```sh
> k3d node start <nodename>
> k3d node stop <nodename>
```

k3d create/start/stop/delete node mynode

### Manage your registry

Create ir delete a local kubernetes internal registry

```sh
> k3d registry create REGISTRY_NAME 
> k3d registry delete REGISTRY_NAME
```


### Replace Ingress Controler

K3D uses Traefik 1.x versios as Ingress controler, due Traefik 2.x is enough mature and provide more functionalities we need do some extra work to use Traefik.

First we create a new file `helm-ingress-traefik.yaml` 

```yaml
# see https://rancher.com/docs/k3s/latest/en/helm/
# see https://github.com/traefik/traefik-helm-chart
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ingress-controller-traefik
  namespace: kube-system
spec:
  repo: https://helm.traefik.io/traefik
  chart: traefik
  version: 9.8.0
  targetNamespace: kube-system
```


Now we can create a new cluster telling to k3d not deploy traefik with 
`--k3s-server-arg '--no-deploy=traefik'` and use previous helm chart defined to deploy new Traefik Ingress Controler
`--volume "$(pwd)/helm-ingress-traefik.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-traefik.yaml"`


```sh
> k3d cluster create traefik --k3s-server-arg '--no-deploy=traefik' --volume "$(pwd)/helm-ingress-traefik.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-traefik.yaml"

```

## Deploy apps on kubernetes


### Configure KUBECONFIG

```sh
export KUBECONFIG=$(k3d kubeconfig write <cluster-name>)
```

#### Manage Kubeconfig
K3D provide some commands to manage kubeconfig

get kubeconfig from cluster dev

```sh
k3d kubeconfig get <cluster-name>
```

create a kubeconfile file in $HOME/.k3d/kubeconfig-dev.yaml 
```sh
kubeconfig write <cluster-name>
```
get kubeconfig from cluster(s) and  merge it/them into a file in $HOME/.k3d or another file

```sh
k3d kubeconfig merge ...
```

### Deploy simple applications

```sh
> k3d kubeconfig merge dev-cluster --kubeconfig-switch-context
> kubectl create deployment nginx --image=nginx
> kubectl create service clusterip nginx --tcp=80:80
> kubectl apply -f  nginx-ingress.yml
```

```yml
# apiVersion: networking.k8s.io/v1beta1 # for k3s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

Testing deployments:

```sh
> curl localhost:4080
> curl -k https://localhost:4443              
> kubectl get po --all-namespaces -o wide
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE    IP          NODE                       NOMINATED NODE   READINESS GATES
kube-system   metrics-server-86cbb8457f-5bpzr           1/1     Running     0          78m    10.42.0.3   k3d-dev-cluster-server-0   <none>           <none>
kube-system   local-path-provisioner-7c458769fb-hd2cc   1/1     Running     0          78m    10.42.1.3   k3d-dev-cluster-agent-0    <none>           <none>
kube-system   helm-install-traefik-4qh5z                0/1     Completed   0          78m    10.42.0.2   k3d-dev-cluster-server-0   <none>           <none>
kube-system   coredns-854c77959c-jmp94                  1/1     Running     0          78m    10.42.1.2   k3d-dev-cluster-agent-0    <none>           <none>
kube-system   svclb-traefik-6ch8f                       2/2     Running     0          78m    10.42.0.4   k3d-dev-cluster-server-0   <none>           <none>
kube-system   svclb-traefik-9tmk4                       2/2     Running     0          78m    10.42.1.4   k3d-dev-cluster-agent-0    <none>           <none>
kube-system   svclb-traefik-h8vgj                       2/2     Running     0          78m    10.42.2.3   k3d-dev-cluster-agent-1    <none>           <none>
kube-system   traefik-6f9cbd9bd4-6bjp4                  1/1     Running     0          78m    10.42.2.2   k3d-dev-cluster-agent-1    <none>           <none>
default       nginx-6799fc88d8-vcjp5                    1/1     Running     0          29m    10.42.2.4   k3d-dev-cluster-agent-1    <none>           <none>
> kubectl scale deployment nginx --replicas 4
> kubectl get po --all-namespaces -o wide
```

### Deploy Persistence Application  

`persistence-app.yml`

```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/shared"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  selector:
    matchLabels:
      app: echo
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: echo
    spec:
      volumes:
        - name: task-pv-storage
          persistentVolumeClaim:
            claimName: task-pv-claim
      containers:
      - image: busybox
        name: echo
        volumeMounts:
          - mountPath: "/data"
            name: task-pv-storage
        command: ["ping", "127.0.0.1"]
```

```sh
> kubectl apply -f persistence-app.yml
> kubectl get pv
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE
task-pv-volume   1Gi        RWO            Retain           Bound    default/task-pv-claim   manual                  2m54s
> kubectl get pvc
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
task-pv-claim    Bound    task-pv-volume                             1Gi        RWO            manual         11s
> kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
echo-58fd7d9b6-x4rxj   1/1     Running   0          16s
```



References
<https://github.com/rancher/k3d>
<https://k3s.io/> <https://github.com/k3s-io/k3s>
<https://en.sokube.ch/post/k3s-k3d-k8s-a-new-perfect-match-for-dev-and-test>