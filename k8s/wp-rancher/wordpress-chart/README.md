# WordPress + MySQL Helm Chart

## Cài đặt

```bash
# Deploy chart
helm install wordpress ./wordpress-chart

# Hoặc với custom values
helm install wordpress ./wordpress-chart --set mysql.rootPassword=mypassword
```

## Kiểm tra

```bash
# Xem pods
kubectl get pods

# Xem services
kubectl get svc

# Lấy URL WordPress (NodePort)
kubectl get svc wordpress
```

## Truy cập WordPress

WordPress sẽ chạy trên NodePort 30080. Truy cập qua:
```
http://<NODE_IP>:30080
```

## Gỡ cài đặt

```bash
helm uninstall wordpress
```

## Cấu hình trong values.yaml

- `mysql.rootPassword`: Root password cho MySQL
- `mysql.database`: Tên database
- `mysql.user`: MySQL user
- `mysql.password`: MySQL password
- `wordpress.nodePort`: Port để truy cập WordPress (mặc định: 30080)
