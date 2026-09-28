#!/usr/bin/env bash
# Replays, by hand, the three things CAPD does to a DevMachine container before and during bootstrap:
#   1. WaitForMultiUserTarget  - container logs must match "Reached target .*Multi-User System" (30s task)
#   2. WaitForCrictlPs         - `crictl ps` must succeed inside the container
#   3. write_files / runcmd    - every bootstrap command is run with `docker exec ... /bin/sh -c`
# Source: kubernetes-sigs/cluster-api test/infrastructure/docker/internal/docker/machine.go
set -u

IMG="${1:?usage: $0 <image>   e.g. kindest/node:v1.34.0 or ghcr.io/siderolabs/talos:v1.13.10}"
NAME="capd-check-$$"

case "$IMG" in
  *talos*)
    # Same flags talosctl's docker provisioner uses; no USERDATA, so Talos waits for a config.
    docker run -d --name "$NAME" --privileged --read-only \
      --mount type=tmpfs,destination=/run --mount type=tmpfs,destination=/system \
      --mount type=tmpfs,destination=/tmp --mount type=volume,destination=/var \
      -e PLATFORM=container "$IMG" >/dev/null ;;
  *)
    # -t: kind runs nodes with a tty, which is where systemd prints "Reached target ...".
    docker run -d -t --name "$NAME" --privileged --tmpfs /run --tmpfs /tmp \
      -v /var -v /lib/modules:/lib/modules:ro "$IMG" >/dev/null ;;
esac
trap 'docker rm -f "$NAME" >/dev/null' EXIT

echo "== $IMG"
target=""
for _ in $(seq 1 30); do
  target=$(docker logs "$NAME" 2>&1 | grep -E 'Reached target .*Multi-User System' || true)
  [ -n "$target" ] && break
  sleep 1
done
echo "0) container: $(docker inspect -f '{{.State.Status}}' "$NAME")"

echo "1) WaitForMultiUserTarget"
if [ -n "$target" ]; then echo "   OK   $target"; else echo "   FAIL multi-user target not reached yet"; fi

echo "2) WaitForCrictlPs: crictl ps"
if out=$(docker exec "$NAME" crictl ps 2>&1); then echo "   OK"; else echo "   FAIL $out"; fi

echo "3) runcmd: /bin/sh -c"
if out=$(docker exec "$NAME" /bin/sh -c 'echo shell ok' 2>&1); then echo "   OK   $out"; else echo "   FAIL $out"; fi
