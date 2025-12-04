# Task Framework: hx-docling-mcp-server
**Date**: 2025-12-01
**Workflow**: Task Breakdown Workflow - Phase 1 Output
**Agent**: Agent Zero (Orchestrator)

---

## Purpose

This document defines the task structure framework for hx-docling-mcp-server deployment. It identifies major work streams, maps them to agent expertise, establishes task numbering schema, and identifies dependencies. This framework guides Phase 3 team task generation.

---

## Work Stream Identification

Based on systematic review of `/nodes/hx-docling-mcp-server/specification/node-spec.md` (8,126 lines), the following major work streams have been identified:

### Work Stream 1: Pre-Deployment Infrastructure
**Scope**: Service account creation, DNS registration, directory structure, permissions setup

**Agent Assignment**: **frank-lucas** (Identity, DNS, Security Specialist)

**Rationale**: Frank specializes in:
- Samba Active Directory service account creation
- DNS record management in hx.dev.local domain
- File/directory permissions and ownership
- Security baseline configuration

**Task Categories**:
- Create service account `docling-mcp@hx.dev.local`
- Register DNS A record for hx-docling-mcp-server.hx.dev.local → 192.168.10.217
- Create base directories (`/opt/docling-mcp/`, `/var/lib/docling-mcp/`, `/etc/docling-mcp/`, `/var/log/docling-mcp/`)
- Configure directory ownership and permissions

**Task Number Range**: 001-010

---

### Work Stream 2: System Dependencies Installation
**Scope**: OS-level package installation (Python, poppler, tesseract, libmagic)

**Agent Assignment**: **william-chen** (Infrastructure & Operations Specialist)

**Rationale**: William specializes in:
- Bare-metal server configuration
- Package management (apt)
- System-level dependency installation
- OS hardening and configuration

**Task Categories**:
- Install system packages via apt (python3.11, python3.11-venv, poppler-utils, tesseract-ocr, libmagic1)
- Verify package installation
- Configure system paths
- Document installed package versions

**Task Number Range**: 011-020

---

### Work Stream 3: Python Virtual Environment Setup
**Scope**: Python 3.11 venv creation, pip configuration, dependency installation

**Agent Assignment**: **william-chen** (Infrastructure & Operations Specialist)

**Rationale**: William handles infrastructure setup including:
- Python virtual environment creation
- Pip package installation
- Requirements management
- Environment activation configuration

**Task Categories**:
- Create Python 3.11 virtual environment in `/opt/docling-mcp/venv/`
- Upgrade pip, setuptools, wheel
- Install Python packages from requirements.txt
- Verify package installation

**Task Number Range**: 021-030

---

### Work Stream 4: MCP Server Application Code
**Scope**: FastMCP server code, MCP tool registration, transport configuration

**Agent Assignment**: **james-rodriguez** (Docling MCP Gateway Specialist)

**Rationale**: James specializes in:
- MCP protocol implementation
- FastMCP framework integration
- Document processing via MCP tools
- Docling library integration

**Task Categories**:
- Create MCP server entry point (`mcp_server.py`)
- Register 19 MCP tools (3 conversion, 11 generation, 5 manipulation)
- Configure HTTP/SSE/stdio transports
- Implement health check endpoint

**Task Number Range**: 031-060

**Sub-Categories**:
- 031-040: Server initialization and transport configuration
- 041-043: Conversion tools (3 tools)
- 044-054: Generation tools (11 tools)
- 055-059: Manipulation tools (5 tools)
- 060: Health check endpoint

---

### Work Stream 5: Document Processing Integration
**Scope**: Docling library integration, format detection, backend selection, OCR pipeline

**Agent Assignment**: **albert-singh** (Docling Processing Specialist)

**Rationale**: Albert specializes in:
- Docling library implementation
- Multi-format document conversion (PDF, DOCX, PPTX, XLSX, HTML, images)
- OCR integration (EasyOCR)
- DoclingDocument schema implementation

**Task Categories**:
- Implement document processor module (`docling_processor.py`)
- Configure format detection pipeline (magic number, MIME type, extension)
- Implement backend selection logic (pypdfium2, python-docx, python-pptx, openpyxl, BeautifulSoup, EasyOCR)
- Implement structure preservation (headings, tables, lists, code blocks, images)
- Integrate OCR pipeline for scanned PDFs

**Task Number Range**: 061-080

---

### Work Stream 6: Knowledge Graph Generation
**Scope**: LightRAG integration, entity/relationship extraction, Qdrant storage

**Agent Assignment**: **andy-taylor** (LightRAG SME)

**Rationale**: Andy specializes in:
- LightRAG framework integration
- Entity extraction via LLM
- Relationship extraction via LLM
- Knowledge graph construction

**Task Categories**:
- Implement LightRAG client module (`literag_client.py`)
- Configure entity extraction pipeline (chunking, LLM prompting, deduplication)
- Configure relationship extraction pipeline
- Implement HTTP API client for hx-literag-server (http://hx-literag-server.hx.dev.local:8000)
- Implement entity/relationship response parsing

**Task Number Range**: 081-100

---

### Work Stream 7: Qdrant Integration
**Scope**: Qdrant client, collection initialization, entity/relationship storage, vector operations

**Agent Assignment**: **mitch-harper** (Qdrant SME)

**Rationale**: Mitch specializes in:
- Qdrant vector database operations
- Collection design and configuration
- HNSW indexing parameters
- Vector search and filtering

**Task Categories**:
- Implement Qdrant client module (HTTP API integration)
- Configure idempotent collection initialization (hx_docling_mcp_entities, hx_docling_mcp_relationships)
- Implement entity insertion with deduplication
- Implement relationship insertion with bidirectional linking
- Configure payload indexes (entity_type, document_id, confidence, mention_count)
- Implement vector search and graph traversal queries

**Task Number Range**: 101-120

---

### Work Stream 8: LiteLLM Integration
**Scope**: LiteLLM HTTP client, model routing, error handling, retry logic

**Agent Assignment**: **shane-black** (LiteLLM SME)

**Rationale**: Shane specializes in:
- LiteLLM gateway integration
- Multi-model routing (Ollama1/2/3 via LiteLLM)
- API error handling
- Performance optimization

**Task Categories**:
- Implement LiteLLM HTTP client module
- Configure entity extraction model routing (gemma3:27b via hx-litellm-server)
- Implement retry logic with exponential backoff
- Configure timeout handling (60 seconds)
- Implement structured output parsing (Pydantic models)

**Task Number Range**: 121-130

---

### Work Stream 9: Redis Integration
**Scope**: Redis connection pool, session management, caching layer

**Agent Assignment**: **sri-patel** (Redis SME)

**Rationale**: Sri specializes in:
- Redis client integration
- Connection pooling
- Session state management
- Caching strategies

**Task Categories**:
- Implement Redis client module with connection pooling
- Configure session management (TTL, sliding window)
- Implement caching layer (document metadata, entity extraction, DoclingDocument cache)
- Configure health checks and connection recovery
- Implement cache key naming conventions

**Task Number Range**: 131-140

---

### Work Stream 10: Configuration Management
**Scope**: Environment variables, Pydantic settings validation, .env file creation

**Agent Assignment**: **paul-warfield** (Pydantic SME)

**Rationale**: Paul specializes in:
- Pydantic BaseSettings validation
- Environment variable configuration
- Field validators and cross-field validation
- Configuration schemas

**Task Categories**:
- Implement Pydantic configuration schema (DoclingMCPConfig)
- Define nested settings classes (RedisSettings, QdrantSettings, LLMSettings, ProcessingSettings, MCPServerSettings)
- Implement field validators (confidence threshold, cache dir validation, TTL validation)
- Create .env.production file with default values
- Implement startup configuration validation

**Task Number Range**: 141-150

---

### Work Stream 11: Systemd Service Configuration
**Scope**: Service unit file creation, service activation, auto-restart configuration

**Agent Assignment**: **william-chen** (Infrastructure & Operations Specialist)

**Rationale**: William specializes in:
- Systemd service management
- Service unit file creation
- Auto-restart configuration
- Service monitoring

**Task Categories**:
- Create systemd unit file (`/etc/systemd/system/docling-mcp.service`)
- Configure service user (docling-mcp)
- Configure ExecStart with venv activation
- Configure auto-restart policy (3 attempts in 5 minutes)
- Enable service for auto-start
- Configure service dependencies (network.target)

**Task Number Range**: 151-160

---

### Work Stream 12: Logging Configuration
**Scope**: Structured logging setup, log levels, log sanitization

**Agent Assignment**: **william-chen** (Infrastructure & Operations Specialist)

**Rationale**: William handles operational infrastructure including:
- Logging configuration
- Log rotation (systemd journal)
- Log sanitization for security
- Log monitoring

**Task Categories**:
- Configure Python logging (JSON structured logs)
- Implement log sanitization (credential redaction, document content truncation)
- Configure log levels (DEBUG, INFO, WARN, ERROR)
- Configure systemd journal output
- Document log access procedures

**Task Number Range**: 161-170

---

### Work Stream 13: Integration Testing
**Scope**: Service integration tests, dependency connectivity, MCP protocol compliance

**Agent Assignment**: **Coordinated by julia-santos** (Testing & Quality Specialist)

**Rationale**: Julia coordinates testing across all integration points:
- LiteLLM connectivity testing
- Qdrant connectivity testing
- Redis connectivity testing
- hx-literag-server connectivity testing
- MCP tool invocation testing

**Task Categories**:
- Create integration test suite
- Test LiteLLM connectivity (TC-INT-005)
- Test Qdrant connectivity (TC-INT-006)
- Test Redis connectivity (TC-INT-007)
- Test hx-literag-server connectivity (TC-INT-004)
- Test MCP tool discovery and invocation
- Validate health check endpoint

**Task Number Range**: 171-190

**Note**: Julia will coordinate this work stream in Phase 3 but detailed test execution occurs in Phase 7 (Test Suite Generation).

---

### Work Stream 14: Post-Deployment Validation
**Scope**: Service startup verification, health checks, deployment smoke tests

**Agent Assignment**: **william-chen** (Infrastructure & Operations Specialist)

**Rationale**: William validates operational readiness:
- Service startup success
- Health check validation
- Dependency connectivity
- Log verification

**Task Categories**:
- Start docling-mcp.service via systemd
- Verify service status (active/running)
- Execute health check endpoint (`curl http://hx-docling-mcp-server.hx.dev.local:8000/health`)
- Validate dependency health status
- Verify log output (no ERROR-level logs on startup)
- Document service operational status

**Task Number Range**: 191-200

---

## CRITICAL: Pre-Execution Validation Requirement

**MANDATORY FOR ALL TASKS**: Every task MUST include a "Pre-Execution Validation" section that checks if the work is already complete BEFORE executing any steps. This prevents duplication of completed work.

**Example Pre-Execution Validation**:
```bash
# Check if service account already exists
samba-tool user show docling-mcp@hx.dev.local 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ VALIDATION: Service account already exists - SKIP task execution"
    exit 0
else
    echo "❌ VALIDATION: Service account does not exist - PROCEED with task"
fi
```

**Validation Logic**:
- If work already complete → SKIP execution, mark task as validated/complete
- If work not complete → PROCEED with implementation steps
- Document validation results in task execution tracking

---

## Task Numbering Schema

**Format**: `hx-docling-mcp-task-NNN-description.md`

**Number Ranges**:
- 001-010: Pre-Deployment Infrastructure (frank-lucas)
- 011-020: System Dependencies Installation (william-chen)
- 021-030: Python Virtual Environment Setup (william-chen)
- 031-060: MCP Server Application Code (james-rodriguez)
- 061-080: Document Processing Integration (albert-singh)
- 081-100: Knowledge Graph Generation (andy-taylor)
- 101-120: Qdrant Integration (mitch-harper)
- 121-130: LiteLLM Integration (shane-black)
- 131-140: Redis Integration (sri-patel)
- 141-150: Configuration Management (paul-warfield)
- 151-160: Systemd Service Configuration (william-chen)
- 161-170: Logging Configuration (william-chen)
- 171-190: Integration Testing (julia-santos coordination)
- 191-200: Post-Deployment Validation (william-chen)
- 999: Execute Test Suite (julia-santos) - Execute existing 52 test cases, document results, validate quality gates

**Total Estimated Tasks**: 50-60 tasks

---

## Agent Assignment Summary

| Agent | Work Streams | Task Count (Estimated) | Technology Focus |
|-------|--------------|------------------------|------------------|
| **frank-lucas** | Pre-Deployment Infrastructure | 6-8 | Samba AD, DNS, permissions |
| **william-chen** | System Dependencies, Python venv, Systemd, Logging, Post-Deployment | 20-25 | Bare-metal, systemd, infrastructure |
| **james-rodriguez** | MCP Server Application Code | 25-30 | FastMCP, MCP protocol, tool registration |
| **albert-singh** | Document Processing Integration | 12-15 | Docling, format detection, OCR |
| **andy-taylor** | Knowledge Graph Generation | 12-15 | LightRAG, entity/relationship extraction |
| **mitch-harper** | Qdrant Integration | 12-15 | Qdrant, vector storage, graph operations |
| **shane-black** | LiteLLM Integration | 6-8 | LiteLLM gateway, model routing |
| **sri-patel** | Redis Integration | 6-8 | Redis, caching, session management |
| **paul-warfield** | Configuration Management | 6-8 | Pydantic, environment variables |
| **julia-santos** | Integration Testing (coordination) | 15-20 | Test strategy, quality gates |

**Total Agents**: 10 specialists

---

## Dependency Matrix

### Sequential Dependencies (Blockers)

```
Pre-Deployment Infrastructure (001-010)
  └─> System Dependencies Installation (011-020)
      └─> Python Virtual Environment Setup (021-030)
          └─> [PARALLEL DEVELOPMENT PHASE]
              ├─> MCP Server Application Code (031-060)
              ├─> Document Processing Integration (061-080)
              ├─> Knowledge Graph Generation (081-100)
              ├─> Qdrant Integration (101-120)
              ├─> LiteLLM Integration (121-130)
              ├─> Redis Integration (131-140)
              └─> Configuration Management (141-150)
          └─> Systemd Service Configuration (151-160)
              └─> Logging Configuration (161-170)
                  └─> Integration Testing (171-190)
                      └─> Post-Deployment Validation (191-200)
```

### Critical Path
1. Pre-Deployment Infrastructure (frank-lucas)
2. System Dependencies Installation (william-chen)
3. Python Virtual Environment Setup (william-chen)
4. Parallel Development (james, albert, andy, mitch, shane, sri, paul)
5. Systemd Service Configuration (william-chen)
6. Logging Configuration (william-chen)
7. Integration Testing (julia-santos coordination)
8. Post-Deployment Validation (william-chen)

### Parallel Development Coordination
Tasks 031-150 can proceed in parallel after Python venv setup (task 030) completes. These work streams are independent at development level but integrate during testing phase (171-190).

---

## Test Suite Status

**IMPORTANT**: Test suite ALREADY EXISTS at `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tests/`

**Existing Test Assets**:
- `test-plan.md` - Complete test plan (90KB)
- `test-suite-index.md` - Test suite index
- `test-suite/` - 52 test case files across categories:
  - deployment/ - Deployment validation tests
  - functionality/ - MCP tool functionality tests
  - integration/ - Integration tests (LiteLLM, Qdrant, Redis, hx-literag-server)
  - health-check/ - Health check tests
  - multimodal/ - Multimodal document processing tests

**julia-santos Role**: Test EXECUTION and validation (NOT test generation)

**Phase 7 Focus**: Execute existing test suite, document results, validate quality gates

---

## Pre-Validation Findings

Based on `/nodes/hx-docling-mcp-server/pre-validation-inventory.md`:

**Server State**: ALL infrastructure components return ❌ (nothing deployed on hx-docling-mcp-server.hx.dev.local)

**Implication**: This is a greenfield deployment. No existing work to preserve. All tasks from this framework must be executed.

**Exception**: hx-literag-server already OPERATIONAL (external dependency, no deployment required)

---

## Architecture Update Acknowledgment

**LightRAG Server Status**: ✅ OPERATIONAL (http://hx-literag-server.hx.dev.local:8000)

**Integration Approach**: HTTP client integration via `literag_client.py` module

**No Deployment Required**: hx-literag-server is an external operational service. Docling MCP Server consumes its HTTP API for entity/relationship extraction.

---

## Phase 2 & 3 Guidance

### Phase 2: Team Member Addition
**Evaluation Criteria**: Are 10 specialist agents sufficient?

**Current Assessment**: YES - All required expertise is covered:
- Identity/Security (frank-lucas)
- Infrastructure (william-chen)
- MCP Protocol (james-rodriguez)
- Document Processing (albert-singh)
- Knowledge Graph (andy-taylor)
- Vector Database (mitch-harper)
- LLM Gateway (shane-black)
- Redis (sri-patel)
- Configuration (paul-warfield)
- Testing (julia-santos)

**Phase 2 Decision**: No additional agents required. Proceed to Phase 3.

### Phase 3: Team Task Generation
**Instructions for Agent Zero**:

1. Invoke each agent with:
   - Full context (specification, charter, this framework)
   - Assigned work stream(s)
   - Task number range
   - Task template
   - Instruction to generate tasks AND create task files in single session

2. Agents to invoke (in this order to respect dependencies):
   - frank-lucas (001-010)
   - william-chen (011-030, 151-170, 191-200) - 3 work streams
   - james-rodriguez (031-060)
   - albert-singh (061-080)
   - andy-taylor (081-100)
   - mitch-harper (101-120)
   - shane-black (121-130)
   - sri-patel (131-140)
   - paul-warfield (141-150)
   - julia-santos (171-190) - Test coordination framework only (full test suite in Phase 7)

3. For each agent:
   - Agent loads specification and charter
   - Agent generates tasks for assigned work stream(s)
   - Agent creates task files in `/nodes/hx-docling-mcp-server/tasks/` directory
   - Agent completes work in ONE continuous session (stateless agent pattern)

---

**Framework Complete**: Ready for Phase 2 evaluation and Phase 3 team invocation

**Agent Zero Sign-Off**: 2025-12-01
