#!/usr/bin/env bash
# Cilium 1.20.2 on the kind cluster from kind/config.yaml.
set -euo pipefail
CILIUM_VERSION="${CILIUM_VERSION:-1.20.2}"
helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo update cilium >/dev/null
helm upgrade --install cilium cilium/cilium --version "$CILIUM_VERSION" \
  -n kube-system -f "$(dirname "$0")/values.yaml"
cilium status --wait
