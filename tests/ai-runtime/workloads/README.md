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

A workload whose status is DEFERRED or whose commissioning is ABORTED cannot be commissioned:
the driver refuses to evaluate any gate for it.


| Workload | Classification | Candidate placement |
| --- | --- | --- |
| `ds4-deepseek` | DEFERRED / RESEARCH | none — commissioning aborted 2026-08-14 |

## Deliberately absent

No `qwen-coder` workload is defined here. `SERVER-REGISTRY.md` currently assigns the Qwen
coder model to **hxs-2**, not hxs-3. Writing a `qwen-coder` workload pointed at hxs-3 would
contradict the registry, which is authoritative. The architecture admits such a workload the
moment the registry supports it — that is the point of keeping host identity and workload
identity apart — but it is not asserted here.

No placeholder `future-model` file exists either. A fake config is worse than an absent one.
