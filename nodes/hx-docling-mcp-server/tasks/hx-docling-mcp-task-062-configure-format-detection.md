# Task 062: Configure Format Detection Pipeline

**Task ID**: hx-docling-mcp-task-062-configure-format-detection
**Phase**: Development - Document Processing Integration
**Status**: Not Started
**Assigned To**: albert-singh (Docling Processing Specialist)
**Dependencies**: hx-docling-mcp-task-061 (Docling library installed)
**Estimated Time**: 2 hours

---

## Objective

Implement automatic document format detection using magic number analysis, MIME type detection, and file extension fallback to enable seamless multi-format document processing without requiring manual format specification from MCP clients.

---

## Pre-Execution Validation

**CRITICAL**: Check if format detection module already exists before proceeding:

```bash
# Check if format detection module exists
if [ -f /opt/docling-mcp/src/docling_processor/format_detector.py ]; then
    echo "✅ VALIDATION: Format detection module already exists - Review implementation"
    echo "Module location: /opt/docling-mcp/src/docling_processor/format_detector.py"
    # Check if module has core functions
    grep -q "def detect_format" /opt/docling-mcp/src/docling_processor/format_detector.py
    if [ $? -eq 0 ]; then
        echo "✅ Core detection function 'detect_format' found - SKIP task execution"
        exit 0
    else
        echo "⚠️ Module exists but incomplete - PROCEED with implementation"
    fi
else
    echo "❌ VALIDATION: Format detection module not found - PROCEED with task"
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
- [ ] Directory structure created: `/opt/docling-mcp/src/docling_processor/`
- [ ] libmagic1 system package installed (for MIME type detection)
- [ ] Python virtual environment activated

---

## Steps

### 1. Create Format Detection Module

```bash
# Create module directory if not exists
mkdir -p /opt/docling-mcp/src/docling_processor

# Create __init__.py for package
touch /opt/docling-mcp/src/docling_processor/__init__.py
```

### 2. Implement Format Detector

Create `/opt/docling-mcp/src/docling_processor/format_detector.py`:

```python
"""
Document Format Detection Module

Implements automatic format detection using magic number analysis,
MIME type detection, and file extension fallback for Docling MCP Server.

Supported Formats: PDF, DOCX, PPTX, XLSX, HTML, Markdown, TXT, EPUB, RTF, PNG, JPG, TIFF
"""

import magic
import mimetypes
from pathlib import Path
from typing import Optional, Literal
from pydantic import Field
from typing_extensions import Annotated

# Define supported document formats (matches FR-005 specification)
DocumentFormat = Literal[
    "pdf", "docx", "pptx", "xlsx", "html", "md", "txt",
    "epub", "rtf", "png", "jpg", "tiff"
]


# MIME type to format mapping
MIME_TYPE_MAP = {
    # PDF
    "application/pdf": "pdf",

    # Office formats
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",

    # Web formats
    "text/html": "html",
    "text/markdown": "md",
    "text/plain": "txt",

    # Other document formats
    "application/epub+zip": "epub",
    "application/rtf": "rtf",
    "text/rtf": "rtf",

    # Image formats
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/tiff": "tiff",
}

# Extension to format mapping (fallback)
EXTENSION_MAP = {
    ".pdf": "pdf",
    ".docx": "docx",
    ".pptx": "pptx",
    ".xlsx": "xlsx",
    ".html": "html",
    ".htm": "html",
    ".md": "md",
    ".markdown": "md",
    ".txt": "txt",
    ".epub": "epub",
    ".rtf": "rtf",
    ".png": "png",
    ".jpg": "jpg",
    ".jpeg": "jpg",
    ".tiff": "tiff",
    ".tif": "tiff",
}


def detect_format_from_mime(file_path: Path) -> Optional[DocumentFormat]:
    """
    Detect document format using magic number (MIME type) analysis.

    This is the most reliable method as it inspects actual file content,
    not just the filename extension.

    Args:
        file_path: Path to document file

    Returns:
        Detected format or None if unrecognized
    """
    try:
        mime = magic.Magic(mime=True)
        mime_type = mime.from_file(str(file_path))

        detected_format = MIME_TYPE_MAP.get(mime_type)
        if detected_format:
            return detected_format

        return None

    except Exception as e:
        # Log error but don't fail - fallback to extension detection
        print(f"MIME detection failed for {file_path}: {e}")
        return None


def detect_format_from_extension(file_path: Path) -> Optional[DocumentFormat]:
    """
    Detect document format from file extension (fallback method).

    Used when MIME type detection fails or is unavailable.

    Args:
        file_path: Path to document file

    Returns:
        Detected format or None if unrecognized
    """
    extension = file_path.suffix.lower()
    return EXTENSION_MAP.get(extension)


def detect_format(file_path: str, hint: Optional[str] = None) -> DocumentFormat:
    """
    Automatically detect document format using multi-stage detection pipeline.

    Detection Order:
    1. Use hint if provided and valid (FR-009 allows manual override)
    2. Magic number analysis (most reliable)
    3. File extension fallback
    4. Raise error if format cannot be determined

    Args:
        file_path: Path to document file (file://, http://, or absolute path)
        hint: Optional format hint from user (e.g., "pdf", "docx")

    Returns:
        Detected document format

    Raises:
        ValueError: If format cannot be detected or is unsupported
    """
    # Handle file:// URLs
    if file_path.startswith("file://"):
        file_path = file_path[7:]  # Remove file:// prefix

    path = Path(file_path)

    # Stage 1: Use hint if provided
    if hint:
        hint_lower = hint.lower().strip()
        if hint_lower in EXTENSION_MAP.values():
            return hint_lower
        else:
            raise ValueError(
                f"Invalid format hint '{hint}'. "
                f"Supported formats: {', '.join(sorted(set(EXTENSION_MAP.values())))}"
            )

    # Stage 2: Magic number analysis (MIME type)
    if path.exists():
        detected = detect_format_from_mime(path)
        if detected:
            return detected

    # Stage 3: File extension fallback
    detected = detect_format_from_extension(path)
    if detected:
        return detected

    # Stage 4: Format unknown - raise error
    raise ValueError(
        f"Unable to detect format for '{file_path}'. "
        f"File extension '{path.suffix}' is not recognized. "
        f"Supported formats: {', '.join(sorted(set(EXTENSION_MAP.values())))}"
    )


def is_format_supported(format_str: str) -> bool:
    """
    Check if a format string is supported by Docling.

    Args:
        format_str: Format identifier (e.g., "pdf", "docx")

    Returns:
        True if supported, False otherwise
    """
    return format_str.lower() in EXTENSION_MAP.values()


def get_supported_formats() -> list[str]:
    """
    Get list of all supported document formats.

    Returns:
        Sorted list of format identifiers
    """
    return sorted(set(EXTENSION_MAP.values()))
```

### 3. Create Unit Tests for Format Detection

Create `/opt/docling-mcp/src/docling_processor/test_format_detector.py`:

```python
"""
Unit tests for format detection module.
"""

import pytest
from pathlib import Path
from src.docling_processor.format_detector import detect_format, is_format_supported, get_supported_formats


def test_detect_format_from_extension():
    """Test format detection from file extension."""
    assert detect_format("/path/to/document.pdf") == "pdf"
    assert detect_format("/path/to/document.docx") == "docx"
    assert detect_format("/path/to/document.pptx") == "pptx"
    assert detect_format("/path/to/document.xlsx") == "xlsx"
    assert detect_format("/path/to/page.html") == "html"
    assert detect_format("/path/to/readme.md") == "md"
    assert detect_format("/path/to/image.png") == "png"


def test_detect_format_with_hint():
    """Test format detection with manual hint override."""
    assert detect_format("/path/to/file.unknown", hint="pdf") == "pdf"
    assert detect_format("/path/to/file.txt", hint="md") == "md"


def test_detect_format_unsupported():
    """Test error handling for unsupported formats."""
    with pytest.raises(ValueError, match="Unable to detect format"):
        detect_format("/path/to/file.xyz")


def test_detect_format_invalid_hint():
    """Test error handling for invalid format hints."""
    with pytest.raises(ValueError, match="Invalid format hint"):
        detect_format("/path/to/file.pdf", hint="invalid_format")


def test_is_format_supported():
    """Test format support checking."""
    assert is_format_supported("pdf") == True
    assert is_format_supported("docx") == True
    assert is_format_supported("xyz") == False


def test_get_supported_formats():
    """Test retrieval of supported format list."""
    formats = get_supported_formats()
    assert "pdf" in formats
    assert "docx" in formats
    assert len(formats) >= 12  # At least 12 supported formats per FR-005


def test_detect_format_from_mime_type():
    """Test format detection from file content (MIME type) - PRIMARY MECHANISM."""
    # Note: This test requires detect_format_from_content() function
    # PDF file signature
    pdf_content = b"%PDF-1.4\n"
    assert detect_format_from_content(pdf_content) == "pdf"

    # DOCX file signature (ZIP with specific structure)
    docx_content = b"PK\x03\x04"  # ZIP signature
    # Note: Full DOCX detection requires checking for [Content_Types].xml

    # HTML content
    html_content = b"<!DOCTYPE html>"
    assert detect_format_from_content(html_content) == "html"


def test_detect_format_file_url_handling():
    """Test format detection with file:// URL prefix removal."""
    assert detect_format("file:///path/to/document.pdf") == "pdf"
    assert detect_format("file:///C:/Users/docs/report.docx") == "docx"
    assert detect_format("file://localhost/tmp/data.xlsx") == "xlsx"


def test_detect_format_case_insensitive():
    """Test case-insensitive extension detection."""
    assert detect_format("/path/to/document.PDF") == "pdf"
    assert detect_format("/path/to/document.DOCX") == "docx"
    assert detect_format("/path/to/document.Pdf") == "pdf"
    assert detect_format("/path/to/IMAGE.PNG") == "png"


def test_detect_format_edge_cases():
    """Test edge cases for format detection."""
    # Empty path
    with pytest.raises(ValueError, match="Unable to detect format"):
        detect_format("")

    # Directory path (no extension)
    with pytest.raises(ValueError, match="Unable to detect format"):
        detect_format("/path/to/directory/")

    # Path with multiple dots
    assert detect_format("/path/to/file.backup.pdf") == "pdf"

    # Hidden file with extension
    assert detect_format("/path/to/.hidden.docx") == "docx"


def test_detect_format_with_query_params():
    """Test format detection with URL query parameters."""
    assert detect_format("https://example.com/doc.pdf?download=true") == "pdf"
    assert detect_format("/path/to/file.docx?version=2") == "docx"
```

### 4. Verify Format Detection Module

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test imports
cd /opt/docling-mcp/src/docling_processor
python3 -c "from format_detector import detect_format, get_supported_formats; print('✅ Format detector imports successful')"

# Run unit tests (if pytest installed)
# pytest test_format_detector.py -v
```

---

## Verification

### Success Criteria

- [ ] Format detection module created at `/opt/docling-mcp/src/docling_processor/format_detector.py`
- [ ] Core functions implemented: `detect_format()`, `detect_format_from_mime()`, `detect_format_from_extension()`
- [ ] MIME type mapping covers all 14+ supported formats (FR-005)
- [ ] Extension mapping covers all supported formats
- [ ] Format hint override mechanism working
- [ ] Error handling for unsupported formats implemented
- [ ] Module imports without errors
- [ ] Unit tests pass (if executed)

### Validation Commands

```bash
# Test format detection for various extensions
source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp/src/docling_processor

python3 << 'EOF'
from format_detector import detect_format, get_supported_formats

# Test extension detection
print("Testing extension detection:")
print(f"  test.pdf -> {detect_format('test.pdf')}")
print(f"  test.docx -> {detect_format('test.docx')}")
print(f"  test.html -> {detect_format('test.html')}")

# List supported formats
print(f"\nSupported formats ({len(get_supported_formats())}): {', '.join(get_supported_formats())}")
EOF
```

### Expected Output

```
Testing extension detection:
  test.pdf -> pdf
  test.docx -> docx
  test.html -> html

Supported formats (12): docx, epub, html, jpg, md, pdf, png, pptx, rtf, tiff, txt, xlsx
```

---

## Rollback

If format detection implementation fails:

```bash
# Remove format detection module
rm -f /opt/docling-mcp/src/docling_processor/format_detector.py
rm -f /opt/docling-mcp/src/docling_processor/test_format_detector.py

# Optionally remove entire package if needed
# rm -rf /opt/docling-mcp/src/docling_processor/
```

---

## Notes

### Format Detection Strategy

**3-Stage Detection Pipeline**:
1. **Manual Hint** (optional): User can override auto-detection with format hint
2. **Magic Number Analysis** (primary): Inspect file header bytes for MIME type (most reliable)
3. **Extension Fallback** (secondary): Use file extension if MIME detection unavailable

### Supported Formats (FR-005 Compliance)

- **PDF**: Including scanned PDFs (OCR in separate task)
- **Office**: DOCX, PPTX, XLSX (OpenXML formats)
- **Web**: HTML, Markdown
- **Images**: PNG, JPG, TIFF (OCR in separate task)
- **Other**: EPUB, RTF, TXT

### URL and Base64 Support

Format detection currently handles local file paths and file:// URLs. HTTP URLs and base64 data URIs require:
- HTTP: Download to temporary file, then detect format
- Base64: Decode to temporary file, then detect format

These extensions will be implemented in Task 063 (Backend Selection Logic).

### MIME Type Detection Dependencies

- Requires `python-magic` library (wraps libmagic)
- System dependency: libmagic1 (installed in hx-docling-mcp-task-011-020)

### Error Handling Philosophy

- **Graceful degradation**: If MIME detection fails, fall back to extension
- **Clear error messages**: Specify unsupported formats and list alternatives
- **No silent failures**: Raise ValueError if format cannot be determined

---

## Related Tasks

**Upstream Dependencies:**
- hx-docling-mcp-task-061: Docling library installation

**Downstream Dependencies:**
- hx-docling-mcp-task-063: Backend selection logic (uses format detection)
- hx-docling-mcp-task-066: DoclingDocument schema implementation
- hx-docling-mcp-task-067: Integrate format detection with MCP tools

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Agent**: albert-singh (Docling Processing Specialist)
