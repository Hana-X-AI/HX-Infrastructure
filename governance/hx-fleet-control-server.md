# HX fleet control server

## purpose

Establish a dedicated central command-and-control server for the HX fleet.

This server is the control plane where Claude Code and other approved agents pull repositories, work in controlled workspaces, validate changes, prepare deployment artifacts, and deploy to the appropriate server in the fleet.

It is not a production workload host.

## operating system

Use:

```text
Ubuntu 24.04 LTS
```

Ubuntu is preferred over Windows because the HX fleet is Linux-based. Using the same operating environment for the control plane and the target servers avoids unnecessary differences in:

- shell behavior;
- filesystem paths;
- permissions;
- SSH tooling;
- service management;
- package management;
- deployment scripts.

Windows remains suitable as the human administration workstation, but the fleet control plane should be native Linux.

## architecture

```text
                    GitHub / source repos
                            |
                            v
                  +-------------------+
                  | HX Control Server |
                  | Ubuntu 24.04 LTS  |
                  |                   |
                  | Claude / agents   |
                  | Git workspaces    |
                  | build / staging   |
                  | deployment tools  |
                  | fleet inventory   |
                  | logs / reports    |
                  +---------+---------+
                            |
                         SSH/FQDN
                            |
       +--------------------+--------------------+
       |                    |                    |
       v                    v                    v
hxs-1.hx.local.arpa   hxs-2.hx.local.arpa   ... hxs-15
```

## responsibilities

The control server should provide:

- canonical local working copies of HX repositories;
- Claude Code and approved agent tooling;
- controlled agent workspaces;
- fleet SSH access;
- fleet inventory and server registry access;
- deployment scripts;
- deployment artifacts;
- pre-deployment validation;
- post-deployment verification;
- centralized deployment and agent logs;
- Git commit, push, and pull-request workflows where appropriate;
- a future location for lightweight fleet orchestration if needed.

## non-responsibilities

Do not use the control server for:

- vLLM inference;
- production model serving;
- production databases;
- application workloads;
- role-specific fleet services;
- general-purpose experimentation unrelated to fleet control.

Keep the control plane clean and operationally focused.

## proposed filesystem layout

```text
/srv/hx/
├── repos/          # canonical repository clones
├── workspaces/     # Claude and agent working copies
├── artifacts/      # deployment outputs
├── deployments/    # deployment tooling
├── inventory/      # fleet definitions and targeting data
├── logs/           # deployment and agent logs
└── backups/        # control-plane configuration backups
```

The exact structure can evolve, but the separation between source repositories, active workspaces, artifacts, deployment tooling, and logs should remain clear.

## deployment model

The expected workflow is:

```text
repository
    |
    v
HX control server
    |
    +--> agent workspace
    |
    +--> validation / build / tests
    |
    +--> approved deployment artifact
    |
    v
target hxs-N server
    |
    v
post-deployment verification
```

Agents should work on the control server first and deploy only after the appropriate project gate or approval is satisfied.

The control server prepares and deploys. The target fleet servers run the approved workloads.

## fleet addressing

Use the established HX FQDN convention for fleet operations:

```text
hxs-1.hx.local.arpa
hxs-2.hx.local.arpa
...
hxs-15.hx.local.arpa
```

Deployment scripts and agent instructions should prefer FQDNs over hard-coded IP addresses where practical.

## SSH access

The control server will require SSH access to the fleet.

The existing fleet key can be used initially.

Longer term, separate:

```text
human workstation key
```

from:

```text
control-plane deployment key
```

This allows the control server and its agents to receive only the fleet privileges required for deployment and operations without depending on a human workstation credential.

## initial build scope

Keep the first implementation lean.

Install and configure only what is required for control-plane operation:

```text
Ubuntu 24.04 LTS
+ static IP
+ hx.local.arpa FQDN
+ SSH
+ Git
+ Claude / approved agent tooling
+ /srv/hx workspace structure
+ fleet SSH access
```

Do not add orchestration platforms, databases, model-serving software, or unrelated services during the initial build.

## future capabilities

Once the basic control plane is proven, possible additions include:

- a lightweight orchestration layer, if one proves necessary. **Not Ansible.** Ruled out by owner decision on 2026-08-13 as more trouble than it is worth; it is not to be proposed again in any plan, roadmap or recommendation;
- centralized deployment history;
- automated fleet health checks;
- controlled secrets management;
- artifact promotion workflows;
- automated rollback;
- scheduled fleet maintenance;
- deployment approval gates.

These are future capabilities, not initial requirements.

## decision

Create one dedicated Ubuntu 24.04 LTS HX fleet control server.

The intended operating model becomes:

```text
Human administrator
        |
        v
HX Control Server
        |
        v
HX fleet
```

rather than:

```text
Human Windows workstation
        |
        v
individual server
```

This control server becomes the stable execution point for Claude, other agents, repository work, deployment preparation, and fleet operations.
