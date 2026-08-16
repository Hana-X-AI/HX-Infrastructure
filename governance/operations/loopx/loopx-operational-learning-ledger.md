That may be LoopX’s strongest strategic value for HX.

It does more than retain task history. It can preserve the complete improvement thread:

What failed and why
Which evidence established the cause
What correction was attempted
How the correction was validated
Which approaches were rejected
What remained unresolved
Who or what should act next
Whether the resulting lesson is reusable

That aligns naturally with HX’s desired learning loop:

incident → diagnosis → correction → validation → durable knowledge → safer future execution

The architectural distinction is important:

LoopX should preserve operational lineage: fixes, decisions, validation receipts, failed approaches, and handoffs.
Mem0 should retain reusable agent/user memory derived from accepted outcomes.
LightRAG should make approved fix records, runbooks, governance documents, and lessons searchable.
sdd-core should receive changes to durable specifications, architecture, or operating policy.
Source control remains authoritative for the actual implementation.

This suggests adding a major pilot question:

Can LoopX convert a completed correction into a validated, reusable knowledge package without creating another knowledge authority?

Ariadne should test the full cycle with one controlled defect: diagnose it, record competing hypotheses, implement and validate the correction, preserve the failure lineage, produce a compact fix-knowledge artifact, and prove that a fresh agent can use that artifact to recognize or resolve a related recurrence.

If that works cleanly, LoopX becomes much more than a continuity mechanism. It becomes the operational learning ledger connecting execution to HX’s memory and knowledge planes.

## Promotion contract

LoopX receipts and run lineage remain execution-local operational evidence. Completion does not
promote them to durable HX knowledge. Promotion is one-way and requires a separate governed change.

### Candidate package

Ariadne may write a candidate only under
`<evidence_directory>/knowledge-candidates/<knowledge_id>.yaml`. It must use this minimum schema:

```yaml
schema_version: hx-loopx-fix-knowledge-v1
knowledge_id: <stable id>
source_run_id: <pilot run id>
source_revision: <LoopX revision>
problem: <public-safe symptom>
root_cause: <validated cause>
rejected_hypotheses: [<item>]
correction: <accepted change>
validation_receipts: [<immutable receipt and hash>]
recurrence_signature: <testable signature>
remaining_limits: [<item>]
privacy_classification: PUBLIC | INTERNAL | RESTRICTED
proposed_retention_class: <class>
proposed_review_or_delete_utc: <timestamp>
proposed_destination: governance/logs/lessons-learned.md
```

Finalize the candidate before review. Do not add approvals to it or modify it after its SHA-256 is
recorded. Raw prompts, local paths, credentials, private task details, and unrestricted logs remain
in the private evidence root.

### Promotion control package

After finalizing the candidate, create
`<evidence_directory>/knowledge-promotions/<knowledge_id>.yaml` with this minimum schema:

```yaml
schema_version: hx-loopx-knowledge-promotion-v1
promotion_id: <stable id>
candidate_artifact:
  artifact_id: <knowledge id>
  path: <exact candidate path>
  sha256: <digest of exact candidate bytes>
proposed_public_record:
  artifact_id: <stable record id>
  path: <exact staged public-record path>
  sha256: <digest of exact proposed record bytes>
scanner_trust_registry:
  path: <owner-approved scanner trust-registry path>
  sha256: <pinned scanner trust-registry digest>
scanner_launch_trust_registry:
  path: <owner-approved launch-attestation trust-registry path>
  sha256: <pinned launch-attestation trust-registry digest>
approval_trust_registry:
  path: <owner-approved approval trust-registry path>
  sha256: <pinned approval trust-registry digest>
destination_change:
  change_id: <stable id>
  repository_path: governance/logs/lessons-learned.md
  operation: <exact operation>
  expected_base_revision: <repository revision>
  expected_pre_change_sha256: <digest>
  proposed_record_artifact_id: <stable record id>
  proposed_record_sha256: <digest>
  approval_trust_registry_sha256: <pinned approval trust-registry digest>
  manifest_sha256: <digest of canonical destination_change object without this field>
authorities:
  owner_identity: <retention and destination-change authority>
  testing_qa_identity: <validation authority>
  domain_owner_identity: <affected-domain authority>
  governance_identity: <privacy and governance authority>
boundary_scan_receipts:
  candidate: <receipt path and sha256>
  proposed_public_record: <receipt path and sha256>
approval_receipts:
  retention_class: <receipt path and sha256>
  review_or_delete_utc: <receipt path and sha256>
  testing_qa: <receipt path and sha256>
  domain_owner: <receipt path and sha256>
  governance: <receipt path and sha256>
  destination_change: <receipt path and sha256>
```

The four authority identities must be pairwise distinct. None may be Ariadne, the LoopX executor,
or the candidate author. A replacement authority requires an owner-recorded recusal and a new
receipt; one authority must not approve another authority's required decision.

### Boundary-scan receipts

The exact candidate bytes and exact proposed-public-record bytes must each pass the approved
boundary and secret scan. Each referenced receipt must use this schema:

```yaml
receipt:
  schema_version: hx-boundary-scan-receipt-v2
  receipt_id: <stable id>
  artifact_id: <candidate or proposed-record id>
  artifact_path: <exact path>
  artifact_sha256: <digest of scanned bytes>
  scanner_identity: <executable path, version, and sha256>
  scan_policy: <policy path, version, and sha256>
  scanner_trust_registry_sha256: <pinned scanner trust-registry digest>
  scanner_launch_trust_registry_sha256: <pinned launch-attestation trust-registry digest>
  scanner_execution:
    launch_schema: hx-sandbox-launch-receipt-v1
    launch_receipt_id: <trusted scanner launch receipt id>
    launch_receipt_sha256: <launch receipt digest>
    exit_status: <observed integer exit status>
    structured_output_sha256: <digest of exact scanner output>
  scanned_at_utc: <timestamp>
  result: PASS | FAIL
  findings: [<finding ids>]
attestation:
  format: hx-boundary-scan-receipt-ed25519-v1
  algorithm: Ed25519
  key_id: <scanner signing key id>
  receipt_sha256: <digest of canonical receipt object>
  signature_base64url: <detached signature>
```

Authenticate the referenced scanner launch receipt and its signature under
`hx-sandbox-launch-receipt-v1` against the pinned `scanner_launch_trust_registry`. Require its
runner, scanner identity, tokenized invocation, scan policy, artifact hash, process ancestry, and
structured-output hash to match this receipt. The recorded exit status must match the observed
process result and be zero.

Canonicalize `receipt` as RFC 8785 JSON and recompute its lowercase SHA-256. Compare that digest to
`attestation.receipt_sha256` and reject a mismatch before signature validation. Then verify the
detached Ed25519 signature over the UTF-8 bytes of
`HX-BOUNDARY-SCAN-V1\n<receipt_sha256>\n`. Resolve `key_id` only through the pinned
`scanner_trust_registry`; require the registry to bind the key to `scanner_identity` and
`boundary-scan` use, and check key validity and revocation at verification time.

A receipt counts only when its schema, receipt hash, launch attestation, signature, approved scanner
and policy identities, registry hash, artifact ID, path, recomputed artifact hash, exit status, and
structured-output hash match; its result is `PASS`; and its findings are empty. Any change to either
artifact invalidates its scan receipt and all later approvals.

### Approval receipts

Every approval reference must resolve to a verifiably signed receipt with this common schema:

```yaml
receipt:
  schema_version: hx-learning-promotion-approval-v2
  approval_id: <stable id>
  approval_type: retention_class | review_or_delete_utc | testing_qa | domain_owner | governance | destination_change
  authority_identity: <identity named for this approval type>
  candidate_artifact_id: <knowledge id>
  candidate_sha256: <exact approved candidate digest>
  destination_change_id: <exact approved change id>
  destination_change_sha256: <destination change manifest digest>
  destination_repository_path: governance/logs/lessons-learned.md
  proposed_record_artifact_id: <stable record id>
  proposed_record_sha256: <exact approved public-record digest>
  approval_trust_registry_sha256: <pinned approval trust-registry digest>
  approved_value: <retention class, review/delete timestamp, or approval-specific value>
  decision: APPROVED | REJECTED
  signed_at_utc: <timestamp>
attestation:
  format: hx-learning-promotion-approval-ed25519-v1
  algorithm: Ed25519
  key_id: <authority signing key id>
  receipt_sha256: <digest of canonical receipt object>
  signature_base64url: <detached signature>
```

Canonicalize `receipt` as RFC 8785 JSON and recompute its lowercase SHA-256. Compare that digest to
`attestation.receipt_sha256` and reject a mismatch before signature validation. Then verify the
detached Ed25519 signature over the UTF-8 bytes of
`HX-LEARNING-PROMOTION-APPROVAL-V1\n<receipt_sha256>\n`. Resolve `key_id` only through the
promotion package's pinned `approval_trust_registry`. The registry must bind the key to the exact
`authority_identity` and permitted `approval_type`, provide the Ed25519 public key and validity
interval, and show that the key is not revoked at verification time.

The owner signs separate `retention_class`, `review_or_delete_utc`, and `destination_change`
receipts. Testing/QA, the domain owner, and governance each sign only their named receipt. All six
receipts must have `APPROVED` decisions, trusted signatures, the expected authority identity, and
identical candidate, destination-change, repository-path, proposed-record, and approval-trust-registry
bindings. A changed hash, trust registry, path, base revision, operation, approved value, or authority
invalidates the affected receipt and every receipt that depends on it.

### One-way promotion

1. Freeze and hash the candidate, proposed public record, and destination-change manifest.
2. Validate both boundary-scan receipts against the frozen artifact bytes.
3. `testing-qa` verifies that the candidate matches accepted receipts and signs its bound approval.
4. The affected domain owner accepts the technical lesson and recurrence signature by signed bound
   approval.
5. Governance signs its bound approval after checking privacy, duplication, and supersession. The
   owner separately approves the retention class, review/delete date, and exact destination change.
6. Before any governed repository change, recompute all artifact, scan-receipt, approval-receipt,
   and destination-change hashes; verify every schema, signature, authority binding, approval value,
   base revision, and `APPROVED` or `PASS` result; and reject missing, stale, invalid, untrusted, or
   mismatched evidence.
7. A separate governed change adds only the approved generalisable lesson to
   `governance/logs/lessons-learned.md`; defects and actions remain in
   `governance/logs/actions-and-issues.md`.
8. The final promotion receipt records the verified control-package hash, resulting repository
   revision and file hash, and governed change identity. LoopX receives only a link to that receipt;
   the repository record is not synchronized back into LoopX state.

The candidate retention class and review/delete timestamp require the two owner-signed, hash-bound
approval receipts. A pilot-charter default alone is not approval for a specific candidate. Without
both valid receipts, private candidate material must not be retained indefinitely or promoted. An
accepted repository lesson follows Git history and the governance supersession rule.

### Ownership boundary

`governance/logs/lessons-learned.md` is the authoritative destination for an accepted operational
lesson. LightRAG may index that approved record only through its separate ingestion control and
receipt; agents may consume the indexed copy, but the governed repository record remains the
source. A LoopX receipt or candidate does not become Mem0 memory, LightRAG knowledge, or sdd-core
authority. Each of those destinations requires its own owner-approved schema, privacy and retention
decision, and promotion receipt. No automatic or bidirectional synchronization is permitted.