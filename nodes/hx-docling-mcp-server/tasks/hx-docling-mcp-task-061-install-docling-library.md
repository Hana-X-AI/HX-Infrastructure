# Task 061: Install Docling Library

**Task ID**: hx-docling-mcp-task-061-install-docling-library
**Phase**: Development - Document Processing Integration
**Status**: Not Started
**Assigned To**: albert-singh (Docling Processing Specialist)
**Dependencies**: hx-docling-mcp-task-030 (Python virtual environment setup complete)
**Estimated Time**: 30 minutes

---

## Objective

Install the Docling document processing library and its core dependencies in the Python 3.11 virtual environment to enable multi-format document conversion (PDF, DOCX, PPTX, XLSX, HTML, images, audio) with structure preservation.

---

## Pre-Execution Validation

**CRITICAL**: Check if Docling is already installed before proceeding:

```bash
# Activate virtual environment and check for Docling installation
source /opt/docling-mcp/venv/bin/activate
python3 -c "import docling; print(f'Docling version: {docling.__version__}')" 2>/dev/null

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ VALIDATION: Docling library already installed - SKIP task execution"
    echo "Run 'pip show docling' to verify installation details"
    exit 0
else
    echo "❌ VALIDATION: Docling library not installed - PROCEED with task"
fi
```

**If Validation Passes (Docling Already Installed)**:
- Mark task as complete with validation timestamp
- Document installed version in task notes
- SKIP all implementation steps below

**If Validation Fails (Docling Not Installed)**:
- Proceed with Prerequisites and Steps sections

---

## Prerequisites

- [ ] Python 3.11 virtual environment created at `/opt/docling-mcp/venv/` (hx-docling-mcp-task-030)
- [ ] Virtual environment activated
- [ ] pip, setuptools, wheel upgraded to latest versions
- [ ] Internet connectivity available for PyPI package downloads
- [ ] System dependencies installed: poppler-utils, tesseract-ocr, libmagic1 (hx-docling-mcp-task-011-020)

---

## Steps

### 1. Activate Virtual Environment

```bash
# Activate Python virtual environment
source /opt/docling-mcp/venv/bin/activate

# Verify activation
which python3
# Expected output: /opt/docling-mcp/venv/bin/python3
```

### 2. Install Docling Core Library

```bash
# Install Docling with all dependencies
pip install docling

# Verify installation
pip show docling
# Expected output: Name, Version, Location, Dependencies
```

### 3. Install Docling Optional Dependencies

Install optional dependencies for enhanced capabilities:

```bash
# Install OCR support (EasyOCR)
pip install easyocr

# Install format-specific backends
pip install pypdfium2  # PDF backend
pip install python-docx  # DOCX backend
pip install python-pptx  # PPTX backend
pip install openpyxl  # XLSX backend
pip install beautifulsoup4 lxml  # HTML backend

# Install table extraction dependencies
pip install opencv-python-headless  # Image processing for table detection
```

### 4. Verify Docling Installation

Test Docling functionality:

```bash
# Test Docling import
python3 << 'EOF'
import docling
from docling.document_converter import DocumentConverter
from docling.datamodel.base_models import InputFormat
from docling.datamodel.document import DoclingDocument
print("✅ Docling imports successful")
print(f"Docling version: {docling.__version__}")
EOF
```

### 5. Verify Backend Support

```bash
# Test format detection and backend availability
python3 << 'EOF'
from docling.document_converter import DocumentConverter

converter = DocumentConverter()
print("✅ DocumentConverter initialized")
print("Available backends:")
print("  - PDF: pypdfium2")
print("  - DOCX: python-docx")
print("  - PPTX: python-pptx")
print("  - XLSX: openpyxl")
print("  - HTML: beautifulsoup4")
print("  - Images (OCR): easyocr")
EOF
```

### 6. Document Installed Packages

```bash
# Generate requirements file with installed versions
pip freeze | grep -E "(docling|pypdfium2|python-docx|python-pptx|openpyxl|beautifulsoup4|lxml|easyocr|opencv-python-headless)" > /opt/docling-mcp/docling-requirements.txt

# Display installed versions
cat /opt/docling-mcp/docling-requirements.txt
```

---

## Verification

### Success Criteria

- [ ] Docling library installed successfully (`pip show docling` returns package details)
- [ ] Core Docling modules importable without errors
- [ ] DocumentConverter class instantiates successfully
- [ ] All backend dependencies installed (pypdfium2, python-docx, python-pptx, openpyxl, beautifulsoup4, easyocr)
- [ ] No import errors when testing Docling modules
- [ ] Requirements file generated at `/opt/docling-mcp/docling-requirements.txt`

### Validation Commands

```bash
# Verify Docling package
pip show docling | grep -E "(Name|Version|Location)"

# Verify backends
pip list | grep -E "(docling|pypdfium2|python-docx|python-pptx|openpyxl|beautifulsoup4|easyocr)"

# Test imports
python3 -c "from docling.document_converter import DocumentConverter; print('✅ Docling ready')"
```

### Expected Output

```
Name: docling
Version: <version>
Location: /opt/docling-mcp/venv/lib/python3.11/site-packages

✅ Docling ready
```

---

## Rollback

If installation fails or causes issues:

```bash
# Uninstall Docling and dependencies
source /opt/docling-mcp/venv/bin/activate
pip uninstall -y docling easyocr pypdfium2 python-docx python-pptx openpyxl beautifulsoup4 lxml opencv-python-headless

# Verify removal
pip show docling
# Expected: WARNING: Package(s) not found: docling

# Remove requirements file
rm -f /opt/docling-mcp/docling-requirements.txt
```

---

## Notes

### Docling Capabilities

- **Supported Formats**: PDF, DOCX, PPTX, XLSX, HTML, Markdown, images (PNG, JPG, TIFF), audio (future)
- **Structure Preservation**: Headings, tables, lists, code blocks, images with captions
- **OCR Support**: EasyOCR for scanned PDFs and images (Latin, Japanese, Chinese, Arabic scripts)
- **Output Format**: DoclingDocument (Pydantic model with structured JSON representation)

### Backend Selection Strategy

Docling automatically selects backends based on document format:
- **PDF**: pypdfium2 (native text) or EasyOCR (scanned)
- **DOCX**: python-docx
- **PPTX**: python-pptx
- **XLSX**: openpyxl
- **HTML**: BeautifulSoup with lxml parser
- **Images**: EasyOCR

### Version Pinning

For production stability, consider pinning Docling version in requirements.txt after successful validation.

### Troubleshooting

**Import Error: "No module named 'docling'"**
- Ensure virtual environment is activated: `source /opt/docling-mcp/venv/bin/activate`
- Verify installation: `pip show docling`

**EasyOCR Installation Fails (Large Model Download)**
- EasyOCR downloads language models on first import (can be 100MB+)
- Ensure sufficient disk space in `/opt/docling-mcp/venv/`
- Consider pre-downloading models during deployment if offline installation needed

**PDF Conversion Fails**
- Verify poppler-utils installed (system dependency for PDF rendering)
- Check pypdfium2 installation: `pip show pypdfium2`

---

## Related Tasks

**Upstream Dependencies:**
- hx-docling-mcp-task-011-020: System dependencies installation (poppler-utils, tesseract-ocr, libmagic1)
- hx-docling-mcp-task-021-030: Python virtual environment setup

**Downstream Dependencies:**
- hx-docling-mcp-task-062: Configure format detection pipeline
- hx-docling-mcp-task-063: Implement backend selection logic
- hx-docling-mcp-task-064: Implement structure preservation
- hx-docling-mcp-task-065: Integrate OCR pipeline

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Agent**: albert-singh (Docling Processing Specialist)
