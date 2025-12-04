# Task: Register MCP Manipulation Tools (5 Tools)

**Task ID**: hx-docling-mcp-task-036-register-manipulation-tools
**Phase**: Installation & Configuration
**Status**: Not Started
**Dependencies**:
- hx-docling-mcp-task-032 (FastMCP server initialization)
- hx-docling-mcp-task-034 (Conversion tools - provides DoclingDocument input)
- hx-docling-mcp-task-061-080 (Docling processing integration - coordinate with albert-singh)
**Estimated Time**: 2 hours
**Assigned Agent**: james-rodriguez (Docling MCP Gateway Specialist)

---

## Objective

Register 5 manipulation tools in the FastMCP server for document manipulation operations:

15. **merge_documents**: Document merging with structure reconciliation and metadata aggregation
16. **split_document**: Document splitting by page/section/size with structure preservation
17. **search_document**: Full-text search with ranking and highlighting
18. **annotate_document**: Annotation addition (highlights, comments, redactions) with persistence
19. **export_document**: Multi-format export (PDF, DOCX, HTML, Markdown) with quality preservation

These tools complete the MCP server's 19-tool offering, enabling comprehensive document lifecycle management.

---

## Pre-Execution Validation

**CRITICAL**: Check if manipulation tools already registered BEFORE creating tool handlers.

```bash
# Check if manipulation tools module exists
if [ -f /opt/docling-mcp/src/tools/manipulation.py ]; then
    # Count registered manipulation tools (should be 5)
    TOOL_COUNT=$(grep -c "^def merge_documents\|^def split_document\|^def search_document\|^def annotate_document\|^def export_document" /opt/docling-mcp/src/tools/manipulation.py || echo "0")

    if [ "$TOOL_COUNT" -ge "5" ]; then
        echo "✅ VALIDATION: Manipulation tools already registered ($TOOL_COUNT tools) - SKIP task execution"

        # Verify import in mcp_server.py
        grep -q "from tools.manipulation import" /opt/docling-mcp/src/mcp_server.py
        if [ $? -eq 0 ]; then
            echo "✅ Manipulation tools imported in mcp_server.py"
            exit 0
        fi
    fi
fi

echo "❌ VALIDATION: Manipulation tools not registered - PROCEED with task"
```

**Validation Logic**:
- If `tools/manipulation.py` exists with all 5 tool functions AND imported in `mcp_server.py` → SKIP
- Otherwise → PROCEED with tool registration

---

## Prerequisites

- [ ] FastMCP server initialized (Task 032)
- [ ] Conversion tools registered (Task 034) - provides DoclingDocument format
- [ ] Docling library installed (coordinate with albert-singh, Tasks 061-080)
- [ ] Directory `/opt/docling-mcp/src/tools/` exists

---

## Steps

### 1. Create Manipulation Tools Module

```bash
# Switch to service account
sudo -u docling-mcp bash

# Create manipulation tools module with 5 tool functions
cat > /opt/docling-mcp/src/tools/manipulation.py <<'EOF'
"""
MCP Manipulation Tools

This module implements 5 MCP tools for document manipulation:
15. merge_documents: Merge multiple documents with structure reconciliation
16. split_document: Split documents by page/section/size
17. search_document: Full-text search with ranking and highlighting
18. annotate_document: Add annotations (highlights, comments, redactions)
19. export_document: Multi-format export (PDF, DOCX, HTML, Markdown)

These tools operate on DoclingDocument format (created by conversion tools)
and enable document lifecycle management beyond initial conversion.

Integration Points:
- Docling processing backend (albert-singh, Tasks 061-080) for format conversion
- Redis caching (sri-patel, Tasks 131-140) for document storage

Specification Reference:
/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md
Section: MCP Tools Specification → PART 3: Manipulation Tools
"""

import logging
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)

# ============================================================================
# Tool 15: merge_documents
# ============================================================================

def merge_documents(
    document_sources: List[str],
    merge_strategy: str = "sequential",
    reconcile_metadata: bool = True,
    preserve_structure: bool = True
) -> Dict[str, Any]:
    """
    Merge multiple documents with structure reconciliation and metadata aggregation.

    Merge Strategies:
    - sequential: Append documents in order (default)
    - interleave: Alternate pages from each document
    - smart: LLM-guided intelligent merging based on content similarity

    Args:
        document_sources: List of document sources (file paths, DoclingDocument IDs)
        merge_strategy: Merge strategy ("sequential", "interleave", "smart")
        reconcile_metadata: Aggregate metadata from all documents
        preserve_structure: Preserve heading hierarchy and structure

    Returns:
        dict: {
            "merged_document": {
                "doc_items": [...],  # Merged DoclingDocument structure
                "metadata": {...}    # Reconciled metadata
            },
            "metadata": {
                "source_count": 3,
                "total_pages": 42,
                "merge_strategy": "sequential",
                "processing_time_ms": 2000
            }
        }

    Example:
        >>> result = merge_documents(
        ...     document_sources=["file:///tmp/doc1.pdf", "file:///tmp/doc2.pdf"],
        ...     merge_strategy="sequential"
        ... )
        >>> result["metadata"]["source_count"]
        2
    """
    logger.info(f"merge_documents invoked: {len(document_sources)} documents")

    # PLACEHOLDER: Document merging implementation
    # Will:
    # 1. Convert all documents to DoclingDocument format (via convert_document)
    # 2. Apply merge strategy (sequential, interleave, smart)
    # 3. Reconcile metadata (combine authors, merge keywords, earliest creation_date)
    # 4. Preserve heading hierarchy (adjust levels if needed)
    # 5. Return merged DoclingDocument

    return {
        "merged_document": {
            "doc_items": [],
            "metadata": {}
        },
        "metadata": {
            "source_count": len(document_sources),
            "total_pages": 0,
            "merge_strategy": merge_strategy,
            "processing_time_ms": 0,
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


# ============================================================================
# Tool 16: split_document
# ============================================================================

def split_document(
    document_source: str,
    split_mode: str = "page",
    split_value: Optional[int] = None,
    preserve_metadata: bool = True
) -> Dict[str, Any]:
    """
    Split document by page/section/size with structure preservation.

    Split Modes:
    - page: Split every N pages (split_value = pages per chunk)
    - section: Split by heading levels (split_value = heading level)
    - size: Split by file size (split_value = max size in KB)

    Args:
        document_source: Document source (file path, DoclingDocument ID)
        split_mode: Split mode ("page", "section", "size")
        split_value: Split parameter (pages per chunk, heading level, or max KB)
        preserve_metadata: Copy metadata to all split documents

    Returns:
        dict: {
            "split_documents": [
                {
                    "chunk_id": 0,
                    "doc_items": [...],
                    "metadata": {...},
                    "page_range": [1, 10]
                },
                {
                    "chunk_id": 1,
                    "doc_items": [...],
                    "metadata": {...},
                    "page_range": [11, 20]
                }
            ],
            "metadata": {
                "chunk_count": 2,
                "split_mode": "page",
                "split_value": 10,
                "processing_time_ms": 1500
            }
        }

    Example:
        >>> result = split_document(
        ...     document_source="file:///tmp/large_report.pdf",
        ...     split_mode="page",
        ...     split_value=10  # 10 pages per chunk
        ... )
        >>> result["metadata"]["chunk_count"]
        5
    """
    logger.info(f"split_document invoked: {document_source[:100]}, mode={split_mode}")

    # PLACEHOLDER: Document splitting implementation
    # Will:
    # 1. Convert document to DoclingDocument (via convert_document)
    # 2. Apply split logic based on mode:
    #    - page: Split doc_items by page boundaries
    #    - section: Split at heading levels
    #    - size: Estimate chunk size and split accordingly
    # 3. Preserve structure within each chunk
    # 4. Copy/adjust metadata for each chunk
    # 5. Return list of split DoclingDocuments

    return {
        "split_documents": [],
        "metadata": {
            "chunk_count": 0,
            "split_mode": split_mode,
            "split_value": split_value,
            "processing_time_ms": 0,
            "note": "Placeholder - Docling integration pending (Tasks 061-080)"
        }
    }


# ============================================================================
# Tool 17: search_document
# ============================================================================

def search_document(
    document_source: str,
    query: str,
    search_mode: str = "text",
    max_results: int = 10,
    highlight: bool = True
) -> Dict[str, Any]:
    """
    Full-text search with ranking and highlighting.

    Search Modes:
    - text: Literal text search (exact or fuzzy matching)
    - semantic: Vector similarity search (via Qdrant embeddings)
    - regex: Regular expression pattern matching

    Args:
        document_source: Document source (file path, DoclingDocument ID)
        query: Search query (text, semantic description, or regex pattern)
        search_mode: Search mode ("text", "semantic", "regex")
        max_results: Maximum number of results to return
        highlight: Include highlighted matches in results

    Returns:
        dict: {
            "results": [
                {
                    "match_id": 0,
                    "text": "The quick brown fox jumps over the lazy dog.",
                    "highlighted_text": "The quick <mark>brown</mark> fox...",
                    "page": 5,
                    "score": 0.95,
                    "context": "...preceding text... match ...following text..."
                }
            ],
            "metadata": {
                "query": "brown",
                "result_count": 3,
                "search_mode": "text",
                "processing_time_ms": 500
            }
        }

    Example:
        >>> result = search_document(
        ...     document_source="file:///tmp/report.pdf",
        ...     query="quarterly revenue",
        ...     search_mode="text",
        ...     max_results=5
        ... )
        >>> len(result["results"])
        3
    """
    logger.info(f"search_document invoked: query='{query}', mode={search_mode}")

    # PLACEHOLDER: Document search implementation
    # Will:
    # 1. Convert document to DoclingDocument (via convert_document)
    # 2. Extract text from all doc_items
    # 3. Apply search logic based on mode:
    #    - text: Use string matching or fuzzy search (fuzzywuzzy)
    #    - semantic: Embed query and search Qdrant for similar chunks
    #    - regex: Compile pattern and search text
    # 4. Rank results by relevance score
    # 5. Generate highlighted matches (wrap in <mark> tags)
    # 6. Return ranked results with context

    return {
        "results": [],
        "metadata": {
            "query": query,
            "result_count": 0,
            "search_mode": search_mode,
            "processing_time_ms": 0,
            "note": "Placeholder - Implementation pending"
        }
    }


# ============================================================================
# Tool 18: annotate_document
# ============================================================================

def annotate_document(
    document_source: str,
    annotations: List[Dict[str, Any]],
    persist: bool = True
) -> Dict[str, Any]:
    """
    Add annotations (highlights, comments, redactions) with persistence.

    Annotation Types:
    - highlight: Text highlighting (yellow, green, red)
    - comment: Text comments attached to regions
    - redaction: Permanent text removal (blackout)
    - note: Margin notes

    Args:
        document_source: Document source (file path, DoclingDocument ID)
        annotations: List of annotation objects:
            [
                {
                    "type": "highlight",
                    "page": 5,
                    "start_char": 100,
                    "end_char": 150,
                    "color": "yellow",
                    "note": "Important section"
                },
                {
                    "type": "comment",
                    "page": 10,
                    "position": {"x": 200, "y": 300},
                    "text": "Review this claim"
                }
            ]
        persist: Save annotated document (True) or return in-memory only (False)

    Returns:
        dict: {
            "annotated_document": {
                "doc_items": [...],  # DoclingDocument with annotations
                "annotations": [...]
            },
            "metadata": {
                "annotation_count": 5,
                "persisted": true,
                "document_id": "annotated_doc_12345"
            }
        }

    Example:
        >>> result = annotate_document(
        ...     document_source="file:///tmp/contract.pdf",
        ...     annotations=[
        ...         {
        ...             "type": "highlight",
        ...             "page": 2,
        ...             "start_char": 500,
        ...             "end_char": 600,
        ...             "color": "yellow"
        ...         }
        ...     ],
        ...     persist=True
        ... )
        >>> result["metadata"]["annotation_count"]
        1
    """
    logger.info(f"annotate_document invoked: {len(annotations)} annotations")

    # PLACEHOLDER: Document annotation implementation
    # Will:
    # 1. Convert document to DoclingDocument (via convert_document)
    # 2. Apply annotations to doc_items:
    #    - highlight: Add inline <mark> tags or metadata
    #    - comment: Attach comment metadata to doc_items
    #    - redaction: Replace text with [REDACTED]
    #    - note: Add margin note metadata
    # 3. If persist=True: Save to Redis with annotations embedded
    # 4. Return annotated DoclingDocument

    return {
        "annotated_document": {
            "doc_items": [],
            "annotations": annotations
        },
        "metadata": {
            "annotation_count": len(annotations),
            "persisted": persist,
            "document_id": "placeholder_id",
            "note": "Placeholder - Implementation pending"
        }
    }


# ============================================================================
# Tool 19: export_document
# ============================================================================

def export_document(
    document_source: str,
    export_format: str = "pdf",
    quality: str = "high",
    preserve_annotations: bool = True
) -> Dict[str, Any]:
    """
    Multi-format export (PDF, DOCX, HTML, Markdown) with quality preservation.

    Export Formats:
    - pdf: Render to PDF (requires pypdf or weasyprint)
    - docx: Export to Microsoft Word (via python-docx)
    - html: Export to HTML with CSS styling
    - markdown: Export to Markdown text

    Quality Levels:
    - high: Maximum fidelity (large file size)
    - medium: Balanced quality/size
    - low: Compressed (small file size)

    Args:
        document_source: Document source (file path, DoclingDocument ID)
        export_format: Export format ("pdf", "docx", "html", "markdown")
        quality: Quality level ("high", "medium", "low")
        preserve_annotations: Include annotations in export

    Returns:
        dict: {
            "export_result": {
                "format": "pdf",
                "file_path": "/tmp/exported_doc_12345.pdf",
                "base64_data": "JVBERi0xLjQK...",  # Optional base64 encoding
                "file_size_bytes": 524288
            },
            "metadata": {
                "export_format": "pdf",
                "quality": "high",
                "processing_time_ms": 3000
            }
        }

    Example:
        >>> result = export_document(
        ...     document_source="file:///tmp/report.pdf",
        ...     export_format="docx",
        ...     quality="high"
        ... )
        >>> result["export_result"]["format"]
        "docx"
    """
    logger.info(f"export_document invoked: format={export_format}, quality={quality}")

    # PLACEHOLDER: Document export implementation
    # Will:
    # 1. Convert document to DoclingDocument (via convert_document)
    # 2. Apply export logic based on format:
    #    - pdf: Render DoclingDocument to PDF (pypdf/weasyprint)
    #    - docx: Convert to DOCX structure (python-docx)
    #    - html: Render to HTML with CSS
    #    - markdown: Convert to Markdown text (reuse convert_document_to_markdown)
    # 3. Apply quality settings (compression, resolution)
    # 4. Include annotations if preserve_annotations=True
    # 5. Return file path or base64-encoded data

    return {
        "export_result": {
            "format": export_format,
            "file_path": "/tmp/placeholder_export.pdf",
            "base64_data": "",
            "file_size_bytes": 0
        },
        "metadata": {
            "export_format": export_format,
            "quality": quality,
            "processing_time_ms": 0,
            "note": "Placeholder - Implementation pending"
        }
    }


# ============================================================================
# Module Exports
# ============================================================================

__all__ = [
    "merge_documents",
    "split_document",
    "search_document",
    "annotate_document",
    "export_document"
]
EOF

chmod 644 /opt/docling-mcp/src/tools/manipulation.py
chown docling-mcp:docling-mcp /opt/docling-mcp/src/tools/manipulation.py
```

### 2. Add Programmatic Tool Registration Helper

First, add a helper function to mcp_server.py for idempotent tool registration:

```bash
# Add tool registration helper after health_check function
cat >> /opt/docling-mcp/src/mcp_server.py << 'EOF'

# ============================================================================
# Tool Registration Helper (Idempotent)
# ============================================================================

def register_tools_from_module(module, module_name: str):
    """
    Programmatically register all MCP tools from a module.
    
    Args:
        module: Python module containing tool functions
        module_name: Display name for logging
    
    Returns:
        int: Number of tools registered
    """
    import inspect
    
    registered_count = 0
    already_registered = [tool.name for tool in mcp.list_tools()]
    
    # Get all callables from module.__all__ or inspect members
    if hasattr(module, '__all__'):
        tool_names = module.__all__
    else:
        tool_names = [name for name, obj in inspect.getmembers(module, inspect.isfunction)]
    
    for tool_name in tool_names:
        try:
            # Skip if already registered (idempotent)
            if tool_name in already_registered:
                logger.debug(f"Tool '{tool_name}' already registered, skipping")
                continue
            
            # Get function from module
            tool_func = getattr(module, tool_name, None)
            if tool_func is None:
                logger.warning(f"Tool '{tool_name}' not found in {module_name}")
                continue
            
            # Register with MCP
            mcp.tool()(tool_func)
            registered_count += 1
            logger.debug(f"Registered tool: {tool_name}")
            
        except Exception as e:
            logger.error(f"Failed to register tool '{tool_name}' from {module_name}: {e}")
    
    if registered_count > 0:
        logger.info(f"✅ Registered {registered_count} tools from {module_name}")
    
    return registered_count

EOF
```

### 3. Register Manipulation Tools Programmatically

Now add the manipulation tools registration using the helper:

```bash
# Add manipulation tools registration after the helper function
cat >> /opt/docling-mcp/src/mcp_server.py << 'EOF'

# ============================================================================
# Manipulation Tools Registration (Task 036) - 5 tools
# ============================================================================

try:
    from tools import manipulation
    manipulation_count = register_tools_from_module(manipulation, "manipulation")
    logger.info(f"✅ Manipulation tools registered: merge, split, search, annotate, export")
except ImportError as e:
    logger.error(f"Failed to import manipulation tools: {e}")
except Exception as e:
    logger.error(f"Error registering manipulation tools: {e}")

# Log total tool count
total_tools = len(mcp.list_tools())
logger.info(f"🎯 TOTAL MCP TOOLS REGISTERED: {total_tools} (Expected: 20 = 1 health + 3 conversion + 11 generation + 5 manipulation)")

EOF
```

### 3. Verify Tool Registration (Complete 19-Tool Suite)

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test complete tool registration
cd /opt/docling-mcp/src/
python3 -c "
import mcp_server
tools = mcp_server.mcp.list_tools()

print('=' * 80)
print('DOCLING MCP SERVER - COMPLETE TOOL INVENTORY')
print('=' * 80)
print(f'Total tools registered: {len(tools)}')
print()

# Expected: 1 (health_check) + 3 (conversion) + 11 (generation) + 5 (manipulation) = 20
expected_count = 20
assert len(tools) == expected_count, f'Expected {expected_count} tools, got {len(tools)}'

# Categorize tools
categories = {
    'Health Check': ['health_check'],
    'Conversion Tools (3)': ['convert_document', 'convert_document_to_markdown', 'batch_convert'],
    'Generation Tools - Knowledge Graph (4)': [
        'generate_knowledge_graph', 'extract_entities', 'extract_relationships', 'create_docling_document'
    ],
    'Generation Tools - Document Processing (7)': [
        'parse_pdf_structure', 'extract_tables', 'extract_images', 'detect_document_language',
        'classify_document_type', 'extract_metadata', 'generate_document_summary'
    ],
    'Manipulation Tools (5)': [
        'merge_documents', 'split_document', 'search_document', 'annotate_document', 'export_document'
    ]
}

tool_names = [t.name for t in tools]

for category, expected_tools in categories.items():
    print(f'{category}:')
    for tool_name in expected_tools:
        status = '✅' if tool_name in tool_names else '❌'
        print(f'  {status} {tool_name}')
    print()

# Verify all tools present
all_expected_tools = [t for tools in categories.values() for t in tools]
for tool_name in all_expected_tools:
    assert tool_name in tool_names, f'Tool {tool_name} not found'

print('=' * 80)
print('✅ ALL 20 MCP TOOLS REGISTERED SUCCESSFULLY')
print('=' * 80)
print()
print('Server Status: Ready for integration with Docling backend (Tasks 061-080)')
print('MCP Protocol: All tools discoverable via MCP tool discovery endpoint')
print('Transports: HTTP, SSE, stdio (configured in Task 033)')
"
```

**Expected Output**:
```
================================================================================
DOCLING MCP SERVER - COMPLETE TOOL INVENTORY
================================================================================
Total tools registered: 20

Health Check:
  ✅ health_check

Conversion Tools (3):
  ✅ convert_document
  ✅ convert_document_to_markdown
  ✅ batch_convert

Generation Tools - Knowledge Graph (4):
  ✅ generate_knowledge_graph
  ✅ extract_entities
  ✅ extract_relationships
  ✅ create_docling_document

Generation Tools - Document Processing (7):
  ✅ parse_pdf_structure
  ✅ extract_tables
  ✅ extract_images
  ✅ detect_document_language
  ✅ classify_document_type
  ✅ extract_metadata
  ✅ generate_document_summary

Manipulation Tools (5):
  ✅ merge_documents
  ✅ split_document
  ✅ search_document
  ✅ annotate_document
  ✅ export_document

================================================================================
✅ ALL 20 MCP TOOLS REGISTERED SUCCESSFULLY
================================================================================

Server Status: Ready for integration with Docling backend (Tasks 061-080)
MCP Protocol: All tools discoverable via MCP tool discovery endpoint
Transports: HTTP, SSE, stdio (configured in Task 033)
```

### 4. Test Manipulation Tool Invocation (Placeholder Mode)

```bash
# Test merge_documents
python3 -c "
import mcp_server
result = mcp_server.merge_documents(['file:///tmp/doc1.pdf', 'file:///tmp/doc2.pdf'])
print('merge_documents result:')
import json
print(json.dumps(result['metadata'], indent=2))
"

# Test split_document
python3 -c "
import mcp_server
result = mcp_server.split_document('file:///tmp/large.pdf', split_mode='page', split_value=10)
print('split_document result:')
import json
print(json.dumps(result['metadata'], indent=2))
"

# Test search_document
python3 -c "
import mcp_server
result = mcp_server.search_document('file:///tmp/doc.pdf', query='quarterly revenue')
print('search_document result:')
import json
print(json.dumps(result['metadata'], indent=2))
"
```

---

## Verification

**Success Criteria**:

- [ ] File `/opt/docling-mcp/src/tools/manipulation.py` created with all 5 tool functions
- [ ] Tools imported and registered in `mcp_server.py`
- [ ] **Total tool count = 20** (1 health_check + 3 conversion + 11 generation + 5 manipulation)
- [ ] All 5 manipulation tools respond with placeholder data
- [ ] No import errors or syntax errors
- [ ] Server initialization shows "TOTAL MCP TOOLS REGISTERED: 20"

---

## Rollback

If tool registration fails:

```bash
# Remove manipulation tools module
rm /opt/docling-mcp/src/tools/manipulation.py

# Restore mcp_server.py backup
BACKUP_FILE=$(ls -t /opt/docling-mcp/src/mcp_server.py.backup.* | head -1)
cp $BACKUP_FILE /opt/docling-mcp/src/mcp_server.py
```

---

## Notes

### Completion Milestone

With this task complete, the Docling MCP Server has **all 19 MCP tools registered**:
- ✅ 3 Conversion Tools (Task 034)
- ✅ 11 Generation Tools (Task 035)
- ✅ 5 Manipulation Tools (Task 036)
- ✅ 1 Health Check Tool (Task 032)

**Total: 20 tools** (19 document processing + 1 health check)

### Next Phase: Backend Integration

The MCP tool **interfaces** are complete. Next steps:

1. **Docling Processing** (albert-singh, Tasks 061-080):
   - Implement actual document conversion logic
   - Replace placeholder responses with real DoclingDocument output

2. **Knowledge Graph Generation** (andy-taylor, Tasks 081-100):
   - Integrate LightRAG HTTP client
   - Implement entity/relationship extraction

3. **Vector Storage** (mitch-harper, Tasks 101-120):
   - Configure Qdrant collections
   - Implement knowledge graph storage

4. **LLM Integration** (shane-black, Tasks 121-130):
   - Configure LiteLLM routing
   - Implement classification and summarization

5. **Caching Layer** (sri-patel, Tasks 131-140):
   - Implement Redis caching
   - Add session management

### MCP Protocol Compliance

All 20 tools are now **MCP protocol compliant**:
- ✅ Tool discovery via `/mcp/tools` endpoint
- ✅ JSON Schema auto-generated from Python type hints
- ✅ Tool invocation via `/mcp/invoke` endpoint
- ✅ Error handling with standard MCP error codes
- ✅ Parameter validation via Pydantic/FastMCP

### Client Integration Ready

MCP clients can now discover and invoke all 20 tools:

**Claude Desktop** (stdio transport):
```json
{
  "mcpServers": {
    "docling": {
      "command": "/opt/docling-mcp/venv/bin/python3",
      "args": ["/opt/docling-mcp/src/mcp_server.py"],
      "env": {"MCP_TRANSPORT": "stdio"}
    }
  }
}
```

**LM Studio** (SSE transport):
```json
{
  "mcpServers": {
    "docling": {
      "url": "http://hx-docling-mcp-server.hx.dev.local:8052/sse",
      "transport": "sse"
    }
  }
}
```

**Custom HTTP Client**:
```bash
curl http://hx-docling-mcp-server.hx.dev.local:8052/mcp/tools
# Returns: JSON array of all 20 tools with schemas
```

---

## Related Tasks

**Prerequisites**:
- Task 032: Initialize FastMCP Server
- Task 034: Register Conversion Tools
- Task 035: Register Generation Tools

**Parallel Tasks** (backend integration):
- Tasks 061-080 (albert-singh): Docling processing backend
- Tasks 081-100 (andy-taylor): LightRAG integration
- Tasks 101-120 (mitch-harper): Qdrant integration
- Tasks 121-130 (shane-black): LiteLLM integration
- Tasks 131-140 (sri-patel): Redis integration

**Completion**: All Work Stream 3 tasks (031-036) now complete!

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Lines 6500-6800: Manipulation tools specifications (5 tools detailed)

**Task Template Version**: 1.0
**Created**: 2025-12-01
**Agent**: james-rodriguez (Docling MCP Gateway Specialist)
