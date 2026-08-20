# governance contract

## purpose

Define how HX-Infrastructure governance records are maintained without turning review history into competing project policy.

## ownership

This contract owns:

```text
governance/
├── actions-and-issues.md
├── lessons-learned.md
├── risk-acceptances.md
└── reports/
```

## local contracts

### actions and issues

Use only `actions-and-issues.md` for routine project actions and issues.

- `Type` is `action` or `issue`.
- update the existing row as status changes;
- record final resolution in the same row;
- do not create separate routine action-item or issue documents.

Open actions do not automatically become phase gates. A task blocks a phase only when the authoritative project gate or contract says it does.

### risk acceptance

Read `risk-acceptances.md` before reporting governance or security risks.

Do not re-report an active accepted risk unless:

- its review or expiry trigger has been reached;
- observed conditions exceed the accepted scope; or
- new evidence materially changes likelihood or impact.

Risk acceptance does not mean the risk is resolved.

### lessons learned

`lessons-learned.md` records the generalisable takeaway from a defect or surprise, not the defect itself.

- the defect belongs in `actions-and-issues.md`; the lesson links back to it;
- add a row only when the lesson changes how future work should be done;
- do not restate project policy, and do not record credential values;
- keep existing rows stable; supersede rather than rewrite history.

### reports

Files under `reports/` are review records.

- Preserve the historical meaning of an existing report.
- Prefer a new report for a new review rather than rewriting prior findings.
- A report may recommend a change but does not override the authoritative project contract, registry, or accepted governance decision.
- When a report conflicts with authoritative project state, document the conflict and use the authoritative source.

Never record credential values in governance files.

## work guidance

- Keep governance entries concise and operational.
- Separate current project state from reviewer commentary.
- Do not convert low-priority observations into blockers without an authoritative gate change.
- Close or resolve entries only when evidence supports the status change.
- Preserve stable identifiers for existing actions, issues, and accepted risks.

## verification

Before completing a governance change:

- check that existing identifiers were preserved;
- confirm status changes are supported by evidence;
- confirm accepted-risk handling is consistent with `risk-acceptances.md`;
- confirm no secrets were copied into governance records;
- verify references to project files use their current paths.

## child dox index

No child `AGENTS.md` is required under `governance/reports/` at this time.
