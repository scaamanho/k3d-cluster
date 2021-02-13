# K3D Persistence Cluster

## Install Software
### Install K3D

Firs install k3d on your system with:

```sh
> curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

### Install kubectl

Install kubernetes client

```sh
> curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
>chmod +x ./kubectl
>sudo mv ./kubectl /usr/local/bin/kubectl
>kubectl version --client
```

## Deploy persistence kubernetes cluster

Crete a directory in your host where Kubernetes cluster will be persist data

```sh
> mkdir ./k3dvol
```

### Create Kubernetes Cluster with LoadBalancer

Create a Kubernetes Cluster.
For this sample will keep cluster simple but you can set "any number" of agents and workers, the limits is comon sense and your memory.

Note that we are pointing port 443 on host to Cluster Load Balancer's 443 port. If you want use http you can use port 80.  

```sh
> k3d cluster create dev-cluster \
--api-port 6553 \
--port 4443:443@loadbalancer  \
--port 4080:80@loadbalancer \
--volume $(pwd)/k3dvol:/shared@agents \
--servers 1 --agents 2
```

### Add nuevos nodos al cluster

Create new nodes (and add them to existing clusters)

```sh
k3d node create nodename --cluster multiserver --role server
```

### Exponer nuevos nodos del cluster

### Manage your registry

Create ir delete a local kubernetes internal registry

```sh
k3d registry create REGISTRY_NAME 
k3d registry delete REGISTRY_NAME
```

## Deploy apps on kubernetes

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

Probando el despliegue.

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
