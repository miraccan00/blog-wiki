#!/usr/bin/env bash
# RBAC first (the background controller needs cilium.io before the first Namespace triggers), then policies.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl apply -f rbac/kyverno-cilium-clusterrole.yaml
kubectl apply -f policies/
kubectl get validatingpolicies,mutatingpolicies,generatingpolicies
