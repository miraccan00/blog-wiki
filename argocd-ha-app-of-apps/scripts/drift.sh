#!/usr/bin/env bash
# scripts/drift.sh [label] — scale product-helloapi-prod to 9 by hand and time how long
# Argo CD's selfHeal takes to put it back to what Git says. It only happens if the application
# controller, Redis and a repo-server are all doing their job, so it is the check
# failover.sh runs after each failure.
set -euo pipefail
NS=product-helloapi-prod; DEP=product-helloapi
want=$(kubectl -n $NS get deploy/$DEP -o jsonpath='{.spec.replicas}')   # what Git says right now
kubectl -n $NS scale deploy/$DEP --replicas=9 >/dev/null
start=$(date +%s)
until [ "$(kubectl -n $NS get deploy/$DEP -o jsonpath='{.spec.replicas}')" = "$want" ]; do
  sleep 1
  if [ $(( $(date +%s) - start )) -gt ${TIMEOUT:-900} ]; then echo "${1:-drift}: NOT reverted after ${TIMEOUT:-900}s"; exit 1; fi
done
echo "${1:-drift}: 9 -> $want reverted by Argo CD in $(( $(date +%s) - start ))s"
