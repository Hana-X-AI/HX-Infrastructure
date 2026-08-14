# Workload definitions

A workload is a model plus a runtime that may be **selected** to run on a host. It is not the
host's identity.

```
SERVER-REGISTRY.md   owns durable host identity and role
this directory       owns workload eligibility and selection
```

Adding a workload here never changes a server's role. Selecting one is explicit — a workload
being installed does not make it active.

Every workload passes `hx-capacity-gate.ps1` before any model download or activation.

## Present

| Workload | Classification | Candidate placement |
| --- | --- | --- |
| `ds4-deepseek` | EXPERIMENTAL | hxs-3, when selected and the gate passes |

## Deliberately absent

No `qwen-coder` workload is defined here. `SERVER-REGISTRY.md` currently assigns the Qwen
coder model to **hxs-2**, not hxs-3. Writing a `qwen-coder` workload pointed at hxs-3 would
contradict the registry, which is authoritative. The architecture admits such a workload the
moment the registry supports it — that is the point of keeping host identity and workload
identity apart — but it is not asserted here.

No placeholder `future-model` file exists either. A fake config is worse than an absent one.
