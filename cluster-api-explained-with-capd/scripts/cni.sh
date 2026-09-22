#!/usr/bin/env bash
# scripts/cni.sh
# Cluster API does NOT install a CNI. Nodes stay NotReady until one exists.
# We install Cilium into the workload cluster through its own kubeconfig.
set -euo pipefail
: "${CLUSTER_NAME:=capi-lab}"
: "${CILIUM_VERSION:=1.18.2}"

clusterctl get kubeconfig "${CLUSTER_NAME}" > "${CLUSTER_NAME}.kubeconfig"

# CAPD exposes the API server on a host port; inside Docker Desktop / Colima
# the certificate is for the load-balancer container, so we skip TLS verify
# for the lab kubeconfig only (never do this outside a lab).
kubectl --kubeconfig "${CLUSTER_NAME}.kubeconfig" config set-cluster "${CLUSTER_NAME}" \
  --server="https://127.0.0.1:$(docker port "${CLUSTER_NAME}-lb" 6443/tcp | cut -d: -f2)" \
  --insecure-skip-tls-verify=true >/dev/null

helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update cilium >/dev/null
helm --kubeconfig "${CLUSTER_NAME}.kubeconfig" upgrade --install cilium cilium/cilium \
  --version "${CILIUM_VERSION}" --namespace kube-system \
  --set ipam.mode=kubernetes

echo "Cilium installed. Nodes should turn Ready within a minute:"
echo "  kubectl --kubeconfig ${CLUSTER_NAME}.kubeconfig get nodes -w"
