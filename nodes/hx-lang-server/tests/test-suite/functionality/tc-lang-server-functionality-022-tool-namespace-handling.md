# Test Case: Verify Tool Namespace Handling

**Test ID**: tc-lang-server-functionality-022-tool-namespace-handling
**Service**: hx-lang-server
**Test Area**: functionality
**Created**: 2025-12-04
**Status**: Not Run
**Priority**: P2 (High)

---

## Test Metadata

**Based on Spec**: FR-020 (Handle tool namespace prefixes from gateway)
**Test Type**: Manual
**Estimated Execution Time**: 5 minutes

---

## Test Objective

Verifies that the MCP client correctly handles tool namespace prefixes (e.g., crawl4ai__smart_crawl_url) from the FastMCP gateway.

---

## Prerequisites

- [ ] Service running
- [ ] FastMCP gateway accessible

---

## Test Steps

### Step 1: Verify Namespace Prefix Handling
**Action:**
```bash
# Check logs for namespace-prefixed tool calls
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -E "crawl4ai__|docling__" | head -5
```

**Expected Behavior:**
Namespaced tool calls visible in logs.

---

### Step 2: Invoke Namespaced Tool
**Action:**
```bash
curl -s -X POST http://localhost:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Use the crawl4ai tool to fetch https://example.com"}' | jq '.metadata.tool_called // .response[:100]'
```

**Expected Behavior:**
Tool called with proper namespace.

---

### Step 3: Verify No Namespace Errors
**Action:**
```bash
sudo journalctl -u hx-lang-server --since "10 minutes ago" | grep -iE "namespace.*error|tool.*not.*found" | head -3
```

**Expected Behavior:**
No namespace-related errors.

---

## Expected Results

- [ ] Namespace prefixes handled
- [ ] Tools invoked correctly
- [ ] No namespace errors

---

## Pass/Fail Criteria

### PASS Criteria
1. Namespaces handled correctly
2. No errors

### FAIL Criteria
1. Namespace errors
2. Tool not found due to prefix

---

## Actual Results

**Execution Date**: [DATE]
**Executed By**: [Name]
**Test Result**: [PASS | FAIL | BLOCKED]

---

## Related Documentation

- `specification/node-spec.md` - FR-020, MCP Client Integration section

---

**Template Version**: 1.0
**Last Updated**: 2025-12-04
