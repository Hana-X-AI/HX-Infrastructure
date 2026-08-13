Perform Phase 1 discovery for the following server:

server: hxs-1
ip address: 192.168.50.200

This is a Phase 1 discovery task only.

Before doing any work:

1. Read the root AGENTS.md.
2. Read servers/AGENTS.md.
3. Read CLAUDE.md.
4. Read GOALS-AND-OBJECTIVES.md.
5. Read INFRASTRUCTURE-CONTRACT.md.
6. Read SERVER-REGISTRY.md.
7. Read governance/policy/risk-acceptances.md.
8. Read the current discovery template under servers/_templates/.
9. Follow the existing discover-server, audit-discovery, and sync-registry skills.

Then perform discovery for hxs-1 by connecting directly to:

192.168.50.200

Do not require hx.local.arpa DNS for this discovery. act-001 remains open and is not a blocker.

Phase 1 boundaries are strict:

- discovery and documentation only;
- do not install packages;
- do not upgrade the OS;
- do not modify network configuration;
- do not modify DNS;
- do not change hostname;
- do not change SSH configuration;
- do not change sudoers;
- do not enable or disable services;
- do not install or change GPU drivers;
- do not format, partition, mount, or modify storage;
- do not install vLLM, Ollama, Hugging Face tooling, databases, or workload software;
- do not assign a server role;
- do not select a workload or model;
- do not create configuration.md.

Use the existing read-only discovery workflow and collector.

For any fact that cannot be obtained with the existing access or tooling, record it explicitly as unavailable rather than changing the server to retrieve it.

Create:

servers/hxs-1/discovery.md

using the approved template.

Record factual as-found information including:

- hostname and identity;
- manufacturer/model/serial where available;
- BIOS/firmware information;
- CPU model, sockets, cores, threads, NUMA;
- RAM capacity and topology where available;
- GPU/accelerator hardware, driver state, and VRAM where available;
- PCI devices relevant to server capability;
- disks, NVMe devices, filesystems, mounts, LVM/RAID state;
- network interfaces, addresses, routes, link speed, DNS state;
- Ubuntu/OS version and kernel;
- time synchronization state;
- relevant installed software;
- relevant enabled/running/failed services;
- listening services where appropriate;
- reboot-required state if observable;
- a concise factual capability summary.

Do not include passwords, private keys, .env values, or other credentials in any output or record.

After collecting the facts:

1. run /audit-discovery for hxs-1;
2. correct only factual/documentation deficiencies identified by the audit;
3. run /sync-registry for hxs-1;
4. update only factual discovery fields in SERVER-REGISTRY.md;
5. leave Assigned Role and Workload / Model unassigned;
6. leave Phase 2 blocked;
7. run /phase1-gate after synchronization.

The fleet-wide Phase 1 gate is expected to remain incomplete because the project expects 15 servers and this is only one discovery.

Important addressing check:

192.168.50.200 may fall outside the currently documented normal server-address range. Do not change the server's address during Phase 1.

If the current project contract or registry confirms that .200 conflicts with the approved addressing policy, record that discrepancy as an issue in governance/logs/actions-and-issues.md and continue discovery by the supplied IP address.

Do not treat the addressing discrepancy as a reason to mutate the server during discovery.

At completion, report:

- SSH/discovery connection result;
- discovery record path;
- audit result;
- registry synchronization result;
- key hardware capability summary;
- any unavailable facts;
- any new action or issue recorded;
- phase1-gate result;
- confirmation that no persistent server changes were made;
- confirmation that no role, workload, or model was assigned.