#!/bin/bash
set -o errexit

echo "Setting up Cert Manager in Kubernetes"
helm upgrade --install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Wait for cert-manager (optional but wise)
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=120s
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=120s
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=120s

# Namespaces
kubectl get ns actions-runner-system >/dev/null 2>&1 || kubectl create ns actions-runner-system
kubectl get ns arc-runners >/dev/null 2>&1 || kubectl create ns arc-runners

helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Let Helm create the secret & own it; pass the token via values
helm upgrade --install actions-runner-controller \
  actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system \
  --set authSecret.create=true \
  --set authSecret.github_token="${GITHUB_TOKEN}"

# ARC controller + webhook
kubectl -n actions-runner-system rollout status deploy/actions-runner-controller --timeout=180s

echo "Waiting for ARC controller webhood service to be ready"
sleep 10


echo "Applying GitHub Actions RunnerDeployment"
cat <<EOF | kubectl apply -f -
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: repo-runner
  namespace: arc-runners
spec:
  replicas: 1
  template:
    spec:
      repository: "${GITHUB_REPOSITORY}"
      dockerdWithinRunnerContainer: true
      labels:
        - kind
        - codespaces
EOF

kubectl -n arc-runners get pods -o wide
