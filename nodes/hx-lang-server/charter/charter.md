# Project Charter: hx-lang-server

**Document Type:** Project/Service Charter
**Charter Version:** 1.1
**Charter Date:** 2025-12-01
**Charter Status:** APPROVED
**Specification Status:** APPROVED (2025-12-04) - Ready for Planning Phase

---

## Project/Service Identification

### Basic Information
**Project/Service Name:** LangGraph Deployment & Integration on HX-Infrastructure
**Project/Service ID:** hx-lang-server
**Project Type:** Service | Integration | Platform
**Target Server:** hx-lang-server.hx.dev.local

### Ownership
**Project Owner:** CAIO (Chief AI Officer)
**Technical Lead:** Agent Zero (Sophia - LangGraph Orchestration SME)
**Stakeholders:**
- CAIO - Strategic direction and approval authority
- Alex Rivera - Platform architecture oversight
- William Chen - Infrastructure deployment and operations
- Julia Santos - Testing and quality assurance
- Technology SMEs - Domain-specific implementation

---

## Vision and Purpose

### Vision Statement
Establish hx-lang-server as the **central orchestration hub** for intelligent, multi-step, and adaptive AI workflows using local Ollama models within HX-Infrastructure. Move beyond linear pipelines to enable stateful, agentic systems with complex reasoning, conditional logic, and tool use capabilities.

### Business/Technical Justification

**Why does this project exist?**

HX-Infrastructure requires a sophisticated agent orchestration layer to coordinate between multiple AI services (Ollama servers, LightRAG, Qdrant, MCP servers) and enable advanced RAG workflows that go beyond simple retrieve-then-generate patterns.

**What problem does it solve?**

1. **Lack of Agent Orchestration**: Currently no central system for multi-step AI workflows
2. **Linear RAG Limitations**: Simple retrieval lacks adaptive reasoning and iteration
3. **Model Coordination Gap**: No framework to route queries to specialized Ollama instances
4. **Workflow Integration**: Need bridge between AI agents and n8n automation

**What value does it deliver?**

| Value Area | Benefit |
|------------|---------|
| **Cost-Effective AI** | Self-hosted Ollama models eliminate cloud LLM API costs |
| **Accelerated Automation** | n8n integration enables visual assembly of AI-driven workflows |
| **Enhanced RAG Accuracy** | Multi-step reasoning with retrieval iteration |
| **Data Security** | All processing on-premise within HX network |
| **Modularity** | Fine-grained control over agent flow and state |
| **Leverage Investments** | Maximizes ROI on existing infrastructure (Ollama, Qdrant, LightRAG) |

### Strategic Alignment

**Constitution Alignment:**
- **Quality First**: Multi-agent testing with 100% coverage before deployment
- **Systematic Approach**: Phased deployment with validation gates
- **Layer-Aware Coordination**: Proper integration across infrastructure layers
- **SOLID Principles**: Clean architecture with proper abstraction boundaries

**Infrastructure Strategy Alignment:**
- Central orchestration hub for Model Serving & Inference Mesh layer
- Bridges Agentic + Toolchain layer with Data Plane layer
- Enables MCP ecosystem integration

---

## Scope

### In Scope

**This project INCLUDES:**

1. **LangGraph Framework Deployment** on hx-lang-server.hx.dev.local
2. **Multi-Agent Orchestration System** with supervisor pattern and specialized workers
3. **Ollama Integration** with dynamic model routing across 3 servers
4. **LightRAG Integration** for adaptive RAG workflows with retrieval iteration
5. **PostgreSQL Checkpointing** for durable long-term state persistence
6. **Redis Integration** for session caching and ephemeral state
7. **FastAPI Wrapper** for API exposure with custom endpoints and middleware
8. **MCP Client Integration** starting with Crawl4AI MCP (via FastMCP gateway)
9. **n8n Integration** with HTTP endpoint, webhooks, and custom node (phased)
10. **Claude Code Integration** for development and runtime agent coordination

**Capabilities Delivered:**

| Phase | Capabilities |
|-------|--------------|
| **Phase 1** | Multi-agent supervisor + 2-3 specialized workers, Ollama routing, LightRAG RAG |
| **Phase 2** | n8n integration (HTTP + webhooks + custom node), MCP ecosystem expansion, Full orchestration framework |
| **Phase 3** (Future) | AG-UI frontend integration (out of scope for this charter) |

### Out of Scope

**This project EXPLICITLY EXCLUDES:**

1. **AG-UI Frontend Deployment** - Future charter (LangGraph prepared for integration)
2. **New Ollama Model Deployment** - Use existing models on hx-ollama1/2/3-server
3. **LightRAG Modifications** - Use existing LightRAG service as-is
4. **Qdrant Configuration Changes** - Use existing vector database
5. **n8n Server Changes** - Only create workflows/nodes, no server modifications
6. **Production Performance Optimization** - Development environment focus

**Future Considerations (Backlog):**
- AG-UI frontend deployment and integration
- Observability integration with hx-metric-server
- Automated model selection based on query classification
- Dynamic tool creation for infrastructure service interaction
- Multi-agent collaboration patterns (agentic model merging)

### Boundaries and Constraints

**Technical Constraints:**
- Must use existing Ollama servers (hx-ollama1/2/3-server.hx.dev.local)
- Must integrate with existing LightRAG (hx-literag-server.hx.dev.local)
- Must use existing PostgreSQL (hx-postgres-server.hx.dev.local) and Redis (hx-redis-server.hx.dev.local)
- LangGraph requires Python 3.10+
- MCP integration via existing FastMCP gateway (hx-fastmcp-server.hx.dev.local)

**Resource Constraints:**
- Single server allocation (hx-lang-server.hx.dev.local)
- Development environment - no production SLA requirements

**Operational Constraints:**
- Bare metal deployment using systemd (HX-Infrastructure philosophy)
- Manual operational procedures (no Ansible playbooks)
- Ansible Vault for credential management only
- **NO FIREWALL** - All firewalls disabled in dev environment
- **SOLID OOP Principles** - All code must follow Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion

---

## Success Criteria

### Measurable Success Criteria

**The project is successful when:**

1. **Adaptive RAG Workflow Operational**
   - Metric: RAG workflow with conditional logic executes successfully
   - Target: Retrieval iteration when initial results insufficient
   - Validation: End-to-end test with document query requiring multiple retrievals

2. **Multi-Ollama Model Routing Working**
   - Metric: Dynamic routing to appropriate Ollama server based on query type
   - Target: General queries → ollama1, Code queries → ollama2, Embeddings → ollama3 (via LightRAG)
   - Validation: Query classification test with routing verification

3. **n8n Integration Complete**
   - Metric: n8n workflow can invoke LangGraph agent and process response
   - Target: HTTP endpoint + webhook callback + custom node available
   - Validation: n8n workflow test with agent invocation

4. **State Persistence Functional**
   - Metric: Conversations persist across service restarts
   - Target: PostgreSQL checkpoints + Redis session cache
   - Validation: Conversation continuity test with service restart

5. **MCP Tool Integration Working**
   - Metric: LangGraph agents can invoke Crawl4AI MCP tools
   - Target: Web crawling tool accessible via FastMCP gateway
   - Validation: Agent-initiated crawl operation test

### Acceptance Criteria

**Project can be accepted when:**
- [ ] All success criteria met
- [ ] All in-scope deliverables completed for current phase
- [ ] 100% test coverage achieved
- [ ] Documentation complete
- [ ] Operational readiness validated
- [ ] Stakeholder sign-off obtained

### Quality Metrics

**Quality will be measured by:**
- Test pass rate: Target 100%
- API response (simple query): Target <5 seconds
- Checkpoint persistence: Target 100% durability
- Integration connectivity: Target all services reachable

---

## Stakeholders and Roles

### Primary Stakeholders

| Stakeholder | Role | Responsibility | Decision Authority |
|-------------|------|----------------|-------------------|
| CAIO | Project Owner | Strategic direction, final approval | Charter, scope, priority |
| Agent Zero | Orchestrator | Multi-agent coordination, synthesis | Agent assignment |
| Sophia | Technical Lead | LangGraph architecture, implementation | Technical decisions |
| Alex Rivera | Architecture | System design oversight | Architecture patterns |
| William Chen | Infrastructure | Deployment, operations | Infrastructure decisions |
| Julia Santos | Quality | Testing, validation | Quality gates |

### Agent Assignments (Preliminary)

| Agent | Specialization | Role in Project |
|-------|---------------|-----------------|
| **Sophia** | LangGraph Orchestration | Primary implementation lead |
| **Bob** | FastAPI | API wrapper implementation |
| **Trinity** | PostgreSQL | Checkpoint database setup |
| **Sri** | Redis | Session/cache integration |
| **Andy** | LightRAG | RAG integration patterns |
| **Jim** | Ollama | Model routing configuration |
| **Isabella** | n8n | Workflow automation integration (Phase 2) |
| **George** | FastMCP | MCP gateway integration |
| **David** | Crawl4AI MCP | Initial MCP tool integration |

### Communication Plan

**Status Updates:** As needed during development
**Escalation Path:** Agent Zero → CAIO
**Decision-Making Process:** Documented in charter/ADRs

---

## High-Level Approach

### Architecture Overview

```
                    ┌─────────────────────────────────────────┐
                    │         hx-lang-server                  │
                    │                                         │
   User/n8n ───────▶│  ┌─────────────────────────────────┐   │
                    │  │       FastAPI Wrapper            │   │
                    │  └─────────────┬───────────────────┘   │
                    │                │                        │
                    │  ┌─────────────▼───────────────────┐   │
                    │  │    LangGraph Supervisor Agent    │   │
                    │  │    (State Management + Routing)  │   │
                    │  └─┬───────────┬───────────────┬───┘   │
                    │    │           │               │        │
                    │  ┌─▼─┐      ┌─▼──┐         ┌─▼──┐      │
                    │  │RAG│      │Code│         │Tool│      │
                    │  │Agt│      │Agt │         │Agt │      │
                    │  └─┬─┘      └─┬──┘         └─┬──┘      │
                    │    │          │              │          │
                    └────┼──────────┼──────────────┼──────────┘
                         │          │              │
    ┌────────────────────┼──────────┼──────────────┼─────────────────┐
    │                    │          │              │                  │
    ▼                    ▼          ▼              ▼                  ▼
┌────────┐    ┌──────────────┐  ┌────────┐   ┌──────────┐    ┌────────────┐
│LightRAG│    │Ollama1 (Gen) │  │Ollama2 │   │ FastMCP  │    │ PostgreSQL │
│        │    │              │  │ (Code) │   │ Gateway  │    │            │
└────────┘    └──────────────┘  └────────┘   └────┬─────┘    └────────────┘
     │                                            │                │
     ▼                                       ┌────▼─────┐    ┌────────────┐
┌────────┐                                   │Crawl4AI  │    │   Redis    │
│ Qdrant │                                   │   MCP    │    │            │
└────────┘                                   └──────────┘    └────────────┘
```

**Key Components:**
1. **FastAPI Wrapper** - API exposure with custom endpoints, middleware
2. **LangGraph Supervisor** - Central orchestration with state management
3. **Specialized Worker Agents** - RAG, Code, Tool agents with specific capabilities
4. **Persistence Layer** - PostgreSQL (durable) + Redis (ephemeral)
5. **External Integrations** - Ollama, LightRAG, MCP, n8n

### Technology Stack

| Technology | Purpose |
|------------|---------|
| **LangGraph** | Agent orchestration framework |
| **LangChain** | LLM abstraction layer |
| **FastAPI** | API wrapper and custom endpoints |
| **langgraph-checkpoint-postgres** | Durable state persistence |
| **langchain-ollama** | Ollama integration |
| **langchain-mcp-adapters** | MCP tool integration |
| **Pydantic** | Data validation and settings |
| **psycopg3** | PostgreSQL async driver |
| **redis-py** | Redis client with pooling |

### Deployment Strategy

**Phase 1: Core LangGraph + RAG**
- Deploy LangGraph with supervisor + 2-3 worker agents
- Configure PostgreSQL checkpointing
- Integrate Redis for session management
- Connect to Ollama servers (dynamic routing)
- Integrate LightRAG for RAG workflows
- Expose via FastAPI

**Phase 2: n8n + MCP Expansion**
- Add n8n integration (HTTP + webhooks + custom node)
- Integrate Crawl4AI MCP via FastMCP gateway
- Build extensible MCP tool registration
- Full orchestration framework

**Phase 3: AG-UI (Future Charter)**
- Prepare LangGraph for AG-UI integration
- AG-UI deployment as separate project

---

## Timeline and Milestones

### Key Milestones

| Milestone | Deliverables | Dependencies |
|-----------|--------------|--------------|
| Charter Approval | Approved charter | CAIO review |
| Specification Complete | node-spec.md | Charter approval |
| Phase 1: Core Complete | LangGraph + RAG operational | Specification |
| Phase 2: Integration Complete | n8n + MCP working | Phase 1 |
| Testing Complete | All tests passing | Implementation |
| Deployment Complete | Service operational | Testing |
| Project Closure | Documentation, lessons learned | Deployment |

### Phasing Summary

| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| **Phase 1** | Core LangGraph + RAG | Supervisor agent, worker agents, Ollama routing, LightRAG integration, state persistence |
| **Phase 2** | n8n + MCP Integration | n8n HTTP/webhook/node, Crawl4AI MCP, full orchestration framework |

---

## Resources

### Agent/Team Allocation

**Primary Agents:**
- **Sophia** (LangGraph SME): Technical lead, implementation
- **Bob** (FastAPI SME): API wrapper development
- **Trinity** (PostgreSQL DBA): Checkpoint database
- **Sri** (Redis SME): Session and cache management

**Supporting Agents:**
- **Andy** (LightRAG SME): RAG integration patterns
- **Jim** (Ollama SME): Model routing
- **Isabella** (n8n SME): Workflow integration (Phase 2)
- **George** (FastMCP SME): MCP gateway integration
- **David** (Crawl4AI MCP SME): Initial MCP integration

**Core Team SMEs:**
- **Alex Rivera**: Architecture oversight
- **William Chen**: Infrastructure deployment
- **Julia Santos**: Testing and quality

### Infrastructure Resources

**Required Infrastructure:**
- hx-lang-server.hx.dev.local: Primary deployment target
- hx-postgres-server.hx.dev.local: Checkpoint storage
- hx-redis-server.hx.dev.local: Session/cache storage

**Integration Points:**
- hx-ollama1-server.hx.dev.local: General LLM
- hx-ollama2-server.hx.dev.local: Code LLM
- hx-ollama3-server.hx.dev.local: Embeddings (via LightRAG)
- hx-literag-server.hx.dev.local: RAG pipeline
- hx-qdrant-server.hx.dev.local: Vector storage
- hx-fastmcp-server.hx.dev.local: MCP gateway
- hx-crawl4ai-mcp-server.hx.dev.local: Crawl4AI MCP
- hx-n8n-server.hx.dev.local: Workflow automation

### Knowledge Resources

**Required Knowledge Repositories:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/langgraph/` - LangGraph framework
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/ag-ui-main/` - AG-UI protocol (future reference)
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/agentic-design-patterns-docs-main/` - Agentic patterns
- `mcp-crawl4ai-rag` - Crawl4AI MCP integration
- `lightrag-main` - LightRAG integration

---

## Dependencies and Prerequisites

### Internal Dependencies

| Dependency | Status | Impact if Delayed |
|------------|--------|-------------------|
| hx-postgres-server operational | Operational | Blocks checkpoint persistence |
| hx-redis-server operational | Operational | Blocks session management |
| hx-ollama1/2/3-server operational | Operational | Blocks LLM integration |
| hx-literag-server operational | Operational | Blocks RAG integration |
| hx-fastmcp-server operational | Operational | Blocks MCP integration |
| hx-crawl4ai-mcp-server operational | Operational | Blocks initial MCP tool |
| hx-n8n-server operational | Operational | Blocks workflow integration |

### Prerequisites

**Must be complete before project starts:**
- [x] All dependent services operational
- [x] Knowledge vault repositories available
- [x] hx-lang-server.hx.dev.local accessible
- [ ] Python 3.10+ installed on target server

---

## Risks and Assumptions

### Initial Risk Assessment

**Top 3-5 Critical Risks Only** (detailed tracking in RAIDD log)

| Risk ID | Risk Description | Likelihood | Impact | Mitigation Strategy |
|---------|-----------------|------------|--------|---------------------|
| R-001 | LangGraph-Ollama integration complexity | M | H | Use proven langchain-ollama patterns |
| R-002 | PostgreSQL checkpoint schema migration | L | M | Use langgraph-checkpoint-postgres stable version |
| R-003 | MCP adapter compatibility issues | M | M | Start with single MCP (Crawl4AI), expand incrementally |
| R-004 | n8n custom node development complexity | M | M | Phase 2 scope, HTTP/webhook first |

### Key Assumptions

**Top 3-5 Critical Assumptions Only** (detailed tracking in RAIDD log)

1. **Ollama servers have sufficient capacity** for additional LangGraph-routed requests
   - Validation: Load testing during development

2. **LightRAG API is stable** and won't require modifications
   - Validation: Review LightRAG documentation, test connectivity

3. **langchain-mcp-adapters supports current MCP protocol version**
   - Validation: Verify adapter compatibility with FastMCP gateway

4. **Python 3.10+ can be installed** on hx-lang-server without conflicts
   - Validation: Pre-deployment verification

---

## Governance and Approval

### Charter Review

**Reviewed By:**
- [x] Project Owner (CAIO) - Date: 2025-12-01
- [x] Technical Lead (Agent Zero) - Date: 2025-12-01

### Charter Approval

**Approved By:**

**Project Owner:** CAIO
**Signature:** APPROVED
**Date:** 2025-12-01

### Constitution Validation

**Constitution Alignment Verified:** [x]
**Notes:** Phased approach with validation gates aligns with Quality First principle

---

## Next Steps After Charter Approval

### Immediate Next Actions

1. **Review and Update RAIDD Log**
   - Add risks R-001 through R-004 with full details
   - Add assumptions A-001 through A-004 with validation plans

2. **Review and Update Backlog**
   - Add out-of-scope items:
     - AG-UI frontend deployment
     - Observability integration (hx-metric-server)
     - Automated model selection
     - Dynamic tool creation
     - Multi-agent collaboration patterns

3. **Setup Project Structure**
   - Create `/nodes/hx-lang-server/specification/`
   - Create `/nodes/hx-lang-server/planning/`
   - Create `/nodes/hx-lang-server/tasks/`
   - Create `/nodes/hx-lang-server/tests/`

4. **Kick-off with Team**
   - Review charter with assigned agents
   - Knowledge assignment review (LangGraph, agentic patterns repos)
   - Begin specification work

### Documents to Create Next

- [ ] `nodes/hx-lang-server/specification/node-spec.md` - Detailed specification
- [ ] `nodes/hx-lang-server/planning/plan.md` - Deployment plan
- [ ] `nodes/hx-lang-server/planning/deployment-architecture.md` - Architecture details

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-01 | Agent Zero | Initial charter creation |
| 1.1 | 2025-12-01 | Agent Zero | Added SOLID OOP principles, NO FIREWALL dev env constraint |

---

## Charter Checklist

### Content Completeness
- [x] Vision and purpose clearly articulated
- [x] Scope (in/out) explicitly defined
- [x] Success criteria measurable and specific
- [x] Stakeholders identified with roles
- [x] Timeline with milestones
- [x] Resources identified and allocated
- [x] Dependencies documented
- [x] Top 3-5 critical risks listed
- [x] Top 3-5 key assumptions listed
- [ ] Approval signatures obtained

### Quality Checks
- [x] Aligns with constitution principles
- [x] Success criteria are SMART
- [x] Scope is clear and realistic
- [x] Dependencies are actionable
- [x] Risks have mitigation strategies
- [x] Phased approach defined
- [x] SOLID OOP principles mandated
- [x] Development environment constraints documented (no firewall)

---

**Charter Version:** 1.1
**Last Updated:** 2025-12-01
**Status:** APPROVED
