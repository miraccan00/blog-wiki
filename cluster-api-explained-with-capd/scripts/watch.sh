#!/usr/bin/env bash
# scripts/watch.sh
# One screen that shows what Cluster API is doing right now.
exec watch -n 2 'kubectl get cluster,kubeadmcontrolplane,machinedeployment,machines -o wide 2>/dev/null'
