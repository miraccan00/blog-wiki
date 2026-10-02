#!/usr/bin/env bash
# compare.sh <ns> <secretA> <secretB> — SHA-256 prefix per key, so values can be compared without printing them.
set -euo pipefail
for s in "$2" "$3"; do
  echo "== $s"
  kubectl -n "$1" get secret "$s" -o json | jq -r '.data | to_entries[] | "\(.key) \(.value)"' |
    while read -r k val; do printf '  %-32s %s\n' "$k" "$(printf %s "$val" | base64 -d | shasum -a 256 | cut -c1-12)"; done
done
