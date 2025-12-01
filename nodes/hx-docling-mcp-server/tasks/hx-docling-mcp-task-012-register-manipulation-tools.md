# Task: Register MCP Manipulation Tools (5 tools)

**Task ID**: hx-docling-mcp-task-012
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-001 (FastMCP Framework Installation)
**Parallel Execution**: Yes [P] (can run parallel with tasks 009, 010, 011, 013)

## Objective

Implement and register 5 document manipulation MCP tools (Tools 15-19) with complete Pydantic schemas, DoclingDocument operations, and export capabilities.

## Prerequisites

- FastMCP framework installed and server skeleton created (Task 005 complete)
- Docling library installed in virtual environment
- Application directory structure at `/opt/docling-mcp/application/docling_mcp/` exists

## Steps

### 1. Create Pydantic Models for Manipulation Tools

```bash
# Create manipulation tool models file
cat > /opt/docling-mcp/application/docling_mcp/models/manipulation.py <<'EOF'
"""
Pydantic models for MCP Document Manipulation Tools.

Defines input/output schemas for:
- merge_documents (Tool 15)
- split_document (Tool 16)
- search_document (Tool 17)
- annotate_document (Tool 18)
- export_document (Tool 19)
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any
from enum import Enum

# ============================================================================
# Tool 15: merge_documents
# ============================================================================

class MergeStrategy(str, Enum):
    """Document merge strategies."""
    CONCATENATE = "concatenate"  # Simple concatenation (preserve all content)
    RECONCILE = "reconcile"  # Smart merge with heading reconciliation
    INTERLEAVE = "interleave"  # Alternate sections from each document

class MergeDocumentsInput(BaseModel):
    """Input schema for merge_documents tool."""
    document_sources: List[str] = Field(
        ...,
        min_length=2,
        max_length=50,
        description="List of document sources to merge (file paths, URLs, or DoclingDocument IDs)"
    )
    merge_strategy: MergeStrategy = Field(
        MergeStrategy.CONCATENATE,
        description="Merge strategy (concatenate, reconcile, interleave)"
    )
    preserve_metadata: bool = Field(
        True,
        description="Preserve metadata from all source documents"
    )
    output_title: Optional[str] = Field(
        None,
        max_length=500,
        description="Title for merged document (auto-generated if omitted)"
    )

class MergeDocumentsOutput(BaseModel):
    """Output schema for merged document."""
    merged_document_id: str = Field(..., description="Unique ID for merged document")
    doc_items: List[Dict[str, Any]] = Field(..., description="Merged document structure")
    metadata: Dict[str, Any] = Field(
        ...,
        description="Merged metadata (source_documents, merge_strategy, total_pages)"
    )
    source_count: int = Field(..., ge=2, description="Number of source documents merged")

# ============================================================================
# Tool 16: split_document
# ============================================================================

class SplitMode(str, Enum):
    """Document split modes."""
    BY_PAGE = "by_page"  # Split by page number
    BY_SECTION = "by_section"  # Split by top-level sections
    BY_HEADING = "by_heading"  # Split by specific heading level
    BY_SIZE = "by_size"  # Split by approximate size (words/characters)

class SplitDocumentInput(BaseModel):
    """Input schema for split_document tool."""
    document_source: str = Field(
        ...,
        description="Document source to split (file path, URL, or DoclingDocument ID)"
    )
    split_mode: SplitMode = Field(
        ...,
        description="Split mode (by_page, by_section, by_heading, by_size)"
    )
    split_parameter: Optional[int] = Field(
        None,
        description="Split parameter: page_number, heading_level (1-6), or max_words per chunk"
    )
    preserve_context: bool = Field(
        False,
        description="Include surrounding context (previous heading) in each chunk"
    )

class DocumentChunk(BaseModel):
    """Single document chunk from split operation."""
    chunk_id: str = Field(..., description="Unique chunk identifier")
    chunk_index: int = Field(..., ge=0, description="Chunk index in split sequence")
    title: Optional[str] = Field(None, description="Chunk title (heading or generated)")
    doc_items: List[Dict[str, Any]] = Field(..., description="Chunk content structure")
    start_page: Optional[int] = Field(None, description="Start page in original document")
    end_page: Optional[int] = Field(None, description="End page in original document")
    word_count: int = Field(..., ge=0, description="Chunk word count")

class SplitDocumentOutput(BaseModel):
    """Output schema for document split."""
    chunks: List[DocumentChunk] = Field(..., description="Split document chunks")
    total_chunks: int = Field(..., ge=1, description="Total number of chunks")
    original_document_id: str = Field(..., description="Source document ID")

# ============================================================================
# Tool 17: search_document
# ============================================================================

class SearchMode(str, Enum):
    """Search algorithm modes."""
    EXACT = "exact"  # Exact substring match
    FUZZY = "fuzzy"  # Fuzzy matching (Levenshtein distance)
    BM25 = "bm25"  # BM25 ranking algorithm
    SEMANTIC = "semantic"  # Semantic similarity (embeddings)

class SearchDocumentInput(BaseModel):
    """Input schema for search_document tool."""
    document_source: str = Field(
        ...,
        description="Document source to search (file path, URL, or DoclingDocument ID)"
    )
    query: str = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="Search query string"
    )
    search_mode: SearchMode = Field(
        SearchMode.BM25,
        description="Search algorithm (exact, fuzzy, bm25, semantic)"
    )
    max_results: int = Field(
        20,
        ge=1,
        le=100,
        description="Maximum number of search results to return"
    )
    highlight: bool = Field(
        True,
        description="Highlight query terms in result snippets"
    )
    context_window: int = Field(
        100,
        ge=0,
        le=500,
        description="Number of characters before/after match for snippet context"
    )

class SearchResult(BaseModel):
    """Single search result."""
    result_id: str = Field(..., description="Unique result identifier")
    score: float = Field(..., ge=0.0, description="Relevance score (algorithm-specific)")
    snippet: str = Field(..., description="Text snippet with match context")
    page: Optional[int] = Field(None, description="Page number (PDF/DOCX)")
    section: Optional[str] = Field(None, description="Section heading")
    char_offset: int = Field(..., ge=0, description="Character offset in document")

class SearchDocumentOutput(BaseModel):
    """Output schema for document search."""
    results: List[SearchResult] = Field(..., description="Search results (sorted by score)")
    total_results: int = Field(..., ge=0, description="Total matching results found")
    query: str = Field(..., description="Original search query")
    search_mode: SearchMode = Field(..., description="Search algorithm used")

# ============================================================================
# Tool 18: annotate_document
# ============================================================================

class AnnotationType(str, Enum):
    """Annotation types."""
    HIGHLIGHT = "highlight"  # Highlight text
    COMMENT = "comment"  # Add comment
    REDACT = "redact"  # Redact sensitive content
    BOOKMARK = "bookmark"  # Add bookmark/anchor

class AnnotationInput(BaseModel):
    """Single annotation specification."""
    annotation_type: AnnotationType = Field(..., description="Annotation type")
    target_text: Optional[str] = Field(
        None,
        description="Text to annotate (exact match or pattern)"
    )
    target_page: Optional[int] = Field(
        None,
        ge=1,
        description="Page number to annotate (PDF/DOCX only)"
    )
    annotation_text: Optional[str] = Field(
        None,
        description="Comment text or redaction replacement text"
    )
    color: Optional[str] = Field(
        "yellow",
        pattern="^(yellow|green|blue|red|orange)$",
        description="Highlight color (for highlight annotations)"
    )

class AnnotateDocumentInput(BaseModel):
    """Input schema for annotate_document tool."""
    document_source: str = Field(
        ...,
        description="Document source to annotate (file path, URL, or DoclingDocument ID)"
    )
    annotations: List[AnnotationInput] = Field(
        ...,
        min_length=1,
        max_length=100,
        description="List of annotations to apply"
    )
    create_new_document: bool = Field(
        True,
        description="Create new annotated document (True) or modify in-place (False)"
    )

class AnnotateDocumentOutput(BaseModel):
    """Output schema for annotated document."""
    annotated_document_id: str = Field(..., description="Unique ID for annotated document")
    annotations_applied: int = Field(..., ge=0, description="Number of annotations successfully applied")
    annotations_failed: int = Field(default=0, ge=0, description="Number of annotations that failed")
    doc_items: List[Dict[str, Any]] = Field(..., description="Annotated document structure")

# ============================================================================
# Tool 19: export_document
# ============================================================================

class ExportFormat(str, Enum):
    """Export output formats."""
    PDF = "pdf"
    DOCX = "docx"
    HTML = "html"
    MARKDOWN = "markdown"
    JSON = "json"
    PLAIN_TEXT = "txt"

class ExportDocumentInput(BaseModel):
    """Input schema for export_document tool."""
    document_source: str = Field(
        ...,
        description="Document source to export (file path, URL, or DoclingDocument ID)"
    )
    export_format: ExportFormat = Field(
        ...,
        description="Output format (pdf, docx, html, markdown, json, txt)"
    )
    output_path: Optional[str] = Field(
        None,
        description="Output file path (auto-generated if omitted, in /var/lib/docling-mcp/exports/)"
    )
    include_images: bool = Field(
        True,
        description="Include images in export (applicable for PDF, DOCX, HTML)"
    )
    include_tables: bool = Field(
        True,
        description="Include tables in export"
    )
    preserve_formatting: bool = Field(
        True,
        description="Preserve document formatting (fonts, colors, styles)"
    )

class ExportDocumentOutput(BaseModel):
    """Output schema for document export."""
    export_file_path: str = Field(..., description="Absolute path to exported file")
    export_format: ExportFormat = Field(..., description="Export format used")
    file_size_bytes: int = Field(..., ge=0, description="Exported file size in bytes")
    page_count: Optional[int] = Field(None, description="Page count (PDF/DOCX only)")
    export_timestamp: str = Field(..., description="Export timestamp (ISO8601)")

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/models/manipulation.py
chmod 644 /opt/docling-mcp/application/docling_mcp/models/manipulation.py
```

### 2. Implement Manipulation Tool Handlers

```bash
# Create manipulation tools implementation
cat > /opt/docling-mcp/application/docling_mcp/tools/manipulation.py <<'EOF'
"""
MCP Document Manipulation Tools Implementation.

Implements 5 MCP tools:
15. merge_documents: Combine multiple DoclingDocuments
16. split_document: Split by page/section/heading/size
17. search_document: Full-text search with BM25 ranking
18. annotate_document: Add annotations (highlights, comments, redactions)
19. export_document: Export to PDF, DOCX, HTML, Markdown
"""

import logging
import hashlib
from datetime import datetime
from typing import List

from fastmcp import FastMCP
from ..models.manipulation import (
    MergeDocumentsInput,
    MergeDocumentsOutput,
    SplitDocumentInput,
    SplitDocumentOutput,
    DocumentChunk,
    SearchDocumentInput,
    SearchDocumentOutput,
    SearchResult,
    AnnotateDocumentInput,
    AnnotateDocumentOutput,
    ExportDocumentInput,
    ExportDocumentOutput,
)

logger = logging.getLogger(__name__)

# ============================================================================
# Tool Registration Functions
# ============================================================================

def register_manipulation_tools(mcp: FastMCP):
    """
    Register all 5 manipulation tools with FastMCP server.

    Args:
        mcp: FastMCP server instance
    """
    logger.info("Registering manipulation tools...")

    # Tools registered via decorators below
    # This function serves as entry point for tool module

    logger.info("Manipulation tools registered: 5 tools (merge_documents through export_document)")

# ============================================================================
# Tool 15: merge_documents
# ============================================================================

def merge_documents_impl(mcp: FastMCP):
    """Decorator-based tool registration for merge_documents."""

    @mcp.tool(
        name="merge_documents",
        description="Merge multiple DoclingDocuments with configurable merge strategy and metadata preservation."
    )
    async def merge_documents(input: MergeDocumentsInput) -> MergeDocumentsOutput:
        """
        Merge multiple documents into single DoclingDocument.

        Workflow:
        1. Load all source documents (from cache or convert)
        2. Apply merge strategy (concatenate, reconcile, interleave)
        3. Merge metadata from all sources
        4. Generate merged document ID
        5. Assemble merged DoclingDocument

        Args:
            input: MergeDocumentsInput with document sources and merge options

        Returns:
            MergeDocumentsOutput: Merged document with combined content
        """
        logger.info(f"merge_documents called: {len(input.document_sources)} documents")

        # TODO: Implement document merging with strategy support
        # Placeholder response
        merged_id = hashlib.sha256(
            "|".join(input.document_sources).encode()
        ).hexdigest()[:16]

        return MergeDocumentsOutput(
            merged_document_id=merged_id,
            doc_items=[{"type": "paragraph", "text": "Placeholder: Implementation pending"}],
            metadata={"merge_strategy": input.merge_strategy.value},
            source_count=len(input.document_sources)
        )

    return merge_documents

# ============================================================================
# Tool 16: split_document
# ============================================================================

def split_document_impl(mcp: FastMCP):
    """Decorator-based tool registration for split_document."""

    @mcp.tool(
        name="split_document",
        description="Split document into chunks by page, section, heading level, or size with optional context preservation."
    )
    async def split_document(input: SplitDocumentInput) -> SplitDocumentOutput:
        """
        Split document into chunks.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Apply split mode logic (by_page, by_section, by_heading, by_size)
        3. Extract chunks with boundaries
        4. Preserve context if enabled (include parent heading)
        5. Generate chunk IDs and metadata

        Args:
            input: SplitDocumentInput with document source and split options

        Returns:
            SplitDocumentOutput: Document chunks with metadata
        """
        logger.info(f"split_document called: source={input.document_source[:50]}...")

        # TODO: Implement document splitting with all modes
        # Placeholder response
        doc_id = hashlib.sha256(input.document_source.encode()).hexdigest()[:16]

        return SplitDocumentOutput(
            chunks=[],
            total_chunks=0,
            original_document_id=doc_id
        )

    return split_document

# ============================================================================
# Tool 17: search_document
# ============================================================================

def search_document_impl(mcp: FastMCP):
    """Decorator-based tool registration for search_document."""

    @mcp.tool(
        name="search_document",
        description="Full-text search with multiple algorithms (exact, fuzzy, BM25, semantic) and result highlighting."
    )
    async def search_document(input: SearchDocumentInput) -> SearchDocumentOutput:
        """
        Search document with configurable algorithm.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Apply search algorithm:
           - exact: Substring matching
           - fuzzy: Levenshtein distance matching
           - bm25: BM25 ranking (default)
           - semantic: Embedding similarity search
        3. Rank results by score
        4. Generate snippets with context window
        5. Highlight query terms if enabled

        Args:
            input: SearchDocumentInput with query and search options

        Returns:
            SearchDocumentOutput: Ranked search results with snippets
        """
        logger.info(f"search_document called: query={input.query}")

        # TODO: Implement full-text search with BM25 and semantic modes
        # Placeholder response

        return SearchDocumentOutput(
            results=[],
            total_results=0,
            query=input.query,
            search_mode=input.search_mode
        )

    return search_document

# ============================================================================
# Tool 18: annotate_document
# ============================================================================

def annotate_document_impl(mcp: FastMCP):
    """Decorator-based tool registration for annotate_document."""

    @mcp.tool(
        name="annotate_document",
        description="Add annotations to document (highlights, comments, redactions, bookmarks) with batch support."
    )
    async def annotate_document(input: AnnotateDocumentInput) -> AnnotateDocumentOutput:
        """
        Add annotations to document.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Process annotations:
           - highlight: Mark text with color
           - comment: Add comment at target text
           - redact: Replace sensitive text with placeholder
           - bookmark: Add section bookmark
        3. Create new document or modify in-place
        4. Track applied and failed annotations
        5. Return annotated DoclingDocument

        Args:
            input: AnnotateDocumentInput with document source and annotations

        Returns:
            AnnotateDocumentOutput: Annotated document with application summary
        """
        logger.info(f"annotate_document called: {len(input.annotations)} annotations")

        # TODO: Implement annotation support for all types
        # Placeholder response
        annotated_id = hashlib.sha256(
            (input.document_source + str(len(input.annotations))).encode()
        ).hexdigest()[:16]

        return AnnotateDocumentOutput(
            annotated_document_id=annotated_id,
            annotations_applied=0,
            annotations_failed=0,
            doc_items=[{"type": "paragraph", "text": "Placeholder: Implementation pending"}]
        )

    return annotate_document

# ============================================================================
# Tool 19: export_document
# ============================================================================

def export_document_impl(mcp: FastMCP):
    """Decorator-based tool registration for export_document."""

    @mcp.tool(
        name="export_document",
        description="Export DoclingDocument to multiple formats (PDF, DOCX, HTML, Markdown, JSON, TXT) with formatting preservation."
    )
    async def export_document(input: ExportDocumentInput) -> ExportDocumentOutput:
        """
        Export document to target format.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Apply export backend per format:
           - pdf: ReportLab PDF generation
           - docx: python-docx library
           - html: HTML5 with CSS styling
           - markdown: GitHub Flavored Markdown
           - json: DoclingDocument JSON serialization
           - txt: Plain text extraction
        3. Preserve formatting if enabled
        4. Include images/tables if enabled
        5. Write to output_path or auto-generate path
        6. Return export metadata

        Args:
            input: ExportDocumentInput with document source and export options

        Returns:
            ExportDocumentOutput: Export file path and metadata
        """
        logger.info(f"export_document called: format={input.export_format.value}")

        # TODO: Implement export backends for all formats
        # Placeholder response
        output_path = input.output_path or f"/var/lib/docling-mcp/exports/export_{datetime.now().isoformat()}.{input.export_format.value}"

        return ExportDocumentOutput(
            export_file_path=output_path,
            export_format=input.export_format,
            file_size_bytes=0,
            page_count=None,
            export_timestamp=datetime.now().isoformat()
        )

    return export_document

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/tools/manipulation.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/manipulation.py
```

### 3. Update Server to Register Manipulation Tools

```bash
# Append to server.py
cat >> /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'

# Import manipulation tool registration
from .tools.manipulation import (
    register_manipulation_tools,
    merge_documents_impl,
    split_document_impl,
    search_document_impl,
    annotate_document_impl,
    export_document_impl,
)

# Register manipulation tools
register_manipulation_tools(mcp)
merge_documents_impl(mcp)
split_document_impl(mcp)
search_document_impl(mcp)
annotate_document_impl(mcp)
export_document_impl(mcp)

logger.info("Manipulation tools registered with MCP server")
EOF
```

### 4. Test Manipulation Tool Registration

```bash
# Test tool import and registration
cd /opt/docling-mcp/application
python <<'PYEOF'
from docling_mcp.server import mcp

# Verify tools registered
tools = mcp.list_tools()
print(f"Total tools registered: {len(tools)}")

# Check manipulation tools present
manipulation_tool_names = [
    "merge_documents",
    "split_document",
    "search_document",
    "annotate_document",
    "export_document"
]
registered_names = [tool["name"] for tool in tools]

for tool_name in manipulation_tool_names:
    if tool_name in registered_names:
        print(f"✓ {tool_name} registered")
    else:
        print(f"✗ {tool_name} MISSING")
        exit(1)

print("\nAll 5 manipulation tools successfully registered")
PYEOF
```

## Deliverables

- Pydantic models for manipulation tools: `/opt/docling-mcp/application/docling_mcp/models/manipulation.py`
- Manipulation tool implementations: `/opt/docling-mcp/application/docling_mcp/tools/manipulation.py`
- 5 MCP tools registered with FastMCP server:
  - `merge_documents` (Tool 15)
  - `split_document` (Tool 16)
  - `search_document` (Tool 17)
  - `annotate_document` (Tool 18)
  - `export_document` (Tool 19)
- Server updated to import and register manipulation tools

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Pydantic models import successfully
python -c "from docling_mcp.models.manipulation import MergeDocumentsInput, SplitDocumentInput, SearchDocumentInput, ExportDocumentInput" && echo "PASS: Models import"

# 2. Tool implementations import successfully
python -c "from docling_mcp.tools.manipulation import register_manipulation_tools" && echo "PASS: Tools import"

# 3. All 5 tools registered
python -c "from docling_mcp.server import mcp; manip_tools = ['merge_documents', 'split_document', 'search_document', 'annotate_document', 'export_document']; registered = [t['name'] for t in mcp.list_tools()]; assert all(tool in registered for tool in manip_tools)" && echo "PASS: 5 manipulation tools registered"

# 4. Export tool has export_format parameter
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'export_document'][0]
assert 'export_format' in tool['inputSchema']['properties']
print('PASS: export_document has export_format parameter')
"

# 5. Search tool has search_mode parameter
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'search_document'][0]
assert 'search_mode' in tool['inputSchema']['properties']
print('PASS: search_document has search_mode parameter')
"
```

### Expected Output

All 5 verification checks should output "PASS".

## Rollback

If manipulation tool registration fails:

```bash
# 1. Remove tool files
rm -f /opt/docling-mcp/application/docling_mcp/tools/manipulation.py
rm -f /opt/docling-mcp/application/docling_mcp/models/manipulation.py

# 2. Restore server.py (remove manipulation tool import lines)

# 3. Document failure reason
echo "Manipulation tool registration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **Placeholder Implementation**: Tool handlers return placeholder responses until full implementation complete (Task 031 - Document Processing Pipeline Integration)
- **Export Backends**: Tool 19 requires export libraries (reportlab for PDF, python-docx for DOCX)
- **Search Algorithms**: Tool 17 BM25 requires rank-bm25 library, semantic requires embedding generation
- **Annotation Support**: Tool 18 annotation types may require format-specific implementation (PDF annotations via pypdf)

## References

- **Specification**: Section 4.2 "MCP Tools Specification" - Tool 15-19 (manipulation tools)
- **Contribution Review**: `james-rodriguez-task-contribution.md` (lines 167-181: Tool 15-19 documentation)
- **Architecture**: Section 3.1 "Tool Registration Architecture"
- **Dependencies**: Task 005 (FastMCP), Task 031 (Document Processing Pipeline Integration)
