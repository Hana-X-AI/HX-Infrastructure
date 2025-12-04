# Test Case: Scanned PDF OCR Processing (85%+ Accuracy)

**Test ID**: tc-docling-mcp-multimodal-002
**Test Area**: Multimodal Validation
**Priority**: MEDIUM
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Validate scanned PDF OCR processing achieves ≥85% accuracy with layout detection.

---

## Test Coverage

**Requirements Covered**:
- FR-005: Support PDF format with OCR
- Test Plan: Scanned PDF Validation (lines 411-434)

---

## Test Steps

### Step 1: Convert Scanned PDF with OCR

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
        "source": "/opt/docling-mcp/tests/test-data/scanned-document.pdf"
      }
    },
    "id": 1
  }' > /tmp/pdf-scanned-result.json
```

**Expected**: OCR processed, text extracted

---

### Step 2: Validate OCR Accuracy

**Action**:
```python
# Compare OCR output to ground truth
pytest tests/multimodal/test_pdf_scanned_ocr.py -v
```

**Expected**: OCR accuracy ≥85%

**Pass Criteria**: Accuracy ≥0.85 (85%)

---

### Step 3: Verify Layout Detection

**Action**:
```bash
cat /tmp/pdf-scanned-result.json | jq '.result.content[0].text | fromjson | .layout'
```

**Expected**:
- Text regions identified
- Image regions identified
- Layout structure detected

**Pass Criteria**: Layout detection successful

---

## Pass/Fail Criteria

**PASS**: OCR accuracy ≥85%, layout detection successful

**FAIL**: Accuracy <85% or layout detection fails

---

**Test Case Version**: 1.0
