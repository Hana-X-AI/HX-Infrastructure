# Test Case: Image OCR Processing (90%+ Accuracy)

**Test ID**: tc-docling-mcp-multimodal-006
**Test Area**: Multimodal Validation
**Priority**: MEDIUM
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Validate image OCR processing achieves ≥90% accuracy for PNG/JPG images.

---

## Test Steps

### Step 1: Convert Image with OCR

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
        "source": "/opt/docling-mcp/tests/test-data/text-image.png"
      }
    },
    "id": 1
  }' > /tmp/image-ocr-result.json
```

**Expected**: OCR text extracted from image

---

### Step 2: Validate OCR Accuracy

**Action**:
```python
pytest tests/multimodal/test_image_ocr.py -v
```

**Expected**: OCR accuracy ≥90%

**Pass Criteria**: ≥90% text extraction accuracy

---

## Pass/Fail Criteria

**PASS**: OCR accuracy ≥90%

**FAIL**: Accuracy <90%

---

**Test Case Version**: 1.0
