# Test Case: PPTX Processing (95%+ Slide Structure)

**Test ID**: tc-docling-mcp-multimodal-004
**Test Area**: Multimodal Validation
**Priority**: MEDIUM
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Validate PPTX processing achieves ≥95% slide structure preservation.

---

## Test Steps

### Step 1: Convert PPTX Presentation

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
        "source": "/opt/docling-mcp/tests/test-data/presentation.pptx"
      }
    },
    "id": 1
  }' > /tmp/pptx-result.json
```

**Expected**: Slides extracted

---

### Step 2: Validate Slide Structure

**Action**:
```python
pytest tests/multimodal/test_pptx_structure.py -v
```

**Expected**: Slide structure accuracy ≥95%

**Pass Criteria**: ≥95% of slides extracted with structure

---

## Pass/Fail Criteria

**PASS**: Slide structure ≥95%

**FAIL**: Structure <95%

---

**Test Case Version**: 1.0
