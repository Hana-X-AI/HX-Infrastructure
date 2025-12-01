# Test Case: MCP Protocol Compliance

**Test ID**: tc-docling-mcp-integration-005
**Test Area**: Integration Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify MCP protocol compliance across all three transports (HTTP, SSE, stdio).

---

## Test Coverage

**Requirements Covered**:
- FR-001: Implement MCP protocol version 1.0+
- FR-003: Support all three MCP transports
- FR-004: Return MCP-compliant tool schemas
- Charter SC-001: MCP Server Operational

---

## Test Steps

### Step 1: Test Tool Discovery Endpoint

**Action**:
```bash
curl -X POST http://192.168.10.217:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  }'
```

**Expected**:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {"name": "convert_document", "description": "...", "inputSchema": {...}},
      ... (19 tools total)
    ]
  },
  "id": 1
}
```

**Pass Criteria**: All 19 tools listed with schemas

---

### Step 2: Test Tool Execution Endpoint

**Action**:
```bash
curl -X POST http://192.168.10.217:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "convert_document",
      "arguments": {"source": "/opt/docling-mcp/tests/test-data/sample.pdf"}
    },
    "id": 2
  }'
```

**Expected**: Valid MCP-compliant response with result

---

### Step 3: Test Error Handling (Invalid Tool)

**Action**:
```bash
curl -X POST http://192.168.10.217:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "nonexistent_tool",
      "arguments": {}
    },
    "id": 3
  }'
```

**Expected**:
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Method not found"
  },
  "id": 3
}
```

**Pass Criteria**: Error code -32601 (Method not found) returned

---

### Step 4: Test SSE Transport (if configured)

**Action**:
```bash
curl -N http://192.168.10.217:8000/mcp/sse
```

**Expected**: SSE stream established (if SSE transport enabled)

---

## Pass/Fail Criteria

**PASS**: All MCP protocol endpoints functional, error handling correct

**FAIL**: Protocol violations, incorrect error codes, or transports non-functional

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-int-005-mcp-protocol-violation.md`

---

**Test Case Version**: 1.0
