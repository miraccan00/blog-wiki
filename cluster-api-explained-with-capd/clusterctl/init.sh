#!/usr/bin/env bash
# clusterctl/init.sh
# Installs the Cluster API core + kubeadm bootstrap + kubeadm control-plane
# providers and the Docker infrastructure provider into the current kubeconfig.
set -euo pipefail

: "${CAPI_VERSION:=v1.14.2}"   # pinned to the clusterctl minor version

# CAPD is a test provider; it is hidden behind this flag on purpose.
export CLUSTER_TOPOLOGY=true

clusterctl init \
  --core "cluster-api:${CAPI_VERSION}" \
  --bootstrap "kubeadm:${CAPI_VERSION}" \
  --control-plane "kubeadm:${CAPI_VERSION}" \
  --infrastructure "docker:${CAPI_VERSION}"

echo
echo "Providers installed. Watch them come up with:"
echo "  kubectl get pods -A | grep -E 'capi|capd'"
