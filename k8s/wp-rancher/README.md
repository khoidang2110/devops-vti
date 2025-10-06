# Hướng dẫn Deploy WordPress + Rancher trên K8s

## Yêu cầu
- K8s cluster đang chạy (EKS hoặc bất kỳ)
- Helm 3 đã cài đặt
- kubectl đã cấu hình

## 1. Xóa tất cả (nếu đã deploy trước đó)

```bash
# Xóa Helm releases
helm uninstall wordpress 2>/dev/null || true
helm uninstall rancher 2>/dev/null || true

# Xóa PV và namespace
kubectl delete pv mysql-pv wordpress-pv 2>/dev/null || true
kubectl delete namespace cattle-system 2>/dev/null || true

# Đợi resources bị xóa hoàn toàn
sleep 10
```

## 2. Deploy WordPress + MySQL

### Bước 1: Tạo PersistentVolume
```bash
kubectl apply -f local-pv.yaml
```

### Bước 2: Deploy WordPress
```bash
helm install wordpress ./wordpress-chart
```

### Bước 3: Lấy LoadBalancer IP cho WordPress
```bash
# Đợi LoadBalancer được tạo (2-3 phút)
kubectl get svc wordpress -w

# Lấy hostname
WP_LB=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "WordPress LoadBalancer: $WP_LB"

# Resolve IP
WP_IP=$(nslookup $WP_LB | grep -A1 "Name:" | grep Address | awk '{print $2}')
echo "WordPress IP: $WP_IP"
```

### Bước 4: Cập nhật domain cho WordPress
```bash
# Sửa file wordpress-chart/templates/wordpress-deployment.yaml
# Thay IP trong dòng: define('WP_HOME', 'http://wordpress.YOUR_IP.nip.io');
# Với IP vừa lấy được

# Sau đó upgrade
helm upgrade wordpress ./wordpress-chart
```

### Bước 5: Truy cập WordPress
```bash
echo "WordPress URL: http://wordpress.$WP_IP.nip.io"
```

## 3. Deploy Rancher

### Bước 1: Lấy IP trước để cấu hình
```bash
# Deploy Rancher lần đầu để lấy LoadBalancer IP
helm install rancher ./rancher-chart

# Đợi LoadBalancer được tạo
kubectl get svc -n cattle-system rancher -w

# Lấy IP
RANCHER_LB=$(kubectl get svc -n cattle-system rancher -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
RANCHER_IP=$(nslookup $RANCHER_LB | grep -A1 "Name:" | grep Address | awk '{print $2}')
echo "Rancher IP: $RANCHER_IP"
```

### Bước 2: Cập nhật domain cho Rancher
```bash
# Sửa file rancher-chart/templates/rancher-deployment.yaml
# Thay IP trong dòng: value: https://rancher.YOUR_IP.nip.io
# Với IP vừa lấy được

# Upgrade Rancher
helm upgrade rancher ./rancher-chart
```

### Bước 3: Đợi pod sẵn sàng
```bash
kubectl get pods -n cattle-system -w
```

### Bước 4: Truy cập Rancher
```bash
echo "Rancher URL: https://rancher.$RANCHER_IP.nip.io"
echo "Username: admin"
echo "Password: admin123"
```

## 4. Script tự động (Recommended)

Tạo file `deploy-all.sh`:

```bash
#!/bin/bash

echo "=== Xóa resources cũ ==="
helm uninstall wordpress 2>/dev/null || true
helm uninstall rancher 2>/dev/null || true
kubectl delete pv mysql-pv wordpress-pv 2>/dev/null || true
kubectl delete namespace cattle-system 2>/dev/null || true
sleep 10

echo "=== Deploy WordPress ==="
kubectl apply -f local-pv.yaml
helm install wordpress ./wordpress-chart

echo "Đợi WordPress LoadBalancer..."
sleep 60
WP_LB=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
WP_IP=$(nslookup $WP_LB | grep -A1 "Name:" | grep Address | awk '{print $2}')

echo "WordPress IP: $WP_IP"
echo "Cập nhật WordPress domain..."
sed -i.bak "s|define('WP_HOME', 'http://wordpress\.[0-9.]*\.nip\.io')|define('WP_HOME', 'http://wordpress.$WP_IP.nip.io')|g" wordpress-chart/templates/wordpress-deployment.yaml
sed -i.bak "s|define('WP_SITEURL', 'http://wordpress\.[0-9.]*\.nip\.io')|define('WP_SITEURL', 'http://wordpress.$WP_IP.nip.io')|g" wordpress-chart/templates/wordpress-deployment.yaml
helm upgrade wordpress ./wordpress-chart

echo "=== Deploy Rancher ==="
helm install rancher ./rancher-chart

echo "Đợi Rancher LoadBalancer..."
sleep 60
RANCHER_LB=$(kubectl get svc -n cattle-system rancher -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
RANCHER_IP=$(nslookup $RANCHER_LB | grep -A1 "Name:" | grep Address | awk '{print $2}')

echo "Rancher IP: $RANCHER_IP"
echo "Cập nhật Rancher domain..."
sed -i.bak "s|value: https://rancher\.[0-9.]*\.nip\.io|value: https://rancher.$RANCHER_IP.nip.io|g" rancher-chart/templates/rancher-deployment.yaml
helm upgrade rancher ./rancher-chart

echo ""
echo "=== HOÀN THÀNH ==="
echo "WordPress: http://wordpress.$WP_IP.nip.io"
echo "Rancher: https://rancher.$RANCHER_IP.nip.io"
echo "Rancher Login - Username: admin, Password: admin123"
```

Chạy script:
```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

## 5. Kiểm tra trạng thái

```bash
# Xem tất cả pods
kubectl get pods --all-namespaces

# Xem services
kubectl get svc --all-namespaces

# Xem PVC
kubectl get pvc
```

## 6. Troubleshooting

### WordPress không truy cập được
```bash
kubectl logs -f deployment/wordpress
kubectl describe pod -l app=wordpress
```

### Rancher không khởi động
```bash
kubectl logs -n cattle-system -l app=rancher
kubectl describe pod -n cattle-system -l app=rancher
```

### LoadBalancer pending
```bash
# Kiểm tra AWS Load Balancer Controller
kubectl get svc --all-namespaces | grep LoadBalancer
```

## Cấu trúc thư mục

```
rancher/
├── README.md                          # File này
├── deploy-all.sh                      # Script tự động
├── local-pv.yaml                      # PersistentVolume cho WordPress
├── wordpress-chart/                   # Helm chart WordPress
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   └── templates/
│       ├── mysql-deployment.yaml
│       ├── mysql-service.yaml
│       ├── mysql-secret.yaml
│       ├── mysql-pvc.yaml
│       ├── wordpress-deployment.yaml
│       ├── wordpress-service.yaml
│       └── wordpress-pvc.yaml
└── rancher-chart/                     # Helm chart Rancher
    ├── Chart.yaml
    ├── values.yaml
    ├── README.md
    └── templates/
        ├── namespace.yaml
        ├── rbac.yaml
        ├── rancher-deployment.yaml
        └── rancher-service.yaml
```
