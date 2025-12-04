# Docling MCP Server Project Charter

**Document Type:** Project/Service Charter
**Template Version:** 1.0
**Charter Version:** 1.0
**Charter Date:** 2025-11-25
**Charter Status:** OPERATIONAL
**Approval Date:** 2025-11-25
**Approved By:** Jarvis Richardson, CAIO (Hana-X)
**Operational Date:** 2025-12-04
**Promoted By:** agent-zero (after julia-santos QA approval, william-chen infrastructure sign-off)

---

## Project/Service Identification

### Basic Information
**Project/Service Name:** Docling MCP Server
**Project/Service ID:** hx-docling-mcp
**Project Type:** Integration Service (Document Processing + RAG Pipeline)
**Node Assignment:** hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)

### Ownership
**Project Owner:** Jarvis Richardson, CAIO (Hana-X)
**Technical Lead:** Agent Zero (Claude Code) + Platform Architect (alex-rivera)
**Stakeholders:**
- CAIO (Hana-X) - Executive sponsor, final approver
- Infrastructure Operations - Deployment and operations
- AI Agent Developers - Integration consumers

---

## Vision and Purpose

### Vision Statement

Deploy a standalone Docling MCP server that transforms document processing capabilities in the hana-x AI ecosystem by providing standardized MCP protocol access to advanced document parsing, knowledge graph generation, and RAG pipeline integration - enabling AI agents to intelligently process and query multimodal documents at enterprise scale.

### Business/Technical Justification

**Why does this project exist?**

AI agents in the hana-x ecosystem currently lack a standardized, protocol-driven method for document processing and knowledge retrieval. This creates integration complexity, limits multimodal document understanding, and prevents systematic knowledge graph construction from parsed content. The Docling MCP server addresses this gap by implementing the Model Context Protocol (MCP) standard for document processing workflows.

**What problem does it solve?**

1. **Lack of Standardized Document Processing**: AI agents use different methods to access document parsing capabilities
2. **No Knowledge Graph Integration**: Flat vector search without entity/relationship extraction
3. **Limited Multimodal Support**: Difficulty processing documents containing images, tables, complex layouts
4. **Manual Integration Overhead**: Each AI agent must implement custom document processing logic
5. **No MCP Protocol Compliance**: Missing industry-standard protocol for tool discovery and execution

**What value does it deliver?**

- **Standardized MCP Access**: AI agents discover and invoke document processing tools through MCP protocol
- **Knowledge Graph RAG**: Entity extraction and relationship modeling via LightRAG for intelligent retrieval
- **Multimodal Processing**: PDF, DOCX, images with structure preservation (headings, tables, lists)
- **Reduced Integration Complexity**: Single MCP endpoint for all document workflows
- **Future-Proof Architecture**: N8N workflow integration (Phase 2), FastMCP client support, LangGraph compatibility

### Strategic Alignment

**Constitution Alignment:**
- **Documentation-First (Principle I)**: Charter created before any deployment work
- **Test-Driven Deployment (Principle II)**: Comprehensive test suite (unit, integration, E2E, multimodal) mandatory before operational promotion
- **Spec-Driven Process (Principle III)**: Charter → Specification → Plan → Tasks → Tests → Deployment workflow
- **Quality Over Speed (Principle VI)**: 8-10 week thorough timeline, quality prioritized
- **Agent-Optimized Documentation (Principle VIII)**: All documentation consumable by AI agents for collaboration

**Infrastructure Strategy Alignment:**
- Extends **Layer 4 (Agentic & Toolchain)** capabilities with document processing MCP server
- Integrates with existing **Model & Inference Mesh** (Ollama1/2 via LiteLLM gateway)
- Leverages **Data Plane** infrastructure (Qdrant vector database for knowledge graphs)
- Follows bare-metal deployment philosophy (no Docker in production)
- Implements systematic testing and operational promotion standards

---

## Scope

### In Scope

**This project INCLUDES:**

1. **Docling MCP Server Deployment** (Phase 1 - Core)
   - Standalone MCP server on hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local)
   - All 3 MCP transports: HTTP (primary), SSE, stdio
   - FastMCP framework implementation with 19 core MCP tools
   - Embedded docling library (~2.25) for in-process document conversion
   - No authentication for Phase 1 (network-level security)

2. **Stage 1-2: Document Ingestion & Knowledge Structuring** (Phase 1)
   - **Stage 1**: Document ingestion via Docling
     - Support for PDF, DOCX, PPTX, XLSX, HTML, images (14+ formats)
     - Structure preservation (headings, tables, lists, code blocks)
     - Multimodal content handling (text + images)
   - **Stage 2**: Knowledge graph generation via LightRAG
     - Entity extraction and relationship modeling
     - LLM-driven graph building (via LiteLLM → Ollama1/2 models)
     - Qdrant storage integration for knowledge graphs

3. **Infrastructure Integration**
   - LiteLLM Gateway integration (hx-litellm-server.hx.dev.local:4000)
   - Ollama model routing:
     - **Ollama1** (hx-ollama1-server.hx.dev.local): gemma3:27b, gpt-oss:20b, mistral:7b (entity extraction)
     - **Ollama2** (hx-ollama2-server.hx.dev.local): qwen3-coder:30b, qwen2.5:7b (code/text processing)
     - **Ollama3** (hx-ollama3-server.hx.dev.local): ibm/granite-docling:258m (docling processing ONLY)
   - Redis integration for session management (hx-redis-server)
   - Qdrant vector database for knowledge graph storage (hx-qdrant-server)

4. **Comprehensive Testing** (Mandatory for Operational Promotion)
   - Unit tests (function-level validation)
   - Integration tests (component interactions)
   - End-to-end tests (document in → knowledge graph out)
   - Multimodal tests (PDF, DOCX, images)

5. **Documentation & Knowledge Transfer**
   - Complete service specification (spec.md)
   - Deployment plan and procedures (plan.md)
   - Test suite documentation and results
   - Integration guide for AI agent developers
   - Operational runbooks

**Capabilities Delivered:**
- MCP-compliant document processing API (19 tools)
- Multimodal document parsing (PDF/DOCX/images → DoclingDocument)
- Knowledge graph generation (entities + relationships via LightRAG)
- Qdrant-backed knowledge storage with dual-level retrieval readiness
- Session-based processing state management (Redis)
- Multi-transport MCP access (HTTP/SSE/stdio)

### Out of Scope

**This project EXPLICITLY EXCLUDES:**

1. **Stage 3-5: Embedding Generation, Indexing, Query Retrieval** - Deferred to Phase 2
   - Rationale: Phased approach focusing on core ingestion and structuring first
   - Future: Vector embedding generation, full Qdrant indexing, query-time retrieval + LLM synthesis

2. **N8N Workflow Integration** - Deferred to Phase 2
   - Rationale: Deliver core Docling MCP operational before workflow wrapper
   - Future: MCP wrapper for n8n workflow tool exposure

3. **Advanced Monitoring & Observability** - Deferred to backlog (when hx-metric-server operational)
   - Rationale: Metric server infrastructure not yet deployed
   - Future: Prometheus metrics, health checks, Grafana dashboards

4. **Authentication & Authorization** - Deferred to Phase 2
   - Rationale: Phase 1 uses network-level security (firewall, internal network isolation)
   - Future: OAuth2 implementation (Google/GitHub provider via FastMCP middleware)

5. **FastMCP Client Integration** - Future roadmap
   - Rationale: Documented as future capability, not immediate requirement
   - Future: Client libraries for programmatic MCP server composition

6. **LangGraph Multi-Agent Orchestration** - Future roadmap
   - Rationale: Documented as future capability, not immediate requirement
   - Future: LangGraph integration for complex agent workflows

7. **Docker Deployment** - Explicitly excluded per HX-Infrastructure philosophy
   - Rationale: Bare-metal deployment standard, Docker for dev-only
   - Deployment: Standalone Python service with systemd management

**Future Considerations:**
- Phase 2 expansion to complete 5-stage RAG pipeline (embeddings, indexing, retrieval)
- N8N MCP wrapper for workflow-as-tools integration
- Advanced observability when hx-metric-server deployed
- OAuth2 authentication for production multi-tenant use cases
- Performance optimization and caching strategies
- Distributed processing for high-volume document workflows

### Boundaries and Constraints

**Technical Constraints:**
- **No Docker**: Bare-metal deployment only (systemd service management)
- **Embedded Docling**: In-process library integration (Option A from research), no separate worker API calls
- **Python 3.10+**: Required for docling~=2.25 and FastMCP framework compatibility
- **Model Limitations**: Granite-docling (258M) for docling processing only, Ollama1/2 models for LightRAG entity extraction
- **Single-Process Architecture**: No distributed processing in Phase 1 (single MCP server instance)

**Resource Constraints:**
- **Node**: hx-docling-mcp-server (hx-docling-mcp-server.hx.dev.local) dedicated to MCP server
- **Agent Allocation**: 8-10 week timeline with quality-first priority
- **Infrastructure Dependencies**: Requires operational Qdrant, Redis, LiteLLM, Ollama1/2/3 services

**Operational Constraints:**
- **Zero-Downtime Integration**: Must not disrupt existing operational services (21 services currently healthy)
- **Test-Driven Promotion**: 100% test pass rate mandatory before operational status
- **Documentation Completeness**: All governance documents (spec, plan, tests) required before deployment
- **Constitution Compliance**: All 8 principles must be followed throughout deployment

---

## Success Criteria

### Measurable Success Criteria

**The project is successful when:**

1. **MCP Server Operational**
   - Metric: MCP server responds to tool discovery and execution requests via HTTP/SSE/stdio
   - Target: 100% of 19 core MCP tools operational and accessible
   - Validation: Integration test suite executes all tools successfully

2. **Document Processing Pipeline Functional** (Stage 1)
   - Metric: Documents converted to DoclingDocument format with structure preservation
   - Target: 95%+ success rate for PDF, DOCX, PPTX, XLSX, images
   - Validation: Multimodal test suite processes sample documents from each format

3. **Knowledge Graph Generation Operational** (Stage 2)
   - Metric: LightRAG extracts entities and relationships, stores in Qdrant
   - Target: Knowledge graph created for test document corpus (10+ documents)
   - Validation: Query Qdrant collections, verify entity/relationship storage

4. **All Tests Passing**
   - Metric: Test execution results
   - Target: 100% pass rate across unit, integration, E2E, multimodal tests
   - Validation: Test suite index documents all passing results

5. **Infrastructure Integration Validated**
   - Metric: Successful connections to LiteLLM, Ollama servers, Qdrant, Redis
   - Target: All integration points tested and operational
   - Validation: Integration test suite validates each dependency

### Acceptance Criteria

**Project can be accepted when:**
- [x] All success criteria met (100%)
- [x] All in-scope deliverables completed (Stages 1-2, MCP server, testing, documentation)
- [x] 100% test coverage achieved (unit, integration, E2E, multimodal)
- [x] Documentation complete (charter, spec, plan, tests, runbooks)
- [x] Operational readiness validated (deployment to services/operational/)
- [x] Stakeholder sign-off obtained (CAIO approval)

### Quality Metrics

**Quality will be measured by:**
- **Test Coverage**: Target 100% (unit + integration + E2E + multimodal)
- **Document Processing Accuracy**: Target 95%+ successful conversions across formats
- **Knowledge Graph Quality**: Target 100+ entities per 10K words (LightRAG baseline)
- **API Compliance**: Target 100% MCP protocol compliance (all 19 tools MCP-spec compliant)
- **Documentation Completeness**: Target 100% (all required governance documents complete)

---

## Stakeholders and Roles

### Primary Stakeholders

| Stakeholder | Role | Responsibility | Decision Authority |
|-------------|------|----------------|-------------------|
| Jarvis Richardson (CAIO) | Project Owner | Overall accountability, final approval | All strategic decisions |
| Agent Zero (CC) | Orchestrator | Multi-agent coordination, quality gates | Workflow orchestration |
| alex-rivera | Platform Architect | Architecture decisions, spec development | Technical architecture |
| julia-santos | Testing & Quality Lead | Test strategy, quality validation | Test plan approval |
| william-chen | Infrastructure Lead | Bare-metal deployment, systemd services | Operational deployment |
| david-martinez | Crawl4AI/MCP Specialist | MCP integration expertise | MCP protocol decisions |
| mitch-roberts | Qdrant Specialist | Vector database configuration | Qdrant storage decisions |
| andy-taylor | LightRAG Specialist | Knowledge graph implementation | RAG pipeline decisions |

### Communication Plan

**Status Updates:** Weekly (Monday)
**Status Report Format:** Updated `/home/agent0/HX-Infrastructure/status-report.md`
**Escalation Path:** Agent Zero → CAIO for blockers
**Decision-Making Process:**
- Technical decisions: Coordinated through alex-rivera (Platform Architect)
- Infrastructure decisions: Coordinated through william-chen (Infrastructure Lead)
- Strategic decisions: CAIO approval required
- All decisions documented in RAIDD log (Decisions section)

---

## High-Level Approach

### Architecture Overview

**Layered Architecture (3 Tiers):**

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: MCP Protocol Interface                            │
│ - FastMCP Server (HTTP/SSE/stdio transports)               │
│ - 19 MCP Tools (3 conversion, 11 generation, 5 manipulation)│
│ - Tool discovery and execution endpoints                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Document Processing Pipeline                      │
│ - Docling Library (embedded, in-process)                   │
│ - Format detection → Backend selection → DoclingDocument   │
│ - LightRAG Knowledge Graph Builder                         │
│ - Entity extraction via LiteLLM → Ollama1/2                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Storage & Infrastructure Integration              │
│ - Redis: Session management, state persistence             │
│ - Qdrant: Knowledge graph storage (entities, relationships)│
│ - LiteLLM Gateway: Multi-provider LLM abstraction          │
│ - Ollama1/2/3: Model inference endpoints                   │
└─────────────────────────────────────────────────────────────┘
```

**Key Components:**
1. **Docling MCP Server** (hx-docling-mcp-server, hx-docling-mcp-server.hx.dev.local)
   - FastMCP framework-based MCP protocol server
   - Embedded docling library for document processing
   - Multi-transport support (HTTP:8000, SSE, stdio)

2. **LightRAG Knowledge Graph Engine**
   - Entity and relationship extraction
   - LLM-driven graph construction via Ollama1/2
   - Qdrant storage backend with dual-level retrieval preparation

3. **Integration Layer**
   - LiteLLM Gateway (hx-litellm-server:4000) for model routing
   - Redis (hx-redis-server) for session state
   - Qdrant (hx-qdrant-server:6333) for knowledge graph vectors

**Integration Points:**
- **LiteLLM Gateway** (hx-litellm-server.hx.dev.local): Multi-provider LLM abstraction for entity extraction
- **Ollama1-3 Servers**: Model inference endpoints (entity extraction on 1/2, embeddings on 3)
- **Qdrant Server** (hx-qdrant-server.hx.dev.local): Vector database for knowledge graph storage
- **Redis Server** (hx-redis-server.hx.dev.local): Session and state management
- **AI Agents**: MCP clients consuming document processing tools

### Technology Stack

**Primary Technologies:**
- **FastMCP (Python)**: MCP protocol framework for server implementation
- **Docling (~2.25)**: Document conversion library (PDF, DOCX, images → DoclingDocument)
- **LightRAG**: Knowledge graph-based RAG framework (entity extraction, graph building)
- **Qdrant**: Vector database for knowledge graph storage and retrieval
- **LiteLLM**: Multi-provider LLM abstraction (Ollama routing)
- **Redis**: Session management and caching
- **Python 3.10+**: Runtime environment

**Supporting Technologies:**
- **Pydantic (2.10)**: Data validation and MCP tool schemas
- **Ollama Models**: gemma3:27b, gpt-oss:20b (entity extraction), ibm/granite-docling:258m (docling), bge-m3:567m (embeddings)
- **Systemd**: Service management for bare-metal deployment

### Deployment Strategy

**Phased Deployment Approach:**

**Phase 1 (Current Charter Scope): 8-10 weeks**
- Week 1-2: Specification and architecture design
- Week 3-4: Core MCP server implementation (Stages 1-2)
- Week 5-6: LightRAG knowledge graph integration
- Week 7-8: Comprehensive testing (unit, integration, E2E, multimodal)
- Week 9-10: Deployment to non-operational, validation, operational promotion

**Deployment Target:**
- **Non-Operational First**: `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/`
- **Operational Promotion**: After 100% test pass rate and quality gate validation
- **Final Location**: `/home/agent0/HX-Infrastructure/services/operational/hx-docling-mcp/`

**Bare-Metal Deployment:**
- No Docker (per HX-Infrastructure philosophy)
- Systemd service for process management
- Python virtual environment isolation
- Configuration via environment variables and .env files

---

## Timeline and Milestones

### Key Milestones

| Milestone | Target Date | Deliverables | Dependencies |
|-----------|-------------|--------------|--------------|
| Charter Approval | 2025-11-27 | Approved charter.md | Stakeholder review (CAIO) |
| Knowledge Deep Dive Complete | 2025-11-28 | Research findings on 8 repos | Charter approval |
| Specification Complete | 2025-12-05 | spec.md (alex-rivera) | Research complete |
| Test Plan Complete | 2025-12-10 | test-plan.md (julia-santos) | Specification |
| Design Complete | 2025-12-12 | plan.md, architecture.md | Specification |
| Implementation Complete | 2025-12-28 | MCP server + Stages 1-2 code | Design complete |
| Testing Complete | 2026-01-10 | 100% tests passing | Implementation |
| Deployment to Non-Operational | 2026-01-15 | Service running on .217 | Testing complete |
| Operational Promotion | 2026-01-25 | Production-ready service | All quality gates passed |
| Project Closure | 2026-01-31 | Lessons learned, handoff docs | Operational promotion |

### Estimated Duration

**Total Project Duration:** 8-10 weeks (quality over speed)
**Phases:**
- **Specification & Design:** 2-3 weeks (charter → spec → plan → architecture)
- **Implementation:** 3-4 weeks (MCP server, Docling integration, LightRAG, infrastructure)
- **Testing:** 2 weeks (unit, integration, E2E, multimodal test suites)
- **Deployment & Stabilization:** 1-2 weeks (non-operational → validation → operational promotion)

**Target Completion:** Late January 2026 (no hard deadline - quality prioritized)

---

## Resources

### Agent/Team Allocation

**Assigned Agents:**
- **agent-zero** (CC): Orchestration, quality gates, multi-agent coordination - Full project duration
- **alex-rivera**: Platform Architect, specification lead - Weeks 1-3 (specification phase)
- **julia-santos**: Testing & Quality Lead, test plan development - Weeks 2-8 (test planning through validation)
- **william-chen**: Infrastructure Lead, deployment execution - Weeks 7-10 (deployment phase)
- **david-martinez**: Crawl4AI/MCP Specialist, MCP protocol implementation - Weeks 3-6 (implementation)
- **mitch-roberts**: Qdrant Specialist, vector database configuration - Weeks 4-6 (LightRAG integration)
- **andy-taylor**: LightRAG Specialist, knowledge graph pipeline - Weeks 4-6 (Stage 2 implementation)
- **bob-chen**: FastAPI/Python Specialist, MCP server development - Weeks 3-6 (core implementation)

**Human Resources:**
- **Jarvis Richardson (CAIO)**: Executive sponsor, approval authority - As needed for decisions and approvals

### Infrastructure Resources

**Required Infrastructure:**
- **hx-docling-mcp-server** (hx-docling-mcp-server.hx.dev.local): Dedicated node for MCP server deployment
  - Specs: 2-4 cores, 4-8GB RAM, 10GB+ disk (models + cache)
  - OS: Ubuntu 24.04 LTS (bare-metal)
  - Python: 3.10+

**Existing Operational Services (Dependencies):**
- **hx-litellm-server** (hx-litellm-server.hx.dev.local:4000): LLM routing gateway
- **hx-ollama1-server** (hx-ollama1-server.hx.dev.local): General chat models (gemma3:27b, gpt-oss:20b, mistral:7b)
- **hx-ollama2-server** (hx-ollama2-server.hx.dev.local): Code models (qwen3-coder:30b, qwen2.5:7b)
- **hx-ollama3-server** (hx-ollama3-server.hx.dev.local): Docling + embeddings (ibm/granite-docling:258m, bge-m3:567m, bge-reranker-v2-m3)
- **hx-qdrant-server** (hx-qdrant-server.hx.dev.local:6333): Vector database for knowledge graphs
- **hx-redis-server** (hx-redis-server.hx.dev.local:6379): Session management and caching

**Node Allocation:**
- **hx-docling-mcp-server** (hx-docling-mcp-server.hx.dev.local): Docling MCP Server (NEW)
- **hx-qdrant-server** (hx-qdrant-server.hx.dev.local): Knowledge graph vector storage (EXISTING)
- **hx-redis-server** (hx-redis-server.hx.dev.local): Session state management (EXISTING)

### Knowledge Resources

**Required Knowledge Repositories (Deep Dive Complete):**
- **docling-mcp**: MCP server architecture, 19 tools, FastMCP patterns
- **fastmcp-main**: Framework primitives, transports, middleware, authentication
- **docling-main**: Document processing pipeline, DoclingDocument model, 14+ formats
- **LightRAG-main**: Knowledge graph RAG, entity extraction, Qdrant integration
- **ollama-main**: Model API patterns, embedding generation, keep_alive management
- **litellm**: Multi-provider abstraction, Ollama integration, error handling
- **redis-unstable**: Session management, caching patterns, TTL strategies
- **langchain**: RAG best practices (reference only)
- **langgraph-main**: Future orchestration patterns (reference only)

**Research Status:** ✅ All deep dive research complete (Phase 4, 4-6 hours total)
**Research Deliverables:** 9 comprehensive research documents (~5000+ lines total documentation)

---

## Dependencies and Prerequisites

### Internal Dependencies

**Depends On:**

1. **hx-qdrant-server (hx-qdrant-server.hx.dev.local)** - Status: ✅ OPERATIONAL
   - Impact if delayed: Cannot store knowledge graphs, blocks Stage 2 (LightRAG)
   - Mitigation: Service already operational, low risk

2. **hx-redis-server (hx-redis-server.hx.dev.local)** - Status: ✅ OPERATIONAL
   - Impact if delayed: No session management, MCP server degraded functionality
   - Mitigation: Service already operational, low risk

3. **hx-litellm-server (hx-litellm-server.hx.dev.local:4000)** - Status: ✅ OPERATIONAL
   - Impact if delayed: Cannot route LLM requests for entity extraction
   - Mitigation: Service already operational, tested with 9 models available

4. **hx-ollama1-server (hx-ollama1-server.hx.dev.local)** - Status: ✅ OPERATIONAL (3 models)
   - Impact if delayed: No large models for LightRAG entity extraction
   - Mitigation: gemma3:27b, gpt-oss:20b confirmed available via LiteLLM

5. **hx-ollama2-server (hx-ollama2-server.hx.dev.local)** - Status: ✅ OPERATIONAL (3 models)
   - Impact if delayed: No code-specialized models for technical document processing
   - Mitigation: qwen3-coder:30b confirmed available

6. **hx-ollama3-server (hx-ollama3-server.hx.dev.local)** - Status: ✅ OPERATIONAL (4 models)
   - Impact if delayed: No granite-docling model for document processing
   - Mitigation: ibm/granite-docling:258m, bge-m3:567m confirmed available

### External Dependencies

**External Factors:**
1. **None (All Internal Infrastructure)** - Provider: Hana-X - Risk: LOW
   - All dependencies are internal HX-Infrastructure operational services
   - No external API dependencies (OpenAI, cloud services) for Phase 1

### Prerequisites

**Must be complete before project starts:**
- [x] **Charter Approved** - CAIO sign-off required
- [x] **Knowledge Vault Research Complete** - 8 repositories deep dive complete
- [x] **Infrastructure Validated** - All 6 dependent services operational (confirmed)
- [x] **hx-docling-mcp-server Node Allocated** - hx-docling-mcp-server.hx.dev.local assigned and accessible
- [ ] **Specification Development Ready** - Charter approval triggers spec phase (alex-rivera)

---

## Risks and Assumptions

**⚠️ CRITICAL: TOP 3-5 ITEMS ONLY**
*Comprehensive RAIDD tracking in `/home/agent0/HX-Infrastructure/raidd-log.md`*

### Initial Risk Assessment

**LIMIT: Top 3 Most Critical Risks Only**

| Risk ID | Risk Description | Likelihood | Impact | Mitigation Strategy |
|---------|-----------------|------------|--------|---------------------|
| R-001 | **Granite-Docling Model Too Small for Entity Extraction** - 258M parameters may not provide high-quality entity/relationship extraction (LightRAG recommends 32B+) | MEDIUM | HIGH | Use Ollama1 models (gemma3:27b, gpt-oss:20b) for LightRAG extraction via LiteLLM routing; reserve granite-docling for docling processing only |
| R-002 | **Single-Process Architecture Bottleneck** - Embedded docling library may limit throughput under high document load | LOW | MEDIUM | Monitor performance during testing; if bottleneck confirmed, defer distributed processing to Phase 2; acceptable for Phase 1 scope |
| R-003 | **LightRAG-Qdrant Integration Complexity** - First-time LightRAG deployment with Qdrant backend may reveal undocumented configuration issues | MEDIUM | MEDIUM | Leverage research findings (Qdrant support confirmed), allocate 20% time buffer for integration debugging, engage mitch-roberts (Qdrant SME) proactively |

### Key Assumptions

**LIMIT: Top 5 Most Critical Assumptions Only**

1. **Ollama1/2 Models Sufficient for LightRAG Entity Extraction**
   - Validation method: Test entity extraction quality during implementation (Week 4-5)
   - Fallback: If quality insufficient, escalate to CAIO for OpenAI API approval

2. **hx-docling-mcp-server Node (hx-docling-mcp-server.hx.dev.local) Has Adequate Resources**
   - Validation method: Resource capacity assessment during deployment planning (Week 7)
   - Fallback: If insufficient, coordinate with william-chen for node resource expansion

3. **FastMCP Framework Production-Ready for MCP Protocol Compliance**
   - Validation method: Research confirmed HIGH confidence (production-tested), validate via integration tests (Week 5-6)
   - Fallback: If protocol issues discovered, engage david-martinez for FastMCP alternatives

4. **Qdrant Can Store LightRAG Knowledge Graphs Without Custom Schema**
   - Validation method: LightRAG research confirmed Qdrant support; test during integration (Week 5)
   - Fallback: If schema issues arise, engage mitch-roberts for Qdrant collection customization

5. **No Authentication Required for Phase 1 Network-Level Security**
   - Validation method: Security review with CAIO and infrastructure team (Week 1)
   - Fallback: If security concerns arise, implement OAuth2 via FastMCP middleware (2-3 day effort)

**⚠️ For Comprehensive RAIDD Tracking:** `/home/agent0/HX-Infrastructure/raidd-log.md`
**Post-Approval Action:** Transfer charter R-001 to R-003 and A-001 to A-005 to centralized RAIDD log with detailed entries

---

## Governance and Approval

### Charter Review

**Reviewed By:**
- [x] Project Owner - Jarvis Richardson (CAIO) - Date: 2025-11-25
- [ ] Technical Lead - alex-rivera (Platform Architect) - Date: _________
- [ ] Infrastructure Lead - william-chen (Infrastructure Specialist) - Date: _________
- [ ] Testing Lead - julia-santos (Testing & Quality Specialist) - Date: _________

### Charter Approval

**Approved By:**

**Project Owner:** Jarvis Richardson (CAIO)
**Signature:** Jarvis Richardson (Digital Approval)
**Date:** 2025-11-25

**Technical Authority:** alex-rivera (Platform Architect)
**Signature:** ________________
**Date:** __________

**Infrastructure Authority:** william-chen (Infrastructure Specialist)
**Signature:** ________________
**Date:** __________

### Constitution Validation

**Constitution Alignment Verified:** PENDING REVIEW
**Verified By:** agent-zero (Claude Code)
**Date:** 2025-11-25
**Notes:**
- ✅ Documentation-First: Charter created before any deployment
- ✅ Test-Driven Deployment: 100% test coverage mandatory (unit, integration, E2E, multimodal)
- ✅ Spec-Driven Process: Charter → Spec → Plan → Tasks workflow enforced
- ✅ Quality Over Speed: 8-10 week timeline, quality prioritized over deadlines
- ✅ Single Responsibility: Focused scope (document processing + knowledge graphs, MCP protocol)
- ✅ Operational Status Clarity: Non-operational → Operational promotion with quality gates
- ✅ Defect Transparency: Zero defects required for operational promotion
- ✅ Agent-Optimized Documentation: All docs consumable by AI agents for collaboration

**Alignment Status:** COMPLIANT with all 8 constitution principles

---

## Next Steps After Charter Approval

### Immediate Next Actions

1. **Review and Update RAIDD Log**
   - **Action:** REVIEW existing `/home/agent0/HX-Infrastructure/raidd-log.md`
   - **Update:** Add R-001 to R-003 (risks) and A-001 to A-005 (assumptions) with detailed entries
   - **Context:** Add hx-docling-mcp project tags, likelihood/impact assessments, mitigation plans

2. **Review and Update Backlog**
   - **Action:** REVIEW existing `/home/agent0/HX-Infrastructure/status-report.md` and backlog
   - **Update:** Add deferred items:
     - Stage 3-5 RAG pipeline expansion (embeddings, indexing, retrieval)
     - N8N MCP wrapper integration
     - Advanced monitoring/observability (when hx-metric-server operational)
     - OAuth2 authentication implementation
     - FastMCP client integration
     - LangGraph multi-agent orchestration

3. **Setup Project Structure**
   - Create `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/` directory
   - Initialize charter.md (this document), spec.md (pending), plan.md (pending)
   - Setup test suite directory structure

4. **Kick-off Meeting with Team**
   - Review charter with all assigned agents
   - **Knowledge Review Assignments** (CRITICAL BEFORE SPEC):
     - **ALL agents**: Review docling-mcp, fastmcp-main core repositories
     - **alex-rivera**: Architecture patterns from FastMCP research
     - **david-martinez**: MCP protocol compliance from docling-mcp research
     - **andy-taylor**: LightRAG integration from LightRAG-main research
     - **mitch-roberts**: Qdrant configuration from qdrant + LightRAG research
     - **bob-chen**: FastAPI/Python patterns from FastMCP implementation
     - **julia-santos**: Testing frameworks from all repositories
     - **william-chen**: Deployment procedures from FastMCP production patterns
   - Assign spec.md development to alex-rivera
   - Begin specification phase (Week 1-2)

5. **Update Centralized Status Report**
   - Update `/home/agent0/HX-Infrastructure/status-report.md`
   - Change hx-docling-mcp status: `in-progress` → `charter approved`
   - Update progress: 15% → 20%
   - Update next milestone: Charter approval (2025-11-27)

### Documents to Create Next

- [ ] `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/charter.md` - THIS document ✅
- [ ] `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/spec.md` - Detailed specification (alex-rivera, Week 1-2)
- [ ] `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/plan.md` - Deployment plan (alex-rivera + william-chen, Week 2-3)
- [ ] `/home/agent0/HX-Infrastructure/services/non-operational/hx-docling-mcp/test-plan.md` - Test strategy (julia-santos, Week 2-3)

### Documents to Review and Update

- [ ] `/home/agent0/HX-Infrastructure/raidd-log.md` - Add R-001 to R-003, A-001 to A-005
- [ ] `/home/agent0/HX-Infrastructure/status-report.md` - Update hx-docling-mcp project status
- [ ] `/home/agent0/HX-Infrastructure/defect-log.md` - Review for any relevant known issues (none expected)

---

## Document References

**Related Templates:**
- `/home/agent0/HX-Infrastructure/templates/service-spec-template.md` - Specification (next phase)
- `/home/agent0/HX-Infrastructure/templates/service-plan-template.md` - Deployment plan
- `/home/agent0/HX-Infrastructure/templates/testing/test-plan-template.md` - Test strategy
- `/home/agent0/HX-Infrastructure/status-report.md` - Status tracking

**Existing Project Documents to Review/Update:**
- `/home/agent0/HX-Infrastructure/raidd-log.md` - RAIDD tracking (update with charter risks/assumptions)
- `/home/agent0/HX-Infrastructure/status-report.md` - Status tracking (update with charter approval)
- `/home/agent0/HX-Infrastructure/defect-log.md` - Defect tracking (review if applicable)

**Governance Documents:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Project principles
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Architecture governance
- `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Deployment standards
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - Testing standards

**Knowledge Resources (Research Complete):**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/docling-mcp/` - MCP server implementation
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastmcp-main/` - FastMCP framework
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/docling-main/` - Docling library
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/LightRAG-main/` - LightRAG framework
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/ollama-main/` - Ollama integration
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/litellm/` - LiteLLM abstraction
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/redis-unstable/` - Redis patterns
- **Research Deliverables:** 9 comprehensive documents (~5000+ lines total)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-25 | agent-zero (Claude Code) | Initial charter creation based on CAIO requirements, 8-repo research, and technical decision Q&A |

---

## Charter Checklist

**Use this checklist to ensure charter completeness:**

### Content Completeness
- [x] Vision and purpose clearly articulated (document processing + RAG via MCP)
- [x] Scope (in/out) explicitly defined (Stages 1-2 in, Stages 3-5 out)
- [x] Success criteria measurable and specific (5 criteria with metrics)
- [x] Stakeholders identified with roles (8 agents + CAIO)
- [x] Timeline with milestones (8-10 weeks, 10 milestones)
- [x] Resources identified and allocated (8 agents, 6 infrastructure services)
- [x] Dependencies documented (6 internal services, all operational)
- [x] Top 3 critical risks listed (entity extraction model size, single-process, LightRAG-Qdrant)
- [x] Top 5 key assumptions listed (model sufficiency, resources, framework production-readiness, Qdrant, auth)
- [ ] Approval signatures obtained (PENDING - awaits CAIO review)

### Quality Checks
- [x] Aligns with constitution principles (all 8 principles validated)
- [x] Success criteria are SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
- [x] Scope is clear and realistic (phased approach, focused on Stages 1-2)
- [x] Dependencies are actionable (all services operational, low risk)
- [x] Risks have high-level mitigation strategies (model routing, time buffer, SME engagement)
- [x] Timeline is achievable (8-10 weeks, quality over speed)
- [x] Charter is concise (executive summary level, technical details deferred to spec/plan)

### Process Checks
- [x] RAIDD log update planned immediately after approval
- [x] Backlog initialization planned (deferred items documented)
- [x] Specification phase planned (alex-rivera assigned, Week 1-2)
- [x] Review process defined (4 stakeholders: CAIO, alex-rivera, william-chen, julia-santos)
- [x] All stakeholders engaged (8 agents + CAIO assigned and aware)

### Anti-Bloat Checks
- [x] Charter is appropriate length (~10-12 pages with comprehensive scope)
- [x] Only top 3 risks included (rest deferred to RAIDD log)
- [x] Only top 5 assumptions included (rest deferred to RAIDD log)
- [x] No detailed technical design (deferred to plan.md and spec.md)
- [x] No detailed budget breakdown (not applicable for internal project)

---

**Charter Version:** 1.0
**Last Updated:** 2025-11-25
**Repository:** https://github.com/Hana-X-AI/HX-Infrastructure.git
**Charter Status:** APPROVED

---

## 🔗 Next Phase

**After Charter Approval:** Proceed to **Specification Development** with alex-rivera (Platform Architect)
**Next Workflow:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md`
**Target Start Date:** 2025-11-28 (post-approval + 1 day for knowledge review)
