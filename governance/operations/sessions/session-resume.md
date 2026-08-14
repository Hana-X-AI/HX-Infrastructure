# Session resume — 2026-08-13

Handoff for a fresh session. Written at the end of a long working day; everything below was
verified by running it, not recalled.

## Read these first

1. `CLAUDE.md`, `GOALS-AND-OBJECTIVES.md`, `SERVER-REGISTRY.md`
2. `governance/policy/risk-acceptances.md`
3. This file

## Where the project stands

| | |
| --- | --- |
| Phase 1 | **COMPLETE** — discovery and documentation, gate satisfied 7/7 |
| Phase 2 | **READY / underway** — repository consolidation and alignment |
| Phase 3 | Server implementation — not started |
| Fleet | 15 servers discovered, all roles assigned; `hxs-cp` control plane outside the fleet |
| Repository | 24 commits on `main`, HEAD `e4a61cd`, working tree clean, **nothing pushed anywhere** |
| Test suite | `tests/remediation-tests-restored.ps1` — **154 pass, 0 fail** |

**Phase 2 was redefined on 2026-08-13.** It used to mean role configuration. It now means
repository consolidation; server implementation became Phase 3. The Phase 1 gate is retired as
a *control* and kept as a dated *record* in both `GOALS-AND-OBJECTIVES.md` and the registry.

## What was done today

**Fleet discovery closed out.** All 15 servers plus `hxs-cp` documented from direct evidence.
The owner ratified the architecture v0.3 role mapping; roles and workloads were transcribed
into `SERVER-REGISTRY.md` (commit `8123965`), the FQDN column corrected to the resolving
`hxs-N.hx.local.arpa` names, all seven gate conditions ticked, `act-012` closed. Phase 2
opened, which released the Phase 1 command guard fleet-wide.

**Governance site.** Nine cross-linked HTML pages generated from the Markdown sources, plus a
standalone build under `governance/site/` that opens from disk with no network. Built by
`tools/build-governance-html.js`, `apply-nav.js`, `make-standalone.js`,
`make-report-standalone.js`. Home page: `governance/index.html`.

**Repository merge planning.** Three AI reviews converged on one plan, then on a deterministic
ledger. The frozen v3 manifest carries one record per legacy file and was independently
verified at **522/522 exact coverage** against a live query of the org repository — nothing
missing, nothing invented.

**Credential exposure found and contained.** A reused service-account/vault password and a
LiteLLM API key appeared in cleartext across legacy documentation and three review documents.
Nine occurrences redacted; git history rewritten to purge the two commits that carried the
value. Tracked as `iss-012`, still open.

**Structure.** `governance/` reorganised into `logs/`, `policy/`, `design/`, `operations/`,
`reports/`, `site/`. 83 path references rewritten across 38 files.

## Outstanding — highest priority first

1. **Rotate both credentials.** `iss-012`. The only action that actually closes the exposure;
   redaction and history rewriting reduce spread but do not neutralise a live credential.
2. **Finish the history purge.** The rewrite is done and `main` is clean, but the old
   secret-bearing commits stay reachable until these run. The classifier blocked me from
   running them; the owner must:

   ```
   git tag -d backup/pre-history-rewrite-2026-08-13
   git update-ref -d refs/original/refs/heads/main
   git reflog expire --expire=now --all
   git gc --prune=now
   ```

   Verify with: `git rev-list --all | while read c; do git grep -l "<token>" $c 2>/dev/null; done`
   — empty output means clean.
3. **Get the repository off this workstation.** `act-005`, open since 2026-08-11. 24 commits
   exist in exactly one place. The destination is valid and already owned:
   `Hana-X-AI/HX-Infrastructure`, private, 522 files, 22 commits. That action was blocked for
   two days on a misidentified repository — it named the *public personal*
   `hanax-ai/HX-Infrastructure`, not the org one. Corrected 2026-08-13.
4. **Docling distillation pilot** — see below.

## The Docling pilot — where it stopped and why

Governed by `governance/reports/claude/claude_20260813_2128_doclingdistillationpilotbriefv2.html`.
Two phases: review, then document-only execution producing `services/docling-mcp/service.md`
distilled from 198 ledger rows.

**Pre-flight result:**

| Item | Result |
| --- | --- |
| Owner decisions committed | PASS — Ansible excluded, gate retired, 15/15 roles |
| Frozen manifest identity | FAIL — pinned path missing; sha256 `9aace847…` vs pinned `260091…` |
| Sanitized historical source | FAIL — `legacy/2025-sanitized` does not exist |
| Docling ledger scope | PASS — 198 rows `lgc-064..lgc-261`, 3 never-open present, 195 eligible |
| Migration branch | not created |

**The owner waived all three failures on their own authority and pinned the override.** Do not
re-raise them. Apply the compensating controls: read only from the live org repo; never open
`lgc-134`, `lgc-260`, `lgc-261`; scan every extraction and the final output for both
credentials; keep `legacy-secret-002` inspect-only.

**Phase 2 did not start.** Three reasons, none of them the waived ones:

- Plan mode was active and blocked all writes.
- The brief's **§3 authority header could not be extracted** — the section returned empty, and
  the instruction requires it verbatim. Get that text before writing `service.md`.
- Context was exhausted. 195 rows deserve a full window; a sampled distillation labelled
  complete would be the exact overclaim this project spent the day correcting.

**To resume:** confirm plan mode is off, obtain the §3 header, then execute Phase 2 on a
dedicated document-migration branch. Hard limits stand — no SSH, no installs, no service
config, no deployment, no registry role changes.

## Standing instructions

- **No Ansible, ever.** Ruled out 2026-08-13; struck from `hx-fleet-control-server.md`. Retain
  Ansible *expertise* as conditional reference; the tool is closed.
- **No hardening** in any plan, roadmap or recommendation. Existing deferred hardening stays
  deferred. Reliability fixes are fine, framed as such.
- **Execute assigned work and report** — do not stop for approval on work already asked for.
  Ask only where a decision is genuinely the owner's and changes what gets built.
- **Never record credential values** in any document, including review documents. Name the
  location and the blast radius; never the value.
- **HTML documents get a visible in-page dark-mode toggle**, not only `prefers-color-scheme`.

## Known discrepancies, deliberately left

- `governance/reports/claude/manifestv3.jsonl` is the **frozen** baseline and contains three
  stale target paths for files that moved into `governance/logs/` and `governance/policy/`
  today. Left untouched — silently amending a frozen baseline is worse than a known
  discrepancy. Reconcile when the migration executes.
- The v3 ledger's `distill` rows carry 1:1 `target_path` values alongside `distill_target`.
  v3 fixed the earlier contradiction by adding `target_kind`; confirm intent before an executor
  follows the 1:1 paths literally.
- Nine published HTML pages remain flat in `governance/` by design. Moving them means editing
  `tools/links.json`, `apply-nav.js` and `make-standalone.js` together; deferred until after
  the merge.
- Report documents under `governance/reports/` were reorganised into per-author subdirectories outside this session; one suite reference to `GITHUB-REMEDIATION-INSTRUCTIONS.md` broke and was repointed to `reports/GitHub-Copilot/`. If more reports move, re-run the suite - it is the fastest detector of a broken governance path.
- `tests/remediation-tests-restored.ps1` still carries a temporary filename. The canonical
  `remediation-tests.ps1` path was locked by a Norton quarantine (`iss-010`); a workstation
  reboot should free it.

## Verification commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\remediation-tests-restored.ps1
```

```bash
node tools/build-governance-html.js && node tools/apply-nav.js \
  && node tools/make-standalone.js && node tools/make-report-standalone.js
```

Expect 154/0 and nine cross-linked pages. Session state should report
`phase 1: COMPLETE, phase 2: READY, registry 15, roles assigned 15`.
