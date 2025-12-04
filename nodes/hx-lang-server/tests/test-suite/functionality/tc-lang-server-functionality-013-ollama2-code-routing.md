# Test Case: Verify Ollama2 Code Routing

**Test ID**: tc-lang-server-functionality-013-ollama2-code-routing
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-011 (Route code-related queries to hx-ollama2-server)
**Based on Plan**: Work Stream 7 (Ollama Integration)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that code-related queries are routed to Ollama2 (hx-ollama2-server.hx.dev.local:11434) using the code model (qwen3-coder:30b).

**Why This Test Is Important:**
Code queries require specialized models for optimal code generation quality.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] Ollama2 accessible with code model loaded

---

## Test Steps

### Step 1: Submit Code Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a Python function to reverse a string"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
query_type is "code", routed to code worker.

---

### Step 2: Verify Code Model Response
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Implement quicksort in Python"}' | jq -r '.response' | head -20
```

**Expected Behavior:**
Response contains valid Python code.

---

### Step 3: Verify Code Syntax in Response
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a class for a linked list"}' | jq -r '.response' | grep -E "class|def"
```

**Expected Behavior:**
Code syntax present in response.

---

## Expected Results

### Primary Expected Results
- [ ] Code queries routed to code agent
- [ ] Ollama2/code model used
- [ ] Valid code in responses

---

## Pass/Fail Criteria

### PASS Criteria
1. Code queries routed correctly
2. Ollama2 used for code
3. Valid code generated

### FAIL Criteria
1. Wrong routing
2. Poor code quality
3. Connection fails

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-011

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
