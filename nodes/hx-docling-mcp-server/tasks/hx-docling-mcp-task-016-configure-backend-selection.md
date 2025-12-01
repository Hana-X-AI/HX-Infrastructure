# Task 016: Configure Document Processing Backend Selection

**Task ID**: hx-docling-mcp-task-016
**Component**: Docling Document Processing (albert-singh)
**Category**: Configuration
**Priority**: HIGH (blocking for document conversion)
**Estimated Effort**: 2-3 hours
**Status**: NOT_STARTED

---

## Objective

Implement intelligent backend selection logic that routes documents to optimal processing backends based on format type, document characteristics, and performance/accuracy trade-offs.

---

## Prerequisites

- [x] Task 010: Docling library installed with all backends (pypdfium2, python-docx, python-pptx, openpyxl, beautifulsoup4, PIL/Tesseract)
- [x] Task 011: Format detection pipeline configured
- [x] System packages: tesseract-ocr, poppler-utils

---

## Technical Context

**From albert-docling-processing.md** (Section 2: Backend Selection Strategy, lines 259-378):
- **PDF Backends**: pypdfium2 (primary), pdfplumber (tables), OCR pipeline (scanned)
- **Backend Selection Criteria**: Speed, accuracy, document characteristics
- **Performance Trade-offs**: pypdfium2 (~10 pages/sec) vs OCR (~2-6 pages/min)
- **Automatic Fallback**: If primary backend fails, try fallback backends

**From Configuration Spec** (configuration-spec.md lines 800-806):
- DOCLING_OCR_ENABLED: true
- DOCLING_LAYOUT_ANALYSIS: true
- DOCLING_MAX_FILE_SIZE_MB: 100

---

## Implementation Steps

### Step 1: Create Backend Selection Module

**File**: `/opt/docling-mcp/application/docling_mcp/processors/backend_selector.py`

```python
#!/usr/bin/env python3
"""
Backend selection module for optimal document processing.

Selects appropriate backend based on:
1. Document format (PDF, DOCX, PPTX, XLSX, HTML, images)
2. Document characteristics (searchable text, tables, images)
3. Performance/accuracy trade-offs
4. Automatic fallback on failure
"""

import logging
import os
from typing import Dict, Optional, Any
from enum import Enum

logger = logging.getLogger(__name__)


class Backend(Enum):
    """Available document processing backends."""
    # PDF backends
    PYPDFIUM2 = "pypdfium2"          # Fast PDF processing
    PDFPLUMBER = "pdfplumber"        # Table-heavy PDFs
    OCR_PIPELINE = "ocr_pipeline"    # Scanned PDFs, images

    # Office backends
    PYTHON_DOCX = "python-docx"      # DOCX
    PYTHON_PPTX = "python-pptx"      # PPTX
    OPENPYXL = "openpyxl"            # XLSX

    # Web/text backends
    BEAUTIFULSOUP4 = "beautifulsoup4"  # HTML/XML
    MARKDOWN = "markdown"              # Markdown

    # Image/OCR backend
    TESSERACT_OCR = "tesseract-ocr"  # Images with OCR


class BackendMetadata:
    """Metadata for backend selection."""

    def __init__(
        self,
        backend: Backend,
        priority: int,
        use_cases: list[str],
        strengths: str,
        limitations: str,
        performance: str
    ):
        self.backend = backend
        self.priority = priority  # 1 = primary, 2 = fallback, 3 = last resort
        self.use_cases = use_cases
        self.strengths = strengths
        self.limitations = limitations
        self.performance = performance


# ============================================================================
# Backend Metadata Registry
# ============================================================================

PDF_BACKENDS = {
    Backend.PYPDFIUM2: BackendMetadata(
        backend=Backend.PYPDFIUM2,
        priority=1,  # Primary backend
        use_cases=["native PDF", "vector graphics", "searchable text"],
        strengths="Fast, accurate text extraction, preserves layout",
        limitations="Fails on encrypted/corrupted PDFs, no OCR",
        performance="~10 pages/second for native PDFs"
    ),
    Backend.PDFPLUMBER: BackendMetadata(
        backend=Backend.PDFPLUMBER,
        priority=2,  # Fallback for table-heavy PDFs
        use_cases=["complex tables", "precise layout extraction"],
        strengths="Superior table detection, cell-level extraction",
        limitations="Slower than pypdfium2, memory-intensive",
        performance="~2 pages/second for table extraction"
    ),
    Backend.OCR_PIPELINE: BackendMetadata(
        backend=Backend.OCR_PIPELINE,
        priority=3,  # Fallback for scanned/image PDFs
        use_cases=["scanned PDFs", "image-only pages", "non-searchable text"],
        strengths="Handles non-searchable PDFs via OCR",
        limitations="Slow (10-30s per page), accuracy varies by quality",
        performance="~2-6 pages/minute depending on DPI"
    )
}

OFFICE_BACKENDS = {
    "docx": Backend.PYTHON_DOCX,
    "pptx": Backend.PYTHON_PPTX,
    "xlsx": Backend.OPENPYXL
}

WEB_BACKENDS = {
    "html": Backend.BEAUTIFULSOUP4,
    "xhtml": Backend.BEAUTIFULSOUP4,
    "xml": Backend.BEAUTIFULSOUP4
}

IMAGE_BACKENDS = {
    "png": Backend.TESSERACT_OCR,
    "jpeg": Backend.TESSERACT_OCR,
    "jpg": Backend.TESSERACT_OCR,
    "tiff": Backend.TESSERACT_OCR
}


# ============================================================================
# Backend Selection Logic
# ============================================================================

def select_pdf_backend(file_path: str, prefer_accuracy: bool = False) -> Backend:
    """
    Select optimal PDF backend based on document characteristics.

    Selection Strategy:
    1. Try pypdfium2 first (fastest)
    2. If no text layer detected → OCR pipeline
    3. If pypdfium2 fails → try pdfplumber
    4. If all fail → OCR pipeline (last resort)

    Args:
        file_path: Path to PDF file
        prefer_accuracy: If True, prefer pdfplumber for table extraction

    Returns:
        Selected Backend enum
    """
    import pypdfium2 as pdfium

    # 1. Try pypdfium2 first (fastest)
    try:
        pdf = pdfium.PdfDocument(file_path)
        page = pdf[0]

        # Check if PDF is searchable (has text layer)
        text_page = page.get_textpage()
        text_content = text_page.get_text_range()

        page.close()
        pdf.close()

        # If text content exists and is substantial, use pypdfium2
        if text_content and len(text_content.strip()) > 50:
            # If prefer_accuracy and document has tables, use pdfplumber
            if prefer_accuracy:
                return Backend.PDFPLUMBER
            return Backend.PYPDFIUM2
        else:
            # No text layer detected, likely scanned PDF
            logger.info("PDF appears to be scanned (no text layer), using OCR pipeline")
            return Backend.OCR_PIPELINE

    except Exception as e:
        # pypdfium2 failed (encryption, corruption), try pdfplumber
        logger.warning(f"pypdfium2 failed: {e}, trying pdfplumber")

        try:
            import pdfplumber
            with pdfplumber.open(file_path) as pdf:
                if len(pdf.pages) > 0:
                    return Backend.PDFPLUMBER
        except Exception as e2:
            logger.warning(f"pdfplumber failed: {e2}, falling back to OCR pipeline")
            return Backend.OCR_PIPELINE

    return Backend.OCR_PIPELINE


def select_backend(
    format: str,
    file_path: str,
    options: Dict[str, Any] = None
) -> Backend:
    """
    Select appropriate backend for document format.

    Args:
        format: Detected document format (pdf, docx, pptx, xlsx, html, png, etc.)
        file_path: Path to document file
        options: Optional backend selection options

    Returns:
        Selected Backend enum

    Raises:
        ValueError: If no backend available for format
    """
    options = options or {}

    # PDF backend selection (requires analysis)
    if format == 'pdf':
        prefer_accuracy = options.get('prefer_accuracy', False)
        return select_pdf_backend(file_path, prefer_accuracy)

    # Office formats
    if format in OFFICE_BACKENDS:
        return OFFICE_BACKENDS[format]

    # Web/HTML formats
    if format in WEB_BACKENDS:
        return WEB_BACKENDS[format]

    # Image formats (OCR required)
    if format in IMAGE_BACKENDS:
        return IMAGE_BACKENDS[format]

    # Markdown/text formats
    if format in ['markdown', 'txt']:
        return Backend.MARKDOWN

    # Unsupported format
    raise ValueError(f"No backend available for format: {format}")


def get_backend_config(backend: Backend) -> Dict[str, Any]:
    """
    Get configuration for specific backend.

    Args:
        backend: Backend enum

    Returns:
        Backend configuration dictionary
    """
    configs = {
        Backend.PYPDFIUM2: {
            "name": "pypdfium2",
            "class": "PyPDFium2Backend",
            "ocr_enabled": False,
            "layout_analysis": True,
            "extract_images": True
        },
        Backend.PDFPLUMBER: {
            "name": "pdfplumber",
            "class": "PDFPlumberBackend",
            "table_extraction": True,
            "layout_analysis": True
        },
        Backend.OCR_PIPELINE: {
            "name": "ocr_pipeline",
            "class": "OCRPipelineBackend",
            "ocr_enabled": True,
            "languages": ["eng"],  # English default
            "preprocessing": True  # Image preprocessing enabled
        },
        Backend.PYTHON_DOCX: {
            "name": "python-docx",
            "class": "DOCXBackend",
            "extract_styles": True,
            "extract_tables": True,
            "extract_images": True
        },
        Backend.PYTHON_PPTX: {
            "name": "python-pptx",
            "class": "PPTXBackend",
            "extract_slides": True,
            "extract_shapes": True,
            "extract_notes": True
        },
        Backend.OPENPYXL: {
            "name": "openpyxl",
            "class": "XLSXBackend",
            "extract_formulas": True,
            "extract_sheets": True
        },
        Backend.BEAUTIFULSOUP4: {
            "name": "beautifulsoup4",
            "class": "HTMLBackend",
            "parser": "lxml",  # Use lxml parser for speed
            "extract_links": True,
            "extract_images": True
        },
        Backend.TESSERACT_OCR: {
            "name": "tesseract-ocr",
            "class": "TesseractBackend",
            "ocr_enabled": True,
            "languages": ["eng"],
            "preprocessing": True
        },
        Backend.MARKDOWN: {
            "name": "markdown",
            "class": "MarkdownBackend",
            "parse_gfm": True  # GitHub Flavored Markdown
        }
    }

    return configs.get(backend, {})


def get_backend_metadata(backend: Backend) -> Optional[BackendMetadata]:
    """
    Get metadata for specific backend.

    Args:
        backend: Backend enum

    Returns:
        BackendMetadata or None if backend has no metadata defined
    """
    # Check PDF backends (have detailed metadata)
    if backend in PDF_BACKENDS:
        return PDF_BACKENDS[backend]

    # Note: Office, Web, and Image backends currently lack detailed metadata.
    # This is intentional as they have simpler, deterministic processing without
    # the complex trade-offs seen in PDF backends. Future enhancement could add
    # metadata registries for these backend types if performance profiling is needed.
    return None


# ============================================================================
# Backend Fallback Logic
# ============================================================================

def get_fallback_backends(primary_backend: Backend) -> list[Backend]:
    """
    Get ordered list of fallback backends for primary backend.

    Args:
        primary_backend: Primary backend that failed

    Returns:
        List of fallback backends to try (in order)
    """
    fallbacks = {
        Backend.PYPDFIUM2: [Backend.PDFPLUMBER, Backend.OCR_PIPELINE],
        Backend.PDFPLUMBER: [Backend.PYPDFIUM2, Backend.OCR_PIPELINE],
        Backend.OCR_PIPELINE: [],  # No fallbacks for OCR (last resort)
        Backend.PYTHON_DOCX: [],   # No fallbacks for Office formats
        Backend.PYTHON_PPTX: [],
        Backend.OPENPYXL: [],
        Backend.BEAUTIFULSOUP4: [],
        Backend.TESSERACT_OCR: [],
        Backend.MARKDOWN: []
    }

    return fallbacks.get(primary_backend, [])
```

---

### Step 2: Create Test Fixtures

**File**: `/opt/docling-mcp/tests/conftest.py`

```python
#!/usr/bin/env python3
"""
Pytest fixtures for backend selection tests.
"""

import pytest
from pathlib import Path
from reportlab.pdfgen import canvas
from PIL import Image
import io


@pytest.fixture
def sample_searchable_pdf(tmp_path):
    """Create a sample searchable PDF for testing."""
    pdf_path = tmp_path / "searchable.pdf"

    # Create PDF with text layer using reportlab
    c = canvas.Canvas(str(pdf_path))
    c.drawString(100, 750, "This is a searchable PDF with substantial text content.")
    c.drawString(100, 730, "It has multiple lines of text to ensure pypdfium2 detection works.")
    c.drawString(100, 710, "Backend selection should choose pypdfium2 for this document.")
    c.save()

    return str(pdf_path)


@pytest.fixture
def sample_scanned_pdf(tmp_path):
    """Create a sample scanned PDF (image-only) for testing."""
    pdf_path = tmp_path / "scanned.pdf"

    # Create blank image to simulate scanned page
    img = Image.new('RGB', (595, 842), color='white')
    img.save(pdf_path, 'PDF')

    return str(pdf_path)
```

---

### Step 3: Create Unit Tests for Backend Selection

**File**: `/opt/docling-mcp/tests/test_backend_selection.py`

```python
#!/usr/bin/env python3
"""
Unit tests for backend selection logic.
"""

import pytest
from docling_mcp.processors.backend_selector import (
    Backend,
    select_backend,
    select_pdf_backend,
    get_backend_config,
    get_fallback_backends
)


class TestPDFBackendSelection:
    """Test PDF backend selection logic."""

    def test_pypdfium2_for_searchable_pdf(self, sample_searchable_pdf):
        """Test pypdfium2 selected for searchable PDF."""
        backend = select_pdf_backend(sample_searchable_pdf)
        assert backend == Backend.PYPDFIUM2

    def test_ocr_pipeline_for_scanned_pdf(self, sample_scanned_pdf):
        """Test OCR pipeline selected for scanned PDF."""
        backend = select_pdf_backend(sample_scanned_pdf)
        assert backend == Backend.OCR_PIPELINE

    def test_pdfplumber_with_prefer_accuracy(self, sample_searchable_pdf):
        """Test pdfplumber selected when prefer_accuracy=True."""
        backend = select_pdf_backend(sample_searchable_pdf, prefer_accuracy=True)
        assert backend == Backend.PDFPLUMBER


class TestFormatBackendMapping:
    """Test format to backend mapping."""

    @pytest.mark.parametrize("format,expected_backend", [
        ("docx", Backend.PYTHON_DOCX),
        ("pptx", Backend.PYTHON_PPTX),
        ("xlsx", Backend.OPENPYXL),
        ("html", Backend.BEAUTIFULSOUP4),
        ("png", Backend.TESSERACT_OCR),
        ("jpeg", Backend.TESSERACT_OCR)
    ])
    def test_format_backend_selection(self, format, expected_backend, tmp_path):
        """Test correct backend selected for each format."""
        # Create dummy file
        file = tmp_path / f"test.{format}"
        file.write_text("dummy")

        backend = select_backend(format, str(file))
        assert backend == expected_backend


class TestBackendConfiguration:
    """Test backend configuration retrieval."""

    def test_pypdfium2_config(self):
        """Test pypdfium2 backend configuration."""
        config = get_backend_config(Backend.PYPDFIUM2)
        assert config["name"] == "pypdfium2"
        assert config["ocr_enabled"] is False
        assert config["layout_analysis"] is True

    def test_ocr_pipeline_config(self):
        """Test OCR pipeline backend configuration."""
        config = get_backend_config(Backend.OCR_PIPELINE)
        assert config["name"] == "ocr_pipeline"
        assert config["ocr_enabled"] is True
        assert config["preprocessing"] is True


class TestFallbackLogic:
    """Test backend fallback logic."""

    def test_pypdfium2_fallbacks(self):
        """Test fallback backends for pypdfium2."""
        fallbacks = get_fallback_backends(Backend.PYPDFIUM2)
        assert fallbacks == [Backend.PDFPLUMBER, Backend.OCR_PIPELINE]

    def test_pdfplumber_fallbacks(self):
        """Test fallback backends for pdfplumber."""
        fallbacks = get_fallback_backends(Backend.PDFPLUMBER)
        assert fallbacks == [Backend.PYPDFIUM2, Backend.OCR_PIPELINE]

    def test_ocr_no_fallbacks(self):
        """Test OCR pipeline has no fallbacks (last resort)."""
        fallbacks = get_fallback_backends(Backend.OCR_PIPELINE)
        assert fallbacks == []


class TestErrorHandling:
    """Test error handling for unsupported formats."""

    def test_unsupported_format_raises_error(self, tmp_path):
        """Test ValueError raised for unsupported format."""
        # Create dummy file with unsupported extension
        file = tmp_path / "test.xyz"
        file.write_text("dummy")

        with pytest.raises(ValueError, match="No backend available for format: xyz"):
            select_backend("xyz", str(file))

    def test_unsupported_binary_format(self, tmp_path):
        """Test ValueError raised for unsupported binary format."""
        file = tmp_path / "test.bin"
        file.write_bytes(b"\x00\x01\x02\x03")

        with pytest.raises(ValueError, match="No backend available for format"):
            select_backend("bin", str(file))
```

---

### Step 4: Integration with Docling Processor

**File**: `/opt/docling-mcp/application/docling_mcp/processors/docling_processor.py` (update)

```python
import logging
from .backend_selector import select_backend, get_backend_config, get_fallback_backends, Backend

logger = logging.getLogger(__name__)


class DoclingProcessor:
    """Document processor with intelligent backend selection."""

    async def convert_document(self, source: str, format: str, options: dict = None):
        """
        Convert document using optimal backend.

        Args:
            source: File path or URL
            format: Detected document format
            options: Conversion options

        Returns:
            DoclingDocument

        Raises:
            ValueError: If all backends fail
        """
        # Select primary backend
        primary_backend = select_backend(format, source, options)
        backend_config = get_backend_config(primary_backend)

        # Try primary backend
        try:
            doc = await self._convert_with_backend(source, primary_backend, backend_config)
            return doc
        except Exception as e:
            logger.warning(f"Primary backend {primary_backend} failed: {e}", exc_info=True)

            # Try fallback backends
            fallbacks = get_fallback_backends(primary_backend)
            for fallback_backend in fallbacks:
                try:
                    logger.info(f"Trying fallback backend: {fallback_backend}")
                    fallback_config = get_backend_config(fallback_backend)
                    doc = await self._convert_with_backend(source, fallback_backend, fallback_config)
                    return doc
                except Exception as fallback_error:
                    logger.error(f"Fallback backend {fallback_backend} failed: {fallback_error}", exc_info=True)
                    continue

            # All backends failed
            raise ValueError(f"All backends failed for format {format}. Source: {source}")
```

---

### Step 5: Validation and Testing

**Command**: Run backend selection tests
```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Run unit tests
pytest tests/test_backend_selection.py -v

# Run with coverage
pytest tests/test_backend_selection.py --cov=docling_mcp.processors.backend_selector --cov-report=term

# Expected output:
# tests/test_backend_selection.py::TestPDFBackendSelection::test_pypdfium2_for_searchable_pdf PASSED
# tests/test_backend_selection.py::TestPDFBackendSelection::test_ocr_pipeline_for_scanned_pdf PASSED
# tests/test_backend_selection.py::TestFormatBackendMapping::test_format_backend_selection PASSED
# tests/test_backend_selection.py::TestBackendConfiguration::test_pypdfium2_config PASSED
# tests/test_backend_selection.py::TestFallbackLogic::test_pypdfium2_fallbacks PASSED
#
# Coverage: 95%+
```

---

## Success Criteria

- [ ] Backend selection module created (`backend_selector.py`)
- [ ] PDF backend selection implements automatic fallback (pypdfium2 → pdfplumber → OCR)
- [ ] Office format backends mapped (DOCX, PPTX, XLSX)
- [ ] HTML/image backend support implemented
- [ ] Backend configuration retrieval working
- [ ] Fallback logic implemented and tested
- [ ] Unit tests created and passing (≥95% coverage)
- [ ] Integration with DoclingProcessor complete

---

## Rollback Procedure

If backend selection fails:
```bash
# Remove backend selection module
rm /opt/docling-mcp/application/docling_mcp/processors/backend_selector.py

# Remove tests
rm /opt/docling-mcp/tests/test_backend_selection.py

# Revert to hardcoded backend selection
git checkout /opt/docling-mcp/application/docling_mcp/processors/docling_processor.py
```

---

## Dependencies

**Depends On**:
- Task 010: Docling library installed
- Task 011: Format detection configured

**Blocks**:
- Task 013: Structure preservation implementation
- Task 014: OCR integration

---

## Notes

**From albert-docling-processing.md** (lines 259-378):
- Backend selection based on performance/accuracy trade-offs
- Automatic fallback increases conversion success rate
- OCR pipeline is last resort for difficult PDFs

**Performance Considerations**:
- pypdfium2: ~10 pages/second (fastest)
- pdfplumber: ~2 pages/second (accurate tables)
- OCR: ~2-6 pages/minute (slowest but handles scanned)

---

**Task Owner**: albert-singh (Docling Document Processing SME)
**Created**: 2025-11-27
**Updated**: 2025-11-27
