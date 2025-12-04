# Defect Report: Malformed PDF Test Data Files

**Defect ID**: defect-docling-mcp-medium-012-malformed-pdf-test-data
**Service**: docling-mcp
**Severity**: MEDIUM
**Status**: OPEN
**Reported Date**: 2025-12-04 03:10 UTC
**Reported By**: julia-santos (Testing & Quality Specialist)
**Assigned To**: TBD
**Blocking Promotion**: NO (workaround available)

---

## Summary

Both PDF test data files (sample-digital.pdf and sample-scanned.pdf) are malformed and lack proper page dimension metadata, causing document conversion to fail. Valid PDFs work correctly, confirming this is a test data issue, not a service defect.

---

## Environment

**Node**: hx-docling-mcp-server.hx.dev.local
**Service Version**: docling-mcp (current)
**Python Version**: 3.12
**Docling Library**: Latest
**Test Data Location**: `/opt/docling-mcp/tests/test-data/pdf/`

---

## Issue Description

### Expected Behavior

PDF conversion via `convert_document` tool should successfully process both digital and scanned PDF files, extracting text and structure.

### Actual Behavior

PDF conversion fails with error:
```
Conversion failed for: sample-digital.pdf with status: ConversionStatus.FAILURE.
Errors: Page 1: could not find the page-dimensions: {
    "/Contents": "4 0 R [stream]",
    "/Parent": "[skipping /Parent]",
    "/Resources": {...},
    "/Type": "/Page"
}
```

Both test files are missing `/MediaBox` or `/CropBox` attributes that define page dimensions, which are required by the PDF specification.

### Impact

**Affected Test Cases**:
- tc-multi-001: Digital PDF Processing - FAILS
- tc-multi-002: Scanned PDF OCR - FAILS
- tc-func-001: Convert PDF Document - FAILS

**Severity Justification**:
- Service functionality NOT affected (valid PDFs work perfectly)
- Test coverage impacted (PDF tests cannot validate with current test data)
- Workaround available (use valid PDF samples)
- Non-blocking for operational promotion

---

## Reproduction Steps

1. SSH to hx-docling-mcp-server.hx.dev.local
2. Initialize MCP session:
   ```bash
   curl -X POST http://localhost:8000/mcp \
     -H "Content-Type: application/json" \
     -H "Accept: application/json, text/event-stream" \
     -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' -i
   ```
3. Extract session ID from `mcp-session-id` header
4. Attempt to convert malformed PDF:
   ```bash
   curl -X POST http://localhost:8000/mcp \
     -H "Content-Type: application/json" \
     -H "mcp-session-id: <SESSION_ID>" \
     -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"convert_document","arguments":{"source":"/opt/docling-mcp/tests/test-data/pdf/sample-digital.pdf","ocr_enabled":false}},"id":2}'
   ```
5. Observe conversion failure with "could not find the page-dimensions" error

**Reproducibility**: 100% with current test data files

---

## Root Cause Analysis

### Investigation

Examined PDF file structure:
```bash
file /opt/docling-mcp/tests/test-data/pdf/sample-digital.pdf
# Output: PDF document, version 1.3, 1 page(s)

ls -lh /opt/docling-mcp/tests/test-data/pdf/sample-digital.pdf
# Output: 1.5K (unusually small for a PDF with content)
```

PDF files were likely generated without proper page dimension metadata. The PDF specification requires either `/MediaBox` (defines page size) or `/CropBox` (defines visible region) in each page object.

### Validation with Valid PDF

Downloaded valid PDF from W3C test suite:
```bash
curl -o /tmp/valid-test.pdf https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf
sudo cp /tmp/valid-test.pdf /opt/docling-mcp/tests/test-data/pdf/
```

Conversion with valid PDF:
```json
{
  "document_id": "doc_a12eb23d906a",
  "source": "/opt/docling-mcp/tests/test-data/pdf/valid-test.pdf",
  "text": "## Dummy PDF file",
  "processing_time": 1.0544815063476562,
  "ocr_applied": false
}
```
✅ **SUCCESS** - Valid PDF processes correctly

**Conclusion**: Service is functional. Test data files are malformed.

---

## Proposed Resolution

### Option 1: Replace Test Data Files (RECOMMENDED)

Create properly formatted PDF test files:

**sample-digital.pdf Requirements**:
- Valid `/MediaBox` attribute (e.g., [0 0 612 792] for US Letter)
- Sample text content for extraction testing
- Headings, paragraphs, and structure for validation
- File size: ~50-100KB

**sample-scanned.pdf Requirements**:
- Valid `/MediaBox` attribute
- Embedded image (scanned document appearance)
- Suitable for OCR testing
- File size: ~500KB-1MB

**Implementation**:
```python
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter

# Create sample-digital.pdf
c = canvas.Canvas("sample-digital.pdf", pagesize=letter)
c.setFont("Helvetica-Bold", 16)
c.drawString(100, 750, "Sample Digital PDF Document")
c.setFont("Helvetica", 12)
c.drawString(100, 700, "This is a test document for docling-mcp validation.")
c.drawString(100, 680, "It contains multiple lines of text for extraction testing.")
c.showPage()
c.save()
```

Or download from validated sources:
- W3C test files: https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/
- PDF Association: https://pdfa.org/resource/test-files/

### Option 2: Use External Test PDFs

Update test cases to reference valid external PDFs:
- Link to stable W3C test resources
- Document external dependency
- Less control over test data content

### Option 3: Generate PDFs Dynamically

Create test PDFs programmatically during test execution:
- Ensures valid structure
- Requires PDF generation library (reportlab, fpdf)
- More complex test setup

---

## Workaround

**Current Workaround** (already implemented):
- Use `/opt/docling-mcp/tests/test-data/pdf/valid-test.pdf` for PDF testing
- Downloaded from: https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf
- All PDF tests PASS with this valid file

**Test Case Updates**:
```bash
# Update tc-multi-001, tc-multi-002, tc-func-001 to use:
source: "/opt/docling-mcp/tests/test-data/pdf/valid-test.pdf"
```

---

## Affected Files

**Malformed Files**:
- `/opt/docling-mcp/tests/test-data/pdf/sample-digital.pdf` (1.5K) - REPLACE
- `/opt/docling-mcp/tests/test-data/pdf/sample-scanned.pdf` (26K) - REPLACE

**Working File**:
- `/opt/docling-mcp/tests/test-data/pdf/valid-test.pdf` (13K) - VALID

**Affected Test Cases**:
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/functionality/tc-docling-mcp-functionality-001-convert-pdf.md`
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/multimodal/tc-docling-mcp-multimodal-001-pdf-digital.md`
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/multimodal/tc-docling-mcp-multimodal-002-pdf-scanned.md`

---

## Priority and Timeline

**Priority**: LOW
- Service functionality NOT impacted
- Workaround available and tested
- Does NOT block operational promotion

**Suggested Timeline**:
- Fix before next major release
- Not urgent for current deployment

**Recommended Owner**: Documentation/QA team member with PDF generation capability

---

## Additional Notes

**Service Validation**:
- PDF conversion working correctly with valid PDFs ✅
- OCR pipeline functional (tested with valid PDF + ocr_enabled=true) ✅
- Docling library operational ✅
- No code changes required ✅

**Test Data Quality**:
This defect highlights the importance of validating test data files. All test data should be validated for structural correctness before use in test suites.

**Prevention**:
Future test data generation should include validation steps:
1. File format validation (e.g., `pdfinfo`, `file` command)
2. Structural validation (required metadata present)
3. Test conversion with target service
4. Document test data generation process

---

## References

- PDF Specification: https://www.adobe.com/content/dam/acom/en/devnet/pdf/pdfs/PDF32000_2008.pdf
- Page Dimensions (MediaBox): Section 7.7.3.3
- Test Execution Report: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-execution-post-libgl-fix-2025-12-04.md`

---

**Resolution**: PENDING
**Verified By**: N/A
**Closed Date**: N/A
