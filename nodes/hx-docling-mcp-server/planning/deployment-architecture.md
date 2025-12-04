# Deployment Architecture: Docling MCP Server

**Project**: hx-docling-mcp-server | **Date**: 2025-11-27 (Created), 2025-12-04 (Operational) | **Version**: 1.0
**Charter**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`
**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
**Plan**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md`
**Status**: ✅ COMPLETE - Architecture Implemented, Service OPERATIONAL

---

## Table of Contents

1. [System Architecture](#1-system-architecture)
2. [Technology Stack Details](#2-technology-stack-details)
3. [MCP Protocol Implementation](#3-mcp-protocol-implementation)
4. [Document Processing Architecture](#4-document-processing-architecture)
5. [Storage Architecture](#5-storage-architecture)
6. [Security Architecture](#6-security-architecture)
7. [Performance Architecture](#7-performance-architecture)
8. [Deployment Architecture](#8-deployment-architecture)
9. [Integration Architecture](#9-integration-architecture)
10. [Scalability and HA Considerations](#10-scalability-and-ha-considerations)
11. [Architecture Decision Records](#11-architecture-decision-records)

---

## 1. System Architecture

### 1.1 Component Architecture Overview

The Docling MCP Server implements a **3-layer architecture** aligned with HX-Infrastructure's layered approach:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Layer 1: MCP Protocol Interface                      │
│                                                                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │  HTTP Transport │  │  SSE Transport  │  │ stdio Transport │             │
│  │    (Port 8000)  │  │  (Port 8000)    │  │   (Process IO)  │             │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘             │
│           │                    │                     │                       │
│           └────────────────────┴─────────────────────┘                       │
│                                │                                             │
│                    ┌───────────▼───────────┐                                 │
│                    │  FastMCP Framework    │                                 │
│                    │  - Tool Registry      │                                 │
│                    │  - Request Router     │                                 │
│                    │  - Schema Validator   │                                 │
│                    │  - Error Handler      │                                 │
│                    └───────────┬───────────┘                                 │
└────────────────────────────────┼─────────────────────────────────────────────┘
                                 │
┌────────────────────────────────▼─────────────────────────────────────────────┐
│                   Layer 2: Document Processing Pipeline                      │
│                                                                               │
│  ┌───────────────────────────────────────────────────────────────┐           │
│  │                    19 MCP Tools (Implementation)              │           │
│  │                                                                │           │
│  │  Conversion Tools (3):          Generation Tools (11):        │           │
│  │  - convert_pdf                  - generate_title              │           │
│  │  - convert_docx                 - generate_toc                │           │
│  │  - convert_url                  - generate_section            │           │
│  │                                 - generate_heading            │           │
│  │  Manipulation Tools (5):        - generate_paragraph          │           │
│  │  - split_document               - generate_list               │           │
│  │  - merge_documents              - generate_table              │           │
│  │  - export_markdown              - generate_image              │           │
│  │  - export_html                  - generate_caption            │           │
│  │  - export_json                  - generate_codeblock          │           │
│  │                                 - generate_reference          │           │
│  └───────────────────────────────────────────────────────────────┘           │
│                                 │                                             │
│                    ┌────────────▼────────────┐                                │
│                    │   Docling Library       │                                │
│                    │   (Embedded In-Process) │                                │
│                    │                         │                                │
│                    │  - Format Detection     │                                │
│                    │  - Backend Routing      │                                │
│                    │  - PDF Processing       │                                │
│                    │  - DOCX Processing      │                                │
│                    │  - Image OCR            │                                │
│                    │  - Structure Extraction │                                │
│                    └────────────┬────────────┘                                │
│                                 │                                             │
│                    ┌────────────▼────────────┐                                │
│                    │   LightRAG Engine       │                                │
│                    │                         │                                │
│                    │  - Entity Extraction    │                                │
│                    │  - Relationship Modeling│                                │
│                    │  - Graph Construction   │                                │
│                    │  - Dual-Level Indexing  │                                │
│                    └────────────┬────────────┘                                │
└─────────────────────────────────┼──────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────────────────────┐
│                Layer 3: Storage & Infrastructure Integration                   │
│                                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             │
│  │   Redis Cache    │  │  Qdrant Vector   │  │  LiteLLM Gateway │             │
│  │  Session State   │  │  Knowledge Graph │  │   LLM Routing    │             │
│  │ (.221:6379)      │  │  (.223:6333)     │  │  (.213:4000)     │             │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘             │
│                                                        │                        │
│                                              ┌─────────▼─────────┐              │
│                                              │  Ollama Cluster   │              │
│                                              │                   │              │
│                                              │  1: gemma3:27b    │              │
│                                              │     gpt-oss:20b   │              │
│                                              │  2: qwen3:30b     │              │
│                                              │  3: granite:258m  │              │
│                                              │     bge-m3:567m   │              │
│                                              └───────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Layer Interactions

**Layer 1 (MCP Protocol Interface):**
- **Purpose**: Expose standardized MCP protocol endpoints for AI agent integration
- **Responsibilities**:
  - Accept HTTP/SSE/stdio requests from MCP clients
  - Route requests to appropriate MCP tool handlers
  - Validate request schemas against Pydantic models
  - Return MCP-compliant responses (JSON-RPC format)
- **Technology**: FastMCP framework (Python)
- **Integration**: Provides interface for AI agents, routes to Layer 2 tools

**Layer 2 (Document Processing Pipeline):**
- **Purpose**: Execute document processing workflows and knowledge graph generation
- **Responsibilities**:
  - Implement 19 MCP tools (conversion, generation, manipulation)
  - Orchestrate docling library for document conversion
  - Coordinate LightRAG engine for entity extraction
  - Manage document processing state and caching
- **Technology**: Docling library (embedded), LightRAG framework, Python asyncio
- **Integration**: Consumes Layer 1 requests, persists to Layer 3 storage

**Layer 3 (Storage & Infrastructure Integration):**
- **Purpose**: Provide persistence, caching, and external LLM access
- **Responsibilities**:
  - Store session state in Redis (TTL-based expiration)
  - Persist knowledge graphs in Qdrant vector database
  - Route LLM requests to Ollama cluster via LiteLLM
  - Manage connection pooling and retry logic
- **Technology**: Redis, Qdrant, LiteLLM, Ollama
- **Integration**: Consumed by Layer 2 processing pipeline

### 1.3 Data Flow Diagrams

**Primary Data Flow: Document Conversion**

```
┌──────────────┐
│  MCP Client  │
│  (AI Agent)  │
└──────┬───────┘
       │ 1. MCP Request (HTTP/SSE/stdio)
       │    Tool: convert_pdf
       │    Input: PDF file (base64 or URL)
       ▼
┌──────────────────────┐
│  FastMCP Framework   │
│  - Parse JSON-RPC    │
│  - Validate Schema   │
│  - Route to Handler  │
└──────┬───────────────┘
       │ 2. Tool Invocation
       │    Handler: convert_pdf()
       ▼
┌──────────────────────┐
│  MCP Tool Handler    │
│  - Extract params    │
│  - Load document     │
│  - Call docling      │
└──────┬───────────────┘
       │ 3. Document Processing
       │    docling.convert(pdf)
       ▼
┌──────────────────────┐
│  Docling Library     │
│  - Detect format     │
│  - Select backend    │
│  - Parse structure   │
│  - Extract content   │
└──────┬───────────────┘
       │ 4. DoclingDocument
       │    (structured JSON)
       ▼
┌──────────────────────┐
│  MCP Tool Handler    │
│  - Serialize output  │
│  - Cache in Redis    │
│  - Return response   │
└──────┬───────────────┘
       │ 5. MCP Response
       │    DoclingDocument JSON
       ▼
┌──────────────┐
│  MCP Client  │
│  (Receives)  │
└──────────────┘
```

**Secondary Data Flow: Knowledge Graph Generation**

```
┌──────────────────────┐
│  Converted Document  │
│  (DoclingDocument)   │
└──────┬───────────────┘
       │ 1. Text Extraction
       │    document.export_to_text()
       ▼
┌──────────────────────┐
│  LightRAG Engine     │
│  - Chunk text        │
│  - Extract entities  │
│  - Model relations   │
└──────┬───────────────┘
       │ 2. LLM Request
       │    Via LiteLLM Gateway
       ▼
┌──────────────────────┐
│  LiteLLM Gateway     │
│  - Route to Ollama1  │
│  - Model: gemma3:27b │
│  - Extract entities  │
└──────┬───────────────┘
       │ 3. Entities & Relations
       │    JSON structured output
       ▼
┌──────────────────────┐
│  LightRAG Engine     │
│  - Build graph       │
│  - Generate vectors  │
│  - Store in Qdrant   │
└──────┬───────────────┘
       │ 4. Vector Storage
       │    Entities + Relations
       ▼
┌──────────────────────┐
│  Qdrant Database     │
│  - Entity collection │
│  - Relation vectors  │
│  - Metadata indexes  │
└──────────────────────┘
```

### 1.4 Integration Points with HX-Infrastructure Services

**Service Dependencies (All Operational):**

| Service | Node | Port | Purpose | Integration Pattern |
|---------|------|------|---------|---------------------|
| **hx-litellm-server** | hx-litellm-server.hx.dev.local | 4000 | LLM routing gateway | Synchronous HTTP (OpenAI-compatible API) |
| **hx-ollama1-server** | hx-ollama1-server.hx.dev.local | 11434 | Entity extraction models | Via LiteLLM (gemma3:27b, gpt-oss:20b) |
| **hx-ollama2-server** | hx-ollama2-server.hx.dev.local | 11434 | Code processing models | Via LiteLLM (qwen3-coder:30b) |
| **hx-ollama3-server** | hx-ollama3-server.hx.dev.local | 11434 | Docling + embedding models | Via LiteLLM (granite-docling:258m, bge-m3:567m) |
| **hx-qdrant-server** | hx-qdrant-server.hx.dev.local | 6333 | Knowledge graph storage | Synchronous HTTP/gRPC |
| **hx-redis-server** | hx-redis-server.hx.dev.local | 6379 | Session state caching | Synchronous TCP (Redis protocol) |

**Network Topology:**

```
Internal Network: 192.168.10.0/24

┌─────────────────────────────────────────────────────────────────┐
│                     hx-docling-mcp-server                       │
│                      (hx-docling-mcp-server.hx.dev.local)                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Docling MCP Server (Port 8000)                        │    │
│  │  - FastMCP Framework                                   │    │
│  │  - Docling Library (embedded)                          │    │
│  │  - LightRAG Engine                                     │    │
│  └────────────────────────────────────────────────────────┘    │
│           │          │          │          │          │         │
└───────────┼──────────┼──────────┼──────────┼──────────┼─────────┘
            │          │          │          │          │
            ▼          ▼          ▼          ▼          ▼
       ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
       │LiteLLM │ │Ollama1 │ │Qdrant  │ │Redis   │ │Ollama3 │
       │.213    │ │.204    │ │.223    │ │.221    │ │.206    │
       │:4000   │ │:11434  │ │:6333   │ │:6379   │ │:11434  │
       └────────┘ └────────┘ └────────┘ └────────┘ └────────┘
            │
            └──> Routes to Ollama1/2/3 (model-based routing)
```

---

## 2. Technology Stack Details

### 2.1 FastMCP Framework Architecture

**Framework Overview:**
- **Purpose**: Provides MCP protocol server implementation with minimal boilerplate
- **Version**: Latest stable (production-ready per research)
- **Language**: Python 3.10+
- **Protocol**: Model Context Protocol (MCP) specification

**FastMCP Core Components:**

```python
# FastMCP Server Structure (Conceptual)

from fastmcp import FastMCP

# Initialize MCP server
mcp = FastMCP("docling-mcp-server")

# Transport configuration
mcp.add_transport("http", port=8000)
mcp.add_transport("sse", port=8000)  # Server-Sent Events
mcp.add_transport("stdio")  # Process I/O

# Tool registration (decorator pattern)
@mcp.tool()
async def convert_pdf(
    source: str,  # PDF file path or URL
    options: dict = {}
) -> DoclingDocument:
    """
    Convert PDF to DoclingDocument format.

    Args:
        source: PDF file path (local) or URL (remote)
        options: Conversion options (OCR, layout analysis, etc.)

    Returns:
        DoclingDocument: Structured document representation
    """
    # Implementation delegates to docling library
    pass

# Server lifecycle
if __name__ == "__main__":
    mcp.run()  # Starts all configured transports
```

**FastMCP Features Utilized:**
- **Automatic Schema Generation**: Pydantic models → MCP tool schemas
- **Multi-Transport Support**: HTTP, SSE, stdio from single codebase
- **Async/Await**: Native asyncio support for concurrent request handling
- **Middleware Support**: Authentication, logging, error handling (Phase 2)
- **Type Safety**: Pydantic validation for all inputs/outputs

### 2.2 Docling Library Integration Patterns

**Integration Approach: Embedded In-Process (Option A)**

**Rationale (from ADR-001):**
- Lower latency (no network overhead for worker API calls)
- Simpler architecture (single-process deployment)
- Easier debugging and development
- Acceptable for Phase 1 throughput requirements

**Docling Processing Flow:**

```python
# Docling Integration Pattern

from docling.document_converter import DocumentConverter
from docling.datamodel.document import DoclingDocument

class DoclingProcessor:
    """Embedded docling library processor."""

    def __init__(self):
        self.converter = DocumentConverter()
        self._cache = {}  # In-memory cache for recent conversions

    async def convert_document(
        self,
        source: str,
        format_hint: str = None
    ) -> DoclingDocument:
        """
        Convert document to DoclingDocument format.

        Architecture:
        1. Format Detection (MIME type, extension, content analysis)
        2. Backend Selection (PDF → PyPDFium, DOCX → python-docx, etc.)
        3. Structure Extraction (headings, paragraphs, tables, images)
        4. DoclingDocument Assembly (hierarchical JSON structure)

        Args:
            source: File path or URL
            format_hint: Optional format override (pdf, docx, etc.)

        Returns:
            DoclingDocument: Structured document representation
        """
        # Format detection
        detected_format = format_hint or self._detect_format(source)

        # Backend routing
        backend = self._select_backend(detected_format)

        # Conversion (synchronous docling call wrapped in async)
        doc = await self._run_in_executor(
            self.converter.convert,
            source,
            backend=backend
        )

        return doc

    def _detect_format(self, source: str) -> str:
        """Detect document format from extension or MIME type."""
        # Implementation: libmagic for MIME detection
        pass

    def _select_backend(self, format: str) -> str:
        """Select appropriate docling backend for format."""
        backend_map = {
            "pdf": "pypdfium2",
            "docx": "python-docx",
            "pptx": "python-pptx",
            "xlsx": "openpyxl",
            "html": "beautifulsoup4",
            "image": "tesseract-ocr"
        }
        return backend_map.get(format, "auto")
```

**Docling Format Support Matrix:**

| Format | Extension | Backend | Structure Support | OCR Support |
|--------|-----------|---------|-------------------|-------------|
| PDF (Digital) | .pdf | pypdfium2 | Full (headings, tables, lists) | No |
| PDF (Scanned) | .pdf | pypdfium2 + tesseract | Full | Yes |
| Microsoft Word | .docx | python-docx | Full (styles, tables, images) | N/A |
| PowerPoint | .pptx | python-pptx | Full (slides, shapes, text) | N/A |
| Excel | .xlsx | openpyxl | Full (sheets, cells, formulas) | N/A |
| HTML | .html | beautifulsoup4 | Full (semantic tags) | N/A |
| Images | .png, .jpg | tesseract-ocr | Text extraction only | Yes |

### 2.3 Python Asyncio Architecture

**Concurrency Model: asyncio Event Loop**

**Rationale (from ADR-002):**
- FastMCP framework built on asyncio
- Natural fit for I/O-bound document processing
- Enables concurrent request handling without thread overhead
- Integrates seamlessly with async HTTP clients (aiohttp for LiteLLM)

**Asyncio Architecture:**

```python
# Asyncio Architecture Pattern

import asyncio
from concurrent.futures import ThreadPoolExecutor

class MCPServer:
    """Async MCP server with thread pool for CPU-bound operations."""

    def __init__(self):
        # Event loop for I/O operations
        self.loop = asyncio.get_event_loop()

        # Thread pool for CPU-intensive docling processing
        self.executor = ThreadPoolExecutor(max_workers=4)

        # Async clients
        self.litellm_client = AsyncLiteLLMClient()
        self.qdrant_client = AsyncQdrantClient()
        self.redis_client = AsyncRedisClient()

    async def handle_request(self, request: MCPRequest) -> MCPResponse:
        """
        Handle MCP request asynchronously.

        Architecture:
        - I/O operations: Native asyncio (network calls)
        - CPU operations: ThreadPoolExecutor (docling processing)
        - Concurrent limit: Semaphore-based rate limiting
        """
        async with self.request_semaphore:
            # Parse request (I/O-bound, async)
            params = await self._parse_request(request)

            # Process document (CPU-bound, thread pool)
            doc = await self.loop.run_in_executor(
                self.executor,
                self._process_document_sync,
                params
            )

            # Store in cache (I/O-bound, async)
            await self.redis_client.set(
                f"doc:{doc.id}",
                doc.to_json(),
                ttl=3600
            )

            return MCPResponse(data=doc)

    def _process_document_sync(self, params: dict) -> DoclingDocument:
        """Synchronous docling processing (runs in thread pool)."""
        # CPU-intensive operations (docling library is synchronous)
        pass
```

**Concurrency Limits:**
- **Request Semaphore**: Max 10 concurrent requests (configurable via `MAX_CONCURRENT_REQUESTS`)
- **Thread Pool**: 4 workers for CPU-bound operations (matches 2-4 core allocation)
- **Connection Pools**:
  - LiteLLM: 20 connections (HTTP connection pool)
  - Qdrant: 10 connections (gRPC channel pool)
  - Redis: 10 connections (Redis connection pool)

### 2.4 LightRAG Knowledge Graph Engine

**LightRAG Architecture:**

```python
# LightRAG Integration Pattern

from lightrag import LightRAG
from lightrag.kg.qdrant_impl import QdrantKGStorage

class KnowledgeGraphBuilder:
    """LightRAG-based knowledge graph construction."""

    def __init__(self, litellm_client, qdrant_client):
        # LightRAG configuration
        self.rag = LightRAG(
            working_dir="/var/lib/docling-mcp/lightrag",
            llm=litellm_client,  # Entity extraction via LiteLLM
            embedding=litellm_client,  # Embedding via LiteLLM (bge-m3)
            kg_storage=QdrantKGStorage(
                client=qdrant_client,
                collection_prefix="docling_mcp_"
            )
        )

    async def build_knowledge_graph(
        self,
        document: DoclingDocument
    ) -> KnowledgeGraph:
        """
        Build knowledge graph from document.

        Architecture:
        1. Text Extraction (DoclingDocument → plain text chunks)
        2. Entity Extraction (LLM via LiteLLM → entities)
        3. Relationship Modeling (LLM via LiteLLM → relations)
        4. Graph Construction (entities + relations → graph structure)
        5. Vector Generation (embedding model via LiteLLM → vectors)
        6. Qdrant Storage (dual-level indexing: entities + themes)

        Args:
            document: DoclingDocument from docling conversion

        Returns:
            KnowledgeGraph: Graph structure with entities and relations
        """
        # Extract text chunks
        chunks = self._extract_chunks(document)

        # Extract entities and relations (LLM-driven)
        entities, relations = await self._extract_entities_relations(chunks)

        # Build graph structure
        graph = self._construct_graph(entities, relations)

        # Generate embeddings
        vectors = await self._generate_embeddings(entities)

        # Store in Qdrant
        await self._store_in_qdrant(graph, vectors)

        return graph

    async def _extract_entities_relations(self, chunks: list) -> tuple:
        """
        Extract entities and relations using LLM.

        LLM Routing (via LiteLLM):
        - Primary Model: ollama/gemma3:27b (entity extraction)
        - Fallback Model: ollama/gpt-oss:20b
        - NOT USED: granite-docling:258m (too small for entity extraction)

        Returns:
            (entities, relations): Extracted knowledge elements
        """
        # LightRAG handles LLM calls via configured llm client
        pass
```

**LightRAG Dual-Level Retrieval Pattern:**
- **Low-Level**: Entity and relationship vectors (fine-grained retrieval)
- **High-Level**: Summarized themes and topics (coarse-grained retrieval)
- **Storage**: Both levels stored in Qdrant collections
- **Retrieval** (Phase 2): Query-time selection of retrieval level

---

## 3. MCP Protocol Implementation

### 3.1 Tool Registration Architecture

**MCP Tool Schema (JSON-RPC):**

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "params": {},
  "id": 1
}

// Response:
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "convert_pdf",
        "description": "Convert PDF document to DoclingDocument format",
        "inputSchema": {
          "type": "object",
          "properties": {
            "source": {
              "type": "string",
              "description": "PDF file path or URL"
            },
            "options": {
              "type": "object",
              "properties": {
                "ocr": {"type": "boolean", "default": false},
                "layout_analysis": {"type": "boolean", "default": true}
              }
            }
          },
          "required": ["source"]
        }
      },
      // ... 18 more tools
    ]
  },
  "id": 1
}
```

**Tool Registration Pattern:**

```python
# MCP Tool Registration

from fastmcp import FastMCP
from pydantic import BaseModel, Field
from typing import Optional

class ConvertPDFInput(BaseModel):
    """Input schema for convert_pdf tool."""
    source: str = Field(..., description="PDF file path or URL")
    ocr: bool = Field(False, description="Enable OCR for scanned PDFs")
    layout_analysis: bool = Field(True, description="Preserve document layout")

class DoclingDocumentOutput(BaseModel):
    """Output schema for DoclingDocument."""
    id: str
    format: str
    content: dict  # Hierarchical document structure
    metadata: dict

mcp = FastMCP("docling-mcp-server")

@mcp.tool(
    name="convert_pdf",
    description="Convert PDF document to DoclingDocument format"
)
async def convert_pdf(
    input: ConvertPDFInput
) -> DoclingDocumentOutput:
    """
    Convert PDF to structured DoclingDocument.

    MCP Protocol:
    - Input validation: Pydantic model (automatic schema generation)
    - Output serialization: Pydantic model → JSON
    - Error handling: MCP-compliant error responses

    Returns:
        DoclingDocumentOutput: Structured document representation
    """
    # Implementation
    pass
```

**19 MCP Tools Implementation:**

**Conversion Tools (3):**
1. `convert_pdf`: PDF → DoclingDocument
2. `convert_docx`: DOCX → DoclingDocument
3. `convert_url`: Web URL → DoclingDocument (HTML scraping)

**Generation Tools (11):**
4. `generate_title`: Extract/generate document title
5. `generate_toc`: Generate table of contents
6. `generate_section`: Create new section from template
7. `generate_heading`: Create heading with style
8. `generate_paragraph`: Generate paragraph from prompt
9. `generate_list`: Create bulleted/numbered list
10. `generate_table`: Create table with data
11. `generate_image`: Generate image caption/description
12. `generate_caption`: Create caption for element
13. `generate_codeblock`: Format code with syntax highlighting
14. `generate_reference`: Generate citation/reference

**Manipulation Tools (5):**
15. `split_document`: Split document into chunks
16. `merge_documents`: Merge multiple DoclingDocuments
17. `export_markdown`: Export to Markdown format
18. `export_html`: Export to HTML format
19. `export_json`: Export to JSON format

### 3.2 Request/Response Flow

**HTTP Transport Request Flow:**

```
1. Client sends HTTP POST to http://hx-docling-mcp-server.hx.dev.local:8000/mcp
   Headers:
     Content-Type: application/json
   Body:
     {
       "jsonrpc": "2.0",
       "method": "tools/call",
       "params": {
         "name": "convert_pdf",
         "arguments": {
           "source": "https://example.com/document.pdf",
           "ocr": false
         }
       },
       "id": "req-001"
     }

2. FastMCP Framework parses JSON-RPC request
   - Validates JSON-RPC format
   - Routes to tool handler: convert_pdf()
   - Validates input against ConvertPDFInput schema

3. Tool Handler executes
   - Downloads PDF (if URL)
   - Calls docling library for conversion
   - Returns DoclingDocument

4. FastMCP Framework serializes response
   - Converts DoclingDocument to JSON
   - Wraps in JSON-RPC response format

5. Server sends HTTP response
   Status: 200 OK
   Headers:
     Content-Type: application/json
   Body:
     {
       "jsonrpc": "2.0",
       "result": {
         "id": "doc-12345",
         "format": "pdf",
         "content": { /* DoclingDocument structure */ },
         "metadata": { /* extraction metadata */ }
       },
       "id": "req-001"
     }
```

**SSE Transport (Server-Sent Events) for Streaming:**

```python
# SSE Transport for Large Document Streaming

@mcp.tool(
    name="convert_pdf_streaming",
    transport="sse"  # Enable SSE for this tool
)
async def convert_pdf_streaming(input: ConvertPDFInput):
    """
    Stream PDF conversion progress via Server-Sent Events.

    Use Case: Large PDFs (100+ pages) with progress updates

    SSE Events:
    - progress: Page conversion progress (0-100%)
    - page_complete: Each page processed
    - complete: Full document ready
    """
    async def event_generator():
        total_pages = get_pdf_page_count(input.source)

        for page_num in range(1, total_pages + 1):
            # Convert page
            page_doc = await convert_pdf_page(input.source, page_num)

            # Emit progress event
            yield {
                "event": "page_complete",
                "data": {
                    "page": page_num,
                    "total": total_pages,
                    "progress": (page_num / total_pages) * 100
                }
            }

        # Emit complete event
        yield {
            "event": "complete",
            "data": full_document
        }

    return event_generator()
```

### 3.3 Error Handling Architecture

**MCP Error Response Format:**

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,  // JSON-RPC error code
    "message": "Invalid params",
    "data": {
      "field": "source",
      "error": "File not found: /path/to/document.pdf"
    }
  },
  "id": "req-001"
}
```

**Error Code Mapping:**

| MCP Error Code | Description | Example |
|----------------|-------------|---------|
| -32700 | Parse error | Malformed JSON |
| -32600 | Invalid request | Missing jsonrpc field |
| -32601 | Method not found | Unknown tool name |
| -32602 | Invalid params | Schema validation failure |
| -32603 | Internal error | Docling processing failure |

**Error Handling Implementation:**

```python
# MCP Error Handling

from fastmcp.exceptions import (
    MCPError,
    InvalidParamsError,
    InternalError
)

@mcp.tool()
async def convert_pdf(input: ConvertPDFInput) -> DoclingDocumentOutput:
    try:
        # Download document
        if input.source.startswith("http"):
            doc_path = await download_file(input.source)
        else:
            doc_path = input.source
            if not os.path.exists(doc_path):
                raise InvalidParamsError(
                    message="File not found",
                    data={"source": input.source}
                )

        # Convert document
        doc = await docling_processor.convert(doc_path)

        return DoclingDocumentOutput.from_docling(doc)

    except FileNotFoundError as e:
        raise InvalidParamsError(
            message=f"File not found: {input.source}",
            data={"source": input.source}
        )

    except DoclingProcessingError as e:
        raise InternalError(
            message=f"Document processing failed: {str(e)}",
            data={"stage": e.stage, "details": e.details}
        )

    except Exception as e:
        # Catch-all for unexpected errors
        raise InternalError(
            message="Unexpected error during document conversion",
            data={"error": str(e)}
        )
```

**Retry Logic for Integration Failures:**

```python
# Retry Pattern for External Service Calls

from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

class IntegrationClient:
    """Base client with retry logic for external services."""

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError))
    )
    async def call_with_retry(self, *args, **kwargs):
        """
        Call external service with exponential backoff retry.

        Retry Strategy:
        - Max attempts: 3
        - Backoff: 1s, 2s, 4s (exponential)
        - Retry on: ConnectionError, TimeoutError
        - Fail fast on: 4xx client errors (invalid requests)
        """
        pass
```

---

## 4. Document Processing Architecture

### 4.1 Document Ingestion Flow

**Ingestion Pipeline Stages:**

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Document Ingestion Pipeline                           │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│  1. Input       │  Sources: Local file, URL, base64-encoded
│     Validation  │  Checks: File size, MIME type, accessibility
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. Format      │  Detection: MIME type (libmagic), extension, content sniffing
│     Detection   │  Formats: PDF, DOCX, PPTX, XLSX, HTML, images (14+ total)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. Backend     │  PDF → pypdfium2 + tesseract (if OCR)
│     Selection   │  DOCX → python-docx
│                 │  PPTX → python-pptx
│                 │  XLSX → openpyxl
│                 │  HTML → beautifulsoup4
│                 │  Images → tesseract-ocr
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. Document    │  Structure: Headings, paragraphs, tables, lists, code blocks
│     Parsing     │  Content: Text, images, metadata
│                 │  Layout: Preserve spatial relationships
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. DoclingDocument  │  Format: Hierarchical JSON structure
│     Assembly    │  Elements: Typed document elements (heading, paragraph, etc.)
│                 │  Metadata: Format, page count, processing timestamp
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  6. Caching     │  Storage: Redis (TTL: 1 hour)
│                 │  Key: doc:{sha256(source)}
│                 │  Value: Serialized DoclingDocument JSON
└─────────────────┘
```

### 4.2 Format Detection and Routing

**Format Detection Strategy:**

```python
# Format Detection Implementation

import magic  # libmagic for MIME type detection
from pathlib import Path

class FormatDetector:
    """Detect document format from multiple signals."""

    MIME_TO_FORMAT = {
        "application/pdf": "pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
        "text/html": "html",
        "image/png": "image",
        "image/jpeg": "image"
    }

    def detect_format(self, source: str, hint: str = None) -> str:
        """
        Detect document format using multiple signals.

        Detection Priority:
        1. Explicit hint (if provided and valid)
        2. MIME type detection (libmagic)
        3. File extension
        4. Content sniffing (first 4KB)

        Args:
            source: File path or URL
            hint: Optional format override

        Returns:
            str: Detected format (pdf, docx, etc.)
        """
        # Priority 1: Explicit hint
        if hint and hint in self.MIME_TO_FORMAT.values():
            return hint

        # Priority 2: MIME type detection
        mime_type = magic.from_file(source, mime=True)
        if mime_type in self.MIME_TO_FORMAT:
            return self.MIME_TO_FORMAT[mime_type]

        # Priority 3: Extension
        ext = Path(source).suffix.lower().lstrip('.')
        if ext in self.MIME_TO_FORMAT.values():
            return ext

        # Priority 4: Content sniffing
        return self._sniff_content(source)

    def _sniff_content(self, source: str) -> str:
        """Detect format by examining file content."""
        with open(source, 'rb') as f:
            header = f.read(4096)

        # PDF signature
        if header.startswith(b'%PDF'):
            return 'pdf'

        # ZIP-based formats (DOCX, PPTX, XLSX)
        if header.startswith(b'PK\x03\x04'):
            # Further inspection of ZIP contents required
            return self._detect_ooxml_format(source)

        # Fallback
        return 'unknown'
```

### 4.3 OCR Integration (Tesseract)

**OCR Architecture:**

```python
# OCR Integration for Scanned PDFs and Images

import pytesseract
from PIL import Image

class OCRProcessor:
    """Tesseract OCR integration for text extraction."""

    def __init__(self):
        self.tesseract_config = {
            "lang": "eng",  # Primary language
            "oem": 3,  # LSTM OCR engine mode
            "psm": 3   # Automatic page segmentation
        }

    async def extract_text_from_image(
        self,
        image_path: str,
        language: str = "eng"
    ) -> str:
        """
        Extract text from image using Tesseract OCR.

        Architecture:
        1. Load image (PIL)
        2. Preprocessing (deskew, denoise, binarization)
        3. OCR extraction (Tesseract)
        4. Post-processing (spell check, formatting)

        Args:
            image_path: Path to image file
            language: OCR language (default: English)

        Returns:
            str: Extracted text
        """
        # Load image
        image = Image.open(image_path)

        # Preprocessing (enhance OCR accuracy)
        processed_image = self._preprocess_image(image)

        # OCR extraction (run in thread pool - CPU intensive)
        text = await self._run_in_executor(
            pytesseract.image_to_string,
            processed_image,
            lang=language,
            config=self._build_tesseract_config()
        )

        return text

    def _preprocess_image(self, image: Image) -> Image:
        """
        Preprocess image for better OCR accuracy.

        Steps:
        - Convert to grayscale
        - Increase contrast
        - Denoise (Gaussian blur)
        - Binarization (Otsu's method)
        """
        # Implementation uses PIL image operations
        pass
```

---

## 5. Storage Architecture

### 5.1 PostgreSQL Schema Design

**NOTE: Phase 1 uses Qdrant for knowledge graph storage only. PostgreSQL integration deferred to Phase 2.**

### 5.2 Qdrant Vector Database Architecture

**Qdrant Collection Schema:**

```python
# Qdrant Collection Configuration for LightRAG

from qdrant_client import QdrantClient
from qdrant_client.models import (
    VectorParams,
    Distance,
    CollectionInfo
)

class QdrantKnowledgeGraphStorage:
    """Qdrant storage backend for LightRAG knowledge graphs."""

    def __init__(self, client: QdrantClient):
        self.client = client
        self.collection_prefix = "docling_mcp_"
        self.embedding_dim = 1024  # bge-m3:567m embedding dimension

    async def initialize_collections(self):
        """
        Create Qdrant collections for knowledge graph storage.

        Collections:
        1. docling_mcp_entities: Entity vectors (fine-grained retrieval)
        2. docling_mcp_relations: Relationship vectors
        3. docling_mcp_themes: High-level theme vectors (coarse-grained retrieval)
        """
        # Entity collection
        await self.client.create_collection(
            collection_name=f"{self.collection_prefix}entities",
            vectors_config=VectorParams(
                size=self.embedding_dim,
                distance=Distance.COSINE
            ),
            # Additional configuration
            shard_number=2,  # Sharding for scalability
            replication_factor=1  # Single-node deployment
        )

        # Relation collection
        await self.client.create_collection(
            collection_name=f"{self.collection_prefix}relations",
            vectors_config=VectorParams(
                size=self.embedding_dim,
                distance=Distance.COSINE
            )
        )

        # Theme collection (high-level concepts)
        await self.client.create_collection(
            collection_name=f"{self.collection_prefix}themes",
            vectors_config=VectorParams(
                size=self.embedding_dim,
                distance=Distance.COSINE
            )
        )
```

**Entity Storage Pattern:**

```python
# Entity Vector Storage

from qdrant_client.models import PointStruct

class EntityVectorStorage:
    """Store entity vectors in Qdrant."""

    async def store_entity(
        self,
        entity_id: str,
        entity_text: str,
        entity_type: str,
        embedding: list[float],
        metadata: dict
    ):
        """
        Store entity with vector embedding in Qdrant.

        Point Structure:
        - id: entity_id (UUID)
        - vector: embedding (1024-dim float array)
        - payload: {
            text: entity_text,
            type: entity_type (PERSON, ORG, CONCEPT, etc.),
            document_id: source document,
            confidence: extraction confidence score,
            metadata: additional context
          }

        Args:
            entity_id: Unique entity identifier
            entity_text: Entity name/description
            entity_type: Entity category (PERSON, ORG, etc.)
            embedding: Vector representation (from bge-m3 model)
            metadata: Additional entity metadata
        """
        point = PointStruct(
            id=entity_id,
            vector=embedding,
            payload={
                "text": entity_text,
                "type": entity_type,
                "document_id": metadata.get("document_id"),
                "confidence": metadata.get("confidence", 0.0),
                "created_at": datetime.utcnow().isoformat(),
                **metadata
            }
        )

        await self.client.upsert(
            collection_name="docling_mcp_entities",
            points=[point]
        )
```

**Relationship Storage Pattern:**

```python
# Relationship Vector Storage

class RelationshipVectorStorage:
    """Store relationship vectors in Qdrant."""

    async def store_relationship(
        self,
        relation_id: str,
        subject_entity_id: str,
        predicate: str,
        object_entity_id: str,
        embedding: list[float],
        metadata: dict
    ):
        """
        Store relationship with vector embedding in Qdrant.

        Relationship Representation:
        - Triple: (subject, predicate, object)
        - Example: (Albert Einstein, WORKED_AT, Princeton University)
        - Vector: Embedding of relationship text representation

        Point Structure:
        - id: relation_id (UUID)
        - vector: embedding (1024-dim)
        - payload: {
            subject_id: entity_id of subject,
            predicate: relationship type,
            object_id: entity_id of object,
            confidence: extraction confidence,
            document_id: source document
          }
        """
        relation_text = f"{subject_entity_id} {predicate} {object_entity_id}"

        point = PointStruct(
            id=relation_id,
            vector=embedding,
            payload={
                "subject_id": subject_entity_id,
                "predicate": predicate,
                "object_id": object_entity_id,
                "relation_text": relation_text,
                "confidence": metadata.get("confidence", 0.0),
                "document_id": metadata.get("document_id"),
                "created_at": datetime.utcnow().isoformat()
            }
        )

        await self.client.upsert(
            collection_name="docling_mcp_relations",
            points=[point]
        )
```

### 5.3 Redis Caching Architecture

**Redis Data Structures:**

```python
# Redis Session Management and Caching

from redis.asyncio import Redis
import json

class RedisCacheManager:
    """Redis-based caching for MCP session state and document caching."""

    def __init__(self, redis_client: Redis):
        self.redis = redis_client
        self.default_ttl = 3600  # 1 hour

    # Session Management
    async def store_session(
        self,
        session_id: str,
        session_data: dict,
        ttl: int = 3600
    ):
        """
        Store MCP session state in Redis.

        Key Pattern: session:{session_id}
        Value: JSON-serialized session data
        TTL: 1 hour (configurable)

        Session Data:
        - user_id: MCP client identifier
        - active_documents: List of document IDs in session
        - preferences: Client preferences (format, language, etc.)
        - created_at: Session creation timestamp
        """
        key = f"session:{session_id}"
        value = json.dumps(session_data)
        await self.redis.setex(key, ttl, value)

    # Document Caching
    async def cache_document(
        self,
        document_id: str,
        document_data: dict,
        ttl: int = 3600
    ):
        """
        Cache converted DoclingDocument in Redis.

        Key Pattern: doc:{document_id}
        Value: JSON-serialized DoclingDocument
        TTL: 1 hour (avoid re-converting same document)

        Use Case: Client requests same document multiple times
        """
        key = f"doc:{document_id}"
        value = json.dumps(document_data)
        await self.redis.setex(key, ttl, value)

    async def get_cached_document(self, document_id: str) -> dict | None:
        """Retrieve cached document if exists."""
        key = f"doc:{document_id}"
        value = await self.redis.get(key)
        return json.loads(value) if value else None

    # Rate Limiting (per client)
    async def check_rate_limit(
        self,
        client_id: str,
        limit: int = 100,
        window: int = 60
    ) -> bool:
        """
        Check if client has exceeded rate limit.

        Key Pattern: ratelimit:{client_id}
        Algorithm: Sliding window counter
        Limit: 100 requests per minute (configurable)

        Returns:
            bool: True if allowed, False if rate limited
        """
        key = f"ratelimit:{client_id}"
        current = await self.redis.incr(key)

        if current == 1:
            # First request in window, set expiry
            await self.redis.expire(key, window)

        return current <= limit
```

**Cache Invalidation Strategy:**

```python
# Cache Invalidation Patterns

class CacheInvalidation:
    """Cache invalidation strategies for Redis."""

    # Strategy 1: TTL-based expiration (primary)
    # - All cached documents expire after 1 hour
    # - Session data expires after 1 hour of inactivity

    # Strategy 2: Event-based invalidation
    async def invalidate_document_cache(self, document_id: str):
        """
        Invalidate document cache when document is updated.

        Use Case: Document re-processed with different options
        """
        key = f"doc:{document_id}"
        await self.redis.delete(key)

    # Strategy 3: Pattern-based invalidation
    async def invalidate_session_caches(self, session_id: str):
        """
        Invalidate all caches associated with session.

        Pattern: session:{session_id}:*
        """
        pattern = f"session:{session_id}:*"
        keys = await self.redis.keys(pattern)
        if keys:
            await self.redis.delete(*keys)
```

---

## 6. Security Architecture

### 6.1 Authentication Flow (Phase 2 - OAuth2)

**NOTE: Phase 1 uses network-level security only (no authentication). OAuth2 deferred to Phase 2.**

**Future OAuth2 Architecture (Phase 2):**

```python
# OAuth2 Authentication (Phase 2 Implementation)

from fastmcp.middleware import oauth2_middleware

# OAuth2 configuration (deferred to Phase 2)
mcp.add_middleware(
    oauth2_middleware(
        providers=["google", "github"],
        callback_url="http://hx-docling-mcp-server.hx.dev.local:8000/oauth/callback",
        scopes=["openid", "profile", "email"]
    )
)
```

### 6.2 Authorization Patterns (Phase 2)

**NOTE: Phase 1 has no authorization (all clients have full access). RBAC deferred to Phase 2.**

### 6.3 Data Encryption (In-Transit and At-Rest)

**In-Transit Encryption:**

**Phase 1 (Optional TLS):**
- **Internal Network**: No TLS required (192.168.10.0/24 isolated)
- **Optional HTTPS**: Port 8443 with self-signed certificate
- **Future**: Certificate from hx-ca-server (internal CA)

**TLS Configuration (Optional):**

```python
# TLS Configuration (Optional for Phase 1)

from fastmcp import FastMCP

mcp = FastMCP("docling-mcp-server")

# Add HTTPS transport (optional)
mcp.add_transport(
    "https",
    port=8443,
    ssl_certfile="/etc/docling-mcp/certs/server.crt",
    ssl_keyfile="/etc/docling-mcp/certs/server.key"
)
```

**At-Rest Encryption:**

**Sensitive Data Protection:**
- **Credentials**: Stored in Ansible Vault (encrypted)
- **Session Data**: Redis (no encryption in Phase 1, isolated network)
- **Document Cache**: Redis (no encryption in Phase 1, temporary data)
- **Knowledge Graphs**: Qdrant (no encryption in Phase 1, derived data)

**Phase 2 Considerations:**
- Qdrant collection encryption (if sensitive documents)
- Redis encryption (if session data contains PII)

### 6.4 Secrets Management (Ansible Vault)

**Ansible Vault Integration:**

```yaml
# /home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml
# Encrypted with: ansible-vault encrypt credentials.yml

---
# Service Account
samba_account: "docling-mcp@hx.dev.local"
samba_password: "[SEE VAULT: vault/credentials.yml]"  # Standard HX-Infrastructure service account password

# LiteLLM API Key (if authentication enabled)
litellm_api_key: "sk-docling-mcp-prod-xxxxx"  # Generated API key

# Redis Password (if authentication enabled)
redis_password: "redis-password-here"  # Generated password

# MCP API Keys (Phase 2 - OAuth2 client secrets)
mcp_oauth_client_id: "docling-mcp-client-id"
mcp_oauth_client_secret: "oauth-client-secret-here"

# Key Rotation Schedule
api_key_rotation_due: "2026-02-27"  # 90-day rotation
```

**Vault Access Pattern:**

```bash
# Vault Password File
/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/.vault_password

# Decrypt credentials
ansible-vault decrypt credentials.yml --vault-password-file .vault_password

# Edit credentials
ansible-vault edit credentials.yml --vault-password-file .vault_password

# Encrypt credentials
ansible-vault encrypt credentials.yml --vault-password-file .vault_password
```

**Environment Variable Loading:**

```python
# Load Secrets from Ansible Vault

import subprocess
import yaml
import os

def load_vault_credentials():
    """
    Load credentials from Ansible Vault.

    Architecture:
    1. Read vault password from .vault_password file
    2. Decrypt credentials.yml using ansible-vault
    3. Load YAML into environment variables
    4. Clear decrypted credentials from memory
    """
    vault_file = "/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml"
    vault_password_file = "/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/.vault_password"

    # Decrypt vault (subprocess call to ansible-vault)
    result = subprocess.run(
        [
            "ansible-vault", "decrypt",
            vault_file,
            "--vault-password-file", vault_password_file,
            "--output", "-"  # Output to stdout
        ],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        raise RuntimeError(f"Failed to decrypt vault: {result.stderr}")

    # Load credentials
    credentials = yaml.safe_load(result.stdout)

    # Set environment variables
    os.environ["SAMBA_ACCOUNT"] = credentials["samba_account"]
    os.environ["SAMBA_PASSWORD"] = credentials["samba_password"]
    os.environ["LITELLM_API_KEY"] = credentials.get("litellm_api_key", "")
    os.environ["REDIS_PASSWORD"] = credentials.get("redis_password", "")

    # Clear decrypted credentials from memory
    del credentials
    del result
```

---

## 7. Performance Architecture

### 7.1 Concurrency Model (Asyncio Workers)

**Asyncio Event Loop Architecture:**

```python
# Asyncio Worker Configuration

import asyncio
from concurrent.futures import ThreadPoolExecutor

class MCPServerRuntime:
    """MCP server runtime with asyncio event loop."""

    def __init__(self):
        # Event loop (main thread)
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        # Thread pool for CPU-bound operations
        self.cpu_executor = ThreadPoolExecutor(
            max_workers=4,  # Matches 2-4 core allocation
            thread_name_prefix="docling-cpu-"
        )

        # Concurrency limits
        self.request_semaphore = asyncio.Semaphore(10)  # Max 10 concurrent requests

        # Connection pools
        self.litellm_pool = AsyncLiteLLMPool(max_connections=20)
        self.qdrant_pool = AsyncQdrantPool(max_connections=10)
        self.redis_pool = AsyncRedisPool(max_connections=10)

    async def handle_request(self, request: MCPRequest) -> MCPResponse:
        """
        Handle MCP request with concurrency control.

        Architecture:
        - Semaphore: Limit concurrent requests (avoid overload)
        - Thread pool: CPU-bound operations (docling processing)
        - Connection pools: Reuse connections to external services
        """
        async with self.request_semaphore:
            # Parse request (I/O-bound, async)
            params = await self._parse_request(request)

            # Process document (CPU-bound, thread pool)
            doc = await self.loop.run_in_executor(
                self.cpu_executor,
                self._process_document_sync,
                params
            )

            # Cache result (I/O-bound, async)
            await self.redis_pool.set(f"doc:{doc.id}", doc.to_json())

            return MCPResponse(data=doc)
```

### 7.2 Resource Allocation Strategy

**Resource Limits:**

| Resource | Allocation | Rationale |
|----------|------------|-----------|
| **CPU** | 2-4 cores | Document processing is CPU-intensive (PDF parsing, OCR) |
| **Memory** | 4-8GB | Docling library + LightRAG + caching (documents in memory during processing) |
| **Disk** | 10GB | Application (500MB) + cache (5GB) + logs (1GB) + models cached (3GB) |
| **Network** | Internal (1 Gbps) | All dependencies on internal network (low latency) |

**Systemd Resource Limits:**

```ini
# /etc/systemd/system/docling-mcp.service

[Service]
# CPU limits
CPUQuota=400%  # Max 4 cores (400% of 1 core)
CPUWeight=100  # Standard priority

# Memory limits
MemoryMax=8G  # Hard limit: 8GB
MemoryHigh=6G  # Soft limit: 6GB (throttle if exceeded)

# I/O limits
IOWeight=100  # Standard I/O priority
```

### 7.3 Caching Strategies

**Multi-Level Caching:**

```
┌────────────────────────────────────────────────────────────────┐
│                    Caching Architecture                        │
└────────────────────────────────────────────────────────────────┘

Level 1: Application Cache (In-Memory)
┌─────────────────────────────────────────┐
│  LRU Cache (128MB max)                  │
│  - Recent DoclingDocuments (last 50)    │
│  - Frequently accessed entities         │
│  - Session metadata                     │
│  Eviction: LRU (Least Recently Used)    │
│  TTL: None (evicted by size limit)      │
└─────────────────────────────────────────┘
         │ Miss
         ▼
Level 2: Distributed Cache (Redis)
┌─────────────────────────────────────────┐
│  Redis Cache (2GB allocated)            │
│  - All converted documents (1 hour TTL) │
│  - Session state (1 hour TTL)           │
│  - Rate limit counters (1 min TTL)      │
│  Eviction: TTL-based expiration         │
└─────────────────────────────────────────┘
         │ Miss
         ▼
Level 3: Source/Recomputation
┌─────────────────────────────────────────┐
│  Reprocess Document                     │
│  - Download from source (if URL)        │
│  - Convert via docling library          │
│  - Store in Level 2 (Redis)             │
│  - Store in Level 1 (memory)            │
└─────────────────────────────────────────┘
```

**Cache Implementation:**

```python
# Multi-Level Caching Implementation

from functools import lru_cache
from cachetools import LRUCache

class MultiLevelCache:
    """Multi-level caching for document processing."""

    def __init__(self, redis_client):
        # Level 1: In-memory LRU cache
        self.memory_cache = LRUCache(maxsize=50)  # Last 50 documents

        # Level 2: Redis distributed cache
        self.redis = redis_client

    async def get_document(self, document_id: str) -> DoclingDocument | None:
        """
        Retrieve document with multi-level cache lookup.

        Lookup Order:
        1. Memory cache (fastest)
        2. Redis cache (fast)
        3. Recompute (slowest)
        """
        # Level 1: Memory cache
        if document_id in self.memory_cache:
            return self.memory_cache[document_id]

        # Level 2: Redis cache
        cached = await self.redis.get(f"doc:{document_id}")
        if cached:
            doc = DoclingDocument.from_json(cached)
            # Populate memory cache
            self.memory_cache[document_id] = doc
            return doc

        # Level 3: Cache miss (caller must recompute)
        return None

    async def store_document(
        self,
        document_id: str,
        document: DoclingDocument,
        ttl: int = 3600
    ):
        """
        Store document in multi-level cache.

        Storage:
        1. Memory cache (immediate access)
        2. Redis cache (distributed access, TTL)
        """
        # Level 1: Memory cache
        self.memory_cache[document_id] = document

        # Level 2: Redis cache
        await self.redis.setex(
            f"doc:{document_id}",
            ttl,
            document.to_json()
        )
```

### 7.4 Rate Limiting Architecture

**Rate Limiting Strategy:**

```python
# Rate Limiting Implementation

class RateLimiter:
    """Rate limiting for MCP clients."""

    def __init__(self, redis_client):
        self.redis = redis_client
        self.limits = {
            "default": (100, 60),  # 100 requests per minute
            "heavy": (10, 60)      # 10 requests per minute for CPU-intensive tools
        }

    async def check_limit(
        self,
        client_id: str,
        tool_name: str
    ) -> tuple[bool, dict]:
        """
        Check if client has exceeded rate limit.

        Rate Limit Tiers:
        - Default: 100 req/min (general tools)
        - Heavy: 10 req/min (convert_pdf, convert_docx - CPU-intensive)

        Returns:
            (allowed, metadata): Tuple of (bool, rate limit metadata)
        """
        # Determine limit tier
        limit_tier = "heavy" if tool_name.startswith("convert") else "default"
        max_requests, window = self.limits[limit_tier]

        # Sliding window counter
        key = f"ratelimit:{client_id}:{tool_name}"
        current_count = await self.redis.incr(key)

        if current_count == 1:
            # First request in window, set expiry
            await self.redis.expire(key, window)

        # Check limit
        allowed = current_count <= max_requests

        metadata = {
            "limit": max_requests,
            "remaining": max(0, max_requests - current_count),
            "reset_in": await self.redis.ttl(key)
        }

        return allowed, metadata
```

---

## 8. Deployment Architecture

### 8.1 Systemd Service Architecture

**Systemd Unit File:**

```ini
# /etc/systemd/system/docling-mcp.service

[Unit]
Description=Docling MCP Server - Document Processing Gateway
Documentation=https://github.com/Hana-X-AI/HX-Infrastructure/nodes/hx-docling-mcp-server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=docling-mcp@hx.dev.local
Group=domain users@hx.dev.local

# Working directory
WorkingDirectory=/opt/docling-mcp

# Environment
Environment="PATH=/opt/docling-mcp/venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/etc/docling-mcp/.env

# Pre-start validation (inline commands, not separate scripts)
ExecStartPre=/bin/bash -c 'test -n "$LITELLM_BASE_URL"'
ExecStartPre=/usr/bin/curl -f http://hx-litellm-server.hx.dev.local:4000/health
ExecStartPre=/bin/bash -c 'test -r /etc/docling-mcp/.env'
ExecStartPre=/bin/bash -c 'test $(df /var/lib/docling-mcp | tail -1 | awk "{print \$4}") -gt 1048576'

# Start command
ExecStart=/opt/docling-mcp/venv/bin/python -m docling_mcp.server

# Reload signal
ExecReload=/bin/kill -HUP $MAINPID

# Restart policy
Restart=on-failure
RestartSec=10
StartLimitBurst=3
StartLimitIntervalSec=60

# Output
StandardOutput=journal
StandardError=journal
SyslogIdentifier=docling-mcp

# Security hardening
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/docling-mcp /var/log/docling-mcp
ReadOnlyPaths=/etc/docling-mcp

# Resource limits
CPUQuota=400%
MemoryMax=8G
MemoryHigh=6G
TasksMax=256

[Install]
WantedBy=multi-user.target
```

**Service Management Commands:**

```bash
# Start service
sudo systemctl start docling-mcp.service

# Enable on boot
sudo systemctl enable docling-mcp.service

# Check status
sudo systemctl status docling-mcp.service

# View logs
sudo journalctl -u docling-mcp.service -f

# Reload configuration
sudo systemctl reload docling-mcp.service

# Restart service
sudo systemctl restart docling-mcp.service

# Stop service
sudo systemctl stop docling-mcp.service
```

### 8.2 Process Management

**Process Lifecycle:**

```
┌────────────────────────────────────────────────────────────────┐
│                    Service Lifecycle                           │
└────────────────────────────────────────────────────────────────┘

1. systemd starts service
   └─> ExecStartPre validation checks
       ├─> Check LITELLM_BASE_URL set
       ├─> Verify LiteLLM health (curl)
       ├─> Verify .env readable
       └─> Verify disk space (>1GB available)

2. ExecStart launches Python process
   └─> /opt/docling-mcp/venv/bin/python -m docling_mcp.server
       ├─> Load configuration (.env, vault)
       ├─> Initialize FastMCP framework
       ├─> Connect to dependencies (Redis, Qdrant, LiteLLM)
       ├─> Register 19 MCP tools
       └─> Start transports (HTTP:8000, SSE, stdio)

3. Service running
   └─> Handles MCP requests
       ├─> HTTP transport (primary)
       ├─> SSE transport (streaming)
       └─> stdio transport (process I/O)

4. Health checks (systemd watchdog - optional Phase 2)
   └─> Periodic health endpoint check
       └─> If unhealthy, restart service

5. Graceful shutdown (on stop/restart)
   └─> SIGTERM signal
       ├─> Complete in-flight requests (30s timeout)
       ├─> Close database connections
       ├─> Flush logs
       └─> Exit

6. Failure handling
   └─> Restart=on-failure
       ├─> RestartSec=10 (wait 10s before restart)
       └─> StartLimitBurst=3 (max 3 restarts in 60s)
```

### 8.3 Logging Architecture

**Logging Configuration:**

```python
# /opt/docling-mcp/config/logging.conf

import logging
from logging.handlers import RotatingFileHandler

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "standard": {
            "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
        },
        "json": {
            "format": "%(message)s",  # JSON formatter (structured logs)
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "INFO",
            "formatter": "standard",
            "stream": "ext://sys.stdout"
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "standard",
            "filename": "/var/log/docling-mcp/docling-mcp.log",
            "maxBytes": 10485760,  # 10MB
            "backupCount": 30,  # Keep 30 days
            "encoding": "utf8"
        },
        "error_file": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "ERROR",
            "formatter": "standard",
            "filename": "/var/log/docling-mcp/error.log",
            "maxBytes": 10485760,
            "backupCount": 30
        },
        "access_file": {
            "class": "logging.handlers.RotatingFileHandler",
            "level": "INFO",
            "formatter": "json",
            "filename": "/var/log/docling-mcp/access.log",
            "maxBytes": 10485760,
            "backupCount": 30
        }
    },
    "loggers": {
        "": {  # Root logger
            "handlers": ["console", "file", "error_file"],
            "level": "INFO",
            "propagate": False
        },
        "access": {  # Access log
            "handlers": ["access_file"],
            "level": "INFO",
            "propagate": False
        }
    }
}
```

**Log Rotation:**

```bash
# /etc/logrotate.d/docling-mcp

/var/log/docling-mcp/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 docling-mcp@hx.dev.local domain users@hx.dev.local
    sharedscripts
    postrotate
        /bin/systemctl reload docling-mcp.service > /dev/null 2>&1 || true
    endscript
}
```

### 8.4 Monitoring Integration Points

**Health Check Endpoint:**

```python
# Health Check Implementation

from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring.

    Checks:
    1. Service alive (HTTP 200 response)
    2. Dependencies reachable (LiteLLM, Qdrant, Redis)
    3. Resource usage (CPU, memory within limits)
    4. Disk space (>1GB available)

    Returns:
        dict: Health status and details
    """
    status = "healthy"
    checks = {}

    # Check LiteLLM
    try:
        response = await litellm_client.health()
        checks["litellm"] = "healthy"
    except Exception as e:
        checks["litellm"] = f"unhealthy: {str(e)}"
        status = "degraded"

    # Check Qdrant
    try:
        await qdrant_client.get_collections()
        checks["qdrant"] = "healthy"
    except Exception as e:
        checks["qdrant"] = f"unhealthy: {str(e)}"
        status = "degraded"

    # Check Redis
    try:
        await redis_client.ping()
        checks["redis"] = "healthy"
    except Exception as e:
        checks["redis"] = f"unhealthy: {str(e)}"
        status = "degraded"

    # Check disk space
    disk_free = shutil.disk_usage("/var/lib/docling-mcp").free
    if disk_free < 1_000_000_000:  # <1GB
        checks["disk"] = f"low: {disk_free / 1e9:.2f}GB"
        status = "degraded"
    else:
        checks["disk"] = "healthy"

    return {
        "status": status,
        "checks": checks,
        "timestamp": datetime.utcnow().isoformat()
    }
```

**Monitoring Endpoints (Phase 2 - Prometheus):**

```python
# Prometheus Metrics (Phase 2)

from prometheus_client import Counter, Histogram, Gauge

# Request metrics
request_count = Counter(
    "docling_mcp_requests_total",
    "Total MCP requests",
    ["tool", "status"]
)

request_duration = Histogram(
    "docling_mcp_request_duration_seconds",
    "Request duration in seconds",
    ["tool"]
)

# Resource metrics
active_requests = Gauge(
    "docling_mcp_active_requests",
    "Number of active requests"
)

cache_hits = Counter(
    "docling_mcp_cache_hits_total",
    "Total cache hits",
    ["level"]  # memory, redis
)
```

---

## 9. Integration Architecture

### 9.1 LiteLLM Gateway Integration

**Integration Pattern:**

```python
# LiteLLM Client Integration

from litellm import acompletion, aembedding
import asyncio

class LiteLLMClient:
    """Async client for LiteLLM Gateway."""

    def __init__(self, base_url: str, api_key: str = None):
        self.base_url = base_url  # http://hx-litellm-server.hx.dev.local:4000
        self.api_key = api_key

        # Model routing configuration
        self.model_routing = {
            "entity_extraction": "ollama/gemma3:27b",
            "entity_extraction_fallback": "ollama/gpt-oss:20b",
            "docling_processing": "ollama/granite-docling:258m",
            "embedding": "ollama/bge-m3:567m"
        }

    async def extract_entities(
        self,
        text: str,
        model: str = None
    ) -> list[dict]:
        """
        Extract entities from text using LLM via LiteLLM.

        Model Routing:
        - Primary: gemma3:27b (entity extraction quality)
        - Fallback: gpt-oss:20b (if gemma3 unavailable)
        - NOT USED: granite-docling:258m (too small for entity extraction)

        Args:
            text: Text to extract entities from
            model: Override model selection

        Returns:
            list[dict]: Extracted entities with types and confidence
        """
        model = model or self.model_routing["entity_extraction"]

        # Construct prompt for entity extraction
        prompt = self._build_entity_extraction_prompt(text)

        try:
            # Call LiteLLM (OpenAI-compatible API)
            response = await acompletion(
                model=model,
                messages=[
                    {"role": "system", "content": "You are an entity extraction expert."},
                    {"role": "user", "content": prompt}
                ],
                api_base=self.base_url,
                api_key=self.api_key,
                temperature=0.1,  # Low temperature for consistent extraction
                max_tokens=2000
            )

            # Parse entity extraction response
            entities = self._parse_entity_response(response)
            return entities

        except Exception as e:
            # Fallback to alternative model
            if model == self.model_routing["entity_extraction"]:
                return await self.extract_entities(
                    text,
                    model=self.model_routing["entity_extraction_fallback"]
                )
            raise

    async def generate_embeddings(
        self,
        texts: list[str],
        model: str = None
    ) -> list[list[float]]:
        """
        Generate embeddings for texts using bge-m3 model.

        Model: ollama/bge-m3:567m (1024-dim embeddings)

        Args:
            texts: List of texts to embed
            model: Override model selection

        Returns:
            list[list[float]]: Embeddings (1024-dim vectors)
        """
        model = model or self.model_routing["embedding"]

        response = await aembedding(
            model=model,
            input=texts,
            api_base=self.base_url,
            api_key=self.api_key
        )

        # Extract embeddings from response
        embeddings = [item["embedding"] for item in response["data"]]
        return embeddings
```

**Error Handling and Retry Logic:**

```python
# LiteLLM Error Handling

from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

class LiteLLMClient:

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((ConnectionError, TimeoutError))
    )
    async def _call_with_retry(self, *args, **kwargs):
        """
        Call LiteLLM with retry logic.

        Retry Strategy:
        - Max attempts: 3
        - Backoff: 1s, 2s, 4s (exponential)
        - Retry on: ConnectionError, TimeoutError
        - Fail fast on: 4xx client errors (invalid requests)
        """
        return await acompletion(*args, **kwargs)
```

### 9.2 Qdrant Integration

**Qdrant Client Integration:**

```python
# Qdrant Client Integration

from qdrant_client import AsyncQdrantClient
from qdrant_client.models import PointStruct, Filter, FieldCondition

class QdrantKnowledgeGraphClient:
    """Async client for Qdrant knowledge graph storage."""

    def __init__(self, host: str, port: int):
        self.client = AsyncQdrantClient(
            host=host,  # hx-qdrant-server.hx.dev.local
            port=port,  # 6333
            grpc_port=6334,
            prefer_grpc=True  # Use gRPC for better performance
        )
        self.collection_prefix = "docling_mcp_"

    async def store_entities(
        self,
        entities: list[dict],
        embeddings: list[list[float]],
        document_id: str
    ):
        """
        Store entities with embeddings in Qdrant.

        Collection: docling_mcp_entities
        Point Structure:
        - id: entity_id (UUID)
        - vector: embedding (1024-dim)
        - payload: {
            text: entity_text,
            type: entity_type (PERSON, ORG, CONCEPT),
            document_id: source document,
            confidence: extraction confidence
          }
        """
        points = []
        for entity, embedding in zip(entities, embeddings):
            point = PointStruct(
                id=entity["id"],
                vector=embedding,
                payload={
                    "text": entity["text"],
                    "type": entity["type"],
                    "document_id": document_id,
                    "confidence": entity["confidence"],
                    "created_at": datetime.utcnow().isoformat()
                }
            )
            points.append(point)

        await self.client.upsert(
            collection_name=f"{self.collection_prefix}entities",
            points=points
        )

    async def query_entities(
        self,
        query_vector: list[float],
        limit: int = 10,
        document_id: str = None
    ) -> list[dict]:
        """
        Query similar entities using vector search.

        Query Parameters:
        - query_vector: Query embedding (1024-dim)
        - limit: Max results to return
        - document_id: Filter by source document (optional)

        Returns:
            list[dict]: Similar entities with similarity scores
        """
        # Build filter if document_id provided
        filter = None
        if document_id:
            filter = Filter(
                must=[
                    FieldCondition(
                        key="document_id",
                        match={"value": document_id}
                    )
                ]
            )

        # Perform vector search
        results = await self.client.search(
            collection_name=f"{self.collection_prefix}entities",
            query_vector=query_vector,
            limit=limit,
            query_filter=filter
        )

        return [
            {
                "id": result.id,
                "score": result.score,
                **result.payload
            }
            for result in results
        ]
```

### 9.3 Redis Integration

**Redis Connection Pool:**

```python
# Redis Connection Pool

from redis.asyncio import Redis, ConnectionPool

class RedisClientManager:
    """Redis client with connection pooling."""

    def __init__(self, host: str, port: int, password: str = None):
        # Connection pool (max 10 connections)
        self.pool = ConnectionPool(
            host=host,  # hx-redis-server.hx.dev.local
            port=port,  # 6379
            password=password,
            db=0,
            max_connections=10,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True
        )

        self.client = Redis(connection_pool=self.pool)

    async def close(self):
        """Close connection pool."""
        await self.client.close()
        await self.pool.disconnect()
```

---

## 10. Scalability and HA Considerations

### 10.1 Horizontal Scaling Approach (Phase 2)

**Current Architecture (Phase 1):**
- **Single-Process Deployment**: One docling-mcp.service instance on hx-docling-mcp-server
- **Rationale**: Acceptable for Phase 1 throughput requirements, simplifies architecture

**Future Horizontal Scaling (Phase 2):**

```
┌──────────────────────────────────────────────────────────────┐
│               Load Balancer (HAProxy/nginx)                  │
│                  (192.168.10.xxx:8000)                       │
└────────────┬──────────────┬──────────────┬──────────────────┘
             │              │              │
    ┌────────▼────────┐ ┌──▼──────────┐ ┌─▼────────────────┐
    │  MCP Instance 1 │ │ Instance 2  │ │  Instance 3      │
    │  (.217:8001)    │ │ (.217:8002) │ │  (.218:8001)     │
    └────────┬────────┘ └──┬──────────┘ └──┬───────────────┘
             │             │               │
             └─────────────┴───────────────┘
                          │
                ┌─────────▼─────────┐
                │  Shared State     │
                │  - Redis (shared) │
                │  - Qdrant (shared)│
                └───────────────────┘
```

**Stateless Design Principles:**
- **No Local State**: All session state in Redis (shared across instances)
- **Shared Knowledge Graphs**: Qdrant collections shared by all instances
- **Idempotent Operations**: Safe to retry requests on different instances
- **Load Balancing**: Round-robin or least-connections algorithm

### 10.2 Load Balancing Considerations (Phase 2)

**Load Balancer Configuration (HAProxy Example):**

```haproxy
# HAProxy Configuration (Phase 2)

frontend mcp_frontend
    bind *:8000
    mode http
    default_backend mcp_backend

backend mcp_backend
    mode http
    balance roundrobin
    option httpchk GET /health

    server mcp1 hx-docling-mcp-server.hx.dev.local:8001 check
    server mcp2 hx-docling-mcp-server.hx.dev.local:8002 check
    server mcp3 hx-crawl4ai-server.hx.dev.local:8001 check
```

### 10.3 Failover Strategies (Phase 2)

**Automatic Failover:**
- **Health Checks**: HAProxy checks `/health` endpoint every 5 seconds
- **Failure Detection**: 3 consecutive failed health checks → instance removed
- **Auto-Recovery**: Instance re-added when health checks pass
- **Connection Draining**: In-flight requests complete before instance removed

### 10.4 State Management for Distributed Deployment (Phase 2)

**Session State Management:**
- **Storage**: Redis (shared across all MCP instances)
- **Session Affinity**: Not required (stateless instances)
- **Session Replication**: Redis persistence ensures session survival across restarts

**Document Cache Sharing:**
- **Shared Cache**: All instances use same Redis instance for document caching
- **Cache Coherence**: TTL-based expiration ensures consistency
- **No Cache Synchronization Needed**: Redis is single source of truth

---

## 11. Architecture Decision Records

### ADR-001: Embedded Docling Library vs Worker API

**Status:** Accepted
**Date:** 2025-11-27
**Context:** Docling library can be integrated as embedded library (in-process) or via separate worker API (out-of-process).

**Decision:** Use embedded docling library (Option A) for Phase 1.

**Rationale:**
1. **Lower Latency**: No network overhead for worker API calls (significant for large documents)
2. **Simpler Architecture**: Single-process deployment, easier debugging and development
3. **Acceptable Throughput**: Single-process can handle Phase 1 requirements (estimated 10-50 documents/hour)
4. **Easier Deployment**: No separate worker service to deploy and manage
5. **Phase 1 Scope**: Limited to Stages 1-2 (ingestion + knowledge graph), distributed processing not required

**Alternatives Considered:**
- **Worker API (Option B)**: Rejected for Phase 1
  - Pros: Better horizontal scaling, isolated failures
  - Cons: Higher latency, more complex architecture, additional service to deploy
  - Decision: Defer to Phase 2 if throughput requirements increase

**Consequences:**
- **Positive**:
  - Faster time to operational (simpler deployment)
  - Lower operational overhead (one service to monitor)
  - Predictable performance (no network variability)
- **Negative**:
  - Limited horizontal scaling (single-process bottleneck)
  - CPU-intensive operations block event loop (mitigated with thread pool)
  - Must re-architecture for high-volume workloads (Phase 2 consideration)

**Validation:**
- Monitor document processing throughput during Phase 1
- If throughput <10 documents/hour, investigate thread pool tuning
- If Phase 2 requires >100 documents/hour, revisit worker API architecture

---

### ADR-002: Asyncio Event Loop vs Multi-Threading

**Status:** Accepted
**Date:** 2025-11-27
**Context:** MCP server can use asyncio (event loop) or multi-threading for concurrency.

**Decision:** Use asyncio event loop with thread pool for CPU-bound operations.

**Rationale:**
1. **FastMCP Framework**: Built on asyncio, native integration
2. **I/O-Bound Workload**: Majority of operations are I/O (network calls to LiteLLM, Qdrant, Redis)
3. **Async Ecosystem**: Python async clients available for all dependencies (aiohttp, qdrant-client async, redis.asyncio)
4. **Thread Pool for CPU**: Docling processing delegated to thread pool (no event loop blocking)
5. **Memory Efficiency**: Asyncio coroutines lighter than threads (thousands of concurrent requests possible)

**Alternatives Considered:**
- **Multi-Threading**: Rejected
  - Pros: Simpler for CPU-bound operations
  - Cons: GIL limits parallelism, higher memory overhead, thread synchronization complexity
- **Multi-Processing**: Rejected for Phase 1
  - Pros: True parallelism (no GIL), better CPU utilization
  - Cons: IPC overhead, memory duplication, process management complexity

**Consequences:**
- **Positive**:
  - Excellent I/O concurrency (handle many simultaneous requests)
  - Low memory footprint (vs threads)
  - FastMCP framework compatibility
- **Negative**:
  - CPU-bound operations require thread pool (additional complexity)
  - Asyncio debugging harder than synchronous code
  - Must avoid blocking I/O in event loop

**Validation:**
- Load testing with 100 concurrent requests (expected: <500ms p95 latency)
- Monitor event loop lag (target: <10ms)
- CPU utilization should reach 80%+ during docling processing (thread pool effectiveness)

---

### ADR-003: Model Assignment for Entity Extraction

**Status:** Accepted
**Date:** 2025-11-27
**Context:** LightRAG entity extraction requires LLM. Options: granite-docling:258m, gemma3:27b, gpt-oss:20b.

**Decision:** Use gemma3:27b (Ollama1) for entity extraction, NOT granite-docling:258m.

**Rationale:**
1. **Model Size**: granite-docling (258M params) too small for high-quality entity/relationship extraction
2. **LightRAG Recommendation**: 32B+ models recommended for entity extraction quality
3. **Compromise**: gemma3:27b (27B params) best available model on Ollama1
4. **Fallback**: gpt-oss:20b as secondary option if gemma3 unavailable
5. **Granite Specialization**: granite-docling optimized for docling processing ONLY (document structure extraction)

**Alternatives Considered:**
- **granite-docling:258m**: Rejected
  - Pros: Smallest model, fastest inference
  - Cons: Too small for entity extraction quality (LightRAG recommends 32B+)
- **External API (OpenAI GPT-4)**: Rejected for Phase 1
  - Pros: Highest quality entity extraction
  - Cons: External dependency, cost, latency, requires CAIO approval

**Consequences:**
- **Positive**:
  - Better entity extraction quality (27B vs 258M parameters)
  - Acceptable inference latency (Ollama1 has sufficient resources)
  - No external API dependencies
- **Negative**:
  - Higher inference latency vs granite-docling (acceptable trade-off)
  - Ollama1 resource contention (shared with other workloads)
  - May still fall short of LightRAG recommendation (32B+)

**Validation:**
- Test entity extraction quality on sample documents (target: 80%+ precision/recall)
- Measure inference latency (target: <5s per document for entity extraction)
- If quality insufficient, escalate to CAIO for OpenAI API approval (Phase 2)

---

### ADR-004: Qdrant Storage Backend for LightRAG

**Status:** Accepted
**Date:** 2025-11-27
**Context:** LightRAG supports multiple storage backends (Qdrant, Milvus, Neo4j, local).

**Decision:** Use Qdrant as LightRAG storage backend.

**Rationale:**
1. **Infrastructure Availability**: hx-qdrant-server already operational (hx-qdrant-server.hx.dev.local:6333)
2. **LightRAG Support**: Qdrant officially supported by LightRAG framework
3. **Vector Search**: Qdrant optimized for vector similarity search (dual-level retrieval)
4. **Scalability**: Qdrant supports sharding and horizontal scaling (Phase 2)
5. **Operational Simplicity**: No new infrastructure deployment required

**Alternatives Considered:**
- **Milvus**: Rejected
  - Pros: High performance, mature vector database
  - Cons: Not deployed in HX-Infrastructure, additional deployment overhead
- **Neo4j**: Rejected
  - Pros: Native graph database, rich graph queries
  - Cons: Not deployed, higher resource requirements, vector search not primary feature
- **Local Storage (JSON files)**: Rejected
  - Pros: Simplest implementation, no dependencies
  - Cons: No vector search, no scalability, not production-ready

**Consequences:**
- **Positive**:
  - No new infrastructure deployment (leverage existing Qdrant)
  - Vector search optimized for retrieval (dual-level pattern)
  - Production-ready storage backend
- **Negative**:
  - Dependency on Qdrant operational status (mitigated: service already stable)
  - Graph query capabilities limited vs Neo4j (acceptable for Phase 1)
  - Qdrant collection schema must match LightRAG requirements (research validated)

**Validation:**
- Verify LightRAG Qdrant integration during Week 5 (LightRAG implementation)
- Test dual-level retrieval (low-level entities + high-level themes)
- Monitor Qdrant resource usage (target: <2GB for 1000 documents)

---

### ADR-005: Redis Session Management vs Database

**Status:** Accepted
**Date:** 2025-11-27
**Context:** MCP session state can be stored in Redis (cache) or PostgreSQL (database).

**Decision:** Use Redis for session state management in Phase 1.

**Rationale:**
1. **Infrastructure Availability**: hx-redis-server operational (hx-redis-server.hx.dev.local:6379)
2. **Performance**: In-memory storage, <1ms latency (vs 10-50ms for PostgreSQL)
3. **TTL Support**: Native TTL for session expiration (no manual cleanup required)
4. **Session Characteristics**: Ephemeral data (1 hour TTL), no long-term persistence needed
5. **Simplicity**: No schema design, no migrations, no relational modeling

**Alternatives Considered:**
- **PostgreSQL**: Rejected for Phase 1
  - Pros: Durable storage, relational queries, ACID guarantees
  - Cons: Slower than Redis, schema design overhead, no native TTL (manual cleanup)
  - Future: Consider for long-term session history (Phase 2 analytics)
- **Local Memory**: Rejected
  - Pros: Fastest access
  - Cons: Lost on restart, no sharing across instances (Phase 2 scaling)

**Consequences:**
- **Positive**:
  - Sub-millisecond session lookup latency
  - Automatic session expiration (TTL-based)
  - No database schema management
  - Production-ready (Redis operational and stable)
- **Negative**:
  - Session data lost on Redis restart (mitigated: sessions are ephemeral, 1-hour TTL)
  - No long-term session analytics (acceptable for Phase 1)
  - Requires Redis operational status (dependency risk mitigated by service stability)

**Validation:**
- Session CRUD operations <1ms p95 latency
- TTL expiration verified (sessions auto-deleted after 1 hour)
- Redis memory usage <500MB for typical session load

---

### ADR-006: Manual Deployment Procedures vs Ansible Automation

**Status:** Accepted
**Date:** 2025-11-27
**Context:** Service can be deployed manually (documented procedures) or via Ansible playbooks (automated).

**Decision:** Use manual deployment procedures (documented commands) for Phase 1, NO Ansible playbooks.

**Rationale:**
1. **HX-Infrastructure Philosophy**: Bare-metal deployment with manual procedures standard
2. **Charter Requirement**: Line 158-160 explicitly excludes automation (Ansible playbooks for deployment)
3. **Learning Opportunity**: Manual procedures ensure deep understanding of deployment
4. **Flexibility**: Easier to adapt procedures during initial deployment (no playbook refactoring)
5. **Ansible Vault Only**: Ansible used exclusively for credentials management (NOT deployment automation)

**Alternatives Considered:**
- **Ansible Playbooks**: Explicitly rejected per charter and infrastructure philosophy
  - Pros: Automated deployment, idempotent operations, less human error
  - Cons: Violates HX-Infrastructure philosophy, adds complexity, harder to debug
- **Bash Scripts**: Rejected
  - Pros: Automated execution
  - Cons: Same objections as Ansible (automation discouraged for deployments)

**Consequences:**
- **Positive**:
  - Aligns with HX-Infrastructure philosophy (constitution compliance)
  - Forces deep understanding of deployment steps
  - Easier to adapt during initial deployment (no playbook refactoring)
  - Documentation-driven (procedures consumable by humans and AI agents)
- **Negative**:
  - Manual execution slower than automation (acceptable for single-node deployment)
  - Human error risk (mitigated by documented procedures with validation checks)
  - No idempotency guarantees (mitigated by pre-deployment validation checks)

**Validation:**
- Deployment procedures documented in DEPLOYMENT-PLAN.md
- Each step includes validation command (manual verification)
- Rollback procedure documented (manual rollback steps)
- Test deployment in non-operational environment (verify procedures work)

---

**Architecture Version**: 1.0
**Last Updated**: 2025-11-27
**Created By**: Alex Rivera (Platform Architect)
**Reviewed By**: PENDING (awaiting Core Team SME reviews)
**Approved By**: PENDING
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git

---

**Based On**:
- HX Infrastructure Constitution v1.0 (`/home/agent0/HX-Infrastructure/constitution.md`)
- Architecture Standards v1.1 (`/home/agent0/HX-Infrastructure/standards/architecture-standards.md`)
- Project Charter v1.0 (`/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md`)
- Deployment Plan v1.0 (`/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/planning/plan.md`)

---

**End of Deployment Architecture Document**

*This architecture document provides comprehensive technical specifications for the Docling MCP Server deployment, including system architecture, technology stack details, MCP protocol implementation, document processing architecture, storage architecture, security architecture, performance architecture, deployment architecture, integration architecture, and scalability considerations. All architecture decisions are documented in ADRs with clear rationale, alternatives considered, and validation criteria.*
