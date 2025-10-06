#!/bin/bash

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
  echo "Usage: ./force-delete-namespace.sh <namespace>"
  exit 1
fi

echo "Force deleting namespace: $NAMESPACE"

# Xóa finalizers
kubectl patch namespace $NAMESPACE -p '{"spec":{"finalizers":[]}}' --type=merge 2>/dev/null || true

# Lấy namespace json và xóa finalizers
TEMP_FILE=$(mktemp)
kubectl get namespace $NAMESPACE -o json > $TEMP_FILE 2>/dev/null

# Sửa finalizers thành empty array
sed -i.bak 's/"finalizers": \[[^]]*\]/"finalizers": []/g' $TEMP_FILE

# Replace qua API
kubectl replace --raw /api/v1/namespaces/$NAMESPACE/finalize -f $TEMP_FILE 2>/dev/null || true

rm -f $TEMP_FILE $TEMP_FILE.bak

echo "Done. Check: kubectl get namespace $NAMESPACE"
