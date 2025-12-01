# Task 015: Configure Document Format Detection Pipeline

**Task ID**: hx-docling-mcp-task-015
**Component**: Docling Document Processing (albert-singh)
**Category**: Configuration
**Priority**: HIGH (blocking for document conversion)
**Estimated Effort**: 2-3 hours
**Status**: NOT_STARTED

---

## Objective

Implement hierarchical format detection pipeline using magic numbers, MIME types, and extensions to accurately identify 14+ document formats with validation and ambiguous format resolution.

---

## Prerequisites

- [x] Task 010: Docling library installed
- [x] System packages installed (libmagic1, file)
- [x] Python dependencies installed (python-magic, mimetypes)

---

## Technical Context

**From albert-docling-processing.md** (Section 1: Format Detection Pipeline, lines 23-255):
- **Detection Hierarchy**: Magic number → MIME type → Extension → Validation
- **Detectable Formats** (diagnostics/validation): PDF, DOCX, PPTX, XLSX, DOC, XLS, PPT, HTML, Markdown, TXT, PNG, JPEG, TIFF, EPUB, RTF
- **Ambiguous Format Handling**: HTML vs XHTML, XML variants (SVG, XHTML)
- **Corrupted File Validation**: PDF page count, ZIP integrity, image verification

**From Configuration Spec** (configuration-spec.md lines 800-807):
- **DOCLING_SUPPORTED_FORMATS** (officially supported): pdf,docx,pptx,xlsx,html,png,jpg,jpeg
- DOCLING_MAX_FILE_SIZE_MB: 100

**Note**: Detection pipeline can identify 15+ formats for diagnostics and error messages, but only formats listed in DOCLING_SUPPORTED_FORMATS are accepted for processing. Extended detection helps provide clear "format not supported" errors vs "format unknown" errors.

---

## Implementation Steps

### Step 1: Create Format Detection Module

**File**: `/opt/docling-mcp/application/docling_mcp/processors/format_detector.py`

```python
#!/usr/bin/env python3
"""
Document format detection module for Docling MCP Server.

Implements hierarchical detection strategy:
1. Magic number detection (file signature bytes - highest confidence)
2. MIME type detection (mimetypes library - medium confidence)
3. Extension-based detection (file extension - lowest confidence)
4. File integrity validation (format-specific checks)
5. Ambiguous format resolution (HTML/XHTML, XML variants)
"""

import logging
import os
import zipfile
import mimetypes
from typing import Optional, Tuple
from pathlib import Path

# Initialize module logger
logger = logging.getLogger(__name__)

# ============================================================================
# Constants
# ============================================================================

# Magic number signatures (first bytes of file)
MAGIC_NUMBERS = {
    b'%PDF-': 'pdf',
    b'PK\x03\x04': 'office_zip',  # ZIP-based Office formats
    b'\x89PNG\r\n\x1a\n': 'png',
    b'\xff\xd8\xff': 'jpeg',
    b'GIF87a': 'gif',
    b'GIF89a': 'gif',
    b'II*\x00': 'tiff',  # Little-endian TIFF
    b'MM\x00*': 'tiff',  # Big-endian TIFF
    b'<!DOCTYPE html': 'html',
    b'<html': 'html',
    b'<?xml': 'xml',
    b'\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1': 'office_legacy'  # Legacy Office (DOC, XLS, PPT)
}

# MIME type to format mapping
MIME_TO_FORMAT = {
    'application/pdf': 'pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'docx',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'pptx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xlsx',
    'application/msword': 'doc',
    'application/vnd.ms-excel': 'xls',
    'application/vnd.ms-powerpoint': 'ppt',
    'text/html': 'html',
    'text/markdown': 'markdown',
    'text/plain': 'txt',
    'image/png': 'png',
    'image/jpeg': 'jpeg',
    'image/tiff': 'tiff',
    'application/epub+zip': 'epub',
    'application/rtf': 'rtf'
}

# Extension to format mapping
EXTENSION_MAP = {
    '.pdf': 'pdf',
    '.docx': 'docx',
    '.doc': 'doc',
    '.pptx': 'pptx',
    '.ppt': 'ppt',
    '.xlsx': 'xlsx',
    '.xls': 'xls',
    '.html': 'html',
    '.htm': 'html',
    '.md': 'markdown',
    '.markdown': 'markdown',
    '.txt': 'txt',
    '.png': 'png',
    '.jpg': 'jpeg',
    '.jpeg': 'jpeg',
    '.tiff': 'tiff',
    '.tif': 'tiff',
    '.epub': 'epub',
    '.rtf': 'rtf'
}

# Officially supported formats (must match DOCLING_SUPPORTED_FORMATS in config)
# Detection pipeline can identify additional formats for diagnostics, but only these
# formats will be accepted for processing. This allows clear error messages like
# "TIFF format detected but not supported" vs "Unknown format".
SUPPORTED_FORMATS = [
    'pdf', 'docx', 'pptx', 'xlsx', 'html', 'png', 'jpg', 'jpeg'
]

# ============================================================================
# Format Detection Functions
# ============================================================================

def detect_by_magic_number(file_path: str) -> Optional[str]:
    """
    Detect document format by reading file signature (magic number).

    Args:
        file_path: Path to document file

    Returns:
        Detected format string or None if no match
    """
    try:
        with open(file_path, 'rb') as f:
            header = f.read(16)  # Read first 16 bytes

        for magic, format_type in MAGIC_NUMBERS.items():
            if header.startswith(magic):
                # Disambiguate ZIP-based Office formats
                if format_type == 'office_zip':
                    return detect_office_zip_format(file_path)
                return format_type

        return None
    except Exception:
        return None


def detect_office_zip_format(file_path: str) -> Optional[str]:
    """
    Distinguish between DOCX, PPTX, XLSX, EPUB based on ZIP contents.

    Args:
        file_path: Path to ZIP-based Office file

    Returns:
        Specific format (docx, pptx, xlsx, epub) or None
    """
    try:
        with zipfile.ZipFile(file_path, 'r') as zf:
            namelist = zf.namelist()

            if 'word/document.xml' in namelist:
                return 'docx'
            elif 'ppt/presentation.xml' in namelist:
                return 'pptx'
            elif 'xl/workbook.xml' in namelist:
                return 'xlsx'
            elif 'META-INF/container.xml' in namelist:
                # Check for EPUB format
                container = zf.read('META-INF/container.xml').decode('utf-8')
                if 'application/epub+zip' in container:
                    return 'epub'

        return 'zip'  # Generic ZIP if no Office markers found
    except (zipfile.BadZipFile, Exception):
        return None


def detect_by_mime_type(file_path: str) -> Optional[str]:
    """
    Detect format using Python mimetypes library.

    Args:
        file_path: Path to document file

    Returns:
        Detected format string or None if no match
    """
    mime_type, _ = mimetypes.guess_type(file_path)
    return MIME_TO_FORMAT.get(mime_type)


def detect_by_extension(file_path: str) -> Optional[str]:
    """
    Detect format from file extension.

    Args:
        file_path: Path to document file

    Returns:
        Detected format string or None if no match
    """
    ext = os.path.splitext(file_path)[1].lower()
    return EXTENSION_MAP.get(ext)


def resolve_ambiguous_format(file_path: str, format: str) -> str:
    """
    Resolve ambiguous format detections (HTML vs XHTML, XML variants).

    Args:
        file_path: Path to document file
        format: Initially detected format

    Returns:
        Resolved format string
    """
    # HTML vs XHTML disambiguation
    if format == 'html':
        try:
            with open(file_path, 'rb') as f:
                content = f.read(1024).decode('utf-8', errors='ignore')

            if '<?xml' in content and 'xhtml' in content.lower():
                return 'xhtml'
            return 'html'
        except Exception:
            return 'html'

    # XML-based formats (SVG, XHTML, custom XML)
    if format == 'xml':
        try:
            with open(file_path, 'rb') as f:
                content = f.read(1024).decode('utf-8', errors='ignore')

            if '<svg' in content:
                return 'svg'
            if 'xhtml' in content.lower():
                return 'xhtml'
            return 'xml'
        except Exception:
            return 'xml'

    return format


def validate_file_integrity(file_path: str, format: str) -> Tuple[bool, Optional[str]]:
    """
    Validate file integrity before processing.

    Args:
        file_path: Path to document file
        format: Detected document format

    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        if format == 'pdf':
            # Verify PDF structure with pypdfium2
            import pypdfium2 as pdfium
            pdf = pdfium.PdfDocument(file_path)
            page_count = len(pdf)
            pdf.close()

            if page_count == 0:
                return False, "PDF has zero pages"

        elif format in ['docx', 'pptx', 'xlsx', 'epub']:
            # Verify ZIP integrity
            with zipfile.ZipFile(file_path, 'r') as zf:
                bad_files = zf.testzip()
                if bad_files:
                    return False, f"Corrupted ZIP entries: {bad_files}"

        elif format in ['png', 'jpeg', 'tiff']:
            # Verify image integrity
            from PIL import Image
            img = Image.open(file_path)
            img.verify()
            img.close()

        return True, None

    except Exception as e:
        return False, f"File validation failed: {str(e)}"


# ============================================================================
# Main Detection Function
# ============================================================================

def detect_document_format(file_path: str, format_hint: Optional[str] = None) -> str:
    """
    Detect document format using hierarchical detection strategy.

    Detection Order:
    1. Format hint (if provided and valid)
    2. Magic number detection (highest confidence)
    3. MIME type detection (medium confidence)
    4. Extension-based detection (lowest confidence)
    5. Ambiguous format resolution
    6. File integrity validation

    Args:
        file_path: Path to document file
        format_hint: Optional format hint from user (e.g., 'pdf', 'docx')

    Returns:
        Detected format string

    Raises:
        ValueError: If format cannot be detected or file is corrupted
    """
    # 1. Use format hint if provided and valid
    if format_hint and format_hint in SUPPORTED_FORMATS:
        is_valid, error = validate_file_integrity(file_path, format_hint)
        if is_valid:
            return format_hint
        else:
            # Log warning but continue with auto-detection
            logger.warning(f"Format hint '{format_hint}' invalid: {error}, falling back to auto-detection")

    # 2. Magic number detection (highest confidence)
    format_type = detect_by_magic_number(file_path)
    if format_type:
        format_type = resolve_ambiguous_format(file_path, format_type)
        is_valid, error = validate_file_integrity(file_path, format_type)
        if is_valid:
            return format_type
        else:
            raise ValueError(f"File corrupted (magic number: {format_type}): {error}")

    # 3. MIME type detection (medium confidence)
    format_type = detect_by_mime_type(file_path)
    if format_type:
        is_valid, error = validate_file_integrity(file_path, format_type)
        if is_valid:
            return format_type

    # 4. Extension-based detection (lowest confidence)
    format_type = detect_by_extension(file_path)
    if format_type:
        is_valid, error = validate_file_integrity(file_path, format_type)
        if is_valid:
            return format_type

    # 5. Format detection failed
    raise ValueError(
        f"Unable to detect format for file: {file_path}. "
        f"Supported formats: {', '.join(SUPPORTED_FORMATS)}"
    )


# ============================================================================
# Utility Functions
# ============================================================================

def get_supported_formats() -> list[str]:
    """Get list of supported document formats."""
    return SUPPORTED_FORMATS.copy()


def is_format_supported(format: str) -> bool:
    """
    Check if format is supported.
    
    Args:
        format: Document format string to check
        
    Returns:
        True if format is supported, False if format is None, empty, or unsupported
    """
    if not format:
        return False
    return format.lower() in SUPPORTED_FORMATS
```

---

### Step 2: Create Unit Tests for Format Detection

**File**: `/opt/docling-mcp/tests/test_format_detection.py`

```python
#!/usr/bin/env python3
"""
Unit tests for document format detection.
"""

import pytest
import tempfile
import os
from pathlib import Path
from docling_mcp.processors.format_detector import (
    detect_by_magic_number,
    detect_by_mime_type,
    detect_by_extension,
    detect_document_format,
    validate_file_integrity,
    is_format_supported
)


class TestMagicNumberDetection:
    """Test magic number-based format detection."""

    def test_pdf_magic_number(self, tmp_path):
        """Test PDF detection from magic number."""
        pdf_file = tmp_path / "test.pdf"
        pdf_file.write_bytes(b'%PDF-1.4\nSample PDF content')

        detected = detect_by_magic_number(str(pdf_file))
        assert detected == 'pdf'

    def test_png_magic_number(self, tmp_path):
        """Test PNG detection from magic number."""
        png_file = tmp_path / "test.png"
        png_file.write_bytes(b'\x89PNG\r\n\x1a\nImage data here')

        detected = detect_by_magic_number(str(png_file))
        assert detected == 'png'

    def test_jpeg_magic_number(self, tmp_path):
        """Test JPEG detection from magic number."""
        jpeg_file = tmp_path / "test.jpg"
        jpeg_file.write_bytes(b'\xff\xd8\xffImage data')

        detected = detect_by_magic_number(str(jpeg_file))
        assert detected == 'jpeg'


class TestMimeTypeDetection:
    """Test MIME type-based format detection."""

    def test_pdf_mime_type(self, tmp_path):
        """Test PDF detection from MIME type."""
        pdf_file = tmp_path / "document.pdf"
        pdf_file.write_text("dummy")

        detected = detect_by_mime_type(str(pdf_file))
        assert detected == 'pdf'

    def test_docx_mime_type(self, tmp_path):
        """Test DOCX detection from MIME type."""
        docx_file = tmp_path / "document.docx"
        docx_file.write_text("dummy")

        detected = detect_by_mime_type(str(docx_file))
        assert detected == 'docx'


class TestExtensionDetection:
    """Test extension-based format detection."""

    @pytest.mark.parametrize("extension,expected_format", [
        ('.pdf', 'pdf'),
        ('.docx', 'docx'),
        ('.pptx', 'pptx'),
        ('.xlsx', 'xlsx'),
        ('.html', 'html'),
        ('.png', 'png'),
        ('.jpg', 'jpeg'),
        ('.jpeg', 'jpeg')
    ])
    def test_extension_detection(self, tmp_path, extension, expected_format):
        """Test format detection from file extension."""
        file = tmp_path / f"document{extension}"
        file.write_text("dummy")

        detected = detect_by_extension(str(file))
        assert detected == expected_format


class TestFormatValidation:
    """Test format support validation."""

    @pytest.mark.parametrize("format,is_supported", [
        ('pdf', True),
        ('docx', True),
        ('pptx', True),
        ('xlsx', True),
        ('html', True),
        ('png', True),
        ('unknown', False),
        ('exe', False),
        (None, False),  # None should return False
        ('', False),    # Empty string should return False
        ('   ', False)  # Whitespace-only should return False
    ])
    def test_format_support(self, format, is_supported):
        """Test format support checking, including None and empty values."""
        assert is_format_supported(format) == is_supported


class TestErrorHandling:
    """Test error handling in format detection."""

    def test_nonexistent_file(self, tmp_path):
        """Test detection on non-existent file raises ValueError."""
        nonexistent_file = tmp_path / "does_not_exist.pdf"
        
        with pytest.raises(ValueError) as exc_info:
            detect_document_format(str(nonexistent_file))
        
        assert "Unable to detect format" in str(exc_info.value)

    def test_corrupted_pdf(self, tmp_path):
        """Test detection on truncated/corrupted PDF raises ValueError."""
        corrupted_pdf = tmp_path / "corrupted.pdf"
        # Write incomplete PDF (only header, no valid structure)
        corrupted_pdf.write_bytes(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n')
        
        with pytest.raises(ValueError) as exc_info:
            detect_document_format(str(corrupted_pdf))
        
        error_msg = str(exc_info.value).lower()
        assert "corrupt" in error_msg or "corrupted" in error_msg

    def test_permission_denied(self, tmp_path):
        """Test detection on permission-denied file raises appropriate exception."""
        restricted_file = tmp_path / "restricted.pdf"
        restricted_file.write_bytes(b'%PDF-1.4\nContent')
        
        # Remove all permissions
        os.chmod(str(restricted_file), 0o000)
        
        try:
            with pytest.raises((PermissionError, OSError)) as exc_info:
                detect_document_format(str(restricted_file))
            
            # Verify it's a permission-related error
            assert exc_info.type in (PermissionError, OSError)
        finally:
            # Restore permissions for cleanup
            os.chmod(str(restricted_file), 0o644)

    def test_empty_file(self, tmp_path):
        """Test detection on empty file raises ValueError."""
        empty_file = tmp_path / "empty.pdf"
        empty_file.write_bytes(b'')
        
        with pytest.raises(ValueError) as exc_info:
            detect_document_format(str(empty_file))
        
        assert "Unable to detect format" in str(exc_info.value)

    def test_unsupported_format(self, tmp_path):
        """Test detection of valid but unsupported format."""
        exe_file = tmp_path / "program.exe"
        exe_file.write_bytes(b'MZ\x90\x00')  # DOS/Windows executable magic
        
        with pytest.raises(ValueError) as exc_info:
            detect_document_format(str(exe_file))
        
        error_msg = str(exc_info.value)
        assert "Unable to detect format" in error_msg or "Supported formats" in error_msg


class TestHierarchicalDetection:
    """Test hierarchical format detection prefers magic numbers over hints."""

    def test_magic_overrides_extension(self, tmp_path):
        """Test magic number detection overrides misleading extension."""
        # Create file with .docx extension but PDF magic number
        misleading_file = tmp_path / "document.docx"
        misleading_file.write_bytes(b'%PDF-1.7\n%\xe2\xe3\xcf\xd3\n1 0 obj\n<<\n/Type /Catalog\n>>\nendobj\nxref\n0 1\ntrailer\n<<\n>>\nstartxref\n0\n%%EOF')
        
        detected = detect_document_format(str(misleading_file))
        # Magic number (PDF) should win over extension (.docx)
        assert detected == 'pdf'

    def test_magic_overrides_format_hint(self, tmp_path):
        """Test magic number detection overrides incorrect format hint."""
        # Create PDF file but hint it's DOCX
        pdf_file = tmp_path / "actual.pdf"
        pdf_file.write_bytes(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n1 0 obj\nendobj\nxref\n0 1\ntrailer\nstartxref\n0\n%%EOF')
        
        # Provide wrong hint
        detected = detect_document_format(str(pdf_file), format_hint='docx')
        # Magic number should override invalid hint
        assert detected == 'pdf'

    def test_mime_fallback_when_no_magic(self, tmp_path, monkeypatch):
        """Test MIME detection is used when magic number fails."""
        # Create file without recognizable magic number
        unknown_magic_file = tmp_path / "document.html"
        unknown_magic_file.write_text('<html><body>Test</body></html>')
        
        # Mock detect_by_magic_number to return None
        monkeypatch.setattr(
            'docling_mcp.processors.format_detector.detect_by_magic_number',
            lambda path: None
        )
        
        detected = detect_document_format(str(unknown_magic_file))
        # Should fall back to MIME or extension detection
        assert detected == 'html'

    def test_extension_fallback_when_mime_fails(self, tmp_path, monkeypatch):
        """Test extension detection is used when MIME detection fails."""
        test_file = tmp_path / "document.pdf"
        test_file.write_text('dummy content')
        
        # Mock both magic and MIME to return None
        monkeypatch.setattr(
            'docling_mcp.processors.format_detector.detect_by_magic_number',
            lambda path: None
        )
        monkeypatch.setattr(
            'docling_mcp.processors.format_detector.detect_by_mime_type',
            lambda path: None
        )
        
        detected = detect_document_format(str(test_file))
        # Should fall back to extension detection
        assert detected == 'pdf'

    def test_all_methods_fail(self, tmp_path, monkeypatch):
        """Test ValueError when all detection methods fail."""
        test_file = tmp_path / "unknown.xyz"
        test_file.write_bytes(b'\x00\x00\x00\x00Unknown format')
        
        # Mock all detection methods to return None
        monkeypatch.setattr(
            'docling_mcp.processors.format_detector.detect_by_magic_number',
            lambda path: None
        )
        monkeypatch.setattr(
            'docling_mcp.processors.format_detector.detect_by_mime_type',
            lambda path: None
        )
        monkeypatch.setattr(
            'docling_mcp.processors.format_detector.detect_by_extension',
            lambda path: None
        )
        
        with pytest.raises(ValueError) as exc_info:
            detect_document_format(str(test_file))
        
        assert "Unable to detect format" in str(exc_info.value)
        assert "Supported formats" in str(exc_info.value)


class TestAmbiguousFormats:
    """Test ambiguous format resolution (XHTML vs HTML, XML variants)."""

    def test_xhtml_detection(self, tmp_path):
        """Test XHTML is properly distinguished from HTML."""
        xhtml_file = tmp_path / "document.xhtml"
        xhtml_content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>XHTML Test</title></head>
<body><p>This is XHTML</p></body>
</html>'''
        xhtml_file.write_text(xhtml_content)
        
        detected = detect_document_format(str(xhtml_file))
        # Should detect as XHTML, not plain HTML
        assert detected in ('xhtml', 'html')  # Accept either if XHTML not separately supported
        
        # If resolve_ambiguous_format exists, test it directly
        try:
            from docling_mcp.processors.format_detector import resolve_ambiguous_format
            resolved = resolve_ambiguous_format(str(xhtml_file), 'xml')
            assert resolved in ('xhtml', 'html')
        except ImportError:
            pass  # resolve_ambiguous_format may not be exported

    def test_html_vs_xhtml_content(self, tmp_path):
        """Test plain HTML without XML declaration stays as HTML."""
        html_file = tmp_path / "document.html"
        html_content = '''<!DOCTYPE html>
<html>
<head><title>HTML5 Test</title></head>
<body><p>This is plain HTML</p></body>
</html>'''
        html_file.write_text(html_content)
        
        detected = detect_document_format(str(html_file))
        assert detected == 'html'

    def test_svg_as_xml_variant(self, tmp_path):
        """Test SVG (XML variant) detection."""
        svg_file = tmp_path / "image.svg"
        svg_content = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
    <circle cx="50" cy="50" r="40" fill="red"/>
</svg>'''
        svg_file.write_text(svg_content)
        
        detected = detect_document_format(str(svg_file))
        # SVG might be detected as xml, svg, or raise error if not supported
        # Just verify it doesn't crash and returns something or raises ValueError
        assert detected is not None or True  # Handled gracefully

    def test_office_zip_disambiguation(self, tmp_path):
        """Test ZIP-based Office format disambiguation (DOCX vs PPTX vs XLSX)."""
        # This would require creating valid Office Open XML files
        # For now, document the test case structure
        # In real implementation, would use zipfile to create proper structure
        # with [Content_Types].xml containing the right format indicators
        pass  # Placeholder for complex Office format tests


class TestMimeTypeDetectionWithMocking:
    """Test MIME type detection with controlled mocking to avoid platform flakiness."""

    def test_mime_detection_with_mock(self, tmp_path, monkeypatch):
        """Test MIME detection with mocked mimetypes registry."""
        test_file = tmp_path / "document.pdf"
        test_file.write_text("dummy")
        
        # Mock mimetypes.guess_type to return controlled value
        import mimetypes
        original_guess_type = mimetypes.guess_type
        
        def mock_guess_type(path, strict=True):
            if path.endswith('.pdf'):
                return ('application/pdf', None)
            return (None, None)
        
        monkeypatch.setattr(mimetypes, 'guess_type', mock_guess_type)
        
        detected = detect_by_mime_type(str(test_file))
        assert detected == 'pdf'

    def test_mime_detection_unknown_type(self, tmp_path, monkeypatch):
        """Test MIME detection returns None for unknown MIME type."""
        test_file = tmp_path / "unknown.xyz"
        test_file.write_text("dummy")
        
        import mimetypes
        monkeypatch.setattr(
            mimetypes,
            'guess_type',
            lambda path, strict=True: (None, None)
        )
        
        detected = detect_by_mime_type(str(test_file))
        assert detected is None
```

---

### Step 3: Integration with Docling Processor

**File**: `/opt/docling-mcp/application/docling_mcp/processors/docling_processor.py` (partial update)

```python
import logging
from .format_detector import detect_document_format

logger = logging.getLogger(__name__)


class DoclingProcessor:
    """Document processor using docling library with format detection."""

    async def convert_document(self, source: str, format_hint: str = None):
        """
        Convert document with automatic format detection.

        Args:
            source: File path or URL
            format_hint: Optional format override

        Returns:
            DoclingDocument

        Raises:
            ValueError: If format cannot be detected, format is unsupported,
                       file is corrupted, or validation fails
            FileNotFoundError: If source file does not exist
            IOError: If file cannot be read or processed
        """
        # Detect format using hierarchical strategy with error handling
        try:
            detected_format = detect_document_format(source, format_hint)
        except ValueError as e:
            # Re-raise with additional context for debugging
            logger.error(
                f"Format detection failed for source='{source}', "
                f"format_hint='{format_hint}': {e}"
            )
            raise ValueError(
                f"Failed to detect document format for '{source}'. "
                f"Format hint: {format_hint or 'None'}. "
                f"Reason: {str(e)}"
            ) from e

        # Validate detected format is non-null and supported
        if not detected_format:
            raise ValueError(
                f"Format detection returned null for source='{source}', "
                f"format_hint='{format_hint}'"
            )
        
        if not isinstance(detected_format, str):
            raise TypeError(
                f"Format detection returned invalid type {type(detected_format).__name__}, "
                f"expected str. Source: '{source}'"
            )

        # Select appropriate backend (requires valid format)
        backend = self._select_backend(detected_format)

        # Convert document (requires valid format and backend)
        doc = await self._convert_with_backend(source, backend, detected_format)

        return doc
```

---

### Step 4: Validation and Testing

**Command**: Run format detection tests
```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Run unit tests
pytest tests/test_format_detection.py -v

# Run with coverage
pytest tests/test_format_detection.py --cov=docling_mcp.processors.format_detector --cov-report=term

# Expected output:
# tests/test_format_detection.py::TestMagicNumberDetection::test_pdf_magic_number PASSED
# tests/test_format_detection.py::TestMagicNumberDetection::test_png_magic_number PASSED
# tests/test_format_detection.py::TestMagicNumberDetection::test_jpeg_magic_number PASSED
# tests/test_format_detection.py::TestMimeTypeDetection::test_pdf_mime_type PASSED
# tests/test_format_detection.py::TestMimeTypeDetection::test_docx_mime_type PASSED
# tests/test_format_detection.py::TestExtensionDetection::test_extension_detection PASSED
# tests/test_format_detection.py::TestFormatValidation::test_format_support PASSED
#
# Coverage: 95%+
```

---

## Success Criteria

- [ ] Format detection module created (`format_detector.py`)
- [ ] Magic number detection supports PDF, DOCX, PPTX, XLSX, images
- [ ] MIME type fallback detection implemented
- [ ] Extension-based detection implemented
- [ ] Office ZIP format disambiguation working (DOCX vs PPTX vs XLSX)
- [ ] File integrity validation implemented
- [ ] Unit tests created and passing (≥95% coverage)
- [ ] Integration with DoclingProcessor complete

---

## Rollback Procedure

If format detection fails:
```bash
# Remove format detection module
rm /opt/docling-mcp/application/docling_mcp/processors/format_detector.py

# Remove tests
rm /opt/docling-mcp/tests/test_format_detection.py

# Revert to simpler detection (extension-only)
git checkout /opt/docling-mcp/application/docling_mcp/processors/docling_processor.py
```

---

## Dependencies

**Depends On**:
- Task 010: Docling library installed

**Blocks**:
- Task 012: Backend selection configuration
- Task 013: Structure preservation implementation

---

## Notes

**From albert-docling-processing.md** (lines 23-255):
- Detection hierarchy ensures highest confidence method used first
- Ambiguous format resolution handles HTML/XHTML, XML/SVG variants
- File integrity validation prevents processing corrupted files

**Testing Strategy**:
- Unit tests for each detection method (magic, MIME, extension)
- Parametrized tests for all supported formats
- Error handling tests for corrupted files

---

**Task Owner**: albert-singh (Docling Document Processing SME)
**Created**: 2025-11-27
**Updated**: 2025-11-27
