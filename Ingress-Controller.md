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


openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=fuf.me' -keyout fuf.me.key -out fuf.me.crt
openssl req -out nginx.fuf.me.csr -newkey rsa:2048 -nodes -keyout nginx.fuf.me.key -subj "/CN=nginx.fuf.me/O=some organization"
openssl x509 -req -days 365 -CA fuf.me.crt -CAkey fuf.me.key -set_serial 0 -in nginx.fuf.me.csr -out nginx.fuf.me.crt
kubectl create secret tls nginx-server-certs --key nginx.fuf.me.key --cert nginx.fuf.me.crt



https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-multi-ssl