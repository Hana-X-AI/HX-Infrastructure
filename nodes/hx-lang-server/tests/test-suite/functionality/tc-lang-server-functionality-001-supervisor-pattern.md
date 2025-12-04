# Test Case: Verify Supervisor Pattern Implementation

**Test ID**: tc-lang-server-functionality-001-supervisor-pattern
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-001 (LangGraph supervisor pattern with configurable worker agents)
**Based on Plan**: Work Stream 6 - LangGraph Agent Implementation (Tasks 053, 058, 059)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the LangGraph supervisor pattern is correctly implemented, accepting queries and routing them to appropriate worker agents based on query classification.

**Why This Test Is Important:**
The supervisor pattern is the core orchestration mechanism. Without it, multi-agent workflows cannot function.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy
- [ ] All worker agents registered

**Dependencies:**
- [ ] Ollama servers accessible
- [ ] LightRAG accessible
- [ ] PostgreSQL accessible for checkpointing

**Environment:**
- [ ] Access to API on port 8100

**Permissions:**
- [ ] API access

---

## Test Setup

### Pre-Test Actions
1. Verify service is running
2. Verify health endpoint returns healthy

### Test Data
**Required Test Data:**
- General query: "What is the capital of France?"
- Code query: "Write a Python function to sort a list"
- RAG query: "Search for information about machine learning"
- Tool query: "Fetch the contents of https://example.com"

---

## Test Steps

### Step 1: Submit General Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the capital of France?"}' | jq .
```

**Expected Behavior:**
Response includes worker_used field indicating which worker handled the query.

**How to Verify:**
Response contains "worker_used" field and valid "response" field.

---

### Step 2: Verify Supervisor Routing Decision
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the capital of France?"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
Query type is "general" and worker is general agent.

**How to Verify:**
query_type and worker_used fields present with appropriate values.

---

### Step 3: Verify Thread ID Assignment
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello"}' | jq '.thread_id'
```

**Expected Behavior:**
Thread ID is assigned for conversation tracking.

**How to Verify:**
thread_id is a non-empty string.

---

### Step 4: Verify Iteration Count
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Simple question"}' | jq '.iteration_count'
```

**Expected Behavior:**
Iteration count is tracked.

**How to Verify:**
iteration_count is a number >= 1.

---

### Step 5: Verify Metadata Returned
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test query"}' | jq '.metadata'
```

**Expected Behavior:**
Metadata object returned with execution details.

**How to Verify:**
metadata object is present with relevant fields.

---

### Step 6: Verify Error Handling for Empty Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": ""}' | jq .
```

**Expected Behavior:**
Appropriate error response for empty query.

**How to Verify:**
Error response with descriptive message.

---

### Step 7: Verify Supervisor Handles Long Query
**Action:**
```bash
LONG_QUERY=$(python3 -c "print('Test query ' * 100)")
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$LONG_QUERY\"}" | jq '{worker_used, response: .response[:100]}'
```

**Expected Behavior:**
Long queries are handled without error.

**How to Verify:**
Valid response returned.

---

## Expected Results

### Primary Expected Results
- [ ] Supervisor accepts queries via /invoke endpoint
- [ ] Worker assignment visible in response
- [ ] Thread ID assigned for conversation
- [ ] Iteration count tracked
- [ ] Metadata includes execution details
- [ ] Error handling works for invalid queries
- [ ] Long queries handled correctly

### Observable Indicators
**API Response:**
- 200 OK status
- JSON response with required fields
- worker_used, thread_id, query_type present

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. /invoke endpoint accepts POST requests
2. Response contains worker_used field
3. Response contains thread_id
4. Response contains query_type
5. Response contains valid response text
6. Empty query returns appropriate error

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. /invoke endpoint not responding
2. Missing required response fields
3. Server error (500) on valid query
4. No worker assignment visible
5. Thread ID not assigned

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. Dependencies not available

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

---

## Test Cleanup

### Post-Test Actions
1. No cleanup required

### Environment Reset
- [ ] No changes made

---

## Notes and Observations

### Dependencies on Other Tests
- Deployment tests must pass
- Related to all functionality tests

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-001

**Related Test Cases:**
- `tc-lang-server-functionality-002-005` - Worker agent tests
- `tc-lang-server-e2e-001` - Supervisor workflow E2E

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
