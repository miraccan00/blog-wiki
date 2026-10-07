# Makefile — Kyverno admission chain on top of Cilium (kind)
# Order: make up && make policies && make demo && make report && make enforce
SHELL := /bin/bash
CLUSTER_NAME ?= cilium-lab

.PHONY: help up cluster gateway-crds cilium kyverno policies demo report enforce audit ci verify reporter ui-reports ui-hubble down
help:
	@grep -E '^[a-z/.-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ —/'

up: cluster gateway-crds cilium kyverno   ## kind (no CNI, no kube-proxy) + Gateway API CRDs + Cilium 1.20 + Kyverno 1.19

cluster:         ## kind cluster from kind/config.yaml
	kind create cluster --config kind/config.yaml

gateway-crds:    ## Gateway API v1.6.1 CRDs. Before Kyverno: it builds its resource cache at start
	bash gateway-api/install-crds.sh

cilium:          ## Cilium with kube-proxy replacement and Hubble 
	bash cilium/install.sh

kyverno:         ## Kyverno via Helm, system namespaces excluded
	bash kyverno/install.sh

policies:        ## aggregated RBAC for cilium.io + the six policies (validations start in Audit)
	bash scripts/apply.sh

demo:            ## namespace → generated CNP, good/bad pod, mutated Deployment, refused Gateway
	bash scripts/demo.sh

report:          ## PolicyReports and the failing results
	bash scripts/report.sh

enforce:         ## Audit → Deny for the six pod policies, in the policy files (see scripts/enforce.sh)
	bash scripts/enforce.sh

audit:           ## back to Audit in the policy files (the lab's starting point)
	bash scripts/audit.sh

ci:              ## kyverno apply against demo/ manifests (what the CI gate runs)
	bash ci/kyverno-apply.sh demo

verify:          ## proof: CNP exists, bad pod refused after enforce, reports clean
	kubectl -n team-a get cnp
	kubectl get validatingpolicies -o custom-columns='NAME:.metadata.name,ACTIONS:.spec.validationActions'
	kubectl apply -f demo/bad-pod.yaml 2>&1 | head -3 || true
	kubectl get polr -A

reporter:        ## Policy Reporter (UI for PolicyReports), with its own CNP next to the generated default-deny
	bash policy-reporter/install.sh

ui-reports:      ## Policy Reporter UI on http://localhost:8082
	kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8082:8080

ui-hubble:       ## Hubble UI on http://localhost:12000 (flows, DROPPED by default-deny)
	cilium hubble ui --port-forward 12000

down:            ## delete the kind cluster
	kind delete cluster --name $(CLUSTER_NAME)
