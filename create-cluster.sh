#!/bin/sh
API_PORT=6443
HTTP_PORT=80
HTTPS_PORT=443
CLUSTER_NAME=k3d-cluster
READ_VALUE=
SERVERS=1
AGENTS=2
TRAEFIK_V2=Yes

# $1 text to show - $2 default value
read_value ()
{
    read -p "${1} [${2}]: " READ_VALUE
    if [ "${READ_VALUE}" = "" ]
    then
        READ_VALUE=$2
    fi
}

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
}




installCluster ()
{
    echo "Creating K3D cluster"
    k3d cluster create ${CLUSTER_NAME} \
    --api-port ${API_PORT} \
    --port ${HTTPS_PORT}:443@loadbalancer  \
    --port ${HTTP_PORT}:80@loadbalancer \
    --volume $(pwd)/k3dvol:/tmp/k3dvol \
#    --k3s-server-arg '--no-deploy=traefik' \
#    --volume "$(pwd)/deployments/helm-ingress-nginx.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-nginx.yaml" \
    --servers ${SERVERS} \
    --agents ${AGENTS}

    echo "LoadBalancer info:"
    echo "kubectl -n=kube-system get svc | egrep -e NAME -e LoadBalancer"
}


checkDependencies 

#Retrieve config values 
read_value "Cluster Name" "${CLUSTER_NAME}"
CLUSTER_NAME=${READ_VALUE}
read_value "API Port" "${API_PORT}"
API_PORT=${READ_VALUE}
read_value "Servers (aka Masters)" "${SERVERS}"
SERVERS=${READ_VALUE}
read_value "Agents (aka Workers)" "${AGENTS}"
AGENTS=${READ_VALUE}
read_value "HTTP Port" "${HTTP_PORT}"
HTTP_PORT=${READ_VALUE}
read_value "HTTPS Port" "${HTTPS_PORT}"
HTTPS_PORT=${READ_VALUE}

# Todo Ask Traefik v2 & Calico
#read_value "Install Traefik V2" "${TRAEFIK_V2}"
#TRAEFIK_V2=${READ_VALUE}

installCluster