# Test Case: Verify PostgreSQL Checkpoint Read

**Test ID**: tc-lang-server-integration-003-postgresql-checkpoint-read
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-008 (Conversation continuation across restarts)
**Integration Point**: PostgreSQL checkpoint tables
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that checkpoints can be read from PostgreSQL to restore conversation state.

---

## Prerequisites

- [ ] Service running
- [ ] Existing checkpoints in database

---

## Test Steps

### Step 1: Create Conversation with Known Thread
**Action:**
```bash
THREAD_ID=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "My name is TestUser"}' | jq -r '.thread_id')
echo "Thread ID: $THREAD_ID"
```

**Expected Behavior:**
Thread ID returned.

---

### Step 2: Verify Checkpoint Stored
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT COUNT(*) FROM langgraph.checkpoints WHERE thread_id = '$THREAD_ID';"
```

**Expected Behavior:**
At least 1 checkpoint exists.

---

### Step 3: Continue Conversation (Tests Read)
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"What is my name?\", \"thread_id\": \"$THREAD_ID\"}" | jq -r '.response' | head -c 200
```

**Expected Behavior:**
Response references "TestUser" (state read from checkpoint).

---

### Step 4: Verify Checkpoint Count Increased
**Action:**
```bash
PGPASSWORD=$POSTGRES_PASSWORD psql -h hx-postgres-server.hx.dev.local -U hx_lang_server -d hx_lang_server -c \
  "SELECT COUNT(*) FROM langgraph.checkpoints WHERE thread_id = '$THREAD_ID';"
```

**Expected Behavior:**
Checkpoint count increased (new state saved).

---

## Expected Results

- [ ] Checkpoints readable
- [ ] State restored correctly
- [ ] Conversation continues
- [ ] Context maintained

---

## Pass/Fail Criteria

### PASS Criteria
1. State read successfully
2. Context maintained
3. Continuation works

### FAIL Criteria
1. Read errors
2. Context lost
3. Cannot continue

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-008

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
