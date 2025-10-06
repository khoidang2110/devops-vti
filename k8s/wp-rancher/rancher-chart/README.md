# Rancher Helm Chart với nip.io

## Cài đặt

```bash
helm install rancher ./rancher-chart
```

## Lấy URL với nip.io

```bash
# Đợi LoadBalancer được tạo
kubectl get svc -n cattle-system rancher -w

# Lấy IP
LB_HOST=$(kubectl get svc -n cattle-system rancher -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
LB_IP=$(nslookup $LB_HOST | grep Address | tail -1 | awk '{print $2}')
echo "Rancher URL: https://rancher.${LB_IP}.nip.io"
```

## Login

- Username: admin
- Password: admin123
