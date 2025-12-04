# Test Case: Verify Tool Discovery and Invocation

**Test ID**: tc-lang-server-functionality-021-tool-discovery-invocation
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-019 (Support tool discovery and invocation for Crawl4AI MCP)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Verifies that the MCP client discovers available tools from the gateway and can invoke them, specifically Crawl4AI tools.

---

## Prerequisites

- [ ] Service running
- [ ] FastMCP gateway accessible
- [ ] Crawl4AI MCP registered with gateway

---

## Test Steps

### Step 1: Trigger Tool Discovery
**Action:**
```bash
# Submit tool query to trigger discovery
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "List available tools"}' | jq '.metadata.available_tools // .response[:200]'
```

**Expected Behavior:**
Tool list or relevant response.

---

### Step 2: Invoke Crawl4AI Tool
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Crawl the webpage at https://httpbin.org/html and extract the content"}' | jq '{worker_used, tool_results: .tool_results, response: .response[:200]}'
```

**Expected Behavior:**
Tool invocation attempted with results.

---

### Step 3: Verify Tool Results in Response
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Fetch and summarize https://example.com"}' | jq '.response' | head -c 500
```

**Expected Behavior:**
Response includes content from crawled URL.

---

## Expected Results

- [ ] Tool discovery works
- [ ] Crawl4AI tool invocable
- [ ] Tool results integrated

---

## Pass/Fail Criteria

### PASS Criteria
1. Tools discovered
2. Invocation succeeds
3. Results in response

### FAIL Criteria
1. No tool discovery
2. Invocation fails
3. No results returned

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-019

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
