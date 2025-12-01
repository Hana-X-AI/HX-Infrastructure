# Test Case: Export Document to JSON

**Test ID**: tc-docling-mcp-functionality-019
**Test Area**: Functionality - Manipulation Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `export_json` MCP tool functions correctly.

---

## Test Coverage

**Requirements Covered**:
- FR-002: Expose 19 core MCP tools - export_json
- Charter SC-001: MCP Server Operational (19 tools)

---

## Test Steps

### Step 1: Invoke export_json Tool

**Action**:
```bash
curl -X POST http://192.168.10.217:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "export_json",
      "arguments": {
        "source": "/opt/docling-mcp/tests/test-data/sample-document.pdf"
      }
    },
    "id": 19
  }'
```

**Expected**: Valid JSON-RPC response with export_json result

**Pass Criteria**: Tool executes successfully, output format correct

---

## Pass/Fail Criteria

**PASS**: Tool invocation successful, valid output format

**FAIL**: Tool invocation fails, invalid format, or error returned

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-func-019-export_json-failed.md`

---

**Test Case Version**: 1.0
