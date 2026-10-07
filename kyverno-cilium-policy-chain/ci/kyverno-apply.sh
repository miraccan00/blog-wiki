#!/usr/bin/env bash
# CI gate: evaluate the policies against the manifests in a PR, no cluster needed.
# Add this step next to the Trivy gate (post 28). Exit code is non-zero on any fail.
# Offline the CLI knows neither the namespaces nor the Gateway API kinds:
#   ci/values.yaml  namespaces, for rules that read namespaceObject (else "error", not "fail")
#   ci/crds/...     the Gateway CRD, else Gateways are silently not evaluated (0 results)
# --crd-paths takes files, not a directory ("CRD file must have .yaml or .yml extension").
set -euo pipefail
cd "$(dirname "$0")/.."
MANIFESTS="${1:-demo}"
CRDS=$(ls ci/crds/*.yaml | paste -sd, -)
kyverno apply policies/ --resource "$MANIFESTS" --values-file ci/values.yaml --crd-paths "$CRDS"
