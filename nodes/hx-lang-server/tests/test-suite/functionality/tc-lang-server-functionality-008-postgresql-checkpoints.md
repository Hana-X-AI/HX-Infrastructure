# Test Case: Verify PostgreSQL Checkpoint Persistence

**Test ID**: tc-lang-server-functionality-008-postgresql-checkpoints
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-006 (Persist agent state to PostgreSQL using langgraph-checkpoint-postgres)
**Based on Plan**: Work Stream 4 (PostgreSQL Integration)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that agent state is correctly persisted to PostgreSQL using langgraph-checkpoint-postgres, enabling conversation recovery and state inspection.

**Why This Test Is Important:**
Checkpoint persistence is critical for conversation continuity across service restarts and for debugging agent workflows.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] PostgreSQL accessible (hx-postgres-server.hx.dev.local:5432)
- [ ] Database hx_lang_server created
- [ ] Checkpoint tables initialized

**Environment:**
- [ ] Access to API and PostgreSQL

---

## Test Steps

### Step 1: Submit Query and Get Thread ID
**Action:**
```bash
THREAD_ID=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello, this is a test conversation"}' | jq -r '.thread_id')
echo "Thread ID: $THREAD_ID"
```

**Expected Behavior:**
Thread ID returned for tracking.

**How to Verify:**
thread_id is a valid non-empty string.

---

### Step 2: Verify Checkpoint Created in PostgreSQL
**Action:**
```bash
# Connect to PostgreSQL and check for checkpoint
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT COUNT(*) FROM langgraph.checkpoints WHERE thread_id = '$THREAD_ID';"
```

**Expected Behavior:**
At least one checkpoint exists for the thread.

**How to Verify:**
Count >= 1.

---

### Step 3: Verify Checkpoint Contains State
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT thread_id, checkpoint_id FROM langgraph.checkpoints WHERE thread_id = '$THREAD_ID' LIMIT 5;"
```

**Expected Behavior:**
Checkpoint records exist with IDs.

**How to Verify:**
Records returned with valid IDs.

---

### Step 4: Submit Follow-up and Verify Additional Checkpoint
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"Continue the conversation\", \"thread_id\": \"$THREAD_ID\"}" | jq '.response' | head -c 100
# Then check checkpoint count
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT COUNT(*) FROM langgraph.checkpoints WHERE thread_id = '$THREAD_ID';"
```

**Expected Behavior:**
Additional checkpoint created for follow-up.

**How to Verify:**
Checkpoint count increased.

---

### Step 5: Verify Checkpoint Latency
**Action:**
```bash
# Time the checkpoint operation
time curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Quick checkpoint test"}' > /dev/null
```

**Expected Behavior:**
Checkpoint completes within <100ms (NFR-002).

**How to Verify:**
Total time is reasonable (checkpoint portion <100ms).

---

## Expected Results

### Primary Expected Results
- [ ] Thread ID assigned to conversations
- [ ] Checkpoints created in PostgreSQL
- [ ] Checkpoint count increases with conversation turns
- [ ] Checkpoint latency <100ms (NFR-002)
- [ ] State data stored in checkpoints

---

## Pass/Fail Criteria

### PASS Criteria
1. Checkpoints created in PostgreSQL
2. Thread ID tracking works
3. Multiple checkpoints per conversation
4. Latency acceptable

### FAIL Criteria
1. No checkpoints created
2. PostgreSQL connection fails
3. Thread ID not assigned
4. Excessive checkpoint latency

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-006, NFR-002

**Related Test Cases:**
- `tc-lang-server-integration-001-003` - PostgreSQL connection tests

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
