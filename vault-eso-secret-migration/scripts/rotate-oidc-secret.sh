#!/usr/bin/env bash
# rotate-oidc-secret.sh — new client secret for the Argo CD app in ZITADEL.
# ZITADEL invalidates the old secret the moment it generates the new one, so Vault and ESO
# follow right away; until argocd-oidc-zitadel holds the new value, new logins fail.
# Sessions that already exist are untouched: Argo CD only uses the client secret at login.
set -euo pipefail
cd "$(dirname "$0")/.."
Z=${ZITADEL_URL:-http://zitadel.127.0.0.1.nip.io:8081}
TOKEN=$(jq -r .root_token .lab/vault-init.json)
PAT=$(kubectl -n zitadel get secret iam-admin-pat -o jsonpath='{.data.pat}' | base64 -d)
api() { curl -sS --fail-with-body -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' -X "$1" "$Z$2" ${3:+-d "$3"}; }
v() { kubectl -n vault exec -i vault-0 -- env VAULT_TOKEN="$TOKEN" vault "$@"; }
byname() { jq -r --arg n "$1" '.result[] | select(.name==$n) | .id'; }

# kubectl port-forward is bound to one pod: after `make rotate-db` restarts ZITADEL, the
# make zitadel-ui loop needs a moment to reconnect (curl exit 52 without this wait).
for _ in $(seq 30); do curl -sf -o /dev/null "$Z/debug/ready" && break; sleep 1; done

project=$(api POST /management/v1/projects/_search '{}' | byname argocd)
app=$(api POST "/management/v1/projects/$project/apps/_search" '{}' | byname argocd)

secret=$(api POST "/management/v1/projects/$project/apps/$app/oidc_config/_generate_client_secret" '{}' | jq -r .clientSecret)
v kv patch secret/platform/argocd/oidc-zitadel clientSecret="$secret" >/dev/null
kubectl -n argocd annotate es argocd-oidc-zitadel force-sync="$(date +%s)" --overwrite >/dev/null
kubectl -n argocd wait es/argocd-oidc-zitadel --for=jsonpath='{.status.conditions[0].reason}'=SecretSynced --timeout=60s >/dev/null
echo "rotated; Vault version: $(v kv metadata get -format=json secret/platform/argocd/oidc-zitadel | jq .data.current_version)"
