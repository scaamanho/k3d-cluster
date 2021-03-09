# K3D CLUSTER

## Versions

### v0.0.1

* Install tools and create a basic cluster

### v0.0.2

* Install Dashboard
* Expand examples

### v0.0.3
* Install Prometheus-Graphana

### v0.0.4
* Create configuration files

### v0.1.0
* Create cluster using configuration files instead command line parameters
* Install Nginx Ingress instead Traefik 1.6
* Use server certificates
* Create Persitent volumes
* Install Prometheus Graphana

## BACKLOG

* Configure k8s Dashboard with Ingress
* Install Rancher (https://gist.github.com/rafi/d4440661e7de208009701ca3627caa1d)
* Change Ingress to Traefik v2 / Ingress    
By default k3s comes with Traefik v1 as the default ingress controller, most of the time I prefer to bring my own ingress controller, my personal choice is ingress-nginx because is fairly straightforward and easy to use (and also a breeze to setup TLS certificates via cert-manager. (https://gist.github.com/rafi/d4440661e7de208009701ca3627caa1d)(https://royportas.com/posts/2020-11-20-setting-up-k3s-and-k3d/) (https://codeburst.io/creating-a-local-development-kubernetes-cluster-with-k3s-and-traefik-proxy-7a5033cb1c2d)
* Change Flanel to Calico (https://k3d.io/usage/guides/calico/)
* Install custom certificates (https://sysadmins.co.za/https-using-letsencrypt-and-traefik-with-k3s/) (https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes-es)
* Install EFK
* Create ansible playbook
* Create ha clusters
* Improve k8s Registry with k3d

* create users and manage cluster roles (https://dev.to/martinsaporiti/instalando-k3d-para-jugar-con-k8s-phg)
* Manage Cluster with lens (https://github.com/lensapp/lens/releases/tag/v4.1.2)
* Deploy Istio (https://dev.to/bufferings/tried-k8s-istio-in-my-local-machine-with-k3d-52gg)
* Portainer (https://github.com/portainer/portainer-k8s)
kubectl apply -f https://raw.githubusercontent.com/portainer/portainer-k8s/master/portainer.yaml
https://load-balancer-ip:9000
* ...
* Kubeapps [comming soon] [optional]
* Istio [comming soon] [optional]
* ELK [comming soon] [optional]