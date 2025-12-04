# Test Case: Generate Table Elements

**Test ID**: tc-docling-mcp-functionality-011
**Test Area**: Functionality - Generation Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `generate_table` MCP tool functions correctly.

---

## Test Coverage

**Requirements Covered**:
- FR-002: Expose 19 core MCP tools - generate_table
- Charter SC-001: MCP Server Operational (19 tools)

---

## Test Steps

### Step 1: Invoke generate_table Tool

**Action**:
```bash
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "generate_table",
      "arguments": {
        "source": "/opt/docling-mcp/tests/test-data/sample-document.pdf"
      }
    },
    "id": 11
  }'
```

**Expected**: Valid JSON-RPC response with tool result

**Pass Criteria**: Tool executes successfully, returns expected data structure

---

## Pass/Fail Criteria

**PASS**: Tool invocation successful, valid response returned

**FAIL**: Tool invocation fails, invalid response, or error returned

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-func-011-generate_table-failed.md`

---

**Test Case Version**: 1.0
