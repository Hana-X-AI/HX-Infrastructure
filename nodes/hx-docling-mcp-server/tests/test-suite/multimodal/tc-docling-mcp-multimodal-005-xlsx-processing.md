# Test Case: XLSX Processing (99%+ Cell Extraction)

**Test ID**: tc-docling-mcp-multimodal-005
**Test Area**: Multimodal Validation
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Validate XLSX processing achieves ≥99% cell data extraction accuracy.

---

## Test Steps

### Step 1: Convert XLSX Spreadsheet

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
        "source": "/opt/docling-mcp/tests/test-data/financial-data.xlsx"
      }
    },
    "id": 1
  }' > /tmp/xlsx-result.json
```

**Expected**: Cell data extracted

---

### Step 2: Validate Cell Data Accuracy

**Action**:
```python
pytest tests/multimodal/test_xlsx_accuracy.py -v
```

**Expected**: Cell extraction accuracy ≥99%

**Pass Criteria**: ≥99% of cells extracted correctly

---

## Pass/Fail Criteria

**PASS**: Cell accuracy ≥99%

**FAIL**: Accuracy <99%

---

**Test Case Version**: 1.0
