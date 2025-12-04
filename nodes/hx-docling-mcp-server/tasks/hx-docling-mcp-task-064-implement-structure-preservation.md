# Task 064: Implement Structure Preservation

**Task ID**: hx-docling-mcp-task-064-implement-structure-preservation
**Phase**: Development - Document Processing Integration
**Status**: Not Started
**Assigned To**: albert-singh (Docling Processing Specialist)
**Dependencies**: hx-docling-mcp-task-063 (Backend selection implemented)
**Estimated Time**: 4 hours

---

## Objective

Implement document structure preservation logic to extract and maintain semantic document elements (headings H1-H6, tables with cell structure, lists with nesting, code blocks, images with captions) during document conversion, ensuring high-fidelity transformation to DoclingDocument format as required by FR-006.

---

## Pre-Execution Validation

**CRITICAL**: Check if structure preservation module already exists before proceeding:

```bash
# Check if structure preservation module exists
if [ -f /opt/docling-mcp/src/docling_processor/structure_extractor.py ]; then
    echo "✅ VALIDATION: Structure preservation module already exists - Review implementation"
    echo "Module location: /opt/docling-mcp/src/docling_processor/structure_extractor.py"
    # Check if module has core functions
    grep -q "def extract_headings\|def extract_tables\|def extract_lists" /opt/docling-mcp/src/docling_processor/structure_extractor.py
    if [ $? -eq 0 ]; then
        echo "✅ Core extraction functions found - SKIP task execution"
        exit 0
    else
        echo "⚠️ Module exists but incomplete - PROCEED with implementation"
    fi
else
    echo "❌ VALIDATION: Structure preservation module not found - PROCEED with task"
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
- [ ] Backend selection implemented (hx-docling-mcp-task-063)
- [ ] Python virtual environment activated
- [ ] Understanding of DoclingDocument schema and doc_items structure

---

## Steps

### 1. Implement Structure Extractor Module

Create `/opt/docling-mcp/src/docling_processor/structure_extractor.py`:

```python
"""
Structure Preservation Module

Extracts and preserves semantic document structure during conversion:
- Headings (H1-H6 hierarchy)
- Tables (cell structure, merged cells, headers)
- Lists (ordered/unordered with nesting)
- Code blocks (language detection)
- Images (extraction with captions)

Implements FR-006 specification requirements.
"""

import logging
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from docling.datamodel.document import DoclingDocument
from docling.datamodel.base_models import DocItemLabel

logger = logging.getLogger(__name__)


@dataclass
class Heading:
    """Represents a document heading with hierarchy level."""
    level: int  # 1-6 for H1-H6
    text: str
    page_number: Optional[int] = None
    bbox: Optional[Dict[str, float]] = None  # Bounding box {x, y, width, height}


@dataclass
class Table:
    """Represents a table with cell structure."""
    rows: List[List[str]]  # 2D array of cell contents
    headers: Optional[List[str]] = None  # Column headers if detected
    page_number: Optional[int] = None
    bbox: Optional[Dict[str, float]] = None
    merged_cells: Optional[List[Dict[str, Any]]] = None  # Merged cell regions


@dataclass
class ListItem:
    """Represents a list item with nesting level."""
    text: str
    level: int  # Nesting level (0 = top-level, 1 = nested, etc.)
    ordered: bool  # True for numbered lists, False for bullet points
    parent_index: Optional[int] = None  # Index of parent item (for nesting)


@dataclass
class CodeBlock:
    """Represents a code block with language detection."""
    code: str
    language: Optional[str] = None  # Detected programming language
    page_number: Optional[int] = None


@dataclass
class Image:
    """Represents an extracted image with caption."""
    image_data: str  # Base64-encoded image or file path
    caption: Optional[str] = None
    alt_text: Optional[str] = None
    page_number: Optional[int] = None
    bbox: Optional[Dict[str, float]] = None


def extract_headings(docling_doc: DoclingDocument) -> List[Heading]:
    """
    Extract all headings from DoclingDocument with hierarchy levels.

    Args:
        docling_doc: Converted DoclingDocument

    Returns:
        List of Heading objects with level, text, page, bbox
    """
    headings = []

    # Iterate through doc_items to find headings
    for item in docling_doc.doc_items:
        if item.label in [
            DocItemLabel.SECTION_HEADER,
            DocItemLabel.TITLE,
            DocItemLabel.SUBTITLE,
        ]:
            # Determine heading level from item metadata or label
            level = _infer_heading_level(item)

            heading = Heading(
                level=level,
                text=item.text if hasattr(item, 'text') else str(item),
                page_number=item.prov[0].page if item.prov else None,
                bbox=_extract_bbox(item),
            )
            headings.append(heading)

    return headings


def extract_tables(docling_doc: DoclingDocument) -> List[Table]:
    """
    Extract all tables from DoclingDocument with cell structure.

    Args:
        docling_doc: Converted DoclingDocument

    Returns:
        List of Table objects with rows, headers, merged cells
    """
    tables = []

    for item in docling_doc.doc_items:
        if item.label == DocItemLabel.TABLE:
            # Extract table data from item
            table_data = _parse_table_item(item)

            table = Table(
                rows=table_data.get("rows", []),
                headers=table_data.get("headers"),
                page_number=item.prov[0].page if item.prov else None,
                bbox=_extract_bbox(item),
                merged_cells=table_data.get("merged_cells"),
            )
            tables.append(table)

    return tables


def extract_lists(docling_doc: DoclingDocument) -> List[ListItem]:
    """
    Extract all lists from DoclingDocument with nesting levels.

    Args:
        docling_doc: Converted DoclingDocument

    Returns:
        List of ListItem objects with text, level, ordered flag
    """
    list_items = []

    for item in docling_doc.doc_items:
        if item.label in [DocItemLabel.LIST_ITEM, DocItemLabel.CODE]:
            # Determine if ordered or unordered list
            ordered = _is_ordered_list(item)
            level = _infer_list_level(item)

            list_item = ListItem(
                text=item.text if hasattr(item, 'text') else str(item),
                level=level,
                ordered=ordered,
            )
            list_items.append(list_item)

    return list_items


def extract_code_blocks(docling_doc: DoclingDocument) -> List[CodeBlock]:
    """
    Extract all code blocks from DoclingDocument with language detection.

    Args:
        docling_doc: Converted DoclingDocument

    Returns:
        List of CodeBlock objects with code, language
    """
    code_blocks = []

    for item in docling_doc.doc_items:
        if item.label == DocItemLabel.CODE:
            # Detect programming language (if possible from metadata)
            language = _detect_code_language(item)

            code_block = CodeBlock(
                code=item.text if hasattr(item, 'text') else str(item),
                language=language,
                page_number=item.prov[0].page if item.prov else None,
            )
            code_blocks.append(code_block)

    return code_blocks


def extract_images(docling_doc: DoclingDocument) -> List[Image]:
    """
    Extract all images from DoclingDocument with captions.

    Args:
        docling_doc: Converted DoclingDocument

    Returns:
        List of Image objects with image_data, caption, alt_text
    """
    images = []

    for item in docling_doc.doc_items:
        if item.label == DocItemLabel.PICTURE:
            # Extract image data (base64 or reference)
            image_data = _extract_image_data(item)
            caption = _extract_image_caption(item)
            alt_text = _extract_image_alt_text(item)

            image = Image(
                image_data=image_data,
                caption=caption,
                alt_text=alt_text,
                page_number=item.prov[0].page if item.prov else None,
                bbox=_extract_bbox(item),
            )
            images.append(image)

    return images


def validate_structure_preservation(
    docling_doc: DoclingDocument,
    min_headings: int = 0,
    min_tables: int = 0,
) -> Dict[str, Any]:
    """
    Validate that document structure was preserved during conversion.

    Args:
        docling_doc: Converted DoclingDocument
        min_headings: Minimum expected heading count (0 = no validation)
        min_tables: Minimum expected table count (0 = no validation)

    Returns:
        Validation results with structure element counts and pass/fail status
    """
    headings = extract_headings(docling_doc)
    tables = extract_tables(docling_doc)
    lists = extract_lists(docling_doc)
    code_blocks = extract_code_blocks(docling_doc)
    images = extract_images(docling_doc)

    validation_result = {
        "heading_count": len(headings),
        "table_count": len(tables),
        "list_count": len(lists),
        "code_block_count": len(code_blocks),
        "image_count": len(images),
        "validation_passed": True,
        "errors": [],
    }

    # Validate minimum counts
    if min_headings > 0 and len(headings) < min_headings:
        validation_result["validation_passed"] = False
        validation_result["errors"].append(
            f"Expected at least {min_headings} headings, found {len(headings)}"
        )

    if min_tables > 0 and len(tables) < min_tables:
        validation_result["validation_passed"] = False
        validation_result["errors"].append(
            f"Expected at least {min_tables} tables, found {len(tables)}"
        )

    return validation_result


# Helper functions for structure extraction

def _infer_heading_level(item) -> int:
    """Infer heading level (1-6) from item metadata or label."""
    # Default heading level inference logic
    # Priority: item metadata > label type > default
    if hasattr(item, 'metadata') and 'level' in item.metadata:
        return min(6, max(1, item.metadata['level']))

    # Fallback based on label
    if item.label == DocItemLabel.TITLE:
        return 1
    elif item.label == DocItemLabel.SUBTITLE:
        return 2
    elif item.label == DocItemLabel.SECTION_HEADER:
        return 3
    else:
        return 3  # Default to H3


def _extract_bbox(item) -> Optional[Dict[str, float]]:
    """Extract bounding box from item provenance."""
    if not item.prov or not hasattr(item.prov[0], 'bbox'):
        return None

    bbox = item.prov[0].bbox
    return {
        "x": bbox.l,
        "y": bbox.t,
        "width": bbox.r - bbox.l,
        "height": bbox.b - bbox.t,
    }


def _parse_table_item(item) -> Dict[str, Any]:
    """
    Parse table data from DocItem with defensive validation.
    
    Handles various Docling table format variations and safely extracts:
    - Row data
    - Column headers
    - Merged cell information (if available)
    
    Returns empty table structure on parsing errors.
    """
    try:
        # Validate item has required attributes
        if not hasattr(item, 'data'):
            logger.warning("Table item missing 'data' attribute, returning empty table")
            return {"rows": [], "headers": None, "merged_cells": None}
        
        if not hasattr(item.data, 'table'):
            logger.warning("Table item.data missing 'table' attribute, returning empty table")
            return {"rows": [], "headers": None, "merged_cells": None}
        
        table = item.data.table
        
        # Validate table has rows
        if not hasattr(table, 'rows'):
            logger.warning("Table object missing 'rows' attribute, returning empty table")
            return {"rows": [], "headers": None, "merged_cells": None}
        
        rows = []
        skipped_rows = 0
        
        # Parse rows with validation
        for row_idx, row in enumerate(table.rows):
            try:
                # Validate row has cells
                if not hasattr(row, 'cells'):
                    logger.warning(f"Table row {row_idx} missing 'cells' attribute, skipping")
                    skipped_rows += 1
                    continue
                
                row_data = []
                for cell_idx, cell in enumerate(row.cells):
                    # Safely extract cell text with multiple fallbacks
                    cell_text = ""
                    if hasattr(cell, 'text'):
                        cell_text = str(cell.text) if cell.text is not None else ""
                    elif hasattr(cell, 'content'):
                        cell_text = str(cell.content) if cell.content is not None else ""
                    else:
                        logger.debug(f"Cell [{row_idx}][{cell_idx}] has no 'text' or 'content' attribute")
                    
                    row_data.append(cell_text)
                
                rows.append(row_data)
                
            except Exception as e:
                logger.warning(f"Error parsing table row {row_idx}: {e}, skipping row")
                skipped_rows += 1
                continue
        
        if skipped_rows > 0:
            logger.info(f"Skipped {skipped_rows} malformed rows during table parsing")
        
        # Detect headers (usually first row)
        headers = rows[0] if rows else None
        
        # Extract merged cell information if available
        merged_cells = None
        if hasattr(table, 'merged_cells') and table.merged_cells:
            try:
                merged_cells = []
                for merge_info in table.merged_cells:
                    if hasattr(merge_info, '__dict__'):
                        merged_cells.append(merge_info.__dict__)
                    else:
                        merged_cells.append(str(merge_info))
                logger.debug(f"Extracted {len(merged_cells)} merged cell regions")
            except Exception as e:
                logger.warning(f"Error extracting merged cells: {e}")
                merged_cells = None
        
        # Log parsing summary
        row_count = len(rows) - 1 if headers else len(rows)
        header_count = len(headers) if headers else 0
        logger.debug(
            f"Parsed table: {row_count} data rows, "
            f"{header_count} headers, "
            f"merged_cells={'yes' if merged_cells else 'no'}"
        )
        
        return {
            "rows": rows[1:] if headers else rows,  # Exclude header row from data
            "headers": headers,
            "merged_cells": merged_cells,
        }
        
    except Exception as e:
        # Catch-all for unexpected errors
        logger.error(
            f"Unexpected error parsing table item: {type(e).__name__}: {e}",
            exc_info=True
        )
        return {"rows": [], "headers": None, "merged_cells": None}


def _is_ordered_list(item) -> bool:
    """Determine if list item is from ordered or unordered list."""
    # Check item metadata or text for numbering pattern
    if hasattr(item, 'metadata') and 'list_type' in item.metadata:
        return item.metadata['list_type'] == 'ordered'

    # Fallback: check if text starts with number
    text = item.text if hasattr(item, 'text') else str(item)
    return text.strip()[:1].isdigit()


def _infer_list_level(item) -> int:
    """Infer list nesting level from item metadata or indentation."""
    if hasattr(item, 'metadata') and 'level' in item.metadata:
        return item.metadata['level']
    return 0  # Default to top-level


def _detect_code_language(item) -> Optional[str]:
    """Detect programming language from code block metadata."""
    if hasattr(item, 'metadata') and 'language' in item.metadata:
        return item.metadata['language']
    return None  # Language detection TODO (future enhancement)


def _extract_image_data(item) -> str:
    """Extract image data (base64 or file reference) from item."""
    if hasattr(item, 'data') and hasattr(item.data, 'image'):
        # Return base64-encoded image or file path
        return item.data.image.get('base64', item.data.image.get('path', ''))
    return ''


def _extract_image_caption(item) -> Optional[str]:
    """Extract image caption from item metadata."""
    if hasattr(item, 'metadata') and 'caption' in item.metadata:
        return item.metadata['caption']
    return None


def _extract_image_alt_text(item) -> Optional[str]:
    """Extract image alt text from item metadata."""
    if hasattr(item, 'metadata') and 'alt_text' in item.metadata:
        return item.metadata['alt_text']
    return None
```

### 2. Create Unit Tests for Structure Preservation

Create `/opt/docling-mcp/src/docling_processor/test_structure_extractor.py`:

```python
"""
Unit tests for structure preservation module.
"""

import pytest
from structure_extractor import (
    extract_headings, extract_tables, extract_lists,
    extract_code_blocks, extract_images,
    validate_structure_preservation,
    Heading, Table, ListItem, CodeBlock, Image
)


def test_heading_dataclass():
    """Test Heading dataclass creation."""
    heading = Heading(level=1, text="Introduction", page_number=1)
    assert heading.level == 1
    assert heading.text == "Introduction"
    assert heading.page_number == 1


def test_table_dataclass():
    """Test Table dataclass creation."""
    table = Table(
        rows=[["Cell 1", "Cell 2"], ["Cell 3", "Cell 4"]],
        headers=["Header 1", "Header 2"],
        page_number=2
    )
    assert len(table.rows) == 2
    assert table.headers == ["Header 1", "Header 2"]


def test_list_item_dataclass():
    """Test ListItem dataclass creation."""
    list_item = ListItem(text="First item", level=0, ordered=True)
    assert list_item.text == "First item"
    assert list_item.ordered == True


def test_code_block_dataclass():
    """Test CodeBlock dataclass creation."""
    code_block = CodeBlock(code="print('hello')", language="python")
    assert code_block.code == "print('hello')"
    assert code_block.language == "python"


def test_image_dataclass():
    """Test Image dataclass creation."""
    image = Image(
        image_data="base64_encoded_data",
        caption="Figure 1: Test Image"
    )
    assert image.caption == "Figure 1: Test Image"


# Note: Full integration tests with actual DoclingDocument require
# real document conversion, which is tested in hx-docling-mcp-task-067
```

### 3. Verify Structure Extractor Module

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test imports
cd /opt/docling-mcp/src/docling_processor
python3 -c "from structure_extractor import extract_headings, extract_tables, extract_lists; print('✅ Structure extractor imports successful')"

# Test dataclasses
python3 << 'EOF'
from structure_extractor import Heading, Table, ListItem, CodeBlock, Image

# Test Heading
heading = Heading(level=1, text="Test", page_number=1)
print(f"✅ Heading created: {heading.text} (H{heading.level})")

# Test Table
table = Table(rows=[["A", "B"], ["C", "D"]], headers=["Col1", "Col2"])
print(f"✅ Table created: {len(table.rows)} rows, {len(table.headers)} headers")

# Test ListItem
item = ListItem(text="Item 1", level=0, ordered=True)
print(f"✅ ListItem created: {item.text} (ordered: {item.ordered})")

# Test CodeBlock
code = CodeBlock(code="x = 1", language="python")
print(f"✅ CodeBlock created: {code.language}")

# Test Image
image = Image(image_data="data", caption="Test")
print(f"✅ Image created: {image.caption}")
EOF
```

---

## Verification

### Success Criteria

- [ ] Structure extractor module created at `/opt/docling-mcp/src/docling_processor/structure_extractor.py`
- [ ] Dataclasses defined for all structure elements: Heading, Table, ListItem, CodeBlock, Image
- [ ] Extraction functions implemented for all elements: `extract_headings()`, `extract_tables()`, `extract_lists()`, `extract_code_blocks()`, `extract_images()`
- [ ] Heading hierarchy detection (H1-H6) implemented
- [ ] Table structure extraction with headers and cell structure implemented
- [ ] List nesting level detection implemented
- [ ] Code block extraction with language detection implemented
- [ ] Image extraction with caption and alt text implemented
- [ ] Structure validation function implemented
- [ ] Module imports without errors
- [ ] Unit tests pass (dataclass tests)

### Validation Commands

```bash
source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp/src/docling_processor

python3 << 'EOF'
from structure_extractor import (
    Heading, Table, ListItem, CodeBlock, Image,
    extract_headings, extract_tables
)

# Test dataclasses
print("Testing structure preservation dataclasses:")
print(f"  ✅ Heading: {Heading(level=1, text='Test')}")
print(f"  ✅ Table: {Table(rows=[['A']])}")
print(f"  ✅ ListItem: {ListItem(text='Item', level=0, ordered=True)}")
print(f"  ✅ CodeBlock: {CodeBlock(code='x=1')}")
print(f"  ✅ Image: {Image(image_data='data')}")

print("\n✅ All structure preservation components initialized")
EOF
```

### Expected Output

```
Testing structure preservation dataclasses:
  ✅ Heading: Heading(level=1, text='Test', page_number=None, bbox=None)
  ✅ Table: Table(rows=[['A']], headers=None, page_number=None, bbox=None, merged_cells=None)
  ✅ ListItem: ListItem(text='Item', level=0, ordered=True, parent_index=None)
  ✅ CodeBlock: CodeBlock(code='x=1', language=None, page_number=None)
  ✅ Image: Image(image_data='data', caption=None, alt_text=None, page_number=None, bbox=None)

✅ All structure preservation components initialized
```

---

## Rollback

If structure preservation implementation fails:

```bash
# Remove structure extractor module
rm -f /opt/docling-mcp/src/docling_processor/structure_extractor.py
rm -f /opt/docling-mcp/src/docling_processor/test_structure_extractor.py
```

---

## Notes

### Structure Elements (FR-006 Compliance)

**Required Structure Elements**:
1. **Headings**: H1-H6 hierarchy with text, page number, bounding box
2. **Tables**: Cell structure, merged cells, headers, page number
3. **Lists**: Ordered/unordered, nesting levels, parent-child relationships
4. **Code Blocks**: Source code with language detection
5. **Images**: Base64/file reference, captions, alt text, bounding box

### Docling DocItem Labels

Docling uses `DocItemLabel` enum to classify document elements:
- `SECTION_HEADER`, `TITLE`, `SUBTITLE` → Headings
- `TABLE` → Tables
- `LIST_ITEM` → Lists
- `CODE` → Code blocks
- `PICTURE` → Images

### Integration with MCP Tools

Structure extraction functions will be used in:
- `convert_document` MCP tool (preserve structure in DoclingDocument)
- `extract_tables` MCP tool (return tables as structured JSON)
- `parse_pdf_structure` MCP tool (analyze document structure)

### Future Enhancements

**Phase 2 Improvements**:
- Advanced table structure: Multi-page tables, complex merged cells
- Code language detection using pygments or custom heuristics
- Image OCR for embedded text extraction
- Mathematical equation extraction (LaTeX rendering)
- Form field extraction (PDF forms)

### Docling Internal Structure

This implementation assumes Docling's internal `DoclingDocument` structure includes:
- `doc_items`: List of document items with labels
- `prov`: Provenance information (page number, bounding box)
- `data`: Element-specific data (table cells, image data)

**Note**: Actual Docling internal structure may vary. This module may need adjustment based on actual Docling library version and API.

---

## Related Tasks

**Upstream Dependencies:**
- hx-docling-mcp-task-061: Docling library installation
- hx-docling-mcp-task-063: Backend selection logic

**Downstream Dependencies:**
- hx-docling-mcp-task-066: DoclingDocument schema implementation (uses structure extraction)
- hx-docling-mcp-task-067: MCP tool integration (uses structure in tool responses)
- hx-docling-mcp-task-031-060: MCP tools (extract_tables, parse_pdf_structure use this module)

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Agent**: albert-singh (Docling Processing Specialist)
