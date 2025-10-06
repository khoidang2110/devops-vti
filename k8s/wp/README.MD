kubectl apply -f wordpress-mysql.yaml

kubectl get pods
kubectl get svc

kubectl rollout undo deployment wordpress

(xoá)
kubectl delete -f wordpress-mysql.yaml

Các bước chạy:

(tạo EBS + apply PersistentVolumeClaim (PVC))
kubectl apply -f storage.yaml



kubectl apply -f storage.yaml
kubectl apply -f postgres.yaml
kubectl apply -f wordpress.yaml


kubectl delete pvc postgres-pvc
kubectl delete -f storage.yaml
kubectl delete -f postgres.yaml
kubectl delete -f wordpress.yaml

kubectl get pvc
kubectl get pv
