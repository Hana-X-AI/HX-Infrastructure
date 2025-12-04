# Test Case: Concurrent Sessions End-to-End

**Test ID**: tc-lang-server-e2e-007-concurrent-sessions
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: NFR-002 (Support 50 concurrent sessions)
**Test Type**: Manual
**Estimated Execution Time**: 15 minutes

---

## Test Objective

Validates that the service correctly handles multiple concurrent sessions without data leakage or performance degradation.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] Sufficient system resources
- [ ] Parallel execution capability

---

## Test Steps

### Step 1: Create Multiple Concurrent Sessions
**Action:**
```bash
# Create 10 concurrent sessions with unique data
for i in {1..10}; do
  (curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
    -H "Content-Type: application/json" \
    -d "{
      \"query\": \"My unique identifier is SESSION_$i. Remember this.\",
      \"session_id\": \"concurrent-test-session-$i\"
    }" --max-time 60 > /tmp/session_$i.txt) &
done
wait
echo "All sessions created"
```

**Expected Behavior:**
All 10 sessions created concurrently.

---

### Step 2: Verify Session Isolation
**Action:**
```bash
# Query each session for its unique identifier
for i in {1..5}; do
  echo "Session $i:"
  curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
    -H "Content-Type: application/json" \
    -d "{
      \"query\": \"What is my unique identifier?\",
      \"session_id\": \"concurrent-test-session-$i\"
    }" --max-time 60 | jq '.response' | head -c 200
  echo ""
done
```

**Expected Behavior:**
Each session returns its own identifier (SESSION_1, SESSION_2, etc.).

---

### Step 3: Concurrent Query Execution
**Action:**
```bash
# Submit 20 concurrent queries across different sessions
for i in {1..20}; do
  session=$((($i % 10) + 1))
  (curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
    -H "Content-Type: application/json" \
    -d "{
      \"query\": \"Quick response test $i\",
      \"session_id\": \"concurrent-test-session-$session\"
    }" --max-time 60 > /tmp/concurrent_$i.txt) &
done
wait
echo "All queries completed"
ls -la /tmp/concurrent_*.txt | wc -l
```

**Expected Behavior:**
All 20 queries complete successfully.

---

### Step 4: Verify Response Times Under Load
**Action:**
```bash
# Measure response time with concurrent load
start=$(date +%s)
for i in {1..10}; do
  (curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
    -H "Content-Type: application/json" \
    -d '{"query": "Quick test"}' --max-time 60 > /dev/null) &
done
wait
end=$(date +%s)
echo "10 concurrent queries completed in $((end-start)) seconds"
```

**Expected Behavior:**
Reasonable completion time (not 10x single query time).

---

### Step 5: Verify No Session Data Leakage
**Action:**
```bash
# Check that session data doesn't leak between sessions
response1=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Do you know about SESSION_5?",
    "session_id": "concurrent-test-session-1"
  }' --max-time 60 | jq '.response')

echo "Session 1 asked about Session 5 data:"
echo "$response1" | head -c 300
```

**Expected Behavior:**
Session 1 should NOT have knowledge of Session 5's data.

---

## Expected Results

- [ ] Multiple sessions created concurrently
- [ ] Session isolation maintained
- [ ] Concurrent queries complete
- [ ] Performance acceptable under load
- [ ] No data leakage between sessions

---

## Pass/Fail Criteria

### PASS Criteria
1. All sessions isolated
2. No data leakage
3. Concurrent handling works

### FAIL Criteria
1. Session data mixed
2. Data leakage detected
3. Concurrent requests fail

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
