# Test Case: Verify Adaptive Retrieval

**Test ID**: tc-lang-server-functionality-017-adaptive-retrieval
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-015 (Support adaptive retrieval with iteration when initial results insufficient)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that the RAG agent can iterate on retrieval when initial results are insufficient, adapting its search strategy.

---

## Prerequisites

- [ ] Service running
- [ ] LightRAG accessible with indexed documents

---

## Test Steps

### Step 1: Submit Complex RAG Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Find detailed technical specifications for implementing distributed consensus"}' | jq '{iteration_count, response: .response[:200]}'
```

**Expected Behavior:**
May require multiple iterations for comprehensive answer.

---

### Step 2: Verify Iteration Count
**Action:**
```bash
# Compare iteration counts for simple vs complex queries
SIMPLE=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is Python?"}' | jq '.iteration_count')
COMPLEX=$(curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain comprehensive microservices architecture patterns with examples"}' | jq '.iteration_count')
echo "Simple: $SIMPLE, Complex: $COMPLEX"
```

**Expected Behavior:**
Complex queries may have higher iteration counts.

---

## Expected Results

- [ ] Adaptive retrieval supported
- [ ] Iteration visible in responses
- [ ] Quality improves with iteration

---

## Pass/Fail Criteria

### PASS Criteria
1. Adaptive behavior observable
2. No crashes on complex queries

### FAIL Criteria
1. No iteration capability
2. Crashes on complex queries

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-015

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
