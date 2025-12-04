# Task 063: Implement Backend Selection Logic

**Task ID**: hx-docling-mcp-task-063-implement-backend-selection
**Phase**: Development - Document Processing Integration
**Status**: Not Started
**Assigned To**: albert-singh (Docling Processing Specialist)
**Dependencies**: hx-docling-mcp-task-062 (Format detection configured)
**Estimated Time**: 3 hours

---

## Objective

Implement backend selection logic that maps detected document formats to appropriate Docling backends (pypdfium2, python-docx, python-pptx, openpyxl, BeautifulSoup, EasyOCR) and configures pipeline options for optimal document processing with structure preservation.

---

## Pre-Execution Validation

**CRITICAL**: Check if backend selection module already exists before proceeding:

```bash
# Check if backend selector module exists
if [ -f /opt/docling-mcp/src/docling_processor/backend_selector.py ]; then
    echo "✅ VALIDATION: Backend selector module already exists - Review implementation"
    echo "Module location: /opt/docling-mcp/src/docling_processor/backend_selector.py"
    # Check if module has core functions
    grep -q "def select_backend" /opt/docling-mcp/src/docling_processor/backend_selector.py
    if [ $? -eq 0 ]; then
        echo "✅ Core selection function 'select_backend' found - SKIP task execution"
        exit 0
    else
        echo "⚠️ Module exists but incomplete - PROCEED with implementation"
    fi
else
    echo "❌ VALIDATION: Backend selector module not found - PROCEED with task"
fi
```

**If Validation Passes (Module Already Complete)**:
- Mark task as complete with validation timestamp
- Verify module functionality with test imports
- SKIP all implementation steps below

**If Validation Fails (Module Not Found/Incomplete)**:
- Proceed with Prerequisites and Steps sections

---

## Prerequisites

- [ ] Docling library installed (hx-docling-mcp-task-061)
- [ ] Format detection module implemented (hx-docling-mcp-task-062)
- [ ] All backend dependencies installed: pypdfium2, python-docx, python-pptx, openpyxl, beautifulsoup4, easyocr
- [ ] Python virtual environment activated

---

## Steps

### 1. Implement Backend Selector Module

Create `/opt/docling-mcp/src/docling_processor/backend_selector.py`:

```python
"""
Backend Selection Module

Maps detected document formats to appropriate Docling backends and
configures pipeline options for optimal processing.

Backends:
- PDF: pypdfium2 (native text) or EasyOCR (scanned)
- DOCX: python-docx
- PPTX: python-pptx
- XLSX: openpyxl
- HTML: BeautifulSoup
- Images: EasyOCR
"""

from typing import Dict, Any, Optional
from docling.document_converter import DocumentConverter, PdfFormatOption
from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions
from docling.backend.pypdfium2_backend import PyPdfiumDocumentBackend
from docling.backend.docx_backend import DocxDocumentBackend
from docling.backend.pptx_backend import PptxDocumentBackend
from docling.backend.html_backend import HTMLDocumentBackend
from docling.pipeline.standard_pdf_pipeline import StandardPdfPipeline
from docling.pipeline.simple_pipeline import SimplePipeline

from format_detector import DocumentFormat

# Note: DocumentFormat is a Literal type alias for string values
# ("pdf", "docx", "pptx", etc.), so it's compatible with dict string keys at runtime


class BackendConfiguration:
    """
    Configuration for Docling backend and pipeline options.
    """

    def __init__(
        self,
        backend_class,
        pipeline_class,
        pipeline_options: Optional[Any] = None,
        format_option_class=None
    ):
        self.backend_class = backend_class
        self.pipeline_class = pipeline_class
        self.pipeline_options = pipeline_options
        self.format_option_class = format_option_class or PdfFormatOption


# Backend mapping for each supported format
BACKEND_MAP: Dict[str, BackendConfiguration] = {
    "pdf": BackendConfiguration(
        backend_class=PyPdfiumDocumentBackend,
        pipeline_class=StandardPdfPipeline,
        pipeline_options=PdfPipelineOptions(
            do_ocr=False,  # Disabled by default, enabled separately for scanned PDFs
            do_table_structure=True,  # Enable table extraction (FR-006)
        ),
        format_option_class=PdfFormatOption,
    ),
    "docx": BackendConfiguration(
        backend_class=DocxDocumentBackend,
        pipeline_class=SimplePipeline,
        pipeline_options=None,  # SimplePipeline has no options
    ),
    "pptx": BackendConfiguration(
        backend_class=PptxDocumentBackend,
        pipeline_class=SimplePipeline,
        pipeline_options=None,
    ),
    "xlsx": BackendConfiguration(
        backend_class=None,  # Handled by openpyxl (no custom backend class in Docling)
        pipeline_class=SimplePipeline,
        pipeline_options=None,
    ),
    "html": BackendConfiguration(
        backend_class=HTMLDocumentBackend,
        pipeline_class=SimplePipeline,
        pipeline_options=None,
    ),
    "md": BackendConfiguration(
        backend_class=None,  # Markdown handled by SimplePipeline (no dedicated backend)
        pipeline_class=SimplePipeline,
        pipeline_options=None,
    ),
    # Images processed via OCR (separate task: hx-docling-mcp-task-065)
    "png": BackendConfiguration(
        backend_class=None,  # OCR backend configured in task 065
        pipeline_class=None,
        pipeline_options=None,
    ),
    "jpg": BackendConfiguration(
        backend_class=None,
        pipeline_class=None,
        pipeline_options=None,
    ),
    "tiff": BackendConfiguration(
        backend_class=None,
        pipeline_class=None,
        pipeline_options=None,
    ),
}


def select_backend(document_format: DocumentFormat) -> BackendConfiguration:
    """
    Select appropriate Docling backend based on detected document format.

    Args:
        document_format: Detected format (from format_detector.detect_format)
            DocumentFormat is a Literal["pdf", "docx", ...] which is a string at runtime,
            so it's directly comparable with BACKEND_MAP's string keys.

    Returns:
        BackendConfiguration with backend class and pipeline options

    Raises:
        ValueError: If format is not supported or backend unavailable
    """
    # DocumentFormat Literal values are strings at runtime, so direct dict lookup works
    if document_format not in BACKEND_MAP:
        raise ValueError(
            f"Unsupported document format '{document_format}'. "
            f"Supported formats: {', '.join(BACKEND_MAP.keys())}"
        )

    config = BACKEND_MAP[document_format]

    # Validate backend is available
    if config.backend_class is None and document_format in ["png", "jpg", "tiff"]:
        # Image formats require OCR backend (configured in separate task)
        raise ValueError(
            f"OCR backend not yet configured for image format '{document_format}'. "
            "This requires hx-docling-mcp-task-065 (OCR pipeline integration)."
        )

    return config


def create_document_converter(
    document_format: DocumentFormat,
    enable_ocr: bool = False,
    enable_table_extraction: bool = True,
) -> DocumentConverter:
    """
    Create DocumentConverter with format-specific backend configuration.

    Args:
        document_format: Detected document format
        enable_ocr: Enable OCR for scanned PDFs/images (default: False)
        enable_table_extraction: Enable table structure extraction (default: True)

    Returns:
        Configured DocumentConverter instance

    Raises:
        ValueError: If format unsupported or backend unavailable
    """
    backend_config = select_backend(document_format)

    # Configure PDF pipeline options if PDF format
    if document_format == "pdf":
        pipeline_options = PdfPipelineOptions(
            do_ocr=enable_ocr,
            do_table_structure=enable_table_extraction,
        )

        format_options = {
            InputFormat.PDF: PdfFormatOption(
                pipeline_cls=backend_config.pipeline_class,
                pipeline_options=pipeline_options,
            )
        }
    else:
        # Non-PDF formats use SimplePipeline (no options)
        # Map string format to InputFormat enum
        input_format_map = {
            "docx": InputFormat.DOCX,
            "pptx": InputFormat.PPTX,
            "xlsx": InputFormat.XLSX,
            "html": InputFormat.HTML,
            "md": InputFormat.MD,
        }

        if document_format not in input_format_map:
            raise ValueError(
                f"Format '{document_format}' not yet supported in converter creation. "
                f"Supported: {', '.join(input_format_map.keys())}"
            )

        input_format = input_format_map[document_format]
        format_options = {
            input_format: PdfFormatOption(  # Use PdfFormatOption as base
                pipeline_cls=backend_config.pipeline_class,
            )
        }

    # Create and return DocumentConverter
    converter = DocumentConverter(format_options=format_options)
    return converter


def get_backend_info(document_format: DocumentFormat) -> Dict[str, Any]:
    """
    Get information about backend configuration for a given format.

    Useful for diagnostics and logging.

    Args:
        document_format: Document format identifier

    Returns:
        Dictionary with backend details (class name, pipeline, options)
    """
    try:
        config = select_backend(document_format)

        return {
            "format": document_format,
            "backend_class": config.backend_class.__name__ if config.backend_class else "None",
            "pipeline_class": config.pipeline_class.__name__ if config.pipeline_class else "None",
            "has_options": config.pipeline_options is not None,
            "options": str(config.pipeline_options) if config.pipeline_options else "None",
        }
    except ValueError as e:
        return {
            "format": document_format,
            "error": str(e),
        }
```

### 2. Create Unit Tests for Backend Selection

Create `/opt/docling-mcp/src/docling_processor/test_backend_selector.py`:

```python
"""
Unit tests for backend selection module.
"""

import pytest
from backend_selector import select_backend, create_document_converter, get_backend_info
from docling.backend.pypdfium2_backend import PyPdfiumDocumentBackend
from docling.backend.docx_backend import DocxDocumentBackend


def test_select_backend_pdf():
    """Test backend selection for PDF format."""
    config = select_backend("pdf")
    assert config.backend_class == PyPdfiumDocumentBackend
    assert config.pipeline_options is not None
    assert config.pipeline_options.do_table_structure == True


def test_select_backend_docx():
    """Test backend selection for DOCX format."""
    config = select_backend("docx")
    assert config.backend_class == DocxDocumentBackend


def test_select_backend_unsupported():
    """Test error handling for unsupported formats."""
    with pytest.raises(ValueError, match="Unsupported document format"):
        select_backend("xyz")


def test_create_document_converter_pdf():
    """Test DocumentConverter creation for PDF."""
    converter = create_document_converter("pdf", enable_ocr=False)
    assert converter is not None


def test_create_document_converter_docx():
    """Test DocumentConverter creation for DOCX."""
    converter = create_document_converter("docx")
    assert converter is not None


def test_get_backend_info_pdf():
    """Test backend info retrieval for PDF."""
    info = get_backend_info("pdf")
    assert info["format"] == "pdf"
    assert info["backend_class"] == "PyPdfiumDocumentBackend"
    assert info["has_options"] == True


def test_create_converter_with_ocr():
    """Test DocumentConverter creation with OCR enabled."""
    converter = create_document_converter("pdf", enable_ocr=True)
    assert converter is not None
```

### 3. Verify Backend Selection Module

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test imports
cd /opt/docling-mcp/src/docling_processor
python3 -c "from backend_selector import select_backend, create_document_converter; print('✅ Backend selector imports successful')"

# Test backend selection
python3 << 'EOF'
from backend_selector import select_backend, get_backend_info

# Test PDF backend
pdf_config = select_backend("pdf")
print(f"PDF backend: {pdf_config.backend_class.__name__}")
print(f"PDF pipeline: {pdf_config.pipeline_class.__name__}")
print(f"Table extraction enabled: {pdf_config.pipeline_options.do_table_structure}")

# Test DOCX backend
docx_config = select_backend("docx")
print(f"\nDOCX backend: {docx_config.backend_class.__name__}")

# Get backend info
print(f"\nBackend info for PDF: {get_backend_info('pdf')}")
EOF
```

---

## Verification

### Success Criteria

- [ ] Backend selector module created at `/opt/docling-mcp/src/docling_processor/backend_selector.py`
- [ ] Backend mapping covers all supported formats: PDF, DOCX, PPTX, XLSX, HTML
- [ ] `select_backend()` function returns correct backend for each format
- [ ] `create_document_converter()` function creates valid DocumentConverter instances
- [ ] PDF pipeline options configured with table extraction enabled (FR-006)
- [ ] OCR disabled by default for PDF (enabled separately for scanned documents)
- [ ] Error handling for unsupported formats implemented
- [ ] Module imports without errors
- [ ] Unit tests pass (if executed)

### Validation Commands

```bash
source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp/src/docling_processor

python3 << 'EOF'
from backend_selector import select_backend, create_document_converter

# Test backend selection for all formats
formats = ["pdf", "docx", "pptx", "xlsx", "html"]
for fmt in formats:
    try:
        config = select_backend(fmt)
        print(f"✅ {fmt.upper()}: {config.backend_class.__name__ if config.backend_class else 'SimplePipeline'}")
    except Exception as e:
        print(f"❌ {fmt.upper()}: {e}")

# Test DocumentConverter creation
converter = create_document_converter("pdf")
print(f"\n✅ DocumentConverter created successfully")
EOF
```

### Expected Output

```
✅ PDF: PyPdfiumDocumentBackend
✅ DOCX: DocxDocumentBackend
✅ PPTX: PptxDocumentBackend
✅ XLSX: SimplePipeline
✅ HTML: HTMLDocumentBackend

✅ DocumentConverter created successfully
```

---

## Rollback

If backend selection implementation fails:

```bash
# Remove backend selector module
rm -f /opt/docling-mcp/src/docling_processor/backend_selector.py
rm -f /opt/docling-mcp/src/docling_processor/test_backend_selector.py
```

---

## Notes

### Backend Architecture

**Format → Backend Mapping**:
- **PDF**: PyPdfiumDocumentBackend (native text extraction) + StandardPdfPipeline
- **DOCX**: DocxDocumentBackend (python-docx library)
- **PPTX**: PptxDocumentBackend (python-pptx library)
- **XLSX**: Handled by openpyxl (no custom backend, SimplePipeline)
- **HTML**: HTMLDocumentBackend (BeautifulSoup + lxml)
- **Images** (PNG, JPG, TIFF): OCR backend (configured in Task 065)

### Pipeline Options

**PDF Pipeline Options** (PdfPipelineOptions):
- `do_ocr`: Enable OCR for scanned PDFs (default: False, enabled in Task 065)
- `do_table_structure`: Enable table extraction (default: True per FR-006)

**SimplePipeline** (DOCX, PPTX, XLSX, HTML):
- No configurable options
- Handles structure preservation automatically

### Structure Preservation Strategy

All backends preserve document structure (FR-006):
- **Headings**: H1-H6 hierarchy detection
- **Tables**: Cell structure, merged cells, headers
- **Lists**: Ordered/unordered with nesting
- **Code Blocks**: Language detection and syntax preservation
- **Images**: Extraction with captions

Implementation of structure preservation is in Task 064.

### OCR Integration

- OCR disabled by default for PDF (performance)
- Enabled on-demand for scanned PDFs or via explicit flag
- Image formats (PNG, JPG, TIFF) always use OCR
- OCR pipeline configuration in Task 065

### Error Handling

- **Unsupported Format**: Raise ValueError with supported format list
- **Backend Unavailable**: Raise ValueError with installation instructions
- **Pipeline Failure**: Log error and return MCP error response (handled in MCP tool layer)

---

## Related Tasks

**Upstream Dependencies:**
- hx-docling-mcp-task-061: Docling library installation
- hx-docling-mcp-task-062: Format detection implementation

**Downstream Dependencies:**
- hx-docling-mcp-task-064: Structure preservation implementation
- hx-docling-mcp-task-065: OCR pipeline integration
- hx-docling-mcp-task-066: DoclingDocument schema implementation
- hx-docling-mcp-task-067: MCP tool integration

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Agent**: albert-singh (Docling Processing Specialist)
