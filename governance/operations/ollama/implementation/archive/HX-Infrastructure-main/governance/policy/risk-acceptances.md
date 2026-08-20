# Risk Acceptances

This register records risks that remain present but have been explicitly accepted for a limited scope and duration. An accepted risk is not resolved.

## Status Values

`accepted` · `expired` · `withdrawn` · `remediated`

## risk-001 — Bootstrap credential strength and disclosure

**Status:** accepted  
**Risk:** Bootstrap administrator credentials do not yet meet the long-term credential baseline and must be treated as disclosed.  
**Scope:** Initial project setup only.  
**Existing controls:** The local environment file is excluded from Git, and tracked documentation contains no secret values.  
**Accepted by:** Project owner  
**Accepted on:** 2026-08-10  
**Review / expiry trigger:** Phase 1 gate review or before Phase 2 begins, whichever occurs first.

## risk-002 — Bootstrap credential-file permissions

**Status:** accepted  
**Risk:** Additional local principals can read or modify the bootstrap credential file through inherited filesystem permissions.  
**Scope:** Initial project setup only.  
**Existing controls:** The credential file remains local, is excluded from Git, and is used only on the controlled setup workstation.  
**Accepted by:** Project owner  
**Accepted on:** 2026-08-10  
**Review / expiry trigger:** Phase 1 gate review or before Phase 2 begins, whichever occurs first.

## risk-003 — Legacy history preservation and public visibility

**Status:** accepted
**Accepted by:** Project owner
**Accepted on:** 2026-08-14

**Supersedes:** the prior requirement to rewrite the 2025 lineage into a sanitized
`legacy/2025-sanitized` ref. That requirement is retired and is not a definition-of-done for
any migration.

**Authoritative historical source**

```
ref:    legacy/2025
commit: a98846d6930f7b0097e7ac237c93b60280f99e44
```

It intentionally preserves the original 2025 history **without rewrite**. It is a raw,
protected archive — **not a sanitized lineage**. No session may describe it as "sanitized".

**Risk:** the archive retains historical credential classes in history, and the repository is
public, so internal network topology, hostnames, fleet architecture and service-account
patterns are publicly readable.

**Conditions, all met at acceptance:**

- Historical credential classes `legacy-secret-001` and `legacy-secret-002` are determined
  dead, non-live or revoked as applicable, by the owner. A future scan hit on either is to be
  read as known-dead, not as live exposure.
- Current `main` contains none of their literal values.
- The historical ref is explicitly **non-authoritative** — evidence and lessons only.
- The branch is protected from mutation and deletion: `lock_branch`, force-push disabled,
  deletion disabled, enforced for admins.
- Migration agents consume it only through the ledger and provenance controls.
- **Public repository visibility is an explicitly accepted owner decision**, ratified
  2026-08-14, for this dev/test/demo project.

**Review / expiry trigger:** a change of project posture from dev/test/demo, or any evidence
that a credential class previously assessed as dead is in fact live.

## Reporting Rule

Do not re-report an active accepted risk unless its review or expiry trigger has been reached, observed conditions exceed its documented scope, or new evidence materially changes its likelihood or impact.
