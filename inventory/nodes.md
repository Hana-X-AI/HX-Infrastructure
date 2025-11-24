# HX-Infrastructure Platform Nodes – Capabilities & Status

**Document Type**: Current State Documentation - Infrastructure Inventory  
**Created**: 2025-11-05  
**Last Updated**: 2025-11-15  
**Status**: ACTIVE - Authoritative Infrastructure Baseline  
**Location**: `/home/agent0/HX-Infrastructure/inventory/nodes.md`

---

## Document Purpose

This document provides a comprehensive inventory of all server nodes in HX-Infrastructure, including their capabilities, responsibilities, operational status, and deployment details. This is a **snapshot of actual production infrastructure** as of the last update date.

### Document Classification

**Type**: Current State Documentation - Infrastructure Inventory
- ✅ Represents actual deployed infrastructure
- ✅ Specific server configurations and status are production values
- ✅ Updated as servers are deployed or decommissioned
- ⚠️ For node documentation template, see `templates/node-template.md` (when created)

**Status Legend**: 
- ✅ **Operational** - Deployed, tested, and validated for production use
- 🛠️ **In Progress** - Deployed but not yet fully validated/configured
- ⬜ **Planned** - To be deployed (design complete, awaiting implementation)
- ⚠️ **Reserved** - IP allocated, not yet deployed

---

## Identity, Trust, and Control

### hx-dc-server (192.168.10.200) – ✅ Operational
**Role:** Domain Controller & Authentication Hub (Samba/LDAP, Kerberos) for `hx.dev.local`.  
**Primary Responsibilities:** 
- Central user/group management
- Single Sign-On (SSO) for Open WebUI and internal applications
- Policy enforcement across infrastructure
- DNS services for hx.dev.local domain

**Data/Paths:** 
- `/var/lib/samba` - Samba domain data
- `/etc/samba` - Samba configuration

**Integration Points:**
- All servers authenticate via this DC
- DNS resolution for all hx.dev.local hosts

**Validation Status:** ✅ All services operational, domain joined servers verified

---

### hx-ca-server (192.168.10.201) – ✅ Operational
**Role:** Internal Certificate Authority (Root CA + Issuing CA).  
**Primary Responsibilities:** 
- Issue and renew TLS certificates for all internal services
- Maintain Certificate Revocation List (CRL) and OCSP responder
- Provide SSH certificate trust foundation
- Certificate lifecycle management

**Data/Paths:** 
- `/var/ca/private` - Private keys (secured)
- `/var/ca/certs` - Issued certificates
- `/var/ca/crl` - Certificate revocation lists

**Integration Points:**
- All HTTPS services use certificates from this CA
- hx-ssl-server retrieves certificates for reverse proxy

**Validation Status:** ✅ Certificate issuance tested, trust chain verified

---

### hx-ssl-server (192.168.10.202) – ✅ Operational
**Role:** Reverse Proxy / TLS Termination (Nginx/Traefik).  
**Primary Responsibilities:** 
- Front all user-facing UIs and APIs
- Enforce HTTPS and mutual TLS (mTLS) where required
- Route traffic to application backends
- Load balancing (when multiple backends available)

**Data/Paths:** 
- `/etc/nginx` or `/etc/traefik` - Proxy configuration
- `/etc/ssl/hx` - TLS certificates from hx-ca-server

**Integration Points:**
- Terminates TLS for hx-webui-server, hx-agui-server, hx-demo-server
- Routes to backend services

**Validation Status:** ✅ Reverse proxy operational, HTTPS routing verified

---

### hx-control-node (192.168.10.203) – ✅ Operational
**Role:** Ansible Control Plane.  
**Primary Responsibilities:** 
- Fleet-wide configuration management
- Idempotent server provisioning
- Secrets management via Ansible Vault
- Infrastructure-as-Code deployment automation

**Data/Paths:** 
- `/srv/ansible/inventories` - Server inventories
- `/srv/ansible/roles` - Ansible roles
- `/srv/ansible/playbooks` - Deployment playbooks
- `/srv/ansible/group_vars` - Group variables

**Integration Points:**
- SSH access to all servers for configuration management
- Manages deployment of services across infrastructure

**Validation Status:** ✅ Ansible automation operational, fleet management verified

---

## Model Serving and Inference Mesh

### hx-ollama{1,2,3}-server (192.168.10.204–206) – ✅ Operational
**Role:** LLM Model Hosts (Ollama).  
**Primary Responsibilities:**
- **hx-ollama1-server (.204):** Primary LLM serving node for general inference workloads
- **hx-ollama2-server (.205):** Code-focused model serving (specialized models for code generation/analysis)
- **hx-ollama3-server (.206):** Embeddings host **and** prompt-enhancement model

**Data/Paths:** 
- `/var/lib/ollama` - Model storage and cache

**Architecture Notes:** 
- The prompt-enhancement model on **ollama3** bypasses LiteLLM for low-latency preprocessing
- Connects **directly to UI-layer apps** (e.g., Open WebUI, custom applications)
- Other model traffic routes via **hx-litellm-server** for unified API gateway

**Integration Points:**
- hx-litellm-server proxies requests to all Ollama servers
- hx-webui-server connects directly to ollama3 for prompt enhancement

**Validation Status:** ✅ All three Ollama servers operational, models loaded and tested

---

### hx-litellm-server (192.168.10.212) – ✅ Operational
**Role:** Unified LLM API Gateway.  
**Primary Responsibilities:** 
- Route requests to appropriate Ollama nodes
- Broker tool calls via Model Context Protocol (MCP)
- Authentication and authorization integration
- Load balancing across model servers
- Request/response logging and metrics

**Data/Paths:** 
- `/etc/litellm` - Configuration files
- `/var/log/litellm/` - Request/response logs

**Integration Points:**
- Frontend: hx-webui-server, application servers
- Backend: hx-ollama1/2/3-server
- MCP: hx-fastmcp-server for tool execution

**Validation Status:** ✅ API gateway operational, integrated with Open WebUI

---

## Data Plane: Structured, Cache, and Vectors

### hx-postgres-server (192.168.10.209) – ✅ Operational
**Role:** System-of-Record Relational Database.  
**Primary Responsibilities:** 
- Application state persistence
- Metadata storage
- Audit logging
- Write-Ahead Log (WAL) archiving for point-in-time recovery

**Data/Paths:** 
- `/var/lib/postgresql/data` - Database cluster
- WAL archive configured for backup/recovery

**Integration Points:**
- Used by: hx-docling-server, hx-crawl4ai-server, hx-literag-server, application servers

**Validation Status:** ✅ Database operational, WAL archiving configured

---

### hx-redis-server (192.168.10.210) – ✅ Operational
**Role:** Redis Cache Server with Web UI.  
**Primary Responsibilities:** 
- Low-latency caching layer
- Message queues for async processing
- Rate limiting and session storage
- Redis UI provides graphical interface (eliminates CLI-only management)

**Data/Paths:** 
- `/var/lib/redis` - Persistence data (RDB/AOF)

**Ports:**
- 6379 - Redis server
- 8001 - Redis UI web interface

**Integration Points:**
- Used by: Application servers, hx-lang-server (when operational)

**Validation Status:** ✅ Redis operational, Redis UI accessible

---

### hx-qdrant-server (192.168.10.207) – ✅ Operational
**Role:** Vector Database.  
**Primary Responsibilities:** 
- Store embeddings for semantic search
- RAG (Retrieval-Augmented Generation) indices
- Vector similarity search
- Snapshots aligned with Postgres backups

**Data/Paths:** 
- `/var/lib/qdrant` - Vector collections and indices

**Ports:**
- 6333 - REST API
- 6334 - gRPC API

**Integration Points:**
- Frontend: hx-qmcp-server (MCP interface)
- Backend: hx-literag-server, application services

**Validation Status:** ✅ Vector database operational, collections verified

---

### hx-qdrant-ui-server (192.168.10.208) – ✅ Operational
**Role:** Qdrant Web UI.  
**Primary Responsibilities:** 
- Graphical interface for managing Qdrant vector databases
- Support for both self-hosted and cloud Qdrant instances
- View, interact with, and manage vector collections
- Similar to Kibana for Elasticsearch

**Port:** 3000 - Web UI

**Integration Points:**
- Connects to hx-qdrant-server for visualization

**Validation Status:** ✅ Web UI operational, connected to Qdrant server

---

### hx-qmcp-server (192.168.10.211) – ✅ Operational
**Role:** Qdrant Model Context Protocol (MCP) Server.  
**Primary Responsibilities:** 
- Connect AI agents to Qdrant vector database
- Provide persistent, semantic memory for agents
- Expose Qdrant's vector search capabilities through standardized MCP interface
- Enable agents to store and retrieve embeddings

**Integration Points:**
- MCP Gateway: hx-fastmcp-server
- Vector DB: hx-qdrant-server
- Clients: AI agents via MCP protocol

**Validation Status:** ✅ MCP server operational, Qdrant integration verified

---

## Agentic + Toolchain

> **Note:** `hx-fastmcp-server` includes a **Brave Search MCP** integration (plugin/internal client) that enables secure web and document search, exposed through FastMCP's unified interface.

### hx-fastmcp-server (192.168.10.213) – ✅ Operational
**Includes:** Brave Search MCP client for secure, context-aware web search and retrieval.  
**Role:** High-throughput MCP **server + client** (unified entry point).  
**Primary Responsibilities:** 
- Execute tools at scale for AI agents
- Expose standardized MCP endpoints
- **Compose and proxy** downstream MCP services within single Python application
- Route MCP requests to specialized services (Qdrant, Docling, Crawl4AI, etc.)

**Port:** 8000 - MCP Gateway

**Integration Points:**
- Frontend: hx-webui-server, application servers
- Backend MCP Services: hx-qmcp-server, hx-docling-mcp-server (when operational), hx-crawl4ai-mcp-server, hx-n8n-mcp-server
- Search: Internal Brave Search MCP client

**Validation Status:** ✅ MCP gateway operational, tool execution verified

---

### hx-n8n-mcp-server (192.168.10.214) – ✅ Operational
**Role:** n8n Model Context Protocol (MCP) Server.  
**Primary Responsibilities:** 
- Bridge between LLMs and n8n workflows
- Allow AI assistants to securely interact with and control n8n workflows through standardized MCP interface
- Enable agents to leverage n8n's visual, low-code automation for real-world task execution
- Workflow triggering and monitoring via MCP

**Data/Paths:** `/srv/n8n-mcp-deployment`

**Deployment Date:** November 11, 2025

**Integration Points:**
- MCP Gateway: hx-fastmcp-server
- Workflow Engine: hx-n8n-server
- Clients: AI agents via MCP protocol

**Validation Status:** ✅ MCP server operational, n8n integration verified

---

### hx-n8n-server (192.168.10.215) – ✅ Operational
**Role:** Workflow Automation and Orchestration Platform.  
**Primary Responsibilities:** 
- Visual workflow builder for integrating apps and automating business processes
- Job scheduling and execution
- CI/CD workflow automation
- Notification and alert management
- Data synchronization across systems

**Data/Paths:** 
- `/srv/n8n` - Workflows, credentials, execution data

**Port:** 5678 - Web UI and API

**Deployment Date:** November 15, 2025

**Integration Points:**
- MCP Interface: hx-n8n-mcp-server
- External APIs: Various third-party integrations
- Database: Uses PostgreSQL for persistence (via hx-postgres-server)

**Validation Status:** ✅ Operational - Login tested, workflows executable

---

### hx-docling-server (192.168.10.216) – ✅ Operational
**Role:** Docling Worker Node.  
**Primary Responsibilities:** 
- Internal and external document retrieval
- Document parsing (PDF, DOCX, etc.)
- Document format conversion
- Text extraction and preprocessing

**Integration Points:**
- MCP Interface: hx-docling-mcp-server (NOT YET OPERATIONAL)
- Database: hx-postgres-server (document metadata storage)

**Validation Status:** ✅ Worker operational, document processing verified
**Note:** MCP server interface not yet operational (hx-docling-mcp-server)

---

### hx-docling-mcp-server (192.168.10.217) – ⬜ Planned
**Role:** Docling MCP Endpoint.  
**Primary Responsibilities:** 
- Expose document parsing and ingestion capabilities to AI agents via MCP
- Provide standardized interface for document processing requests
- Queue and manage document processing jobs

**Integration Points:**
- MCP Gateway: hx-fastmcp-server (when operational)
- Worker: hx-docling-server
- Clients: AI agents via MCP protocol

**Validation Status:** ⬜ Not yet operational - Requires deployment and configuration
**Blockers:** MCP interface implementation pending

---

### hx-crawl4ai-mcp-server (192.168.10.218) – ✅ Operational
**Role:** Crawl4AI MCP Endpoint.  
**Primary Responsibilities:** 
- Provide controlled web scraping capabilities through MCP for AI agents
- Request validation and rate limiting
- Crawl job management and monitoring
- Results formatting and delivery

**Integration Points:**
- MCP Gateway: hx-fastmcp-server
- Worker: hx-crawl4ai-server
- Clients: AI agents via MCP protocol

**Validation Status:** ✅ MCP server operational, crawl requests verified

---

### hx-crawl4ai-server (192.168.10.219) – ✅ Operational
**Role:** Crawl4AI Worker Node.  
**Primary Responsibilities:** 
- Execute web crawling for internal and external sites
- Corpus gathering for knowledge base construction
- Structured data extraction from web pages
- Rate-limited, respectful crawling

**Integration Points:**
- MCP Interface: hx-crawl4ai-mcp-server
- Database: hx-postgres-server (crawled content storage)

**Validation Status:** ✅ Worker operational, crawling functional

---

### hx-literag-server (192.168.10.220) – ✅ Operational
**Role:** LightRAG Server.  
**Primary Responsibilities:** 
- Efficient Retrieval-Augmented Generation (RAG) framework
- Build knowledge graph of relationships between entities and concepts
- Dual-level retrieval:
  - Semantic vector search (via Qdrant)
  - Knowledge graph context
- Generate comprehensive and relevant answers combining both retrieval methods

**Integration Points:**
- Vector DB: hx-qdrant-server (embeddings and semantic search)
- Database: hx-postgres-server (knowledge graph storage)
- Clients: Application servers, AI agents

**Validation Status:** ✅ RAG framework operational, dual-level retrieval verified

---

### hx-coderabbit-server (192.168.10.228) – ⚠️ Reserved
**Role:** CodeRabbit MCP Server.  
**Primary Responsibilities:** 
- Allow AI agents to interact with CodeRabbit AI platform via MCP
- Provide local Git repository integration
- AI-assisted code review capabilities
- Development context integration for agents

**Port:** 8005 (designated, not yet bound)

**Status:** Reserved - IP allocated, not yet deployed

**Integration Points (Planned):**
- MCP Gateway: hx-fastmcp-server
- Local Git repositories
- CodeRabbit AI platform API

**Validation Status:** ⚠️ Not deployed - Awaiting implementation

---

### hx-shadcn-server (192.168.10.229) – ⬜ Planned
**Role:** Shadcn MCP Server.  
**Primary Responsibilities:** 
- Standalone TypeScript-based server
- Act as bridge between AI agents and component registries
- Enable structured component discovery
- Component integration automation

**Status:** Planned - IP allocated, not yet deployed

**Integration Points (Planned):**
- MCP Gateway: hx-fastmcp-server
- Component registries (shadcn/ui, etc.)
- Frontend development workflows

**Validation Status:** ⬜ Not deployed - Awaiting requirements finalization

---

## Application and User-Facing Layers

### hx-webui-server (192.168.10.227) – ✅ Operational
**Role:** Open WebUI for Chat/Agent User Experience.  
**Primary Responsibilities:** 
- Provide full MCP tool access to end users
- User authentication via Domain Controller/Kerberos
- Chat interface for AI agent interactions
- Real-time streaming of agent responses
- Session management and conversation history

**Port:** 3000 - Web UI (behind hx-ssl-server reverse proxy)

**Integration Points:**
- Auth: hx-dc-server (Kerberos SSO)
- LLM Gateway: hx-litellm-server
- Direct LLM: hx-ollama3-server (prompt enhancement bypass)
- MCP Tools: hx-fastmcp-server
  - Docling/Crawl4AI document processing
  - Qdrant via hx-qmcp-server
- Ingress: hx-ssl-server (TLS termination)

**Validation Status:** ✅ Operational - Integrated with LiteLLM, MCP tools accessible

---

### hx-agui-server (192.168.10.221) – ⬜ Planned
**Role:** AG-UI (Agent-User Interaction Protocol) Application Server.  
**Primary Responsibilities:** 
- Implement AG-UI protocol for standardized agent-user interactions
- Event-based communication (SSE, WebSockets)
- Real-time agentic chat with streaming
- Bi-directional state synchronization
- Generative UI and structured messages
- Frontend tool integration
- Human-in-the-loop collaboration workflows

**Technology Stack:**
- TypeScript/Node.js runtime
- AG-UI SDK (@ag-ui/core, @ag-ui/client)
- Framework integrations: LangGraph, Mastra, CrewAI, Pydantic AI, etc.

**Port:** TBD (3001 recommended to avoid conflict with Open WebUI)

**Integration Points (Planned):**
- LLM Gateway: hx-litellm-server
- MCP Tools: hx-fastmcp-server
- Agent Frameworks: hx-lang-server (LangGraph when operational)
- Auth: hx-dc-server
- Ingress: hx-ssl-server

**Status:** ⬜ Not yet operational - Requires deployment
**Related Documentation:** 
- AG-UI Protocol: See repository documentation
- Framework integrations available for: LangGraph, Mastra, CrewAI, Pydantic AI, Google ADK, Agno, LlamaIndex, AG2

**Validation Status:** ⬜ Not deployed - AG-UI server setup pending

---

### hx-dev-server (192.168.10.222) – ⬜ Planned
**Role:** Development Environment for Custom Applications.  
**Primary Responsibilities:** 
- Build and run containerized Next.js solutions
- Isolated development environments (Docker-based)
- Custom application development and testing
- Consume platform services (LiteLLM, LangGraph, MCP services)
- Hot-reload development workflows

**Technology Stack:**
- Docker/Docker Compose for container isolation
- Next.js framework
- TypeScript/JavaScript development

**Data/Paths (Planned):** 
- `/srv/apps/dev` - Application source and containers
- Container registry integration (TBD)
- SCM integration (Git repositories)

**Integration Points (Planned):**
- LLM: hx-litellm-server
- MCP: hx-fastmcp-server
- Agents: hx-lang-server (when operational)
- Vector DB: hx-qmcp-server
- Ingress: hx-ssl-server

**Status:** ⬜ Not operational - Requires Docker environment setup
**Blockers:** 
- Docker containerization environment not yet configured
- Need isolated development container infrastructure

**Validation Status:** ⬜ Not deployed - Container infrastructure pending

---

### hx-demo-server (192.168.10.223) – 🛠️ In Progress
**Role:** Demo Environment for Stakeholder Presentations.  
**Primary Responsibilities:** 
- Receive promoted containers from hx-dev-server
- Host stable application versions for demonstrations
- Mirror production platform integrations
- Provide controlled environment for stakeholder access

**Data/Paths (Planned):** 
- `/srv/apps/demo` - Promoted application containers
- Container registry integration (TBD)

**Integration Points (Planned):**
- Same as hx-dev-server (LiteLLM, MCP, LangGraph, etc.)
- Receives promoted builds from dev environment
- Ingress: hx-ssl-server

**Status:** 🛠️ In Progress - Infrastructure allocated, configuration pending
**Dependencies:** 
- hx-dev-server container pipeline
- Promotion workflow from dev to demo

**Validation Status:** 🛠️ Partially configured - Awaiting container promotion workflow

---

## Integration, Coordination, and Observability

### hx-cc-server (192.168.10.224) – ✅ Operational
**Role:** Claude Code Systems Integrator & Knowledge Hub.  
**Primary Responsibilities:** 
- Coordinate agent execution runs
- Manage local knowledge repositories
- Infrastructure orchestration via Claude Code
- System integration and coordination

**Authoritative Storage (Updated Paths):**
- `/home/agent0/HX-Infrastructure` - Main infrastructure repository
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos` - Knowledge vault
- `/home/agent0/HX-Infrastructure/hx-knowledge/docs` - Documentation

**Integration Points:**
- All infrastructure nodes (orchestration)
- Knowledge management across services
- Agent coordination

**Validation Status:** ✅ Operational - Claude Code integration functional

---

### hx-metric-server (192.168.10.225) – ⬜ Planned
**Role:** Metrics and Telemetry Collection (Planned).  
**Primary Responsibilities:** 
- Centralized logging aggregation
- Metrics collection (Prometheus)
- Long-term retention storage
- Grafana dashboards for visualization
- Alerting and notification

**Planned Stack:**
- Prometheus (metrics collection) - Port 9090
- Grafana (dashboards) - Port 3001
- Alertmanager (notifications) - Port 9093
- Log aggregation (Loki or similar)

**Status:** ⬜ Not operational - Planned for future deployment
**Note:** Some basic metrics may be collected individually by services, but centralized observability is not yet implemented

**Validation Status:** ⬜ Not deployed - Observability stack pending

---

### hx-lang-server (192.168.10.226) – ⬜ Planned
**Role:** LangGraph Server.  
**Primary Responsibilities:** 
- Host LangGraph instance for agent workflow orchestration
- State management for multi-agent systems
- Graph-based agent execution
- Used by applications and agents for complex workflow chaining

**Technology Stack:**
- LangGraph (NOT LangChain)
- Python runtime
- Integration with LLM providers via hx-litellm-server

**Integration Points (Planned):**
- LLM: hx-litellm-server
- Database: hx-postgres-server (state persistence)
- Cache: hx-redis-server (session state)
- Vector: hx-qdrant-server (RAG integration)
- Applications: hx-dev-server, hx-demo-server, hx-agui-server

**Status:** ⬜ Not operational - LangGraph deployment pending
**Note:** This server will run **LangGraph** (agent orchestration framework), NOT LangChain

**Validation Status:** ⬜ Not deployed - LangGraph server setup required

---

## Server Status Summary

### Deployment Statistics (Current State)

**Total Servers:** 30 nodes allocated

**Operational Status Breakdown:**
- **Operational (✅):** 22 nodes
  - Identity & Control: 4 nodes
  - Model & Inference: 4 nodes
  - Data Plane: 5 nodes
  - Agentic & Toolchain: 7 nodes (fastmcp, n8n-mcp, n8n, docling-worker, crawl4ai-mcp, crawl4ai-worker, literag)
  - Application Layer: 1 node (webui)
  - Integration: 1 node (cc-server)

- **In Progress (🛠️):** 1 node
  - hx-demo-server

- **Planned (⬜):** 5 nodes
  - hx-docling-mcp-server (worker operational, MCP interface pending)
  - hx-agui-server (AG-UI protocol server)
  - hx-dev-server (Docker environment required)
  - hx-metric-server (observability stack)
  - hx-lang-server (LangGraph orchestration)

- **Reserved (⚠️):** 2 nodes
  - hx-coderabbit-server (IP allocated, port designated)
  - hx-shadcn-server (IP allocated)

- **Not Counted:** 1 node
  - Gateway (192.168.10.1) - Network infrastructure, not server

**Total Accounted:** 22 + 1 + 5 + 2 = 30 servers + 1(gateway) = 31 total ✓

### Service Category Distribution

| Category | Nodes | Operational | In Progress | Planned | Reserved |
|----------|-------|-------------|-------------|---------|----------|
| Identity & Control | 4 | 4 | 0 | 0 | 0 |
| Model & Inference | 4 | 4 | 0 | 0 | 0 |
| Data Plane | 5 | 5 | 0 | 0 | 0 |
| Agentic & Toolchain | 10 | 7 | 0 | 1 | 2 |
| Application Layer | 4 | 1 | 1 | 2 | 0 |
| Integration & Governance | 3 | 1 | 0 | 2 | 0 |
| **Totals** | **30** | **22** | **1** | **5** | **2** |

---

## Traceability to Architecture Documentation

### Alignment with HX-Infrastructure Standards

This node inventory aligns with HX-Infrastructure core documents:
1. **Network Topology** (`network/network-topology.md`) - IP allocations and zones match exactly
2. **Architecture Standards** (`standards/architecture-standards.md`) - Service patterns comply
3. **Documentation Requirements** (`standards/documentation-requirements.md`) - Format follows standards
4. **Testing Requirements** (`standards/testing-requirements.md`) - Validation status reflects test-driven deployment

### Updated Traceability Map

**Frontend/UI Layer:**
- `hx-webui-server` (✅ Operational - Open WebUI)
- `hx-agui-server` (⬜ Planned - AG-UI protocol)
- Custom Next.js apps: `hx-dev-server` (⬜ Planned) → `hx-demo-server` (🛠️ In Progress)

**Backend & Integration Services:**
- LLM Gateway: `hx-litellm-server` (✅)
- MCP Gateway: `hx-fastmcp-server` (✅ with Brave Search)
- Workflow: `hx-n8n-mcp-server` (✅), `hx-n8n-server` (✅)
- Document Processing: `hx-docling-server` (✅), `hx-docling-mcp-server` (⬜)
- Web Scraping: `hx-crawl4ai-mcp-server` (✅), `hx-crawl4ai-server` (✅)
- Agent Orchestration: `hx-lang-server` (⬜ - LangGraph)
- RAG Framework: `hx-literag-server` (✅)

**Data & Model Infrastructure:**
- Relational: `hx-postgres-server` (✅)
- Cache: `hx-redis-server` (✅)
- Vectors: `hx-qdrant-server` (✅), `hx-qdrant-ui-server` (✅), `hx-qmcp-server` (✅)
- Models: `hx-ollama1-server` (✅), `hx-ollama2-server` (✅), `hx-ollama3-server` (✅)

**Platform & Infrastructure:**
- Auth/DNS: `hx-dc-server` (✅)
- Certificates: `hx-ca-server` (✅)
- Ingress: `hx-ssl-server` (✅)
- Config Mgmt: `hx-control-node` (✅)

**DevOps & Governance:**
- Integration: `hx-cc-server` (✅)
- Observability: `hx-metric-server` (⬜)

**Reserved/Future:**
- Code Review: `hx-coderabbit-server` (⚠️)
- Component Library: `hx-shadcn-server` (⚠️)

---

## Appendix A – Host File Reference

**Current as of:** 2025-11-15

Below is the production static hosts file deployed across HX-Infrastructure. This matches the network topology exactly.

```
# =====================================================================
# HX-Infrastructure Project – Static hosts file
# Domain: hx.dev.local
# Generated: 2025-10-21
# Last Updated: 2025-11-15
# =====================================================================

127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters

# --- HX Servers -------------------------------------------------------
192.168.10.200  hx-dc-server.hx.dev.local            hx-dc-server
192.168.10.201  hx-ca-server.hx.dev.local            hx-ca-server
192.168.10.202  hx-ssl-server.hx.dev.local           hx-ssl-server
192.168.10.203  hx-control-node.hx.dev.local         hx-control-node
192.168.10.204  hx-ollama1-server.hx.dev.local       hx-ollama1-server
192.168.10.205  hx-ollama2-server.hx.dev.local       hx-ollama2-server
192.168.10.206  hx-ollama3-server.hx.dev.local       hx-ollama3-server
192.168.10.207  hx-qdrant-server.hx.dev.local        hx-qdrant-server
192.168.10.208  hx-qdrant-ui-server.hx.dev.local     hx-qdrant-ui-server
192.168.10.209  hx-postgres-server.hx.dev.local      hx-postgres-server
192.168.10.210  hx-redis-server.hx.dev.local         hx-redis-server
192.168.10.211  hx-qmcp-server.hx.dev.local          hx-qmcp-server
192.168.10.212  hx-litellm-server.hx.dev.local       hx-litellm-server
192.168.10.213  hx-fastmcp-server.hx.dev.local       hx-fastmcp-server
192.168.10.214  hx-n8n-mcp-server.hx.dev.local       hx-n8n-mcp-server
192.168.10.215  hx-n8n-server.hx.dev.local           hx-n8n-server
192.168.10.216  hx-docling-server.hx.dev.local       hx-docling-server
192.168.10.217  hx-docling-mcp-server.hx.dev.local   hx-docling-mcp-server
192.168.10.218  hx-crawl4ai-mcp-server.hx.dev.local  hx-crawl4ai-mcp-server
192.168.10.219  hx-crawl4ai-server.hx.dev.local      hx-crawl4ai-server
192.168.10.220  hx-literag-server.hx.dev.local       hx-literag-server
192.168.10.221  hx-agui-server.hx.dev.local          hx-agui-server
192.168.10.222  hx-dev-server.hx.dev.local           hx-dev-server
192.168.10.223  hx-demo-server.hx.dev.local          hx-demo-server
192.168.10.224  hx-cc-server.hx.dev.local            hx-cc-server
192.168.10.225  hx-metric-server.hx.dev.local        hx-metric-server
192.168.10.226  hx-lang-server.hx.dev.local          hx-lang-server
192.168.10.227  hx-webui-server.hx.dev.local         hx-webui-server
192.168.10.228  hx-coderabbit-server.hx.dev.local    hx-coderabbit-server
192.168.10.229  hx-shadcn-server.hx.dev.local        hx-shadcn-server
127.0.1.1       hx-control-node.hx.dev.local         hx-control-node
```

---

## Change Log

### Infrastructure Changes

| Date | Change Type | Description | Affected Servers | Changed By |
|------|-------------|-------------|------------------|------------|
| 2025-11-05 | Initial | Platform nodes initial documentation | All 30 servers | Infrastructure Team |
| 2025-11-11 | Deployment | Deployed hx-n8n-mcp-server | hx-n8n-mcp-server (.214) | Infrastructure Team |
| 2025-11-15 | Deployment | Deployed hx-n8n-server, validated operational | hx-n8n-server (.215) | Infrastructure Team |
| 2025-11-15 | Adaptation | Adapted for HX-Infrastructure from Hana-X | All documentation | HX-Infrastructure Team |
| 2025-11-15 | Correction | Corrected operational status for 6 servers | docling-mcp, agui, dev, metric, lang, shadcn | HX-Infrastructure Team |
| 2025-11-15 | Correction | Fixed LangChain → LangGraph for hx-lang-server | hx-lang-server (.226) | HX-Infrastructure Team |
| 2025-11-15 | Enhancement | Added AG-UI documentation section | hx-agui-server (.221) | HX-Infrastructure Team |
| 2025-11-15 | Correction | Fixed server count math (28→21 operational) | Server summary | HX-Infrastructure Team |

### Pending Changes

| Planned Date | Change Type | Description | Impact | Priority |
|--------------|-------------|-------------|--------|----------|
| TBD | Deployment | Deploy hx-docling-mcp-server | Complete Docling MCP integration | High |
| TBD | Deployment | Deploy hx-agui-server (AG-UI protocol) | Add AG-UI agent interaction capability | High |
| TBD | Deployment | Configure hx-dev-server Docker environment | Enable custom app development | High |
| TBD | Deployment | Deploy hx-metric-server observability stack | Centralized monitoring | High |
| TBD | Deployment | Deploy hx-lang-server (LangGraph) | Agent orchestration framework | High |
| TBD | Configuration | Complete hx-demo-server setup | Finish stakeholder demo environment | Medium |
| TBD | Deployment | Deploy hx-coderabbit-server | Code review automation | Medium |
| TBD | Deployment | Deploy hx-shadcn-server | Component library integration | Low |

---

## Document Maintenance

### Update Triggers

This document MUST be updated when:
- ✅ New servers deployed to infrastructure
- ✅ Server status changes (operational, in-progress, planned)
- ✅ IP address changes occur
- ✅ Service roles or responsibilities change
- ✅ Integration points are modified
- ✅ New capabilities are added to servers
- ✅ Servers are decommissioned

### Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-05 | Initial platform nodes documentation | Infrastructure Team |
| 2.0 | 2025-11-15 | Adapted for HX-Infrastructure, corrected status, added AG-UI, fixed LangGraph | HX-Infrastructure Team |

### Related Documents

**HX-Infrastructure Core Documents:**
- `constitution.md` - Project principles and philosophy
- `README.md` - Repository overview and navigation
- `action-plan-v2-updated.md` - Project roadmap and status

**Network and Infrastructure:**
- `network/network-topology.md` - Network architecture and IP allocations (v1.1.1)
- `network/port-mapping.md` - Service port assignments (when created)
- `nodes/<node-name>/node-spec.md` - Individual node specifications (when created)

**Standards:**
- `standards/naming-conventions.md` - Naming standards
- `standards/architecture-standards.md` - Architecture guidelines
- `standards/documentation-requirements.md` - Documentation standards
- `standards/testing-requirements.md` - Testing and validation requirements
- `standards/deployment-requirements.md` - Deployment procedures

**Agent Documentation:**
- `hx-agents/hx-agent-inventory.md` - 32 agents (5 Core Team SMEs + 27 Technology SMEs) and capabilities
- `hx-agents/hx-orchestration-guide.md` - Multi-agent workflows
- `CLAUDE.md` - Agent Zero orchestration instructions

**External References:**
- AG-UI Protocol Documentation: https://ag-ui.com/
- AG-UI GitHub Repository: https://github.com/ag-ui-protocol/ag-ui

---

**Document Information:**
- **Version**: 2.0
- **Status**: ACTIVE - Authoritative Infrastructure Baseline
- **Maintained By**: HX-Infrastructure Team
- **Review Frequency**: Weekly or upon infrastructure changes
- **Last Review**: 2025-11-15
- **Next Review**: 2025-11-22 (or upon significant change)

---

*This platform nodes inventory represents the current state of HX-Infrastructure's server deployment. It serves as the authoritative reference for server capabilities, operational status, and integration points. All infrastructure changes must be reflected in this document within 24 hours of implementation.*
