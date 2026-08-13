# hx-infrastructure agent routing contract

## purpose

- Route agent work to the authoritative HX-Infrastructure instructions without duplicating those instructions.
- Apply this file repo-wide unless a closer `AGENTS.md` adds more specific local guidance.
- A child `AGENTS.md` may specialize local work but must not weaken repository-wide governance.

## ownership

This root contract owns:

- repository-wide agent routing;
- global documentation discipline;
- the child contract index.

Authoritative project rules remain in:

- `CLAUDE.md`
- `GOALS-AND-OBJECTIVES.md`
- `INFRASTRUCTURE-CONTRACT.md`
- `SERVER-REGISTRY.md`
- `governance/policy/risk-acceptances.md`

Do not restate those documents here when a reference is sufficient.

## local contracts

Before editing:

1. read this file;
2. identify every path that may change;
3. read each applicable child `AGENTS.md` on the path to those files;
4. read the authoritative project documents relevant to the task;
5. use the closest `AGENTS.md` for local workflow details.

Repository-wide rules:

- Phase 1 is discovery and documentation only.
- Server role, workload, and model assignment are manual decisions.
- Phase 2 must not begin while the fleet-wide Phase 1 gate is blocked.
- `discovery.md` records as-found state and must not be rewritten as configured state.
- routine actions and issues belong in `governance/logs/actions-and-issues.md`.
- accepted risks are handled according to `governance/policy/risk-acceptances.md`.
- never copy credentials or private keys into tracked documentation.

## work guidance

- Keep changes minimal, factual, and scoped to the requested work.
- Prefer existing project files and workflows over new process documents.
- Do not create child `AGENTS.md` files unless a directory becomes a durable boundary with its own rules, responsibilities, or verification needs.
- Update an `AGENTS.md` only when the durable contract, ownership, workflow, or child index changes.
- Operational data changes alone do not require an `AGENTS.md` edit.
- Remove stale or contradictory guidance instead of documenting multiple competing rules.

## verification

Before completion:

- re-check every changed path against the applicable `AGENTS.md` chain;
- run existing verification relevant to the change;
- do not claim a test passed unless it completed successfully;
- verify that no secret material was introduced;
- report any contract file intentionally left unchanged when a task materially changes behavior.

## child dox index

- `.claude/AGENTS.md` — Claude Code skills, agents, hooks, settings, packaging, and automation verification.
- `governance/AGENTS.md` — action/issue tracking, risk acceptance, and review/report records.
- `servers/AGENTS.md` — server discovery and Phase 2 configuration records.

No other child `AGENTS.md` files are required at this time.
