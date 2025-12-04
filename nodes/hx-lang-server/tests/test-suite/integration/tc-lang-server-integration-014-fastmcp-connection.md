# Test Case: Verify FastMCP Connection

**Test ID**: tc-lang-server-integration-014-fastmcp-connection
**Service**: hx-lang-server
**Test Area**: integration
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P1 (Critical)

---

## Test Metadata

**Based on Spec**: FR-018 (FastMCP gateway connection)
**Integration Point**: hx-fastmcp-server.hx.dev.local:8000
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that hx-lang-server can connect to FastMCP gateway for MCP tool access.

---

## Prerequisites

- [ ] FastMCP accessible at hx-fastmcp-server.hx.dev.local:8000

---

## Test Steps

### Step 1: Verify FastMCP Connectivity
**Action:**
```bash
curl -s http://hx-fastmcp-server.hx.dev.local:8000/health 2>/dev/null || echo "Check FastMCP health"
```

**Expected Behavior:**
Health endpoint responds.

---

### Step 2: Verify Configuration
**Action:**
```bash
grep "FASTMCP" /opt/hx-lang-server/.env
```

**Expected Behavior:**
FASTMCP_URL configured.

---

### Step 3: Test Service Health with FastMCP
**Action:**
```bash
curl -s http://localhost:8100/health | jq '.dependencies.fastmcp // .dependencies.mcp'
```

**Expected Behavior:**
FastMCP shows status.

---

## Expected Results

- [ ] FastMCP accessible
- [ ] Configuration correct
- [ ] Health integrated

---

## Pass/Fail Criteria

### PASS Criteria
1. Connection works
2. Config correct

### FAIL Criteria
1. Connection fails
2. Wrong config

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
