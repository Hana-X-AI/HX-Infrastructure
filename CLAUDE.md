# CLAUDE.md — HX-Infrastructure

Read first:

1. `GOALS-AND-OBJECTIVES.md`
2. `INFRASTRUCTURE-CONTRACT.md`
3. `SERVER-REGISTRY.md`
4. `governance/policy/risk-acceptances.md`

## Phase 1

Phase 1 is discovery and documentation only.

- Inspect servers.
- Record factual hardware, OS, storage, network, and relevant runtime state.
- Create/update `servers/<server>/discovery.md`.
- Update the registry with discovered facts.
- Do not assign server roles.
- Do not select workloads or models.
- Do not perform role-specific configuration.

Role assignment is manual.

## Phase 1 Gate

The canonical Phase 1 gate and independently approved expected-fleet baseline are defined in `GOALS-AND-OBJECTIVES.md`.

Evaluate that gate by comparing the expected fleet count with the registry count and completed discovery count. Do not begin Phase 2 until every canonical gate condition is complete.

## Phase 2

Do not begin until every server is discovered, documented, reviewed, and manually assigned a role.

When Phase 2 begins for a server:

- preserve `discovery.md`;
- configure only the approved role;
- create `configuration.md`;
- document and validate the configured state.

Keep documentation concise and factual. Avoid speculative architecture, exhaustive runbooks, and unnecessary planning documents.

## Documentation and MCP Use

Context7 MCP is the project documentation-retrieval service.

Use documentation sources in this order:

1. Installed/local documentation on the target system:
   - `man`
   - command `--help`
   - `/usr/share/doc`
   - installed package/version information
2. Context7 MCP retrieval of current official documentation.
3. Official vendor/project documentation when additional detail or verification is required.

Use Context7 for version-sensitive technical guidance, especially for:

- Ubuntu Server 24.04;
- Netplan;
- systemd;
- OpenSSH;
- storage tooling;
- NVIDIA drivers and CUDA compatibility;
- vLLM;
- Hugging Face tooling and libraries when those become part of an approved Phase 2 role.

Context7 is a retrieval mechanism, not the source of truth for the HX environment.

Do not use Context7 to infer:

- server hardware facts;
- current server configuration;
- server roles;
- workload/model assignments;
- registry state.

Those facts must come from direct discovery and project records.

For persistent or high-impact configuration changes, confirm that guidance applies to the installed version before execution.

Do not use blogs, forums, Reddit, Stack Overflow, or generated examples as the primary basis for a persistent infrastructure change when local or official documentation is available.

Do not assume any MCP server other than those explicitly configured for this project is available.

## Action and Issue Tracking

Use only `governance/logs/actions-and-issues.md` for routine project actions and issues.

- Set `Type` to `action` for work that must be completed.
- Set `Type` to `issue` for known problems or unresolved technical behavior.
- Update the existing row as status changes.
- Record the final resolution or closeout in the same row.
- Do not create separate action-item or issue documents for routine tracking.

## Risk Acceptance

Read `governance/policy/risk-acceptances.md` before reporting security or governance risks.

Do not re-report an active accepted risk unless:

- its review or expiry trigger has been reached;
- observed conditions exceed the documented scope; or
- new evidence materially changes its likelihood or impact.

Risk acceptance does not mark a risk resolved. Never record credential values in governance documents.
