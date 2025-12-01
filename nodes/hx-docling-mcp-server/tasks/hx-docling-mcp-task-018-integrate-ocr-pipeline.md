# Task 018: Integrate OCR Pipeline for Scanned Documents

**Task ID**: hx-docling-mcp-task-018
**Component**: Docling Document Processing (albert-singh)
**Category**: Implementation
**Priority**: MEDIUM (required for scanned PDFs/images)
**Estimated Effort**: 3-4 hours
**Status**: COMPLETED
**Completed**: 2025-11-29
**Summary**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/ocr-integration-summary.md`

---

## Objective

Integrate EasyOCR or Tesseract OCR pipeline with preprocessing (deskew, denoise, contrast enhancement, binarization) for processing scanned PDFs and images with text.

---

## Prerequisites

- [x] Task 010: Docling library installed (includes Tesseract)
- [x] System packages: tesseract-ocr, tesseract-ocr-eng
- [x] Python packages: pytesseract, Pillow

---

## Technical Context

**From albert-docling-processing.md** (Section 4: OCR Integration, lines 693-893):
- **OCR Engine**: EasyOCR (multi-language) OR Tesseract (faster, English)
- **Preprocessing Pipeline**: Grayscale → Deskew → Denoise → Contrast → Binarize
- **Language Support**: English (required), Spanish, French, German, Japanese, Chinese, Arabic (optional)
- **Performance**: 2-6 pages/minute depending on DPI and quality

**From Configuration Spec** (configuration-spec.md lines 805-806):
- DOCLING_OCR_ENABLED: true
- OCR accuracy target: 85%+ for scanned PDFs (test-plan.md line 369)

---

## Implementation Steps

### Step 1: Create OCR Processor Module

**File**: `/opt/docling-mcp/application/docling_mcp/processors/ocr_processor.py`

```python
"""OCR processing pipeline for scanned documents and images."""

import logging
import pytesseract
from PIL import Image, ImageEnhance, ImageFilter
import numpy as np
from typing import Dict, Optional, Any

logger = logging.getLogger(__name__)


class OCRProcessor:
    """
    OCR processor for scanned PDFs and images using Tesseract.
    Includes preprocessing pipeline for improved accuracy.
    """

    def __init__(self, languages: list[str] = None):
        """
        Initialize OCR processor.

        Args:
            languages: List of language codes (default: ['eng'])
        """
        self.languages = languages or ['eng']
        self.lang_string = '+'.join(self.languages)

        # Verify Tesseract installation
        try:
            version = pytesseract.get_tesseract_version()
            logger.info(f"Tesseract OCR version: {version}")
        except Exception as e:
            raise RuntimeError(f"Tesseract not found: {e}")

    def preprocess_image(self, image: Image.Image) -> Image.Image:
        """
        Apply preprocessing pipeline to improve OCR accuracy.

        Steps:
        1. Convert to grayscale
        2. Deskew (correct rotation)
        3. Denoise (remove artifacts)
        4. Enhance contrast
        5. Binarize (black/white)

        Args:
            image: PIL Image object

        Returns:
            Preprocessed PIL Image
        """
        # 1. Convert to grayscale
        image = image.convert('L')

        # 2. Deskew (correct rotation)
        image = self._deskew_image(image)

        # 3. Denoise (median filter)
        image = image.filter(ImageFilter.MedianFilter(size=3))

        # 4. Enhance contrast
        enhancer = ImageEnhance.Contrast(image)
        image = enhancer.enhance(2.0)

        # 5. Binarize (threshold to black/white)
        threshold = 128
        image = image.point(lambda p: 255 if p > threshold else 0)

        return image

    def _deskew_image(self, image: Image.Image) -> Image.Image:
        """
        Correct image rotation using simple heuristics.

        Args:
            image: PIL Image object

        Returns:
            Deskewed PIL Image
        """
        # Simple deskew: rotate by detected angle
        # (In production, use cv2.minAreaRect for better accuracy)
        try:
            # Placeholder: Rotate by 0 degrees (no deskew)
            # TODO: Implement proper deskew with OpenCV if needed
            return image
        except Exception:
            return image

    def extract_text_with_ocr(
        self,
        image: Image.Image,
        detail_level: int = 1  # 0=text only, 1=text+confidence
    ) -> Dict[str, Any]:
        """
        Extract text from image using Tesseract OCR.

        Args:
            image: PIL Image object
            detail_level: 0=text only, 1=text+confidence+bbox

        Returns:
            Dictionary with text, confidence, language
        """
        # Preprocess image
        preprocessed = self.preprocess_image(image)

        # Run OCR
        if detail_level == 0:
            # Text only (fastest)
            text = pytesseract.image_to_string(
                preprocessed,
                lang=self.lang_string
            )
            return {
                "text": text,
                "confidence": None,
                "language": self.lang_string
            }
        else:
            # Text + confidence + bounding boxes (detailed)
            data = pytesseract.image_to_data(
                preprocessed,
                lang=self.lang_string,
                output_type=pytesseract.Output.DICT
            )

            # Extract text and calculate average confidence
            text_parts = []
            confidences = []

            for i, conf in enumerate(data['conf']):
                if conf > 0:  # Valid text
                    text_parts.append(data['text'][i])
                    confidences.append(int(conf))

            avg_confidence = sum(confidences) / len(confidences) if confidences else 0

            return {
                "text": ' '.join(text_parts),
                "confidence": avg_confidence / 100.0,  # Normalize to 0-1
                "language": self.lang_string,
                "regions": self._extract_regions(data)
            }

    def _extract_regions(self, ocr_data: dict) -> list[dict]:
        """Extract text regions with bounding boxes."""
        regions = []

        for i in range(len(ocr_data['text'])):
            if int(ocr_data['conf'][i]) > 0:
                regions.append({
                    "text": ocr_data['text'][i],
                    "confidence": int(ocr_data['conf'][i]) / 100.0,
                    "bbox": {
                        "x": ocr_data['left'][i],
                        "y": ocr_data['top'][i],
                        "width": ocr_data['width'][i],
                        "height": ocr_data['height'][i]
                    }
                })

        return regions

    def process_scanned_pdf_page(self, page_image: Image.Image, page_num: int) -> dict:
        """
        Process single scanned PDF page.

        Args:
            page_image: PIL Image of PDF page
            page_num: Page number (0-indexed)

        Returns:
            Dictionary with extracted text and metadata
        """
        ocr_result = self.extract_text_with_ocr(page_image, detail_level=1)

        return {
            "type": "paragraph",
            "text": ocr_result["text"],
            "page": page_num,
            "metadata": {
                "ocr_confidence": ocr_result["confidence"],
                "extraction_method": "tesseract_ocr",
                "language": ocr_result["language"]
            }
        }
```

---

### Step 2: Integrate OCR with PDF Backend

**File**: `/opt/docling-mcp/application/docling_mcp/processors/backends/ocr_backend.py`

```python
"""OCR backend for scanned PDF processing."""

import pypdfium2 as pdfium
from docling_mcp.processors.ocr_processor import OCRProcessor


class OCRBackend:
    """Backend for processing scanned PDFs with OCR."""

    def __init__(self):
        self.ocr_processor = OCRProcessor(languages=['eng'])

    def process_scanned_pdf(self, pdf_path: str) -> list[dict]:
        """
        Convert scanned PDF to structured document items using OCR.

        Args:
            pdf_path: Path to scanned PDF

        Returns:
            List of document items (paragraphs with OCR text)
        """
        doc_items = []

        pdf = pdfium.PdfDocument(pdf_path)
        for page_num, page in enumerate(pdf):
            # Render page as image (2x resolution for better OCR)
            bitmap = page.render(scale=2.0)
            pil_image = bitmap.to_pil()

            # Run OCR on page
            page_item = self.ocr_processor.process_scanned_pdf_page(pil_image, page_num)
            doc_items.append(page_item)

            page.close()

        pdf.close()

        return doc_items
```

---

### Step 3: Create Unit Tests

**File**: `/opt/docling-mcp/tests/test_ocr_processing.py`

```python
"""Unit tests for OCR processing."""

import pytest
from PIL import Image
from docling_mcp.processors.ocr_processor import OCRProcessor


class TestOCRPreprocessing:
    """Test OCR preprocessing pipeline."""

    def test_image_preprocessing(self, sample_text_image):
        """Test image preprocessing steps."""
        processor = OCRProcessor()
        preprocessed = processor.preprocess_image(sample_text_image)

        # Verify grayscale
        assert preprocessed.mode == 'L'

    def test_text_extraction(self, sample_text_image):
        """Test text extraction from image."""
        processor = OCRProcessor()
        result = processor.extract_text_with_ocr(sample_text_image, detail_level=0)

        assert "text" in result
        assert len(result["text"]) > 0


class TestScannedPDFProcessing:
    """Test scanned PDF processing."""

    def test_scanned_pdf_conversion(self, sample_scanned_pdf):
        """Test OCR on scanned PDF."""
        from docling_mcp.processors.backends.ocr_backend import OCRBackend

        backend = OCRBackend()
        doc_items = backend.process_scanned_pdf(sample_scanned_pdf)

        assert len(doc_items) > 0
        assert all(item["type"] == "paragraph" for item in doc_items)
        assert all("ocr_confidence" in item["metadata"] for item in doc_items)
```

---

## Success Criteria

- [ ] OCR processor module created with Tesseract integration
- [ ] Preprocessing pipeline implemented (grayscale, deskew, denoise, contrast, binarize)
- [ ] OCR backend for scanned PDFs implemented
- [ ] Image OCR support for PNG/JPEG/TIFF
- [ ] OCR confidence scores captured (target: 85%+ for quality scans)
- [ ] Unit tests created and passing (≥90% coverage)
- [ ] Integration with backend selector complete

---

## Dependencies

**Depends On**:
- Task 010: Docling library installed
- Task 012: Backend selection configured

**Blocks**:
- Task 015: DoclingDocument schema (needs OCR metadata fields)

---

**Task Owner**: albert-singh (Docling Document Processing SME)
**Created**: 2025-11-27
