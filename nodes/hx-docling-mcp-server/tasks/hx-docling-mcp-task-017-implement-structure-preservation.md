# Task 017: Implement Document Structure Preservation

**Task ID**: hx-docling-mcp-task-017
**Component**: Docling Document Processing (albert-singh)
**Category**: Implementation
**Priority**: HIGH (core feature)
**Estimated Effort**: 4-5 hours
**Status**: NOT_STARTED

---

## Objective

Implement comprehensive structure preservation for document conversion, extracting and maintaining headings, tables, lists, code blocks, images, and footnotes with hierarchical relationships intact.

---

## Prerequisites

- [x] Task 010: Docling library installed
- [x] Task 011: Format detection configured
- [x] Task 012: Backend selection configured

---

## Technical Context

**From albert-docling-processing.md** (Section 3: Structure Preservation, lines 425-691):
- **Heading Detection**: Font-based heuristics (PDF), style-based (DOCX), semantic tags (HTML)
- **Table Extraction**: Cell boundaries, merged cells, header rows, multi-page tables
- **List Detection**: Ordered/unordered, nesting levels, indentation-based
- **Code Block Detection**: Monospace fonts, syntax highlighting, language detection
- **Image Extraction**: Inline images, captions, alt text, position preservation
- **Footnote Extraction**: Reference linking, superscript detection

---

## Implementation Steps

### Step 1: Implement Heading Extraction

**File**: `/opt/docling-mcp/application/docling_mcp/processors/structure/heading_extractor.py`

```python
"""Heading detection and hierarchy extraction."""

import logging
from typing import List, Dict, Any, Optional
from docling.datamodel.document import DoclingDocument

logger = logging.getLogger(__name__)


class HeadingExtractor:
    """Extract heading hierarchy from documents."""
    
    # Configurable font-size thresholds (in points)
    FONT_SIZE_THRESHOLDS = {
        1: 18.0,  # H1: >= 18pt
        2: 16.0,  # H2: >= 16pt
        3: 14.0,  # H3: >= 14pt
        4: 12.0,  # H4: >= 12pt
        5: 11.0,  # H5: >= 11pt
        6: 10.0,  # H6: >= 10pt
    }
    
    # Case-insensitive style name mapping with variants
    STYLE_NAME_MAPPING = {
        # Standard heading styles
        'heading 1': 1, 'heading1': 1, 'heading_1': 1, 'h1': 1, 'title': 1,
        'heading 2': 2, 'heading2': 2, 'heading_2': 2, 'h2': 2, 'subtitle': 2,
        'heading 3': 3, 'heading3': 3, 'heading_3': 3, 'h3': 3,
        'heading 4': 4, 'heading4': 4, 'heading_4': 4, 'h4': 4,
        'heading 5': 5, 'heading5': 5, 'heading_5': 5, 'h5': 5,
        'heading 6': 6, 'heading6': 6, 'heading_6': 6, 'h6': 6,
        # Common international variants
        'titel': 1, 'titre': 1, 'título': 1, '标题': 1,
        'untertitel': 2, 'sous-titre': 2, 'subtítulo': 2, '副标题': 2,
    }

    def extract_headings(self, doc: DoclingDocument) -> List[Dict[str, Any]]:
        """
        Extract headings with hierarchy levels.
        
        Only includes headings with reliably detected levels (1-6).
        Items with no detectable level are filtered out.

        Returns:
            List of heading dictionaries with text, level, style, position
        """
        headings = []

        for item in doc.doc_items:
            if item.label == "heading" or self._is_heading_by_style(item):
                level = self._detect_heading_level(item)
                
                # Filter out items where level could not be reliably detected
                if level is None:
                    logger.debug(
                        f"Skipping heading with no reliable level: {getattr(item, 'text', 'unknown')[:50]}"
                    )
                    continue
                
                heading_data = {
                    "type": "heading",
                    "level": level,
                    "text": getattr(item, 'text', ''),
                    "style": self._extract_style(item),
                    "position": self._extract_position(item)
                }
                headings.append(heading_data)

        return headings

    def _detect_heading_level(self, item) -> Optional[int]:
        """
        Detect heading level (1-6) from font size/style.
        
        Returns:
            Level 1-6 if reliably detected, None otherwise
        """
        level = None
        
        # Strategy 1: Try style-based detection first (most reliable)
        style_level = self._detect_level_by_style(item)
        if style_level is not None:
            level = style_level
        
        # Strategy 2: Try font-size based detection for PDFs
        elif hasattr(item, 'font_size') and item.font_size:
            font_size = item.font_size
            try:
                font_size = float(font_size)
                
                # Find appropriate level based on thresholds
                for heading_level in range(1, 7):
                    if font_size >= self.FONT_SIZE_THRESHOLDS[heading_level]:
                        level = heading_level
                        break
                
                # If below all thresholds, can't reliably determine
                if level is None:
                    logger.debug(f"Font size {font_size}pt below minimum threshold for H6")
                    
            except (ValueError, TypeError):
                logger.warning(f"Could not parse font_size: {font_size}")
        
        # Validate level is within bounds [1, 6]
        if level is not None and not (1 <= level <= 6):
            logger.warning(f"Computed level {level} outside valid range [1, 6], rejecting")
            return None
        
        return level

    def _detect_level_by_style(self, item) -> Optional[int]:
        """
        Detect heading level from style name with case-insensitive matching.
        
        Returns:
            Level 1-6 if matched, None otherwise
        """
        if not hasattr(item, 'style_name') or not item.style_name:
            return None
        
        style_name = str(item.style_name).strip().lower()
        
        if not style_name:
            return None
        
        # Direct lookup in mapping
        if style_name in self.STYLE_NAME_MAPPING:
            return self.STYLE_NAME_MAPPING[style_name]
        
        # Fuzzy matching for partial matches (e.g., "MyHeading 1" contains "heading 1")
        for style_key, level in self.STYLE_NAME_MAPPING.items():
            if style_key in style_name:
                return level
        
        return None
```

---

### Step 2: Implement Table Extraction

**File**: `/opt/docling-mcp/application/docling_mcp/processors/structure/table_extractor.py`

```python
"""Table structure extraction with merged cell support."""

import logging
from typing import List, Dict, Any, Optional
from docling.datamodel.document import DoclingDocument

logger = logging.getLogger(__name__)


class TableExtractor:
    """Extract table structures from documents using Docling's TableData model."""

    def extract_tables(self, doc: DoclingDocument) -> List[Dict[str, Any]]:
        """
        Extract tables with cell structure, merged cells, headers.
        
        Uses Docling's TableData model (item.data) with proper attribute names:
        - item.data.grid: List[List[TableCell]] 
        - cell.row_span / cell.col_span (not colspan/rowspan)
        - cell.column_header / cell.row_header (not assumption about first row)

        Returns:
            List of table dictionaries
        """
        tables = []

        for item in doc.doc_items:
            if item.label == "table":
                try:
                    table_data = {
                        "type": "table",
                        "num_rows": self._count_rows(item),
                        "num_cols": self._count_cols(item),
                        "headers": self._extract_headers(item),
                        "cells": self._extract_cells(item),
                        "position": self._extract_position(item)
                    }
                    tables.append(table_data)
                except Exception as e:
                    logger.error(f"Failed to extract table: {e}", exc_info=True)

        return tables

    def _count_rows(self, table_item) -> int:
        """Count number of rows in the table."""
        if hasattr(table_item, 'data') and table_item.data:
            return getattr(table_item.data, 'num_rows', 0)
        return 0

    def _count_cols(self, table_item) -> int:
        """Count number of columns in the table."""
        if hasattr(table_item, 'data') and table_item.data:
            return getattr(table_item.data, 'num_cols', 0)
        return 0

    def _extract_headers(self, table_item) -> List[str]:
        """
        Extract header texts from cells marked with column_header=True.
        
        Does not assume first row is header; instead uses cell.column_header attribute.
        """
        headers = []
        
        if not hasattr(table_item, 'data') or not table_item.data:
            return headers
        
        # Collect texts from cells with column_header=True
        table_cells = getattr(table_item.data, 'table_cells', [])
        for cell in table_cells:
            if getattr(cell, 'column_header', False):
                text = getattr(cell, 'text', '').strip()
                if text:
                    headers.append(text)
        
        return headers

    def _extract_cells(self, table_item) -> List[Dict[str, Any]]:
        """
        Extract individual cells with row_span/col_span and header detection.
        
        Iterates item.data.grid (List[List[TableCell]]) and reads:
        - cell.row_span (not rowspan)
        - cell.col_span (not colspan)
        - cell.column_header / cell.row_header (not first row assumption)
        """
        cells = []

        if not hasattr(table_item, 'data') or not table_item.data:
            return cells
        
        grid = getattr(table_item.data, 'grid', [])
        
        for row_idx, row in enumerate(grid):
            if not isinstance(row, list):
                logger.warning(f"Grid row {row_idx} is not a list, skipping")
                continue
            
            for col_idx, cell in enumerate(row):
                if cell is None:
                    continue
                
                try:
                    cell_data = {
                        "row": row_idx,
                        "col": col_idx,
                        "text": getattr(cell, 'text', ''),
                        "row_span": getattr(cell, 'row_span', 1),
                        "col_span": getattr(cell, 'col_span', 1),
                        "is_column_header": getattr(cell, 'column_header', False),
                        "is_row_header": getattr(cell, 'row_header', False)
                    }
                    cells.append(cell_data)
                except Exception as e:
                    logger.warning(f"Failed to extract cell at ({row_idx}, {col_idx}): {e}")

        return cells

    def _extract_position(self, table_item) -> Optional[Dict[str, Any]]:
        """
        Extract position information from table item.
        
        Reads page_no and bbox attributes with safe defaults.
        """
        if not table_item:
            return None
        
        position = {}
        
        # Extract page number
        page_no = getattr(table_item, 'page_no', None)
        if page_no is not None:
            position['page'] = page_no
        
        # Extract bounding box
        bbox = getattr(table_item, 'bbox', None)
        if bbox is not None:
            # bbox might be a tuple/list [x0, y0, x1, y1] or an object
            if hasattr(bbox, '__iter__') and not isinstance(bbox, (str, dict)):
                try:
                    bbox_list = list(bbox)
                    if len(bbox_list) >= 4:
                        position['bbox'] = {
                            'x0': bbox_list[0],
                            'y0': bbox_list[1],
                            'x1': bbox_list[2],
                            'y1': bbox_list[3]
                        }
                except (TypeError, ValueError, IndexError) as e:
                    logger.debug(f"Could not parse bbox: {e}")
            elif isinstance(bbox, dict):
                position['bbox'] = bbox
        
        return position if position else None
```

---

### Step 3: Implement List Detection

**File**: `/opt/docling-mcp/application/docling_mcp/processors/structure/list_extractor.py`

```python
"""List detection (ordered/unordered) with nesting."""

import re
import logging
from typing import List, Dict

logger = logging.getLogger(__name__)


class ListExtractor:
    """Extract ordered and unordered lists."""

    # Expanded to include international numbering patterns
    ORDERED_MARKERS = re.compile(
        r'^('
        r'\d+|'  # Arabic numerals: 1, 2, 3
        r'[a-zA-Z]|'  # Latin letters: a, b, c, A, B, C
        r'[ivxIVX]+|'  # Roman numerals: i, ii, iii, IV, V
        r'[一二三四五六七八九十]+|'  # Chinese numerals
        r'[壱弐参四五六七八九拾]+|'  # Japanese formal numerals
        r'[壹貳參肆伍陸柒捌玖拾]+'  # Traditional Chinese numerals
        r')[.)）]'  # Followed by period, closing paren, or fullwidth paren
    )
    UNORDERED_MARKERS = ['•', '-', '*', '◦', '▪', '○', '■', '□', '–', '—']

    def extract_lists(self, doc) -> List[Dict]:
        """
        Extract lists with nesting levels.

        Returns:
            List of list dictionaries (ordered/unordered)
        """
        lists = []
        current_list = None

        for item in doc.doc_items:
            if item.label == "list_item" or self._is_list_item(item):
                list_type, marker = self._detect_list_type(item.text)
                level = self._detect_nesting_level(item)

                if current_list is None or current_list["type"] != list_type:
                    # Start new list
                    current_list = {
                        "type": list_type,
                        "items": []
                    }
                    lists.append(current_list)

                current_list["items"].append({
                    "text": self._clean_list_item_text(item.text),
                    "level": level,
                    "marker": marker
                })

        return lists

    def _is_list_item(self, item) -> bool:
        """Check if item is a list item based on label."""
        # Common list item labels in document processing
        list_labels = {
            'list_item',
            'list-item',
            'bullet',
            'bullet_list_item',
            'numbered_list_item',
            'ordered_list_item',
            'unordered_list_item'
        }
        return getattr(item, 'label', '').lower() in list_labels

    def _detect_nesting_level(self, item) -> int:
        """Detect nesting level from indent attribute."""
        # Try to get indent from various possible attributes
        indent = getattr(item, 'indent', None) or getattr(item, 'indentation', 0)
        
        if indent is None:
            return 0
        
        # Use safe divisor for indentation (typically 20-40 pixels per level)
        # Default to 30 pixels per indentation level
        indent_per_level = 30
        
        try:
            level = int(indent) // indent_per_level
            return max(0, level)  # Ensure non-negative
        except (ValueError, TypeError):
            logger.warning(f"Could not parse indent value: {indent}")
            return 0

    def _clean_list_item_text(self, text: str) -> str:
        """Strip ordered/unordered markers from list item text."""
        if not text:
            return ""
        
        text = text.strip()
        
        # Remove ordered markers (numbers, letters, roman numerals with punctuation)
        text = self.ORDERED_MARKERS.sub('', text)
        
        # Remove unordered markers
        for marker in self.UNORDERED_MARKERS:
            if text.startswith(marker):
                text = text[len(marker):]
                break
        
        # Clean up extra whitespace
        return text.strip()

    def _detect_list_type(self, text: str):
        """Detect ordered vs unordered list."""
        text_stripped = text.strip()
        
        match = self.ORDERED_MARKERS.match(text_stripped)
        if match:
            marker = match.group(1)  # Extract the marker part
            return "ordered_list", marker
        
        for marker in self.UNORDERED_MARKERS:
            if text_stripped.startswith(marker):
                return "unordered_list", marker
        
        return "unordered_list", "•"
```

---

### Step 4: Implement Image Extraction

**File**: `/opt/docling-mcp/application/docling_mcp/processors/structure/image_extractor.py`

```python
"""Image extraction with captions and metadata."""

import base64
import logging
from typing import List, Dict, Union

logger = logging.getLogger(__name__)


class ImageExtractor:
    """Extract images from documents."""

    def extract_images(self, doc) -> List[Dict]:
        """
        Extract images with captions, alt text, metadata.

        Returns:
            List of image dictionaries
        """
        images = []

        for item in doc.doc_items:
            if item.label == "image":
                # Check if item has image_data before using it
                if not hasattr(item, 'image_data') or item.image_data is None:
                    logger.warning(
                        f"Image item missing image_data, skipping: {getattr(item, 'self_ref', 'unknown')}"
                    )
                    continue
                
                try:
                    image_data = {
                        "type": "image",
                        "format": self._detect_format(item),
                        "encoding": "base64",
                        "data": self._encode_image(item.image_data),
                        "width": getattr(item, 'width', None),
                        "height": getattr(item, 'height', None),
                        "caption": self._extract_caption(item),
                        "alt_text": getattr(item, 'alt_text', None),
                        "position": self._extract_position(item)
                    }
                    images.append(image_data)
                except Exception as e:
                    logger.error(
                        f"Failed to extract image: {getattr(item, 'self_ref', 'unknown')}",
                        exc_info=True
                    )

        return images

    def _encode_image(self, image_data: Union[bytes, str]) -> str:
        """
        Encode image to base64 string.
        
        Args:
            image_data: Either raw bytes or already-encoded base64 string
            
        Returns:
            Base64-encoded string
            
        Raises:
            ValueError: If image_data is neither bytes nor str
        """
        if isinstance(image_data, str):
            # Already encoded, return as-is
            return image_data
        elif isinstance(image_data, bytes):
            # Encode bytes to base64
            return base64.b64encode(image_data).decode('utf-8')
        else:
            raise ValueError(
                f"image_data must be bytes or str, got {type(image_data).__name__}"
            )
```

---

### Step 5: Create Unified Structure Extractor

**File**: `/opt/docling-mcp/application/docling_mcp/processors/structure_extractor.py`

```python
"""Unified structure extraction orchestrator."""

import logging
from .structure.heading_extractor import HeadingExtractor
from .structure.table_extractor import TableExtractor
from .structure.list_extractor import ListExtractor
from .structure.image_extractor import ImageExtractor

logger = logging.getLogger(__name__)


class StructureExtractor:
    """Orchestrate all structure extraction."""

    def __init__(self):
        self.heading_extractor = HeadingExtractor()
        self.table_extractor = TableExtractor()
        self.list_extractor = ListExtractor()
        self.image_extractor = ImageExtractor()

    def extract_structure(self, doc) -> dict:
        """
        Extract all document structures with graceful degradation.
        
        If an extractor fails, logs the error and returns an empty list
        for that component, allowing partial results.

        Args:
            doc: Docling document object

        Returns:
            Dictionary with headings, tables, lists, images
        """
        # Initialize result with default empty lists
        result = {
            "headings": [],
            "tables": [],
            "lists": [],
            "images": []
        }
        
        # Map result keys to extractor callables
        extractors = [
            ("headings", self.heading_extractor.extract_headings),
            ("tables", self.table_extractor.extract_tables),
            ("lists", self.list_extractor.extract_lists),
            ("images", self.image_extractor.extract_images)
        ]
        
        # Extract each structure type with error handling
        for key, extractor_func in extractors:
            try:
                result[key] = extractor_func(doc)
            except Exception as e:
                logger.error(
                    f"Failed to extract {key} from document",
                    exc_info=True
                )
                # result[key] remains as empty list (default)
        
        return result
```

---

### Step 6: Create Unit Tests

**File**: `/opt/docling-mcp/tests/test_structure_extraction.py`

```python
"""Unit tests for structure preservation."""

import pytest
from unittest.mock import Mock


# ============================================================================
# Fixtures - Mock Docling Document Objects
# ============================================================================

@pytest.fixture
def sample_doc_with_headings():
    """Mock DoclingDocument with known heading structure."""
    doc = Mock()
    doc.doc_items = [
        Mock(label="title", text="Main Title", level=1, self_ref="h1"),
        Mock(label="section_header", text="Introduction", level=2, self_ref="h2_1"),
        Mock(label="section_header", text="Background", level=2, self_ref="h2_2"),
        Mock(label="section_header", text="Subsection", level=3, self_ref="h3_1"),
    ]
    return doc


@pytest.fixture
def sample_doc_with_tables():
    """Mock DoclingDocument with known table structure."""
    doc = Mock()
    
    # Create mock table with cells
    table_item = Mock(
        label="table",
        num_rows=3,
        num_cols=2,
        self_ref="table1"
    )
    table_item.get_cells = Mock(return_value=[
        Mock(row=0, col=0, text="Header 1", row_span=1, col_span=1),
        Mock(row=0, col=1, text="Header 2", row_span=1, col_span=1),
        Mock(row=1, col=0, text="Row 1 Col 1", row_span=1, col_span=1),
        Mock(row=1, col=1, text="Row 1 Col 2", row_span=1, col_span=1),
        Mock(row=2, col=0, text="Row 2 Col 1", row_span=1, col_span=1),
        Mock(row=2, col=1, text="Row 2 Col 2", row_span=1, col_span=1),
    ])
    
    doc.doc_items = [table_item]
    return doc


@pytest.fixture
def sample_doc_with_lists():
    """Mock DoclingDocument with known list structure."""
    doc = Mock()
    doc.doc_items = [
        Mock(label="list_item", text="First item", enumeration="1", level=0),
        Mock(label="list_item", text="Second item", enumeration="2", level=0),
        Mock(label="list_item", text="Nested item", enumeration="a", level=1),
    ]
    return doc


@pytest.fixture
def malformed_doc():
    """Mock document with missing/malformed attributes."""
    doc = Mock()
    doc.doc_items = None  # Simulate missing doc_items
    return doc


@pytest.fixture
def composite_doc():
    """Mock document with multiple structure types for integration testing."""
    doc = Mock()
    
    # Create table with cells
    table = Mock(label="table", num_rows=2, num_cols=2, self_ref="t1")
    table.get_cells = Mock(return_value=[
        Mock(row=0, col=0, text="A1", row_span=1, col_span=1),
        Mock(row=0, col=1, text="B1", row_span=1, col_span=1),
        Mock(row=1, col=0, text="A2", row_span=1, col_span=1),
        Mock(row=1, col=1, text="B2", row_span=1, col_span=1),
    ])
    
    doc.doc_items = [
        Mock(label="title", text="Test Document", level=1, self_ref="h1"),
        Mock(label="section_header", text="Section 1", level=2, self_ref="h2"),
        Mock(label="list_item", text="Item 1", enumeration="1", level=0),
        table,
    ]
    return doc


# ============================================================================
# Heading Extraction Tests
# ============================================================================

class TestHeadingExtraction:
    """Test heading extraction with exact output verification."""

    def test_heading_levels_exact(self, sample_doc_with_headings):
        """Test heading level detection with exact expected output."""
        from docling_mcp.processors.structure.heading_extractor import HeadingExtractor

        extractor = HeadingExtractor()
        headings = extractor.extract_headings(sample_doc_with_headings)

        # Exact count check
        assert len(headings) == 4
        
        # Exact content and level checks
        assert headings[0]["text"] == "Main Title"
        assert headings[0]["level"] == 1
        
        assert headings[1]["text"] == "Introduction"
        assert headings[1]["level"] == 2
        
        assert headings[2]["text"] == "Background"
        assert headings[2]["level"] == 2
        
        assert headings[3]["text"] == "Subsection"
        assert headings[3]["level"] == 3

    def test_heading_extraction_malformed_doc(self, malformed_doc):
        """Test heading extractor handles malformed documents gracefully."""
        from docling_mcp.processors.structure.heading_extractor import HeadingExtractor

        extractor = HeadingExtractor()
        headings = extractor.extract_headings(malformed_doc)

        # Should return empty list, not raise exception
        assert headings == []


# ============================================================================
# Table Extraction Tests
# ============================================================================

class TestTableExtraction:
    """Test table extraction with exact output verification."""

    def test_table_structure_exact(self, sample_doc_with_tables):
        """Test table extraction with exact dimensions and content."""
        from docling_mcp.processors.structure.table_extractor import TableExtractor

        extractor = TableExtractor()
        tables = extractor.extract_tables(sample_doc_with_tables)

        # Exact count and structure
        assert len(tables) == 1
        
        table = tables[0]
        assert table["num_rows"] == 3
        assert table["num_cols"] == 2
        assert len(table["cells"]) == 6
        
        # Exact cell content verification
        cells = table["cells"]
        assert cells[0]["text"] == "Header 1"
        assert cells[0]["row"] == 0
        assert cells[0]["col"] == 0
        
        assert cells[1]["text"] == "Header 2"
        assert cells[1]["row"] == 0
        assert cells[1]["col"] == 1
        
        assert cells[2]["text"] == "Row 1 Col 1"
        assert cells[3]["text"] == "Row 1 Col 2"
        assert cells[4]["text"] == "Row 2 Col 1"
        assert cells[5]["text"] == "Row 2 Col 2"

    def test_table_extraction_malformed_doc(self, malformed_doc):
        """Test table extractor handles malformed documents gracefully."""
        from docling_mcp.processors.structure.table_extractor import TableExtractor

        extractor = TableExtractor()
        tables = extractor.extract_tables(malformed_doc)

        # Should return empty list, not raise exception
        assert tables == []


# ============================================================================
# List Extraction Tests
# ============================================================================

class TestListExtraction:
    """Test list extraction with exact output verification."""

    def test_list_nesting_exact(self, sample_doc_with_lists):
        """Test list extraction with exact nesting and content."""
        from docling_mcp.processors.structure.list_extractor import ListExtractor

        extractor = ListExtractor()
        lists = extractor.extract_lists(sample_doc_with_lists)

        # Exact count
        assert len(lists) == 3
        
        # Exact content and nesting
        assert lists[0]["text"] == "First item"
        assert lists[0]["level"] == 0
        assert lists[0]["enumeration"] == "1"
        
        assert lists[1]["text"] == "Second item"
        assert lists[1]["level"] == 0
        assert lists[1]["enumeration"] == "2"
        
        assert lists[2]["text"] == "Nested item"
        assert lists[2]["level"] == 1
        assert lists[2]["enumeration"] == "a"

    def test_list_extraction_malformed_doc(self, malformed_doc):
        """Test list extractor handles malformed documents gracefully."""
        from docling_mcp.processors.structure.list_extractor import ListExtractor

        extractor = ListExtractor()
        lists = extractor.extract_lists(malformed_doc)

        # Should return empty list, not raise exception
        assert lists == []


# ============================================================================
# Unified Structure Extractor Integration Tests
# ============================================================================

class TestStructureExtractorIntegration:
    """Integration tests for unified structure extraction."""

    def test_unified_extraction_composite_doc(self, composite_doc):
        """Test StructureExtractor extracts all structure types from composite doc."""
        from docling_mcp.processors.structure_extractor import StructureExtractor

        extractor = StructureExtractor()
        result = extractor.extract_structure(composite_doc)

        # Verify all structure types present
        assert "headings" in result
        assert "tables" in result
        assert "lists" in result
        assert "images" in result
        
        # Exact counts from composite fixture
        assert len(result["headings"]) == 2  # title + section_header
        assert len(result["tables"]) == 1
        assert len(result["lists"]) == 1
        assert len(result["images"]) == 0  # No images in fixture
        
        # Verify specific content
        assert result["headings"][0]["text"] == "Test Document"
        assert result["headings"][1]["text"] == "Section 1"
        assert result["tables"][0]["num_rows"] == 2
        assert result["tables"][0]["num_cols"] == 2
        assert result["lists"][0]["text"] == "Item 1"

    def test_unified_extraction_graceful_degradation(self, malformed_doc):
        """Test StructureExtractor returns partial results on extractor failures."""
        from docling_mcp.processors.structure_extractor import StructureExtractor

        extractor = StructureExtractor()
        result = extractor.extract_structure(malformed_doc)

        # Should return dict with all keys, empty lists for failed extractors
        assert isinstance(result, dict)
        assert "headings" in result
        assert "tables" in result
        assert "lists" in result
        assert "images" in result
        
        # All should be empty lists due to malformed doc
        assert result["headings"] == []
        assert result["tables"] == []
        assert result["lists"] == []
        assert result["images"] == []
```

---

## Success Criteria

- [ ] Heading extractor implemented with level detection (H1-H6)
- [ ] Table extractor handles merged cells, headers, multi-page tables
- [ ] List extractor detects nesting levels, ordered/unordered markers
- [ ] Image extractor preserves captions, alt text, metadata
- [ ] Code block and footnote extractors implemented
- [ ] Unit tests created and passing (≥95% coverage)
- [ ] Integration with DoclingProcessor complete

---

## Dependencies

**Depends On**:
- Task 010: Docling library installed
- Task 011: Format detection
- Task 012: Backend selection

**Blocks**:
- Task 014: OCR integration
- Task 015: DoclingDocument schema implementation

---

**Task Owner**: albert-singh (Docling Document Processing SME)
**Created**: 2025-11-27
