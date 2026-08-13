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

## Reporting Rule

Do not re-report an active accepted risk unless its review or expiry trigger has been reached, observed conditions exceed its documented scope, or new evidence materially changes its likelihood or impact.
