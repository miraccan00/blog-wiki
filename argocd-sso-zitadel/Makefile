# Makefile — Argo CD SSO with ZITADEL, on top of the HA lab from argocd-ha-app-of-apps.
# Order: make up && make argocd && make bootstrap && make dns && make zitadel-ui (own terminal)
#        && make setup && make ui (own terminal), then log in as alice or bob.
# platform-gitops branch blog-05 = blog-04 + ZITADEL (apps/zitadel*.yaml, zitadel/) + OIDC/RBAC in values.
SHELL      := /bin/bash
export KUBECONFIG := $(CURDIR)/.lab/kubeconfig
CHART_VER  ?= 10.9.2
REV        ?= blog-05
RAW        := https://raw.githubusercontent.com/miraccan00/platform-gitops/$(REV)

.PHONY: help up argocd bootstrap dns zitadel-ui setup ui users status down
help:
	@grep -E '^[a-z/.-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ —/'

up:          ## kind: 1 control plane + 3 workers (same cluster as the HA post)
	@mkdir -p .lab
	kind create cluster --config kind/cluster.yaml --kubeconfig $(KUBECONFIG)
	kubectl wait --for=condition=Ready nodes --all --timeout=180s

argocd:      ## helm install Argo CD HA with blog-05 values (OIDC + RBAC already in them)
	helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
	helm repo update argo >/dev/null
	helm install argocd argo/argo-cd --version $(CHART_VER) -n argocd --create-namespace \
	  -f $(RAW)/argocd/values-ha.yaml --wait --timeout 10m

bootstrap:   ## apply root; Argo CD creates 9 Applications, ZITADEL and its Postgres included
	kubectl apply -f $(RAW)/bootstrap/root.yaml
	bash scripts/wait-apps.sh

dns:         ## CoreDNS rewrite: pods resolve zitadel.127.0.0.1.nip.io to the zitadel Service
	bash scripts/coredns-rewrite.sh

zitadel-ui:  ## ZITADEL on http://zitadel.127.0.0.1.nip.io:8081 (console: zitadel-admin@zitadel.zitadel.127.0.0.1.nip.io / Password1!)
	@while :; do kubectl -n zitadel port-forward svc/zitadel 8081:8081 || true; echo "port-forward lost, reconnecting"; sleep 1; done

setup:       ## project, roles, OIDC app, groups Action, alice and bob, Secret argocd/argocd-oidc-zitadel
	bash scripts/zitadel-setup.sh

ui:          ## Argo CD on http://localhost:8080 (log in via ZITADEL; admin password stays as break-glass)
	@echo "http://localhost:8080  break-glass admin / $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@while :; do kubectl -n argocd port-forward svc/argocd-server 8080:80 || true; echo "port-forward lost, reconnecting"; sleep 1; done

users:       ## the two lab users
	@echo "alice / Password1!  -> group platform-admins  -> role:admin"
	@echo "bob   / Password1!  -> group platform-viewers -> role:readonly"

status:      ## Applications and ZITADEL pods
	@kubectl -n argocd get applications
	@kubectl -n zitadel get pods

down:        ## delete the kind cluster and ./.lab
	kind delete cluster --name argocd-ha
	rm -rf .lab
