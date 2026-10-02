# Makefile — ZITADEL's secrets from Git into Vault through ESO, on top of the argocd-sso-zitadel lab.
# Clean cluster: make up argocd bootstrap vault && make dns && make zitadel-ui (own terminal)
#                && make setup rotate-db rotate-oidc && make ui (own terminal)
# Running 05 lab: make from-05 vault rotate-db rotate-oidc
# platform-gitops branch blog-05b = blog-05 + Vault, ESO, ClusterSecretStore, ExternalSecrets instead of base64.
SHELL      := /bin/bash
export KUBECONFIG := $(CURDIR)/.lab/kubeconfig
CHART_VER  ?= 10.9.2
REV        ?= blog-05b
RAW        := https://raw.githubusercontent.com/miraccan00/platform-gitops/$(REV)

.PHONY: help up argocd bootstrap from-05 vault vault-init vault-config seed rotate-db rotate-oidc \
        vault-ui dns zitadel-ui setup ui cli users status down
help:
	@grep -E '^[a-z0-9/.-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ —/'

up:          ## kind: 1 control plane + 3 workers (same cluster as the HA post)
	@mkdir -p .lab
	kind create cluster --config kind/cluster.yaml --kubeconfig $(KUBECONFIG)
	kubectl wait --for=condition=Ready nodes --all --timeout=180s

argocd:      ## helm install Argo CD HA (values unchanged since blog-05: OIDC + RBAC)
	helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
	helm repo update argo >/dev/null
	helm install argocd argo/argo-cd --version $(CHART_VER) -n argocd --create-namespace \
	  -f $(RAW)/argocd/values-ha.yaml --wait --timeout 10m

bootstrap:   ## apply root at blog-05b; returns once vault-0 runs (sealed: nothing else can be Healthy yet)
	kubectl apply -f $(RAW)/bootstrap/root.yaml
	@until kubectl -n vault get pod vault-0 >/dev/null 2>&1; do sleep 2; done

from-05:     ## a running 05 lab: point root at blog-05b; Argo CD installs Vault and ESO, prunes the base64 Secrets
	kubectl apply -f $(RAW)/bootstrap/root.yaml
	@until kubectl -n vault get pod vault-0 >/dev/null 2>&1; do sleep 2; done

vault: vault-init vault-config seed ## init + unseal, configure, first values; wait for 12 Applications (argocd-secrets: after setup)
	SKIP=argocd-secrets bash scripts/wait-apps.sh

vault-init:  ## init once (keys in .lab/vault-init.json), unseal; run again after every vault-0 restart
	bash scripts/vault-init.sh

vault-config: ## kv-v2 at secret/, Kubernetes auth, policy eso-read, role eso
	bash scripts/vault-config.sh

seed:        ## the values blog-05 left in Git, read from the blog-05 branch, written into Vault
	bash scripts/seed-from-git.sh

rotate-db:   ## new Postgres password: ALTER USER, kv patch, ESO force-sync, restart ZITADEL
	bash scripts/rotate-db-password.sh

rotate-oidc: ## new client secret for the Argo CD app in ZITADEL, kv patch, ESO force-sync
	bash scripts/rotate-oidc-secret.sh

vault-ui:    ## Vault UI on http://localhost:8200 (token: jq -r .root_token .lab/vault-init.json)
	@while :; do kubectl -n vault port-forward svc/vault-active 8200:8200 || true; echo "port-forward lost, reconnecting"; sleep 1; done

dns:         ## CoreDNS rewrite: pods resolve zitadel.127.0.0.1.nip.io to the zitadel Service
	bash scripts/coredns-rewrite.sh

zitadel-ui:  ## ZITADEL on http://zitadel.127.0.0.1.nip.io:8081 (console: zitadel-admin@zitadel.zitadel.127.0.0.1.nip.io / Password1!)
	@while :; do kubectl -n zitadel port-forward svc/zitadel 8081:8081 || true; echo "port-forward lost, reconnecting"; sleep 1; done

setup:       ## project, roles, OIDC apps, groups Action, users; client ID and secret go to Vault
	bash scripts/zitadel-setup.sh
	bash scripts/wait-apps.sh

ui:          ## Argo CD on http://localhost:8080 (log in via ZITADEL; admin password stays as break-glass)
	@echo "http://localhost:8080  break-glass admin / $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@while :; do kubectl -n argocd port-forward svc/argocd-server 8080:80 || true; echo "port-forward lost, reconnecting"; sleep 1; done

cli:         ## argocd CLI login through ZITADEL (browser opens); its own port-forward
	argocd login --port-forward --port-forward-namespace argocd --plaintext --sso

users:       ## the three lab users
	@echo "alice / Password1!  -> group platform-admins    -> role:admin"
	@echo "dave  / Password1!  -> group product-developers -> role:developer (products project only)"
	@echo "bob   / Password1!  -> group platform-viewers   -> role:readonly"

status:      ## Applications, Vault seal state, ExternalSecrets
	@kubectl -n argocd get applications
	@kubectl -n vault exec vault-0 -- vault status 2>/dev/null | grep -E 'Sealed|Version' || true
	@kubectl get clustersecretstore,externalsecrets -A

down:        ## delete the kind cluster and ./.lab (the unseal keys go with it)
	kind delete cluster --name argocd-ha
	rm -rf .lab
