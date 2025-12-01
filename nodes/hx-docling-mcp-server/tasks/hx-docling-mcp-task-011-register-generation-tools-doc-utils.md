# Task: Register MCP Generation Tools - Document Utilities (8 tools)

**Task ID**: hx-docling-mcp-task-011
**Category**: MCP Tools
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-001 (FastMCP Framework Installation)
**Parallel Execution**: Yes [P] (can run parallel with tasks 009, 010, 012, 013)

## Objective

Implement and register 8 document utility MCP generation tools (Tools 7-14) with complete Pydantic schemas, docling integration, and LLM-based classification/summarization capabilities.

## Prerequisites

- FastMCP framework installed and server skeleton created (Task 005 complete)
- Docling library installed in virtual environment
- Application directory structure at `/opt/docling-mcp/application/docling_mcp/` exists
- LiteLLM client available for LLM-based tools (classification, summarization)

## Steps

### 1. Create Pydantic Models for Document Utility Tools

```bash
# Create document utility tool models file
cat > /opt/docling-mcp/application/docling_mcp/models/generation_doc_utils.py <<'EOF'
"""
Pydantic models for MCP Document Utility Generation Tools.

Defines input/output schemas for:
- create_docling_document (Tool 7)
- parse_pdf_structure (Tool 8)
- extract_tables (Tool 9)
- extract_images (Tool 10)
- detect_document_language (Tool 11)
- classify_document_type (Tool 12)
- extract_metadata (Tool 13)
- generate_document_summary (Tool 14)
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any
from enum import Enum

# ============================================================================
# Tool 7: create_docling_document
# ============================================================================

class DocItemType(str, Enum):
    """DoclingDocument item types."""
    HEADING = "heading"
    PARAGRAPH = "paragraph"
    LIST_ITEM = "list_item"
    TABLE = "table"
    CODE_BLOCK = "code_block"
    IMAGE = "image"

class CreateDoclingDocumentInput(BaseModel):
    """Input schema for create_docling_document tool."""
    text_content: str = Field(
        ...,
        min_length=1,
        max_length=500000,
        description="Raw text content to structure as DoclingDocument"
    )
    structure_hints: Optional[List[Dict[str, Any]]] = Field(
        None,
        description="Optional structure hints (item_type, level, text) for manual structuring"
    )
    detect_structure: bool = Field(
        True,
        description="Auto-detect document structure (headings, lists, code blocks)"
    )
    title: Optional[str] = Field(
        None,
        max_length=500,
        description="Document title (auto-detected if omitted)"
    )

class DoclingDocumentOutput(BaseModel):
    """Output schema for DoclingDocument."""
    document_id: str = Field(..., description="Unique document identifier (SHA256 hash)")
    doc_items: List[Dict[str, Any]] = Field(..., description="Hierarchical document structure items")
    metadata: Dict[str, Any] = Field(..., description="Document metadata")

# ============================================================================
# Tool 8: parse_pdf_structure
# ============================================================================

class ParsePDFStructureInput(BaseModel):
    """Input schema for parse_pdf_structure tool."""
    pdf_source: str = Field(
        ...,
        description="PDF file path (file://) or URL (https://)"
    )
    include_toc: bool = Field(
        True,
        description="Extract table of contents from PDF bookmarks"
    )
    include_sections: bool = Field(
        True,
        description="Detect section boundaries via heading analysis"
    )

class PDFStructureOutput(BaseModel):
    """Output schema for PDF structure analysis."""
    page_count: int = Field(..., description="Total number of pages")
    toc: List[Dict[str, Any]] = Field(..., description="Table of contents entries (title, page, level)")
    sections: List[Dict[str, Any]] = Field(..., description="Detected sections (title, start_page, end_page)")
    metadata: Dict[str, Any] = Field(..., description="PDF metadata (author, title, creation_date)")

# ============================================================================
# Tool 9: extract_tables
# ============================================================================

class ExtractTablesInput(BaseModel):
    """Input schema for extract_tables tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID)"
    )
    include_headers: bool = Field(
        True,
        description="Include table header rows in extraction"
    )
    merge_cells: bool = Field(
        True,
        description="Handle merged cells in table structure"
    )
    output_format: str = Field(
        "json",
        pattern="^(json|csv|markdown)$",
        description="Output format: json (structured), csv (tabular), markdown (gfm tables)"
    )

class TableCell(BaseModel):
    """Table cell structure."""
    row: int = Field(..., ge=0, description="Row index (0-based)")
    col: int = Field(..., ge=0, description="Column index (0-based)")
    rowspan: int = Field(1, ge=1, description="Number of rows spanned")
    colspan: int = Field(1, ge=1, description="Number of columns spanned")
    text: str = Field(..., description="Cell text content")
    is_header: bool = Field(False, description="True if header cell")

class TableOutput(BaseModel):
    """Single table extraction result."""
    table_id: str = Field(..., description="Unique table identifier")
    rows: int = Field(..., ge=1, description="Number of rows")
    cols: int = Field(..., ge=1, description="Number of columns")
    cells: List[TableCell] = Field(..., description="Table cells with structure")
    page: Optional[int] = Field(None, description="Source page number (PDF only)")

class ExtractTablesOutput(BaseModel):
    """Output schema for table extraction."""
    tables: List[TableOutput] = Field(..., description="Extracted tables")
    total_tables: int = Field(..., ge=0, description="Total number of tables found")

# ============================================================================
# Tool 10: extract_images
# ============================================================================

class ExtractImagesInput(BaseModel):
    """Input schema for extract_images tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID)"
    )
    include_captions: bool = Field(
        True,
        description="Extract image captions from surrounding text"
    )
    min_width: int = Field(
        100,
        ge=10,
        le=5000,
        description="Minimum image width in pixels (filter small icons)"
    )
    min_height: int = Field(
        100,
        ge=10,
        le=5000,
        description="Minimum image height in pixels"
    )
    output_format: str = Field(
        "base64",
        pattern="^(base64|file_path)$",
        description="Output format: base64 (inline), file_path (extracted files)"
    )

class ImageOutput(BaseModel):
    """Single image extraction result."""
    image_id: str = Field(..., description="Unique image identifier")
    width: int = Field(..., ge=1, description="Image width in pixels")
    height: int = Field(..., ge=1, description="Image height in pixels")
    format: str = Field(..., description="Image format (png, jpg, tiff)")
    data: str = Field(..., description="Base64 data or file path (per output_format)")
    caption: Optional[str] = Field(None, description="Extracted caption text")
    page: Optional[int] = Field(None, description="Source page number (PDF only)")

class ExtractImagesOutput(BaseModel):
    """Output schema for image extraction."""
    images: List[ImageOutput] = Field(..., description="Extracted images")
    total_images: int = Field(..., ge=0, description="Total number of images found")

# ============================================================================
# Tool 11: detect_document_language
# ============================================================================

class DetectLanguageInput(BaseModel):
    """Input schema for detect_document_language tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, DoclingDocument ID, or raw text)"
    )
    text_sample_length: int = Field(
        5000,
        ge=100,
        le=50000,
        description="Number of characters to sample for language detection"
    )

class LanguageDetectionOutput(BaseModel):
    """Output schema for language detection."""
    primary_language: str = Field(..., description="Primary detected language (ISO 639-1 code)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Detection confidence (0.0 to 1.0)")
    all_languages: List[Dict[str, Any]] = Field(
        ...,
        description="All detected languages with confidence scores (sorted by confidence)"
    )

# ============================================================================
# Tool 12: classify_document_type
# ============================================================================

class DocumentTypeClass(str, Enum):
    """Document type classification categories."""
    REPORT = "report"
    ARTICLE = "article"
    CONTRACT = "contract"
    INVOICE = "invoice"
    PRESENTATION = "presentation"
    SPREADSHEET = "spreadsheet"
    EMAIL = "email"
    MANUAL = "manual"
    OTHER = "other"

class ClassifyDocumentInput(BaseModel):
    """Input schema for classify_document_type tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID)"
    )
    llm_model: str = Field(
        "gemma3:27b",
        pattern=r"^[a-zA-Z0-9_:./-]+$",
        description="LLM model for classification (routed via LiteLLM)"
    )
    confidence_threshold: float = Field(
        0.7,
        ge=0.0,
        le=1.0,
        description="Minimum confidence for classification (return 'other' if below)"
    )

class DocumentClassificationOutput(BaseModel):
    """Output schema for document classification."""
    document_type: DocumentTypeClass = Field(..., description="Classified document type")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Classification confidence")
    reasoning: str = Field(..., description="LLM reasoning for classification")
    all_types: List[Dict[str, Any]] = Field(
        ...,
        description="All types with confidence scores (sorted by confidence)"
    )

# ============================================================================
# Tool 13: extract_metadata
# ============================================================================

class ExtractMetadataInput(BaseModel):
    """Input schema for extract_metadata tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID)"
    )
    include_llm_extraction: bool = Field(
        False,
        description="Use LLM to extract additional metadata (author, keywords) if not in file metadata"
    )

class DocumentMetadataOutput(BaseModel):
    """Output schema for metadata extraction."""
    title: Optional[str] = Field(None, description="Document title")
    author: Optional[str] = Field(None, description="Document author(s)")
    creation_date: Optional[str] = Field(None, description="Creation date (ISO8601)")
    modification_date: Optional[str] = Field(None, description="Last modification date (ISO8601)")
    keywords: List[str] = Field(default_factory=list, description="Document keywords/tags")
    page_count: Optional[int] = Field(None, description="Total pages (PDF/DOCX)")
    word_count: Optional[int] = Field(None, description="Estimated word count")
    language: Optional[str] = Field(None, description="Detected language (ISO 639-1)")
    format: str = Field(..., description="Document format (pdf, docx, etc.)")

# ============================================================================
# Tool 14: generate_document_summary
# ============================================================================

class SummarizationStyle(str, Enum):
    """Summarization style options."""
    EXTRACTIVE = "extractive"  # Extract key sentences
    ABSTRACTIVE = "abstractive"  # Generate new summary text
    BULLET_POINTS = "bullet_points"  # Structured bullet list

class GenerateSummaryInput(BaseModel):
    """Input schema for generate_document_summary tool."""
    document_source: str = Field(
        ...,
        description="Document source (file path, URL, or DoclingDocument ID)"
    )
    max_length: int = Field(
        500,
        ge=50,
        le=5000,
        description="Maximum summary length in words"
    )
    style: SummarizationStyle = Field(
        SummarizationStyle.ABSTRACTIVE,
        description="Summarization style (extractive, abstractive, bullet_points)"
    )
    llm_model: str = Field(
        "gemma3:27b",
        pattern=r"^[a-zA-Z0-9_:./-]+$",
        description="LLM model for summarization (routed via LiteLLM)"
    )

class DocumentSummaryOutput(BaseModel):
    """Output schema for document summary."""
    summary: str = Field(..., description="Generated summary text")
    word_count: int = Field(..., ge=1, description="Summary word count")
    source_word_count: int = Field(..., ge=1, description="Source document word count")
    compression_ratio: float = Field(..., ge=0.0, le=1.0, description="Summary/source word ratio")
    style_used: SummarizationStyle = Field(..., description="Summarization style applied")

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/models/generation_doc_utils.py
chmod 644 /opt/docling-mcp/application/docling_mcp/models/generation_doc_utils.py
```

### 2. Implement Document Utility Tool Handlers

```bash
# Create document utility tools implementation
cat > /opt/docling-mcp/application/docling_mcp/tools/generation_doc_utils.py <<'EOF'
"""
MCP Document Utility Generation Tools Implementation.

Implements 8 MCP tools:
7. create_docling_document: Programmatic DoclingDocument creation
8. parse_pdf_structure: PDF-specific metadata extraction
9. extract_tables: Table detection and extraction
10. extract_images: Image extraction with captions
11. detect_document_language: Language detection via langdetect
12. classify_document_type: LLM-based document classification
13. extract_metadata: Metadata extraction
14. generate_document_summary: Abstractive summarization
"""

import logging
import hashlib
from typing import List

from fastmcp import FastMCP
from ..models.generation_doc_utils import (
    CreateDoclingDocumentInput,
    DoclingDocumentOutput,
    ParsePDFStructureInput,
    PDFStructureOutput,
    ExtractTablesInput,
    ExtractTablesOutput,
    TableOutput,
    TableCell,
    ExtractImagesInput,
    ExtractImagesOutput,
    ImageOutput,
    DetectLanguageInput,
    LanguageDetectionOutput,
    ClassifyDocumentInput,
    DocumentClassificationOutput,
    ExtractMetadataInput,
    DocumentMetadataOutput,
    GenerateSummaryInput,
    DocumentSummaryOutput,
    SummarizationStyle,
)

logger = logging.getLogger(__name__)

# ============================================================================
# Tool Registration Functions
# ============================================================================

def register_generation_doc_utils_tools(mcp: FastMCP):
    """
    Register all 8 document utility generation tools with FastMCP server.

    Args:
        mcp: FastMCP server instance
    """
    logger.info("Registering document utility generation tools...")

    # Tools registered via decorators below
    # This function serves as entry point for tool module

    logger.info("Document utility generation tools registered: 8 tools (create_docling_document through generate_document_summary)")

# ============================================================================
# Tool 7: create_docling_document
# ============================================================================

def create_docling_document_impl(mcp: FastMCP):
    """Decorator-based tool registration for create_docling_document."""

    @mcp.tool(
        name="create_docling_document",
        description="Programmatically create structured DoclingDocument from raw text with optional structure hints."
    )
    async def create_docling_document(input: CreateDoclingDocumentInput) -> DoclingDocumentOutput:
        """
        Create DoclingDocument from raw text with structure detection.

        Workflow:
        1. Parse text_content
        2. Auto-detect structure (headings, lists, code blocks) if enabled
        3. Apply structure_hints if provided
        4. Assemble DoclingDocument with doc_items hierarchy
        5. Generate document_id (SHA256 hash)

        Args:
            input: CreateDoclingDocumentInput with text and structure options

        Returns:
            DoclingDocumentOutput: Structured document with doc_items
        """
        logger.info(f"create_docling_document called: text_length={len(input.text_content)}")

        # TODO: Implement structure detection and DoclingDocument assembly
        # Placeholder response
        doc_id = hashlib.sha256(input.text_content.encode()).hexdigest()[:16]

        return DoclingDocumentOutput(
            document_id=doc_id,
            doc_items=[{"type": "paragraph", "text": "Placeholder: Implementation pending"}],
            metadata={"word_count": len(input.text_content.split()), "structure_detected": input.detect_structure}
        )

    return create_docling_document

# ============================================================================
# Tool 8: parse_pdf_structure
# ============================================================================

def parse_pdf_structure_impl(mcp: FastMCP):
    """Decorator-based tool registration for parse_pdf_structure."""

    @mcp.tool(
        name="parse_pdf_structure",
        description="Extract PDF-specific structure: page count, table of contents, section boundaries."
    )
    async def parse_pdf_structure(input: ParsePDFStructureInput) -> PDFStructureOutput:
        """
        Parse PDF structure and metadata.

        Workflow:
        1. Open PDF via Docling backend
        2. Extract page count
        3. Extract TOC from PDF bookmarks if available
        4. Detect sections via heading analysis
        5. Extract PDF metadata (author, title, dates)

        Args:
            input: ParsePDFStructureInput with PDF source and options

        Returns:
            PDFStructureOutput: Page count, TOC, sections, metadata
        """
        logger.info(f"parse_pdf_structure called: source={input.pdf_source[:50]}...")

        # TODO: Implement PDF structure parsing via Docling backend
        # Placeholder response

        return PDFStructureOutput(
            page_count=0,
            toc=[],
            sections=[],
            metadata={"placeholder": "Implementation pending"}
        )

    return parse_pdf_structure

# ============================================================================
# Tool 9: extract_tables
# ============================================================================

def extract_tables_impl(mcp: FastMCP):
    """Decorator-based tool registration for extract_tables."""

    @mcp.tool(
        name="extract_tables",
        description="Extract table structures from documents with cell-level detail and configurable output formats."
    )
    async def extract_tables(input: ExtractTablesInput) -> ExtractTablesOutput:
        """
        Extract tables from document.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Detect table regions
        3. Extract table cells with structure (row, col, rowspan, colspan)
        4. Handle merged cells if enabled
        5. Format output (json, csv, markdown)

        Args:
            input: ExtractTablesInput with document source and format options

        Returns:
            ExtractTablesOutput: Extracted tables with cell structures
        """
        logger.info(f"extract_tables called: source={input.document_source[:50]}...")

        # TODO: Implement table extraction via Docling table detection
        # Placeholder response

        return ExtractTablesOutput(
            tables=[],
            total_tables=0
        )

    return extract_tables

# ============================================================================
# Tool 10: extract_images
# ============================================================================

def extract_images_impl(mcp: FastMCP):
    """Decorator-based tool registration for extract_images."""

    @mcp.tool(
        name="extract_images",
        description="Extract images from documents with optional caption detection and size filtering."
    )
    async def extract_images(input: ExtractImagesInput) -> ExtractImagesOutput:
        """
        Extract images from document.

        Workflow:
        1. Get DoclingDocument (from cache or convert)
        2. Detect image regions
        3. Filter by min_width/min_height
        4. Extract image data (base64 or save to file)
        5. Extract captions from surrounding text if enabled

        Args:
            input: ExtractImagesInput with document source and extraction options

        Returns:
            ExtractImagesOutput: Extracted images with metadata and captions
        """
        logger.info(f"extract_images called: source={input.document_source[:50]}...")

        # TODO: Implement image extraction via Docling image detection
        # Placeholder response

        return ExtractImagesOutput(
            images=[],
            total_images=0
        )

    return extract_images

# ============================================================================
# Tool 11: detect_document_language
# ============================================================================

def detect_document_language_impl(mcp: FastMCP):
    """Decorator-based tool registration for detect_document_language."""

    @mcp.tool(
        name="detect_document_language",
        description="Detect document language using langdetect library with confidence scores."
    )
    async def detect_document_language(input: DetectLanguageInput) -> LanguageDetectionOutput:
        """
        Detect document language.

        Workflow:
        1. Extract text sample from document (first N characters)
        2. Use langdetect library for language detection
        3. Return primary language with confidence
        4. Return all detected languages ranked by confidence

        Args:
            input: DetectLanguageInput with document source and sample length

        Returns:
            LanguageDetectionOutput: Primary language, confidence, all languages
        """
        logger.info(f"detect_document_language called: source={input.document_source[:50]}...")

        # TODO: Implement language detection via langdetect
        # Placeholder response

        return LanguageDetectionOutput(
            primary_language="en",
            confidence=0.99,
            all_languages=[{"language": "en", "confidence": 0.99}]
        )

    return detect_document_language

# ============================================================================
# Tool 12: classify_document_type
# ============================================================================

def classify_document_type_impl(mcp: FastMCP):
    """Decorator-based tool registration for classify_document_type."""

    @mcp.tool(
        name="classify_document_type",
        description="Classify document type (report, article, contract, invoice, etc.) using LLM-based classification."
    )
    async def classify_document_type(input: ClassifyDocumentInput) -> DocumentClassificationOutput:
        """
        Classify document type via LLM.

        Workflow:
        1. Extract document structure and content sample
        2. Build classification prompt with type definitions
        3. Query LLM via LiteLLM (gemma3:27b default)
        4. Parse LLM response for document type and reasoning
        5. Return classification with confidence

        Args:
            input: ClassifyDocumentInput with document source and LLM model

        Returns:
            DocumentClassificationOutput: Type, confidence, reasoning, all types
        """
        logger.info(f"classify_document_type called: source={input.document_source[:50]}...")

        # TODO: Implement LLM-based document classification via LiteLLM
        # Placeholder response

        return DocumentClassificationOutput(
            document_type="other",
            confidence=0.5,
            reasoning="Placeholder: Implementation pending",
            all_types=[{"type": "other", "confidence": 0.5}]
        )

    return classify_document_type

# ============================================================================
# Tool 13: extract_metadata
# ============================================================================

def extract_metadata_impl(mcp: FastMCP):
    """Decorator-based tool registration for extract_metadata."""

    @mcp.tool(
        name="extract_metadata",
        description="Extract document metadata (author, title, creation date, keywords) from file metadata and optionally via LLM."
    )
    async def extract_metadata(input: ExtractMetadataInput) -> DocumentMetadataOutput:
        """
        Extract document metadata.

        Workflow:
        1. Extract file metadata (PDF metadata, DOCX properties)
        2. Detect document language
        3. Count pages/words
        4. If include_llm_extraction: Use LLM to extract author/keywords from content
        5. Return comprehensive metadata

        Args:
            input: ExtractMetadataInput with document source and LLM option

        Returns:
            DocumentMetadataOutput: Title, author, dates, keywords, counts
        """
        logger.info(f"extract_metadata called: source={input.document_source[:50]}...")

        # TODO: Implement metadata extraction from file properties and LLM
        # Placeholder response

        return DocumentMetadataOutput(
            title=None,
            author=None,
            creation_date=None,
            modification_date=None,
            keywords=[],
            page_count=None,
            word_count=None,
            language=None,
            format="unknown"
        )

    return extract_metadata

# ============================================================================
# Tool 14: generate_document_summary
# ============================================================================

def generate_document_summary_impl(mcp: FastMCP):
    """Decorator-based tool registration for generate_document_summary."""

    @mcp.tool(
        name="generate_document_summary",
        description="Generate document summary using LLM with configurable length and style (extractive, abstractive, bullet points)."
    )
    async def generate_document_summary(input: GenerateSummaryInput) -> DocumentSummaryOutput:
        """
        Generate document summary via LLM.

        Workflow:
        1. Get DoclingDocument text content
        2. Build summarization prompt per style (extractive, abstractive, bullet_points)
        3. Query LLM via LiteLLM (gemma3:27b default)
        4. Parse LLM response for summary
        5. Calculate compression ratio
        6. Return summary with metrics

        Args:
            input: GenerateSummaryInput with document source, length, style, model

        Returns:
            DocumentSummaryOutput: Summary text, word counts, compression ratio
        """
        logger.info(f"generate_document_summary called: source={input.document_source[:50]}...")

        # TODO: Implement LLM-based summarization via LiteLLM
        # Placeholder response

        return DocumentSummaryOutput(
            summary="Placeholder: Implementation pending",
            word_count=5,
            source_word_count=100,
            compression_ratio=0.05,
            style_used=input.style
        )

    return generate_document_summary

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/tools/generation_doc_utils.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/generation_doc_utils.py
```

### 3. Update Server to Register Document Utility Tools

```bash
# Append to server.py
cat >> /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'

# Import document utility generation tool registration
from .tools.generation_doc_utils import (
    register_generation_doc_utils_tools,
    create_docling_document_impl,
    parse_pdf_structure_impl,
    extract_tables_impl,
    extract_images_impl,
    detect_document_language_impl,
    classify_document_type_impl,
    extract_metadata_impl,
    generate_document_summary_impl,
)

# Register document utility generation tools
register_generation_doc_utils_tools(mcp)
create_docling_document_impl(mcp)
parse_pdf_structure_impl(mcp)
extract_tables_impl(mcp)
extract_images_impl(mcp)
detect_document_language_impl(mcp)
classify_document_type_impl(mcp)
extract_metadata_impl(mcp)
generate_document_summary_impl(mcp)

logger.info("Document utility generation tools registered with MCP server")
EOF
```

### 4. Test Document Utility Tool Registration

```bash
# Test tool import and registration
cd /opt/docling-mcp/application
python <<'PYEOF'
from docling_mcp.server import mcp

# Verify tools registered
tools = mcp.list_tools()
print(f"Total tools registered: {len(tools)}")

# Check document utility tools present
doc_util_tool_names = [
    "create_docling_document",
    "parse_pdf_structure",
    "extract_tables",
    "extract_images",
    "detect_document_language",
    "classify_document_type",
    "extract_metadata",
    "generate_document_summary"
]
registered_names = [tool["name"] for tool in tools]

for tool_name in doc_util_tool_names:
    if tool_name in registered_names:
        print(f"✓ {tool_name} registered")
    else:
        print(f"✗ {tool_name} MISSING")
        exit(1)

print("\nAll 8 document utility generation tools successfully registered")
PYEOF
```

## Deliverables

- Pydantic models for document utility tools: `/opt/docling-mcp/application/docling_mcp/models/generation_doc_utils.py`
- Document utility tool implementations: `/opt/docling-mcp/application/docling_mcp/tools/generation_doc_utils.py`
- 8 MCP tools registered with FastMCP server:
  - `create_docling_document` (Tool 7)
  - `parse_pdf_structure` (Tool 8)
  - `extract_tables` (Tool 9)
  - `extract_images` (Tool 10)
  - `detect_document_language` (Tool 11)
  - `classify_document_type` (Tool 12)
  - `extract_metadata` (Tool 13)
  - `generate_document_summary` (Tool 14)
- Server updated to import and register document utility tools

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Pydantic models import successfully
python -c "from docling_mcp.models.generation_doc_utils import CreateDoclingDocumentInput, ExtractTablesInput, GenerateSummaryInput" && echo "PASS: Models import"

# 2. Tool implementations import successfully
python -c "from docling_mcp.tools.generation_doc_utils import register_generation_doc_utils_tools" && echo "PASS: Tools import"

# 3. All 8 tools registered
python -c "from docling_mcp.server import mcp; doc_util_tools = ['create_docling_document', 'parse_pdf_structure', 'extract_tables', 'extract_images', 'detect_document_language', 'classify_document_type', 'extract_metadata', 'generate_document_summary']; registered = [t['name'] for t in mcp.list_tools()]; assert all(tool in registered for tool in doc_util_tools)" && echo "PASS: 8 document utility tools registered"

# 4. LLM-based tools have llm_model parameter
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'classify_document_type'][0]
assert 'llm_model' in tool['inputSchema']['properties']
print('PASS: classify_document_type has LLM model parameter')
"

# 5. Table extraction tool has output_format parameter
python -c "
from docling_mcp.server import mcp
tool = [t for t in mcp.list_tools() if t['name'] == 'extract_tables'][0]
assert 'output_format' in tool['inputSchema']['properties']
print('PASS: extract_tables has output_format parameter')
"
```

### Expected Output

All 5 verification checks should output "PASS".

## Rollback

If document utility tool registration fails:

```bash
# 1. Remove tool files
rm -f /opt/docling-mcp/application/docling_mcp/tools/generation_doc_utils.py
rm -f /opt/docling-mcp/application/docling_mcp/models/generation_doc_utils.py

# 2. Restore server.py (remove document utility tool import lines)

# 3. Document failure reason
echo "Document utility tool registration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **Placeholder Implementation**: Tool handlers return placeholder responses until full implementation complete (Task 031 - Document Processing Pipeline Integration)
- **LLM Integration**: Tools 12 and 14 require LiteLLM client integration (Task 026)
- **Language Detection**: Tool 11 requires langdetect library (installed via requirements.txt)
- **Table/Image Extraction**: Tools 9 and 10 require Docling backend table/image detection features
- **PDF Structure Parsing**: Tool 8 requires PDF-specific Docling backend capabilities

## References

- **Specification**: Section 4.2 "MCP Tools Specification" - Tool 7-14 (generation tools)
- **Contribution Review**: `james-rodriguez-task-contribution.md` (lines 149-166: Tool 4-5 documentation)
- **Architecture**: Section 3.1 "Tool Registration Architecture"
- **Dependencies**: Task 005 (FastMCP), Task 026 (LiteLLM Integration), Task 031 (Document Processing Pipeline)
