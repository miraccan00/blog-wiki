#!/usr/bin/env bash
# scripts/probe.sh [label] — ask Argo CD for a hard refresh of product-helloapi-prod and time
# how long until the controller writes a new reconciledAt. A hard refresh needs all three:
# the application controller (does the comparison), a repo-server (re-renders the chart,
# cache bypassed) and Redis (the controller caches the result there).
# Unlike selfHeal this has no backoff, so it is safe to run again and again.
set -euo pipefail
APP=${APP:-product-helloapi-prod}
before=$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.reconciledAt}')
# reconciledAt has 1 s resolution: if the refresh lands in the same second as the last
# reconcile (e.g. right after drift.sh), the value doesn't change and we'd wait for the
# next periodic reconcile (~3 min). Step into the next second before starting the clock.
sleep 1
start=$(date +%s)
kubectl -n argocd annotate application "$APP" argocd.argoproj.io/refresh=hard --overwrite >/dev/null
until now=$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.reconciledAt}' 2>/dev/null) && [ -n "$now" ] && [ "$now" != "$before" ]; do
  sleep 1
  if [ $(( $(date +%s) - start )) -gt ${TIMEOUT:-600} ]; then echo "${1:-probe}: no reconciliation for ${TIMEOUT:-600}s (last: $before)"; exit 1; fi
done
echo "${1:-probe}: hard refresh reconciled in $(( $(date +%s) - start ))s"
