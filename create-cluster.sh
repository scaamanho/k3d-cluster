#!/bin/sh
CLUSTER_DOMAIN=fuf.me
API_PORT=6443
HTTP_PORT=80
HTTPS_PORT=443
CLUSTER_NAME=k3d-cluster
READ_VALUE=
SERVERS=1
AGENTS=1
TRAEFIK_V2=Yes

INSTALL_DASHBOARD=Yes
INSTALL_PROMETHEUS=Yes


# $1 text to show - $2 default value
read_value ()
{
    read -p "${1} [${2}]: " READ_VALUE
    if [ "${READ_VALUE}" = "" ]
    then
        READ_VALUE=$2
    fi
}

# Check if exist docker, k3d and kubectl
checkDependencies ()
{
    # Check Docker
    if ! type docker > /dev/null; then
        echo "Docker could not be found. Installing it ..."
        curl -L -o ./install-docker.sh "https://get.docker.com"
        chmod +x ./install-docker.sh
        ./install-docker.sh
        sudo usermod -aG docker $USER
        exit
    fi

    # Check K3D
    if ! type docker > /dev/null; then
        echo "K3D could not be found. Installing it ..."
        curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
        # Install k3d autocompletion for bash
        echo "source <(k3d completion bash)" >> ~/.bashrc
        exit
    fi

    # Check Kubectl
    if ! type kubectl > /dev/null; then
        echo "Kubectl could not be found. Installing it ..."
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
        kubectl version --client
        exit
    fi

    # Check Helm
    if ! type helm > /dev/null; then
        echo "Helm could not be found. Installing it ..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
        chmod +x ./get_helm.sh
        ./get_helm.sh
        exit
    fi
}


header()
{
    echo ""
    echo ""
    echo "${1}"
    echo "-------------------------------------"
}

footer()
{
    echo "-------------------------------------"
    echo ""
    echo ""
}

installCluster ()
{
    echo "Creating K3D cluster"
#https://github.com/rancher/k3d/blob/main/tests/assets/config_test_simple.yaml
    cat <<EOF > tmp-k3d-${CLUSTER_NAME}.yaml
apiVersion: k3d.io/v1alpha2
kind: Simple
name: ${CLUSTER_NAME}
servers: ${SERVERS} 
agents: ${AGENTS}
kubeAPI:
  hostIP: "0.0.0.0"
  hostPort: "${API_PORT}" # puerto kubernetes api 6443:6443
#image: rancher/k3s:latest
image: rancher/k3s:v1.19.4-k3s1
volumes:
#  - volume: /tmp:/tmp/fakepath # volumen en el localhost:contenedor
#  - volume: $(pwd)/k3deploy/helm-ingress-ngnx.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-nginx.yaml
  - volume: $(pwd)/k3dvol:/tmp/k3dvol # volumen en el localhost:contenedor
    nodeFilters:
      - all
ports:
  - port: ${HTTP_PORT}:80 # puerto http localhost:contenedor 8080:80
    nodeFilters:
      - loadbalancer
  - port: 0.0.0.0:${HTTPS_PORT}:443 # https con 8443:443
    nodeFilters:
      - loadbalancer
env:
  - envVar: secret=token
    nodeFilters:
      - all
labels:
  - label: best_cluster=forced_tag
    nodeFilters:
      - server[0] # 
      - loadbalancer

#registries:
#  create: true
#  use: []
#  config: |
#    mirrors:
#      "my.company.registry":
#        endpoint:
#          - http://my.company.registry:5000

options:
  k3d:
    wait: true
    timeout: "60s" # Cuando no se pueda arrancar, no entre en bucle arriba/abajo
    disableLoadbalancer: false
    disableImageVolume: false
  k3s:
    extraServerArgs:
      - --tls-san=127.0.0.1
      - --no-deploy=traefik
#      - --flannel-backend=none

    extraAgentArgs: []
  kubeconfig:
    updateDefaultKubeconfig: true # actualiza automatica el kubeconfig
    switchCurrentContext: true # cambia al nuevo contexto
EOF


 #   k3d cluster create ${CLUSTER_NAME} \
 #   --api-port ${API_PORT} \
 #   --port ${HTTPS_PORT}:443@loadbalancer  \
 #   --port ${HTTP_PORT}:80@loadbalancer \
 #   --volume $(pwd)/k3dvol:/tmp/k3dvol \
 #   --servers ${SERVERS} \
 #   --agents ${AGENTS}

    k3d cluster create --config test-k3d-${CLUSTER_NAME}.yaml

#    --k3s-server-arg '--no-deploy=traefik' \
#    --volume "$(pwd)/deployments/helm-ingress-nginx.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-nginx.yaml" \
    sleep 2
    header "LoadBalancer info:"
    kubectl -n=kube-system get svc | egrep -e NAME -e LoadBalancer
    footer
}

installIngress ()
{
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  helm install --namespace ingress-nginx  --create-namespace ingress bitnami/nginx-ingress-controller
}


installDashboard ()
{
    kubectl config use-context k3d-${CLUSTER_NAME}

    # Install Kubernetes Dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
    # Create dashboard account
    kubectl create serviceaccount dashboard-admin-sa
    # bind the dashboard-admin-service-account service account to the cluster-admin role
    kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
    # display token
    header "Keep this Token to acces dashboard"
    #kubectl describe secret $(kubectl get secrets | grep dashboard-admin-sa | cut -d' ' -f1)
    kubectl describe secret $(kubectl get secrets | grep dashboard-admin-sa | awk '{ print $1 }')

    header "Dashboard Access:"
    echo "kubectl proxy"
    echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login"
    footer
}


installPrometheus ()
{
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add stable https://charts.helm.sh/stable
    helm repo update
    helm install --namespace monitoring --create-namespace prometheus  --set server.global.scrape_interval=30s prometheus-community/prometheus
    helm install --namespace monitoring --create-namespace grafana stable/grafana --set sidecar.datasources.enabled=true --set sidecar.dashboards.enabled=true --set sidecar.datasources.label=grafana_datasource --set sidecar.dashboards.label=grafana_dashboard
    cat <<EOF | kubectl create -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  namespace: monitoring
  annotations:
    ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
    - host: grafana.${CLUSTER_DOMAIN}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 80
EOF

    header "Grafana Access:"
    echo "url: https://grafana.${CLUSTER_DOMAIN}"
    echo "username: admin"
    echo "password: $(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)"
    footer
}

checkDependencies 

#Retrieve config values 
read_value "Cluster Name" "${CLUSTER_NAME}"
CLUSTER_NAME=${READ_VALUE}
read_value "Cluster Domain" "${CLUSTER_DOMAIN}"
CLUSTER_DOMAIN=${READ_VALUE}
read_value "API Port" "${API_PORT}"
API_PORT=${READ_VALUE}
read_value "Servers (Masters)" "${SERVERS}"
SERVERS=${READ_VALUE}
read_value "Agents (Workers)" "${AGENTS}"
AGENTS=${READ_VALUE}
read_value "LoadBalancer HTTP Port" "${HTTP_PORT}"
HTTP_PORT=${READ_VALUE}
read_value "LoadBalancer HTTPS Port" "${HTTPS_PORT}"
HTTPS_PORT=${READ_VALUE}

# Todo Ask Traefik v2 & Calico
#read_value "Install Traefik V2" "${TRAEFIK_V2}"
#TRAEFIK_V2=${READ_VALUE}

installCluster
installIngress

read_value "Install Dashbard? (Yes/No)" "${INSTALL_DASHBOARD}"
INSTALL_DASHBOARD=${READ_VALUE}
if [ "${INSTALL_DASHBOARD}" = "Yes" ];
then
    installDashboard
fi

read_value "Install Prometheus? (Yes/No)" "${INSTALL_PROMETHEUS}"
INSTALL_PROMETHEUS=${READ_VALUE}

if [ "${INSTALL_PROMETHEUS}" = "Yes" ];
then
    installPrometheus
fi