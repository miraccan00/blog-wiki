# An admission chain with Kyverno on top of Cilium

Code for the article
**[Kyverno Admission Webhooks: Default-Deny for Every Namespace, 3 Core Rules, and the Gap When Kyverno Goes Down](https://miraccanyilmaz.me/en/blog/kyverno-cilium-policy-chain/)**
· [Türkçe](https://miraccanyilmaz.me/blog/kyverno-cilium-policy-chain/)

Kyverno, as a Kubernetes admission webhook, generates a `CiliumNetworkPolicy` default-deny for every new
namespace, refuses pods that Cilium could not police (`hostNetwork`, `privileged`, no `app` label), derives
the missing `app` label on Deployments, keeps `Gateway` objects in the platform namespace, and enforces
three rules from the [Kyverno policy library](https://github.com/kyverno/policies): no `latest` tag, no
`default` namespace, CPU/memory requests and memory limits. Same rules in CI with `kyverno apply`.
Kyverno at admission, Cilium on the wire.

## Versions (run on 2026-10-06)

| Tool | Version |
|---|---|
| macOS (Apple Silicon) + Colima | 4 CPU / 8 GB VM |
| kind | v0.33.0, Kubernetes v1.37.0 |
| Gateway API CRDs | v1.6.1 (standard) |
| Cilium | 1.20.2 (kube-proxy replacement, Hubble) |
| Kyverno | v1.19.1 (chart 3.9.1), `policies.kyverno.io/v1` ValidatingPolicy / MutatingPolicy / GeneratingPolicy |
| kyverno CLI | 1.19.1 (`brew install kyverno`) |
| cilium CLI | `brew install cilium-cli` |

## Run

```bash
make up          # kind → Gateway API CRDs → Cilium → Kyverno (~130 s). CRDs before Kyverno, see below
make policies    # aggregated RBAC, then the nine policies (pod rules in Audit)
make demo        # team-a → default-deny CNP; good/bad/careless pods; pod in default; mutated Deployment; refused Gateway
make report      # PolicyReports with failures, then every failing result
make enforce     # Audit → Deny, in the policy files (not kubectl patch)
make ci          # kyverno apply policies/ --resource demo/, no cluster: pass 25, fail 8, error 0
make verify
make audit       # policy files back to Audit (the starting point)
make down
```

## In the UI

```bash
make reporter     # Policy Reporter + its UI (with its own CNP next to the generated default-deny)
make ui-reports   # own terminal: http://localhost:8082
make ui-hubble    # own terminal: http://localhost:12000, namespace team-a
kubectl apply -f demo/curl-pod.yaml
kubectl -n team-a exec curl -- curl -s -m 5 https://example.com   # times out
```

- **Policy Reporter** (http://localhost:8082): Dashboard shows pass/fail per policy type; with the demo pods in Audit
  it was 71 pass, 7 fail (`bad` 4, `careless` 2, `quick-test` 1). KyvernoValidatingPolicy in the menu lists each
  failing pod with the rule's message.
- **Hubble UI** (http://localhost:12000, namespace `team-a`): the `curl` pod's requests to `example.com:443` show up
  as `dropped`; DNS still resolves. That's the generated default-deny at work.
- Then `make enforce` and apply `demo/careless-pod.yaml` again: refused in the terminal, nothing new in the UI.

## Layout

```
kyverno-cilium-policy-chain/
├── Makefile
├── kind/config.yaml                     # no default CNI, no kube-proxy
├── gateway-api/install-crds.sh          # Gateway API v1.6.1 CRDs, before Cilium and Kyverno
├── cilium/{values.yaml,install.sh}
├── kyverno/{values.yaml,install.sh}     # system namespaces excluded via resourceFilters + webhook selector
├── rbac/kyverno-cilium-clusterrole.yaml # aggregated ClusterRoles: background/admission → cilium.io, reports → gateways
├── policies/
│   ├── generate-default-deny.yaml       # GeneratingPolicy: Namespace → CiliumNetworkPolicy default-deny (+DNS)
│   ├── require-app-label.yaml           # ValidatingPolicy (Audit → Deny)
│   ├── disallow-host-network.yaml       # ValidatingPolicy
│   ├── disallow-privileged.yaml         # ValidatingPolicy (containers + initContainers, SYS_ADMIN/BPF caps)
│   ├── disallow-latest-tag.yaml         # from the Kyverno library (best-practices-vpol)
│   ├── disallow-default-namespace.yaml  # from the Kyverno library (best-practices-vpol)
│   ├── require-requests-limits.yaml     # from the Kyverno library (best-practices-vpol/require-pod-requests-limits)
│   ├── restrict-gateway-namespace.yaml  # ValidatingPolicy (Deny from day one)
│   └── mutate-name-label.yaml           # MutatingPolicy: app=<deployment name> on object + pod template
├── scripts/{apply,demo,report,enforce,audit}.sh
├── ci/kyverno-apply.sh                  # the CI gate step
├── ci/values.yaml                       # namespaces for rules that read namespaceObject offline
├── ci/crds/                             # Gateway CRD so the CLI evaluates Gateways offline
├── policy-reporter/                     # values (with resources), install.sh, allow-policy-reporter.yaml (second CNP)
└── demo/{good-pod,bad-pod,careless-pod,default-ns-pod,curl-pod,unlabelled-deployment,bad-gateway}.yaml
```

## Measured in the article's run

| What | Result |
|---|---|
| Three library rules in Audit, first report | 12 violations, incl. the lab's own `good` pod and `echo` Deployment (no `resources`) and kind's `local-path-provisioner` |
| After the fix | only the three deliberately bad demo pods |
| `bad` pod after Deny | 4 violations in one error message (one shared exclusion list → one webhook) |
| `make ci` | `pass: 25, fail: 8, warn: 0, error: 0`, the same 8 as the cluster |
| Kyverno scaled to 0 | webhook configs 7 → 2, a `latest`/no-resources pod admitted |
| Kyverno unreachable | pod refused: `failed calling webhook ... no route to host` |
| Namespaces created during an outage | no default-deny until `generateExisting` is toggled off/on |
| Generated CNP deleted / edited | recreated in ~5 s / edit not reverted |

## Notes

- Install the Gateway API CRDs before Kyverno: Kyverno reads resource types at start, and Gateways created
  afterwards are refused with `resource gateways not found` until Kyverno restarts.
- Apply `rbac/` before `policies/`. Without `cilium.io` permissions the background controller fails
  (`permission denied ... ciliumnetworkpolicies`) and does not retry when the permission comes back.
- After any Kyverno outage, re-run the existing-namespace pass:
  ```bash
  kubectl patch generatingpolicy generate-default-deny --type merge -p '{"spec":{"evaluation":{"generateExisting":{"enabled":false}}}}'
  kubectl patch generatingpolicy generate-default-deny --type merge -p '{"spec":{"evaluation":{"generateExisting":{"enabled":true}}}}'
  ```
- Keep one exclusion list across policies: Kyverno opens one webhook per distinct `namespaceSelector`, and
  the API server returns only the first refusal.
- Switch to Deny in the files. A `kubectl patch` is undone by the next `kubectl apply -f policies/`.
- The webhook `failurePolicy` stays `Fail`. `kube-system` and `kyverno` are excluded so a Kyverno outage
  cannot block CNI, DNS or Kyverno's own recovery.
