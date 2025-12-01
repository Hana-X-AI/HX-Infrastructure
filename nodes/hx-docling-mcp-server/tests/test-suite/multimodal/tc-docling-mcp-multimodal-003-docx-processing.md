# Test Case: DOCX Processing (99%+ Accuracy)

**Test ID**: tc-docling-mcp-multimodal-003
**Test Area**: Multimodal Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Validate DOCX processing achieves ≥99% accuracy with style preservation.

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
        "source": "/opt/docling-mcp/tests/test-data/business-document.docx"
      }
    },
    "id": 1
  }' > /tmp/docx-result.json
```

**Expected**: DoclingDocument with DOCX content

---

### Step 2: Validate Text Accuracy

**Action**:
```python
pytest tests/multimodal/test_docx_accuracy.py -v
```

**Expected**: Text accuracy ≥99%

---

### Step 3: Verify Style Preservation

**Action**:
```bash
cat /tmp/docx-result.json | jq '.result.content[0].text | fromjson | .doc_items[] | select(.style)'
```

**Expected**: Styles (bold, italic, underline) preserved

**Pass Criteria**: Styles preserved for formatted text

---

## Pass/Fail Criteria

**PASS**: Text accuracy ≥99%, styles preserved

**FAIL**: Accuracy <99% or style loss

---

**Test Case Version**: 1.0
