# Test Plan: Docling MCP Server

**Service**: docling-mcp
**Created**: 2025-11-27
**Status**: Phase 1 Complete - Ready for Test Creation
**Based on Spec**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (7,801 lines, APPROVED)
**Based on Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md` (APPROVED)
**Based on Architecture**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/deployment-architecture.md` (COMPLETE)
**Based on Configuration**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/configuration-spec.md` (COMPLETE)
**Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md` (APPROVED 2025-11-25)

---

## Test Plan Overview

### Purpose

This comprehensive test plan ensures the Docling MCP Server deployment meets all requirements from the approved charter and specification through rigorous, automated testing with 100% coverage mandate. Testing validates multimodal document processing capabilities, MCP protocol compliance, knowledge graph generation, and infrastructure integration - all following HX-Infrastructure test-driven deployment standards.

### Scope

**In Scope:**
- **Deployment Validation**: Service installation, configuration, dependencies, systemd service, directory structure, file permissions
- **Functionality Testing**: All 19 MCP tools (3 conversion, 11 generation, 5 manipulation), DoclingDocument format validation, multimodal processing
- **Integration Testing**: LiteLLM Gateway, Qdrant vector database, Redis cache, LightRAG knowledge graph engine, MCP protocol transports
- **Health Check Testing**: Endpoint validation, resource monitoring, dependency health, stability verification
- **Multimodal Validation**: PDF (digital 99%+, scanned 85%+), DOCX, PPTX, XLSX, image processing with format-specific accuracy thresholds
- **Quality Gate Enforcement**: Automated validation commands, coverage measurement, evidence capture, STOP on failure
- **Rollback Testing**: Mandatory rollback procedure validation before operational promotion
- **Defect Management Integration**: Test failure triggers, severity assessment, resolution validation

**Out of Scope:**
- Stages 3-5 (embedding, indexing, retrieval) - Deferred to Phase 2
- N8N workflow integration - Deferred to Phase 2
- Advanced monitoring/observability - Deferred until hx-metric-server operational
- Authentication/authorization - Deferred to Phase 2
- Performance testing beyond baseline validation - Deferred to Phase 2

### Test Objectives

1. **Validate 100% Deployment Compliance**: Verify deployment matches architecture and configuration specifications
2. **Verify 100% Functional Requirements Coverage**: Test all 19 MCP tools with multimodal validation
3. **Confirm Integration Point Functionality**: Validate LiteLLM, Qdrant, Redis, LightRAG integrations
4. **Ensure Operational Readiness**: Health checks passing, resource limits respected, stability confirmed
5. **Enforce Quality Gates**: Automated validation with ≥95% coverage, 100% test pass rate mandatory
6. **Validate Rollback Capability**: Ensure safe rollback before operational promotion
7. **Enable Defect Tracking**: Systematic failure analysis with severity-based escalation

---

## Test Strategy

### Test-Driven Deployment Approach

**MANDATORY WORKFLOW** (per HX-Infrastructure testing-requirements.md):

```
1. Write test-plan.md (THIS DOCUMENT) ✅
   ↓
2. Write ALL test cases (Tasks 020-027 in plan.md)
   ↓
3. Run tests - MUST FAIL (service not deployed yet)
   ↓
4. Execute deployment (Tasks 001-019 in plan.md)
   ↓
5. Run tests - MUST PASS (100% pass rate required)
   ↓
6. Quality gate validation - Automated enforcement
   ↓
7. Rollback test validation - Mandatory before promotion
   ↓
8. Defect resolution - IF any failures
   ↓
9. Re-test - Verify fixes
   ↓
10. Promotion criteria met → Move to operational
```

**No Shortcuts Allowed:**
- ❌ Cannot deploy without tests written first
- ❌ Cannot skip test creation phases
- ❌ Cannot promote with failing tests
- ❌ Cannot skip quality gate validation
- ❌ Cannot skip rollback testing

### Test Coverage Mandate: 100%

**Coverage Requirements** (NON-NEGOTIABLE):
- **Line Coverage**: ≥95% (pytest-cov enforced)
- **Branch Coverage**: ≥90% (pytest-cov enforced)
- **Requirements Coverage**: 100% (every FR, SC, integration point tested)
- **MCP Tools Coverage**: 100% (all 19 tools tested)
- **Multimodal Format Coverage**: 100% (PDF, DOCX, PPTX, XLSX, images)
- **Integration Point Coverage**: 100% (LiteLLM, Qdrant, Redis, LightRAG)

**Coverage Enforcement** (automated via quality gates):
```bash
# Coverage validation command (MUST pass before promotion)
pytest tests/ --cov=docling_mcp --cov-report=html --cov-report=xml \
  --cov-report=term --cov-fail-under=95 --junitxml=test-results.xml

# Quality gate enforcement
coverage report --fail-under=95 || { echo "FAIL: Coverage < 95%"; exit 1; }
```

**IF coverage < 95% THEN:**
1. STOP deployment
2. Create defect: `defect-docling-mcp-critical-001-insufficient-coverage.md`
3. Add missing tests
4. Re-run coverage validation
5. Proceed ONLY when coverage ≥95%

---

## Quality Gap Resolution (6 Gaps from Julia Santos Quality Review)

This test plan addresses ALL 6 quality gaps identified in the approved plan.md (lines 629-638):

### Gap 2: Test Coverage Methodology ✅ RESOLVED

**pytest.ini Configuration** (complete file with coverage settings):
```ini
# /opt/docling-mcp/pytest.ini
# Pytest Configuration for Docling MCP Server

[pytest]
minversion = 7.4
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Coverage settings
addopts =
    --verbose
    --strict-markers
    --tb=short
    --cov=docling_mcp
    --cov-report=html:htmlcov
    --cov-report=xml:coverage.xml
    --cov-report=term-missing
    --cov-fail-under=95
    --cov-branch
    --junitxml=test-results.xml
    --maxfail=5

# Markers for test categorization
markers =
    deployment: Deployment validation tests
    functionality: Functionality tests
    integration: Integration tests
    health: Health check tests
    multimodal: Multimodal document tests
    slow: Slow-running tests
    requires_litellm: Tests requiring LiteLLM Gateway
    requires_qdrant: Tests requiring Qdrant
    requires_redis: Tests requiring Redis

# Coverage configuration
[coverage:run]
branch = True
source = docling_mcp
omit =
    */tests/*
    */venv/*
    */__pycache__/*

[coverage:report]
precision = 2
show_missing = True
skip_covered = False
fail_under = 95.0

[coverage:html]
directory = htmlcov
```

**pyproject.toml Configuration** (tool.pytest section):
```toml
# /opt/docling-mcp/pyproject.toml

[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "docling-mcp"
version = "1.0.0"
description = "Docling MCP Server - Document Processing Gateway"
requires-python = ">=3.11"

[tool.pytest.ini_options]
minversion = "7.4"
testpaths = ["tests"]
pythonpath = ["application"]

# Coverage thresholds (NON-NEGOTIABLE)
[tool.coverage.run]
branch = true
source = ["docling_mcp"]
omit = ["*/tests/*", "*/venv/*"]

[tool.coverage.report]
precision = 2
fail_under = 95.0
show_missing = true

# Line coverage: ≥95%
# Branch coverage: ≥90%
```

**Fixture Strategy** (conftest.py patterns):
```python
# tests/conftest.py
# Centralized test fixtures for Docling MCP Server

import pytest
import asyncio
from typing import Dict, Any
from unittest.mock import Mock, AsyncMock

# ============================================================================
# Session-scoped fixtures (shared across all tests)
# ============================================================================

@pytest.fixture(scope="session")
def event_loop():
    """Event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
def test_config() -> Dict[str, Any]:
    """Test configuration."""
    return {
        "litellm_base_url": "http://192.168.10.212:4000",
        "qdrant_host": "192.168.10.207",
        "qdrant_port": 6333,
        "redis_host": "192.168.10.210",
        "redis_port": 6379,
        "service_host": "192.168.10.217",
        "service_port": 8000,
    }

# ============================================================================
# Function-scoped fixtures (fresh for each test)
# ============================================================================

@pytest.fixture
def mock_litellm_client():
    """Mock LiteLLM client."""
    client = Mock()
    client.call_llm = AsyncMock(return_value="Mocked LLM response")
    client.health_check = AsyncMock(return_value=True)
    return client

@pytest.fixture
def mock_qdrant_client():
    """Mock Qdrant client."""
    client = Mock()
    client.upsert = AsyncMock(return_value={"status": "ok"})
    client.search = AsyncMock(return_value=[])
    client.health_check = AsyncMock(return_value=True)
    return client

@pytest.fixture
def mock_redis_client():
    """Mock Redis client."""
    client = Mock()
    client.get = AsyncMock(return_value=None)
    client.set = AsyncMock(return_value=True)
    client.ping = AsyncMock(return_value=True)
    return client

@pytest.fixture
def sample_pdf_path(tmp_path):
    """Sample PDF file for testing."""
    pdf_path = tmp_path / "sample.pdf"
    # Create minimal valid PDF
    pdf_content = b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n%%EOF"
    pdf_path.write_bytes(pdf_content)
    return str(pdf_path)

@pytest.fixture
def sample_docx_path(tmp_path):
    """Sample DOCX file for testing."""
    # Create minimal valid DOCX (in reality, would use python-docx)
    docx_path = tmp_path / "sample.docx"
    # Minimal DOCX structure
    docx_path.write_text("Sample DOCX content")
    return str(docx_path)

@pytest.fixture
def mcp_server():
    """MCP server instance for testing."""
    from docling_mcp.server import create_server
    server = create_server(test_mode=True)
    yield server
    server.shutdown()
```

**Parametrization Approach** (pytest.mark.parametrize for multimodal testing):
```python
# Example: Parametrized multimodal test
import pytest

@pytest.mark.multimodal
@pytest.mark.parametrize("document_format,expected_accuracy", [
    ("pdf_digital", 0.99),      # Digital PDF: 99%+ accuracy
    ("pdf_scanned", 0.85),      # Scanned PDF: 85%+ OCR accuracy
    ("docx", 0.99),             # DOCX: 99%+ accuracy
    ("pptx", 0.95),             # PPTX: 95%+ accuracy
    ("xlsx", 0.99),             # XLSX: 99%+ accuracy
    ("png_ocr", 0.90),          # PNG with OCR: 90%+ accuracy
    ("jpg_ocr", 0.90),          # JPG with OCR: 90%+ accuracy
])
def test_document_conversion_accuracy(document_format, expected_accuracy, sample_documents):
    """Test document conversion accuracy for all formats."""
    # Implementation validates format-specific accuracy thresholds
    pass
```

**Coverage Reporting** (HTML, XML, terminal output):
```bash
# HTML coverage report (htmlcov/index.html)
coverage html

# XML coverage report (coverage.xml for CI/CD)
coverage xml

# Terminal coverage report (with missing lines)
coverage report --show-missing

# Quality gate: Fail if coverage < 95%
coverage report --fail-under=95 || exit 1
```

**Coverage Enforcement** (CI/CD integration, quality gate criteria):
```yaml
# CI/CD pipeline integration (reference - manual deployment for Phase 1)
# Future: GitHub Actions / GitLab CI integration

quality_gate:
  coverage_validation:
    - run: pytest tests/ --cov=docling_mcp --cov-fail-under=95
    - run: coverage report --fail-under=95
    - condition: MUST PASS before deployment
    - on_failure: STOP deployment, create defect ticket
```

**Gap 2 Resolution Summary**:
- ✅ Complete pytest.ini with coverage settings (≥95% threshold)
- ✅ pyproject.toml tool.pytest section configured
- ✅ Fixture strategy documented (session/function scoped)
- ✅ Parametrization approach for multimodal testing
- ✅ Coverage reporting (HTML, XML, terminal)
- ✅ Coverage enforcement automated (quality gate)

---

### Gap 3: Multimodal Validation Criteria ✅ RESOLVED

**Format-Specific Accuracy Thresholds**:

| Document Format | Accuracy Threshold | Structure Preservation | Error Handling |
|----------------|-------------------|----------------------|----------------|
| **PDF (Digital)** | 99%+ text extraction | Heading hierarchy, tables, lists | Invalid PDF: clear error message |
| **PDF (Scanned)** | 85%+ OCR accuracy | Layout detection, OCR quality | OCR failure: fallback to layout only |
| **DOCX** | 99%+ text extraction | Heading hierarchy, style preservation | Corrupted DOCX: graceful degradation |
| **PPTX** | 95%+ slide structure | Slide structure, text box extraction | Missing slides: partial processing |
| **XLSX** | 99%+ cell extraction | Cell data, formula preservation | Invalid formulas: data only extraction |
| **PNG/JPG (OCR)** | 90%+ OCR accuracy | Image metadata, OCR text | OCR failure: metadata only extraction |

**Structure Preservation Requirements**:

**1. PDF Processing** (Digital PDF):
```python
# Validation criteria for PDF processing
def validate_pdf_processing(docling_doc, source_pdf):
    """
    Validate PDF processing quality.

    Criteria:
    - Text extraction accuracy: ≥99%
    - Heading hierarchy preserved (H1, H2, H3)
    - Tables extracted with structure
    - Lists maintained (ordered/unordered)
    - Images extracted with captions
    """
    # Text extraction accuracy
    extracted_text = docling_doc.get_text()
    source_text = extract_pdf_text(source_pdf)
    accuracy = calculate_similarity(extracted_text, source_text)
    assert accuracy >= 0.99, f"PDF text accuracy {accuracy} < 99%"

    # Heading hierarchy
    headings = docling_doc.get_headings()
    assert len(headings) > 0, "No headings extracted"
    assert all(h.level in [1, 2, 3] for h in headings), "Invalid heading levels"

    # Tables
    tables = docling_doc.get_tables()
    assert len(tables) == count_pdf_tables(source_pdf), "Table count mismatch"

    # Lists
    lists = docling_doc.get_lists()
    assert len(lists) > 0, "No lists extracted"
```

**2. PDF Processing** (Scanned PDF with OCR):
```python
# Validation criteria for scanned PDF with OCR
def validate_scanned_pdf_processing(docling_doc, source_pdf):
    """
    Validate scanned PDF OCR processing.

    Criteria:
    - OCR accuracy: ≥85% (Tesseract)
    - Layout detection successful
    - Image regions identified
    - Text regions extracted
    """
    # OCR accuracy (ground truth comparison)
    extracted_text = docling_doc.get_text()
    ground_truth = load_ground_truth(source_pdf)
    accuracy = calculate_ocr_accuracy(extracted_text, ground_truth)
    assert accuracy >= 0.85, f"OCR accuracy {accuracy} < 85%"

    # Layout detection
    layout = docling_doc.get_layout()
    assert layout.text_regions > 0, "No text regions detected"
    assert layout.image_regions >= 0, "Layout detection failed"
```

**3. DOCX Processing**:
```python
# Validation criteria for DOCX processing
def validate_docx_processing(docling_doc, source_docx):
    """
    Validate DOCX processing quality.

    Criteria:
    - Text extraction accuracy: ≥99%
    - Style preservation (bold, italic, underline)
    - Heading hierarchy preserved
    - Tables extracted with formatting
    """
    # Text extraction accuracy
    extracted_text = docling_doc.get_text()
    source_text = extract_docx_text(source_docx)
    accuracy = calculate_similarity(extracted_text, source_text)
    assert accuracy >= 0.99, f"DOCX text accuracy {accuracy} < 99%"

    # Style preservation
    styles = docling_doc.get_styles()
    assert "bold" in styles, "Bold style not preserved"
    assert "italic" in styles, "Italic style not preserved"
```

**4. PPTX Processing**:
```python
# Validation criteria for PPTX processing
def validate_pptx_processing(docling_doc, source_pptx):
    """
    Validate PPTX processing quality.

    Criteria:
    - Slide structure preserved: ≥95%
    - Text box extraction accurate
    - Charts/images identified
    """
    # Slide structure
    slides = docling_doc.get_slides()
    source_slides = count_pptx_slides(source_pptx)
    structure_accuracy = len(slides) / source_slides
    assert structure_accuracy >= 0.95, f"Slide structure {structure_accuracy} < 95%"

    # Text box extraction
    for slide in slides:
        assert len(slide.text_boxes) > 0, f"Slide {slide.number} missing text boxes"
```

**5. XLSX Processing**:
```python
# Validation criteria for XLSX processing
def validate_xlsx_processing(docling_doc, source_xlsx):
    """
    Validate XLSX processing quality.

    Criteria:
    - Cell data extraction: ≥99%
    - Formula preservation
    - Sheet structure maintained
    """
    # Cell data accuracy
    extracted_data = docling_doc.get_cell_data()
    source_data = extract_xlsx_data(source_xlsx)
    accuracy = calculate_data_accuracy(extracted_data, source_data)
    assert accuracy >= 0.99, f"XLSX data accuracy {accuracy} < 99%"

    # Formula preservation
    formulas = docling_doc.get_formulas()
    assert len(formulas) > 0, "Formulas not preserved"
```

**6. Image Processing** (PNG/JPG with OCR):
```python
# Validation criteria for image OCR
def validate_image_ocr_processing(docling_doc, source_image):
    """
    Validate image OCR processing.

    Criteria:
    - OCR accuracy: ≥90%
    - Image metadata extracted
    - Text regions identified
    """
    # OCR accuracy
    extracted_text = docling_doc.get_text()
    ground_truth = load_image_ground_truth(source_image)
    accuracy = calculate_ocr_accuracy(extracted_text, ground_truth)
    assert accuracy >= 0.90, f"Image OCR accuracy {accuracy} < 90%"

    # Metadata extraction
    metadata = docling_doc.get_metadata()
    assert metadata.width > 0, "Image width not extracted"
    assert metadata.height > 0, "Image height not extracted"
```

**Error Handling Expectations**:

```python
# Error handling validation
def test_error_handling_invalid_pdf():
    """Test error handling for invalid PDF."""
    with pytest.raises(InvalidPDFError) as exc:
        convert_pdf("corrupted.pdf")

    # Error message must be clear and actionable
    assert "Invalid PDF" in str(exc.value)
    assert "corrupted" in str(exc.value).lower()

def test_error_handling_ocr_failure():
    """Test OCR failure graceful degradation."""
    result = convert_pdf("scanned_unreadable.pdf")

    # Should fallback to layout-only extraction
    assert result.layout is not None, "Layout not extracted"
    assert result.ocr_status == "failed", "OCR status not set"
    assert result.text == "", "OCR text should be empty"
```

**Test Data Sets** (sample documents for each format):

**Test Data Location**: `/opt/docling-mcp/tests/test-data/`

```
tests/test-data/
├── pdf/
│   ├── digital_10page.pdf          # Technical documentation (10 pages)
│   ├── scanned_5page.pdf           # Scanned research paper (5 pages)
│   └── forms_2page.pdf             # Forms with tables (2 pages)
├── docx/
│   ├── business_doc_tables.docx    # Business document with tables
│   └── styled_headings.docx        # Document with heading hierarchy
├── pptx/
│   └── presentation_charts.pptx    # Presentation with charts
├── xlsx/
│   └── spreadsheet_formulas.xlsx   # Spreadsheet with formulas
└── images/
    ├── invoice.png                 # Invoice image (OCR test)
    └── receipt.jpg                 # Receipt image (OCR test)
```

**Validation Methods** (diff comparison, structure verification, manual inspection):

**1. Diff Comparison** (automated text similarity):
```python
from difflib import SequenceMatcher

def calculate_similarity(text1: str, text2: str) -> float:
    """Calculate text similarity ratio (0.0-1.0)."""
    return SequenceMatcher(None, text1, text2).ratio()

def validate_text_extraction(extracted: str, expected: str, threshold: float = 0.99):
    """Validate text extraction meets threshold."""
    similarity = calculate_similarity(extracted, expected)
    assert similarity >= threshold, f"Similarity {similarity} < {threshold}"
```

**2. Structure Verification** (automated structure validation):
```python
def validate_document_structure(docling_doc, expected_structure):
    """Validate document structure matches expectations."""
    # Heading hierarchy
    assert docling_doc.headings == expected_structure.headings

    # Tables
    assert len(docling_doc.tables) == len(expected_structure.tables)

    # Lists
    assert len(docling_doc.lists) == len(expected_structure.lists)
```

**3. Manual Inspection** (for complex cases):
```python
def generate_inspection_report(docling_doc, output_path):
    """Generate HTML report for manual inspection."""
    html_content = f"""
    <html>
    <head><title>Document Processing Report</title></head>
    <body>
        <h1>Document Processing Report</h1>
        <h2>Text Extraction</h2>
        <pre>{docling_doc.get_text()}</pre>

        <h2>Structure</h2>
        <ul>
            <li>Headings: {len(docling_doc.headings)}</li>
            <li>Tables: {len(docling_doc.tables)}</li>
            <li>Lists: {len(docling_doc.lists)}</li>
        </ul>

        <h2>Images</h2>
        {render_images(docling_doc.images)}
    </body>
    </html>
    """

    with open(output_path, "w") as f:
        f.write(html_content)
```

**Gap 3 Resolution Summary**:
- ✅ Format-specific accuracy thresholds defined (PDF 99%/85%, DOCX 99%, PPTX 95%, XLSX 99%, images 90%)
- ✅ Structure preservation requirements documented
- ✅ Error handling expectations specified
- ✅ Test data sets identified (sample documents per format)
- ✅ Validation methods documented (diff, structure, manual)

---

### Gap 4: Quality Gate Validation Commands ✅ RESOLVED

**Concrete pytest Execution Commands** (with JUnit XML output):

```bash
# ============================================================================
# PRIMARY QUALITY GATE COMMAND (ALL TESTS)
# ============================================================================

# Run complete test suite with coverage and JUnit XML output
pytest tests/ \
  --cov=docling_mcp \
  --cov-report=html:htmlcov \
  --cov-report=xml:coverage.xml \
  --cov-report=term-missing \
  --cov-fail-under=95 \
  --cov-branch \
  --junitxml=test-results.xml \
  --verbose \
  --tb=short \
  --maxfail=5

# Expected output:
# - JUnit XML: test-results.xml (for CI/CD integration)
# - HTML coverage: htmlcov/index.html (for manual review)
# - XML coverage: coverage.xml (for automated tools)
# - Terminal output: Pass/fail summary with missing lines
# - Exit code: 0 (success), 1 (failure)

# ============================================================================
# QUALITY GATE: IF ANY TEST FAILS → STOP DEPLOYMENT
# ============================================================================
```

**Coverage Measurement Commands**:

```bash
# 1. Generate coverage report (detailed)
coverage report --show-missing --precision=2

# Expected output:
# Name                                 Stmts   Miss Branch BrPart  Cover   Missing
# --------------------------------------------------------------------------------
# docling_mcp/__init__.py                 12      0      0      0   100%
# docling_mcp/server.py                  245      5     42      3    97.2%   123-125, 234
# docling_mcp/tools/conversion.py        178      3     28      2    98.1%   45, 89
# ...
# --------------------------------------------------------------------------------
# TOTAL                                 1250     12    180      8    97.8%

# 2. Enforce coverage threshold (≥95%)
coverage report --fail-under=95

# Expected output:
# - IF coverage ≥ 95%: Exit code 0 (success)
# - IF coverage < 95%: Exit code 2 (failure) + error message

# Example failure output:
# Coverage failure: total of 94.5 is less than fail-under=95.0
# EXIT CODE: 2

# 3. Generate HTML coverage report (for manual review)
coverage html --directory=htmlcov

# Expected output:
# - HTML files in htmlcov/ directory
# - Open htmlcov/index.html in browser for visual coverage report

# 4. Generate XML coverage report (for CI/CD tools)
coverage xml --output=coverage.xml

# Expected output:
# - coverage.xml file in Cobertura XML format
# - Parseable by CI/CD systems (Jenkins, GitLab, GitHub Actions)
```

**Evidence Capture Mechanisms** (logs, reports, timestamps):

**1. JUnit XML Test Results** (test-results.xml):
```xml
<!-- Example JUnit XML output -->
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="pytest" errors="0" failures="0" skipped="0" tests="52" time="45.231" timestamp="2025-11-27T10:30:00">
    <testcase classname="tests.test_deployment.TestDeployment" name="test_service_installed" time="0.123">
      <!-- PASS: No error/failure tags -->
    </testcase>
    <testcase classname="tests.test_functionality.TestConversion" name="test_convert_pdf" time="2.456">
      <!-- PASS: No error/failure tags -->
    </testcase>
    <!-- ... additional test cases ... -->
  </testsuite>
</testsuites>
```

**Capture command**:
```bash
# JUnit XML always generated with --junitxml flag
pytest tests/ --junitxml=test-results.xml

# Parse test results programmatically
python -c "
import xml.etree.ElementTree as ET
tree = ET.parse('test-results.xml')
root = tree.getroot()
suite = root.find('testsuite')
print(f\"Tests: {suite.get('tests')}\")
print(f\"Failures: {suite.get('failures')}\")
print(f\"Errors: {suite.get('errors')}\")
print(f\"Time: {suite.get('time')} seconds\")
"
```

**2. Coverage XML Report** (coverage.xml):
```xml
<!-- Example Cobertura XML output -->
<?xml version="1.0" ?>
<coverage version="7.3.2" timestamp="1701091800000" lines-valid="1250" lines-covered="1222" line-rate="0.978" branches-valid="180" branches-covered="172" branch-rate="0.956" complexity="0">
  <packages>
    <package name="docling_mcp" line-rate="0.978" branch-rate="0.956" complexity="0">
      <classes>
        <class name="server.py" filename="docling_mcp/server.py" line-rate="0.972" branch-rate="0.952" complexity="0">
          <lines>
            <line number="1" hits="1"/>
            <line number="2" hits="1"/>
            <!-- ... additional lines ... -->
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
```

**Capture command**:
```bash
# Coverage XML generated with --cov-report=xml
pytest tests/ --cov=docling_mcp --cov-report=xml

# Validate coverage threshold programmatically
python -c "
import xml.etree.ElementTree as ET
tree = ET.parse('coverage.xml')
root = tree.getroot()
line_rate = float(root.get('line-rate'))
branch_rate = float(root.get('branch-rate'))
print(f\"Line coverage: {line_rate * 100:.2f}%\")
print(f\"Branch coverage: {branch_rate * 100:.2f}%\")
if line_rate < 0.95:
    print(\"FAIL: Line coverage < 95%\")
    exit(1)
"
```

**3. HTML Coverage Report** (htmlcov/index.html):
```bash
# Generate HTML report for manual inspection
coverage html --directory=htmlcov

# Open in browser (manual step)
# Expected: Visual report showing:
# - Overall coverage percentage
# - Per-file coverage breakdown
# - Missing lines highlighted in red
# - Partially covered branches in yellow
```

**4. Test Execution Logs** (with timestamps):
```bash
# Capture test execution with timestamps
pytest tests/ --verbose --tb=short 2>&1 | tee test-execution.log

# Add timestamp prefix to each line
pytest tests/ --verbose --tb=short 2>&1 | \
  while IFS= read -r line; do echo "$(date +'%Y-%m-%d %H:%M:%S') $line"; done | \
  tee test-execution-timestamped.log

# Example log output:
# 2025-11-27 10:30:00 ============================= test session starts ==============================
# 2025-11-27 10:30:01 tests/test_deployment/test_installation.py::test_service_installed PASSED
# 2025-11-27 10:30:02 tests/test_deployment/test_configuration.py::test_config_created PASSED
# ...
# 2025-11-27 10:45:31 ============================== 52 passed in 45.31s ==============================
```

**Quality Gate Enforcement** (STOP on failure, defect logging triggers):

**Automated Quality Gate Script** (`tests/quality-gate.sh`):

```bash
#!/bin/bash
# Quality Gate Validation Script
# Location: /opt/docling-mcp/tests/quality-gate.sh
# Description: Automated quality gate enforcement with STOP on failure

set -e  # Exit on any error

echo "========================================"
echo "QUALITY GATE VALIDATION"
echo "========================================"
echo "Timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
echo ""

# ============================================================================
# GATE 1: Test Execution
# ============================================================================
echo "[GATE 1] Running test suite..."
pytest tests/ \
  --cov=docling_mcp \
  --cov-report=html:htmlcov \
  --cov-report=xml:coverage.xml \
  --cov-report=term-missing \
  --cov-fail-under=95 \
  --cov-branch \
  --junitxml=test-results.xml \
  --verbose \
  --tb=short \
  --maxfail=5 \
  2>&1 | tee test-execution.log

TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo ""
  echo "❌ GATE 1 FAILED: Test execution failed"
  echo "Exit code: $TEST_EXIT_CODE"
  echo ""
  echo "ACTION REQUIRED:"
  echo "1. Review test-execution.log for failure details"
  echo "2. Create defect ticket: defect-docling-mcp-high-001-test-failure.md"
  echo "3. Fix failing tests"
  echo "4. Re-run quality gate validation"
  echo ""
  echo "DEPLOYMENT STOPPED"
  exit 1
fi

echo "✅ GATE 1 PASSED: All tests passing"
echo ""

# ============================================================================
# GATE 2: Coverage Validation
# ============================================================================
echo "[GATE 2] Validating coverage threshold (≥95%)..."
coverage report --fail-under=95 2>&1 | tee coverage-validation.log

COVERAGE_EXIT_CODE=$?

if [ $COVERAGE_EXIT_CODE -ne 0 ]; then
  echo ""
  echo "❌ GATE 2 FAILED: Coverage < 95%"
  echo "Exit code: $COVERAGE_EXIT_CODE"
  echo ""
  echo "ACTION REQUIRED:"
  echo "1. Review htmlcov/index.html for missing coverage"
  echo "2. Create defect ticket: defect-docling-mcp-critical-001-insufficient-coverage.md"
  echo "3. Add tests for uncovered code"
  echo "4. Re-run quality gate validation"
  echo ""
  echo "DEPLOYMENT STOPPED"
  exit 1
fi

echo "✅ GATE 2 PASSED: Coverage ≥95%"
echo ""

# ============================================================================
# GATE 3: Integration Test Validation
# ============================================================================
echo "[GATE 3] Validating integration tests..."
pytest tests/test-suite/integration/ --verbose --tb=short 2>&1 | tee integration-test.log

INTEGRATION_EXIT_CODE=$?

if [ $INTEGRATION_EXIT_CODE -ne 0 ]; then
  echo ""
  echo "❌ GATE 3 FAILED: Integration tests failed"
  echo "Exit code: $INTEGRATION_EXIT_CODE"
  echo ""
  echo "ACTION REQUIRED:"
  echo "1. Review integration-test.log for failure details"
  echo "2. Create defect ticket: defect-docling-mcp-high-002-integration-failure.md"
  echo "3. Investigate dependency connectivity (LiteLLM, Qdrant, Redis)"
  echo "4. Fix integration issues"
  echo "5. Re-run quality gate validation"
  echo ""
  echo "DEPLOYMENT STOPPED"
  exit 1
fi

echo "✅ GATE 3 PASSED: All integration tests passing"
echo ""

# ============================================================================
# GATE 4: Health Check Validation
# ============================================================================
echo "[GATE 4] Validating health checks..."
pytest tests/test-suite/health-check/ --verbose --tb=short 2>&1 | tee health-check-test.log

HEALTH_EXIT_CODE=$?

if [ $HEALTH_EXIT_CODE -ne 0 ]; then
  echo ""
  echo "❌ GATE 4 FAILED: Health check tests failed"
  echo "Exit code: $HEALTH_EXIT_CODE"
  echo ""
  echo "ACTION REQUIRED:"
  echo "1. Review health-check-test.log for failure details"
  echo "2. Create defect ticket: defect-docling-mcp-critical-002-health-check-failure.md"
  echo "3. Investigate service health issues"
  echo "4. Fix health check failures"
  echo "5. Re-run quality gate validation"
  echo ""
  echo "DEPLOYMENT STOPPED"
  exit 1
fi

echo "✅ GATE 4 PASSED: All health checks passing"
echo ""

# ============================================================================
# SUCCESS: All Quality Gates Passed
# ============================================================================
echo "========================================"
echo "✅ ALL QUALITY GATES PASSED"
echo "========================================"
echo "Timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
echo ""
echo "Evidence:"
echo "- Test results: test-results.xml"
echo "- Coverage HTML: htmlcov/index.html"
echo "- Coverage XML: coverage.xml"
echo "- Test execution log: test-execution.log"
echo "- Coverage validation log: coverage-validation.log"
echo "- Integration test log: integration-test.log"
echo "- Health check log: health-check-test.log"
echo ""
echo "DEPLOYMENT APPROVED: Proceed to next phase"
exit 0
```

**Quality Gate Usage**:
```bash
# Make script executable
chmod +x /opt/docling-mcp/tests/quality-gate.sh

# Run quality gate validation
/opt/docling-mcp/tests/quality-gate.sh

# Expected output on SUCCESS:
# ========================================
# ✅ ALL QUALITY GATES PASSED
# ========================================
# EXIT CODE: 0

# Expected output on FAILURE:
# ❌ GATE X FAILED: <failure reason>
# ACTION REQUIRED: <remediation steps>
# DEPLOYMENT STOPPED
# EXIT CODE: 1
```

**IF Quality Gate Fails**:

**STOP Deployment Immediately**:
1. **DO NOT proceed** to next deployment phase
2. **DO NOT promote** service to operational
3. **DO NOT bypass** quality gate

**Create Defect Ticket**:
```bash
# Automated defect creation on quality gate failure
cat > /home/agent0/HX-Infrastructure/defects/defect-docling-mcp-<severity>-<seq>-<description>.md <<EOF
# Defect: Docling MCP Server - <Description>

**Defect ID**: defect-docling-mcp-<severity>-<seq>
**Service**: docling-mcp
**Severity**: <CRITICAL|HIGH|MEDIUM|LOW>
**Status**: OPEN
**Discovered**: $(date +'%Y-%m-%d %H:%M:%S')
**Discovered By**: Quality Gate Automation

## Description
Quality gate validation failed during test execution.

## Failure Details
- **Gate**: <Gate Number and Name>
- **Exit Code**: <Exit code>
- **Log File**: <Log file path>

## Reproduction Steps
1. Run quality gate: /opt/docling-mcp/tests/quality-gate.sh
2. Observe failure at Gate <X>
3. Review log file: <log file path>

## Expected Behavior
All quality gates pass with exit code 0.

## Actual Behavior
Gate <X> failed with exit code <Y>.

## Evidence
- Test results: test-results.xml
- Coverage report: htmlcov/index.html
- Execution log: test-execution.log

## Impact
CRITICAL: Blocks deployment to operational status.

## Resolution Required
1. Investigate root cause from log files
2. Fix failing tests or coverage gaps
3. Re-run quality gate validation
4. Verify all gates pass
5. Update defect status to RESOLVED

## Assigned To
<Testing team member>
EOF
```

**Escalation Path**:
```
Quality Gate Failure
    ↓
1. STOP Deployment (automated)
    ↓
2. Create Defect Ticket (automated)
    ↓
3. Notify Testing Lead (julia-santos)
    ↓
4. IF 2+ failures in same area → Escalate to component owner
    ↓
5. IF defect unresolved >3 days → Escalate to project manager (agent-zero)
    ↓
6. Fix defect, re-test
    ↓
7. Re-run quality gate
    ↓
8. IF PASS → Continue deployment
   IF FAIL → Repeat escalation
```

**Gap 4 Resolution Summary**:
- ✅ Concrete pytest execution commands with JUnit XML output
- ✅ Coverage measurement commands (report, HTML, XML)
- ✅ Evidence capture mechanisms (logs, reports, timestamps)
- ✅ Quality gate enforcement (automated script, STOP on failure)
- ✅ Defect logging triggers (automated defect creation)
- ✅ Escalation paths documented

---

### Gap 5: Rollback Testing Validation ✅ RESOLVED

**Mandatory Rollback Test Procedure**:

**Test Case**: `tc-docling-mcp-deployment-014-rollback-validation.md`

**Location**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/test-suite/deployment/tc-docling-mcp-deployment-014-rollback-validation.md`

**Objective**: Validate service can be cleanly rolled back without residual state, then successfully re-deployed with identical test results.

**Prerequisites**:
- Service deployed to non-operational
- All deployment tests passing
- All functionality tests passing
- Baseline test results captured

**Rollback Test Procedure** (deploy → rollback → validate → re-deploy):

**STEP 1: Deploy Service to Non-Operational**
```bash
# Execute deployment tasks 001-019 from plan.md
# Verify deployment successful
sudo systemctl status docling-mcp.service
# Expected: active (running)

# Capture baseline health check
curl -f http://192.168.10.217:8000/health | jq . > baseline-health.json
```

**STEP 2: Execute Full Test Suite (Pre-Rollback)**
```bash
# Run complete test suite, capture results
pytest tests/ --junitxml=pre-rollback-test-results.xml --verbose

# Capture test summary
cp test-results.xml pre-rollback-test-results.xml

# Expected: 100% pass rate
```

**STEP 3: Perform Rollback**
```bash
# 1. Stop service
sudo systemctl stop docling-mcp.service
sudo systemctl disable docling-mcp.service

# Verify service stopped
sudo systemctl is-active docling-mcp.service
# Expected: inactive

# 2. Backup current state (before removal)
sudo mkdir -p /opt/docling-mcp/backups/rollback-$(date +%Y%m%d-%H%M%S)
ROLLBACK_BACKUP="/opt/docling-mcp/backups/rollback-$(date +%Y%m%d-%H%M%S)"

sudo cp -r /etc/docling-mcp $ROLLBACK_BACKUP/etc
sudo cp -r /var/lib/docling-mcp $ROLLBACK_BACKUP/var-lib
sudo cp /etc/systemd/system/docling-mcp.service $ROLLBACK_BACKUP/

# Verify backup created
ls -lh $ROLLBACK_BACKUP

# 3. Remove service configuration
sudo rm /etc/systemd/system/docling-mcp.service
sudo systemctl daemon-reload

# Verify service unit removed
systemctl list-unit-files | grep docling-mcp
# Expected: No results

# 4. Remove application
sudo rm -rf /opt/docling-mcp/venv
sudo rm -rf /opt/docling-mcp/application
# Keep /opt/docling-mcp/backups for investigation

# Verify application removed
test -d /opt/docling-mcp/venv && echo "FAIL: venv still exists" || echo "PASS: venv removed"
test -d /opt/docling-mcp/application && echo "FAIL: application still exists" || echo "PASS: application removed"

# 5. Remove configuration (optional - may keep for investigation)
# sudo rm -rf /etc/docling-mcp
# WARNING: This removes credentials - ensure backed up

# 6. Clean working directories
sudo rm -rf /var/lib/docling-mcp/cache/*
sudo rm -rf /var/lib/docling-mcp/workspace/*
# Keep directories for future deployment

# Verify cleanup
du -sh /var/lib/docling-mcp/cache
du -sh /var/lib/docling-mcp/workspace
# Expected: Empty or minimal size
```

**STEP 4: Validate Clean State (Post-Rollback)**
```bash
# 1. Verify service stopped
sudo systemctl status docling-mcp.service
# Expected: "could not be found"

# 2. Verify application removed
test ! -d /opt/docling-mcp/venv && echo "PASS: Virtual environment removed" || echo "FAIL: venv exists"

# 3. Verify service unit removed
test ! -f /etc/systemd/system/docling-mcp.service && echo "PASS: Service unit removed" || echo "FAIL: unit exists"

# 4. Verify port released
sudo netstat -tulpn | grep :8000
# Expected: No docling-mcp process

# 5. Verify no orphaned processes
pgrep -f docling-mcp
# Expected: No results

# 6. Verify no residual data in cache/workspace
find /var/lib/docling-mcp/cache -type f | wc -l
find /var/lib/docling-mcp/workspace -type f | wc -l
# Expected: 0 files

# VALIDATION CRITERIA: All checks above PASS
```

**STEP 5: Re-Deploy Service**
```bash
# Execute deployment tasks 001-019 again (from plan.md)
# Verify re-deployment successful
sudo systemctl status docling-mcp.service
# Expected: active (running)

# Capture post-rollback health check
curl -f http://192.168.10.217:8000/health | jq . > post-rollback-health.json
```

**STEP 6: Re-Execute Test Suite (Post-Re-Deploy)**
```bash
# Run complete test suite again
pytest tests/ --junitxml=post-rollback-test-results.xml --verbose

# Capture test summary
cp test-results.xml post-rollback-test-results.xml

# Expected: 100% pass rate (identical to pre-rollback)
```

**STEP 7: Validate Identical Results**
```bash
# Compare test results (should be identical)
diff -u pre-rollback-test-results.xml post-rollback-test-results.xml
# Expected: No differences in test outcomes (timestamps will differ)

# Compare health checks (should be identical)
diff -u <(jq -S 'del(.uptime_seconds)' baseline-health.json) \
        <(jq -S 'del(.uptime_seconds)' post-rollback-health.json)
# Expected: No differences (excluding uptime)

# Extract test counts
python -c "
import xml.etree.ElementTree as ET

pre = ET.parse('pre-rollback-test-results.xml').getroot().find('testsuite')
post = ET.parse('post-rollback-test-results.xml').getroot().find('testsuite')

print('Pre-rollback tests:', pre.get('tests'))
print('Pre-rollback failures:', pre.get('failures'))
print('Post-rollback tests:', post.get('tests'))
print('Post-rollback failures:', post.get('failures'))

assert pre.get('tests') == post.get('tests'), 'Test count mismatch'
assert pre.get('failures') == post.get('failures'), 'Failure count mismatch'
print('✅ Test results identical')
"
```

**Rollback Validation Criteria** (ALL MUST PASS):

| Validation Criterion | Expected Result | Evidence Location |
|---------------------|----------------|-------------------|
| Service stopped cleanly | systemctl status shows "could not be found" | rollback-validation.log |
| Virtual environment removed | /opt/docling-mcp/venv does not exist | rollback-validation.log |
| Service unit removed | /etc/systemd/system/docling-mcp.service does not exist | rollback-validation.log |
| Port released | netstat shows port 8000 available | rollback-validation.log |
| No orphaned processes | pgrep -f docling-mcp returns no results | rollback-validation.log |
| Cache cleaned | /var/lib/docling-mcp/cache/ empty | rollback-validation.log |
| Workspace cleaned | /var/lib/docling-mcp/workspace/ empty | rollback-validation.log |
| Re-deployment successful | systemctl status shows "active (running)" | rollback-validation.log |
| Test results identical | Pre/post-rollback test counts match | test-results comparison |
| Health check identical | Pre/post-rollback health status match | health-check comparison |

**Rollback Test Must Pass Before Operational Promotion**:

**MANDATORY GATE**: Rollback test validation is a **BLOCKING requirement** for operational promotion.

**Gate Enforcement**:
```bash
# Quality gate validation includes rollback test
if [ ! -f "tests/test-results/rollback-validation-PASS.log" ]; then
  echo "❌ GATE FAILED: Rollback test not passed"
  echo "ACTION REQUIRED:"
  echo "1. Execute tc-docling-mcp-deployment-014-rollback-validation.md"
  echo "2. Verify all rollback criteria pass"
  echo "3. Document results in rollback-validation-PASS.log"
  echo "4. Re-run quality gate validation"
  echo ""
  echo "PROMOTION BLOCKED: Cannot promote to operational without rollback test"
  exit 1
fi

echo "✅ Rollback test passed: Promotion eligible"
```

**Rollback Test Results Documentation Requirements**:

**Required Documentation**:
1. **Test Execution Log**: `rollback-validation.log` (all commands and output)
2. **Pre-Rollback Test Results**: `pre-rollback-test-results.xml`
3. **Post-Rollback Test Results**: `post-rollback-test-results.xml`
4. **Health Check Comparison**: `baseline-health.json` vs `post-rollback-health.json`
5. **Screenshots/Evidence**: Terminal output showing clean state validation
6. **Sign-off Checklist**: All rollback criteria verified

**Documentation Template** (`rollback-validation-results.md`):

```markdown
# Rollback Test Validation Results: Docling MCP Server

**Test Date**: 2025-11-27
**Test Executed By**: [Name/Agent]
**Service Version**: 1.0.0
**Test Case**: tc-docling-mcp-deployment-014-rollback-validation.md

---

## Rollback Test Summary

**Overall Status**: PASS / FAIL

### Pre-Rollback State
- Service Status: active (running)
- Total Tests: 52
- Tests Passing: 52 (100%)
- Health Check: Healthy
- Baseline Captured: Yes

### Rollback Execution
- Service Stopped: ✅ Yes
- Application Removed: ✅ Yes
- Configuration Removed: ✅ Yes
- Clean State Validated: ✅ Yes

### Post-Rollback State
- Service Unit Removed: ✅ Yes
- Virtual Environment Removed: ✅ Yes
- Port Released: ✅ Yes
- No Orphaned Processes: ✅ Yes
- Cache Cleaned: ✅ Yes
- Workspace Cleaned: ✅ Yes

### Re-Deployment
- Service Re-Deployed: ✅ Yes
- Service Status: active (running)
- Total Tests: 52
- Tests Passing: 52 (100%)
- Health Check: Healthy

### Validation Results
- Test Results Identical: ✅ Yes (52/52 tests match)
- Health Status Identical: ✅ Yes (status=healthy)
- No Residual Issues: ✅ Yes

---

## Evidence

**Pre-Rollback Test Results**:
- File: pre-rollback-test-results.xml
- Tests: 52, Failures: 0, Pass Rate: 100%

**Post-Rollback Test Results**:
- File: post-rollback-test-results.xml
- Tests: 52, Failures: 0, Pass Rate: 100%

**Test Results Comparison**:
```bash
diff pre-rollback-test-results.xml post-rollback-test-results.xml
# No differences in test outcomes (timestamps excluded)
```

**Health Check Comparison**:
```bash
diff baseline-health.json post-rollback-health.json
# No differences (uptime excluded)
```

**Clean State Validation**:
```bash
# Service stopped
systemctl status docling-mcp.service
# Output: Unit docling-mcp.service could not be found.

# Port released
netstat -tulpn | grep :8000
# Output: (no results)

# No orphaned processes
pgrep -f docling-mcp
# Output: (no results)
```

---

## Sign-off Checklist

- [x] All cleanup successful (service, application, configuration removed)
- [x] Re-deployment successful (service running, tests passing)
- [x] Test results identical (pre/post-rollback match)
- [x] Health check identical (pre/post-rollback match)
- [x] No residual issues (orphaned processes, residual data)
- [x] Evidence captured and documented
- [x] Rollback test PASSED

**Rollback Test Status**: ✅ PASSED

**Approved By**: [Name]
**Approval Date**: [Date]

---

**Rollback Test Complete**: Service eligible for operational promotion.
```

**Mandatory Gate**: Rollback Test MUST Pass Before Operational Promotion

**Promotion Criteria Update**:
```markdown
Service can be promoted to operational ONLY if:
- [ ] ALL deployment validation tests PASS
- [ ] ALL functionality tests PASS
- [ ] ALL integration tests PASS
- [ ] ALL health check tests PASS
- [ ] ✅ ROLLBACK TEST PASSED ← MANDATORY NEW REQUIREMENT
- [ ] NO critical or high severity defects
- [ ] Test results documented in tests/test-results/
- [ ] Rollback validation results documented
```

**Gap 5 Resolution Summary**:
- ✅ Mandatory rollback test procedure documented (deploy → rollback → validate → re-deploy)
- ✅ Rollback validation criteria defined (clean state, identical test results)
- ✅ Rollback test must pass before operational promotion (BLOCKING gate)
- ✅ Rollback test results documentation requirements specified
- ✅ Rollback test integrated into quality gate validation

---

### Gap 6: Defect Management Integration ✅ RESOLVED

**Test Failure → Defect Creation Triggers** (IF FAIL conditions):

**Automated Defect Creation Rules**:

```bash
# Automated defect creation on test failure
# Location: tests/defect-automation.sh

#!/bin/bash
# Defect Automation Script
# Triggered on test failures to create defect tickets

# Parse test results XML for failures
python3 << 'EOF'
import xml.etree.ElementTree as ET
import sys
from datetime import datetime

# Load test results
tree = ET.parse('test-results.xml')
root = tree.getroot()
suite = root.find('testsuite')

# Check for failures
failures = int(suite.get('failures', 0))
errors = int(suite.get('errors', 0))

if failures + errors == 0:
    print("✅ No test failures - no defects to create")
    sys.exit(0)

print(f"⚠️ Found {failures + errors} test failures")

# Parse each failed test
for testcase in suite.findall('testcase'):
    failure = testcase.find('failure')
    error = testcase.find('error')

    if failure is not None or error is not None:
        # Extract test information
        test_class = testcase.get('classname')
        test_name = testcase.get('name')
        test_time = testcase.get('time')

        # Determine severity based on test area
        if 'deployment' in test_class:
            severity = 'CRITICAL'  # Deployment failures block everything
        elif 'functionality' in test_class:
            severity = 'HIGH'      # Feature broken
        elif 'integration' in test_class:
            severity = 'HIGH'      # Dependency issue
        elif 'health' in test_class:
            severity = 'CRITICAL'  # Service unavailable
        else:
            severity = 'MEDIUM'    # Default

        # Extract failure message
        if failure is not None:
            failure_message = failure.text
        else:
            failure_message = error.text

        # Generate defect file
        defect_id = f"defect-docling-mcp-{severity.lower()}-{datetime.now().strftime('%Y%m%d%H%M%S')}-{test_name.replace('test_', '')}"
        defect_path = f"/home/agent0/HX-Infrastructure/defects/{defect_id}.md"

        with open(defect_path, 'w') as f:
            f.write(f"""# Defect: Docling MCP Server - {test_name}

**Defect ID**: {defect_id}
**Service**: docling-mcp
**Severity**: {severity}
**Status**: OPEN
**Discovered**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Discovered By**: Automated Test Failure Detection

## Description
Test failure detected during automated test execution.

## Test Information
- **Test Class**: {test_class}
- **Test Name**: {test_name}
- **Test Duration**: {test_time} seconds

## Failure Message
```
{failure_message}
```

## Reproduction Steps
1. Run test suite: `pytest tests/`
2. Observe failure in test: `{test_class}::{test_name}`
3. Review failure message above

## Expected Behavior
Test should pass with exit code 0.

## Actual Behavior
Test failed with error message above.

## Evidence
- Test results: test-results.xml
- Execution log: test-execution.log
- Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Impact
{severity}: {"Blocks deployment" if severity == "CRITICAL" else "Blocks operational promotion" if severity == "HIGH" else "Should be resolved"}

## Resolution Required
1. Investigate root cause from failure message
2. Fix failing test or code
3. Re-run test suite
4. Verify test passes
5. Update defect status to RESOLVED

## Assigned To
Testing Lead (julia-santos)

## Escalation
{"IMMEDIATE escalation to infrastructure lead (william-chen or alex-rivera)" if severity == "CRITICAL" else "Escalate if unresolved >3 days"}
""")

        print(f"✅ Created defect: {defect_path}")

EOF
```

**IF FAIL Conditions by Test Area**:

| Test Area | IF Test Fails → Severity | Defect Trigger | Escalation Path |
|-----------|-------------------------|----------------|-----------------|
| **Deployment** | tc-docling-mcp-deployment-* FAILS | **CRITICAL** | Immediate → william-chen (Infrastructure) |
| **Functionality** | tc-docling-mcp-functionality-* FAILS | **HIGH** | Immediate → Component owner / alex-rivera (Architecture) |
| **Integration** | tc-docling-mcp-integration-* FAILS | **HIGH** (LiteLLM, Qdrant, Redis)<br>**MEDIUM** (non-critical) | Immediate → Dependency owner |
| **Health Check** | tc-docling-mcp-health-* FAILS | **CRITICAL** | Immediate → william-chen (Infrastructure) |

**Defect Severity Assessment Criteria Per Test Area**:

**CRITICAL Defects** (Immediate Escalation):
- Service cannot start (deployment test failure)
- Health check endpoint unreachable (health test failure)
- Service crash on startup (deployment test failure)
- Systemd service fails to enable (deployment test failure)
- Security vulnerability discovered (security test failure)
- Data loss risk identified (integration test failure with data store)

**HIGH Defects** (Escalate if >1 day unresolved):
- Core MCP tool broken (functionality test failure)
- Integration with LiteLLM fails (integration test failure)
- Integration with Qdrant fails (integration test failure)
- Document processing produces invalid output (functionality test failure)
- Performance degradation >50% (performance test failure)
- Resource usage exceeds limits (health test failure)

**MEDIUM Defects** (Escalate if >3 days unresolved):
- Non-critical feature broken (functionality test failure)
- Minor integration issue with workaround (integration test failure)
- Performance degradation 20-50% (performance test failure)
- Non-critical configuration issue (deployment test failure)
- Cosmetic issue in output (functionality test failure)

**LOW Defects** (Track in backlog):
- Cosmetic issue (documentation, UI)
- Minor bug with workaround (functionality test failure - low priority feature)
- Documentation gap (documentation test failure)
- Enhancement request (feature request, not defect)

**Defect Severity Decision Tree**:

```
Test Failure Detected
    ↓
Q1: Can service start?
    NO → CRITICAL (deployment blocker)
    YES ↓
Q2: Is core functionality broken?
    YES → HIGH (feature broken)
    NO ↓
Q3: Is integration point broken?
    YES → HIGH (dependency issue)
    NO ↓
Q4: Is health check failing?
    YES → CRITICAL (service unavailable)
    NO ↓
Q5: Is performance degraded >50%?
    YES → HIGH (performance issue)
    NO ↓
Q6: Is there a workaround?
    NO → MEDIUM (no workaround)
    YES → LOW (workaround available)
```

**Defect Template** (from HX-Infrastructure standards):

**Template Location**: `/home/agent0/HX-Infrastructure/templates/testing/defect-template.md`

**Usage**:
```bash
# Create defect from template
cp /home/agent0/HX-Infrastructure/templates/testing/defect-template.md \
   /home/agent0/HX-Infrastructure/defects/defect-docling-mcp-<severity>-<seq>-<description>.md

# Fill in:
# - Defect ID
# - Severity (CRITICAL, HIGH, MEDIUM, LOW)
# - Test area that failed
# - Failure message
# - Reproduction steps
# - Expected vs actual behavior
# - Evidence (logs, screenshots)
# - Resolution steps
```

**Defect Resolution Validation** (Re-test After Fix):

**Resolution Workflow**:
```
1. Defect Created (test failure detected)
    ↓
2. Assigned to Component Owner (based on test area)
    ↓
3. Root Cause Analysis (investigate failure)
    ↓
4. Fix Implementation (code/config change)
    ↓
5. Re-Test (MANDATORY)
    ↓
    IF Test Passes:
        6a. Update Defect Status: RESOLVED
        7a. Document Resolution
        8a. Re-run Full Test Suite (regression check)
        9a. Quality Gate Validation
        10a. Proceed to Promotion (if all gates pass)
    ↓
    IF Test Still Fails:
        6b. Update Defect Status: IN PROGRESS
        7b. Document Investigation Findings
        8b. Return to Step 3 (Root Cause Analysis)
        9b. Escalate if >2 attempts fail
```

**Re-Test Validation Commands**:
```bash
# After defect fix, re-run specific test
pytest tests/test-suite/<area>/<test-file>.py -v

# Expected: Test now passes

# Re-run full test suite (regression check)
pytest tests/ --verbose --tb=short

# Expected: All tests pass (regression not introduced)

# Update defect status
echo "Status: RESOLVED" >> /home/agent0/HX-Infrastructure/defects/defect-docling-mcp-<id>.md
echo "Resolved: $(date +'%Y-%m-%d %H:%M:%S')" >> /home/agent0/HX-Infrastructure/defects/defect-docling-mcp-<id>.md
echo "Resolution: <describe fix>" >> /home/agent0/HX-Infrastructure/defects/defect-docling-mcp-<id>.md
```

**Resolution Validation Criteria**:
- [ ] Original failing test now passes
- [ ] No new test failures introduced (regression check)
- [ ] Root cause addressed (not just symptom)
- [ ] Resolution documented in defect ticket
- [ ] Defect status updated to RESOLVED
- [ ] Quality gate validation re-run (all gates pass)

**Escalation Paths** (based on severity and resolution time):

**CRITICAL Defects** (Immediate Escalation):
```
CRITICAL Defect Created (deployment/health failure)
    ↓
IMMEDIATE → Escalate to william-chen (Infrastructure) or alex-rivera (Architecture)
    ↓
IF unresolved >4 hours → Escalate to CAIO (project manager)
    ↓
IF unresolved >1 day → Emergency review, consider scope reduction
```

**HIGH Defects** (Escalate if >1 Day Unresolved):
```
HIGH Defect Created (functionality/integration failure)
    ↓
Assign to Component Owner (based on test area)
    ↓
IF unresolved >1 day → Escalate to william-chen or alex-rivera
    ↓
IF unresolved >3 days → Escalate to CAIO
    ↓
IF 2+ HIGH defects in same area → Escalate immediately to component owner
```

**MEDIUM Defects** (Escalate if >3 Days Unresolved):
```
MEDIUM Defect Created (non-critical issue)
    ↓
Assign to Component Owner
    ↓
IF unresolved >3 days → Escalate to component owner
    ↓
IF unresolved >7 days → Escalate to project manager
```

**LOW Defects** (Track in Backlog):
```
LOW Defect Created (cosmetic/enhancement)
    ↓
Add to Backlog (not blocking promotion)
    ↓
Review quarterly for prioritization
```

**2+ Defects in Same Area** (Pattern Detection):
```
IF 2+ HIGH defects in same test area detected:
    ↓
IMMEDIATE Escalation to Component Owner
    ↓
Pattern Analysis: Are these related?
    ↓
    IF Related:
        - Create CRITICAL parent defect
        - Link child defects
        - Escalate to architecture review (alex-rivera)
    ↓
    IF Unrelated:
        - Continue independent resolution
        - Monitor for additional failures
```

**Defect Unresolved >3 Days** (Automatic Escalation):
```bash
# Automated escalation check (run daily)
#!/bin/bash
# defect-escalation-check.sh

DEFECTS_DIR="/home/agent0/HX-Infrastructure/defects"
CURRENT_DATE=$(date +%s)

for defect in $DEFECTS_DIR/defect-docling-mcp-*.md; do
    # Extract creation date
    CREATED=$(grep "Discovered:" "$defect" | awk '{print $2, $3}')
    CREATED_EPOCH=$(date -d "$CREATED" +%s)

    # Extract severity
    SEVERITY=$(grep "Severity:" "$defect" | awk '{print $2}')

    # Extract status
    STATUS=$(grep "Status:" "$defect" | awk '{print $2}')

    # Skip if resolved
    if [ "$STATUS" == "RESOLVED" ]; then
        continue
    fi

    # Calculate days open
    DAYS_OPEN=$(( ($CURRENT_DATE - $CREATED_EPOCH) / 86400 ))

    # Escalation rules
    if [ "$SEVERITY" == "CRITICAL" ] && [ $DAYS_OPEN -gt 0 ]; then
        echo "⚠️ ESCALATION: CRITICAL defect open >1 day: $defect"
        echo "ACTION: Escalate to CAIO immediately"
    elif [ "$SEVERITY" == "HIGH" ] && [ $DAYS_OPEN -gt 1 ]; then
        echo "⚠️ ESCALATION: HIGH defect open >1 day: $defect"
        echo "ACTION: Escalate to component owner"
    elif [ "$SEVERITY" == "MEDIUM" ] && [ $DAYS_OPEN -gt 3 ]; then
        echo "⚠️ ESCALATION: MEDIUM defect open >3 days: $defect"
        echo "ACTION: Escalate to component owner"
    fi
done
```

**Gap 6 Resolution Summary**:
- ✅ Test failure → defect creation triggers (automated detection)
- ✅ Defect severity assessment criteria per test area (CRITICAL, HIGH, MEDIUM, LOW)
- ✅ Defect resolution validation before promotion (re-test mandatory)
- ✅ Escalation paths (severity-based, time-based, pattern-based)
- ✅ Automated defect creation on test failure
- ✅ Defect tracking integrated into quality gate validation

---

## Test Areas and Test Cases

### 1. Deployment Validation Tests (14 Test Cases)

**Purpose**: Verify deployment executed correctly per deployment-architecture.md and configuration-spec.md

**Test Area Directory**: `tests/test-suite/deployment/`

**Test Cases**:

1. `tc-docling-mcp-deployment-001-verify-installation.md`
   - **Objective**: Verify service files installed in correct locations
   - **Coverage**: /opt/docling-mcp/, /etc/docling-mcp/, /var/lib/docling-mcp/, /var/log/docling-mcp/

2. `tc-docling-mcp-deployment-002-verify-configuration.md`
   - **Objective**: Verify configuration files created and correct
   - **Coverage**: .env file, logging.conf, systemd unit file

3. `tc-docling-mcp-deployment-003-verify-dependencies.md`
   - **Objective**: Verify all dependencies installed (system + Python)
   - **Coverage**: Python 3.11+, poppler-utils, tesseract-ocr, pip packages

4. `tc-docling-mcp-deployment-004-service-starts.md`
   - **Objective**: Verify service starts without errors
   - **Coverage**: systemctl start, process running, logs clean

5. `tc-docling-mcp-deployment-005-systemd-unit-file.md`
   - **Objective**: Verify systemd unit file configured correctly (HX-Infrastructure requirement)
   - **Coverage**: Unit file syntax, service enabled, service active, status healthy

6. `tc-docling-mcp-deployment-006-filesystem-layout.md`
   - **Objective**: Verify filesystem layout matches architecture spec (HX-Infrastructure requirement)
   - **Coverage**: Directory structure, file ownership, permissions

7. `tc-docling-mcp-deployment-007-environment-variables.md`
   - **Objective**: Verify environment variables loaded correctly
   - **Coverage**: .env file loaded, all required variables set, values correct

8. `tc-docling-mcp-deployment-008-python-venv.md`
   - **Objective**: Verify Python virtual environment created correctly
   - **Coverage**: venv exists, Python version, pip packages installed

9. `tc-docling-mcp-deployment-009-log-files.md`
   - **Objective**: Verify log files created and writable
   - **Coverage**: Log directory, log files, rotation configured

10. `tc-docling-mcp-deployment-010-network-binding.md`
    - **Objective**: Verify service binds to correct network interface and port
    - **Coverage**: Port 8000 listening, internal interface only (not 0.0.0.0)

11. `tc-docling-mcp-deployment-011-vault-access.md`
    - **Objective**: Verify service can access Ansible Vault secrets (HX-Infrastructure requirement)
    - **Coverage**: Vault file exists, encrypted, service loaded secrets

12. `tc-docling-mcp-deployment-012-manual-execution.md`
    - **Objective**: Verify deployment followed manual procedures (HX-Infrastructure requirement)
    - **Coverage**: Task files executed, no automation artifacts

13. `tc-docling-mcp-deployment-013-configuration-from-template.md`
    - **Objective**: Verify configuration created from templates (HX-Infrastructure requirement)
    - **Coverage**: Templates used, variables substituted, syntax valid

14. `tc-docling-mcp-deployment-014-rollback-validation.md`
    - **Objective**: Validate rollback capability (MANDATORY before operational promotion)
    - **Coverage**: Deploy → rollback → validate clean state → re-deploy → verify identical results

**Estimated Test Execution Time**: 30-45 minutes (sequential execution required for deployment tests)

---

### 2. Functionality Tests (19 Test Cases - One Per MCP Tool)

**Purpose**: Verify all 19 MCP tools meet functional requirements

**Test Area Directory**: `tests/test-suite/functionality/`

**Subdirectories**:
- `tests/test-suite/functionality/conversion/` - 3 conversion tools
- `tests/test-suite/functionality/generation/` - 11 generation tools
- `tests/test-suite/functionality/manipulation/` - 5 manipulation tools

**Conversion Tools** (3 tests):

1. `tc-docling-mcp-functionality-001-convert-pdf.md`
   - **Tool**: convert_pdf
   - **Objective**: Convert PDF to DoclingDocument format
   - **Coverage**: PDF upload, conversion, DoclingDocument returned, structure preserved

2. `tc-docling-mcp-functionality-002-convert-docx.md`
   - **Tool**: convert_docx
   - **Objective**: Convert DOCX to DoclingDocument format
   - **Coverage**: DOCX upload, conversion, style preservation

3. `tc-docling-mcp-functionality-003-convert-url.md`
   - **Tool**: convert_url
   - **Objective**: Convert document from URL
   - **Coverage**: URL fetch, format detection, conversion

**Generation Tools** (11 tests):

4. `tc-docling-mcp-functionality-004-generate-title.md`
   - **Tool**: generate_title
   - **Objective**: Generate document title
   - **Coverage**: Title generation, LLM integration

5. `tc-docling-mcp-functionality-005-generate-toc.md`
   - **Tool**: generate_toc
   - **Objective**: Generate table of contents
   - **Coverage**: TOC structure, heading hierarchy

6. `tc-docling-mcp-functionality-006-generate-section.md`
   - **Tool**: generate_section
   - **Objective**: Generate document section
   - **Coverage**: Section content, heading level

7. `tc-docling-mcp-functionality-007-generate-heading.md`
   - **Tool**: generate_heading
   - **Objective**: Generate heading element
   - **Coverage**: Heading text, level (H1-H6)

8. `tc-docling-mcp-functionality-008-generate-paragraph.md`
   - **Tool**: generate_paragraph
   - **Objective**: Generate paragraph element
   - **Coverage**: Paragraph text, formatting

9. `tc-docling-mcp-functionality-009-generate-list.md`
   - **Tool**: generate_list
   - **Objective**: Generate list element (ordered/unordered)
   - **Coverage**: List items, list type

10. `tc-docling-mcp-functionality-010-generate-table.md`
    - **Tool**: generate_table
    - **Objective**: Generate table element
    - **Coverage**: Table structure, rows, columns

11. `tc-docling-mcp-functionality-011-generate-image.md`
    - **Tool**: generate_image
    - **Objective**: Generate image element
    - **Coverage**: Image reference, caption

12. `tc-docling-mcp-functionality-012-generate-caption.md`
    - **Tool**: generate_caption
    - **Objective**: Generate caption for image/table
    - **Coverage**: Caption text, associated element

13. `tc-docling-mcp-functionality-013-generate-codeblock.md`
    - **Tool**: generate_codeblock
    - **Objective**: Generate code block element
    - **Coverage**: Code content, language syntax highlighting

14. `tc-docling-mcp-functionality-014-generate-reference.md`
    - **Tool**: generate_reference
    - **Objective**: Generate reference/citation
    - **Coverage**: Reference format, bibliography

**Manipulation Tools** (5 tests):

15. `tc-docling-mcp-functionality-015-split-document.md`
    - **Tool**: split_document
    - **Objective**: Split document into sections
    - **Coverage**: Split logic, section boundaries

16. `tc-docling-mcp-functionality-016-merge-documents.md`
    - **Tool**: merge_documents
    - **Objective**: Merge multiple documents
    - **Coverage**: Merge logic, structure preservation

17. `tc-docling-mcp-functionality-017-export-markdown.md`
    - **Tool**: export_markdown
    - **Objective**: Export DoclingDocument to Markdown
    - **Coverage**: Markdown syntax, formatting preservation

18. `tc-docling-mcp-functionality-018-export-html.md`
    - **Tool**: export_html
    - **Objective**: Export DoclingDocument to HTML
    - **Coverage**: HTML structure, styling

19. `tc-docling-mcp-functionality-019-export-json.md`
    - **Tool**: export_json
    - **Objective**: Export DoclingDocument to JSON
    - **Coverage**: JSON structure, data completeness

**Estimated Test Execution Time**: 1-2 hours (can run in parallel)

---

### 3. Integration Tests (5 Test Cases)

**Purpose**: Verify service integrates correctly with dependencies

**Test Area Directory**: `tests/test-suite/integration/`

**Test Cases**:

1. `tc-docling-mcp-integration-001-litellm-connection.md`
   - **Objective**: Verify LiteLLM Gateway connection and model routing
   - **Coverage**: Connection, authentication, model availability (gemma3:27b, gpt-oss:20b, granite-docling:258m)

2. `tc-docling-mcp-integration-002-qdrant-connection.md`
   - **Objective**: Verify Qdrant vector database connection and collection access
   - **Coverage**: Connection, collection creation, vector upsert, search

3. `tc-docling-mcp-integration-003-redis-connection.md`
   - **Objective**: Verify Redis cache connection and session management
   - **Coverage**: Connection, key-value operations, session TTL

4. `tc-docling-mcp-integration-004-lightrag-integration.md`
   - **Objective**: Verify LightRAG knowledge graph engine integration
   - **Coverage**: Entity extraction, relationship modeling, graph storage in Qdrant

5. `tc-docling-mcp-integration-005-mcp-protocol.md`
   - **Objective**: Verify MCP protocol compliance (HTTP, SSE, stdio transports)
   - **Coverage**: Tool discovery, tool execution, error handling

**Estimated Test Execution Time**: 30-45 minutes (sequential due to dependency checks)

---

### 4. Health Check Tests (4 Test Cases)

**Purpose**: Verify ongoing operational health

**Test Area Directory**: `tests/test-suite/health-check/`

**Test Cases**:

1. `tc-docling-mcp-health-001-endpoint.md`
   - **Objective**: Verify health endpoint responds correctly
   - **Coverage**: /health endpoint, response time < 2 seconds, status=healthy

2. `tc-docling-mcp-health-002-resources.md`
   - **Objective**: Verify resource usage within limits
   - **Coverage**: CPU < 400%, Memory < 8GB, Disk usage acceptable

3. `tc-docling-mcp-health-003-no-errors.md`
   - **Objective**: Verify no error conditions in logs
   - **Coverage**: No ERROR/CRITICAL logs, no crash events, service stable

4. `tc-docling-mcp-health-004-dependency-connectivity.md`
   - **Objective**: Verify dependency health
   - **Coverage**: LiteLLM reachable, Qdrant reachable, Redis reachable

**Estimated Test Execution Time**: 15-20 minutes

---

### 5. Multimodal Validation Tests (6 Test Cases)

**Purpose**: Verify multimodal document processing with format-specific accuracy

**Test Area Directory**: `tests/test-suite/multimodal/`

**Test Cases**:

1. `tc-docling-mcp-multimodal-001-pdf-digital.md`
   - **Objective**: Validate digital PDF processing (99%+ accuracy)
   - **Coverage**: Text extraction, heading hierarchy, tables, lists

2. `tc-docling-mcp-multimodal-002-pdf-scanned.md`
   - **Objective**: Validate scanned PDF OCR processing (85%+ accuracy)
   - **Coverage**: OCR accuracy, layout detection, image regions

3. `tc-docling-mcp-multimodal-003-docx-processing.md`
   - **Objective**: Validate DOCX processing (99%+ accuracy)
   - **Coverage**: Text extraction, style preservation, tables

4. `tc-docling-mcp-multimodal-004-pptx-processing.md`
   - **Objective**: Validate PPTX processing (95%+ slide structure)
   - **Coverage**: Slide structure, text boxes, charts/images

5. `tc-docling-mcp-multimodal-005-xlsx-processing.md`
   - **Objective**: Validate XLSX processing (99%+ cell extraction)
   - **Coverage**: Cell data, formula preservation, sheet structure

6. `tc-docling-mcp-multimodal-006-image-ocr.md`
   - **Objective**: Validate image OCR processing (90%+ accuracy)
   - **Coverage**: PNG/JPG OCR, metadata extraction, text regions

**Estimated Test Execution Time**: 1-1.5 hours

---

## Test Coverage Summary

**Total Test Cases**: 48 test cases

| Test Area | Test Cases | Coverage |
|-----------|------------|----------|
| Deployment Validation | 14 | 100% deployment steps + HX-Infrastructure requirements + rollback |
| Functionality | 19 | 100% MCP tools (3 conversion + 11 generation + 5 manipulation) |
| Integration | 5 | 100% integration points (LiteLLM, Qdrant, Redis, LightRAG, MCP) |
| Health Check | 4 | 100% health validation (endpoint, resources, errors, dependencies) |
| Multimodal | 6 | 100% document formats (PDF, DOCX, PPTX, XLSX, images) |

**Requirements Traceability Matrix**:

| Requirement ID | Requirement Description | Test Case ID(s) | Priority |
|---------------|------------------------|----------------|----------|
| **Charter Success Criteria** |
| SC-001 | MCP Server Operational (19 tools) | tc-docling-mcp-functionality-001 through 019 | HIGH |
| SC-002 | Document Ingestion via Docling | tc-docling-mcp-multimodal-001 through 006 | HIGH |
| SC-003 | Knowledge Graph via LightRAG | tc-docling-mcp-integration-004 | HIGH |
| SC-004 | Qdrant Integration | tc-docling-mcp-integration-002 | HIGH |
| SC-005 | LiteLLM Integration | tc-docling-mcp-integration-001 | HIGH |
| **Deployment Requirements** |
| DR-001 | Service installed correctly | tc-docling-mcp-deployment-001 | HIGH |
| DR-002 | Configuration files created | tc-docling-mcp-deployment-002 | HIGH |
| DR-003 | Dependencies installed | tc-docling-mcp-deployment-003 | HIGH |
| DR-004 | Systemd service configured | tc-docling-mcp-deployment-005 | CRITICAL |
| DR-005 | Filesystem layout correct | tc-docling-mcp-deployment-006 | HIGH |
| DR-006 | Ansible Vault accessible | tc-docling-mcp-deployment-011 | HIGH |
| DR-007 | Manual deployment verified | tc-docling-mcp-deployment-012 | HIGH |
| DR-008 | Rollback capability validated | tc-docling-mcp-deployment-014 | CRITICAL |
| **Functional Requirements** |
| FR-001 | MCP Protocol Compliance | tc-docling-mcp-integration-005 | HIGH |
| FR-002 | Document Conversion (PDF) | tc-docling-mcp-functionality-001, tc-docling-mcp-multimodal-001, 002 | HIGH |
| FR-003 | Document Conversion (DOCX) | tc-docling-mcp-functionality-002, tc-docling-mcp-multimodal-003 | HIGH |
| FR-004 | Knowledge Graph Generation | tc-docling-mcp-integration-004 | HIGH |
| FR-005 | Multimodal Processing | tc-docling-mcp-multimodal-001 through 006 | HIGH |

**100% Requirements Coverage**: ✅ All requirements mapped to test cases

---

## Test Execution Strategy

### Execution Order (MANDATORY SEQUENCE)

**Tests MUST execute in this order** (per HX-Infrastructure testing-requirements.md):

```
1. Deployment Validation Tests (tc-docling-mcp-deployment-001 through 014)
   ↓ ALL MUST PASS before proceeding
2. Functionality Tests (tc-docling-mcp-functionality-001 through 019)
   ↓ ALL MUST PASS before proceeding
3. Integration Tests (tc-docling-mcp-integration-001 through 005)
   ↓ ALL MUST PASS before proceeding
4. Health Check Tests (tc-docling-mcp-health-001 through 004)
   ↓ ALL MUST PASS before proceeding
5. Multimodal Tests (tc-docling-mcp-multimodal-001 through 006)
   ↓ ALL MUST PASS for operational promotion
```

**IF ANY TEST FAILS**:
1. STOP execution immediately
2. Create defect ticket (automated via defect-automation.sh)
3. Investigate root cause
4. Fix issue
5. Re-run ALL tests from beginning (regression check)

### Test Execution Commands

**Complete Test Suite Execution**:
```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Run complete test suite with quality gate validation
/opt/docling-mcp/tests/quality-gate.sh

# Expected output:
# - All gates pass
# - Exit code 0
# - Evidence files generated:
#   - test-results.xml (JUnit XML)
#   - coverage.xml (Cobertura XML)
#   - htmlcov/index.html (HTML coverage report)
#   - test-execution.log (execution log with timestamps)
```

**Individual Test Area Execution**:
```bash
# Run deployment tests only
pytest tests/test-suite/deployment/ --verbose --tb=short

# Run functionality tests only
pytest tests/test-suite/functionality/ --verbose --tb=short

# Run integration tests only
pytest tests/test-suite/integration/ --verbose --tb=short

# Run health check tests only
pytest tests/test-suite/health-check/ --verbose --tb=short

# Run multimodal tests only
pytest tests/test-suite/multimodal/ --verbose --tb=short
```

**Individual Test Case Execution**:
```bash
# Run specific test case
pytest tests/test-suite/deployment/test_installation.py::test_service_installed --verbose

# Run specific test with coverage
pytest tests/test-suite/functionality/test_convert_pdf.py --cov=docling_mcp.tools.conversion --verbose
```

### Pass/Fail Criteria

**Individual Test**:
- **PASS**: All assertions pass, no exceptions, exit code 0
- **FAIL**: Any assertion fails, exception raised, exit code 1
- **BLOCKED**: Cannot execute due to dependency failure (e.g., service not running)

**Test Suite**:
- **PASS**: ALL tests pass (100% pass rate)
- **FAIL**: ANY test fails
- **BLOCKED**: ANY test blocked

**Quality Gate**:
- **PASS**: All gates pass (tests 100%, coverage ≥95%, integration healthy, health checks passing)
- **FAIL**: Any gate fails
- **ACTION**: STOP deployment, create defect, fix, re-test

### Parallel Execution

**Tests that CAN run in parallel** (within same test area):
- Functionality tests (independent MCP tool tests)
- Multimodal tests (independent format tests)

**Tests that MUST run sequentially**:
- Deployment tests (order-dependent: installation → configuration → startup)
- Integration tests (dependency on service running)
- Health check tests (require service operational)

**Parallel Execution Command** (pytest-xdist):
```bash
# Install pytest-xdist for parallel execution
pip install pytest-xdist

# Run functionality tests in parallel (4 workers)
pytest tests/test-suite/functionality/ -n 4 --verbose

# Run multimodal tests in parallel (4 workers)
pytest tests/test-suite/multimodal/ -n 4 --verbose
```

**CAUTION**: Only use parallel execution for independent tests. Deployment, integration, and health tests MUST run sequentially.

---

## Service Promotion Criteria

**Service can be promoted from non-operational to operational ONLY if:**

### General Test Requirements ✅
- [ ] Test plan complete and approved (this document)
- [ ] All 48 test cases written before deployment
- [ ] All test cases use template format
- [ ] Test cases peer reviewed
- [ ] Requirements coverage matrix shows 100%

### Standard Test Coverage ✅
- [ ] All 14 deployment validation tests PASS
- [ ] All 19 functionality tests PASS (100% MCP tools coverage)
- [ ] All 5 integration tests PASS (100% integration points)
- [ ] All 4 health check tests PASS
- [ ] All 6 multimodal tests PASS (100% format coverage)

### Quality Gate Validation ✅
- [ ] pytest execution complete (test-results.xml generated)
- [ ] Coverage ≥95% validated (coverage.xml generated)
- [ ] All quality gates PASS (quality-gate.sh exit code 0)
- [ ] Evidence captured (logs, reports, timestamps)

### Rollback Testing ✅ MANDATORY
- [ ] Rollback test executed (tc-docling-mcp-deployment-014)
- [ ] All rollback criteria PASS (clean state, identical results)
- [ ] Rollback validation results documented
- [ ] Rollback test sign-off complete

### Defect Management ✅
- [ ] No CRITICAL severity defects
- [ ] No HIGH severity defects
- [ ] MEDIUM/LOW defects justified if present
- [ ] All defects documented in /defects/
- [ ] Defect resolution validation complete

### Documentation ✅
- [ ] Test plan complete (this document)
- [ ] All test cases documented
- [ ] All test results documented in tests/test-results/
- [ ] Requirements coverage matrix updated
- [ ] Test suite index complete

### Infrastructure Compliance ✅
- [ ] Systemd service tests PASS (unit file, enabled, running, status)
- [ ] Bare metal deployment tests PASS (filesystem, resources)
- [ ] Manual deployment verification PASS (no automation artifacts)
- [ ] Ansible Vault tests PASS (vault access, scope verification)
- [ ] Configuration tests PASS (manual template-based creation)

### Final Approval ✅
- [ ] Infrastructure lead approval (william-chen)
- [ ] QA approval (julia-santos)
- [ ] All blocking issues resolved
- [ ] Service ready for operational/

**MANDATORY**: ALL criteria above MUST be met. No exceptions. No shortcuts.

---

## Test Schedule

| Phase | Duration | Activities | Deliverables |
|-------|----------|------------|-------------|
| **Test Plan Creation** | 1 day | Create this test plan document | test-plan.md (COMPLETE) |
| **Test Case Creation** | 4-5 days | Write all 48 test cases | 48 test case files |
| **Test Environment Setup** | 1 day | Prepare test data, fixtures | Test data files, conftest.py |
| **Pre-Deploy Test Execution** | 1 day | Run tests (should fail - service not deployed) | Pre-deploy test results |
| **Deployment Execution** | 2-3 days | Execute deployment tasks 001-019 | Service deployed to non-operational |
| **Post-Deploy Test Execution** | 2-3 days | Run all tests (should pass) | test-results.xml, coverage reports |
| **Rollback Testing** | 1 day | Execute rollback validation | Rollback validation results |
| **Defect Resolution** | 3-5 days (if needed) | Fix any failures, re-test | Defect tickets, resolution docs |
| **Quality Gate Validation** | 1 day | Run quality-gate.sh, verify all gates pass | Quality gate evidence |
| **Final Approval** | 1 day | Review, sign-off | Promotion approval |

**Total Estimated Duration**: 15-20 days (including defect resolution buffer)

**Critical Path Dependencies**:
- Test case creation MUST complete before deployment execution
- Deployment MUST complete before post-deploy test execution
- All tests MUST pass before rollback testing
- Rollback test MUST pass before operational promotion

---

## Defect Management

### Defect Tracking

**Defect Location**: `/home/agent0/HX-Infrastructure/defects/`
**Naming Convention**: `defect-docling-mcp-<severity>-<seq>-<description>.md`
**Template**: `/home/agent0/HX-Infrastructure/templates/testing/defect-template.md`

### Severity Definitions

**CRITICAL**: Service completely non-functional, deployment blocker, security breach
- Examples: Service fails to start, systemd service broken, health check unreachable, data loss risk
- Escalation: IMMEDIATE → william-chen or alex-rivera
- Resolution Required: <4 hours

**HIGH**: Major functionality broken, significant operational impact, integration failure
- Examples: MCP tool broken, LiteLLM connection fails, Qdrant integration fails, performance degradation >50%
- Escalation: IF unresolved >1 day → william-chen or alex-rivera
- Resolution Required: <1 day

**MEDIUM**: Functionality impaired, workaround available, minor integration issue
- Examples: Non-critical feature broken, performance degradation 20-50%, minor config issue
- Escalation: IF unresolved >3 days → component owner
- Resolution Required: <3 days

**LOW**: Minor issue, cosmetic, enhancement request
- Examples: Documentation gap, cosmetic issue, enhancement
- Escalation: Backlog review quarterly
- Resolution Required: Backlog

### Defect Resolution Requirements

**CRITICAL/HIGH Defects**:
- MUST be resolved before operational promotion
- MUST be re-tested after fix
- MUST verify no regression introduced
- MUST document resolution in defect ticket

**MEDIUM Defects**:
- Should be resolved before promotion
- May accept with documented justification
- Must track for future resolution

**LOW Defects**:
- Can be backlogged
- Do not block promotion
- Review quarterly for prioritization

### Automated Defect Creation

**Defect Automation Script**: `/opt/docling-mcp/tests/defect-automation.sh`

**Trigger**: Test failure detected in test-results.xml
**Action**: Create defect ticket automatically
**Severity**: Determined by test area (deployment=CRITICAL, functionality=HIGH, etc.)
**Assignment**: Based on test area (deployment→william-chen, functionality→component owner, etc.)

---

## Test Deliverables

### Test Artifacts ✅
- [x] Test plan (this document - COMPLETE)
- [ ] 48 test cases in tests/test-suite/[area]/
- [ ] Test results in tests/test-results/
- [ ] Coverage reports (HTML, XML)
- [ ] Defects logged in /defects/ (if any)
- [ ] Test summary report
- [ ] Test metrics and coverage report
- [ ] Rollback validation results

### Documentation Updates
- [ ] Update inventory/services.md with test status
- [ ] Update service status (non-operational → operational after promotion)
- [ ] Document lessons learned
- [ ] Update test suite index

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| LiteLLM Gateway unavailable during testing | HIGH | LOW | Test environment validation before test execution, retry logic in tests |
| Qdrant vector database unavailable | HIGH | LOW | Pre-flight connectivity check, fallback to mock in test environment |
| Redis cache unavailable | MEDIUM | LOW | Pre-flight connectivity check, test with in-memory fallback |
| Test data files missing | MEDIUM | LOW | Create test data as part of test environment setup (Task 027) |
| Insufficient test coverage | CRITICAL | MEDIUM | Automated coverage validation (≥95% enforced), quality gate BLOCKS promotion |
| Test failures due to timing issues | MEDIUM | MEDIUM | Implement retry logic, increase timeouts for slow operations |
| Rollback test failure | HIGH | LOW | Dry-run rollback procedure before executing test, document manual steps |
| Multimodal accuracy below thresholds | HIGH | MEDIUM | Use validated ground truth data, adjust thresholds if justified with evidence |

---

## Test Metrics

### Metrics to Track
- **Total test cases planned**: 48
- **Test cases created**: (To be tracked during Task 020-027)
- **Test cases executed**: (To be tracked during test execution)
- **Pass rate**: (% passed / total executed) - TARGET: 100%
- **Coverage**: (line coverage %) - TARGET: ≥95%
- **Defects found by severity**: (CRITICAL, HIGH, MEDIUM, LOW counts)
- **Defects resolved**: (Resolution rate)
- **Time to execute test suite**: (Minutes) - TARGET: <2 hours
- **Rollback test status**: (PASS/FAIL) - MANDATORY: PASS

### Success Metrics (NON-NEGOTIABLE)
- **Pass Rate**: 100% (all tests must pass)
- **Requirements Coverage**: 100% (all requirements tested)
- **Code Coverage**: ≥95% (line coverage enforced)
- **Critical/High Defects**: 0 (none unresolved)
- **Rollback Test**: PASS (mandatory before promotion)

---

## Test Tools and Resources

### Tools Required
- **pytest** (v7.4+): Primary testing framework
- **pytest-cov**: Coverage measurement
- **pytest-asyncio**: Async test support
- **pytest-xdist**: Parallel test execution (optional)
- **coverage**: Coverage reporting
- **curl**: HTTP endpoint testing
- **jq**: JSON parsing for health checks
- **systemctl**: Service management validation
- **netstat**: Network port validation

### Test Environment
- **Node**: hx-docling-mcp-server (192.168.10.217)
- **OS**: Ubuntu 24.04 LTS
- **Python**: 3.11+
- **Virtual Environment**: /opt/docling-mcp/venv
- **Test Data**: /opt/docling-mcp/tests/test-data/

### Personnel
- **Test Plan Creator**: julia-santos (Testing & Quality Specialist) - COMPLETE
- **Test Case Creators**: To be assigned (Tasks 020-027)
- **Test Executors**: To be assigned (post-deployment)
- **Defect Tracker**: julia-santos
- **Approval Authority**: william-chen (Infrastructure), julia-santos (QA), CAIO (Final)

---

## Approval and Sign-off

### Review Status
- [x] Test plan reviewed by julia-santos (creator - self-review)
- [ ] Test plan reviewed by william-chen (infrastructure lead)
- [ ] Test plan reviewed by alex-rivera (architecture lead)
- [ ] Test coverage verified against charter and specification
- [ ] Test approach approved by Core Team SMEs

### Approval
**Test Plan Status**: Phase 1 Complete - Ready for Test Creation

**Created By**: Julia Santos (Testing & Quality Specialist)
**Date**: 2025-11-27
**Version**: 1.0

**Pending Approvals**:
- [ ] william-chen (Infrastructure Specialist) - Infrastructure-specific test validation
- [ ] alex-rivera (Platform Architect) - Architecture compliance review
- [ ] CAIO - Final approval for Phase 3 (Test Creation)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-27 | julia-santos | Initial test plan creation - Phase 1 deliverable addressing all 6 quality gaps from plan.md quality review |

---

## Summary: Quality Gaps Resolved

This comprehensive test plan addresses ALL 6 quality gaps identified in the approved plan.md (lines 629-638):

✅ **Gap 2 - Test Coverage Methodology**: Complete pytest.ini configuration, pyproject.toml, fixture strategy (conftest.py), parametrization for multimodal testing, coverage reporting (HTML/XML/terminal), coverage enforcement (≥95% threshold, CI/CD integration)

✅ **Gap 3 - Multimodal Validation Criteria**: Format-specific accuracy thresholds (PDF 99%/85%, DOCX 99%, PPTX 95%, XLSX 99%, images 90%+), structure preservation requirements, error handling expectations, test data sets, validation methods (diff, structure, manual)

✅ **Gap 4 - Quality Gate Validation Commands**: Concrete pytest commands with JUnit XML output, coverage measurement commands, evidence capture (logs, reports, timestamps), quality gate enforcement (automated script, STOP on failure), defect logging triggers

✅ **Gap 5 - Rollback Testing Validation**: Mandatory rollback test procedure (deploy → rollback → validate → re-deploy), rollback validation criteria, rollback test MUST pass before operational promotion, rollback results documentation requirements

✅ **Gap 6 - Defect Management Integration**: Test failure → defect creation triggers (automated), defect severity assessment criteria per test area (CRITICAL/HIGH/MEDIUM/LOW), defect resolution validation before promotion, escalation paths (severity-based, time-based, pattern-based)

**Test Plan Completeness**:
- 48 test cases defined (14 deployment + 19 functionality + 5 integration + 4 health + 6 multimodal)
- 100% requirements coverage (all FR, SC, DR mapped to tests)
- 100% MCP tools coverage (all 19 tools tested)
- 100% integration points coverage (LiteLLM, Qdrant, Redis, LightRAG, MCP)
- 100% multimodal formats coverage (PDF, DOCX, PPTX, XLSX, images)
- Quality gates automated (pytest, coverage, integration, health, rollback)
- Defect management integrated (automated creation, severity assessment, escalation)

**Next Steps**: Phase 3 (Task Generation) - Create 48 test case files following test-plan.md specifications

---

**Template Version**: 2.0 (Enhanced with comprehensive quality gap resolution)
**Last Updated**: 2025-11-27
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
**Constitution Compliance**: ✅ Test-Driven Deployment (Principle II), Quality Over Speed (Principle VI)
**HX-Infrastructure Standards Compliance**: ✅ testing-requirements.md, deployment-requirements.md, document-quality-checklist.md
