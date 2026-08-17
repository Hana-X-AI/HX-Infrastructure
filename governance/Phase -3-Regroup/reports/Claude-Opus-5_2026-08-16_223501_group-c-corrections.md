# Group C — items 5, 6 and 7

**Author:** Claude-Opus-5 (Claude Code, workstation session)
**Date:** 2026-08-16 22:35:01 CDT
**Branch:** `docs/phase3-remediation-evidence`
**Tasks:** Next-steps group C — item 5 (changelog row), item 6 / CR-4 (stale v3 digest), item 7 / CR-2 (`assert` as a write guard)
**Predecessor report:** `Claude-Opus-5_2026-08-16_221444_items-3-and-2-guard-fail-closed.md`
**Status:** COMPLETE — all three applied, each verified independently rather than accepted from the briefing.

---

## 1. Verdict

All three corrections were real and all three are applied. Every factual claim the briefing made about them held up under independent check — but two of the three needed a check the briefing had not run, and one of those turned up a governance-integrity problem worth naming.

| Item | Briefing claim | Independent check | Outcome |
| --- | --- | --- | --- |
| 5 | the branch has no record of receiving the hard-lock; suite moved 154 to 160 | derived from the commit itself, not taken on trust | **confirmed** — row added |
| 6 / CR-4 | line 63 digest is wrong; `6317299d…d998e45` is correct | re-hashed the artifact from disk | **confirmed** — line 63 corrected |
| 7 / CR-2 | `python -O` strips the assert, so the write proceeds | ran both code shapes under `-O` | **confirmed** — guard replaced |

**Finding:** the Phase 3 changelog already contained a row claiming the v3 digest had been corrected. It had not been — not on this branch. See §3.2.

Gate: **295 PASS / 0 FAIL**, `git diff --check` clean.

---

## 2. Item 5 — the changelog row

### 2.1 Verifying the numbers before writing them down

The briefing supplied the row text, including "suite moves 154 to 160." A changelog is a durable record, so the figure was derived rather than copied. Both versions of the suite were extracted from git and compared:

```
git show 8ec683b^:tests/remediation-tests-restored.ps1
git show 8ec683b:tests/remediation-tests-restored.ps1
```

`Assert-True` call sites: **91 before, 91 after** — the count did not change, so the delta had to come from a loop. It did:

Both complete blocks are reproduced below, not only the changed lines, because the load-bearing claim is about the **post-change** state of all six rows — three of which changed value without changing position.

**Before** — `8ec683b^:tests/remediation-tests-restored.ps1`, the `$phase2States` literal:

```powershell
$phase2States = @(
    @{ Value = "BLOCKED";     GuardActive = $true  },
    @{ Value = "READY";       GuardActive = $false },
    @{ Value = "IN PROGRESS"; GuardActive = $false },
    @{ Value = "COMPLETE";    GuardActive = $false }
)
```

**After** — `8ec683b:tests/remediation-tests-restored.ps1`, same literal:

```powershell
$phase2States = @(
    @{ Value = "BLOCKED";     GuardActive = $true },
    @{ Value = "READY";       GuardActive = $true },
    @{ Value = "IN PROGRESS"; GuardActive = $true },
    @{ Value = "COMPLETE";    GuardActive = $true },
    @{ Value = "BANANA";      GuardActive = $true },   # unknown value
    @{ Value = "";            GuardActive = $true }     # malformed / empty
)
```

Read as a diff, that is **three values flipped** — `READY`, `IN PROGRESS` and `COMPLETE` move from `$false` to `$true` — plus **two rows added**. Every one of the six now reads `GuardActive = $true`, and no row in the post-change block releases the guard. That is the hard-lock claim, stated as the complete end state rather than as a delta.

Reproduce with:

```
git show 8ec683b^:tests/remediation-tests-restored.ps1
git show 8ec683b:tests/remediation-tests-restored.ps1
```

The literal sits at lines 758-765 of the post-change file, and at the same location in the current working tree — the block survived this session's F1 rebuild unchanged, which is why the current suite still reports six states.

**On the assertion arithmetic:** only the two *added* rows change the count, because each row contributes three assertions whether its flag is `$true` or `$false` — the flag selects which branch asserts, not how many. Two added rows x three assertions = **+6**, which is exactly 154 → 160. The three flipped values change what the suite *proves* without changing what it *counts*.

### 2.2 What was written

Two rows appended to `governance/Phase -3-Regroup/README.md`, not one.

The first is the record the README conflict dropped — that this branch received the hard-lock on 2026-08-16 as `ba991166`, and by what route. The second records this session's own work, because the changelog is a living index and a 160-to-295 suite change with three guards altered is exactly the kind of event it exists to capture. Both rows state plainly that no remediation gate was closed.

---

## 3. Item 6 / CR-4 — the stale v3 digest

### 3.1 Verified by hashing, not by trust

The briefing asserted `6317299d…d998e45` is correct and said it had been verified by hashing. That is a claim about a check someone else ran, so it was re-run here:

```
$ sha256sum "governance/Phase -3-Regroup/remediation/claude_20260815_0234_phase3remediationplandeepv3.html"
6317299dfd591e0eabfd1b9184110a5d8c52ba9578b3492879758f55cd998e45
```

That matches lines 15 and 25 of `governance/Phase -3-Regroup/remediation/README.md` exactly, and contradicts line 63's `ce206cb2…a6886`. Line 63 now reads `6317299d…d998e45`.

### 3.2 The sweep, with its search term stated

The sweep matched the **8-character prefix `ce206cb2`**, not the full 64-character digest. That distinction matters, because the full digest never existed in this repository: line 63 always carried the elided form `ce206cb2…a6886`, so a full-length search would have returned zero hits and proved nothing. Confirmed — `grep -rE "ce206cb2[0-9a-f]{56}"` matches no file.

Searching the prefix across `*.md`, `*.html`, `*.ps1` and `*.txt`, excluding `node_modules/` and `.venv/`:

Counts below are **individual string matches**, not matching lines — one line in this report carries three of them.

| File | Matches | Why it is correct |
| --- | --- | --- |
| `governance/Phase -3-Regroup/remediation/README.md` | **0** | the defect, fixed — line 63 now reads `6317299d…d998e45` |
| `governance/Phase -3-Regroup/reports/Claude-Opus-5_2026-08-16_223501_...md` (this report) | 6 | §3.1 once, §3.2 four times, §5 once |
| `governance/Phase -3-Regroup/remediation/claude_2026-08-16_180846_...onboarding-prompt.md` | 1 | states the defect as CR-4 |
| `governance/Phase -3-Regroup/reports/Claude-Opus-5_2026-08-16_221444_...md` | 1 | names it as a queued next task |
| `governance/logs/actions-and-issues.md` | 1 | `act-019` closeout describing the defect |
| `governance/actions-and-issues.html` | 1 | generated mirror of `act-019` |
| `governance/site/actions-and-issues.html` | 1 | generated mirror of `act-019` |
| **Total** | **11 across 6 files** | |

**Zero matches are load-bearing digest records.** Every one is prose describing the defect, or a generated mirror of such prose. This report is counted in that total rather than excluded from it, which is why its own five appear as the largest single contribution.

Reproduce with:

```
grep -rc "ce206cb2" --include=*.md --include=*.html --include=*.ps1 --include=*.txt .
```

excluding `node_modules/` and `.venv/`. Note that `grep -c` reports fewer, because it counts *lines*; the table above counts matches, and several lines carry more than one.

The earlier draft of this section said "two remaining occurrences" and did not name its search term. That was accurate for the sweep as run and understated afterwards: the `act-019` row and its two generated mirrors were written later in this same session, and this report adds six more. A count of a string inside a document that discusses that string is self-referential by nature — which is the reason to state the search term and the counting basis rather than a bare number.

### 3.3 Finding — the changelog recorded a correction this branch never received

`governance/Phase -3-Regroup/README.md:141` reads:

> `| 2026-08-15 | Extended scanner v2 to inspect both guard implementations, isolated legacy v1 output, bounded the hard-lock description, and corrected the v3 placement digest. |`

That last clause was **false on this branch**. The correction is commit `d1ad55d`, which exists only on `remediation/phase3`. The changelog row travelled here; the one-line fix it describes did not.

This is worth naming beyond the individual defect. A changelog row is normally treated as evidence that something happened — and here it was the *only* thing asserting a correction that had not landed, on the same branch, for a full day. It also explains why CR-4 survived earlier review passes: anyone checking whether the digest had been fixed would have found a changelog row saying yes.

The clause is now true. It was made true by fixing the file, not by editing the row.

**This is a per-branch hazard, not a one-off.** Any changelog row written against work that lands on a different branch has the same failure mode.

---

## 4. Item 7 / CR-2 — `assert` as a write-safety guard

### 4.1 The defect, proved rather than asserted

`_s2.py` gated its only write with a bare assertion:

```python
count = text.count('SUPERSEDED V1')
assert count == 1, f'Expected 1, got {count}'
f.write_text(text, encoding='utf-8')
```

`python -O` strips assertions. Rather than restate that from memory, both code shapes were run under both interpreters with the guard condition deliberately violated:

| Shape | Interpreter | Exit | Result |
| --- | --- | --- | --- |
| `assert count == 1` | `python` | 1 | `AssertionError: Expected 1, got 2` |
| `assert count == 1` | `python -O` | 0 | **`REACHED WRITE`** |
| `if count != 1: sys.exit(...)` | `python` | 1 | `FAIL: expected 1 SUPERSEDED V1 banner, got 2` |
| `if count != 1: sys.exit(...)` | `python -O` | 1 | `FAIL: expected 1 SUPERSEDED V1 banner, got 2` |

Row two is the defect: under `-O` the guard vanishes and the write proceeds on a document the script has just decided is malformed.

### 4.2 The fix

```python
count = text.count('SUPERSEDED V1')
if count != 1:
    sys.exit(f'FAIL: expected 1 SUPERSEDED V1 banner, got {count}')
f.write_text(text, encoding='utf-8')
```

`sys.exit` was chosen over `raise` because the file already has three guards in exactly that shape (lines 9, 11, 13), each with a `FAIL:` prefix. Matching them keeps one idiom in a twenty-eight-line script.

### 4.3 Honest severity

The `count != 1` branch is close to unreachable in practice. Line 12 already exits if `SUPERSEDED V1` appears anywhere in the source, and the script then inserts exactly one banner — so `count` is 1 by construction. This is a defensive guard that was defensive in name only.

That does not make the fix wrong. A guard that cannot fire under `-O` is worse than no guard, because it reads as protection in review. But the finding is a correctness-of-form issue, not evidence that a document was ever corrupted, and it should not be recorded as the latter.

Live check: the script was run under both `python` and `python -O` after the change. Both exit 1 at the earlier banner-already-present guard, and the target file is unmodified.

`_s2.py` still sits at the repository root in violation of the naming standard. That remains a separate item and was not touched.

---

## 5. Gate

| Check | Result |
| --- | --- |
| Regression suite | **295 PASS / 0 FAIL** |
| `git diff --check` | clean |
| Stale digest, prefix `ce206cb2` repo-wide | 11 matches in 6 files, **all prose describing the defect or generated mirrors of it**; 0 load-bearing digest records. Full 64-char form: 0, and it never existed. Enumerated in §3.2 |
| `_s2.py` under `python` and `python -O` | both exit 1, target file unmodified |

Scope: the suite covers `tests/remediation-tests-restored.ps1` only. It does not assert anything about `_s2.py` or either README, so for these three items the suite proves *no regression*, not *correctness*. The evidence for correctness is in §2.1, §3.1 and §4.1.

---

## 6. Recommendations

### R-1 — Treat a changelog row as a claim, not as evidence (do next, cheap)

§3.2 is the general case: a row can travel to a branch on which its underlying change does not exist. The P1-01 scanner already greps prose for lifecycle statements; the same mechanism could check that a row naming a digest, a commit, or a count agrees with the file it describes.

- **Resolves:** rows that silently vouch for work absent from their own branch.
- **Does not resolve:** rows describing work with nothing checkable in them.
- **Prerequisite:** none.

### R-2 — When cherry-picking conflicts, record what the resolution dropped

The README conflict resolved to HEAD, which was the right call, and the loss was a changelog row nobody noticed for a day. A one-line note in the commit message naming what the resolution discarded would have made item 5 unnecessary.

### R-3 — Do not rename `_s2.py` as part of this work (non-recommendation)

It violates the root-directory naming standard, it is a known separate item, and renaming it in a diff about a write guard would bury the actual change. Flagged, not touched.

---

## 7. Next tasks

Group C is closed. Four items remain: 8, 9, 10 and 11.

**Option 1 — item 8, the hook installer (CR-3 / F-06). RECOMMENDED.**

Two defects in one package. `claude-hooks/README.md:3` claims "seven approved project hook commands" and then lists five, because it lists *events* and `PreToolUse` carries three. The count was raised from five to seven to satisfy the P1-01 scanner's prose regex without touching the list — the scope-narrowing pattern F-06 exists to flag. Separately, `claude-hooks/apply-hooks.ps1:40` omits `hx-permanent-policy-guard.ps1` and `hx-authority-edit-guard.ps1` from `$ourPattern`, so re-running the installer stacks registrations 7 → 9 → 11.

- **For:** it is a genuinely broken installer, it is self-contained, and it sits directly on top of the hook work just completed — the packaged-hook layout, the matchers and the parity test are all already loaded and now enforced by the suite.
- **Against:** it needs a two-run test fixture built from scratch, which the suite has no precedent for.

**Option 2 — item 11, F-05, the nine corrupted lines.**

`governance/policy/ai-runtime-acceptance-contract.md` carries nine lines mangled by a DS4-stripping regex, including the MIT attribution paragraph. Known-good blob `b7c6885132bde530dc60d7b01465ec45958fd7ef` at `04793ee`, but it cannot be restored verbatim — it reintroduces a `ds4-deepseek` profile that no longer exists, so the text must be reconstructed semantically.

- **For:** it is damage to a governance policy document, including a licence attribution, which is the most consequential thing still broken.
- **Against:** semantic reconstruction of a policy file is the one item here that plausibly needs owner review of the wording rather than just a correct fix. It also touches `governance/policy/`, which the authority-edit guard escalates by design.

**Recommendation: Option 1.** Item 8 is fully specified and finishes the hook layer while its context is loaded. Item 11 is better done as its own pass with the owner available to rule on wording.

**Flagging ahead:** item 10 carries an embedded owner question that should not be decided by an agent — the literal workstation path appears in thirteen `servers/hxs-*/pre-work-results.md` files, and those are historical records of machine state at discovery time. Rewriting paths inside them arguably falsifies a record. Raise it when item 10 is scheduled; do not fold it into a sweep.

---

## 8. Provenance and limits

- **Verified fact.** The 154-to-160 derivation (§2.1), the SHA-256 (§3.1), the four-row `-O` experiment (§4.1), the suite result and `git diff --check` are all reproducible from the commands shown.
- **No claim taken on trust.** Each of the three briefing assertions was re-derived locally before the corresponding edit was made. All three held.
- **Attestation, not evidence:** no live server was contacted and no remote endpoint was invoked. Work was local file edits, `git` plain-text queries, two local Python runs, and one local PowerShell suite run.
- **Untouched deliberately:** the four modified LangGraph phase-2 files remain uncommitted; the untracked paths under `governance/operations/` remain untracked pending owner ruling 10; `_s2.py` keeps its non-compliant name.
- **Not covered:** items 8, 9, 10 and 11; the P1-01 scanner; F-02, F-04, F-05, F-06; CR-1 and CR-3. None were run or inspected.
