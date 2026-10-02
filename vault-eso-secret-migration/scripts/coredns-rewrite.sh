#!/usr/bin/env bash
# scripts/coredns-rewrite.sh — make zitadel.127.0.0.1.nip.io mean the same thing inside the cluster
# as in the browser. Public DNS answers 127.0.0.1 (nip.io), which in a pod is the pod itself; the
# rewrite sends the name to the zitadel Service instead. "answer auto" rewrites the name in the
# answer back to the one that was asked; without it the client drops the answer and keeps 127.0.0.1.
# Lab plumbing only: in production ZITADEL has a real DNS name and nobody edits CoreDNS.
set -euo pipefail
NAME=zitadel.127.0.0.1.nip.io
RULE="    rewrite name exact $NAME zitadel.zitadel.svc.cluster.local answer auto"
core=$(kubectl -n kube-system get cm coredns -o jsonpath='{.data.Corefile}')
if grep -qF "$NAME" <<<"$core"; then echo "rewrite already there"; else
  new=$(python3 -c 'import sys; c,r=sys.argv[1],sys.argv[2]; print(c.replace("    ready\n","    ready\n"+r+"\n",1), end="")' "$core" "$RULE")
  kubectl -n kube-system create cm coredns --from-literal=Corefile="$new" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl -n kube-system rollout restart deploy/coredns >/dev/null
  kubectl -n kube-system rollout status deploy/coredns --timeout=120s >/dev/null
  echo "rewrite added: $NAME -> zitadel.zitadel.svc.cluster.local"
fi
# prove it from inside the cluster, the way argocd-server will see it
kubectl -n argocd run dns-check --rm -i --restart=Never --image=curlimages/curl:8.16.0 --quiet -- \
  -s --max-time 10 "http://$NAME:8081/.well-known/openid-configuration" | python3 -c 'import sys,json; print("issuer seen from a pod:", json.load(sys.stdin)["issuer"])'
