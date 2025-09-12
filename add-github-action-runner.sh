#!/bin/bash
set -o errexit

helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update
helm install actions-runner-controller actions-runner-controller/actions-runner-controller --namespace actions-runner-system --create-namespace

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/<your_enterprise/org/repo>"
GITHUB_PAT="$GITHUB_TOKEN"

helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
