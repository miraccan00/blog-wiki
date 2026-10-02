#!/usr/bin/env bash
# seed-from-git.sh — first write into Vault: the values blog-05 left in Git as base64.
# They come from the blog-05 branch, not from the cluster: Git history is exactly where they leak from,
# and on a clean cluster the Secrets were never created. scripts/rotate-db-password.sh replaces the
# Postgres password right after; the masterkey stays (ZITADEL's data is encrypted with it).
# Also copies Argo CD's OIDC values if a blog-05 cluster still has the Secret zitadel-setup.sh wrote.
set -euo pipefail
cd "$(dirname "$0")/.."
RAW=https://raw.githubusercontent.com/miraccan00/platform-gitops/blog-05/zitadel/db/secrets.yaml
TOKEN=$(jq -r .root_token .lab/vault-init.json)
v() { kubectl -n vault exec -i vault-0 -- env VAULT_TOKEN="$TOKEN" vault "$@"; }
yaml=$(curl -fsSL "$RAW")
g() { awk -v k="$1:" '$1==k {print $2; exit}' <<<"$yaml" | base64 -d; }

v kv put secret/platform/zitadel/db \
  POSTGRES_USER="$(g POSTGRES_USER)" \
  POSTGRES_PASSWORD="$(g POSTGRES_PASSWORD)" \
  POSTGRES_DB="$(g POSTGRES_DB)" \
  ZITADEL_DATABASE_POSTGRES_DSN="$(g ZITADEL_DATABASE_POSTGRES_DSN)" >/dev/null
v kv put secret/platform/zitadel/masterkey masterkey="$(g masterkey)" >/dev/null
echo "vault: secret/platform/zitadel/{db,masterkey} written from blog-05"

if kubectl -n argocd get secret argocd-oidc-zitadel >/dev/null 2>&1 &&
   ! v kv get secret/platform/argocd/oidc-zitadel >/dev/null 2>&1; then
  o() { kubectl -n argocd get secret argocd-oidc-zitadel -o jsonpath="{.data.$1}" | base64 -d; }
  v kv put secret/platform/argocd/oidc-zitadel clientID="$(o clientID)" clientSecret="$(o clientSecret)" cliClientID="$(o cliClientID)" >/dev/null
  echo "vault: secret/platform/argocd/oidc-zitadel copied from the blog-05 Secret"
fi
