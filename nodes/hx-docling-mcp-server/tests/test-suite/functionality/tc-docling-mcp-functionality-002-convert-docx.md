# Test Case: Convert DOCX Document

**Test ID**: tc-docling-mcp-functionality-002
**Test Area**: Functionality - Conversion Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `convert_document` MCP tool correctly converts DOCX to DoclingDocument JSON format.

---

## Test Coverage

**Requirements Covered**:
- FR-002: convert_document tool
- FR-005: Support DOCX format
- FR-006: Preserve document structure

---

## Test Steps

### Step 1: Convert DOCX Document

**Action**:
```bash
curl -X POST http://192.168.10.217:8000/mcp/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "convert_document",
      "arguments": {
        "source": "/opt/docling-mcp/tests/test-data/sample-document.docx"
      }
    },
    "id": 2
  }'
```

**Expected**: DoclingDocument JSON with DOCX content

---

### Step 2: Verify Style Preservation

**Action**:
```bash
# Check bold/italic styles preserved
curl ... | jq '.result.content[0].text | fromjson | .doc_items[] | select(.style)'
```

**Expected**: Styles (bold, italic, underline) preserved in doc_items

---

## Pass/Fail Criteria

**PASS**: DOCX converted with styles preserved

**FAIL**: Conversion fails or styles lost

---

**Test Case Version**: 1.0
