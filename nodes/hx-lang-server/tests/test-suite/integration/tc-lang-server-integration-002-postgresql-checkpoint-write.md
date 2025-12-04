# Test Case: Verify PostgreSQL Checkpoint Write

**Test ID**: tc-lang-server-integration-002-postgresql-checkpoint-write
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-006, NFR-002 (Checkpoint latency <100ms)
**Integration Point**: PostgreSQL checkpoint tables
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that checkpoints are correctly written to PostgreSQL with acceptable latency (<100ms per checkpoint).

---

## Prerequisites

- [ ] Service running
- [ ] PostgreSQL connection working (integration-001 passed)

---

## Test Steps

### Step 1: Get Initial Checkpoint Count
**Action:**
```bash
INITIAL_COUNT=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "SELECT COUNT(*) FROM langgraph.checkpoints;")
echo "Initial checkpoint count: $INITIAL_COUNT"
```

**Expected Behavior:**
Count retrieved.

---

### Step 2: Submit Query and Measure Time
**Action:**
```bash
time curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test checkpoint write"}' > /dev/null
```

**Expected Behavior:**
Query completes (checkpoint written).

---

### Step 3: Verify Checkpoint Created
**Action:**
```bash
NEW_COUNT=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -t -c "SELECT COUNT(*) FROM langgraph.checkpoints;")
echo "New checkpoint count: $NEW_COUNT"
echo "Checkpoints created: $((NEW_COUNT - INITIAL_COUNT))"
```

**Expected Behavior:**
Checkpoint count increased.

---

### Step 4: Verify Checkpoint Content
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT thread_id, checkpoint_id, created_at FROM langgraph.checkpoints ORDER BY created_at DESC LIMIT 3;"
```

**Expected Behavior:**
Recent checkpoints visible with valid data.

---

## Expected Results

- [ ] Checkpoints created on query
- [ ] Checkpoint count increases
- [ ] Data stored correctly
- [ ] Latency acceptable

---

## Pass/Fail Criteria

### PASS Criteria
1. Checkpoints created
2. Data valid
3. Latency <100ms

### FAIL Criteria
1. No checkpoints created
2. Write errors
3. Excessive latency

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-006, NFR-002

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
