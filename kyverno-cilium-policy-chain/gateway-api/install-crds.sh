#!/usr/bin/env bash
# Gateway API CRDs. Cilium 1.20 supports Gateway API v1.6.1; install them BEFORE enabling gatewayAPI in Cilium.
# CHANNEL=experimental adds TLSRoute/TCPRoute/UDPRoute fields; standard is enough for this post.
set -euo pipefail
GW_VERSION="${GW_VERSION:-v1.6.1}"
CHANNEL="${CHANNEL:-standard}"
BASE="https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GW_VERSION}/config/crd/${CHANNEL}"
for crd in gatewayclasses gateways httproutes referencegrants grpcroutes backendtlspolicies tlsroutes; do
  kubectl apply --server-side -f "${BASE}/gateway.networking.k8s.io_${crd}.yaml"
done
kubectl get crd | grep gateway.networking.k8s.io
