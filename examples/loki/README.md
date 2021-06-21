helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm show values grafana/loki-stack > /tmp/loki-stack-values.yaml
helm upgrade --install loki grafana/loki-stack --values /tmp/loki-stack-values.yaml -n loki --create-namespace

kubectl get secret --namespace loki loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo



kubectl get all -n loki                              
NAME                                                READY   STATUS              RESTARTS   AGE
pod/loki-promtail-sfhgz                             0/1     ContainerCreating   0          20s
pod/loki-promtail-z82xf                             0/1     ContainerCreating   0          20s
pod/loki-prometheus-node-exporter-2xkt2             0/1     ContainerCreating   0          20s
pod/loki-0                                          0/1     ContainerCreating   0          20s
pod/loki-prometheus-alertmanager-6d999d78c5-cgprr   0/2     ContainerCreating   0          20s
pod/loki-kube-state-metrics-6c7c68c46-cf76f         1/1     Running             0          20s
pod/loki-prometheus-server-545c88f87d-h5k2q         0/2     ContainerCreating   0          20s
pod/loki-prometheus-node-exporter-j799q             1/1     Running             0          20s
pod/loki-prometheus-pushgateway-f8d8f7945-4gg24     0/1     Running             0          20s

NAME                                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/loki-headless                   ClusterIP   None            <none>        3100/TCP   20s
service/loki                            ClusterIP   10.43.95.216    <none>        3100/TCP   20s
service/loki-prometheus-node-exporter   ClusterIP   None            <none>        9100/TCP   20s
service/loki-prometheus-alertmanager    ClusterIP   10.43.175.91    <none>        80/TCP     20s
service/loki-kube-state-metrics         ClusterIP   10.43.111.121   <none>        8080/TCP   20s
service/loki-prometheus-server          ClusterIP   10.43.133.226   <none>        80/TCP     20s
service/loki-prometheus-pushgateway     ClusterIP   10.43.223.55    <none>        9091/TCP   20s

NAME                                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/loki-promtail                   2         2         0       2            0           <none>          20s
daemonset.apps/loki-prometheus-node-exporter   2         2         1       2            1           <none>          20s

NAME                                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/loki-prometheus-pushgateway    0/1     1            0           20s
deployment.apps/loki-prometheus-server         0/1     1            0           20s
deployment.apps/loki-prometheus-alertmanager   0/1     1            0           20s
deployment.apps/loki-kube-state-metrics        1/1     1            1           20s

NAME                                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/loki-prometheus-pushgateway-f8d8f7945     1         1         0       20s
replicaset.apps/loki-prometheus-alertmanager-6d999d78c5   1         1         0       20s
replicaset.apps/loki-prometheus-server-545c88f87d         1         1         0       20s
replicaset.apps/loki-kube-state-metrics-6c7c68c46         1         1         1       20s