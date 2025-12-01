# Task: Register MCP Conversion Tools (3 tools)

**Task ID**: hx-docling-mcp-task-009
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-001 (FastMCP Framework Installation)
**Parallel Execution**: No (sequential after task 001)

## Objective

Implement and register 3 conversion MCP tools (`convert_document`, `convert_document_to_markdown`, `batch_convert`) with complete Pydantic schemas, docling integration, and MCP protocol compliance.

## Prerequisites

- FastMCP framework installed and server skeleton created (Task 005 complete)
- Docling library installed in virtual environment
- Application directory structure at `/opt/docling-mcp/application/docling_mcp/` exists

## Steps

### 1. Create Pydantic Models for Conversion Tools

```bash
# Create conversion tool models file
cat > /opt/docling-mcp/application/docling_mcp/models/conversion.py <<'EOF'
"""
Pydantic models for MCP Conversion Tools.

Defines input/output schemas for:
- convert_document
- convert_document_to_markdown
- batch_convert
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum

class DocumentFormat(str, Enum):
    """Supported document formats."""
    PDF = "pdf"
    DOCX = "docx"
    PPTX = "pptx"
    XLSX = "xlsx"
    HTML = "html"
    IMAGE = "image"
    AUTO = "auto"

class OCRLanguage(str, Enum):
    """Supported OCR languages."""
    ENGLISH = "eng"
    SPANISH = "spa"
    FRENCH = "fra"
    GERMAN = "deu"
    CHINESE = "chi_sim"

# ============================================================================
# Tool 1: convert_document
# ============================================================================

class ConvertDocumentInput(BaseModel):
    """Input schema for convert_document tool."""
    document_source: str = Field(
        ...,
        description="Document source: file path (/path/to/doc.pdf), URL (https://...), or base64-encoded data (data:...)"
    )
    format_hint: Optional[DocumentFormat] = Field(
        None,
        description="Optional format hint (overrides auto-detection). Use if source lacks extension."
    )
    preserve_images: bool = Field(
        True,
        description="Include images in DoclingDocument (base64-encoded)"
    )
    ocr_enabled: bool = Field(
        True,
        description="Enable OCR for scanned PDFs and images (uses tesseract)"
    )
    ocr_language: OCRLanguage = Field(
        OCRLanguage.ENGLISH,
        description="OCR language for text extraction"
    )
    table_detection: bool = Field(
        True,
        description="Detect and extract table structures"
    )
    cache_result: bool = Field(
        True,
        description="Cache converted DoclingDocument in Redis (1h TTL)"
    )

class DoclingDocumentOutput(BaseModel):
    """Output schema for DoclingDocument."""
    document_id: str = Field(..., description="Unique document identifier (SHA256 hash)")
    format: str = Field(..., description="Detected document format (pdf, docx, etc.)")
    content: Dict[str, Any] = Field(..., description="Hierarchical document structure (doc_items tree)")
    metadata: Dict[str, Any] = Field(
        ...,
        description="Extraction metadata: page_count, processing_time_ms, backend_used, ocr_applied"
    )

# ============================================================================
# Tool 2: convert_document_to_markdown
# ============================================================================

class TableFormat(str, Enum):
    """Markdown table format options."""
    GFM = "gfm"  # GitHub Flavored Markdown (pipe tables)
    HTML = "html"  # HTML table tags
    PLAIN = "plain"  # Plain text representation

class ConvertToMarkdownInput(BaseModel):
    """Input schema for convert_document_to_markdown tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID from cache)"
    )
    table_format: TableFormat = Field(
        TableFormat.GFM,
        description="Table rendering format (gfm = GitHub tables, html = HTML tags, plain = ASCII)"
    )
    max_line_length: Optional[int] = Field(
        None,
        description="Max line length for text wrapping (None = no wrapping)"
    )
    include_images: bool = Field(
        False,
        description="Include image references as Markdown ![alt](src) syntax"
    )
    preserve_headings: bool = Field(
        True,
        description="Preserve heading hierarchy (# ## ### etc.)"
    )
    preserve_lists: bool = Field(
        True,
        description="Preserve list formatting (bullets and numbering)"
    )
    cache_result: bool = Field(
        True,
        description="Cache Markdown output in Redis"
    )

class MarkdownOutput(BaseModel):
    """Output schema for Markdown conversion."""
    markdown_text: str = Field(..., description="Full Markdown-formatted text")
    metadata: Dict[str, Any] = Field(
        ...,
        description="Conversion metadata: format_used, processing_time_ms, source_document_id"
    )

# ============================================================================
# Tool 3: batch_convert
# ============================================================================

class BatchConvertInput(BaseModel):
    """Input schema for batch_convert tool."""
    document_sources: List[str] = Field(
        ...,
        description="List of document sources (file paths, URLs, or DoclingDocument IDs)",
        min_length=1,
        max_length=100
    )
    max_concurrent: int = Field(
        4,
        description="Maximum concurrent conversions (1-10)",
        ge=1,
        le=10
    )
    fail_fast: bool = Field(
        False,
        description="Stop batch on first error (False = continue processing remaining documents)"
    )
    output_format: str = Field(
        "docling_document",
        description="Output format: 'docling_document' or 'markdown'"
    )
    progress_callback: bool = Field(
        False,
        description="Enable progress events via SSE transport (requires SSE client)"
    )

class BatchDocumentResult(BaseModel):
    """Result for single document in batch."""
    source: str = Field(..., description="Original document source")
    success: bool = Field(..., description="Conversion succeeded")
    document_id: Optional[str] = Field(None, description="Document ID if success=True")
    output: Optional[Dict[str, Any]] = Field(None, description="DoclingDocument or Markdown output")
    error: Optional[str] = Field(None, description="Error message if success=False")
    processing_time_ms: int = Field(..., description="Processing time for this document")

class BatchConvertOutput(BaseModel):
    """Output schema for batch_convert tool."""
    results: List[BatchDocumentResult] = Field(..., description="Per-document results")
    summary: Dict[str, Any] = Field(
        ...,
        description="Summary statistics: total, successful, failed, total_time_ms, average_time_ms"
    )

EOF

# Set ownership and permissions
chown "docling-mcp@hx.dev.local:domain users@hx.dev.local" /opt/docling-mcp/application/docling_mcp/models/conversion.py
chmod 644 /opt/docling-mcp/application/docling_mcp/models/conversion.py
```

### 2. Implement Conversion Tool Handlers

```bash
# Create conversion tools implementation
cat > /opt/docling-mcp/application/docling_mcp/tools/conversion.py <<'EOF'
"""
MCP Conversion Tools Implementation.

Implements 3 MCP tools:
1. convert_document: PDF/DOCX/images → DoclingDocument
2. convert_document_to_markdown: Document → Markdown text
3. batch_convert: Parallel batch conversion
"""

import logging
import hashlib
import asyncio
from typing import List
from concurrent.futures import ThreadPoolExecutor

from fastmcp import FastMCP
from ..models.conversion import (
    ConvertDocumentInput,
    DoclingDocumentOutput,
    ConvertToMarkdownInput,
    MarkdownOutput,
    BatchConvertInput,
    BatchConvertOutput,
    BatchDocumentResult
)

logger = logging.getLogger(__name__)

# Thread pool for CPU-bound docling processing
executor = ThreadPoolExecutor(max_workers=4)

# ============================================================================
# Tool Registration Functions
# ============================================================================

def register_conversion_tools(mcp: FastMCP):
    """
    Register all 3 conversion tools with FastMCP server.

    Args:
        mcp: FastMCP server instance
    """
    logger.info("Registering conversion tools...")

    # Tools will be registered via decorators
    # This function serves as entry point for tool module

    logger.info("Conversion tools registered: convert_document, convert_document_to_markdown, batch_convert")

# ============================================================================
# Tool 1: convert_document
# ============================================================================

def convert_document_impl(mcp: FastMCP):
    """Decorator-based tool registration for convert_document."""

    @mcp.tool(
        name="convert_document",
        description="Convert document (PDF, DOCX, PPTX, XLSX, HTML, images) to structured DoclingDocument format with optional OCR and table detection."
    )
    async def convert_document(input: ConvertDocumentInput) -> DoclingDocumentOutput:
        """
        Convert document to DoclingDocument format.

        Workflow:
        1. Format detection (MIME + extension + hint)
        2. Backend selection (PDF → pypdfium2, DOCX → python-docx, etc.)
        3. Document parsing (structure extraction)
        4. DoclingDocument assembly
        5. Redis caching (if enabled)

        Args:
            input: ConvertDocumentInput with document source and options

        Returns:
            DoclingDocumentOutput: Structured document with metadata

        Raises:
            InvalidParamsError: If document source invalid or format unsupported
            InternalError: If docling processing fails
        """
        logger.info(f"convert_document called: source={input.document_source[:50]}...")

        # TODO: Implement docling integration (deferred to document processing pipeline task)
        # For now, return placeholder structure

        # Calculate document ID (SHA256 of source)
        doc_id = hashlib.sha256(input.document_source.encode()).hexdigest()[:16]

        # Placeholder response
        return DoclingDocumentOutput(
            document_id=doc_id,
            format="pdf",  # Placeholder
            content={
                "doc_items": [],
                "text": "Placeholder: Docling integration pending"
            },
            metadata={
                "page_count": 0,
                "processing_time_ms": 0,
                "backend_used": "placeholder",
                "ocr_applied": False
            }
        )

    return convert_document

# ============================================================================
# Tool 2: convert_document_to_markdown
# ============================================================================

def convert_document_to_markdown_impl(mcp: FastMCP):
    """Decorator-based tool registration for convert_document_to_markdown."""

    @mcp.tool(
        name="convert_document_to_markdown",
        description="Convert document to Markdown format optimized for LLM consumption with configurable table formatting and heading preservation."
    )
    async def convert_document_to_markdown(input: ConvertToMarkdownInput) -> MarkdownOutput:
        """
        Convert document to Markdown text.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Apply Markdown conversion rules (headings, lists, tables, code blocks)
        3. Format tables per table_format parameter
        4. Apply line wrapping if max_line_length set
        5. Cache result in Redis

        Args:
            input: ConvertToMarkdownInput with document source and formatting options

        Returns:
            MarkdownOutput: Markdown text with metadata
        """
        logger.info(f"convert_document_to_markdown called: source={input.document_source[:50]}...")

        # TODO: Implement Markdown conversion logic
        # Placeholder response

        return MarkdownOutput(
            markdown_text="# Placeholder Markdown\n\nDocling integration pending.",
            metadata={
                "format_used": input.table_format.value,
                "processing_time_ms": 0,
                "source_document_id": "placeholder"
            }
        )

    return convert_document_to_markdown

# ============================================================================
# Tool 3: batch_convert
# ============================================================================

def batch_convert_impl(mcp: FastMCP):
    """Decorator-based tool registration for batch_convert."""

    @mcp.tool(
        name="batch_convert",
        description="Batch convert multiple documents in parallel with configurable concurrency, fail-fast mode, and optional progress events via SSE."
    )
    async def batch_convert(input: BatchConvertInput) -> BatchConvertOutput:
        """
        Batch convert multiple documents in parallel.

        Workflow:
        1. Create asyncio semaphore (max_concurrent limit)
        2. Launch parallel conversion tasks
        3. Emit progress events if SSE enabled
        4. Handle errors per fail_fast setting
        5. Aggregate results and summary statistics

        Args:
            input: BatchConvertInput with document list and batch options

        Returns:
            BatchConvertOutput: Per-document results + summary stats
        """
        logger.info(f"batch_convert called: {len(input.document_sources)} documents, max_concurrent={input.max_concurrent}")

        # TODO: Implement parallel batch processing
        # Placeholder response with per-document results

        results = [
            BatchDocumentResult(
                source=source,
                success=True,
                document_id=hashlib.sha256(source.encode()).hexdigest()[:16],
                output={"content": "placeholder"},
                error=None,
                processing_time_ms=0
            )
            for source in input.document_sources
        ]

        return BatchConvertOutput(
            results=results,
            summary={
                "total": len(input.document_sources),
                "successful": len(input.document_sources),
                "failed": 0,
                "total_time_ms": 0,
                "average_time_ms": 0
            }
        )

    return batch_convert

EOF

# Set ownership and permissions
chown "docling-mcp@hx.dev.local:domain users@hx.dev.local" /opt/docling-mcp/application/docling_mcp/tools/conversion.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/conversion.py
```

### 3. Update Server to Register Conversion Tools

```bash
# Modify server.py to import and register conversion tools (idempotent)
SERVER_FILE="/opt/docling-mcp/application/docling_mcp/server.py"

# Check if conversion tools are already registered
if grep -q "register_conversion_tools" "$SERVER_FILE"; then
    echo "✓ Conversion tools already registered in server.py (skipping)"
else
    echo "→ Adding conversion tool registration to server.py"
    cat >> "$SERVER_FILE" <<'EOF'

# Import conversion tool registration
from .tools.conversion import (
    register_conversion_tools,
    convert_document_impl,
    convert_document_to_markdown_impl,
    batch_convert_impl
)

# Register conversion tools
register_conversion_tools(mcp)
convert_document_impl(mcp)
convert_document_to_markdown_impl(mcp)
batch_convert_impl(mcp)

logger.info("Conversion tools registered with MCP server")
EOF
    echo "✓ Conversion tools registered successfully"
fi
```

### 4. Test Conversion Tool Registration

```bash
# Test tool import and registration
cd /opt/docling-mcp/application
python <<'PYEOF'
from docling_mcp.server import mcp

# Verify tools registered
tools = mcp.list_tools()
print(f"Total tools registered: {len(tools)}")

# Check conversion tools present
conversion_tool_names = ["convert_document", "convert_document_to_markdown", "batch_convert"]
registered_names = [tool["name"] for tool in tools]

for tool_name in conversion_tool_names:
    if tool_name in registered_names:
        print(f"✓ {tool_name} registered")
    else:
        print(f"✗ {tool_name} MISSING")
        exit(1)

print("\nAll 3 conversion tools successfully registered")
PYEOF
```

## Deliverables

- Pydantic models for conversion tools: `/opt/docling-mcp/application/docling_mcp/models/conversion.py`
- Conversion tool implementations: `/opt/docling-mcp/application/docling_mcp/tools/conversion.py`
- 3 MCP tools registered with FastMCP server:
  - `convert_document` (7 input parameters, DoclingDocument output)
  - `convert_document_to_markdown` (7 input parameters, Markdown output)
  - `batch_convert` (5 input parameters, batch results output)
- Server updated to import and register conversion tools

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Pydantic models import successfully
python -c "from docling_mcp.models.conversion import ConvertDocumentInput, ConvertToMarkdownInput, BatchConvertInput" && echo "PASS: Models import"

# 2. Tool implementations import successfully
python -c "from docling_mcp.tools.conversion import register_conversion_tools" && echo "PASS: Tools import"

# 3. All 3 tools registered (exact name matching)
python -c "
from docling_mcp.server import mcp
expected_tools = {'convert_document', 'convert_document_to_markdown', 'batch_convert'}
actual_tools = {t['name'] for t in mcp.list_tools()}
assert expected_tools.issubset(actual_tools), f'Missing tools: {expected_tools - actual_tools}'
print('PASS: All 3 conversion tools registered')
"

# 4. Tool schemas include required parameters
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'convert_document'][0]
assert 'document_source' in tool['inputSchema']['properties']
assert 'ocr_enabled' in tool['inputSchema']['properties']
print('PASS: convert_document schema correct')
"

# 5. Batch tool has concurrency parameter
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'batch_convert'][0]
assert 'max_concurrent' in tool['inputSchema']['properties']
print('PASS: batch_convert has concurrency control')
"
```

### Expected Output

All 5 verification checks should output "PASS". Tool schemas should validate against MCP protocol JSON Schema specification.

## Rollback

If conversion tool registration fails:

```bash
# 1. Remove conversion tool files
rm -f /opt/docling-mcp/application/docling_mcp/tools/conversion.py
rm -f /opt/docling-mcp/application/docling_mcp/models/conversion.py

# 2. Restore server.py to pre-registration state
# (Manual: Remove conversion tool import lines from server.py)

# 3. Document failure reason
echo "Conversion tool registration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **Placeholder Implementation**: Tool handlers return placeholder responses until docling integration complete (Task 010)
- **Pydantic Validation**: All input parameters validated automatically by FastMCP framework via Pydantic schemas
- **MCP Compliance**: Tool schemas follow MCP JSON-RPC specification (JSON Schema for inputs/outputs)
- **Batch Concurrency**: Semaphore-based concurrency control limits parallel conversions (configurable 1-10)
- **Progress Events**: SSE transport required for batch progress callbacks (implemented in Task 007)

## References

- **Specification**: Section 4.2 "MCP Tools Specification" - Tool 1, 2, 3 (convert tools)
- **Previous Contribution**: `/nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/james-mcp-tools.md` (lines 23-68)
- **Architecture**: Section 3.1 "Tool Registration Architecture" (lines 604-720)
- **Test Plan**: TC-FUNC-001 to TC-FUNC-003 (conversion tool functionality tests)
