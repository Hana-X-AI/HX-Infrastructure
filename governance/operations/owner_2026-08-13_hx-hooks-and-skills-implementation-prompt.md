# HX-Infrastructure — Implement the Approved Hooks and Skills Architecture

You are Claude Code operating inside the canonical local HX-Infrastructure repository.

## PURPOSE

This task operationalizes two related governance improvements that have already been researched, reviewed, and approved:

1. **The HX Claude Code hook layer**
2. **The HX-native agent skills layer**

The design and implementation guidance for both are located here:

```text
C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\governance\operations
```

Your job is **not to redesign these systems from scratch**.

Your job is to:

- inspect the approved material in `governance\operations`;
- inspect the current repository state;
- reconcile the approved design with what actually exists today;
- implement the hooks and skills in the repository's canonical locations;
- preserve current working mechanisms;
- validate the result end-to-end;
- document exactly what changed.

The overarching objective is to strengthen HX-Infrastructure's AI-native execution model without introducing a second control plane, duplicate framework, stale infrastructure state, or unnecessary complexity.

---

# 1. HOW TO USE THE MATERIAL IN `governance\operations`

Start from the repository root:

```powershell
cd C:\Users\JarvisRichardson\Desktop\HX-Infrastructure
```

Then inspect:

```text
governance\operations
```

Recursively inventory the directory before making changes.

The directory contains the approved design material for the hook architecture and agent-skills integration. It may contain:

- human-facing HTML implementation briefs;
- Claude Code execution prompts;
- hook package material;
- skill migration/adoption guidance;
- supporting reference files;
- prior design decisions.

Treat those documents as **implementation inputs**, not as proof that their described target state is already operational.

## Authority rule

If a document in `governance\operations` says that something should exist, but the current repository shows that it has not yet been implemented:

```text
operations document = TARGET-STATE / APPROVED DESIGN
repository = CURRENT STATE
```

Do not confuse the two.

If the current repository has evolved since an operations document was written, reconcile deliberately rather than overwriting newer valid work.

---

# 2. PRIMARY GOAL

When this task is complete, HX-Infrastructure should have:

### A. A small deterministic Claude Code hook enforcement layer

The hooks should enforce immediate high-confidence project invariants and validation requirements.

They should **not** become another workflow engine.

### B. HX-native reusable agent skills

The selected upstream agent-skill concepts should be transformed into capabilities that extend the existing HX Spec-Driven Development model.

They should **not** install another SDD framework or another skill-routing framework.

### C. One coherent governance hierarchy

The final architecture should remain:

```text
HX GOVERNANCE
      |
      v
sdd-core execution model
      |
      v
repository/context routing
      |
      v
HX skills + specialist agents
      |
      v
deterministic hooks
      |
      v
tests / validators / evidence
      |
      v
human review
```

There must be no competing hierarchy.

---

# 3. EXISTING HX AUTHORITIES

Before implementing anything, locate and read the current versions of the repository's authoritative files.

At minimum inspect:

```text
.specify/memory/constitution.md
knowledge/instructions.md
CLAUDE.md
AGENTS.md
GOALS-AND-OBJECTIVES.md
INFRASTRUCTURE-CONTRACT.md
SERVER-REGISTRY.md
```

where present.

Also inspect:

```text
.claude/
.specify/
knowledge/
governance/
servers/
scripts/
tests/
```

and any existing directories containing:

- skills;
- agents;
- commands;
- validators;
- lifecycle/state files;
- repository governance.

Do not infer authority purely from filenames. Determine the actual current authority chain from repository instructions and cross-references.

---

# 4. NON-NEGOTIABLE HX CONSTRAINTS

The following decisions are already settled.

Do not reopen them during this task.

## 4.1 `sdd-core` remains the execution backbone

HX-Infrastructure already uses its own Spec-Driven Development model.

In particular:

```text
.specify/memory/constitution.md
```

provides global governance, while:

```text
knowledge/instructions.md
```

provides local repository/context routing.

Do not introduce a second SDD framework.

Do not replace this structure with assumptions inherited from another agent-skills repository.

---

## 4.2 Ansible is permanently out of scope

Ansible must not appear as:

- an orchestration recommendation;
- a future implementation path;
- an agent workflow;
- a skill workflow;
- an example command;
- a fallback;
- a "cleaner alternative";
- a planned dependency.

Stale Ansible references encountered in the touched implementation scope should be deliberately removed or corrected.

The validated HX fleet-control baseline is native Bash/SSH orchestration from the control plane.

---

## 4.3 Native fleet control remains authoritative

The established HX pattern is:

```text
hxs-cp
  |
  +-- SSH user: hxsa
  |
  +-- explicit server/IP mapping
  |
  +-- SCP script to /tmp
  |
  +-- remote execution using passwordless sudo
  |
  +-- host / fleet / verify modes
```

Do not silently replace this mechanism with another infrastructure orchestrator.

Skills may improve its planning, validation, documentation, testing, and reliability.

They must not replace the model without a separate explicit architecture decision.

---

## 4.4 Truth-state separation is mandatory

Preserve explicit distinctions among:

```text
TARGET-STATE
AS-BUILT
DISCOVERED
PROPOSED
LEGACY / HISTORICAL
```

A well-written design document is not evidence that something is installed.

A legacy configuration is not evidence of current state.

A planned host assignment is not a discovered host fact.

Runtime/current-state claims require current authoritative evidence.

---

## 4.5 Keep deferred rabbit holes deferred

Do not expand this task into:

- comprehensive security hardening;
- detailed MCP exposure policy;
- production-grade observability architecture;
- broad performance tuning;
- unrelated infrastructure implementation.

Those are separate workstreams.

The purpose here is to operationalize hooks and skills.

---

# 5. PREFLIGHT — DO THIS BEFORE MODIFYING FILES

Before making any repository change:

1. inventory `governance\operations`;
2. identify the hook implementation brief;
3. identify the hook execution prompt/reference material;
4. identify the skills adoption/migration brief;
5. identify the skills execution prompt/reference material;
6. inspect the current `.claude` configuration;
7. inspect current skill and agent structures;
8. inspect tests and validators;
9. inspect current Git status and branch;
10. identify any uncommitted work;
11. identify any discrepancies between the approved operations material and current repository state.

Produce a concise internal reconciliation table before editing:

```text
AREA
Approved target
Current repository state
Gap
Implementation action
```

Do not stop merely because the target and current repository differ.

Reconcile them intelligently.

---

# 6. PART A — IMPLEMENT THE APPROVED HOOK ARCHITECTURE

The existing HX hook package already has a working foundation.

Preserve the current behaviors unless current repository evidence shows they were intentionally superseded.

## Existing behaviors to preserve

### `hx-session-state.ps1`

Event:

```text
SessionStart
```

Purpose:

- inject concise current HX phase state;
- inject relevant registry counts/status;
- give Claude a dynamic dashboard.

Do not turn this into a massive context injector.

Do not inject every skill or governance file at session startup.

---

### `hx-phase1-guard.ps1`

Event:

```text
PreToolUse
```

Purpose:

- enforce the Phase 1 → Phase 2 boundary;
- prohibit role-specific or persistent infrastructure mutation while Phase 2 is still blocked.

Keep this hook **phase-specific**.

Do not overload it with rules that are permanent in all phases.

---

### `hx-validate-discovery.ps1`

Event:

```text
PostToolUse
```

Purpose:

- validate discovery records;
- validate `SERVER-REGISTRY.md`;
- give Claude immediate deterministic feedback after edits.

Preserve all existing working validation.

Extend it as described below.

---

### `hx-validate-subagent.ps1`

Event:

```text
SubagentStop
```

Purpose:

- enforce the completion contract for `server-discovery`;
- prevent a discovery agent from declaring completion without a valid completed discovery artifact.

Preserve this pattern.

---

### `hx-notify.ps1`

Event:

```text
Notification
```

Purpose:

- notify the human operator when Claude is idle or a background agent needs input;
- avoid notification storms.

Preserve asynchronous Windows behavior and the existing decision not to create alerts for every permission prompt.

---

# 7. ADD THREE PERMANENT HOOK CONTROLS

Add exactly these three permanent behaviors unless the current repository already contains an equivalent mechanism.

If an equivalent already exists, consolidate rather than duplicate.

---

## 7.1 `hx-permanent-policy-guard.ps1`

### Purpose

Enforce architectural prohibitions that remain true regardless of project phase.

### Event

Use:

```text
PreToolUse
```

for shell execution tools used by the current local Claude configuration.

Verify exact matcher names from the current installation rather than assuming them.

### Initial required permanent prohibition

Block:

```text
ansible
ansible-playbook
ansible-galaxy
```

in every phase.

The denial message should be concise and actionable:

```text
DENIED: Ansible is outside the HX-Infrastructure architecture.
Use the approved native Bash/SSH fleet-control model.
```

### Important constraints

Do not turn this into:

- a generic shell allowlist;
- another Phase 1 guard;
- duplicate storage-protection logic;
- a large regex collection of hypothetical dangers.

The permanent policy guard should contain only genuinely permanent deterministic project rules.

---

# 8. `hx-authority-edit-guard.ps1`

### Purpose

Protect repository files capable of changing HX governance or Claude's own control plane.

### Event

```text
PreToolUse
```

for:

```text
Write
Edit
```

or the current equivalent tool names.

### Protected classes

Determine the definitive current list from repository authority.

Likely candidates include:

```text
.specify/memory/constitution.md
knowledge/instructions.md
CLAUDE.md
AGENTS.md
GOALS-AND-OBJECTIVES.md
INFRASTRUCTURE-CONTRACT.md
.claude/settings.json
critical hook scripts
critical validation/control scripts
```

Handle:

```text
SERVER-REGISTRY.md
```

carefully.

It is authoritative operational data, but there may already be an approved `server-discovery` / registry synchronization workflow that legitimately updates it.

Do not break that workflow.

### Decision semantics

For a main/coordinating session:

```text
protected authority edit -> ASK
```

The owner should explicitly approve governance/control-plane changes.

For a specialist/subagent:

```text
protected authority edit -> DENY
```

unless a very narrow existing approved workflow proves an exception is required.

Ordinary files:

```text
DEFER / NO OPINION
```

### Architectural principle

A specialist may say:

```text
"INFRASTRUCTURE-CONTRACT.md appears inconsistent with current evidence."
```

It should not silently rewrite the contract.

The coordinating layer owns reconciliation.

---

# 9. `hx-config-integrity.ps1`

### Purpose

Provide a secondary control ensuring Claude's project configuration has not been weakened.

### Event

Use:

```text
ConfigChange
```

with the appropriate current project-settings matcher.

Verify current Claude Code event semantics before implementing.

### Validate at least

The current project settings must retain:

- required HX hook registrations;
- required permanent policy hook;
- authority edit protection;
- required existing hook behaviors;
- critical permission controls;
- structurally valid hook definitions.

If an invalid configuration change occurs:

- reject/block it from becoming active where the Claude Code event permits;
- provide concise diagnostic evidence;
- record enough context to troubleshoot the change.

### Important limitation

This hook is a **backstop**.

It is not the only protection for:

```text
.claude/settings.json
```

The authority edit guard should intercept the attempted edit first.

Do not claim that `ConfigChange` automatically restores old file bytes unless the current Claude Code behavior explicitly proves that.

---

# 10. EXTEND DISCOVERY VALIDATION — DO NOT CREATE ANOTHER HOOK EVENT

Extend:

```text
hx-validate-discovery.ps1
```

with registry-driven identity validation.

The goal is to validate factual consistency without introducing a second hardcoded infrastructure inventory.

Use:

```text
SERVER-REGISTRY.md
```

and whichever current network authority the repository defines as the source data.

Compare relevant fields against:

```text
servers/*/discovery.md
```

where applicable.

Validate things such as:

```text
duplicate current IP
duplicate hostname/FQDN where uniqueness is expected
server identity mismatch
registry vs discovery IP mismatch
registry vs discovery hostname mismatch
invalid presentation of known legacy addressing as current
```

Error output should identify:

```text
server
field
expected
actual
source
```

## Critical prohibition

Do not create another static array like:

```text
hxs-1 = 192.168...
hxs-2 = 192.168...
...
```

inside the validator.

The validator should consume authoritative inventory.

It should not become inventory.

---

# 11. PRESERVE EXISTING PERMISSION CONTROLS

Inspect current:

```text
.claude/settings.json
```

and existing permission deny rules.

The existing hook package documentation indicates that irreversible storage commands already have phase-independent permission restrictions.

Preserve current valid rules unless an explicit current repository authority says otherwise.

Do not migrate those rules into the new permanent policy hook simply for symmetry.

Use the strongest existing deterministic mechanism for each rule.

---

# 12. UPDATE HOOK INSTALLATION / SETTINGS INTEGRATION

Where the current repository still uses an installer/package workflow, update it rather than bypassing it.

Likely files include equivalents of:

```text
apply-hooks.ps1
settings.fragment.json
README.md
```

Verify actual current locations.

Required properties:

- existing unrelated settings survive;
- unrelated hooks survive;
- HX hooks do not duplicate on repeated installation;
- backup behavior survives;
- non-hook settings survive;
- permission rules survive;
- new hooks are installed into the canonical `.claude/hooks` location;
- repeated application is idempotent.

The intended hook topology should become approximately:

```text
SessionStart
  -> hx-session-state.ps1

PreToolUse shell
  -> hx-phase1-guard.ps1
  -> hx-permanent-policy-guard.ps1

PreToolUse Write/Edit
  -> hx-phase1-guard.ps1 where applicable
  -> hx-authority-edit-guard.ps1

PostToolUse Write/Edit
  -> hx-validate-discovery.ps1

SubagentStop server-discovery
  -> hx-validate-subagent.ps1

Notification
  -> hx-notify.ps1

ConfigChange project settings
  -> hx-config-integrity.ps1
```

Do not rely on handler ordering for correctness.

Each relevant hook must remain independently safe.

---

# 13. PART B — IMPLEMENT THE APPROVED HX-NATIVE SKILLS

The second half of this task is to implement the agent-skills migration material in:

```text
governance\operations
```

The upstream `addyosmani/agent-skills` repository was reviewed as a **source library**, not as a framework to install wholesale.

That distinction is mandatory.

---

# 14. DO NOT IMPORT THE UPSTREAM SKILL FRAMEWORK WHOLESALE

Do not copy all upstream skills into HX.

Do not adopt:

```text
using-agent-skills
```

as a top-level router.

Do not import:

```text
spec-driven-development
```

as another SDD lifecycle.

Do not introduce upstream assumptions such as:

```text
tasks/plan.md
tasks/todo.md
```

unless they already match HX's canonical structure.

Do not introduce another:

- lifecycle;
- constitution;
- router;
- task-state system;
- execution framework.

Mine the useful mechanisms and transform them into HX-native capabilities.

---

# 15. TARGET HX SKILL CAPABILITIES

Implement the following six capabilities.

Before creating new directories, inspect the repository for existing skills or instructions that already provide some of them.

Prefer:

```text
improve / consolidate
```

over:

```text
duplicate
```

---

## 15.1 HX Context Engineering

### Purpose

Teach agents how to navigate authoritative HX context without indiscriminately loading the repository.

The conceptual order should be:

```text
constitution
    ->
repository/context router
    ->
current task/spec
    ->
relevant service/server/project sources
    ->
runtime/discovery evidence
```

The skill should teach:

- authority resolution;
- relevance filtering;
- progressive context loading;
- avoidance of stale cross-environment state;
- explicit handling of conflicting sources;
- when runtime evidence outranks documentation.

Do not make the skill itself a second context router.

It should explain how to use the existing HX router.

---

# 16. HX Source-Driven Research

### Purpose

Formalize the HX principle:

```text
Do not guess unstable infrastructure/tooling facts.
```

For matters such as:

- vLLM;
- CUDA;
- NVIDIA drivers;
- Qwen;
- Docker;
- kernel features;
- networking;
- storage;
- APIs;
- rapidly changing software;

the skill should require:

1. determine the actual relevant version/environment;
2. prefer authoritative primary documentation;
3. distinguish source evidence from inference;
4. record meaningful source/version/date information;
5. state uncertainty explicitly;
6. avoid converting general upstream documentation into claims about the HX environment without evidence.

Keep this lightweight.

Do not implement WebFetch caching as part of this task unless the approved operations documentation explicitly makes it required.

---

# 17. HX Adversarial Validation

### Purpose

Formalize the independent-review workflow already used successfully during HX planning.

The workflow should resemble:

```text
CLAIM
  ->
EXTRACT EVIDENCE
  ->
CHALLENGE / DOUBT
  ->
RECONCILE
  ->
STOP
```

Use independent reviewers only when the work can genuinely be separated.

A reviewer should:

- inspect evidence;
- identify contradictions;
- challenge unsupported assumptions;
- classify findings by materiality;
- provide bounded conclusions.

Review should stop when material doubts are resolved.

Do not create endless policy-review loops.

---

# 18. HX Planning & Gates

### Purpose

Improve infrastructure implementation planning without replacing `sdd-core`.

Retain useful concepts such as:

- dependency-first ordering;
- explicit entry criteria;
- explicit exit criteria;
- acceptance criteria;
- evidence requirements;
- rollback considerations;
- risk-first sequencing;
- small verifiable implementation slices.

For HX infrastructure, a useful implementation slice may be:

```text
one service
one server
one server role
one fleet-control capability
```

rather than a traditional software "vertical slice."

Do not impose upstream plan/task filenames where HX already has its own workflow.

---

# 19. HX Architecture Decisions & Authority

### Purpose

Help agents determine:

```text
what was decided
why it was decided
what authority it has
whether it is target-state or current-state
```

Support ADR-style records where appropriate.

The skill should reinforce explicit classifications:

```text
TARGET-STATE
AS-BUILT
DISCOVERED
PROPOSED
LEGACY / HISTORICAL
```

Historical rationale should be retained where valuable.

Historical state must not be treated as current configuration.

---

# 20. HX Legacy Migration

### Purpose

Support the ongoing consolidation of historical HX repositories and knowledge.

The core philosophy is:

```text
mine knowledge
transform useful content
preserve rationale
discard stale environment assumptions
```

Not:

```text
copy old repository into new repository
```

The skill should guide agents to classify legacy material approximately as:

```text
ADOPT
ADAPT
MINE-REFERENCE
DEFER
REJECT
```

For each migrated item, consider:

```text
source
capability/knowledge being retained
current authority conflict
target location
transformation required
validation method
provenance
```

Do not mechanically translate old IP addresses, paths, package versions, host assignments, or service state into current truth.

---

# 21. SKILL STRUCTURE

Follow the current HX repository's established skill format.

Do not assume upstream directory structure is correct for HX.

Where the current HX skill system follows conventional skill packaging, keep entrypoints lean.

Conceptually:

```text
skill/
  SKILL.md
  references/
  scripts/
  assets/
```

but only create folders that materially improve the skill.

Keep `SKILL.md` concise enough to function as a control plane.

Move large technical/domain material into references where appropriate.

Do not duplicate information that already belongs to:

```text
constitution
knowledge/instructions.md
infrastructure contracts
server registry
```

Skills should reference authority.

They should not clone it.

---

# 22. SPECIALIST AGENT MODEL

While implementing the skills, reconcile them with the current HX specialist-agent architecture.

Preserve this principle:

```text
skills = HOW
agents = WHO
coordinating session/workflow = WHEN + SYNTHESIS
hooks = DETERMINISTIC ENFORCEMENT
```

Specialist agents should have real domain responsibility.

Examples may include:

```text
network
storage
GPU/compute
platform/services
documentation/authority
validation
```

Do not create a persona whose primary role is merely:

```text
decide which other persona to call
```

Specialists must not recursively build their own orchestration hierarchies.

Prefer:

```text
coordinator
  +-> specialist A
  +-> specialist B
  +-> specialist C

specialists return evidence

coordinator reconciles
```

Parallel execution is appropriate only for genuinely independent work.

---

# 23. SKILL PROVENANCE

The source repository used during design was MIT licensed.

If implementation substantially copies upstream text, code, templates, or other copyrightable material:

- retain required MIT attribution;
- record source provenance;
- distinguish transformed HX-native material from original upstream material.

Do not add unnecessary attribution to concepts or ideas that were independently rewritten and are not substantial copies.

Use repository conventions for third-party notices if they already exist.

---

# 24. HOOKS AND SKILLS MUST COMPLEMENT EACH OTHER

This is one of the most important acceptance conditions.

Example:

### Governance says

```text
Ansible is not part of HX.
```

### Skill says

```text
Use the approved Bash/SSH fleet-control workflow.
```

### Hook says

```text
ansible-playbook -> DENIED
```

That is correct layering.

Another example:

### Governance says

```text
SERVER-REGISTRY.md is authoritative.
```

### Skill says

```text
Resolve current server identity from authoritative inventory.
```

### Hook/validator says

```text
discovery identity != registry identity -> VALIDATION FAILURE
```

Correct.

Do not repeat full governance policy in every layer.

---

# 25. DO NOT IMPLEMENT THESE AS PART OF THIS TASK

Explicitly exclude:

- wholesale import of the 24 upstream skills;
- `using-agent-skills` meta-router;
- second SDD lifecycle;
- Ansible;
- WebFetch research cache unless already explicitly approved as required;
- generic tool-failure ledger;
- broad secret-scanning hook;
- file-placement-police hook;
- giant SessionStart knowledge injection;
- router-only agents;
- recursive specialist orchestration;
- observability implementation;
- detailed MCP controls;
- broad security-hardening project;
- unrelated server/service installation.

Keep scope bounded.

---

# 26. TESTING REQUIREMENTS — HOOKS

Use the repository's existing test conventions.

Do not create a second test framework.

At minimum verify:

## Permanent policy

```text
Phase 1 + ansible -> DENY
Phase 2 + ansible -> DENY
benign shell command -> not denied by permanent guard
```

## Phase guard regression

Existing Phase-1-prohibited operations remain blocked while Phase 2 is blocked.

Operations that are *only* Phase-1-prohibited should no longer be blocked by the phase guard when Phase 2 is legitimately open.

Permanent prohibitions remain permanent.

## Authority guard

Main/coordinating session:

```text
protected authority edit -> ASK
```

Specialist/subagent:

```text
protected arbitrary authority edit -> DENY
```

Ordinary edit:

```text
DEFER
```

Verify that legitimate registry/discovery synchronization still works.

## Discovery identity

Test at least:

```text
duplicate IP
duplicate hostname/FQDN if prohibited
registry/discovery hostname mismatch
registry/discovery IP mismatch
valid identity
```

Confirm the validator has no embedded second fleet mapping.

## Config integrity

Test:

```text
remove required hook
disable HX protection
legitimate unrelated settings change
```

Verify that `.claude/settings.json` remains protected both before and after attempted weakening.

## Installer

Run the installer twice.

Verify:

```text
no duplicated HX hooks
unrelated settings preserved
unrelated hooks preserved
permissions.deny preserved
backup behavior works
```

## Runtime

Start or resume Claude Code.

Run:

```text
/hooks
```

Verify every intended project hook is registered with no startup errors.

---

# 27. TESTING REQUIREMENTS — SKILLS

Validate each implemented HX skill against concrete scenarios.

Examples:

## Context Engineering

Give an agent a task affecting one server/service.

Verify it reads:

```text
governance/routing
relevant scoped files
necessary runtime evidence
```

without loading irrelevant repository content.

## Source-Driven Research

Give it a version-sensitive technology question.

Verify:

- environment/version discovery occurs;
- authoritative sources are preferred;
- facts and inference are distinguished.

## Adversarial Validation

Give it a consequential architecture claim.

Verify:

- evidence is extracted;
- unsupported assumptions are challenged;
- a bounded reconciliation is produced.

## Planning & Gates

Give it a multi-host implementation goal.

Verify:

- dependencies;
- entry gate;
- implementation steps;
- exit gate;
- verification evidence;
- rollback consideration.

## Architecture Decisions & Authority

Give it conflicting target-state and discovered-state documents.

Verify it does not flatten them into one "truth."

## Legacy Migration

Give it a stale legacy service configuration.

Verify it extracts useful knowledge without copying historical environment state as current configuration.

---

# 28. CLEAN-CONTEXT VALIDATION

After implementation, perform a fresh-context review.

The reviewer should be able to answer:

1. What is the highest project governance authority?
2. How does repository/context routing work?
3. What role do skills play?
4. What role do agents play?
5. What role do hooks play?
6. Where does current server identity come from?
7. Is Ansible allowed?
8. What is the fleet orchestration baseline?
9. How are target-state and as-built facts distinguished?
10. Can a specialist independently change governance?

Expected high-level answers:

```text
Governance defines policy.
sdd-core remains the execution backbone.
knowledge routing scopes context.
skills define reusable methods.
specialists provide bounded expertise.
coordinator owns synthesis.
hooks enforce deterministic invariants.
registry/current evidence supplies operational truth.
Ansible is prohibited.
native Bash/SSH is authoritative.
governance changes require intentional coordination/approval.
```

If a fresh agent instead discovers two conflicting lifecycle systems or two competing routers, the implementation is not complete.

---

# 29. CHANGE DISCIPLINE

Make small coherent changes.

Do not refactor unrelated material.

Do not replace good existing HX mechanisms merely to match the approved design document literally.

Where current repository state is better than the proposal:

```text
preserve current mechanism
document why
adapt the approved intent
```

Where the repository contradicts settled HX governance:

```text
correct the contradiction
record the change
```

Do not silently guess when authority can be determined by repository inspection.

---

# 30. IMPLEMENTATION SEQUENCE

Execute in this order.

## Phase 0 — Baseline

- inspect operations material;
- inspect repository authorities;
- inspect existing hooks;
- inspect existing skills;
- inspect specialist agents;
- inspect tests;
- inspect Git state;
- establish current/target gaps.

Gate:

```text
Current authority and implementation baseline understood.
```

## Phase 1 — Hook regression baseline

Run existing hook tests before modification.

Gate:

```text
Current behavior known.
```

## Phase 2 — Permanent policy guard

Implement and test phase-independent Ansible prohibition.

Gate:

```text
Ansible denied independently of project phase.
```

## Phase 3 — Authority edit guard

Implement after reconciling actual governance and registry workflows.

Gate:

```text
Governance protected without breaking legitimate workflows.
```

## Phase 4 — Discovery validator extension

Implement registry-driven identity consistency.

Gate:

```text
Identity validation works without a second inventory.
```

## Phase 5 — Config integrity

Implement project-settings integrity backstop.

Gate:

```text
Required HX controls cannot silently disappear.
```

## Phase 6 — Hook packaging/settings

Update installer, settings fragment, README, and tests as applicable.

Gate:

```text
Installation is repeatable and idempotent.
```

## Phase 7 — HX-native skills

Implement/consolidate the six approved capabilities.

Gate:

```text
Skills extend sdd-core rather than duplicate it.
```

## Phase 8 — Specialist reconciliation

Update existing agents only where required to align with the final skill model.

Gate:

```text
Specialists remain bounded; coordinator remains synthesis authority.
```

## Phase 9 — Full validation

Run:

- hook tests;
- skill validation;
- repository validation;
- reference/link validation;
- clean-context validation;
- `/hooks` runtime verification.

Gate:

```text
All critical acceptance criteria pass.
```

---

# 31. REQUIRED DELIVERABLES

At completion provide:

## 1. Exact change inventory

List:

```text
CREATED
MODIFIED
REMOVED
UNCHANGED-BUT-VALIDATED
```

with paths.

## 2. Hook topology

Show:

```text
event
matcher
script
purpose
decision behavior
```

## 3. Skills topology

Show:

```text
skill/capability
purpose
trigger/use case
references/scripts
relationship to existing HX authority
```

## 4. Migration decisions

For material from the upstream skills design, summarize:

```text
ADOPT
ADAPT
MINE-REFERENCE
DEFER
REJECT
```

## 5. Test evidence

Include exact:

```text
test
command
result
```

for the important acceptance cases.

## 6. Deviations

If current repository reality required a different implementation from the operations documents, state:

```text
approved design
current reality
decision
reason
```

## 7. Residual/deferred work

Do not silently leave TODOs.

Classify them.

---

# 32. HUMAN-FACING COMPLETION REPORT

Create a polished dark-mode HTML completion report in the repository's established human-facing report location.

Use the repository's current naming convention.

The report should include:

- executive summary;
- purpose and goals;
- before/after architecture;
- exact hook topology;
- exact skill topology;
- files changed;
- Ansible prohibition evidence;
- native Bash/SSH preservation evidence;
- authority-edit behavior;
- registry-driven validation behavior;
- configuration-integrity behavior;
- skill implementation summary;
- agent reconciliation summary;
- tests and runtime validation;
- installer/idempotence evidence;
- provenance/licensing treatment;
- rejected/deferred ideas;
- residual risks;
- recommended next step.

Clearly label:

```text
TARGET-STATE
```

versus:

```text
NOW IMPLEMENTED / AS-BUILT IN REPOSITORY
```

where relevant.

---

# 33. DEFINITION OF DONE

This task is complete only when all of the following are true:

- [ ] The current five approved hook behaviors still work.
- [ ] The permanent-policy guard is operational.
- [ ] Ansible is denied regardless of project phase.
- [ ] The authority-edit guard is operational.
- [ ] High-authority files cannot be casually modified by specialists.
- [ ] Legitimate current discovery/registry synchronization still works.
- [ ] Config integrity protection is operational.
- [ ] Discovery validation includes registry-driven identity consistency.
- [ ] No second hardcoded fleet inventory was introduced.
- [ ] Existing destructive-storage permission controls remain intact.
- [ ] Hook installation remains idempotent.
- [ ] Unrelated `.claude/settings.json` configuration is preserved.
- [ ] Six HX-native skill capabilities are implemented or deliberately consolidated with equivalent existing capabilities.
- [ ] No upstream meta-router was installed.
- [ ] No second SDD framework was installed.
- [ ] Skills use progressive/scoped context rather than duplicating governance content.
- [ ] Specialist agents remain bounded and non-recursive.
- [ ] Coordinator remains the synthesis authority.
- [ ] All current regression tests pass.
- [ ] All new tests pass.
- [ ] `/hooks` verifies the expected runtime hook configuration.
- [ ] A clean-context agent can correctly identify the HX authority hierarchy.
- [ ] A dark-mode HTML completion report has been produced.
- [ ] Git diff contains no unrelated refactoring or accidental generated artifacts.

---

# FINAL OPERATING PRINCIPLE

Do not implement "more AI infrastructure."

Implement **clearer boundaries**.

The desired architecture is deliberately simple:

```text
Constitution / contracts
        |
        v
sdd-core + repository routing
        |
        v
HX skills
        |
        v
specialist agents
        |
        v
deterministic hooks
        |
        v
validators / tests / evidence
        |
        v
coordinator + human review
```

Each layer has one responsibility.

Preserve that separation.

Inspect the current repository, reconcile the approved material in:

```text
C:\Users\JarvisRichardson\Desktop\HX-Infrastructure\governance\operations
```

and then implement, test, validate, and document the complete hooks + skills architecture.

Do not return only a proposed plan. Make the approved system operational in the current local repository.