# Items 3 and 2 — guard fail-closed and the crossed F1 matrix

**Author:** Claude-Opus-5 (Claude Code, workstation session)
**Date:** 2026-08-16 22:14:44 CDT
**Branch:** `docs/phase3-remediation-evidence`
**Tasks:** Next-steps group B item 3 (F-03) and item 2 (CR-5), executed together as Option 1
**Predecessor report:** `Claude-Opus-5_2026-08-16_213727_step-1-verification-gate.md`
**Status:** COMPLETE — suite green, all claims below reproduced from executed commands.

---

## 1. Verdict

**F-03 was real, it was wider than the finding described, and it is now closed.** The Phase 3 mutation guard failed open on malformed hook input. It no longer does — and neither do the two other PreToolUse guards, which had the same outcome by a quieter route.

**CR-5 was real and is now closed.** The F1 matrix crossed nothing; it varied the registry state against a single command, and varied the protected mutations against a single default root. The product of the two axes — the 96 cells where a state-specific regression could hide — was never tested. It is now.

**Suite: 295 PASS / 0 FAIL**, up from 160. The 135 new assertions are almost entirely the crossed matrix and the fail-closed regression cases.

Four further defects were found while doing the work. All four are fixed in this change, per the standing directive to fix rather than report:

| Found | Fixed |
| --- | --- |
| `hx-validate-discovery.ps1:7` had the identical strict-mode fail-open | guarded read |
| `hx-permanent-policy-guard.ps1` and `hx-authority-edit-guard.ps1` allowed silently on payloads they could not inspect | both fail closed |
| No test enforced `.claude/AGENTS.md`'s active/packaged hook parity rule | two assertions added |
| `governance/index.html` published "25 entries · 4 open" against a log holding 38 entries and 6 open | regenerated |

---

## 2. What changed

```
.claude/hooks/hx-phase1-guard.ps1                     48 +-
.claude/hooks/hx-permanent-policy-guard.ps1           26 +-
.claude/hooks/hx-authority-edit-guard.ps1             27 +-
.claude/hooks/hx-validate-discovery.ps1                8 +-
claude-hooks/claude-hooks/hooks/  (4 packaged copies, byte-identical)
tests/remediation-tests-restored.ps1                 196 +-
governance/logs/actions-and-issues.md                  1 +   (iss-020)
governance/*.html, governance/site/*.html              regenerated from Markdown
```

`git diff --check` is clean.

---

## 3. Item 3 — the fail-open, and why a guarded read was not enough

### 3.1 The mechanism

`hx-common.ps1:1` sets `Set-StrictMode -Version Latest`, so reading an absent property is a terminating error. `Read-HxHookInput` returns a bare `[pscustomobject]@{}` for empty or whitespace stdin, so a malformed payload has neither `tool_name` nor `tool_input`.

`hx-phase1-guard.ps1` denies by writing `permissionDecision: deny` and exiting **0**. Both `exit` statements in the file were `exit 0`; the hook has no exit-code deny path at all. So a strict-mode crash produced exit 1 with no decision on stdout, and a non-zero exit carrying no decision is a non-blocking error — the protected tool call proceeds.

### 3.2 Three paths in the guard, not two

The finding named lines 11 and 25 and stated that line 16 "defends the same way correctly." It does not. Line 16 read:

```powershell
if ($null -ne $inputObject.tool_input.PSObject.Properties["file_path"]) {
```

That guards `file_path` while performing an unguarded `.tool_input` read to do it. Probed directly:

| Payload | Before | After |
| --- | --- | --- |
| empty stdin | exit 1, `The property 'tool_name' cannot be found on this object` | exit 0, **DENY** |
| `{"tool_name":"Write"}` — no `tool_input` | exit 1, `The property 'tool_input' cannot be found on this object` | exit 0, **DENY** |
| `{"tool_name":"Bash"}` — no `tool_input` | exit 1, same error | exit 0, **DENY** |

### 3.3 A guarded read alone would still have failed open

This is the part the finding did not reach, and it changed the fix.

Reading an absent field through a defensive helper yields `""`. An empty command matches none of the fourteen blocked patterns; an empty file path matches no `configuration.md` route. The hook then exits 0 with no decision — **which allows the call.** No crash, same outcome.

`.claude/AGENTS.md:38` is explicit:

> "missing or malformed hook input must not silently create a fail-open path for a protected operation."

So the guards fail **closed**. The load-bearing fact that makes this safe is in `.claude/settings.json`: `hx-phase1-guard.ps1` is registered on the matcher `Bash|PowerShell|Write|Edit`, `hx-permanent-policy-guard.ps1` on `Bash|PowerShell`, and `hx-authority-edit-guard.ps1` on `Write|Edit`. Every payload reaching a guard is a protected call **by construction**. One it cannot classify or inspect is therefore a protected call it failed to screen, and denying it costs nothing — no `Read`, `Grep` or `Glob` ever reaches these hooks.

The tool name is still re-checked inside each hook rather than trusted from the matcher. That is the posture `hx-validate-subagent.ps1` adopted under `iss-002`, and it is the reason the packaged fragment carries the same matchers.

### 3.4 The fix, using the helper that already existed

`hx-common.ps1:12-25` already provides `Get-HxInputProperty`, written for the `iss-002` remediation to do exactly this. No new idiom was introduced; the guard was simply the one hook that had not adopted it. `hx-permanent-policy-guard.ps1` and `hx-authority-edit-guard.ps1` were already using it for `tool_name` — they crashed on nothing, but allowed on everything they could not read.

### 3.5 Verified behaviour, all three guards

| Payload | phase1-guard | permanent-policy | authority-edit |
| --- | --- | --- | --- |
| empty stdin | DENY | DENY | ASK |
| tool outside the matcher (`Read`) | DENY | DENY | ASK |
| no `tool_input` | DENY | DENY | ASK |
| empty `command` / `file_path` | DENY | DENY | ASK |
| `lsblk -o NAME,SIZE` | ALLOW | ALLOW | n/a |
| `Write servers/hx-test/discovery.md` | ALLOW | n/a | ALLOW |
| `Write servers/hx-test/configuration.md` | **DENY** | n/a | ALLOW |
| blocked shell mutation | **DENY** | n/a | n/a |

`hx-authority-edit-guard.ps1` escalates to `ask` rather than `deny` deliberately. Its normal decision on a protected file is already a confirmation prompt; a payload it cannot classify may be an entirely ordinary write, and only the confirmation step needs preserving. Denying there would have been a behaviour change dressed as a fix.

### 3.6 Verified live, not only in fixtures

Every `Bash`, `Write` and `Edit` call made in this session after the change passed through all three guards in the real harness and was allowed. That is end-to-end confirmation that the payload-shape assumption behind the fail-closed branch is correct — real `Write`/`Edit` payloads do carry `file_path`, real `Bash` payloads do carry `command`. Had the assumption been wrong, the session would have denied its own next tool call immediately and visibly.

---

## 4. Item 2 — the crossed matrix

### 4.1 The hole

Two loops, never multiplied:

- `$phase2States` — six registry states, each tested against **one** command (`apt-get install`).
- `$guardCategories` — fourteen protected mutations, each tested against **one** default root.

A regression that released `systemctl` for exactly one registry state passed both loops. The `""` and `"BANANA"` rows look like malformed-input coverage but are malformed *registry values*, a different axis entirely.

### 4.2 The replacement

Per registry state, the matrix now runs:

- **14** `$guardCategories` blocked mutations — the crossed cells;
- **2** direct tool routes, `Write` and `Edit` against `servers/<host>/configuration.md`, which no state loop had ever exercised;
- **7** malformed payload shapes — empty payload, no `tool_name`, `Bash`/`Write` without `tool_input`, empty `command`, empty `file_path`, and a tool outside the matcher;
- **1** allow control, `lsblk -o NAME,SIZE`.

That is 24 real hook invocations per state, 144 across six states, plus the standalone rows.

**The allow control matters.** Without it the matrix would also pass a guard that denied everything unconditionally — which, after a fail-closed change, is a live failure mode rather than a theoretical one.

### 4.3 The grep was demoted, as instructed

The textual `Test-HxPhase2Open` check now sits **after** the behavioural matrix and is renamed `F1: guard source retains no Phase 2 release branch (secondary)`. Its comment states plainly that a green grep with a red matrix means the matrix. It proves one string is absent from one file; it never proved the hard-lock.

### 4.4 The matchers are now pinned

The fail-closed design depends on each guard being registered only for tools it can inspect. That dependency did not exist before this change, so three assertions pin it. A widened matcher would route unrelated tools into a guard that now denies what it cannot classify — the suite fails first.

### 4.5 Counts, stated as scope

| | Before | After |
| --- | --- | --- |
| Suite assertions | 160 | **295** |
| F1 assertions | 21 | 155 |
| Crossed (state x mutation) cells | 0 | 96 |
| Malformed-payload cases | 0 | 45 |
| Runtime | not measured | **~5 min** |

The suite covers `tests/remediation-tests-restored.ps1` only. It does not cover the P1-01 scanner, the hook installer, or the governance site.

---

## 5. Defects found during the work, and fixed

### 5.1 `hx-validate-discovery.ps1:7` — same defect, outside F-03's wording

`$inputObject.tool_input.PSObject.Properties["file_path"]` threw on any malformed payload; exit 1, validation skipped entirely. Found by probing every hook rather than only the one the finding named. Fixed with the same helper.

Left as an allow-on-empty rather than made fail-closed: it is a `PostToolUse` validator, so denying is not available to it, and it already exits 0 for any path outside `discovery.md` and `SERVER-REGISTRY.md`.

### 5.2 The other two guards allowed silently

Neither crashed — both already used `Get-HxInputProperty` for `tool_name` — but both exited 0 and allowed when the field they screen on could not be read. Same fail-open outcome, no error to notice. Both now fail closed. §3.5 has the verified behaviour.

### 5.3 `.claude/AGENTS.md`'s hook-parity rule was unenforced

> "Active and packaged hook copies must remain synchronized."

The suite checked that `.claude/settings.json` and `settings.fragment.json` agree. **Nothing checked the hook scripts themselves.** A fix applied to `.claude/hooks/` shipped a stale script to anyone installing from `claude-hooks/`.

This was not hypothetical: it happened during this task. After fixing the guard, `cmp` reported `hx-phase1-guard.ps1 DIFFERS` and `hx-validate-discovery.ps1 DIFFERS` against their packaged copies. Two assertions now compare the file sets and the SHA-256 of every script, both directions. All eight pairs are byte-identical.

### 5.4 The published governance index was 13 entries stale

Regenerating from Markdown surfaced this on `governance/index.html`:

```diff
-        <span class="meta">25 entries · 4 open</span>
+        <span class="meta">38 entries · 6 open</span>
```

The generated pages had also been hand-edited after generation — the nav block was reordered and re-indented relative to what `tools/build-governance-html.js` emits. Both `build-governance-html.js` and `make-standalone.js` were re-run; the standalone build reports "9 standalone pages, 81 link groups rewritten, all cross-links verified."

This is adjacent to F-02 (38 stale lifecycle statements outside the P1-01 allowlist) but is not the same defect: F-02 is about lifecycle *statements*, this was a stale *entry count* on the landing page. F-02's sweep is still open.

---

## 6. Recommendations

### R-1 — Re-run `build-governance-html.js` as a gate, not a habit (do next)

The drift in §5.4 existed because nothing failed when the generated pages diverged from their source. Add an assertion that regenerating produces no diff, in the same spirit as the hook-parity check.

- **Resolves:** silent staleness of every published governance page.
- **Does not resolve:** F-02's stale lifecycle statements, which live in the page *bodies* under `tools/page-bodies/`.
- **Prerequisite:** none. The generator is deterministic — two runs in this session produced identical output.

### R-2 — Decide the suite runtime trade-off (owner call, low stakes)

~5 minutes, from ~200 process spawns at roughly 1.8 s each on Windows PowerShell 5.1. A gate that takes five minutes is a gate people skip.

The cheapest 40 % cut is to stop crossing the 7 malformed shapes with all 6 registry states (42 invocations) and run them against two representative states instead. The guard no longer reads the registry at all, so the malformed axis is nearly state-independent — but "nearly" is exactly the assumption CR-5 punished last time. **Recommendation: keep full coverage.** Correctness of the Phase 3 hard-lock outranks five minutes.

- **Reversal criteria:** if the suite starts being skipped in practice, trim the malformed cross first and say so in the output.

### R-3 — Leave `$root` alone in both hooks (non-recommendation)

`hx-phase1-guard.ps1:4` and `hx-validate-discovery.ps1:4` both assign `$root = Get-HxProjectRoot $inputObject` and never use it. It became dead when the Phase 2 release branch was removed. It is pre-existing, harmless, and unrelated to this change; deleting it would put an untraceable line in this diff. Flagged, not touched.

### R-4 — Do not treat the schemas or this change as enforcement of anything wider

This change hardens three hooks and their tests. It does not make the Meta-Agent JSON Schemas live, and it does not close F-02, F-04, F-05, F-06 or CR-1 through CR-4.

---

## 7. Next tasks

Group C is now the cheapest remaining work, and two of its three items are one-line edits.

**Option 1 — Group C in one pass: items 5, 6 and 7. RECOMMENDED.**

- **5** — append the missing changelog row recording that this branch received the hard-lock via `8ec683b`.
- **6 / CR-4** — correct the stale v3 digest at `governance/Phase -3-Regroup/remediation/README.md:63` from `ce206cb2…a6886` to `6317299d…d998e45`. Cherry-picking `d1ad55d` conflicts, so this is a direct edit.
- **7 / CR-2** — replace the `assert` used as a write-safety guard at `_s2.py:24` with an explicit conditional that raises before `write_text`, since `python -O` strips assertions.

**For:** three small, independent, fully specified corrections; one report closes all three. **Against:** none material. Item 7 touches a file that also violates the naming standard, which stays a separate item — do not conflate.

**Option 2 — item 8, the hook installer (CR-3 / F-06).**

`claude-hooks/README.md:3` claims seven hook commands and lists five, because it lists events rather than commands. `apply-hooks.ps1:40` omits two hooks from `$ourPattern`, so re-runs produce 7 → 9 → 11 registrations.

**For:** it is a real broken installer, and it is adjacent to the hook work just completed while the context is loaded. **Against:** larger than any Group C item, and it needs a two-run test fixture built from scratch.

**Recommendation: Option 1.** Group C clears three findings for roughly the cost of one, and item 8 loses nothing by waiting.

---

## 8. Provenance and limits

- **Verified fact.** Exit codes, decision JSON, blob comparisons, assertion counts and the 295/0 result are reproducible from the commands in §3 and §4. The suite was re-run after the `governance/logs/actions-and-issues.md` edit, because `tests/remediation-tests-restored.ps1:380` reads that file — the earlier green run would not have covered it.
- **Verified live.** §3.6 — the fail-closed branches were exercised against the real harness by this session's own tool calls, not only against fixtures.
- **Inference, stated as such.** "The protected tool call proceeds" on a non-zero exit with no decision is derived from the guard's own deny mechanism plus the project's recorded characterisation at `governance/logs/actions-and-issues.md` (`iss-002`). It was not observed end-to-end, because the harness constructs hook payloads itself and a malformed one cannot be induced on demand.
- **Attestation, not evidence:** no live server was contacted and no remote endpoint was invoked. All work was local file edits, local PowerShell hook invocations, `git` plain-text queries, and two local Node generators.
- **Untouched deliberately:** the four modified LangGraph phase-2 files remain uncommitted and unstaged; they are a separate concern with an open owner question about which branch they land on. The ~14 untracked paths under `governance/operations/` remain untracked, pending owner ruling 10.
- **Not covered:** the P1-01 scanner, the hook installer, F-02, F-04, F-05, F-06, CR-1 through CR-4. None were run or inspected.
