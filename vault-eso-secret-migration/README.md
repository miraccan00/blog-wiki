# vault-eso-secret-migration

Code for the article **Moving Secrets into Vault: From base64 in Git to Vault and ESO Without Downtime** —
[EN](https://miraccanyilmaz.me/en/blog/vault-eso-secret-migration/) ·
[TR](https://miraccanyilmaz.me/blog/vault-eso-secret-migration/).

It builds on [argocd-sso-zitadel](../argocd-sso-zitadel/): the same kind cluster, Argo CD and ZITADEL, with
branch `blog-05b` of [platform-gitops](https://github.com/miraccan00/platform-gitops) instead of `blog-05`.
`blog-05b` adds Vault (`apps/vault.yaml`, `vault/`), External Secrets Operator (`apps/external-secrets*.yaml`,
`external-secrets/`) and replaces ZITADEL's base64 Secrets with ExternalSecrets of the same names
(`zitadel/db/externalsecrets.yaml`, `argocd/secrets/oidc-zitadel.yaml`). `blog-05` is untouched; the previous
article and its lab keep working from it.

The branch history is the migration, one commit per step:

| Commit | Step |
|---|---|
| `3011bfd` | Vault and ESO next to the Git Secrets; shadow ExternalSecrets (`*-eso`) to compare values |
| `e872343` | ExternalSecrets take the real names, base64 Secrets removed from Git |
| `f2e4cd4` | Argo CD's OIDC client secret from Vault (it was never in Git, only in a script) |

Versions: hashicorp/vault chart 0.34.1 (Vault 2.0.4), external-secrets chart 2.11.0 (ESO v2.11.0, API
`external-secrets.io/v1`), argo/argo-cd chart 10.9.2 (Argo CD v3.5.3), zitadel/zitadel chart 10.1.0
(ZITADEL v4.19), kind 0.33, Colima 4 CPU / 8 GB on Apple Silicon. Vault and ESO add about 180 MiB
(working set: vault-0 70, ESO controller 33, webhook 26, cert-controller 51).

```
vault-eso-secret-migration/
├── Makefile                        make up / argocd / bootstrap / vault / setup / rotate-db / rotate-oidc / down
├── kind/cluster.yaml               1 control plane + 3 workers (same as the HA article)
├── scripts/colima-limits.sh        inotify limits for 4 kind nodes on Colima
├── scripts/vault-init.sh           init once (5 shares, threshold 3), unseal; keys in .lab/vault-init.json
├── scripts/vault-config.sh         kv-v2 at secret/, Kubernetes auth, read-only policy and role for ESO
├── scripts/seed-from-git.sh        the values blog-05 left in Git, read from that branch, into Vault
├── scripts/compare.sh              SHA-256 prefix per key of two Secrets, values never printed
├── scripts/rotate-db-password.sh   ALTER USER, kv patch, ESO force-sync, restart ZITADEL
├── scripts/rotate-oidc-secret.sh   new client secret in ZITADEL, kv patch, ESO force-sync
├── scripts/zitadel-setup.sh        as in 05, but the OIDC client goes to Vault instead of a Secret
├── scripts/wait-apps.sh            wait for the 13 Applications (SKIP= to leave some out)
└── scripts/coredns-rewrite.sh      pods resolve zitadel.127.0.0.1.nip.io to the zitadel Service
```

Clean cluster:

```bash
bash scripts/colima-limits.sh   # Colima only
make up                         # ~40 s
make argocd                     # ~6 min (redis-ha)
make bootstrap                  # root at blog-05b; returns when vault-0 exists (sealed)
make vault                      # init, unseal, configure, seed; ZITADEL Ready ~70 s after init
make dns
make zitadel-ui                 # own terminal
make setup                      # OIDC client into Vault; argocd-secrets turns green, 13 of 13
make rotate-db                  # new Postgres password, ~4 s
make rotate-oidc                # new client secret, <1 s
make ui                         # own terminal: http://localhost:8080 → "Log in via ZITADEL"
make vault-ui                   # own terminal: http://localhost:8200, token: jq -r .root_token .lab/vault-init.json
make down
```

A running 05 lab: `make from-05 vault rotate-db rotate-oidc`. Argo CD prunes the base64 Secrets as soon as
root points at `blog-05b`; running pods keep their environment, so nothing restarts until `rotate-db`.

`.lab/vault-init.json` holds the unseal keys and the root token. It never leaves `.lab` (gitignored) and
`make down` deletes it. Vault comes back **sealed** after every `vault-0` restart, `colima stop` included:
run `make vault-init` again.

## Measured in the article's run

| What | Result |
|---|---|
| Git Secret vs ESO copy, SHA-256 prefix per key | identical (6 of 6 keys) |
| Cutover commit: base64 Secrets pruned by Argo CD, recreated by ESO | same second (17:58:57), new UIDs, no pod restart |
| `make rotate-db` | 3.3 s; 180 probe requests during it, 180 × 200 |
| Old password from Git history after rotation | `FATAL: password authentication failed for user "zitadel"` |
| `make rotate-oidc`, then alice logs in | 0.7 s; login OK, argocd-server not restarted |
| `vault kv put` with one key instead of `kv patch` | Secret loses `clientID`; Argo CD sends `client_id=$argocd-oidc-zitadel:clientID`, ZITADEL `400 Errors.App.NotFound` |
| Clean install: Vault init → ESO writes the Secrets → ZITADEL Ready | 29 s → 71 s |
| After both rotations: alice / dave / bob sync `product-helloapi-dev` | 200 / 200 / 403 |

## Lab shortcuts, on purpose

- One Vault server in the cluster, raft storage, HTTP. Production runs Vault outside the cluster, 3 nodes,
  TLS, the key shares with different people and the root token revoked after setup.
- The root token does everything here. A real setup gives humans their own Vault auth (OIDC through
  ZITADEL is the obvious one) and keeps the root token for break-glass.
- The ZITADEL masterkey moves unchanged: ZITADEL encrypts its data with it. The value from Git history stays
  valid, so who could read the repo has to be treated as having had it.
