# Makefile — HA Argo CD on kind, then app-of-apps from github.com/miraccan00/platform-gitops
# Order: make up && make argocd && make bootstrap && make failover
# Everything Argo CD deploys comes from three public repos (branch $(REV)):
#   platform-gitops           Argo CD values, root, apps/, ApplicationSets, namespaces
#   product-helloapi-gitops   helloapi chart + overlays/{dev,prod}
#   hellofiber                the Go service; CI publishes ghcr.io/miraccan00/hellofiber:sha-<7>
SHELL      := /bin/bash
export KUBECONFIG := $(CURDIR)/.lab/kubeconfig
CHART_VER  ?= 10.9.2
REV        ?= blog-04
RAW        := https://raw.githubusercontent.com/miraccan00/platform-gitops/$(REV)

.PHONY: help up argocd bootstrap status password ui hello ship drift probe failover out-of-service down
help:
	@grep -E '^[a-z/.-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ —/'

up:          ## kind: 1 control plane + 3 workers (redis-ha needs 3 nodes)
	@mkdir -p .lab
	kind create cluster --config kind/cluster.yaml --kubeconfig $(KUBECONFIG)
	kubectl wait --for=condition=Ready nodes --all --timeout=180s

argocd:      ## helm install Argo CD in HA mode with platform-gitops' values (the only helm command)
	helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
	helm repo update argo >/dev/null
	time helm install argocd argo/argo-cd --version $(CHART_VER) -n argocd --create-namespace \
	  -f $(RAW)/argocd/values-ha.yaml --wait --timeout 10m
	kubectl -n argocd get pods -o wide --sort-by=.spec.nodeName

bootstrap:   ## apply the root Application once; Argo CD takes it from there
	kubectl apply -f $(RAW)/bootstrap/root.yaml
	bash scripts/wait-apps.sh

status:      ## Applications with sync/health, Argo CD pods per node
	@kubectl -n argocd get applications
	@kubectl -n argocd get pods -o wide --sort-by=.spec.nodeName

password:    ## initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

ui:          ## UI on http://localhost:8080, user admin (server.insecure=true; TLS belongs on the gateway)
	@echo "http://localhost:8080  admin / $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@# port-forward sticks to one argocd-server pod; when failover kills it, reconnect
	@while :; do kubectl -n argocd port-forward svc/argocd-server 8080:80 || true; echo "port-forward lost, reconnecting"; sleep 1; done

hello:       ## call hellofiber in dev and prod through a port-forward
	@for e in dev prod; do \
	  kubectl -n product-helloapi-$$e port-forward svc/product-helloapi 18080:80 >/dev/null 2>&1 & pf=$$!; \
	  sleep 2; curl -s localhost:18080/hello; echo; kill $$pf; wait $$pf 2>/dev/null || true; done

ship:        ## after pushing a change to product-helloapi-gitops: refresh and time the rollout
	bash scripts/ship.sh

drift:       ## scale prod by hand and time selfHeal (run it twice: it backs off 2s, 6s, 18s ... 300s)
	bash scripts/drift.sh

probe:       ## hard refresh of product-helloapi-prod, time until reconciled
	bash scripts/probe.sh

failover:    ## kill the Redis master, a repo-server, then the controller's node (~9 min)
	bash scripts/failover.sh

out-of-service: ## kill the controller's node again, add the out-of-service taint, time the move
	bash scripts/node-out-of-service.sh

down:        ## delete the kind cluster and ./.lab
	kind delete cluster --name argocd-ha
	rm -rf .lab
