# Project Charter: Docling MCP Server Integration

**Document Type:** Project/Service Charter
**Template Version:** 1.0
**Charter Date:** 2025-11-24
**Charter Status:** Draft

---

## Project/Service Identification

### Basic Information
**Project/Service Name:** Docling MCP Server Integration
**Project/Service ID:** hx-docling-mcp-server
**Project Type:** Integration - MCP Protocol Server
**Charter Version:** 1.0
**Charter Date:** 2025-11-24
**Charter Status:** Draft

### Ownership
**Project Owner:** CAIO (Chief AI Officer)
**Technical Lead:** James Anderson (Docling MCP SME)
**Supporting Agents:**
- George Kim (FastMCP Gateway SME) - HTTP wrapper integration
- Lou Martinez (Qdrant MCP SME) - Vector database integration
- Marcus Johnson (LightRAG SME) - RAG pipeline integration
- Jim Turner (Ollama SME) - granite-docling model deployment

**Stakeholders:**
- CAIO - Project sponsor and decision authority
- HX-Infrastructure Team - Infrastructure deployment and operations
- AI Agent Developers - Primary consumers of document processing capabilities

---

## Vision and Purpose

### Vision Statement
Deploy a production-grade Docling MCP server that exposes advanced document processing capabilities to AI agents and n8n workflows, enabling seamless conversion of PDFs, DOCX, and images into structured formats while integrating with LightRAG for knowledge graph construction and Qdrant for vector search.

### Business/Technical Justification

**Why does this project exist?**

AI agents and workflow automation systems require standardized, efficient document processing capabilities to extract structured information from various document formats. The Model Context Protocol (MCP) provides a universal standard for exposing these capabilities, eliminating the need for custom API integrations for each tool or platform.

**What problem does it solve?**

- **Streamlined Development:** Developers currently lack a standardized protocol (MCP) to integrate document parsing into AI agents, requiring custom APIs for each tool
- **Slow Document Processing:** Traditional OCR methods are significantly slower than modern deep learning approaches
- **Complex Integration:** Each workflow automation system (n8n) and AI agent requires custom integration code
- **RAG Pipeline Gaps:** No unified path from document ingestion → knowledge graph creation → vector storage → retrieval

**What value does it deliver?**

**Development Value:**
- **Faster document processing:** Docling processes documents 3-5x faster than traditional OCR
- **Easy agent integration:** Single MCP protocol for all AI agents (Claude Desktop, LM Studio, custom agents)
- **Advanced AI workflows:** Enables RAG pipelines with knowledge graph construction and hybrid vector search
- **Reduced integration time:** Standard MCP protocol eliminates weeks of custom API development

**Business Value:**
- **Increased efficiency:** Automated document processing reduces manual data entry
- **Scalability:** MCP standard enables integration with multiple tools/platforms without redesign
- **Cost reduction:** Faster processing means lower infrastructure costs
- **Future-proof:** MCP protocol adoption ensures compatibility with emerging AI agent frameworks

### Strategic Alignment

**Constitution Alignment:**
- **Quality First:** Test-driven deployment with 100% test coverage before promotion to operational
- **Documentation-First Philosophy:** Complete specification and planning before implementation
- **Layer-Aware Architecture:** Deploys to Layer 4 (Agentic & Toolchain) with proper dependencies on Layers 1-3
- **No Assumptions:** Systematic validation of all integration points

**Infrastructure Strategy Alignment:**
- Completes Docling ecosystem integration (worker operational, MCP interface was blocked)
- Enables n8n workflow automation with document processing capabilities
- Integrates with existing RAG infrastructure (LightRAG, Qdrant, Ollama)
- Follows bare-metal systemd deployment pattern (no Docker)

---

## Scope

### In Scope

**This project INCLUDES:**

1. **Docling MCP Server Deployment (192.168.10.217)**
   - Bare-metal Python service with systemd management
   - MCP protocol server with 3 transport modes (stdio, sse, streamable-http)
   - Tool groups: conversion, generation, manipulation
   - Disk-based cache for document persistence
   - Integration with Ollama3 (192.168.10.206) for granite-docling:258m model

2. **FastAPI HTTP Wrapper for n8n Integration**
   - Custom FastAPI service translating HTTP → MCP calls
   - RESTful endpoints for n8n workflows
   - Support for all Docling MCP tool capabilities
   - Authentication and rate limiting

3. **LightRAG + Qdrant Pipeline Integration**
   - Document ingestion: Docling → structured content extraction
   - Knowledge graph: LightRAG entity/relationship extraction using LLMs
   - Multimodal embeddings: FastEmbed for text + image vectors
   - Vector storage: Qdrant indexing (dense + sparse hybrid search)
   - Query-time retrieval: LightRAG queries Qdrant

4. **MCP Gateway Integration**
   - Register with hx-fastmcp-server (192.168.10.213) for centralized MCP routing
   - Expose tools to AI agents via standard MCP protocol

5. **Comprehensive Testing**
   - Unit tests for all MCP tools
   - Integration tests for full RAG pipeline (Docling → LightRAG → Qdrant → retrieval)
   - HTTP wrapper API tests
   - Performance tests (document processing throughput)
   - End-to-end tests with n8n workflows

**Capabilities Delivered:**
- PDF, DOCX, image conversion to DoclingDocument format (JSON, Markdown)
- Document generation capabilities (programmatic document creation)
- Document manipulation tools (editing, structure modification)
- RAG ingestion pipeline (document → knowledge graph → vector search)
- n8n workflow integration via HTTP API
- AI agent integration via MCP protocol (Claude, LM Studio, custom agents)

### Out of Scope

**This project EXCLUDES:**

1. **Not Modifying Existing Systems:**
   - hx-docling-server (192.168.10.216) remains operational as-is (NO CHANGES)
   - hx-n8n-server workflows (no changes to n8n platform itself)
   - Qdrant or LightRAG server configuration (use existing services)

2. **Future Enhancements (Deferred):**
   - FastMCP client integration (calling Docling MCP from FastMCP gateway)
   - LangGraph agent orchestration integration
   - Multi-worker distributed architecture
   - Docker containerization (bare-metal only for this phase)
   - Advanced caching strategies (Redis integration)

3. **Not Included:**
   - Real-time collaboration features
   - Document editing UI
   - User management system
   - Milvus vector database integration (using Qdrant instead)

### Scope Boundaries

**System Boundaries:**
- **Upstream:** AI agents (MCP clients), n8n workflows (HTTP clients)
- **Downstream:** Ollama3 (LLM backend), LightRAG (knowledge graph), Qdrant (vector storage)
- **Integration Point:** hx-fastmcp-server (MCP gateway)
- **No Integration:** hx-docling-server (separate worker, no coordination)

---

## Success Criteria

### Acceptance Criteria

**Deployment Success:**
- [ ] hx-docling-mcp-server service operational on 192.168.10.217
- [ ] Systemd service starts automatically on boot
- [ ] All 3 transport modes functional (stdio, sse, streamable-http)
- [ ] Disk-based cache persisting documents across restarts

**MCP Protocol Success:**
- [ ] All conversion tools operational (PDF → DoclingDocument)
- [ ] All generation tools operational (document creation)
- [ ] All manipulation tools operational (document editing)
- [ ] MCP protocol compliant with JSON-RPC 2.0 specification

**n8n Integration Success:**
- [ ] FastAPI HTTP wrapper operational
- [ ] n8n workflow can call document conversion endpoint
- [ ] n8n workflow can call document generation endpoint
- [ ] HTTP → MCP protocol translation working correctly

**RAG Pipeline Success:**
- [ ] Docling processes PDF → structured content
- [ ] LightRAG generates knowledge graph (entities, relationships, keywords)
- [ ] FastEmbed creates multimodal embeddings (text + images)
- [ ] Qdrant indexes vectors with hybrid search (dense + sparse)
- [ ] End-to-end query: user question → LightRAG → Qdrant → LLM → answer

**Integration Success:**
- [ ] Registered with hx-fastmcp-server MCP gateway
- [ ] AI agent (Claude Desktop config) can discover and use tools
- [ ] Ollama3 granite-docling:258m model responding to requests

**Testing Success:**
- [ ] 100% test coverage for all MCP tools
- [ ] All integration tests passing
- [ ] Performance benchmark: Process 10 PDFs < 60 seconds
- [ ] n8n workflow integration test passing

### Quality Metrics

**Performance Targets:**
- Document conversion latency: < 5 seconds per PDF (average 10 pages)
- RAG pipeline latency: < 10 seconds (document → indexed in Qdrant)
- HTTP wrapper response time: < 100ms overhead
- Concurrent document processing: 5+ documents simultaneously

**Reliability Targets:**
- Service uptime: 99% (systemd auto-restart on failure)
- Cache persistence: 100% (no data loss on restart)
- Error rate: < 1% (failed document conversions)

**Test Coverage Targets:**
- Unit test coverage: 100% of MCP tools
- Integration test coverage: 100% of RAG pipeline
- End-to-end test coverage: 100% of user workflows (n8n + agent)

---

## Technical Requirements

### Infrastructure Layer Assignment
**Layer:** 4 (Agentic & Toolchain)
**Node:** hx-docling-mcp-server (192.168.10.217)
**IP Address:** 192.168.10.217
**Hostname:** hx-docling-mcp-server.hx.dev.local

### Dependencies

**Layer 1 (Identity & Trust):**
- hx-dc-server: Domain authentication, DNS resolution
- hx-ca-server: TLS certificates for HTTPS
- hx-ssl-server: Reverse proxy for HTTP wrapper API (if exposed externally)

**Layer 2 (Model & Inference):**
- hx-ollama3-server (192.168.10.206): granite-docling:258m model for LLM processing

**Layer 3 (Data Plane):**
- hx-qdrant-server (192.168.10.220): Vector storage for RAG
- hx-literag-server (192.168.10.220): Knowledge graph construction

**Layer 4 (Same Layer):**
- hx-fastmcp-server (192.168.10.213): MCP gateway registration

**External Dependencies:**
- Python 3.10+ (bare-metal installation)
- docling-mcp package (PyPI)
- FastAPI (for HTTP wrapper)
- FastEmbed (for multimodal embeddings)

### Technology Stack

**Primary:**
- **Language:** Python 3.10+
- **MCP Server:** docling-mcp (PyPI package)
- **HTTP Wrapper:** FastAPI (custom implementation)
- **Process Management:** systemd (bare-metal service)
- **Caching:** Filesystem (disk-based persistence)

**Integration:**
- **LLM Backend:** Ollama (hx-ollama3-server, granite-docling:258m)
- **RAG Framework:** LightRAG (hx-literag-server)
- **Vector Database:** Qdrant (hx-qdrant-server)
- **Embedding:** FastEmbed (integrated with LightRAG)

---

## Assumptions

1. **Infrastructure Assumptions:**
   - hx-ollama3-server operational with granite-docling:258m model deployed
   - hx-qdrant-server operational and accessible
   - hx-literag-server operational with LightRAG configured
   - hx-fastmcp-server operational for MCP gateway registration
   - Python 3.10+ available on hx-docling-mcp-server node

2. **Integration Assumptions:**
   - LightRAG can connect to Ollama3 for LLM processing
   - Qdrant supports hybrid search (dense + sparse vectors)
   - FastEmbed compatible with LightRAG pipeline
   - n8n workflows can make HTTP requests to custom APIs

3. **Operational Assumptions:**
   - Bare-metal deployment acceptable (no Docker requirement)
   - Disk-based caching sufficient (no Redis requirement initially)
   - Single-node deployment sufficient (no multi-worker scaling)
   - Systemd service management acceptable

4. **Technical Assumptions:**
   - MCP protocol (JSON-RPC 2.0) is production-ready
   - Docling library performance meets requirements (< 5s per document)
   - HTTP → MCP translation overhead is minimal (< 100ms)

---

## Risks

### Critical Risks (High Impact, Requires Mitigation)

1. **Risk: granite-docling:258m Model Not Available**
   - **Impact:** RAG pipeline cannot function without LLM for knowledge extraction
   - **Probability:** Medium
   - **Mitigation:** Verify model availability on hx-ollama3-server before deployment; fallback to alternative models if needed

2. **Risk: LightRAG-Qdrant Integration Complexity**
   - **Impact:** RAG pipeline may require significant custom integration work
   - **Probability:** Medium
   - **Mitigation:** Prototype integration during specification phase; identify integration gaps early

3. **Risk: Disk-Based Cache Performance**
   - **Impact:** Document processing may be slower than expected with filesystem cache
   - **Probability:** Low
   - **Mitigation:** Benchmark cache performance during testing; Redis upgrade path if needed

### Moderate Risks (Medium Impact)

4. **Risk: HTTP Wrapper Authentication/Security**
   - **Impact:** n8n workflows may expose document processing to unauthorized access
   - **Probability:** Medium
   - **Mitigation:** Implement API key authentication in FastAPI wrapper; review security requirements during spec

5. **Risk: Concurrent Document Processing**
   - **Impact:** Performance degrades with multiple simultaneous requests
   - **Probability:** Medium
   - **Mitigation:** Implement request queuing; load testing during performance validation

---

## Dependencies

### Prerequisites (Must Be Complete Before Start)

1. **Infrastructure:**
   - [x] hx-docling-mcp-server node provisioned (192.168.10.217)
   - [x] hx-ollama3-server operational (192.168.10.206)
   - [x] hx-qdrant-server operational (192.168.10.220)
   - [x] hx-literag-server operational (192.168.10.220)
   - [x] hx-fastmcp-server operational (192.168.10.213)
   - [ ] granite-docling:258m model deployed to hx-ollama3-server
   - [ ] Python 3.10+ installed on hx-docling-mcp-server
   - [ ] Domain joined (hx.dev.local)

2. **Configuration:**
   - [ ] DNS record for hx-docling-mcp-server.hx.dev.local
   - [ ] TLS certificate from hx-ca-server
   - [ ] Service account: docling-mcp@hx.dev.local

### Blocking Dependencies

- **Blocks:** None (this is a new service with no downstream dependencies yet)
- **Blocked By:**
  - granite-docling:258m model deployment (required for LLM processing)
  - LightRAG configuration verification (required for knowledge graph)

---

## Timeline and Milestones

### Estimated Duration
**Total Project Duration:** 3-4 weeks

### Phase Breakdown

**Phase 1: Specification Development (Week 1)**
- Charter approved
- Technical specification created
- Architecture design validated
- Integration points documented
- **Milestone:** Specification approved

**Phase 2: Task Planning & Test Planning (Week 1-2)**
- Deployment plan created
- Task breakdown with dependencies
- Test plan with 100% coverage
- Resource allocation confirmed
- **Milestone:** Plan approved, ready for development

**Phase 3: Development & Testing (Week 2-3)**
- Deploy Docling MCP server (systemd)
- Build FastAPI HTTP wrapper
- Integrate LightRAG + Qdrant pipeline
- Execute test suite (100% coverage)
- **Milestone:** All tests passing, ready for deployment validation

**Phase 4: Deployment & Validation (Week 3-4)**
- Deploy to non-operational environment
- Integration testing with n8n workflows
- Performance validation
- Security review
- **Milestone:** Quality gates passed, ready for promotion

**Phase 5: Promotion & Closeout (Week 4)**
- Promote to operational
- End-to-end validation
- Documentation finalized
- Knowledge transfer
- **Milestone:** Service operational, project complete

### Key Milestones

- **M1 (Week 1):** Charter Approved → Begin Specification
- **M2 (Week 1-2):** Specification + Plans Approved → Begin Development
- **M3 (Week 2-3):** All Tests Passing (100% coverage) → Deploy Non-Operational
- **M4 (Week 3-4):** Quality Gates Passed → Promote to Operational
- **M5 (Week 4):** Service Operational, Project Closeout Complete

---

## Resource Requirements

### Agent Assignments

**Lead:**
- **James Anderson** (Docling MCP SME) - Primary technical lead for MCP server deployment

**Supporting Agents:**
- **George Kim** (FastMCP Gateway SME) - HTTP wrapper architecture and FastMCP integration
- **Lou Martinez** (Qdrant MCP SME) - Vector database integration patterns
- **Marcus Johnson** (LightRAG SME) - Knowledge graph pipeline design
- **Jim Turner** (Ollama SME) - granite-docling:258m model deployment and configuration
- **Bob Martinez** (FastAPI SME) - HTTP wrapper implementation

**Quality & Operations:**
- **Julia Santos** (Testing & Quality SME) - Test planning and quality validation
- **William Chen** (Infrastructure SME) - Bare-metal deployment and systemd configuration
- **Frank Lucas** (Security SME) - Authentication and security review

### Infrastructure Resources

**Compute:**
- hx-docling-mcp-server (192.168.10.217) - Single bare-metal node
- Estimated CPU: 4-8 cores (document processing is CPU-intensive)
- Estimated RAM: 16-32 GB (large document handling)
- Estimated Disk: 100-200 GB (disk-based cache storage)

**Network:**
- Inbound: Port 8000 (HTTP wrapper API for n8n)
- Outbound: Ollama3 (7680), LightRAG (TBD), Qdrant (6333), FastMCP (TBD)

---

## Approval and Sign-Off

### Charter Review

**Charter Author:** Agent Zero (Claude Code)
**Date Created:** 2025-11-24
**Charter Status:** Draft - Awaiting CAIO Review

### Approval Signatures

**CAIO Approval:**
- Name: _______________________________
- Date: _______________________________
- Signature: _______________________________

**Technical Lead Approval:**
- Name: James Anderson (Docling MCP SME)
- Date: _______________________________
- Signature: _______________________________

---

## Post-Approval Actions

### Immediate Next Steps (After Charter Approval)

1. **Review and Update RAIDD Log:**
   - Extract top 5 risks from charter → add to `/home/agent0/HX-Infrastructure/raidd-log.md`
   - Extract 4 assumptions from charter → add to RAIDD log
   - Extract dependencies → add to RAIDD log

2. **Review and Update Backlog:**
   - Add out-of-scope items to `/home/agent0/HX-Infrastructure/backlog.md`:
     - FastMCP client integration (future)
     - LangGraph integration (future)
     - Multi-worker architecture (future)
     - Docker containerization (future)
     - Redis caching (future)

3. **Knowledge Review Assignments:**
   - James Anderson: docling-mcp repository review
   - George Kim: FastMCP integration patterns review
   - Bob Martinez: FastAPI best practices review
   - Marcus Johnson: LightRAG pipeline review
   - Lou Martinez: Qdrant hybrid search review

4. **Kick-off Meeting Agenda:**
   - Charter walkthrough (15 min)
   - Knowledge repository assignments (10 min)
   - Q&A and clarifications (15 min)
   - Timeline confirmation (10 min)
   - Begin specification work (Alex Rivera coordination)

---

## Document Control

**Document Location:** `/home/agent0/HX-Infrastructure/services/planning/hx-docling-mcp-server/charter-hx-docling-mcp-server.md`

**Version History:**

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-24 | Initial charter creation | Agent Zero (CC) |

**Related Documents:**
- **Template:** `/home/agent0/HX-Infrastructure/templates/charter-template.md`
- **Next Phase:** Specification Development (spec-workflow.md)
- **Infrastructure Docs:** `/home/agent0/HX-Infrastructure/inventory/nodes.md`
- **Agent Inventory:** `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md`

---

**Charter Status:** Draft - Ready for CAIO Review and Approval
