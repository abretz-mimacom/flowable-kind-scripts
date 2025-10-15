#!/bin/bash
set -o errexit

CLUSTER_NAME="${1:-kind}"

PROJECT_DIR="${CODESPACE_VSCODE_FOLDER:-$GITHUB_WORKSPACE}"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
DISABLE_ARC="${2:-false}"
SINGLE_CLUSTER="${3:-false}"

# 1. Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" \
    registry:2
fi

# Check if kind is installed, install with brew if not
if ! command -v kind >/dev/null 2>&1; then
  echo "kind not found, installing..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, installing..."
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  brew install kind derailed/k9s/k9s
fi

# 2. Create kind cluster with containerd registry config dir enabled
#
# NOTE: the containerd config patch is not necessary with images from kind v0.27.0+
# It may enable some older images to work similarly.
# If you're only supporting newer relases, you can just use `kind create cluster` here.
#
# See:
# https://github.com/kubernetes-sigs/kind/issues/2875
# https://github.com/containerd/containerd/blob/main/docs/cri/config.md#registry-configuration
# See: https://github.com/containerd/containerd/blob/main/docs/hosts.md
if [ -z $SINGLE_CLUSTER ]; then
  echo "Creating 3-node kind cluster ${CLUSTER_NAME}..."
  cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
  kind: Cluster
  apiVersion: kind.x-k8s.io/v1alpha4
  name: "${CLUSTER_NAME}"
  nodes:
    - role: control-plane
    - role: worker
    - role: worker
  containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"
  EOF
fi

if [ $SINGLE_CLUSTER ]; then
  echo "Creating singe-node kind cluster ${CLUSTER_NAME}..."
  cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
  kind: Cluster
  apiVersion: kind.x-k8s.io/v1alpha4
  name: "${CLUSTER_NAME}"
  containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"
  EOF
fi
# 3. Add the registry config to the nodes
#
# This is necessary because localhost resolves to loopback addresses that are
# network-namespace local.
# In other words: localhost in the container is not localhost on the host.
#
# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${reg_port} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# 4. Connect the registry to the cluster network if not already connected
# This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# 5. Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# 6. Add ingress controller
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --set controller.service.type=ClusterIP --namespace ingress-nginx --create-namespace

# 7. Add github action runner
if [ -z DISABLE_ARC ];
  "$PROJECT_DIR/scripts/add-github-action-runner.sh" "$CLUSTER_NAME"
fi
