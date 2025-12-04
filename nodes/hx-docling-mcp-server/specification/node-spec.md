# Service Specification: Docling MCP Server

**Document Type:** Service Specification (Phase 2: Specification Development)
**Template Version:** 1.0
**Specification Version:** 1.0
**Created:** 2025-11-25
**Operational Date:** 2025-12-04
**Status:** ✅ COMPLETE - Service Implemented and OPERATIONAL
**Architect:** alex-rivera (Platform Architect)
**Contributors:** albert-singh (Docling Processing), andy-taylor (LightRAG Extraction), marcus-johnson (LightRAG Configuration), shane-black (LiteLLM Integration), james-rodriguez (MCP Tools)
**Project ID:** hx-docling-mcp
**Node Assignment:** hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)
**Charter Reference:** `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md` (Status: APPROVED)

---

## Document Purpose

This specification defines **WHAT** the Docling MCP Server does and **WHY** it's needed, without prescribing **HOW** to deploy it (implementation details deferred to plan.md and deployment procedures).

**Context Chain:**
- **Charter** (`charter.md`) - Defined project vision, scope, strategic alignment (OPERATIONAL)
- **This Document** - Defines service requirements, architecture, and capabilities (IMPLEMENTED)
- **Architecture** (`planning/deployment-architecture.md`) - Technical design and component integration (COMPLETE)
- **Plan** (`planning/plan.md`) - Deployment procedures and implementation steps (COMPLETE)

---

## Executive Summary

### Service Overview

The Docling MCP Server is a standalone document processing service that exposes advanced document parsing, knowledge graph generation, and RAG pipeline capabilities through the Model Context Protocol (MCP). It transforms how AI agents in the hana-x ecosystem process multimodal documents by providing standardized, protocol-driven access to:

1. **Document Ingestion** (Stage 1): Convert PDF, DOCX, PPTX, XLSX, HTML, images (14+ formats) to structured DoclingDocument format with preserved semantic structure
2. **Knowledge Structuring** (Stage 2): Extract entities and relationships via LightRAG, build knowledge graphs stored in Qdrant for intelligent retrieval

**Primary Value Proposition:**
- **MCP Protocol Standardization**: AI agents discover and invoke 19 document processing tools through standard MCP protocol (HTTP/SSE/stdio transports)
- **Knowledge Graph RAG**: Move beyond flat vector search to entity-relationship-aware document understanding
- **Multimodal Processing**: Handle complex documents with text, images, tables, code blocks, preserving structure and semantics
- **Reduced Integration Complexity**: Single MCP endpoint replaces multiple ad-hoc document processing integrations

**Deployment Context:**
- **Target Node**: hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)
- **Deployment Philosophy**: Bare-metal deployment with systemd service management (no Docker for production)
- **Timeline**: 8-10 weeks (quality over speed)
- **Scope**: Phase 1 delivers Stages 1-2 (ingestion + knowledge structuring); Stages 3-5 (embeddings, indexing, retrieval) deferred to Phase 2

### Relationship with hx-docling-server

**Two-Server Architecture:**

HX-Infrastructure deploys Docling capabilities across two specialized servers:

| Server | IP | Status | Purpose | Primary Interface |
|--------|----|---------|---------|--------------------|
| **hx-docling-server** | hx-docling-server.hx.dev.local | ✅ Operational | Document worker node | Direct API (HTTP/REST) |
| **hx-docling-mcp-server** | hx-docling-mcp-server.hx.dev.local | ⬜ Planned | MCP protocol gateway | MCP (HTTP/SSE/stdio) |

**Coordination Strategy:**

The two servers serve **complementary, non-overlapping** roles:

1. **hx-docling-server (hx-docling-server.hx.dev.local)** - Document Processing Worker:
   - **Role**: Bare-metal Docling worker for internal document processing tasks
   - **Primary Responsibilities**:
     - Internal document retrieval and parsing
     - Document format conversion (PDF, DOCX, etc.)
     - Text extraction and preprocessing
     - Document metadata storage (PostgreSQL integration)
   - **Primary Clients**: Internal services requiring direct document processing
   - **Interface**: Direct HTTP REST API for document processing jobs
   - **Status**: ✅ Already operational, processing documents for HX-Infrastructure services

2. **hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)** - MCP Protocol Gateway:
   - **Role**: MCP-standardized interface for AI agent integration
   - **Primary Responsibilities**:
     - Expose document processing capabilities via MCP protocol
     - Provide 19 standardized MCP tools for AI agents
     - Knowledge graph generation with LightRAG integration
     - Enable AI agents to discover and invoke document processing via MCP
   - **Primary Clients**: AI agents (Claude Desktop, LM Studio, custom MCP clients)
   - **Interface**: Model Context Protocol (MCP) with HTTP/SSE/stdio transports
   - **Status**: ⬜ Planned deployment (this specification)

**Integration Pattern:**

The servers operate **independently** without direct inter-server communication:

- **No backend integration**: hx-docling-mcp-server does NOT call hx-docling-server as a backend
- **Independent processing**: Each server has its own Docling installation and processing pipeline
- **Shared infrastructure dependencies**: Both use common services (LiteLLM, Qdrant, Redis, PostgreSQL)
- **Different client bases**: Worker server serves internal apps, MCP server serves AI agents

**Why Two Servers?**

1. **Protocol Separation**: Direct HTTP API (worker) vs. MCP protocol (AI agents)
2. **Client Isolation**: Internal services vs. external AI agent integrations
3. **Operational Independence**: Worker server already operational; MCP server adds new capability without disrupting existing services
4. **Resource Allocation**: Separate bare-metal servers allow independent scaling and resource management

**Future Coordination (Phase 2+):**

Potential future integration patterns (not in Phase 1 scope):
- Shared document metadata repository (PostgreSQL consolidation)
- Shared knowledge graph storage (unified Qdrant collections)
- Load distribution for high-volume document processing

**Current Scope**: Phase 1 establishes hx-docling-mcp-server as independent MCP gateway with its own processing pipeline.

---

## Service Purpose & Requirements

### Primary Purpose

**Core Mission:**
The Docling MCP Server provides AI agents with a standardized MCP interface for transforming unstructured multimodal documents into structured knowledge graphs, enabling intelligent document-aware retrieval and reasoning.

**Key Capabilities:**
1. **Document Processing as MCP Tools**: 19 MCP-compliant tools for document conversion, knowledge generation, and manipulation
2. **Multi-Format Document Understanding**: Parse PDF, DOCX, PPTX, XLSX, HTML, images with structure preservation (headings, tables, lists, code blocks)
3. **Knowledge Graph Construction**: Entity extraction and relationship modeling via LightRAG using Ollama1/2 models
4. **Dual-Level Storage**: Raw DoclingDocument JSON + Knowledge Graph entities/relationships in Qdrant
5. **Session Management**: Redis-backed processing state for multi-step document workflows

### Problem Statement

**Current State Challenges:**
- AI agents lack standardized protocol for document processing (each implements custom integration)
- No knowledge graph layer for document understanding (flat vector search insufficient for complex queries)
- Limited multimodal support (difficulty with documents containing images, tables, complex layouts)
- Manual integration overhead (each agent reimplements document parsing logic)
- No MCP protocol compliance (missing industry-standard tool discovery and execution)

**Target State Benefits:**
- **Protocol-Driven Discovery**: AI agents use MCP protocol to discover available document tools dynamically
- **Knowledge Graph RAG**: Entity-relationship graphs enable intelligent retrieval (e.g., "find all contracts mentioning Company X with obligations to Party Y")
- **Multimodal Excellence**: Handle complex documents (scientific papers, financial reports, technical manuals) with preserved structure
- **Zero Custom Integration**: AI agents integrate via standard MCP clients (no service-specific code)
- **Future-Proof Architecture**: Supports N8N workflow integration, FastMCP client composition, LangGraph orchestration

### Deployment Scenarios

**Scenario 1: AI Agent Document Processing**
- **Given**: AI agent needs to process user-uploaded PDF report
- **When**: Agent invokes MCP tool `convert_document_to_markdown` via HTTP transport
- **Then**:
  - Docling MCP server receives document path/URL
  - Docling library converts PDF → DoclingDocument (structure preserved)
  - Server returns Markdown with headings, tables, images extracted
  - Agent uses Markdown for downstream reasoning tasks

**Scenario 2: Knowledge Graph Generation**
- **Given**: Batch of 50 research papers in PDF format
- **When**: Agent invokes MCP tool `generate_knowledge_graph` with document collection
- **Then**:
  - LightRAG extracts entities (authors, institutions, concepts) and relationships (citations, collaborations)
  - Entities stored in Qdrant collection `hx_docling_mcp_entities` with embeddings
  - Relationships stored in Qdrant collection `hx_docling_mcp_relationships`
  - Agent can query knowledge graph: "What institutions collaborated with MIT on quantum computing?"

**Scenario 3: Session-Based Multi-Step Workflow**
- **Given**: AI agent needs to process large document corpus in multiple steps
- **When**: Agent creates session via `create_session`, uploads documents, generates graphs, then queries
- **Then**:
  - Redis stores session state (document IDs, processing status, graph metadata)
  - Agent can resume processing across multiple requests
  - Session expires after configurable TTL (default 24 hours)

**Scenario 4: Multimodal Table Extraction**
- **Given**: Financial report PDF with complex multi-page tables
- **When**: Agent invokes `extract_tables` MCP tool
- **Then**:
  - Docling backend detects table regions across pages
  - Table structure reconstructed (merged cells, headers, data rows)
  - Returns JSON table representation + CSV export option
  - Agent ingests structured data for analysis

### Operational Requirements

**Service Availability:**
- **What happens when service fails?**
  - MCP clients receive connection timeout or HTTP 503 error
  - In-progress document processing jobs lost (no persistence across restart in Phase 1)
  - Agents must retry document processing requests
  - Mitigation: Systemd auto-restart, health check monitoring

**Network Resilience:**
- **How does system handle network interruption?**
  - **To LiteLLM/Ollama**: Retry with exponential backoff (3 attempts), fail gracefully with error to MCP client
  - **To Qdrant**: Connection pool with retry logic, fail document if vector storage unavailable (no partial graphs)
  - **To Redis**: Graceful degradation - if Redis unavailable, disable session management (stateless mode)
  - **From MCP clients**: HTTP timeouts return 504 Gateway Timeout, client must retry

**Recovery Requirements:**
- **Recovery Point Objective (RPO)**: Session state loss acceptable (Redis TTL-based, no critical data)
- **Recovery Time Objective (RTO)**: 5 minutes (systemd restart + dependency health checks)
- **Data Durability**: Knowledge graphs persisted in Qdrant (durable), DoclingDocuments ephemeral in Phase 1

---

## Requirements

### Functional Requirements

#### MCP Protocol Compliance

- **FR-001**: Service MUST implement MCP protocol version 1.0+ with full compliance for tool discovery and execution:
  - **Protocol Version**: MCP 1.0 specification with JSON-RPC 2.0 as transport layer
  - **FastMCP Framework**: Version >=0.2 for production-ready MCP server implementation
  - **Server Initialization**: Create FastMCP instance via `mcp = FastMCP("docling-mcp-server", version="1.0.0")`
  - **Tool Discovery Endpoint**: `tools/list` method returns complete tool manifest with:
    - Tool names (19 tools across 3 categories)
    - Tool descriptions (auto-generated from function docstrings)
    - Input schemas (auto-generated from Pydantic type hints)
    - Return type schemas (JSON Schema representation)
  - **Tool Execution Endpoint**: `tools/call` method with parameter validation:
    - JSON-RPC request format: `{"jsonrpc":"2.0","method":"tools/call","params":{"name":"<tool_name>","arguments":{...}},"id":<request_id>}`
    - Pydantic schema validation before tool execution (reject invalid params with `-32602` error)
    - Async/await support for concurrent tool execution (max 5 concurrent document conversions)
  - **Error Handling**: MCP-compliant error codes with actionable messages:
    - `-32700`: Parse error (invalid JSON in request body)
    - `-32600`: Invalid request (missing `jsonrpc`, `method`, or `id` fields)
    - `-32601`: Method not found (unknown tool name in `params.name`)
    - `-32602`: Invalid params (schema validation failure, type mismatch)
    - `-32603`: Internal error (uncaught exception during tool execution)
    - `-1`: Document processing error (file not found, unsupported format, conversion failure)
    - `-2`: Integration failure (LiteLLM, Qdrant, Redis unavailable)
  - **Cancellation Support**: `tools/cancel` method for aborting long-running tool executions
    - Request: `{"jsonrpc":"2.0","method":"tools/cancel","params":{"id":<request_id>}}`
    - Implementation: asyncio task cancellation via `task.cancel()`
    - Response: `{"jsonrpc":"2.0","result":"cancelled","id":<cancel_request_id>}`
  - **Timeout Management**: Configurable per-tool execution limits (environment variables):
    - `convert_document`: 120 seconds default (2 minutes for large PDFs)
    - `generate_knowledge_graph`: 300 seconds default (5 minutes for LLM extraction)
    - `batch_convert`: 600 seconds default (10 minutes for batch operations)
    - Configuration: `TOOL_TIMEOUT_SECONDS_{TOOL_NAME}` environment variable
  - **Compliance Validation**: All tool responses MUST conform to MCP response format:
    - Success: `{"jsonrpc":"2.0","result":{"content":[{"type":"text","text":"<json_result>"}]},"id":<request_id>}`
    - Error: `{"jsonrpc":"2.0","error":{"code":<error_code>,"message":"<error_message>","data":{...}},"id":<request_id>}`

- **FR-002**: Service MUST expose 19 core MCP tools across three categories with decorator-based registration:
  - **Tool Registration Pattern**: Use `@mcp.tool()` decorator for each tool
    - Example: `@mcp.tool(description="Convert document to DoclingDocument JSON format")`
    - Auto-generate `inputSchema` from Pydantic type hints (function parameters)
    - Auto-generate `outputSchema` from return type annotation
  - **Conversion Tools** (3):
    - `convert_document`: Convert file/URL/base64 to DoclingDocument JSON
      - Parameters: `source: str` (required), `format: Optional[str]` (hint)
      - Returns: `DoclingDocument` (Pydantic model with doc_items, metadata)
      - Timeout: 120 seconds
    - `convert_document_to_markdown`: Convert to Markdown text format
      - Parameters: `source: str` (required), `format: Optional[str]` (hint)
      - Returns: `str` (Markdown representation)
      - Timeout: 120 seconds
    - `batch_convert`: Convert multiple documents in single request
      - Parameters: `sources: List[str]` (required), `format: Optional[str]` (hint)
      - Returns: `List[DoclingDocument]` (array of converted documents)
      - Timeout: 600 seconds
  - **Generation Tools** (11):
    - `generate_knowledge_graph`: Extract entities and relationships via LightRAG (See MCP Tools Specification → Tool 4)
      - Parameters: `docling_document: DoclingDocument` (required), `llm_model: str` (default: "gemma3:27b")
      - Returns: `KnowledgeGraph` (entities, relationships, Qdrant collection ID)
      - Timeout: 300 seconds
      - **Qdrant Integration**: Stores entities in `hx_docling_mcp_entities` collection and relationships in `hx_docling_mcp_relationships` collection
    - `extract_entities`: NER extraction from DoclingDocument
    - `extract_relationships`: Relation extraction from entities
    - `create_docling_document`: Manual DoclingDocument construction
    - `parse_pdf_structure`: PDF-specific structure analysis
    - `extract_tables`: Table extraction with cell structure
    - `extract_images`: Image extraction with captions
    - `detect_document_language`: Language detection via langdetect
    - `classify_document_type`: Document classification (report, article, invoice, etc.)
    - `extract_metadata`: Author, title, creation date extraction
    - `generate_document_summary`: Abstractive summarization via LLM
  - **Manipulation Tools** (5):
    - `merge_documents`: Combine multiple DoclingDocuments
    - `split_document`: Split by page/section/heading
    - `search_document`: Full-text search with highlighting
    - `annotate_document`: Add annotations (highlights, comments, redactions)
    - `export_document`: Export to output formats (PDF, DOCX, HTML, Markdown)
  - **Schema Auto-Generation**: All tools MUST have auto-generated schemas via Pydantic
    - Type mapping: `str` → JSON string, `int` → JSON number, `List[T]` → JSON array, `Optional[T]` → nullable type
    - Nested models: Pydantic `BaseModel` classes → JSON object schemas with nested properties
    - Validation rules: `Field(description="...")` → schema description, `Field(ge=0)` → minimum value constraint
  - **Detailed Tool Specifications**: See "MCP Tools Specification" section for complete parameter schemas, implementation patterns, performance characteristics, and integration details for all 19 tools

- **FR-003**: Service MUST support all three MCP transports with simultaneous activation:
  - **HTTP Transport** (primary for AI agent integrations):
    - **Server**: Uvicorn ASGI server with uvloop event loop
    - **Listen Address**: `0.0.0.0:8000` (accessible within hx.dev.local network)
    - **MCP Endpoint**: `POST /mcp` for all JSON-RPC 2.0 requests
    - **Tool Discovery**: Send JSON-RPC request `{"jsonrpc":"2.0","method":"tools/list","id":1}` to `/mcp`
    - **Tool Execution**: Send JSON-RPC request `{"jsonrpc":"2.0","method":"tools/call","params":{"name":"...","arguments":{...}},"id":2}` to `/mcp`
    - **Health Check**: `GET /health` (non-MCP endpoint for monitoring)
    - **CORS**: Disabled by default (internal network), configurable via `CORS_ORIGINS` environment variable
    - **Authentication**: None in Phase 1 (network-level security), OAuth2 in Phase 2
      - Phase 2: `Authorization: Bearer <token>` header validation
      - OAuth2 providers: Google, GitHub (via FastMCP auth middleware)
    - **Rate Limiting**: None in Phase 1, token bucket (100 req/min per client) in Phase 2
    - **Request Logging**: All HTTP requests logged with timestamp, client IP, method, path, status code, duration
  - **SSE Transport** (for long-running document processing with progress updates):
    - **Endpoint**: `GET /mcp/sse` establishes Server-Sent Events stream
    - **Event Format**: Standard SSE format `data: <json>\n\n`
    - **Progress Events**: Emit percentage-based progress for tools >30 seconds
      - Event type: `progress` with tool name and percentage (0-100)
      - Example: `data: {"type":"progress","tool":"convert_document","percentage":45}\n\n`
    - **Completion Event**: Final `data: <json_rpc_response>\n\n` with full tool result
    - **Keepalive**: Send `:ping\n\n` every 30 seconds to prevent client timeout
    - **Connection Management**: Track active SSE connections (max 20 concurrent)
    - **Reconnection Strategy**: Clients should reconnect with exponential backoff (1s, 2s, 4s, max 30s)
  - **stdio Transport** (for CLI integration, shell scripts, automation):
    - **Activation**: `python -m docling_mcp.server --transport stdio`
    - **Input**: Read JSON-RPC requests from stdin (newline-delimited)
    - **Output**: Write JSON-RPC responses to stdout (newline-delimited)
    - **Buffering**: Flush stdout after each response (immediate delivery)
    - **Error Handling**: Write JSON-RPC errors to stdout (NOT stderr for protocol compliance)
    - **Logging**: Write logs to stderr (separate from JSON-RPC communication)
    - **Use Cases**:
      - Shell scripts: `cat request.json | python -m docling_mcp.server --transport stdio`
      - Claude Desktop: MCP server configuration JSON
      - Automation pipelines: CI/CD document processing
  - **Multi-Transport Support**: All transports MUST be active simultaneously
    - HTTP server runs in main asyncio event loop
    - stdio handled in separate thread (reads stdin, posts to asyncio queue)
    - SSE uses same HTTP server with dedicated `/mcp/sse` endpoint
  - **Transport Selection**: MCP clients choose transport based on use case (no automatic fallback)
    - HTTP: JSON-RPC 2.0 over HTTP POST, stateless request/response
    - SSE: Long-running jobs requiring progress updates (>30 seconds)
    - stdio: Local scripts, CLI tools, Claude Desktop integration

- **FR-004**: Service MUST return MCP-compliant tool schemas with comprehensive Pydantic validation:
  - **Schema Generation**: FastMCP auto-generates JSON Schema from Pydantic models
    - Tool names: Extracted from function name (snake_case)
    - Tool descriptions: Extracted from function docstring (first line)
    - Input schema: Generated from function parameters with type hints
    - Output schema: Generated from return type annotation
  - **Parameter Validation**: All tool parameters MUST have Pydantic type hints with comprehensive Field constraints
    - Required parameters: No default value (e.g., `source: str`)
    - Optional parameters: `Optional[T]` with default value (e.g., `format: Optional[str] = None`)
    - Parameter descriptions: Use `Field(description="...")` for detailed documentation (REQUIRED for all MCP tool parameters - LLMs use descriptions as prompts)
    - Validation constraints:
      - Numeric: `Field(ge=0, le=100)` for bounded ranges (e.g., confidence scores 0.0-1.0, page numbers ≥1)
      - String: `Field(min_length=1, max_length=500)` for length constraints
      - Pattern: `Annotated[str, StringConstraints(pattern=r"^[a-z0-9_-]+$")]` for format validation (RUNTIME VALIDATED - Field(pattern=...) only affects JSON Schema)
      - Enums: `Literal["option1", "option2"]` for fixed value sets (entity types, predicates) - RUNTIME VALIDATED
      - Examples: `Field(json_schema_extra={"examples": ["file:///opt/docs/sample.pdf", "https://example.com/doc.pdf"]})` for documentation and LLM guidance (Pydantic v2 requires examples in json_schema_extra)
    - Custom validators: Use `@field_validator` for complex validation logic
      - Path traversal prevention: Block `..`, `/etc`, `/root`, `/home` in file paths
      - URL validation: Validate HTTP/HTTPS URLs with proper scheme and domain
      - Size limits: Validate file size ≤500MB before processing
      - Format validation: Verify MIME types match file extensions
  - **Custom Type Definitions**: Define reusable Annotated types for common constraints
    - `DocumentFormat = Literal["pdf", "docx", "pptx", "xlsx", "html", "md", "txt", "epub", "rtf", "png", "jpg", "tiff"]` (enum for supported formats)
    - `ConfidenceScore = Annotated[float, Field(ge=0.0, le=1.0, description="Extraction confidence score (0.0 to 1.0)")]`
    - `DocumentSource = Annotated[str, StringConstraints(pattern=r"^(file://|https?://|data:)", min_length=1, max_length=2000)]` (runtime-validated URL/path with protocol enforcement)
    - `EntityType = Literal["Person", "Organization", "Location", "Concept", "Product", "Date", "Event", "Technology", "Method", "Metric", "Dataset", "Model", "Tool"]`
    - `RelationshipPredicate = Literal["works_for", "leads", "member_of", "located_in", "near", "mentions", "cites", "before", "after", "during", "part_of", "instance_of", "authored_by", "contributed_to"]`
    - `UUID = UUID4` (Pydantic native UUID validation - rejects invalid UUIDs at runtime)
    - `ISOTimestamp = datetime` (Pydantic auto-parses ISO8601 timestamps - rejects malformed dates at runtime)
    - `QdrantCollectionName = Annotated[str, StringConstraints(pattern=r"^docling_[a-z_]+$", min_length=8, max_length=64)]` (runtime-validated collection naming)
  - **Return Type Schemas**: All tools MUST return Pydantic models or primitive types
    - Pydantic models: Auto-serialized to JSON by FastMCP (e.g., `DoclingDocument`)
    - Primitive types: `str`, `int`, `float`, `bool` (direct JSON serialization)
    - Collections: `List[T]`, `Dict[str, T]` (array and object schemas)
  - **Error Code Standardization**: Map Python exceptions to MCP error codes with custom error classes
    - `ValueError`, `TypeError`, `ValidationError` → `-32602` (Invalid params)
    - `FileNotFoundError`, `PermissionError` → `-1` (Document processing error)
    - `TimeoutError` → `-32603` (Internal error with timeout details)
    - `Exception` (generic) → `-32603` (Internal error with traceback in logs only, sanitized message to client)
    - Custom error classes: `UnsupportedFormatError`, `PathTraversalError`, `FileSizeExceededError`, `QdrantConnectionError`, `LLMExtractionError`
  - **Error Response Format**: All errors MUST include actionable messages with context and field-specific guidance
    - Error message: User-friendly description of what went wrong
    - Error data: Additional context (tool name, source file, error type, validation details)
    - Example: `{"error": {"code": -1, "message": "Conversion failed: Unsupported file format '.xyz'. Supported formats: pdf, docx, pptx, xlsx, html, md, txt", "data": {"tool": "convert_document", "source": "file:///invalid.xyz", "error_type": "UnsupportedFormatError", "supported_formats": ["pdf", "docx", "pptx", "xlsx", "html", "md", "txt"]}}}`
  - **Custom Error Messages**: Define user-friendly error messages for all validation failures
    - Field-specific guidance: "source must be a valid file path (file://), HTTP URL (http/https), or base64 data URI (data:)"
    - Range violations: "confidence must be between 0.0 and 1.0, got {value}"
    - Pattern mismatches: "entity_type must be one of: Person, Organization, Location, Concept, Product, Date, Event"
    - Size violations: "Document size {size}MB exceeds maximum allowed 500MB"
    - Path violations: "Path traversal detected in '{path}'. Paths cannot contain '..', '/etc', '/root', or '/home'"
  - **Schema Validation on Startup**: Service MUST validate all tool schemas during initialization
    - Check all tools have valid Pydantic signatures
    - Verify all parameters have Field descriptions (warn if missing, fail if required parameters lack descriptions)
    - Validate all custom types resolve correctly
    - Fail fast if schema generation fails (log error and exit with status code 1)
    - Log warning if tool missing description or parameter documentation
  - **Client SDK Compatibility**: Schemas MUST be compatible with MCP client libraries
    - Python MCP SDK: `StdioClient`, `HttpClient` (mcp library)
    - Claude Desktop: stdio transport configuration JSON
    - LangChain MCP: HTTP transport via `MCPClient` wrapper
    - FastMCP In-Memory: `FastMCPTransport` for testing
  - **JSON Schema Generation**: Export complete JSON Schema for all MCP tools
    - Schema introspection: Send `{"jsonrpc":"2.0","method":"tools/list","id":1}` to receive JSON Schema for all tools
    - Schema generation: Use `model.model_json_schema(mode="serialization")` for output schemas
    - Schema versioning: Include `"$schema": "https://json-schema.org/draft/2020-12/schema"` header
    - Schema metadata: Title, description, version, author, contact for documentation generation
    - Breaking change detection: Compare schemas between versions, flag incompatible changes

#### Document Processing (Stage 1)

- **FR-005**: Service MUST support 14+ document formats via Docling library:
  - **PDF**: Including scanned PDFs with OCR fallback
  - **Office**: DOCX, PPTX, XLSX
  - **Web**: HTML, Markdown
  - **Images**: PNG, JPG, TIFF (with OCR processing)
  - **Other**: EPUB, RTF
- **FR-006**: Service MUST preserve document structure during conversion:
  - **Headings**: Detect and label H1-H6 hierarchy
  - **Tables**: Extract with cell structure, merged cells, headers
  - **Lists**: Ordered and unordered with nesting
  - **Code Blocks**: Language detection and syntax preservation
  - **Images**: Extract as base64 or external file references with captions
- **FR-007**: Service MUST produce DoclingDocument JSON format as primary output with schema validation
- **FR-008**: Service MUST support document input via:
  - **File path**: Local filesystem paths on hx-docling-mcp-server
  - **URL**: Download remote documents (HTTP/HTTPS)
  - **Base64**: Inline document data in MCP tool invocation
- **FR-009**: Service MUST detect document format automatically (no manual format specification required)
- **FR-010**: Service MUST handle conversion errors gracefully:
  - Return MCP error response with diagnostic information (format unsupported, corruption detected, OCR failure)
  - Log error details for debugging (document path, error type, Docling backend used)

#### Knowledge Graph Generation (Stage 2)

- **FR-011**: Service MUST integrate LightRAG for entity extraction and relationship modeling with Qdrant storage backend
  - **LightRAG Version**: Use latest stable release with Qdrant integration support
  - **Entity Extraction Pipeline**: Document chunking (max 4000 tokens), LLM-based entity extraction (gemma3:27b), entity deduplication via Qdrant semantic similarity (0.85 threshold), entity resolution (merge aliases)
  - **Relationship Extraction Pipeline**: Co-occurrence detection, LLM-based relationship classification, bidirectional relationship handling
  - **Graph Construction**: Dual-collection architecture (entities + relationships), entity-relationship integrity constraints, graph validation
- **FR-012**: Service MUST use Ollama models via LiteLLM gateway for entity/relationship extraction and embeddings:
  - **Entity Extraction Models** (LiteLLM routing):
    - **Ollama1 models** (gemma3:27b, gpt-oss:20b): Primary entity extraction (large context 8K-32K, high quality NER)
    - **Ollama2 models** (qwen3-coder:30b, qwen2.5:7b): Technical document processing (code entities, API names)
    - **Model Selection**: Environment variable `LLM_ENTITY_EXTRACTION_MODEL` (default: "gemma3:27b")
  - **Embedding Generation** (Ollama3): bge-m3:567m (1024D dense vectors), entity embeddings use entity_name + context_snippet, batch size 32
  - **LLM Configuration**: Temperature 0.1 (deterministic), max tokens 2048, timeout 60s, retry 3 attempts with exponential backoff
- **FR-013**: Service MUST extract structured entities with comprehensive attributes and Qdrant-optimized schema:
  - **Entity Types**: Person, Organization, Location, Concept, Product, Date, Event (configurable), extended types Phase 2 (Technology, Method, Metric, Dataset, Model, Tool)
  - **Entity Payload Schema** (Complete - See Component 3: LightRAG Knowledge Engine → Qdrant Collection Architecture → Entity Collection): entity_id, entity_name, entity_type, aliases, confidence, extraction_model, document_id, document_source, text_span, context_snippet, attributes (Dict), mention_count, extraction_timestamp
  - **Qdrant Payload Indexes**: entity_type (keyword), document_id (keyword), confidence (float), mention_count (integer)
- **FR-014**: Service MUST extract relationships with detailed attributes and Qdrant graph traversal support:
  - **Relationship Types**: Organizational (works_for, leads, member_of), Spatial (located_in, near), Reference (mentions, cites), Temporal (before, after, during), Semantic (part_of, instance_of), Authorship (authored_by, contributed_to), Custom (user-defined)
  - **Relationship Payload Schema** (Complete - See Component 3: LightRAG Knowledge Engine → Qdrant Collection Architecture → Relationship Collection): relationship_id, subject_entity_id, subject_entity_name, predicate, object_entity_id, object_entity_name, confidence, bidirectional, attributes (Dict), document_id, text_evidence, text_span, extraction_model, extraction_timestamp
  - **Qdrant Payload Indexes**: subject_entity_id (keyword - CRITICAL for graph traversal), object_entity_id (keyword - CRITICAL), predicate (keyword), document_id (keyword), confidence (float)
  - **Bidirectional Handling**: Symmetric relationships stored twice with swapped subject/object for efficient bi-directional graph traversal
- **FR-015**: Service MUST store knowledge graphs in Qdrant with production-ready dual-collection architecture:
  - **Entity Collection** (`hx_docling_mcp_entities`): 1024D vectors (bge-m3:567m), Cosine distance, HNSW (m:16, ef_construct:100), Scalar INT8 quantization Phase 2 (4x RAM reduction >100K entities), RAM estimate 100K entities = ~470MB
  - **Relationship Collection** (`hx_docling_mcp_relationships`): 1024D relationship embeddings, Cosine distance, HNSW (m:16, ef_construct:100), RAM estimate 500K relationships = ~2.35GB
  - **Connection Configuration**: HTTP API, connection pool (max 10, keepalive 60s), retry logic (3 attempts, exponential backoff), graceful degradation if Qdrant unavailable
  - **Complete Implementation**: See Component 3: LightRAG Knowledge Engine → Subsections 3.3 (Entity Deduplication Strategy), 3.5 (Graph Construction Workflow), 3.7 (LightRAG Configuration and Tuning) for collection initialization, entity insertion with deduplication, relationship insertion, batch operations, performance tuning, scaling triggers
- **FR-016**: Service MUST generate knowledge graphs for single documents and document collections with entity deduplication:
  - **Single Document**: Extract entities → Generate embeddings → Deduplicate via Qdrant (>0.85 similarity) → Insert/update → Extract relationships → Insert. Performance: <60s per 10K words
  - **Document Collection** (Unified Graph): Semantic similarity deduplication (0.85 threshold), alias aggregation, attribute merging, cross-document relationship linking, batch processing (10 docs parallel, bulk insert 100 entities/200 relationships per batch). Performance: 100 docs in <30 minutes
  - **Graph Validation**: Entity integrity, relationship integrity (subject/object IDs exist), orphaned entity detection, duplicate relationship prevention
  - **Complete Workflows**: See Component 3: LightRAG Knowledge Engine → Subsection 3.5 (Graph Construction Workflow) for detailed implementation and code examples
- **FR-017**: Service MUST provide comprehensive graph statistics via MCP tool and Qdrant queries:
  - **Entity Statistics**: Count by type, top entities by mention_count (limit 100), confidence distribution histogram
  - **Relationship Statistics**: Count by type, top connected entities (degree centrality), bidirectional ratio
  - **Graph Topology**: Density (relationships/entities), entity coverage (% of text with mentions), orphaned entity count
  - **Document-Level**: Entities per document, relationships per document
  - **MCP Tool** (`get_knowledge_graph_stats`): Input (document_id, entity_type, predicate - all optional), Output (complete statistics JSON), Performance <5s for <100K entities
  - **Complete Queries**: See Component 3: LightRAG Knowledge Engine → Subsection 3.8 (Knowledge Graph Query Capabilities) for Qdrant query examples and metric calculations

#### Session Management

- **FR-018**: Service MUST support session-based workflows via Redis with comprehensive state management:
  - **Create Session**:
    - Generate unique session ID (UUID v4 format)
    - Store session metadata in Redis hash `session:<session_id>` with fields:
      - `user`: User identifier or "anonymous"
      - `created_at`: ISO8601 timestamp
      - `last_accessed`: ISO8601 timestamp (updated on each access)
      - `ttl_hours`: Configured TTL in hours (default: 24)
      - `workflow_state`: Current workflow state (initialized, processing, completed)
    - Add session_id to active sessions index `sessions:active` (Redis set)
    - Set initial TTL using Redis EXPIRE command
  - **Upload Documents**:
    - Associate document IDs with session via Redis set `session:<session_id>:documents`
    - Use SADD for atomic document addition
    - Initialize document status in `session:<session_id>:status` hash (pending)
  - **Process Documents**:
    - Track processing status per document using Redis hash `session:<session_id>:status`
    - Support atomic status transitions: pending → processing → completed/failed
    - Use HSET for atomic status updates
    - Update `last_accessed` timestamp on status changes
  - **Query Session**:
    - Retrieve session metadata from `session:<session_id>` hash
    - Get associated documents from `session:<session_id>:documents` set
    - Get processing status from `session:<session_id>:status` hash
    - Extend session TTL using sliding window strategy (see FR-019)
    - Return comprehensive session state (metadata + documents + status)
  - **Delete Session**:
    - Remove session from active index `sessions:active`
    - Delete session metadata hash `session:<session_id>`
    - Delete document set `session:<session_id>:documents`
    - Delete status hash `session:<session_id>:status`
    - Use Redis MULTI/EXEC for atomic cleanup
  - **List Active Sessions**:
    - Query `sessions:active` set for all active session IDs
    - Return session summaries (metadata only, no document details)
- **FR-019**: Service MUST implement configurable session TTL with sliding window:
  - **Default TTL**: 24 hours (86400 seconds) from creation
  - **Maximum TTL**: 168 hours (7 days) hard limit
  - **Sliding Window TTL Extension**:
    - Extend TTL on every session access (get, update operations)
    - Extension increment: Configurable TTL_EXTENSION_HOURS (default: 4 hours)
    - Maximum extension: Cannot exceed 168 hours from creation
    - Use Redis EXPIRE to atomically update TTL
  - **TTL Configuration**:
    - Environment variable `SESSION_TTL_HOURS` (default: 24, max: 168)
    - Environment variable `SESSION_TTL_EXTENSION_HOURS` (default: 4)
    - Validate TTL configuration on service startup
  - **TTL Enforcement**:
    - Redis automatically expires keys when TTL reached
    - No manual cleanup required (Redis EXPIRE handles eviction)
    - Log session expiration events (monitor for premature expiration)
- **FR-020**: Service MUST gracefully degrade if Redis unavailable:
  - **Resilience Strategy**:
    - Connection pooling with health checks (Redis PING every 30 seconds)
    - Retry logic: 3 attempts with exponential backoff (100ms, 200ms, 400ms)
    - Circuit breaker: Disable session features after 5 consecutive failures
  - **Graceful Degradation Behavior**:
    - Detect Redis unavailability via connection errors or health check failures
    - Log WARNING: "Redis unavailable, operating in stateless mode"
    - Disable session-dependent MCP tools (create_session, get_session_status, etc.)
    - Continue operating stateless MCP tools (document conversion, knowledge graph generation without session tracking)
    - Return MCP error for session tools: `{"error": "session_unavailable", "message": "Redis service unavailable, session management disabled"}`
  - **In-Memory Fallback** (Optional - Phase 2):
    - Maintain in-memory session cache for active sessions (limited to 100 sessions)
    - Warn users that sessions are ephemeral (lost on service restart)
    - Log INFO: "Using in-memory session fallback (non-persistent)"
  - **Recovery Handling**:
    - Re-enable session features when Redis health check succeeds
    - Log INFO: "Redis connection restored, session management enabled"
    - Resume normal session operations
  - **Error Responses**:
    - Return MCP error with actionable message
    - Include fallback suggestions (e.g., "Use stateless document conversion tools instead")
    - Log all Redis failures with error context (operation, session_id, error type)

#### Caching Strategy (Performance Optimization)

- **FR-021A**: Service SHOULD implement Redis caching for performance optimization:
  - **Document Metadata Cache**:
    - Cache document metadata (format, page count, file size, author, title) in Redis hash `cache:doc_metadata:<document_hash>`
    - TTL: 7 days (604800 seconds)
    - Invalidation: Manual delete on document update/deletion
    - Use case: Avoid re-parsing document headers for repeated requests
  - **LLM Response Cache** (Semantic Caching):
    - Cache entity extraction results in Redis hash `cache:entities:<prompt_hash>`
    - Hash key generation: SHA256(document_content + extraction_prompt + model_name)
    - TTL: 24 hours (86400 seconds) for entity extraction results
    - Use case: Avoid re-running expensive LLM inference for identical documents
    - Cache hit metrics: Track cache hit ratio (target >40% for repeated documents)
  - **DoclingDocument Cache**:
    - Cache converted DoclingDocument JSON in Redis string `cache:docling:<document_hash>`
    - TTL: 24 hours (ephemeral cache, reduce conversion overhead)
    - Compression: Use Redis LZF compression for large documents (>100KB)
    - Use case: Avoid re-converting same document multiple times in workflows
    - Size limit: Max 5MB per cached document (prevent Redis memory bloat)
  - **Knowledge Graph Query Cache** (Phase 2 - Future):
    - Cache Qdrant query results for common entity searches
    - TTL: 1 hour (shorter for query freshness)
    - Invalidation: On knowledge graph updates
  - **Cache Invalidation Strategy**:
    - Time-based: TTL expiration (automatic via Redis EXPIRE)
    - Event-based: Manual invalidation on document update/deletion
    - Memory-based: Evict using volatile-lru policy when Redis memory >75%
  - **Cache Hit/Miss Metrics**:
    - `cache_hits_total{cache_type="metadata|entities|docling"}`: Counter
    - `cache_misses_total{cache_type="..."}`: Counter
    - `cache_hit_ratio{cache_type="..."}`: Gauge (hits / (hits + misses))
    - Target cache hit ratio: >40% for production workloads
  - **Cache Configuration**:
    - Environment variable `CACHE_ENABLED` (default: true)
    - Environment variable `CACHE_TTL_HOURS` (default: 24)
    - Environment variable `CACHE_MAX_DOCUMENT_SIZE_MB` (default: 5)

#### Integration & Interoperability

- **FR-021**: Service MUST integrate with LiteLLM Gateway (hx-litellm-server:4000) for multi-provider LLM abstraction:
  - Use LiteLLM as single endpoint for Ollama1/2/3 model routing
  - Support LiteLLM health checks before entity extraction
  - Handle LiteLLM errors (model unavailable, rate limit, timeout)
- **FR-022**: Service MUST integrate with Qdrant (hx-qdrant-server:6333) for knowledge graph storage:
  - Create collections on startup if not exist
  - Use Qdrant HTTP API (not gRPC for simplicity)
  - Validate Qdrant connectivity before graph generation
- **FR-023**: Service MUST integrate with Redis (hx-redis-server:6379) for session state:
  - Use Redis connection pool (max 10 connections)
  - Implement Redis pub/sub for session events (optional, Phase 2)
  - Handle Redis failures gracefully (see FR-020)
- **FR-024**: Service MUST log all integration failures with retry counts and error messages

#### Monitoring & Observability

- **FR-025**: Service MUST expose health check endpoint (`/health`) returning:
  - Service status (healthy, degraded, unhealthy)
  - Dependency status (LiteLLM, Qdrant, Redis connection checks)
  - Version information (Docling version, FastMCP version, service version)
- **FR-026**: Service MUST log all MCP tool invocations:
  - Tool name, parameters (sanitized - no document content), session ID
  - Execution time, result status (success, error), error messages
- **FR-027**: Service MUST track operational metrics:
  - **Performance**: Document processing time (p50, p95, p99), entity extraction time
  - **Throughput**: Documents processed per hour, MCP requests per second
  - **Errors**: Failed conversions by format, LLM API errors, Qdrant write failures
  - **Resource**: CPU usage, memory usage, disk space (document cache)
- **FR-028**: Service MUST write structured logs in JSON format with fields:
  - Timestamp (ISO8601), log level (DEBUG/INFO/WARN/ERROR), component (MCP server, Docling, LightRAG), message, context (session ID, document ID, tool name)

### Non-Functional Requirements

#### Performance

- **NFR-001**: Document conversion MUST complete within:
  - **Small documents** (<10 pages, <5MB): 5 seconds p95
  - **Medium documents** (10-100 pages, 5-50MB): 30 seconds p95
  - **Large documents** (100+ pages, >50MB): 2 minutes p95
- **NFR-002**: Entity extraction MUST complete within:
  - **Per 10K words**: 60 seconds p95 (LLM inference bottleneck)
- **NFR-003**: MCP tool discovery MUST respond within 500ms
- **NFR-004**: Health check endpoint MUST respond within 2 seconds

#### Scalability

- **NFR-005**: Service MUST handle concurrent MCP clients:
  - **Phase 1 target**: 5 concurrent clients (development/testing load)
  - **Future target**: 20+ concurrent clients (production load - Phase 2)
- **NFR-006**: Service MUST process document corpus:
  - **Phase 1 target**: 100 documents per batch, 1000 documents per day
  - **Future target**: 10,000 documents per day (horizontal scaling - Phase 2)
- **NFR-007**: Knowledge graph storage MUST scale to:
  - **Phase 1 target**: 100K entities, 500K relationships
  - **Future target**: 10M+ entities (Qdrant cluster - Phase 2)

#### Reliability

- **NFR-008**: Service MUST achieve 99% uptime during operational phase (excluding planned maintenance)
- **NFR-009**: Service MUST auto-restart on crash via systemd (maximum 3 restarts in 5 minutes, then fail state)
- **NFR-010**: Service MUST handle dependency failures gracefully:
  - LiteLLM unavailable: Disable entity extraction, allow document conversion only
  - Qdrant unavailable: Disable knowledge graph storage, return error for graph generation tools
  - Redis unavailable: Disable session management, operate in stateless mode

#### Security

- **NFR-011**: Service MUST implement network-level security for Phase 1:
  - Listen on `0.0.0.0:8000` (accessible within hx.dev.local network only)
  - No public internet exposure (internal network isolation 192.168.10.0/24)
  - No authentication required (trusted internal network assumption)
- **NFR-012**: Service MUST store credentials in Ansible Vault:
  - LiteLLM API key (if required)
  - Qdrant API key (if enabled)
  - Redis password (if enabled)
- **NFR-013**: Service MUST NOT log sensitive data:
  - Sanitize document content in logs (truncate to first 100 characters)
  - Redact credentials in error messages
  - No user-identifiable information in metrics
- **NFR-014**: Service MUST validate all MCP tool inputs:
  - Schema validation via Pydantic
  - Path traversal prevention (no access to `/etc`, `/root`, etc.)
  - File size limits (max 500MB per document in Phase 1)

#### Maintainability

- **NFR-015**: Service MUST use configuration management:
  - Environment variables for all runtime configuration (no hardcoded values)
  - `.env` file for local development overrides
  - Configuration validation on startup (fail fast if misconfigured)
- **NFR-016**: Service MUST document all MCP tools:
  - Pydantic schemas auto-generate tool descriptions
  - Example tool invocations in documentation
  - Error codes and troubleshooting guide
- **NFR-017**: Service MUST follow Python code quality standards:
  - Type hints for all functions (mypy validation)
  - Docstrings for all public APIs (Google style)
  - Unit test coverage >80% (pytest framework)

### Node Requirements

#### Target Node

- **Target Node**: hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)
- **Operating System**: Ubuntu 24.04 LTS (bare-metal installation)
- **Hostname**: hx-docling-mcp-server.hx.dev.local (DNS via hx-dc-server)
- **Network**: Internal hx.dev.local network, no public internet exposure

#### Resource Requirements

- **CPU**:
  - **Minimum**: 2 cores (Intel/AMD x86_64)
  - **Recommended**: 4 cores (for concurrent document processing)
  - **Rationale**: Docling processing is CPU-intensive (PDF parsing, OCR, image extraction)
- **Memory**:
  - **Minimum**: 4GB RAM
  - **Recommended**: 8GB RAM
  - **Rationale**: Document processing buffers (large PDFs in memory), LightRAG entity extraction, Qdrant client cache
- **Storage**:
  - **Minimum**: 10GB disk space
  - **Recommended**: 50GB disk space
  - **Breakdown**:
    - Operating system: 5GB
    - Python virtual environment: 2GB (docling, FastMCP, dependencies)
    - Document cache: 5GB (temporary storage for downloaded/uploaded documents)
    - Logs: 1GB (rotated daily, 7-day retention)
    - Growth buffer: 37GB (future document corpus expansion)
- **Network**:
  - **Bandwidth**: 100Mbps minimum (document downloads, Qdrant writes)
  - **Ports**: TCP 8000 (MCP HTTP server)
  - **Outbound Access**: Required to LiteLLM (hx-litellm-server.hx.dev.local:4000), Qdrant (hx-qdrant-server.hx.dev.local:6333), Redis (hx-redis-server.hx.dev.local:6379)

#### System Dependencies

- **Python Runtime**: Python 3.10+ (docling requires 3.10 minimum, 3.11 recommended)
- **System Libraries**:
  - `poppler-utils`: PDF rendering backend for Docling
  - `tesseract-ocr`: OCR engine for scanned PDFs and images
  - `libmagic1`: File format detection (MIME type identification)
  - `build-essential`: Compilation tools for Python packages with native extensions
- **Python Packages** (managed via pip in virtual environment):
  - `docling~=2.63`: Document processing library (latest stable)
  - `fastmcp>=0.2`: MCP protocol framework
  - `qdrant-client`: Qdrant vector database client
  - `redis`: Redis client library
  - `pydantic>=2.10`: Data validation and MCP schemas
  - `httpx`: HTTP client for LiteLLM integration
  - `uvicorn`: ASGI server for FastMCP HTTP transport
  - `python-dotenv`: Environment variable management from .env files
  - `tenacity`: Retry logic with exponential backoff
  - `prometheus-client`: Metrics exposure (Phase 2)

#### Directory Structure

**Service Installation Paths**:
```
/opt/docling-mcp/                      # Primary service installation directory
├── venv/                              # Python virtual environment
│   ├── bin/                           # Python executables, activation scripts
│   ├── lib/python3.11/site-packages/  # Installed Python packages
│   └── pyvenv.cfg                     # Virtual environment configuration
├── src/                               # Service source code
│   ├── mcp_server.py                  # FastMCP server entry point
│   ├── docling_processor.py           # Document conversion logic
│   ├── literag_client.py              # hx-literag-server HTTP API client
│   ├── integration_manager.py         # LiteLLM, Qdrant, Redis clients
│   ├── session_manager.py             # Session lifecycle management
│   ├── health_check.py                # Health check endpoint logic
│   └── config.py                      # Configuration loading and validation
├── .env                               # Environment variables (not in git)
├── requirements.txt                   # Python package dependencies
├── README.md                          # Service documentation
└── LICENSE                            # Service license file
```

**Runtime Data Paths**:
```
/var/lib/docling-mcp/                  # Service runtime data
├── cache/                             # Document cache (temporary downloads)
│   ├── uploads/                       # User-uploaded documents
│   └── downloads/                     # Remote URL downloads
└── state/                             # Service state files (future)
    └── sessions.db                    # Local session backup (Phase 2)
```

**Configuration Paths**:
```
/etc/docling-mcp/                      # Service configuration
├── .env.production                    # Production environment variables
└── logging.yaml                       # Logging configuration (Phase 2)
```

**Log Paths**:
```
/var/log/docling-mcp/                  # Service logs
├── docling-mcp.log                    # Current application log (JSON format)
├── docling-mcp.log.1                  # Rotated log (yesterday)
├── docling-mcp.log.2.gz               # Compressed rotated log
└── error.log                          # Error-only log (ERROR level)
```

**Systemd Service Path**:
```
/etc/systemd/system/                   # Systemd unit files
└── docling-mcp.service                # Service unit file
```

#### User and Group Management

**Service Account**:
- **Username**: `docling-mcp`
- **Group**: `docling-mcp`
- **UID/GID**: System-assigned (typically 100-999 range for system accounts)
- **Home Directory**: `/opt/docling-mcp` (service installation directory)
- **Shell**: `/usr/sbin/nologin` (no interactive login allowed)
- **Purpose**: Least-privilege service execution, filesystem isolation

**File Ownership**:
- `/opt/docling-mcp/`: `docling-mcp:docling-mcp` (read-only for service account)
- `/var/lib/docling-mcp/`: `docling-mcp:docling-mcp` (read-write for cache operations)
- `/var/log/docling-mcp/`: `docling-mcp:docling-mcp` (read-write for logging)
- `/etc/docling-mcp/`: `root:docling-mcp` (read-only for service, writable by root only)

**Permissions**:
- Service source code: 755 (directories), 644 (files) - read-execute for service, read-only for others
- Configuration files: 640 (read-only for service, no access for others - credential protection)
- Cache directory: 770 (read-write-execute for service, no access for others)
- Log directory: 750 (read-write-execute for service, read-only for group)

#### Python Virtual Environment Setup

**Virtual Environment Requirements**:
- **Location**: `/opt/docling-mcp/venv/`
- **Python Version**: 3.11 (installed via Ubuntu 24.04 `python3.11` package)
- **Creation Method**: `python3.11 -m venv /opt/docling-mcp/venv`
- **Activation**: Automated via systemd unit file (ExecStart uses venv/bin/python directly)
- **Isolation**: Prevents conflicts with system Python packages, enables version pinning

**Dependency Management**:
- **requirements.txt**: Pinned versions for reproducible deployments
  - Example: `docling==2.63.0`, `fastmcp==0.2.1`, `pydantic==2.10.3`
- **Installation**: `venv/bin/pip install -r requirements.txt --no-cache-dir`
- **Upgrade Strategy**: Manual upgrades only (no automatic updates), tested in non-operational first
- **Dependency Version Pinning**:
  - Critical packages (docling, fastmcp): Exact version pinning (`==`) or compatible release (`~=`)
  - Supporting packages (httpx, redis, qdrant-client): Compatible version range (`~=`)
  - Security patches: Reviewed and applied via manual requirements.txt update

**Virtual Environment Validation**:
- Pre-deployment check: `venv/bin/python -c "import docling, fastmcp; print('Dependencies OK')"`
- Post-deployment health check: Systemd ExecStartPre validates Python environment before service start

### Dependencies

#### Internal Service Dependencies

**CRITICAL Dependencies** (service cannot function without):

1. **hx-litellm-server (hx-litellm-server.hx.dev.local:4000)** - Status: ✅ OPERATIONAL
   - **Purpose**: Multi-provider LLM abstraction for entity extraction
   - **Integration**: HTTP API calls for chat completions (LightRAG entity extraction)
   - **Models Required**: gemma3:27b (Ollama1), qwen3-coder:30b (Ollama2)
   - **Criticality**: Critical for Stage 2 (knowledge graph generation); Stage 1 (document conversion) can operate without
   - **Fallback**: If unavailable, disable knowledge graph generation, allow document conversion only

2. **hx-qdrant-server (hx-qdrant-server.hx.dev.local:6333)** - Status: ✅ OPERATIONAL
   - **Purpose**: Vector database for knowledge graph storage
   - **Integration**: HTTP API for collection management, vector upsert, search
   - **Collections**: `hx_docling_mcp_entities`, `hx_docling_mcp_relationships`
   - **Criticality**: Critical for Stage 2 (knowledge graph storage); Stage 1 independent
   - **Fallback**: If unavailable, return error for knowledge graph tools, allow document conversion

3. **hx-ollama1-server (hx-ollama1-server.hx.dev.local:11434)** - Status: ✅ OPERATIONAL
   - **Purpose**: Large language models for entity extraction
   - **Integration**: Via LiteLLM gateway (indirect dependency)
   - **Models**: gemma3:27b (primary), gpt-oss:20b (fallback)
   - **Criticality**: Critical for high-quality entity extraction
   - **Fallback**: Use Ollama2 models (lower quality) if Ollama1 unavailable

4. **hx-ollama2-server (hx-ollama2-server.hx.dev.local:11434)** - Status: ✅ OPERATIONAL
   - **Purpose**: Code-specialized models for technical document processing
   - **Integration**: Via LiteLLM gateway (indirect dependency)
   - **Models**: qwen3-coder:30b (technical docs), qwen2.5:7b (fallback)
   - **Criticality**: High for technical document entity extraction
   - **Fallback**: Use Ollama1 models (general-purpose) if Ollama2 unavailable

**HIGH Priority Dependencies** (service degraded without):

5. **hx-redis-server (hx-redis-server.hx.dev.local:6379)** - Status: ✅ OPERATIONAL
   - **Purpose**: Session state management for multi-step workflows
   - **Integration**: Redis connection pool, key-value storage
   - **Data Stored**: Session metadata, document processing status, temporary cache
   - **Criticality**: High for session-based workflows; can operate stateless without
   - **Fallback**: Graceful degradation - disable session tools, operate in stateless mode

6. **hx-literag-server (hx-literag-server.hx.dev.local:8000)** - Status: ✅ OPERATIONAL
   - **Purpose**: LightRAG knowledge graph generation via HTTP API
   - **Integration**: HTTP API for document chunking, entity extraction, relationship mapping
   - **Endpoints**: `/chunk`, `/extract_entities`, `/extract_relationships`
   - **Criticality**: Critical for Stage 2 (knowledge graph generation); Stage 1 (document conversion) can operate without
   - **Fallback**: If unavailable, disable knowledge graph tools, allow document conversion only

7. **hx-ollama3-server (hx-ollama3-server.hx.dev.local:11434)** - Status: ✅ OPERATIONAL
   - **Purpose**: Embedding models for vector generation (Phase 2 primary use)
   - **Integration**: Via LiteLLM gateway (indirect dependency)
   - **Models**: ibm/granite-docling:258m (document processing - LOW priority), bge-m3:567m (embeddings - Phase 2)
   - **Criticality**: Low for Phase 1 (embeddings not used); High for Phase 2
   - **Fallback**: Phase 1 does not require Ollama3; Phase 2 will use for embeddings

#### Infrastructure Dependencies

7. **hx-dc-server** - Status: ✅ OPERATIONAL
   - **Purpose**: DNS resolution for service discovery
   - **Integration**: System-level DNS resolution (hx.dev.local domain)
   - **Criticality**: Critical for resolving hostnames (hx-litellm-server.hx.dev.local, etc.)
   - **Fallback**: Use IP addresses directly if DNS unavailable (requires config change)

8. **hx-ca-server** - Status: ✅ OPERATIONAL
   - **Purpose**: TLS certificates for internal service communication (Phase 2)
   - **Integration**: Certificate files in `/etc/ssl/hx/`
   - **Criticality**: Low for Phase 1 (no TLS), High for Phase 2 (mTLS between services)
   - **Fallback**: Phase 1 operates without TLS (internal network trusted)

#### External Dependencies

**None for Phase 1** - All dependencies are internal HX-Infrastructure services. No external API calls (OpenAI, cloud services) required.

### Integrations

#### Upstream Services (Services that consume Docling MCP Server)

**AI Agents** (MCP Clients):
- **Integration Protocol**: MCP over HTTP/SSE/stdio
- **Use Cases**: Document processing for RAG pipelines, knowledge extraction, document analysis
- **Tools Consumed**: All 19 MCP tools (conversion, generation, manipulation)
- **Authentication**: None (Phase 1 - internal network trust)

**N8N Workflows** (Phase 2 - Future):
- **Integration Protocol**: MCP wrapper for N8N custom nodes
- **Use Cases**: Automated document processing workflows, batch knowledge graph generation
- **Tools Consumed**: Conversion and generation tools primarily

**FastMCP Clients** (Future):
- **Integration Protocol**: FastMCP client library (programmatic MCP composition)
- **Use Cases**: Multi-agent orchestration, server-to-server MCP communication

#### Downstream Services (Services consumed by Docling MCP Server)

**LiteLLM Gateway** (hx-litellm-server:4000):
- **Integration Protocol**: HTTP/REST (OpenAI-compatible API)
- **Data Flow**:
  - Docling MCP → LiteLLM: Chat completion requests with entity extraction prompts
  - LiteLLM → Docling MCP: JSON responses with extracted entities/relationships
- **Error Handling**: Retry with exponential backoff (3 attempts), timeout 60 seconds, fail gracefully if unavailable

**Qdrant** (hx-qdrant-server:6333):
- **Integration Protocol**: HTTP/REST (Qdrant HTTP API)
- **Data Flow**:
  - Docling MCP → Qdrant: Create collections, upsert vectors (entities, relationships)
  - Qdrant → Docling MCP: Confirmation responses, search results (Phase 2)
- **Error Handling**: Retry on connection error (3 attempts), fail document processing if write fails (no partial graphs)

**Redis** (hx-redis-server:6379):
- **Integration Protocol**: Redis protocol (redis-py client)
- **Data Flow**:
  - Docling MCP → Redis: Set session keys, update processing status, cache metadata
  - Redis → Docling MCP: Get session state, check cache hits
- **Error Handling**: Connection pool with health checks, graceful degradation if unavailable (disable sessions)

**Ollama Servers** (Indirect - via LiteLLM):
- **Integration Protocol**: Via LiteLLM (no direct integration)
- **Data Flow**: LiteLLM routes requests to Ollama1/2/3 based on model selection
- **Error Handling**: LiteLLM handles Ollama failures, Docling MCP receives LiteLLM error responses

### Configuration Requirements

#### Environment Variables

**Required** (service fails to start if missing):
- `LITELLM_API_BASE`: LiteLLM gateway base URL (default: `http://hx-litellm-server.hx.dev.local:4000`)
- `LIGHTRAG_API_URL`: hx-literag-server API base URL (default: `http://hx-literag-server.hx.dev.local:8000`)
- `QDRANT_HOST`: Qdrant server hostname (default: `hx-qdrant-server.hx.dev.local`)
- `QDRANT_PORT`: Qdrant server port (default: `6333`)
- `REDIS_HOST`: Redis server hostname (default: `hx-redis-server.hx.dev.local`)
- `REDIS_PORT`: Redis server port (default: `6379`)

**Optional** (defaults provided):
- `MCP_HTTP_PORT`: MCP HTTP server port (default: `8000`)
- `MCP_SSE_ENABLED`: Enable SSE transport (default: `true`)
- `MCP_STDIO_ENABLED`: Enable stdio transport (default: `true`)
- `DOCLING_CACHE_DIR`: Temporary document cache directory (default: `/var/lib/docling-mcp/cache`)
- `LOG_LEVEL`: Logging verbosity (default: `INFO`, options: `DEBUG`, `INFO`, `WARN`, `ERROR`)
- `LOG_FORMAT`: Log format (default: `json`, options: `json`, `text`)

**Redis Session Management**:
- `SESSION_TTL_HOURS`: Redis session TTL in hours (default: `24`, max: `168`)
- `SESSION_TTL_EXTENSION_HOURS`: TTL extension increment for sliding window (default: `4`)
- `REDIS_CONNECTION_POOL_SIZE`: Redis connection pool max size (default: `10`)
- `REDIS_CONNECTION_TIMEOUT_SECONDS`: Redis connection timeout (default: `5`)
- `REDIS_OPERATION_TIMEOUT_SECONDS`: Redis read/write timeout (default: `10`)
- `REDIS_RETRY_ATTEMPTS`: Retry attempts for transient Redis failures (default: `3`)
- `REDIS_HEALTH_CHECK_INTERVAL_SECONDS`: Redis health check interval (default: `30`)

**Redis Caching**:
- `CACHE_ENABLED`: Enable Redis caching for performance (default: `true`)
- `CACHE_TTL_HOURS`: Default cache TTL in hours (default: `24`)
- `CACHE_MAX_DOCUMENT_SIZE_MB`: Max cached document size in MB (default: `5`)
- `CACHE_METADATA_TTL_HOURS`: Document metadata cache TTL (default: `168` [7 days])
- `CACHE_ENTITY_TTL_HOURS`: Entity extraction cache TTL (default: `24`)
- `CACHE_DOCLING_TTL_HOURS`: DoclingDocument cache TTL (default: `24`)

**Model & Processing**:
- `ENTITY_EXTRACTION_MODEL`: LLM model for entity extraction (default: `gemma3:27b`)
- `DOCUMENT_MAX_SIZE_MB`: Maximum document size in MB (default: `500`)
- `CONCURRENT_WORKERS`: Number of concurrent document processing workers (default: `4`)

#### Pydantic Settings Validation

**Configuration Schema** (Pydantic BaseSettings for environment validation):
```python
from pydantic import BaseModel, BaseSettings, Field, field_validator, HttpUrl
from pydantic.types import StringConstraints
from typing import Literal, Optional, Annotated
from pathlib import Path

class RedisSettings(BaseModel):
    """Redis connection and session management configuration."""

    host: str = Field(
        default="hx-redis-server.hx.dev.local",
        description="Redis server hostname or IP address"
    )
    port: int = Field(
        default=6379,
        ge=1,
        le=65535,
        description="Redis server port"
    )
    password: Optional[str] = Field(
        default=None,
        description="Redis authentication password (loaded from Ansible Vault)"
    )
    connection_pool_size: int = Field(
        default=10,
        ge=1,
        le=100,
        description="Maximum Redis connection pool size"
    )
    connection_timeout_seconds: int = Field(
        default=5,
        ge=1,
        le=30,
        description="Redis connection timeout in seconds"
    )
    operation_timeout_seconds: int = Field(
        default=10,
        ge=1,
        le=60,
        description="Redis read/write operation timeout in seconds"
    )
    retry_attempts: int = Field(
        default=3,
        ge=0,
        le=10,
        description="Number of retry attempts for transient Redis failures"
    )
    health_check_interval_seconds: int = Field(
        default=30,
        ge=5,
        le=300,
        description="Redis health check ping interval in seconds"
    )

class SessionSettings(BaseModel):
    """Session management TTL configuration."""

    ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="Session TTL in hours (max 168 hours = 7 days)"
    )
    ttl_extension_hours: int = Field(
        default=4,
        ge=1,
        le=48,
        description="TTL extension increment for sliding window (hours)"
    )

    @field_validator('ttl_extension_hours')
    @classmethod
    def validate_extension(cls, v: int, info) -> int:
        """Validate extension increment doesn't exceed total TTL."""
        if 'ttl_hours' in info.data and v > info.data['ttl_hours']:
            raise ValueError(
                f"ttl_extension_hours ({v}) cannot exceed ttl_hours ({info.data['ttl_hours']})"
            )
        return v

class CacheSettings(BaseModel):
    """Redis caching performance optimization configuration."""

    enabled: bool = Field(
        default=True,
        description="Enable Redis caching for document metadata, LLM responses, and DoclingDocuments"
    )
    ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="Default cache TTL in hours"
    )
    max_document_size_mb: int = Field(
        default=5,
        ge=1,
        le=100,
        description="Maximum document size to cache in MB (prevent Redis memory bloat)"
    )
    metadata_ttl_hours: int = Field(
        default=168,
        ge=1,
        le=720,
        description="Document metadata cache TTL (7 days default)"
    )
    entity_ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="Entity extraction result cache TTL"
    )
    docling_ttl_hours: int = Field(
        default=24,
        ge=1,
        le=168,
        description="DoclingDocument JSON cache TTL"
    )

class QdrantSettings(BaseModel):
    """Qdrant vector database connection configuration."""

    host: str = Field(
        default="hx-qdrant-server.hx.dev.local",
        description="Qdrant server hostname or IP address"
    )
    port: int = Field(
        default=6333,
        ge=1,
        le=65535,
        description="Qdrant HTTP API port"
    )
    api_key: Optional[str] = Field(
        default=None,
        description="Qdrant API authentication key (loaded from Ansible Vault if enabled)"
    )
    connection_pool_max: int = Field(
        default=10,
        ge=1,
        le=50,
        description="Maximum HTTP connection pool size"
    )
    keepalive_seconds: int = Field(
        default=60,
        ge=10,
        le=300,
        description="HTTP connection keep-alive timeout"
    )
    retry_attempts: int = Field(
        default=3,
        ge=0,
        le=10,
        description="Number of retry attempts for Qdrant operations"
    )

class LLMSettings(BaseModel):
    """LLM configuration for entity extraction via LiteLLM gateway."""

    litellm_api_base: HttpUrl = Field(
        default="http://hx-litellm-server.hx.dev.local:4000",
        description="LiteLLM gateway base URL for model routing"
    )
    entity_extraction_model: Annotated[str, StringConstraints(pattern=r"^[a-z0-9:-]+$")] = Field(
        default="gemma3:27b",
        description="Default LLM model for entity extraction (routed via LiteLLM)"
    )
    temperature: float = Field(
        default=0.1,
        ge=0.0,
        le=2.0,
        description="LLM sampling temperature (0.1 for deterministic extraction)"
    )
    max_tokens: int = Field(
        default=2048,
        ge=128,
        le=8192,
        description="Maximum LLM response tokens"
    )
    timeout_seconds: int = Field(
        default=60,
        ge=10,
        le=300,
        description="LLM API request timeout"
    )

class ProcessingSettings(BaseModel):
    """Document processing and performance configuration."""

    document_max_size_mb: int = Field(
        default=500,
        ge=1,
        le=2000,
        description="Maximum document size for processing in MB"
    )
    concurrent_workers: int = Field(
        default=4,
        ge=1,
        le=20,
        description="Number of concurrent document processing workers"
    )
    docling_cache_dir: Path = Field(
        default=Path("/var/lib/docling-mcp/cache"),
        description="Temporary document cache directory path"
    )

    @field_validator('docling_cache_dir')
    @classmethod
    def validate_cache_dir(cls, v: Path) -> Path:
        """Validate cache directory is absolute path and writable."""
        if not v.is_absolute():
            raise ValueError(f"docling_cache_dir must be absolute path, got: {v}")
        return v

class MCPServerSettings(BaseModel):
    """MCP protocol server transport configuration."""

    http_port: int = Field(
        default=8000,
        ge=1024,
        le=65535,
        description="MCP HTTP server listen port"
    )
    sse_enabled: bool = Field(
        default=True,
        description="Enable Server-Sent Events transport for progress updates"
    )
    stdio_enabled: bool = Field(
        default=True,
        description="Enable stdio transport for CLI and Claude Desktop integration"
    )
    log_level: Literal["DEBUG", "INFO", "WARN", "ERROR"] = Field(
        default="INFO",
        description="Logging verbosity level"
    )
    log_format: Literal["json", "text"] = Field(
        default="json",
        description="Log output format (json for structured logging)"
    )

class DoclingMCPConfig(BaseSettings):
    """Master configuration settings for Docling MCP Server with validation."""

    # Nested configuration groups
    redis: RedisSettings = Field(default_factory=RedisSettings)
    session: SessionSettings = Field(default_factory=SessionSettings)
    cache: CacheSettings = Field(default_factory=CacheSettings)
    qdrant: QdrantSettings = Field(default_factory=QdrantSettings)
    llm: LLMSettings = Field(default_factory=LLMSettings)
    processing: ProcessingSettings = Field(default_factory=ProcessingSettings)
    mcp: MCPServerSettings = Field(default_factory=MCPServerSettings)

    @field_validator('processing')
    @classmethod
    def validate_processing_limits(cls, v: ProcessingSettings) -> ProcessingSettings:
        """Cross-field validation for processing limits."""
        # Ensure concurrent workers don't exceed reasonable limits for available resources
        if v.concurrent_workers > 10:
            import warnings
            warnings.warn(
                f"concurrent_workers={v.concurrent_workers} may cause high memory usage "
                f"with max document size {v.document_max_size_mb}MB"
            )
        return v

    model_config = {
        "env_prefix": "",  # No prefix, use direct environment variable names
        "env_nested_delimiter": "_",  # Support nested config: REDIS_HOST, CACHE_ENABLED
        "case_sensitive": False,  # Allow lowercase environment variables
        "validate_assignment": True,  # Validate on attribute assignment
        "extra": "forbid",  # Fail if unknown environment variables detected
        "json_schema_extra": {
            "title": "Docling MCP Server Configuration",
            "description": "Comprehensive configuration schema with validation for Docling MCP Server",
            "version": "1.0.0"
        }
    }

    @classmethod
    def load_config(cls) -> "DoclingMCPConfig":
        """Load and validate configuration from environment variables with startup validation."""
        try:
            config = cls()
            # Log configuration (sanitized - no secrets)
            import logging
            logger = logging.getLogger(__name__)
            logger.info("Configuration loaded successfully")
            logger.debug(f"Redis: {config.redis.host}:{config.redis.port}")
            logger.debug(f"Qdrant: {config.qdrant.host}:{config.qdrant.port}")
            logger.debug(f"LiteLLM: {config.llm.litellm_api_base}")
            logger.debug(f"Session TTL: {config.session.ttl_hours}h")
            logger.debug(f"Cache enabled: {config.cache.enabled}")
            logger.debug(f"Document max size: {config.processing.document_max_size_mb}MB")
            logger.debug(f"Concurrent workers: {config.processing.concurrent_workers}")
            return config
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Configuration validation failed: {e}")
            raise SystemExit(1)  # Fail fast on startup
```

**Startup Configuration Validation**:
1. Load environment variables from `.env` file or system environment
2. Instantiate `DoclingMCPConfig` (triggers Pydantic validation)
3. Validate all field constraints (ranges, patterns, cross-field rules)
4. Fail fast with status code 1 if validation fails
5. Log sanitized configuration (no secrets) at DEBUG level
6. Proceed with service initialization if validation succeeds

#### Configuration Files

**Primary Config**: `.env` file (for local overrides, not committed to git)
- Location: `/home/agent0/services/operational/hx-docling-mcp/.env`
- Format: `KEY=VALUE` pairs, one per line
- Example:
  ```env
  LITELLM_API_BASE=http://hx-litellm-server.hx.dev.local:4000
  QDRANT_HOST=hx-qdrant-server.hx.dev.local
  LOG_LEVEL=DEBUG
  ```

**Systemd Service**: `/etc/systemd/system/docling-mcp.service`
- Manages service lifecycle (start, stop, restart, enable)
- Loads environment variables from `.env` file
- Auto-restart on failure (3 attempts in 5 minutes)

**Logging Config**: Embedded in Python code (no separate config file in Phase 1)
- Structured JSON logging to stdout (captured by systemd journal)
- Future: Separate `logging.yaml` for advanced configuration (Phase 2)

#### Secrets Management

**Ansible Vault Storage** (credentials stored securely):
- **LiteLLM API Key** (if LiteLLM configured with authentication in future)
  - Vault Path: `group_vars/hx_infrastructure/vault_litellm_api_key.yml`
  - Usage: Loaded into `LITELLM_API_KEY` environment variable
- **Qdrant API Key** (if Qdrant authentication enabled in future)
  - Vault Path: `group_vars/hx_infrastructure/vault_qdrant_api_key.yml`
  - Usage: Loaded into `QDRANT_API_KEY` environment variable
- **Redis Password** (if Redis authentication enabled in future)
  - Vault Path: `group_vars/hx_infrastructure/vault_redis_password.yml`
  - Usage: Loaded into `REDIS_PASSWORD` environment variable

**Phase 1 Security**: No secrets required (internal network, no authentication on dependencies)

### Security Requirements

#### Network Security

**Network Isolation**:
- **Network Zone**: Trusted internal network (hx.dev.local, 192.168.10.0/24)
- **No DMZ Exposure**: Service not accessible from DMZ or public internet
- **No External Dependencies**: All service integrations are internal (no external API calls)
- **Service Discovery**: DNS resolution via hx-dc-server (hx-dc-server.hx.dev.local) only

**TLS/SSL Strategy**:
- **Phase 1**: No TLS (internal network trust assumption)
  - **Rationale**: All communication within trusted 192.168.10.0/24 network, physically isolated development environment
  - **Risk Acceptance**: Network-level security sufficient for development/initial deployment
- **Phase 2**: mTLS (mutual TLS) for all service-to-service communication
  - **Certificate Authority**: hx-ca-server internal CA
  - **Certificate Types**: Server certificates for MCP HTTP server, client certificates for LiteLLM/Qdrant/Redis connections
  - **TLS Version**: TLS 1.3 minimum (stronger security, improved performance)
  - **Cipher Suites**: Modern cipher suites only (no deprecated algorithms)

#### Authentication & Authorization

**Phase 1 Security Model**: Network-Level Trust
- **Authentication**: None required (internal network trust)
- **Authorization**: None (all MCP clients trusted)
- **Rationale**:
  - All MCP clients are internal AI agents (no external users)
  - Network isolation (192.168.10.0/24) prevents unauthorized access
  - Development/testing phase with controlled access
- **Risk Mitigation**:
  - Network isolation enforces access control
  - Service monitoring detects unauthorized access attempts
  - Audit logging tracks all MCP tool invocations

**Phase 2 Security Model**: OAuth2 + RBAC

**OAuth2 Authentication** (via FastMCP middleware):
- **Provider**: Google OAuth2 or GitHub OAuth2 (configurable)
- **Flow**: Authorization Code Flow with PKCE (most secure for web/mobile clients)
- **Token Management**:
  - **Access Tokens**: Short-lived (15 minutes), stored in Redis session
  - **Refresh Tokens**: Long-lived (7 days), secure HttpOnly cookies
  - **Token Validation**: Verify signature, expiration, audience on every MCP request
  - **Token Refresh**: Automatic refresh via refresh token when access token expires
- **Scopes**: `mcp:read`, `mcp:write`, `mcp:admin`
- **Session Management**: Redis-backed sessions with secure session IDs (256-bit random)

**Role-Based Access Control (RBAC)**:
- **Roles**:
  - **Admin**: Full access to all MCP tools (conversion, generation, manipulation)
  - **User**: Access to conversion and generation tools (no manipulation)
  - **Read-Only**: Access to read-only tools (extract_metadata, search_document, get_session_status)
- **Authorization Enforcement**: FastMCP middleware checks role before tool execution
- **Role Assignment**: Stored in Redis session metadata, populated from OAuth2 provider claims or user database
- **Audit Trail**: All authorization decisions logged (user ID, role, tool, result)

**API Key Authentication** (Service-to-Service):
- **Use Case**: Non-interactive MCP clients (automated workflows, service integrations)
- **Key Format**: `hx-mcp-<service-name>-<random-32-chars>` (e.g., `hx-mcp-n8n-a1b2c3d4e5f6...`)
- **Key Storage**: Ansible Vault (`vault_mcp_api_keys.yml`)
- **Key Validation**: SHA-256 hash comparison, constant-time comparison to prevent timing attacks
- **Key Rotation**: 90-day rotation policy, manual procedure:
  1. Generate new API key: `openssl rand -hex 32`
  2. Edit vault: `ansible-vault edit /home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/credentials.yml`
  3. Update key value in `mcp_api_keys` section
  4. Save and close vault
  5. Restart service: `systemctl restart docling-mcp.service`
  6. Notify consuming services of new key
  7. Document rotation in change log

#### Data Security

**Data Classification**:
- **Document Content**: Sensitive (depends on user documents - may contain confidential information)
- **Knowledge Graph Entities**: Sensitive (extracted from document content)
- **Session Metadata**: Low sensitivity (session IDs, processing status)
- **Logs**: Medium sensitivity (sanitized document content, no credentials)

**Encryption at Rest**:
- **Phase 1**: Not implemented
  - **Rationale**: No persistent document storage (documents processed in-memory, not retained)
  - **Knowledge Graphs**: Stored in Qdrant (encryption managed by Qdrant service)
  - **Sessions**: Stored in Redis (ephemeral, TTL-based expiration)
- **Phase 2**: Document cache encryption
  - **Cache Location**: `/var/lib/docling-mcp/cache` (temporary document storage)
  - **Encryption Method**: LUKS (Linux Unified Key Setup) disk encryption for cache directory
  - **Key Management**: Encryption keys stored in hx-ca-server secure storage

**Encryption in Transit**:
- **Phase 1**: Not implemented (internal network trust)
- **Phase 2**: TLS 1.3 for all communications
  - **MCP HTTP**: HTTPS on port 8443 (TLS 1.3, server certificate from hx-ca-server)
  - **LiteLLM Integration**: HTTPS to hx-litellm-server (mTLS client certificate)
  - **Qdrant Integration**: HTTPS to hx-qdrant-server (mTLS client certificate)
  - **Redis Integration**: TLS-enabled Redis connection (client certificate authentication)

**Data Sanitization**:
- **Log Sanitization** (see NFR-013):
  - **Document Content**: Truncate to first 100 characters in logs (prevent log bloat, reduce exposure)
  - **Credentials**: Redact all credentials (API keys, tokens) in error messages and logs
  - **User Identifiable Information**: No PII in logs (session IDs only, no usernames/emails)
  - **Sanitization Library**: Custom sanitization module with regex-based redaction
- **Input Sanitization**:
  - **Pydantic Validation**: All MCP tool inputs validated against schemas (type checking, range validation)
  - **Path Traversal Prevention**: Block access to sensitive paths (`/etc`, `/root`, `/home`, system directories)
  - **File Size Limits**: Maximum 500MB per document (prevent resource exhaustion)
  - **File Type Validation**: MIME type validation, reject executable files (`.exe`, `.sh`, `.py`)

**Data Retention**:
- **Document Cache**: 24-hour TTL (auto-delete after processing complete)
- **Session Data**: 24-hour TTL (configurable, max 7 days)
- **Knowledge Graphs**: Persistent in Qdrant (manual deletion required)
- **Logs**: 7-day retention (systemd journal rotation), 30-day retention in centralized logging (Phase 2)

#### Threat Model

**Asset Inventory**:
- **Critical Assets**: MCP server process, document cache, knowledge graphs in Qdrant, session data in Redis
- **Data Assets**: Document content (in-transit), extracted entities/relationships, session metadata
- **Infrastructure Assets**: hx-docling-mcp-server node, LiteLLM/Qdrant/Redis service connections

**Attack Vectors & Mitigations**:

| Attack Vector | Threat Description | Likelihood | Impact | Mitigation Strategy |
|--------------|-------------------|------------|--------|---------------------|
| **Malicious Document Upload** | Attacker uploads crafted document to exploit Docling parser vulnerability (buffer overflow, code injection) | MEDIUM | HIGH | - Input validation (file size limits, type validation)<br>- Sandboxed Docling processing (future: container isolation)<br>- Regular Docling library updates (security patches)<br>- Virus scanning integration (Phase 2) |
| **MCP Tool Abuse** | Attacker invokes resource-intensive tools repeatedly (DoS via excessive processing) | LOW (Phase 1), MEDIUM (Phase 2) | MEDIUM | - Rate limiting per client IP (Phase 2: 100 req/min)<br>- Concurrent processing limits (max 4 workers)<br>- Resource monitoring and alerting (CPU/memory thresholds)<br>- Authentication required (Phase 2 blocks anonymous abuse) |
| **Path Traversal** | Attacker uses `convert_document` with malicious path to read sensitive files (`/etc/passwd`, `/root/.ssh/id_rsa`) | MEDIUM | HIGH | - Path traversal prevention (block `..`, `/etc`, `/root`, `/home`)<br>- Whitelist document directories only<br>- Filesystem sandboxing (chroot or namespace isolation - Phase 2) |
| **Dependency Exploitation** | Attacker compromises LiteLLM/Qdrant/Redis to inject malicious data or extract knowledge graphs | LOW | HIGH | - Network segmentation (isolated internal network 192.168.10.0/24)<br>- mTLS authentication (Phase 2 - mutual certificate validation)<br>- Input validation on integration responses<br>- Dependency health monitoring (detect anomalous behavior) |
| **LLM Prompt Injection** | Attacker embeds malicious prompts in document content to manipulate entity extraction (extract fake entities, poison knowledge graph) | MEDIUM | MEDIUM | - Prompt sanitization (escape special characters)<br>- Output validation (verify entity schema, confidence thresholds)<br>- LLM temperature tuning (reduce hallucination risk)<br>- Human review for critical extractions (Phase 2) |
| **Knowledge Graph Poisoning** | Attacker uploads documents with false information to corrupt knowledge graph (disinformation attack) | LOW | MEDIUM | - Source attribution (track entities to source documents)<br>- Entity confidence scoring (flag low-confidence entities)<br>- Manual review workflows (Phase 2 approval process)<br>- Version control for knowledge graphs (rollback capability) |
| **Session Hijacking** | Attacker steals session ID to access another user's documents/knowledge graphs | LOW (Phase 1), MEDIUM (Phase 2) | HIGH | - Secure session ID generation (256-bit random)<br>- HttpOnly, Secure cookie flags (Phase 2)<br>- Session IP binding (validate IP matches session)<br>- Short session TTL (24 hours max) |
| **Credential Exposure** | Attacker gains access to LiteLLM/Qdrant/Redis credentials via log leakage or config files | LOW | HIGH | - Ansible Vault for all credentials (encrypted at rest)<br>- Log sanitization (redact credentials in all logs)<br>- No credentials in environment variables (load from vault at runtime)<br>- Principle of least privilege (service accounts with minimal permissions) |
| **Insider Threat** | Malicious insider with server access extracts knowledge graphs or exfiltrates documents | LOW | HIGH | - Audit logging (all MCP tool invocations logged with user context)<br>- Role-based access control (Phase 2 - limit tool access)<br>- Regular access reviews (quarterly audits)<br>- Data exfiltration detection (monitor Qdrant query patterns) |

**Security Testing Requirements**:
- **Penetration Testing**: Phase 2 requirement before operational promotion
  - **Scope**: MCP API security, authentication bypass, path traversal, injection attacks
  - **Frequency**: Annual, after major version upgrades
- **Vulnerability Scanning**: Monthly automated scans (Python package CVEs, system packages)
- **Dependency Audits**: Quarterly review of Docling, FastMCP, LightRAG dependencies
- **Security Code Review**: Pre-deployment review by frank-lucas (Security Specialist)

**Incident Response**:
- **Detection**: Security alerts on suspicious activity (failed authentication, path traversal attempts, rate limit violations)
- **Response Procedures**:
  1. **Isolate**: Identify and disable compromised session, investigate source IP
  2. **Investigate**: Review audit logs, identify attack vector, assess damage
  3. **Contain**: Patch vulnerability, rotate credentials if compromised
  4. **Recover**: Restore knowledge graphs from backup (if poisoned), restart service if necessary
  5. **Report**: Document incident, update threat model, improve defenses
- **Escalation Path**: william-chen (Infrastructure) → frank-lucas (Security) → CAIO (for critical incidents)

#### Ansible Vault Credential Structure

**Vault File Organization** (Phase 2 - when authentication enabled):
```
/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/vault/
├── credentials.yml              # Main vault file (encrypted)
├── .vault_password              # Vault password file (gitignored)
└── README.md                    # Vault usage instructions
```

**credentials.yml Structure**:
```yaml
---
# LiteLLM Gateway Credentials (if LiteLLM authentication enabled)
litellm:
  api_base: "http://hx-litellm-server.hx.dev.local:4000"
  api_key: "{{ vault_litellm_api_key }}"  # Placeholder for future
  timeout_seconds: 60

# Qdrant Vector Database Credentials (if Qdrant authentication enabled)
qdrant:
  host: "hx-qdrant-server.hx.dev.local"
  port: 6333
  api_key: "{{ vault_qdrant_api_key }}"  # Placeholder for future
  collection_entities: "hx_docling_mcp_entities"
  collection_relationships: "hx_docling_mcp_relationships"
  grpc_enabled: false  # Use HTTP API for simplicity

# Redis Session Store Credentials (if Redis authentication enabled)
redis:
  host: "hx-redis-server.hx.dev.local"
  port: 6379
  password: "{{ vault_redis_password }}"  # Placeholder for future
  db: 0  # Database index for Docling MCP sessions
  max_connections: 10

# OAuth2 Provider Credentials (Phase 2)
oauth2:
  provider: "google"  # or "github"
  client_id: "{{ vault_oauth2_client_id }}"
  client_secret: "{{ vault_oauth2_client_secret }}"
  redirect_uri: "https://hx-docling-mcp-server.hx.dev.local:8443/oauth2/callback"
  scopes:
    - "openid"
    - "email"
    - "profile"

# MCP API Keys (Service-to-Service Authentication)
mcp_api_keys:
  n8n_workflow_service:
    key: "{{ vault_mcp_api_key_n8n }}"
    permissions:
      - "mcp:read"
      - "mcp:write"
    expires: "2026-12-31"
  fastmcp_client_test:
    key: "{{ vault_mcp_api_key_test }}"
    permissions:
      - "mcp:read"
    expires: "2026-06-30"

# TLS/mTLS Certificates (Phase 2)
tls:
  server_cert_path: "/etc/ssl/hx/docling-mcp-server.crt"
  server_key_path: "/etc/ssl/hx/docling-mcp-server.key"
  ca_cert_path: "/etc/ssl/hx/ca-cert.pem"
  client_cert_path: "/etc/ssl/hx/docling-mcp-client.crt"  # For outbound mTLS
  client_key_path: "/etc/ssl/hx/docling-mcp-client.key"

# Service Account (if needed for system operations)
service_account:
  username: "docling-mcp@hx.dev.local"
  password: "{{ vault_service_account_password }}"  # If needed for AD integration
```

**Vault Access Instructions** (`vault/README.md`):
```markdown
# Docling MCP Credentials Vault

## Viewing Credentials
ansible-vault view credentials.yml

## Editing Credentials
ansible-vault edit credentials.yml

## Encrypting New File
ansible-vault encrypt credentials.yml

## Decrypting (for deployment)
ansible-vault decrypt credentials.yml --output=/tmp/credentials.yml
# Use in deployment, then delete /tmp/credentials.yml

## Vault Password
Stored in `.vault_password` file (gitignored)
Standard password: See `vault/credentials.yml` (Ansible Vault encrypted)
```

**Phase 1 Reality Check**:
- **No credentials required**: LiteLLM, Qdrant, Redis currently operate without authentication
- **Vault prepared for future**: Structure defined, but `credentials.yml` not created until Phase 2
- **Service account exists**: `docling-mcp@hx.dev.local` created via samba-tool (password stored in `vault/credentials.yml`)

#### Compliance & Audit

**GDPR/Privacy Compliance**:
- **Phase 1**: Not applicable (internal documents only, no personal data processing)
- **Phase 2**: If processing user documents with personal data:
  - **Data Minimization**: Only extract entities/relationships required for knowledge graph
  - **Right to Erasure**: API endpoint to delete user knowledge graphs from Qdrant
  - **Data Portability**: Export knowledge graphs in JSON format
  - **Consent Management**: Require explicit consent before processing personal documents
  - **Privacy Policy**: Document data processing practices, retention policies

**Audit Logging**:
- **What is Logged**: All MCP tool invocations, authentication events, authorization decisions, security events
- **Log Format**: JSON structured logs with fields:
  ```json
  {
    "timestamp": "2025-11-25T10:30:15.123Z",
    "level": "INFO",
    "component": "security_audit",
    "event_type": "mcp_tool_invocation",
    "user_id": "session_abc123",
    "tool_name": "convert_document",
    "parameters_hash": "sha256:a1b2c3...",  # Hash of sanitized parameters
    "result": "success",
    "duration_ms": 3500,
    "source_ip": "hx-n8n-server.hx.dev.local"
  }
  ```
- **Retention**: 30 days (compliance requirement), 90 days in centralized logging (Phase 2)
- **Immutability**: Logs written to append-only storage (prevent tampering)
- **Access Control**: Audit logs readable only by admin role, immutable by all users

**Security Configuration Baselines**:
- **Operating System**: Ubuntu 24.04 LTS with security updates applied monthly
- **Python Packages**: Regular updates for security patches (Docling, FastMCP, dependencies)
- **Network Security**: Internal network isolation (192.168.10.0/24) with no external exposure
- **Service Hardening**:
  - Systemd service runs as non-root user (`docling-mcp` system account)
  - Resource limits enforced (4GB memory, 2 CPU cores soft limit)
  - No shell access for service account (login shell: `/usr/sbin/nologin`)
  - Working directory restricted (`/var/lib/docling-mcp`, no access to `/root`, `/home`)

**Certificate Management** (Phase 2):
- **Certificate Authority**: hx-ca-server internal CA
- **Certificate Lifecycle**:
  - **Generation**: Coordinate with frank-lucas (Security Specialist) for CSR creation
  - **Signing**: CA signs certificates with 365-day validity
  - **Installation**: Certificates deployed to `/etc/ssl/hx/` directory
  - **Rotation**: 30 days before expiration, manual procedure:
    1. Coordinate with frank-lucas to generate new CSR
    2. Submit CSR to hx-ca-server for signing
    3. Receive new certificate from frank-lucas
    4. Stop service: `systemctl stop docling-mcp.service`
    5. Backup old certificates: `cp /etc/ssl/hx/*.crt /opt/docling-mcp/backups/certs/`
    6. Install new certificates to `/etc/ssl/hx/`
    7. Update file permissions: `chown docling-mcp:docling-mcp /etc/ssl/hx/*.crt`
    8. Start service: `systemctl start docling-mcp.service`
    9. Verify health check: `curl https://hx-docling-mcp-server.hx.dev.local:8443/health`
    10. Document rotation in change log
  - **Revocation**: CRL (Certificate Revocation List) checked on startup
- **Certificate Types Required**:
  - **Server Certificate**: `docling-mcp-server.crt` (for HTTPS MCP server)
  - **Client Certificate**: `docling-mcp-client.crt` (for mTLS to LiteLLM/Qdrant/Redis)
  - **CA Certificate**: `ca-cert.pem` (for validating peer certificates)

### Monitoring & Observability

#### Health Checks

**Primary Health Check**: HTTP endpoint `/health`
- **URL**: `http://hx-docling-mcp-server.hx.dev.local:8000/health`
- **Response Format**: JSON
  ```json
  {
    "status": "healthy",  // healthy | degraded | unhealthy
    "version": "1.0.0",
    "dependencies": {
      "litellm": {"status": "healthy", "latency_ms": 50},
      "qdrant": {"status": "healthy", "latency_ms": 20},
      "redis": {"status": "degraded", "error": "connection timeout"}
    },
    "uptime_seconds": 86400
  }
  ```
- **Check Interval**: 30 seconds (external monitoring system)
- **Timeout**: 2 seconds (fail if health check exceeds timeout)

**Dependency Health Checks**:
- **LiteLLM**: GET `/health` endpoint, expect 200 OK
- **Qdrant**: GET `/collections` endpoint, expect 200 OK
- **Redis**: PING command, expect PONG response

#### Key Metrics

**Performance Metrics**:
- `document_processing_duration_seconds{format="pdf|docx|..."}`: Histogram (p50, p95, p99)
- `entity_extraction_duration_seconds`: Histogram (LLM inference time)
- `mcp_tool_invocation_duration_seconds{tool_name="..."}`: Histogram
- `qdrant_write_duration_seconds`: Histogram (vector upsert time)

**Throughput Metrics**:
- `documents_processed_total{format="...", status="success|error"}`: Counter
- `mcp_requests_total{transport="http|sse|stdio", status="success|error"}`: Counter
- `entities_extracted_total`: Counter
- `relationships_extracted_total`: Counter

**Error Metrics**:
- `document_conversion_errors_total{format="...", error_type="..."}`: Counter
- `llm_api_errors_total{model="...", error_type="timeout|rate_limit|..."}`: Counter
- `qdrant_write_errors_total{error_type="..."}`: Counter
- `redis_errors_total{operation="get|set|..."}`: Counter

**Resource Metrics**:
- `process_cpu_usage_percent`: Gauge
- `process_memory_usage_bytes`: Gauge
- `disk_usage_bytes{mount="/var/lib/docling-mcp"}`: Gauge

**Redis Session & Cache Metrics**:
- `redis_operation_duration_seconds{operation="get|set|delete|sadd|hset|..."}`: Histogram (p50, p95, p99)
- `redis_connection_pool_size{state="active|idle"}`: Gauge
- `redis_connection_errors_total{error_type="connection|timeout|auth|..."}`: Counter
- `redis_operation_errors_total{operation="...", error_type="..."}`: Counter
- `session_ttl_extensions_total`: Counter (sliding window TTL extensions)
- `session_evictions_total{reason="ttl_expired|manual_delete|redis_eviction"}`: Counter
- `session_operations_total{operation="create|get|update|delete"}`: Counter
- `cache_hits_total{cache_type="metadata|entities|docling"}`: Counter
- `cache_misses_total{cache_type="..."}`: Counter
- `cache_hit_ratio{cache_type="..."}`: Gauge (computed: hits / (hits + misses))
- `cache_size_bytes{cache_type="..."}`: Gauge (total size of cached data)
- `cache_evictions_total{cache_type="...", reason="ttl|memory|manual"}`: Counter

**Metric Exposure**: Prometheus-compatible endpoint `/metrics` (Phase 2 - when hx-metric-server operational)

#### Logging Requirements

**Log Levels**:
- **DEBUG**: Detailed diagnostics (MCP request/response payloads, Docling internal processing steps)
- **INFO**: Normal operations (MCP tool invocations, document processing start/complete, dependency health checks)
- **WARN**: Degraded state (Redis unavailable, LLM API slow response, large document processing)
- **ERROR**: Failures (document conversion errors, entity extraction failures, dependency unavailable)

**Log Structure** (JSON format):
```json
{
  "timestamp": "2025-11-25T10:30:15.123Z",
  "level": "INFO",
  "component": "mcp_server",
  "message": "MCP tool invoked",
  "context": {
    "tool_name": "convert_document",
    "session_id": "abc123",
    "document_id": "doc456",
    "format": "pdf",
    "duration_ms": 3500
  }
}
```

**Log Retention**:
- **Local Storage**: 7 days (systemd journal rotation)
- **Centralized Logging**: Future (when hx-logging-server operational)

**Log Destinations**:
- **stdout**: Captured by systemd journal (`journalctl -u docling-mcp.service`)
- **File**: Optional file logging to `/var/log/docling-mcp/` (disabled by default)

#### Alerting Requirements

**Critical Alerts** (immediate notification):
- Service down (health check fails for 3 consecutive checks)
- All dependencies unavailable (LiteLLM, Qdrant, Redis all unhealthy)
- Disk space <10% (document cache full)

**Warning Alerts** (notification within 15 minutes):
- Dependency degraded (1 of 3 dependencies unhealthy)
- High error rate (>5% document conversion failures over 10 minutes)
- Performance degradation (p95 latency >2x baseline)

**Alert Destinations**: Future (Phase 2 - email, Slack integration when monitoring infrastructure operational)

---

## Success Criteria

### Deployment Success

- **SC-001**: MCP server responds to health check within 2 seconds with `status: "healthy"`
  - **Validation Method**: Execute `curl http://hx-docling-mcp-server.hx.dev.local:8000/health` 10 times, measure response time and status
  - **Expected Result**: 10/10 requests return 200 OK, response time <2s, JSON contains `status: "healthy"`, dependency health checks pass
  - **Automated Test**: TC-INT-005 (LiteLLM connectivity), TC-INT-006 (Qdrant connectivity), TC-INT-007 (Redis connectivity)
  - **Test Execution**: Run during every deployment validation phase
  - **Pass Criteria**: 100% success rate (10/10), average response time <1s, no dependency health failures
  - **Evidence Required**: HTTP response logs, timing measurements, dependency health status JSON

- **SC-002**: All 19 MCP tools discoverable via MCP protocol tool listing
  - **Validation Method**: Invoke MCP tool discovery endpoint, parse returned tool schemas, count tools, validate schema structure
  - **Expected Result**: JSON array with 19 tool definitions, each containing name, description, inputSchema, outputSchema
  - **Automated Test**: TC-UNIT-011 (output schema validation), custom MCP protocol compliance test
  - **Test Execution**: Run during integration testing phase
  - **Pass Criteria**: Tool count = 19, all schemas valid Pydantic models, no missing required fields
  - **Evidence Required**: Tool discovery response JSON, schema validation report

- **SC-003**: Service successfully converts sample documents from all supported formats (PDF, DOCX, PPTX, XLSX, HTML, images)
  - **Validation Method**: Execute multimodal test suite (TC-MM-001 through TC-MM-014), process 16 sample documents (14 formats + corrupted + zero-byte)
  - **Expected Result**: ≥15/16 documents process successfully (≥93.75% success rate), failures only for known limitations (corrupted, zero-byte, poor quality OCR)
  - **Automated Test**: All multimodal tests (TC-MM-001 to TC-MM-014)
  - **Test Execution**: Run weekly during development, before every deployment
  - **Pass Criteria**: Critical formats (PDF, DOCX, PPTX, XLSX, HTML) 100% pass, non-critical formats (EPUB, RTF) ≥95% pass, graceful errors for invalid inputs
  - **Evidence Required**: Test execution report with per-format success rates, sample output DoclingDocuments, error messages for failures

- **SC-004**: Knowledge graph generation creates entities and relationships, stores in Qdrant successfully
  - **Validation Method**: Execute TC-INT-002 (knowledge graph E2E), process test corpus (10 research papers), query Qdrant collections, validate entity/relationship storage
  - **Expected Result**: 500+ entities extracted from corpus (50+ per document average), 1000+ relationships, Qdrant collections populated and queryable
  - **Automated Test**: TC-INT-002 (generate_knowledge_graph E2E), TC-E2E-001 (complete RAG pipeline)
  - **Test Execution**: Run before deployment, after any LightRAG/Qdrant configuration changes
  - **Pass Criteria**: Entity count ≥500, relationship count ≥1000, Qdrant query success rate 100%, graph density (relationships/entities) ≥2.0
  - **Evidence Required**: Qdrant collection statistics, sample entity/relationship JSON, graph density metrics, query test results

- **SC-005**: All integration tests pass (LiteLLM, Qdrant, Redis connectivity and functionality)
  - **Validation Method**: Execute full integration test suite (TC-INT-001 through TC-INT-008), validate all dependency connections and operations
  - **Expected Result**: 8/8 integration tests pass, all dependencies healthy, all MCP tools functional
  - **Automated Test**: TC-INT-005 (LiteLLM), TC-INT-006 (Qdrant), TC-INT-007 (Redis), TC-INT-008 (Ollama routing), TC-INT-001 to TC-INT-004 (MCP tool integration)
  - **Test Execution**: Run daily during development, before every deployment
  - **Pass Criteria**: 100% integration test pass rate (8/8), zero connection errors, all dependency health checks pass
  - **Evidence Required**: Pytest integration test report, dependency health check logs, connection pool statistics

### Operational Success

- **SC-006**: Service maintains 99%+ uptime during 7-day testing period in non-operational environment
  - **Validation Method**: Deploy to non-operational, run automated health check script every 30 seconds for 7 days (20,160 checks), calculate uptime percentage
  - **Expected Result**: ≥19,958 successful health checks (99%), <202 failures allowed (1%), no unplanned service crashes
  - **Automated Test**: Continuous health check monitoring script, TC-PERF-007 (48-hour soak test component)
  - **Test Execution**: Run once before operational promotion (7-day continuous monitoring)
  - **Pass Criteria**: Uptime ≥99%, mean time between failures (MTBF) ≥24 hours, all failures due to planned maintenance or dependency issues (not service crashes)
  - **Evidence Required**: Health check log (7 days), uptime calculation report, failure analysis (root causes documented), systemd service status history

- **SC-007**: Document processing performance meets NFR-001 targets (95th percentile latency)
  - **Validation Method**: Execute TC-PERF-001 (latency baseline), process 160 documents (100 small, 50 medium, 10 large), measure p95 latency per category
  - **Expected Result**: Small <5s (p95), medium <30s (p95), large <2min (p95)
  - **Automated Test**: TC-PERF-001 (conversion latency baseline)
  - **Test Execution**: Run before deployment, weekly during development
  - **Pass Criteria**: Small p95 ≤5s (95/100 documents), medium p95 ≤30s (48/50 documents), large p95 ≤120s (10/10 documents)
  - **Evidence Required**: Performance benchmark report with latency distributions (p50, p95, p99), per-format latency breakdown, outlier analysis

- **SC-008**: Entity extraction quality meets baseline (100+ entities per 10K words, 90%+ precision on manual review)
  - **Validation Method**: Execute TC-INT-002 with entity-rich documents, calculate entity density, manual precision spot-check (sample 100 entities randomly, verify accuracy)
  - **Expected Result**: ≥100 entities per 10K words, manual precision review shows ≥90 accurate entities out of 100 sampled
  - **Automated Test**: TC-INT-002 (knowledge graph generation), TC-E2E-002 (multi-document graph)
  - **Manual Test**: Random sample entity precision check by julia-santos
  - **Test Execution**: Run before deployment, after LightRAG model changes
  - **Pass Criteria**: Entity density ≥100 per 10K words, precision ≥90%, no systematic extraction failures (e.g., missing all dates, all organizations)
  - **Evidence Required**: Entity density report (entities/word count), manual precision review results (spreadsheet with 100 sampled entities, accuracy scores), error pattern analysis

- **SC-009**: Zero critical errors during 48-hour continuous operation test
  - **Validation Method**: Execute TC-PERF-007 (48-hour soak test), submit 10 documents/hour (480 total), monitor error logs continuously
  - **Expected Result**: Zero ERROR-level log entries, zero service crashes, zero unhandled exceptions
  - **Automated Test**: TC-PERF-007 (soak test)
  - **Test Execution**: Run once before operational promotion (48-hour continuous load)
  - **Pass Criteria**: 0 ERROR-level logs, 0 crashes, 0 unhandled exceptions, <5 WARN-level logs (non-critical warnings acceptable)
  - **Evidence Required**: Complete error log (48 hours), log level distribution report, WARN-level log analysis (root causes documented)

- **SC-010**: Service handles dependency failures gracefully (LiteLLM unavailable → document conversion still works, Redis unavailable → stateless mode enabled)
  - **Validation Method**: Execute all chaos engineering tests (TC-CHAOS-001 through TC-CHAOS-008), validate graceful degradation, recovery, error messaging
  - **Expected Result**: All 8 chaos scenarios pass, service degrades gracefully (no crashes), features disable appropriately, recovery successful after dependency restoration
  - **Automated Test**: TC-CHAOS-001 (LiteLLM failure), TC-CHAOS-002 (Qdrant failure), TC-CHAOS-003 (Redis failure), TC-CHAOS-004 (multiple failures), TC-CHAOS-005 to TC-CHAOS-008 (network, crash, disk, timeout scenarios)
  - **Test Execution**: Run before deployment, after resilience logic changes
  - **Pass Criteria**: 8/8 chaos tests pass, zero service crashes, health status correctly reflects degradation (healthy → degraded → unhealthy), recovery time <5 minutes after dependency restoration
  - **Evidence Required**: Chaos test execution report, health status transitions log, error message samples (verify clarity and actionability), recovery time measurements

### Quality Metrics Targets

- **Test Coverage**: 80%+ unit test coverage, 100% integration test coverage (all MCP tools tested)
  - **Validation Method**: Run `pytest --cov=docling_mcp --cov-report=term --cov-report=html`, parse coverage report
  - **Expected Result**: Overall coverage ≥80%, critical components (MCP tools, entity extraction, integration manager) ≥90%
  - **Test Execution**: Run with every test suite execution
  - **Evidence Required**: Pytest coverage report (HTML), coverage badge, per-module coverage breakdown

- **Document Processing Accuracy**: 95%+ successful conversions across all formats
  - **Validation Method**: Execute multimodal test suite, calculate success rate (successful conversions / total attempts)
  - **Expected Result**: ≥95% success rate (15/16 test documents), failures only for known limitations
  - **Test Execution**: Run weekly, before deployment
  - **Evidence Required**: Format-by-format success rates, failure root cause analysis

- **Knowledge Graph Quality**: 100+ entities per 10K words (LightRAG baseline), 90%+ entity precision
  - **Validation Method**: See SC-008 validation method
  - **Expected Result**: Entity density ≥100/10K, precision ≥90%
  - **Test Execution**: Run before deployment
  - **Evidence Required**: Entity density report, precision review results

- **API Compliance**: 100% MCP protocol compliance (all 19 tools conform to MCP spec)
  - **Validation Method**: Execute TC-UNIT-011 (output schema validation), TC-UNIT-012 (error handling), custom MCP protocol validator
  - **Expected Result**: All 19 tools pass MCP schema validation, error responses conform to MCP error spec
  - **Test Execution**: Run daily during development
  - **Evidence Required**: MCP protocol validation report, schema conformance test results

- **Documentation Completeness**: 100% (charter, spec, architecture, plan, test plan, runbooks all complete)
  - **Validation Method**: File existence check, peer review completion tracking, documentation quality checklist validation
  - **Expected Result**: All 6 governance documents present, peer-reviewed, quality checklist passed
  - **Test Execution**: Run before operational promotion
  - **Evidence Required**: Document checklist report, peer review sign-offs, quality gate validation results

---

## Architecture Overview

### System Context

**Infrastructure Layer**: Layer 4 (Agentic & Toolchain) - Document Processing MCP Server
**Service Category**: Integration Service (Document Processing + RAG Pipeline)

**System Context Diagram:**

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        HX-Infrastructure Ecosystem                          │
│                                                                              │
│  ┌─────────────────┐          ┌──────────────────────────────────┐         │
│  │  AI Agents      │──MCP────▶│   Docling MCP Server             │         │
│  │  (MCP Clients)  │          │   (hx-docling-mcp-server)        │         │
│  │                 │          │   hx-docling-mcp-server.hx.dev.local:8000            │         │
│  └─────────────────┘          └──────────────────────────────────┘         │
│         │                                  │                                │
│         │                                  │                                │
│         │                     ┌────────────┴─────────────┐                 │
│         │                     │                          │                 │
│         │                     ▼                          ▼                 │
│         │          ┌────────────────────┐   ┌───────────────────┐         │
│         │          │  LiteLLM Gateway   │   │  Qdrant Vector DB  │         │
│         │          │  (LLM Abstraction) │   │  (Knowledge Graph) │         │
│         │          │  hx-litellm-server.hx.dev.local    │   │  hx-qdrant-server.hx.dev.local    │         │
│         │          └────────────────────┘   └───────────────────┘         │
│         │                     │                          │                 │
│         │                     │                          │                 │
│         │        ┌────────────┴───────────┬──────────────┘                 │
│         │        │                        │                                │
│         │        ▼                        ▼                                │
│         │  ┌───────────┐  ┌───────────┐  ┌───────────┐                    │
│         │  │  Ollama1  │  │  Ollama2  │  │  Ollama3  │                    │
│         │  │  (LLMs)   │  │  (Code)   │  │  (Embed)  │                    │
│         │  │.204:11434 │  │.205:11434 │  │.206:11434 │                    │
│         │  └───────────┘  └───────────┘  └───────────┘                    │
│         │                                                                   │
│         │                        ┌──────────────────┐                      │
│         └───────────────────────▶│  Redis Cache     │                      │
│                                   │  (Sessions)      │                      │
│                                   │  hx-redis-server.hx.dev.local  │                      │
│                                   └──────────────────┘                      │
└────────────────────────────────────────────────────────────────────────────┘
```

**Integration Summary**:
- **Inbound**: AI Agents (MCP clients) invoke document processing tools via HTTP/SSE/stdio
- **Outbound**: LiteLLM (entity extraction), Qdrant (knowledge graph storage), Redis (session state)

### High-Level Architecture (3-Layer)

**Layer 1: MCP Protocol Interface**

#### FastMCP Server Initialization
- **Framework Version**: FastMCP >=0.2 with MCP protocol 1.0 compliance
- **Server Instance**: Created via `mcp = FastMCP("docling-mcp-server", version="1.0.0")`
- **Transport Configuration**:
  - **HTTP Transport** (Primary): Uvicorn ASGI server on `0.0.0.0:8000`
    - Path: `/mcp/` base path for all MCP endpoints
    - Tool discovery: `POST /mcp` with `{"jsonrpc":"2.0","method":"tools/list","id":1}` returns tool manifest
    - Tool execution: `POST /mcp` with `{"jsonrpc":"2.0","method":"tools/call","params":{...},"id":2}` invokes tools
    - Health check: `GET /health` (non-MCP endpoint for monitoring)
  - **SSE Transport**: Server-Sent Events on `/mcp/sse` for streaming responses
    - Connection: `GET /mcp/sse` establishes event stream
    - Event format: `data: {"jsonrpc":"2.0","result":{...}}\n\n`
    - Use case: Long-running document conversions with progress updates
    - Keepalive: Send `ping` event every 30 seconds to maintain connection
  - **stdio Transport**: JSON-RPC over stdin/stdout for CLI integration
    - Activation: `python -m docling_mcp.server --transport stdio`
    - Input: Read JSON-RPC requests from stdin (one request per line)
    - Output: Write JSON-RPC responses to stdout (one response per line)
    - Use case: Shell scripts, automation pipelines, local testing

#### MCP Protocol Compliance
- **JSON-RPC Version**: 2.0 (strict adherence)
- **Protocol Version**: MCP 1.0 specification
- **Tool Discovery Endpoint**: `tools/list` returns all 19 tools with Pydantic-generated schemas
  - Request: `{"jsonrpc":"2.0","method":"tools/list","id":1}`
  - Response: Array of tool definitions with name, description, inputSchema (JSON Schema from Pydantic)
- **Tool Execution Endpoint**: `tools/call` invokes tool with validated parameters
  - Request: `{"jsonrpc":"2.0","method":"tools/call","params":{"name":"convert_document","arguments":{"source":"file:///doc.pdf"}},"id":2}`
  - Response: `{"jsonrpc":"2.0","result":{"content":[{"type":"text","text":"...docling_json..."}]},"id":2}`
- **Error Responses**: MCP-compliant error codes
  - `-32700`: Parse error (invalid JSON)
  - `-32600`: Invalid request (missing required fields)
  - `-32601`: Method not found (unknown tool name)
  - `-32602`: Invalid params (schema validation failure)
  - `-32603`: Internal error (uncaught exception in tool execution)
  - Custom codes: `-1` for document processing errors, `-2` for integration failures

#### Tool Registration Patterns

- **Decorator-Based Registration**: Use `@mcp.tool()` to register each of 19 tools with comprehensive input validation

**Example: convert_document with Field Validators**
```python
from pydantic import BaseModel, Field, field_validator
from typing import Annotated, Optional
import os
import re

class ConvertDocumentInput(BaseModel):
    """Input schema for convert_document MCP tool with comprehensive validation."""

    source: Annotated[str, Field(
        min_length=1,
        max_length=2000,
        description="File path (file://), HTTP URL (http/https://), or base64 data URI (data:)",
        json_schema_extra={
            "examples": [
                "file:///opt/docs/sample.pdf",
                "https://example.com/document.pdf",
                "data:application/pdf;base64,JVBERi0xLjQK..."
            ]
        }
    )]
    format: Optional[DocumentFormat] = Field(
        default=None,
        description="Optional format hint for document type detection (auto-detected if omitted)"
    )

    @field_validator('source')
    @classmethod
    def validate_source(cls, v: str) -> str:
        """Validate document source with security checks."""
        # Path traversal prevention
        if '..' in v:
            raise ValueError("Path traversal detected: source cannot contain '..'")

        # File path validation
        if v.startswith('file://'):
            path = v[7:]  # Remove file:// prefix
            # Block access to sensitive directories
            forbidden_paths = ['/etc', '/root', '/home', '/var/lib/ansible', '/opt/vault']
            for forbidden in forbidden_paths:
                if path.startswith(forbidden):
                    raise ValueError(
                        f"Access denied to sensitive path: {forbidden}. "
                        f"Allowed directories: /opt/docling-mcp/data/, /tmp/docling-uploads/"
                    )
            # Ensure absolute path
            if not os.path.isabs(path):
                raise ValueError(f"File path must be absolute, got: {path}")
            return v

        # URL validation
        elif v.startswith(('http://', 'https://')):
            import ipaddress
            from urllib.parse import urlparse

            # Basic URL format check
            url_pattern = r'^https?://[\w\-\.]+(:\d+)?(/[\w\-\./%?&=]*)?$'
            if not re.match(url_pattern, v):
                raise ValueError(f"Invalid URL format: {v}")

            # SSRF protection with configurable allowlist
            # Parse URL to extract host
            parsed = urlparse(v)
            host = parsed.hostname or parsed.netloc.split(':')[0]

            # ALWAYS deny: loopback, 0.0.0.0, metadata endpoints
            always_denied = ['localhost', '127.0.0.1', '::1', '0.0.0.0', '169.254.169.254']
            if host.lower() in always_denied:
                raise ValueError(
                    f"URL access denied to blocked host: {host}. "
                    f"Loopback and metadata endpoints always blocked."
                )

            # Check against allowed CIDRs (environment variable: ALLOWED_CIDRS)
            # Default: deny all private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
            # Example: ALLOWED_CIDRS="192.168.10.0/24,10.0.1.0/24" to allow specific subnets
            allowed_cidrs_str = os.getenv('ALLOWED_CIDRS', '')
            allowed_cidrs = [ipaddress.ip_network(cidr.strip()) for cidr in allowed_cidrs_str.split(',') if cidr.strip()]

            # Resolve host to IP address
            try:
                # Handle literal IP addresses
                try:
                    ip = ipaddress.ip_address(host)
                except ValueError:
                    # Host is domain name - would resolve via DNS in runtime
                    # For spec purposes, document that resolution happens at runtime
                    # and IP must be in allowed CIDRs
                    return v

                # Check if IP is in any allowed CIDR
                if allowed_cidrs:
                    if not any(ip in cidr for cidr in allowed_cidrs):
                        raise ValueError(
                            f"URL access denied: {host} ({ip}) not in allowed CIDRs. "
                            f"Configure ALLOWED_CIDRS environment variable to permit internal hosts."
                        )
                else:
                    # No allowlist configured - deny all private IPs
                    if ip.is_private:
                        raise ValueError(
                            f"URL access denied to private network: {host} ({ip}). "
                            f"Set ALLOWED_CIDRS environment variable to allow specific internal networks. "
                            f"Example: ALLOWED_CIDRS='192.168.10.0/24,10.0.1.0/24'"
                        )
            except ValueError as e:
                # Re-raise validation errors
                raise

            return v

        # Base64 data URI validation
        elif v.startswith('data:'):
            # Validate data URI format: data:<mimetype>;base64,<data>
            data_uri_pattern = r'^data:[\w/\-]+;base64,[A-Za-z0-9+/=]+$'
            if not re.match(data_uri_pattern, v):
                raise ValueError(
                    f"Invalid data URI format. Expected: data:<mimetype>;base64,<base64_data>"
                )
            # Check data size (prevent excessive memory usage)
            # Base64 encoding increases size by ~1.33x, so 500MB limit = ~665MB base64
            base64_data = v.split(',')[1]
            if len(base64_data) > 700_000_000:  # ~700MB base64 limit
                raise ValueError(
                    f"Data URI too large: {len(base64_data)} bytes. "
                    f"Maximum allowed: 700MB (base64 encoded)"
                )
            return v

        else:
            raise ValueError(
                f"Invalid source format. Must start with 'file://', 'http://', 'https://', or 'data:'. "
                f"Got: {v[:50]}..."
            )

@mcp.tool(description="Convert document to DoclingDocument JSON format with structure preservation")
async def convert_document(
    input_params: ConvertDocumentInput,
) -> DoclingDocument:
    """
    Convert multimodal document to structured DoclingDocument JSON format.

    Args:
        input_params: Validated input parameters (source, optional format)

    Returns:
        DoclingDocument: Parsed document with structure (headings, tables, lists, images)

    Raises:
        ValueError: If document format unsupported or file not found
        ValidationError: If input validation fails (path traversal, invalid URL, etc.)
        TimeoutError: If conversion exceeds 120 seconds
    """
    # FastMCP automatically validates input_params against ConvertDocumentInput schema
    # Any validation error results in MCP error response -32602 (Invalid params)

    # Extract validated parameters
    source = input_params.source
    format_hint = input_params.format

    # Additional file existence check for file:// sources
    if source.startswith('file://'):
        file_path = source[7:]
        if not os.path.exists(file_path):
            raise FileNotFoundError(
                f"Document not found: {file_path}. "
                f"Ensure file exists and has read permissions."
            )

        # File size validation (prevent processing massive files)
        file_size_mb = os.path.getsize(file_path) / (1024 * 1024)
        max_size_mb = 500  # From config
        if file_size_mb > max_size_mb:
            raise ValueError(
                f"Document size {file_size_mb:.1f}MB exceeds maximum {max_size_mb}MB"
            )

    # Proceed with Docling conversion (validated input, safe to process)
    docling_result = await docling_processor.convert(source, format_hint)
    return docling_result
```

**Example: generate_knowledge_graph with Cross-Field Validation**
```python
class GenerateKnowledgeGraphInput(BaseModel):
    """Input schema for knowledge graph generation with entity/relationship constraints."""

    docling_document: str = Field(
        description="DoclingDocument JSON string from convert_document output"
    )
    llm_model: str = Field(
        default="gemma3:27b",
        pattern=r"^[a-z0-9:-]+$",
        description="LLM model for entity extraction (routed via LiteLLM)"
    )
    entity_types: Optional[List[EntityType]] = Field(
        default=None,
        max_length=13,
        description="Filter entity extraction to specific types (default: all types)"
    )
    confidence_threshold: ConfidenceScore = Field(
        default=0.5,
        description="Minimum confidence score for entities/relationships (0.0 to 1.0)"
    )
    max_entities: int = Field(
        default=1000,
        ge=1,
        le=10000,
        description="Maximum number of entities to extract (prevent memory overflow)"
    )

    @field_validator('docling_document')
    @classmethod
    def validate_docling_json(cls, v: str) -> str:
        """Validate DoclingDocument JSON structure."""
        import json
        try:
            doc_dict = json.loads(v)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in docling_document: {e}")

        # Validate required DoclingDocument fields
        required_fields = ['doc_items', 'metadata']
        for field in required_fields:
            if field not in doc_dict:
                raise ValueError(
                    f"Missing required field '{field}' in DoclingDocument. "
                    f"Expected format from convert_document output."
                )

        # Validate document not empty
        if not doc_dict.get('doc_items'):
            raise ValueError("DoclingDocument is empty (no doc_items). Cannot extract entities.")

        return v

    @field_validator('confidence_threshold')
    @classmethod
    def validate_confidence_reasonable(cls, v: float) -> float:
        """Warn if confidence threshold too high."""
        if v > 0.9:
            import warnings
            warnings.warn(
                f"confidence_threshold={v} is very high. "
                f"May result in very few entities extracted."
            )
        return v

@mcp.tool(description="Generate knowledge graph with entities and relationships via LightRAG")
async def generate_knowledge_graph(
    input_params: GenerateKnowledgeGraphInput,
) -> KnowledgeGraphResult:
    """
    Extract entities and relationships from DoclingDocument, store in Qdrant.

    Args:
        input_params: Validated input parameters

    Returns:
        KnowledgeGraphResult: Entity/relationship counts, Qdrant collection IDs, statistics

    Raises:
        ValueError: If DoclingDocument invalid or LLM extraction fails
        QdrantConnectionError: If Qdrant unavailable
    """
    # FastMCP validates input_params automatically
    # Proceed with validated, safe input
    pass
```

**Validation Error Response Examples**:

Path traversal attempt:
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params: Path traversal detected: source cannot contain '..'",
    "data": {
      "tool": "convert_document",
      "field": "source",
      "value": "file://../../../etc/passwd",
      "error_type": "ValidationError"
    }
  },
  "id": 2
}
```

Invalid confidence score:
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params: confidence_threshold must be between 0.0 and 1.0, got 1.5",
    "data": {
      "tool": "generate_knowledge_graph",
      "field": "confidence_threshold",
      "value": 1.5,
      "error_type": "ValidationError"
    }
  },
  "id": 3
}
```
- **Schema Generation**: FastMCP auto-generates `inputSchema` from Pydantic type hints
  - Type mapping: `str` → JSON string, `int` → JSON number, `Optional[T]` → nullable type
  - Nested models: Pydantic BaseModel classes → JSON object schemas
  - Validation: Automatic parameter validation before tool execution
- **Tool Categories** (19 tools organized by function):
  - **Conversion Tools** (3): `convert_document`, `convert_document_to_markdown`, `batch_convert`
  - **Generation Tools** (11): `generate_knowledge_graph`, `extract_entities`, `extract_relationships`, `create_docling_document`, `parse_pdf_structure`, `extract_tables`, `extract_images`, `detect_document_language`, `classify_document_type`, `extract_metadata`, `generate_document_summary`
  - **Manipulation Tools** (5): `merge_documents`, `split_document`, `search_document`, `annotate_document`, `export_document`

#### Tool Composition and Dependencies
- **Tool Chaining**: Some tools depend on outputs of others
  - `generate_knowledge_graph` requires `convert_document` output (DoclingDocument → entities/relationships)
  - `extract_tables` can operate on `convert_document` output or raw file
  - `merge_documents` requires multiple `convert_document` calls
- **Dependency Management**: Tools declare dependencies via documentation, not enforced at runtime
- **Execution Order**: MCP clients responsible for orchestrating multi-step workflows
  1. Call `convert_document` to get DoclingDocument
  2. Call `generate_knowledge_graph` with DoclingDocument JSON
  3. Call `extract_entities` for fine-grained entity inspection
- **Concurrent Tool Execution**: FastMCP supports async/await for concurrent tool calls
  - MCP clients can send multiple `tools/call` requests in parallel
  - Server handles concurrency via asyncio event loop
  - Resource limits: Max 5 concurrent document conversions (configurable via `MAX_CONCURRENT_CONVERSIONS`)

#### Request/Response Schemas
- **Tool Discovery Response Schema**:
  ```json
  {
    "jsonrpc": "2.0",
    "result": {
      "tools": [
        {
          "name": "convert_document",
          "description": "Convert document to DoclingDocument JSON format",
          "inputSchema": {
            "type": "object",
            "properties": {
              "source": {"type": "string", "description": "File path, URL, or base64 data URI"},
              "format": {"type": "string", "description": "Optional format hint", "enum": ["pdf", "docx", "pptx", "xlsx", "html", "md", "txt"]}
            },
            "required": ["source"]
          }
        }
      ]
    },
    "id": 1
  }
  ```
- **Tool Execution Request Schema**:
  ```json
  {
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "convert_document",
      "arguments": {
        "source": "file:///opt/docling-mcp/data/sample.pdf",
        "format": "pdf"
      }
    },
    "id": 2
  }
  ```
- **Tool Execution Response Schema** (Success):
  ```json
  {
    "jsonrpc": "2.0",
    "result": {
      "content": [
        {
          "type": "text",
          "text": "{\"doc_items\": [...], \"metadata\": {...}}"
        }
      ]
    },
    "id": 2
  }
  ```
- **Tool Execution Response Schema** (Error):
  ```json
  {
    "jsonrpc": "2.0",
    "error": {
      "code": -1,
      "message": "Document conversion failed: Unsupported file format",
      "data": {
        "tool": "convert_document",
        "source": "file:///invalid.xyz",
        "error_type": "UnsupportedFormatError"
      }
    },
    "id": 2
  }
  ```

#### Error Handling and Timeout Management
- **MCP Error Codes**: Map Python exceptions to MCP error codes
  - `ValueError`, `TypeError` → `-32602` (Invalid params)
  - `FileNotFoundError` → `-1` (Document processing error with custom message)
  - `TimeoutError` → `-32603` (Internal error with timeout details)
  - `Exception` (generic) → `-32603` (Internal error with traceback in logs)
- **Tool Timeouts**: Configurable per-tool execution limits
  - `convert_document`: 120 seconds (2 minutes) for large PDFs
  - `generate_knowledge_graph`: 300 seconds (5 minutes) for LLM-heavy extraction
  - `batch_convert`: 600 seconds (10 minutes) for batch operations
  - Configuration: Environment variable `TOOL_TIMEOUT_SECONDS_{TOOL_NAME}`
- **Cancellation Support**: MCP clients can cancel long-running tools
  - Request: `{"jsonrpc":"2.0","method":"tools/cancel","params":{"id":2}}`
  - Implementation: asyncio task cancellation via `task.cancel()`
  - Response: `{"jsonrpc":"2.0","result":"cancelled","id":3}`

#### Transport-Specific Implementation Details

**HTTP Transport Configuration**:
- **Server**: Uvicorn with `uvloop` event loop for performance
- **CORS**: Disabled by default (internal network only), configurable via `CORS_ORIGINS`
- **Authentication**: None in Phase 1 (network-level security), OAuth2 in Phase 2
  - Phase 2: `Authorization: Bearer <token>` header validation via FastMCP middleware
  - OAuth2 providers: Google, GitHub (configured via FastMCP auth decorators)
- **Rate Limiting**: None in Phase 1, token bucket in Phase 2 (100 requests/minute per client)
- **Request Logging**: All HTTP requests logged with timestamp, client IP, method, path, status, duration

**SSE Transport Configuration**:
- **Event Stream Format**: `data: <json>\n\n` (standard SSE format)
- **Progress Updates**: For long-running tools, emit progress events
  - Event type: `progress` with percentage (0-100)
  - Example: `data: {"type":"progress","tool":"convert_document","percentage":45}\n\n`
- **Completion Event**: Final `data: <json_rpc_response>\n\n` event with full result
- **Connection Management**: Track active SSE connections in-memory (max 20 concurrent)
- **Keepalive**: Send `:ping\n\n` every 30 seconds to prevent client timeout
- **Reconnection Strategy**: Clients should reconnect with exponential backoff (1s, 2s, 4s, max 30s)

**stdio Transport Configuration**:
- **Input Buffering**: Read stdin line-by-line (newline-delimited JSON-RPC)
- **Output Buffering**: Flush stdout after each response (ensure immediate delivery)
- **Error Handling**: Write JSON-RPC errors to stdout (NOT stderr for protocol compliance)
- **Logging**: Log to stderr (separate from JSON-RPC communication on stdout)
- **Activation Command**: `python -m docling_mcp.server --transport stdio`
- **Use Cases**: Shell scripts (`cat request.json | python -m docling_mcp.server --transport stdio`), automation tools

#### Transport Selection Logic and Fallback
- **Primary Transport**: HTTP (most common for AI agent integrations)
- **Selection Strategy**: MCP clients choose transport based on use case
  - **HTTP**: JSON-RPC 2.0 over HTTP POST, stateless request/response
  - **SSE**: Long-running jobs requiring progress updates (>30 seconds)
  - **stdio**: Local scripts, CLI tools, automation pipelines
- **Fallback Strategy**: No automatic fallback (client selects transport explicitly)
- **Multi-Transport Support**: All transports active simultaneously (listen on HTTP + stdio together)
  - HTTP server runs in main asyncio loop
  - stdio handled in separate thread (reads stdin, posts to asyncio queue)
  - SSE uses same HTTP server with `/mcp/sse` endpoint

#### Tool Versioning and Schema Evolution
- **Tool Versioning Strategy**: Semantic versioning per tool (encoded in tool name)
  - Current: `convert_document` (v1 implicit)
  - Future: `convert_document_v2` with enhanced parameters
  - Deprecation: Keep `convert_document` for 6 months after v2 release
- **Schema Evolution Rules**:
  - **Backward Compatible Changes**: Add optional parameters (safe, no version bump)
  - **Breaking Changes**: Require new tool version (e.g., remove required parameter)
  - **Response Format Changes**: Add fields (backward compatible), remove fields (breaking)
- **Deprecation Policy**: Deprecated tools return warning in response metadata
  - Response: `{"result": {...}, "warning": "Tool convert_document deprecated, use convert_document_v2"}`
  - Timeline: 6-month deprecation notice before removal

#### Client SDK Compatibility
- **Supported Clients**:
  - **Claude Desktop**: MCP stdio transport via configuration JSON
  - **LangChain MCP**: HTTP transport via `MCPClient` wrapper
  - **Custom Python Clients**: Use `mcp` library with `StdioClient` or `HttpClient`
  - **FastMCP In-Memory Clients**: For testing via `FastMCPTransport`
- **SDK Examples** (documented in service README):
  - **Python**: `from mcp import StdioClient; client = StdioClient("python -m docling_mcp.server --transport stdio")`
  - **TypeScript**: HTTP client via `fetch` with JSON-RPC requests
  - **Claude Desktop Config**: `{"mcpServers": {"docling": {"command": "python", "args": ["-m", "docling_mcp.server", "--transport", "stdio"]}}}`

#### FastMCP Framework Upgrade Path
- **Current Version**: FastMCP 0.2.x (MCP 1.0 support)
- **Upgrade Strategy**:
  - **Patch Updates** (0.2.x): Apply immediately (bug fixes, no breaking changes)
  - **Minor Updates** (0.3.x): Review changelog, test tools, deploy within 1 month
  - **Major Updates** (1.0.x): Comprehensive testing, 3-month upgrade window
- **Compatibility Testing**: Test suite includes FastMCPTransport in-memory tests
  - Validates tool registration, schema generation, execution
  - Catches FastMCP breaking changes before deployment
- **Rollback Plan**: Keep previous FastMCP version pinned in `requirements.txt.lock`
  - Rollback command: `pip install fastmcp==0.2.5` (downgrade if 0.3.x breaks)

#### MCP Best Practices Implementation
- **Tool Naming Convention**: Verb-noun pattern (`convert_document`, `extract_entities`)
- **Parameter Naming**: Snake_case for consistency with Python conventions
- **Response Format**: Always return Pydantic models (auto-serialized to JSON by FastMCP)
- **Error Messages**: Actionable, user-friendly messages with context
  - Bad: `"Conversion failed"` (vague)
  - Good: `"Conversion failed: Unsupported file format '.xyz'. Supported formats: pdf, docx, pptx, xlsx, html, md, txt"`
- **Documentation**: Tool descriptions in docstrings (auto-extracted by FastMCP)
  - Include parameter descriptions, example values, expected output format
- **Idempotency**: Tools with same inputs produce same outputs (important for caching)
  - Exception: `generate_knowledge_graph` may vary due to LLM non-determinism
  - Mitigation: Set LLM temperature=0 for deterministic extraction (configurable)

**Layer 2: Document Processing & Knowledge Engine**
- **Docling Library**: Embedded in-process document conversion (PDF, DOCX, images → DoclingDocument)
- **LightRAG Engine**: Entity extraction and relationship modeling via LLM (gemma3:27b, qwen3-coder:30b)
- **Format Handlers**: Automatic format detection, backend selection (pypdfium2, mammoth, tesseract)
- **DoclingDocument Model**: Canonical JSON representation with structure preservation

**Layer 3: Storage & Infrastructure Integration**
- **Qdrant Client**: HTTP API integration for knowledge graph vector storage
- **Redis Client**: Connection pool for session management and caching
- **LiteLLM Client**: HTTP client for multi-provider LLM abstraction (Ollama routing)
- **Health Check Manager**: Dependency health monitoring and graceful degradation

### Component Breakdown

#### Core Components

**1. FastMCP Server** (MCP Protocol Layer)
- **Purpose**: Expose document processing capabilities as MCP protocol tools
- **Responsibilities**:
  - Tool registration and schema generation (Pydantic models)
  - MCP protocol compliance (tool discovery, execution, error responses)
  - Multi-transport handling (HTTP/SSE/stdio)
  - Request routing to document processing pipeline
- **Technology**: FastMCP framework (Python)
- **Interfaces**:
  - **Input**: MCP tool invocation requests (JSON-RPC over HTTP, SSE, stdio)
  - **Output**: MCP tool responses (JSON results, error responses)

**2. Docling Processor** (Document Conversion)
- **Purpose**: Convert multimodal documents to structured DoclingDocument format
- **Responsibilities**:
  - Format detection (magic number, MIME type, file extension analysis - hierarchical fallback)
  - Backend selection (pypdfium2/pdfplumber/OCR for PDF, python-docx for DOCX, python-pptx for PPTX, openpyxl for XLSX, BeautifulSoup for HTML, EasyOCR for images)
  - Structure preservation (headings, tables, lists, code blocks, images, footnotes, citations)
  - DoclingDocument generation (JSON with semantic annotations, Pydantic validation)
  - Error handling (corrupted file recovery, unsupported format fallback, large file streaming)
- **Technology**: Docling library ~2.63 (embedded in-process), EasyOCR for optical character recognition
- **Interfaces**:
  - **Input**: Document file path, URL, or base64 data + format hint (optional)
  - **Output**: DoclingDocument JSON (structure + content with metadata)

#### 2.1 Format Detection Pipeline

**Detection Hierarchy** (executed in order until format identified):

1. **Magic Number Detection** (file signature bytes - highest priority)
   - PDF: `%PDF-` signature
   - Office ZIP formats: `PK\x03\x04` (DOCX, PPTX, XLSX - disambiguated via ZIP contents)
   - Images: PNG (`\x89PNG`), JPEG (`\xff\xd8\xff`), TIFF, GIF
   - HTML: `<!DOCTYPE html>`, `<html>`
   - Legacy Office: `\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1`

2. **Office ZIP Disambiguation** (for DOCX/PPTX/XLSX):
   - DOCX: Contains `word/document.xml`
   - PPTX: Contains `ppt/presentation.xml`
   - XLSX: Contains `xl/workbook.xml`
   - EPUB: Contains `META-INF/container.xml` with `application/epub+zip`

3. **MIME Type Detection** (fallback if magic number fails)
   - Uses Python `mimetypes` library for MIME → format mapping

4. **Extension-Based Detection** (final fallback)
   - Maps file extensions (`.pdf`, `.docx`, `.pptx`, `.xlsx`, `.html`, `.md`, `.txt`, `.png`, `.jpg`, etc.) to formats

5. **Ambiguous Format Handling**:
   - HTML vs. XHTML: Check for `<?xml>` declaration and `xhtml` namespace
   - XML-based formats: Detect SVG (`<svg>`), XHTML variants
   - Corrupted file validation: Verify PDF structure (page count), ZIP integrity (testzip), image integrity (PIL verify)

**Complete Detection Workflow**:
- **Input**: `file_path` (str), `format_hint` (Optional[str])
- **Process**:
  1. Use format hint if provided and valid (validate file integrity)
  2. Try magic number detection → validate integrity
  3. Try MIME type detection → validate integrity
  4. Try extension-based detection → validate integrity
  5. Raise `ValueError` if format cannot be detected
- **Output**: Detected format string (e.g., `'pdf'`, `'docx'`)

#### 2.2 Backend Selection Strategy

**PDF Backend Selection** (dynamic based on document characteristics):

| Backend | Priority | Use Cases | Strengths | Limitations | Performance |
|---------|----------|-----------|-----------|-------------|-------------|
| **pypdfium2** | 1 (Primary) | Native PDF, vector graphics, searchable text | Fast, accurate text extraction, preserves layout | Fails on encrypted/corrupted PDFs, no OCR | ~10 pages/second |
| **pdfplumber** | 2 (Fallback) | Complex tables, precise layout extraction | Superior table detection, cell-level extraction | Slower, memory-intensive | ~2 pages/second |
| **OCR pipeline** | 3 (Fallback) | Scanned PDFs, image-only pages, non-searchable text | Handles non-searchable PDFs via EasyOCR | Slow (10-30s/page), accuracy varies | ~2-6 pages/minute |

**Backend Selection Algorithm**:
1. Try `pypdfium2` first (fastest) - check if PDF has text layer (>50 chars on first page)
2. If no text layer detected → use `ocr_pipeline` (scanned PDF)
3. If `pypdfium2` fails (encryption, corruption) → try `pdfplumber`
4. If `pdfplumber` fails → fallback to `ocr_pipeline`

**Other Format Backends**:

- **DOCX**: `python-docx` - Complete structure preservation (headings H1-H9, tables with merged cells, nested lists, inline images with captions, footnotes/endnotes, comments metadata)
- **PPTX**: `python-pptx` - Slide-by-slide extraction (title, body, notes, shapes, charts, slide layout)
- **XLSX**: `openpyxl` - Formula preservation, cell formatting, multi-sheet support, merged cells, named ranges
- **HTML**: `BeautifulSoup4` - DOM traversal, semantic tag extraction (h1-h6, lists, tables, links, images, code blocks), script/style removal, whitespace normalization
- **Images (PNG/JPEG/TIFF)**: `Pillow + EasyOCR` - Image preprocessing (deskew, denoise, contrast enhancement), multi-language OCR (en, es, fr, de, ja, zh, ar, ru), confidence scoring

#### 2.3 Structure Preservation Specifications

**Heading Detection and Hierarchy**:

| Format | Detection Method | Mapping Rules |
|--------|------------------|---------------|
| **PDF** | Font size and weight heuristics | >14pt → H1, 12-14pt bold → H2, 11-12pt bold → H3, 10-11pt bold → H4. Fallback: Indentation-based hierarchy |
| **DOCX** | Style-based detection | `Heading 1` → H1, `Heading 2` → H2, ..., `Heading 9` → H9. Custom styles detected by font attributes |
| **HTML** | Semantic tag extraction | `<h1>` → H1, `<h2>` → H2, ..., `<h6>` → H6 |
| **Markdown** | Markdown syntax parsing | `#` → H1, `##` → H2, `###` → H3, ..., `######` → H6 |

**Table Structure Extraction**:

- **PDF**: `pdfplumber` (preferred) or Docling TableFormer - Cell boundary detection, merged cell handling (colspan/rowspan), header row detection, multi-page table continuation, nested tables (limited), challenges: borderless tables (spacing-based), complex merged cells (heuristic), rotated tables
- **DOCX**: `python-docx` - Native table structure (rows, cells), merged cell information (grid span), cell formatting (borders, shading), nested tables (full support)
- **HTML**: `BeautifulSoup` - Semantic table parsing (thead, tbody, tfoot), colspan/rowspan attributes, cell alignment
- **XLSX**: `openpyxl` - Cell grid structure, merged cell ranges, formula preservation, multiple sheets

**List Detection**:

- **Ordered lists**: Markers (`1.`, `a.`, `i.`, `A.`, `I.`), indentation-based nesting (2-4 spaces per level)
- **Unordered lists**: Markers (`•`, `-`, `*`, `◦`, `▪`), indentation-based nesting
- **Schema**: `type`, `items` (text, level, number/marker), `position`

**Code Block Detection**:

- **HTML**: `<pre>`, `<code>` tags, language detection via `class` attribute (e.g., `class="language-python"`)
- **Markdown**: Triple backtick syntax with language specifier (e.g., ` ```python`)
- **PDF/DOCX**: Heuristics (monospace font detection, indentation patterns, syntax highlighting colors, line numbering), Pygments lexer-based language detection (fallback)

**Image Extraction**:

- **PDF**: `pypdfium2` image extraction (JPEG, PNG, TIFF embedded), export options (base64 inline, external file reference, data URI), metadata (width, height, DPI, color space, position/bbox)
- **DOCX**: `python-docx` image relationships (JPEG, PNG, GIF, BMP), caption extraction (text immediately following image - heuristic)
- **HTML**: `<img>` tag extraction, attributes (`src`, `alt`, `width`, `height`)

**Footnote and Citation Extraction**:

- **PDF**: Detection via superscript numbers in text, footer region text matching, font size heuristics (smaller font), challenges: multi-column layouts, inline citations
- **DOCX**: Native footnote/endnote objects, automatic reference linking via Word structure
- **HTML**: Anchor tag detection (e.g., `<a href="#fn1">`), citation extraction from ordered list in footer/dedicated section

#### 2.4 OCR Integration (EasyOCR)

**OCR Pipeline for Scanned PDFs and Images**:

**Configuration**:
- **Languages**: Auto-detect or manual specification (en, es, fr, de, ja, zh, ar, ru - 8 common languages)
- **GPU Acceleration**: Auto-detect CUDA availability for 5-10x speedup
- **Batch Size**: 10 images processed in parallel
- **Detail Level**: 2 (text + confidence + bounding boxes)
- **Paragraph Grouping**: Enabled (group text into paragraphs for better structure)

**Preprocessing Pipeline** (improves OCR accuracy):
1. **Grayscale Conversion**: Convert image to grayscale (reduces noise)
2. **Deskew**: Correct rotation using OpenCV (detect angle via `cv2.minAreaRect`, rotate via `cv2.warpAffine`)
3. **Denoise**: Apply median filter (size=3) to remove artifacts
4. **Contrast Enhancement**: Enhance contrast by factor 2.0 using PIL `ImageEnhance.Contrast`
5. **Binarization**: Convert to black/white (threshold=128)

**OCR Execution**:
- **Method**: `easyocr.Reader.readtext()` with paragraph grouping
- **Output**: List of `(bbox, text, confidence)` tuples
- **Language Detection**: Fallback to `langdetect` library if language not specified
- **Confidence Scoring**: Per-region confidence (0.0-1.0), averaged for overall document confidence

**Performance**:
- **Speed**: 2-6 pages/minute (GPU), 0.5-2 pages/minute (CPU)
- **Accuracy**: 95%+ for high-quality scans (300 DPI), 70-85% for poor quality (<150 DPI)
- **Post-Processing**: Optional spell-check (pyspellchecker), whitespace normalization, line-break detection, paragraph segmentation

**Usage in Docling Pipeline**:
- Detect scanned PDFs (no text layer via `pypdfium2` test)
- Render each PDF page as image (2x resolution for better OCR)
- Run OCR with preprocessing pipeline
- Create `DoclingDocument` items with `type='paragraph'`, `ocr_confidence` in metadata

#### 2.5 DoclingDocument JSON Schema

**Complete Pydantic Schema Definition** (for MCP transport and validation):

```python
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Literal
from datetime import datetime

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
    font_weight: Optional[Literal['normal', 'bold']] = Field(None)
    font_family: Optional[str] = Field(None)
    color: Optional[str] = Field(None, description="Text color (hex RGB)")

class HeadingItem(BaseModel):
    """Heading element (H1-H6)."""
    type: Literal['heading'] = 'heading'
    level: int = Field(ge=1, le=6, description="Heading level (1-6)")
    text: str
    style: Optional[Style] = None
    position: Optional[Position] = None

class ParagraphItem(BaseModel):
    """Paragraph text element."""
    type: Literal['paragraph'] = 'paragraph'
    text: str
    position: Optional[Position] = None
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata (e.g., ocr_confidence)")

class ListItem(BaseModel):
    """Individual list item."""
    text: str
    level: int = Field(ge=0, description="Nesting level (0-based)")
    number: Optional[int] = Field(None)
    marker: Optional[str] = Field(None)

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
    language: str
    code: str
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
DocItem = HeadingItem | ParagraphItem | ListItemContainer | TableItem | ImageItem | CodeBlockItem | FootnoteItem

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
    extraction_model: str = Field(default="docling~2.63")
    backend_used: str = Field(description="Backend used (pypdfium2, python-docx, ocr_pipeline, etc.)")
    schema_version: str = Field(default="1.0.0")

class DoclingDocument(BaseModel):
    """
    Canonical DoclingDocument format for structured document representation.
    All document conversions produce this schema for downstream processing.
    """
    doc_items: List[DocItem] = Field(description="Ordered list of document elements")
    metadata: DocumentMetadata = Field(description="Document-level metadata")
```

**Schema Serialization for MCP Transport**:
- **Serialize**: `DoclingDocument.model_dump_json(indent=2, exclude_none=True)` → JSON string
- **Deserialize**: `DoclingDocument.model_validate_json(json_str)` → DoclingDocument object

**Schema Versioning Strategy**: Semantic versioning (1.0.0)
- **Patch** (1.0.x): Add optional fields, fix bugs (backward compatible)
- **Minor** (1.x.0): Add new item types, extend metadata (backward compatible)
- **Major** (x.0.0): Remove fields, change types, restructure (breaking changes)

#### 2.6 Error Handling and Recovery

**Corrupted File Recovery**:
1. **Strategy 1**: Try `PyPDF2` in lenient mode (`strict=False`) for corrupted PDFs
2. **Strategy 2**: Fallback to OCR entire document (render pages as images, run EasyOCR)
3. **Last Resort**: Extract as plain text (open with `encoding='utf-8', errors='ignore'`)

**Unsupported Format Fallback**:
- Extract content as plain text if format detected but no backend available
- Raise `ValueError` with supported formats list if extraction impossible

**Large File Handling** (streaming to limit memory usage):
- **Threshold**: 100MB file size
- **Strategy**: Process PDF page-by-page (streaming mode) - process, close, release resources immediately
- **Implementation**: `pypdfium2` with page-level iteration, asyncio yield control every 10 pages
- **Limitations**: Structure detection disabled in streaming mode (paragraphs only, no headings/tables)
- **Supported Formats**: PDF only (streaming not supported for DOCX/PPTX/XLSX)

**Memory Management**:
- **Monitoring**: `psutil` process memory tracking, alert if >1GB usage
- **Garbage Collection**: Force `gc.collect()` after processing each document
- **Cleanup**: Release page/document resources immediately in `finally` blocks

**Timeout Handling**:
- **Timeout**: 120 seconds default for document conversion
- **Implementation**: `asyncio.wait_for()` wrapper around conversion function
- **Error**: Raise `TimeoutError` if conversion exceeds timeout (prevents hanging on large/corrupted files)

**Contributor**: albert-singh (Docling SME)

**3. LightRAG Knowledge Engine** (Knowledge Graph Generation)
- **Purpose**: Extract entities and relationships, build knowledge graphs with Qdrant vector storage
- **Responsibilities**:
  - Entity extraction (NER via LLM prompting with gemma3:27b, qwen3-coder:30b)
  - Relationship extraction (relation extraction via LLM)
  - Entity deduplication and resolution (semantic similarity via embeddings)
  - Graph construction (nodes = entities, edges = relationships)
  - Qdrant storage integration (vector embeddings + metadata, dual-collection architecture)
  - Embedding generation (bge-m3:567m via Ollama3 for 1024D dense vectors)
- **Technology**: LightRAG framework (Python), bge-m3 embeddings via Ollama3
- **Interfaces**:
  - **Input**: DoclingDocument JSON or raw text
  - **Output**: Entity list + Relationship list (JSON), Qdrant collection IDs

- **Qdrant Collection Architecture**:

  **Entity Collection** (`hx_docling_mcp_entities`):
  - **Purpose**: Store extracted entities with semantic embeddings for similarity search
  - **Vector Configuration**:
    - **Dimensions**: 1024 (bge-m3:567m embedding model output)
    - **Distance Metric**: Cosine (optimal for semantic similarity, normalized embeddings)
    - **HNSW Parameters**:
      - `m: 16` (balanced connectivity for 1024D vectors, moderate RAM usage)
      - `ef_construct: 100` (build-time search quality, sufficient for <1M entities)
      - `on_disk: false` (Phase 1: <100K entities, RAM-only for speed)
    - **Quantization**: Scalar INT8 (4x RAM reduction, <1% recall loss)
      - Phase 1 disabled (prioritize accuracy during development)
      - Phase 2 enabled when entity count >100K
  - **Payload Schema** (Pydantic BaseModel Definition):
    ```python
    from pydantic import BaseModel, Field, field_validator
    from typing import Dict, List, Any, Optional
    from datetime import datetime

    class TextSpan(BaseModel):
        """Text location within document."""
        start: int = Field(ge=0, description="Character offset of span start")
        end: int = Field(ge=0, description="Character offset of span end (exclusive)")

        @field_validator('end')
        @classmethod
        def validate_span(cls, v: int, info) -> int:
            if 'start' in info.data and v <= info.data['start']:
                raise ValueError(f"end ({v}) must be greater than start ({info.data['start']})")
            return v

    class EntityPayload(BaseModel):
        """Qdrant payload schema for entity storage with comprehensive validation."""

        entity_id: UUID = Field(
            description="UUID v4 for global entity uniqueness across knowledge graph"
        )
        entity_name: str = Field(
            min_length=1,
            max_length=200,
            description="Canonical entity name (e.g., 'MIT', 'John Smith')"
        )
        entity_type: EntityType = Field(
            description="Entity classification type"
        )
        aliases: List[str] = Field(
            default_factory=list,
            max_length=20,
            description="Alternative names for deduplication (e.g., ['Massachusetts Institute of Technology', 'MIT'])"
        )
        attributes: Dict[str, Any] = Field(
            default_factory=dict,
            description="Type-specific attributes (e.g., {'founded': '1861', 'location': 'Cambridge, MA'})"
        )
        confidence: ConfidenceScore = Field(
            description="LLM extraction confidence score (0.0 to 1.0)"
        )
        document_id: str = Field(
            min_length=1,
            max_length=256,
            description="Source document identifier (hash or path)"
        )
        document_source: str = Field(
            min_length=1,
            max_length=2000,
            description="Document file path or URL"
        )
        text_span: TextSpan = Field(
            description="Original text location within document"
        )
        context_snippet: str = Field(
            min_length=0,
            max_length=500,
            description="Surrounding text context (50 chars before/after entity mention)"
        )
        extraction_model: str = Field(
            pattern=r"^[a-z0-9:-]+$",
            description="LLM model used for extraction (e.g., 'gemma3:27b', 'qwen3-coder:30b')"
        )
        extraction_timestamp: ISOTimestamp = Field(
            description="ISO8601 timestamp of entity extraction"
        )
        mention_count: int = Field(
            default=1,
            ge=1,
            description="Frequency of entity mentions across document corpus (entity importance metric)"
        )

        @field_validator('aliases')
        @classmethod
        def validate_aliases(cls, v: List[str]) -> List[str]:
            """Remove duplicates and empty aliases, validate length."""
            if not v:
                return []
            # Remove duplicates while preserving order
            seen = set()
            unique_aliases = []
            for alias in v:
                alias_stripped = alias.strip()
                if alias_stripped and alias_stripped not in seen:
                    if len(alias_stripped) > 200:
                        raise ValueError(f"Alias too long (max 200 chars): {alias_stripped[:50]}...")
                    seen.add(alias_stripped)
                    unique_aliases.append(alias_stripped)
            return unique_aliases

        @field_validator('context_snippet')
        @classmethod
        def validate_context(cls, v: str) -> str:
            """Trim and sanitize context snippet."""
            return v.strip()[:500]

        model_config = {
            "json_schema_extra": {
                "examples": [{
                    "entity_id": "550e8400-e29b-41d4-a716-446655440000",
                    "entity_name": "MIT",
                    "entity_type": "Organization",
                    "aliases": ["Massachusetts Institute of Technology", "MIT"],
                    "attributes": {"founded": "1861", "location": "Cambridge, MA", "type": "university"},
                    "confidence": 0.95,
                    "document_id": "doc_abc123",
                    "document_source": "file:///opt/docs/research_paper.pdf",
                    "text_span": {"start": 1234, "end": 1237},
                    "context_snippet": "researchers at MIT developed a novel approach to",
                    "extraction_model": "gemma3:27b",
                    "extraction_timestamp": "2025-11-25T10:30:00Z",
                    "mention_count": 5
                }]
            }
        }
    ```
  - **Indexes** (Payload Field Indexes for Fast Filtering):
    - `entity_type` (keyword index): Fast filtering by entity type (e.g., "show all Person entities")
    - `document_id` (keyword index): Find all entities from specific document
    - `confidence` (float index): Filter by extraction confidence threshold
    - `mention_count` (integer index): Sort by entity importance/frequency

  **Relationship Collection** (`hx_docling_mcp_relationships`):
  - **Purpose**: Store entity relationships for graph traversal and multi-hop reasoning
  - **Vector Configuration**:
    - **Dimensions**: 1024 (relationship text embeddings: "Subject PREDICATE Object")
    - **Distance Metric**: Cosine (semantic similarity for relationship types)
    - **HNSW Parameters**:
      - `m: 16` (standard connectivity for relationship graph)
      - `ef_construct: 100` (moderate build quality)
      - `on_disk: false` (Phase 1: <500K relationships, RAM-only)
    - **Quantization**: Disabled Phase 1, Scalar INT8 Phase 2 when >500K relationships
  - **Payload Schema** (Pydantic BaseModel Definition):
    ```python
    class RelationshipPayload(BaseModel):
        """Qdrant payload schema for relationship storage with graph traversal validation."""

        relationship_id: UUID = Field(
            description="UUID v4 for global relationship uniqueness"
        )
        subject_entity_id: UUID = Field(
            description="Foreign key to hx_docling_mcp_entities.entity_id (source node in graph)"
        )
        subject_entity_name: str = Field(
            min_length=1,
            max_length=200,
            description="Denormalized subject entity name for fast display without join"
        )
        predicate: RelationshipPredicate = Field(
            description="Relationship type classification"
        )
        object_entity_id: UUID = Field(
            description="Foreign key to hx_docling_mcp_entities.entity_id (target node in graph)"
        )
        object_entity_name: str = Field(
            min_length=1,
            max_length=200,
            description="Denormalized object entity name for fast display without join"
        )
        attributes: Dict[str, Any] = Field(
            default_factory=dict,
            description="Relationship-specific attributes (e.g., {'role': 'CEO', 'from': '2015', 'to': '2023'})"
        )
        confidence: ConfidenceScore = Field(
            description="LLM extraction confidence score (0.0 to 1.0)"
        )
        document_id: str = Field(
            min_length=1,
            max_length=256,
            description="Source document identifier"
        )
        text_evidence: str = Field(
            min_length=1,
            max_length=1000,
            description="Sentence or phrase containing relationship evidence (e.g., 'John Smith is CEO of Acme Corp')"
        )
        text_span: Optional[TextSpan] = Field(
            default=None,
            description="Optional text location of relationship evidence within document"
        )
        extraction_model: str = Field(
            pattern=r"^[a-z0-9:-]+$",
            description="LLM model used for relationship extraction"
        )
        extraction_timestamp: ISOTimestamp = Field(
            description="ISO8601 timestamp of relationship extraction"
        )
        bidirectional: bool = Field(
            default=False,
            description="True if relationship is symmetric (e.g., 'collaborates_with', 'near')"
        )

        @field_validator('predicate')
        @classmethod
        def validate_predicate_bidirectional(cls, v: str, info) -> str:
            """Validate bidirectional flag matches predicate semantics."""
            # Define symmetric predicates that should be bidirectional
            symmetric_predicates = {'near', 'collaborates_with', 'partners_with'}
            if 'bidirectional' in info.data:
                is_bidirectional = info.data['bidirectional']
                if v in symmetric_predicates and not is_bidirectional:
                    raise ValueError(
                        f"Predicate '{v}' is symmetric and must have bidirectional=True"
                    )
            return v

        @field_validator('text_evidence')
        @classmethod
        def validate_text_evidence(cls, v: str) -> str:
            """Sanitize and trim text evidence."""
            sanitized = v.strip()
            if not sanitized:
                raise ValueError("text_evidence cannot be empty")
            return sanitized[:1000]

        model_config = {
            "json_schema_extra": {
                "examples": [{
                    "relationship_id": "650e8400-e29b-41d4-a716-446655440001",
                    "subject_entity_id": "550e8400-e29b-41d4-a716-446655440000",
                    "subject_entity_name": "John Smith",
                    "predicate": "works_for",
                    "object_entity_id": "550e8400-e29b-41d4-a716-446655440002",
                    "object_entity_name": "Acme Corp",
                    "attributes": {"role": "CEO", "from": "2015", "to": "2023"},
                    "confidence": 0.92,
                    "document_id": "doc_abc123",
                    "text_evidence": "John Smith served as CEO of Acme Corp from 2015 to 2023",
                    "text_span": {"start": 5678, "end": 5734},
                    "extraction_model": "gemma3:27b",
                    "extraction_timestamp": "2025-11-25T10:30:05Z",
                    "bidirectional": False
                }]
            }
        }
    ```
  - **Indexes** (Payload Field Indexes):
    - `subject_entity_id` (keyword index): Find all outgoing relationships from entity
    - `object_entity_id` (keyword index): Find all incoming relationships to entity
    - `predicate` (keyword index): Filter by relationship type
    - `document_id` (keyword index): All relationships from specific document
    - `confidence` (float index): Filter by confidence threshold

- **Qdrant Operations**:

  **Collection Initialization** (On Service Startup):
  ```python
  # CRITICAL: Idempotent collection initialization - SAFE for restarts/upgrades
  # NEVER use recreate_collection() in production - causes data loss on every restart!

  # Initialize entity collection (idempotent - preserves existing data)
  if not qdrant_client.collection_exists("hx_docling_mcp_entities"):
      # Collection doesn't exist - create it
      qdrant_client.create_collection(
          collection_name="hx_docling_mcp_entities",
          vectors_config=VectorParams(
              size=1024,
              distance=Distance.COSINE,
              on_disk=False
          ),
          hnsw_config=HnswConfigDiff(
              m=16,
              ef_construct=100
          ),
          quantization_config=None  # Phase 1 disabled
      )

      # Create payload indexes for fast filtering (only on new collection)
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_entities",
          field_name="entity_type",
          field_schema="keyword"
      )
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_entities",
          field_name="document_id",
          field_schema="keyword"
      )
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_entities",
          field_name="confidence",
          field_schema="float"
      )
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_entities",
          field_name="mention_count",
          field_schema="integer"
      )
  # Collection exists - preserve data (schema changes require explicit migration)

  # Initialize relationship collection (same idempotent pattern)
  if not qdrant_client.collection_exists("hx_docling_mcp_relationships"):
      qdrant_client.create_collection(
          collection_name="hx_docling_mcp_relationships",
          vectors_config=VectorParams(
              size=1024,
              distance=Distance.COSINE,
              on_disk=False
          ),
          hnsw_config=HnswConfigDiff(
              m=16,
              ef_construct=100
          ),
          quantization_config=None
      )
      # Create payload indexes (see Entity Collection Payload Indexes for fields)
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_relationships",
          field_name="subject_entity_id",
          field_schema="keyword"
      )
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_relationships",
          field_name="object_entity_id",
          field_schema="keyword"
      )
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_relationships",
          field_name="predicate",
          field_schema="keyword"
      )
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_relationships",
          field_name="document_id",
          field_schema="keyword"
      )
  # Collection exists - preserve data
      qdrant_client.create_payload_index(
          collection_name="hx_docling_mcp_relationships",
          field_name="confidence",
          field_schema="float"
      )
  ```

  **Qdrant Collection Migration Strategy**:

  **CRITICAL: Data Durability Requirements (NFR-013)**
  - Knowledge graph data MUST persist across service restarts and upgrades
  - NEVER use `recreate_collection()` in production (data loss on every restart)
  - All collection operations MUST be idempotent
  - Schema changes require explicit migration procedures

  **Collection Schema Versioning**:
  ```python
  # Store schema version in collection metadata (for migration tracking)
  ENTITY_COLLECTION_VERSION = "1.0.0"
  RELATIONSHIP_COLLECTION_VERSION = "1.0.0"

  # Version format: MAJOR.MINOR.PATCH
  # MAJOR: Breaking changes (incompatible schema changes)
  # MINOR: Backward-compatible additions (new optional fields)
  # PATCH: Bug fixes, documentation updates (no schema change)
  ```

  **Schema Change Categories and Migration Strategies**:

  1. **Backward-Compatible Changes (Minor Version Bump)**:
     - **Examples**: Add optional payload field, add new payload index, increase field max_length
     - **Migration Strategy**: NO DATA MIGRATION REQUIRED
     - **Implementation**:
       ```python
       # Existing data works as-is (optional fields default to null)
       # Just create new payload index for new field
       try:
           qdrant_client.create_payload_index(
               collection_name="hx_docling_mcp_entities",
               field_name="new_optional_field",
               field_schema="keyword"
           )
       except Exception:
           pass  # Index may already exist (idempotent)
       ```
     - **Safe to deploy**: Yes, no downtime required

  2. **Breaking Changes (Major Version Bump)**:
     - **Examples**:
       - Change vector dimensions (1024 → 768)
       - Change distance metric (Cosine → Dot)
       - Remove required field or change field type
       - Rename field
     - **Migration Strategy**: FULL COLLECTION RECREATION REQUIRED
     - **Implementation** (DEVELOPMENT ONLY - User must coordinate):
       ```python
       # WARNING: This destroys all existing data!
       # Only run in development or with explicit backup/restore plan

       import datetime
       from qdrant_client.models import SnapshotDescription

       # Step 1: Create full snapshot for rollback safety
       snapshot_name = f"hx_docling_mcp_entities_v1_backup_{datetime.now().isoformat()}"
       snapshot = qdrant_client.create_snapshot(collection_name="hx_docling_mcp_entities")
       # Download snapshot to local storage for safety
       # snapshot.download(f"/opt/backups/qdrant/{snapshot_name}.snapshot")

       # Step 2: Export all existing data (for re-embedding if needed)
       all_entities = []
       offset = None
       while True:
           result = qdrant_client.scroll(
               collection_name="hx_docling_mcp_entities",
               limit=1000,
               offset=offset,
               with_payload=True,
               with_vectors=True
           )
           if not result[0]:
               break
           all_entities.extend(result[0])
           offset = result[1]

       # Step 3: Drop old collection (DESTRUCTIVE!)
       qdrant_client.delete_collection(collection_name="hx_docling_mcp_entities")

       # Step 4: Create new collection with updated schema
       qdrant_client.create_collection(
           collection_name="hx_docling_mcp_entities",
           vectors_config=VectorParams(
               size=768,  # NEW: Changed from 1024
               distance=Distance.DOT,  # NEW: Changed from COSINE
               on_disk=False
           ),
           hnsw_config=HnswConfigDiff(m=16, ef_construct=100)
       )

       # Step 5: Re-embed and re-insert all entities with new model
       for entity in all_entities:
           # Generate new embedding with new model (768D)
           new_embedding = ollama3_client.embeddings(
               model="new-model:768d",
               prompt=f"{entity.payload['entity_name']} {entity.payload['context_snippet']}"
           )
           # Transform payload if schema changed (rename fields, convert types)
           migrated_payload = migrate_entity_payload_v1_to_v2(entity.payload)
           # Re-insert with new embedding and migrated payload
           qdrant_client.upsert(
               collection_name="hx_docling_mcp_entities",
               points=[{
                   "id": entity.id,
                   "vector": new_embedding,
                   "payload": migrated_payload
               }]
           )

       # Step 6: Verify migration success
       new_count = qdrant_client.count(collection_name="hx_docling_mcp_entities")
       assert new_count.count == len(all_entities), "Migration data loss detected!"
       ```
     - **Deployment Procedure**:
       1. Announce maintenance window (knowledge graph unavailable)
       2. Stop docling-mcp-server service
       3. Create Qdrant snapshot backup
       4. Run migration script (development testing required first!)
       5. Verify data integrity (entity count, sample queries)
       6. Start docling-mcp-server service with new code
       7. Monitor for errors (rollback from snapshot if failures)

  3. **HNSW/Quantization Tuning (No Schema Change)**:
     - **Examples**: Change m from 16 → 32, enable quantization, change ef_construct
     - **Migration Strategy**: IN-PLACE UPDATES (no data loss)
     - **Implementation**:
       ```python
       # Enable quantization (preserves all data, improves RAM efficiency)
       from qdrant_client.models import ScalarQuantization, ScalarType

       qdrant_client.update_collection(
           collection_name="hx_docling_mcp_entities",
           quantization_config=ScalarQuantization(
               scalar=ScalarType.INT8,
               always_ram=False
           )
       )
       # Qdrant automatically re-quantizes existing vectors (no downtime)

       # Update HNSW parameters (optimizer runs in background)
       qdrant_client.update_collection(
           collection_name="hx_docling_mcp_entities",
           hnsw_config=HnswConfigDiff(
               m=32,  # Increased from 16 for better recall
               ef_construct=200  # Increased from 100 for better index quality
           )
       )
       # Existing index is rebuilt gradually (no service interruption)
       ```
     - **Safe to deploy**: Yes, changes apply gradually without downtime

  4. **Storage Migration (RAM → Disk)**:
     - **When**: Entity count exceeds 100K (RAM pressure)
     - **Migration Strategy**: IN-PLACE CONVERSION
     - **Implementation**:
       ```python
       # Move collection to disk (preserves all data)
       qdrant_client.update_collection(
           collection_name="hx_docling_mcp_entities",
           vectors_config=VectorParams(
               size=1024,
               distance=Distance.COSINE,
               on_disk=True  # Changed from False
           )
       )
       # Qdrant moves vectors to disk automatically (gradual migration)
       # Search latency increases slightly (~2-5x slower)
       # RAM usage drops significantly (only HNSW graph in RAM)
       ```
     - **Safe to deploy**: Yes, transparent migration

  **When `recreate_collection()` Is Acceptable**:
  - ✅ **Development/Testing ONLY**: Local development environments, integration tests
  - ✅ **Explicit User Confirmation**: User manually runs migration script with full understanding
  - ❌ **NEVER in service startup code**: Causes data loss on every restart/upgrade
  - ❌ **NEVER in production automation**: Violates NFR-013 data durability

  **Production Deployment Checklist**:
  - [ ] Collection initialization uses `get_collection()` + `create_collection()` pattern
  - [ ] No `recreate_collection()` calls in service startup code
  - [ ] Schema version tracked in documentation and code comments
  - [ ] Backup strategy in place (Qdrant snapshots + S3 storage)
  - [ ] Migration runbook documented for breaking changes
  - [ ] Rollback procedure tested (restore from snapshot)
  - [ ] Monitoring configured (collection count, search latency, RAM usage)

  **Entity Insertion with Deduplication**:
  ```python
  # 1. Extract entity from LLM response
  new_entity = {"name": "MIT", "type": "Organization", ...}

  # 2. Generate embedding for entity name + context
  embedding_text = f"{new_entity['name']} {new_entity.get('context_snippet', '')}"
  embedding = ollama3_client.embeddings(model="bge-m3:567m", prompt=embedding_text)

  # 3. Search for duplicate entities (semantic similarity)
  duplicates = qdrant_client.search(
      collection_name="hx_docling_mcp_entities",
      query_vector=embedding,
      query_filter={
          "must": [{"key": "entity_type", "match": {"value": new_entity['type']}}]
      },
      limit=5,
      score_threshold=0.85  # High similarity = likely duplicate
  )

  # 4. Merge or insert
  if duplicates and duplicates[0].score > 0.85:
      # Update existing entity (increment mention_count, merge aliases)
      existing_id = duplicates[0].id
      qdrant_client.set_payload(
          collection_name="hx_docling_mcp_entities",
          payload={"mention_count": existing_entity["mention_count"] + 1},
          points=[existing_id]
      )
      return existing_id
  else:
      # Insert new entity
      entity_id = str(uuid.uuid4())
      qdrant_client.upsert(
          collection_name="hx_docling_mcp_entities",
          points=[{
              "id": entity_id,
              "vector": embedding,
              "payload": {**new_entity, "entity_id": entity_id, "mention_count": 1}
          }]
      )
      return entity_id
  ```

  **Relationship Insertion with Bidirectional Links**:
  ```python
  # 1. Extract relationship from LLM response
  relationship = {
      "subject": "John Smith",
      "predicate": "works_for",
      "object": "Acme Corp",
      "bidirectional": False
  }

  # 2. Resolve entity IDs (search entities by name)
  subject_id = resolve_entity_id("John Smith", entity_type="Person")
  object_id = resolve_entity_id("Acme Corp", entity_type="Organization")

  # 3. Generate relationship embedding
  rel_text = f"{relationship['subject']} {relationship['predicate']} {relationship['object']}"
  rel_embedding = ollama3_client.embeddings(model="bge-m3:567m", prompt=rel_text)

  # 4. Insert relationship
  rel_id = str(uuid.uuid4())
  qdrant_client.upsert(
      collection_name="hx_docling_mcp_relationships",
      points=[{
          "id": rel_id,
          "vector": rel_embedding,
          "payload": {
              "relationship_id": rel_id,
              "subject_entity_id": subject_id,
              "object_entity_id": object_id,
              "predicate": relationship["predicate"],
              "bidirectional": relationship["bidirectional"],
              # ... other fields
          }
      }]
  )

  # 5. If bidirectional, insert reverse relationship
  if relationship["bidirectional"]:
      reverse_rel_id = str(uuid.uuid4())
      qdrant_client.upsert(
          collection_name="hx_docling_mcp_relationships",
          points=[{
              "id": reverse_rel_id,
              "vector": rel_embedding,  # Same embedding
              "payload": {
                  "subject_entity_id": object_id,  # Swapped
                  "object_entity_id": subject_id,
                  "predicate": relationship["predicate"],
                  # ... other fields
              }
          }]
      )
  ```

  **Graph Traversal Queries** (Entity Neighbors):
  ```python
  # Find all entities connected to "MIT" via any relationship
  def get_entity_neighbors(entity_id: str, max_depth: int = 1):
      # Get all outgoing relationships
      outgoing = qdrant_client.scroll(
          collection_name="hx_docling_mcp_relationships",
          scroll_filter={
              "must": [{"key": "subject_entity_id", "match": {"value": entity_id}}]
          },
          limit=1000
      )

      # Get all incoming relationships
      incoming = qdrant_client.scroll(
          collection_name="hx_docling_mcp_relationships",
          scroll_filter={
              "must": [{"key": "object_entity_id", "match": {"value": entity_id}}]
          },
          limit=1000
      )

      # Extract connected entity IDs
      neighbor_ids = set()
      for rel in outgoing[0]:
          neighbor_ids.add(rel.payload["object_entity_id"])
      for rel in incoming[0]:
          neighbor_ids.add(rel.payload["subject_entity_id"])

      # Fetch entity details
      neighbors = qdrant_client.retrieve(
          collection_name="hx_docling_mcp_entities",
          ids=list(neighbor_ids)
      )

      return neighbors
  ```

  **Semantic Search for Entities** (Vector Similarity):
  ```python
  # Find entities semantically similar to "quantum computing research"
  query_embedding = ollama3_client.embeddings(
      model="bge-m3:567m",
      prompt="quantum computing research"
  )

  similar_entities = qdrant_client.search(
      collection_name="hx_docling_mcp_entities",
      query_vector=query_embedding,
      query_filter={
          "must": [{"key": "entity_type", "match": {"value": "Concept"}}]
      },
      limit=10,
      score_threshold=0.7
  )
  ```

  **Hybrid Search** (Vector + Metadata Filtering):
  ```python
  # Find high-confidence Person entities related to "machine learning" from specific document
  query_embedding = ollama3_client.embeddings(model="bge-m3:567m", prompt="machine learning")

  results = qdrant_client.search(
      collection_name="hx_docling_mcp_entities",
      query_vector=query_embedding,
      query_filter={
          "must": [
              {"key": "entity_type", "match": {"value": "Person"}},
              {"key": "document_id", "match": {"value": "doc_abc123"}},
              {"key": "confidence", "range": {"gte": 0.8}}
          ]
      },
      limit=20
  )
  ```

  **Batch Operations** (Bulk Entity/Relationship Insertion):
  ```python
  # Batch insert 1000 entities in single request (10x faster than sequential)
  batch_entities = []
  for entity_data in extracted_entities:
      embedding = ollama3_client.embeddings(model="bge-m3:567m", prompt=entity_data["name"])
      batch_entities.append({
          "id": str(uuid.uuid4()),
          "vector": embedding,
          "payload": entity_data
      })

  # Upsert in batches of 100 (optimal for Qdrant HTTP API)
  for i in range(0, len(batch_entities), 100):
      batch = batch_entities[i:i+100]
      qdrant_client.upsert(
          collection_name="hx_docling_mcp_entities",
          points=batch,
          wait=True  # Wait for write confirmation
      )
  ```

- **Performance & Scalability**:

  **Connection Pooling**:
  - HTTP connection pool: Max 10 connections to Qdrant, keepalive 60s
  - Connection timeout: 5s connect, 30s read (large batch operations)
  - Retry logic: 3 attempts with exponential backoff (100ms, 200ms, 400ms)

  **Retry Logic for Write Failures**:
  ```python
  from tenacity import retry, stop_after_attempt, wait_exponential

  @retry(
      stop=stop_after_attempt(3),
      wait=wait_exponential(multiplier=1, min=1, max=10),
      reraise=True
  )
  def qdrant_upsert_with_retry(collection_name, points):
      return qdrant_client.upsert(
          collection_name=collection_name,
          points=points,
          wait=True
      )
  ```

  **Batch Size Optimization**:
  - **Small entities** (<1KB payload): 100 entities per batch
  - **Large entities** (>1KB payload with long context_snippet): 50 entities per batch
  - **Relationships**: 200 relationships per batch (smaller payloads)
  - Monitor Qdrant response latency, adjust batch size dynamically

  **Memory Usage Monitoring**:
  ```python
  # Check collection size and RAM usage
  collection_info = qdrant_client.get_collection(collection_name="hx_docling_mcp_entities")

  metrics = {
      "total_entities": collection_info.points_count,
      "indexed_vectors": collection_info.indexed_vectors_count,
      "ram_usage_bytes": collection_info.vectors_count * 1024 * 4,  # 1024D * 4 bytes (float32)
      "disk_usage_bytes": collection_info.disk_data_size
  }

  # Alert if RAM usage >75% of available memory
  if metrics["ram_usage_bytes"] > 0.75 * available_ram:
      logger.warning(f"Qdrant RAM usage high: {metrics['ram_usage_bytes'] / 1e9:.2f}GB")
  ```

  **Scaling Triggers**:
  - **100K entities**: Enable Scalar INT8 quantization (4x RAM reduction)
  - **500K entities**: Enable on_disk storage for vectors (slower search, lower RAM)
  - **1M entities**: Increase HNSW `ef` during search from 128 to 256 (maintain recall >95%)
  - **5M entities**: Consider Qdrant cluster with sharding (Phase 2 - horizontal scaling)

#### 3.1 Entity Extraction Pipeline (LightRAG + LLM Integration)

**Contributor**: andy-taylor (LightRAG SME)

**Document Chunking** (Preprocessing for LLM-Safe Context Windows):

- **Chunk Size**: 4096 tokens (optimal for 32KB context models like gemma3:27b, leaves 28KB for prompt overhead)
  - **Rationale**: LightRAG research shows optimal entity extraction with 4K-token chunks (balances context richness vs LLM compute cost)
- **Chunk Overlap**: 512 tokens (12.5% overlap) to preserve entity/relationship context at chunk boundaries
  - **Why Overlap**: Prevents split entities (e.g., "Massachusett..." chunk 1, "...s Institute of Technology" chunk 2)
- **Chunking Strategy**:
  - **Semantic Chunking**: Split at paragraph boundaries (`\n\n`) to preserve topical coherence
  - **Fallback**: Token-based splitting if paragraph exceeds 4096 tokens (force split at sentence `.` boundary)
  - **Code Block Preservation**: Treat code blocks as atomic units (do not split mid-code, critical for technical docs)
  - **Token Counting**: `tiktoken` library with `cl100k_base` encoding (GPT-3.5/4-compatible, works for all Ollama models)
  - **Chunk Metadata**: Track `document_id`, `chunk_index`, `char_start`, `char_end` for source attribution
- **Edge Cases**:
  - Documents <4096 tokens: Single chunk (no splitting required)
  - Long paragraphs (>4096 tokens): Force split at sentence boundaries, preserve context with overlap
  - Code blocks: Treat as atomic units (do not split mid-code)

**Entity Types** (10 Configurable Types):

| Entity Type | Description | Examples |
|-------------|-------------|----------|
| **Person** | Individuals, authors, researchers, historical figures | "Dr. Jane Smith", "Albert Einstein" |
| **Organization** | Companies, institutions, research groups, government agencies | "MIT", "IBM Research", "UN" |
| **Location** | Countries, cities, geographic regions, facilities | "Cambridge, MA", "Building 32" |
| **Concept** | Abstract ideas, theories, methodologies, scientific concepts | "Quantum Entanglement", "Machine Learning" |
| **Technology** | Software, hardware, tools, frameworks, programming languages | "Python", "LightRAG", "CUDA" |
| **Product** | Commercial products, services, brands | "iPhone", "Windows 11", "Qdrant Cloud" |
| **Event** | Historical events, conferences, incidents, milestones | "ICML 2024", "Apollo 11 Launch" |
| **Date** | Temporal references (absolute dates, time periods, durations) | "November 25 2025", "1990s", "3 months" |
| **Quantity** | Numerical values with units, measurements, statistics | "54.8% win rate", "1024 dimensions", "32GB RAM" |
| **Document** | References to other documents, papers, reports, standards | "RFC 9110", "LightRAG Research Paper" |

**LLM Extraction Prompt Template** (with Few-Shot Examples):

```markdown
You are an expert entity extraction system. Extract structured entities from technical documents.

ENTITY TYPES: Person, Organization, Location, Concept, Technology, Product, Event, Date, Quantity, Document

INSTRUCTIONS:
1. Extract ALL entities of the specified types from the text chunk
2. For each entity, provide:
   - entity_text: Exact text span from document (verbatim, no normalization)
   - entity_type: One of the 10 entity types (EXACTLY as spelled)
   - normalized_name: Canonical form (e.g., "Dr. John Smith" → "John Smith", "MIT" → "Massachusetts Institute of Technology")
   - confidence: Confidence score 0.0-1.0
     * 0.9-1.0: Explicit mentions with clear context
     * 0.7-0.9: Inferred entities with supporting context
     * <0.7: Ambiguous entities
   - context: 50-character snippet surrounding entity mention (for disambiguation)
   - attributes: Type-specific structured attributes
3. Extract entities even if mentioned only once (frequency filtering is post-processing)
4. Preserve entity coreferences (distinguish "Tesla" the company vs "Tesla" the person)
5. Return ONLY valid JSON array (no markdown, no preamble, no explanation)

FEW-SHOT EXAMPLE:
Text: "IBM Research announced LightRAG, a knowledge graph RAG framework, achieving 54.8% win rate."
Output:
{
  "entities": [
    {
      "entity_text": "IBM Research",
      "entity_type": "Organization",
      "normalized_name": "IBM Research",
      "confidence": 0.95,
      "context": "...announced by IBM Research in...",
      "attributes": {"industry": "technology research", "parent_company": "IBM"}
    },
    {
      "entity_text": "LightRAG",
      "entity_type": "Technology",
      "normalized_name": "LightRAG",
      "confidence": 0.98,
      "context": "...IBM Research announced LightRAG, a knowledge...",
      "attributes": {"category": "framework", "purpose": "knowledge graph RAG"}
    },
    {
      "entity_text": "54.8% win rate",
      "entity_type": "Quantity",
      "normalized_name": "54.8%",
      "confidence": 0.92,
      "context": "...achieving 54.8% win rate...",
      "attributes": {"value": 54.8, "unit": "percent", "metric": "win_rate"}
    }
  ]
}

Document text to process:
{document_chunk}

Output (JSON only, no explanation):
```

**LLM Model Selection** (via LiteLLM):

| Model | Use Case | Latency (P95) | Quality (F1 Score) | Cost |
|-------|----------|---------------|-------------------|------|
| **gemma3:27b** | General documents (business, reports, articles) | 2-5 seconds/1K tokens | 0.85+ | Free (local Ollama1) |
| **qwen3-coder:30b** | Technical docs (code, API docs, source) | 3-7 seconds/1K tokens | 0.90+ (technical entities) | Free (local Ollama2) |
| **gpt-oss:20b** | Fallback when primary models unavailable | 1-3 seconds/1K tokens | 0.75+ | Free (local Ollama1) |

**LLM API Configuration** (via LiteLLM Gateway):

```python
import litellm

litellm.set_verbose = False  # Disable debug logging in production

# Entity extraction request
response = litellm.completion(
    model="gemma3:27b",  # LiteLLM routes to ollama/gemma3:27b → Ollama1
    messages=[
        {"role": "system", "content": ENTITY_EXTRACTION_SYSTEM_PROMPT},
        {"role": "user", "content": document_chunk}
    ],
    temperature=0.1,  # Near-deterministic (minimize LLM variance for consistency)
    max_tokens=2048,  # Sufficient for entity JSON arrays
    timeout=60,  # 60 second timeout (prevent hanging on slow models)
    api_base="http://hx-litellm-server.hx.dev.local:4000"  # LiteLLM Gateway
)

entities_json = response.choices[0].message.content
```

**Response Parsing & Validation** (Pydantic Schemas):

```python
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Literal

class ExtractedEntity(BaseModel):
    """Single entity extracted from document chunk."""
    entity_text: str = Field(min_length=1, max_length=200)
    entity_type: Literal["Person", "Organization", "Location", "Concept", "Technology", "Product", "Event", "Date", "Quantity", "Document"] = Field(
        description="Entity classification type (runtime validated via Literal)"
    )
    normalized_name: str = Field(min_length=1, max_length=200)
    confidence: float = Field(ge=0.0, le=1.0)
    context: str = Field(min_length=0, max_length=500)
    attributes: Dict[str, Any] = Field(default_factory=dict)

class ExtractionResponse(BaseModel):
    """LLM extraction response wrapper."""
    entities: List[ExtractedEntity]

# Parse LLM JSON response
try:
    extraction = ExtractionResponse.model_validate_json(entities_json)
except ValidationError as e:
    logger.error(f"LLM response validation failed: {e}")
    # Fallback: Return empty entity list if LLM output malformed
    extraction = ExtractionResponse(entities=[])
```

#### 3.2 Relationship Extraction

**Relationship Types** (10 Configurable Types):

| Relationship Type | Description | Examples | Bidirectional |
|-------------------|-------------|----------|---------------|
| **works_for** | Employment relationship | "John Smith works_for IBM" | No (Subject → Object) |
| **located_in** | Spatial relationship | "MIT located_in Cambridge, MA" | No |
| **mentions** | Document reference | "Research Paper mentions LightRAG" | No |
| **cites** | Citation relationship | "Paper A cites Paper B" | No |
| **part_of** | Hierarchical membership | "Deep Learning part_of Machine Learning" | No |
| **authored_by** | Authorship relationship | "Paper authored_by Dr. Smith" | No |
| **collaborates_with** | Collaboration (symmetric) | "Researcher A collaborates_with Researcher B" | Yes (stored twice, swapped) |
| **partners_with** | Partnership (symmetric) | "Company A partners_with Company B" | Yes |
| **similar_to** | Semantic similarity | "Concept A similar_to Concept B" | Yes |
| **leads** | Leadership relationship | "CEO leads Engineering Team" | No |

**LLM Relationship Extraction Prompt**:

```markdown
You are an expert relationship extraction system. Extract structured relationships between entities.

RELATIONSHIP TYPES: works_for, located_in, mentions, cites, part_of, authored_by, collaborates_with, partners_with, similar_to, leads

INSTRUCTIONS:
1. Extract ALL relationships between entities in the text
2. For each relationship, provide:
   - subject_entity: Subject entity name (canonical form)
   - predicate: Relationship type (one of 10 types above)
   - object_entity: Object entity name (canonical form)
   - confidence: Confidence score 0.0-1.0
   - context: 100-character snippet showing relationship in text
   - attributes: Relationship-specific attributes (e.g., {"role": "CEO", "from": "2015"})
3. Return ONLY valid JSON array

Document text:
{document_chunk}

Entities detected in this chunk (use these canonical names):
{entity_list}

Output (JSON only):
```

**Relationship Validation Layers**:

1. **Existence Validation**: Verify subject_entity and object_entity exist in entity collection (foreign key constraint)
2. **Type Compatibility**: Validate relationship type matches entity types (e.g., "works_for" requires Person → Organization)
3. **Bidirectional Handling**: For symmetric relationships (collaborates_with, partners_with, similar_to), store both directions:
   - Store: (A, collaborates_with, B)
   - Store: (B, collaborates_with, A)
4. **Duplicate Detection**: Prevent duplicate relationships (same subject, predicate, object)

#### 3.3 Entity Deduplication Strategy

**Hybrid String + Vector Similarity** (0.85 threshold):

**5-Phase Deduplication Algorithm**:

1. **Exact Match** (String Equality):
   - Compare normalized_name via case-insensitive exact match
   - Example: "MIT" == "MIT" → Merge immediately

2. **Alias Match** (String Contains):
   - Check if entity_name appears in existing entity's aliases list
   - Example: "Massachusetts Institute of Technology" in aliases["MIT"] → Merge

3. **Fuzzy String Similarity** (Jaro-Winkler):
   - Apply Jaro-Winkler similarity (favors prefix matches)
   - Threshold: 0.90 (high precision, avoid false positives)
   - Example: "Dr. John Smith" vs "John Smith" → similarity 0.92 → Merge

4. **Vector Similarity** (Cosine Distance on Embeddings):
   - Generate embedding for entity name + context snippet (bge-m3:567m)
   - Search Qdrant for similar entities (same entity_type, cosine similarity >0.85)
   - Example: "Machine Learning" vs "ML" → vector similarity 0.91 → Merge

5. **Manual Review Queue** (Uncertain Cases):
   - If string similarity 0.75-0.90 AND vector similarity 0.75-0.85 → flag for manual review
   - Log to `deduplication_review.jsonl` for human validation

**Deduplication Merge Strategy**:

```python
def merge_entities(existing_entity: EntityPayload, new_entity: ExtractedEntity) -> EntityPayload:
    """Merge new entity into existing entity, preserving information."""
    # Update aliases (add new entity_text if not already present)
    updated_aliases = list(set(existing_entity.aliases + [new_entity.entity_text, new_entity.normalized_name]))

    # Increment mention_count
    updated_mention_count = existing_entity.mention_count + 1

    # Merge attributes (new attributes override existing if conflict)
    merged_attributes = {**existing_entity.attributes, **new_entity.attributes}

    # Use highest confidence score
    updated_confidence = max(existing_entity.confidence, new_entity.confidence)

    return EntityPayload(
        entity_id=existing_entity.entity_id,  # Preserve original ID
        entity_name=existing_entity.entity_name,  # Keep canonical name
        entity_type=existing_entity.entity_type,
        aliases=updated_aliases,
        attributes=merged_attributes,
        confidence=updated_confidence,
        document_id=existing_entity.document_id,  # Original source document
        document_source=existing_entity.document_source,
        text_span=existing_entity.text_span,
        context_snippet=existing_entity.context_snippet,
        extraction_model=existing_entity.extraction_model,
        extraction_timestamp=existing_entity.extraction_timestamp,
        mention_count=updated_mention_count
    )
```

**Performance Optimization**:

- **Batch Deduplication**: Process 100 entities, then run deduplication pass (vs dedup after each entity)
- **Qdrant Search Optimization**: Use `query_filter` to restrict search to same entity_type (10x speedup)
- **Embedding Cache**: Cache entity name embeddings for 24 hours (Redis), avoid redundant Ollama3 calls

#### 3.4 LLM Integration Patterns

**Task-Specific Model Routing** (via LiteLLM):

| Task | Primary Model | Fallback Model | Rationale |
|------|---------------|----------------|-----------|
| **General entity extraction** | gemma3:27b | gpt-oss:20b | High accuracy for general text |
| **Technical entity extraction** | qwen3-coder:30b | gemma3:27b | Optimized for code, API docs |
| **Relationship extraction** | gemma3:27b | gpt-oss:20b | Good at semantic relationships |
| **Entity disambiguation** | gemma3:27b | N/A | Contextual reasoning required |

**Prompt Engineering Best Practices**:

1. **Few-Shot Examples**: Provide 2-3 examples in system prompt (improves consistency by 25%)
2. **Explicit Schema**: Specify JSON schema explicitly in prompt (reduces malformed responses)
3. **No Markdown Artifacts**: Instruct "return JSON only, no markdown" (prevents ` ```json` wrappers)
4. **Confidence Calibration**: Define confidence ranges explicitly (0.9-1.0 = explicit, 0.7-0.9 = inferred)
5. **Entity Type Spelling**: Use exact spelling from enum (prevents "Organization" vs "organisation" mismatches)

**Error Handling Strategies**:

1. **JSON Parse Failures**: Attempt regex extraction of JSON from markdown-wrapped response (e.g., strip ` ```json`)
2. **Invalid Entity Types**: Map unknown types to "Concept" (generic fallback)
3. **Missing Required Fields**: Skip entity if `entity_text` or `entity_type` missing (log warning)
4. **LLM Timeout**: Return partial results from previous chunks if timeout on current chunk
5. **Retry Logic**: Retry with fallback model (gpt-oss:20b) if primary model fails 2x

#### 3.5 Graph Construction Workflow

**5-Phase Workflow** (Ingestion → Chunking → Extraction → Deduplication → Storage):

**Phase 1: Document Ingestion**
- Input: DoclingDocument JSON or file path
- Extract text content from `doc_items` (concatenate paragraphs, headings)
- Output: Full document text string

**Phase 2: Document Chunking**
- Apply semantic chunking (4096 tokens, 512 overlap)
- Track chunk metadata (chunk_index, char_start, char_end)
- Output: List of text chunks with metadata

**Phase 3: Entity & Relationship Extraction** (per chunk)
- For each chunk:
  1. Generate entity extraction LLM prompt
  2. Call LiteLLM (`gemma3:27b` or `qwen3-coder:30b`)
  3. Parse LLM JSON response → validate with Pydantic
  4. Generate relationship extraction LLM prompt (with entities from step 3)
  5. Call LiteLLM for relationship extraction
  6. Parse and validate relationships
- Output: List of ExtractedEntity + List of ExtractedRelationship per chunk

**Phase 4: Entity Deduplication**
- Collect all entities across chunks
- Run 5-phase deduplication algorithm
- Merge duplicate entities (update aliases, mention_count)
- Output: Deduplicated entity list

**Phase 5: Qdrant Storage**
- Generate embeddings for each entity (bge-m3:567m via Ollama3)
- Batch upsert entities to `hx_docling_mcp_entities` collection (100 per batch)
- Generate embeddings for relationships ("Subject PREDICATE Object")
- Batch upsert relationships to `hx_docling_mcp_relationships` collection (200 per batch)
- Output: Qdrant collection IDs + entity/relationship counts

**Progress Tracking** (for `generate_knowledge_graph` MCP tool):

```python
@dataclass
class GraphConstructionProgress:
    """Progress tracking for knowledge graph generation."""
    total_chunks: int
    chunks_processed: int
    entities_extracted: int
    entities_after_dedup: int
    relationships_extracted: int
    qdrant_upsert_complete: bool
    errors: List[str] = field(default_factory=list)

    @property
    def percent_complete(self) -> float:
        return (self.chunks_processed / self.total_chunks) * 100 if self.total_chunks > 0 else 0
```

**Quality Metrics** (logged after each graph generation):

```python
quality_metrics = {
    "entity_precision": 0.85,  # Manual annotation sample (100 entities)
    "entity_recall": 0.80,
    "entity_f1": 0.82,
    "relationship_precision": 0.80,
    "relationship_recall": 0.75,
    "deduplication_rate": 0.23,  # 23% entities merged via deduplication
    "avg_entity_confidence": 0.88,
    "avg_relationship_confidence": 0.82,
    "extraction_latency_seconds": 45.2,  # For 10K-word document
    "llm_calls": 15,  # Number of LLM requests
    "llm_cost": 0.00  # Free (local Ollama)
}
```

#### 3.6 Configuration Requirements

**Environment Variables**:

```bash
# LiteLLM Gateway
LITELLM_BASE_URL=http://hx-litellm-server.hx.dev.local:4000
LITELLM_API_KEY=  # Optional, not required for Phase 1

# Ollama Endpoints (for direct access if needed)
OLLAMA1_BASE_URL=http://hx-ollama1-server.hx.dev.local:11434  # gemma3:27b, gpt-oss:20b
OLLAMA2_BASE_URL=http://hx-ollama2-server.hx.dev.local:11434  # qwen3-coder:30b
OLLAMA3_BASE_URL=http://hx-ollama3-server.hx.dev.local:11434  # bge-m3:567m (embeddings only)

# Entity Extraction Configuration
ENTITY_EXTRACTION_MODEL=gemma3:27b
TECHNICAL_EXTRACTION_MODEL=qwen3-coder:30b
RELATIONSHIP_EXTRACTION_MODEL=gemma3:27b
EMBEDDING_MODEL=bge-m3:567m

# Chunking Configuration
CHUNK_SIZE_TOKENS=4096
CHUNK_OVERLAP_TOKENS=512

# Deduplication Configuration
DEDUPLICATION_SIMILARITY_THRESHOLD=0.85
JARO_WINKLER_THRESHOLD=0.90
```

**Redis Keys** (for caching and progress tracking):

```
# Entity embedding cache (24-hour TTL)
extraction_cache:{model_name}:{content_sha256}

# Entity name embedding cache (24-hour TTL)
embedding_cache:entity:{entity_name_sha256}

# Graph construction progress (for async `generate_knowledge_graph` tool)
graph_progress:{session_id}

# Deduplication review queue
dedup_review:{document_id}
```

**Contributor**: andy-taylor (LightRAG SME)

#### 3.7 LightRAG Configuration and Tuning

**Contributor**: marcus-johnson (LightRAG Architecture Specialist)

**Document Chunking Strategy**:
- **Chunk Size**: 4096 tokens maximum (optimal for LLM context window, gemma3:27b supports 8K context)
- **Chunk Overlap**: 512 tokens (12.5% overlap ensures entity context spans chunk boundaries)
- **Chunking Algorithm**: Semantic chunking via hx-literag-server API (preserves paragraph/section boundaries when possible)
- **Configuration**:
  ```python
  literag_request = {
      "text": document_text,
      "chunk_size": 4096,
      "chunk_overlap": 512,
      "chunking_strategy": "semantic",  # Alternative: "fixed", "recursive"
      "preserve_section_boundaries": True
  }
  response = httpx.post(f"{LIGHTRAG_API_URL}/chunk", json=literag_request)
  ```

**Entity Deduplication Configuration**:
- **Semantic Similarity Threshold**: 0.85 (cosine similarity, high threshold for precision)
- **Deduplication Scope**: Per entity type (Person vs Person, Organization vs Organization)
- **Alias Handling**: Merge aliases into canonical entity (e.g., "MIT" + "Massachusetts Institute of Technology")
- **Cross-Document Deduplication**: Enabled by default (unified knowledge graph across document corpus)
- **Deduplication Algorithm**: LightRAG semantic deduplication via Qdrant vector search
  1. Extract entity from LLM response
  2. Generate embedding (bge-m3:567m)
  3. Search Qdrant for similar entities (similarity >0.85, same entity_type)
  4. If match found: Update existing entity (increment mention_count, merge aliases)
  5. If no match: Insert new entity
- **Configuration**:
  ```python
  deduplication_config = {
      "similarity_threshold": 0.85,
      "scope": "per_type",  # "per_type", "global", "per_document"
      "merge_strategy": "append_aliases",  # "append_aliases", "prefer_highest_confidence", "keep_all"
      "cross_document": True
  }
  ```

**Embedding Generation Configuration**:
- **Embedding Model**: bge-m3:567m (1024-dimensional dense vectors)
- **Embedding Context**: Entity name + context snippet (50 chars before/after mention)
- **Batch Size**: 32 entities per embedding request (optimize Ollama3 throughput)
- **Embedding Cache**: Redis cache (24-hour TTL, SHA256 hash key from entity_name + context)
- **Configuration**:
  ```python
  embedding_config = {
      "model": "bge-m3:567m",
      "context_window": 50,  # Characters before/after entity mention
      "batch_size": 32,
      "cache_enabled": True,
      "cache_ttl_hours": 24,
      "normalize_vectors": True  # Cosine distance requires normalized vectors
  }
  ```

**LLM Configuration for Entity Extraction**:
- **Primary Model**: gemma3:27b (via LiteLLM → Ollama1)
- **Fallback Model**: gpt-oss:20b (if gemma3:27b unavailable)
- **Technical Documents**: qwen3-coder:30b (via LiteLLM → Ollama2, optimized for code/API entity extraction)
- **Temperature**: 0.1 (near-deterministic, minimize LLM variance)
- **Max Tokens**: 2048 (sufficient for entity lists in JSON format)
- **Timeout**: 60 seconds per LLM request
- **Retry Policy**: 3 attempts with exponential backoff (1s, 2s, 4s)
- **Configuration**:
  ```python
  llm_config = {
      "entity_extraction_model": "gemma3:27b",
      "technical_docs_model": "qwen3-coder:30b",
      "relationship_extraction_model": "gemma3:27b",
      "temperature": 0.1,
      "max_tokens": 2048,
      "timeout_seconds": 60,
      "retry_attempts": 3,
      "system_prompt_template": "Extract entities from the following text. Return JSON array of entities with fields: name, type, attributes."
  }
  ```

**Entity Taxonomy (Configurable)**:
- **Default Entity Types**: Person, Organization, Location, Concept, Product, Date, Event (andy-taylor's 10 types as base)
- **Extended Types (Phase 2)**: Technology, Method, Metric, Dataset, Model, Tool, Institution, Publication
- **Custom Types**: User-defined via configuration (e.g., "Drug", "Gene", "Disease" for biomedical documents)
- **Type Hierarchy**: Support parent-child relationships (e.g., "Technology" → "Programming Language", "Framework")
- **Configuration**:
  ```python
  entity_taxonomy = {
      "default_types": ["Person", "Organization", "Location", "Concept", "Product", "Date", "Event", "Technology", "Quantity", "Document"],
      "extended_types": ["Method", "Metric", "Dataset", "Model", "Tool", "Institution", "Publication"],
      "custom_types": [],  # User-defined
      "type_hierarchy": {
          "Technology": ["Programming Language", "Framework", "Library"],
          "Organization": ["Company", "Institution", "Government Agency"]
      }
  }
  ```

**Relationship Type Taxonomy (Configurable)**:
- **Default Relationship Types**:
  - Organizational: works_for, leads, member_of, reports_to
  - Spatial: located_in, near, headquartered_in
  - Reference: mentions, cites, references
  - Temporal: before, after, during, concurrent_with
  - Semantic: part_of, instance_of, subclass_of
  - Authorship: authored_by, contributed_to, edited_by
- **Bidirectional Relationships**: collaborates_with, partners_with, similar_to (stored twice with swapped subject/object)
- **Custom Relationships**: User-defined via configuration (e.g., "treats", "causes" for medical domain)
- **Configuration**:
  ```python
  relationship_taxonomy = {
      "default_types": ["works_for", "located_in", "mentions", "cites", "part_of", "authored_by", "collaborates_with", "partners_with", "similar_to", "leads"],
      "bidirectional_types": ["collaborates_with", "partners_with", "similar_to"],
      "custom_types": [],  # User-defined
      "type_attributes": {
          "works_for": ["role", "from_date", "to_date"],
          "authored_by": ["author_position", "publication_date"]
      }
  }
  ```

#### 3.8 Knowledge Graph Query Capabilities

**Contributor**: marcus-johnson (LightRAG Architecture Specialist)

**Entity Search Capabilities**:

1. **Semantic Search** (Vector Similarity):
   - **Use Case**: Find entities conceptually similar to query text
   - **Example**: "Find all entities related to quantum computing research"
   - **Performance**: <100ms for <100K entities, <500ms for <1M entities

2. **Exact Match Search** (Keyword Filter):
   - **Use Case**: Find entity by exact name
   - **Example**: "Find entity 'MIT'"
   - **Performance**: <10ms (keyword index lookup)

3. **Fuzzy Search** (Alias Matching):
   - **Use Case**: Find entities with similar names or aliases
   - **Example**: "Find entities with alias containing 'Massachusetts Institute'"
   - **Performance**: <50ms (full-text index on aliases field)

4. **Attribute Filtering**:
   - **Use Case**: Find entities with specific attribute values
   - **Example**: "Find all organizations founded before 1900"
   - **Performance**: <100ms (indexed attributes)

5. **Confidence-Based Filtering**:
   - **Use Case**: Filter entities by extraction confidence
   - **Example**: "Find high-confidence Person entities (>0.8)"
   - **Performance**: <50ms (float index on confidence)

**Relationship Traversal Capabilities**:

1. **1-Hop Neighbors** (Direct Connections):
   - **Use Case**: Find all entities directly connected to target entity
   - **Performance**: <200ms for entities with <1000 connections

2. **Multi-Hop Traversal** (2-hop, 3-hop):
   - **Use Case**: Find entities N-hops away from target
   - **Example**: "Find all entities 2 hops from 'John Smith' (friends of friends)"
   - **Performance**: <1s for 2-hop, <5s for 3-hop (graph sparsity dependent)

3. **Shortest Path** (Path Finding):
   - **Use Case**: Find shortest path between two entities
   - **Performance**: <500ms for path length <5

4. **Predicate Filtering** (Relationship Type):
   - **Use Case**: Find relationships of specific type
   - **Performance**: <50ms (indexed predicate field)

**Subgraph Extraction Capabilities**:

1. **Entity Neighborhood Subgraph**:
   - **Use Case**: Extract local subgraph around entity (nodes + edges)
   - **Performance**: <2s for 2-hop subgraph with <10K entities

2. **Topic Clustering Subgraph**:
   - **Use Case**: Extract subgraph of entities related to specific topic
   - **Performance**: <1s for <200 topic-related entities

3. **Document-Scoped Subgraph**:
   - **Use Case**: Extract knowledge graph for specific document
   - **Performance**: <500ms per document

**Graph Analytics Capabilities**:

1. **Centrality Metrics** (Entity Importance):
   - **Degree Centrality**: Count of connections per entity
   - **Use Case**: Identify most connected entities (hubs, influential nodes)

2. **Clustering Coefficient** (Graph Density):
   - **Definition**: Ratio of actual edges to possible edges in entity neighborhood
   - **Use Case**: Measure how tightly connected an entity's neighborhood is

3. **Community Detection** (Graph Partitioning):
   - **Algorithm**: Louvain algorithm (external library like networkx)
   - **Use Case**: Identify clusters of related entities (research groups, topics, organizations)

4. **PageRank** (Entity Importance via Link Structure):
   - **Algorithm**: PageRank over relationship graph
   - **Use Case**: Rank entities by importance (citations, authority)

**Hybrid Query Modes** (Combining Low-Level and High-Level Retrieval):

1. **Low-Level Retrieval** (Specific Entity/Fact Lookup):
   - **Use Case**: Answer specific questions with precise facts
   - **Example**: "Who is the CEO of Acme Corp?"

2. **High-Level Retrieval** (Abstract Concept Queries):
   - **Use Case**: Explore broad topics and relationships
   - **Example**: "What are the main research areas at MIT?"

3. **Hybrid Query** (Combination):
   - **Use Case**: Complex questions requiring both specific facts and conceptual understanding
   - **Example**: "Find all researchers at MIT working on quantum computing who published in 2023"

#### 3.9 Performance Optimization and Benchmarking

**Contributor**: marcus-johnson (LightRAG Architecture Specialist)

**Batch Entity Extraction**:
- **Parallel Document Processing**: Process 10 documents concurrently (asyncio tasks)
- **LLM Request Batching**: Combine multiple entity extraction requests into single LLM call (reduce latency)
- **Configuration**:
  ```python
  performance_config = {
      "parallel_documents": 10,
      "llm_batch_size": 5,  # Process 5 chunks per LLM request
      "max_concurrent_llm_requests": 3  # Limit concurrent LLM calls (avoid rate limits)
  }
  ```
- **Benchmark**: 100 documents (10K words each) in <30 minutes (with gemma3:27b)

**Incremental Graph Updates** (Avoid Full Reconstruction):
- **Strategy**: Only extract entities from new/modified documents, merge into existing graph
- **Algorithm**:
  1. Check if document already processed (query Qdrant for document_id)
  2. If exists: Delete old entities/relationships, extract new ones
  3. If new: Extract entities/relationships, merge via deduplication
- **Performance**: 10x faster than full graph reconstruction for updates

**Query Optimization**:
- **Index Utilization**: Ensure all filtered fields have payload indexes
- **Scroll vs Search**: Use `scroll` for large result sets (>1000 items), `search` for vector similarity queries
- **Limit Results**: Always set reasonable limits (default: 100, max: 10000) to prevent memory exhaustion
- **Filter Pushdown**: Apply filters in Qdrant query (not post-processing in Python) for performance

**Memory Management**:
- **Lazy Loading**: Load entity details only when needed (don't fetch all entities upfront)
- **Pagination**: Use Qdrant scroll with offset/limit for large graphs
- **Batch Deletion**: Delete old entities in batches of 1000 (prevent memory spikes)

**Caching Strategy** (Redis-Backed):
- **Entity Embedding Cache**: Cache bge-m3 embeddings for 24 hours (reduce Ollama3 load)
- **LLM Response Cache**: Cache entity extraction results (keyed by document hash + model)
- **Query Result Cache**: Cache frequent queries for 1 hour
- **Cache Hit Ratio Target**: >40% for production workloads

#### 3.10 Quality Validation and Metrics

**Contributor**: marcus-johnson (LightRAG Architecture Specialist)

**Entity Extraction Quality Metrics**:

1. **Precision** (Correctness of Extracted Entities):
   - **Target**: >85% precision for default entity types
   - **Measurement**: Manual annotation of sample (100 documents), compare against LightRAG output

2. **Recall** (Completeness of Entity Extraction):
   - **Target**: >80% recall for default entity types
   - **Factors**: Chunking strategy, LLM context window

3. **F1 Score** (Harmonic Mean of Precision and Recall):
   - **Target**: >82% F1 score for default entity types
   - **Tracking**: Log F1 score per entity type, monitor degradation over time

4. **Confidence Calibration** (LLM Confidence Accuracy):
   - **Target**: Confidence scores should be well-calibrated (±5% error)

**Relationship Extraction Quality Metrics**:

1. **Precision**: >80% precision for default relationship types
2. **Recall**: >75% recall for default relationship types
3. **Subject-Object Accuracy**: >90% (correct entity linking)

**Graph Coherence Metrics**:

1. **Entity Connectivity** (Graph Density):
   - **Metric**: Average degree per entity (relationships per entity)
   - **Target**: >2.0 (indicates well-connected graph)

2. **Consistency Checks**:
   - **Orphaned Entities**: <10% target
   - **Dangling Relationships**: 0% (strict integrity constraint)

3. **Deduplication Effectiveness**:
   - **Target**: >20% deduplication rate (indicates effective alias merging)

**Monitoring and Alerting** (Phase 2 - When hx-metric-server Operational):

1. **Entity Extraction Latency**: p95 <10s per document (10K words)
2. **Relationship Extraction Latency**: p95 <15s per document
3. **Graph Storage Operations**: p95 <500ms for batch of 100 entities
4. **Entity Extraction Quality**: F1 >0.82 (alert if <0.75)
5. **Deduplication Rate**: >20% (alert if <10%)

**4. Integration Manager** (External Service Clients)
- **Purpose**: Manage connections to LiteLLM, Qdrant, Redis with resilience and performance optimization
- **Responsibilities**:
  - Connection pool management (Redis, LiteLLM HTTP connection pooling)
  - Health check execution (LiteLLM `/health`, Qdrant `/health`, Redis `PING`)
  - Retry logic with exponential backoff and circuit breaking
  - Graceful degradation (disable features if dependencies unavailable)
  - Credential management (API keys from environment, Ansible Vault integration)
  - Request routing and load balancing (LiteLLM Router model fallback)
  - Response caching for identical entity extraction requests (cost optimization)
- **Technology**: httpx (HTTP client for LiteLLM), redis-py (Redis client), qdrant-client (Qdrant)
- **Interfaces**:
  - **Input**: Integration requests (LLM completion, vector upsert, session get/set)
  - **Output**: Integration responses (JSON, success/failure status, retry metadata)

#### 4.1 LiteLLM Gateway Integration

**Contributor**: shane-black (LiteLLM Integration SME)

**LiteLLM Client Configuration**:
- **Base URL**: `http://hx-litellm-server.hx.dev.local:4000` (LiteLLM proxy endpoint)
- **API Key Handling**: Optional API key from environment variable `LITELLM_API_KEY` (future OAuth2 support)
- **Timeout Configuration**:
  - Connection timeout: 10 seconds (establish TCP connection to LiteLLM proxy)
  - Read timeout: 120 seconds (wait for LLM completion response, handles slow model inference)
  - Write timeout: 5 seconds (send request payload)
- **Connection Pooling**: httpx AsyncClient with connection pool (max 20 connections, max 100 keepalive connections)
- **Streaming vs Batch**: Batch completions only (no streaming for entity extraction, deterministic output required)
- **Rate Limiting**: Client-side rate limiter (max 10 concurrent requests to LiteLLM, queue excess requests)
- **Backoff Strategy**: Exponential backoff with jitter (initial 1s, max 60s, multiplier 2.0, jitter ±20%)

**Model Selection Strategy**:
- **Primary Model (General Text)**: `gemma3:27b` via Ollama1 (hx-ollama1-server.hx.dev.local)
  - Use case: General document entity extraction (business documents, reports, articles)
  - Model routing: LiteLLM routes to `ollama/gemma3:27b` → Ollama1 backend
  - Latency: ~2-5 seconds for 1K token entity extraction (P95)
  - Quality: High accuracy for named entities (PERSON, ORG, LOCATION, DATE)
- **Secondary Model (Technical/Code)**: `qwen3-coder:30b` via Ollama2 (hx-ollama2-server.hx.dev.local)
  - Use case: Technical documentation, source code, API documentation entity extraction
  - Model routing: LiteLLM routes to `ollama/qwen3-coder:30b` → Ollama2 backend
  - Latency: ~3-7 seconds for 1K token entity extraction (P95)
  - Quality: Excellent for technical entities (FUNCTION, CLASS, API_ENDPOINT, DEPENDENCY)
- **Fallback Model**: `gpt-oss:20b` via Ollama1 (hx-ollama1-server.hx.dev.local)
  - Use case: Fallback when primary models unavailable or overloaded
  - Model routing: LiteLLM Router automatically falls back on 503/timeout
  - Latency: ~1-3 seconds for 1K token entity extraction (faster, lower quality)

**Model Fallback Strategy** (LiteLLM Router-Based):
1. **First attempt**: Use primary model (gemma3:27b or qwen3-coder:30b based on document type)
2. **On 503/timeout**: LiteLLM Router automatically retries with fallback model (gpt-oss:20b)
3. **On repeated failures**: Circuit breaker opens, disable entity extraction for 60 seconds
4. **Circuit breaker recovery**: Attempt health check after 60s, re-enable if healthy

**Model Performance Characteristics**:
- **gemma3:27b**: High accuracy (F1 0.85+), moderate latency (3-5s), medium token throughput (100 tok/s)
- **qwen3-coder:30b**: Excellent technical accuracy (F1 0.90+), higher latency (5-7s), lower throughput (60 tok/s)
- **gpt-oss:20b**: Moderate accuracy (F1 0.75+), low latency (1-3s), high throughput (200 tok/s)

**Cost Optimization** (Prefer Local Ollama):
- **Cost Tier 1 (Free)**: Ollama1/2 local models (gemma3, qwen3-coder, gpt-oss) - zero cost per token
- **Cost Tier 2 (Fallback)**: No external API providers in Phase 1 (future: OpenAI/Anthropic if quality insufficient)
- **Caching Strategy**: Cache entity extraction results for identical document chunks (SHA-256 hash key)
  - Cache backend: Redis with 7-day TTL for extraction results
  - Cache key format: `extraction_cache:{model_name}:{content_hash}`
  - Expected cache hit rate: 15-30% for repeated document processing workflows
  - Cost savings: 15-30% reduction in LLM API calls via caching

**Prompt Engineering for Entity Extraction**:

Prompt templates structured for high extraction quality:
```python
ENTITY_EXTRACTION_PROMPT = """
You are an expert entity extraction system. Extract entities from the following document text.

Return ONLY a JSON array of entities with this exact structure:
[
  {
    "name": "entity name exactly as it appears",
    "type": "PERSON|ORG|LOCATION|DATE|PRODUCT|CONCEPT|FUNCTION|CLASS|API_ENDPOINT",
    "confidence": 0.0-1.0,
    "context": "surrounding sentence for disambiguation"
  }
]

Rules:
- Extract only factual entities mentioned in the text
- Preserve exact capitalization and spelling
- Assign confidence based on contextual clarity (explicit mention = 1.0, inferred = 0.5-0.8)
- Include enough context for disambiguation (e.g., "Apple Inc." vs "apple fruit")
- Return empty array [] if no entities found

Document text:
{document_chunk}

Output (JSON only, no explanation):
"""
```

**LLM Parameter Settings**:
- **Temperature**: 0.1 (near-deterministic, consistent entity extraction)
- **Top-p**: 0.9 (nucleus sampling for quality)
- **Max Tokens**: 2048 (sufficient for entity JSON arrays)
- **Stop Sequences**: `["```", "---"]` (prevent markdown artifacts)
- **Presence Penalty**: 0.0 (allow repeated entity mentions)
- **Frequency Penalty**: 0.0 (no penalty for common entities)

#### 4.2 Error Handling & Resilience

**Contributor**: shane-black (LiteLLM Integration SME)

**LiteLLM Error Types and Handling**:

1. **Timeout Errors** (`asyncio.TimeoutError`):
   - **Cause**: LLM inference exceeds read timeout (120s)
   - **Recovery**: Retry with exponential backoff (1s, 2s, 4s), max 3 attempts
   - **Fallback**: Switch to faster fallback model (gpt-oss:20b) if retries exhausted
   - **MCP Error Code**: `REQUEST_TIMEOUT` (-32002)

2. **Rate Limit Errors** (HTTP 429):
   - **Cause**: Exceeded LiteLLM proxy rate limits
   - **Recovery**: Exponential backoff with jitter (1-60s range), max 5 attempts
   - **Queue Management**: Queue excess requests, process when capacity available
   - **MCP Error Code**: `RATE_LIMITED` (-32001)

3. **Model Unavailable** (HTTP 503):
   - **Cause**: Ollama backend down or overloaded
   - **Recovery**: LiteLLM Router automatically retries with fallback model
   - **Circuit Breaker**: Open after 3 consecutive 503 errors, disable entity extraction for 60s
   - **MCP Error Code**: `SERVICE_UNAVAILABLE` (-32003)

4. **Invalid Response** (Malformed JSON):
   - **Cause**: LLM returned non-JSON or invalid entity structure
   - **Recovery**: Attempt regex extraction of JSON from markdown-wrapped response
   - **Validation**: Pydantic schema validation, skip malformed entities
   - **Fallback**: Return partial results (valid entities only), log error
   - **MCP Error Code**: `PARSE_ERROR` (-32700)

**Retry Logic with Exponential Backoff**:

```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=60),
    retry=retry_if_exception_type((TimeoutError, httpx.HTTPStatusError)),
    reraise=True
)
async def litellm_completion_with_retry(
    model: str,
    messages: List[Dict[str, str]],
    temperature: float = 0.1,
    max_tokens: int = 2048
) -> str:
    """Call LiteLLM with automatic retry on transient errors."""
    response = await litellm_client.post(
        "/v1/chat/completions",
        json={
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        },
        timeout=httpx.Timeout(connect=10.0, read=120.0, write=5.0)
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]
```

**Circuit Breaker Pattern**:

```python
from enum import Enum
from datetime import datetime, timedelta

class CircuitState(Enum):
    CLOSED = "closed"  # Normal operation
    OPEN = "open"      # Failures exceeded threshold, reject requests
    HALF_OPEN = "half_open"  # Testing recovery

class CircuitBreaker:
    """Circuit breaker for LiteLLM integration."""

    def __init__(self, failure_threshold: int = 3, timeout_seconds: int = 60):
        self.failure_threshold = failure_threshold
        self.timeout = timedelta(seconds=timeout_seconds)
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

    async def call(self, func, *args, **kwargs):
        """Execute function through circuit breaker."""
        if self.state == CircuitState.OPEN:
            # Check if timeout expired, switch to half-open
            if datetime.utcnow() - self.last_failure_time > self.timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker OPEN - LiteLLM unavailable")

        try:
            result = await func(*args, **kwargs)
            # Success - reset circuit
            if self.state == CircuitState.HALF_OPEN:
                self.state = CircuitState.CLOSED
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = datetime.utcnow()

            if self.failure_count >= self.failure_threshold:
                self.state = CircuitState.OPEN
                logger.error(f"Circuit breaker OPEN after {self.failure_count} failures")

            raise e
```

**Graceful Degradation**:

When LiteLLM unavailable:
1. **Disable Entity Extraction**: Return MCP error for `generate_knowledge_graph` tool
2. **Document Conversion Still Works**: Docling processor operates independently
3. **Cached Results**: Return cached entity extraction results if available (7-day TTL)
4. **Health Check**: Expose degraded status via `/health` endpoint
5. **User Notification**: MCP error message: "Entity extraction unavailable (LiteLLM service degraded)"

**Error Logging and Alerting**:

```python
# Structured error logging
logger.error(
    "LiteLLM request failed",
    extra={
        "error_type": "timeout",
        "model": "gemma3:27b",
        "retry_attempt": 3,
        "latency_ms": 125000,
        "request_id": "req_abc123"
    }
)

# Metrics for alerting (Phase 2 - Prometheus)
litellm_request_duration_seconds.labels(model="gemma3:27b", status="timeout").observe(125.0)
litellm_errors_total.labels(model="gemma3:27b", error_type="timeout").inc()
```

#### 4.3 Performance Optimization

**Contributor**: shane-black (LiteLLM Integration SME)

**Batch Processing** (Multiple Chunks in Single Request):

```python
async def batch_extract_entities(chunks: List[str], model: str = "gemma3:27b") -> List[List[ExtractedEntity]]:
    """Extract entities from multiple chunks in parallel."""
    # Limit concurrent LLM requests (avoid overwhelming LiteLLM)
    semaphore = asyncio.Semaphore(10)

    async def extract_chunk(chunk: str) -> List[ExtractedEntity]:
        async with semaphore:
            prompt = ENTITY_EXTRACTION_PROMPT.format(document_chunk=chunk)
            response_json = await litellm_completion_with_retry(
                model=model,
                messages=[{"role": "user", "content": prompt}]
            )
            return ExtractionResponse.model_validate_json(response_json).entities

    # Process chunks in parallel
    results = await asyncio.gather(*[extract_chunk(chunk) for chunk in chunks])
    return results
```

**Parallel Requests** (Concurrent LLM Calls):

- **Concurrency Limit**: Max 10 concurrent requests to LiteLLM (avoid rate limits)
- **Semaphore Pattern**: `asyncio.Semaphore(10)` to throttle concurrency
- **Speedup**: 5-10x faster than sequential processing for batch documents

**Response Caching** (Redis-Backed):

```python
import hashlib

async def cached_entity_extraction(chunk: str, model: str) -> List[ExtractedEntity]:
    """Extract entities with Redis caching."""
    # Generate cache key
    content_hash = hashlib.sha256(chunk.encode()).hexdigest()
    cache_key = f"extraction_cache:{model}:{content_hash}"

    # Check cache
    cached_result = await redis_client.get(cache_key)
    if cached_result:
        return ExtractionResponse.model_validate_json(cached_result).entities

    # Cache miss - perform extraction
    entities = await extract_entities_from_chunk(chunk, model)

    # Store in cache (7-day TTL)
    await redis_client.setex(
        cache_key,
        timedelta(days=7),
        ExtractionResponse(entities=entities).model_dump_json()
    )

    return entities
```

**Token Usage Tracking** (Cost Monitoring):

```python
@dataclass
class TokenUsageMetrics:
    """Track LLM token usage for cost monitoring."""
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    model: str
    latency_ms: float

async def track_token_usage(response: Dict[str, Any], model: str, latency_ms: float):
    """Log token usage for cost analysis."""
    usage = response.get("usage", {})
    metrics = TokenUsageMetrics(
        prompt_tokens=usage.get("prompt_tokens", 0),
        completion_tokens=usage.get("completion_tokens", 0),
        total_tokens=usage.get("total_tokens", 0),
        model=model,
        latency_ms=latency_ms
    )

    logger.info(f"Token usage: {metrics.total_tokens} tokens ({metrics.model}), latency: {metrics.latency_ms}ms")

    # Metrics (Phase 2)
    litellm_tokens_total.labels(model=model, token_type="prompt").inc(metrics.prompt_tokens)
    litellm_tokens_total.labels(model=model, token_type="completion").inc(metrics.completion_tokens)
```

**Performance Targets**:
- **Entity Extraction Latency**: p95 <10s per document (10K words, 3 chunks)
- **Batch Processing Speedup**: 5-10x faster than sequential (10 concurrent requests)
- **Cache Hit Rate**: >15% for production workloads (reduces LLM load by 15-30%)
- **LiteLLM Throughput**: 100-200 requests/minute (limited by Ollama backend capacity)

**Contributor**: shane-black (LiteLLM Integration SME)

**5. Session Manager** (Workflow State)
- **Purpose**: Manage session-based multi-step document processing workflows with Redis-backed persistence
- **Responsibilities**:
  - Session creation and lifecycle management (TTL enforcement with sliding window)
  - Document ID association with sessions (Redis sets for efficient membership checks)
  - Processing status tracking (pending, processing, completed, failed) with atomic transitions
  - Session metadata storage (user context, timestamps, workflow state)
  - Graceful degradation when Redis unavailable (in-memory fallback with warning)
  - Cache warming for frequently accessed sessions
- **Technology**: Redis (key-value storage, sets, hashes), redis-py connection pooling, Python data classes
- **Interfaces**:
  - **Input**: Session operations (create, get, update, delete, extend TTL, list documents)
  - **Output**: Session state (JSON metadata), document processing status
- **Redis Data Structures**:
  - **Session Metadata**: Redis hash `session:<session_id>` (keys: user, created_at, last_accessed, ttl_hours, workflow_state)
  - **Document Association**: Redis set `session:<session_id>:documents` (members: document_ids)
  - **Processing Status**: Redis hash `session:<session_id>:status` (keys: document_id, values: pending|processing|completed|failed)
  - **Session Index**: Redis set `sessions:active` (members: session_ids for efficient listing)
- **TTL Strategy**:
  - **Default TTL**: 24 hours (86400 seconds) from creation
  - **Sliding Window**: Extend TTL on each session access (read/write operations)
  - **Maximum TTL**: 168 hours (7 days) hard limit to prevent unbounded growth
  - **Automatic Cleanup**: Redis EXPIRE command enforces TTL, no manual garbage collection required
  - **TTL Extension**: Each session access extends TTL by TTL_EXTENSION_HOURS (default: 4 hours, max: remaining_ttl_to_max)
- **Resilience Patterns**:
  - **Connection Pooling**: Redis connection pool (max 10 connections, timeout 5 seconds)
  - **Retry Logic**: 3 retry attempts with exponential backoff (100ms, 200ms, 400ms) for transient errors
  - **Circuit Breaker**: Disable session features after 5 consecutive Redis failures, re-enable on successful health check
  - **Graceful Degradation**: If Redis unavailable, operate in stateless mode (disable session tools, return MCP error)
  - **Health Checks**: Redis PING command every 30 seconds, mark degraded if latency >100ms
- **Performance Optimization**:
  - **Connection Keepalive**: TCP keepalive enabled (interval: 60 seconds, idle: 300 seconds)
  - **Connection Timeout**: 5 seconds connect timeout, 10 seconds read/write timeout
  - **Pipelining**: Use Redis pipeline for bulk operations (batch session status updates, document association)
  - **Memory Management**: Monitor Redis memory usage, alert if >75% of maxmemory
  - **Eviction Policy**: volatile-lru (evict least recently used keys with TTL set, preserve persistent data)
- **Error Handling**:
  - **Connection Errors**: Retry with backoff, fail to stateless mode after 3 attempts
  - **Timeout Errors**: Log timeout, return cached data if available, otherwise fail gracefully
  - **Redis Down**: Log ERROR, disable session features, return MCP error for session tools
  - **Key Expiration**: Handle expired sessions gracefully (return not_found error, cleanup references)
- **Monitoring Metrics**:
  - `redis_operation_duration_seconds{operation="get|set|delete|..."}`: Histogram (p50, p95, p99)
  - `redis_connection_pool_size`: Gauge (active connections, idle connections)
  - `redis_errors_total{error_type="connection|timeout|key_not_found|..."}`: Counter
  - `session_ttl_extensions_total`: Counter (track sliding window TTL extensions)
  - `session_evictions_total{reason="ttl_expired|manual_delete|redis_eviction"}`: Counter

**6. Health Check & Monitoring** (Observability)
- **Purpose**: Expose health status and operational metrics
- **Responsibilities**:
  - Dependency health checks (LiteLLM, Qdrant, Redis)
  - Service health aggregation (healthy, degraded, unhealthy)
  - Metric collection (performance, throughput, errors)
  - Log management (structured JSON logging)
- **Technology**: Python logging, Prometheus client (Phase 2)
- **Interfaces**:
  - **Input**: Health check requests, metric queries
  - **Output**: Health status JSON, Prometheus metrics (Phase 2)

### Data Flow

**Document Conversion Flow (Stage 1)**:

```
1. AI Agent → MCP Client: Invoke tool "convert_document" with document path
2. MCP Client → FastMCP Server (HTTP): POST /mcp/tool/convert_document
3. FastMCP Server: Validate MCP request, extract parameters
4. FastMCP Server → Docling Processor: Convert document (path)
5. Docling Processor: Detect format (PDF), select backend (pypdfium2)
6. Docling Processor: Parse PDF → Extract pages, images, tables, text
7. Docling Processor → FastMCP Server: Return DoclingDocument JSON
8. FastMCP Server → MCP Client: MCP response (DoclingDocument)
9. MCP Client → AI Agent: DoclingDocument available for downstream tasks
```

**Knowledge Graph Generation Flow (Stage 2)**:

```
1. AI Agent → MCP Client: Invoke tool "generate_knowledge_graph" with document
2. MCP Client → FastMCP Server (HTTP): POST /mcp/tool/generate_knowledge_graph
3. FastMCP Server → Docling Processor: Convert document (if not already converted)
4. Docling Processor → FastMCP Server: Return DoclingDocument JSON
5. FastMCP Server → LightRAG Engine: Extract entities from DoclingDocument
6. LightRAG Engine → Integration Manager: Request LLM completion (entity extraction prompt)
7. Integration Manager → LiteLLM Gateway: POST /v1/chat/completions (model: gemma3:27b)
8. LiteLLM Gateway → Ollama1: Forward request to gemma3:27b model
9. Ollama1 → LiteLLM Gateway: Return entity extraction result (JSON)
10. LiteLLM Gateway → Integration Manager: Return completion (entities)
11. Integration Manager → LightRAG Engine: Return entities
12. LightRAG Engine: Extract relationships (repeat LLM call with relationship prompt)
13. LightRAG Engine: Deduplicate entities, construct graph
14. LightRAG Engine → Integration Manager: Store entities in Qdrant
15. Integration Manager → Qdrant: POST /collections/hx_docling_mcp_entities/points (upsert entities)
16. Qdrant → Integration Manager: Confirm upsert success
17. Integration Manager → LightRAG Engine: Confirm entity storage
18. LightRAG Engine → Integration Manager: Store relationships in Qdrant
19. Integration Manager → Qdrant: POST /collections/hx_docling_mcp_relationships/points
20. Qdrant → Integration Manager: Confirm upsert success
21. LightRAG Engine → FastMCP Server: Return graph summary (entity count, relationship count)
22. FastMCP Server → MCP Client: MCP response (knowledge graph metadata)
23. MCP Client → AI Agent: Knowledge graph available for querying
```

**Session Management Flow**:

```
1. AI Agent → MCP Client: Invoke tool "create_session"
2. MCP Client → FastMCP Server: POST /mcp/tool/create_session
3. FastMCP Server → Session Manager: Create session
4. Session Manager → Integration Manager: Redis SET session:abc123 (metadata JSON, TTL 24h)
5. Integration Manager → Redis: SET command
6. Redis → Integration Manager: OK
7. Session Manager → FastMCP Server: Return session ID "abc123"
8. FastMCP Server → MCP Client: MCP response (session ID)
9. AI Agent: Use session ID for subsequent tool invocations (upload, process, query)
10. [Later] AI Agent → MCP Client: Invoke tool "get_session_status" (session_id: abc123)
11. FastMCP Server → Session Manager: Get session
12. Session Manager → Integration Manager: Redis GET session:abc123
13. Integration Manager → Redis: GET command
14. Redis → Integration Manager: Session metadata JSON
15. Session Manager → FastMCP Server: Return session state
16. FastMCP Server → MCP Client: MCP response (session status)
```

### Technology Stack

**Core Technologies**:
- **Python 3.10+**: Runtime environment (docling requires 3.10 minimum)
- **FastMCP 0.2+**: MCP protocol framework for server implementation
- **Docling ~2.63**: Document conversion library (embedded, in-process)
- **LightRAG**: Knowledge graph-based RAG framework (entity extraction, graph building)
- **Qdrant Client**: Python client for Qdrant vector database (HTTP API)
- **Redis-py**: Python client for Redis (connection pool, pub/sub)
- **Pydantic 2.10+**: Data validation, MCP tool schema generation
- **Uvicorn**: ASGI server for FastMCP HTTP transport

**Supporting Technologies**:
- **httpx**: HTTP client for LiteLLM integration (async-capable)
- **pypdfium2**: PDF rendering backend for Docling (alternative: pdfium)
- **mammoth**: DOCX parsing backend for Docling
- **tesseract-ocr**: OCR engine for scanned PDFs and images (system package)
- **poppler-utils**: PDF rendering utilities (system package)

**Infrastructure Technologies**:
- **Systemd**: Service management (auto-restart, logging, resource limits)
- **Ubuntu 24.04 LTS**: Operating system (bare-metal deployment)
- **Python venv**: Virtual environment for dependency isolation

### Deployment Architecture

**Single-Node Deployment** (Phase 1):
- **Node**: hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)
- **Process Model**: Single Python process (Uvicorn ASGI server)
- **Concurrency**: Asyncio-based concurrency (4 worker coroutines by default)
- **State**: Stateless (session state in Redis, knowledge graphs in Qdrant)

**Service Management**:
- **Systemd Unit**: `docling-mcp.service`
- **Auto-Restart**: Yes (3 restarts in 5 minutes, then fail state)
- **Logging**: systemd journal + optional file logging
- **Resource Limits**: Systemd cgroup limits (4GB memory, 2 CPU cores soft limit)

**Systemd Service Unit File** (`/etc/systemd/system/docling-mcp.service`):
```ini
[Unit]
Description=Docling MCP Server - Document Processing and Knowledge Graph Service
Documentation=file:///opt/docling-mcp/README.md
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=docling-mcp
Group=docling-mcp
WorkingDirectory=/opt/docling-mcp
Environment="PATH=/opt/docling-mcp/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EnvironmentFile=/etc/docling-mcp/.env.production

# Pre-start validation
ExecStartPre=/opt/docling-mcp/venv/bin/python -c "import docling, fastmcp; print('Dependencies validated')"
ExecStartPre=/bin/mkdir -p /var/lib/docling-mcp/cache/uploads /var/lib/docling-mcp/cache/downloads
ExecStartPre=/bin/chown -R docling-mcp:docling-mcp /var/lib/docling-mcp /var/log/docling-mcp

# Main service execution
ExecStart=/opt/docling-mcp/venv/bin/uvicorn src.mcp_server:app --host 0.0.0.0 --port 8000 --log-level info --workers 1

# Graceful shutdown
ExecStop=/bin/kill -TERM $MAINPID
TimeoutStopSec=30

# Automatic restart policy
Restart=on-failure
RestartSec=10s
StartLimitInterval=300s
StartLimitBurst=3

# Resource limits
MemoryLimit=4G
CPUQuota=200%
TasksMax=1024

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/docling-mcp /var/log/docling-mcp
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
LockPersonality=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=docling-mcp

[Install]
WantedBy=multi-user.target
```

**Deployment Procedure Outline** (Detailed plan in `plan.md`):

**Phase 1: Pre-Deployment Preparation**
1. Validate node accessibility (SSH access to hx-docling-mcp-server.hx.dev.local)
2. Verify OS version (Ubuntu 24.04 LTS confirmed)
3. Check resource availability (CPU, memory, disk space meet requirements)
4. Validate dependency service status (LiteLLM, Qdrant, Redis, Ollama1/2/3 operational)
5. DNS verification (hx-docling-mcp-server.hx.dev.local resolves correctly)

**Phase 2: System Configuration**

**NOTE:** Service account `docling-mcp@hx.dev.local` must be created FIRST on hx-dc-server (hx-dc-server.hx.dev.local) by frank-lucas (Security Specialist) using `samba-tool user create` per HX-Infrastructure identity standards. See Security Architecture section for Samba AD account details.

1. Install system dependencies:
   - Python 3.11 runtime
   - poppler-utils, tesseract-ocr, libmagic1, build-essential
   - Additional system libraries (libssl-dev, libffi-dev, image libraries)

2. Verify Samba AD service account exists and is replicated:
   - **PREREQUISITE:** frank-lucas must create `docling-mcp@hx.dev.local` on hx-dc-server BEFORE proceeding
   - Verify account replication: `wbinfo -i docling-mcp@hx.dev.local`
   - Verify account availability: `getent passwd docling-mcp@hx.dev.local`
   - If SSSD not configured, coordinate with william-chen for domain integration

3. Create local system user for systemd service execution:
   - **Option A (PREFERRED if SSSD configured):** Use domain account directly in systemd unit file:
     ```
     [Service]
     User=docling-mcp@hx.dev.local
     Group=domain users@hx.dev.local
     ```
   - **Option B (if SSSD NOT configured):** Create local system user:
     ```bash
     useradd --system --home-dir /opt/docling-mcp --shell /usr/sbin/nologin docling-mcp-local
     ```
     Note: This local account is SEPARATE from the Samba AD account and used only for process execution.

4. Create directory structure:
   - `/opt/docling-mcp/` (service installation)
   - `/var/lib/docling-mcp/` (runtime data, cache)
   - `/var/log/docling-mcp/` (logs)
   - `/etc/docling-mcp/` (configuration)

5. Set file ownership and permissions per security requirements:
   - If using domain account: `chown -R docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp`
   - If using local account: `chown -R docling-mcp-local:docling-mcp-local /opt/docling-mcp`

**Phase 3: Service Installation**
1. Create Python virtual environment (`python3.11 -m venv /opt/docling-mcp/venv`)
2. Install Python dependencies via requirements.txt
3. Deploy service source code to `/opt/docling-mcp/src/`
4. Configure environment variables in `/etc/docling-mcp/.env.production`:
   - LiteLLM API base URL
   - Qdrant host/port
   - Redis host/port
   - Log level, cache directory, session TTL
5. Install systemd service unit file (`/etc/systemd/system/docling-mcp.service`)
6. Reload systemd daemon (`systemctl daemon-reload`)

**Phase 4: Health Check Integration with Systemd**
- Health check endpoint (`/health`) validates:
  - Service running and responsive
  - LiteLLM connectivity (entity extraction capability)
  - Qdrant connectivity (knowledge graph storage capability)
  - Redis connectivity (session management capability)
- Systemd integration:
  - ExecStartPre validates Python environment before start
  - Health check endpoint monitored externally (every 30 seconds)
  - Service enters degraded state if dependencies unavailable (graceful degradation)

**Phase 5: Service Startup and Validation**
1. Enable service for automatic startup (`systemctl enable docling-mcp.service`)
2. Start service (`systemctl start docling-mcp.service`)
3. Monitor startup logs (`journalctl -u docling-mcp.service -f`)
4. Validate health check endpoint responds (`curl http://hx-docling-mcp-server.hx.dev.local:8000/health`)
5. Execute integration tests (MCP tool discovery, sample document conversion)
6. Verify dependency integrations (LiteLLM, Qdrant, Redis connectivity tests)

**Phase 6: Post-Deployment Validation**
1. Run deployment test suite (subset of full test suite, critical paths only)
2. Generate test knowledge graph from sample document corpus
3. Query Qdrant for entities (verify storage successful)
4. Monitor resource usage (CPU, memory, disk during initial operation)
5. Review logs for warnings or errors
6. Confirm auto-restart functionality (trigger controlled failure, verify systemd restarts)

**Operational Requirements**:

**Log Rotation Policies**:
- **Systemd Journal**: Managed by systemd-journald
  - Retention: 7 days or 500MB (whichever reached first)
  - Location: `/var/log/journal/` (persistent journal)
  - Configuration: `/etc/systemd/journald.conf` (SystemMaxUse=500M, MaxRetentionSec=7days)
- **File Logs** (optional, `/var/log/docling-mcp/`):
  - Rotation: Daily at midnight via logrotate
  - Retention: 7 daily logs, compress after 1 day
  - Configuration: `/etc/logrotate.d/docling-mcp`
  - Example logrotate config:
    ```
    /var/log/docling-mcp/*.log {
        daily
        rotate 7
        compress
        delaycompress
        missingok
        notifempty
        create 0640 docling-mcp docling-mcp
        sharedscripts
        postrotate
            systemctl reload docling-mcp.service > /dev/null 2>&1 || true
        endscript
    }
    ```

**Backup Requirements**:
- **Configuration Backup**:
  - Files: `/etc/docling-mcp/.env.production`, `/etc/systemd/system/docling-mcp.service`
  - Frequency: Before any configuration change (manual backup)
  - Location: `/opt/docling-mcp/backups/config/` (versioned by date)
  - Retention: Keep all configuration versions (config files are small)
- **State Data Backup** (Future - Phase 2):
  - Files: `/var/lib/docling-mcp/state/sessions.db` (when implemented)
  - Frequency: Manual daily backup procedure (documented in MAINTENANCE-PROCEDURES.md)
  - Location: Remote backup server or S3-compatible storage
  - Retention: 30 days (manual cleanup of old backups)
- **Knowledge Graph Backup**:
  - Responsibility: Qdrant service (hx-qdrant-server handles snapshots)
  - Docling MCP does NOT manage Qdrant backups (delegated to Qdrant operational procedures)
- **Document Cache** (NOT backed up - ephemeral):
  - `/var/lib/docling-mcp/cache/` is temporary storage only
  - Purged automatically when >48 hours old or disk >85% full
  - No backup required (source documents stored elsewhere by clients)

**Disaster Recovery Considerations**:

**Recovery Point Objective (RPO)**:
- **Configuration**: RPO = 0 (version controlled in git, can restore to any previous state)
- **Service Code**: RPO = 0 (version controlled in git)
- **Session State**: RPO = 24 hours (sessions expire after 24h, acceptable data loss)
- **Knowledge Graphs**: RPO = 24 hours (Qdrant backups managed separately by Qdrant service)
- **Document Cache**: RPO = N/A (ephemeral, not backed up)

**Recovery Time Objective (RTO)**:
- **Service Restart**: RTO = 5 minutes (systemd auto-restart + health check validation)
- **Full Node Recovery**: RTO = 30 minutes (restore from backup + redeploy service)
- **Dependency Failure Recovery**: RTO = immediate (graceful degradation, feature disablement)

**Disaster Recovery Scenarios**:

1. **Service Crash** (severity: low):
   - Detection: Systemd monitors process, health check fails
   - Recovery: Systemd auto-restart (3 attempts), service operational within 30 seconds
   - Validation: Health check endpoint returns healthy status
   - RTO: <1 minute

2. **Node Hardware Failure** (severity: high):
   - Detection: Node unreachable, health checks fail
   - Recovery: Deploy service to standby node (manual or automated failover in Phase 2)
   - Steps: Install service on new node, restore configuration from backup, validate dependencies, start service
   - RTO: 30 minutes (manual deployment), 5 minutes (automated failover - Phase 2)

3. **Configuration Corruption** (severity: medium):
   - Detection: Service fails to start, configuration validation errors in logs
   - Recovery: Restore configuration from latest backup (`/opt/docling-mcp/backups/config/`)
   - Steps: Stop service, restore .env.production, validate syntax, restart service
   - RTO: 10 minutes

4. **Dependency Failure** (LiteLLM, Qdrant, Redis down) (severity: medium):
   - Detection: Health check reports degraded status, MCP tool errors
   - Recovery: Service operates in degraded mode (graceful degradation), full recovery when dependencies restored
   - Steps: Troubleshoot dependency service, restore dependency, service auto-recovers
   - RTO: Depends on dependency recovery time (service remains partially operational)

5. **Disk Space Exhaustion** (severity: medium):
   - Detection: Disk utilization >90%, document cache write failures
   - Recovery: Automated cache cleanup (purge documents >48h old), manual cleanup if automated fails
   - Steps: Trigger cache cleanup script, verify disk space freed, service resumes normal operation
   - RTO: 5 minutes (automated cleanup), 15 minutes (manual cleanup)

**Maintenance Windows and Update Procedures**:

**Planned Maintenance Windows**:
- **Frequency**: Monthly (first Sunday of month, 02:00-04:00 UTC)
- **Duration**: 2 hours maximum (typical: 30 minutes)
- **Activities**:
  - Python dependency updates (security patches)
  - OS package updates (system libraries)
  - Configuration review and optimization
  - Log cleanup and archive
  - Performance baseline measurement
- **Notification**: 7 days advance notice to service consumers (AI agents, integration owners)

**Update Procedures** (Python Dependencies):

1. **Pre-Update Validation** (Non-Operational Environment):
   - Deploy updated dependencies to `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/`
   - Run full test suite (unit, integration, E2E)
   - Validate 100% test pass rate
   - Performance benchmark comparison (ensure no regression)
   - Security scan (pip-audit for vulnerabilities)

2. **Backup Current State**:
   - Backup current requirements.txt
   - Backup current .env.production
   - Backup current service code (git tag current version)

3. **Deployment to Operational** (During Maintenance Window):
   - Stop service (`systemctl stop docling-mcp.service`)
   - Update Python dependencies (`venv/bin/pip install -r requirements.txt --upgrade`)
   - Deploy updated service code (if applicable)
   - Start service (`systemctl start docling-mcp.service`)
   - Monitor startup logs for errors
   - Validate health check endpoint
   - Execute smoke tests (critical MCP tools)

4. **Post-Update Validation**:
   - Run deployment test suite (subset of full suite, 15 minutes)
   - Monitor service for 24 hours (check for errors, performance degradation)
   - Review logs for warnings or unexpected behavior
   - Rollback if critical issues detected (restore backup, restart service)

**Rollback Procedures**:
- **Trigger**: Critical bug, performance regression >20%, dependency incompatibility
- **Steps**:
  1. Stop service (`systemctl stop docling-mcp.service`)
  2. Restore previous requirements.txt
  3. Reinstall previous dependencies (`venv/bin/pip install -r requirements.txt.backup`)
  4. Restore previous service code (git checkout previous tag)
  5. Restart service (`systemctl start docling-mcp.service`)
  6. Validate service operational (health check + smoke tests)
- **RTO**: 15 minutes (rollback faster than troubleshooting)

**Monitoring Integration Points**:
- **Health Check Endpoint** (`/health`): Polled every 30 seconds by external monitoring
- **Systemd Status**: Monitored via systemctl (service active/failed state)
- **Log Monitoring**: Systemd journal logs forwarded to centralized logging (Phase 2)
- **Metrics Endpoint** (`/metrics` - Phase 2): Prometheus scrape endpoint for operational metrics
- **Dependency Health**: Health check endpoint reports dependency status (LiteLLM, Qdrant, Redis)

**Alerting Integration** (Phase 2):
- **Critical Alerts**:
  - Service down (systemd failed state): Immediate notification (PagerDuty, email)
  - All dependencies unavailable: Immediate notification
  - Disk space <10%: Immediate notification
- **Warning Alerts**:
  - Service degraded (1+ dependency unhealthy): Notification within 15 minutes
  - High error rate (>5% document failures over 10 min): Notification within 15 minutes
  - Performance degradation (p95 latency >2x baseline): Notification within 15 minutes

**Network Architecture**:
- **Bind Address**: `0.0.0.0:8000` (accessible within hx.dev.local)
- **Firewall**: DISABLED per HX-Infrastructure standard (network-level security via internal network isolation 192.168.10.0/24)
- **DNS**: hx-docling-mcp-server.hx.dev.local (registered in hx-dc-server)
- **No Reverse Proxy**: Direct access (no hx-ssl-server reverse proxy in Phase 1)

**Future Scaling** (Phase 2+):
- Horizontal scaling: Multiple Docling MCP instances behind load balancer (nginx or haproxy)
- Distributed processing: Separate worker pool for long-running document jobs (Celery + RabbitMQ)
- Caching layer: Redis cache for DoclingDocument results (reduce reprocessing, TTL-based expiration)

---

## MCP Tools Specification

### Tool Categories and Implementation Overview

This section provides detailed specifications for all 19 MCP tools organized into three functional categories. Each tool specification includes parameter schemas, implementation patterns, Docling integration details, error handling strategies, and performance characteristics.

**Conversion Tools** (3 tools):
1. `convert_document`: Convert multimodal document to DoclingDocument JSON format with full structure preservation
2. `convert_document_to_markdown`: Convert document to Markdown text with semantic structure intact
3. `batch_convert`: Parallel batch conversion of multiple documents with progress tracking

**Generation Tools** (11 tools):
4. `generate_knowledge_graph`: LightRAG-powered entity/relationship extraction with Qdrant storage
5. `extract_entities`: Named entity recognition via LLM with confidence scoring
6. `extract_relationships`: Relationship extraction with bidirectional handling
7. `create_docling_document`: Programmatic DoclingDocument creation from raw text/JSON
8. `parse_pdf_structure`: PDF-specific structure analysis (pages, sections, TOC, metadata)
9. `extract_tables`: Table detection and cell-level extraction with format conversion
10. `extract_images`: Image extraction with base64 encoding and metadata preservation
11. `detect_document_language`: Multi-language detection via langdetect with confidence scores
12. `classify_document_type`: LLM-based document classification (report, article, contract, invoice, etc.)
13. `extract_metadata`: Metadata extraction (author, title, creation date, keywords)
14. `generate_document_summary`: LLM-powered abstractive summarization with configurable length

**Manipulation Tools** (5 tools):
15. `merge_documents`: Document merging with structure reconciliation and metadata aggregation
16. `split_document`: Document splitting by page/section/size with structure preservation
17. `search_document`: Full-text search with ranking and highlighting
18. `annotate_document`: Annotation addition (highlights, comments, redactions) with persistence
19. `export_document`: Multi-format export (PDF, DOCX, HTML, Markdown) with quality preservation

### PART 1: Conversion Tools (3 tools)

#### Tool 1: convert_document

**Purpose**: Convert multimodal documents (14+ formats) to structured DoclingDocument JSON with semantic structure preservation, intelligent backend selection, and performance optimization.

**MCP Schema** (Enhanced with 7 input parameters):
```python
{
  "name": "convert_document",
  "description": "Convert a multimodal document (PDF, DOCX, PPTX, XLSX, HTML, image, etc.) to structured DoclingDocument JSON format with preserved semantic structure (headings, tables, lists, images).",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {
        "type": "string",
        "description": "Document source: file path (file://), URL (http/https), or base64-encoded data (data:)"
      },
      "format_hint": {
        "type": "string",
        "enum": ["pdf", "docx", "pptx", "xlsx", "html", "markdown", "image", "auto"],
        "default": "auto",
        "description": "Document format hint (auto-detect if not specified via MIME type + extension)"
      },
      "preserve_images": {
        "type": "boolean",
        "default": true,
        "description": "Whether to extract and preserve images in DoclingDocument with base64 encoding"
      },
      "ocr_enabled": {
        "type": "boolean",
        "default": true,
        "description": "Enable OCR for scanned PDFs and images (Tesseract via Docling)"
      },
      "ocr_language": {
        "type": "string",
        "default": "eng",
        "enum": ["eng", "spa", "fra", "deu", "chi_sim", "jpn", "kor"],
        "description": "OCR language hint (Tesseract language codes)"
      },
      "table_detection": {
        "type": "boolean",
        "default": true,
        "description": "Enable table structure detection and cell-level extraction"
      },
      "cache_result": {
        "type": "boolean",
        "default": true,
        "description": "Cache DoclingDocument result in Redis (24h TTL) for reuse"
      }
    },
    "required": ["document_source"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "docling_document": {
        "type": "object",
        "description": "DoclingDocument JSON with hierarchical doc_items tree (structure + content)"
      },
      "metadata": {
        "type": "object",
        "properties": {
          "format": {"type": "string", "description": "Detected document format"},
          "page_count": {"type": "integer"},
          "backend_used": {"type": "string", "description": "Docling backend (pypdfium2, mammoth, pandoc, etc.)"},
          "processing_time_ms": {"type": "integer"},
          "cache_hit": {"type": "boolean", "description": "Whether result was served from cache"}
        }
      }
    }
  }
}
```

**Docling Integration Details**:

**1. Format Detection Algorithm**:
```python
def detect_format(document_source: str, format_hint: str) -> DocumentFormat:
    """
    Priority: format_hint > MIME type > file extension
    """
    if format_hint != "auto":
        return format_hint  # Trust user-provided hint

    # Step 1: MIME type detection (for URLs and base64 data URIs)
    if document_source.startswith("http"):
        response = requests.head(document_source)
        mime_type = response.headers.get("Content-Type")
        if mime_type:
            format_map = {
                "application/pdf": "pdf",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
                "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
                "text/html": "html",
                "text/markdown": "markdown",
                "image/png": "image",
                "image/jpeg": "image",
                "image/tiff": "image"
            }
            if mime_type in format_map:
                return format_map[mime_type]

    # Step 2: File extension detection (for file:// paths)
    if document_source.startswith("file://"):
        ext = Path(document_source[7:]).suffix.lower()
        ext_map = {
            ".pdf": "pdf", ".docx": "docx", ".pptx": "pptx", ".xlsx": "xlsx",
            ".html": "html", ".htm": "html", ".md": "markdown", ".markdown": "markdown",
            ".png": "image", ".jpg": "image", ".jpeg": "image", ".tiff": "image", ".tif": "image"
        }
        if ext in ext_map:
            return ext_map[ext]

    # Step 3: Magic number detection (fallback)
    data_bytes = fetch_document_bytes(document_source, max_bytes=1024)
    magic_numbers = {
        b"%PDF": "pdf",
        b"PK\x03\x04": "docx",  # Also pptx, xlsx (all are ZIP archives, need deeper inspection)
        b"<html": "html",
        b"<!DOCTYPE html": "html",
        b"\x89PNG": "image"
    }
    for magic, fmt in magic_numbers.items():
        if data_bytes.startswith(magic):
            return fmt

    raise ValueError(f"Unable to detect document format for: {document_source[:100]}")
```

**2. Backend Selection Logic**:
```python
def select_docling_backend(document_format: str, ocr_enabled: bool) -> str:
    """
    Map document format to optimal Docling backend
    """
    backend_map = {
        # Native backends (fast, high-fidelity)
        "pdf": "pypdfium2" if not ocr_enabled else "tesseract",  # pypdfium2 for digital PDFs, Tesseract for scanned
        "docx": "mammoth",  # Best for DOCX structure preservation
        "pptx": "python-pptx",  # Native PowerPoint library
        "xlsx": "openpyxl",  # Excel spreadsheet library
        "html": "bs4",  # BeautifulSoup4 HTML parser
        "markdown": "mistune",  # Markdown parser

        # Image formats (require OCR)
        "image": "tesseract",  # Always OCR for images

        # Fallback backend (universal but slower)
        "unknown": "pandoc"  # Pandoc supports 40+ formats but slower conversion
    }

    backend = backend_map.get(document_format, "pandoc")
    logger.info(f"Selected backend: {backend} for format: {document_format}")
    return backend
```

**3. Structure Preservation Techniques**:

Docling preserves 6 semantic structure types in `doc_items` hierarchical tree:

| Structure Type | Preservation Method | DoclingDocument Representation |
|----------------|---------------------|-------------------------------|
| **Headings** | Heading level detection (H1-H6) | `{"type": "heading", "level": 1-6, "text": "..."}` |
| **Lists** | Ordered/unordered list parsing | `{"type": "list", "ordered": true/false, "items": [...]}` |
| **Tables** | Cell-level extraction with row/col indices | `{"type": "table", "rows": [...], "cells": [{"row": 0, "col": 0, "text": "..."}]}` |
| **Images** | Base64 encoding with captions | `{"type": "image", "data": "base64...", "caption": "...", "dimensions": {...}}` |
| **Paragraphs** | Text block detection with font/style metadata | `{"type": "paragraph", "text": "...", "font_size": 12, "bold": false}` |
| **Code Blocks** | Syntax highlighting and language detection | `{"type": "code", "language": "python", "text": "..."}` |

**4. Performance Optimization**:
- **Redis Caching**: Cache key = `docling:v1:MD5(document_source + params)`, TTL = 24h
  - Cache hit → <500ms latency (skip Docling processing)
  - Cache miss → Full conversion (PDF 5-60s depending on page count)
- **Parallel Page Processing**: Multi-page PDFs processed in parallel (max 4 workers)
- **Streaming Mode**: Large documents (>100MB) streamed to avoid memory bloat

**5. Error Handling Patterns**:

| Error Type | MCP Error Code | Error Message | Recovery Strategy |
|------------|----------------|---------------|-------------------|
| `FileNotFoundError` | `-32002` | "Document not found: {path}" | Return error with suggestion to check path |
| `UnsupportedFormatError` | `-1` | "Format {format} not supported. Supported: {formats}" | Return supported format list |
| `OCRFailureError` | `-2` | "OCR failed: {details}. Try non-OCR backend." | Fallback to text-based extraction |
| `TableDetectionError` | `-32603` | "Table detection failed: {details}" | Return document without table structure + warning |
| `DocumentTooLargeError` | `-1` | "Document size {size}MB exceeds limit 500MB" | Return error with size limit |
| `DownloadTimeoutError` | `-2` | "URL download timeout (60s): {url}" | Retry with exponential backoff (3 attempts) |

**6. Implementation Workflow** (5 steps):
```
1. Validate input → 2. Detect format → 3. Select backend → 4. Convert to DoclingDocument → 5. Cache result + return
```

**7. Performance Characteristics**:
- **Small PDF (1-5 pages)**: <5s conversion time
- **Medium PDF (10-50 pages)**: <30s conversion time
- **Large PDF (100+ pages)**: <120s conversion time (with parallel processing)
- **DOCX/PPTX/XLSX**: <10s (native backends are fast)
- **Image OCR**: 2-10s per image (depends on resolution)

**8. Testing Validation**:
- TC-MM-001 to TC-MM-014: Format-specific multimodal conversion tests (≥95% success rate)
- TC-UNIT-001: Format detection algorithm (100% accuracy on test corpus)
- TC-E2E-001: End-to-end conversion with caching (cache hit rate >40%)

---

#### Tool 2: convert_document_to_markdown

**Purpose**: Convert documents to Markdown text optimized for LLM consumption with semantic structure preservation and configurable formatting.

**MCP Schema** (Enhanced with 7 input parameters):
```python
{
  "name": "convert_document_to_markdown",
  "description": "Convert document to Markdown text format with semantic structure intact. Optimized for LLM consumption and downstream processing.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {
        "type": "string",
        "description": "Document source (file path, URL, or DoclingDocument ID from cache)"
      },
      "format_hint": {
        "type": "string",
        "enum": ["pdf", "docx", "pptx", "xlsx", "html", "markdown", "image", "auto"],
        "default": "auto"
      },
      "preserve_images": {
        "type": "boolean",
        "default": false,
        "description": "Include images as base64 data URIs (increases output size)"
      },
      "ocr_enabled": {"type": "boolean", "default": true},
      "ocr_language": {"type": "string", "default": "eng"},
      "table_format": {
        "type": "string",
        "enum": ["markdown", "html", "plain"],
        "default": "markdown",
        "description": "Table rendering format (markdown=pipe tables, html=HTML tables, plain=text-only)"
      },
      "max_line_length": {
        "type": "integer",
        "default": 120,
        "minimum": 80,
        "maximum": 200,
        "description": "Max line length for text wrapping (0=no wrapping)"
      }
    },
    "required": ["document_source"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "markdown_text": {
        "type": "string",
        "description": "Markdown-formatted document text"
      },
      "metadata": {
        "type": "object",
        "properties": {
          "format": {"type": "string"},
          "character_count": {"type": "integer"},
          "word_count": {"type": "integer"},
          "processing_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Markdown Conversion Rules** (7 subsections):

**1. Headings**: DoclingDocument heading levels → Markdown ATX headings
```
DoclingDocument: {"type": "heading", "level": 1, "text": "Introduction"}
Markdown: # Introduction
```

**2. Lists**: Preserve ordered/unordered list structure with proper indentation
```
DoclingDocument: {"type": "list", "ordered": false, "items": ["Item 1", {"type": "list", "items": ["Nested"]}]}
Markdown:
- Item 1
  - Nested
```

**3. Tables**: Render as Markdown pipe tables (or HTML if complex)
```
DoclingDocument: {"type": "table", "rows": 3, "cols": 2, "cells": [...]}
Markdown:
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
```

**4. Links**: Convert DoclingDocument hyperlinks to Markdown link syntax
```
DoclingDocument: {"type": "link", "url": "https://example.com", "text": "Example"}
Markdown: [Example](https://example.com)
```

**5. Images**: Embed as Markdown images (with optional base64 data URIs)
```
DoclingDocument: {"type": "image", "data": "base64...", "caption": "Figure 1"}
Markdown: ![Figure 1](data:image/png;base64,...)
```

**6. Code Blocks**: Preserve language hints and syntax highlighting
```
DoclingDocument: {"type": "code", "language": "python", "text": "print('hello')"}
Markdown:
```python
print('hello')
```
```

**7. Inline Formatting**: Bold, italic, code spans
```
DoclingDocument: {"type": "paragraph", "text": "This is **bold** and *italic*"}
Markdown: This is **bold** and *italic*
```

**Implementation Strategy** (5-step workflow):
```python
def convert_to_markdown(docling_document: DoclingDocument, table_format: str, max_line_length: int) -> str:
    """
    Step 1: Convert DoclingDocument to Markdown AST
    Step 2: Traverse doc_items tree recursively
    Step 3: Render each node type (heading, list, table, etc.) to Markdown syntax
    Step 4: Apply text wrapping if max_line_length > 0
    Step 5: Return Markdown string
    """
    markdown_ast = []

    for item in docling_document.doc_items:
        if item.type == "heading":
            markdown_ast.append(f"{'#' * item.level} {item.text}\n\n")
        elif item.type == "paragraph":
            wrapped_text = textwrap.fill(item.text, width=max_line_length) if max_line_length > 0 else item.text
            markdown_ast.append(f"{wrapped_text}\n\n")
        elif item.type == "list":
            markdown_ast.append(render_list(item))
        elif item.type == "table":
            if table_format == "markdown":
                markdown_ast.append(render_markdown_table(item))
            elif table_format == "html":
                markdown_ast.append(render_html_table(item))
            else:
                markdown_ast.append(render_plain_table(item))
        elif item.type == "code":
            markdown_ast.append(f"```{item.language}\n{item.text}\n```\n\n")
        elif item.type == "image" and preserve_images:
            markdown_ast.append(f"![{item.caption}](data:image/png;base64,{item.data})\n\n")

    return "".join(markdown_ast)
```

**Error Handling**: Delegates to `convert_document` tool (same error handling patterns)

**Performance**: Faster than full DoclingDocument conversion (Markdown rendering is lightweight, ~1-2s post-conversion)

**Use Cases**:
- LLM context preparation (Markdown is LLM-friendly)
- Knowledge base ingestion (many RAG systems prefer Markdown)
- Documentation generation
- Content migration (CMS systems often support Markdown import)

**Testing Validation**: TC-UNIT-003 (Markdown rendering from DoclingDocument)

---

#### Tool 3: batch_convert

**Purpose**: Parallel batch conversion of multiple documents with concurrency control, progress tracking, and comprehensive error handling.

**MCP Schema** (Enhanced with 9 input parameters):
```python
{
  "name": "batch_convert",
  "description": "Convert multiple documents in parallel with progress tracking and comprehensive error handling. Supports fail-fast and fail-tolerant modes.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_sources": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of document sources (file paths, URLs, or base64 data)"
      },
      "format_hint": {"type": "string", "default": "auto"},
      "preserve_images": {"type": "boolean", "default": true},
      "ocr_enabled": {"type": "boolean", "default": true},
      "ocr_language": {"type": "string", "default": "eng"},
      "table_detection": {"type": "boolean", "default": true},
      "cache_result": {"type": "boolean", "default": true},
      "max_concurrent": {
        "type": "integer",
        "default": 4,
        "minimum": 1,
        "maximum": 10,
        "description": "Max concurrent conversions (limit to avoid resource exhaustion)"
      },
      "fail_fast": {
        "type": "boolean",
        "default": false,
        "description": "Stop on first error (true) or continue with remaining documents (false)"
      },
      "progress_callback": {
        "type": "boolean",
        "default": true,
        "description": "Emit SSE progress events during batch processing"
      }
    },
    "required": ["document_sources"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "results": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "document_source": {"type": "string"},
            "status": {"type": "string", "enum": ["success", "error"]},
            "docling_document": {"type": "object", "description": "Present if status=success"},
            "error": {"type": "string", "description": "Present if status=error"},
            "processing_time_ms": {"type": "integer"}
          }
        }
      },
      "summary": {
        "type": "object",
        "properties": {
          "total_count": {"type": "integer"},
          "success_count": {"type": "integer"},
          "error_count": {"type": "integer"},
          "total_processing_time_ms": {"type": "integer"},
          "average_time_per_document_ms": {"type": "integer"},
          "cache_hit_count": {"type": "integer"}
        }
      }
    }
  }
}
```

**Implementation Subsections**:

**1. Concurrency Control** (asyncio semaphore pattern):
```python
import asyncio
from typing import List

async def batch_convert(document_sources: List[str], max_concurrent: int) -> List[ConversionResult]:
    """
    Use asyncio.Semaphore to limit concurrent conversions
    """
    semaphore = asyncio.Semaphore(max_concurrent)

    async def convert_with_semaphore(source: str) -> ConversionResult:
        async with semaphore:  # Acquire semaphore (blocks if max_concurrent reached)
            try:
                result = await convert_document_async(source)
                return ConversionResult(status="success", docling_document=result)
            except Exception as e:
                return ConversionResult(status="error", error=str(e))

    # Start all conversions concurrently (semaphore controls parallelism)
    tasks = [convert_with_semaphore(source) for source in document_sources]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    return results
```

**2. Progress Tracking** (Server-Sent Events):
```python
async def batch_convert_with_progress(document_sources: List[str], progress_callback: bool) -> List[ConversionResult]:
    """
    Emit SSE progress events during batch processing
    """
    total_count = len(document_sources)
    completed_count = 0

    async def convert_and_notify(source: str) -> ConversionResult:
        nonlocal completed_count
        result = await convert_document_async(source)

        completed_count += 1
        if progress_callback:
            # Emit SSE event
            progress_percentage = (completed_count / total_count) * 100
            await emit_sse_event({
                "type": "progress",
                "tool": "batch_convert",
                "percentage": progress_percentage,
                "completed": completed_count,
                "total": total_count,
                "current_document": source
            })

        return result

    results = await asyncio.gather(*[convert_and_notify(src) for src in document_sources])
    return results
```

**3. Error Handling Strategy** (fail-fast vs fail-tolerant):
```python
async def batch_convert_with_error_handling(
    document_sources: List[str],
    fail_fast: bool
) -> List[ConversionResult]:
    """
    fail_fast=True: Stop on first error (raise exception)
    fail_fast=False: Continue with remaining documents, collect all errors
    """
    results = []

    for source in document_sources:
        try:
            result = await convert_document_async(source)
            results.append(ConversionResult(status="success", docling_document=result))
        except Exception as e:
            if fail_fast:
                # Fail-fast mode: raise exception immediately
                raise BatchConversionError(f"Batch conversion failed on {source}: {e}") from e
            else:
                # Fail-tolerant mode: log error, continue with next document
                logger.warning(f"Conversion failed for {source}: {e}")
                results.append(ConversionResult(status="error", error=str(e), document_source=source))

    return results
```

**4. Performance Optimization** (~70% time reduction vs sequential):
- **Parallelism**: 4 concurrent conversions reduce total time by ~70% (10 docs: 300s sequential → 90s parallel)
- **Caching**: Redis cache shared across batch (subsequent identical documents return <500ms)
- **Chunking**: Large batches (>100 docs) processed in chunks of 50 to avoid memory bloat

**5. Error Scenarios**:

| Error Type | MCP Code | Message | Recovery |
|------------|----------|---------|----------|
| `TimeoutError` | `-2` | "Batch conversion timeout (600s total)" | Return partial results + error summary |
| `ResourceExhaustedError` | `-2` | "System resources exhausted (memory/CPU)" | Reduce max_concurrent, retry |
| `PartialFailureError` | `-32603` | "{error_count}/{total_count} conversions failed" | Return mixed success/error results |

**6. Use Cases**:
- Bulk document ingestion (digital libraries, knowledge bases)
- Multi-file upload processing (web applications)
- Corpus preparation (ML training datasets)
- Migration workflows (legacy document conversion)

**7. Performance Characteristics**:
- **Small batch (10 docs, avg 5 pages each)**: <90s total (vs 300s sequential, 70% faster)
- **Medium batch (50 docs)**: <300s total (with chunking)
- **Large batch (100+ docs)**: Chunked processing (50 docs per chunk, ~10 min total)

**8. Testing Validation**:
- TC-E2E-003: Batch conversion with mixed success/failure (fail_fast=false)
- TC-PERF-001: Parallel speedup validation (≥60% time reduction vs sequential)
- SC-002: Batch conversion success rate (≥95% with fail-tolerant mode)

---

### PART 2: Generation Tools (11 tools)

#### Tool 4: generate_knowledge_graph

**Purpose**: LightRAG-powered entity and relationship extraction from single or multiple documents with automatic deduplication and Qdrant vector storage for intelligent graph-based retrieval.

**MCP Schema** (Enhanced with LightRAG parameters):
```python
{
  "name": "generate_knowledge_graph",
  "description": "Extract entities/relationships via LightRAG, build knowledge graph in Qdrant with dual-collection architecture. Uses LLM-based entity extraction (gemma3:27b via LiteLLM) and bge-m3 embeddings (Ollama3).",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_sources": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of document sources (file paths, URLs, or DoclingDocument IDs from cache)"
      },
      "entity_types": {
        "type": "array",
        "items": {"type": "string"},
        "default": ["person", "organization", "location", "concept", "product", "date", "event"],
        "description": "Entity taxonomy for extraction (extensible: add custom types like 'technology', 'method')"
      },
      "relationship_types": {
        "type": "array",
        "items": {"type": "string"},
        "default": ["works_for", "located_in", "mentions", "cites", "part_of", "authored_by"],
        "description": "Relationship taxonomy (extensible: add domain-specific types)"
      },
      "llm_model": {
        "type": "string",
        "default": "gemma3:27b",
        "enum": ["gemma3:27b", "gpt-oss:20b", "qwen3-coder:30b", "mistral:7b"],
        "description": "LLM model for entity/relationship extraction via LiteLLM (Ollama1/2 routing)"
      },
      "llm_temperature": {
        "type": "number",
        "default": 0.1,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "LLM temperature for deterministic extraction (0.0 = deterministic, 0.1 recommended for consistency)"
      },
      "embedding_model": {
        "type": "string",
        "default": "bge-m3:567m",
        "description": "Embedding model for entity/relationship vectors (Ollama3: bge-m3 1024D)"
      },
      "deduplicate_entities": {
        "type": "boolean",
        "default": true,
        "description": "Semantic deduplication via Qdrant similarity search (0.85 threshold)"
      },
      "deduplication_threshold": {
        "type": "number",
        "default": 0.85,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Cosine similarity threshold for entity deduplication (0.85 = high confidence duplicates)"
      },
      "max_chunk_size": {
        "type": "integer",
        "default": 4000,
        "description": "Max tokens per document chunk for LLM processing (LightRAG chunking strategy)"
      },
      "confidence_threshold": {
        "type": "number",
        "default": 0.5,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Minimum extraction confidence to include entity/relationship (0.5 = medium confidence)"
      }
    },
    "required": ["document_sources"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "graph_summary": {
        "type": "object",
        "properties": {
          "entity_count": {"type": "integer", "description": "Total entities extracted"},
          "relationship_count": {"type": "integer", "description": "Total relationships extracted"},
          "entity_types": {
            "type": "object",
            "additionalProperties": {"type": "integer"},
            "description": "Entity count by type: {'person': 45, 'organization': 23, ...}"
          },
          "relationship_types": {
            "type": "object",
            "additionalProperties": {"type": "integer"},
            "description": "Relationship count by type: {'works_for': 12, 'cites': 34, ...}"
          },
          "graph_density": {
            "type": "number",
            "description": "Relationships per entity (avg degree), target ≥2.0 for connected graph"
          },
          "entity_coverage": {
            "type": "number",
            "description": "% of document words with entity mentions (quality metric)"
          }
        }
      },
      "qdrant_collection_ids": {
        "type": "object",
        "properties": {
          "entities_collection": {"type": "string", "default": "hx_docling_mcp_entities"},
          "relationships_collection": {"type": "string", "default": "hx_docling_mcp_relationships"}
        }
      },
      "processing_metadata": {
        "type": "object",
        "properties": {
          "documents_processed": {"type": "integer"},
          "total_processing_time_ms": {"type": "integer"},
          "llm_api_calls": {"type": "integer"},
          "entities_deduplicated": {"type": "integer", "description": "Entities merged via deduplication"},
          "cache_hit_rate": {"type": "number", "description": "% of LLM responses cached"}
        }
      }
    }
  }
}
```

**LightRAG Integration Workflow**:

**1. Document Chunking Strategy**:
```python
import httpx

# Call hx-literag-server HTTP API for chunking
response = httpx.post(
    f"{LIGHTRAG_API_URL}/chunk",
    json={
        "documents": [doc.to_dict() for doc in docling_documents],
        "max_chunk_size": 4000,
        "overlap": 200,  # 200-token overlap for context continuity
        "strategy": "semantic"  # Semantic boundary detection (sentences, paragraphs)
    },
    timeout=30.0
)
chunks = response.json()["chunks"]
```

**2. Entity Extraction Pipeline**:
```python
# Step 1: Extract entities from each chunk via LLM
for chunk in chunks:
    extraction_prompt = f"""
    Extract entities from the following text. Return JSON array with format:
    [
        {{
            "name": "entity name",
            "type": "person|organization|location|concept|product|date|event",
            "confidence": 0.0-1.0,
            "context": "surrounding text snippet"
        }}
    ]

    Text: {chunk.text}
    """

    # LLM call via LiteLLM (routes to gemma3:27b on Ollama1)
    response = await litellm.acompletion(
        model="gemma3:27b",
        messages=[{"role": "user", "content": extraction_prompt}],
        temperature=0.1,  # Deterministic extraction
        max_tokens=2048,
        timeout=60
    )

    # Parse LLM response (JSON array of entities)
    entities_chunk = json.loads(response.choices[0].message.content)

    # Step 2: Generate embeddings for each entity (bge-m3 via Ollama3)
    for entity in entities_chunk:
        embedding_text = f"{entity['name']} {entity.get('context', '')}"
        entity['embedding'] = await ollama3.embeddings(
            model="bge-m3:567m",
            prompt=embedding_text
        )

    # Step 3: Deduplicate entities via Qdrant semantic similarity
    if deduplicate_entities:
        for entity in entities_chunk:
            # Search Qdrant for similar entities (cosine similarity)
            duplicates = qdrant.search(
                collection_name="hx_docling_mcp_entities",
                query_vector=entity['embedding'],
                query_filter={"entity_type": entity['type']},
                limit=5,
                score_threshold=deduplication_threshold  # 0.85 default
            )

            if duplicates and duplicates[0].score > deduplication_threshold:
                # Merge with existing entity (increment mention_count, aggregate aliases)
                existing_entity_id = duplicates[0].id
                qdrant.update_payload(
                    collection_name="hx_docling_mcp_entities",
                    point_id=existing_entity_id,
                    payload={
                        "mention_count": existing_entity.mention_count + 1,
                        "aliases": list(set(existing_entity.aliases + [entity['name']])),
                        "document_ids": list(set(existing_entity.document_ids + [chunk.document_id]))
                    }
                )
            else:
                # Insert new entity into Qdrant
                qdrant.upsert(
                    collection_name="hx_docling_mcp_entities",
                    points=[{
                        "id": generate_uuid(),
                        "vector": entity['embedding'],
                        "payload": {
                            "entity_id": generate_uuid(),
                            "entity_name": entity['name'],
                            "entity_type": entity['type'],
                            "aliases": [entity['name']],
                            "confidence": entity['confidence'],
                            "extraction_model": "gemma3:27b",
                            "document_id": chunk.document_id,
                            "text_span": {"start": chunk.start_char, "end": chunk.end_char},
                            "context_snippet": entity['context'],
                            "mention_count": 1,
                            "extraction_timestamp": datetime.utcnow().isoformat()
                        }
                    }]
                )
```

**3. Relationship Extraction Pipeline**:
```python
# Step 1: Extract relationships from each chunk via LLM
for chunk in chunks:
    # Get entities mentioned in this chunk (for relationship validation)
    chunk_entities = [e for e in all_entities if e['text_span'] overlaps chunk.span]

    relationship_prompt = f"""
    Extract relationships between entities. Return JSON array:
    [
        {{
            "subject": "entity name",
            "predicate": "relationship type (works_for|located_in|mentions|cites|part_of|authored_by)",
            "object": "entity name",
            "confidence": 0.0-1.0,
            "evidence": "sentence containing relationship"
        }}
    ]

    Entities: {[e['name'] for e in chunk_entities]}
    Text: {chunk.text}
    """

    response = await litellm.acompletion(
        model="gemma3:27b",
        messages=[{"role": "user", "content": relationship_prompt}],
        temperature=0.1,
        max_tokens=2048,
        timeout=60
    )

    relationships_chunk = json.loads(response.choices[0].message.content)

    # Step 2: Validate relationships (subject and object must exist in entities)
    for rel in relationships_chunk:
        subject_entity = find_entity_by_name(rel['subject'], chunk_entities)
        object_entity = find_entity_by_name(rel['object'], chunk_entities)

        if not subject_entity or not object_entity:
            continue  # Skip orphan relationships (no matching entities)

        # Step 3: Generate relationship embedding (subject PREDICATE object text)
        relationship_text = f"{rel['subject']} {rel['predicate']} {rel['object']} {rel['evidence']}"
        rel_embedding = await ollama3.embeddings(model="bge-m3:567m", prompt=relationship_text)

        # Step 4: Insert relationship into Qdrant
        qdrant.upsert(
            collection_name="hx_docling_mcp_relationships",
            points=[{
                "id": generate_uuid(),
                "vector": rel_embedding,
                "payload": {
                    "relationship_id": generate_uuid(),
                    "subject_entity_id": subject_entity.entity_id,
                    "subject_entity_name": rel['subject'],
                    "predicate": rel['predicate'],
                    "object_entity_id": object_entity.entity_id,
                    "object_entity_name": rel['object'],
                    "confidence": rel['confidence'],
                    "bidirectional": is_symmetric_relationship(rel['predicate']),  # e.g., "collaborates_with"
                    "document_id": chunk.document_id,
                    "text_evidence": rel['evidence'],
                    "extraction_model": "gemma3:27b",
                    "extraction_timestamp": datetime.utcnow().isoformat()
                }
            }]
        )

        # Step 5: If bidirectional, insert reverse relationship
        if is_symmetric_relationship(rel['predicate']):
            qdrant.upsert(
                collection_name="hx_docling_mcp_relationships",
                points=[{...}]  # Same as above but subject/object swapped
            )
```

**4. Graph Validation and Quality Metrics**:
```python
# After extraction completes, calculate graph statistics
graph_stats = {
    "entity_count": qdrant.count(collection_name="hx_docling_mcp_entities", filter={"document_id": doc_ids}),
    "relationship_count": qdrant.count(collection_name="hx_docling_mcp_relationships", filter={"document_id": doc_ids}),
    "graph_density": relationship_count / entity_count if entity_count > 0 else 0,  # Target ≥2.0
    "entity_coverage": (unique_entities_with_mentions / total_words) * 100  # Target ≥10%
}

# Validate graph integrity
orphaned_relationships = validate_all_relationship_entities_exist()  # Should be 0
duplicate_entities = find_entities_above_similarity_threshold(0.95)  # Should be minimal
```

**5. Error Handling**:

| Error Type | MCP Code | Message | Recovery |
|------------|----------|---------|----------|
| LiteLLMTimeoutError | `-2` | "LLM API timeout (60s) during entity extraction" | Retry with exponential backoff (3 attempts) |
| LLMResponseParseError | `-2` | "Failed to parse LLM JSON response: {error}" | Log malformed response, continue with next chunk |
| QdrantWriteError | `-2` | "Qdrant upsert failed: {details}" | Retry upsert, failover to local storage if Qdrant down |
| EntityDeduplicationError | `-32603` | "Deduplication failed: {error}" | Disable deduplication, insert all entities |
| InsufficientTextError | `-1` | "Document too short (<100 words), insufficient for knowledge graph" | Return empty graph with warning |

**6. Performance Optimization**:
- **LLM Response Caching**: Cache entity extraction results in Redis (key: SHA256(chunk_text + extraction_prompt + model), TTL: 24h)
  - Cache hit rate target: >40% for repeated document processing
- **Batch Embedding Generation**: Generate embeddings in batches of 32 entities/relationships (reduce Ollama3 API calls)
- **Parallel Chunk Processing**: Process chunks in parallel (max 4 concurrent LLM calls to avoid rate limiting)
- **Qdrant Batch Upsert**: Batch insert 100 entities + 200 relationships per upsert (reduce network overhead)

**7. Performance Characteristics**:
- **Single document (5000 words)**: <60s total (chunking 5s + LLM extraction 40s + Qdrant storage 15s)
- **Batch of 10 documents**: <30 minutes total (parallel processing + caching)
- **Entity extraction rate**: 100+ entities per 10K words (LightRAG baseline)
- **Relationship extraction rate**: 200+ relationships per 10K words (well-connected graph)

**8. Testing Validation**:
- TC-INT-002: Knowledge graph E2E (50+ entities, 100+ relationships from 5K word document)
- TC-E2E-002: Multi-document deduplication (entity count < sum of individual docs)
- SC-004: Knowledge graph generation success (500+ entities, 1000+ relationships from 10-doc corpus)
- SC-008: Entity extraction quality (100+ entities per 10K words, 90%+ precision on manual review)

---

#### Tool 5: extract_entities

**Purpose**: Named Entity Recognition (NER) from DoclingDocument without relationship extraction. Optimized for quick entity tagging and filtering workflows.

**MCP Schema**:
```python
{
  "name": "extract_entities",
  "description": "Extract named entities only (no relationships) via LLM-based NER. Returns entity list with confidence scores and deduplication.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {
        "type": "string",
        "description": "Document source (file path, URL) or DoclingDocument ID from cache"
      },
      "entity_types": {
        "type": "array",
        "items": {"type": "string"},
        "default": ["person", "organization", "location", "concept", "product", "date", "event"],
        "description": "Entity taxonomy filter (extract only specified types)"
      },
      "llm_model": {
        "type": "string",
        "default": "gemma3:27b",
        "description": "LLM model for NER via LiteLLM"
      },
      "confidence_threshold": {
        "type": "number",
        "default": 0.5,
        "minimum": 0.0,
        "maximum": 1.0,
        "description": "Minimum extraction confidence (0.5 = medium, 0.7 = high)"
      },
      "deduplicate": {
        "type": "boolean",
        "default": true,
        "description": "Merge duplicate entity mentions (same name, case-insensitive)"
      },
      "include_context": {
        "type": "boolean",
        "default": true,
        "description": "Include surrounding text context (50 chars before/after mention)"
      }
    },
    "required": ["document_source"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "entities": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "entity_id": {"type": "string", "description": "UUID"},
            "entity_name": {"type": "string"},
            "entity_type": {"type": "string"},
            "confidence": {"type": "number"},
            "mentions": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "text_span": {"type": "object", "properties": {"start": {"type": "integer"}, "end": {"type": "integer"}}},
                  "context_snippet": {"type": "string", "description": "Surrounding text (if include_context=true)"}
                }
              },
              "description": "All mentions of this entity in document (deduplicated)"
            },
            "mention_count": {"type": "integer"},
            "attributes": {"type": "object", "description": "Type-specific attributes (e.g., title for person, location for organization)"}
          }
        }
      },
      "summary": {
        "type": "object",
        "properties": {
          "total_entities": {"type": "integer"},
          "entity_types": {"type": "object", "additionalProperties": {"type": "integer"}},
          "average_confidence": {"type": "number"},
          "processing_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Implementation Workflow**:
1. Convert document to DoclingDocument (if not already cached)
2. Chunk text into 4000-token segments
3. Extract entities from each chunk via LLM (same prompt as `generate_knowledge_graph` but no relationships)
4. Deduplicate entities (case-insensitive name matching + confidence-based merging)
5. Filter by confidence_threshold (discard entities below threshold)
6. Return entity list with mention aggregation

**Deduplication Logic**:
```python
def deduplicate_entities(entities, case_sensitive=False):
    entity_map = {}

    for entity in entities:
        key = entity['name'] if case_sensitive else entity['name'].lower()

        if key in entity_map:
            # Merge with existing entity
            existing = entity_map[key]
            existing['mentions'].extend(entity['mentions'])
            existing['mention_count'] += entity['mention_count']
            existing['confidence'] = max(existing['confidence'], entity['confidence'])  # Keep highest confidence
        else:
            entity_map[key] = entity

    return list(entity_map.values())
```

**Performance**: Faster than `generate_knowledge_graph` (no relationship extraction, ~40% time reduction)

**Testing Validation**: TC-UNIT-004 (Entity extraction from LLM response)

---

#### Tools 6-14: Generation Tools (Remaining)

**NOTE**: The following tools provide brief specifications due to document length constraints. Full implementation details follow the same comprehensive pattern as Tools 1-5 above.

**Tool 6: extract_relationships**
- **Purpose**: Extract relationships between known entities (requires entity list as input)
- **Parameters**: `entities` (array), `relationship_types` (array), `llm_model`, `bidirectional_handling` (bool)
- **Output**: Relationship list with subject/predicate/object triples
- **Implementation**: Similar to `generate_knowledge_graph` relationship extraction but operates on pre-extracted entities

**Tool 7: create_docling_document**
- **Purpose**: Programmatically create DoclingDocument from raw text/JSON (no file conversion needed)
- **Parameters**: `text_content` (str), `metadata` (object), `structure_hints` (headings, lists, etc.)
- **Output**: DoclingDocument JSON
- **Use case**: Synthetic document creation for testing, API-generated content

**Tool 8: parse_pdf_structure**
- **Purpose**: PDF-specific metadata extraction (page count, TOC, sections, bookmarks)
- **Parameters**: `pdf_source`, `extract_toc` (bool), `analyze_sections` (bool)
- **Output**: PDF structure metadata (pages, TOC tree, section boundaries)
- **Implementation**: Uses PyPDFium2 for structure analysis without full text extraction

**Tool 9: extract_tables**
- **Purpose**: Table detection and extraction with cell-level structure
- **Parameters**: `document_source`, `table_index` (int or "all"), `format` ("json"|"csv"|"markdown")
- **Output**: Array of table structures with rows/columns/cells
- **Docling Integration**: Uses table detection backend (varies by format: PDF → pypdfium2, DOCX → mammoth)

**Tool 10: extract_images**
- **Purpose**: Extract images with captions and metadata
- **Parameters**: `document_source`, `image_index` (int or "all"), `encoding` ("base64"|"file_path")
- **Output**: Array of images with data, captions, dimensions
- **Implementation**: Docling backend extracts images → base64 encode or save to cache directory

**Tool 11: detect_document_language**
- **Purpose**: Multi-language detection via langdetect library
- **Parameters**: `document_source`, `detect_all_languages` (bool for multi-language docs)
- **Output**: Primary language + confidence, optional secondary languages
- **Implementation**: Uses langdetect on extracted text (after DoclingDocument conversion)

**Tool 12: classify_document_type**
- **Purpose**: LLM-based document classification (report, article, contract, invoice, etc.)
- **Parameters**: `document_source`, `classification_taxonomy` (array of types), `llm_model`
- **Output**: Document type + confidence + reasoning
- **Implementation**: LLM prompt with first 2000 words + structure hints (headings, sections)

**Tool 13: extract_metadata**
- **Purpose**: Metadata extraction (author, title, creation date, keywords)
- **Parameters**: `document_source`, `metadata_fields` (array: "author"|"title"|"date"|"keywords")
- **Output**: Metadata object with requested fields
- **Implementation**: Document properties extraction + LLM-based fallback for missing fields

**Tool 14: generate_document_summary**
- **Purpose**: Abstractive summarization via LLM
- **Parameters**: `document_source`, `summary_length` (int words or "short"|"medium"|"long"), `llm_model`
- **Output**: Summary text + key points array
- **Implementation**: LLM prompt with full document text (or chunks if >10K words) + summarization instructions

---

### PART 3: Manipulation Tools (5 tools)

#### Tool 15: merge_documents

**Purpose**: Combine multiple DoclingDocuments into single unified document with structure reconciliation and metadata aggregation.

**MCP Schema**:
```python
{
  "name": "merge_documents",
  "description": "Merge multiple DoclingDocuments into single document with structure reconciliation and metadata aggregation.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_sources": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of document sources or DoclingDocument IDs to merge"
      },
      "merge_strategy": {
        "type": "string",
        "enum": ["append", "interleave", "hierarchical"],
        "default": "append",
        "description": "append: concatenate docs | interleave: alternate pages | hierarchical: preserve section structure"
      },
      "preserve_metadata": {
        "type": "boolean",
        "default": true,
        "description": "Include metadata from all source documents in merged document"
      },
      "add_separators": {
        "type": "boolean",
        "default": true,
        "description": "Insert visual separators (horizontal rules) between merged documents"
      }
    },
    "required": ["document_sources"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "merged_document": {"type": "object", "description": "Unified DoclingDocument"},
      "metadata": {
        "type": "object",
        "properties": {
          "source_count": {"type": "integer"},
          "total_pages": {"type": "integer"},
          "merged_documents": {"type": "array", "items": {"type": "string"}},
          "merge_strategy": {"type": "string"}
        }
      }
    }
  }
}
```

**Merge Strategies**:
1. **Append**: Simple concatenation (doc1 + separator + doc2 + separator + doc3...)
2. **Interleave**: Alternate pages from each document (useful for side-by-side comparison)
3. **Hierarchical**: Preserve heading hierarchy, nest under new top-level heading per source document

**Implementation**: Traverse doc_items trees, concatenate or interleave, reconcile heading levels

---

#### Tool 16: split_document

**Purpose**: Split DoclingDocument into multiple smaller documents by page, section, heading, or size.

**MCP Schema**:
```python
{
  "name": "split_document",
  "description": "Split DoclingDocument into multiple documents by page, section, heading, or size boundaries.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string"},
      "split_strategy": {
        "type": "string",
        "enum": ["page", "section", "heading_level", "size"],
        "description": "page: one doc per page | section: split on H1/H2 | heading_level: split on H{level} | size: split by token count"
      },
      "heading_level": {
        "type": "integer",
        "minimum": 1,
        "maximum": 6,
        "description": "Required if split_strategy=heading_level (1-6)"
      },
      "max_size_tokens": {
        "type": "integer",
        "description": "Required if split_strategy=size (max tokens per split document)"
      },
      "preserve_structure": {
        "type": "boolean",
        "default": true,
        "description": "Maintain heading hierarchy in split documents"
      }
    },
    "required": ["document_source", "split_strategy"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "split_documents": {
        "type": "array",
        "items": {"type": "object", "description": "DoclingDocument segment"}
      },
      "summary": {
        "type": "object",
        "properties": {
          "segment_count": {"type": "integer"},
          "split_strategy": {"type": "string"},
          "average_size_tokens": {"type": "integer"}
        }
      }
    }
  }
}
```

**Implementation**: Traverse doc_items tree, identify split boundaries, create new DoclingDocument per segment

---

#### Tool 17: search_document

**Purpose**: Full-text search within DoclingDocument with ranking and highlighting.

**MCP Schema**:
```python
{
  "name": "search_document",
  "description": "Full-text search within DoclingDocument with BM25 ranking and context highlighting.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string"},
      "query": {"type": "string", "description": "Search query (keywords or phrases)"},
      "case_sensitive": {"type": "boolean", "default": false},
      "max_results": {"type": "integer", "default": 10},
      "highlight": {"type": "boolean", "default": true, "description": "Highlight matches in context snippets"},
      "context_window": {"type": "integer", "default": 50, "description": "Characters before/after match for context"}
    },
    "required": ["document_source", "query"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "results": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "score": {"type": "number"},
            "text_span": {"type": "object"},
            "context": {"type": "string", "description": "Highlighted context snippet"},
            "page": {"type": "integer"}
          }
        }
      },
      "summary": {
        "type": "object",
        "properties": {
          "total_matches": {"type": "integer"},
          "query": {"type": "string"},
          "processing_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Search Algorithm**: BM25 ranking on document text with highlight_matches() for context snippets

---

#### Tool 18: annotate_document

**Purpose**: Add annotations (highlights, comments, redactions) to DoclingDocument with persistence.

**MCP Schema**:
```python
{
  "name": "annotate_document",
  "description": "Add annotations (highlights, comments, redactions) to DoclingDocument. Annotations stored as metadata layer.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string"},
      "annotations": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "type": {"type": "string", "enum": ["highlight", "comment", "redaction"]},
            "text_span": {"type": "object"},
            "content": {"type": "string", "description": "Comment text (for type=comment)"},
            "color": {"type": "string", "description": "Highlight color hex code (for type=highlight)"}
          }
        }
      },
      "persist": {
        "type": "boolean",
        "default": true,
        "description": "Save annotations to document metadata (retrievable on future requests)"
      }
    },
    "required": ["document_source", "annotations"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "annotated_document": {"type": "object"},
      "annotation_count": {"type": "integer"}
    }
  }
}
```

**Implementation**: Annotations stored as metadata overlay (does not modify original content)

---

#### Tool 19: export_document

**Purpose**: Export DoclingDocument to output formats (PDF, DOCX, HTML, Markdown) with quality preservation.

**MCP Schema**:
```python
{
  "name": "export_document",
  "description": "Export DoclingDocument to output format (PDF, DOCX, HTML, Markdown) with structure and formatting preservation.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "document_source": {"type": "string", "description": "DoclingDocument ID or source"},
      "output_format": {
        "type": "string",
        "enum": ["pdf", "docx", "html", "markdown"],
        "description": "Target export format"
      },
      "preserve_formatting": {"type": "boolean", "default": true},
      "include_images": {"type": "boolean", "default": true},
      "output_path": {
        "type": "string",
        "description": "Optional file path to save exported document (if omitted, returns base64)"
      }
    },
    "required": ["document_source", "output_format"]
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "exported_document": {
        "type": "string",
        "description": "Base64-encoded document (if output_path not provided)"
      },
      "output_path": {"type": "string", "description": "Saved file path (if provided)"},
      "metadata": {
        "type": "object",
        "properties": {
          "format": {"type": "string"},
          "file_size_bytes": {"type": "integer"},
          "export_time_ms": {"type": "integer"}
        }
      }
    }
  }
}
```

**Export Backends**:
- **PDF**: Use reportlab or weasyprint for HTML→PDF conversion
- **DOCX**: Use python-docx for structure→DOCX mapping
- **HTML**: Direct HTML generation from DoclingDocument structure
- **Markdown**: Reuse `convert_document_to_markdown` logic

---

### Implementation Patterns Summary

**Common Patterns Across All Tools**:

**1. Input Validation** (Pydantic models):
- All parameters validated against JSON Schema before tool execution
- Invalid params → MCP error code `-32602` with descriptive message

**2. Caching Strategy** (Redis):
- Cache key: `tool_name:v1:MD5(parameters)`
- TTL: 24 hours for DoclingDocument results, 1 hour for LLM responses
- Cache hit → <500ms latency (skip processing)

**3. Error Handling** (MCP-compliant):
- Map Python exceptions → MCP error codes
- Include actionable error messages with context
- Log full stack traces for debugging (not exposed to client)

**4. Progress Reporting** (SSE transport):
- Long-running tools (>30s) emit progress events
- Format: `{"type":"progress","tool":"tool_name","percentage":45}`

**5. Timeout Management**:
- Per-tool timeouts via environment variables
- Default timeouts: conversion 120s, knowledge graph 300s, batch 600s
- Cancellation support via `tools/cancel` MCP method

---

### Docling Integration Best Practices

**1. Backend Selection**:
- Always prefer native backends (pypdfium2 for PDF) over OCR (slower, less accurate)
- OCR fallback triggered automatically for scanned PDFs (no embedded text layers)
- Multi-format support via backend abstraction (Docling library handles backend routing)

**2. Structure Preservation**:
- Preserve semantic structure (headings, lists, tables) in DoclingDocument JSON
- Use doc_items tree structure (hierarchical nodes with type annotations)
- Include metadata for all structural elements (heading level, list type, table dimensions)

**3. Performance Optimization**:
- Redis caching for repeated document processing (40%+ cache hit rate target)
- Parallel processing for multi-page PDFs (max 4 workers)
- Streaming for large documents (>100MB) to avoid memory bloat

**4. Error Recovery**:
- Graceful degradation: partial results better than total failure
- OCR failures → return text-based extraction with warning
- Table detection failures → return document without table structure

---

### Testing Strategy Summary

**Test Coverage Requirements**:
- Unit tests: 80%+ code coverage (pytest-cov)
- Integration tests: 100% MCP tool coverage (all 19 tools executed E2E)
- Multimodal tests: ≥95% format success rate (14+ formats)
- Performance tests: Latency targets met (NFR-001)
- Chaos tests: Graceful degradation validated

**Key Test Cases per Tool Category**:
- **Conversion**: TC-MM-001 to TC-MM-014 (format-specific accuracy tests)
- **Generation**: TC-INT-002 (knowledge graph E2E), TC-E2E-002 (multi-doc deduplication)
- **Manipulation**: Custom test cases for merge, split, search, annotate, export

**Quality Gates**:
- QG-002: 100% integration tests pass
- QG-004: ≥95% multimodal test success rate
- QG-005: Performance benchmarks meet NFR-001 targets

---

## Pydantic Schema Validation Summary

### Overview

The Docling MCP Server implements comprehensive data validation using Pydantic V2 throughout all layers of the application architecture. This ensures type-safety, prevents security vulnerabilities, provides clear error messages, and enables automatic JSON Schema generation for MCP protocol compliance.

### Validation Layers

**Layer 1: MCP Tool Input Validation**
- All 19 MCP tools use Pydantic BaseModel input schemas with Field constraints
- Custom validators prevent security vulnerabilities (path traversal, SSRF, injection attacks)
- Field-level validation with descriptive error messages for actionable feedback
- Examples: `ConvertDocumentInput`, `GenerateKnowledgeGraphInput`

**Layer 2: Data Model Validation**
- Entity and relationship payloads use comprehensive Pydantic schemas
- Cross-field validation ensures data integrity (e.g., text_span.end > text_span.start)
- Custom validators for semantic validation (e.g., bidirectional predicate checking)
- Examples: `EntityPayload`, `RelationshipPayload`, `TextSpan`

**Layer 3: Configuration Validation**
- Pydantic BaseSettings for environment variable validation
- Nested configuration groups with cross-field validation
- Fail-fast startup validation with sanitized logging (secrets excluded)
- Example: `DoclingMCPConfig` with nested `RedisSettings`, `QdrantSettings`, etc.

### Custom Type Definitions

Reusable Annotated types for common constraints across the codebase:

```python
from typing import Literal, Annotated
from pydantic import UUID4, Field
from pydantic.types import StringConstraints
from datetime import datetime

# Format enumerations (Literal types - runtime validated)
DocumentFormat = Literal["pdf", "docx", "pptx", "xlsx", "html", "md", "txt", "epub", "rtf", "png", "jpg", "tiff"]
EntityType = Literal["Person", "Organization", "Location", "Concept", "Product", "Date", "Event", "Technology", "Method", "Metric", "Dataset", "Model", "Tool"]
RelationshipPredicate = Literal["works_for", "leads", "member_of", "located_in", "near", "mentions", "cites", "before", "after", "during", "part_of", "instance_of", "authored_by", "contributed_to"]

# Constrained types (runtime validated)
ConfidenceScore = Annotated[float, Field(ge=0.0, le=1.0, description="Extraction confidence score (0.0 to 1.0)")]

# DocumentSource: Protocol validation with StringConstraints (RUNTIME VALIDATION)
DocumentSource = Annotated[str, StringConstraints(
    pattern=r"^(file://|https?://|data:)",
    min_length=1,
    max_length=2000
)]

# UUID: Pydantic native UUID4 type (RUNTIME VALIDATION - rejects invalid UUIDs)
UUID = UUID4

# ISOTimestamp: Pydantic datetime auto-parses ISO8601 (RUNTIME VALIDATION - rejects malformed timestamps)
ISOTimestamp = datetime

# QdrantCollectionName: StringConstraints for pattern validation (RUNTIME VALIDATION)
QdrantCollectionName = Annotated[str, StringConstraints(
    pattern=r"^docling_[a-z_]+$",
    min_length=8,
    max_length=64
)]
```

### Field Validators

**Security Validators** (prevent vulnerabilities):
- Path traversal prevention: Block `..`, `/etc`, `/root`, `/home` in file paths
- SSRF prevention: Block localhost and private IP ranges in URLs
- Size limits: Validate file size ≤500MB, base64 data ≤700MB
- Format validation: Verify MIME types, file extensions, data URI formats

**Data Integrity Validators** (ensure correctness):
- Cross-field validation: `text_span.end > text_span.start`
- Semantic validation: Bidirectional predicates must have `bidirectional=True`
- Deduplication: Remove duplicate aliases, trim whitespace
- Required field validation: DoclingDocument must have `doc_items` and `metadata`

**User Experience Validators** (provide guidance):
- Warn if confidence threshold >0.9 (may extract too few entities)
- Warn if concurrent workers >10 (may cause high memory usage)
- Provide specific error messages with allowed values and examples

### Error Message Standards

**Field-Specific Guidance**:
```python
# Bad error message
raise ValueError("Invalid source")

# Good error message with guidance
raise ValueError(
    f"Invalid source format. Must start with 'file://', 'http://', 'https://', or 'data:'. "
    f"Got: {source[:50]}..."
)
```

**Range Violation Messages**:
```python
# Template
f"{field_name} must be between {min} and {max}, got {value}"

# Example
"confidence_threshold must be between 0.0 and 1.0, got 1.5"
```

**Pattern Mismatch Messages**:
```python
# Template
f"{field_name} must be one of: {', '.join(allowed_values)}"

# Example
"entity_type must be one of: Person, Organization, Location, Concept, Product, Date, Event"
```

**Security Violation Messages**:
```python
# Template
f"Access denied to {resource}: {reason}. Allowed: {allowed_alternatives}"

# Examples
"Path traversal detected in '{path}'. Paths cannot contain '..', '/etc', '/root', or '/home'"
"URL access denied to private network: {blocked_host}. Only external URLs allowed for security."
"Document size {size}MB exceeds maximum allowed 500MB"
```

### JSON Schema Generation

**Automatic Schema Export**:
- Schema introspection: Send `{"jsonrpc":"2.0","method":"tools/list","id":1}` to `/mcp` returns JSON Schema for all tools
- Method: `model.model_json_schema(mode="serialization")` for all output schemas
- Schema metadata: Title, description, version, examples for documentation
- Breaking change detection: Compare schemas between versions

**Schema Versioning**:
- Include `"$schema": "https://json-schema.org/draft/2020-12/schema"` header
- Version in schema metadata: `"version": "1.0.0"`
- Deprecation warnings: Flag deprecated tools/parameters in schema

**Client Compatibility**:
- Python MCP SDK: Full compatibility with `StdioClient`, `HttpClient`
- Claude Desktop: stdio transport configuration JSON
- LangChain MCP: HTTP transport via `MCPClient` wrapper
- FastMCP In-Memory: Testing via `FastMCPTransport`

### Startup Validation

**Configuration Validation Process**:
1. Load environment variables from `.env` file or system environment
2. Instantiate `DoclingMCPConfig()`
3. Pydantic validates all fields (ranges, patterns, cross-field rules)
4. If validation fails: Log error, exit with status code 1 (fail fast)
5. If validation succeeds: Log sanitized config (DEBUG level), proceed with startup
6. Validate all MCP tool schemas (check signatures, Field descriptions)
7. Fail if any tool missing required field descriptions

**Startup Validation Example**:
```python
from docling_mcp.config import DoclingMCPConfig

# This runs on service startup (in __main__.py)
try:
    config = DoclingMCPConfig.load_config()
    logger.info("Configuration validation successful")
except Exception as e:
    logger.error(f"Configuration validation failed: {e}")
    sys.exit(1)  # Fail fast - do not start service with invalid config
```

### Performance Considerations

**Lazy Validation** (for large payloads):
- Use `model_construct()` for trusted data from Qdrant (bypass validation)
- Cache validated schemas for repeated tool invocations
- Disable `validate_assignment` for immutable models

**Validation Caching**:
- Reuse `TypeAdapter` instances for primitive type validation
- Cache compiled regex patterns in validators
- Use `@lru_cache` on expensive validation functions

**Optimization Strategies**:
- Strict mode: `model_config = {"strict": True}` disables type coercion for performance
- Disable unnecessary features: `model_config = {"validate_default": False}`
- Use `TypeAdapter` for simple types instead of full BaseModel

### Testing Strategy

**Validation Testing Requirements**:
- Unit tests for all field validators (path traversal, SSRF, size limits)
- Edge case testing (boundary values: 0.0, 1.0, max size limits)
- Cross-field validation tests (text_span, confidence thresholds)
- Security testing (malicious inputs, injection attacks)
- Error message clarity testing (verify actionable guidance)

**Test Coverage Targets**:
- 100% coverage for all custom validators
- 100% coverage for all Field constraints
- All validation error paths tested
- All custom error messages verified

**Example Validation Tests**:
```python
def test_path_traversal_prevention():
    """Test that path traversal is blocked in file sources."""
    with pytest.raises(ValidationError, match="Path traversal detected"):
        ConvertDocumentInput(source="file://../../../etc/passwd")

def test_ssrf_prevention():
    """Test that localhost URLs are blocked."""
    with pytest.raises(ValidationError, match="URL access denied to private network"):
        ConvertDocumentInput(source="http://localhost:8000/admin")

def test_file_size_limit():
    """Test that oversized documents are rejected."""
    # Mock 600MB file
    with pytest.raises(ValueError, match="exceeds maximum 500MB"):
        # Validation logic test
        pass

def test_confidence_score_range():
    """Test confidence score validation."""
    # Valid range
    input_valid = GenerateKnowledgeGraphInput(
        docling_document='{"doc_items": [], "metadata": {}}',
        confidence_threshold=0.75
    )
    assert input_valid.confidence_threshold == 0.75

    # Invalid range
    with pytest.raises(ValidationError, match="must be between 0.0 and 1.0"):
        GenerateKnowledgeGraphInput(
            docling_document='{"doc_items": [], "metadata": {}}',
            confidence_threshold=1.5
        )
```

### Anti-Patterns to Avoid

**DO NOT**:
- Use Pydantic V1 APIs (`parse_obj`, `parse_raw`, `Config` class)
- Hardcode validation rules (use Field constraints instead)
- Skip Field descriptions (breaks OpenAPI docs and LLM prompting)
- Use mutable defaults (`default=[]` instead of `default_factory=list`)
- Ignore ValidationError details (parse `.errors()` for debugging)
- Serialize sensitive fields without exclusion (`model_dump(exclude={'password'})`)
- Mix V1 and V2 APIs (causes deprecation warnings)
- Over-validate (reject valid edge cases unnecessarily)
- Under-validate security-critical fields (path traversal, SSRF)

**DO**:
- Use Pydantic V2 APIs (`model_validate`, `model_dump`, `model_json_schema`)
- Define reusable Annotated types for common constraints
- Add Field descriptions to ALL parameters (required for MCP tools)
- Use `default_factory` for mutable defaults
- Parse ValidationError.errors() for detailed field-level debugging
- Use `@field_serializer` to mask sensitive fields
- Exclusively use V2 APIs
- Balance security and usability (reject malicious inputs, accept valid edge cases)
- Validate all user inputs (never trust external data)

### Benefits Delivered

**Type Safety**:
- Compile-time type checking with mypy
- Runtime validation prevents type errors
- Auto-completion in IDEs (VSCode, PyCharm)

**Security**:
- Path traversal prevention (block `..`, sensitive directories)
- SSRF prevention (block localhost, private IPs)
- Size limit enforcement (prevent DoS via large payloads)
- Input sanitization (trim, normalize, validate formats)

**Developer Experience**:
- Clear error messages with actionable guidance
- Auto-generated JSON Schema for API documentation
- Consistent validation patterns across codebase
- Reduced boilerplate (validation via decorators)

**Operational Excellence**:
- Fail-fast startup validation (detect misconfigurations immediately)
- Sanitized logging (secrets excluded from logs)
- Breaking change detection (schema versioning)
- Client SDK compatibility (OpenAPI 3.1 schemas)

---

## Testing Strategy

### Test Coverage Requirements

**Test Categories**:
1. **Unit Tests** (80%+ code coverage):
   - Docling Processor: Format detection, backend selection, structure preservation
   - LightRAG Engine: Entity extraction, relationship extraction, graph construction
   - Integration Manager: LiteLLM client, Qdrant client, Redis client
   - Session Manager: Session lifecycle, TTL enforcement, status tracking
   - MCP Tool Handlers: Input validation, output formatting, error handling

2. **Integration Tests** (100% MCP tool coverage):
   - All 19 MCP tools executed end-to-end
   - Dependency integration: LiteLLM, Qdrant, Redis connectivity tests
   - Multi-step workflows: Session-based document processing

3. **End-to-End Tests**:
   - Complete document processing pipeline: Upload PDF → Convert → Generate knowledge graph → Query Qdrant
   - Multi-document knowledge graph: Batch processing with entity deduplication
   - Error scenarios: Dependency failures, invalid inputs, timeout handling

4. **Multimodal Tests**:
   - Format-specific tests: PDF, DOCX, PPTX, XLSX, HTML, images (14+ formats)
   - Complex document tests: Multi-page tables, embedded images, mixed content
   - OCR tests: Scanned PDFs, image-based documents

5. **Performance Tests**:
   - Latency benchmarks: Document conversion time by size/format
   - Throughput tests: Concurrent document processing (5 clients)
   - Soak tests: 48-hour continuous operation under sustained load

6. **Chaos Engineering Tests**:
   - Dependency failure scenarios: LiteLLM down, Qdrant down, Redis down
   - Graceful degradation validation: Feature disablement, error handling
   - Recovery tests: Auto-restart after crash, dependency recovery

### Detailed Test Scenarios by Category

#### 1. Unit Test Scenarios

**Docling Processor Tests**:

**TC-UNIT-001: Format Detection Accuracy**
- **Scenario**: Test automatic format detection for all supported formats
- **Test Data**: 14 sample files (PDF, DOCX, PPTX, XLSX, HTML, MD, PNG, JPG, TIFF, EPUB, RTF, corrupted file, unknown extension)
- **Test Steps**:
  1. Invoke format detector with each sample file
  2. Capture detected format
  3. Compare against expected format
- **Expected Result**: 100% accuracy for valid formats, graceful error for corrupted/unknown
- **Pass Criteria**: All 14 files correctly identified or error raised with diagnostic message
- **Automated**: pytest test `tests/unit/test_format_detection.py`

**TC-UNIT-002: Structure Preservation in DoclingDocument**
- **Scenario**: Verify heading hierarchy, tables, lists, code blocks preserved during conversion
- **Test Data**: Structured document with H1-H6 headings, 3-level nested lists, 2 tables (simple + merged cells), 1 code block
- **Test Steps**:
  1. Convert test document to DoclingDocument
  2. Parse JSON structure
  3. Verify heading levels preserved (H1 → level 1, H2 → level 2, etc.)
  4. Verify list nesting depth matches source (3 levels)
  5. Verify table cell count and structure (merged cells preserved)
  6. Verify code block language detected and syntax preserved
- **Expected Result**: All structural elements preserved with correct hierarchy and attributes
- **Pass Criteria**: JSON schema validation passes, manual inspection confirms structure accuracy
- **Automated**: pytest test `tests/unit/test_structure_preservation.py`

**TC-UNIT-003: Backend Selection Logic**
- **Scenario**: Test backend selection for different format/quality combinations
- **Test Data**: PDF (text-based, scanned), DOCX (simple, complex formatting), image (clear text, poor quality)
- **Test Steps**:
  1. Process each test file
  2. Capture backend selection (pypdfium2, tesseract, mammoth)
  3. Verify backend matches expected choice for format/quality
- **Expected Result**: pypdfium2 for text PDFs, tesseract for scanned PDFs/poor images, mammoth for DOCX
- **Pass Criteria**: Backend selection matches documented decision matrix 100%
- **Automated**: pytest test with mocked backends `tests/unit/test_backend_selection.py`

**LightRAG Engine Tests**:

**TC-UNIT-004: Entity Extraction from LLM Response**
- **Scenario**: Test entity parser handles various LLM response formats
- **Test Data**: Mock LLM responses (valid JSON, malformed JSON, incomplete entities, duplicate entities)
- **Test Steps**:
  1. Feed mock LLM responses to entity parser
  2. Capture parsed entities
  3. Verify entity attributes (name, type, confidence, span)
  4. Verify error handling for malformed responses
- **Expected Result**: Valid responses → entities extracted, malformed → error raised with context
- **Pass Criteria**: 100% of valid responses parsed correctly, all malformed responses error with diagnostic message
- **Automated**: pytest test `tests/unit/test_entity_extraction.py`

**TC-UNIT-005: Relationship Extraction and Validation**
- **Scenario**: Test relationship extraction from text with entity references
- **Test Data**: Text snippet with entity pairs, mock entity list, expected relationships
- **Test Steps**:
  1. Extract relationships from text
  2. Verify subject-predicate-object structure
  3. Validate entity references exist in entity list
  4. Check confidence scores assigned
- **Expected Result**: All valid relationships extracted, invalid entity references rejected
- **Pass Criteria**: Relationship triples match expected output, orphan relationships rejected
- **Automated**: pytest test `tests/unit/test_relationship_extraction.py`

**TC-UNIT-006: Entity Deduplication Logic**
- **Scenario**: Test entity deduplication across multiple documents
- **Test Data**: 3 documents with overlapping entities (same name, different contexts)
- **Test Steps**:
  1. Extract entities from all documents
  2. Run deduplication algorithm
  3. Verify duplicate entities merged with combined contexts
  4. Verify unique entities preserved
- **Expected Result**: Similar entities merged (e.g., "IBM" mentions unified), dissimilar entities preserved
- **Pass Criteria**: Final entity count matches expected (duplicates removed), entity contexts aggregated correctly
- **Automated**: pytest test `tests/unit/test_entity_deduplication.py`

**Integration Manager Tests**:

**TC-UNIT-007: LiteLLM Client Retry Logic**
- **Scenario**: Test exponential backoff retry on LiteLLM failures
- **Test Data**: Mock LiteLLM responses (timeout, 503 error, success on 3rd attempt)
- **Test Steps**:
  1. Configure mock LiteLLM to fail twice, succeed third time
  2. Invoke LiteLLM client
  3. Capture retry attempts and delays
  4. Verify exponential backoff (1s, 2s, 4s delays)
- **Expected Result**: Client retries 3 times with exponential backoff, succeeds on 3rd attempt
- **Pass Criteria**: Retry count = 3, delays match exponential pattern, final request succeeds
- **Automated**: pytest test with mocked httpx client `tests/unit/test_litellm_retry.py`

**TC-UNIT-008: Qdrant Client Connection Pool**
- **Scenario**: Test connection pool reuse and health checks
- **Test Data**: Multiple concurrent Qdrant requests (10 parallel upserts)
- **Test Steps**:
  1. Send 10 parallel upsert requests
  2. Monitor connection pool usage
  3. Verify connections reused (not 10 new connections)
  4. Check health check executed before requests
- **Expected Result**: Connection pool size ≤ max (10), connections reused efficiently
- **Pass Criteria**: Connection count ≤ 10, health check passes before requests, all upserts succeed
- **Automated**: pytest test `tests/unit/test_qdrant_connection_pool.py`

**TC-UNIT-009: Redis Session TTL Enforcement**
- **Scenario**: Test session expiration after configured TTL
- **Test Data**: Session with TTL = 1 second (test override)
- **Test Steps**:
  1. Create session with 1-second TTL
  2. Wait 2 seconds
  3. Attempt to retrieve session
  4. Verify session expired and returns None
- **Expected Result**: Session exists immediately after creation, expires after TTL
- **Pass Criteria**: Session retrieval succeeds at t=0, fails at t=2s with session_not_found error
- **Automated**: pytest test `tests/unit/test_session_ttl.py`

**MCP Tool Handler Tests**:

**TC-UNIT-010: Input Validation via Pydantic**
- **Scenario**: Test MCP tool input validation rejects invalid parameters
- **Test Data**: Invalid tool invocations (missing required param, wrong type, out-of-range value, path traversal attempt)
- **Test Steps**:
  1. Invoke MCP tool with each invalid input
  2. Capture validation errors
  3. Verify error messages include parameter name and validation failure reason
- **Expected Result**: All invalid inputs rejected with descriptive validation errors
- **Pass Criteria**: 100% of invalid inputs rejected, error messages human-readable and diagnostic
- **Automated**: pytest test `tests/unit/test_mcp_input_validation.py`

**TC-UNIT-011: Output Formatting Consistency**
- **Scenario**: Test MCP tool outputs match declared schemas
- **Test Data**: Successful tool executions for all 19 tools
- **Test Steps**:
  1. Execute each tool with valid inputs
  2. Capture output JSON
  3. Validate against Pydantic output schema
  4. Verify all required fields present, types correct
- **Expected Result**: All tool outputs conform to declared schemas
- **Pass Criteria**: 19/19 tools pass schema validation, no missing/extra fields
- **Automated**: pytest test `tests/unit/test_mcp_output_schemas.py`

**TC-UNIT-012: Error Handling and MCP Error Responses**
- **Scenario**: Test error scenarios return MCP-compliant error responses
- **Test Data**: Error conditions (file not found, LLM timeout, Qdrant write failure, invalid format)
- **Test Steps**:
  1. Trigger each error condition
  2. Capture MCP error response
  3. Verify error structure (code, message, data)
  4. Check error codes match MCP spec
- **Expected Result**: All errors return MCP-compliant error responses with diagnostic information
- **Pass Criteria**: Error responses match MCP spec, error codes documented, messages actionable
- **Automated**: pytest test `tests/unit/test_mcp_error_handling.py`

#### 2. Integration Test Scenarios

**MCP Tool Integration Tests**:

**TC-INT-001: convert_document End-to-End**
- **Scenario**: Test complete document conversion flow via MCP
- **Test Data**: Sample PDF (10 pages, mixed text/images/tables)
- **Test Steps**:
  1. MCP client invokes convert_document with PDF path
  2. Docling processes PDF → DoclingDocument
  3. MCP server returns DoclingDocument JSON
  4. Validate JSON structure and content
- **Expected Result**: DoclingDocument contains all pages, images extracted, tables preserved, text accurate
- **Pass Criteria**: JSON schema valid, page count = 10, table count ≥ expected, image count ≥ expected
- **Validation Method**: Compare output against known-good baseline, manual spot-check for accuracy
- **Automated**: pytest integration test `tests/integration/test_convert_document.py`

**TC-INT-002: generate_knowledge_graph End-to-End**
- **Scenario**: Test complete knowledge graph generation via MCP
- **Test Data**: Research paper PDF (5000 words, entity-rich content)
- **Test Steps**:
  1. MCP client invokes generate_knowledge_graph with PDF
  2. Docling converts to DoclingDocument
  3. LightRAG extracts entities via LiteLLM (gemma3:27b)
  4. LightRAG extracts relationships
  5. Entities/relationships stored in Qdrant
  6. MCP server returns graph summary
- **Expected Result**: 50+ entities extracted, 100+ relationships, Qdrant collections populated
- **Pass Criteria**: Graph summary shows entity_count ≥ 50, relationship_count ≥ 100, Qdrant query confirms storage
- **Validation Method**: Query Qdrant collections directly, verify entity/relationship presence, check graph density
- **Automated**: pytest integration test `tests/integration/test_generate_knowledge_graph.py`

**TC-INT-003: batch_convert Performance**
- **Scenario**: Test batch conversion of multiple documents
- **Test Data**: 10 documents (mix of PDF, DOCX, PPTX)
- **Test Steps**:
  1. MCP client invokes batch_convert with document list
  2. Server processes all documents
  3. Returns list of DoclingDocuments
  4. Measure processing time
- **Expected Result**: All 10 documents converted successfully, batch processing faster than sequential
- **Pass Criteria**: 10/10 documents converted, total time < 10x single document time (parallelism benefit)
- **Validation Method**: Time measurement, verify all outputs present and valid
- **Automated**: pytest integration test `tests/integration/test_batch_convert.py`

**TC-INT-004: Session-Based Multi-Step Workflow**
- **Scenario**: Test session creation, document upload, processing, status query, cleanup
- **Test Data**: Session with 3 documents
- **Test Steps**:
  1. MCP client creates session
  2. Uploads 3 documents to session
  3. Processes documents (convert + generate graph)
  4. Queries session status (should show 3 completed)
  5. Deletes session
  6. Verifies session cleanup (Redis keys removed)
- **Expected Result**: Session lifecycle managed correctly, status accurate, cleanup complete
- **Pass Criteria**: Session created, 3 documents processed, status query shows completed, Redis keys removed after delete
- **Validation Method**: Redis key inspection before/after, session status validation
- **Automated**: pytest integration test `tests/integration/test_session_workflow.py`

**Dependency Integration Tests**:

**TC-INT-005: LiteLLM Connectivity and Model Availability**
- **Scenario**: Test LiteLLM gateway connectivity and model availability
- **Test Data**: Chat completion request (simple entity extraction prompt)
- **Test Steps**:
  1. Health check LiteLLM endpoint
  2. List available models via LiteLLM API
  3. Send chat completion request for gemma3:27b
  4. Verify response contains entities
- **Expected Result**: LiteLLM healthy, gemma3:27b available, completion successful
- **Pass Criteria**: Health check 200 OK, model list includes gemma3:27b, completion returns valid JSON
- **Validation Method**: HTTP status codes, model list parsing, completion response validation
- **Automated**: pytest integration test `tests/integration/test_litellm_integration.py`

**TC-INT-006: Qdrant Collection Management**
- **Scenario**: Test Qdrant collection creation, upsert, query
- **Test Data**: Test entities (10 entities with embeddings), test relationships (20 relationships)
- **Test Steps**:
  1. Create collections (hx_docling_mcp_entities_test, hx_docling_mcp_relationships_test)
  2. Upsert entities into hx_docling_mcp_entities_test
  3. Upsert relationships into hx_docling_mcp_relationships_test
  4. Query collections (retrieve all points)
  5. Verify point count matches upserted count
  6. Delete test collections
- **Expected Result**: Collections created, upserts successful, queries return correct counts
- **Pass Criteria**: Entity collection has 10 points, relationship collection has 20 points, cleanup successful
- **Validation Method**: Qdrant API calls, point count validation
- **Automated**: pytest integration test `tests/integration/test_qdrant_integration.py`

**TC-INT-007: Redis Session Storage and Retrieval**
- **Scenario**: Test Redis session CRUD operations
- **Test Data**: Test session metadata (JSON with user, timestamp, document IDs)
- **Test Steps**:
  1. SET session key with metadata
  2. GET session key (verify retrieval)
  3. UPDATE session key (add new document ID)
  4. GET updated session (verify change)
  5. DELETE session key
  6. Verify key no longer exists
- **Expected Result**: All CRUD operations successful, data integrity maintained
- **Pass Criteria**: SET/GET/UPDATE/DELETE all succeed, retrieved data matches stored data
- **Validation Method**: Redis command results, data comparison
- **Automated**: pytest integration test `tests/integration/test_redis_integration.py`

**TC-INT-008: Ollama Model Routing via LiteLLM**
- **Scenario**: Test LiteLLM routes requests to correct Ollama servers
- **Test Data**: Requests for gemma3:27b (Ollama1), qwen3-coder:30b (Ollama2)
- **Test Steps**:
  1. Send completion request for gemma3:27b via LiteLLM
  2. Verify routing to Ollama1 (hx-ollama1-server.hx.dev.local)
  3. Send completion request for qwen3-coder:30b via LiteLLM
  4. Verify routing to Ollama2 (hx-ollama2-server.hx.dev.local)
- **Expected Result**: LiteLLM correctly routes requests to appropriate Ollama servers
- **Pass Criteria**: Both requests succeed, routing confirmed via LiteLLM logs or response headers
- **Validation Method**: LiteLLM routing logs, Ollama server access logs
- **Automated**: pytest integration test `tests/integration/test_ollama_routing.py`

#### 3. End-to-End Test Scenarios

**TC-E2E-001: Complete RAG Pipeline (Stage 1 + Stage 2)**
- **Scenario**: Test full pipeline: document upload → conversion → knowledge graph → Qdrant storage → query validation
- **Test Data**: Technical whitepaper PDF (10 pages, entity-rich)
- **Test Steps**:
  1. Upload PDF via MCP
  2. Convert to DoclingDocument
  3. Generate knowledge graph (entities + relationships)
  4. Store in Qdrant
  5. Query Qdrant for specific entity (e.g., "Kubernetes")
  6. Verify entity found with correct attributes and relationships
- **Expected Result**: Pipeline completes successfully, entity retrievable from Qdrant with relationships
- **Pass Criteria**: All steps succeed, Qdrant query returns expected entity with relationships
- **Validation Method**: Step-by-step verification, Qdrant query results inspection
- **Automated**: pytest E2E test `tests/e2e/test_complete_rag_pipeline.py`

**TC-E2E-002: Multi-Document Knowledge Graph with Entity Deduplication**
- **Scenario**: Test knowledge graph generation across multiple documents with entity overlap
- **Test Data**: 5 research papers on same topic (AI/ML), overlapping entities expected (TensorFlow, PyTorch, researchers)
- **Test Steps**:
  1. Batch convert 5 papers
  2. Generate unified knowledge graph with deduplication enabled
  3. Query Qdrant for "TensorFlow" entity
  4. Verify single entity with references to all 5 documents
  5. Check relationship count (should include cross-document relationships)
- **Expected Result**: Entities deduplicated across documents, relationships unified, cross-document connections exist
- **Pass Criteria**: Entity count < sum of individual document entities (deduplication occurred), "TensorFlow" entity has 5 document references
- **Validation Method**: Entity count comparison, Qdrant query for deduplicated entities, relationship graph analysis
- **Automated**: pytest E2E test `tests/e2e/test_multi_document_knowledge_graph.py`

**TC-E2E-003: Error Recovery - Invalid Document Handling**
- **Scenario**: Test system handles invalid/corrupted documents gracefully
- **Test Data**: Corrupted PDF, zero-byte file, unsupported format (.exe file)
- **Test Steps**:
  1. Attempt to convert corrupted PDF
  2. Verify error response (not crash)
  3. Attempt to convert zero-byte file
  4. Verify error response
  5. Attempt to convert unsupported format
  6. Verify error response with format diagnostic
- **Expected Result**: All invalid inputs return MCP error responses, service remains operational
- **Pass Criteria**: 3/3 errors handled gracefully, service health check passes after errors, no crashes
- **Validation Method**: Error response validation, service health check, log inspection for exceptions
- **Automated**: pytest E2E test `tests/e2e/test_invalid_document_handling.py`

**TC-E2E-004: Concurrent Client Load**
- **Scenario**: Test service handles multiple concurrent MCP clients
- **Test Data**: 5 concurrent clients, each processing 2 documents
- **Test Steps**:
  1. Launch 5 MCP clients in parallel
  2. Each client converts 2 documents (10 total documents)
  3. Monitor processing time and success rate
  4. Verify all 10 documents processed successfully
- **Expected Result**: All clients succeed, processing time reasonable (parallelism effective)
- **Pass Criteria**: 10/10 documents processed successfully, no client timeouts, p95 latency within NFR-001 targets
- **Validation Method**: Client success tracking, latency measurement, concurrency logs
- **Automated**: pytest E2E test with concurrent execution `tests/e2e/test_concurrent_clients.py`

#### 4. Multimodal Test Scenarios

**TC-MM-001: PDF Text Extraction Accuracy**
- **Scenario**: Test text extraction from text-based PDF
- **Test Data**: Clean PDF with known text content (reference document)
- **Test Steps**:
  1. Convert PDF to DoclingDocument
  2. Extract text content from DoclingDocument
  3. Compare against reference text (character-level comparison)
  4. Calculate accuracy (character match percentage)
- **Expected Result**: Text accuracy ≥ 99%
- **Pass Criteria**: Character match ≥ 99%, no major word omissions
- **Validation Method**: String comparison algorithm, manual spot-check for semantic accuracy
- **Automated**: pytest multimodal test `tests/multimodal/test_pdf_text_extraction.py`

**TC-MM-002: PDF Table Extraction with Merged Cells**
- **Scenario**: Test table extraction from PDF with complex table (merged cells, multi-page tables)
- **Test Data**: Financial report PDF with 3-page table, merged header cells
- **Test Steps**:
  1. Extract tables from PDF
  2. Verify table structure (rows, columns, merged cells)
  3. Compare against reference table (CSV ground truth)
  4. Check cell values match
- **Expected Result**: Table structure preserved, cell values accurate
- **Pass Criteria**: Row/column count matches reference, merged cells preserved, cell value accuracy ≥ 95%
- **Validation Method**: JSON table structure validation, CSV comparison
- **Automated**: pytest multimodal test `tests/multimodal/test_pdf_table_extraction.py`

**TC-MM-003: PDF Image Extraction and Captioning**
- **Scenario**: Test image extraction from PDF with embedded images
- **Test Data**: PDF with 5 images (diagrams, charts, photos)
- **Test Steps**:
  1. Extract images from PDF
  2. Verify image count (should be 5)
  3. Check image captions if present
  4. Validate image format (base64 or file reference)
- **Expected Result**: All 5 images extracted, captions preserved
- **Pass Criteria**: Image count = 5, captions match source, image data valid (decodable)
- **Validation Method**: Image count validation, base64 decode test, caption text comparison
- **Automated**: pytest multimodal test `tests/multimodal/test_pdf_image_extraction.py`

**TC-MM-004: DOCX Formatting Preservation**
- **Scenario**: Test DOCX conversion preserves formatting (bold, italic, headings, lists)
- **Test Data**: DOCX with rich formatting (bold/italic text, H1-H3 headings, bulleted/numbered lists)
- **Test Steps**:
  1. Convert DOCX to DoclingDocument
  2. Verify heading hierarchy (H1, H2, H3 levels)
  3. Check list structure (bullet vs numbered, nesting)
  4. Verify inline formatting (bold, italic spans)
- **Expected Result**: Formatting preserved in DoclingDocument JSON annotations
- **Pass Criteria**: Heading levels correct, list types correct, inline formatting annotations present
- **Validation Method**: JSON structure inspection, annotation tag validation
- **Automated**: pytest multimodal test `tests/multimodal/test_docx_formatting.py`

**TC-MM-005: PPTX Slide Structure Extraction**
- **Scenario**: Test PPTX conversion extracts slide structure (titles, content, notes)
- **Test Data**: PPTX with 10 slides (titles, bullet points, speaker notes, embedded images)
- **Test Steps**:
  1. Convert PPTX to DoclingDocument
  2. Verify slide count (should be 10)
  3. Check slide titles extracted
  4. Verify bullet points preserved
  5. Check speaker notes included
- **Expected Result**: All 10 slides extracted, titles and content preserved, notes included
- **Pass Criteria**: Slide count = 10, titles match source, bullet points preserved, notes present
- **Validation Method**: Slide count validation, content comparison against source
- **Automated**: pytest multimodal test `tests/multimodal/test_pptx_extraction.py`

**TC-MM-006: XLSX Cell Data and Formulas**
- **Scenario**: Test XLSX conversion extracts cell data and preserves formulas
- **Test Data**: XLSX with 3 sheets (data sheet, formula sheet, chart sheet)
- **Test Steps**:
  1. Convert XLSX to DoclingDocument
  2. Verify sheet count (should be 3)
  3. Check cell values in data sheet
  4. Verify formula preservation (formula strings, not just values)
  5. Check chart references (if supported)
- **Expected Result**: All sheets extracted, cell values accurate, formulas preserved
- **Pass Criteria**: Sheet count = 3, cell values match source, formulas stored as strings
- **Validation Method**: Sheet/cell comparison, formula string validation
- **Automated**: pytest multimodal test `tests/multimodal/test_xlsx_extraction.py`

**TC-MM-007: HTML Structure and Semantic Tags**
- **Scenario**: Test HTML conversion preserves semantic structure (headers, lists, links, code blocks)
- **Test Data**: HTML page with headers (h1-h6), lists (ul, ol), links, code blocks (pre/code tags)
- **Test Steps**:
  1. Convert HTML to DoclingDocument
  2. Verify heading hierarchy
  3. Check list structure
  4. Verify links preserved (href attributes)
  5. Check code blocks preserved
- **Expected Result**: Semantic structure preserved, links functional, code blocks formatted
- **Pass Criteria**: Headers correct levels, lists correct types, links present with hrefs, code blocks preserved
- **Validation Method**: JSON structure validation, semantic tag mapping check
- **Automated**: pytest multimodal test `tests/multimodal/test_html_extraction.py`

**TC-MM-008: Scanned PDF OCR Accuracy**
- **Scenario**: Test OCR accuracy on scanned PDF (image-based, no embedded text)
- **Test Data**: Scanned research paper (high quality scan, 5 pages)
- **Test Steps**:
  1. Convert scanned PDF (OCR triggered automatically)
  2. Extract text from DoclingDocument
  3. Compare against reference text (if available)
  4. Calculate OCR accuracy (word error rate)
- **Expected Result**: OCR text accuracy ≥ 90% (high quality scan)
- **Pass Criteria**: Word error rate ≤ 10%, readable text extracted
- **Validation Method**: OCR accuracy measurement (if reference available), manual readability check
- **Automated**: pytest multimodal test `tests/multimodal/test_scanned_pdf_ocr.py`

**TC-MM-009: Image Document OCR (JPG/PNG)**
- **Scenario**: Test OCR on standalone image documents (screenshots, photos of documents)
- **Test Data**: JPG image of text document (clear text, good lighting)
- **Test Steps**:
  1. Convert image to DoclingDocument (OCR)
  2. Extract text
  3. Verify text readable and accurate
- **Expected Result**: Text extracted, readable content
- **Pass Criteria**: Text extraction succeeds, content recognizable, major words captured
- **Validation Method**: Manual readability check, keyword presence validation
- **Automated**: pytest multimodal test `tests/multimodal/test_image_ocr.py`

**TC-MM-010: Poor Quality Image OCR (Low Resolution)**
- **Scenario**: Test OCR performance on low-quality image (low resolution, poor contrast)
- **Test Data**: Low-resolution JPG (72dpi, low contrast text)
- **Test Steps**:
  1. Attempt OCR on low-quality image
  2. Capture OCR confidence scores
  3. Verify error handling if OCR fails
- **Expected Result**: OCR attempted, low confidence reported if poor quality, or error raised with diagnostic
- **Pass Criteria**: OCR either succeeds with low confidence warning OR fails gracefully with quality diagnostic
- **Validation Method**: Confidence score check, error message validation
- **Automated**: pytest multimodal test `tests/multimodal/test_poor_quality_ocr.py`

**TC-MM-011: Markdown to DoclingDocument Conversion**
- **Scenario**: Test Markdown conversion preserves structure (headers, lists, code blocks, links)
- **Test Data**: Markdown file with headers (#, ##, ###), lists (-, *), code blocks (\`\`\`), links
- **Test Steps**:
  1. Convert Markdown to DoclingDocument
  2. Verify header hierarchy
  3. Check list structure
  4. Verify code blocks with language tags
  5. Check links preserved
- **Expected Result**: Markdown structure preserved in DoclingDocument
- **Pass Criteria**: Headers correct levels, lists correct, code blocks with language, links present
- **Validation Method**: JSON structure validation, Markdown element mapping
- **Automated**: pytest multimodal test `tests/multimodal/test_markdown_conversion.py`

**TC-MM-012: EPUB Structure and Chapter Extraction**
- **Scenario**: Test EPUB conversion extracts chapters and structure
- **Test Data**: EPUB ebook with 10 chapters, TOC, metadata
- **Test Steps**:
  1. Convert EPUB to DoclingDocument
  2. Verify chapter count (should be 10)
  3. Check TOC preserved
  4. Verify metadata (title, author)
- **Expected Result**: All chapters extracted, TOC structure preserved, metadata extracted
- **Pass Criteria**: Chapter count = 10, TOC links functional, metadata correct
- **Validation Method**: Chapter count validation, TOC structure check, metadata comparison
- **Automated**: pytest multimodal test `tests/multimodal/test_epub_extraction.py`

**TC-MM-013: RTF Formatting Preservation**
- **Scenario**: Test RTF conversion preserves formatting (bold, italic, colors, fonts)
- **Test Data**: RTF file with rich formatting (bold/italic, colored text, multiple fonts)
- **Test Steps**:
  1. Convert RTF to DoclingDocument
  2. Verify inline formatting annotations (bold, italic)
  3. Check color/font metadata if preserved
- **Expected Result**: Formatting preserved in DoclingDocument annotations
- **Pass Criteria**: Bold/italic annotations present, text content accurate
- **Validation Method**: JSON annotation inspection, text accuracy check
- **Automated**: pytest multimodal test `tests/multimodal/test_rtf_formatting.py`

**TC-MM-014: Mixed Content Document (Text + Images + Tables)**
- **Scenario**: Test complex document with all content types
- **Test Data**: PDF with text paragraphs, 3 tables, 5 images, code blocks, headings
- **Test Steps**:
  1. Convert mixed content PDF
  2. Verify all content types extracted (text, tables, images, code)
  3. Check content ordering preserved (text → image → table → code)
  4. Validate structure completeness
- **Expected Result**: All content types extracted and ordered correctly
- **Pass Criteria**: Table count = 3, image count = 5, code block count ≥ 1, content order matches source
- **Validation Method**: Content type count, ordering validation, completeness check
- **Automated**: pytest multimodal test `tests/multimodal/test_mixed_content_document.py`

#### 5. Performance Test Scenarios

**TC-PERF-001: Document Conversion Latency Baseline**
- **Scenario**: Establish baseline latency for document conversion by size/format
- **Test Data**: Documents of varying sizes (small <10 pages, medium 10-100 pages, large >100 pages) across all formats
- **Test Steps**:
  1. Convert 100 small documents (measure p50, p95, p99)
  2. Convert 50 medium documents
  3. Convert 10 large documents
  4. Record latency distributions
  5. Compare against NFR-001 targets
- **Expected Result**: Latencies within NFR-001 targets (small <5s, medium <30s, large <2min at p95)
- **Pass Criteria**: 95% of documents meet NFR-001 targets for their size category
- **Validation Method**: Latency measurement with percentile calculation
- **Automated**: pytest performance test with benchmarking `tests/performance/test_conversion_latency.py`

**TC-PERF-002: Entity Extraction Throughput**
- **Scenario**: Measure entity extraction throughput (entities per second)
- **Test Data**: 10 documents (5000 words each, entity-rich content)
- **Test Steps**:
  1. Extract entities from all 10 documents
  2. Measure total processing time
  3. Calculate entities per second
  4. Compare against baseline (100+ entities per 10K words in 60s = ~16 entities/sec minimum)
- **Expected Result**: Entity extraction meets throughput baseline
- **Pass Criteria**: Throughput ≥ 16 entities/second average across 10 documents
- **Validation Method**: Throughput calculation (total entities / total time)
- **Automated**: pytest performance test `tests/performance/test_entity_extraction_throughput.py`

**TC-PERF-003: Concurrent Client Handling**
- **Scenario**: Test service handles concurrent clients without degradation
- **Test Data**: 5 concurrent clients, each processing 10 documents (50 total)
- **Test Steps**:
  1. Launch 5 clients simultaneously
  2. Each client processes 10 documents sequentially
  3. Measure per-client latency (p95)
  4. Compare against baseline (single client latency)
- **Expected Result**: p95 latency with 5 clients ≤ 2x single client latency
- **Pass Criteria**: Concurrent p95 latency ≤ 2x baseline, all 50 documents succeed
- **Validation Method**: Latency comparison, success rate tracking
- **Automated**: pytest performance test with concurrent execution `tests/performance/test_concurrent_clients.py`

**TC-PERF-004: Qdrant Write Performance**
- **Scenario**: Measure Qdrant write latency for knowledge graph storage
- **Test Data**: 1000 entities, 5000 relationships
- **Test Steps**:
  1. Upsert 1000 entities to Qdrant (batch upsert)
  2. Measure upsert time (p95)
  3. Upsert 5000 relationships
  4. Measure upsert time
  5. Calculate write throughput (points/second)
- **Expected Result**: Write latency within reasonable bounds (p95 <5s for 1000 entities)
- **Pass Criteria**: Entity upsert p95 <5s, relationship upsert p95 <20s, no write errors
- **Validation Method**: Latency measurement, error rate tracking
- **Automated**: pytest performance test `tests/performance/test_qdrant_write.py`

**TC-PERF-005: Redis Session Operations Latency**
- **Scenario**: Measure Redis session operation latencies (SET, GET, UPDATE, DELETE)
- **Test Data**: 1000 session operations (250 of each type)
- **Test Steps**:
  1. Execute 250 SET operations
  2. Measure latency (p95)
  3. Repeat for GET, UPDATE, DELETE
  4. Calculate latency distribution
- **Expected Result**: All operations <10ms at p95
- **Pass Criteria**: SET/GET/UPDATE/DELETE p95 latency <10ms each
- **Validation Method**: Latency measurement with percentile calculation
- **Automated**: pytest performance test `tests/performance/test_redis_latency.py`

**TC-PERF-006: Memory Usage Under Load**
- **Scenario**: Monitor memory usage during document processing
- **Test Data**: 50 large documents (100+ pages each)
- **Test Steps**:
  1. Record baseline memory usage
  2. Process 50 large documents sequentially
  3. Monitor memory usage every 10 seconds
  4. Calculate peak memory and memory leak detection
- **Expected Result**: Memory usage stays within systemd limits (4GB), no memory leaks
- **Pass Criteria**: Peak memory <4GB, memory returns to baseline after processing (no leaks)
- **Validation Method**: Memory profiling (psutil), leak detection (growth rate analysis)
- **Automated**: pytest performance test with memory monitoring `tests/performance/test_memory_usage.py`

**TC-PERF-007: Soak Test (48-Hour Continuous Operation)**
- **Scenario**: Test service stability under sustained load for 48 hours
- **Test Data**: Continuous document processing (10 documents/hour, 480 total documents)
- **Test Steps**:
  1. Start service
  2. Submit 10 documents per hour for 48 hours
  3. Monitor health checks every 30 seconds
  4. Track error rate, latency degradation, memory leaks
  5. Verify service remains healthy throughout
- **Expected Result**: Service maintains 99%+ uptime, no performance degradation, zero critical errors
- **Pass Criteria**: Uptime ≥99%, error rate <1%, latency stable (no >20% increase), memory stable (no leaks)
- **Validation Method**: Health check monitoring, error log analysis, performance metrics trending
- **Automated**: Long-running test script with monitoring `tests/performance/test_soak_48h.py`

**TC-PERF-008: Batch Processing Efficiency**
- **Scenario**: Compare batch processing vs sequential processing efficiency
- **Test Data**: 20 documents for batch, same 20 for sequential
- **Test Steps**:
  1. Process 20 documents via batch_convert (single request)
  2. Measure total time
  3. Process same 20 documents sequentially (20 separate requests)
  4. Measure total time
  5. Calculate efficiency gain (batch should be faster)
- **Expected Result**: Batch processing ≥30% faster than sequential
- **Pass Criteria**: Batch time ≤ 0.7 * sequential time (30%+ speedup)
- **Validation Method**: Time comparison, efficiency calculation
- **Automated**: pytest performance test `tests/performance/test_batch_efficiency.py`

#### 6. Chaos Engineering Test Scenarios

**TC-CHAOS-001: LiteLLM Service Unavailable**
- **Scenario**: Test graceful degradation when LiteLLM is down
- **Test Data**: Document for conversion (Stage 1), document for knowledge graph (Stage 2)
- **Test Steps**:
  1. Stop LiteLLM service (or block network access)
  2. Attempt document conversion (should succeed - Stage 1 independent)
  3. Attempt knowledge graph generation (should fail gracefully)
  4. Verify error message indicates LiteLLM unavailable
  5. Restart LiteLLM
  6. Retry knowledge graph generation (should succeed)
- **Expected Result**: Stage 1 works, Stage 2 fails gracefully with diagnostic error, service recovers after LiteLLM restart
- **Pass Criteria**: Conversion succeeds, knowledge graph fails with clear error, service remains healthy, recovery successful
- **Validation Method**: Service health check during failure, error message validation, recovery verification
- **Automated**: pytest chaos test with service manipulation `tests/chaos/test_litellm_failure.py`

**TC-CHAOS-002: Qdrant Service Unavailable**
- **Scenario**: Test graceful degradation when Qdrant is down
- **Test Data**: Document for knowledge graph generation
- **Test Steps**:
  1. Stop Qdrant service
  2. Attempt knowledge graph generation
  3. Verify error indicates Qdrant unavailable (no crash)
  4. Check service health status (should be degraded, not unhealthy)
  5. Restart Qdrant
  6. Retry knowledge graph generation (should succeed)
- **Expected Result**: Knowledge graph generation fails with Qdrant error, service degraded but operational, recovery successful
- **Pass Criteria**: Error raised with Qdrant diagnostic, service health = degraded, recovery after Qdrant restart
- **Validation Method**: Error message validation, health check monitoring, recovery test
- **Automated**: pytest chaos test `tests/chaos/test_qdrant_failure.py`

**TC-CHAOS-003: Redis Service Unavailable**
- **Scenario**: Test graceful degradation when Redis is down
- **Test Data**: Session-based workflow (create session, upload document)
- **Test Steps**:
  1. Stop Redis service
  2. Attempt to create session (should fail gracefully)
  3. Attempt document conversion without session (should succeed - stateless mode)
  4. Check service health (should be degraded)
  5. Restart Redis
  6. Create session (should succeed)
- **Expected Result**: Session operations fail gracefully, stateless operations succeed, service degraded, recovery successful
- **Pass Criteria**: Session creation fails with Redis error, stateless conversion succeeds, health = degraded, recovery verified
- **Validation Method**: Error handling validation, stateless mode verification, recovery test
- **Automated**: pytest chaos test `tests/chaos/test_redis_failure.py`

**TC-CHAOS-004: Multiple Dependency Failures**
- **Scenario**: Test service behavior when multiple dependencies fail simultaneously
- **Test Data**: Document processing request
- **Test Steps**:
  1. Stop LiteLLM, Qdrant, and Redis simultaneously
  2. Attempt various MCP tool invocations
  3. Verify service health = unhealthy (all critical dependencies down)
  4. Check only stateless document conversion works
  5. Restart all dependencies
  6. Verify full recovery
- **Expected Result**: Service unhealthy, only stateless operations work, full recovery after all dependencies restart
- **Pass Criteria**: Health = unhealthy, minimal functionality preserved, recovery after dependency restart
- **Validation Method**: Health check monitoring, capability testing during failure, recovery verification
- **Automated**: pytest chaos test `tests/chaos/test_multiple_dependency_failures.py`

**TC-CHAOS-005: Network Partition to Ollama Servers**
- **Scenario**: Test behavior when Ollama servers unreachable (network partition)
- **Test Data**: Document for entity extraction
- **Test Steps**:
  1. Simulate network failure to Ollama1/2 (stop service or disconnect)
  2. Attempt knowledge graph generation
  3. Verify LiteLLM timeout/error propagated correctly
  4. Check service doesn't crash
  5. Restore network access
  6. Retry (should succeed)
- **Expected Result**: Entity extraction fails with timeout error, service operational, recovery successful
- **Pass Criteria**: Error indicates model timeout, service health = degraded, recovery after network restoration
- **Validation Method**: Error message validation, timeout measurement, recovery test
- **Automated**: pytest chaos test with network manipulation `tests/chaos/test_ollama_network_partition.py`

**TC-CHAOS-006: Service Crash and Auto-Restart**
- **Scenario**: Test systemd auto-restart after service crash
- **Test Data**: N/A (crash triggered deliberately)
- **Test Steps**:
  1. Trigger service crash (e.g., send SIGKILL)
  2. Verify systemd restarts service automatically
  3. Check service healthy after restart
  4. Process test document (verify functionality)
  5. Trigger crash 3 more times (exceed systemd restart limit)
  6. Verify service enters failed state after 3 restarts
- **Expected Result**: Service auto-restarts after crash, remains healthy, enters failed state after 3 crashes (systemd limit)
- **Pass Criteria**: Auto-restart successful, functionality restored, failed state after 3 restarts
- **Validation Method**: Systemd status monitoring, service health check, restart count tracking
- **Automated**: pytest chaos test with service manipulation `tests/chaos/test_auto_restart.py`

**TC-CHAOS-007: Disk Space Exhaustion**
- **Scenario**: Test service behavior when disk space low
- **Test Data**: Large documents (fill disk cache)
- **Test Steps**:
  1. Fill disk to 95% capacity (document cache)
  2. Attempt document processing
  3. Verify error indicates disk space issue
  4. Check service doesn't crash
  5. Clean up cache (free space)
  6. Retry (should succeed)
- **Expected Result**: Processing fails with disk space error, service operational, recovery after cleanup
- **Pass Criteria**: Error raised with disk diagnostic, service health = degraded, recovery after cleanup
- **Validation Method**: Disk monitoring, error validation, recovery test
- **Automated**: pytest chaos test with disk fill `tests/chaos/test_disk_exhaustion.py`

**TC-CHAOS-008: Dependency Slow Response (Timeout Handling)**
- **Scenario**: Test timeout handling when dependencies respond slowly
- **Test Data**: Knowledge graph generation request
- **Test Steps**:
  1. Configure mock LiteLLM with 120-second response delay (exceeds 60s timeout)
  2. Attempt entity extraction
  3. Verify request times out with error
  4. Check service operational (not blocked indefinitely)
  5. Restore normal LiteLLM response time
  6. Retry (should succeed)
- **Expected Result**: Request times out after 60s, error raised, service operational, recovery successful
- **Pass Criteria**: Timeout at 60s (not 120s), error indicates timeout, service responsive, recovery verified
- **Validation Method**: Timeout measurement, error validation, service responsiveness check
- **Automated**: pytest chaos test with mock delays `tests/chaos/test_dependency_timeout.py`

### Test Data Requirements

**Standard Test Corpus** (Required for all test execution):

1. **Sample Documents by Format** (stored in `tests/data/documents/`):
   - `sample-small.pdf` (3 pages, text-only, 1MB)
   - `sample-medium.pdf` (50 pages, mixed content, 20MB)
   - `sample-large.pdf` (200 pages, complex tables, 80MB)
   - `sample-scanned.pdf` (5 pages, scanned image, requires OCR)
   - `sample-complex-table.pdf` (financial report with multi-page tables, merged cells)
   - `sample.docx` (10 pages, rich formatting, embedded images)
   - `sample.pptx` (10 slides, bullet points, speaker notes)
   - `sample.xlsx` (3 sheets, formulas, charts)
   - `sample.html` (web page with semantic tags, links, code blocks)
   - `sample.md` (Markdown document with headers, lists, code blocks)
   - `sample.jpg` (high-quality image with text, requires OCR)
   - `sample-poor-quality.jpg` (low-resolution, poor contrast, OCR challenge)
   - `sample.epub` (ebook with 10 chapters, TOC, metadata)
   - `sample.rtf` (rich text with formatting)
   - `sample-corrupted.pdf` (deliberately corrupted file for error testing)
   - `sample-zero-byte.txt` (empty file for error testing)

2. **Entity-Rich Documents** (for knowledge graph testing, stored in `tests/data/knowledge/`):
   - `research-paper-1.pdf` (AI/ML research paper, 5000 words, 50+ entities)
   - `research-paper-2.pdf` (related AI/ML paper for deduplication testing)
   - `research-paper-3.pdf` (third paper for multi-document graph)
   - `technical-whitepaper.pdf` (10 pages, technical concepts, entity-rich)
   - `contract-sample.pdf` (legal contract with entities: parties, dates, obligations)

3. **Reference Ground Truth** (for accuracy validation, stored in `tests/data/reference/`):
   - `sample-small-text.txt` (extracted text from sample-small.pdf for comparison)
   - `sample-complex-table.csv` (CSV representation of table from PDF)
   - `research-paper-1-entities.json` (manually annotated entities for validation)
   - `research-paper-1-relationships.json` (manually annotated relationships)

4. **Mock Service Responses** (for unit testing, stored in `tests/mocks/`):
   - `litellm-entity-response.json` (mock LiteLLM entity extraction response)
   - `litellm-relationship-response.json` (mock relationship extraction response)
   - `litellm-error-timeout.json` (mock timeout error response)
   - `qdrant-upsert-success.json` (mock Qdrant upsert confirmation)
   - `redis-session-data.json` (mock session metadata)

5. **Performance Benchmark Data** (for performance testing, stored in `tests/data/performance/`):
   - `perf-documents-small/` (100 small documents for latency baseline)
   - `perf-documents-medium/` (50 medium documents for throughput)
   - `perf-documents-large/` (10 large documents for stress testing)
   - `perf-entity-rich/` (10 entity-rich documents for extraction throughput)

**Test Data Preparation**:
- **Pre-Test Setup**: All test data must be available in `tests/data/` before test execution
- **Data Licensing**: Use public domain or Creative Commons licensed documents only (no copyrighted material)
- **Data Privacy**: No real user documents, no sensitive information in test data
- **Data Versioning**: Test corpus versioned with git (baseline for reproducibility)

### Quality Gates

**Pre-Deployment Quality Gates** (All must pass before operational promotion):

**QG-001: Unit Test Coverage**
- **Requirement**: ≥80% code coverage (pytest-cov)
- **Validation**: Run `pytest --cov=docling_mcp --cov-report=term --cov-report=html`
- **Pass Criteria**: Coverage report shows ≥80% overall, ≥90% for critical components (MCP tools, entity extraction)
- **Blocker**: YES - deployment blocked if <80%

**QG-002: Integration Test Success Rate**
- **Requirement**: 100% integration tests pass (all 19 MCP tools operational)
- **Validation**: Run `pytest tests/integration/ -v`
- **Pass Criteria**: 0 failures, 0 errors, all dependency integrations functional
- **Blocker**: YES - deployment blocked if any integration test fails

**QG-003: End-to-End Test Success Rate**
- **Requirement**: 100% E2E tests pass (complete workflows functional)
- **Validation**: Run `pytest tests/e2e/ -v`
- **Pass Criteria**: All E2E scenarios succeed, no workflow failures
- **Blocker**: YES - deployment blocked if any E2E test fails

**QG-004: Multimodal Test Coverage**
- **Requirement**: ≥95% success rate across all document formats
- **Validation**: Run `pytest tests/multimodal/ -v`, calculate success rate
- **Pass Criteria**: ≥95% of format tests pass (e.g., 13/14 formats operational, 1 known limitation acceptable)
- **Blocker**: PARTIAL - critical formats (PDF, DOCX) must pass 100%, non-critical formats (EPUB, RTF) can have 1-2 failures if documented

**QG-005: Performance Benchmarks**
- **Requirement**: Latencies meet NFR-001 targets (p95: small <5s, medium <30s, large <2min)
- **Validation**: Run `pytest tests/performance/test_conversion_latency.py --benchmark-only`
- **Pass Criteria**: 95% of documents meet latency targets for their size category
- **Blocker**: PARTIAL - Must meet targets for small/medium (high frequency), large documents can exceed by ≤20% if documented

**QG-006: Chaos Engineering Resilience**
- **Requirement**: Service survives all chaos scenarios, recovers gracefully
- **Validation**: Run `pytest tests/chaos/ -v`
- **Pass Criteria**: All dependency failure tests pass (graceful degradation), recovery tests succeed
- **Blocker**: YES - deployment blocked if service crashes or fails to recover from dependency failures

**QG-007: Zero Critical Defects**
- **Requirement**: No unresolved critical or high-severity defects
- **Validation**: Review `/home/agent0/HX-Infrastructure/defects/` for hx-docling-mcp defects
- **Pass Criteria**: 0 critical defects, 0 high defects, low/medium defects acceptable if documented and triaged
- **Blocker**: YES - deployment blocked if any critical/high defects unresolved

**QG-008: Documentation Completeness**
- **Requirement**: All governance documents complete (charter, spec, architecture, plan, test-plan, runbook)
- **Validation**: File existence check + peer review completion
- **Pass Criteria**: All required documents present and peer-reviewed
- **Blocker**: YES - deployment blocked if governance docs incomplete

**QG-009: Health Check Validation**
- **Requirement**: Health check endpoint responds within 2s, reports healthy status
- **Validation**: `curl http://hx-docling-mcp-server.hx.dev.local:8000/health` (run 10 times)
- **Pass Criteria**: 10/10 requests succeed, response time <2s, status = "healthy", all dependencies healthy
- **Blocker**: YES - deployment blocked if health check fails or slow

**QG-010: Security Scan (Dependency Vulnerabilities)**
- **Requirement**: No high/critical vulnerabilities in Python dependencies
- **Validation**: Run `pip-audit` or `safety check` on requirements.txt
- **Pass Criteria**: 0 high/critical vulnerabilities, low/medium acceptable if reviewed and documented
- **Blocker**: YES - deployment blocked if high/critical vulnerabilities unpatched

### Continuous Testing Integration

**CI/CD Test Automation** (Future - Phase 2):
- **Pre-Commit Hook**: Run unit tests + linting before commit
- **CI Pipeline**: Run full test suite (unit + integration + E2E) on every commit
- **Nightly Tests**: Performance tests + chaos engineering tests
- **Pre-Deployment Gate**: Full test suite + security scan before operational promotion

**Test Execution Schedule** (Phase 1 - Manual):
- **Unit Tests**: Run daily during development, <5 minutes execution time
- **Integration Tests**: Run after dependency changes, <15 minutes execution time
- **E2E Tests**: Run before deployment, <30 minutes execution time
- **Multimodal Tests**: Run weekly, <1 hour execution time
- **Performance Tests**: Run before deployment + weekly, <2 hours execution time
- **Chaos Tests**: Run before deployment, <30 minutes execution time
- **Soak Test**: Run once before operational promotion, 48 hours duration

### Defect Management Process

**Defect Discovery**: Tests identify defects during execution
**Defect Logging**: Create `defect-hx-docling-mcp-<severity>-<seq>-<desc>.md` in `/home/agent0/HX-Infrastructure/defects/`
**Defect Triage**: Agent Zero or julia-santos assigns severity (critical, high, medium, low)
**Defect Assignment**: Assign to appropriate Technology SME agent based on component
**Defect Resolution**: Developer fixes defect, creates regression test
**Defect Verification**: julia-santos verifies fix with regression test, marks resolved
**Defect Closure**: Update defect record with resolution details, close after validation

### Test Deliverables

**Test Documentation**:
- `test-plan.md`: Comprehensive test strategy, coverage goals, test environments (julia-santos)
- `test-suite-index.md`: Master index of all test cases, execution results, coverage summary
- `test-case-*.md`: Individual test case definitions (63 test cases defined above, each gets dedicated file)
- `test-execution-*.md`: Test run results with pass/fail status, logs, screenshots, evidence

**Test Execution Results**:
- `test-execution-unit-YYYY-MM-DD.md`: Unit test run results
- `test-execution-integration-YYYY-MM-DD.md`: Integration test run results
- `test-execution-e2e-YYYY-MM-DD.md`: End-to-end test run results
- `test-execution-multimodal-YYYY-MM-DD.md`: Multimodal test run results
- `test-execution-performance-YYYY-MM-DD.md`: Performance benchmark results
- `test-execution-chaos-YYYY-MM-DD.md`: Chaos engineering test results
- Defect reports: `defect-*.md` for any test failures (centralized in `/defects`)

**Test Automation**:
- `tests/` directory: Pytest test suite (unit, integration, E2E, multimodal, performance, chaos)
- `tests/conftest.py`: Pytest fixtures (mock services, test data loaders, dependency management)
- `tests/unit/`: Unit tests (12 test files defined above)
- `tests/integration/`: Integration tests (8 test files defined above)
- `tests/e2e/`: End-to-end tests (4 test files defined above)
- `tests/multimodal/`: Format-specific tests (14 test files defined above)
- `tests/performance/`: Performance benchmarks (8 test files defined above)
- `tests/chaos/`: Chaos engineering tests (8 test files defined above)
- `tests/data/`: Test data corpus (documents, reference data, mocks)
- `tests/mocks/`: Mock service responses for unit testing

---

## Documentation Requirements

### Service Documentation

**Governance Documents** (Required for operational promotion):
- ✅ `charter.md`: Project charter (APPROVED)
- ⏳ `node-spec.md`: This specification (DRAFT - awaiting review)
- ⏳ `architecture.md`: Technical architecture design (FUTURE - alex-rivera)
- ⏳ `plan.md`: Deployment plan (FUTURE - william-chen)
- ⏳ `test-plan.md`: Test strategy (FUTURE - julia-santos)

**Technical Documentation**:
- `README.md`: Service overview, quick start guide, MCP tool reference
- `API.md`: MCP tool API reference (auto-generated from Pydantic schemas)
- `INTEGRATION.md`: Integration guide for AI agent developers (MCP client examples)
- `CONFIGURATION.md`: Environment variables, configuration options
- `TROUBLESHOOTING.md`: Common issues, diagnostic procedures, log analysis

**Operational Documentation**:
- `RUNBOOK.md`: Operational procedures (start, stop, restart, health checks)
- `MONITORING.md`: Monitoring guide (metrics, alerts, log interpretation)
- `BACKUP.md`: Backup and recovery procedures (Qdrant snapshots, Redis dumps)
- `UPGRADE.md`: Upgrade procedures (Python packages, Docling library, FastMCP)

**Developer Documentation**:
- `CONTRIBUTING.md`: Development guide (local setup, testing, code standards)
- `ARCHITECTURE.md`: Technical architecture deep dive (component diagrams, data flows)
- `CHANGELOG.md`: Version history, release notes

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (no specific commands, exact file paths, detailed configs)
- [x] Focused on service requirements and operational needs (WHAT and WHY, not HOW)
- [x] Written for infrastructure team and agents (clear, structured, comprehensive)
- [x] All mandatory sections completed (Service Purpose, Requirements, Node Requirements, Dependencies, Security, Monitoring, Success Criteria)

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers (all assumptions clarified via charter and research)
- [x] Requirements are testable and unambiguous (all FRs have validation criteria)
- [x] Success criteria are measurable (all SCs have quantitative targets)
- [x] Scope is clearly bounded (Stages 1-2 in scope, Stages 3-5 out of scope for Phase 1)
- [x] Dependencies identified and validated (all 6 services operational, confirmed in charter)
- [x] Node requirements specified (hx-docling-mcp-server, hx-docling-mcp-server.hx.dev.local, resource allocations)
- [x] Security requirements defined (network-level security, Phase 1 no authentication, Ansible Vault for secrets)
- [x] Monitoring requirements clear (health checks, metrics, logging, alerting)

### Infrastructure Alignment
- [x] Aligns with HX Infrastructure constitution (Charter validation: COMPLIANT with all 8 principles)
- [x] Node capacity verified (Charter confirms node allocated: hx-docling-mcp-server.hx.dev.local)
- [x] Network topology considered (hx.dev.local internal network isolation, no firewalls per HX-Infrastructure policy)
- [x] Naming conventions followed (hx-docling-mcp-server, service naming standards)
- [x] Bare-metal deployment philosophy (systemd service management, no Docker for production)
- [x] Manual procedures (no Ansible playbooks for deployment, runbooks for operations)
- [x] Ansible Vault for secrets (credentials stored in vault, not in code/docs)

### Specification Quality
- [x] Charter alignment (all charter requirements translated to spec)
- [x] Research integration (8 knowledge vault repos researched, findings incorporated)
- [x] Architecture coherence (3-layer architecture, clear component boundaries)
- [x] Integration clarity (all upstream/downstream services documented)
- [x] MCP protocol compliance (19 tools specified, schema examples provided)
- [x] Testing strategy comprehensive (6 test categories, coverage targets)
- [x] Documentation plan complete (governance, technical, operational docs listed)

---

## Execution Status

**Specification Development Progress**:
- [x] Charter reviewed completely (740 lines, approved status confirmed)
- [x] Service purpose defined (document processing + knowledge graph via MCP)
- [x] Requirements generated (28 FRs, 17 NFRs, comprehensive coverage)
- [x] Dependencies identified (6 internal services, all operational)
- [x] Node requirements specified (hx-docling-mcp-server, resource allocations)
- [x] Security requirements defined (network-level, Ansible Vault, Phase 2 OAuth2)
- [x] Monitoring requirements clear (health checks, metrics, logging, alerting)
- [x] Success criteria defined (10 SCs with validation methods)
- [x] Architecture overview created (3-layer architecture, component breakdown, data flows)
- [x] MCP tools specification (19 tools across 3 categories, schema examples)
- [x] Testing strategy outlined (6 test categories, coverage targets)
- [x] Documentation requirements listed (governance, technical, operational)
- [x] Review checklist completed (content quality, requirement completeness, infrastructure alignment)

**Next Steps**:
1. **Specification Review** (alex-rivera → Team review → CAIO approval)
2. **Architecture Design** (alex-rivera creates architecture.md with detailed component design)
3. **Test Planning** (julia-santos creates test-plan.md with test suite structure)
4. **Deployment Planning** (william-chen creates plan.md with deployment procedures)

---

## Related Documentation

**Project Governance**:
- [Charter](/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md) - Project vision, scope, timeline (APPROVED)
- [RAIDD Log](/home/agent0/HX-Infrastructure/raidd-log.md) - Risks, assumptions, issues, dependencies, decisions
- [Status Report](/home/agent0/HX-Infrastructure/status-report.md) - Project status tracking

**Templates**:
- [Service Spec Template](/home/agent0/HX-Infrastructure/templates/service-spec-template.md) - This template
- [Service Architecture Template](/home/agent0/HX-Infrastructure/templates/service-architecture-template.md) - Next phase
- [Service Plan Template](/home/agent0/HX-Infrastructure/templates/service-plan-template.md) - Deployment plan
- [Test Plan Template](/home/agent0/HX-Infrastructure/templates/testing/test-plan-template.md) - Test strategy

**Standards**:
- [Constitution](/home/agent0/HX-Infrastructure/constitution.md) - Project principles
- [Architecture Standards](/home/agent0/HX-Infrastructure/standards/architecture-standards.md) - Architecture governance
- [Documentation Requirements](/home/agent0/HX-Infrastructure/standards/documentation-requirements.md) - Documentation standards
- [Testing Requirements](/home/agent0/HX-Infrastructure/standards/testing-requirements.md) - Testing standards
- [Deployment Requirements](/home/agent0/HX-Infrastructure/standards/deployment-requirements.md) - Deployment philosophy

**Knowledge Resources**:
- [docling-mcp Research](/home/agent0/HX-Infrastructure/hx-knowledge/repos/docling-mcp/) - MCP server implementation research
- [fastmcp-main Research](/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastmcp-main/) - FastMCP framework research
- [docling-main Research](/home/agent0/HX-Infrastructure/hx-knowledge/repos/docling-main/) - Docling library research
- [LightRAG-main Research](/home/agent0/HX-Infrastructure/hx-knowledge/repos/LightRAG-main/) - LightRAG framework research

---

## Specification Metadata

**Document Version**: 1.0 (Initial Draft)
**Created By**: alex-rivera (Platform Architect)
**Created Date**: 2025-11-25
**Status**: Draft (Awaiting Review)
**Review Cycle**: Specification Review → Architecture Design → Team Review → CAIO Approval
**Approval Required**: CAIO (Jarvis Richardson)
**Charter Reference**: [charter.md](/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/charter/charter.md) (Status: APPROVED)

**Review Assignments**:
- **Platform Architect** (alex-rivera): Architecture alignment, technical feasibility
- **Testing Lead** (julia-santos): Testability, success criteria, quality metrics
- **Infrastructure Lead** (william-chen): Deployment feasibility, resource requirements, operational readiness
- **MCP Specialist** (david-martinez): MCP protocol compliance, tool design
- **CAIO** (Jarvis Richardson): Final approval authority

**Estimated Review Duration**: 3-5 days
**Target Approval Date**: 2025-12-05 (per charter milestone)

---

## Specification Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-25 | alex-rivera | Initial specification draft based on approved charter, 8-repo research findings, and technical decision synthesis |
| 0.4 | 2025-11-26 | alex-rivera | Synthesis completion: Integrated 5 enhancement documents (Docling Processing, LightRAG Extraction, LightRAG Configuration, LiteLLM Integration, MCP Tools), updated cross-references, validated quality |

---

**Specification Version**: 1.0
**Last Updated**: 2025-11-26
**Maintained By**: alex-rivera (Platform Architect)
**Contributors**: albert-singh, andy-taylor, marcus-johnson, shane-black, james-rodriguez
**Lifecycle Phase**: Phase 2 (Specification Development)
**Repository**: <https://github.com/Hana-X-AI/HX-Infrastructure.git>
**Document Path**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/node-spec.md`
