Run these in order
```bash
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check if it worked
kubectl get all
minikube service my-web-service --url
```
