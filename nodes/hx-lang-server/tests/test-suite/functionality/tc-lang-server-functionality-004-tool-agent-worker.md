# Test Case: Verify Tool Agent Worker

**Test ID**: tc-lang-server-functionality-004-tool-agent-worker
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-002 (Worker agent types: Tool Agent), FR-017-020 (MCP integration)
**Based on Plan**: Work Stream 6 (Task 056), Work Stream 9 (MCP Client Integration)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

**What This Test Validates:**
Verifies that the Tool Agent worker correctly handles tool-related queries by routing them to appropriate MCP tools via the FastMCP gateway.

**Why This Test Is Important:**
Tool invocation extends LangGraph capabilities to external tools like web crawling. Correct routing ensures tools are invoked properly.

---

## Prerequisites

**Service State:**
- [ ] Service running and healthy
- [ ] Tool agent registered with supervisor

**Dependencies:**
- [ ] FastMCP gateway accessible (hx-fastmcp-server.hx.dev.local:8000)
- [ ] Crawl4AI MCP available through gateway

**Environment:**
- [ ] Access to API on port 8100

**Permissions:**
- [ ] API access

---

## Test Setup

### Pre-Test Actions
1. Verify service is running
2. Verify FastMCP gateway is accessible

### Test Data
**Required Test Data:**
- Tool trigger queries containing: crawl, fetch, scrape, web, url

---

## Test Steps

### Step 1: Submit Tool Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Crawl the webpage at https://example.com"}' | jq .
```

**Expected Behavior:**
Query routed to tool agent.

**How to Verify:**
worker_used indicates tool agent.

---

### Step 2: Verify Tool Worker Selection
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Fetch the content from https://docs.python.org"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
query_type is "tool", worker_used is tool_agent.

**How to Verify:**
Both fields indicate tool processing.

---

### Step 3: Verify "Scrape" Keyword Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Scrape the data from this website"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"Scrape" keyword triggers tool agent.

**How to Verify:**
query_type is "tool".

---

### Step 4: Verify "Web" Keyword Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Search the web for information"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
"Web" keyword triggers tool agent.

**How to Verify:**
query_type is "tool".

---

### Step 5: Verify URL in Query Routing
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Get the contents of https://github.com"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
URL presence may influence routing.

**How to Verify:**
Appropriate worker selected.

---

### Step 6: Verify Tool Invocation Metadata
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Fetch https://httpbin.org/get"}' | jq '.metadata'
```

**Expected Behavior:**
Metadata may include tool invocation details.

**How to Verify:**
metadata object present.

---

### Step 7: Verify Tool Results in Response
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Crawl https://example.com and summarize"}' | jq '.tool_results // .response'
```

**Expected Behavior:**
Tool results integrated into response.

**How to Verify:**
Response contains relevant information from the URL.

---

## Expected Results

### Primary Expected Results
- [ ] Tool queries routed to tool agent
- [ ] query_type correctly classified as "tool"
- [ ] worker_used shows tool_agent
- [ ] Keyword triggers work (crawl, fetch, scrape, web, url)
- [ ] Tool invocation attempted via MCP
- [ ] Results integrated into response

### Observable Indicators
**API Response:**
- query_type: "tool"
- worker_used: "tool_agent" or similar
- tool_results may be present

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. Tool keywords trigger tool agent
2. query_type correctly identified as "tool"
3. worker_used indicates tool agent
4. No server errors
5. Tool invocation attempted

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. Tool queries not routed to tool agent
2. query_type incorrect
3. Server error on tool query
4. Complete failure to invoke tools
5. Crashes on tool queries

### BLOCKED Criteria
**Test is BLOCKED if:**
1. Service not running
2. FastMCP gateway inaccessible

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
- Requires tc-lang-server-functionality-001 to pass
- Related to functionality-019-021 (MCP tests)

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| | | | |

---

## Related Documentation

**Related Specifications:**
- `specification/node-spec.md` - FR-002, FR-017-020

**Related Test Cases:**
- `tc-lang-server-functionality-019-021` - MCP tests
- `tc-lang-server-integration-014-016` - MCP integration tests
- `tc-lang-server-e2e-007` - MCP workflow E2E

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
