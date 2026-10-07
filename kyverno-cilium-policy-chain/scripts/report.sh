#!/usr/bin/env bash
# PolicyReports per namespace (summary), then every failing result: namespace, policy, resource, message.
set -euo pipefail
kubectl get polr -A -o custom-columns='NS:.metadata.namespace,KIND:.scope.kind,NAME:.scope.name,PASS:.summary.pass,FAIL:.summary.fail' |
  awk 'NR==1 || $5 > 0'
echo
kubectl get polr -A -o json | python3 -c '
import json, sys
for r in json.load(sys.stdin)["items"]:
    ns = r["metadata"]["namespace"]
    scope = r.get("scope", {})
    for res in r.get("results", []):
        if res.get("result") == "fail":
            subj = scope.get("kind", "") + "/" + scope.get("name", "")
            print("%-20s %-28s %-36s %s" % (ns, res["policy"], subj, res.get("message", "").strip()[:90]))
'
