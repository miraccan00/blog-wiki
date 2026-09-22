#!/usr/bin/env bash
# scripts/colima-limits.sh
# kind nodes are systemd containers; each one opens many inotify instances.
# Colima's default fs.inotify.max_user_instances=128 is exhausted around the
# 4th node and new node containers die at boot with:
#   "Failed to create control group inotify object: Too many open files"
# Raise the limits in the Colima VM (Docker Desktop users: see README).
set -euo pipefail
colima ssh -- sudo sysctl -w fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=1048576
