# Repository merge recommendation

Written 2026-08-13. A recommendation, not a decision. Before any remote push or other
remote write begins, record in `governance/actions-and-issues.md`:

- the accepted correction to `act-005` (wrong-repository identification resolved);
- an action for the fact-update sweep (Step 5);
- an action for mining the archive into architecture v0.3 (Step 6).

Keep `act-005` open until final remote verification is complete, then close it in the same
commit that records the verification result.

## Situation

Two repositories describe this project from different eras, and neither knows about the other.

| | `Hana-X-AI/HX-Infrastructure` | This local repository |
| --- | --- | --- |
| Created | 2025-11-15, last pushed 2025-12-04 | 2026-08-11 |
| Visibility | Private, org-owned | Local only, never pushed |
| Size | 522 files | ~110 files, 10 commits |
| Subject | 27 logical service nodes | 15 physical hosts plus `hxs-cp` |
| Addressing | `192.168.10.200-229`, `hx.dev.local` | `192.168.50.200-215`, `hx.local.arpa` |
| Root path | `/home/agent0/HX-Infrastructure` | repository-relative |
| Strength | Process: standards, templates, procedures, quality gates, agent orchestration, Python hooks, 411 files of deployment work under `nodes/` | Facts: measured hardware for every host, synced registry, discovery records, PowerShell hooks, 153-assertion suite, nine-page governance site |
| Weakness | Every fact invalidated by the relocation | Almost no process framework |

The two are complementary rather than competing. Neither is a superset of the other, and the
overlap is confined to six paths.

## Two corrections to the record

**`act-005` names the wrong repository.** It states the name is taken by "an unrelated public
Ansible project". That is `hanax-ai/HX-Infrastructure` — a different, *public* repository under
the personal account, last pushed 2025-09-17. The org repository
`Hana-X-AI/HX-Infrastructure` is private, already owned, and is a valid destination. The
action has been blocked since 2026-08-11 on a mistaken identification.

**LiteRAG was a real node.** The old inventory contains `hx-literag-server (192.168.10.220)`,
operational. The LiteRAG/LightRAG ambiguity did not come from a spec typo or an instruction;
both names are genuine in different eras. `ll-030` covers this class of stale claim.

## Recommendation

Make the org repository the single home. Merge the local work into it preserving both
histories, keep the old process framework but update its facts before treating it as current,
and freeze what the relocation invalidated under `archive/`.

| Question | Recommendation |
| --- | --- |
| Merge shape | Org repo becomes the single home; both commit trails preserved |
| What carries forward | Everything is in play, but nothing counts as current until its facts are corrected. Purge only what is irrelevant |
| Exception | `.claude/` commands and the 32-agent orchestration model — adopt selectively. Process load stays light |
| Hooks | Keep both, scoped. PowerShell for the Windows workstation, Python re-targeted for `hxs-cp` |
| Old inventory | Archive, then mine it as source material for architecture v0.3 |

### Target layout

```text
Hana-X-AI/HX-Infrastructure (main)
├── SERVER-REGISTRY.md              local — authoritative on hardware and roles
├── CLAUDE.md                       reconciled
├── servers/                        local — 16 records, unchanged
├── governance/                     local — logs, reports, HTML site
├── tools/  tests/                  local
├── standards/  templates/          remote — facts updated
├── procedures/  .quality-gates/    remote — facts updated
├── hx-agents/  nodes/              remote — facts updated
└── archive/2025-pre-relocation/    frozen, never edited
    ├── inventory/  network/
    └── README.md
```

## Sequence

**1. Make the local work safe first.** Nothing is pushed today.

Run the secret scan over the full history, working tree, and any untracked files first:

```bash
git log --all --full-history --diff-filter=A -- | xargs -I{} git show {} \
  | grep -iE '(password|token|secret|private_key|api_key)\s*=\s*[^<$({\s]'
git grep -inE '(password|token|secret|private_key|api_key)\s*=\s*[^<$({\s]'
git status --short  # review any untracked files manually
```

If the scan produces any hits, stop and investigate before continuing. Only after the scan
passes:

```bash
git remote add origin https://github.com/Hana-X-AI/HX-Infrastructure.git
git push origin main:refs/heads/import/local-2026-08-13
```

That single push removes the real risk in `act-005` even if the rest is abandoned. A zip on
the same desktop protects against a bad merge, not against losing the workstation.

**2. Integrate on a branch.**

```bash
git fetch origin
git checkout -b integrate/merge-local origin/main
git merge --allow-unrelated-histories main
```

**3. Resolve the six collisions.** Local wins on facts and on the single-log rule; the old
repo wins on process depth. After resolving all conflicts:

| Path | Resolution |
| --- | --- |
| `CLAUDE.md` | Rewrite as one file. Keep the local Phase 1/2 gates, Context7 ordering, single-log rule and credential prohibition. Adopt the old repo's Zero Assumptions Policy, which is stronger than anything local and matches how this project already works. Drop the Agent Zero framing and `/home/agent0` paths |
| `.claude/hooks/` | Both. The six PowerShell hooks are unchanged. The Python hooks are kept but not wired on Windows |
| `.claude/commands/` | Selective. Take the document-lint, status-report and handoff utilities and the spec/task workflow pair. Leave the phase machinery and 32-agent orchestration out of `main` |
| `lessons-learned.md` | `governance/lessons-learned.md` (31 entries) survives. Fold anything still true from the old root file in as new `ll-` rows, then delete it |
| `README.md` | Rewrite. The old one describes 58 repositories and 32 agents and no longer describes this repository |
| `.gitignore` / `.gitattributes` | Union the ignores. Keep the local `.gitattributes` verbatim — `* -text` plus `*.sh text eol=lf` is what resolved `iss-005` and keeps the collector free of CR bytes |

The old `defects.md`, `defect-log.md`, `raidd-log.md`, `backlog.md` and `status-report.md`
conflict with this project's own rule that `governance/actions-and-issues.md` is the only
routine tracking log. Move them to `archive/` and carry any live item across as rows.

```bash
git add -A && git status --porcelain  # must be empty before continuing
git commit -m "Step 3: resolve six-path collisions and merge tracking logs"
```

**4. Archive what the relocation invalidated.** Move `inventory/` and `network/` to
`archive/2025-pre-relocation/` without editing them, and write a README stating the old subnet,
domain and root path, and that `SERVER-REGISTRY.md` supersedes all of it.

```bash
git add -A && git status --porcelain  # must be empty before continuing
git commit -m "Step 4: archive pre-relocation inventory and network docs"
```

**5. Update everything that carries forward.** This is the bulk of the work. Nothing from the
old repository counts as current until corrected:

```text
192.168.10.          ->  192.168.50.        taken from SERVER-REGISTRY.md, never guessed
hx.dev.local         ->  hx.local.arpa
/home/agent0/...     ->  repository-relative paths
agent0               ->  hxsa
hx-litellm-server    ->  hxs-1   (or whichever host carries the LiteLLM workload, per registry)
hx-postgres-server   ->  hxs-2
hx-qdrant-server     ->  hxs-3
hx-literag-server    ->  hxs-4
hx-n8n-server        ->  hxs-5
hx-docling-server    ->  hxs-6
hx-crawl4ai-server   ->  hxs-7
hx-webui-server      ->  hxs-8
hx-<other>-server    ->  hxs-N where N is determined by the registry; never guessed
```

Scan scope: `standards/`, `procedures/`, `templates/`, `.quality-gates/`, `hx-agents/`, and
`nodes/` document headers. Explicitly exclude `archive/2025-pre-relocation/` from all
replacement passes — its contents are frozen source material and must not be edited.

Also scan `hx-agents/` and `nodes/` for residual occurrences of `agent0`, `hx-agents/`,
`nodes/`, and any `hx-<role>-server` pattern not yet remapped. `standards/naming-conventions.md` and
`governance/documentation-standards.md` both define naming and must become one document;
naming-conventions is broader, so fold the local rules into it and leave a pointer.

`.claude/hooks/hx-ip-validator-hook.py` hard-codes the old subnet. Re-targeting it at
`192.168.50.0/24` is the highest-value single fix in the sweep: it turns a stale file into a
live guard against exactly the error class this project has already hit, where an address was
read out of a terminal paste and four of fifteen came out wrong (`ll-031`).

```bash
git add -A && git status --porcelain  # must be empty before continuing
git commit -m "Step 5: update carried-forward facts; retarget IP validator to 192.168.50.0/24"
```

**6. Mine the archive for architecture v0.3.** The 27 old nodes are the service catalogue that
v0.3 is re-homing onto 15 hosts, and each entry carries responsibilities, data paths and
integration points. `hx-litellm-server`, `hx-postgres-server`, `hx-qdrant-server`,
`hx-literag-server`, `hx-n8n-server`, `hx-docling-server`, `hx-crawl4ai-server` and
`hx-webui-server` all correspond to services v0.3 already places. This is prior operational
knowledge about services that ran, not speculation.

**7. Land it.**

```bash
git status --porcelain  # must be empty — no uncommitted work before this step
git checkout main
git status --porcelain  # must still be empty after checkout
git merge --no-ff integrate/merge-local
git push -u origin main
```

## Verification

Run before pushing to `main`. Treat any failure as blocking.

```powershell
# 1. Regression suite — expected: 153 pass, 0 fail
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\remediation-tests-restored.ps1
# exit code must be 0
```

```bash
# 2. Governance site rebuild — expected: no errors, output files updated
node tools/apply-nav.js && node tools/make-standalone.js
```

```powershell
# 3. Discovery counts — expected: registry=15, discovery_complete=15, roles_assigned=0
powershell -NoProfile -ExecutionPolicy Bypass -Command "
  & .claude\hooks\hx-session-state.ps1 | ConvertFrom-Json |
  Select-Object registry, discovery_complete, roles_assigned
"
```

```powershell
# 4. Phase-guard denial — expected: permissionDecision=deny, exit 0
$payload = '{"tool_name":"Bash","tool_input":{"command":"apt install nginx"}}'
$result = $payload | powershell -NoProfile -ExecutionPolicy Bypass \
  -File .claude\hooks\hx-phase1-guard.ps1
($result | ConvertFrom-Json).permissionDecision  # must equal 'deny'
```

```powershell
# 5. All PowerShell hook pairs byte-identical (active vs packaged)
$hooks = 'hx-common','hx-notify','hx-phase1-guard','hx-session-state','hx-validate-discovery','hx-validate-subagent'
foreach ($h in $hooks) {
  $a = Get-FileHash ".claude\hooks\$h.ps1" -Algorithm SHA256
  $b = Get-FileHash "claude-hooks\claude-hooks\hooks\$h.ps1" -Algorithm SHA256
  if ($a.Hash -ne $b.Hash) { Write-Error "MISMATCH: $h"; exit 1 }
  "OK: $h"
}
# Python hooks present (wiring verified on hxs-cp, not Windows)
Get-Item .claude\hooks\*.py | Select-Object Name
```

```bash
# 6. Pushed-tree secret scan — expected: no output (zero hits)
git log origin/main --all --full-history -p \
  | grep -iE '(password|token|secret|private_key|api_key)\s*=\s*[^<$({[:space:]]' \
  || true
# .env must not appear in the tree
git ls-tree -r --name-only origin/main | grep -F '.env' && echo FAIL || echo OK
```

```bash
# 7. Stale-fact scan — expected: no output under standards/ procedures/ templates/ .quality-gates/
# archive/2025-pre-relocation/ is intentionally excluded
git grep -lE '192\.168\.10\.|hx\.dev\.local|/home/agent0' \
  -- standards/ procedures/ templates/ .quality-gates/ hx-agents/ nodes/ \
  ':!archive/'
```

```bash
# 8. Both histories present — expected: commits from both the local and remote lineages
git log --oneline --graph | head -40
# must show at least one commit from the pre-2026 remote history
git log --oneline --before=2026-01-01 | head -5
```

## What this closes, and what it does not

Closes `act-005` once `main` is pushed, and supersedes the mistaken blocker recorded against
it. Gives the process framework a current home instead of leaving it stranded in a stale
repository, and gives the fleet facts somewhere off the workstation.

It does not resolve `act-012` — the fleet capability review and role assignment are unaffected
— and it does not change `SERVER-REGISTRY.md`, which stays authoritative and still records
zero assigned roles.

Governance to write alongside the work: correct `act-005`, raise an action for the fact-update
sweep in step 5, raise an action for mining the archive into v0.3, and record the lesson that
two repositories for one project, neither aware of the other, is how a fleet ends up documented
twice and correctly nowhere.
