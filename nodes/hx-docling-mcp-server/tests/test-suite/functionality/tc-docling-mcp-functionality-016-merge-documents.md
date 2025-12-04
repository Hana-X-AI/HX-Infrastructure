# Test Case: Merge Multiple Documents

**Test ID**: tc-docling-mcp-functionality-016
**Test Area**: Functionality - Manipulation Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `merge_documents` MCP tool functions correctly.

---

## Test Coverage

**Requirements Covered**:
- FR-002: Expose 19 core MCP tools - merge_documents
- Charter SC-001: MCP Server Operational (19 tools)

---

## Test Steps

### Step 1: Invoke merge_documents Tool

**Action**:
```bash
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "merge_documents",
      "arguments": {
        "source": "/opt/docling-mcp/tests/test-data/sample-document.pdf"
      }
    },
    "id": 16
  }'
```

**Expected**: Valid JSON-RPC response with merge_documents result

**Pass Criteria**: Tool executes successfully, output format correct

---

## Pass/Fail Criteria

**PASS**: Tool invocation successful, valid output format

**FAIL**: Tool invocation fails, invalid format, or error returned

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-func-016-merge_documents-failed.md`

---

**Test Case Version**: 1.0
