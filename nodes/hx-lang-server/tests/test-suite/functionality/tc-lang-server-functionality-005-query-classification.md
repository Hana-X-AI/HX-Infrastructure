# Test Case: Verify Query Classification

**Test ID**: tc-lang-server-functionality-005-query-classification
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-003 (Route queries based on query classification)
**Based on Plan**: Work Stream 6 (Task 052 - Query Classifier)
**Test Type**: Manual
**Estimated Execution Time**: 15 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the query classifier correctly categorizes incoming queries into types (general, code, rag, tool) using keyword-based classification with LLM fallback for ambiguous queries.

**Why This Test Is Important:**
Query classification drives routing decisions. Incorrect classification leads to wrong worker selection and suboptimal responses.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy

**Dependencies:**
- [ ] All workers registered

**Environment:**
- [ ] Access to API on port 8100

**Permissions:**
- [ ] API access

---

## Test Setup

### Pre-Test Actions
1. Verify service is running

### Test Data
**Required Test Data:**
Per specification keyword sets:
- CODE_KEYWORDS: code, function, class, debug, error, python, javascript, sql, api, implement
- RAG_KEYWORDS: search, find, document, knowledge, what is, explain, how does
- TOOL_KEYWORDS: crawl, fetch, scrape, web, url

---

## Test Steps

### Step 1: Test "general" Classification
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the weather like today?"}' | jq '.query_type'
```

**Expected Behavior:**
Query without specific keywords classified as "general".

**How to Verify:**
query_type is "general".

---

### Step 2: Test "code" Classification - "function" keyword
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a function to sort numbers"}' | jq '.query_type'
```

**Expected Behavior:**
"function" keyword triggers "code" classification.

**How to Verify:**
query_type is "code".

---

### Step 3: Test "code" Classification - "python" keyword
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Show me how to do this in Python"}' | jq '.query_type'
```

**Expected Behavior:**
"python" keyword triggers "code" classification.

**How to Verify:**
query_type is "code".

---

### Step 4: Test "rag" Classification - "search" keyword
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for documentation about APIs"}' | jq '.query_type'
```

**Expected Behavior:**
"search" keyword triggers "rag" classification.

**How to Verify:**
query_type is "rag".

---

### Step 5: Test "rag" Classification - "what is" phrase
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is machine learning?"}' | jq '.query_type'
```

**Expected Behavior:**
"what is" phrase triggers "rag" classification.

**How to Verify:**
query_type is "rag".

---

### Step 6: Test "tool" Classification - "crawl" keyword
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Crawl this webpage and summarize"}' | jq '.query_type'
```

**Expected Behavior:**
"crawl" keyword triggers "tool" classification.

**How to Verify:**
query_type is "tool".

---

### Step 7: Test "tool" Classification - "url" keyword
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Get the content from this URL"}' | jq '.query_type'
```

**Expected Behavior:**
"url" keyword triggers "tool" classification.

**How to Verify:**
query_type is "tool".

---

### Step 8: Test Case Insensitivity
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "WRITE A PYTHON FUNCTION"}' | jq '.query_type'
```

**Expected Behavior:**
Classification is case-insensitive.

**How to Verify:**
query_type is "code" despite uppercase.

---

### Step 9: Test Ambiguous Query (LLM Fallback)
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Help me with my project"}' | jq '.query_type'
```

**Expected Behavior:**
Ambiguous query uses LLM fallback or defaults to general.

**How to Verify:**
query_type is a valid classification.

---

### Step 10: Test Mixed Keywords Priority
**Action:**
```bash
# Query with both code and RAG keywords
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search for Python code examples"}' | jq '.query_type'
```

**Expected Behavior:**
First matching keyword set wins or priority order followed.

**How to Verify:**
query_type is consistently classified.

---

## Expected Results

### Primary Expected Results
- [ ] "general" queries correctly classified
- [ ] "code" keywords trigger code classification
- [ ] "rag" keywords trigger rag classification
- [ ] "tool" keywords trigger tool classification
- [ ] Classification is case-insensitive
- [ ] Ambiguous queries handled gracefully
- [ ] Mixed keywords have consistent priority

### Observable Indicators
**API Response:**
- query_type field is always present
- query_type is one of: general, code, rag, tool

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Each keyword correctly triggers its classification
2. Case-insensitive matching works
3. query_type always returned
4. No errors during classification
5. Ambiguous queries don't crash

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Keywords don't trigger correct classification
2. Case sensitivity issues
3. query_type missing
4. Errors during classification
5. Crashes on ambiguous queries

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running

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
- Foundation for all worker tests

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-003, Query Classification section

**Related Test Cases:**
- `tc-lang-server-functionality-002-004` - Worker routing tests

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
