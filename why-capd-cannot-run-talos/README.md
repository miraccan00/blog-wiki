# why-capd-cannot-run-talos

Code for the article **Why Cluster API's Docker Provider Can't Bootstrap Talos** —
[EN](https://miraccanyilmaz.me/en/blog/why-capd-cannot-run-talos/) ·
[TR](https://miraccanyilmaz.me/blog/why-capd-cannot-run-talos/).

No cluster is built here. The script replays, with plain `docker`, the three checks CAPD runs against a
node container before and during bootstrap, once against `kindest/node` and once against Talos.

Versions used in the article: `kindest/node:v1.34.0`, `ghcr.io/siderolabs/talos:v1.13.10`, Docker 27 on
Colima 0.8 (Apple Silicon, VM kernel 6.8). CAPD source quoted from `kubernetes-sigs/cluster-api` `main`
(September 2026).

```
why-capd-cannot-run-talos/
├── Makefile               make check / check-kind / check-talos / inspect
└── scripts/capd-checks.sh WaitForMultiUserTarget, WaitForCrictlPs, `/bin/sh -c` against one image
```

```bash
make check      # ~40 s; kind passes all three, Talos fails all three
make inspect    # which of sh/bash/systemctl/crictl/kubeadm/cloud-init each image ships
```

Containers are removed on exit; nothing else is created. Talos 1.14 needs a 6.13+ kernel in Docker
(see `../talos-linux-explained/README.md`), so the default stays on v1.13.10.
