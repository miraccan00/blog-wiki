# argocd-ha-app-of-apps

Code for the article **Argo CD in HA, Explained by Breaking It** —
[EN](https://miraccanyilmaz.me/en/blog/argocd-ha-app-of-apps/) ·
[TR](https://miraccanyilmaz.me/blog/argocd-ha-app-of-apps/).

This folder is the lab: a kind cluster, the one `helm install`, and the scripts that break things and
time the recovery. What Argo CD actually deploys lives in three public repos, as it would at work:

| Repo | Role |
|---|---|
| [platform-gitops](https://github.com/miraccan00/platform-gitops) | Argo CD values, `bootstrap/root.yaml`, `apps/`, ApplicationSets, namespaces + quotas |
| [product-helloapi-gitops](https://github.com/miraccan00/product-helloapi-gitops) | the helloapi chart and `overlays/{dev,prod}` (image tag, replicas, message) |
| [hellofiber](https://github.com/miraccan00/hellofiber) | the Go service; CI publishes `ghcr.io/miraccan00/hellofiber:sha-<7>` (amd64 + arm64) |

The article uses branch `blog-04` of all three (`make ... REV=blog-04`, the default).

Versions used in the article: argo/argo-cd chart 10.9.2 (Argo CD v3.5.3, redis 8.6.4), kind 0.33 with
`kindest/node:v1.35.0`, Helm 3.15, Docker 27 on Colima 0.8 (4 CPU / 8 GB, Apple Silicon).

```
argocd-ha-app-of-apps/
├── Makefile                      make up / argocd / bootstrap / hello / ship / failover / down
├── kind/cluster.yaml             1 control plane + 3 workers (redis-ha needs 3 nodes)
├── scripts/colima-limits.sh      inotify limits for 4 kind nodes on Colima
├── scripts/wait-apps.sh          wait for the 7 Applications to be Synced/Healthy
├── scripts/ship.sh               after a push: refresh (what a webhook does), time the rollout
├── scripts/drift.sh              scale prod by hand, time selfHeal
├── scripts/probe.sh              hard refresh, time until reconciled (no backoff, safe to repeat)
├── scripts/failover.sh           Redis master, a repo-server, then the controller's node
├── scripts/node-out-of-service.sh  the controller's node again, with the out-of-service taint
└── docs/how-to-ship-a-change.md  the page teams get on day one
```

```bash
brew install kind kubectl helm       # kind 0.33, helm 3.15+
bash scripts/colima-limits.sh        # Colima only; Docker Desktop: see below
make up                              # ~50 s
make argocd                          # ~6 min: the three Redis pods start one after another
make bootstrap                       # 7 Applications Synced/Healthy in ~20 s
make hello
make failover                        # ~9 min; 7 of them waiting on a dead node on purpose
make out-of-service
make down
```

`KUBECONFIG` points into `./.lab`; nothing is written to `~/.kube`.

## Measured in the article's run

| What | Result |
|---|---|
| `helm install` with redis-ha, `--wait` | 343 s |
| `kubectl apply` root → 7 Applications Synced/Healthy | 19 s |
| Push to product repo → 3/3 pods, no webhook (polling 120 s + 60 s jitter) | 91 s |
| Push → Synced/Healthy with a refresh (what a webhook does) | 4 s |
| Redis master deleted → Sentinel promotes a replica | 12 s (41 s in an earlier run) |
| Hard refresh while the Redis master is gone | 6 s |
| Hard refresh right after a repo-server is deleted | 1 s |
| Worker running the application controller stopped | no reconciliation for 7 min; pod stuck `Terminating` |
| Same, plus the `out-of-service` taint | controller Ready on another node 81 s after the node died |

## Docker Desktop

Docker Desktop's VM already has higher inotify limits; skip `colima-limits.sh`. Give it at least
4 CPU / 8 GB; the four nodes use about 3 GB with everything running.
