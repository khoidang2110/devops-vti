#!/bin/bash

set -e
echo "=== Deploy WordPress + MySQL ==="
kubectl apply -f local-pv.yaml
helm install wordpress ./wordpress-chart

echo "Đợi WordPress LoadBalancer được tạo (60s)..."
sleep 60

WP_LB=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "WordPress LoadBalancer: $WP_LB"

WP_IP=$(nslookup $WP_LB 2>/dev/null | grep -A1 "Name:" | grep Address | awk '{print $2}')
echo "WordPress IP: $WP_IP"

if [ -z "$WP_IP" ]; then
    echo "Không lấy được IP, thử lại..."
    sleep 30
    WP_IP=$(nslookup $WP_LB 2>/dev/null | grep -A1 "Name:" | grep Address | awk '{print $2}')
fi

echo "Cập nhật WordPress domain..."
sed -i.bak "s|http://wordpress\.[0-9.]*\.nip\.io|http://wordpress.$WP_IP.nip.io|g" wordpress-chart/templates/wordpress-deployment.yaml
helm upgrade wordpress ./wordpress-chart

echo ""
echo "=== Deploy Rancher ==="
helm install rancher ./rancher-chart

echo "Đợi Rancher LoadBalancer được tạo (60s)..."
sleep 60

RANCHER_LB=$(kubectl get svc -n cattle-system rancher -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Rancher LoadBalancer: $RANCHER_LB"

RANCHER_IP=$(nslookup $RANCHER_LB 2>/dev/null | grep -A1 "Name:" | grep Address | awk '{print $2}')
echo "Rancher IP: $RANCHER_IP"

if [ -z "$RANCHER_IP" ]; then
    echo "Không lấy được IP, thử lại..."
    sleep 30
    RANCHER_IP=$(nslookup $RANCHER_LB 2>/dev/null | grep -A1 "Name:" | grep Address | awk '{print $2}')
fi

echo "Cập nhật Rancher domain..."
sed -i.bak "s|https://rancher\.[0-9.]*\.nip\.io|https://rancher.$RANCHER_IP.nip.io|g" rancher-chart/templates/rancher-deployment.yaml
helm upgrade rancher ./rancher-chart

echo ""
echo "Đợi pods sẵn sàng..."
sleep 30

echo ""
echo "=== HOÀN THÀNH ==="
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "WordPress URL: http://wordpress.$WP_IP.nip.io"
echo "WordPress Admin: http://wordpress.$WP_IP.nip.io/wp-admin/"
echo ""
echo "Rancher URL: https://rancher.$RANCHER_IP.nip.io"
echo "Rancher Login:"
echo "  - Username: admin"
echo "  - Password: admin123"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Kiểm tra trạng thái:"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get svc --all-namespaces"
