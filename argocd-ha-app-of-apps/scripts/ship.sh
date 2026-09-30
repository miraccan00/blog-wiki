#!/usr/bin/env bash
# scripts/ship.sh — run right after pushing a change to product-helloapi-gitops.
# Without a webhook Argo CD polls Git every 3 minutes (timeout.reconciliation, plus jitter).
# The refresh annotation does what a GitHub webhook would do: tell Argo CD to look now.
set -euo pipefail
APP=${APP:-product-helloapi-prod}
before=$(kubectl -n argocd get application $APP -o jsonpath='{.status.sync.revision}')
start=$(date +%s)
kubectl -n argocd annotate application $APP argocd.argoproj.io/refresh=normal --overwrite >/dev/null
until rev=$(kubectl -n argocd get application $APP -o jsonpath='{.status.sync.revision}') && [ "$rev" != "$before" ] \
  && [ "$(kubectl -n argocd get application $APP -o jsonpath='{.status.sync.status}/{.status.health.status}')" = "Synced/Healthy" ]; do
  sleep 1
done
echo "$APP: ${before:0:7} -> ${rev:0:7}, Synced/Healthy $(( $(date +%s) - start ))s after refresh"
