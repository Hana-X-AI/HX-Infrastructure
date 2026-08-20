Review accepted with the following corrections and direction.

First, confirm this additional fleet fact:

**The other 11 servers have been confirmed to have no discrete GPU.**

Treat that as owner-confirmed fleet input. Their individual Phase 1 discoveries should still record the actual hardware observed on each host, but there is no expectation that servers 5–15 provide additional NVIDIA GPU inference capacity.

This matters because it establishes that the four GPU-bearing servers are the fleet's discrete-GPU inference-capacity pool unless later direct discovery contradicts that owner-confirmed fact.

For the current report, make these corrections:

1. Replace:

   `hxs-1 cannot serve a model at all`

   with:

   `As found, hxs-1 cannot currently run CUDA-dependent NVIDIA inference workloads such as vLLM.`

   The discovered evidence proves that `nouveau` is bound, CUDA is absent, and the proprietary NVIDIA stack is not installed. It does not prove that every possible form of model serving is impossible.

2. Keep VRAM as:

   `unavailable from current as-found OS/driver state`

   Do not install NVIDIA drivers during Phase 1 merely to obtain VRAM.

3. Do not propose installing the shared fleet SSH key during Phase 1.

   We have already decided that the shared fleet SSH identity is a Phase 2 baseline activity.

   `discovery.md` must remain the as-found record and must not contain HX-introduced persistent configuration changes mixed into discovery.

4. Where the report says the NVIDIA driver "has to be installed for the role anyway," make the statement conditional:

   `If hxs-1 is later manually assigned a CUDA/vLLM role, the approved NVIDIA driver will be installed during Phase 2.`

   No role has been assigned yet.

Current project validation state:

```text
regression suite: 153/153 passing
server-registry phase 2 status: BLOCKED
role assignment: unchanged
phase 2 configuration: not started
```

Preserve that state.

Also record this fleet capability conclusion:

```text
gpu-bearing servers: 4
confirmed servers without discrete gpu: 11
additional discrete-gpu inference capacity among servers 5–15: none expected
```

Do not use this statement as a substitute for normal hardware discovery on those 11 servers. Their eventual `discovery.md` records must still reflect direct server evidence.

## next action

Run the two remaining read-only probes against `hxs-1` **now, before beginning discovery of servers 2–4**:

1. supplementary root/read-only pass;
2. rewritten native-Ubuntu VRAM / PCIe probe.

Reason for sequencing:

- complete the first server's discovery before moving on;
- validate the final discovery procedure on one host;
- collect PCIe negotiated width/speed for both GPUs;
- definitively record VRAM as either directly exposed or unavailable;
- collect the remaining read-only firmware/DIMM/security/network facts;
- identify any problems with the procedure before repeating it across servers 2–4.

These probes remain Phase 1 read-only discovery.

Do not:

- install packages;
- install NVIDIA drivers;
- install CUDA;
- alter SSH configuration;
- alter networking;
- alter storage;
- assign a role;
- select a workload or model;
- create `configuration.md`.

If a root-level fact requires interactive sudo authentication, request it as needed, but perform read-only commands only.

After both probes:

1. update `servers/hxs-1/discovery.md` with directly observed facts only;
2. keep vendor specifications clearly outside the as-found discovery record;
3. run `/audit-discovery`;
4. run `/sync-registry` if factual registry fields changed;
5. run `/phase1-gate`;
6. confirm Phase 2 remains `BLOCKED`;
7. confirm the regression suite remains `153/153`.

Then stop and report before starting servers 2–4.

Report:

```text
root-pass result
vram-probe result
pcie link width/speed per gpu
final vram status
discovery audit result
registry changes, if any
phase1-gate result
regression result
any facts still unavailable
confirmation that no persistent changes were made
```