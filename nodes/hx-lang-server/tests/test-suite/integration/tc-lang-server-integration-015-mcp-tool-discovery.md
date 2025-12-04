# Test Case: Verify MCP Tool Discovery

**Test ID**: tc-lang-server-integration-015-mcp-tool-discovery
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-019 (Tool discovery)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that MCP tools are discovered from the FastMCP gateway.

---

## Prerequisites

- [ ] FastMCP connection working
- [ ] MCP tools registered with gateway

---

## Test Steps

### Step 1: Check Gateway Tool List
**Action:**
```bash
curl -s http://hx-fastmcp-server.hx.dev.local:8000/tools 2>/dev/null | head -c 500 || echo "Check tools endpoint"
```

**Expected Behavior:**
Tool list returned.

---

### Step 2: Trigger Discovery via Service
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -i "tool.*discover\|mcp.*tool" | head -5
```

**Expected Behavior:**
Tool discovery activity logged.

---

### Step 3: Verify Crawl4AI Tool Available
**Action:**
```bash
curl -s http://hx-fastmcp-server.hx.dev.local:8000/tools 2>/dev/null | grep -i "crawl4ai" || echo "Check for crawl4ai tools"
```

**Expected Behavior:**
Crawl4AI tools visible.

---

## Expected Results

- [ ] Tools discovered
- [ ] Crawl4AI available
- [ ] Discovery logged

---

## Pass/Fail Criteria

### PASS Criteria
1. Tools discovered
2. Key tools available

### FAIL Criteria
1. No tools found
2. Discovery fails

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
