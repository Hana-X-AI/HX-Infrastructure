# Repository migration pattern

Frozen 2026-08-14 from the Docling MCP distillation pilot. This is the reusable template for
every subsequent capability migration, LangGraph next.

The pilot's value was not the Docling document. It was proving which controls actually catch
mistakes and which only look like they do. What follows is the set that caught something real.

## The four parts

| Part | Artifact |
| --- | --- |
| Ledger | `governance/reports/claude/manifestv3.1resolved.jsonl` |
| Provenance | `governance/reports/claude/provenance-index.jsonl` |
| Capability contracts | `.claude/agents/<capability>.md` |
| Acceptance gates | run before any commit, no waivers |

## 1. Ledger schema

One record per legacy file. 522 records covering every capability; a migration works its own
slice by `owner_capability`.

**Two identities, both recorded, never conflated.**

```
manifest_base_sha256      the immutable incoming artifact — verify BEFORE any work
manifest_resolved_sha256  after resolution — this is what provenance and acceptance bind to
```

Base is verified first and never modified. Only two edits are permitted after verification:
resolve `repath_required` targets against the real current tree, and set
`provenance.source_ref` / `provenance.source_commit`. **Never** change IDs, dispositions,
classifications, policy decisions or schema semantics. If a row looks mis-dispositioned, note
it in the return package.

**Invariants, all asserted at acceptance:**

- record count, unique IDs and unique legacy paths all agree
- no `historical` or distill row carries a current-tree `target_path` — that dual field was the
  1:1-copy ambiguity the pilot found, and v3.1 fixed it by nulling `target_path`
- zero `repath_required` remaining
- every governance destination resolves to a path that exists
- dispositions identical to base

**Source provenance is a single layer.** There is no sanitize step. `source_ref` names the
protected archive; `source_commit` names the exact snapshot read, which is not necessarily a
file's last-modified commit.

## 2. Provenance model

Provenance must reproduce the exact historical object that was read. Anything less proves which
ledger row was cited, not which version of it.

Every record binds:

```
manifest_base_sha256 · manifest_resolved_sha256 · ledger_id · legacy_path ·
source_repo · source_ref · source_commit · source_path · source_sha256 ·
read_from · distillation_status · distilled_into · reviewed_by ·
migration_status · migration_commit
```

Rules:

- **Verify the hashes, do not trust them.** Recompute every `source_sha256` against the archive
  tip. The Docling pass verified 522 with 0 mismatches; a mismatch means the ledger and the
  archive disagree and work stops.
- `distillation_status` is `used`, `reviewed-not-used`, or `blocked`. Every `used` row carries
  at least one exact `distilled_into` target including the section anchor.
- **`reviewed-not-used` is a real and useful outcome.** It is the record saying a file was
  examined and did not deserve to survive. A migration where everything is `used` has not been
  filtered.
- Blocked and excluded rows: `read_from` null, an explicit reason, no invented content
  provenance. They still carry a `source_sha256` because they exist in the archive —
  present in archive, blocked from migration.
- **No false migration.** Historical rows keep `migration_status: pending`. Never flip a row to
  `migrated` because it was cited; a future executor reads that as "this file is now in main".
- **Count by row, never by pattern.** The pilot's first coverage figure was inflated by five
  rows because a loose regex swept in IDs that were never cited. Derive the counts from the
  provenance index itself.

## 3. Capability contracts and review

**Capability-first, not persona-first.** Legacy documents name people who signed off in 2025.
Those names are historical evidence and never current sign-off.

Minimum four contracts per migration, at `.claude/agents/<capability>.md`. Each defines:
`capability_id`, `purpose`, `scope`, `out_of_scope`, `authoritative_inputs`,
`historical_sources_allowed`, `prohibited_authority_sources`, `required_output`,
`validation_partner`, `activation_state`.

For Docling the four were `docling-mcp`, `infrastructure-ops`, `testing-qa`, `lightrag`. The
middle two are reusable as-is; the domain pair changes per migration.

**The authoring context does not sign its own work.** Each review runs in a separate context
against the contract. This is not ceremony — in the Docling pass the separate reviewers caught
a wrong framework name, a release-versus-tip conflation, a CUDA dependency chain on a GPU-less
host, a recommended topology whose host did not exist, and three "open" questions that ratified
documents had already settled. None of that was visible from inside the authoring context.

Each review returns: sections reviewed; current authorities consulted with version or commit
and date; findings; required corrections; unresolved verification items; and a verdict of
PASS / CONDITIONAL PASS / FAIL.

`reviewed_by` is populated only where the contract exists, the review actually ran, and the
section was in scope. Anything else stays `SME REVIEW REQUIRED`.

## 4. Acceptance gates

Run before any commit. **No waivers.** A gate that cannot fail is not a gate — prove failability
at least once per suite.

| Family | Asserts |
| --- | --- |
| SOURCE | Archive ref exists and is protected; source identity bound on every row; the ref the migration reads was not mutated |
| LEDGER | Counts and uniqueness; no historical `target_path`; zero unresolved repaths; dispositions unchanged from base; destinations exist |
| DESIGN | Authority header intact; upstream pinned to one release; owner decisions recorded, not inferred; boundary classifications present |
| SME | Contracts exist; reviews ran; `reviewed_by` reflects only real reviews |
| PROVENANCE | Row count; bound to the resolved hash; used rows carry target and source identity; blocked rows explicit; no false migration |
| SHADOW-REPO | No historical file under current `main` |
| STANDARDS | New report names match the naming rule; no spaces, non-ASCII or parentheses in any repository path |

**Scan filenames NUL-delimited.** `git ls-files` quotes paths containing spaces, so a naive
`split()` breaks them into tokens that individually look clean. The pilot's first filename gate
passed a file with a space in it for exactly this reason.

## 5. Authoring rules that survived review

- **Resolve, never translate.** Every host, address, port and version resolves from current
  authority. Never derive a current value from a legacy one. The 2025 Docling specification
  carried 245 wrong address literals across 38 files.
- **Mark, do not guess.** An unresolved current fact is `VERIFICATION REQUIRED`. That marker is
  the deliverable, not a gap in it.
- **Verify upstream at execution time.** Do not trust a version number copied into a brief. The
  Docling pass found upstream had moved two major versions and changed protocol framework since
  the material being distilled.
- **Target-state, never as-built.** The document is authoritative for intended design and
  asserts nothing about what is installed. Apply the same standard to partner services: an
  assigned role in the registry is not a running service.
- **Author from meaning, never copy text.** This is what keeps credential literals out of the
  output structurally, rather than relying on a scan afterwards.
- **State disposition of optional upstream features.** Anything that would pull the service
  across its own boundary is disabled by default and named as such.

## 6. Next application — LangGraph

The ledger already carries the slice: **213 rows, `lgc-262` to `lgc-474`**, `owner_capability`
`langgraph`, distilling to `services/langgraph/service.md`. 212 `historical`, 1 `retire`;
6 rows `secret_risk: confirmed` and 5 `inspect`.

It reuses this pattern unchanged. What changes is the domain capability pair alongside
`infrastructure-ops` and `testing-qa`, and the current-authority set for the host LangGraph is
assigned to.

## Related

- `governance/policy/risk-acceptances.md` — `risk-003` governs the archive and its visibility
- `governance/policy/documentation-standards.md` — naming and file placement
- `governance/reports/claude-code/Claude-Opus-5_2026-08-13_docling-corrective-pass-report.html`
  — the worked example this pattern is drawn from
