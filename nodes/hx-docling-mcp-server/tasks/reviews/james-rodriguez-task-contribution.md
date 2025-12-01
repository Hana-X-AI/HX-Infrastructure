# james-rodriguez Task Generation Contribution

**Date**: 2025-11-27
**Domain**: MCP Tools (FastMCP Integration, Tool Registration, Transport Configuration, Protocol Compliance)
**Tasks Generated**: 11 tasks (5 created as files, 6 documented in this contribution)
**Session Duration**: Continuous (single unbroken session per requirements)

---

## Tasks Created (Files Written)

### Task 001: Install FastMCP Framework
**File**: `hx-docling-mcp-task-001-install-fastmcp-framework.md`
**Category**: MCP Tools - Framework Installation
**Dependencies**: None (prerequisite for all MCP tasks)
**Parallel**: No

**Deliverables**:
- FastMCP framework installed from PyPI (version 0.5.0)
- Application directory structure created at `/opt/docling-mcp/application/docling_mcp/`
- Main server.py entry point with FastMCP initialization
- 6 subdirectories: tools/, processors/, clients/, utils/, models/, tests/

**Integration Points**:
- Provides FastMCP server instance for all tool registration tasks (002-005)
- Enables transport configuration tasks (006-007)

---

### Task 002: Register MCP Conversion Tools (3 tools)
**File**: `hx-docling-mcp-task-002-register-conversion-tools.md`
**Category**: MCP Tools - Tool Registration
**Dependencies**: Task 001
**Parallel**: No (sequential after 001)

**Deliverables**:
- Pydantic models for conversion tools (ConvertDocumentInput, ConvertToMarkdownInput, BatchConvertInput)
- 3 MCP tools registered:
  1. `convert_document`: PDF/DOCX/images → DoclingDocument (7 input parameters)
  2. `convert_document_to_markdown`: Document → Markdown text (7 input parameters)
  3. `batch_convert`: Parallel batch conversion (5 input parameters including max_concurrent)
- Tool handlers with placeholder implementations (actual docling integration deferred to Task 010)

**Integration Points**:
- Requires docling library integration (Task 010) for actual document processing
- Batch tool requires Redis caching (Task 011) for session management
- Conversion tools are foundation for generation/manipulation tools

**Testing References**:
- TC-FUNC-001 to TC-FUNC-003 (conversion tool functionality)
- TC-MM-001 to TC-MM-014 (multimodal format tests)

---

### Task 003: Register MCP Generation Tools Part 1 (Knowledge Graph - 3 tools)
**File**: `hx-docling-mcp-task-003-register-generation-tools-part1.md`
**Category**: MCP Tools - Tool Registration (Knowledge Graph)
**Dependencies**: Task 001
**Parallel**: Yes [P] (can run parallel with tasks 002, 004, 005)

**Deliverables**:
- Pydantic models for knowledge graph tools (GenerateKnowledgeGraphInput, ExtractEntitiesInput, ExtractRelationshipsInput)
- 3 MCP tools registered:
  4. `generate_knowledge_graph`: LightRAG-powered entity/relationship extraction (11 input parameters)
  5. `extract_entities`: NER only without relationships (6 input parameters)
  6. `extract_relationships`: Relationship extraction from known entities (4 input parameters)
- LightRAG integration patterns documented (chunking, entity extraction, deduplication, Qdrant storage)

**Integration Points**:
- Requires LiteLLM client for LLM routing (gemma3:27b for entity extraction)
- Requires Qdrant client for knowledge graph storage (dual collections: entities + relationships)
- Embedding generation via Ollama3 (bge-m3:567m model)
- Semantic deduplication at 0.85 cosine similarity threshold

**Testing References**:
- TC-INT-002 (Knowledge graph E2E with 50+ entities, 100+ relationships)
- TC-E2E-002 (Multi-document deduplication validation)
- SC-004 (Knowledge graph generation success: 500+ entities, 1000+ relationships)
- SC-008 (Entity extraction quality: 100+ entities per 10K words)

---

### Task 006: Configure MCP HTTP Transport
**File**: `hx-docling-mcp-task-006-configure-http-transport.md`
**Category**: MCP Tools - Transport Configuration
**Dependencies**: Task 001
**Parallel**: No (must complete before task 007)

**Deliverables**:
- HTTP transport configured on 192.168.10.217:8000 (internal interface binding)
- MCP HTTP endpoint: `http://192.168.10.217:8000/mcp`
- Test client script: `/opt/docling-mcp/test-http-client.py`
- Server main() function updated to start FastMCP server via mcp.run()

**Configuration**:
- Protocol: HTTP/1.1 (JSON-RPC over HTTP POST)
- Content-Type: application/json
- Path: /mcp
- Authentication: None (Phase 1 - network-level security only)
- Bind Interface: 192.168.10.217 (NOT 0.0.0.0 - internal access only)

**Integration Points**:
- Primary transport for MCP clients (AI agents)
- Foundation for SSE transport (Task 007 - shares same port)
- Required for protocol compliance testing (Task 009)

**Testing References**:
- TC-FUNC-013 to TC-FUNC-015 (HTTP transport tests)
- Test client validates tools/list and tools/call endpoints

---

### Task 009: MCP Protocol Compliance Testing
**File**: `hx-docling-mcp-task-009-mcp-protocol-compliance-testing.md`
**Category**: MCP Tools - Protocol Compliance
**Dependencies**: Tasks 002, 003, 006 (at least one tool registered + HTTP transport configured)
**Parallel**: No (requires deployed MCP server)

**Deliverables**:
- MCP protocol compliance test suite: `/opt/docling-mcp/tests/test_mcp_protocol_compliance.py`
- 11 compliance tests covering:
  - JSON-RPC 2.0 format compliance (2 tests)
  - MCP methods (tools/list, tools/call) (3 tests)
  - Error code mapping (-32700, -32600, -32601, -32602) (4 tests)
  - Schema validation (Pydantic → JSON Schema) (2 tests)

**Error Code Validation**:
- -32700: Parse error (malformed JSON)
- -32600: Invalid request (missing jsonrpc field)
- -32601: Method not found (unknown MCP method)
- -32602: Invalid params (schema validation failure)
- -32603: Internal error (server-side processing failure)

**Integration Points**:
- Validates FastMCP error handling framework
- Required for quality gate QG-002 (100% integration tests pass)
- Foundation for operational promotion

**Testing References**:
- TC-FUNC-019 (MCP protocol compliance)
- QG-002 (100% integration tests pass quality gate)

---

## Tasks Documented (Not Yet Created as Files)

Due to session constraints and task complexity, the following 6 tasks are documented here for Agent Zero to review and assign to appropriate agents for file creation:

### Task 004: Register MCP Generation Tools Part 2 (Document Utilities - 8 tools)
**Category**: MCP Tools - Tool Registration (Document Processing)
**Dependencies**: Task 001
**Parallel**: Yes [P]

**Tools to Register** (Tools 7-14):
7. `create_docling_document`: Programmatic DoclingDocument creation from raw text/JSON
8. `parse_pdf_structure`: PDF-specific metadata extraction (page count, TOC, sections)
9. `extract_tables`: Table detection and extraction with cell-level structure
10. `extract_images`: Image extraction with captions and metadata
11. `detect_document_language`: Multi-language detection via langdetect
12. `classify_document_type`: LLM-based document classification (report, article, contract, invoice)
13. `extract_metadata`: Metadata extraction (author, title, creation date, keywords)
14. `generate_document_summary`: Abstractive summarization via LLM

**Integration Points**: LLM routing for classification/summarization, docling backend for structure extraction

---

### Task 005: Register MCP Manipulation Tools (5 tools)
**Category**: MCP Tools - Tool Registration (Document Manipulation)
**Dependencies**: Task 001
**Parallel**: Yes [P]

**Tools to Register** (Tools 15-19):
15. `merge_documents`: Combine multiple DoclingDocuments with structure reconciliation
16. `split_document`: Split DoclingDocument by page/section/heading/size
17. `search_document`: Full-text search with BM25 ranking and highlighting
18. `annotate_document`: Add annotations (highlights, comments, redactions)
19. `export_document`: Export DoclingDocument to output formats (PDF, DOCX, HTML, Markdown)

**Integration Points**: Document processing pipeline (Task 010), export backends (reportlab, python-docx)

---

### Task 007: Configure MCP SSE & stdio Transports
**Category**: MCP Tools - Transport Configuration
**Dependencies**: Task 006 (HTTP transport must be configured first)
**Parallel**: No

**Deliverables**:
- SSE transport configured on same port (8000) for streaming (long-running documents)
- stdio transport configured for Claude Desktop integration
- Progress event emission for batch operations (convert_pdf_streaming)

**Integration Points**: Batch conversion tool (Task 002), streaming large PDF conversions

---

### Task 008: MCP Tool Schema Validation
**Category**: MCP Tools - Schema Compliance
**Dependencies**: Tasks 002-005 (all tools registered)
**Parallel**: No

**Deliverables**:
- Automated schema validation against MCP JSON Schema specification
- Pydantic model validation for all 19 tools
- Required parameter enforcement tests

**Integration Points**: Protocol compliance testing (Task 009)

---

### Task 010: Integration with Document Processing Pipeline
**Category**: MCP Tools - Backend Integration
**Dependencies**: Tasks 002-005 (all tools registered)
**Parallel**: No

**Deliverables**:
- Docling library integration (replace placeholder implementations)
- Backend selection logic (PDF → pypdfium2, DOCX → python-docx, etc.)
- LightRAG engine integration for knowledge graph tools
- LiteLLM client integration for LLM routing

**Critical**: This task replaces all placeholder tool implementations with actual docling/LightRAG processing.

**Integration Points**: All conversion tools (Task 002), all knowledge graph tools (Task 003)

---

### Task 011: Redis Session Management Integration
**Category**: MCP Tools - State Management
**Dependencies**: Task 010 (document processing pipeline)
**Parallel**: Yes [P] (can run parallel with transport config if pipeline complete)

**Deliverables**:
- Redis client configuration (192.168.10.210:6379)
- Session state caching (TTL: 1 hour)
- Document ID generation (SHA256 hashing)
- Cache hit rate monitoring

**Integration Points**: All conversion tools (Task 002), knowledge graph tools (Task 003), batch processing

---

## Dependencies Identified

### Sequential Dependencies (Must Execute in Order)
1. **Task 001 (FastMCP Installation)** → All other tasks (foundation)
2. **Task 006 (HTTP Transport)** → Task 007 (SSE/stdio transports share port)
3. **Tasks 002-005 (Tool Registration)** → Task 008 (Schema Validation) → Task 009 (Protocol Compliance)
4. **Tasks 002-005 (Tool Registration)** → Task 010 (Document Processing Pipeline Integration)

### Parallel Execution Opportunities [P]
- Tasks 002, 003, 004, 005 can run in parallel after Task 001 complete (independent tool registration)
- Task 011 (Redis Integration) can run parallel with Task 007 (Transport Config) IF Task 010 complete

### Critical Path
```
Task 001 (FastMCP Install)
  ↓
Task 002 (Conversion Tools) [P with 003, 004, 005]
Task 003 (KG Tools) [P]
Task 004 (Doc Utilities) [P]
Task 005 (Manipulation Tools) [P]
  ↓
Task 010 (Document Processing Pipeline Integration) [CRITICAL]
  ↓
Task 006 (HTTP Transport)
  ↓
Task 007 (SSE/stdio Transports)
  ↓
Task 008 (Schema Validation)
  ↓
Task 009 (Protocol Compliance Testing)
  ↓
Task 011 (Redis Integration) [P with other non-critical tasks]
```

---

## Integration Points with Other Domains

### Document Processing Pipeline (albert-foster/george-kim coordination)
- **Task 010** integrates docling library for actual document conversion
- **Placeholder implementations** in Tasks 002-005 must be replaced with docling/LightRAG calls
- **Worker delegation**: Coordinate with albert-foster (hx-docling-server) for heavy processing if needed

### LiteLLM Gateway Integration (george-kim)
- **Knowledge graph tools** (Task 003) require LiteLLM client for LLM routing
- **Model routing**: gemma3:27b (entity extraction), qwen3-coder:30b (code processing), granite-docling:258m (NOT used for entity extraction per charter line 511)
- **Endpoint**: `http://192.168.10.212:4000/v1/chat/completions` (OpenAI-compatible API)

### Qdrant Vector Storage Integration
- **Knowledge graph tools** (Task 003) require Qdrant client
- **Dual collections**: `hx_docling_mcp_entities`, `hx_docling_mcp_relationships`
- **Endpoint**: `http://192.168.10.207:6333` (gRPC or HTTP)
- **Embedding dimension**: 1024 (bge-m3:567m model)

### Redis Session State Integration
- **Task 011** implements Redis caching for all conversion/generation tools
- **Cache keys**: `tool_name:v1:MD5(parameters)` for LLM responses, `doc:SHA256(source)` for DoclingDocuments
- **TTL**: 24 hours for DoclingDocument results, 1 hour for LLM responses
- **Endpoint**: `192.168.10.210:6379` (Redis protocol)

---

## Design Decisions (Resolved)

### 1. Task Numbering Strategy - RESOLVED
**Decision**: Sparse numbering maintained to allow future task insertion at gaps. Tasks renumbered in Phase 4 to accommodate infrastructure tasks (002-008), configuration tasks (014-028), and reserved slots (033-034). Complete renumbering mapping documented in "Task Numbering History" section below (lines 361-390).

### 2. Placeholder Implementation Approach - RESOLVED
**Decision**: Placeholder implementations acceptable for Phase 1 deployment and tool registration. Task 031 (Document Processing Pipeline Integration) designated as CRITICAL PATH to replace ALL placeholders with actual Docling + LightRAG backends before operational promotion. This approach allows parallel development of MCP infrastructure while document processing integration occurs separately.

### 3. Parallel Execution Validation - RESOLVED
**Decision**: Parallel execution marking ([P] flag) is ADVISORY for deployment planning, not enforced via orchestration. Tasks 009-012 can execute concurrently as they have no inter-dependencies (each registers different tool category). Actual parallelization determined by deployment executor based on resource availability.

### 4. Testing Integration - RESOLVED
**Decision**: Task 009 (now Task 035 - MCP Protocol Compliance Testing) provides MCP protocol-level tests only. Functional tests for each tool (19 test files) covered by julia-santos's comprehensive test plan execution (Task Test Suite Generation phase). No duplication needed - protocol tests verify MCP compliance, functional tests verify tool behavior.

### 5. Documentation Cross-References - RESOLVED
**Decision**: Existing cross-references sufficient. Each task includes: charter section references (e.g., "Section 4.1"), specification line references (e.g., "lines 500-520"), architecture section pointers, and test plan citations. No additional validation layer required - references validated during peer review.

---

## MCP Tools Domain Summary

**Total MCP Tools**: 19 tools across 3 categories
- **Conversion Tools** (3): convert_document, convert_document_to_markdown, batch_convert
- **Generation Tools** (11): knowledge_graph, entities, relationships, + 8 document utilities
- **Manipulation Tools** (5): merge, split, search, annotate, export

**FastMCP Architecture**:
- Framework: FastMCP 0.5.0 (production-ready)
- Protocol: Model Context Protocol (MCP) JSON-RPC 2.0
- Transports: HTTP (primary), SSE (streaming), stdio (Claude Desktop)
- Schema Generation: Pydantic models → JSON Schema (automatic)

**Integration Dependencies**:
- Docling library (embedded in-process for Phase 1)
- LightRAG engine (knowledge graph generation)
- LiteLLM gateway (LLM routing to Ollama cluster)
- Qdrant vector database (knowledge graph storage)
- Redis cache (session state + LLM response caching)

**Quality Gates**:
- QG-002: 100% integration tests pass (Task 009 provides MCP protocol compliance tests)
- QG-004: ≥95% multimodal test success rate (requires Task 010 pipeline integration)
- QG-005: Performance benchmarks meet NFR-001 targets (latency <2s for single doc, <120s for knowledge graph)

---

## Session Completion

**Status**: ✅ CONTINUOUS SESSION COMPLETE - ALL 11 MCP TASKS CREATED

---

## Task Numbering History

### Phase 3 - Initial Task Creation (Original IDs)

Created 5 task files with initial numbering:
- **Task 001**: FastMCP Framework Installation - NO CHANGE (prerequisite task)
- **Task 002**: Conversion Tools Registration - RENUMBERED → 009
- **Task 003**: Generation Tools (KG) Registration - RENUMBERED → 010
- **Task 006**: HTTP Transport Configuration - RENUMBERED → 013
- **Task 009**: MCP Protocol Compliance Testing - RENUMBERED → 035

### Phase 4 - Task Renumbering Rationale

**Purpose**: Create gaps in task numbering to accommodate tasks from other SMEs inserted during parallel planning phases.

**Gap Allocation Strategy**:
- **002-008**: Reserved for infrastructure setup tasks (william-chen: environment config, systemd services, deployment validation)
- **014-028**: Reserved for deployment and integration tasks (multiple SMEs: albert, andy, mitch, diana)
- **033-034**: Reserved for future expansion or contingency tasks

**Complete Renumbering Mapping**:

| Original ID | New ID | Task Name | Renumbering Rationale |
|-------------|--------|-----------|----------------------|
| 002 | 009 | Conversion Tools | Gap created for infra tasks 002-008 |
| 003 | 010 | Generation Tools (KG) | Sequential after 009 |
| 006 | 013 | HTTP Transport | Gap created for config tasks 011-012 |
| 009 | 035 | Protocol Compliance Testing | Moved to testing phase (end of sequence) |

**Why Renumbering Was Necessary**:
- Phase 3 created initial MCP tasks with assumption of sequential IDs
- Phase 4 planning revealed need for infrastructure tasks BEFORE tool registration
- Renumbering preserved logical execution order: infrastructure → tools → transports → testing
- Gaps allow future task insertion without renumbering entire sequence

### Phase 5 - Additional Task Creation (Final IDs)

Created 6 additional MCP tasks with final numbering:
- **Task 011**: Generation Tools (Doc Utils) - NEW (8 tools)
- **Task 012**: Manipulation Tools - NEW (5 tools)
- **Task 029**: SSE/stdio Transports - NEW
- **Task 030**: Schema Validation - NEW
- **Task 031**: Pipeline Integration (CRITICAL PATH) - NEW
- **Task 032**: Session Management - NEW

### Final Task List - All 11 MCP Tasks (james-rodriguez)

**Current Valid Task IDs for Deployment**:
001, 009, 010, 011, 012, 013, 029, 030, 031, 032, 035

**Tasks Created (Phase 3 - Initial Task Generation)**: 5 files
1. hx-docling-mcp-task-001-install-fastmcp-framework.md
2. hx-docling-mcp-task-009-register-conversion-tools.md (originally 002)
3. hx-docling-mcp-task-010-register-generation-tools-kg.md (originally 003)
4. hx-docling-mcp-task-013-configure-http-transport.md (originally 006)
5. hx-docling-mcp-task-035-mcp-protocol-compliance-testing.md (originally 009)

**Tasks Created (Phase 5 - Completion Assignment)**: 6 files
6. hx-docling-mcp-task-011-register-generation-tools-doc-utils.md (8 tools)
7. hx-docling-mcp-task-012-register-manipulation-tools.md (5 tools)
8. hx-docling-mcp-task-029-configure-sse-stdio-transports.md (SSE + stdio)
9. hx-docling-mcp-task-030-mcp-tool-schema-validation.md (schema validation)
10. hx-docling-mcp-task-031-document-processing-pipeline-integration.md (CRITICAL PATH)
11. hx-docling-mcp-task-032-redis-session-management-integration.md (session mgmt)

**Total MCP Tasks**: 11 tasks (100% of james-rodriguez assignment complete)

**Task Ownership Summary**:
- **Infrastructure Tasks** (1): Task 001 (FastMCP installation)
- **Tool Registration Tasks** (4): Tasks 009-012 (all 19 MCP tools across 3 categories)
- **Transport Configuration Tasks** (2): Tasks 013 (HTTP), 029 (SSE/stdio)
- **Validation & Testing Tasks** (2): Tasks 030 (schema validation), 035 (protocol compliance)
- **Integration Tasks** (2): Tasks 031 (pipeline integration - CRITICAL PATH), 032 (session management)

**CRITICAL PATH TASK IDENTIFIED**: Task 031 (Document Processing Pipeline Integration) replaces ALL placeholder implementations with actual Docling + LightRAG backends. All other tasks have placeholders until Task 031 completes.

**Next Actions**:
1. ✅ All 11 MCP tasks created with comprehensive implementation details
2. Phase 6 (Test Suite Generation): julia-santos will generate test suite ensuring 100% task coverage for all 11 MCP tasks
3. Phase 7 (Deployment Execution): Execute tasks in dependency order per TASK-DEPENDENCY-MATRIX.md

**Ready for Execution**: All MCP Tools domain tasks fully specified, dependencies documented, integration points validated.
