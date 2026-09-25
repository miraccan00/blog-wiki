#!/usr/bin/env bash
# Register the schematic with Image Factory and print the image references
# you would use on real hardware / a cloud. No account, no auth.
set -euo pipefail

VERSION=${TALOS_VERSION:-v1.13.10}
ID=$(curl -sf -X POST https://factory.talos.dev/schematics \
      -H 'Content-Type: application/yaml' \
      --data-binary @factory/schematic.yaml | sed -E 's/.*"id":"([a-f0-9]+)".*/\1/')

cat <<EOF
schematic id : $ID
installer    : factory.talos.dev/metal-installer/$ID:$VERSION     # talosctl upgrade --image ...
hcloud       : factory.talos.dev/hcloud-installer/$ID:$VERSION    # Hetzner Cloud
metal iso    : https://factory.talos.dev/image/$ID/$VERSION/metal-arm64.iso
nocloud raw  : https://factory.talos.dev/image/$ID/$VERSION/nocloud-amd64.raw.xz
EOF
