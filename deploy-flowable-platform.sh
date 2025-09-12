#!/bin/bash
set -e

# Usage: ./deploy-flowable-platform.sh <release-name> [namespace]
# <release-name>: Helm release name (required)
# [namespace]: Kubernetes namespace (default: flowable)

if [ -z "$1" ]; then
    echo "Usage: $0 <release-name> [namespace]"
    exit 1
fi

NAMESPACE="$1"
RELEASE_NAME="${2:-flowable}"


# Ensure required environment variables are set
if [ -z "$FLOWABLE_REPO_USER" ] || [ -z "$FLOWABLE_REPO_PASSWORD" ]; then
    echo "Please set FLOWABLE_REPO_USER and FLOWABLE_REPO_PASSWORD environment variables."
    exit 1
fi

# Check if namespace exists, if not create it
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace $NAMESPACE exists. Will not attempt to create it."
else
  echo "Namespace $NAMESPACE does not exist. Creating it now."
  source "$CODESPACE_VSCODE_FOLDER/scripts/create-ns-secrets.sh" "$NAMESPACE" "$RELEASE_NAME"
fi

# Add the Flowable Helm repo
helm repo add flowable https://repo.flowable.com/flowable-helm \
    --username "$FLOWABLE_REPO_USER" \
    --password "$FLOWABLE_REPO_PASSWORD"

helm repo update

helm dependency build "$CODESPACE_VSCODE_FOLDER/helm/"

# Install or upgrade the Flowable platform chart from local ./helm directory
helm upgrade --install "$RELEASE_NAME" "$CODESPACE_VSCODE_FOLDER/helm/" -f "$CODESPACE_VSCODE_FOLDER/helm/$NAMESPACE/values.yaml" \
    --namespace "$NAMESPACE" \
    --create-namespace

echo "Flowable platform deployed with release name '$RELEASE_NAME' in namespace '$NAMESPACE'."
