# talos-linux-explained

Code for the article **Talos Linux, Explained by Running It: No Shell, One Machine Config, an OS You
Talk to Over gRPC** — [EN](https://miraccanyilmaz.me/en/blog/talos-linux-explained/) ·
[TR](https://miraccanyilmaz.me/blog/talos-linux-explained/).

Versions used in the article: Talos v1.13.10 (image), talosctl v1.13.5, Kubernetes 1.35.8 → 1.36.4,
Docker 27 on Colima 0.8 (4 CPU / 8 GB, Apple Silicon, VM kernel 6.8).

```
talos-linux-explained/
├── Makefile                        make up / patch / upgrade / status / down
├── cluster/create.sh               talosctl cluster create docker, state kept under ./.lab
├── config/lab.patch.yaml           patch for all nodes (extraHostEntries, no scheduling on CP)
├── config/controlplane.patch.yaml  apiServer extraArgs + node label
├── config/worker.patch.yaml        kubelet extraArgs, sysctls, node label (applied live by `make patch`)
├── config/needs-reboot.patch.yaml  a change the API will only apply with a reboot (dry-run demo)
├── factory/schematic.yaml          Image Factory schematic: iscsi-tools + util-linux-tools
├── factory/schematic-id.sh         POST the schematic, print installer / ISO references
├── scripts/patch.sh                dry-run, apply, prove the node runs the new values, then the reboot case
├── scripts/upgrade.sh              upgrade-k8s (works in Docker) + OS upgrade (refused in Docker, shown)
└── docs/api-vs-ssh.md              SSH habit → talosctl command table
```

```bash
brew install talosctl kubectl          # talosctl 1.13.x
make up                                # ~2 min after the image is pulled
make patch
make upgrade                           # Kubernetes 1.35.8 -> 1.36.4; the OS upgrade is refused in Docker
make down
```

Nothing is written to `~/.talos` or `~/.kube`; `TALOSCONFIG` and `KUBECONFIG` point into `./.lab`.

## Two things to know before `make up`

- **Talos 1.14 does not start in Docker on a kernel older than 6.13.** Its `/etc` overlay is mounted
  with file-descriptor layers (`fsconfig(FSCONFIG_SET_FD, "lowerdir+")`, kernel 6.13+). Colima 0.8 ships
  a 6.8 kernel, so `ghcr.io/siderolabs/talos:v1.14.x` dies in `machined` with
  `FSCONFIG_SET_FD failed: bad file descriptor` and `talosctl cluster create` waits forever. The lab
  pins v1.13.10. On a 6.13+ host (recent Docker Desktop, Linux) set `TALOS_VERSION=v1.14.1`.
- **Flannel needs `br_netfilter` on the VM.** Talos runs as a container and cannot load host modules.
  On Colima: `colima ssh -- sudo modprobe br_netfilter`. Without it `kube-flannel` crash-loops with
  `Failed to check br_netfilter` and CoreDNS never gets a sandbox.

Both are explained in the article's "What went wrong" section.
