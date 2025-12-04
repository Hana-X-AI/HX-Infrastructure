# Test Case: Verify Conversation Continuation

**Test ID**: tc-lang-server-functionality-010-conversation-continuation
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-008 (Conversation continuation across service restarts)
**Based on Plan**: Work Stream 4-5 (PostgreSQL, Redis Integration)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that conversations can continue across multiple requests using thread_id, maintaining context from previous interactions.

**Why This Test Is Important:**
Multi-turn conversations are essential for complex workflows. Context preservation ensures coherent interactions.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] PostgreSQL for checkpoint storage
- [ ] Redis for session caching

---

## Test Steps

### Step 1: Start New Conversation
**Action:**
```bash
RESPONSE1=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "My name is Alice and I am testing the system"}')
THREAD_ID=$(echo $RESPONSE1 | jq -r '.thread_id')
echo "Thread ID: $THREAD_ID"
echo "Response: $(echo $RESPONSE1 | jq -r '.response' | head -c 200)"
```

**Expected Behavior:**
Thread ID assigned, initial response generated.

---

### Step 2: Continue with Context Reference
**Action:**
```bash
RESPONSE2=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"What is my name?\", \"thread_id\": \"$THREAD_ID\"}")
echo "Response: $(echo $RESPONSE2 | jq -r '.response' | head -c 200)"
```

**Expected Behavior:**
Response references "Alice" from previous context.

**How to Verify:**
Response acknowledges previous context about name.

---

### Step 3: Third Turn Maintains Context
**Action:**
```bash
RESPONSE3=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"What was I doing?\", \"thread_id\": \"$THREAD_ID\"}")
echo "Response: $(echo $RESPONSE3 | jq -r '.response' | head -c 200)"
```

**Expected Behavior:**
Context maintained across three turns.

---

### Step 4: Verify Iteration Count Increases
**Action:**
```bash
echo "Turn 1 iterations: $(echo $RESPONSE1 | jq '.iteration_count')"
echo "Turn 3 iterations: $(echo $RESPONSE3 | jq '.iteration_count')"
```

**Expected Behavior:**
Iteration tracking shows conversation progression.

---

## Expected Results

### Primary Expected Results
- [ ] Thread ID enables continuation
- [ ] Context preserved across turns
- [ ] Previous information accessible
- [ ] Multi-turn tracking works

---

## Pass/Fail Criteria

### PASS Criteria
1. Thread ID enables continuation
2. Context referenced in later turns
3. No context loss

### FAIL Criteria
1. Context not maintained
2. Thread ID not recognized
3. Responses ignore previous turns

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-008

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
