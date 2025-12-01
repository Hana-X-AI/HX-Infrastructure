# Test Case: Split Document into Sections

**Test ID**: tc-docling-mcp-functionality-015
**Test Area**: Functionality - Manipulation Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `split_document` MCP tool functions correctly.

---

## Test Coverage

**Requirements Covered**:
- FR-002: Expose 19 core MCP tools - split_document
- Charter SC-001: MCP Server Operational (19 tools)

---

## Test Steps

### Step 1: Invoke split_document Tool

**Action**:
```bash
curl -X POST http://192.168.10.217:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "split_document",
      "arguments": {
        "source": "/opt/docling-mcp/tests/test-data/sample-document.pdf"
      }
    },
    "id": 15
  }'
```

**Expected**: Valid JSON-RPC response with split_document result

**Pass Criteria**: Tool executes successfully, output format correct

---

## Pass/Fail Criteria

**PASS**: Tool invocation successful, valid output format

**FAIL**: Tool invocation fails, invalid format, or error returned

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-func-015-split_document-failed.md`

---

**Test Case Version**: 1.0
