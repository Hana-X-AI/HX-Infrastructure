# Test Case: Verify MCP Tool Invocation

**Test ID**: tc-lang-server-integration-016-mcp-tool-invocation
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-019 (Tool invocation)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that MCP tools can be invoked through the service.

---

## Prerequisites

- [ ] MCP tool discovery working
- [ ] Crawl4AI tool available

---

## Test Steps

### Step 1: Invoke Tool via Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Crawl https://example.com and show the content"}' | jq '{worker_used, response: .response[:200]}'
```

**Expected Behavior:**
Tool agent invokes crawl tool.

---

### Step 2: Verify Tool Results
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Fetch the title from https://example.com"}' | jq '.response' | head -c 300
```

**Expected Behavior:**
Response contains fetched content.

---

### Step 3: Check Tool Invocation Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -i "tool.*invoke\|crawl4ai" | head -5
```

**Expected Behavior:**
Tool invocation logged.

---

## Expected Results

- [ ] Tool invocation works
- [ ] Results returned
- [ ] Activity logged

---

## Pass/Fail Criteria

### PASS Criteria
1. Invocation succeeds
2. Results in response

### FAIL Criteria
1. Invocation fails
2. No results

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
