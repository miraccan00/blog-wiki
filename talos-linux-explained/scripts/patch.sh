#!/usr/bin/env bash
# Apply config/worker.patch.yaml to the running worker. First a dry run, so the
# API tells us whether it would reboot and shows the diff; then the real thing;
# then proof the node runs the new values. Last, a patch Talos refuses to apply live.
set -euo pipefail

WORKER=${WORKER:-10.5.0.3}

echo "== 1. dry run: what would change, would it reboot =="
talosctl patch mc --nodes "$WORKER" --patch @config/worker.patch.yaml --dry-run

echo
echo "== 2. apply =="
talosctl patch mc --nodes "$WORKER" --patch @config/worker.patch.yaml

echo
echo "== 3. what the node runs now =="
talosctl get kubeletconfig --nodes "$WORKER" -o jsonpath='{.spec.extraArgs}'
talosctl read /proc/sys/net/core/somaxconn --nodes "$WORKER"
kubectl get nodes -l node.lab/pool=general

echo
echo "== 4. a change Talos will not apply live (dry run only) =="
talosctl patch mc --nodes "$WORKER" --patch @config/needs-reboot.patch.yaml --dry-run
