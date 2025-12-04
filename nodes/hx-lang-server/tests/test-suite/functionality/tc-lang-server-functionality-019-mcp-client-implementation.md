# Test Case: Verify MCP Client Implementation

**Test ID**: tc-lang-server-functionality-019-mcp-client-implementation
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-017 (Implement MCP CLIENT using langchain-mcp-adapters)
**Based on Plan**: Work Stream 9 (MCP Client Integration)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server implements MCP client (not server) functionality using langchain-mcp-adapters to consume tools from FastMCP gateway.

---

## Prerequisites

- [ ] Service running
- [ ] langchain-mcp-adapters installed

---

## Test Steps

### Step 1: Verify MCP Adapter Package
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show langchain-mcp-adapters | grep -E "Name:|Version:"
```

**Expected Behavior:**
langchain-mcp-adapters installed.

---

### Step 2: Submit Tool Query
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Fetch content from https://example.com"}' | jq '{query_type, worker_used}'
```

**Expected Behavior:**
Tool query routed to tool agent using MCP client.

---

### Step 3: Verify MCP Configuration
**Action:**
```bash
grep "FASTMCP_URL\|MCP" /opt/hx-lang-server/.env
```

**Expected Behavior:**
MCP gateway URL configured.

---

## Expected Results

- [ ] MCP client package installed
- [ ] Tool queries use MCP client
- [ ] FastMCP gateway configured

---

## Pass/Fail Criteria

### PASS Criteria
1. MCP adapters installed
2. Tool routing works

### FAIL Criteria
1. Package missing
2. Tool queries fail

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-017

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
