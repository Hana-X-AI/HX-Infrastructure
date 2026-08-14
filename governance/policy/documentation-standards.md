# Documentation and file naming standards

How files in this repository are named and where they belong. Written 2026-08-13, after a
structure review found three naming schemes running in parallel and fifteen server records
in three different shapes.

Existing files that predate this document were aligned to it where the change was safe.
The deliberate exceptions are listed at the end; they are exceptions, not drift.

## Naming rules

| Location | Rule | Example |
| --- | --- | --- |
| Repository root | `SCREAMING-KEBAB-CASE.md`, reserved for canonical project documents | `SERVER-REGISTRY.md` |
| `governance/` | `lower-kebab-case.md` | `risk-acceptances.md` |
| `governance/reports/` | `<author>_<YYYY-MM-DD>[_<HHMMSS>]_<lower-kebab-slug>.md` | `Claude-Opus-5_2026-08-13_hxs-5-to-15-discovery-report.md` |
| `servers/<host>/` | fixed file names, see below | `discovery.md` |
| `.claude/hooks/` | `hx-<function>.ps1` | `hx-phase1-guard.ps1` |
| Scripts | `lower-kebab-case` with the extension of the language | `collect-server-facts.sh` |

Rules that apply everywhere:

- **No spaces in file names.** They break shell quoting, URLs and cross-platform tooling.
- **No em-dashes or other non-ASCII characters in file names.** They survive badly through
  copy-paste, terminals and Git on Windows.
- Use a hyphen as the word separator. The underscore is reserved for the field separator in
  report names.
- The time component of a report name is optional, and is used only to disambiguate two
  reports by the same author on the same date.
- `<author>` identifies who produced the document: `Claude-Opus-5`, `GitHub-Copilot`,
  `chatgpt`, or `owner` for material written by the project owner.

## Server record file set

One directory per host, named for the hostname the host reports:

```text
servers/<hostname>/
├── pre-work-results.md    human preparation record, written before discovery
├── discovery.md           the server as found, Phase 1
├── driver-results.md      only where an approved driver directive was executed
└── configuration.md       the configured state, Phase 2 only
```

`discovery.md` is never rewritten to reflect later configuration. Where an approved change
is made after discovery, it is recorded in a clearly separated section of the same file, as
on `hxs-1` through `hxs-4`, or in `driver-results.md`.

## Pre-work record shape

Every `pre-work-results.md` follows one shape:

```text
# <hostname> — pre-work results

**Server:** / **IP address:** / **FQDN:** / **Admin account:**

## Declared hardware        counts from building the machine, not from a command
## Preparation outcome      derived from the evidence below
## Raw terminal output      verbatim, fenced, never edited
```

Two rules matter more than the layout:

- **The raw terminal output is evidence.** It is preserved byte for byte. Structure is added
  above it, never applied to it.
- **The IP address is taken from `SERVER-REGISTRY.md`**, not read out of the paste. Pastes
  contain subnet addresses, gateway addresses and unrelated hosts, and reading an address out
  of one produced wrong values on four records before this rule existed.

A four-backtick fence is used because at least one paste contains a three-backtick sequence.

## HTML pages: two outputs, one source

The governance pages exist in two forms, and the difference is deliberate.

| Location | Shape | Links | Use |
| --- | --- | --- | --- |
| `governance/*.html` | No `<!DOCTYPE>`, `<html>`, `<head>` or `<body>` | Absolute `claude.ai` artifact URLs | Published as Claude artifacts |
| `governance/site/*.html` | Fully-formed documents | Relative filenames | Opening from disk, a file server, or an exported bundle |

**The artifact form must not carry the HTML boilerplate.** The publisher wraps the source
file in its own `<!doctype html><head></head><body>` skeleton at publish time and requires
the source not to include those tags; adding them nests a second document inside the first.

**The standalone form must carry it**, plus two things the artifact form cannot supply:

- `<html lang="en">` and `<meta charset="utf-8">`, which assistive technology depends on.
- `<meta name="viewport" content="width=device-width, initial-scale=1">`. Without it a phone
  lays the page out at desktop width and scales the result down, so the `clamp()` sizing
  never engages and the responsive design is inert.

Build both from `tools/`:

```sh
node tools/build-governance-html.js   # regenerate governance/*.html from the Markdown
node tools/make-standalone.js         # derive governance/site/*.html from those
```

`tools/links.json` holds the artifact URL for each page. `make-standalone.js` fails rather
than emits if any artifact URL survives into the standalone build or if any page stops
linking to its siblings.

The two log pages are generated from `actions-and-issues.md` and `lessons-learned.md`, which
remain the source of truth. Their cells contain escaped pipes, so the parser splits only on
unescaped ones; a naive split corrupts rows.

## Deliberate exceptions

These look inconsistent and are intentional. Do not "fix" them.

| Path | Why |
| --- | --- |
| `.claude/skills/*/SKILL.md` | Claude Code requires this exact filename |
| `.claude/AGENTS.md`, `governance/AGENTS.md`, `servers/AGENTS.md` | Fixed name, resolved by directory |
| `claude-hooks/claude-hooks/hooks/` | The doubled directory is the real packaged layout. A regression test guards against the single-nested form reappearing, because that stale path was a real defect once |
| `conversations/SYNC-POLICY.md` | Predates this standard and is referenced in historical reports |
| `governance/reports/GitHub-Copilot/GITHUB-REMEDIATION-INSTRUCTIONS.md` | Referenced by the regression suite |
| Existing report file names | Archival. They are cited across the governance log; renaming them rewrites the provenance trail for no operational gain |

## What was changed on 2026-08-13

| Before | After |
| --- | --- |
| `governance/Tooling First Rule.md` | `governance/policy/tooling-first-rule.md` |
| `governance/reports/Claude Prompt — Discover GPU VRAM Without NVIDIA Drivers.md` | `governance/reports/owner_2026-08-11_gpu-vram-discovery-prompt.md` |
| `governance/reports/response to claude — gpu capability report.md` | `governance/reports/owner_2026-08-11_gpu-capability-report-response.md` |
| 15 `pre-work-results.md` in three different shapes, every IP field blank | one shape, IP and FQDN populated from the registry, evidence preserved |
| A reference to `claude-opus-5_...` that did not resolve on a case-sensitive filesystem | corrected to `Claude-Opus-5_...` |

Every reference to a renamed file was updated in the same pass, and all `governance/` paths
cited anywhere in the repository were confirmed to resolve.
