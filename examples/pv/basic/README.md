**NOTA**: If u use manual, you only can create one `pv` and one `pvc` asociated to this storage


Verify if `pv` and pvc is allready installed

```
kubectl get pv,pvc
```

if `pv` is not installed

```
kubectl apply -f k3d-pv.yaml k3d-pvc.yaml k3d-persistent-application.yaml
``` 

if `pv` is instaled

```
kubectl apply -f k3d-pvc.yaml k3d-persistent-application.yaml
```

if `pv` and `pvc` is installed 
```
kubectl apply -f k3d-persistent-application.yaml
```



test

```
kubectl exect -it busybox ls /mydata
kubectl exect -it busybox2 ls /mydata
```