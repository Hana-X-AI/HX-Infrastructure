# Test Case: Verify State Schema Versioning

**Test ID**: tc-lang-server-functionality-011-state-schema-versioning
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-009 (State schema versioning for backward compatibility)
**Based on Plan**: Work Stream 6 (Task 051 - Agent State Schema)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the AgentState TypedDict includes schema_version field for backward compatibility tracking.

**Why This Test Is Important:**
Schema versioning enables safe upgrades and migration of checkpoint data across versions.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

---

## Test Steps

### Step 1: Verify Schema Version in Response
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test query"}' | jq '.metadata.schema_version // "Not in metadata"'
```

**Expected Behavior:**
schema_version may be in metadata or checkpoint.

---

### Step 2: Check Checkpoint for Schema Version
**Action:**
```bash
# Query PostgreSQL for schema version in checkpoint data
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT checkpoint_id, (channel_values->>'schema_version') as schema_version FROM langgraph.checkpoints LIMIT 3;"
```

**Expected Behavior:**
schema_version field present in checkpoint data.

---

## Expected Results

### Primary Expected Results
- [ ] schema_version field exists in state
- [ ] Version is documented (e.g., "1.0")

---

## Pass/Fail Criteria

### PASS Criteria
1. Schema version tracked
2. Version accessible

### FAIL Criteria
1. No version tracking
2. Field missing

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-009, State Schema Design

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
