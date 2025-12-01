# Task 014: Install Docling Library and Document Processing Dependencies

**Task ID**: hx-docling-mcp-task-014
**Component**: Docling Document Processing (albert-singh)
**Category**: Installation
**Priority**: HIGH (blocking for all document processing)
**Estimated Effort**: 1-2 hours
**Status**: COMPLETE
**Completed**: 2025-11-28
**Executed By**: james (Docling MCP Integration SME)

---

## Objective

Install docling library (~2.25) and all document processing dependencies (system packages and Python libraries) required for multimodal document conversion (PDF, DOCX, PPTX, XLSX, HTML, images).

---

## Prerequisites

- [ ] Python 3.11+ installed (Task 001)
- [ ] System packages installed (build-essential, gcc, g++, make)
- [ ] Virtual environment created (`/opt/docling-mcp/venv`)
- [ ] pip upgraded (`pip install --upgrade pip setuptools wheel`)

---

## Technical Context

**From Specification** (node-spec.md Section 4.3.2, albert-docling-processing.md):
- Docling library version: ~2.25.0
- System dependencies: poppler-utils (PDF), tesseract-ocr (OCR), libmagic1 (MIME detection)
- Python dependencies: docling-core, docling-parse, pypdfium2, python-docx, python-pptx, openpyxl, Pillow, pytesseract
- Format support: 14+ formats (PDF, DOCX, PPTX, XLSX, HTML, PNG, JPG, TIFF, EPUB, RTF, Markdown, TXT)

**From Configuration Spec** (configuration-spec.md lines 243-314):
- System packages: poppler-utils, tesseract-ocr, tesseract-ocr-eng, libmagic1, libmagic-dev, libpng-dev, libjpeg-dev, libtiff-dev
- Python packages: docling~=2.25.0, docling-core>=1.0.0, docling-parse>=1.0.0, python-docx, python-pptx, openpyxl, Pillow, pytesseract, python-magic, pypdfium2, beautifulsoup4, lxml

---

## Implementation Steps

### Step 1: Install System Dependencies

**Command**: Install document processing system packages
```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Install PDF processing dependencies
sudo apt-get install -y poppler-utils

# Install OCR engine and language data
sudo apt-get install -y tesseract-ocr tesseract-ocr-eng

# Install MIME type detection
sudo apt-get install -y libmagic1 libmagic-dev

# Install image processing libraries
sudo apt-get install -y libpng-dev libjpeg-dev libtiff-dev
```

**Validation**:
```bash
# Verify poppler-utils (PDF rendering)
pdftotext -v
# Expected: pdftotext version 23.x or higher

# Verify tesseract (OCR engine)
tesseract --version
# Expected: tesseract 5.x or higher

# Verify libmagic (MIME detection)
file --version
# Expected: file-5.x
```

---

### Step 2: Install Docling Library

**Command**: Install docling and core dependencies
```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Install docling library
pip install docling~=2.25.0

# Install docling core components
pip install docling-core>=1.0.0
pip install docling-parse>=1.0.0
```

**Validation**:
```bash
# Verify docling installation
python -c "import docling; print(docling.__version__)"
# Expected: 2.25.x

# Verify docling-core
python -c "import docling_core; print(docling_core.__version__)"
# Expected: 1.x.x

# Verify docling-parse
python -c "import docling_parse; print(docling_parse.__version__)"
# Expected: 1.x.x
```

---

### Step 3: Install Format-Specific Dependencies

**Command**: Install document format libraries
```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# PDF processing
pip install pypdfium2==4.25.0

# Microsoft Office formats
pip install python-docx==1.1.0
pip install python-pptx==0.6.23
pip install openpyxl==3.1.2

# HTML/XML processing
pip install beautifulsoup4==4.12.2
pip install lxml==4.9.3

# Image processing and OCR
pip install Pillow==10.1.0
pip install pytesseract==0.3.10

# MIME type detection (Python wrapper)
pip install python-magic==0.4.27
```

**Validation**:
```bash
# Verify PDF backend (pypdfium2)
python -c "import pypdfium2; print(pypdfium2.__version__)"
# Expected: 4.25.0

# Verify DOCX backend (python-docx)
python -c "import docx; print(docx.__version__)"
# Expected: 1.1.0

# Verify PPTX backend (python-pptx)
python -c "import pptx; print(pptx.__version__)"
# Expected: 0.6.23

# Verify XLSX backend (openpyxl)
python -c "import openpyxl; print(openpyxl.__version__)"
# Expected: 3.1.2

# Verify HTML backend (beautifulsoup4)
python -c "from bs4 import BeautifulSoup; import bs4; print(bs4.__version__)"
# Expected: 4.12.2

# Verify image backend (Pillow)
python -c "from PIL import Image; import PIL; print(PIL.__version__)"
# Expected: 10.1.0

# Verify OCR wrapper (pytesseract)
python -c "import pytesseract; print(pytesseract.__version__)"
# Expected: 0.3.10
```

---

### Step 4: Verify Docling Functionality

**Test Script**: Create `/opt/docling-mcp/test_docling_install.py`
```python
#!/usr/bin/env python3
"""
Test script to verify docling installation and format support.
"""

import sys
from docling.document_converter import DocumentConverter
from docling.datamodel.base_models import InputFormat

def test_docling_import():
    """Test docling library can be imported."""
    try:
        import docling
        print(f"✓ Docling version: {docling.__version__}")
        return True
    except ImportError as e:
        print(f"✗ Docling import failed: {e}")
        return False

def test_document_converter():
    """Test DocumentConverter instantiation."""
    try:
        converter = DocumentConverter()
        print("✓ DocumentConverter instantiated successfully")
        return True
    except Exception as e:
        print(f"✗ DocumentConverter instantiation failed: {e}")
        return False

def test_backend_availability():
    """Test format-specific backends are available."""
    backends = {
        "PDF (pypdfium2)": "pypdfium2",
        "DOCX (python-docx)": "docx",
        "PPTX (python-pptx)": "pptx",
        "XLSX (openpyxl)": "openpyxl",
        "HTML (beautifulsoup4)": "bs4",
        "Images (Pillow)": "PIL"
    }

    all_ok = True
    for name, module in backends.items():
        try:
            __import__(module)
            print(f"✓ {name} backend available")
        except ImportError:
            print(f"✗ {name} backend NOT available")
            all_ok = False

    return all_ok

def test_ocr_availability():
    """Test OCR dependencies are available."""
    try:
        import pytesseract
        # Test tesseract binary
        version = pytesseract.get_tesseract_version()
        print(f"✓ Tesseract OCR available (version: {version})")
        return True
    except Exception as e:
        print(f"✗ Tesseract OCR NOT available: {e}")
        return False

def main():
    """Run all installation tests."""
    print("=" * 60)
    print("Docling Installation Verification")
    print("=" * 60)

    tests = [
        ("Docling Import", test_docling_import),
        ("DocumentConverter", test_document_converter),
        ("Backend Availability", test_backend_availability),
        ("OCR Availability", test_ocr_availability)
    ]

    results = []
    for name, test_func in tests:
        print(f"\n{name}:")
        result = test_func()
        results.append(result)

    print("\n" + "=" * 60)
    if all(results):
        print("✓ All docling installation tests PASSED")
        sys.exit(0)
    else:
        print("✗ Some docling installation tests FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

**Run Validation**:
```bash
# Make test script executable
chmod +x /opt/docling-mcp/test_docling_install.py

# Run test script
python /opt/docling-mcp/test_docling_install.py

# Expected output:
# ============================================================
# Docling Installation Verification
# ============================================================
#
# Docling Import:
# ✓ Docling version: 2.25.x
#
# DocumentConverter:
# ✓ DocumentConverter instantiated successfully
#
# Backend Availability:
# ✓ PDF (pypdfium2) backend available
# ✓ DOCX (python-docx) backend available
# ✓ PPTX (python-pptx) backend available
# ✓ XLSX (openpyxl) backend available
# ✓ HTML (beautifulsoup4) backend available
# ✓ Images (Pillow) backend available
#
# OCR Availability:
# ✓ Tesseract OCR available (version: 5.x)
#
# ============================================================
# ✓ All docling installation tests PASSED
```

---

### Step 5: Create Docling Working Directories

**Command**: Create directories for docling cache and workspace
```bash
# Create cache directory (from configuration-spec.md line 419)
sudo mkdir -p /var/lib/docling-mcp/cache
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/lib/docling-mcp/cache
sudo chmod 755 /var/lib/docling-mcp/cache

# Create working directory (from configuration-spec.md line 420)
sudo mkdir -p /var/lib/docling-mcp/workspace
sudo chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /var/lib/docling-mcp/workspace
sudo chmod 755 /var/lib/docling-mcp/workspace
```

**Validation**:
```bash
# Verify directories exist and are writable
ls -ld /var/lib/docling-mcp/cache
ls -ld /var/lib/docling-mcp/workspace

# Test write permissions
sudo -u docling-mcp@hx.dev.local touch /var/lib/docling-mcp/cache/test.txt
sudo -u docling-mcp@hx.dev.local touch /var/lib/docling-mcp/workspace/test.txt
sudo rm /var/lib/docling-mcp/cache/test.txt /var/lib/docling-mcp/workspace/test.txt
```

---

## Success Criteria

- [ ] All system packages installed and verified (poppler-utils, tesseract, libmagic)
- [ ] Docling library ~2.25 installed and importable
- [ ] All format-specific backends available (PDF, DOCX, PPTX, XLSX, HTML, images)
- [ ] OCR functionality available (tesseract 5.x+)
- [ ] DocumentConverter instantiates successfully
- [ ] Test script passes all validation checks
- [ ] Working directories created with correct permissions

---

## Rollback Procedure

If installation fails:
```bash
# Uninstall docling and dependencies
pip uninstall -y docling docling-core docling-parse pypdfium2 python-docx python-pptx openpyxl beautifulsoup4 lxml Pillow pytesseract python-magic

# Remove system packages (optional - may affect other services)
# sudo apt-get remove -y poppler-utils tesseract-ocr

# Remove working directories
sudo rm -rf /var/lib/docling-mcp/cache
sudo rm -rf /var/lib/docling-mcp/workspace
```

---

## Dependencies

**Depends On**:
- Task 001: Python 3.11+ installed
- System package installation (build tools)
- Virtual environment created

**Blocks**:
- Task 011: Configure format detection pipeline
- Task 012: Configure backend selection logic
- Task 013: Implement structure preservation
- Task 018: Integrate OCR pipeline

---

## Notes

**From albert-docling-processing.md**:
- Format detection uses magic number hierarchy (lines 23-56)
- Backend selection strategy documented (lines 260-329)
- Structure preservation specs provided (lines 425-691)
- OCR integration with EasyOCR documented (lines 693-863)

**Version Pinning Rationale**:
- docling~=2.25.0: Charter-specified version (charter.md line 330)
- All dependencies pinned to stable versions per configuration-spec.md

**Troubleshooting**:
- If pypdfium2 fails: Check system architecture (x86_64 required)
- If tesseract fails: Verify language data installed (`tesseract-ocr-eng`)
- If python-magic fails: Install libmagic-dev system package

---

**Task Owner**: albert-singh (Docling Document Processing SME)
**Created**: 2025-11-27
**Updated**: 2025-11-27
