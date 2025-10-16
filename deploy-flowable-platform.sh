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


# Check for required environment variables and prompt if not set
if [ -z "$FLOWABLE_REPO_USER" ]; then
  echo "FLOWABLE_REPO_USER is not set."
  read -rp "Please enter your Flowable repository username: " FLOWABLE_REPO_USER
  
  if [ -z "$FLOWABLE_REPO_USER" ]; then
    echo "Error: FLOWABLE_REPO_USER is required."
    exit 1
  fi
  
  # Attempt to store as Codespace secret if running in Codespaces
  if [ -n "$CODESPACE_NAME" ]; then
    echo "Attempting to store FLOWABLE_REPO_USER as a Codespace secret..."
    if gh codespace secrets set FLOWABLE_REPO_USER -b "$FLOWABLE_REPO_USER" 2>/dev/null; then
      echo "Successfully stored FLOWABLE_REPO_USER as a Codespace secret."
    else
      echo "Warning: Failed to store FLOWABLE_REPO_USER as a Codespace secret. Continuing with current session value."
    fi
  fi
fi

if [ -z "$FLOWABLE_REPO_PASS" ]; then
  echo "FLOWABLE_REPO_PASS is not set."
  read -rsp "Please enter your Flowable repository password: " FLOWABLE_REPO_PASS
  echo  # New line after password input
  
  if [ -z "$FLOWABLE_REPO_PASS" ]; then
    echo "Error: FLOWABLE_REPO_PASS is required."
    exit 1
  fi
  
  # Attempt to store as Codespace secret if running in Codespaces
  if [ -n "$CODESPACE_NAME" ]; then
    echo "Attempting to store FLOWABLE_REPO_PASS as a Codespace secret..."
    if gh codespace secrets set FLOWABLE_REPO_PASS -b "$FLOWABLE_REPO_PASS" 2>/dev/null; then
      echo "Successfully stored FLOWABLE_REPO_PASS as a Codespace secret."
    else
      echo "Warning: Failed to store FLOWABLE_REPO_PASS as a Codespace secret. Continuing with current session value."
    fi
  fi
fi

if [ -z "$FLOWABLE_LICENSE_KEY" ]; then
  echo "FLOWABLE_LICENSE_KEY is not set."
  read -rp "Please enter your Flowable license key: " FLOWABLE_LICENSE_KEY
  
  if [ -z "$FLOWABLE_LICENSE_KEY" ]; then
    echo "Error: FLOWABLE_LICENSE_KEY is required."
    exit 1
  fi
  
  # Attempt to store as Codespace secret if running in Codespaces
  if [ -n "$CODESPACE_NAME" ]; then
    echo "Attempting to store FLOWABLE_LICENSE_KEY as a Codespace secret..."
    if gh codespace secrets set FLOWABLE_LICENSE_KEY -b "$FLOWABLE_LICENSE_KEY" 2>/dev/null; then
      echo "Successfully stored FLOWABLE_LICENSE_KEY as a Codespace secret."
    else
      echo "Warning: Failed to store FLOWABLE_LICENSE_KEY as a Codespace secret. Continuing with current session value."
    fi
  fi
fi

# Note: Script uses FLOWABLE_REPO_PASSWORD for Helm, but prompts use FLOWABLE_REPO_PASS
# Set FLOWABLE_REPO_PASSWORD to match the existing code if it was prompted
if [ -n "$FLOWABLE_REPO_PASS" ]; then
  FLOWABLE_REPO_PASSWORD="$FLOWABLE_REPO_PASS"
fi

# Ensure required environment variables are set
if [ -z "$FLOWABLE_REPO_USER" ] || [ -z "$FLOWABLE_REPO_PASSWORD" ]; then
    echo "Error: FLOWABLE_REPO_USER and FLOWABLE_REPO_PASSWORD must be set."
    exit 1
fi

PROJECT_DIR="${CODESPACE_VSCODE_FOLDER:-$GITHUB_WORKSPACE}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
echo "Project directory is: $PROJECT_DIR"

# Check if namespace exists, if not create it
if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace $NAMESPACE exists. Will not attempt to create it."
else
  echo "Namespace $NAMESPACE does not exist. Creating it now."
  source "$PROJECT_DIR/scripts/create-ns-secrets.sh" "$NAMESPACE" "$RELEASE_NAME"
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

echo "Flowable platform deployed with release name '$RELEASE_NAME' in namespace '$NAMESPACE'."
