# Talos Linux, explained by running it — lab Makefile
#
#   make up        create a 1 control plane + 1 worker Talos cluster in Docker
#   make patch     apply the worker machine-config patch live and show what changed
#   make upgrade   Kubernetes upgrade (works in Docker) and OS upgrade (real machines only)
#   make status    members as Talos sees them, nodes as Kubernetes sees them
#   make down      destroy the cluster and remove the state directory
#
# All state (talosconfig, kubeconfig, cluster state) stays under ./.lab so nothing
# in ~/.talos or ~/.kube is touched.

CLUSTER ?= talos-lab
LAB     ?= $(CURDIR)/.lab

export TALOSCONFIG := $(LAB)/talosconfig
export KUBECONFIG  := $(LAB)/kubeconfig
export CLUSTER LAB

# talosctl dials the Docker socket directly and ignores `docker context`.
# On Colima / Docker Desktop that socket is not /var/run/docker.sock.
export DOCKER_HOST ?= $(shell docker context inspect -f '{{.Endpoints.docker.Host}}' 2>/dev/null)

.PHONY: up patch upgrade status down

up:
	./cluster/create.sh

patch:
	./scripts/patch.sh

upgrade:
	./scripts/upgrade.sh

status:
	talosctl get members --nodes 10.5.0.2
	kubectl get nodes -o wide

down:
	talosctl cluster destroy --name $(CLUSTER) --state $(LAB)/state
	rm -rf $(LAB)
