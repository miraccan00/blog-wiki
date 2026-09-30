# argocd-sso-zitadel

Code for the article **Argo CD SSO Integration: OIDC and RBAC with ZITADEL** —
[EN](https://miraccanyilmaz.me/en/blog/argocd-sso-zitadel/) ·
[TR](https://miraccanyilmaz.me/blog/argocd-sso-zitadel/).

It builds on [argocd-ha-app-of-apps](../argocd-ha-app-of-apps/): the same kind cluster, the same three repos,
with branch `blog-05` of [platform-gitops](https://github.com/miraccan00/platform-gitops) instead of `blog-04`.
`blog-05` adds ZITADEL (`apps/zitadel-db.yaml`, `apps/zitadel.yaml`, `zitadel/`) and puts OIDC and RBAC into
`argocd/values-ha.yaml`. Argo CD installs ZITADEL itself; there is no Dex.

Secrets for ZITADEL's Postgres and its masterkey sit in Git as base64 (`zitadel/db/secrets.yaml`) on purpose.
That is where most teams start, and it is what the next article moves into Vault. Lab values only.

Versions: argo/argo-cd chart 10.9.2 (Argo CD v3.5.3), zitadel/zitadel chart 10.1.0 (ZITADEL v4.19),
postgres 17, kind 0.33 with `kindest/node:v1.35.0`, Colima 4 CPU / 8 GB on Apple Silicon.

```
argocd-sso-zitadel/
├── Makefile                    make up / argocd / bootstrap / dns / zitadel-ui / setup / ui / down
├── kind/cluster.yaml           1 control plane + 3 workers (same as the HA article)
├── scripts/colima-limits.sh    inotify limits for 4 kind nodes on Colima
├── scripts/wait-apps.sh        wait for the 9 Applications to be Synced/Healthy
├── scripts/coredns-rewrite.sh  pods resolve zitadel.127.0.0.1.nip.io to the zitadel Service
└── scripts/zitadel-setup.sh    project, roles, OIDC app, groups Action, users, Secret for Argo CD
```

```bash
bash scripts/colima-limits.sh   # Colima only
make up                         # ~40 s
make argocd                     # ~6 min (redis-ha)
make bootstrap                  # 9 Applications, ZITADEL and Postgres included, ~50 s
make dns                        # CoreDNS rewrite, prints the issuer as a pod sees it
make zitadel-ui                 # own terminal: http://zitadel.127.0.0.1.nip.io:8081
make setup                      # ~5 s
make ui                         # own terminal: http://localhost:8080 → "Log in via ZITADEL"
make users                      # alice (admin) and bob (readonly), password Password1!
make down
```

`KUBECONFIG` points into `./.lab`; nothing is written to `~/.kube`.

## Why the odd hostname

The issuer URL in every token must be the same for the browser and for `argocd-server`. The browser reaches
ZITADEL through a port-forward on 127.0.0.1; a pod that resolves the same name to 127.0.0.1 talks to itself.
`zitadel.127.0.0.1.nip.io` resolves to 127.0.0.1 through public DNS, and `make dns` adds a CoreDNS rewrite
(`answer auto`) so pods get the zitadel Service instead. `zitadel.localhost` does not work: resolvers answer
`*.localhost` with loopback without asking DNS. In production ZITADEL has a real DNS name and none of this exists.

## Measured in the article's run

| What | Result |
|---|---|
| `make bootstrap`: 9 Applications Synced/Healthy (ZITADEL, Postgres, retry on the PreSync hooks) | 48 s |
| `make setup` | 4 s |
| alice (`platform-admins`) syncs `product-helloapi-dev` | 200 |
| bob (`platform-viewers`) syncs `product-helloapi-dev` | 403 `permission denied: applications, sync, …` |

## Two things that are the old way, on purpose

- ZITADEL v4 sends logins to **Login v2**, a separate app that needs path routing on the same host. Without an
  ingress this lab uses the built-in login (`DefaultInstance.Features.LoginV2.Required: false`).
- The `groups` claim comes from a ZITADEL **Actions v1** script (the method in Argo CD's docs). Actions v1 is
  deprecated in v4 and removed in v5; the v2 equivalent calls an external HTTP service.
