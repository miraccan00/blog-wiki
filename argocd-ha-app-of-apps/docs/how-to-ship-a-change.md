# How to ship a change

One page for product teams. If something here is wrong, open a PR against this file.

## The rule

The cluster runs what Git says. Argo CD compares the two every 2–3 minutes (seconds with the webhook)
and puts the cluster back if someone changed it by hand. A `kubectl edit` in production lasts until
the next comparison.

## Where things live

| You want to change | Repo | File |
|---|---|---|
| Code | `hellofiber` | anything; every push builds `ghcr.io/miraccan00/hellofiber:sha-<7>` |
| Which build runs | `product-helloapi-gitops` | `overlays/<env>/values.yaml` → `image.tag` |
| Replicas, env vars, resources | `product-helloapi-gitops` | `overlays/<env>/values.yaml` |
| The chart itself | `product-helloapi-gitops` | `chart/` (bump `version` in `Chart.yaml` and both overlays) |
| Namespace quota | `platform-gitops` | `namespaces/<product>/<env>/` (platform team reviews) |

## Shipping a new build

1. Merge your code. CI prints the image tag, e.g. `sha-d96497a`.
2. In `product-helloapi-gitops`, change `image.tag` in `overlays/dev/values.yaml`. Open a PR, merge.
3. Check dev: the Argo CD UI shows `product-helloapi-dev` Synced / Healthy with your commit.
4. Same change in `overlays/prod/values.yaml`, separate PR. Prod is a second, reviewed step on purpose.

## Rolling back

Revert the PR. Do not use "Rollback" in the UI for a real rollback: with auto-sync on, Argo CD syncs
back to Git on the next comparison, and Git still says the new version.

## When it does not sync

| You see | Usually means |
|---|---|
| `OutOfSync`, nothing happens | Auto-sync already tried this commit and is backing off (up to 5 minutes between attempts). Fix and push a new commit. |
| `Degraded` | Pods are not becoming ready: check probes, image tag, quota (`kubectl describe` the ReplicaSet). |
| `ComparisonError` | The chart does not render. Run `kubectl kustomize --enable-helm overlays/<env>` locally. |
| `exceeded quota` in events | Your requests × replicas are over the namespace quota. Ask the platform team, or lower them. |

## What you do not do

- `kubectl apply`, `kubectl edit`, `kubectl scale` in dev or prod. Argo CD reverts it; the next person
  reading Git will not know it happened.
- Push to `main` without a PR in either gitops repo.
- Put secrets in values files. They are coming through External Secrets (separate page).
