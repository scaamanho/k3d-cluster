```yaml
...
  k3s:
    extraServerArgs:
      - --tls-san=127.0.0.1
      - --no-deploy=traefik
...
```


Deploy Ingress
--------------

```sh 
$> kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
```


```sh
$> helm repo add bitnami https://charts.bitnami.com/bitnami
$> helm repo update
$> helm install --namespace ingress-nginx  --create-namespace ingress bitnami/nginx-ingress-controller
```

Test Ingress
------------

`nginx-ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  rules:
  - host: "nginx.fuf.me"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: nginx
            port:
              number: 80
```


```
$ kubectl create deployment nginx --image=nginx
$ kubectl create service clusterip nginx --tcp=80:80
$ kubectl apply -f  nginx-ingress.yaml
```