#!/usr/bin/env bash
# scripts/failover.sh — break one HA component at a time, then prove Argo CD still
# reconciles (scripts/probe.sh: a hard refresh must produce a new reconciledAt).
# Not drift.sh: selfHeal backs off on repeated drift to the same commit (2s, 6s, 18s, ...
# up to 300s), so a second and third drift would measure the backoff, not the failure.
#   1. delete the Redis master pod        -> Sentinel promotes a replica, HAProxy follows
#   2. delete one repo-server pod         -> the other replica renders manifests
#   3. stop the worker running the application controller (docker stop)
set -euo pipefail
cd "$(dirname "$0")/.."
ts() { date +%H:%M:%S; }
bash scripts/probe.sh "baseline"

echo; echo "== 1. Redis master"
# Sentinel reports the master as an announce Service IP, so ask each pod for its role.
# Redis requires auth (the chart's redis-secret-init job); the container has it in $AUTH.
role() { kubectl -n argocd exec "$1" -c redis -- sh -c 'redis-cli --no-auth-warning -a "$AUTH" info replication' 2>/dev/null | tr -d '\r' | awk -F: '/^role:/{print $2}'; }
master=""
for p in argocd-redis-ha-server-{0,1,2}; do [ "$(role $p)" = master ] && master=$p; done
master_ip=$(kubectl -n argocd exec argocd-redis-ha-server-0 -c redis -- redis-cli -p 26379 sentinel get-master-addr-by-name argocd | head -1)
echo "$(ts) master is $master (sentinel: $master_ip), deleting"
kubectl -n argocd delete pod "$master" --wait=false >/dev/null
start=$(date +%s)
bash scripts/probe.sh "right after redis master delete" &
PROBE=$!
other=$(printf '%s\n' argocd-redis-ha-server-{0,1,2} | grep -v "$master" | head -1)
until new_ip=$(kubectl -n argocd exec "$other" -c redis -- redis-cli -p 26379 sentinel get-master-addr-by-name argocd 2>/dev/null | head -1) \
  && [ -n "$new_ip" ] && [ "$new_ip" != "$master_ip" ]; do sleep 1; done
echo "$(ts) sentinel promoted $new_ip after $(( $(date +%s) - start ))s"
wait $PROBE

echo; echo "== 2. repo-server"
rs=$(kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-repo-server -o jsonpath='{.items[0].metadata.name}')
echo "$(ts) deleting $rs"
kubectl -n argocd delete pod "$rs" --wait=false >/dev/null
bash scripts/probe.sh "right after repo-server delete"

echo; echo "== 3. node running the application controller"
node=$(kubectl -n argocd get pod argocd-application-controller-0 -o jsonpath='{.spec.nodeName}')
echo "$(ts) controller on $node; on the same node:"
kubectl -n argocd get pods -o wide --field-selector spec.nodeName="$node" --no-headers | awk '{print "   " $1}'
docker stop "$node" >/dev/null
echo "$(ts) docker stop $node"
TIMEOUT=${NODE_TIMEOUT:-420} bash scripts/probe.sh "with $node down" || true
echo "$(ts) controller pod:"
kubectl -n argocd get pod argocd-application-controller-0 -o wide --no-headers | awk '{print "   " $1, $3, $7}'
kubectl get node "$node" --no-headers | awk '{print "   node", $1, $2}'
docker start "$node" >/dev/null
echo "$(ts) docker start $node"
kubectl wait --for=condition=Ready node/"$node" --timeout=180s >/dev/null
until [ "$(kubectl -n argocd get pod argocd-application-controller-0 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" = true ]; do sleep 1; done
echo "$(ts) controller Ready again"
bash scripts/probe.sh "after $node is back"
