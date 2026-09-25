#!/usr/bin/env bash
# Create a Talos cluster as Docker containers: 1 control plane + 1 worker.
# Works on Apple Silicon (Colima or Docker Desktop) and on Linux.
set -euo pipefail

CLUSTER=${CLUSTER:-talos-lab}
LAB=${LAB:-$(pwd)/.lab}
TALOS_VERSION=${TALOS_VERSION:-v1.13.10}
K8S_VERSION=${K8S_VERSION:-1.35.8}   # one minor behind, so upgrade.sh has somewhere to go

# talosctl dials the Docker socket directly and ignores `docker context`.
export DOCKER_HOST=${DOCKER_HOST:-$(docker context inspect -f '{{.Endpoints.docker.Host}}')}

mkdir -p "$LAB"
export TALOSCONFIG="$LAB/talosconfig"
export KUBECONFIG="$LAB/kubeconfig"

# Only the cluster-wide patch and the control-plane patch go in at generation time.
# config/worker.patch.yaml is applied to the running worker later by `make patch`.
talosctl cluster create docker \
  --name "$CLUSTER" \
  --state "$LAB/state" \
  --image "ghcr.io/siderolabs/talos:${TALOS_VERSION}" \
  --kubernetes-version "$K8S_VERSION" \
  --workers 1 \
  --config-patch @config/lab.patch.yaml \
  --config-patch-controlplanes @config/controlplane.patch.yaml \
  --talosconfig-destination "$TALOSCONFIG"

talosctl config node 10.5.0.2

# The kubeconfig Talos hands out points at https://10.5.0.2:6443, the container's
# own address. On macOS that network lives inside the Colima / Docker Desktop VM,
# so rewrite the server to the port Docker published on 127.0.0.1.
talosctl kubeconfig "$KUBECONFIG" --force
PORT=$(docker port "${CLUSTER}-controlplane-1" 6443/tcp | head -1 | cut -d: -f2)
kubectl config set-cluster "$CLUSTER" --server="https://127.0.0.1:${PORT}" >/dev/null

echo
echo "TALOSCONFIG=$TALOSCONFIG"
echo "KUBECONFIG=$KUBECONFIG   (API server: https://127.0.0.1:${PORT})"
