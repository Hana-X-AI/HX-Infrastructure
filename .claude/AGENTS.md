# claude automation contract

## purpose

Define local rules for Claude Code automation assets used by HX-Infrastructure.

## ownership

This contract owns work under:

```text
.claude/
├── agents/
├── hooks/
├── skills/
└── settings.json
```

It also governs synchronization between active hook files and the distributable hook package.

## local contracts

Before changing Claude automation, also read:

- `../CLAUDE.md`
- `../GOALS-AND-OBJECTIVES.md`
- `../INFRASTRUCTURE-CONTRACT.md`
- `../SERVER-REGISTRY.md`
- `../governance/risk-acceptances.md`

Automation must preserve these boundaries:

- Phase 1 automation may discover and document but may not assign roles, workloads, or models.
- Phase 1 automation may not perform persistent role-specific configuration.
- Phase 2 release state must follow the lifecycle vocabulary defined by `SERVER-REGISTRY.md`.
- hooks are deterministic guardrails, not a substitute for authoritative project state.
- skills implement repeatable workflows; hooks should not contain complex knowledge workflows.
- missing or malformed hook input must not silently create a fail-open path for a protected operation.

Active and packaged hook copies must remain synchronized.

Current packaged hook location:

```text
../claude-hooks/claude-hooks/hooks/
```

## work guidance

- Prefer the smallest change that corrects the identified automation behavior.
- Do not infer undocumented Claude Code hook payload semantics; verify live behavior when the change depends on it.
- Preserve read-only discovery commands during Phase 1.
- Keep destructive/mutating command patterns narrowly targeted enough that inspection commands remain usable.
- When changing a hook, update its packaged copy in the same change.
- When changing lifecycle behavior, add focused regression coverage.
- Do not add automatic permission approval for destructive or persistent infrastructure operations.
- Do not expose `.env` values through scripts, tests, logging, fixtures, or error output.

## verification

For automation changes, run the applicable checks:

- PowerShell syntax/parse validation for `.ps1` hooks;
- JSON parsing for `.claude/settings.json`;
- shell syntax validation for discovery scripts;
- `tests/remediation-tests.ps1` when affected;
- direct representative hook invocation when useful;
- active/package hook comparison after hook changes.

A regression suite is considered passing only if it completes and reports its result.

## child dox index

No child `AGENTS.md` files are required under `.claude/` at this time.

The existing `agents/`, `hooks/`, and `skills/` directories remain governed by this contract.
