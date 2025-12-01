# Task 020: Integrate Docling Processing with MCP Tools

**Task ID**: hx-docling-mcp-task-020
**Component**: Docling Document Processing (albert-singh)
**Category**: Integration
**Priority**: HIGH (completes Docling processing pipeline)
**Estimated Effort**: 2-3 hours
**Status**: NOT_STARTED

---

## Objective

Integrate complete Docling document processing pipeline (format detection, backend selection, structure preservation, OCR, DoclingDocument schema) with MCP tool handlers (convert_document, convert_document_to_markdown, batch_convert).

---

## Prerequisites

- [x] Task 010: Docling library installed
- [x] Task 011: Format detection configured
- [x] Task 012: Backend selection configured
- [x] Task 013: Structure preservation implemented
- [x] Task 014: OCR pipeline integrated
- [x] Task 015: DoclingDocument schema implemented
- [ ] Task 002: MCP conversion tools registered (james-rodriguez)

---

## Technical Context

**From Plan** (plan.md lines 193-277):
- **MCP Conversion Tools**: convert_document, convert_document_to_markdown, batch_convert
- **Integration Points**: Docling processor → MCP tool handlers
- **Response Format**: DoclingDocument JSON (serialized via Pydantic)

**From Specification** (node-spec.md Section 5.3, Tools):
- convert_document: source (str), format_hint (str), options (dict) → DoclingDocument
- convert_document_to_markdown: source (str) → Markdown (str)
- batch_convert: sources (list[str]) → list[DoclingDocument]

---

## Implementation Steps

### Step 1: Create Complete Docling Processor Orchestrator

**File**: `/opt/docling-mcp/application/docling_mcp/processors/docling_processor.py` (complete implementation)

```python
"""
Complete Docling document processing orchestrator.

Integrates:
- Format detection (Task 011)
- Backend selection (Task 012)
- Structure preservation (Task 013)
- OCR pipeline (Task 014)
- DoclingDocument schema (Task 015)
"""

import os
from typing import Optional, Dict, Any
from pathlib import Path

from docling_mcp.processors.format_detector import detect_document_format
from docling_mcp.processors.backend_selector import (
    select_backend,
    get_backend_config,
    get_fallback_backends,
    Backend
)
from docling_mcp.processors.structure_extractor import StructureExtractor
from docling_mcp.processors.ocr_processor import OCRProcessor
from docling_mcp.models.docling_document import (
    DoclingDocument,
    DocumentMetadata,
    ParagraphItem
)


class DoclingProcessor:
    """
    Orchestrates complete document processing pipeline.

    Pipeline stages:
    1. Format detection
    2. Backend selection
    3. Document conversion
    4. Structure extraction
    5. DoclingDocument assembly
    """

    def __init__(self):
        self.structure_extractor = StructureExtractor()
        self.ocr_processor = OCRProcessor()

    async def convert_document(
        self,
        source: str,
        format_hint: Optional[str] = None,
        options: Optional[Dict[str, Any]] = None
    ) -> DoclingDocument:
        """
        Convert document to DoclingDocument format.

        Args:
            source: File path or URL
            format_hint: Optional format hint (pdf, docx, etc.)
            options: Optional conversion options

        Returns:
            DoclingDocument instance

        Raises:
            ValueError: If conversion fails
        """
        options = options or {}

        # Stage 1: Format detection
        detected_format = detect_document_format(source, format_hint)
        print(f"Detected format: {detected_format}")

        # Stage 2: Backend selection
        backend = select_backend(detected_format, source, options)
        backend_config = get_backend_config(backend)
        print(f"Selected backend: {backend.value}")

        # Stage 3: Document conversion (with fallback)
        try:
            raw_doc = await self._convert_with_backend(
                source,
                backend,
                backend_config,
                detected_format
            )
        except Exception as e:
            print(f"Primary backend failed: {e}")

            # Try fallback backends
            fallbacks = get_fallback_backends(backend)
            for fallback_backend in fallbacks:
                try:
                    print(f"Trying fallback: {fallback_backend.value}")
                    fallback_config = get_backend_config(fallback_backend)
                    raw_doc = await self._convert_with_backend(
                        source,
                        fallback_backend,
                        fallback_config,
                        detected_format
                    )
                    backend = fallback_backend  # Update to fallback backend
                    break
                except Exception:
                    continue
            else:
                raise ValueError(f"All backends failed for {source}")

        # Stage 4: Structure extraction
        structure = self.structure_extractor.extract_structure(raw_doc)

        # Stage 5: DoclingDocument assembly
        doc = self._assemble_docling_document(
            raw_doc,
            structure,
            detected_format,
            backend.value,
            source
        )

        return doc

    async def _convert_with_backend(
        self,
        source: str,
        backend: Backend,
        config: dict,
        format: str
    ):
        """Convert document using specific backend."""
        if backend == Backend.PYPDFIUM2:
            from docling.document_converter import DocumentConverter
            converter = DocumentConverter()
            result = converter.convert(source)
            return result.document

        elif backend == Backend.OCR_PIPELINE:
            from docling_mcp.processors.backends.ocr_backend import OCRBackend
            ocr_backend = OCRBackend()
            doc_items = ocr_backend.process_scanned_pdf(source)
            # Return mock document with OCR items
            return type('RawDoc', (), {'doc_items': doc_items})()

        elif backend == Backend.PYTHON_DOCX:
            from docling.document_converter import DocumentConverter
            converter = DocumentConverter()
            result = converter.convert(source)
            return result.document

        # ... (other backends)

        else:
            raise ValueError(f"Backend not implemented: {backend}")

    def _assemble_docling_document(
        self,
        raw_doc: Any,  # Type depends on backend (DoclingDocument or dict)
        structure: Dict[str, Any],
        format: str,
        backend_used: str,
        source: str
    ) -> DoclingDocument:
        """
        Assemble final DoclingDocument from raw conversion and structure.
        
        Args:
            raw_doc: Raw document from backend (may be DoclingDocument instance or dict)
            structure: Extracted structure dict with 'headings', 'tables', 'lists', 'images' keys
            format: Document format (e.g., 'pdf', 'docx')
            backend_used: Backend name (e.g., 'docling', 'pypdf', 'pdfminer')
            source: Source file path
            
        Returns:
            DoclingDocument with unified structure
            
        Note:
            Handles both dict-based items (from structure dict) and Pydantic model instances
            (from raw_doc.doc_items). Uses isinstance checks to determine item type.
        """
        # Extract doc items from raw document
        doc_items = []

        # Add structured elements (headings, tables, lists, images)
        # These come from structure dict and are dicts
        for heading in structure.get('headings', []):
            doc_items.append(heading)

        for table in structure.get('tables', []):
            doc_items.append(table)

        for list_item in structure.get('lists', []):
            doc_items.append(list_item)

        for image in structure.get('images', []):
            doc_items.append(image)

        # Add paragraphs from raw document
        # raw_doc may be a DoclingDocument (Pydantic model) or dict depending on backend
        if hasattr(raw_doc, 'doc_items'):
            for item in raw_doc.doc_items:
                # Handle both dict and Pydantic model formats
                # Dict format (from some backends): use .get() for safe access
                if isinstance(item, dict):
                    if item.get('type') == 'paragraph':
                        doc_items.append(item)
                # Pydantic model format (from Docling backend): use attribute access
                elif hasattr(item, 'type'):
                    # Type can be accessed as attribute on Pydantic models
                    if item.type == 'paragraph' or isinstance(item, ParagraphItem):
                        doc_items.append(item)

        # Extract metadata
        metadata = DocumentMetadata(
            title=getattr(raw_doc, 'title', None),
            page_count=self._get_page_count(raw_doc),
            format=format,
            file_size_bytes=os.path.getsize(source) if os.path.exists(source) else None,
            backend_used=backend_used,
            extraction_model="docling~2.25",
            schema_version="1.0.0"
        )

        return DoclingDocument(
            doc_items=doc_items,
            metadata=metadata
        )

    def _get_page_count(self, raw_doc) -> int:
        """Extract page count from raw document."""
        if hasattr(raw_doc, 'page_count'):
            return raw_doc.page_count
        elif hasattr(raw_doc, 'doc_items'):
            # Count unique page numbers
            pages = set()
            for item in raw_doc.doc_items:
                if isinstance(item, dict) and 'page' in item:
                    pages.add(item['page'])
            return len(pages) if pages else 1
        return 1

    async def convert_to_markdown(self, source: str) -> str:
        """
        Convert document to Markdown format.

        Args:
            source: File path or URL

        Returns:
            Markdown string
        """
        # First convert to DoclingDocument
        doc = await self.convert_document(source)

        # Convert DoclingDocument to Markdown
        markdown_parts = []

        for item in doc.doc_items:
            if item.type == 'heading':
                markdown_parts.append(f"{'#' * item.level} {item.text}\n")
            elif item.type == 'paragraph':
                markdown_parts.append(f"{item.text}\n")
            elif item.type in ['ordered_list', 'unordered_list']:
                for list_item in item.items:
                    prefix = f"{list_item.number}." if item.type == 'ordered_list' else "-"
                    indent = "  " * list_item.level
                    markdown_parts.append(f"{indent}{prefix} {list_item.text}\n")
            elif item.type == 'table':
                # Simple table markdown (without merged cells)
                markdown_parts.append(self._table_to_markdown(item))
            elif item.type == 'code_block':
                markdown_parts.append(f"```{item.language}\n{item.code}\n```\n")

        return '\n'.join(markdown_parts)

    def _table_to_markdown(self, table) -> str:
        """Convert table to Markdown format."""
        # Simplified table rendering (no merged cell support)
        rows = [['' for _ in range(table.num_cols)] for _ in range(table.num_rows)]

        for cell in table.cells:
            rows[cell.row][cell.col] = cell.text

        md_lines = []
        for idx, row in enumerate(rows):
            md_lines.append(f"| {' | '.join(row)} |")
            if idx == 0:
                md_lines.append(f"| {' | '.join(['---'] * table.num_cols)} |")

        return '\n'.join(md_lines) + '\n'
```

---

### Step 2: Update MCP Tool Handlers

**File**: `/opt/docling-mcp/application/docling_mcp/tools/conversion_tools.py` (update from Task 002)

```python
from docling_mcp.processors.docling_processor import DoclingProcessor

# Initialize processor singleton
docling_processor = DoclingProcessor()


@mcp.tool()
async def convert_document(
    source: str,
    format_hint: str = None,
    options: dict = None
) -> dict:
    """
    Convert document to DoclingDocument format.

    Args:
        source: File path or URL
        format_hint: Optional format hint
        options: Optional conversion options

    Returns:
        DoclingDocument as dictionary
    """
    doc = await docling_processor.convert_document(source, format_hint, options)
    return doc.to_dict()


@mcp.tool()
async def convert_document_to_markdown(source: str) -> str:
    """
    Convert document to Markdown format.

    Args:
        source: File path or URL

    Returns:
        Markdown string
    """
    markdown = await docling_processor.convert_to_markdown(source)
    return markdown


@mcp.tool()
async def batch_convert(sources: list[str], options: dict = None) -> list[dict]:
    """
    Batch convert multiple documents.

    Args:
        sources: List of file paths or URLs
        options: Optional conversion options

    Returns:
        List of DoclingDocument dictionaries
    """
    results = []

    for source in sources:
        try:
            doc = await docling_processor.convert_document(source, options=options)
            results.append({
                "source": source,
                "status": "success",
                "document": doc.to_dict()
            })
        except Exception as e:
            results.append({
                "source": source,
                "status": "error",
                "error": str(e)
            })

    return results
```

---

### Step 3: Create Integration Tests

**File**: `/opt/docling-mcp/tests/test_mcp_integration.py`

```python
"""Integration tests for Docling + MCP tools."""

import pytest
from docling_mcp.processors.docling_processor import DoclingProcessor


@pytest.mark.asyncio
class TestDoclingMCPIntegration:
    """Test complete Docling to MCP tool integration."""

    async def test_convert_pdf_to_docling_document(self, sample_pdf):
        """Test end-to-end PDF conversion."""
        processor = DoclingProcessor()
        doc = await processor.convert_document(sample_pdf)

        assert doc.metadata.format == 'pdf'
        assert doc.metadata.page_count > 0
        assert len(doc.doc_items) > 0

    async def test_convert_to_markdown(self, sample_pdf):
        """Test Markdown conversion."""
        processor = DoclingProcessor()
        markdown = await processor.convert_to_markdown(sample_pdf)

        assert isinstance(markdown, str)
        assert len(markdown) > 0

    async def test_batch_conversion(self, sample_pdfs):
        """Test batch conversion."""
        processor = DoclingProcessor()

        for pdf in sample_pdfs:
            doc = await processor.convert_document(pdf)
            assert doc.metadata.format == 'pdf'
```

---

## Success Criteria

- [ ] Complete Docling processor orchestrator implemented
- [ ] Format detection → Backend selection → Conversion → Structure extraction pipeline working
- [ ] MCP tool handlers updated to use Docling processor
- [ ] convert_document tool returns DoclingDocument JSON
- [ ] convert_document_to_markdown tool returns Markdown string
- [ ] batch_convert tool processes multiple documents
- [ ] Integration tests created and passing (≥90% coverage)
- [ ] End-to-end conversion tested for PDF, DOCX, images

---

## Dependencies

**Depends On**:
- Tasks 010-015: All Docling processing tasks complete
- Task 002: MCP conversion tools registered

**Blocks**:
- Task 020-027: Test suite execution (requires working Docling integration)

---

**Task Owner**: albert-singh (Docling Document Processing SME) + james-rodriguez (MCP integration)
**Created**: 2025-11-27
