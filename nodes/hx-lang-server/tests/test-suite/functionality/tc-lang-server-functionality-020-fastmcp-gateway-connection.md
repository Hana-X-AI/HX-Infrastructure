# Test Case: Verify FastMCP Gateway Connection

**Test ID**: tc-lang-server-functionality-020-fastmcp-gateway-connection
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-018 (Connect to FastMCP gateway at hx-fastmcp-server.hx.dev.local)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the MCP client connects to the FastMCP gateway for tool access.

---

## Prerequisites

- [ ] Service running
- [ ] FastMCP gateway accessible at hx-fastmcp-server.hx.dev.local:8000

---

## Test Steps

### Step 1: Verify Gateway URL Configuration
**Action:**
```bash
grep "FASTMCP_URL" /opt/hx-lang-server/.env
```

**Expected Behavior:**
FASTMCP_URL=http://hx-fastmcp-server.hx.dev.local:8000

---

### Step 2: Verify Gateway Connectivity
**Action:**
```bash
curl -s http://hx-fastmcp-server.hx.dev.local:8000/health || echo "Gateway health check"
```

**Expected Behavior:**
Gateway responds.

---

### Step 3: Test Tool Query Through Gateway
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Use the crawl tool to get https://example.com"}' | jq '{worker_used, response: .response[:100]}'
```

**Expected Behavior:**
Tool invocation attempted via gateway.

---

## Expected Results

- [ ] Gateway URL configured
- [ ] Gateway accessible
- [ ] Tool queries use gateway

---

## Pass/Fail Criteria

### PASS Criteria
1. Configuration correct
2. Gateway connectivity works

### FAIL Criteria
1. Wrong URL
2. Gateway unreachable

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-018

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
