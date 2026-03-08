#!/bin/bash

set -e

echo "========================================"
echo "Installing ArgoCD in Kubernetes"
echo "========================================"

# 1️⃣ Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2️⃣ Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "========================================"
echo "Installing ArgoCD CLI"
echo "========================================"

# 3️⃣ Install ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

echo "========================================"
echo "Fetching Initial Admin Password"
echo "========================================"

# 4️⃣ Get password
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d)

echo "Username: admin"
echo "Password: $ARGO_PWD"

echo "========================================"
echo "Starting Port Forward"
echo "========================================"

# 5️⃣ Start port forward in background
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

sleep 5

echo "========================================"
echo "Logging into ArgoCD CLI"
echo "========================================"

# 6️⃣ Login CLI
argocd login localhost:8080 \
--username admin \
--password $ARGO_PWD \
--insecure

echo "========================================"
echo "Enable Auto Namespace Creation"
echo "========================================"

# 7️⃣ Enable namespace auto creation
kubectl patch configmap argocd-cm -n argocd \
--type merge \
-p '{"data":{"application.namespaces.autoCreate":"true"}}'

kubectl rollout restart deployment argocd-server -n argocd

echo "========================================"
echo "Creating ArgoCD Application"
echo "========================================"

# 8️⃣ Create GitOps app
argocd app create gitops-nginx \
--repo https://github.com/MasfikurRahaman/Kubernetes_practice.git \
--path gitops \
--dest-server https://kubernetes.default.svc \
--dest-namespace argo-test \
--sync-policy automated

# Enable prune + self heal
argocd app set gitops-nginx \
--sync-policy automated \
--auto-prune \
--self-heal

echo "========================================"
echo "ArgoCD Setup Completed"
echo "========================================"
echo "Access UI: http://localhost:8080"
echo "Username: admin"
echo "Password: $ARGO_PWD"
