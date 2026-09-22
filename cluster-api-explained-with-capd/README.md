# Cluster API, explained by building one

Code for the article
**[Cluster API, Explained by Building One: kind, the Docker Provider and a Workload Cluster in 15 Minutes](https://miraccanyilmaz.me/en/blog/cluster-api-explained-with-capd/)**
· [Türkçe](https://miraccanyilmaz.me/blog/cluster-api-explained-with-capd/)

A management cluster on kind, the Cluster API Docker provider (CAPD), and a workload
cluster you can scale and upgrade by editing one object. Everything runs as containers
on your laptop; no cloud account needed.

## Versions this was run with

| Tool | Version |
|---|---|
| macOS (Apple Silicon) + Colima | 4 CPU / 8 GB VM |
| Docker Engine | 27.4.0 |
| kind | v0.33.0 |
| clusterctl / Cluster API | v1.14.2 |
| Kubernetes (workload) | v1.34.0 → v1.34.3 |
| Cilium | 1.18.2 |

## Run

```bash
# Colima only: kind nodes exhaust the default inotify limit around the 4th node
bash scripts/colima-limits.sh

make mgmt        # kind cluster + clusterctl init (~1 min)
make workload    # apply workload/cluster.yaml
make watch       # in a second terminal
make cni         # Cilium into the workload cluster; nodes turn Ready
make status      # clusterctl describe tree
make scale       # workers 1 -> 3 (edits Cluster.spec.topology, not the MachineDeployment)
make upgrade     # rolling upgrade to NEW_VERSION (default v1.34.3)
make clean
```

## Layout

```
kind/mgmt.yaml            management cluster; mounts /var/run/docker.sock (CAPD needs it)
clusterctl/init.sh        pinned provider install
workload/cluster.yaml     generated with `clusterctl generate cluster --flavor development`, committed
scripts/cni.sh            fetch kubeconfig, fix the API endpoint for Colima/Docker Desktop, install Cilium
scripts/watch.sh          one screen: Cluster, KubeadmControlPlane, MachineDeployment, Machines
scripts/colima-limits.sh  fs.inotify.max_user_instances=512 in the Colima VM
docs/crd-map.md           which object does what
```

## Docker Desktop instead of Colima

The inotify fix is the same sysctl, applied inside the Docker Desktop VM:

```bash
docker run --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i -- \
  sysctl -w fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=1048576
```

## Not for production

CAPD is a test provider maintained inside the cluster-api repo. Its whole purpose is to
exercise the Cluster API contract without a cloud. The same manifests with a real
infrastructure provider (Hetzner, OpenStack, KubeVirt, Proxmox) are where the value is.
