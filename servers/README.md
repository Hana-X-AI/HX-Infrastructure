# Server Records

One directory per server, named for the hostname the host reports:

```text
servers/<hostname>/
```

## File set

```text
pre-work-results.md    human preparation record, written before discovery runs
discovery.md           the server as found — Phase 1
driver-results.md      only where an approved driver directive was executed
configuration.md       the configured state — Phase 2 only
```

`pre-work-results.md` and `discovery.md` exist for every discovered server. The other two
are present only where they apply.

## Rules

- Never rewrite `discovery.md` to reflect later configuration. Record an approved
  post-discovery change in a clearly separated section of the same file, or in
  `driver-results.md`.
- The raw terminal output inside `pre-work-results.md` is evidence. Preserve it byte for
  byte; add structure above it, never to it.
- Take a server's IP address from `SERVER-REGISTRY.md`, not from a terminal paste.

Naming and layout rules for the whole repository are in
`governance/policy/documentation-standards.md`.
