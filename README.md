# blog-wiki

Code for the articles at [miraccanyilmaz.me](https://miraccanyilmaz.me). One folder per article on `main`,
folder name = article slug. Each folder has its own README with the article link and `make up / make down`.
Articles without code point to the relevant project repository. A tag `<slug>-v1` marks the code as it was
on publication day.

## Articles, in publishing order

| # | Date | Article (EN / TR) | Category | Code |
|---|---|---|---|---|
| 01 | 2026-09-22 | [Cluster API, Explained by Building One: kind, the Docker Provider and a Workload Cluster in 15 Minutes](https://miraccanyilmaz.me/en/blog/cluster-api-explained-with-capd/)<br>[Cluster API'yi Kurarak Anlamak: kind, Docker Provider ve 15 Dakikada Bir Workload Cluster](https://miraccanyilmaz.me/blog/cluster-api-explained-with-capd/) | `platform-engineering` | [`cluster-api-explained-with-capd/`](cluster-api-explained-with-capd/) |
| 02 | 2026-09-25 | [Talos Linux, Explained by Running It: No Shell, One Machine Config, an OS You Talk to Over gRPC](https://miraccanyilmaz.me/en/blog/talos-linux-explained/)<br>[Talos Linux'u Çalıştırarak Anlamak: Shell Yok, Tek Makine Konfigürasyonu, gRPC ile Konuşulan İşletim Sistemi](https://miraccanyilmaz.me/blog/talos-linux-explained/) | `platform-engineering` | [`talos-linux-explained/`](talos-linux-explained/) |
| 03 | 2026-09-27 | [Why Cluster API's Docker Provider Can't Bootstrap Talos](https://miraccanyilmaz.me/en/blog/why-capd-cannot-run-talos/)<br>[Cluster API Docker Provider Talos'u Neden Ayağa Kaldıramaz](https://miraccanyilmaz.me/blog/why-capd-cannot-run-talos/) | `platform-engineering` | [`why-capd-cannot-run-talos/`](why-capd-cannot-run-talos/) |
| 04 | 2026-10-13 | [Argo CD in HA, Explained by Breaking It: redis-ha, App-of-Apps and the One Pod That Doesn't Fail Over](https://miraccanyilmaz.me/en/blog/argocd-ha-app-of-apps/)<br>[Argo CD'yi HA Kurup Bozarak Anlamak: redis-ha, App-of-Apps ve Failover Etmeyen Tek Pod](https://miraccanyilmaz.me/blog/argocd-ha-app-of-apps/) | `gitops` | [`argocd-ha-app-of-apps/`](argocd-ha-app-of-apps/) |
| 05 | 2026-10-02 | [Argo CD SSO Integration: OIDC and RBAC with ZITADEL](https://miraccanyilmaz.me/en/blog/argocd-sso-zitadel/)<br>[Argo CD SSO Entegrasyonu: ZITADEL ile OIDC ve RBAC](https://miraccanyilmaz.me/blog/argocd-sso-zitadel/) | `security` | [`argocd-sso-zitadel/`](argocd-sso-zitadel/) |

## Published earlier

| Article | Code |
|---|---|
| [Pre-commit Nedir?](https://miraccanyilmaz.me/blog/pre-commit-nedir/) · [EN](https://miraccanyilmaz.me/en/blog/pre-commit-nedir/) | [`pre-commit/`](pre-commit/) · [`pre-commit-ozel-kontroller/`](pre-commit-ozel-kontroller/) (moving from the branches of the same name) |

## Layout

```
<slug>/
├── README.md        # article link, versions, how to run
├── Makefile         # make up / make demo / make down (where applicable)
└── ...
```

CI runs per folder with path filters: `go vet`, `terraform fmt -check`, `ansible-lint`, `yamllint`.
Nothing here contains real credentials, hostnames or IPs; see each README for the placeholders to fill.
