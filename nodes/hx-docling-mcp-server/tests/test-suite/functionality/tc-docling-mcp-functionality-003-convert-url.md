# Test Case: Convert Document from URL

**Test ID**: tc-docling-mcp-functionality-003
**Test Area**: Functionality - Conversion Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `convert_document` MCP tool can fetch and convert documents from URLs.

---

## Test Coverage

**Requirements Covered**:
- FR-002: convert_document tool
- FR-008: Support document input via URL

---

## Test Steps

### Step 1: Convert Document from HTTP URL

**Action**:
```bash
curl -X POST http://hx-docling-mcp-server.hx.dev.local:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "convert_document",
      "arguments": {
        "source": "http://example.com/test-document.pdf"
      }
    },
    "id": 3
  }'
```

**Expected**: Document fetched from URL and converted

**Pass Criteria**: HTTP URL source supported, document converted

---

## Pass/Fail Criteria

**PASS**: URL document fetched and converted successfully

**FAIL**: URL fetch fails or conversion errors

---

**Test Case Version**: 1.0
