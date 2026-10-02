#!/usr/bin/env bash
# vault-config.sh — KV v2 at secret/, Kubernetes auth, one read-only policy and role for ESO.
# Idempotent: every write below replaces the same object with the same content.
set -euo pipefail
cd "$(dirname "$0")/.."
TOKEN=$(jq -r .root_token .lab/vault-init.json)
v() { kubectl -n vault exec -i vault-0 -- env VAULT_TOKEN="$TOKEN" vault "$@"; }

v secrets list -format=json | jq -e '."secret/"' >/dev/null || v secrets enable -path=secret kv-v2
v auth list -format=json | jq -e '."kubernetes/"' >/dev/null || v auth enable kubernetes
# Vault runs in the cluster: it validates ServiceAccount tokens with its own pod's token and CA.
v write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc:443

# ESO only reads. Writes happen by a human with `vault kv patch`, never by the cluster.
v policy write eso-read - <<'HCL'
path "secret/data/platform/*"     { capabilities = ["read"] }
path "secret/metadata/platform/*" { capabilities = ["read", "list"] }
HCL

v write auth/kubernetes/role/eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  audience=vault policies=eso-read ttl=15m
echo "vault: kv-v2 secret/, auth kubernetes, policy eso-read, role eso"
