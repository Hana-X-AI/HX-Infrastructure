# Task: Register MCP Conversion Tools (3 Tools)

**Task ID**: hx-docling-mcp-task-034-register-conversion-tools
**Phase**: Installation & Configuration
**Status**: Not Started
**Dependencies**:
- hx-docling-mcp-task-032 (FastMCP server initialization)
- hx-docling-mcp-task-061-080 (Docling processing integration - coordinate with albert-singh)
**Estimated Time**: 2 hours
**Assigned Agent**: james-rodriguez (Docling MCP Gateway Specialist)

---

## Objective

Register 3 conversion tools in the FastMCP server for multimodal document conversion:
1. **convert_document**: Convert documents (PDF, DOCX, PPTX, XLSX, HTML, images) to DoclingDocument JSON
2. **convert_document_to_markdown**: Convert documents to Markdown text with structure preservation
3. **batch_convert**: Parallel batch conversion of multiple documents with progress tracking

These tools expose Albert Singh's Docling processing capabilities (Tasks 061-080) through standardized MCP protocol.

---

## Pre-Execution Validation

**CRITICAL**: Check if conversion tools already registered BEFORE creating tool handlers.

```bash
# Check if conversion tools module exists
if [ -f /opt/docling-mcp/src/tools/conversion.py ]; then
    # Verify it contains all 3 tools
    grep -q "convert_document" /opt/docling-mcp/src/tools/conversion.py && \
    grep -q "convert_document_to_markdown" /opt/docling-mcp/src/tools/conversion.py && \
    grep -q "batch_convert" /opt/docling-mcp/src/tools/conversion.py

    if [ $? -eq 0 ]; then
        echo "✅ VALIDATION: Conversion tools already registered - SKIP task execution"
        # Verify import in mcp_server.py
        grep -q "from tools.conversion import" /opt/docling-mcp/src/mcp_server.py
        if [ $? -eq 0 ]; then
            echo "✅ Conversion tools imported in mcp_server.py"
            exit 0
        fi
    fi
fi

echo "❌ VALIDATION: Conversion tools not registered - PROCEED with task"
```

**Validation Logic**:
- If `tools/conversion.py` exists with all 3 tool decorators AND imported in `mcp_server.py` → SKIP
- Otherwise → PROCEED with tool registration

---

## Prerequisites

- [ ] FastMCP server initialized (Task 032)
- [ ] Docling library installed and configured (coordinate with albert-singh, Tasks 061-080)
- [ ] Redis client configured for caching (coordinate with sri-patel, Tasks 131-140)
- [ ] Directory `/opt/docling-mcp/src/tools/` exists

---

## Steps

### 1. Create Conversion Tools Module

```bash
# Switch to service account
sudo -u docling-mcp bash

# Create conversion tools module
cat > /opt/docling-mcp/src/tools/conversion.py <<'EOF'
"""
MCP Conversion Tools

This module implements 3 MCP tools for document conversion:
1. convert_document: Multimodal document → DoclingDocument JSON
2. convert_document_to_markdown: Document → Markdown text
3. batch_convert: Batch parallel document conversion

Integration:
- Docling processing backend (albert-singh, Tasks 061-080)
- Redis caching (sri-patel, Tasks 131-140)
- FastMCP tool decorators for MCP protocol compliance

Tool Schemas defined per specification:
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md
Section: MCP Tools Specification → PART 1: Conversion Tools
"""

import logging
from typing import Optional, List, Dict, Any
from pathlib import Path

# FastMCP will be imported from parent scope (mcp_server.py)
# Tool decorators will use: @mcp.tool()

logger = logging.getLogger(__name__)

# ============================================================================
# Tool 1: convert_document
# ============================================================================

def convert_document(
    document_source: str,
    format_hint: str = "auto",
    preserve_images: bool = True,
    ocr_enabled: bool = True,
    ocr_language: str = "eng",
    table_detection: bool = True,
    cache_result: bool = True
) -> Dict[str, Any]:
    """
    Convert a multimodal document to structured DoclingDocument JSON format.

    Supports 14+ document formats with semantic structure preservation:
    - PDF (digital and scanned with OCR)
    - Microsoft Office (DOCX, PPTX, XLSX)
    - Web formats (HTML, Markdown)
    - Images (PNG, JPEG, TIFF with OCR)

    Args:
        document_source: Document source (file://, http://, https://, or data: URI)
        format_hint: Format hint ("pdf", "docx", "pptx", "xlsx", "html", "markdown", "image", "auto")
        preserve_images: Extract and preserve images as base64 in DoclingDocument
        ocr_enabled: Enable OCR for scanned PDFs and images (Tesseract)
        ocr_language: OCR language code (eng, spa, fra, deu, chi_sim, jpn, kor)
        table_detection: Enable table structure detection and cell-level extraction
        cache_result: Cache DoclingDocument result in Redis (24h TTL)

    Returns:
        dict: {
            "docling_document": {
                "doc_items": [...],  # Hierarchical document structure
                "metadata": {...}
            },
            "metadata": {
                "format": "pdf",
                "page_count": 10,
                "backend_used": "pypdfium2",
                "processing_time_ms": 5432,
                "cache_hit": false
            }
        }

    Raises:
        FileNotFoundError: Document source not found
        ValueError: Unsupported document format
        RuntimeError: Document processing failure (OCR, table detection, etc.)

    Example:
        >>> result = convert_document(
        ...     document_source="file:///tmp/report.pdf",
        ...     preserve_images=True,
        ...     ocr_enabled=True
        ... )
        >>> result["docling_document"]["doc_items"][0]
        {"type": "heading", "level": 1, "text": "Executive Summary"}

    Integration:
        - Delegates to Docling processing backend (Tasks 061-080)
        - Uses Redis for caching (Tasks 131-140)
        - Returns DoclingDocument compliant with Docling schema
    """
    logger.info(f"convert_document invoked: {document_source[:100]}")

    # PLACEHOLDER: Integration with Docling backend (albert-singh, Tasks 061-080)
    # Will be implemented as:
    # from utils.docling_processor import DoclingProcessor
    # processor = DoclingProcessor()
    # docling_doc = processor.convert(
    #     source=document_source,
    #     format_hint=format_hint,
    #     ocr_enabled=ocr_enabled,
    #     ocr_language=ocr_language,
    #     table_detection=table_detection,
    #     preserve_images=preserve_images
    # )

    # PLACEHOLDER: Redis caching (sri-patel, Tasks 131-140)
    # cache_key = f"docling:v1:{hash(document_source + str(params))}"
    # if cache_result and redis_client.exists(cache_key):
    #     return redis_client.get(cache_key)

    # Placeholder response
    return {
        "docling_document": {
            "doc_items": [],
            "metadata": {
                "title": "Placeholder",
                "author": "",
                "creation_date": ""
            }
        },
        "metadata": {
            "format": format_hint if format_hint != "auto" else "pdf",
            "page_count": 0,
            "backend_used": "placeholder",
            "processing_time_ms": 0,
            "cache_hit": False,
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


# ============================================================================
# Tool 2: convert_document_to_markdown
# ============================================================================

def convert_document_to_markdown(
    document_source: str,
    format_hint: str = "auto",
    preserve_images: bool = False,
    ocr_enabled: bool = True,
    ocr_language: str = "eng",
    table_format: str = "markdown",
    max_line_length: int = 120
) -> Dict[str, Any]:
    """
    Convert document to Markdown text format with semantic structure preservation.

    Optimized for LLM consumption and downstream processing. Converts hierarchical
    DoclingDocument structure to Markdown syntax (headings, lists, tables, code blocks).

    Args:
        document_source: Document source (file://, http://, https://, or data: URI)
        format_hint: Format hint ("pdf", "docx", etc., or "auto")
        preserve_images: Include images as base64 data URIs (increases output size)
        ocr_enabled: Enable OCR for scanned PDFs and images
        ocr_language: OCR language code
        table_format: Table rendering ("markdown", "html", "plain")
        max_line_length: Max line length for text wrapping (0=no wrapping, 80-200)

    Returns:
        dict: {
            "markdown_text": "# Heading 1\\n\\nParagraph text...\\n\\n## Heading 2...",
            "metadata": {
                "format": "pdf",
                "character_count": 12345,
                "word_count": 2000,
                "processing_time_ms": 3200
            }
        }

    Example:
        >>> result = convert_document_to_markdown(
        ...     document_source="file:///tmp/article.pdf",
        ...     table_format="markdown",
        ...     max_line_length=100
        ... )
        >>> print(result["markdown_text"][:100])
        # Article Title

        This is the introduction paragraph with automatic line wrapping...

    Integration:
        - Calls convert_document internally to get DoclingDocument
        - Converts DoclingDocument → Markdown using rendering rules
        - Faster than full DoclingDocument JSON (optimized for LLM context)
    """
    logger.info(f"convert_document_to_markdown invoked: {document_source[:100]}")

    # PLACEHOLDER: Will delegate to convert_document, then render as Markdown
    # docling_doc = convert_document(
    #     document_source=document_source,
    #     format_hint=format_hint,
    #     preserve_images=preserve_images,
    #     ocr_enabled=ocr_enabled,
    #     ocr_language=ocr_language
    # )
    # markdown_text = render_markdown(docling_doc, table_format, max_line_length)

    return {
        "markdown_text": "# Placeholder Document\n\nMarkdown rendering pending Docling integration (Tasks 061-080)",
        "metadata": {
            "format": format_hint if format_hint != "auto" else "pdf",
            "character_count": 0,
            "word_count": 0,
            "processing_time_ms": 0
        }
    }


# ============================================================================
# Tool 3: batch_convert
# ============================================================================

def batch_convert(
    document_sources: List[str],
    format_hint: str = "auto",
    preserve_images: bool = True,
    ocr_enabled: bool = True,
    ocr_language: str = "eng",
    table_detection: bool = True,
    cache_result: bool = True,
    max_concurrent: int = 4,
    fail_fast: bool = False,
    progress_callback: bool = True
) -> Dict[str, Any]:
    """
    Convert multiple documents in parallel with progress tracking and error handling.

    Supports both fail-fast (stop on first error) and fail-tolerant (continue on errors)
    modes. Uses asyncio semaphore for concurrency control (default: 4 concurrent conversions).

    Args:
        document_sources: List of document sources (file://, http://, data: URIs)
        format_hint: Format hint for all documents (or "auto" for per-document detection)
        preserve_images: Extract and preserve images in all documents
        ocr_enabled: Enable OCR for scanned PDFs/images
        ocr_language: OCR language code
        table_detection: Enable table structure detection
        cache_result: Cache results in Redis (24h TTL)
        max_concurrent: Max concurrent conversions (1-10, default: 4)
        fail_fast: Stop on first error (True) or continue (False)
        progress_callback: Emit SSE progress events during batch processing

    Returns:
        dict: {
            "results": [
                {
                    "document_source": "file:///doc1.pdf",
                    "status": "success",
                    "docling_document": {...},
                    "processing_time_ms": 5432
                },
                {
                    "document_source": "file:///doc2.pdf",
                    "status": "error",
                    "error": "File not found: /doc2.pdf",
                    "processing_time_ms": 0
                }
            ],
            "summary": {
                "total_count": 10,
                "success_count": 9,
                "error_count": 1,
                "total_processing_time_ms": 54320,
                "average_time_per_document_ms": 5432,
                "cache_hit_count": 3
            }
        }

    Example:
        >>> result = batch_convert(
        ...     document_sources=[
        ...         "file:///tmp/doc1.pdf",
        ...         "file:///tmp/doc2.docx",
        ...         "https://example.com/doc3.pdf"
        ...     ],
        ...     max_concurrent=2,
        ...     fail_fast=False
        ... )
        >>> result["summary"]
        {"total_count": 3, "success_count": 3, "error_count": 0, ...}

    Integration:
        - Uses asyncio.Semaphore for concurrency control
        - Delegates to convert_document for each document
        - Emits SSE progress events if progress_callback=True
    """
    logger.info(f"batch_convert invoked: {len(document_sources)} documents")

    # PLACEHOLDER: Parallel batch processing implementation
    # Will use asyncio for concurrent conversions:
    # async def batch_convert_async():
    #     semaphore = asyncio.Semaphore(max_concurrent)
    #     tasks = [convert_with_semaphore(src, semaphore) for src in document_sources]
    #     results = await asyncio.gather(*tasks, return_exceptions=not fail_fast)
    #     return compile_results(results)

    # Placeholder: Single-threaded simulation
    results = []
    for source in document_sources:
        results.append({
            "document_source": source,
            "status": "success",
            "docling_document": {"placeholder": True},
            "processing_time_ms": 0
        })

    return {
        "results": results,
        "summary": {
            "total_count": len(document_sources),
            "success_count": len(document_sources),
            "error_count": 0,
            "total_processing_time_ms": 0,
            "average_time_per_document_ms": 0,
            "cache_hit_count": 0,
            "note": "Placeholder - Batch processing pending implementation"
        }
    }


# ============================================================================
# Module Exports
# ============================================================================

__all__ = [
    "convert_document",
    "convert_document_to_markdown",
    "batch_convert"
]
EOF

chmod 644 /opt/docling-mcp/src/tools/conversion.py
chown docling-mcp:docling-mcp /opt/docling-mcp/src/tools/conversion.py
```

### 2. Register Tools in MCP Server

Update `/opt/docling-mcp/src/mcp_server.py` to import and register conversion tools:

```bash
# Add import statement after FastMCP initialization (before health_check definition)
sed -i '/^logger.info("✅ FastMCP server instance initialized/a\
\
# ============================================================================\
# Conversion Tools Registration (Task 034)\
# ============================================================================\
\
from tools.conversion import (\
    convert_document,\
    convert_document_to_markdown,\
    batch_convert\
)\
\
# Register conversion tools with FastMCP using @mcp.tool() decorator\
mcp.tool()(convert_document)\
mcp.tool()(convert_document_to_markdown)\
mcp.tool()(batch_convert)\
\
logger.info("✅ Registered 3 conversion tools: convert_document, convert_document_to_markdown, batch_convert")\
' /opt/docling-mcp/src/mcp_server.py
```

### 3. Verify Tool Registration

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test tool registration
cd /opt/docling-mcp/src/
python3 -c "
import mcp_server
tools = mcp_server.mcp.list_tools()
print(f'✅ Total tools registered: {len(tools)}')
print('✅ Tool names:')
for tool in tools:
    print(f'   - {tool.name}')

# Verify conversion tools present
tool_names = [t.name for t in tools]
assert 'convert_document' in tool_names, 'convert_document not found'
assert 'convert_document_to_markdown' in tool_names, 'convert_document_to_markdown not found'
assert 'batch_convert' in tool_names, 'batch_convert not found'
print('✅ All conversion tools registered successfully')
"
```

**Expected Output**:
```
✅ Total tools registered: 4
✅ Tool names:
   - health_check
   - convert_document
   - convert_document_to_markdown
   - batch_convert
✅ All conversion tools registered successfully
```

### 4. Test Tool Invocation (Placeholder Mode)

```bash
# Test convert_document invocation
python3 -c "
import mcp_server
result = mcp_server.convert_document('file:///tmp/test.pdf')
print('convert_document result:')
import json
print(json.dumps(result, indent=2))
"

# Test convert_document_to_markdown invocation
python3 -c "
import mcp_server
result = mcp_server.convert_document_to_markdown('file:///tmp/test.pdf')
print('convert_document_to_markdown result:')
import json
print(json.dumps(result, indent=2))
"

# Test batch_convert invocation
python3 -c "
import mcp_server
result = mcp_server.batch_convert(['file:///tmp/doc1.pdf', 'file:///tmp/doc2.pdf'])
print('batch_convert result:')
import json
print(json.dumps(result['summary'], indent=2))
"
```

---

## Verification

**Success Criteria**:

- [ ] File `/opt/docling-mcp/src/tools/conversion.py` created with all 3 tool functions
  ```bash
  ls -la /opt/docling-mcp/src/tools/conversion.py
  ```

- [ ] Tools imported and registered in `mcp_server.py`:
  ```bash
  grep -q "from tools.conversion import" /opt/docling-mcp/src/mcp_server.py
  ```

- [ ] All 3 conversion tools registered in FastMCP:
  ```bash
  python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp/src'); import mcp_server; assert len([t for t in mcp_server.mcp.list_tools() if t.name in ['convert_document', 'convert_document_to_markdown', 'batch_convert']]) == 3"
  ```

- [ ] Tool invocation succeeds (returns placeholder responses):
  ```bash
  python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp/src'); import mcp_server; result = mcp_server.convert_document('file:///tmp/test.pdf'); assert 'docling_document' in result"
  ```

- [ ] No import errors or syntax errors:
  ```bash
  python3 -m py_compile /opt/docling-mcp/src/tools/conversion.py
  python3 -m py_compile /opt/docling-mcp/src/mcp_server.py
  ```

---

## Rollback

If tool registration fails:

```bash
# Remove conversion tools module
rm /opt/docling-mcp/src/tools/conversion.py

# Restore mcp_server.py backup (from Task 033)
BACKUP_FILE=$(ls -t /opt/docling-mcp/src/mcp_server.py.backup.* | head -1)
cp $BACKUP_FILE /opt/docling-mcp/src/mcp_server.py
```

---

## Notes

### Placeholder Implementation Strategy

These tools return **placeholder responses** until integration tasks complete:

- **Tasks 061-080** (albert-singh): Implement actual Docling document processing
- **Tasks 131-140** (sri-patel): Implement Redis caching layer
- **This task (034)**: Register MCP tool interfaces with placeholder logic

**Why Placeholders?**
- Enables parallel development (MCP tools can be tested while Docling integration progresses)
- Allows MCP client testing (tool discovery, schema validation, invocation flow)
- Simplifies incremental integration (replace placeholders with actual implementations)

### Tool Parameter Validation

FastMCP automatically validates tool parameters using Python type hints:
- `document_source: str` → Required string parameter
- `preserve_images: bool = True` → Optional boolean with default
- `max_concurrent: int = 4` → Optional integer with default

Invalid invocations return MCP error code `-32602` (Invalid params).

### Integration Dependencies

**Conversion tools depend on**:
1. **Docling Processing** (albert-singh, Tasks 061-080):
   - Format detection (PDF, DOCX, PPTX, etc.)
   - Backend selection (pypdfium2, mammoth, python-pptx, etc.)
   - OCR integration (Tesseract)
   - Table detection
   - Structure preservation (headings, lists, tables, images)

2. **Redis Caching** (sri-patel, Tasks 131-140):
   - Cache key generation (MD5 hash of source + parameters)
   - Cache hit/miss logic
   - TTL management (24 hours)
   - Cache invalidation

### Performance Considerations

**convert_document**:
- Small PDFs (1-5 pages): <5s
- Medium PDFs (10-50 pages): <30s
- Large PDFs (100+ pages): <120s with parallel processing

**convert_document_to_markdown**:
- Faster than full DoclingDocument JSON (Markdown rendering is lightweight)
- Post-conversion overhead: ~1-2s

**batch_convert**:
- Linear scaling with `max_concurrent` setting
- 10 documents with `max_concurrent=4`: ~2.5x faster than sequential
- Redis caching improves subsequent batch runs (cache hit rate >40%)

### Future Enhancements (Phase 2)

- **Authentication**: OAuth2 token validation before tool invocation
- **Rate Limiting**: Enforce request limits per client (100 req/min)
- **Quota Management**: Track usage per API key
- **Webhook Support**: Progress callbacks via webhooks (alternative to SSE)

---

## Related Tasks

**Prerequisites**:
- Task 032: Initialize FastMCP Server

**Parallel Tasks** (coordination required):
- Tasks 061-080 (albert-singh): Docling processing backend (provides actual conversion logic)
- Tasks 131-140 (sri-patel): Redis integration (provides caching layer)

**Next Tasks**:
- Task 035: Register generation tools - knowledge graph
- Task 036: Register generation tools - document processing
- Task 037: Register manipulation tools

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: MCP Tools Specification → PART 1: Conversion Tools (detailed schemas)
- Lines 5255-5628: Tool specifications for convert_document, convert_document_to_markdown, batch_convert

**Task Template Version**: 1.0
**Created**: 2025-12-01
**Agent**: james-rodriguez (Docling MCP Gateway Specialist)
