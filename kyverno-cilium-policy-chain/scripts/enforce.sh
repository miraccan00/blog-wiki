#!/usr/bin/env bash
# Audit → Deny, in the files. Run after `make report` shows FAIL=0 for real workloads.
# Not `kubectl patch`: the next `kubectl apply -f policies/` (or an Argo CD sync) puts the file's
# Audit back without a word. The change belongs in Git; in a real repo this is a PR.
set -euo pipefail
cd "$(dirname "$0")/.."
for p in require-app-label disallow-host-network disallow-privileged \
         disallow-latest-tag require-requests-limits disallow-default-namespace; do
  f=$(grep -l "name: $p\$" policies/*.yaml)
  sed -i.bak 's/validationActions: \[Audit\]/validationActions: [Deny]/' "$f" && rm -f "$f.bak"
done
kubectl apply -f policies/ >/dev/null
kubectl get validatingpolicies -o custom-columns='NAME:.metadata.name,ACTIONS:.spec.validationActions'
