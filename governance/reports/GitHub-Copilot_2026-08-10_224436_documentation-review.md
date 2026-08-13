# HX-Infrastructure Project Review

**Reviewer:** GitHub Copilot  
**Originally reviewed at:** 2026-08-10 22:44:36 -05:00  
**Updated at:** 2026-08-10 23:42:24 -05:00  
**Scope:** All 40 non-`.git` files present in the project, including hidden project configuration, active and distributable Claude hooks, skills, governance records, templates, and the ignored environment file's schema and Git treatment  
**Method:** Root-down document and code review, cross-document consistency checks, PowerShell and Bash syntax checks, JSON parsing, active/package hash comparison, representative hook payload tests, Git-ignore checks, and current Claude Code hook-semantics verification

## Executive Assessment

The project has a coherent Phase 1 boundary and correctly reports **Phase 1: IN PROGRESS** and **Phase 2: BLOCKED**. It is not ready for Phase 1 acceptance: no server discovery records or manual role assignments exist, the expected fleet is not independently defined, and the discovery hook validators currently fail open on their success path.

No critical finding was identified. One high-severity automation defect, five medium findings, and six low findings require attention. The high-severity validator defect should be corrected before relying on Claude hooks to accept a discovery record or allow a discovery subagent to finish.

## Findings

### High - Discovery validators crash and fail open when a record has no structural problems

[hx-common.ps1](../../.claude/hooks/hx-common.ps1#L53-L79) returns the problem list through the PowerShell pipeline. When the list is empty, the function emits no object, so both [hx-validate-discovery.ps1](../../.claude/hooks/hx-validate-discovery.ps1#L18-L19) and [hx-validate-subagent.ps1](../../.claude/hooks/hx-validate-subagent.ps1#L24-L33) receive `$null` and fail under `Set-StrictMode` when evaluating `$problems.Count`.

A direct test used an exact discovery skeleton containing every required heading plus `Status: COMPLETE` and `Discovery Status: COMPLETE`. Both hooks exited `1` with `The property 'Count' cannot be found on this object`. Claude Code's [official hook reference](https://code.claude.com/docs/en/hooks#exit-code-output) specifies that exit codes other than `2` are non-blocking for these events. The post-write check therefore allows the write, and the `SubagentStop` check allows the subagent to stop, while only reporting a hook error.

**Recommendation:** Make the helper or both callers produce a stable collection on the zero-problem path, for example by assigning `@(Get-HxDiscoveryProblems $filePath)`. Add direct payload tests for zero, one, and multiple problems and assert both exit code and JSON decision shape. Keep the active and packaged hook copies synchronized through the installer.

### Medium - The Phase 1 guard misses common relative-path shell writes

[hx-phase1-guard.ps1](../../.claude/hooks/hx-phase1-guard.ps1#L8-L25) detects `configuration.md` only when `servers` is preceded by a slash or backslash. The active matcher correctly includes `Bash|PowerShell|Write|Edit`, and absolute file-tool paths are denied. However, direct tests showed no deny decision for either of these representative shell commands:

```text
echo x > servers/hx-test/configuration.md
Set-Content servers\hx-test\configuration.md x
```

This contradicts the package's claim that the guard blocks creation or editing of per-server `configuration.md` during Phase 1. The package correctly calls the guard defense in depth rather than a sandbox, but bare relative paths are a normal command form and should be covered.

**Recommendation:** Normalize shell command paths and recognize `servers/.../configuration.md` at the start of a token as well as after a path separator. Add regression cases for forward and backslashes, quoted paths, `./servers`, bare `servers`, absolute paths, and unrelated files. For hard enforcement, use Claude permission deny rules where possible and keep the hook explicitly documented as defense in depth.

### Medium - The Phase 1 gate is neither canonical nor independently countable

[GOALS-AND-OBJECTIVES.md](../../GOALS-AND-OBJECTIVES.md#L38-L50) defines seven gate conditions, while [SERVER-REGISTRY.md](../../SERVER-REGISTRY.md#L19-L30) defines five. The shorter registry gate omits explicit confirmation that no role-specific configuration has begun and does not preserve the same wording for fleet completeness and comparability.

The [phase1-gate skill](../../.claude/skills/phase1-gate/SKILL.md#L19-L30) also requires every expected server to be present, but its permitted sources are the registry and existing discovery records. Neither source contains an independently approved expected-server list or count, so registry completeness is circular: the registry cannot prove that it contains servers that were never entered.

**Recommendation:** Define one canonical Phase 1 checklist and link every other gate display to it. Add a manually approved expected-fleet baseline, such as a named server list or explicit expected count, from a source independent of discovered rows. Keep role assignment manual.

### Medium - The Phase 2 template cannot satisfy the mandatory change-record contract

[INFRASTRUCTURE-CONTRACT.md](../../INFRASTRUCTURE-CONTRACT.md#L738-L752) requires nine fields for every material infrastructure change. [servers/_templates/configuration.md](../../servers/_templates/configuration.md#L62-L66) offers only `Timestamp | Change | Result` and has no designated record for previous state, configuration files touched, commands or automation used, rollback method, or unresolved issues.

A configuration record completed exactly from the template can therefore be complete by template standards while remaining noncompliant with the contract.

**Recommendation:** Add a material-change table containing all nine contract fields, or add explicit previous-state, files/commands, rollback, and unresolved-issues sections linked to each change entry.

### Medium - Discovery validation checks structure, not populated facts, and permits conflicting status fields

[Get-HxDiscoveryProblems](../../.claude/hooks/hx-common.ps1#L53-L79) checks headings and the presence of a top-level status marker but does not verify that sections contain facts or explicit unavailable reasons. After the zero-result crash is fixed, a factually empty skeleton would have no reported problem. The stronger completeness rules in [audit-discovery](../../.claude/skills/audit-discovery/SKILL.md#L17-L34) are not enforced by either hook.

[servers/_templates/discovery.md](../../servers/_templates/discovery.md#L1-L76) also contains both `Status` and `Discovery Status`. The subagent validator requires only the latter to be `COMPLETE`, so the former can remain `IN PROGRESS` without blocking completion.

**Recommendation:** Require substantive content or an explicit unavailable reason in each required section, reject unchanged template placeholders, and reduce the record to one canonical discovery-status field. Define registry status values and transitions from the same canonical field.

### Medium - The project has no tracked baseline

`git status --short` reported every non-ignored project path as untracked. The live `.env` is correctly ignored, but the documents, hooks, skills, templates, and governance records currently have no tracked project baseline for review, rollback, or change attribution.

**Recommendation:** Resolve the high- and medium-priority defects, verify that no live secret file is staged, and create an initial reviewed commit containing the non-secret project artifacts.

### Low - The action log blurs router and server ownership of static addressing

[actions-and-issues.md](../actions-and-issues.md#L18) asks for persistent router-side "server static-IP" and DNS record management. The contract assigns static addressing to Ubuntu hosts and explicitly prohibits ASUS DHCP reservations in [INFRASTRUCTURE-CONTRACT.md](../../INFRASTRUCTURE-CONTRACT.md#L209-L220).

**Recommendation:** Reword `act-001` as persistent router-side DNS records for server-managed static IP addresses. State that address approval is recorded in the registry, addressing is applied on the server, and the router provides name resolution only.

### Low - Role, workload, approval, and lifecycle-field authority is incomplete

[SERVER-REGISTRY.md](../../SERVER-REGISTRY.md#L1-L16) is the role-assignment source of truth, while [servers/_templates/configuration.md](../../servers/_templates/configuration.md#L3-L7) repeats role and workload and adds an undefined `Approved by` field. The registry's `Discovery` and `Phase 2` columns also have no defined value set or transition criteria.

**Recommendation:** State that the configuration record copies approved role/workload values from the registry, define what `Approved by` approves and who may supply it, and define canonical lifecycle values and transition criteria.

### Low - Root installation guidance omits the hook installation path

[INSTALL.md](../../INSTALL.md#L1-L26) describes copying skills and the discovery agent, but its expected tree omits `.claude/settings.json` and `.claude/hooks`. It does not direct readers to the separate [hook installer](../../claude-hooks/README.md), so a user can complete the root instructions without installing Phase 1 hook enforcement.

**Recommendation:** Either include hooks and settings in the root installation tree or clearly split the process into skill/agent installation and hook installation, with a verification command for each.

### Low - Two skill descriptions contain malformed duplicated prose

[audit-discovery](../../.claude/skills/audit-discovery/SKILL.md#L1-L17) contains `a a server discovery Markdown record record` and `the target a server discovery Markdown record`. [sync-registry](../../.claude/skills/sync-registry/SKILL.md#L1-L15) contains similar duplicated phrases in both metadata and workflow text. The malformed frontmatter descriptions can reduce reliable skill selection and make the instructions harder to interpret.

**Recommendation:** Replace each phrase with `a server discovery record`, then verify the frontmatter and workflow wording in both active skill files.

### Low - Router DNS validation relies on an undefined hostname

[INFRASTRUCTURE-CONTRACT.md](../../INFRASTRUCTURE-CONTRACT.md#L280-L305) and its [validation section](../../INFRASTRUCTURE-CONTRACT.md#L649-L672) test `HX-Router.hx.local.arpa`, but no current project record establishes that canonical hostname and address.

**Recommendation:** Define the router's canonical record in the network baseline or use an explicit `<known-host>.hx.local.arpa` placeholder until the record is approved and implemented.

### Low - The infrastructure contract heading hierarchy changes after section 4

[INFRASTRUCTURE-CONTRACT.md](../../INFRASTRUCTURE-CONTRACT.md#L1-L170) starts with one document H1 and H2 numbered sections. Sections 5 through 16 then use H1, making them peers of the document title in rendered outlines.

**Recommendation:** Use H2 for every numbered top-level section and H3 for their subsections.

## Prioritized Recommendations

1. Fix and regression-test the zero-problem discovery-validator path before accepting discovery records through hooks.
2. Close the relative-path guard bypass and document the limit between hook defense in depth and hard permission enforcement.
3. Establish one canonical gate plus an independently approved expected-fleet baseline.
4. Strengthen substantive discovery validation, consolidate statuses, and align the Phase 2 template with the change-record contract.
5. Create the first non-secret Git baseline after the reviewed fixes are complete.
6. Resolve the lower-priority ownership, installation, skill-text, hostname, and heading issues together as documentation cleanup.

## Confirmed Clean Areas

- Phase 2 is consistently blocked until fleet-wide discovery, manual review, and manual role assignment are complete.
- Agents and skills consistently prohibit automatic role, workload, and model assignment.
- `discovery.md` is preserved as the as-found record; `configuration.md` is a separate Phase 2 artifact.
- All active PowerShell hook files parse successfully.
- The Bash fact collector passes `bash -n` under Git Bash and remains read-only by inspection.
- Active and distributable hook files are hash-identical; active settings and the packaged settings fragment are structurally identical.
- `.mcp.json`, both hook settings files, and `.vscode/settings.json` parse as JSON. The Context7 project entry uses hosted HTTP transport and contains no embedded header or key.
- `.env` is ignored and `.env.example` is not ignored. No credential value is reproduced in this report.
- Routine action and issue tracking consistently points to `governance/logs/actions-and-issues.md`; the obsolete `OPEN-ACTIONS.md` reference from the prior report has been removed.

## Accepted-Risk Treatment

[risk-001 and risk-002](../risk-acceptances.md#L9-L30) remain active, setup-scoped, and time-bounded. Their review trigger has not been reached because Phase 1 remains in progress and Phase 2 is blocked. In accordance with the register and [CLAUDE.md](../../CLAUDE.md#L91-L99), this review does not re-report the accepted bootstrap credential-strength/disclosure or credential-file-permission risks.

## Files Reviewed

The review covered all 40 files outside `.git`:

- Root and editor configuration (11): `.env`, `.env.example`, `.gitignore`, `.mcp.json`, `.vscode/settings.json`, `CLAUDE.md`, `GOALS-AND-OBJECTIVES.md`, `INFRASTRUCTURE-CONTRACT.md`, `INSTALL.md`, `README.md`, and `SERVER-REGISTRY.md`.
- Active Claude assets (13): `.claude/settings.json`, `.claude/agents/server-discovery.md`, six hook scripts, four skill files, and `collect-server-facts.sh`.
- Distributable hook package (9): `claude-hooks/README.md`, `apply-hooks.ps1`, `settings.fragment.json`, and six packaged hook scripts.
- Governance and continuity (4): `conversations/SYNC-POLICY.md`, `governance/logs/actions-and-issues.md`, `governance/policy/risk-acceptances.md`, and this report's prior version.
- Server documentation (3): `servers/README.md` and both files in `servers/_templates`.

## Review Limits

- No live ASUS router or Ubuntu server was queried or changed, so hardware, network, and service facts could not be compared with project records.
- No completed server discovery record exists. Hook behavior was tested with temporary local fixtures and representative Claude hook JSON, not a live SSH discovery run.
- Hooks were invoked directly rather than through a full interactive Claude Code session. Official behavior was checked against Claude Code `2.1.221` and the current official hook reference.
- Context7 is structurally configured but remains pending user approval in Claude Code; no Context7 result was required for this review.
- The ignored `.env` was assessed for schema and repository treatment without copying secret values into the report.
