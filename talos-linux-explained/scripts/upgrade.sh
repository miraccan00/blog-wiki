#!/usr/bin/env bash
# Two different upgrades, two different commands.
#
#   talosctl upgrade-k8s   rewrites the Kubernetes component versions in every machine
#                          config and rolls the static pods and kubelets; no reboot.
#                          Works everywhere, including the Docker lab.
#   talosctl upgrade       replaces the OS image on disk and reboots; needs a real disk,
#                          so the API refuses it in container mode. Kept here for real nodes.
set -euo pipefail

CLUSTER=${CLUSTER:-talos-lab}
CP=${CP:-10.5.0.2}
K8S_TO=${K8S_TO:-1.36.4}
TALOS_TO=${TALOS_TO:-v1.13.10}
# Image Factory installer with the extensions from factory/schematic.yaml:
INSTALLER=${INSTALLER:-factory.talos.dev/metal-installer/613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245:${TALOS_TO}}

export DOCKER_HOST=${DOCKER_HOST:-$(docker context inspect -f '{{.Endpoints.docker.Host}}')}

# upgrade-k8s talks to the API server itself. On macOS the container address is not
# reachable from the host, so point it at the port Docker published.
ENDPOINT=127.0.0.1:$(docker port "${CLUSTER}-controlplane-1" 6443/tcp | head -1 | cut -d: -f2)

echo "== Kubernetes -> $K8S_TO =="
talosctl upgrade-k8s --nodes "$CP" --to "$K8S_TO" --endpoint "$ENDPOINT"

echo
PLATFORM=$(talosctl get platformmetadata --nodes "$CP" -o jsonpath='{.spec.platform}')
if [ "$PLATFORM" = "container" ]; then
  echo "== Talos OS: platform=$PLATFORM, asking anyway so you can see the answer =="
  talosctl upgrade --nodes "$CP" --image "$INSTALLER" || true
  exit 0
fi

echo "== Talos OS -> $INSTALLER, one node at a time =="
for node in $(talosctl get members --nodes "$CP" -o jsonpath='{.spec.addresses[0]}'); do
  talosctl upgrade --nodes "$node" --image "$INSTALLER" --wait
done
