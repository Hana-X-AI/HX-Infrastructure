# Test Case: Verify LightRAG Query Modes

**Test ID**: tc-lang-server-functionality-018-lightrag-query-modes
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-016 (Support LightRAG query modes: local, global, hybrid, mix)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that the service can utilize different LightRAG query modes for optimal retrieval strategies.

---

## Prerequisites

- [ ] Service running
- [ ] LightRAG accessible

---

## Test Steps

### Step 1: Test Default Query Mode
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for Python documentation"}' | jq '.metadata.query_mode // "mode not exposed"'
```

**Expected Behavior:**
Query mode used or default applied.

---

### Step 2: Test with Query Mode Config (if supported)
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for detailed analysis", "config": {"rag_mode": "hybrid"}}' | jq .
```

**Expected Behavior:**
Mode configuration accepted.

---

### Step 3: Verify No Errors on Different Modes
**Action:**
```bash
for mode in local global hybrid mix; do
  echo "Testing mode: $mode"
  curl -s -X POST http://localhost:8100/invoke \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"Search test\", \"config\": {\"rag_mode\": \"$mode\"}}" | jq '.response[:50]'
done
```

**Expected Behavior:**
All modes work without errors.

---

## Expected Results

- [ ] Query modes supported
- [ ] No errors on mode selection
- [ ] Mode affects retrieval behavior

---

## Pass/Fail Criteria

### PASS Criteria
1. Modes accepted
2. No errors

### FAIL Criteria
1. Mode selection fails
2. Errors on specific modes

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-016

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
