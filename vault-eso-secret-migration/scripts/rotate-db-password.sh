#!/usr/bin/env bash
# rotate-db-password.sh — new Postgres password for ZITADEL. The old one is in Git history forever;
# after this it no longer opens anything.
# Order: Postgres first, then Vault, then ESO, then ZITADEL. ZITADEL's open connections survive
# ALTER USER (Postgres checks the password only at login), so the old pod keeps serving
# until the new one, started with the new DSN, is Ready.
set -euo pipefail
cd "$(dirname "$0")/.."
TOKEN=$(jq -r .root_token .lab/vault-init.json)
v() { kubectl -n vault exec -i vault-0 -- env VAULT_TOKEN="$TOKEN" vault "$@"; }
NEW=$(openssl rand -hex 24)

# 1. Postgres. Inside the pod psql connects over the local socket without a password.
kubectl -n zitadel exec zitadel-postgres-0 -- psql -U zitadel -d zitadel -qc "ALTER USER zitadel WITH PASSWORD '$NEW'"

# 2. Vault. patch, not put: put replaces the whole secret and drops every key you didn't repeat.
v kv patch secret/platform/zitadel/db \
  POSTGRES_PASSWORD="$NEW" \
  ZITADEL_DATABASE_POSTGRES_DSN="postgresql://zitadel:$NEW@zitadel-postgres.zitadel.svc:5432/zitadel?sslmode=disable" >/dev/null

# 3. ESO. Don't wait for refreshInterval (1h): any change to this annotation triggers a sync now.
kubectl -n zitadel annotate es zitadel-db zitadel-postgres force-sync="$(date +%s)" --overwrite >/dev/null
kubectl -n zitadel wait es/zitadel-db --for=jsonpath='{.status.conditions[0].reason}'=SecretSynced --timeout=60s >/dev/null

# 4. ZITADEL reads the DSN from env only at start.
kubectl -n zitadel rollout restart deploy/zitadel
kubectl -n zitadel rollout status deploy/zitadel --timeout=5m
echo "rotated; Vault version: $(v kv metadata get -format=json secret/platform/zitadel/db | jq .data.current_version)"
