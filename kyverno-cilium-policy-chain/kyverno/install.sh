#!/usr/bin/env bash
# Kyverno 1.19.x from the official chart. CRDs come with the chart.
set -euo pipefail
KYVERNO_VERSION="${KYVERNO_VERSION:-3.9.1}"   # chart 3.9.1 = Kyverno v1.19.1
helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
helm repo update kyverno >/dev/null
helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --version "$KYVERNO_VERSION" -f "$(dirname "$0")/values.yaml"
kubectl -n kyverno rollout status deploy/kyverno-admission-controller --timeout=180s
kubectl -n kyverno rollout status deploy/kyverno-background-controller --timeout=180s
kubectl -n kyverno get pods
