# Test Case: Streaming Response End-to-End

**Test ID**: tc-lang-server-e2e-006-streaming-response
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-003 (Streaming endpoint delivers tokens progressively)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates that the streaming endpoint delivers tokens progressively as they are generated.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] curl with streaming support

---

## Test Steps

### Step 1: Submit Streaming Request
**Action:**
```bash
curl -N -X POST http://hx-lang-server.hx.dev.local:8100/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "Write a short poem about clouds"}' --max-time 60 2>&1 | head -20
```

**Expected Behavior:**
Tokens arrive progressively (SSE format or chunked).

---

### Step 2: Verify Progressive Token Delivery
**Action:**
```bash
# Capture timing of token arrivals
start=$(date +%s%N)
curl -N -s -X POST http://hx-lang-server.hx.dev.local:8100/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "Count from 1 to 10 slowly"}' --max-time 60 | while read -r line; do
    echo "$(date +%s%N) - $line"
done | head -15
```

**Expected Behavior:**
Timestamps show progressive delivery (not all at once).

---

### Step 3: Verify SSE Format
**Action:**
```bash
curl -N -s -X POST http://hx-lang-server.hx.dev.local:8100/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello streaming test"}' --max-time 30 | head -10
```

**Expected Behavior:**
Output in SSE format (data: prefix) or chunked transfer.

---

### Step 4: Verify Complete Response
**Action:**
```bash
response=$(curl -N -s -X POST http://hx-lang-server.hx.dev.local:8100/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "List three colors"}' --max-time 60)
echo "Response received:"
echo "$response" | tail -5
```

**Expected Behavior:**
Complete response received with termination signal.

---

### Step 5: Verify No Data Loss
**Action:**
```bash
# Submit and capture full response
full_response=$(curl -N -s -X POST http://hx-lang-server.hx.dev.local:8100/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "Write the alphabet A through Z"}' --max-time 60)
echo "Character count: $(echo "$full_response" | wc -c)"
echo "Contains A-Z: $(echo "$full_response" | grep -o "[A-Z]" | sort -u | wc -l) unique letters"
```

**Expected Behavior:**
Complete response with no missing tokens.

---

## Expected Results

- [ ] Streaming endpoint responds
- [ ] Tokens delivered progressively
- [ ] SSE/chunked format used
- [ ] Response completes properly
- [ ] No data loss

---

## Pass/Fail Criteria

### PASS Criteria
1. Progressive token delivery
2. Proper format
3. Complete response

### FAIL Criteria
1. All tokens at once (not streaming)
2. Invalid format
3. Incomplete/truncated response

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
