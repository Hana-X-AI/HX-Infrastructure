# Item 11 — F-05, reconstructing the AI runtime acceptance contract

**Author:** Claude-Opus-5 (Claude Code, workstation session)
**Date:** 2026-08-17 00:07:52 CDT
**Branch:** `docs/phase3-remediation-evidence`
**Task:** Next-steps group E item 11 — nine lines of `governance/policy/ai-runtime-acceptance-contract.md` corrupted by a DS4-stripping regex, including the MIT attribution paragraph
**Predecessor report:** `Claude-Opus-5_2026-08-16_230620_item-8-hook-installer.md`
**Status:** COMPLETE — eleven regions across two files reconstructed; the reconstruction rule changed on evidence found mid-task, and a second damaged file was found by sweeping rather than by trusting the finding's scope.

---

## 1. Verdict

All nine damaged regions in the contract are repaired, plus two more in a second file the finding did not name. The contract now reads as continuous prose, its profile table matches what is actually on disk, and its licence paragraph states a coherent position.

**The reconstruction rule is not the one the finding implied, and this is the most important thing in this report.** The finding framed the constraint as *"the known-good blob cannot be restored verbatim because it reintroduces a `ds4-deepseek` profile that no longer exists."* That is true but narrow. The actual constraint is a recorded owner ruling, found in the removal commit itself:

> `bd894b87` — **"Owner ruling: DS4 dropped. Removed wherever it lived on this branch."**
> "Zero DS4 or DeepSeek references remain under `tests/`, `governance/policy/` or `.claude/` on this branch."

My initial reading was that a provenance and attribution record is historical and should name its source even after a profile is dropped — an attribution that names nothing attributes nothing. The commit message settles it the other way, explicitly and for this exact directory. The reconstruction therefore restores **meaning** without restoring **names**, and the report says so plainly rather than quietly making a judgment call the owner had already made.

Two further findings surfaced while doing the work. Both are the same class as the CR-4 changelog defect found earlier today — **a record vouching for work that was not done.** See §4.

Gates: AI-runtime invariants **22 PASS / 0 FAIL**; remediation suite green; `git diff --check` clean.

---

## 2. The damage, enumerated

Nine regions, established by diffing the working file against the known-good blob rather than by eye.

```
git cat-file -p b7c6885132bde530dc60d7b01465ec45958fd7ef   # the pre-strip original at 04793ee
diff -u <that> governance/policy/ai-runtime-acceptance-contract.md
```

Blob and commit both verified present: `git cat-file -t` returns `blob`, and `git ls-tree -r 04793ee` resolves it to this exact path.

| # | Line(s) | Damage |
| --- | --- | --- |
| 1 | 23 | `DwarfStar` survived the strip — the source project's own name, of which `DS4` is the abbreviation |
| 2 | 100 | `Mined from exact sampled representation, using…` — subject deleted, sentence ungrammatical |
| 3 | 126 | Profile table row reduced to `` | ` live later | … | `` — orphan backtick, wrong column count |
| 4 | 128 | `**The experimental classification applies to the ` not to any server.**` |
| 5 | 164 | `- It does not adopt ` ` — orphan backtick, sentence truncated mid-clause |
| 6 | 170 | `Design inspiration only — the reviewedzip`, SHA-256` — words fused |
| 7 | 172 | `` `github.com/antirez/ MIT licensed, copyrightc authors and the ggml authors.`` — **the MIT attribution line** |
| 8 | 174 | `**No** The patterns adopted —` — the "no source was copied" claim decapitated |
| 9 | 180-181 | `Facts asserted about` / `inference engine targeting not a general GGUF runner` |

Region 8 is the one that mattered most. `**No DS4 source code was copied into HX.**` had been reduced to `**No**`, which deletes the single sentence in the document that states HX's licence position.

---

## 3. The reconstruction

Names removed by the ruling; meaning restored.

| Region | Reconstructed as |
| --- | --- |
| 1 | "a reviewed third-party inference-runtime snapshot" |
| 2 | "Mined from the reviewed runtime's tool-call replay mechanism: it keeps a bounded map from tool ID to the exact sampled representation, using canonical re-rendering only as a fallback…" |
| 3 | Row **deleted**. Replaced by a sentence recording that a cross-runtime profile is a valid future addition and none is declared today |
| 4 | "**A profile's status classification applies to the runtime profile, not to any server.**" — keeps the governance point without an experimental profile to attach it to |
| 5 | "It does not adopt any third-party agent framework as an HX orchestration framework." Plus a restored second clause for the deleted DSML line: "It does not adopt any third-party markup or serialization format as an HX format." |
| 6-7 | Snapshot identified by its SHA-256 rather than by name or URL; MIT licence and the ggml copyright retained |
| 8 | "**No source code from that snapshot was copied into HX.**" |
| 9 | "it is a narrow inference engine targeting a single model family, not a general GGUF runner" |

### 3.1 The licence question, handled explicitly

Dropping the upstream URL and the named copyright holder from an MIT-related paragraph deserves a stated justification rather than a silent edit.

The contract's own text supplies it: **"No MIT notice obligation is triggered by idea reuse; had source been copied, the notice and source path would be recorded here."** No source was copied — that is the document's standing claim, restored in region 8 — so no notice obligation exists and there is nothing the ruling can suppress that the licence requires.

Two safeguards were added rather than assumed:

- The **SHA-256 is retained** as the snapshot's identifier. The provenance record still points at exactly one artifact; it simply points by hash instead of by name.
- A sentence now states that the ruling **would not override a notice obligation** if source were ever copied. Without it, a future reader could read the redaction as precedent for suppressing a real attribution. That is the failure mode worth writing down.

### 3.2 The profile table now matches the filesystem

Before, the table listed three profiles. On disk:

```
tests/ai-runtime/profiles/
├── offline-fixture.json
└── vllm-qwen.json
```

Two. The third had been deleted by `bd894b87` and its table row left behind as wreckage — so the contract advertised a profile that could not be selected. The table now lists exactly the two that exist.

---

## 4. Findings — two records that vouched for work not done

### 4.1 A repair commit that repaired one line break

`5a134cad`, **"Repair prose damaged by the DS4-stripping regex"**, is already an ancestor of HEAD. Its entire effect on this file:

```diff
-Mined from
-exact sampled representation, using canonical re-rendering only as a fallback, because
+Mined from exact sampled representation, using canonical re-rendering only as a fallback, because
```

It joined two broken lines into one still-broken sentence. Eight other damaged regions, including the decapitated licence claim, were untouched. The commit title asserts the repair; the commit performs a reflow.

This is why F-05 survived: anyone checking whether the prose damage had been repaired would find a commit saying yes.

**This is the third instance of the same pattern today** — after the CR-4 changelog row that claimed a digest correction this branch never received, and the `claude-hooks/README.md` count raised from five to seven to satisfy a prose regex without correcting the list. Three different records, three different authors, one shape: **the artifact that reports the work is easier to update than the work.**

### 4.2 The removal commit's own completeness claim was false

`bd894b87` closes with:

> "Zero DS4 or DeepSeek references remain under `tests/`, `governance/policy/` or `.claude/` on this branch."

It was true of neither `governance/policy/` nor `tests/`.

In the contract, line 23 read "the reviewed **DwarfStar** snapshot", and the mangled provenance text still carried `antirez/` and `.c authors`. A strip keyed on the string `DS4` cannot see the same project written as `DwarfStar` — the abbreviation and the expansion are different strings for one entity.

**A second file carried the identical damage.** Sweeping all three named directories rather than only the file the finding pointed at turned up `tests/ai-runtime/README.md:104-105`:

```
Design inspiration from the reviewed DwarfStar snapshot, upstream
`github.com/antirez/ MIT licensed. **No** The adopted ideas —
```

Same regex, same two failure modes in one place: the surviving `DwarfStar` and `antirez/` names, and the same decapitated `**No** ` licence claim. F-05 named nine lines in one file; there were eleven across two. It is repaired to match the contract, and it defers to the contract for the SHA-256 and the full licence position rather than restating them.

The claim was verifiable when written and was not verified. It is true now — `grep -rin "ds4\|deepseek\|dwarfstar\|antirez"` across `governance/policy/`, `tests/` and `.claude/` returns nothing.

---

## 5. Gate

| Check | Result |
| --- | --- |
| AI-runtime invariant suite | **22 PASS / 0 FAIL** — includes "runtime acceptance layer is preserved" |
| Remediation regression suite | **305 PASS / 0 FAIL** |
| `git diff --check` | clean |
| Forbidden names across `governance/policy/`, `tests/`, `.claude/` | **0** — `ds4`, `deepseek`, `dwarfstar`, `antirez`, case-insensitive |
| Unmatched backticks outside code fences, same scope | 0 |
| Profile table vs `tests/ai-runtime/profiles/` | 2 rows, 2 files, exact match |
| Files repaired | 2 — the contract, and `tests/ai-runtime/README.md` |

Scope: the invariant suite proves the acceptance layer's structural rules still hold. **Neither suite asserts prose quality** — no test would have caught the original corruption, and none catches its repair. The evidence for correctness here is the diff against the known-good blob in §2, not a green gate. See R-2.

---

## 6. Recommendations

### R-1 — This edit is reversible if the ruling is read differently (owner call)

The ruling is unambiguous about names. If the intent was narrower — drop the runtime and its profile, keep the provenance record complete — then §3.1's redaction should be undone and the upstream named again. The SHA-256 is retained precisely so that decision stays available without archaeology.

- **Trigger to revisit:** any future decision to publish this repository, where an unnamed design source reads worse than a named one.

### R-2 — A prose-integrity check would have caught all nine regions (do with item 9)

Every one of the nine is mechanically detectable: an odd backtick count outside code fences, a Markdown table row whose column count differs from its header, a bolded span opened and not closed, a line ending mid-clause. That is a lint, not a judgment.

Item 9 (F-02) already involves running a repo-wide scan with a documented exclusion list. Adding these checks there costs little and covers every governance document, not just this one.

- **Resolves:** silent regex damage to prose, repo-wide.
- **Does not resolve:** semantically wrong prose that parses cleanly.
- **Prerequisite:** none.

### R-3 — Treat a bulk find-and-replace over prose as a change requiring evidence

All three of today's "record ahead of reality" findings trace to the same habit: a mechanical edit, a confident commit message, no verification pass. A regex that edits documentation should be followed by a diff review of every touched file, and the commit message should state what was checked rather than what was intended.

---

## 7. Next tasks

Items 9 and 10 remain. They overlap and should be planned as one sweep, not taken separately.

**Option 1 — items 9 and 10 together, scoped first. RECOMMENDED.**

Item 9 (F-02) re-runs the P1-01 exit gate repo-wide instead of against its eleven-file allowlist, then fixes the 38 stale lifecycle statements outside it — including the published site at `governance/index.html` and `governance/site/`, and the generator at `tools/page-bodies/`. Item 10 sweeps the literal workstation path out of 26 tracked files. Both walk the same file set. Fold in R-2's prose lint while the scan is being rebuilt.

- **For:** one pass over the file set instead of three; R-2 lands where it is cheapest; historical reports take dated supersession banners rather than rewrites, which is one decision applied once.
- **Against:** it is the largest remaining piece of work by a wide margin, and it carries an owner question that must be answered before the sweep runs, not after.

**Option 2 — item 9 alone, leave item 10 for later.**

- **For:** smaller, and F-02 is the more consequential of the two.
- **Against:** guarantees a second pass over the same files, and item 10's own baseline ("26 tracked files") shifts every time item 9 edits one of them.

**Recommendation: Option 1, but answer the owner question first.**

**Owner question, blocking item 10 only:** the literal workstation path appears inside thirteen `servers/hxs-*/pre-work-results.md` files. Those are historical records of machine state at discovery time, and `governance/documentation-standards.html` states that raw terminal output "is evidence… preserved byte for byte." Rewriting paths inside them arguably falsifies a record. The options are (a) leave all thirteen untouched and scope item 10 to runnable scripts and current docs only, or (b) redact them with a visible marker noting the redaction. I recommend (a). This is a ruling, not a fix, and I will not decide it.

---

## 8. Provenance and limits

- **Verified fact.** The nine damaged regions come from a diff against blob `b7c6885132bde530dc60d7b01465ec45958fd7ef`, whose existence and path at `04793ee` were both confirmed. The `bd894b87` and `5a134cad` quotations are `git log -1 --format=%B` and `git diff` output. The forbidden-name sweep, backtick check, and profile-table comparison are reproducible from §5.
- **Judgment, stated as such.** Which words replace the removed names is authorial. The rule they follow — restore meaning, restore no names — is derived from the owner ruling quoted in §1, not chosen by me. §3.1's licence reasoning is mine and is flagged for owner review in R-1.
- **Changed approach mid-task.** I began intending to restore the upstream name on the grounds that an attribution record should name its source, and reversed on finding the ruling in `bd894b87`. Recorded because the discarded reasoning is the reasoning a future reader is most likely to repeat.
- **Attestation, not evidence:** no live server was contacted and no remote endpoint was invoked. Work was local file edits, `git` plain-text queries, and two local PowerShell suite runs.
- **Swept, not assumed.** Rather than repairing only the file the finding named, all three directories the removal commit claimed clean — `governance/policy/`, `tests/`, `.claude/` — were swept for both failure modes: surviving names, and odd backtick counts outside code fences. That is how the second damaged file was found. Both checks now return zero across that scope.
- **Not covered:** items 9 and 10; the P1-01 scanner; F-02; CR-1. None were run or inspected. The sweep above covered three directories, not the whole repository — R-2 would extend it.
