#!/usr/bin/env bash
# scripts/wait-apps.sh — wait until the 7 Applications exist and are all Synced + Healthy
#   root, argocd, applicationsets, ns-product-helloapi-{dev,prod}, product-helloapi-{dev,prod}
set -euo pipefail
WANT=${WANT:-7}
start=$(date +%s)
while :; do
  out=$(kubectl -n argocd get applications -o jsonpath='{range .items[*]}{.status.sync.status}/{.status.health.status}{"\n"}{end}' 2>/dev/null || true)
  n=$(grep -c . <<<"$out" || true)
  if [ "$n" -ge "$WANT" ] && ! grep -qv '^Synced/Healthy$' <<<"$out"; then break; fi
  if [ $(( $(date +%s) - start )) -gt 600 ]; then echo "timeout after 600s"; kubectl -n argocd get applications; exit 1; fi
  sleep 2
done
kubectl -n argocd get applications
echo "all $n Synced/Healthy in $(( $(date +%s) - start ))s"
