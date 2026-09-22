# Which object does what (ClusterClass flavor, CAPI v1.14)

```
Cluster (capi-lab)                      ← the only thing you edit day to day
│  spec.topology.version                ← Kubernetes version of the whole cluster
│  spec.topology.controlPlane.replicas
│  spec.topology.workers.machineDeployments[].replicas
│  spec.topology.classRef → ClusterClass (quick-start)
│
├─ DevCluster                           ← infrastructure provider: "the cluster exists"
│                                          (for CAPD: a haproxy load-balancer container)
├─ KubeadmControlPlane                  ← control-plane provider: N control-plane Machines
│   └─ Machine ─┬─ KubeadmConfig        ← bootstrap provider: kubeadm init/join data
│               └─ DevMachine           ← infrastructure provider: one kind node container
└─ MachineDeployment (md-0)             ← like a Deployment, but for nodes
    └─ MachineSet                       ← like a ReplicaSet
        └─ Machine ─┬─ KubeadmConfig
                    └─ DevMachine
```

Three provider families, always the same shape:

| Family | Answers | Here |
|---|---|---|
| Infrastructure | "give me a VM / container / instance" | Docker (`DevMachine`) |
| Bootstrap | "how does that node become a Kubernetes node" | kubeadm (`KubeadmConfig`) |
| Control plane | "how many control-plane nodes, how are they rolled" | kubeadm (`KubeadmControlPlane`) |

Swap Docker for Hetzner, OpenStack, KubeVirt or Proxmox and only the first row changes.
Swap kubeadm for Talos and the second and third rows change — which is exactly why the
Docker provider cannot boot Talos (next article).
