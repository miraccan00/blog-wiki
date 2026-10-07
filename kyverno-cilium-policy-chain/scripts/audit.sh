#!/usr/bin/env bash
# Back to the starting point: every pod policy in Audit (restrict-gateway-namespace stays Deny).
set -euo pipefail
cd "$(dirname "$0")/.."
for f in policies/*.yaml; do
  grep -q 'name: restrict-gateway-namespace$' "$f" && continue
  sed -i.bak 's/validationActions: \[Deny\]/validationActions: [Audit]/' "$f" && rm -f "$f.bak"
done
