# Test Case: Verify 64KB Context Validation

**Test ID**: tc-lang-server-functionality-015-64kb-context-validation
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-013 (Validate Ollama model context size >= 64KB for RAG and Code)
**Based on Plan**: Work Stream 7 (Ollama Integration - Task 073, 074)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the service validates Ollama models have at least 64KB context size for RAG and Code operations, as required for LightRAG entity extraction and complex code generation.

**Why This Test Is Important:**
Insufficient context size causes truncation of RAG context and code, leading to incomplete or incorrect responses.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] Ollama servers configured with 64KB context models

---

## Test Steps

### Step 1: Submit Large RAG Query
**Action:**
```bash
# Create a query that would benefit from large context
LARGE_QUERY="Search for comprehensive information about distributed systems including consistency models, CAP theorem, Paxos, Raft, and their implementations. I need detailed technical explanations."
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$LARGE_QUERY\"}" | jq -r '.response' | wc -c
```

**Expected Behavior:**
Response is substantive (not truncated).

---

### Step 2: Submit Complex Code Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a complete implementation of a B-tree data structure in Python with insert, delete, search, and range query operations with full documentation"}' | jq -r '.response' | wc -c
```

**Expected Behavior:**
Large code response generated without truncation.

---

### Step 3: Verify Context Configuration in Environment
**Action:**
```bash
grep -i "CONTEXT\|context" /opt/hx-lang-server/.env || echo "Context may be configured at Ollama level"
```

**Expected Behavior:**
Context configuration visible or configured at Ollama.

---

### Step 4: Check for Context Errors in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -i "context\|truncat\|limit" | head -5
```

**Expected Behavior:**
No context truncation errors.

---

## Expected Results

### Primary Expected Results
- [ ] Large queries handled without truncation
- [ ] Complex code generated completely
- [ ] No context limit errors
- [ ] 64KB context available

---

## Pass/Fail Criteria

### PASS Criteria
1. Large responses not truncated
2. No context errors
3. Complex queries handled

### FAIL Criteria
1. Responses truncated
2. Context errors in logs
3. Incomplete code generation

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-013, SC-007

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
