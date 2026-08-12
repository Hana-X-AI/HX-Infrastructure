# server records contract

## purpose

Define local rules for server discovery and configuration records.

## ownership

This contract owns:

```text
servers/
├── README.md
├── _templates/
└── <server>/
    ├── discovery.md
    └── configuration.md
```

## local contracts

### phase 1 — discovery

Phase 1 is discovery and documentation only.

For each server:

- inspect the server as found;
- record factual hardware, firmware, OS, storage, network, GPU/accelerator, and relevant software/service state;
- create or update `servers/<server>/discovery.md`;
- use explicit `unavailable`, `not detected`, or equivalent factual wording when a fact cannot be obtained;
- do not invent values;
- do not assign a role, workload, or model;
- do not perform role-specific configuration.

`discovery.md` answers:

> What was this server when HX found it?

Once accepted as complete, preserve it as historical as-found evidence.

### registry synchronization

`SERVER-REGISTRY.md` is the fleet-level source of truth for lifecycle state and manual role assignment.

During Phase 1 automation may synchronize factual discovery fields only.

Automation must not populate or infer:

- `Assigned Role`;
- `Workload / Model`;
- manual approval decisions.

### phase 2 — configuration

Do not create or modify a server's `configuration.md` while Phase 2 is blocked.

When Phase 2 is legitimately open:

- copy the approved role/workload from `SERVER-REGISTRY.md`;
- configure only the approved role;
- preserve `discovery.md`;
- document material changes and validation in `configuration.md`.

`configuration.md` answers:

> What did HX configure this server to become?

## work guidance

- Use the templates in `servers/_templates/`.
- Keep records factual and concise.
- Prefer direct evidence from the server over assumptions.
- Do not place credentials, private keys, or secret values in server records.
- Stable DNS is useful but is not required to perform Phase 1 discovery when the server is reachable by an approved IP address.
- Do not create per-server child `AGENTS.md` files unless a server directory later becomes a durable boundary with genuinely different operating rules.

## verification

For Phase 1 records, use the established project workflow as applicable:

```text
/audit-discovery
/sync-registry
/phase1-gate
```

A server discovery record should not be treated as complete until required facts are present or explicitly documented as unavailable.

For Phase 2 records, validate the configured role using the approved role-specific workflow and record the result without altering the historical discovery record.

## child dox index

No child `AGENTS.md` files are required under individual server directories at this time.
