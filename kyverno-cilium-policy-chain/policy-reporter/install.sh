#!/usr/bin/env bash
# Policy Reporter UI for the PolicyReports. Run after `make policies` (the namespace gets its default-deny first).
set -euo pipefail
cd "$(dirname "$0")"
helm repo add policy-reporter https://kyverno.github.io/policy-reporter >/dev/null 2>&1 || true
helm repo update policy-reporter >/dev/null
kubectl create namespace policy-reporter --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f allow-policy-reporter.yaml
helm upgrade --install policy-reporter policy-reporter/policy-reporter --version 3.10.0 \
  -n policy-reporter -f values.yaml --wait --timeout 5m
kubectl -n policy-reporter get pods
