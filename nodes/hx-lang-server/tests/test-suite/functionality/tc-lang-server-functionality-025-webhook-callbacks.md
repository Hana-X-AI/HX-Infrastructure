# Test Case: Verify Webhook Callbacks

**Test ID**: tc-lang-server-functionality-025-webhook-callbacks
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-023 (Support webhook callbacks for n8n integration)
**Based on Plan**: Work Stream 10 (FastAPI Application)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that the service supports webhook callback registration for async operation completion notifications.

---

## Prerequisites

- [ ] Service running and healthy
- [ ] Test webhook receiver available (e.g., httpbin or local receiver)

---

## Test Steps

### Step 1: Check Webhooks Endpoint Exists
**Action:**
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8100/webhooks \
  -H "Content-Type: application/json" \
  -d '{"url": "https://httpbin.org/post", "events": ["completion"]}'
```

**Expected Behavior:**
Endpoint exists (may return 200, 201, or 400 with validation error).

---

### Step 2: Register Test Webhook
**Action:**
```bash
curl -s -X POST http://localhost:8100/webhooks \
  -H "Content-Type: application/json" \
  -d '{"url": "https://httpbin.org/post", "events": ["task_complete"]}' | jq .
```

**Expected Behavior:**
Webhook registered or registration response.

---

### Step 3: Invoke with Callback URL
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Simple task", "callback_url": "https://httpbin.org/post"}' | jq .
```

**Expected Behavior:**
Request accepted, callback noted.

---

### Step 4: Verify Webhook Documentation
**Action:**
```bash
curl -s http://localhost:8100/openapi.json | jq '.paths["/webhooks"] // "Endpoint not documented"'
```

**Expected Behavior:**
Webhooks endpoint documented in OpenAPI.

---

## Expected Results

- [ ] Webhooks endpoint exists
- [ ] Registration works
- [ ] Callback URL accepted in invoke
- [ ] API documented

---

## Pass/Fail Criteria

### PASS Criteria
1. Webhook registration works
2. Callback URLs accepted

### FAIL Criteria
1. No webhook support
2. Registration fails

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-023

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
