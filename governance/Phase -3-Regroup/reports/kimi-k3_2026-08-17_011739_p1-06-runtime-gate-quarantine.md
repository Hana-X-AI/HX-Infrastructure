# P1-06 — DS4-era runtime-gate quarantine

**Author:** kimi-k3 (workstation session)
**Date:** 2026-08-17 01:17 CDT
**Branch:** `docs/phase3-remediation-evidence` (main checkout)
**Task:** P1-06 — quarantine the DS4-era runtime gates under `tests/ai-runtime/`
**Briefing:** `governance/Phase -3-Regroup/remediation/claude_2026-08-17_005156_parallel-agent-prompt-p1-06.md`
**Status:** COMPLETE — inventory and DS4 sweep done; **zero files changed** because the premise of Part 2 did not hold against the repository.

---

## 1. Verdict

**The runtime gates have no live-contact path to quarantine.** The briefing's Part 2 premise — "several of them are written to reach out and touch hardware" — is not supported by the current tree. Every gate script *evaluates repository evidence and reports*; none executes an install, download, service, network, or host command. The single nominal live path (`hx-runtime-acceptance.ps1` reading a profile's `base_url_env`) terminates in `live execution not implemented in this pass` and issues no HTTP request.

Per the owner's ruling ("I accept that there is no live-contact path and yes repo wins"), **no fail-closed phase guard was added.** Adding one would guard against a capability the scripts do not have — the over-engineering the standing rules forbid.

**Part 3 (DS4 profile sweep) found nothing to strip:** `tests/ai-runtime/` is already free of `ds4` and third-profile assumptions.

No files under `tests/ai-runtime/` were edited. `git diff --stat` for this task is empty.

---

## 2. Part 1 — inventory and reference graph

**Scope of the reference grep:** the repository working tree, `.git` excluded. The two sweeps in this report (the reference grep here and the `ds4` sweep in section 4) were run minutes apart while the working tree was changing, so their file totals differed by one (28,685 vs 28,686) — that difference is a timing artifact, not a scope difference. Re-run together against a single stable snapshot after the task, both covered the same 28,688 files. The count is a scope statement, not a result; the results below are unaffected.

| Owned path | What it does | Live-contact path | Invoked by other code |
| --- | --- | --- | --- |
| `hx-capacity-gate.ps1` | Evaluates a workload against registry/workload JSON; reports PASS/FAIL/BLOCKED. Header: "Contacts nothing." | None | No — read as source text by the invariants test only |
| `hx-gpu-fit.ps1` | Arithmetic on artifact size vs. VRAM. Header: "Contacts nothing." | None — writes BLOCKED for host mutation | No |
| `hx-workload-commission.ps1` | Commissioning gate state machine; reports state. Header: "contacts no host." | None — refuses deferred/aborted workloads | No |
| `hx-runtime-acceptance.ps1` | Replays fixtures through the contract tests; can read `base_url_env`. | Designed but **not wired** — line 268 `live execution not implemented in this pass`; all L2–L5 SKIP, no request issued | No |
| `hx-runtime-invariants.tests.ps1` | The 22-assertion suite. Reads the above as source text (`Get-Content -Raw`). | None | (is the suite) |

**Reference graph.** All references are documentation (remediation plans, recon reports, the tracker) plus the invariants test reading the gates as data. No CI config, task runner, or build script invokes any gate as an executable. The gates are reachable only by direct manual invocation.

**Primitive sweep.** All four gate scripts searched for `Invoke-WebRequest`, `Invoke-RestMethod`, `curl`, `wget`, `ssh`, `scp`, `apt`, `apt-get`, `dpkg`, `pip`, `npm install`, `ollama`, `nvidia-smi`, `Start-Service`, `Stop-Service`, `Restart-Service`, `Set-Service`, `New-Service`, `Test-Connection`, `System.Net`, `WebClient`, `HttpClient`, `Start-Process`. **Zero live-contact primitives** (matches were comments, `.EXAMPLE` lines, or the invariants test asserting their absence).

**Surprise relative to the briefing:** the scripts are already inert in Phase 3 by construction, not by guard. The "commissioning" reach the briefing warns about is a designed capability that was never implemented.

---

## 3. Part 2 — live-contact reachability

**Nothing to remove.** The phase-guard pattern from `.claude/hooks/hx-phase1-guard.ps1` was read and understood (fail-closed: unknown/empty/missing/malformed all refuse, every error path exits non-zero). It was not applied because there is no reachable code path for it to gate.

The `hx-runtime-acceptance.ps1` live branch was traced end to end: when a profile's `base_url_env` is set, `$isLive` becomes `$true`, the URL is recorded in the evidence object (`host`, `base_url` fields), and every L2–L5 test is then marked `SKIP` with reason `live execution not implemented in this pass`. No socket, request, or process is created. Setting `HX_VLLM_BASE_URL` cannot make this script contact anything.

If and when the live path is implemented in the authorized implementation phase, a fail-closed phase guard at the entry point becomes the correct control. That is future work for that phase, not Phase 3 hardening of an inert script.

---

## 4. Part 3 — DS4 profile assumptions

**Profiles on disk: exactly 2** — `offline-fixture.json`, `vllm-qwen.json` (verified by directory listing).

**Owned-subtree sweep** (`tests/ai-runtime/`, all 27 files including `README.md` read for context): case-insensitive `ds4`, plus `deepseek`, `third profile`, `three profiles`, `profiles.Count -eq 3`, `profiles[2]`. **Zero matches.**

The invariants test references `vllm-qwen` by name (asserting it stays PRIMARY) and iterates `profiles/*.json` generically; it hard-codes no profile count and names no third profile. No fixture, workload definition, or test assumes a profile that is not on disk.

**Repository-wide `ds4` sweep** (scope: 28,686 files, `.git` excluded, case-insensitive): 74 files matched. Reviewed by category:

- **Binary/base64 false positives** — `.mp4`, `.png`, `.ttf`, `.pdf`, `cacert.pem`, `.lock`, `go.sum`, `package-lock.json`, etc.: "ds4" is a coincidental byte substring. Not actionable.
- **Vendored mirrors** under `governance/operations/*/...` (ollama, vllm, langgraph, jcode, loopx, OmniRoute): third-party source trees held for reference. Out of scope for the runtime gate work and not live configuration.
- **Governance text** (tracker, remediation plans, reports, `session-resume.md`): legitimate *historical* mentions describing the DS4 removal (e.g. the `iss-022` closeout: "The profile table also advertised a `ds4-deepseek` profile whose backing file had been deleted"). These are records of the fix, not live references. One tracker match (`act-014`) is a coincidental `hxs-4` substring.

**No live `ds4` reference exists anywhere in the repository's active configuration or code.** Nothing to strip.

---

## 5. Checks run, with output and scope

| Check | Scope | Result |
| --- | --- | --- |
| `hx-runtime-invariants.tests.ps1` **before** | full suite | **22 PASS / 0 FAIL** — matches briefing baseline; tree had not moved |
| `hx-runtime-invariants.tests.ps1` **after** | full suite | **22 PASS / 0 FAIL** — unchanged; no edits were made |
| Profiles on disk | `tests/ai-runtime/profiles/` | exactly 2: `offline-fixture.json`, `vllm-qwen.json` |
| Live-contact primitive sweep | 4 gate scripts | 0 primitives |
| Reference graph | 28,685 files (`.git` excl.) | doc references + invariants test only; no executable caller |
| `ds4` sweep, owned subtree | 27 files | 0 matches |
| Third-profile assumption sweep | 26 files (README excl.) | 0 matches |
| `ds4` sweep, repo-wide | 28,686 files (`.git` excl.) | 74 files, all false-positive binaries, vendored mirrors, or historical text; 0 live references |

The reference-grep and `ds4`-sweep totals differ by one (28,685 vs 28,686) because the two ran minutes apart while the working tree was changing. Re-run together against a single stable snapshot after the task, both covered the same 28,688 files. The one-file difference is a timing artifact, not a scope difference; the results are unaffected.

**Main suite cross-check:** not run. This task touched nothing the main suite covers — no file was edited. Stated as an attestation, not a test result.

---

## 6. What I could not resolve / contradictions

- **Contradiction (repository wins):** the briefing's Part 2 premise — that these scripts "are written to reach out and touch hardware" — is false against the current tree. There is no live-contact reachability to remove. Resolved by owner ruling: repo wins, no guard added.
- **No before/after change to report for any file** because no edit was warranted. The honest result of P1-06 is "already clean," not a diff.
- **`tests/ai-runtime/README.md` was not written** (owned by Claude Code). No change to it was needed; nothing to propose.
- **Not added to the tracker.** The tracker (`governance/logs/actions-and-issues.md`) is under a live-collision hold with Claude Code (P2-02 parked pending cc's commit). Per the briefing's append-only discipline and the active hold, I did not append a row. If the owner wants P1-06 recorded there, the row is: *P1-06 DS4-era runtime-gate quarantine — inventory found no live-contact path and no DS4 profile assumption; zero changes; suites 22/0 before and after.*

---

## 7. Attestations

- No live server was contacted; no remote endpoint was invoked; no package, service, storage, or network command was run against any host. (Attestation.)
- No commissioning path was executed. The only scripts run were the read-only invariants suite and directory/search commands. (Attestation.)
- No file under `tests/ai-runtime/` was created, modified, or deleted. (Verifiable: `git status` for that subtree is clean under this task.)
- Line endings and encoding: untouched — no file was written.
