# Test Case: Convert PDF Document

**Test ID**: tc-docling-mcp-functionality-001
**Test Area**: Functionality - Conversion Tools
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify `convert_document` MCP tool correctly converts PDF to DoclingDocument JSON format.

---

## Test Coverage

**Requirements Covered**:
- FR-001: MCP protocol compliance
- FR-002: Expose 19 core MCP tools - convert_document
- FR-005: Support 14+ document formats via Docling
- FR-006: Preserve document structure during conversion
- Charter SC-002: Document Ingestion via Docling

---

## Test Steps

### Step 1: Invoke MCP Tool via HTTP Transport

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
        "source": "/opt/docling-mcp/tests/test-data/sample-report.pdf"
      }
    },
    "id": 1
  }'
```

**Expected Result**:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [{
      "type": "text",
      "text": "{\"doc_items\":[...],\"metadata\":{\"title\":\"Sample Report\",...}}"
    }]
  },
  "id": 1
}
```

**Pass Criteria**: 
- HTTP 200 response
- Valid JSON-RPC response format
- DoclingDocument JSON in result.content[0].text

---

### Step 2: Verify DoclingDocument Structure

**Action**:
```bash
# Parse returned DoclingDocument JSON
curl ... | jq '.result.content[0].text | fromjson | keys'
```

**Expected**: Keys include `doc_items`, `metadata`, `main_text`

---

### Step 3: Verify Structure Preservation

**Action**:
```bash
# Check headings preserved
curl ... | jq '.result.content[0].text | fromjson | .doc_items[] | select(.type=="heading")'

# Check tables preserved  
curl ... | jq '.result.content[0].text | fromjson | .doc_items[] | select(.type=="table")'
```

**Expected**: 
- Headings with levels (H1, H2, H3) extracted
- Tables with structure preserved

**Pass Criteria**: Document structure (headings, tables, lists) preserved

---

## Pass/Fail Criteria

**PASS**: PDF converted, DoclingDocument JSON returned, structure preserved

**FAIL**: Conversion fails, invalid JSON, structure lost

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-func-001-pdf-conversion-failed.md`

---

**Test Case Version**: 1.0
