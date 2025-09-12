#!/bin/bash
set -o errexit

echo "Setting up Cert Manager in Kubernetes"
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

NAMESPACE="arc-runners"

echo "Setting up GitHub Actions Runner Controller in Kubernetes"
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update
helm install gha-rs-controller actions-runner-controller/actions-runner-controller --namespace "$NAMESPACE" --create-namespace

INSTALLATION_NAME="arc-runner-set"
GITHUB_CONFIG_URL="https://github.com/abretz-mimacom/flowable-deploy-template"
GITHUB_PAT="$GITHUB_TOKEN"

echo "Setting up GitHub Actions Runners scaleset in Kubernetes"
helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
