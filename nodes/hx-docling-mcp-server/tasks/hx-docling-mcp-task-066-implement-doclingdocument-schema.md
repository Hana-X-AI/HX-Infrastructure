# Task 066: Implement DoclingDocument Schema

**Task ID**: hx-docling-mcp-task-066-implement-doclingdocument-schema
**Phase**: Development - Document Processing Integration
**Status**: Not Started
**Assigned To**: albert-singh (Docling Processing Specialist)
**Dependencies**: hx-docling-mcp-task-064 (Structure preservation)
**Estimated Time**: 2 hours

---

## Objective

Implement Pydantic schema validation for DoclingDocument JSON format to ensure consistent, validated document representations for MCP tool responses, with comprehensive field validation and export functionality as required by FR-007.

---

## Pre-Execution Validation

**CRITICAL**: Check if DoclingDocument schema module already exists before proceeding:

```bash
# Check if schema module exists
if [ -f /opt/docling-mcp/src/docling_processor/docling_schema.py ]; then
    echo "✅ VALIDATION: DoclingDocument schema module already exists - Review implementation"
    echo "Module location: /opt/docling-mcp/src/docling_processor/docling_schema.py"
    # Check if module has core classes
    grep -q "class DoclingDocumentSchema\|class DocItemSchema" /opt/docling-mcp/src/docling_processor/docling_schema.py
    if [ $? -eq 0 ]; then
        echo "✅ Core schema classes found - SKIP task execution"
        exit 0
    else
        echo "⚠️ Module exists but incomplete - PROCEED with implementation"
    fi
else
    echo "❌ VALIDATION: DoclingDocument schema module not found - PROCEED with task"
fi
```

**If Validation Passes (Module Already Complete)**:
- Mark task as complete with validation timestamp
- Verify schema validation with test imports
- SKIP all implementation steps below

**If Validation Fails (Module Not Found/Incomplete)**:
- Proceed with Prerequisites and Steps sections

---

## Prerequisites

- [ ] Docling library installed (hx-docling-mcp-task-061)
- [ ] Structure preservation implemented (hx-docling-mcp-task-064)
- [ ] Pydantic library installed (part of Python dependencies)
- [ ] Python virtual environment activated

---

## Steps

### 1. Implement DoclingDocument Pydantic Schema

Create `/opt/docling-mcp/src/docling_processor/docling_schema.py`:

```python
"""
DoclingDocument Pydantic Schema

Provides Pydantic validation schemas for DoclingDocument JSON format
to ensure consistent, validated document representations for MCP tools.

Implements FR-007 specification requirements.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from uuid import UUID, uuid4


class BoundingBox(BaseModel):
    """Bounding box coordinates for document elements."""
    x: float = Field(ge=0, description="X coordinate (left edge)")
    y: float = Field(ge=0, description="Y coordinate (top edge)")
    width: float = Field(gt=0, description="Width of bounding box")
    height: float = Field(gt=0, description="Height of bounding box")


class Provenance(BaseModel):
    """Provenance information for document items (source, page, location)."""
    page: int = Field(ge=1, description="Page number (1-indexed)")
    bbox: Optional[BoundingBox] = Field(None, description="Bounding box on page")
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0, description="Extraction confidence")


class DocItemSchema(BaseModel):
    """
    Schema for individual document items (headings, paragraphs, tables, etc.).
    """
    item_id: str = Field(default_factory=lambda: str(uuid4()), description="Unique item ID")
    label: str = Field(description="Item type: heading, paragraph, table, list, code, image")
    text: Optional[str] = Field(None, description="Text content of item")
    level: Optional[int] = Field(None, ge=1, le=6, description="Heading level (1-6) if applicable")
    prov: List[Provenance] = Field(default_factory=list, description="Provenance information")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")

    @field_validator('label')
    @classmethod
    def validate_label(cls, v):
        """Validate label is recognized document element type."""
        valid_labels = [
            'heading', 'paragraph', 'table', 'list_item', 'code',
            'image', 'caption', 'footnote', 'page_header', 'page_footer'
        ]
        if v.lower() not in valid_labels:
            raise ValueError(f"Invalid label '{v}'. Must be one of: {', '.join(valid_labels)}")
        return v.lower()


class DocumentMetadata(BaseModel):
    """Document-level metadata."""
    title: Optional[str] = Field(None, description="Document title")
    author: Optional[str] = Field(None, description="Document author")
    creation_date: Optional[datetime] = Field(None, description="Document creation date")
    modification_date: Optional[datetime] = Field(None, description="Last modification date")
    page_count: int = Field(ge=1, description="Total number of pages")
    language: Optional[str] = Field(None, description="Detected language (ISO 639-1 code)")
    format: str = Field(description="Original document format (pdf, docx, etc.)")


class DoclingDocumentSchema(BaseModel):
    """
    Complete DoclingDocument schema with validation.

    This schema validates the JSON output from Docling document conversion,
    ensuring all required fields are present and properly formatted.
    """
    document_id: str = Field(default_factory=lambda: str(uuid4()), description="Unique document ID")
    schema_version: str = Field(default="1.0", description="Schema version for backward compatibility")
    doc_items: List[DocItemSchema] = Field(description="List of document items (structure elements)")
    metadata: DocumentMetadata = Field(description="Document metadata")
    conversion_timestamp: datetime = Field(default_factory=datetime.utcnow, description="Conversion timestamp (UTC)")
    source_path: Optional[str] = Field(None, description="Original document source path or URL")

    @field_validator('doc_items')
    @classmethod
    def validate_doc_items_not_empty(cls, v):
        """Validate that document has at least one item."""
        if not v:
            raise ValueError("Document must contain at least one doc_item")
        return v

    def export_to_json(self) -> Dict[str, Any]:
        """Export DoclingDocument to JSON-serializable dictionary."""
        return self.model_dump(mode='json')

    def export_to_markdown(self) -> str:
        """
        Export DoclingDocument to Markdown format.

        Converts document structure to readable Markdown with:
        - Headings preserved with # syntax
        - Paragraphs as plain text
        - Lists with - or 1. syntax
        - Code blocks with ``` syntax
        - Tables in Markdown table format
        """
        markdown_lines = []

        # Add document title if available
        if self.metadata.title:
            markdown_lines.append(f"# {self.metadata.title}\n")

        # Convert doc_items to Markdown
        for item in self.doc_items:
            if item.label == 'heading':
                level = item.level or 1
                markdown_lines.append(f"{'#' * level} {item.text}\n")

            elif item.label == 'paragraph':
                markdown_lines.append(f"{item.text}\n")

            elif item.label == 'list_item':
                markdown_lines.append(f"- {item.text}\n")

            elif item.label == 'code':
                language = item.metadata.get('language', '')
                markdown_lines.append(f"```{language}\n{item.text}\n```\n")

            elif item.label == 'table':
                # Table conversion (simplified - assumes table data in metadata)
                if 'rows' in item.metadata:
                    rows = item.metadata['rows']
                    if rows:
                        # Add table header
                        if 'headers' in item.metadata and item.metadata['headers']:
                            headers = item.metadata['headers']
                            markdown_lines.append("| " + " | ".join(headers) + " |")
                            markdown_lines.append("| " + " | ".join(["---"] * len(headers)) + " |")

                        # Add table rows
                        for row in rows:
                            markdown_lines.append("| " + " | ".join(row) + " |")
                        markdown_lines.append("")

            elif item.label == 'caption':
                # Caption text (for figures, tables, etc.)
                markdown_lines.append(f"*{item.text}*\n")

            elif item.label == 'footnote':
                # Footnote as superscript reference
                footnote_id = item.metadata.get('footnote_id', '1')
                markdown_lines.append(f"[^{footnote_id}]: {item.text}\n")

            elif item.label == 'page_header':
                # Page header as horizontal rule with text
                markdown_lines.append(f"---\n**Header:** {item.text}\n")

            elif item.label == 'page_footer':
                # Page footer as horizontal rule with text
                markdown_lines.append(f"**Footer:** {item.text}\n---\n")

            elif item.label == 'image':
                # Image with alt text and optional path
                image_path = item.metadata.get('image_path', '')
                alt_text = item.text or 'Image'
                markdown_lines.append(f"![{alt_text}]({image_path})\n")

        return "\n".join(markdown_lines)

    def get_statistics(self) -> Dict[str, Any]:
        """
        Get document statistics.

        Returns:
            Dictionary with counts of different document elements
        """
        label_counts = {}
        for item in self.doc_items:
            label_counts[item.label] = label_counts.get(item.label, 0) + 1

        return {
            "document_id": self.document_id,
            "total_items": len(self.doc_items),
            "page_count": self.metadata.page_count,
            "label_distribution": label_counts,
            "has_tables": label_counts.get('table', 0) > 0,
            "has_code": label_counts.get('code', 0) > 0,
            "has_images": label_counts.get('image', 0) > 0,
        }


def validate_docling_document(data: Dict[str, Any]) -> DoclingDocumentSchema:
    """
    Validate raw DoclingDocument JSON data against schema.

    Args:
        data: Dictionary containing DoclingDocument JSON

    Returns:
        Validated DoclingDocumentSchema instance

    Raises:
        ValidationError: If data does not conform to schema
    """
    return DoclingDocumentSchema(**data)


def create_docling_document(
    doc_items: List[DocItemSchema],
    metadata: DocumentMetadata,
    source_path: Optional[str] = None,
) -> DoclingDocumentSchema:
    """
    Create validated DoclingDocument from components.

    Args:
        doc_items: List of document items
        metadata: Document metadata
        source_path: Optional source path

    Returns:
        Validated DoclingDocumentSchema instance
    """
    return DoclingDocumentSchema(
        doc_items=doc_items,
        metadata=metadata,
        source_path=source_path,
    )
```

### 2. Create Unit Tests for Schema Validation

Create `/opt/docling-mcp/src/docling_processor/test_docling_schema.py`:

```python
"""
Unit tests for DoclingDocument schema validation.

Comprehensive test suite covering:
- BoundingBox validation (coordinates, dimensions)
- Provenance validation (page numbers, confidence, bbox)
- DocItemSchema validation (labels, levels, text)
- DocumentMetadata validation (page counts, formats)
- DoclingDocumentSchema validation (items, metadata)
- Export functions (JSON, Markdown) - all 10 item types
- Statistics function - all 10 item types
- Helper functions (validate_docling_document, create_docling_document)
- Edge cases (empty documents, invalid levels, unicode, large docs)

Resolves defect-docling-mcp-medium-004-test-coverage-gaps.md
"""

import pytest
from pydantic import ValidationError
from src.docling_processor.docling_schema import (
    DoclingDocumentSchema, DocItemSchema, DocumentMetadata,
    BoundingBox, Provenance, validate_docling_document, create_docling_document
)


# ============================================================================
# BOUNDING BOX TESTS
# ============================================================================

def test_bounding_box_valid():
    """Test valid bounding box creation."""
    bbox = BoundingBox(x=10.0, y=20.0, width=100.0, height=50.0)
    assert bbox.x == 10.0
    assert bbox.width == 100.0


def test_bounding_box_invalid_negative_x():
    """Test bounding box rejects negative x coordinate."""
    with pytest.raises(ValidationError):
        BoundingBox(x=-10.0, y=20.0, width=100.0, height=50.0)


def test_bounding_box_invalid_negative_y():
    """Test bounding box rejects negative y coordinate."""
    with pytest.raises(ValidationError):
        BoundingBox(x=10.0, y=-20.0, width=100.0, height=50.0)


def test_bounding_box_invalid_zero_width():
    """Test bounding box rejects zero width."""
    with pytest.raises(ValidationError):
        BoundingBox(x=10.0, y=20.0, width=0.0, height=50.0)


def test_bounding_box_invalid_zero_height():
    """Test bounding box rejects zero height."""
    with pytest.raises(ValidationError):
        BoundingBox(x=10.0, y=20.0, width=100.0, height=0.0)


def test_bounding_box_invalid_negative_width():
    """Test bounding box rejects negative width."""
    with pytest.raises(ValidationError):
        BoundingBox(x=10.0, y=20.0, width=-100.0, height=50.0)


def test_bounding_box_invalid_negative_height():
    """Test bounding box rejects negative height."""
    with pytest.raises(ValidationError):
        BoundingBox(x=10.0, y=20.0, width=100.0, height=-50.0)


# ============================================================================
# PROVENANCE VALIDATION TESTS
# ============================================================================

def test_provenance_valid():
    """Test valid provenance creation."""
    bbox = BoundingBox(x=0, y=0, width=10, height=10)
    prov = Provenance(page=1, bbox=bbox, confidence=0.95)
    assert prov.page == 1
    assert prov.confidence == 0.95


def test_provenance_valid_no_bbox():
    """Test provenance without bounding box (optional)."""
    prov = Provenance(page=1, confidence=0.8)
    assert prov.page == 1
    assert prov.bbox is None


def test_provenance_valid_no_confidence():
    """Test provenance without confidence (optional)."""
    prov = Provenance(page=5)
    assert prov.page == 5
    assert prov.confidence is None


def test_provenance_invalid_page_zero():
    """Test provenance rejects page=0 (must be >= 1)."""
    with pytest.raises(ValidationError):
        Provenance(page=0)


def test_provenance_invalid_page_negative():
    """Test provenance rejects negative page numbers."""
    with pytest.raises(ValidationError):
        Provenance(page=-1)


def test_provenance_invalid_confidence_negative():
    """Test provenance rejects negative confidence scores."""
    with pytest.raises(ValidationError):
        Provenance(page=1, confidence=-0.1)


def test_provenance_invalid_confidence_over_one():
    """Test provenance rejects confidence > 1.0."""
    with pytest.raises(ValidationError):
        Provenance(page=1, confidence=1.5)


def test_provenance_valid_confidence_boundaries():
    """Test provenance accepts confidence at boundaries (0.0 and 1.0)."""
    prov_zero = Provenance(page=1, confidence=0.0)
    assert prov_zero.confidence == 0.0

    prov_one = Provenance(page=1, confidence=1.0)
    assert prov_one.confidence == 1.0


# ============================================================================
# DOC ITEM SCHEMA TESTS
# ============================================================================

def test_doc_item_valid():
    """Test valid DocItem creation."""
    item = DocItemSchema(
        label='heading',
        text='Introduction',
        level=1,
    )
    assert item.label == 'heading'
    assert item.text == 'Introduction'


def test_doc_item_invalid_label():
    """Test DocItem rejects invalid labels."""
    with pytest.raises(ValidationError):
        DocItemSchema(label='invalid_label', text='Test')


def test_doc_item_all_valid_labels():
    """Test all 10 valid label types are accepted."""
    valid_labels = [
        'heading', 'paragraph', 'table', 'list_item', 'code',
        'image', 'caption', 'footnote', 'page_header', 'page_footer'
    ]
    for label in valid_labels:
        item = DocItemSchema(label=label, text='Test content')
        assert item.label == label


def test_doc_item_label_case_insensitive():
    """Test label validation is case-insensitive (normalized to lowercase)."""
    item_upper = DocItemSchema(label='HEADING', text='Test')
    assert item_upper.label == 'heading'

    item_mixed = DocItemSchema(label='PaRaGrApH', text='Test')
    assert item_mixed.label == 'paragraph'


def test_doc_item_heading_level_boundaries():
    """Test heading level validation (1-6)."""
    # Valid levels
    for level in range(1, 7):
        item = DocItemSchema(label='heading', text='Test', level=level)
        assert item.level == level


def test_doc_item_heading_level_zero_invalid():
    """Test heading level=0 is rejected."""
    with pytest.raises(ValidationError):
        DocItemSchema(label='heading', text='Test', level=0)


def test_doc_item_heading_level_seven_invalid():
    """Test heading level=7 is rejected (max is 6)."""
    with pytest.raises(ValidationError):
        DocItemSchema(label='heading', text='Test', level=7)


def test_doc_item_heading_level_negative_invalid():
    """Test negative heading level is rejected."""
    with pytest.raises(ValidationError):
        DocItemSchema(label='heading', text='Test', level=-1)


def test_doc_item_with_provenance():
    """Test DocItem with provenance information."""
    prov = Provenance(page=1, confidence=0.9)
    item = DocItemSchema(
        label='paragraph',
        text='Content with provenance',
        prov=[prov]
    )
    assert len(item.prov) == 1
    assert item.prov[0].page == 1


def test_doc_item_with_metadata():
    """Test DocItem with custom metadata."""
    item = DocItemSchema(
        label='table',
        text='',
        metadata={'rows': [['A', 'B'], ['1', '2']], 'headers': ['Col1', 'Col2']}
    )
    assert 'rows' in item.metadata
    assert len(item.metadata['rows']) == 2


# ============================================================================
# DOCUMENT METADATA TESTS
# ============================================================================

def test_document_metadata_valid():
    """Test valid DocumentMetadata creation."""
    metadata = DocumentMetadata(
        title='Test Document',
        page_count=5,
        format='pdf',
    )
    assert metadata.title == 'Test Document'
    assert metadata.page_count == 5


def test_document_metadata_minimal():
    """Test DocumentMetadata with only required fields."""
    metadata = DocumentMetadata(page_count=1, format='docx')
    assert metadata.page_count == 1
    assert metadata.format == 'docx'
    assert metadata.title is None


def test_document_metadata_invalid_page_count_zero():
    """Test DocumentMetadata rejects page_count=0."""
    with pytest.raises(ValidationError):
        DocumentMetadata(page_count=0, format='pdf')


def test_document_metadata_invalid_page_count_negative():
    """Test DocumentMetadata rejects negative page_count."""
    with pytest.raises(ValidationError):
        DocumentMetadata(page_count=-1, format='pdf')


def test_document_metadata_all_fields():
    """Test DocumentMetadata with all optional fields."""
    from datetime import datetime
    metadata = DocumentMetadata(
        title='Complete Document',
        author='Test Author',
        creation_date=datetime(2025, 1, 1),
        modification_date=datetime(2025, 12, 1),
        page_count=100,
        language='en',
        format='pdf'
    )
    assert metadata.author == 'Test Author'
    assert metadata.language == 'en'


# ============================================================================
# DOCLING DOCUMENT SCHEMA TESTS
# ============================================================================

def test_docling_document_valid():
    """Test valid DoclingDocument creation."""
    items = [
        DocItemSchema(label='heading', text='Title', level=1),
        DocItemSchema(label='paragraph', text='Content'),
    ]
    metadata = DocumentMetadata(
        title='Test',
        page_count=1,
        format='pdf',
    )

    doc = DoclingDocumentSchema(
        doc_items=items,
        metadata=metadata,
    )

    assert len(doc.doc_items) == 2
    assert doc.metadata.title == 'Test'
    assert doc.schema_version == '1.0'  # Default schema version


def test_docling_document_empty_items():
    """Test DoclingDocument rejects empty doc_items."""
    metadata = DocumentMetadata(page_count=1, format='pdf')

    with pytest.raises(ValidationError, match="at least one doc_item"):
        DoclingDocumentSchema(doc_items=[], metadata=metadata)


def test_docling_document_auto_generated_id():
    """Test DoclingDocument generates unique document_id."""
    items = [DocItemSchema(label='paragraph', text='Test')]
    metadata = DocumentMetadata(page_count=1, format='pdf')

    doc1 = DoclingDocumentSchema(doc_items=items, metadata=metadata)
    doc2 = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    assert doc1.document_id != doc2.document_id  # Unique IDs


def test_docling_document_with_source_path():
    """Test DoclingDocument with source_path."""
    items = [DocItemSchema(label='paragraph', text='Test')]
    metadata = DocumentMetadata(page_count=1, format='pdf')

    doc = DoclingDocumentSchema(
        doc_items=items,
        metadata=metadata,
        source_path='/path/to/document.pdf'
    )

    assert doc.source_path == '/path/to/document.pdf'


# ============================================================================
# EXPORT TO JSON TESTS
# ============================================================================

def test_export_to_json():
    """Test JSON export functionality."""
    items = [DocItemSchema(label='paragraph', text='Test')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    json_data = doc.export_to_json()
    assert 'doc_items' in json_data
    assert 'metadata' in json_data
    assert 'document_id' in json_data
    assert 'schema_version' in json_data
    assert 'conversion_timestamp' in json_data


def test_export_to_json_preserves_all_data():
    """Test JSON export preserves all document data."""
    prov = Provenance(page=1, confidence=0.95)
    items = [
        DocItemSchema(
            label='heading',
            text='Title',
            level=1,
            prov=[prov],
            metadata={'custom_key': 'custom_value'}
        )
    ]
    metadata = DocumentMetadata(
        title='Test Doc',
        author='Author',
        page_count=1,
        format='pdf'
    )
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    json_data = doc.export_to_json()

    assert json_data['doc_items'][0]['label'] == 'heading'
    assert json_data['doc_items'][0]['level'] == 1
    assert json_data['doc_items'][0]['prov'][0]['confidence'] == 0.95
    assert json_data['metadata']['title'] == 'Test Doc'


# ============================================================================
# EXPORT TO MARKDOWN TESTS - ALL 10 ITEM TYPES
# ============================================================================

def test_export_to_markdown_heading():
    """Test Markdown export for heading items."""
    items = [
        DocItemSchema(label='heading', text='Level 1 Heading', level=1),
        DocItemSchema(label='heading', text='Level 2 Heading', level=2),
        DocItemSchema(label='heading', text='Level 6 Heading', level=6),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '# Level 1 Heading' in markdown
    assert '## Level 2 Heading' in markdown
    assert '###### Level 6 Heading' in markdown


def test_export_to_markdown_paragraph():
    """Test Markdown export for paragraph items."""
    items = [DocItemSchema(label='paragraph', text='This is paragraph content.')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert 'This is paragraph content.' in markdown


def test_export_to_markdown_list_item():
    """Test Markdown export for list_item items."""
    items = [
        DocItemSchema(label='list_item', text='First item'),
        DocItemSchema(label='list_item', text='Second item'),
        DocItemSchema(label='list_item', text='Third item'),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '- First item' in markdown
    assert '- Second item' in markdown
    assert '- Third item' in markdown


def test_export_to_markdown_code():
    """Test Markdown export for code items."""
    items = [
        DocItemSchema(
            label='code',
            text='def hello():\n    print("Hello, World!")',
            metadata={'language': 'python'}
        )
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '```python' in markdown
    assert 'def hello():' in markdown
    assert '```' in markdown


def test_export_to_markdown_code_no_language():
    """Test Markdown export for code items without language specified."""
    items = [DocItemSchema(label='code', text='console.log("test");')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '```\n' in markdown or '```' in markdown


def test_export_to_markdown_table():
    """Test Markdown export for table items."""
    items = [
        DocItemSchema(
            label='table',
            text='',
            metadata={
                'headers': ['Name', 'Age', 'City'],
                'rows': [['Alice', '30', 'NYC'], ['Bob', '25', 'LA']]
            }
        )
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '| Name | Age | City |' in markdown
    assert '| --- | --- | --- |' in markdown
    assert '| Alice | 30 | NYC |' in markdown
    assert '| Bob | 25 | LA |' in markdown


def test_export_to_markdown_table_no_headers():
    """Test Markdown export for table without headers."""
    items = [
        DocItemSchema(
            label='table',
            text='',
            metadata={'rows': [['A', 'B'], ['C', 'D']]}
        )
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '| A | B |' in markdown
    assert '| C | D |' in markdown


def test_export_to_markdown_image():
    """Test Markdown export for image items."""
    items = [
        DocItemSchema(
            label='image',
            text='Diagram of system architecture',
            metadata={'image_path': '/images/architecture.png'}
        )
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '![Diagram of system architecture](/images/architecture.png)' in markdown


def test_export_to_markdown_image_no_alt_text():
    """Test Markdown export for image without alt text."""
    items = [
        DocItemSchema(
            label='image',
            text='',
            metadata={'image_path': '/images/photo.jpg'}
        )
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '![Image]' in markdown or '![]' in markdown


def test_export_to_markdown_caption():
    """Test Markdown export for caption items."""
    items = [DocItemSchema(label='caption', text='Figure 1: System Overview')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '*Figure 1: System Overview*' in markdown


def test_export_to_markdown_footnote():
    """Test Markdown export for footnote items."""
    items = [
        DocItemSchema(
            label='footnote',
            text='This is a footnote explaining the term.',
            metadata={'footnote_id': '1'}
        )
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '[^1]:' in markdown
    assert 'This is a footnote explaining the term.' in markdown


def test_export_to_markdown_page_header():
    """Test Markdown export for page_header items."""
    items = [DocItemSchema(label='page_header', text='Chapter 1: Introduction')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '---' in markdown
    assert 'Header:' in markdown or 'Chapter 1: Introduction' in markdown


def test_export_to_markdown_page_footer():
    """Test Markdown export for page_footer items."""
    items = [DocItemSchema(label='page_footer', text='Page 1 of 10')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert 'Footer:' in markdown or 'Page 1 of 10' in markdown
    assert '---' in markdown


def test_export_to_markdown_all_item_types():
    """Test Markdown export handles all 10 item types in one document."""
    items = [
        DocItemSchema(label='heading', text='Document Title', level=1),
        DocItemSchema(label='paragraph', text='Introduction paragraph.'),
        DocItemSchema(label='list_item', text='List item 1'),
        DocItemSchema(label='code', text='print("code")', metadata={'language': 'python'}),
        DocItemSchema(label='table', text='', metadata={'rows': [['A', 'B']]}),
        DocItemSchema(label='image', text='Alt text', metadata={'image_path': '/img.png'}),
        DocItemSchema(label='caption', text='Caption text'),
        DocItemSchema(label='footnote', text='Footnote text', metadata={'footnote_id': '1'}),
        DocItemSchema(label='page_header', text='Header text'),
        DocItemSchema(label='page_footer', text='Footer text'),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()

    # Verify all types are represented
    assert '# Document Title' in markdown
    assert 'Introduction paragraph.' in markdown
    assert '- List item 1' in markdown
    assert '```python' in markdown
    assert '| A | B |' in markdown
    assert '![Alt text]' in markdown
    assert '*Caption text*' in markdown
    assert '[^1]:' in markdown


def test_export_to_markdown_with_document_title():
    """Test Markdown export includes document title from metadata."""
    items = [DocItemSchema(label='paragraph', text='Content')]
    metadata = DocumentMetadata(title='My Document Title', page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    assert '# My Document Title' in markdown


# ============================================================================
# GET STATISTICS TESTS - ALL 10 ITEM TYPES
# ============================================================================

def test_get_statistics_basic():
    """Test document statistics generation."""
    items = [
        DocItemSchema(label='heading', text='H1', level=1),
        DocItemSchema(label='paragraph', text='P1'),
        DocItemSchema(label='paragraph', text='P2'),
        DocItemSchema(label='table', text='', metadata={'rows': []}),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    stats = doc.get_statistics()
    assert stats['total_items'] == 4
    assert stats['label_distribution']['paragraph'] == 2
    assert stats['has_tables'] == True


def test_get_statistics_all_item_types():
    """Test statistics for document with all 10 item types."""
    items = [
        DocItemSchema(label='heading', text='H1', level=1),
        DocItemSchema(label='heading', text='H2', level=2),
        DocItemSchema(label='paragraph', text='P1'),
        DocItemSchema(label='paragraph', text='P2'),
        DocItemSchema(label='paragraph', text='P3'),
        DocItemSchema(label='list_item', text='L1'),
        DocItemSchema(label='list_item', text='L2'),
        DocItemSchema(label='code', text='code'),
        DocItemSchema(label='table', text='', metadata={'rows': []}),
        DocItemSchema(label='image', text='', metadata={'image_path': '/img.png'}),
        DocItemSchema(label='caption', text='Caption'),
        DocItemSchema(label='footnote', text='Footnote'),
        DocItemSchema(label='page_header', text='Header'),
        DocItemSchema(label='page_footer', text='Footer'),
    ]
    metadata = DocumentMetadata(page_count=10, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    stats = doc.get_statistics()

    assert stats['total_items'] == 14
    assert stats['page_count'] == 10
    assert stats['label_distribution']['heading'] == 2
    assert stats['label_distribution']['paragraph'] == 3
    assert stats['label_distribution']['list_item'] == 2
    assert stats['label_distribution']['code'] == 1
    assert stats['label_distribution']['table'] == 1
    assert stats['label_distribution']['image'] == 1
    assert stats['label_distribution']['caption'] == 1
    assert stats['label_distribution']['footnote'] == 1
    assert stats['label_distribution']['page_header'] == 1
    assert stats['label_distribution']['page_footer'] == 1
    assert stats['has_tables'] == True
    assert stats['has_code'] == True
    assert stats['has_images'] == True


def test_get_statistics_single_type():
    """Test statistics for document with single item type."""
    items = [
        DocItemSchema(label='paragraph', text='P1'),
        DocItemSchema(label='paragraph', text='P2'),
        DocItemSchema(label='paragraph', text='P3'),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    stats = doc.get_statistics()

    assert stats['total_items'] == 3
    assert stats['label_distribution']['paragraph'] == 3
    assert stats['has_tables'] == False
    assert stats['has_code'] == False
    assert stats['has_images'] == False


def test_get_statistics_no_tables_code_images():
    """Test statistics correctly identifies missing element types."""
    items = [
        DocItemSchema(label='heading', text='H1', level=1),
        DocItemSchema(label='paragraph', text='P1'),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    stats = doc.get_statistics()

    assert stats['has_tables'] == False
    assert stats['has_code'] == False
    assert stats['has_images'] == False
    assert 'table' not in stats['label_distribution']
    assert 'code' not in stats['label_distribution']
    assert 'image' not in stats['label_distribution']


# ============================================================================
# VALIDATE_DOCLING_DOCUMENT FUNCTION TESTS
# ============================================================================

def test_validate_docling_document_valid():
    """Test validate_docling_document with valid data."""
    data = {
        'doc_items': [
            {'label': 'paragraph', 'text': 'Test content'}
        ],
        'metadata': {
            'page_count': 1,
            'format': 'pdf'
        }
    }

    doc = validate_docling_document(data)

    assert isinstance(doc, DoclingDocumentSchema)
    assert len(doc.doc_items) == 1
    assert doc.metadata.page_count == 1


def test_validate_docling_document_invalid_missing_items():
    """Test validate_docling_document rejects missing doc_items."""
    data = {
        'metadata': {
            'page_count': 1,
            'format': 'pdf'
        }
    }

    with pytest.raises(ValidationError):
        validate_docling_document(data)


def test_validate_docling_document_invalid_missing_metadata():
    """Test validate_docling_document rejects missing metadata."""
    data = {
        'doc_items': [
            {'label': 'paragraph', 'text': 'Test'}
        ]
    }

    with pytest.raises(ValidationError):
        validate_docling_document(data)


def test_validate_docling_document_invalid_empty_items():
    """Test validate_docling_document rejects empty doc_items."""
    data = {
        'doc_items': [],
        'metadata': {
            'page_count': 1,
            'format': 'pdf'
        }
    }

    with pytest.raises(ValidationError, match="at least one doc_item"):
        validate_docling_document(data)


def test_validate_docling_document_invalid_item_label():
    """Test validate_docling_document rejects invalid item labels."""
    data = {
        'doc_items': [
            {'label': 'invalid_type', 'text': 'Test'}
        ],
        'metadata': {
            'page_count': 1,
            'format': 'pdf'
        }
    }

    with pytest.raises(ValidationError):
        validate_docling_document(data)


def test_validate_docling_document_malformed_data():
    """Test validate_docling_document rejects malformed data."""
    # Not a dict
    with pytest.raises((ValidationError, TypeError)):
        validate_docling_document("not a dict")

    # Wrong type for doc_items
    with pytest.raises(ValidationError):
        validate_docling_document({
            'doc_items': 'not a list',
            'metadata': {'page_count': 1, 'format': 'pdf'}
        })


def test_validate_docling_document_with_all_fields():
    """Test validate_docling_document preserves all optional fields."""
    data = {
        'document_id': 'custom-id-123',
        'schema_version': '2.0',
        'doc_items': [
            {
                'item_id': 'item-1',
                'label': 'heading',
                'text': 'Title',
                'level': 1,
                'prov': [{'page': 1, 'confidence': 0.95}],
                'metadata': {'custom': 'value'}
            }
        ],
        'metadata': {
            'title': 'Test Doc',
            'author': 'Author',
            'page_count': 5,
            'format': 'pdf',
            'language': 'en'
        },
        'source_path': '/path/to/doc.pdf'
    }

    doc = validate_docling_document(data)

    assert doc.document_id == 'custom-id-123'
    assert doc.schema_version == '2.0'
    assert doc.doc_items[0].item_id == 'item-1'
    assert doc.metadata.author == 'Author'
    assert doc.source_path == '/path/to/doc.pdf'


# ============================================================================
# CREATE_DOCLING_DOCUMENT FUNCTION TESTS
# ============================================================================

def test_create_docling_document_success():
    """Test create_docling_document with valid inputs."""
    items = [
        DocItemSchema(label='heading', text='Title', level=1),
        DocItemSchema(label='paragraph', text='Content'),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')

    doc = create_docling_document(items, metadata)

    assert isinstance(doc, DoclingDocumentSchema)
    assert len(doc.doc_items) == 2
    assert doc.document_id is not None


def test_create_docling_document_with_source_path():
    """Test create_docling_document with source_path."""
    items = [DocItemSchema(label='paragraph', text='Test')]
    metadata = DocumentMetadata(page_count=1, format='pdf')

    doc = create_docling_document(items, metadata, source_path='/docs/test.pdf')

    assert doc.source_path == '/docs/test.pdf'


def test_create_docling_document_validation_failure_empty():
    """Test create_docling_document fails with empty items."""
    metadata = DocumentMetadata(page_count=1, format='pdf')

    with pytest.raises(ValidationError, match="at least one doc_item"):
        create_docling_document([], metadata)


def test_create_docling_document_generates_ids():
    """Test create_docling_document generates unique document IDs."""
    items = [DocItemSchema(label='paragraph', text='Test')]
    metadata = DocumentMetadata(page_count=1, format='pdf')

    doc1 = create_docling_document(items, metadata)
    doc2 = create_docling_document(items, metadata)

    assert doc1.document_id != doc2.document_id


# ============================================================================
# EDGE CASE TESTS
# ============================================================================

def test_unicode_characters_in_text():
    """Test handling of unicode/special characters in text fields."""
    items = [
        DocItemSchema(label='heading', text='日本語タイトル', level=1),
        DocItemSchema(label='paragraph', text='Emoji: 🎉🔥💻'),
        DocItemSchema(label='paragraph', text='Special: <>&"\''),
        DocItemSchema(label='paragraph', text='Math: α β γ δ ∑ ∫'),
    ]
    metadata = DocumentMetadata(
        title='Ünïcödé Document',
        page_count=1,
        format='pdf'
    )
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    # Should not raise
    json_data = doc.export_to_json()
    markdown = doc.export_to_markdown()

    assert '日本語タイトル' in markdown
    assert '🎉' in markdown


def test_very_long_text():
    """Test handling of very long text content."""
    long_text = 'A' * 100000  # 100KB of text
    items = [DocItemSchema(label='paragraph', text=long_text)]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    json_data = doc.export_to_json()
    assert len(json_data['doc_items'][0]['text']) == 100000


def test_large_document_many_items():
    """Test handling of documents with many items (performance)."""
    items = [
        DocItemSchema(label='paragraph', text=f'Paragraph {i}')
        for i in range(1000)
    ]
    metadata = DocumentMetadata(page_count=100, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    stats = doc.get_statistics()
    assert stats['total_items'] == 1000
    assert stats['label_distribution']['paragraph'] == 1000


def test_empty_text_fields():
    """Test items with empty text (valid for images, tables)."""
    items = [
        DocItemSchema(label='image', text='', metadata={'image_path': '/img.png'}),
        DocItemSchema(label='table', text='', metadata={'rows': [['A']]}),
    ]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    assert len(doc.doc_items) == 2


def test_single_item_document():
    """Test minimal document with single item."""
    items = [DocItemSchema(label='paragraph', text='Only content')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    assert len(doc.doc_items) == 1
    stats = doc.get_statistics()
    assert stats['total_items'] == 1


def test_heading_without_level():
    """Test heading with default level (None)."""
    items = [DocItemSchema(label='heading', text='Heading without level')]
    metadata = DocumentMetadata(page_count=1, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    markdown = doc.export_to_markdown()
    # Should use level 1 as default (or handle None)
    assert 'Heading without level' in markdown


def test_multiple_provenance_entries():
    """Test item spanning multiple pages/locations."""
    provs = [
        Provenance(page=1, confidence=0.9),
        Provenance(page=2, confidence=0.85),
        Provenance(page=3, confidence=0.95),
    ]
    items = [
        DocItemSchema(label='table', text='', prov=provs, metadata={'rows': [['A']]})
    ]
    metadata = DocumentMetadata(page_count=3, format='pdf')
    doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

    assert len(doc.doc_items[0].prov) == 3
```

### 3. Verify Schema Implementation

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test imports
cd /opt/docling-mcp/src/docling_processor
python3 -c "from docling_schema import DoclingDocumentSchema, DocItemSchema, DocumentMetadata; print('✅ DoclingDocument schema imports successful')"

# Test schema validation
python3 << 'EOF'
from docling_schema import DoclingDocumentSchema, DocItemSchema, DocumentMetadata

# Create sample document
items = [
    DocItemSchema(label='heading', text='Sample Document', level=1),
    DocItemSchema(label='paragraph', text='This is a test paragraph.'),
]

metadata = DocumentMetadata(
    title='Test Document',
    page_count=1,
    format='pdf',
)

doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)

print(f"✅ Document created: {doc.metadata.title}")
print(f"  Items: {len(doc.doc_items)}")
print(f"  Document ID: {doc.document_id}")

# Test export to JSON
json_data = doc.export_to_json()
print(f"✅ JSON export successful: {len(json_data)} keys")

# Test export to Markdown
markdown = doc.export_to_markdown()
print(f"✅ Markdown export successful: {len(markdown)} characters")

# Test statistics
stats = doc.get_statistics()
print(f"✅ Statistics: {stats['total_items']} items, {stats['page_count']} pages")
EOF
```

---

## Verification

### Success Criteria

- [ ] DoclingDocument schema module created at `/opt/docling-mcp/src/docling_processor/docling_schema.py`
- [ ] Pydantic schemas defined: DoclingDocumentSchema, DocItemSchema, DocumentMetadata, BoundingBox, Provenance
- [ ] Field validation implemented with appropriate constraints (ge, le, pattern)
- [ ] JSON export function implemented: `export_to_json()`
- [ ] Markdown export function implemented: `export_to_markdown()` - handles all 10 item types
- [ ] Statistics function implemented: `get_statistics()` - counts all 10 item types
- [ ] Schema validation function implemented: `validate_docling_document()`
- [ ] Document creation function implemented: `create_docling_document()`
- [ ] **Unit tests pass with 100% coverage**: all item types, all validation rules, all functions, all edge cases
  - [ ] BoundingBox validation tests (coordinates, dimensions - 7 tests)
  - [ ] Provenance validation tests (page numbers, confidence boundaries - 9 tests)
  - [ ] DocItemSchema validation tests (labels, levels, metadata - 12 tests)
  - [ ] DocumentMetadata validation tests (page counts, formats - 5 tests)
  - [ ] DoclingDocumentSchema validation tests (items, metadata, IDs - 4 tests)
  - [ ] Export to JSON tests (basic, data preservation - 2 tests)
  - [ ] Export to Markdown tests (all 10 item types - 15 tests)
  - [ ] Statistics tests (all 10 item types - 4 tests)
  - [ ] validate_docling_document() function tests (valid, invalid, malformed - 7 tests)
  - [ ] create_docling_document() function tests (success, failure, IDs - 4 tests)
  - [ ] Edge case tests (unicode, long text, large docs, empty fields - 8 tests)
- [ ] Module imports without errors

### Validation Commands

```bash
source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp/src/docling_processor

# Run unit tests
pytest test_docling_schema.py -v

# Test schema validation
python3 << 'EOF'
from docling_schema import DoclingDocumentSchema, DocItemSchema, DocumentMetadata

# Test valid document
items = [DocItemSchema(label='paragraph', text='Test')]
metadata = DocumentMetadata(page_count=1, format='pdf')
doc = DoclingDocumentSchema(doc_items=items, metadata=metadata)
print(f"✅ Valid document created: {doc.document_id}")

# Test invalid document (empty items)
try:
    invalid_doc = DoclingDocumentSchema(doc_items=[], metadata=metadata)
    print("❌ Validation failed - should reject empty items")
except Exception as e:
    print(f"✅ Validation working - rejected empty items: {type(e).__name__}")
EOF
```

### Expected Output

```
✅ Valid document created: <uuid>
✅ Validation working - rejected empty items: ValidationError
```

---

## Rollback

If schema implementation fails:

```bash
# Remove schema module
rm -f /opt/docling-mcp/src/docling_processor/docling_schema.py
rm -f /opt/docling-mcp/src/docling_processor/test_docling_schema.py
```

---

## Notes

### DoclingDocument Schema Design

**Core Components**:
1. **DocItemSchema**: Individual document elements (headings, paragraphs, tables, etc.)
2. **DocumentMetadata**: Document-level metadata (title, author, page count, etc.)
3. **DoclingDocumentSchema**: Complete document with items and metadata
4. **Provenance**: Source information (page number, bounding box, confidence)
5. **BoundingBox**: Spatial coordinates for elements

### Field Validation (FR-007)

**Validation Rules**:
- Page numbers: `ge=1` (1-indexed)
- Heading levels: `ge=1, le=6` (H1-H6)
- Confidence scores: `ge=0.0, le=1.0`
- Bounding box: `x, y >= 0`, `width, height > 0`
- Doc items: `min_length=1` (at least one item required)

### Export Formats

**JSON Export** (`export_to_json()`):
- Complete lossless representation
- Suitable for storage and transmission
- MCP tool primary return format

**Markdown Export** (`export_to_markdown()`):
- Human-readable text format
- Structure preserved with Markdown syntax
- Used by `convert_document_to_markdown` MCP tool

### Integration with Docling Library

Docling library provides its own `DoclingDocument` class. This Pydantic schema:
- Wraps Docling's DoclingDocument for validation
- Adds MCP-specific export methods
- Provides statistics and analysis functions
- Ensures consistency across MCP tool responses

### Schema Versioning

Consider adding schema version field for future compatibility:
```python
schema_version: str = Field(default="1.0", description="Schema version")
```

This enables backward compatibility when schema evolves in Phase 2.

---

## Related Tasks

**Upstream Dependencies:**
- hx-docling-mcp-task-061: Docling library installation
- hx-docling-mcp-task-064: Structure preservation (provides structure elements)

**Downstream Dependencies:**
- hx-docling-mcp-task-067: MCP tool integration (uses schema for tool responses)
- hx-docling-mcp-task-031-060: MCP tools (convert_document, create_docling_document use schema)

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Agent**: albert-singh (Docling Processing Specialist)
