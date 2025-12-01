# Task 019: Implement DoclingDocument Pydantic Schema

**Task ID**: hx-docling-mcp-task-019
**Component**: Docling Document Processing (albert-singh)
**Category**: Implementation
**Priority**: HIGH (core data model)
**Estimated Effort**: 3-4 hours
**Status**: NOT_STARTED

---

## Objective

Implement complete Pydantic v2 schema for DoclingDocument format with all document element types (headings, paragraphs, tables, lists, images, code blocks, footnotes), metadata, serialization for MCP transport, and schema versioning.

---

## Prerequisites

- [x] Task 010: Docling library installed
- [x] Python packages: pydantic>=2.0
- [x] Tasks 011-014: Structure extraction implemented

---

## Technical Context

**From albert-docling-processing.md** (Section 5: DoclingDocument JSON Schema, lines 895-1075):
- **Pydantic v2 Schema**: Complete type-safe models for all document elements
- **Element Types**: Heading, Paragraph, List, Table, Image, CodeBlock, Footnote
- **Metadata**: Document-level metadata (title, author, page count, format, extraction timestamp)
- **Serialization**: JSON serialization for MCP transport with exclude_none
- **Schema Versioning**: Semantic versioning (1.0.0) with evolution rules

**From Specification** (node-spec.md FR-007):
- DoclingDocument format: Hierarchical JSON structure
- MCP tool integration: Serialize to JSON for `convert_document` tool response

---

## Implementation Steps

### Step 1: Create Pydantic Schema Module

**File**: `/opt/docling-mcp/application/docling_mcp/models/docling_document.py`

```python
"""
DoclingDocument Pydantic schema for structured document representation.

This is the canonical format for all document conversions in the Docling MCP Server.
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Literal, Union
from datetime import datetime


# ============================================================================
# Supporting Models
# ============================================================================

class BoundingBox(BaseModel):
    """Document element bounding box coordinates."""
    x0: float = Field(description="Left edge coordinate")
    y0: float = Field(description="Top edge coordinate")
    x1: float = Field(description="Right edge coordinate")
    y1: float = Field(description="Bottom edge coordinate")


class Position(BaseModel):
    """Position of document element within document."""
    page: int = Field(description="Page number (0-indexed)")
    bbox: BoundingBox = Field(description="Bounding box coordinates")


class Style(BaseModel):
    """Text style attributes."""
    font_size: Optional[float] = Field(None, description="Font size in points")
    font_weight: Optional[Literal['normal', 'bold']] = Field(None, description="Font weight")
    font_family: Optional[str] = Field(None, description="Font family name")
    color: Optional[str] = Field(None, description="Text color (hex RGB)")


# ============================================================================
# Document Element Models
# ============================================================================

class HeadingItem(BaseModel):
    """Heading element (H1-H6)."""
    type: Literal['heading'] = 'heading'
    level: int = Field(ge=1, le=6, description="Heading level (1-6)")
    text: str = Field(description="Heading text content")
    style: Optional[Style] = None
    position: Optional[Position] = None


class ParagraphItem(BaseModel):
    """Paragraph text element."""
    type: Literal['paragraph'] = 'paragraph'
    text: str = Field(description="Paragraph text content")
    position: Optional[Position] = None
    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata (e.g., ocr_confidence)"
    )


class ListItem(BaseModel):
    """Individual list item."""
    text: str
    level: int = Field(ge=0, description="Nesting level (0-based)")
    number: Optional[int] = Field(None, description="Item number for ordered lists")
    marker: Optional[str] = Field(None, description="Bullet marker for unordered lists")


class ListItemContainer(BaseModel):
    """Ordered or unordered list container."""
    type: Literal['ordered_list', 'unordered_list']
    items: List[ListItem]
    position: Optional[Position] = None


class TableCell(BaseModel):
    """Table cell with position and span information."""
    row: int
    col: int
    text: str
    colspan: int = Field(default=1, ge=1)
    rowspan: int = Field(default=1, ge=1)
    is_header: bool = False


class TableItem(BaseModel):
    """Table element with cell structure."""
    type: Literal['table'] = 'table'
    num_rows: int = Field(ge=1)
    num_cols: int = Field(ge=1)
    headers: List[Dict[str, Any]] = Field(default_factory=list)
    cells: List[TableCell]
    position: Optional[Position] = None


class ImageItem(BaseModel):
    """Image element with encoding options."""
    type: Literal['image'] = 'image'
    format: str = Field(description="Image format (jpeg, png, tiff)")
    encoding: Literal['base64', 'file_reference', 'data_uri']
    data: str = Field(description="Base64 string or file path")
    width: int
    height: int
    caption: Optional[str] = None
    alt_text: Optional[str] = None
    position: Optional[Position] = None


class CodeBlockItem(BaseModel):
    """Code block element with language detection."""
    type: Literal['code_block'] = 'code_block'
    language: str = Field(description="Programming language")
    code: str = Field(description="Raw code text")
    line_numbers: bool = False
    highlighted_lines: List[int] = Field(default_factory=list)
    position: Optional[Position] = None


class FootnoteItem(BaseModel):
    """Footnote/citation element."""
    type: Literal['footnote'] = 'footnote'
    reference_number: int
    reference_text: str
    footnote_text: str
    position: Optional[Position] = None


# Union type for all document items
DocItem = Union[
    HeadingItem,
    ParagraphItem,
    ListItemContainer,
    TableItem,
    ImageItem,
    CodeBlockItem,
    FootnoteItem
]


# ============================================================================
# Document Metadata
# ============================================================================

class DocumentMetadata(BaseModel):
    """Document-level metadata."""
    title: Optional[str] = None
    author: Optional[str] = None
    creation_date: Optional[datetime] = None
    modification_date: Optional[datetime] = None
    page_count: int = Field(ge=1)
    format: str = Field(description="Source document format (pdf, docx, etc.)")
    file_size_bytes: Optional[int] = None
    language: Optional[str] = None
    extraction_timestamp: datetime = Field(default_factory=datetime.utcnow)
    extraction_model: str = Field(default="docling~2.25")
    backend_used: str = Field(
        description="Backend used for conversion (pypdfium2, python-docx, etc.)"
    )
    schema_version: str = Field(
        default="1.0.0",
        description="DoclingDocument schema version"
    )


# ============================================================================
# Main DoclingDocument Model
# ============================================================================

class DoclingDocument(BaseModel):
    """
    Canonical DoclingDocument format for structured document representation.

    All document conversions produce this schema for downstream processing.
    This format is optimized for:
    - MCP tool responses (JSON serialization)
    - Knowledge graph generation (entity/relation extraction)
    - RAG pipeline ingestion (chunking and embedding)
    """
    doc_items: List[DocItem] = Field(
        description="Ordered list of document elements"
    )
    metadata: DocumentMetadata = Field(
        description="Document-level metadata"
    )

    class Config:
        """Pydantic v2 configuration."""
        json_schema_extra = {
            "example": {
                "doc_items": [
                    {
                        "type": "heading",
                        "level": 1,
                        "text": "Introduction to Docling",
                        "position": {
                            "page": 0,
                            "bbox": {"x0": 72, "y0": 100, "x1": 540, "y1": 130}
                        }
                    },
                    {
                        "type": "paragraph",
                        "text": "Docling is a document processing framework...",
                        "position": {
                            "page": 0,
                            "bbox": {"x0": 72, "y0": 150, "x1": 540, "y1": 200}
                        }
                    }
                ],
                "metadata": {
                    "title": "Docling Documentation",
                    "page_count": 10,
                    "format": "pdf",
                    "backend_used": "pypdfium2",
                    "schema_version": "1.0.0"
                }
            }
        }

    # ========================================================================
    # Serialization Methods
    # ========================================================================

    def to_json(self, **kwargs) -> str:
        """
        Serialize DoclingDocument to JSON string for MCP response.

        Args:
            **kwargs: Additional arguments for model_dump_json

        Returns:
            JSON string representation
        """
        return self.model_dump_json(
            indent=2,
            exclude_none=True,
            **kwargs
        )

    def to_dict(self, **kwargs) -> dict:
        """
        Serialize DoclingDocument to Python dictionary.

        Args:
            **kwargs: Additional arguments for model_dump

        Returns:
            Dictionary representation
        """
        return self.model_dump(
            exclude_none=True,
            **kwargs
        )

    @classmethod
    def from_json(cls, json_str: str) -> "DoclingDocument":
        """
        Deserialize JSON string to DoclingDocument object.

        Args:
            json_str: JSON string representation

        Returns:
            DoclingDocument instance
        """
        return cls.model_validate_json(json_str)

    @classmethod
    def from_dict(cls, data: dict) -> "DoclingDocument":
        """
        Deserialize dictionary to DoclingDocument object.

        Args:
            data: Dictionary representation

        Returns:
            DoclingDocument instance
        """
        return cls.model_validate(data)

    # ========================================================================
    # Utility Methods
    # ========================================================================

    def get_text(self) -> str:
        """Extract all text content from document."""
        text_parts = []
        for item in self.doc_items:
            if hasattr(item, 'text'):
                text_parts.append(item.text)
            elif item.type == 'table':
                for cell in item.cells:
                    text_parts.append(cell.text)
            elif item.type in ['ordered_list', 'unordered_list']:
                for list_item in item.items:
                    text_parts.append(list_item.text)
        return '\n'.join(text_parts)

    def get_headings(self) -> List[HeadingItem]:
        """Extract all headings from document."""
        return [item for item in self.doc_items if item.type == 'heading']

    def get_tables(self) -> List[TableItem]:
        """Extract all tables from document."""
        return [item for item in self.doc_items if item.type == 'table']

    def get_images(self) -> List[ImageItem]:
        """Extract all images from document."""
        return [item for item in self.doc_items if item.type == 'image']


# ============================================================================
# Schema Version Constants
# ============================================================================

SCHEMA_VERSION = "1.0.0"  # Semantic versioning

# Version evolution rules:
# - Patch (1.0.x): Add optional fields, fix bugs (backward compatible)
# - Minor (1.x.0): Add new item types, extend metadata (backward compatible)
# - Major (x.0.0): Remove fields, change types, restructure (breaking changes)
```

---

### Step 2: Create Unit Tests for Schema

**File**: `/opt/docling-mcp/tests/test_docling_document_schema.py`

```python
"""Unit tests for DoclingDocument Pydantic schema."""

import pytest
from datetime import datetime
from docling_mcp.models.docling_document import (
    DoclingDocument,
    DocumentMetadata,
    HeadingItem,
    ParagraphItem,
    TableItem,
    TableCell,
    BoundingBox,
    Position
)


class TestDoclingDocumentSchema:
    """Test DoclingDocument schema validation."""

    def test_minimal_document(self):
        """Test minimal valid document."""
        doc = DoclingDocument(
            doc_items=[
                ParagraphItem(type='paragraph', text='Test paragraph')
            ],
            metadata=DocumentMetadata(
                page_count=1,
                format='pdf',
                backend_used='pypdfium2'
            )
        )

        assert doc.metadata.page_count == 1
        assert len(doc.doc_items) == 1

    def test_serialization_to_json(self):
        """Test JSON serialization."""
        doc = DoclingDocument(
            doc_items=[
                HeadingItem(type='heading', level=1, text='Title')
            ],
            metadata=DocumentMetadata(
                page_count=1,
                format='pdf',
                backend_used='pypdfium2'
            )
        )

        json_str = doc.to_json()
        assert isinstance(json_str, str)
        assert 'doc_items' in json_str
        assert 'metadata' in json_str

    def test_deserialization_from_json(self):
        """Test JSON deserialization."""
        json_str = '''
        {
            "doc_items": [
                {"type": "paragraph", "text": "Test"}
            ],
            "metadata": {
                "page_count": 1,
                "format": "pdf",
                "backend_used": "pypdfium2"
            }
        }
        '''

        doc = DoclingDocument.from_json(json_str)
        assert len(doc.doc_items) == 1
        assert doc.doc_items[0].text == 'Test'

    def test_get_text_utility(self):
        """Test text extraction utility."""
        doc = DoclingDocument(
            doc_items=[
                HeadingItem(type='heading', level=1, text='Title'),
                ParagraphItem(type='paragraph', text='Body text')
            ],
            metadata=DocumentMetadata(
                page_count=1,
                format='pdf',
                backend_used='pypdfium2'
            )
        )

        text = doc.get_text()
        assert 'Title' in text
        assert 'Body text' in text


class TestTableSchema:
    """Test table schema validation."""

    def test_table_with_cells(self):
        """Test table with cell structure."""
        table = TableItem(
            type='table',
            num_rows=2,
            num_cols=2,
            cells=[
                TableCell(row=0, col=0, text='A', is_header=True),
                TableCell(row=0, col=1, text='B', is_header=True),
                TableCell(row=1, col=0, text='1'),
                TableCell(row=1, col=1, text='2')
            ]
        )

        assert table.num_rows == 2
        assert table.num_cols == 2
        assert len(table.cells) == 4
```

---

### Step 3: Integration with Docling Processor

**File**: `/opt/docling-mcp/application/docling_mcp/processors/docling_processor.py` (update)

```python
from docling_mcp.models.docling_document import DoclingDocument, DocumentMetadata, ParagraphItem

class DoclingProcessor:
    """Document processor that outputs DoclingDocument schema."""

    async def convert_document(self, source: str, format: str) -> DoclingDocument:
        """
        Convert document to DoclingDocument format.

        Args:
            source: File path or URL
            format: Document format

        Returns:
            DoclingDocument instance
        """
        # ... (existing conversion logic)

        # Assemble DoclingDocument
        doc = DoclingDocument(
            doc_items=extracted_items,
            metadata=DocumentMetadata(
                title=extracted_metadata.get('title'),
                page_count=page_count,
                format=format,
                backend_used=backend.value,
                extraction_model="docling~2.25"
            )
        )

        return doc
```

---

## Success Criteria

- [ ] Complete Pydantic v2 schema implemented for DoclingDocument
- [ ] All element types defined (Heading, Paragraph, Table, List, Image, CodeBlock, Footnote)
- [ ] Metadata model complete with extraction timestamp, backend info
- [ ] Serialization methods implemented (to_json, from_json, to_dict, from_dict)
- [ ] Utility methods implemented (get_text, get_headings, get_tables, get_images)
- [ ] Unit tests created and passing (≥95% coverage)
- [ ] Schema validation enforced with Pydantic

---

## Dependencies

**Depends On**:
- Task 010: Docling library installed
- Tasks 011-014: Structure extraction implemented

**Blocks**:
- Task 016: Integration with MCP tools (requires serialization)

---

**Task Owner**: albert-singh (Docling Document Processing SME)
**Created**: 2025-11-27
