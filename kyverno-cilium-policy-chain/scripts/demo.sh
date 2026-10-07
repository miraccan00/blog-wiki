#!/usr/bin/env bash
# The chain end to end: a namespace gets its default-deny, a good pod passes, a bad pod fails,
# an unlabelled Deployment is mutated, a Gateway outside platform is refused.
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl create namespace team-a --dry-run=client -o yaml | kubectl apply -f -
sleep 3
echo "--- generated CiliumNetworkPolicy:"
kubectl -n team-a get cnp default-deny -o yaml | sed -n '/^spec:/,$p'
echo "--- good pod:"
kubectl apply -f demo/good-pod.yaml
echo "--- bad pod (Audit: admitted, reported; Deny: refused):"
kubectl apply -f demo/bad-pod.yaml || true
echo "--- careless pod (latest tag, no requests/limits) and a pod in default:"
kubectl apply -f demo/careless-pod.yaml || true
kubectl apply -f demo/default-ns-pod.yaml || true
echo "--- unlabelled Deployment, labels after mutation:"
kubectl apply -f demo/unlabelled-deployment.yaml
kubectl -n team-a get deploy echo -o jsonpath='{.metadata.labels}{"\n"}{.spec.template.metadata.labels}{"\n"}'
echo "--- Gateway outside platform:"
kubectl apply -f demo/bad-gateway.yaml || true
