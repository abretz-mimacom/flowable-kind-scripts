#!/bin/bash

set -e

NAMESPACE="${1:?Usage: $0 <namespace> [release_name]}"
RELEASE_NAME="${2:-flowable}"

# Find a pod containing "engage"
ENGAGE_POD=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | grep engage | head -n1)
if [ -z "$ENGAGE_POD" ]; then
    echo "No pod containing 'engage' found in namespace $NAMESPACE"
else
    echo "Port-forwarding $ENGAGE_POD 8080 -> 8080-local"
    kubectl port-forward -n "$NAMESPACE" pod/"$ENGAGE_POD" 8080:8080-local &
fi

# Find a pod containing "design"
DESIGN_POD=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | grep design | head -n1)
if [ -n "$DESIGN_POD" ]; then
    echo "Port-forwarding $DESIGN_POD 8080 -> 8081-local"
    kubectl port-forward -n "$NAMESPACE" pod/"$DESIGN_POD" 8080:8081-local &
else
    echo "No pod containing 'design' found in namespace $NAMESPACE"
fi

# Find a pod containing "control"
CONTROL_POD=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | grep control | head -n1)
if [ -z "$CONTROL_POD" ]; then
    echo "No pod containing 'control' found in namespace $NAMESPACE"
else
    echo "Port-forwarding $CONTROL_POD 8080 -> 8082-local"
    kubectl port-forward -n "$NAMESPACE" pod/"$CONTROL_POD" 8080:8082-local &
fi

wait