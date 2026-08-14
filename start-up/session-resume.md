# Session resume — HX-Infrastructure

**Written:** 2026-08-14
**Repo state at handoff:** `main` @ `5a134cadae922d09e91c33f5f95182ec97bda326`, clean, pushed.

Read this first, then the four documents `CLAUDE.md` names. This file tells you where things
stand and what not to re-litigate; it does not replace the governing documents.

---

## 1. Repository shape — consolidation is DONE

Two branches exist on origin. That is the intended end state.

| Ref | SHA | Meaning |
| --- | --- | --- |
| `main` | `5a134ca` | The 2026 lineage. All three workstreams consolidated. 229 files. |
| `legacy/2025` | `a98846d` | Protected 2025 archive, 522 files. **Never modify, never delete.** |

The two histories are **deliberately unrelated** — `git merge-base main legacy/2025` is empty, and
that is correct, not a defect. `legacy/2025` is the read-only source of record for legacy mining.

`migration/docling-pilot`, `migration/langgraph-pilot` and `feature/ai-runtime-acceptance` were
merged into `main` and deleted. Their tips remain reachable from `main`'s history. The
`HX-AI-Runtime` worktree was removed; there is one worktree now.

**Phase 1 is COMPLETE, Phase 2 is READY.** 15 servers, all discovered, all roles assigned.

---

## 2. Standing owner rulings — do NOT re-litigate

| Ruling | Date | Status |
| --- | --- | --- |
| **Ansible is ruled out** entirely. Keep the expertise, never propose the tool. | 2026-08-13 | permanent |
| **DS4 is dropped.** Removed everywhere. Zero references remain. | 2026-08-14 | permanent |
| **Migration method accepted as the repository standard**, no longer a pilot. | 2026-08-14 | `governance/policy/migration-method-decision.md` |
| **Qwen3.5-9B is the 8 GB model choice.** | 2026-08-14 | settled |
| **Decision 3: LangGraph runs as the PACKAGED SERVER.** | 2026-08-14 | FINAL |
| **Decision 1: Qwen stays loopback-only; remote consumption only via OmniRoute.** | 2026-08-14 | FINAL |
| **Decision 4: MCP tool plane stays CURRENT REQUIRED.** | 2026-08-14 | FINAL |
| **LiteLLM is superseded by OmniRoute** in target state. | 2026-08-14 | applied |
| **No hardening in plans.** Reliability fixes are fine, framed as such. | standing | permanent |

---

## 3. Two principles now enforced by the migration pattern

Both were earned by failures in this repository. They apply to all future work.

- **P-A — gate construction.** A validation gate must specify **how** it verifies, not only the
  property it claims. A gate that names the right property but cannot fail is worse than none:
  it ships confidence. *(Earned by `iss-018`.)*
- **P-B — acceptance scope.** An acceptance states exactly what it authorizes and how that was
  verified, never more. Materially different scopes become **distinct acceptance states**.
  *(Earned by `iss-017`.)*

A workstream's **method** pass is independent of its **design** acceptance. A method producing a
failing, corrected design is a success.

---

## 4. What is parked, and why

**LangGraph — `services/langgraph/service.md` — REVISED / NOT ACCEPTED — PARKED.**
Implementation NOT authorized. hxs-11 deployment NO-GO.

The distillation **pilot is complete and successful**: its purpose was to validate the migration
method against a stateful orchestrator with six live integration boundaries, and it did — five
independent capability reviews, all FAIL, each finding something the authoring context could not
see. The design not reaching acceptance is a **separate outcome** from the method being proven.

The five FAIL findings are the **implementation-correction backlog** (`iss-019`), to be worked when
LangGraph implementation is scheduled. **Do not re-derive or re-review them now.** Verdicts and
findings: `governance/operations/langgraph/Claude-Opus-5_2026-08-14_langgraph-review-verdicts.md`.

Highest-value items in that backlog, so they are not rediscovered from scratch:

- The packaged server exposes `/store`, `/mcp`, `/a2a` and webhooks **enabled by default**; all
  four must be disabled at deploy, or LangGraph becomes an MCP *server* and durable memory becomes
  network-reachable.
- The base object store **cannot be disabled** and is fully functional without an index; the
  requirement is to make it *unreachable*, not merely unused.
- Redis is a **hard health-gated run-queue dependency** of that mode, and must point at hxs-9.
- `STRICT_MSGPACK` **requires an allowlist** or it degrades checkpoints silently on resume.

---

## 5. Open items

| ID | State | Subject |
| --- | --- | --- |
| `iss-019` | backlog | LangGraph implementation-correction backlog (above) |
| `iss-017` | open | Accepted Qwen capability unreachable from hxs-11/hxs-8; OmniRoute mechanism undefined. Also: registry and acceptance record disagree about hxs-4's workload — **unruled** |
| `iss-015` | open | hxs-4 endpoint silently truncates over-limit prompts to 32,770 tokens. Affects **any** client that can exceed the window |
| `iss-016` | open | Claude Code not qualified against that endpoint. Owner noted it will likely never target it |
| `act-015` | open | LangGraph pilot record |
| `iss-010` | open | Norton quarantine holds `tests/remediation-tests.ps1`; suite runs as `tests/remediation-tests-restored.ps1`. A reboot releases the handle |
| `iss-011` | open | hxs-15 has no VT-x exposed; firmware change, human/console work |
| `act-011` / `iss-001` | backlog | Router-side DNS does not survive reboot; `/jffs/hx-dns-load.sh` must be run manually |

---

## 6. Verification commands

Run these before and after any substantive change.

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\remediation-tests-restored.ps1
   expect: 154 pass / 0 fail

powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\ai-runtime\hx-runtime-invariants.tests.ps1
   expect: 22 pass / 0 fail

sha256sum governance/reports/claude/manifestv3.1resolved.jsonl
   expect: 64eb356f5b22d39c4705e2babb48a16fe6a20e3fa4d5747cba6ed7516c64cd59
```

The resolved ledger is **frozen**. If its hash changes, stop — something has mutated a pinned
artifact. `*.jsonl` is normalised to LF by `.gitattributes` precisely because an editor once
rewrote it with CRLF and broke the pin.

---

## 7. Traps this repository has already hit

Each of these cost real time. They are recorded so they are not repeated.

- **Verify a commit by its contents, never by its message.** A `git add` with a pathspec for an
  already-deleted directory fails the *entire* add; the commit then carried a message describing
  work it did not contain.
- **Prefer vendor source over vendor prose** when a source drop is available. Claims were made
  three times from a README while the shipped code on disk contradicted it.
- **Never remove a term from prose with a regex that deletes to a clause boundary.** It takes the
  surrounding words with it. Removing a reference is an edit, not a substitution.
- **Count coverage per row, never by pattern.** A loose regex once inflated a coverage figure.
- **Scan filenames NUL-delimited.** `git ls-files` quotes paths containing spaces.
- **`git add -A` catches vendored clones.** They are gitignored now, and `core.safecrlf` will
  refuse them anyway — that refusal is the protection working.
- **On a single-GPU host, unload before changing context size.** Overcommit wedges the NVIDIA
  kernel context into unkillable D-state; only a reboot clears it.
- **SME review outputs must be committed as artefacts.** A reviewer could not adjudicate eight of
  its own prior findings because they existed only in conversation (`act-018`).

---

## 8. Where to look

| For | Read |
| --- | --- |
| Project constitution | `GOALS-AND-OBJECTIVES.md` |
| Fleet facts, roles, placement | `SERVER-REGISTRY.md` — authoritative for host/role |
| Legacy mining method | `governance/policy/repository-migration-pattern.md` |
| Method acceptance + P-A/P-B | `governance/policy/migration-method-decision.md` |
| What a runtime is accepted for | `governance/policy/runtime-acceptance-decisions.md` |
| Engine-neutral acceptance contract | `governance/policy/ai-runtime-acceptance-contract.md` |
| Accepted risks | `governance/policy/risk-acceptances.md` — read before reporting any risk |
| All actions and issues | `governance/logs/actions-and-issues.md` — the **only** routine tracker |
| Capability contracts | `.claude/agents/` |

Vendored upstream source drops live under `governance/operations/` (`langgraph-main`, `ollama`,
`vllm`). They are **gitignored reference material** — read them for source verification, never
commit them.

---

## 9. Suggested next steps

Not instructions — the owner decides. Listed so a fresh session has orientation.

1. **Nothing is blocked waiting on me.** Consolidation is complete and the tree is clean.
2. If LangGraph implementation is scheduled, start from `iss-019` and the verdicts artefact.
3. `iss-017` carries an **unruled** conflict: the registry assigns hxs-4 `Qwen2.5-3B` plus the
   embedding/rerank plane, while the acceptance record places `Qwen3.5-9B` on the same 8 GB card.
   Someone must rule which authority governs.
4. Phase 2 is READY but not begun. Phase 2 work is per-server role configuration and requires its
   own authorization.
