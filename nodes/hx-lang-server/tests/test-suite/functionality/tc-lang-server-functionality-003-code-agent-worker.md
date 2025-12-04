# Test Case: Verify Code Agent Worker

**Test ID**: tc-lang-server-functionality-003-code-agent-worker
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-002 (Worker agent types: Code Agent), FR-011 (Ollama2 code routing)
**Based on Plan**: Work Stream 6 (Task 055), Work Stream 7 (Ollama Integration)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the Code Agent worker correctly handles code-related queries by routing them to Ollama2 (code-specialized model) and generating appropriate code responses.

**Why This Test Is Important:**
Code generation is a specialized task requiring a code-focused LLM. Correct routing to Ollama2 ensures optimal code quality.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy
- [ ] Code agent registered with supervisor

**Dependencies:**
- [ ] Ollama2 service accessible (hx-ollama2-server.hx.dev.local:11434)
- [ ] Code model loaded (qwen3-coder:30b or configured model)

**Environment:**
- [ ] Access to API on port 8100

**Permissions:**
- [ ] API access

---

## Test Setup

### Pre-Test Actions
1. Verify service is running
2. Verify Ollama2 is accessible

### Test Data
**Required Test Data:**
- Code trigger queries containing: code, function, class, debug, error, python, javascript, sql, api, implement

---

## Test Steps

### Step 1: Submit Code Generation Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a Python function to calculate fibonacci numbers"}' | jq .
```

**Expected Behavior:**
Query routed to code agent, response includes code.

**How to Verify:**
worker_used indicates code agent, response contains code block.

---

### Step 2: Verify Code Worker Selection
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Implement a binary search algorithm in Python"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
query_type is "code", worker_used is code_agent.

**How to Verify:**
Both fields indicate code processing.

---

### Step 3: Verify "Debug" Keyword Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Debug this code: for i in range(10) print(i)"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"Debug" keyword triggers code agent routing.

**How to Verify:**
query_type is "code".

---

### Step 4: Verify "Function" Keyword Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Create a function to validate email addresses"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"Function" keyword triggers code agent.

**How to Verify:**
query_type is "code".

---

### Step 5: Verify SQL Query Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a SQL query to join users and orders tables"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"SQL" keyword triggers code agent.

**How to Verify:**
query_type is "code".

---

### Step 6: Verify JavaScript Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a JavaScript async function for API calls"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"JavaScript" keyword triggers code agent.

**How to Verify:**
query_type is "code".

---

### Step 7: Verify Code Response Contains Code Block
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a Python class for a stack data structure"}' | jq -r '.response' | grep -E "class|def|```"
```

**Expected Behavior:**
Response contains code syntax or markdown code block.

**How to Verify:**
Output includes class, def, or code fence markers.

---

## Expected Results

### Primary Expected Results
- [ ] Code queries routed to code agent
- [ ] query_type correctly classified as "code"
- [ ] worker_used shows code_agent
- [ ] Keyword triggers work (code, function, class, debug, error, python, javascript, sql, api, implement)
- [ ] Response includes actual code
- [ ] Uses Ollama2 (code model)

### Observable Indicators
**API Response:**
- query_type: "code"
- worker_used: "code_agent" or similar
- Response contains code syntax

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Code keywords trigger code agent
2. query_type correctly identified as "code"
3. worker_used indicates code agent
4. Response contains code
5. No server errors

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Code queries not routed to code agent
2. query_type incorrect
3. Server error on code query
4. No code in response
5. Routed to wrong Ollama server

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. Ollama2 inaccessible

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
- Requires tc-lang-server-functionality-001 to pass
- Related to integration-009 (Ollama2 connection)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-002, FR-011

**Related Test Cases:**
- `tc-lang-server-functionality-013-ollama2-code-routing.md`
- `tc-lang-server-integration-009-ollama2-connection.md`

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
