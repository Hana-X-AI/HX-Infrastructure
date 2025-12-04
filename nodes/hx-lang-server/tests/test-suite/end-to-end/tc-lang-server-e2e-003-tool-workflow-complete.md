# Test Case: Tool Workflow Complete End-to-End

**Test ID**: tc-lang-server-e2e-003-tool-workflow-complete
**Service**: hx-lang-server
**Test Area**: end-to-end
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: SC-008 (Tool agent invokes MCP tools via FastMCP)
**Test Type**: Manual
**Estimated Execution Time**: 10 minutes

---

## Test Objective

Validates the complete tool invocation workflow from query through FastMCP tool discovery to tool execution and response.

---

## Prerequisites

- [ ] hx-lang-server service running
- [ ] FastMCP gateway running
- [ ] Crawl4AI or other tools registered

---

## Test Steps

### Step 1: Submit Tool-Requiring Query
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Crawl and summarize the content from https://example.com"
  }' --max-time 120 | jq '.'
```

**Expected Behavior:**
Response contains crawled content.

---

### Step 2: Verify Worker Selection
**Action:**
```bash
curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Fetch the title from a webpage"
  }' --max-time 120 | jq '.worker_used'
```

**Expected Behavior:**
Worker should be "tool" or "tool_agent".

---

### Step 3: Verify Tool Discovery Occurred
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "tool.*discover|mcp.*tool|available.*tool" | head -5
```

**Expected Behavior:**
Tool discovery logged.

---

### Step 4: Verify Tool Execution Logged
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "tool.*invoke|execute.*tool|crawl4ai" | head -5
```

**Expected Behavior:**
Tool execution logged.

---

### Step 5: Verify FastMCP Communication
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "5 minutes ago" | grep -iE "fastmcp|mcp.*gateway|sse.*connect" | head -5
```

**Expected Behavior:**
FastMCP gateway communication logged.

---

## Expected Results

- [ ] Tool queries processed successfully
- [ ] Tool worker selected
- [ ] Tool discovery works
- [ ] Tool execution succeeds
- [ ] FastMCP integration functional

---

## Pass/Fail Criteria

### PASS Criteria
1. Complete tool workflow executes
2. Tool results returned
3. FastMCP integration works

### FAIL Criteria
1. Tool workflow fails
2. No tool results
3. FastMCP connection fails

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
