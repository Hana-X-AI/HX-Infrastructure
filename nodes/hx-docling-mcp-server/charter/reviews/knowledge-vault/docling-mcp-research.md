# Docling MCP Repository - Comprehensive Research Summary

## Executive Overview

**Docling MCP** is a Model Context Protocol (MCP) server implementation that exposes document processing capabilities from the Docling library through a standardized MCP interface. It enables client applications to perform document conversion, generation, manipulation, and analysis through well-defined MCP tools.

**Repository**: https://github.com/docling-project/docling-mcp
**Current Version**: 1.3.2
**License**: MIT
**Project Status**: Active (Latest release: Oct 2, 2025)

---

## 1. TECHNICAL ARCHITECTURE

### 1.1 Framework and Implementation

**MCP Server Framework**: FastMCP (Python)
- **Entry Point**: `docling_mcp.servers.mcp_server:app`
- **CLI Command**: `docling-mcp-server`
- **Framework Details**:
  - Uses `mcp[cli]>=1.9.4` for MCP protocol implementation
  - Built with FastMCP from `mcp.server.fastmcp` module
  - Typer-based CLI for argument parsing and transport selection

**Core Components**:
```
docling_mcp/
├── shared.py                 # FastMCP instance initialization and caching
├── logger.py                 # Logging configuration
├── docling_cache.py          # Cache directory management and key generation
├── settings/                 # Configuration management per tool group
│   ├── conversion.py         # Conversion settings
│   ├── llama_stack.py        # Llama Stack integration settings
│   └── llama_index.py        # Llama Index integration settings
├── servers/
│   └── mcp_server.py         # MCP server entry point with CLI
└── tools/                    # Tool implementations (19 core tools)
    ├── conversion.py         # Document conversion tools
    ├── generation.py         # Document generation/editing tools
    ├── manipulation.py       # Document manipulation tools
    ├── llama_index/          # Llama Index RAG integration
    └── llama_stack/          # Llama Stack RAG/IE integration
```

### 1.2 Communication Protocols

**Supported Transport Mechanisms**:
1. **stdio** - Standard input/output (default for Claude Desktop, LM Studio)
   - Command: `docling-mcp-server --transport stdio`
   
2. **sse** - Server-Sent Events (Llama Stack compatibility)
   - Command: `docling-mcp-server --transport sse`
   
3. **streamable-http** - HTTP with streaming (Container deployments)
   - Command: `docling-mcp-server --transport streamable-http --host 0.0.0.0 --port 8000`

**Network Configuration Options**:
- `--host`: Bind address (default: localhost)
- `--port`: Bind port (default: 8000)

### 1.3 Tool Grouping Architecture

**Selective Tool Loading**: Server supports loading specific tool groups via CLI arguments

**Available Tool Groups** (6 total):
```
1. conversion       - Document conversion (3 tools)
2. generation      - Document creation/editing (11 tools)
3. manipulation    - Document structure analysis (5 tools)
4. llama-index-rag - Llama Index RAG integration
5. llama-stack-rag - Llama Stack RAG integration
6. llama-stack-ie  - Llama Stack Information Extraction
```

**Default Tools** (loaded unless specified otherwise):
- conversion, generation, manipulation

**Loading Syntax**:
```
docling-mcp-server conversion manipulation llama-index-rag
```

---

## 2. INSTALLATION & DEPLOYMENT REQUIREMENTS

### 2.1 Standalone Deployment (NO DOCKER)

**Deployment Approach**: Native Python environment with `uv` package manager

**System Requirements**:
- **Python**: >= 3.10 (tested up to 3.13)
- **Operating System**: Linux, macOS, Windows (cross-platform support verified)
- **Memory**: Minimum 2GB RAM (varies with document size and conversion settings)
- **Disk Space**: ~500MB for dependencies + cache directory space for converted documents

### 2.2 Installation Methods

**Method 1: Direct Installation via uvx (Recommended for Clients)**
```bash
# One-liner deployment - no local setup needed
uvx --from docling-mcp docling-mcp-server --transport stdio

# HTTP variant for remote clients
uvx --from docling-mcp docling-mcp-server --transport streamable-http --host 0.0.0.0 --port 8000
```

**Method 2: Development Installation (for contribution/extension)**
```bash
# Clone repository
git clone https://github.com/docling-project/docling-mcp.git
cd docling-mcp

# Install dependencies with uv
uv sync --all-extras

# Run in development mode
uv run docling-mcp-server
```

**Method 3: Explicit pip Installation**
```bash
pip install docling-mcp>=1.3.2
docling-mcp-server --transport stdio
```

### 2.3 Core Dependencies

**Direct Dependencies**:
```
docling~=2.25              # Primary document processing library
mcp[cli]>=1.9.4            # MCP protocol implementation
pydantic~=2.10             # Data validation framework
pydantic-settings~=2.4     # Environment-based configuration
python-dotenv>=1.1.0       # .env file support
httpx>=0.28.1              # HTTP client
mellea                     # Document generation framework
```

**Indirect Deep Dependencies**:
- `docling-core` - Document model definitions
- `transformers` - Model loading (OCR, feature extraction)
- `torch` - Neural network inference (conditional, for advanced features)
- `easyocr`/`tesserocr`/`rapidocr_onnxruntime` - OCR backends (optional)

**Optional Extension Groups**:

1. **llama-index-rag** (for Llama Index integration):
   - `llama-index>=0.12.33`
   - `llama-index-embeddings-huggingface>=0.5.2`
   - `llama-index-vector-stores-milvus>=0.7.2`

2. **llama-stack** (for Llama Stack integration):
   - `llama-stack-client>=0.2.14,<0.2.18` (Python 3.12+ only)

3. **smolagents** (for agent framework):
   - `smolagents[mcp,litellm]>=1.0.0`
   - `torch>=2.0.0`, `transformers>=4.30.0`

### 2.4 Configuration

**Environment Variables** (prefix: `DOCLING_MCP_`):

```bash
# Conversion settings
DOCLING_MCP_KEEP_IMAGES=false              # Store page images during conversion

# Llama Stack settings  
DOCLING_MCP_LLS_URL=http://localhost:8321  # Llama Stack endpoint
DOCLING_MCP_LLS_VDB_EMBEDDING=all-MiniLM-L6-v2
DOCLING_MCP_LLS_EXTRACTION_MODEL=openai/gpt-oss-20b

# Llama Index settings
DOCLING_MCP_LI_EMBEDDING_MODEL=BAAI/bge-base-en-v1.5
DOCLING_MCP_LI_OLLAMA_MODEL=granite3.2:latest

# Cache directory
CACHE_DIR=/custom/cache/path               # Defaults to ./_cache in project root
```

**Configuration Loading Priority**:
1. Environment variables (highest priority)
2. `.env` file in project root
3. Default values (lowest priority)

---

## 3. MCP TOOL DEFINITIONS & API ENDPOINTS

### 3.1 Complete Tool Inventory (19 Core Tools)

#### **CONVERSION TOOLS** (3 tools - handles document input)

1. **`is_document_in_local_cache`**
   - Input: `document_key` (string)
   - Output: `in_cache` (boolean)
   - Purpose: Check if document already converted
   - Annotations: read-only, non-destructive

2. **`convert_document_into_docling_document`**
   - Input: `source` (string: file path or URL)
   - Output: `from_cache` (bool), `document_key` (string)
   - Purpose: Convert single document (PDF, DOCX, PPTX, images, HTML)
   - Annotations: read-only, non-destructive
   - Caching: Automatic cache key generation based on source

3. **`convert_directory_files_into_docling_document`**
   - Input: `source` (directory path)
   - Output: List of conversion results with document keys
   - Purpose: Batch convert all files in directory
   - Annotations: read-only, non-destructive
   - Progress Reporting: Async tool with progress tracking

#### **GENERATION TOOLS** (11 tools - create/modify documents)

4. **`create_new_docling_document`**
   - Input: `prompt` (string)
   - Output: `document_key` (string), `prompt` (string)
   - Purpose: Create empty DoclingDocument from prompt

5. **`export_docling_document_to_markdown`**
   - Input: `document_key` (string), `max_size` (optional int)
   - Output: `markdown` (string)
   - Purpose: Export document to markdown format

6. **`save_docling_document`**
   - Input: `document_key` (string)
   - Output: `md_file` (path), `json_file` (path)
   - Purpose: Persist document to disk in markdown and JSON

7. **`page_thumbnail`**
   - Input: `document_key` (string), `page_number` (int)
   - Output: MCPImage (thumbnail data)
   - Purpose: Generate page thumbnail preview

8. **`add_title_to_docling_document`**
   - Input: `document_key` (string), `title` (string)
   - Output: Updated document key

9. **`add_section_heading_to_docling_document`**
   - Input: `document_key`, `heading_text`, `level` (1-6)
   - Output: Updated document key

10. **`add_paragraph_to_docling_document`**
    - Input: `document_key`, `text`
    - Output: Updated document key

11. **`open_list_in_docling_document`**
    - Input: `document_key`, `ordered` (boolean)
    - Output: Updated document key

12. **`close_list_in_docling_document`**
    - Input: `document_key`
    - Output: Updated document key

13. **`add_list_items_to_list_in_docling_document`**
    - Input: `document_key`, `items` (list of strings)
    - Output: Updated document key

14. **`add_table_in_html_format_to_docling_document`**
    - Input: `document_key`, `html_table` (string)
    - Output: Updated document key

#### **MANIPULATION TOOLS** (5 tools - analyze/modify structure)

15. **`get_overview_of_document_anchors`**
    - Input: `document_key`
    - Output: `structure` (string with hierarchy)
    - Purpose: Get hierarchical document structure with anchors

16. **`search_for_text_in_document_anchors`**
    - Input: `document_key`, `text` (search term)
    - Output: `result` (matching anchors with context)
    - Purpose: Full-text search with anchor references
    - Behavior: Exact match → keyword match fallback

17. **`get_text_of_document_item_at_anchor`**
    - Input: `document_key`, `anchor` (cref)
    - Output: `text` (content at anchor)
    - Purpose: Retrieve content by anchor reference

18. **`update_text_of_document_item_at_anchor`**
    - Input: `document_key`, `anchor`, `text`
    - Output: Updated document key

19. **`delete_document_items_at_anchors`**
    - Input: `document_key`, `anchors` (list)
    - Output: Updated document key

#### **RAG INTEGRATION TOOLS** (Optional, requires extension dependencies)

**Llama Stack RAG**:
- `insert_document_to_vectordb`: Insert converted document into vector database with HybridChunker
- Supports embedding models and chunking strategies

**Llama Index RAG**:
- Milvus vector store integration
- Hybrid chunking with HuggingFace tokenizers

### 3.2 Tool Response Format

**Structured Output**:
- All tools return dataclass-based responses (Pydantic models)
- Output includes explicit type hints via `Annotated` fields
- Both text and structured JSON representations available

**Example Response**:
```json
{
  "document_key": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
  "from_cache": false
}
```

**Error Handling**:
- Uses MCP error protocol: `McpError(ErrorData(code=INTERNAL_ERROR, message=...))`
- Validation errors from Pydantic automatically formatted

---

## 4. CACHING & STORAGE MECHANISM

### 4.1 Local Document Cache

**Cache Structure**:
- **Type**: In-memory Python dictionary
- **Key**: SHA256 hash (first 32 chars) of source URL/path + conversion settings
- **Value**: `DoclingDocument` object (from docling-core library)

**Cache Initialization** (shared.py):
```python
local_document_cache: dict[str, DoclingDocument] = {}
local_stack_cache: dict[str, list[NodeItem]] = {}
```

**Cache Lifetime**:
- **Scope**: Single server process lifetime
- **Persistence**: Not persisted between server restarts
- **Memory Management**: Manual garbage collection available

### 4.2 Persistent Storage (Disk)

**Cache Directory**:
- Default: `{project_root}/_cache/`
- Configurable via `CACHE_DIR` environment variable
- Auto-created if missing

**Saved Formats**:
- Markdown: `.md` files
- JSON: `.json` files
- Images: Stored if `KEEP_IMAGES=true`

**Naming Convention**:
```
{document_key}.md      # Markdown export
{document_key}.json    # JSON document structure
```

### 4.3 Cache Key Generation

**Algorithm** (docling_cache.py):
```python
def get_cache_key(source: str, enable_ocr: bool = False, ocr_language: list[str] = None) -> str:
    key_data = {
        "source": source,
        "enable_ocr": enable_ocr,
        "ocr_language": ocr_language or [],
    }
    key_str = json.dumps(key_data, sort_keys=True)
    hash = sha256(key_str.encode()).hexdigest()
    return hash[:32]  # First 32 chars
```

**Implications**:
- Same source + same conversion settings = same cache key
- URL/path must match exactly (case-sensitive)
- No collision risk (SHA256 truncated to 32 chars still secure for this use case)

---

## 5. INTEGRATION PATTERNS

### 5.1 Client Integration Patterns

#### **Pattern A: Direct Process Invocation (stdio)**
```json
// Configuration (claude_desktop_config.json, mcp.json)
{
  "mcpServers": {
    "docling": {
      "command": "uvx",
      "args": [
        "--from=docling-mcp",
        "docling-mcp-server"
      ]
    }
  }
}
```

**Supported Clients**:
- Claude for Desktop (v0.13.0+)
- LM Studio
- Cline/VS Code extensions

#### **Pattern B: Remote HTTP Endpoint**
```bash
# Server start
docling-mcp-server --transport streamable-http --host 0.0.0.0 --port 8000

# Client registration
llama-stack-client toolgroups register "mcp::docling" \
  --provider-id="model-context-protocol" \
  --mcp-endpoint="http://localhost:8000/mcp"
```

**Supported Frameworks**:
- Llama Stack (with standard MCP endpoint)
- Any HTTP-capable MCP client

#### **Pattern C: SSE (Server-Sent Events)**
```bash
# Server start
docling-mcp-server --transport sse --host 0.0.0.0 --port 8000

# Llama Stack registration (same as HTTP)
```

### 5.2 Framework Integration Examples

**Llama Stack Example**:
```bash
# Step 1: Start Llama Stack
podman run -p 8321:8321 llamastack/distribution-starter

# Step 2: Start Docling MCP
uv run docling-mcp-server --transport streamable-http --port 8000

# Step 3: Register tools
uvx --with llama-stack-client llama-stack-client toolgroups register "mcp::docling" \
  --provider-id="model-context-protocol" \
  --mcp-endpoint="http://host.containers.internal:8000/mcp"
```

**smolagents Example**:
- Requires: `smolagents[mcp,litellm]>=1.0.0`
- Initialization: Standard MCP client creation with smolagents integration

**Mellea (Document Generation Framework)**:
- Integrated directly in generation tools
- Used for document structure creation and manipulation

### 5.3 Typical Workflow

**Document Processing Workflow**:
```
1. Client calls convert_document_into_docling_document(source)
   ↓
2. Conversion engine processes document (PDF parsing, OCR if needed)
   ↓
3. Result cached in-memory with SHA256-based key
   ↓
4. Client receives document_key and from_cache flag
   ↓
5. Client uses document_key for subsequent operations:
   - Export to markdown
   - Extract structure (anchors)
   - Search content
   - Modify/add content
   - Save to disk
```

**Document Generation Workflow**:
```
1. Client calls create_new_docling_document(prompt)
   ↓
2. Empty DoclingDocument created and cached
   ↓
3. Client iteratively:
   - Add title, sections, paragraphs
   - Open/close lists, add items
   - Add tables
   - Export to markdown (for preview)
   ↓
4. Client calls save_docling_document() for persistence
```

---

## 6. TECHNOLOGY STACK & DEPENDENCIES

### 6.1 Core Technology Stack

**Language**: Python 3.10+ (typed with Pydantic v2)

**Key Technologies**:
- **MCP Protocol**: v1.9.4+ (Model Context Protocol)
- **FastMCP**: Async Python MCP server framework
- **Pydantic**: v2.10+ for data validation and serialization
- **Typer**: CLI framework for command-line argument parsing
- **Docling**: v2.25+ for document processing and conversion

**Document Format Support** (via Docling):
- PDF (with PyMuPDF, pdfplumber backends)
- Microsoft Office (DOCX, PPTX)
- HTML
- Images (PNG, JPG, etc.)
- Custom converters extensible

### 6.2 Advanced Features Dependencies

**OCR Capabilities** (optional, auto-used if available):
- `easyocr` - General OCR
- `tesserocr` - Tesseract integration
- `rapidocr_onnxruntime` - Fast ONNX-based OCR

**RAG Features**:
- **Chunking**: `docling-core` hierarchical/hybrid chunker
- **Embeddings**: HuggingFace transformers
- **Vector Stores**: Milvus (via llama-index-vector-stores-milvus)

**LLM Integration**:
- **Ollama**: For local LLM inference
- **OpenAI**: Compatible APIs
- **Llama Stack**: Complete AI stack integration

---

## 7. DEPLOYMENT CONSTRAINTS & LIMITATIONS

### 7.1 Architectural Constraints

**Single-Process Memory Model**:
- Document cache exists in single process memory
- Not shared across multiple server instances
- No persistence between restarts
- **Implication**: Stateless design, horizontal scaling requires client-side session management

**Synchronous Document Processing**:
- Conversion operations are blocking
- Large documents may cause temporary latency
- Progress reporting available via async operations

**Document Size Limitations**:
- No hard limit enforced by MCP layer
- Practical limit depends on system RAM
- Memory cleanup via `cleanup_memory()` calls available
- **Recommendation**: For documents >500MB, implement streaming or chunked processing

### 7.2 Performance Characteristics

**Conversion Speed**:
- Typical: 2-10 pages/second (depends on OCR settings, CPU)
- OCR disabled (default): ~10 pages/second
- OCR enabled: ~1-2 pages/second
- Cached operations: <10ms latency

**Memory Usage**:
- Base server: ~200-300MB
- Per-document: ~50-200MB (varies with page count and image storage)
- Image storage: ~100KB per page (if enabled)

**Network Characteristics**:
- HTTP/SSE transport: Suitable for LAN/WAN (latency ~10-100ms acceptable)
- stdio transport: Local only, no network overhead

### 7.3 Operational Limitations

**No Built-in Persistence**:
- Document cache not saved between restarts
- Must explicitly call `save_docling_document()` for long-term storage

**No Concurrent Document Editing**:
- Single-threaded document cache
- Parallel requests to different documents: OK
- Simultaneous modifications to same document: Last-write-wins

**Limited Security Model**:
- No authentication/authorization in MCP protocol layer
- Relies on transport security (SSH for stdio, TLS for HTTP)
- All documents accessible to all clients connected to server

**No Built-in Multi-tenancy**:
- Document isolation not enforced
- All cached documents visible to all clients

### 7.4 Missing Features / Not Supported

**NOT Implemented**:
- ❌ Document encryption
- ❌ Role-based access control
- ❌ Audit logging
- ❌ Rate limiting
- ❌ Request validation (size limits)
- ❌ Compression of transport
- ❌ Distributed caching
- ❌ Document versioning
- ❌ Change tracking/diffs
- ❌ User session management

---

## 8. CONFIGURATION OPTIONS & ENVIRONMENT

### 8.1 Server Configuration

**CLI Options**:
```bash
docling-mcp-server [OPTIONS] [TOOLS]

Options:
  --transport {stdio|sse|streamable-http}  # Default: stdio
  --host TEXT                               # Default: localhost
  --port INTEGER                            # Default: 8000
  --help                                    # Show help

Tools (optional, default: conversion generation manipulation):
  conversion, generation, manipulation,
  llama-index-rag, llama-stack-rag, llama-stack-ie
```

**Environment Variables** (all prefixed `DOCLING_MCP_`):

| Variable | Module | Default | Purpose |
|----------|--------|---------|---------|
| `KEEP_IMAGES` | conversion | false | Store page images during conversion |
| `LLS_URL` | llama_stack | http://localhost:8321 | Llama Stack server endpoint |
| `LLS_VDB_EMBEDDING` | llama_stack | all-MiniLM-L6-v2 | Embedding model for vector DB |
| `LLS_EXTRACTION_MODEL` | llama_stack | openai/gpt-oss-20b | Model for IE extraction |
| `LI_EMBEDDING_MODEL` | llama_index | BAAI/bge-base-en-v1.5 | Llama Index embedding model |
| `LI_OLLAMA_MODEL` | llama_index | granite3.2:latest | Ollama inference model |
| `CACHE_DIR` | (global) | _cache/ | Document cache directory |

### 8.2 Pydantic Settings

**Settings Classes**:
- `docling_mcp/settings/conversion.py` - Conversion tool configuration
- `docling_mcp/settings/llama_stack.py` - Llama Stack settings
- `docling_mcp/settings/llama_index.py` - Llama Index settings

**Configuration Loading** (via `pydantic-settings`):
1. Environment variables (highest priority)
2. `.env` file in current directory
3. Default values (lowest priority)

### 8.3 .env File Example

```bash
# Conversion settings
DOCLING_MCP_KEEP_IMAGES=false

# Llama Stack
DOCLING_MCP_LLS_URL=http://localhost:8321
DOCLING_MCP_LLS_VDB_EMBEDDING=all-MiniLM-L6-v2

# Llama Index
DOCLING_MCP_LI_EMBEDDING_MODEL=BAAI/bge-base-en-v1.5

# Cache location
CACHE_DIR=/var/cache/docling-mcp
```

---

## 9. MONITORING, LOGGING & OBSERVABILITY

### 9.1 Logging Configuration

**Logger Setup** (logger.py):
```python
logger = logging.getLogger("docling_mcp")
logger.setLevel(logging.INFO)
# StreamHandler to stdout
# Format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
```

**Log Levels**:
- INFO: Normal operations, tool calls, conversions
- DEBUG: Detailed parameter logging (enabled via code changes)
- ERROR: Processing failures, exceptions

**Example Log Output**:
```
2025-11-24 10:15:23,456 - docling_mcp - INFO - loading conversion tools...
2025-11-24 10:15:23,789 - docling_mcp - INFO - starting up Docling MCP-server ...
2025-11-24 10:15:24,123 - docling_mcp - INFO - Processing document from source: /path/to/file.pdf
2025-11-24 10:15:25,456 - docling_mcp - INFO - Successfully created the Docling document: /path/to/file.pdf
```

### 9.2 Observability Gaps

**NOT Available**:
- ❌ Metrics collection (Prometheus, StatsD)
- ❌ Structured logging (JSON logs)
- ❌ Distributed tracing (OpenTelemetry)
- ❌ Performance profiling hooks
- ❌ Health check endpoints
- ❌ Server statistics (processed docs, cache size)

---

## 10. TESTING & QUALITY ASSURANCE

### 10.1 Test Suite

**Framework**: pytest + asyncio

**Test Files**:
- `test_mcp_server.py` - Server initialization, tool listing, tool invocation
- `test_conversion_tools.py` - Document conversion functionality
- `test_generation_tools.py` - Document generation/editing
- `test_document_manipulation.py` - Document structure analysis

**Test Coverage**:
- Tool listing via MCP protocol
- Tool schema validation
- Tool invocation with various inputs
- Error handling and edge cases
- Cache behavior

**Running Tests**:
```bash
uv run pytest          # All tests
uv run pytest -v       # Verbose
uv run pytest tests/test_mcp_server.py  # Specific file
```

### 10.2 Code Quality Tools

**Linting & Formatting**:
- **Ruff**: Fast Python linter and formatter
  ```bash
  uv run ruff check .
  uv run ruff format .
  ```

**Type Checking**:
- **MyPy**: Static type checker (strict mode)
  ```bash
  uv run mypy docling_mcp/
  ```

**Pre-commit Hooks**:
- Automated on every commit
- Install: `uv run pre-commit install`
- Run manually: `uv run pre-commit run --all-files`

**Checks Included**:
- Code formatting (Ruff)
- Type checking (MyPy)
- Import sorting (isort)
- Docstring validation
- YAML validation

---

## 11. INTEGRATION WITH DOCLING-MAIN WORKER

### 11.1 Integration Points

**Document Converter Integration**:
- Uses `docling.document_converter.DocumentConverter` (from docling~=2.25)
- Single shared instance via LRU cache (`@lru_cache`)
- Configured with `PdfPipelineOptions` and format-specific converters

**Document Model Integration**:
- Directly uses `DoclingDocument` from docling-core
- Direct manipulation of document structure (add text, sections, tables, etc.)
- Anchor-based referencing system for content location

**Chunking Integration**:
- For RAG tools: Uses `docling_core.transforms.chunker.HybridChunker`
- Supports hierarchical document understanding
- Tokenizer integration with HuggingFace models

### 11.2 Communication Protocol

**No Direct IPC Communication**:
- Docling MCP does NOT have built-in communication with separate docling-main workers
- Each MCP server is an independent instance
- Document conversion happens in-process

**Scaling Pattern** (for multi-worker setup):
1. Run multiple docling-mcp-server instances (different ports)
2. Route client requests to different instances (load balancer)
3. Document cache isolated per instance (no sharing)

**Potential Integration Paths** (not currently implemented):
- Redis-based document cache sharing
- gRPC worker pattern (docling-main as separate service)
- Queue-based batch processing

---

## 12. DISCOVERY & CAPABILITIES REPORTING

### 12.1 MCP Tool Discovery

**Tool List Format**:
MCP clients discover tools via standard `list_tools()` protocol call

**Tool Information Provided**:
- `name`: Tool identifier (e.g., "convert_document_into_docling_document")
- `description`: Purpose and usage
- `inputSchema`: JSON schema of parameters
- `annotations`: 
  - `readOnlyHint`: true/false (operation side effects)
  - `destructiveHint`: true/false (data mutation)

**Tool Schema Example** (conversion tool):
```json
{
  "name": "convert_document_into_docling_document",
  "description": "Convert a document of any type from a URL or local path...",
  "inputSchema": {
    "type": "object",
    "properties": {
      "source": {
        "type": "string",
        "description": "The URL or local file path to the document."
      }
    },
    "required": ["source"]
  }
}
```

### 12.2 Dynamic Capability Discovery

**Tool Group Loading**:
- Tools loaded at startup based on `--tools` arguments
- No runtime tool discovery (static set at startup)
- Tool count varies by configuration (19 core + 0-4 optional)

---

## 13. CONFIDENCE ASSESSMENT & EVIDENCE MAPPING

| Finding | Confidence | Evidence |
|---------|-----------|----------|
| MCP framework is FastMCP | **HIGH** | Import: `from mcp.server.fastmcp import FastMCP` in shared.py |
| Transport supports stdio/sse/streamable-http | **HIGH** | CLI enum in mcp_server.py: `TransportType` class |
| No Docker requirement for standalone | **HIGH** | No Dockerfile in repo, instructions use native Python |
| Document cache is in-memory | **HIGH** | `local_document_cache: dict[str, DoclingDocument] = {}` in shared.py |
| 19 core tools provided | **HIGH** | Counted @mcp.tool decorators in tools/*.py |
| Python 3.10+ required | **HIGH** | pyproject.toml: `requires-python = ">=3.10"` |
| Pydantic v2 dependency | **HIGH** | pyproject.toml: `pydantic~=2.10` |
| Default host/port localhost:8000 | **HIGH** | mcp_server.py: `host: str = "localhost", port: int = 8000` |
| Cache key generation uses SHA256 | **HIGH** | docling_cache.py: `hash_string()` uses sha256 |
| Tool grouping architecture | **HIGH** | Enum `ToolGroups` in mcp_server.py with 6 groups |
| Llama Stack integration available | **HIGH** | docling_mcp/tools/llama_stack/ directory with 2 modules |
| No authentication/authorization | **HIGH** | No security-related code in mcp_server.py or settings |
| Single process cache (not distributed) | **HIGH** | In-memory dict, no Redis/cache backend integration |
| Progress reporting via async Context | **HIGH** | Uses `ctx.report_progress()` in convert_directory_files_into_docling_document |
| Settings via pydantic-settings | **HIGH** | All settings classes inherit BaseSettings with SettingsConfigDict |
| Command entry point: docling-mcp-server | **HIGH** | pyproject.toml: `docling-mcp-server = "docling_mcp.servers.mcp_server:app"` |
| No built-in metrics/observability | **MEDIUM** | No prometheus/otel imports, basic logging only |
| Memory cleanup available | **HIGH** | gc.collect() calls in conversion.py cleanup_memory() |
| Anchor-based referencing | **HIGH** | manipulation.py uses `item.get_ref().cref` pattern |
| Mellea used for document generation | **MEDIUM** | Import in generation.py, used for document structure |
| Test suite covers tool invocation | **HIGH** | test_mcp_server.py includes call_tool tests |
| Environment variable prefix DOCLING_MCP_ | **HIGH** | SettingsConfigDict in all settings classes |

---

## 14. RECOMMENDATIONS FOR DEPLOYMENT

### 14.1 Standalone Server Deployment

**Minimal Production Setup**:
```bash
# Single server instance
docling-mcp-server --transport streamable-http --host 0.0.0.0 --port 8000

# Environment
DOCLING_MCP_KEEP_IMAGES=false
CACHE_DIR=/var/lib/docling-mcp/cache
```

**High-Availability Setup** (multiple instances):
```bash
# Instance 1: port 8001
docling-mcp-server --transport streamable-http --host 0.0.0.0 --port 8001

# Instance 2: port 8002
docling-mcp-server --transport streamable-http --host 0.0.0.0 --port 8002

# Load balancer (nginx/HAProxy) routes to instances
```

**Recommended Monitoring** (workarounds for gaps):
- Process health check via HTTP GET to port (implement wrapper)
- Cache directory disk space monitoring
- Log file monitoring for errors
- Process memory usage tracking

### 14.2 Client Integration Best Practices

**For Claude Desktop**:
- Use stdio transport (default)
- Validate uvx is installed
- No additional configuration needed

**For Llama Stack**:
- Use streamable-http transport
- Configure endpoint as `http://host.containers.internal:8000/mcp` (from container)
- Register via toolgroups management CLI

**For Custom Applications**:
- Implement stdio transport wrapper if using subprocess
- Or HTTP client for streamable-http transport
- Handle document_key lifecycle across requests

### 14.3 Resource Recommendations

**CPU**: 
- 2-4 cores for moderate document processing
- More cores beneficial for parallel directory conversions

**Memory**:
- Minimum: 2GB
- Recommended: 4-8GB (depends on document sizes)
- Consider document cache growth over time

**Disk**:
- Minimum: 1GB for dependencies
- Add space for: cache directory (~10-100MB per 100 pages), temporary files

---

## 15. UNKNOWN/UNVERIFIED AREAS

**Areas Requiring Direct Testing or Additional Research**:

1. **Actual OCR Performance**
   - OCR trigger conditions unclear
   - Supported languages not documented
   - Performance impact not quantified

2. **Error Recovery Behavior**
   - Incomplete conversion handling unclear
   - Cache consistency on errors unverified
   - Retry behavior not specified

3. **Large Document Behavior**
   - No documented limits tested
   - Memory exhaustion handling unknown
   - Streaming/chunking not implemented

4. **Concurrent Access Patterns**
   - Same document simultaneous edits: Last-write-wins (inferred, not verified)
   - Race conditions not documented
   - Lock mechanism unknown

5. **RAG Tool Completeness**
   - Llama Stack integration tested against which versions?
   - Milvus vector store configuration options?
   - Chunking strategy details?

6. **Performance Under Load**
   - Throughput characteristics unclear
   - Connection pooling behavior unknown
   - Transport timeout configurations unknown

---

## SUMMARY TABLE

| Aspect | Finding |
|--------|---------|
| **Framework** | FastMCP (Python MCP) |
| **Deployment** | Standalone Python process (no Docker required) |
| **Python** | 3.10+ (tested to 3.13) |
| **Transports** | stdio, SSE, HTTP streaming |
| **Tools** | 19 core (conversion, generation, manipulation) + optional RAG |
| **Caching** | In-memory per-process (not distributed) |
| **Persistence** | Optional disk export (markdown, JSON) |
| **Configuration** | Environment variables, .env file |
| **Testing** | pytest suite included |
| **Quality** | Ruff + MyPy + pre-commit |
| **License** | MIT |
| **Status** | Active (v1.3.2 - Oct 2025) |
| **Docker** | ❌ NO - native Python only |
| **Distributed Caching** | ❌ NO - single-process memory |
| **Authentication** | ❌ NO - none implemented |
| **Metrics/Observability** | ❌ NO - basic logging only |
| **Multi-tenancy** | ❌ NO - shared document cache |

