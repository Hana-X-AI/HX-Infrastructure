# Test Case: Verify Human-in-the-Loop Interrupts

**Test ID**: tc-lang-server-functionality-006-human-in-loop
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-004 (Human-in-the-loop interrupts for agent approval workflows)
**Based on Plan**: Work Stream 6 (Task 060)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the LangGraph implementation supports human-in-the-loop interrupts, allowing workflows to pause for human approval before proceeding with sensitive operations.

**Why This Test Is Important:**
Human oversight is critical for sensitive operations. The interrupt mechanism ensures humans can review and approve agent actions.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy
- [ ] Human-in-loop feature enabled in configuration

**Dependencies:**
- [ ] PostgreSQL for checkpoint storage during interrupt

**Environment:**
- [ ] Access to API on port 8100

---

## Test Steps

### Step 1: Verify Interrupt Configuration Available
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test query", "config": {"interrupt_before": ["agent_action"]}}' | jq .
```

**Expected Behavior:**
Config with interrupt settings is accepted.

**How to Verify:**
No error related to interrupt configuration.

---

### Step 2: Verify Thread State Persisted During Interrupt
**Action:**
```bash
# Submit query that triggers interrupt (if configured)
# Then verify thread state is persisted
THREAD_ID=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Perform action requiring approval"}' | jq -r '.thread_id')
echo "Thread ID: $THREAD_ID"
```

**Expected Behavior:**
Thread ID returned for continuation after approval.

**How to Verify:**
thread_id is a valid string.

---

### Step 3: Verify Continuation After Approval
**Action:**
```bash
# Continue with previous thread_id
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"Continue with approval\", \"thread_id\": \"$THREAD_ID\"}" | jq .
```

**Expected Behavior:**
Conversation continues from interrupted state.

**How to Verify:**
Response indicates continuation.

---

## Expected Results

### Primary Expected Results
- [ ] Interrupt configuration is accepted
- [ ] State persisted during interrupt
- [ ] Continuation with thread_id works
- [ ] No state loss during interrupt

---

## Pass/Fail Criteria

### PASS Criteria
1. Interrupt configuration accepted
2. Thread state persisted
3. Continuation works

### FAIL Criteria
1. Interrupt configuration rejected
2. State lost during interrupt
3. Cannot continue after interrupt

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-004

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
