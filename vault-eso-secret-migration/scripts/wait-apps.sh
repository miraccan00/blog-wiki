#!/usr/bin/env bash
# scripts/wait-apps.sh — wait until the 13 Applications exist and are all Synced + Healthy
#   root, argocd, argocd-secrets, applicationsets, external-secrets, external-secrets-store, vault,
#   zitadel-db, zitadel, ns-product-helloapi-{dev,prod}, product-helloapi-{dev,prod}
set -euo pipefail
WANT=${WANT:-13}
LIMIT=${LIMIT:-600}
# Names to leave out. On a clean cluster argocd-secrets stays Degraded until `make setup` has written
# the OIDC client into Vault, so `make vault` skips it.
SKIP=${SKIP:-}
start=$(date +%s)
while :; do
  out=$(kubectl -n argocd get applications -o jsonpath='{range .items[*]}{.metadata.name} {.status.sync.status}/{.status.health.status}{"\n"}{end}' 2>/dev/null || true)
  [ -n "$SKIP" ] && out=$(grep -vE "^($SKIP) " <<<"$out" || true)
  out=$(cut -d' ' -f2 <<<"$out")
  n=$(grep -c . <<<"$out" || true)
  if [ "$n" -ge "$(( WANT - $(wc -w <<<"${SKIP//|/ }") ))" ] && ! grep -qv '^Synced/Healthy$' <<<"$out"; then break; fi
  if [ $(( $(date +%s) - start )) -gt $LIMIT ]; then echo "timeout after ${LIMIT}s"; kubectl -n argocd get applications; exit 1; fi
  sleep 2
done
kubectl -n argocd get applications
echo "all $n Synced/Healthy in $(( $(date +%s) - start ))s"
