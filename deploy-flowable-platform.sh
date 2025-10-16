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

PROJECT_DIR="${CODESPACE_VSCODE_FOLDER:-$GITHUB_WORKSPACE}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$PROJECT_DIR/scripts}"
echo
echo "Project directory is: $PROJECT_DIR"


# Check for required environment variables and prompt if any are missing
if [ -z "$FLOWABLE_REPO_USER" ] || [ -z "$FLOWABLE_REPO_PASSWORD" ] || [ -z "$FLOWABLE_LICENSE_PATH" ]; then
  echo
  echo "One or more required environment variables are not set."
  source "$SCRIPTS_DIR/prompt-secrets-input.sh"
fi

# Ensure required environment variables are set
if [ -z "$FLOWABLE_REPO_USER" ] || [ -z "$FLOWABLE_REPO_PASSWORD" ]; then
    echo
    echo "Error: FLOWABLE_REPO_USER and FLOWABLE_REPO_PASSWORD must be set."
    exit 1
fi

# Check if namespace exists, if not create it
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo
  echo "Namespace $NAMESPACE exists. Will not attempt to create it."
else
  echo
  echo "Namespace $NAMESPACE does not exist. Creating it now."
  source "$SCRIPTS_DIR/create-ns-secrets.sh" "$NAMESPACE" "$RELEASE_NAME"
fi

# Add the Flowable Helm repo
helm repo add flowable https://repo.flowable.com/flowable-helm \
    --username "$FLOWABLE_REPO_USER" \
    --password "$FLOWABLE_REPO_PASSWORD"

helm repo update

helm dependency build "$PROJECT_DIR/helm/"

# Install or upgrade the Flowable platform chart from local ./helm directory
helm upgrade --install "$RELEASE_NAME" "$PROJECT_DIR/helm/" -f "$PROJECT_DIR/helm/$NAMESPACE/values.yaml" \
    --namespace "$NAMESPACE" \
    --create-namespace

echo
echo
echo "Flowable platform deployed with release name '$RELEASE_NAME' in namespace '$NAMESPACE'."
echo
echo
