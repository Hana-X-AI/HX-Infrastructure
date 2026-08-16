# HX Claude Meta-Agent Enforcement — Implementation Prompt

**Status:** OWNER-APPROVED IMPLEMENTATION CHARTER
**Prepared for:** Claude Code
**Owner:** Agent Zero / Jarvis Richardson
**Scope:** HX-Infrastructure Meta-Agent enforcement and governed OmniRoute delegation
**Operating rule:** Inspect first, implement second, prove every control, stop at the owner synchronization gate.

---

## Prompt to Claude Code

You are implementing the HX Meta-Agent compliance control plane. The desired behavior is not merely advisory. The architecture must be enforced through the strongest Claude Code mechanisms available in the installed version, with prompts used for meaning and runtime controls used for prohibition.

Do not begin by editing files. Complete Phase 0 and present the preflight result before making changes. Do not deploy, configure servers, or perform unrelated repository remediation.

### 1. Owner-approved authority model

The authority order is:

1. Agent Zero / Jarvis Richardson's current explicit instruction and ratified owner decisions.
2. Canonical HX governance, constitutions, policies, registries, contracts and accepted decisions.
3. Current repository and as-built evidence.
4. Approved architecture and agent capability definitions.
5. Independently produced validation evidence.
6. Agent reports and generated artifacts.
7. Historical material and unverified proposals.

Lower authority may inform but may not override higher authority. No agent may approve its own architectural authority, adoption decision, deployment authorization, exception or risk acceptance.

### 2. Required topology

Implement this federated three-tier topology:

- **Tier 1 — Claude Code / Claude:** owner interface, intent normalization, authority checks, routing, synchronization and final reporting.
- **Tier 2 — Max:** dedicated OmniRoute primary coordinator, sole task dispatcher and sole integration coordinator for OmniRoute.
- **Tier 2 council:** nine persistent domain stewards advise and review within their domains; they do not independently dispatch Tier-3 OmniRoute agents unless a later owner decision explicitly grants that authority.
- **Tier 3 — ephemeral task cells:** bounded reconnaissance, reproduction, implementation, adversarial review, proof and knowledge-capture agents. They are non-recursive.

Claude must not dispatch Tier-3 OmniRoute task cells directly. Max must not delegate integration authority. Tier-3 agents must not possess the native `Agent` tool or its legacy `Task` alias.

Prefer running Max as a dedicated main-session agent using `claude --agent max`. This allows Max's `tools` frontmatter to use a native `Agent(<approved-types>)` allowlist. Do not implement Max as an ordinary nested subagent unless Phase 0 proves a dedicated main-agent handoff is infeasible and the owner approves an alternative. The type allowlist inside `Agent(...)` is ignored when the definition itself runs as a subagent, so prompt text cannot close that gap.

### 3. Mandatory Knowledge Base Review

Apply this directive to Claude, Max, every steward and every Tier-3 agent:

> **Knowledge Base Review (mandatory pre-task step)**
>
> Before executing any task, you must review the knowledge base located in your assigned operations directory. Each agent's operations directory contains the unzipped source repository for its system.
>
> Base path: `C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\governance\operations\<AgentName>\<repo-release-folder>`
>
> Example (OmniRoute): `C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\governance\operations\OmniRoute\OmniRoute-release-v3.8.50`
>
> When a task depends on information outside the assigned operations directory, review the relevant shared-library or operations directory before proceeding rather than assuming or inventing details.
>
> No task execution begins until this review is complete.

This is both an instruction and an enforced gate. An agent assertion is not proof of review.

### 4. Phase 0 — read-only preflight

Before editing anything:

1. Read the repository's root `CLAUDE.md`, applicable nested `CLAUDE.md` and `AGENTS.md` files, `.specify/memory/constitution.md`, `knowledge/instructions.md`, current governance policies, current agent roster, operations directories, actions/issues logs and architecture decisions.
2. Review the complete OmniRoute operations knowledge base and every other operations directory materially implicated by the implementation.
3. Locate existing agent definitions, hooks, settings, launch scripts, schemas, tests and prior Meta-Agent documents.
4. Determine the installed Claude Code version and compare it with the current official documentation for subagents, hooks, permissions, settings and Agent SDK behavior.
5. Inventory all currently loaded agent names and resolve duplicate-name or precedence conflicts. Do not invent missing steward or helper names.
6. Identify whether organization-managed settings are available. If available, prefer them for non-overridable controls. If unavailable, document the residual tamper risk and propose OS-protected user-level controls plus repository controls.
7. Record the current git branch, clean/dirty state, remote, relevant hashes and protected files. Preserve unrelated user work.
8. Produce a preflight matrix of proposed files: create, modify, leave untouched, or verification required.
9. Surface contradictions and stop for an owner ruling if any current canonical authority conflicts with this charter.

Do not claim a control is enforceable until you have verified that the installed Claude Code version supports it.

### 5. Canonical artifacts to implement

Use existing repository conventions when they differ from the proposed names below. Otherwise create a coherent structure equivalent to:

```text
CLAUDE.md
governance/policy/meta-agent-authority.md
governance/policy/agent-delegation-policy.yaml
governance/schemas/knowledge-review-receipt.schema.json
governance/schemas/agent-result-envelope.schema.json
governance/schemas/subagent-state-registry.schema.json
governance/operations/sessions/meta-agent/
.claude/agents/claude-tier1.md
.claude/agents/max.md
.claude/agents/<existing-approved-tier3-agents>.md
.claude/hooks/hx-policy-gate.ps1
.claude/hooks/hx-result-validator.ps1
.claude/settings.json
scripts/hx-launch-claude-tier1.ps1
scripts/hx-launch-max.ps1
tests/meta-agent-controls/
```

Do not create a second actions/issues system, decision log, memory store, checkpoint store or source of architectural truth.

### 6. `CLAUDE.md` responsibilities

Keep `CLAUDE.md` concise. It must:

- identify Claude as the Meta-Agent and Agent Zero as final human authority;
- point to the canonical Meta-Agent authority policy;
- state that Max is the sole OmniRoute dispatcher and integration coordinator;
- require the Knowledge Base Review before task execution;
- distinguish planning, reconnaissance, implementation, validation, adoption and deployment;
- forbid silent scope expansion and invented evidence;
- define hard stops and the owner synchronization gate;
- state explicitly that instructions do not override permissions, hooks, schemas or governance;
- avoid duplicating large policy bodies likely to drift.

### 6.1 Tier-1 entry point

Implement Claude's owner-facing role as a dedicated Tier-1 agent/session entry point. Its agent definition must use an explicit `tools` allowlist that omits `Agent` and the legacy `Task` alias, and must declare both as disallowed when the installed version supports that defense in depth. Tier 1 may normalize intent, check authority, create the bounded task charter and synchronize with the owner, but it must hand OmniRoute dispatch to the dedicated Max main session.

No session except the verified dedicated Max main session may receive `Agent(<exact-approved-tier3-types>)` or another Tier-3 dispatch capability. The Tier-1 launcher must verify the repository, policy and agent-definition identity before startup. Do not rely on `Agent(type)` restrictions declared in a context where the installed Claude Code version does not enforce them.

### 7. Max agent definition

Implement Max as a project-scoped agent definition and a dedicated main-session launch path.

Requirements:

- `name: max`
- a description that makes Max the OmniRoute dispatcher and integrator, not a universal implementer;
- an explicit `tools` allowlist rather than inherited tools;
- native `Agent(<exact-approved-tier3-types>)` syntax only when Max is launched as the main agent;
- `permissionMode: dontAsk` unless a stricter verified mode is available, paired with explicit allow rules; never use `bypassPermissions`;
- bounded `maxTurns` and explicit model/effort selected from available approved models;
- no uncontrolled MCP inheritance;
- worktree requirements for implementation cells;
- the mandatory Knowledge Base Review directive;
- task packet, result-envelope, retry and escalation rules;
- no authority to approve adoption, deployment, exceptions or risk acceptance;
- no direct broad implementation when an atomic task cell is the correct executor.

The launch wrapper must verify repository identity, branch policy, settings/policy hashes and agent definition before invoking `claude --agent max`.

### 8. Tier-3 agent definitions

Use the approved existing names from the repository. Do not replace human names with functional aliases unless the owner approves it. Each Tier-3 definition must:

- contain only the tools required for its atomic responsibility;
- omit `Agent` and `Task` completely;
- include `disallowedTools: Agent, Task` when supported as defense in depth;
- use `permissionMode: dontAsk` with narrow pre-approved tools, or `plan` for read-only agents;
- set a bounded `maxTurns`;
- use `isolation: worktree` for code-writing agents;
- prohibit integration, deployment, governance mutation and agent-definition mutation;
- include the Knowledge Base Review directive and receipt requirement;
- return the canonical result envelope;
- stop on scope, authority, permission, evidence or knowledge-base failure.

Do not allow an implementing agent to serve as its own independent reviewer or proof agent.

### 9. Delegation policy

Create one machine-readable policy mapping:

- caller identity;
- permitted child agent types;
- task modes;
- allowed/protected paths;
- required operations directory;
- required receipt scope;
- allowed tools and commands;
- worktree requirement;
- maximum turns;
- concurrency class;
- retry classes;
- required independent reviewer;
- required acceptance evidence;
- next authority.

Default deny. Unknown callers, child types, paths, modes or commands fail closed.

### 10. Knowledge-review receipt

The canonical contract is `governance/schemas/knowledge-review-receipt.schema.json`, version `hx-knowledge-review-receipt/v1`. The receipt must be task- and run-specific and include at least:

```json
{
  "schema_version": "hx-knowledge-review-receipt/v1",
  "task_id": "OMNI-YYYYMMDD-NNN",
  "run_id": "uuid",
  "agent": "max",
  "operations_root": "absolute canonical path",
  "repository_identity": {
    "path": "absolute canonical path",
    "release_or_commit": "verified value"
  },
  "sources_reviewed": [
    {"path": "relative path", "sha256": "hex", "purpose": "why required"}
  ],
  "external_sources_reviewed": [],
  "review_completed_at": "ISO-8601 timestamp",
  "max_age_seconds": 3600,
  "review_completed": true
}
```

The validator must parse `review_completed_at` as an ISO-8601 timestamp with an offset and compare it with current UTC time. It must reject an unparseable or future timestamp and reject a receipt when its age exceeds the canonical 3600-second maximum. The receipt may not select a different maximum. The validator must also canonicalize paths, reject traversal, reject missing/unreadable sources, reject mismatched hashes, reject a receipt from another task/run/agent and reject an empty evidence list. Store receipts in the approved task-session evidence directory, not inside the source knowledge repository.

### 11. Enforcement hooks

Implement deterministic hooks with PowerShell 7-compatible scripts because the authoritative workstation paths are Windows paths. If the current environment also requires Bash/WSL support, add a separately tested wrapper without weakening the Windows control.

At minimum:

1. **PreToolUse policy gate**
   - On malformed input or internal validation error, deliberately return a valid deny response or exit 2.
   - For mutation, shell, network, MCP, Agent, commit or integration tools, require a valid current knowledge-review receipt.
   - Enforce caller, tool, target path, command class, task mode and worktree policy.
   - Deny direct Tier-3 dispatch outside the Max primary session.
   - Deny unknown agent types.
   - Deny changes to protected governance, agent, hook and settings files except in a separately authorized control-plane maintenance task.
   - Never auto-approve destructive, credential, deployment or external-publication actions.

2. **PostToolUse evidence logger**
   - Record normalized evidence references, not uncontrolled transcripts.
   - Redact secrets and avoid copying source repositories into the state registry.

3. **SubagentStart audit/context hook**
   - Record `agent_id` and `agent_type` and inject the task ID, scope and receipt requirement.
   - Do not treat this event as a blocking gate; official behavior permits context injection but not blocking.

4. **SubagentStop/result validation hook**
   - Validate the result envelope.
   - Block completion and return a correction request when required fields or evidence are absent.
   - Do not allow narrative confidence to substitute for validation results.

5. **ConfigChange audit/block hook**
   - Reject unauthorized runtime settings changes.

Use exact official hook input and output schemas for the installed version. Do not infer undocumented fields.

**Critical hook limitation:** ordinary command, HTTP and MCP-tool hooks do not fail closed when the hook cannot start, emits invalid output, returns an ordinary nonzero code, loses its connection or times out. The tool continues through normal permission handling. Only an Agent SDK callback hook is documented to block a PreToolUse call on timeout. Therefore:

- never make a command/HTTP hook the sole control for a critical prohibition;
- back every critical hook decision with a static deny/allow boundary, managed policy, tool deprivation or launcher boundary;
- use exit code 2 for a command-hook denial when structured output cannot be produced;
- use only valid JSON on stdout when structured decisions are used;
- consider an Agent SDK callback control plane if dynamic fail-closed behavior is mandatory; and
- test missing-script, invalid-JSON, exit-1, exit-2, connection-failure and timeout behavior explicitly.

### 12. Settings and runtime limits

Configure and verify:

- `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` inside the dedicated Max main session so Max may spawn one subagent layer and those agents may not spawn again;
- a deliberately small `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`, chosen from demonstrated workload needs rather than the default of 20;
- `permissions.disableBypassPermissionsMode: "disable"`;
- disable Auto mode if it conflicts with deterministic HX authorization;
- deny unapproved agents, tools, MCP servers and protected paths;
- use managed settings when available for controls that must not be overridden;
- never rely on a per-subagent token field that Claude Code does not support;
- use `maxTurns`, model/effort choice, concurrency/depth bounds and whole-query spend controls where available.

If managed settings are available, evaluate `allowManagedHooksOnly`, `allowManagedPermissionRulesOnly`, `disableSideloadFlags`, strict customization controls and fail-closed remote settings. Do not enable any option until its effect on approved HX project agents and skills is understood and tested.

### 13. Result envelope

Every delegated task must return an envelope that validates against `governance/schemas/agent-result-envelope.schema.json`, version `hx-agent-result/v1`. This schema is the only structural contract for `scope_observed`, validation commands and results, independent review, `retry_reason`, and the `error.class` taxonomy. Producers and validators must consume the canonical schema instead of maintaining inline variants.

Runtime validation must also reject `validation.independent_reviewer` when it equals `agent` and must corroborate `scope_observed` against external evidence. JSON Schema cannot compare sibling values or prove observed scope; the schema's `$comment` records these mandatory validator rules.

An output with status `completed` is invalid unless required evidence and independent review are present.

### 14. Retry policy

- Maximum one retry for a demonstrated transient failure, output-format failure or narrowly bounded syntax defect.
- Zero automatic retries for knowledge, permission, security, authority, scope or evidence failures.
- Zero retry when a native concurrency error explicitly instructs Claude not to retry.
- Every retry gets a new `run_id`, preserves the original evidence and records the classified recoverable failure in `retry_reason`; `error` describes only the terminal error for the current run.
- After the permitted retry fails, the terminal `error` records `retryable: false`; Max stops and escalates through Claude to Agent Zero.
- Never guess missing data to make a failed task appear complete.

### 15. State registry

Maintain a task-scoped, append-only transition registry containing only:

- task and run IDs;
- agent identity;
- source identities;
- state transition and timestamp;
- input evidence references;
- output evidence references and hashes;
- validation status;
- retry count;
- reviewer;
- next authority.

The registry is not the canonical task log, actions/issues log, architecture decision record, source repository, Mem0 memory store, LoopX ledger or LangGraph checkpoint store. Retain governed raw evidence separately; compact active context by referencing it rather than deleting it.

### 16. Tamper boundary

Do not claim full enforcement if the executing agent can modify its own hooks, policies or settings.

Use this preference order:

1. Organization-managed settings and hooks that project/user configuration cannot override.
2. OS-protected user-level control files and a dedicated launcher that verifies their hashes.
3. Repository-tracked hooks/settings plus protected-path denials and hash verification, explicitly labeled as a weaker pilot boundary.

Document exactly which boundary is achieved. A repository-only pilot may prove behavior but not establish non-bypassable governance.

### 17. Required adversarial tests

Build deterministic tests proving at least:

1. The dedicated Tier-1 entry point has no usable `Agent` or legacy `Task` tool, and a direct attempt to dispatch every approved OmniRoute Tier-3 type is denied. A policy backstop must also deny the same calls outside the verified dedicated Max main session.
2. Max can dispatch every approved Tier-3 type.
3. Max cannot dispatch an unapproved or built-in catch-all agent.
4. Tier-3 agents cannot access `Agent` or legacy `Task`.
5. A missing, stale, forged, cross-task or empty knowledge receipt blocks execution.
6. Path traversal, symlink/junction escape and case-normalization tricks are rejected.
7. A read-only agent cannot write through Bash or PowerShell.
8. An implementation agent cannot write outside its worktree or assigned paths.
9. An agent cannot alter protected policies, hooks, settings or agent definitions.
10. Malformed hook input causes an explicit deny when the hook executes; its static permission backstop still blocks the action when the hook cannot execute.
11. Missing hook, invalid output, ordinary failure and timeout cannot bypass a critical control because a static/managed boundary blocks the action; if an SDK callback is used, confirm its documented timeout denial.
12. `completed` without required validation is rejected.
13. Runtime validation rejects an implementer that self-certifies independent review.
14. Permission, security, authority, scope, knowledge and evidence failures are not retried.
15. A transient/format retry occurs at most once with a new run ID. A successful retry validates with `status: completed`, `error: null`, `retry_count: 1` and a classified `retry_reason`; a failed final retry validates only with `error.retryable: false`.
16. Concurrency and depth limits behave as configured.
17. Worktree isolation protects the main checkout.
18. Configuration changes are audited and unauthorized changes are blocked.
19. Built-in Explore, Plan, general-purpose and `claude` agents cannot create an unintended dispatch path.
20. The launcher refuses a wrong repository, wrong branch condition, failed policy hash or unavailable required operations knowledge base.

Include negative tests. A PASS means the prohibited action was actually attempted and deterministically denied, not merely that an agent promised not to attempt it.

### 18. Rollout gates

Implement in this order:

1. Baseline and contradiction report.
2. Canonical policy and schemas.
3. Read-only audit logging.
4. Knowledge receipt validator.
5. Max dedicated launch path and allowlisted Agent types.
6. Non-recursive Tier-3 definitions.
7. PreToolUse and result gates with static deny backstops or an SDK callback boundary for every critical prohibition.
8. Adversarial test suite.
9. Bounded dry-run pilot with no source mutation.
10. Bounded worktree mutation pilot.
11. Owner review and acceptance decision.

Do not activate enforcement globally before the tests demonstrate that valid work remains possible and prohibited work is blocked.

### 19. Required handoff

Return:

- executive outcome;
- exact files created or changed;
- current and resulting architecture;
- authority and source review receipt;
- installed Claude Code version and verified feature matrix;
- tests run, exact commands and complete pass/fail counts;
- negative-control evidence;
- known residual bypass paths;
- rollback procedure;
- deferred items;
- owner decisions required;
- proposed next step.

Do not declare the control plane `ENFORCED` until all critical negative tests pass, every dynamic critical rule has a non-hook static backstop or verified SDK fail-closed boundary, and the control files are outside the ordinary agent write boundary. Use `PILOT-ENFORCED` for repository-only enforcement and `DESIGNED` when controls have not been exercised.

Stop at the owner synchronization gate. Do not proceed to deployment, broad rollout or unrelated remediation without Agent Zero's explicit authorization.

---

## Non-negotiable acceptance statement

The implementation is acceptable only when the architecture is true because the runtime makes violations unavailable or denies them—not because Claude, Max or another agent says it will comply.
