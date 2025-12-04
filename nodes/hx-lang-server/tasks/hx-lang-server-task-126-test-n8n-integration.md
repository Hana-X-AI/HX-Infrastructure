# Task: Test n8n Integration

**Task ID**: hx-lang-server-task-126-test-n8n-integration
**Phase**: Implementation (Phase 2)
**Assigned To**: Isabella (n8n Workflow Automation SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-121 through hx-lang-server-task-125 (All n8n integration tasks)
**Estimated Time**: 90 minutes

---

## Objective

Execute comprehensive integration testing of hx-lang-server with n8n workflows to validate HTTP endpoints, webhook callbacks, status polling, error handling, and conversation continuity. This ensures production-ready n8n integration before Phase 2 completion.

---

## Prerequisites

- [ ] hx-lang-server operational with all n8n endpoints
- [ ] n8n server operational at hx-n8n-server.hx.dev.local:5678
- [ ] Workflow examples created and available for import
- [ ] Test data and scenarios prepared

---

## Specification Reference

**From node-spec.md v2.1, Section: n8n Integration (Phase 2)**

Lines 104-108:
- FR-026: Service MUST expose HTTP endpoint for n8n HTTP Request node
- FR-027: Service MUST support webhook callback registration for async operations
- FR-028: Service MUST provide thread_id for conversation continuity in n8n workflows

---

## Test Categories

### Category 1: Basic HTTP Request Integration
### Category 2: Conversation Continuity
### Category 3: Async Operations with Callbacks
### Category 4: Status Polling
### Category 5: Error Handling
### Category 6: Performance and Reliability

---

## Test Execution Steps

### Test Category 1: Basic HTTP Request Integration

#### Test 1.1: Simple Synchronous Query

**Objective:** Verify basic POST /invoke endpoint works from n8n

**Steps:**
1. Import workflow `01-simple-query.json` into n8n
2. Modify query to: "What is LangGraph?"
3. Execute workflow
4. Verify response received

**Expected Results:**
- [ ] HTTP 200 status code
- [ ] Response contains `thread_id` (UUID format)
- [ ] Response contains `response` (non-empty string)
- [ ] Response contains `query_type` (e.g., "general", "rag")
- [ ] Response contains `worker_used` (e.g., "rag_agent")
- [ ] Response contains `iteration_count` (integer > 0)
- [ ] Response contains `async_mode: false`

**Verification Command:**
```bash
# Test from command line for comparison
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "What is LangGraph?"}' | jq
```

**Pass Criteria:** All expected fields present with valid values

---

#### Test 1.2: Query with Metadata

**Objective:** Verify workflow_id and execution_id are accepted and tracked

**Steps:**
1. Import workflow `01-simple-query.json`
2. Add workflow_id and execution_id to request body
3. Execute workflow
4. Check response metadata

**Expected Results:**
- [ ] Request accepted with additional metadata
- [ ] Response includes metadata section
- [ ] Metadata contains workflow_id if provided
- [ ] Metadata contains execution_id if provided

**Pass Criteria:** Metadata successfully passed through and returned

---

### Test Category 2: Conversation Continuity

#### Test 2.1: Multi-Turn Conversation

**Objective:** Verify thread_id enables conversation context

**Steps:**
1. Import workflow `02-multi-turn-conversation.json`
2. Execute workflow with all three queries:
   - Query 1: "Hello, my name is Alice"
   - Query 2: "What is my name?"
   - Query 3: "Tell me about myself"
3. Verify responses reference previous context

**Expected Results:**
- [ ] First query generates thread_id
- [ ] Same thread_id used for queries 2 and 3
- [ ] Second query response mentions "Alice"
- [ ] Third query response references information from query 1
- [ ] All queries return same thread_id

**Pass Criteria:** Agent demonstrates memory of previous conversation

---

#### Test 2.2: Thread Persistence Across Workflows

**Objective:** Verify thread_id works across different workflow executions

**Steps:**
1. Execute simple query workflow, capture thread_id
2. Create new workflow execution with captured thread_id
3. Verify conversation continues

**Expected Results:**
- [ ] Thread_id from first execution valid in second
- [ ] Conversation context maintained
- [ ] No errors about missing thread

**Pass Criteria:** Thread persistence verified across executions

---

### Test Category 3: Async Operations with Callbacks

#### Test 3.1: Webhook Callback Registration

**Objective:** Verify webhook callback_url registration works

**Steps:**
1. Import workflow `03-async-with-webhook.json`
2. Configure webhook trigger node
3. Execute workflow with callback_url
4. Wait for callback delivery

**Expected Results:**
- [ ] Initial response returns immediately (< 1 second)
- [ ] Response includes `async_mode: true`
- [ ] Response includes `status_url`
- [ ] Webhook receives callback within reasonable time (< 60 seconds)
- [ ] Callback payload contains complete result

**Verification:**
```bash
# Check webhook received callback
# In n8n: View webhook executions
# Verify POST received with N8nInvokeResponse payload
```

**Pass Criteria:** Callback successfully delivered to webhook URL

---

#### Test 3.2: Callback Error Handling

**Objective:** Verify error callbacks work for failed operations

**Steps:**
1. Configure workflow with invalid query (to trigger error)
2. Provide callback_url
3. Execute workflow
4. Verify error callback received

**Expected Results:**
- [ ] Error callback delivered to webhook
- [ ] Callback contains N8nErrorResponse format
- [ ] Error message is descriptive
- [ ] Error code is present

**Pass Criteria:** Error callbacks delivered successfully

---

### Test Category 4: Status Polling

#### Test 4.1: Async Status Polling Flow

**Objective:** Verify GET /status/{thread_id} polling works

**Steps:**
1. Import workflow `04-async-with-polling.json`
2. Execute workflow
3. Monitor status polling loop
4. Verify completion detected

**Expected Results:**
- [ ] Initial status: "pending" or "processing"
- [ ] Status updates during processing
- [ ] Final status: "completed"
- [ ] Result populated when status === "completed"
- [ ] Loop terminates when completed

**Verification:**
```bash
# Manual status check
THREAD_ID="<thread-id-from-workflow>"
curl -s http://hx-lang-server.hx.dev.local:8100/status/$THREAD_ID | jq
```

**Pass Criteria:** Status polling successfully detects completion

---

#### Test 4.2: Status Expiration Handling

**Objective:** Verify expired thread_id returns 404

**Steps:**
1. Generate thread_id
2. Wait for TTL expiration (or use invalid thread_id)
3. Poll status endpoint
4. Verify 404 error

**Expected Results:**
- [ ] HTTP 404 status code
- [ ] Error code: "THREAD_NOT_FOUND"
- [ ] Error message descriptive

**Pass Criteria:** Expired threads return appropriate error

---

### Test Category 5: Error Handling

#### Test 5.1: Validation Error (422)

**Objective:** Verify empty query rejected with validation error

**Steps:**
1. Import workflow `05-error-handling.json`
2. Execute test with empty query
3. Verify validation error

**Expected Results:**
- [ ] HTTP 422 status code
- [ ] Error response contains validation details
- [ ] Field-level error information present

**Verification:**
```bash
# Test empty query
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": ""}' | jq
```

**Pass Criteria:** Validation errors properly returned

---

#### Test 5.2: Thread Not Found (404)

**Objective:** Verify invalid thread_id returns 404

**Steps:**
1. Execute workflow with invalid thread_id
2. Verify 404 error response

**Expected Results:**
- [ ] HTTP 404 status code
- [ ] Error code: "THREAD_NOT_FOUND"

**Pass Criteria:** Invalid thread_id handled correctly

---

#### Test 5.3: Server Error Handling (500)

**Objective:** Verify graceful error handling for internal errors

**Steps:**
1. Trigger server error (if possible via test query)
2. Verify error response format

**Expected Results:**
- [ ] HTTP 500 status code
- [ ] Error response with error_code
- [ ] Request_id for debugging

**Pass Criteria:** Internal errors return structured error response

---

### Test Category 6: Performance and Reliability

#### Test 6.1: Concurrent Workflow Executions

**Objective:** Verify multiple n8n workflows can run concurrently

**Steps:**
1. Launch 5 concurrent workflow executions
2. Monitor all for successful completion
3. Verify no interference between executions

**Expected Results:**
- [ ] All 5 workflows complete successfully
- [ ] Each receives unique thread_id
- [ ] No cross-contamination of responses
- [ ] Response times reasonable (< 10 seconds)

**Pass Criteria:** Concurrent executions succeed without interference

---

#### Test 6.2: Large Query Handling

**Objective:** Verify large queries are handled properly

**Steps:**
1. Execute workflow with 4000-character query
2. Verify successful processing

**Expected Results:**
- [ ] Large query accepted (within 8000 char limit)
- [ ] Response generated successfully
- [ ] No truncation errors

**Pass Criteria:** Large queries handled correctly

---

#### Test 6.3: Long-Running Query Timeout

**Objective:** Verify timeout handling for sync queries

**Steps:**
1. Execute query with expected long processing time
2. Monitor for timeout or completion
3. Verify appropriate handling

**Expected Results:**
- [ ] Query completes OR times out gracefully
- [ ] If timeout, appropriate error message
- [ ] Async mode recommended for long queries

**Pass Criteria:** Long queries handled without crashes

---

## Test Results Documentation

### Test Execution Summary Template

Create file: `/opt/hx-lang-server/tests/n8n-integration-test-results.md`

```markdown
# n8n Integration Test Results

**Test Date:** 2025-12-04
**Tester:** Isabella (n8n Workflow Automation SME)
**hx-lang-server Version:** 1.0.0
**n8n Version:** 1.x

---

## Test Summary

| Category | Tests | Passed | Failed | Blocked |
|----------|-------|--------|--------|---------|
| Basic HTTP Request | 2 | | | |
| Conversation Continuity | 2 | | | |
| Async Callbacks | 2 | | | |
| Status Polling | 2 | | | |
| Error Handling | 3 | | | |
| Performance | 3 | | | |
| **TOTAL** | **14** | | | |

**Overall Pass Rate:** __%

---

## Detailed Test Results

### Test 1.1: Simple Synchronous Query
- **Status:** PASS / FAIL / BLOCKED
- **Execution Time:** ___ seconds
- **Notes:** ___
- **Evidence:** Screenshot/log excerpt

### Test 1.2: Query with Metadata
- **Status:** PASS / FAIL / BLOCKED
- **Notes:** ___

[Continue for all tests...]

---

## Issues Discovered

| Issue ID | Severity | Description | Status |
|----------|----------|-------------|--------|
| N8N-001 | High | ___ | Open |

---

## Recommendations

1. ___
2. ___

---

## Sign-Off

- **Tested By:** Isabella
- **Reviewed By:** Julia Santos (Testing & Quality Specialist)
- **Date:** 2025-12-04
- **Approved for Phase 2 Completion:** YES / NO
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Test results | `/opt/hx-lang-server/tests/n8n-integration-test-results.md` | Comprehensive test results |
| Test evidence | `/opt/hx-lang-server/tests/evidence/` | Screenshots and logs |

---

## Acceptance Criteria

- [ ] All 14 test cases executed
- [ ] 100% pass rate for basic functionality (Categories 1-2)
- [ ] 90%+ pass rate for advanced functionality (Categories 3-6)
- [ ] Test results documented with evidence
- [ ] Any failures have associated defect reports
- [ ] Performance tests show acceptable response times
- [ ] Error handling tests pass with correct status codes
- [ ] Conversation continuity verified across multiple queries

---

## Rollback Procedure

If critical failures discovered:

1. Document all failures in test results
2. Create defect reports for HIGH severity issues
3. Block Phase 2 completion until resolved
4. Escalate to Julia Santos (Testing & Quality Specialist)

---

## Notes

- **Test Environment:** hx.dev.local (development)
- **Network:** All services on 192.168.10.0/24
- **Credentials:** Standard development credentials
- **Concurrent Users:** Single tester, simulated concurrent workflows
- **Test Data:** No sensitive data used in tests

---

**Created By:** Isabella (n8n Workflow Automation SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: n8n Integration (FR-026, FR-027, FR-028)
