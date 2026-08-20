# HX SDD Repository — CI/CD and Code Review Process

**Applies to:** every HX repository built on spec-driven development (SDD) — `HX-Ai-Platform` and successors.
**Status:** documented process. Configuration facts verified against CodeRabbit docs 2026-08-18.
**Truth state:** the CodeRabbit product facts below are vendor-verified; the HX pipeline stages describe the intended process, not a measured as-built state.

---

## 1. The loop

```
spec → plan → tasks → implement → repo validator → PR → CodeRabbit → Claude Code → merge
```

Five gates. Nothing merges that has not cleared all five.

| # | Gate | Runs | Blocks on |
|---|---|---|---|
| G1 | **SDD artifacts present** | local + CI | missing `spec.md`, `plan.md`, `tasks.md`, `acceptance.md` |
| G2 | **Repository validator** | `tests/repository/validate.sh` | structural drift, missing locks, syntax errors, credential leak |
| G3 | **CodeRabbit review** | GitHub App, on PR open + each push | unresolved review threads |
| G4 | **Claude Code remediation** | local, agent-driven | findings not addressed or not explicitly declined |
| G5 | **Owner merge** | human | anything unresolved at G3/G4 |

---

## 2. G1 — SDD artifacts

Every feature branch carries a `specs/NNN-<slug>/` directory:

| File | Answers |
|---|---|
| `spec.md` | what and why; definition of done; non-goals |
| `plan.md` | state progression and execution envelope |
| `tasks.md` | ordered task ledger with per-task gates |
| `runbook.md` | exact commands, expected output, failure handling |
| `acceptance.md` | the single pass/fail contract |

**Rule:** a PR that changes behaviour without a corresponding spec directory is rejected at review, not at merge. Spec precedes build — that is the whole point of SDD.

---

## 3. G2 — Repository validator

`tests/repository/validate.sh`, run before any PR and as the first CI step.

What it should assert:

- required files exist (constitution, registries, catalogs, active spec set)
- agent contract count matches the registry
- every declared technology has `library.yaml` + `source-lock.yaml`
- `bash -n` on every shell script under `platform/` and `tests/`
- pinned identifiers appear where they must (model tag, digest, version)
- **no credential patterns anywhere in the tree**

Exit non-zero on any failure. The credential scan is the one check that must never be relaxed.

> **Design rule learned the hard way:** the validator gates *infrastructure execution*. Do not couple it to documentation cosmetics — HTML titles, presence of `<svg>`, prose phrasing. A validator that fails because a report heading changed will block a deployment for a reason nobody can act on. Assert structure and locks; do not assert wording.

---

## 4. G3 — CodeRabbit

### Configuration

`.coderabbit.yaml` at repository root. **It must exist on the feature branch** — CodeRabbit reads the config from the branch under review, not from the default branch.

Bootstrap it from the live resolved config rather than hand-writing:

```
@coderabbitai generate configuration
```
Opens a PR adding the current effective config as `.coderabbit.yaml`.

```
@coderabbitai emit path instructions
```
Opens a PR with suggested path-scoped review guidance — useful for telling CodeRabbit that `runbook.md` is executable procedure, not prose.

### Review commands (PR comment)

| Command | Effect |
|---|---|
| `@coderabbitai review` | incremental review of new changes |
| `@coderabbitai full review` | complete review of all files from scratch |
| `@coderabbitai pause` / `resume` | stop / restart automatic reviews |
| `@coderabbitai resolve` | mark all CodeRabbit threads resolved |
| `@coderabbitai approve` | resolve all threads and attempt approval |
| `@coderabbitai autofix` | apply fixes directly or via stacked PR |
| `@coderabbitai fix-ci` | investigate failing CI and generate fixes |
| `@coderabbitai generate docstrings` | docstrings for functions/classes |
| `@coderabbitai generate unit tests` | tests for the PR's code |
| `@coderabbitai generate sequence diagram` | diagram of the PR history |
| `@coderabbitai configuration` | print resolved config as YAML |
| `@coderabbitai help` | command reference |

### HX usage rules

- **`resolve` and `approve` are owner-only.** An agent must never clear its own review threads. That converts an independent gate into a self-certification.
- **`autofix` is allowed only via stacked PR**, never direct-to-branch. The fix gets its own review.
- **A finding is closed two ways only:** fixed, or explicitly declined with a one-line reason in the thread. Silence is not closure.

---

## 5. G4 — CodeRabbit → Claude Code handback

Two paths. Both are supported; pick one per repository and record the choice.

### Path A — Claude Code plugin (preferred)

Claude Code has a native CodeRabbit plugin:

```
/coderabbit:review
```

Runs the review and surfaces findings inside the Claude Code session directly. Fewest moving parts.

### Path B — CLI in agent mode

```bash
# install
curl -fsSL https://cli.coderabbit.ai/install.sh | sh
# or: brew install coderabbit

# authenticate (headless)
cr auth login --api-key "cr-************"

# verify setup
cr doctor
```

Review scopes:

| Command | Scope |
|---|---|
| `coderabbit review` | tracked changes |
| `coderabbit review --committed` | committed changes only |
| `coderabbit review --uncommitted` | staged and tracked edits |
| `coderabbit review --include-untracked` | includes untracked files |
| `cr --base develop` | review against a non-default base |
| `cr review --light` | faster local review policy |

**The handback flag:**

```bash
coderabbit review --agent
```

Emits **structured JSON** instead of human-readable text, designed for agent and Skill integration. This is what feeds Claude Code for an autonomous generate → review → iterate cycle.

Useful adjuncts:

```bash
cr review findings        # replay stored findings without re-running
cr review --show-prompts  # inspect the prompts used in the last review
cr stats                  # review statistics
```

### The remediation contract

For each finding Claude Code must produce one of:

| Outcome | Requirement |
|---|---|
| `fixed` | commit reference |
| `declined` | one-line reason posted in the thread |
| `deferred` | backlog entry ID |

**No finding is silently dropped.** Run `cr review findings` before requesting merge to confirm the ledger is empty or fully dispositioned.

---

## 6. G5 — Merge

Owner merges. Preconditions:

1. G1–G4 all clear
2. no unresolved CodeRabbit threads
3. every finding fixed, declined-with-reason, or backlogged with an ID
4. validator PASS on the merge commit, not just the branch head

---

## 7. Known failure modes

| Failure | Cause | Prevention |
|---|---|---|
| CodeRabbit silently not reviewing | `.coderabbit.yaml` only on the default branch | config must be on the **feature branch** |
| Findings accumulate unaddressed | no disposition contract | require fixed / declined / deferred per finding |
| Agent self-approves | agent has `resolve`/`approve` access | owner-only commands |
| Validator blocks on cosmetics | validator asserts prose and markup | assert structure and locks only |
| Autofix bypasses review | `autofix` applied to branch | stacked PR only |
| Merge passes on a stale check | validator ran on branch head, not merge commit | re-run at merge |

---

## 8. Setup checklist for a new SDD repo

- [ ] `.coderabbit.yaml` at root, committed on the feature branch
- [ ] `tests/repository/validate.sh` present and wired into CI
- [ ] `specs/NNN-<slug>/` with the five SDD artifacts
- [ ] `governance/backlog.md` for deferred findings
- [ ] CodeRabbit `resolve` / `approve` restricted to owner
- [ ] handback path chosen and recorded — plugin or `--agent` CLI
- [ ] credential scan in the validator, verified failing on a planted test string

---

## Sources

- CodeRabbit — configuration: <https://docs.coderabbit.ai/getting-started/configure-coderabbit>
- CodeRabbit — review commands: <https://docs.coderabbit.ai/reference/review-commands>
- CodeRabbit — CLI: <https://docs.coderabbit.ai/cli>

*Prepared by Claude (Opus 5), 2026-08-18. Process documentation. CodeRabbit product facts vendor-verified; HX pipeline stages are the intended process, not a measured as-built state.*
