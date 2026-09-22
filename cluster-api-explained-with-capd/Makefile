# Makefile — Cluster API on kind with the Docker provider (ClusterClass flavor)
# Order: make mgmt && make workload && make cni && make scale && make upgrade
SHELL := /bin/bash
CLUSTER_NAME       ?= capi-lab
KUBERNETES_VERSION ?= v1.34.0
NEW_VERSION        ?= v1.34.3
CP_COUNT           ?= 1
WORKER_COUNT       ?= 1
WORKERS            ?= 3

.PHONY: help mgmt init workload cni watch scale upgrade status clean
help:
	@grep -E '^[a-z/.-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ —/'

mgmt:            ## kind management cluster with the docker socket mounted, then providers
	kind create cluster --config kind/mgmt.yaml
	$(MAKE) init

init:            ## install CAPI providers (core, kubeadm bootstrap + control plane, docker)
	bash clusterctl/init.sh
	kubectl wait --for=condition=Available --timeout=180s -n capd-system deploy/capd-controller-manager
	kubectl wait --for=condition=Available --timeout=180s -n capi-system deploy/capi-controller-manager

workload/cluster.yaml:  ## render the manifest (committed so the lab is reproducible)
	CLUSTER_TOPOLOGY=true clusterctl generate cluster $(CLUSTER_NAME) \
	  --infrastructure docker --flavor development \
	  --kubernetes-version $(KUBERNETES_VERSION) \
	  --control-plane-machine-count=$(CP_COUNT) \
	  --worker-machine-count=$(WORKER_COUNT) > workload/cluster.yaml

workload: workload/cluster.yaml   ## create the workload cluster (ClusterClass + Cluster)
	kubectl apply -f workload/cluster.yaml
	@echo "In another terminal: make watch"

cni:             ## install Cilium into the workload cluster (CAPI does not ship a CNI)
	CLUSTER_NAME=$(CLUSTER_NAME) bash scripts/cni.sh

watch:           ## live view of Cluster / KCP / MachineDeployment / Machines
	bash scripts/watch.sh

status:          ## clusterctl's tree view
	clusterctl describe cluster $(CLUSTER_NAME) --show-conditions=false

scale:           ## workers 1 -> $(WORKERS). With ClusterClass you edit the Cluster, not the MachineDeployment
	kubectl patch cluster $(CLUSTER_NAME) --type merge \
	  -p '{"spec":{"topology":{"workers":{"machineDeployments":[{"class":"default-worker","name":"md-0","replicas":$(WORKERS)}]}}}}'

upgrade:         ## rolling Kubernetes upgrade: one field on the Cluster
	kubectl patch cluster $(CLUSTER_NAME) --type merge -p '{"spec":{"topology":{"version":"$(NEW_VERSION)"}}}'
	@echo "Watch machines get replaced: make watch"

clean:           ## delete the workload cluster (CAPI removes the containers), then kind
	-kubectl delete cluster $(CLUSTER_NAME) --wait=true --timeout=300s
	-kind delete cluster --name capi-mgmt
	-rm -f $(CLUSTER_NAME).kubeconfig
