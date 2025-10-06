# Hướng dẫn Restart EKS Cluster

## Cách 1: Restart Worker Nodes (Khuyến nghị)

### Bước 1: Lấy thông tin nodes
```bash
kubectl get nodes -o wide
```

### Bước 2: Drain nodes (chuyển pods sang node khác)
```bash
# Drain từng node
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data --force
```

### Bước 3: Restart nodes trên AWS Console
1. Vào AWS Console > EC2
2. Tìm instances của EKS worker nodes
3. Chọn instance > Actions > Instance State > Reboot

### Bước 4: Uncordon nodes (cho phép schedule pods lại)
```bash
kubectl uncordon <NODE_NAME>
```

## Cách 2: Terminate và tạo lại nodes (Nhanh hơn)

### Bước 1: Terminate nodes trên AWS
1. Vào AWS Console > EC2
2. Terminate tất cả worker nodes
3. Auto Scaling Group sẽ tự động tạo nodes mới

### Bước 2: Đợi nodes mới sẵn sàng
```bash
kubectl get nodes -w
```

## Cách 3: Xóa namespace bằng API (Không cần restart)

### Thử force xóa namespace cattle-system
```bash
kubectl get namespace cattle-system -o json > cattle-system.json
# Sửa file: xóa "finalizers": [...] trong spec
kubectl replace --raw "/api/v1/namespaces/cattle-system/finalize" -f cattle-system.json
```

Hoặc dùng lệnh nhanh:
```bash
kubectl get namespace cattle-system -o json | \
  sed 's/"finalizers": \[[^]]*\]/"finalizers": []/g' | \
  kubectl replace --raw /api/v1/namespaces/cattle-system/finalize -f -
```

## Cách 4: Script tự động xóa namespace stuck

Tạo file `force-delete-namespace.sh`:
```bash
#!/bin/bash

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
  echo "Usage: ./force-delete-namespace.sh <namespace>"
  exit 1
fi

echo "Force deleting namespace: $NAMESPACE"

# Xóa finalizers
kubectl patch namespace $NAMESPACE -p '{"spec":{"finalizers":[]}}' --type=merge

# Xóa qua API
kubectl get namespace $NAMESPACE -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw /api/v1/namespaces/$NAMESPACE/finalize -f -

echo "Done"
```

Chạy:
```bash
chmod +x force-delete-namespace.sh
./force-delete-namespace.sh cattle-system
```

## Sau khi restart/xóa namespace

```bash
# Kiểm tra cluster
kubectl get nodes
kubectl get namespaces

# Chạy cleanup và deploy
./cleanup.sh
./deploy-all.sh
```
