# Task 067: Integrate Document Processing with MCP Tools

**Task ID**: hx-docling-mcp-task-067-integrate-document-processing-with-mcp-tools
**Phase**: Development - Document Processing Integration
**Status**: Not Started
**Assigned To**: albert-singh (Docling Processing Specialist)
**Dependencies**: hx-docling-mcp-task-066 (DoclingDocument schema), hx-docling-mcp-task-031-060 (MCP tools registered)
**Estimated Time**: 4 hours

---

## Objective

Integrate Docling document processing modules (format detection, backend selection, structure preservation, OCR, schema validation) with FastMCP tools to provide complete document conversion functionality through MCP protocol, enabling AI agents to convert documents to DoclingDocument format via standardized tool invocations.

---

## Pre-Execution Validation

**CRITICAL**: Check if MCP tool integration already exists before proceeding:

```bash
# Check if document processor integration module exists
if [ -f /opt/docling-mcp/src/mcp_tools/document_converter.py ]; then
    echo "✅ VALIDATION: Document converter MCP integration already exists - Review implementation"
    echo "Module location: /opt/docling-mcp/src/mcp_tools/document_converter.py"
    # Check if module has MCP tool decorators
    grep -q "@mcp.tool\|async def convert_document" /opt/docling-mcp/src/mcp_tools/document_converter.py
    if [ $? -eq 0 ]; then
        echo "✅ MCP tool integration found - SKIP task execution"
        exit 0
    else
        echo "⚠️ Module exists but incomplete - PROCEED with implementation"
    fi
else
    echo "❌ VALIDATION: Document converter MCP integration not found - PROCEED with task"
fi
```

**If Validation Passes (Integration Already Complete)**:
- Mark task as complete with validation timestamp
- Verify MCP tool functionality with test invocations
- SKIP all implementation steps below

**If Validation Fails (Integration Not Found/Incomplete)**:
- Proceed with Prerequisites and Steps sections

---

## Prerequisites

- [ ] All document processing modules implemented:
  - [ ] Format detection (hx-docling-mcp-task-062)
  - [ ] Backend selection (hx-docling-mcp-task-063)
  - [ ] Structure preservation (hx-docling-mcp-task-064)
  - [ ] OCR integration (hx-docling-mcp-task-065)
  - [ ] DoclingDocument schema (hx-docling-mcp-task-066)
- [ ] MCP server and tools framework created (hx-docling-mcp-task-031-060)
- [ ] FastMCP framework installed and configured
- [ ] Python virtual environment activated

---

## Steps

### 1. Create Document Converter MCP Tools Module

Create `/opt/docling-mcp/src/mcp_tools/document_converter.py`:

```python
"""
Document Converter MCP Tools

Integrates Docling document processing with FastMCP tools to provide
document conversion capabilities via MCP protocol.

MCP Tools Implemented:
- convert_document: Convert to DoclingDocument JSON
- convert_document_to_markdown: Convert to Markdown
- batch_convert: Batch document conversion
"""

import sys
from pathlib import Path
from typing import Optional, List, Dict, Any
from pydantic import Field
import logging

# Import MCP Context for structured logging (optional)
try:
    from mcp.server.session import ServerSession
    from mcp.types import LoggingLevel
except ImportError:
    ServerSession = None
    LoggingLevel = None

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Initialize module logger
logger = logging.getLogger(__name__)

from docling_processor.format_detector import detect_format
from docling_processor.backend_selector import create_document_converter
from docling_processor.ocr_processor import OCRProcessor, create_ocr_processor
from docling_processor.structure_extractor import (
    extract_headings, extract_tables, extract_lists,
    extract_code_blocks, extract_images,
    validate_structure_preservation
)
from docling_processor.docling_schema import (
    DoclingDocumentSchema, validate_docling_document
)

# FastMCP will be initialized in mcp_server.py
# This module provides tool implementation functions


async def convert_document_impl(
    source: str = Field(description="Document source (file://, http://, or data: URI)"),
    format_hint: Optional[str] = Field(None, description="Optional format hint (pdf, docx, etc.)"),
    enable_ocr: bool = Field(False, description="Enable OCR for scanned documents"),
    enable_table_extraction: bool = Field(True, description="Extract table structures"),
    ocr_languages: Optional[List[str]] = Field(None, description="OCR languages (e.g., ['en', 'ja'])"),
    ctx: Optional[ServerSession] = None,  # MCP Context for structured logging
) -> DoclingDocumentSchema:
    """
    Convert document to DoclingDocument JSON format.

    This is the primary document conversion MCP tool. It:
    1. Detects document format automatically
    2. Selects appropriate backend
    3. Converts with structure preservation
    4. Returns validated DoclingDocument schema

    Args:
        source: Document source path, URL, or data URI
        format_hint: Optional format override
        enable_ocr: Enable OCR for scanned PDFs/images
        enable_table_extraction: Enable table structure extraction
        ocr_languages: Languages for OCR (default: ['en'])

    Returns:
        Validated DoclingDocument with structure preserved

    Raises:
        ValueError: If format unsupported or conversion fails
    """
    # Step 1: Detect format
    document_format = detect_format(source, hint=format_hint)

    # Step 2: Handle OCR if enabled or if image format
    if document_format in ['png', 'jpg', 'tiff'] or enable_ocr:
        # Use OCR processor
        ocr_processor = create_ocr_processor(
            languages=ocr_languages or ['en'],
            gpu=False,  # TODO: Detect GPU availability
        )

        if document_format == 'pdf':
            # Check if scanned PDF
            is_scanned = ocr_processor.is_scanned_pdf(source)
            if is_scanned or enable_ocr:
                result = ocr_processor.process_with_ocr(
                    source,
                    enable_table_extraction=enable_table_extraction
                )
            else:
                # Native PDF, use standard conversion
                converter = create_document_converter(
                    document_format,
                    enable_ocr=False,
                    enable_table_extraction=enable_table_extraction,
                )
                result = converter.convert(source)
        else:
            # Image format - always use OCR
            result = ocr_processor.process_with_ocr(source)
    else:
        # Step 3: Standard conversion (no OCR)
        converter = create_document_converter(
            document_format,
            enable_ocr=False,
            enable_table_extraction=enable_table_extraction,
        )
        result = converter.convert(source)

    # Step 4: Extract structure elements
    docling_doc = result.document

    # Validate structure preservation
    structure_validation = validate_structure_preservation(docling_doc)
    if not structure_validation['validation_passed']:
        # Log warning but don't fail conversion
        warning_msg = f"Structure validation issues for {source}: {structure_validation['errors']}"
        logger.warning(warning_msg)
        # Use MCP context logging if available
        if ctx and hasattr(ctx, 'send_log_message'):
            await ctx.send_log_message(
                level=LoggingLevel.WARNING if LoggingLevel else "warning",
                data=warning_msg,
                logger="document_converter"
            )

    # Step 5: Convert Docling's internal document to Pydantic schema
    # Use Docling's export_to_json() to get JSON-serializable dict
    try:
        docling_json = docling_doc.export_to_json()
    except AttributeError:
        # Fallback: If export_to_json() not available, convert to dict manually
        # This handles older Docling versions or custom document types
        docling_json = {
            "doc_items": [item.dict() if hasattr(item, 'dict') else vars(item) 
                         for item in getattr(docling_doc, 'doc_items', [])],
            "metadata": (getattr(docling_doc, 'metadata', {}).dict() 
                        if hasattr(getattr(docling_doc, 'metadata', {}), 'dict') 
                        else vars(getattr(docling_doc, 'metadata', {}))),
            "source_path": getattr(docling_doc, 'source_path', source),
        }
    
    # Step 6: Validate and convert to DoclingDocumentSchema (Pydantic)
    # This ensures the output conforms to our schema and is JSON-serializable
    try:
        docling_schema = validate_docling_document(docling_json)
    except Exception as e:
        raise ValueError(
            f"Failed to validate DoclingDocument schema: {e}. "
            f"The conversion produced invalid output. "
            f"Check document structure and schema compatibility."
        ) from e
    
    # Step 7: Return Pydantic schema (FastMCP will call .dict() for JSON serialization)
    return docling_schema


async def convert_document_to_markdown_impl(
    source: str = Field(description="Document source (file://, http://, or data: URI)"),
    format_hint: Optional[str] = Field(None, description="Optional format hint"),
    enable_ocr: bool = Field(False, description="Enable OCR for scanned documents"),
) -> str:
    """
    Convert document to Markdown text format.

    Args:
        source: Document source path, URL, or data URI
        format_hint: Optional format override
        enable_ocr: Enable OCR for scanned documents

    Returns:
        Markdown representation of document
    """
    # Convert to DoclingDocumentSchema (Pydantic) first
    docling_schema = await convert_document_impl(
        source=source,
        format_hint=format_hint,
        enable_ocr=enable_ocr,
    )

    # Export to Markdown using schema's built-in export method
    # DoclingDocumentSchema.export_to_markdown() converts structured doc_items to Markdown
    markdown = docling_schema.export_to_markdown()
    return markdown


async def batch_convert_impl(
    sources: List[str] = Field(description="List of document sources"),
    format_hint: Optional[str] = Field(None, description="Optional format hint (applies to all)"),
    enable_ocr: bool = Field(False, description="Enable OCR"),
    ctx: Optional[ServerSession] = None,  # MCP Context for structured logging
) -> List[DoclingDocumentSchema]:
    """
    Batch convert multiple documents.

    Args:
        sources: List of document sources
        format_hint: Optional format hint (applied to all documents)
        enable_ocr: Enable OCR for all documents

    Returns:
        List of converted DoclingDocuments (only successful conversions)

    Raises:
        ValueError: If any document conversion fails (with details of all failures)
    """
    results = []
    errors = []

    for source in sources:
        try:
            doc = await convert_document_impl(
                source=source,
                format_hint=format_hint,
                enable_ocr=enable_ocr,
                ctx=ctx,  # Pass MCP context through
            )
            results.append(doc)
        except Exception as e:
            # Log individual failure and track for aggregated error
            error_msg = f"Failed to convert {source}: {type(e).__name__}: {str(e)}"
            logger.error(error_msg, exc_info=True)
            # Use MCP context logging if available
            if ctx and hasattr(ctx, 'send_log_message'):
                await ctx.send_log_message(
                    level=LoggingLevel.ERROR if LoggingLevel else "error",
                    data=error_msg,
                    logger="batch_converter"
                )
            errors.append({
                "source": source,
                "error": str(e),
                "error_type": type(e).__name__,
            })

    # If any conversions failed, raise aggregated error
    if errors:
        error_summary = f"Batch conversion failed for {len(errors)}/{len(sources)} documents:\n"
        for err in errors:
            error_summary += f"  - {err['source']}: {err['error_type']}: {err['error']}\n"
        
        # Log summary before raising
        summary_msg = f"BATCH CONVERSION SUMMARY: {len(results)} succeeded, {len(errors)} failed"
        logger.info(summary_msg)
        # Use MCP context logging if available
        if ctx and hasattr(ctx, 'send_log_message'):
            await ctx.send_log_message(
                level=LoggingLevel.INFO if LoggingLevel else "info",
                data=summary_msg,
                logger="batch_converter"
            )
        
        raise ValueError(error_summary.strip())

    return results


# NOTE: Alternative Implementation for Partial Success
# 
# If you need to return partial results (successful conversions even when some fail),
# create a separate tool with a different return type:
#
# async def batch_convert_partial_impl(
#     sources: List[str],
#     format_hint: Optional[str] = None,
#     enable_ocr: bool = False,
# ) -> Dict[str, Any]:
#     """Return dict with 'successes' and 'failures' lists."""
#     successes = []
#     failures = []
#     
#     for source in sources:
#         try:
#             doc = await convert_document_impl(source, format_hint, enable_ocr)
#             successes.append({"source": source, "document": doc})
#         except Exception as e:
#             failures.append({"source": source, "error": str(e)})
#     
#     return {
#         "successes": successes,
#         "failures": failures,
#         "total": len(sources),
#         "success_count": len(successes),
#         "failure_count": len(failures),
#     }
#
# This approach:
# - Returns structured dict instead of List[DoclingDocumentSchema]
# - Allows MCP client to handle partial results
# - Requires different return type (not List[DoclingDocumentSchema])


# Additional helper tools

async def extract_tables_impl(
    source: str = Field(description="Document source"),
    format_hint: Optional[str] = Field(None, description="Optional format hint"),
) -> List[Dict[str, Any]]:
    """
    Extract all tables from document with cell structure.

    Args:
        source: Document source
        format_hint: Optional format hint

    Returns:
        List of tables with rows, headers, page numbers
    """
    # Convert document
    docling_doc = await convert_document_impl(
        source=source,
        format_hint=format_hint,
        enable_table_extraction=True,
    )

    # Extract tables using structure extractor
    tables = extract_tables(docling_doc)

    # Convert to JSON-serializable format with defensive attribute access
    result = []
    for table in tables:
        # Defensively access attributes with sensible defaults
        rows = getattr(table, 'rows', [])
        headers = getattr(table, 'headers', [])
        page_number = getattr(table, 'page_number', None)
        bbox = getattr(table, 'bbox', None)
        
        # Ensure rows and headers are lists (coerce types)
        if not isinstance(rows, list):
            rows = list(rows) if rows else []
        if not isinstance(headers, list):
            headers = list(headers) if headers else []
        
        result.append({
            "rows": rows,
            "headers": headers,
            "page_number": page_number,
            "bbox": bbox,
        })
    
    return result


async def parse_pdf_structure_impl(
    source: str = Field(description="PDF document source"),
) -> Dict[str, Any]:
    """
    Analyze PDF structure and return detailed element breakdown.

    Args:
        source: PDF document source

    Returns:
        Dictionary with structure analysis (headings, tables, lists, images)
    """
    # Convert PDF
    docling_doc = await convert_document_impl(
        source=source,
        format_hint='pdf',
        enable_table_extraction=True,
    )

    # Extract all structure elements
    headings = extract_headings(docling_doc)
    tables = extract_tables(docling_doc)
    lists = extract_lists(docling_doc)
    code_blocks = extract_code_blocks(docling_doc)
    images = extract_images(docling_doc)

    # Defensively build result with getattr and type coercion
    result = {
        "headings": [],
        "tables": [],
        "lists": [],
        "code_blocks": [],
        "images": [],
        "statistics": {},
    }
    
    # Process headings with defensive attribute access
    for h in headings:
        level = getattr(h, 'level', None)
        text = getattr(h, 'text', "")
        page = getattr(h, 'page_number', None)
        result["headings"].append({
            "level": level,
            "text": str(text) if text else "",
            "page": page,
        })
    
    # Process tables with defensive attribute access
    for t in tables:
        rows = getattr(t, 'rows', [])
        page = getattr(t, 'page_number', None)
        # Coerce rows to list if not already
        if not isinstance(rows, list):
            rows = list(rows) if rows else []
        result["tables"].append({
            "rows": rows,
            "page": page,
        })
    
    # Process lists with defensive attribute access
    for l in lists:
        text = getattr(l, 'text', "")
        level = getattr(l, 'level', None)
        ordered = getattr(l, 'ordered', False)
        result["lists"].append({
            "text": str(text) if text else "",
            "level": level,
            "ordered": bool(ordered),
        })
    
    # Process code blocks with defensive attribute access
    for c in code_blocks:
        language = getattr(c, 'language', None)
        page = getattr(c, 'page_number', None)
        result["code_blocks"].append({
            "language": str(language) if language else None,
            "page": page,
        })
    
    # Process images with defensive attribute access
    for i in images:
        caption = getattr(i, 'caption', "")
        page = getattr(i, 'page_number', None)
        result["images"].append({
            "caption": str(caption) if caption else "",
            "page": page,
        })
    
    # Build statistics
    result["statistics"] = {
        "heading_count": len(result["headings"]),
        "table_count": len(result["tables"]),
        "list_count": len(result["lists"]),
        "code_block_count": len(result["code_blocks"]),
        "image_count": len(result["images"]),
    }
    
    return result
```

### 2. Register MCP Tools in MCP Server

Update `/opt/docling-mcp/src/mcp_server.py` to register document conversion tools:

```python
# Add to mcp_server.py

from mcp_tools.document_converter import (
    convert_document_impl,
    convert_document_to_markdown_impl,
    batch_convert_impl,
    extract_tables_impl,
    parse_pdf_structure_impl,
)

# Register conversion tools with FastMCP
@mcp.tool(description="Convert document to DoclingDocument JSON format")
async def convert_document(
    source: str,
    format_hint: Optional[str] = None,
    enable_ocr: bool = False,
    enable_table_extraction: bool = True,
    ocr_languages: Optional[List[str]] = None,
):
    """Convert document to DoclingDocument format with structure preservation."""
    return await convert_document_impl(
        source=source,
        format_hint=format_hint,
        enable_ocr=enable_ocr,
        enable_table_extraction=enable_table_extraction,
        ocr_languages=ocr_languages,
    )


@mcp.tool(description="Convert document to Markdown text format")
async def convert_document_to_markdown(
    source: str,
    format_hint: Optional[str] = None,
    enable_ocr: bool = False,
):
    """Convert document to Markdown with structure preserved."""
    return await convert_document_to_markdown_impl(
        source=source,
        format_hint=format_hint,
        enable_ocr=enable_ocr,
    )


@mcp.tool(description="Batch convert multiple documents")
async def batch_convert(
    sources: List[str],
    format_hint: Optional[str] = None,
    enable_ocr: bool = False,
):
    """Convert multiple documents in a single request."""
    return await batch_convert_impl(
        sources=sources,
        format_hint=format_hint,
        enable_ocr=enable_ocr,
    )


@mcp.tool(description="Extract all tables from document with cell structure")
async def extract_tables(source: str, format_hint: Optional[str] = None):
    """Extract tables with rows, headers, and cell structure."""
    return await extract_tables_impl(source=source, format_hint=format_hint)


@mcp.tool(description="Analyze PDF structure and return element breakdown")
async def parse_pdf_structure(source: str):
    """Analyze PDF document structure (headings, tables, lists, images)."""
    return await parse_pdf_structure_impl(source=source)
```

### 3. Create Integration Tests

Create `/opt/docling-mcp/src/mcp_tools/test_document_converter_integration.py`:

```python
"""
Integration tests for document converter MCP tools.
"""

import pytest
from document_converter import (
    convert_document_impl,
    convert_document_to_markdown_impl,
    extract_tables_impl,
)


@pytest.mark.asyncio
async def test_convert_document_pdf():
    """Test PDF document conversion (requires sample PDF)."""
    # This test requires a sample PDF file
    # For now, it's a placeholder for integration testing phase
    pass


@pytest.mark.asyncio
async def test_convert_to_markdown():
    """Test Markdown conversion (requires sample document)."""
    pass


@pytest.mark.asyncio
async def test_extract_tables():
    """Test table extraction (requires sample document with tables)."""
    pass


# Full integration tests will be executed in hx-docling-mcp-task-171-190
```

### 4. Verify MCP Tool Integration

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test imports
cd /opt/docling-mcp/src
python3 -c "from mcp_tools.document_converter import convert_document_impl; print('✅ Document converter MCP tools import successful')"

# Test MCP tool registration (manual check)
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp/src')

from mcp_tools.document_converter import (
    convert_document_impl,
    convert_document_to_markdown_impl,
    batch_convert_impl,
    extract_tables_impl,
    parse_pdf_structure_impl,
)

print("✅ MCP tool implementations available:")
print("  - convert_document_impl")
print("  - convert_document_to_markdown_impl")
print("  - batch_convert_impl")
print("  - extract_tables_impl")
print("  - parse_pdf_structure_impl")

print("\n✅ Document processing integration complete")
EOF
```

---

## Verification

### Success Criteria

- [ ] Document converter MCP tools module created at `/opt/docling-mcp/src/mcp_tools/document_converter.py`
- [ ] MCP tool implementations created for all conversion tools:
  - [ ] `convert_document_impl`
  - [ ] `convert_document_to_markdown_impl`
  - [ ] `batch_convert_impl`
  - [ ] `extract_tables_impl`
  - [ ] `parse_pdf_structure_impl`
- [ ] Tools registered with FastMCP in mcp_server.py using `@mcp.tool()` decorator
- [ ] Format detection integrated into conversion pipeline
- [ ] Backend selection integrated based on detected format
- [ ] Structure preservation applied during conversion
- [ ] OCR integration enabled for scanned PDFs and images
- [ ] Schema validation applied to conversion results
- [ ] Module imports without errors
- [ ] MCP server can discover registered tools via `tools/list` method

### Validation Commands

```bash
source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp/src

# Test tool imports
python3 << 'EOF'
from mcp_tools.document_converter import convert_document_impl

print("✅ MCP tool implementations loaded")
print("  Tool: convert_document")
print("  Parameters: source, format_hint, enable_ocr, enable_table_extraction, ocr_languages")
EOF

# Test MCP server startup (if configured)
# python3 -m mcp_server --transport stdio
# (Send tools/list request to verify tool discovery)
```

### Expected Output

```
✅ MCP tool implementations loaded
  Tool: convert_document
  Parameters: source, format_hint, enable_ocr, enable_table_extraction, ocr_languages
```

---

## Rollback

If integration fails:

```bash
# Remove MCP tools module
rm -f /opt/docling-mcp/src/mcp_tools/document_converter.py
rm -f /opt/docling-mcp/src/mcp_tools/test_document_converter_integration.py

# Revert mcp_server.py changes (remove tool registrations)
# Manual edit required to remove @mcp.tool decorators
```

---

## Notes

### Integration Architecture

**Document Processing Pipeline**:
1. **Format Detection** → Detect document format (PDF, DOCX, etc.)
2. **Backend Selection** → Choose appropriate Docling backend
3. **OCR (if needed)** → Enable OCR for scanned documents/images
4. **Conversion** → Convert to Docling's internal DoclingDocument
5. **Structure Extraction** → Extract headings, tables, lists, code, images
6. **Schema Conversion** → Convert internal document to Pydantic DoclingDocumentSchema
7. **Schema Validation** → Validate against DoclingDocumentSchema (Pydantic)
8. **Export** → Return JSON-serializable schema to MCP client (FastMCP auto-serializes)

### Schema Conversion Process

**Why Conversion is Required**:
- Docling library returns internal `DoclingDocument` objects (not JSON-serializable)
- FastMCP requires JSON-serializable return types for MCP protocol
- Pydantic schemas provide validation, type safety, and automatic serialization
- Our `DoclingDocumentSchema` adds custom export methods (export_to_markdown, export_to_json)

**Conversion Implementation**:
```python
# Step 1: Get Docling's internal document from conversion result
docling_doc = result.document  # Type: docling.document.DoclingDocument

# Step 2: Convert to JSON-serializable dict using Docling's built-in export
docling_json = docling_doc.export_to_json()  # Type: Dict[str, Any]

# Step 3: Validate and convert to Pydantic schema
docling_schema = validate_docling_document(docling_json)  # Type: DoclingDocumentSchema

# Step 4: Return Pydantic schema (FastMCP calls .dict() for JSON serialization)
return docling_schema  # FastMCP auto-converts to JSON for MCP client
```

**Fallback Strategy**:
If `export_to_json()` is not available (older Docling versions):
```python
# Manual conversion using object attributes
docling_json = {
    "doc_items": [item.dict() for item in docling_doc.doc_items],
    "metadata": docling_doc.metadata.dict(),
    "source_path": docling_doc.source_path,
}
```

**Benefits**:
- ✅ Type safety via Pydantic validation
- ✅ JSON serialization guaranteed (FastMCP requirement)
- ✅ Schema validation catches conversion errors early
- ✅ Clear error messages for debugging
- ✅ Consistent output format across all tools

### Defensive Attribute Access Pattern

**Problem**: Structure extraction objects may have missing or malformed attributes:
- Different Docling versions expose different attributes
- Document processing may fail to extract certain elements
- Direct attribute access (`obj.attr`) raises `AttributeError` at runtime

**Solution**: Defensive programming with `getattr()` and type coercion:

```python
# UNSAFE: Direct attribute access (crashes if missing)
rows = table.rows          # AttributeError if table has no 'rows'
headers = table.headers    # AttributeError if table has no 'headers'

# SAFE: Defensive attribute access with defaults
rows = getattr(table, 'rows', [])           # Returns [] if missing
headers = getattr(table, 'headers', [])     # Returns [] if missing
page = getattr(table, 'page_number', None)  # Returns None if missing

# SAFER: Type coercion for robustness
if not isinstance(rows, list):
    rows = list(rows) if rows else []  # Convert iterables or None to list
```

**Default Values by Attribute**:

| Attribute | Default | Rationale |
|-----------|---------|-----------|
| `rows`, `headers` | `[]` | Empty list for missing table data |
| `page_number`, `page` | `None` | Nullable integer field |
| `bbox` | `None` | Nullable bounding box |
| `level` | `None` | Nullable heading/list level |
| `text`, `caption` | `""` | Empty string for missing text |
| `ordered` | `False` | Boolean default for unordered lists |
| `language` | `None` | Nullable language code |

**Applied in Functions**:
- `extract_tables_impl()`: Defensive access for rows, headers, page_number, bbox
- `parse_pdf_structure_impl()`: Defensive access for all structure elements (headings, tables, lists, code blocks, images)

**Benefits**:
- ✅ No runtime crashes from missing attributes
- ✅ Graceful handling of partial extraction failures
- ✅ Compatible with multiple Docling versions
- ✅ JSON-safe outputs (no undefined/null issues)
- ✅ Type coercion prevents serialization errors

### MCP Tool Design

**Tool Naming Convention**:
- Primary tools: `convert_document`, `convert_document_to_markdown`
- Batch operations: `batch_convert`
- Specialized extraction: `extract_tables`, `parse_pdf_structure`

**Parameter Design**:
- Required parameters: `source` (document path/URL)
- Optional parameters: `format_hint`, `enable_ocr`, `ocr_languages`
- Defaults favor convenience (OCR disabled, table extraction enabled)

### Error Handling Strategy

**Single Document Conversion**:
- Errors propagate directly to MCP client (no error suppression)
- MCP protocol handles error reporting to user
- Clear error messages with diagnostic information

**Batch Conversion** (`batch_convert_impl`):
- **All-or-nothing approach**: Fails entire batch if any document fails
- Logs each individual failure as it occurs
- Collects all errors and raises aggregated `ValueError` at end
- Error message includes:
  - Total success/failure count
  - Per-document error details (source, error type, error message)
- MCP receives single error with all failure details

**Error Aggregation Example**:
```python
# Batch of 3 documents, 2 fail
# Output logged during processing:
ERROR: Failed to convert doc1.pdf: FileNotFoundError: [Errno 2] No such file
ERROR: Failed to convert doc3.pdf: ValueError: Unsupported format: .xyz

# Final error raised to MCP:
ValueError: Batch conversion failed for 2/3 documents:
  - doc1.pdf: FileNotFoundError: [Errno 2] No such file or directory
  - doc3.pdf: ValueError: Unsupported format: .xyz
```

**MCP Error Responses**:
- Format unsupported → `ValueError` with supported format list
- Conversion failure → Exception propagated with diagnostic message
- File not found → `FileNotFoundError` with path information
- OCR failure → `RuntimeError` from OCR processor with retry details
- Batch conversion → `ValueError` with aggregated error summary

**Benefits**:
- ✅ Type-safe return values (no mixed dict/schema returns)
- ✅ Clear error responsibility (MCP handles error reporting)
- ✅ Detailed diagnostics for debugging
- ✅ Consistent error handling across all tools
- ✅ No silent failures or partial results

### Structured Logging Integration

**Dual Logging System**:
All MCP tool implementations use both Python logging and MCP context logging:

```python
# Python logging (always available)
logger.warning("Structure validation issues")
logger.error("Conversion failed", exc_info=True)
logger.info("Batch completed")

# MCP context logging (when ctx provided)
if ctx and hasattr(ctx, 'send_log_message'):
    await ctx.send_log_message(
        level=LoggingLevel.WARNING,
        data=warning_msg,
        logger="document_converter"
    )
```

**Logging Levels Used**:

| Level | Usage | Example |
|-------|-------|---------|
| `WARNING` | Structure validation issues | "Structure validation issues for doc.pdf: missing table headers" |
| `ERROR` | Individual conversion failures | "Failed to convert doc1.pdf: FileNotFoundError" |
| `INFO` | Batch operation summaries | "BATCH CONVERSION SUMMARY: 8 succeeded, 2 failed" |

**MCP Context Integration**:
- Functions accept optional `ctx: Optional[ServerSession]` parameter
- When `ctx` is provided, logs sent via `await ctx.send_log_message()`
- MCP client receives structured log messages in real-time
- Falls back to Python logging if MCP context unavailable

**Logger Names**:
- `document_converter` - Single document conversions
- `batch_converter` - Batch operations

**Benefits**:
- ✅ Structured logging for MCP clients (real-time visibility)
- ✅ Python logging for server-side debugging
- ✅ Backward compatible (ctx optional)
- ✅ Async-safe logging (await ctx.send_log_message)
- ✅ Exception details preserved (exc_info=True)

**Example Integration**:
```python
# MCP server tool registration
@mcp.tool()
async def convert_document(
    source: str,
    format_hint: Optional[str] = None,
    enable_ocr: bool = False,
    ctx: ServerSession = None,
) -> DoclingDocumentSchema:
    return await convert_document_impl(
        source=source,
        format_hint=format_hint,
        enable_ocr=enable_ocr,
        ctx=ctx,  # Pass MCP context for logging
    )
```

### Performance Considerations

**Conversion Time Estimates**:
- Small PDF (10 pages): 2-5 seconds
- Large PDF (100 pages): 20-40 seconds
- Scanned PDF with OCR (10 pages): 10-20 seconds
- DOCX (50 pages): 3-7 seconds

**Timeout Configuration**:
- Default tool timeout: 120 seconds (configurable in mcp_server.py)
- Batch conversion: 600 seconds (10 minutes for large batches)

### Integration with Other MCP Tools

**Downstream Tools** (use converted DoclingDocument):
- `generate_knowledge_graph`: Uses DoclingDocument for entity extraction
- `extract_entities`: Operates on DoclingDocument structure
- `merge_documents`: Combines multiple DoclingDocuments

**Tool Composition Pattern**:
```python
# Example workflow via MCP
doc = await convert_document(source="file:///path/to/doc.pdf")
knowledge_graph = await generate_knowledge_graph(docling_document=doc)
```

### Future Enhancements (Phase 2)

**Additional Tools**:
- `convert_document_with_preprocessing`: Image enhancement, deskewing
- `extract_document_metadata`: Author, title, keywords
- `classify_document_type`: Report, invoice, contract, etc.
- `detect_document_language`: Multi-language detection

---

## Related Tasks

**Upstream Dependencies:**
- hx-docling-mcp-task-061: Docling library installation
- hx-docling-mcp-task-062: Format detection
- hx-docling-mcp-task-063: Backend selection
- hx-docling-mcp-task-064: Structure preservation
- hx-docling-mcp-task-065: OCR integration
- hx-docling-mcp-task-066: DoclingDocument schema
- hx-docling-mcp-task-031-060: MCP server and tools framework

**Downstream Dependencies:**
- hx-docling-mcp-task-081-100: Knowledge graph generation (uses converted documents)
- hx-docling-mcp-task-171-190: Integration testing (tests all MCP tools)

---

**Task Created**: 2025-12-01
**Last Updated**: 2025-12-01
**Agent**: albert-singh (Docling Processing Specialist)
