# Test Case: Digital PDF Processing (99%+ Accuracy)

**Test ID**: tc-docling-mcp-multimodal-001
**Test Area**: Multimodal Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Validate digital PDF processing achieves ≥99% text extraction accuracy with structure preservation.

---

## Test Coverage

**Requirements Covered**:
- FR-005: Support PDF format
- FR-006: Preserve document structure
- Test Plan: Multimodal Validation Criteria (lines 363-434)

---

## Test Steps

### Step 1: Convert Digital PDF

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
        "source": "/opt/docling-mcp/tests/test-data/digital-report.pdf"
      }
    },
    "id": 1
  }' | jq '.' > /tmp/pdf-digital-result.json
```

**Expected**: DoclingDocument JSON returned

---

### Step 2: Validate Text Extraction Accuracy

**Action**:
```python
# Use pytest test (conftest.py fixture validate_pdf_processing)
pytest tests/multimodal/test_pdf_digital_accuracy.py -v
```

**Expected**: Text extraction accuracy ≥99%

**Pass Criteria**: Accuracy score ≥0.99 (99%)

---

### Step 3: Verify Heading Hierarchy Preserved

**Action**:
```bash
cat /tmp/pdf-digital-result.json | jq '.result.content[0].text | fromjson | .doc_items[] | select(.type=="heading")'
```

**Expected**: 
- Headings extracted with correct levels (H1, H2, H3)
- Hierarchy preserved (H1 → H2 → H3 nesting)

**Pass Criteria**: All headings present with correct levels

---

### Step 4: Verify Table Structure Preserved

**Action**:
```bash
cat /tmp/pdf-digital-result.json | jq '.result.content[0].text | fromjson | .doc_items[] | select(.type=="table")'
```

**Expected**:
- Tables extracted with structure (rows, columns, cells)
- Merged cells handled correctly
- Headers identified

**Pass Criteria**: Table count matches source PDF, structure preserved

---

### Step 5: Verify Lists Preserved

**Action**:
```bash
cat /tmp/pdf-digital-result.json | jq '.result.content[0].text | fromjson | .doc_items[] | select(.type=="list")'
```

**Expected**: 
- Ordered lists with numbering
- Unordered lists with bullets
- Nested lists preserved

**Pass Criteria**: All lists extracted correctly

---

## Pass/Fail Criteria

**PASS**: 
- Text accuracy ≥99%
- Heading hierarchy preserved
- Tables extracted with structure
- Lists preserved

**FAIL**: Accuracy <99% or structure preservation failures

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-multi-001-pdf-digital-accuracy.md`

---

**Test Case Version**: 1.0
