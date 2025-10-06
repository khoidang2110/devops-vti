#!/bin/bash

echo "=== Xóa resources cũ ==="

# Xóa Helm releases
helm uninstall wordpress -n default 2>/dev/null || true
helm uninstall rancher -n default 2>/dev/null || true

# Xóa tất cả Helm secrets
kubectl delete secret -l owner=helm --all-namespaces 2>/dev/null || true
kubectl delete secret -l name=wordpress --all-namespaces 2>/dev/null || true
kubectl delete secret -l name=rancher --all-namespaces 2>/dev/null || true

# Xóa tất cả resources WordPress/MySQL
echo "Xóa deployments..."
kubectl delete deployment wordpress mysql --grace-period=0 --force 2>/dev/null || true

echo "Xóa services..."
kubectl delete service wordpress mysql 2>/dev/null || true

echo "Xóa secrets..."
kubectl delete secret mysql-secret 2>/dev/null || true

echo "Xóa PVCs..."
kubectl delete pvc wordpress-pvc mysql-pvc 2>/dev/null || true

echo "Xóa PVs..."
kubectl delete pv mysql-pv wordpress-pv 2>/dev/null || true

echo "Đợi resources xóa xong..."
sleep 20

# Xóa Rancher webhooks
kubectl delete validatingwebhookconfiguration rancher.cattle.io 2>/dev/null || true
kubectl delete mutatingwebhookconfiguration rancher.cattle.io 2>/dev/null || true

# Xóa namespace cattle-system
if kubectl get namespace cattle-system 2>/dev/null; then
  echo "Xóa namespace cattle-system..."
  kubectl patch namespace cattle-system -p '{"spec":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  kubectl delete namespace cattle-system --grace-period=0 --force 2>/dev/null &
  echo "Namespace đang được xóa trong background"
fi

sleep 5

echo ""
echo "=== Kiểm tra resources còn lại ==="
REMAINING=$(kubectl get deployment,service,pvc,pv -o name 2>/dev/null | grep -E "wordpress|mysql" || true)
if [ -n "$REMAINING" ]; then
  echo "⚠ Còn resources:"
  kubectl get deployment,service,pvc,pv 2>/dev/null | grep -E "wordpress|mysql|NAME"
  echo ""
  echo "Chạy lại: ./cleanup.sh"
  exit 1
fi
echo "✓ Đã xóa sạch tất cả resources"

echo ""
echo "=== Xóa hoàn tất ==="
echo "Bây giờ có thể chạy: ./deploy-all.sh"
