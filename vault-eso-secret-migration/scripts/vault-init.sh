#!/usr/bin/env bash
# vault-init.sh — init Vault once, unseal it (again after every pod restart).
# Lab only: the unseal keys and root token land in .lab/vault-init.json, next to the kubeconfig.
# In production the 5 key shares go to 5 different people and the root token is revoked after setup.
set -euo pipefail
cd "$(dirname "$0")/.."
INIT=.lab/vault-init.json
v() { kubectl -n vault exec vault-0 -- vault "$@"; }
# `vault status` exits 2 while sealed; that is an answer here, not a failure.
st() { v status -format=json 2>/dev/null || true; }

kubectl -n vault wait --for=jsonpath='{.status.phase}'=Running pod/vault-0 --timeout=180s >/dev/null

if [[ "$(st | jq -r .initialized)" != "true" ]]; then
  v operator init -key-shares=5 -key-threshold=3 -format=json > "$INIT"
  chmod 600 "$INIT"
  echo "initialized, keys in $INIT"
fi

if [[ "$(st | jq -r .sealed)" == "true" ]]; then
  for i in 0 1 2; do
    v operator unseal "$(jq -r ".unseal_keys_b64[$i]" "$INIT")" >/dev/null
  done
fi
v status | grep -E 'Sealed|Storage Type|Version|HA Mode'
