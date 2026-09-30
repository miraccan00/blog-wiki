#!/usr/bin/env bash
# scripts/node-out-of-service.sh — the fix for a dead node under a StatefulSet pod.
# Stop the node running the application controller, wait for NotReady, then add the
# out-of-service taint (Kubernetes non-graceful node shutdown, GA since 1.28). The
# taint tells Kubernetes the node is really gone, so the controller pod is force-deleted
# and the StatefulSet recreates it elsewhere. Cloud providers remove the Node object for
# you; on bare metal nobody does, and without this the pod waits for the node forever.
set -euo pipefail
cd "$(dirname "$0")/.."
ts() { date +%H:%M:%S; }
node=$(kubectl -n argocd get pod argocd-application-controller-0 -o jsonpath='{.spec.nodeName}')
docker stop "$node" >/dev/null; t0=$(date +%s); echo "$(ts) docker stop $node"
until kubectl get node "$node" --no-headers | grep -q NotReady; do sleep 1; done
echo "$(ts) $node NotReady after $(( $(date +%s) - t0 ))s"
kubectl taint node "$node" node.kubernetes.io/out-of-service=nodeshutdown:NoExecute >/dev/null
echo "$(ts) out-of-service taint added"
until n=$(kubectl -n argocd get pod argocd-application-controller-0 -o jsonpath='{.spec.nodeName}' 2>/dev/null) && [ -n "$n" ] && [ "$n" != "$node" ] \
  && [ "$(kubectl -n argocd get pod argocd-application-controller-0 -o jsonpath='{.status.containerStatuses[0].ready}')" = true ]; do sleep 1; done
echo "$(ts) controller Ready on $n, $(( $(date +%s) - t0 ))s after the node died"
bash scripts/probe.sh "controller moved"
docker start "$node" >/dev/null
kubectl wait --for=condition=Ready node/"$node" --timeout=180s >/dev/null
kubectl taint node "$node" node.kubernetes.io/out-of-service- >/dev/null
echo "$(ts) $node back, taint removed"
