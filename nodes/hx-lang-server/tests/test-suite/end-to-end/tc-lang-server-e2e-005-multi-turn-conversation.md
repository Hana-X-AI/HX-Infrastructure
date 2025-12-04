# Test Case: Multi-Turn Conversation End-to-End

**Test ID**: tc-lang-server-e2e-005-multi-turn-conversation
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-006 (Multi-turn conversations with context)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates that multi-turn conversations maintain context correctly across multiple exchanges.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] PostgreSQL and Redis running

---

## Test Steps

### Step 1: Start Conversation (Turn 1)
**Action:**
```bash
session_id="e2e-multi-turn-$(date +%s)"
echo "Session ID: $session_id"

curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Let's discuss Python programming. What are decorators?\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response[:300]'
```

**Expected Behavior:**
Explanation of Python decorators.

---

### Step 2: Follow-Up Question (Turn 2)
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Can you show me an example of what we just discussed?\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response[:400]'
```

**Expected Behavior:**
Example of decorator (references previous context about decorators).

---

### Step 3: Reference Earlier Context (Turn 3)
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"What topic have we been discussing?\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response'
```

**Expected Behavior:**
Response references "Python programming" and "decorators".

---

### Step 4: Build on Context (Turn 4)
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Now explain how to chain multiple of these together\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response[:400]'
```

**Expected Behavior:**
Explanation of chaining decorators (maintains conversation context).

---

### Step 5: Verify Full Context Available (Turn 5)
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"Summarize everything we discussed in this conversation\",
    \"session_id\": \"$session_id\"
  }" --max-time 60 | jq '.response'
```

**Expected Behavior:**
Summary includes all topics: decorators, examples, chaining.

---

## Expected Results

- [ ] Each turn builds on previous context
- [ ] References to "we discussed" work correctly
- [ ] Implicit references resolved
- [ ] Full conversation history available
- [ ] Summary includes all topics

---

## Pass/Fail Criteria

### PASS Criteria
1. Context maintained across all turns
2. References correctly resolved
3. Conversation coherent

### FAIL Criteria
1. Context lost between turns
2. References not understood
3. Incoherent responses

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
