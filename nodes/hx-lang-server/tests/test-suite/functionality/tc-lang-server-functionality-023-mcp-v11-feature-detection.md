# Test Case: Verify MCP v1.1 Feature Detection

**Test ID**: tc-lang-server-functionality-023-mcp-v11-feature-detection
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-020a (Support MCP protocol v1.1 with feature detection for backward compatibility)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the MCP client supports MCP protocol v1.1 with feature detection for backward compatibility with v1.0 servers.

---

## Prerequisites

- [ ] Service running
- [ ] FastMCP gateway accessible

---

## Test Steps

### Step 1: Verify MCP Adapters Version
**Action:**
```bash
/opt/hx-lang-server/venv/bin/pip show langchain-mcp-adapters | grep Version
```

**Expected Behavior:**
Version supports MCP v1.1.

---

### Step 2: Check for v1.1 Features in Logs
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "30 minutes ago" | grep -iE "mcp.*1\\.1|protocol.*version|feature.*detect" | head -5
```

**Expected Behavior:**
Protocol version or feature detection visible.

---

### Step 3: Verify Fallback Works
**Action:**
```bash
# Normal tool invocation should work regardless of protocol version
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Fetch https://example.com"}' | jq '.response[:100]'
```

**Expected Behavior:**
Tool invocation works with version negotiation.

---

## Expected Results

- [ ] MCP v1.1 supported
- [ ] Feature detection active
- [ ] Backward compatibility maintained

---

## Pass/Fail Criteria

### PASS Criteria
1. Modern MCP adapters installed
2. Tool invocation works

### FAIL Criteria
1. Protocol version errors
2. Compatibility issues

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-020a

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
