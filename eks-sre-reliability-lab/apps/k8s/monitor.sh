#!/bin/bash

set -e

echo "======================================"
echo "Kubernetes Monitoring Setup Starting"
echo "Prometheus + Grafana"
echo "======================================"

# Add Helm repo
echo "Adding Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1
helm repo update >/dev/null 2>&1

# Create namespace
echo "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install stack
echo "Installing kube-prometheus-stack..."
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
--namespace monitoring \
--wait

echo "Waiting for Grafana pod..."

kubectl wait \
--namespace monitoring \
--for=condition=ready pod \
--selector=app.kubernetes.io/name=grafana \
--timeout=180s

echo ""
echo "======================================"
echo "Grafana Login Details"
echo "======================================"

PASSWORD=$(kubectl get secret -n monitoring monitoring-grafana \
-o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Username: admin"
echo "Password: $PASSWORD"
echo ""

echo "Grafana URL:"
echo "http://localhost:3000"

echo ""
echo "Starting port-forward..."

kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
