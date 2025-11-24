# HX-Infrastructure Agent Ecosystem Documentation

**Directory:** `/home/agent0/HX-Infrastructure/hx-agents/`
**Purpose:** Comprehensive documentation of the 32-agent specialist ecosystem (5 Core Team SMEs + 27 Technology SMEs)
**Last Updated:** 2025-11-24
**Status:** ✅ Production Documentation

---

## Overview

This directory contains comprehensive documentation for the HX-Infrastructure multi-agent ecosystem. The ecosystem consists of 32 agents (5 Core Team SMEs + 27 Technology SMEs) organized for systematic infrastructure development and operations, orchestrated by Agent Zero (Universal PM Orchestrator).

**Key Principle:** Layer-aware coordination with strict dependency management ensures services deploy in correct order with proper foundation layers operational first.

---

## Documents in This Directory

### 1. Agent Inventory
**File:** `hx-agent-inventory.md`
**Size:** 1,111 lines
**Purpose:** Complete inventory of all 32 agents (5 Core Team SMEs + 27 Technology SMEs) with roles, responsibilities, and knowledge requirements

**Contents:**
- **Layer 0:** Governance & Orchestration (2 agents)
  - agent-zero: Universal PM Orchestrator
  - alex: Platform Architect

- **Layer 1:** Identity & Trust (4 agents)
  - frank: Samba DC/LDAP/Kerberos
  - william: Ubuntu Systems Administrator
  - yasmin: Docker Platform
  - amanda: Ansible Automation

- **Layer 2:** Model & Inference (3 agents)
  - patricia: Ollama Cluster
  - maya: LiteLLM Gateway
  - laura: LangGraph Orchestration

- **Layer 3:** Data Plane (4 agents)
  - quinn: PostgreSQL
  - samuel: Redis
  - robert: Qdrant Vector DB
  - sarah: Qdrant Web UI

- **Layer 4:** Agentic & Toolchain (7 agents)
  - george: fastMCP Gateway
  - marcus: LightRAG Knowledge
  - brian: AG-UI Protocol
  - david: Crawl4AI MCP
  - diana: Crawl4AI Worker
  - carlos: CodeRabbit MCP
  - kevin: Continue.dev

- **Layer 5:** Application (16 agents)
  - Core infrastructure services
  - Application-specific services
  - Frontend and backend specialists

- **Layer 6:** Integration & Testing (2 agents)
  - isaac: CI/CD Pipeline
  - julia: Testing & Quality

- **Layer 7:** App-Agnostic Leads (3 agents)
  - nathan: Frontend Lead
  - fatima: Backend Lead
  - victor: Full-Stack Lead

- **Utility & Specialized:** (4 agents)
  - elena: NLP Specialist
  - paul: Data Science Specialist
  - omar: DevOps Specialist
  - olivia: Project Manager

**Each Agent Entry Includes:**
- Role and responsibilities
- Server and service information
- Critical dependencies
- Knowledge requirements (repository access)
- Profile file location
- Integration points

---

### 2. Knowledge Vault Catalog
**File:** `hx-knowledge-vault-catalog.md`
**Size:** 624 lines
**Purpose:** Catalog of all knowledge repositories available to agents

**Organization:**
Repositories organized by infrastructure layer matching agent organization:

**Layer 1: Identity & Trust**
- Samba, LDAP, Kerberos repositories
- Authentication and directory service docs
- SSL/TLS and PKI resources

**Layer 2: Model & Inference**
- Ollama, LiteLLM, LangGraph repositories
- LLM provider documentation
- Agent framework resources

**Layer 3: Data Plane**
- PostgreSQL, Redis, Qdrant repositories
- Database and vector store documentation
- Data management resources

**Layer 4: Agentic & Toolchain**
- MCP protocol repositories
- Agent tooling and frameworks
- Development tool documentation

**Layer 5: Application**
- Application-specific repositories
- Frontend and backend frameworks
- Service-specific documentation

**Layer 6: Integration & Testing**
- CI/CD tool repositories
- Testing framework documentation
- Quality assurance resources

**Repository Information Includes:**
- Repository name and location
- Primary purpose and use cases
- Agents that require this knowledge
- Related repositories and dependencies
- Key documentation files

**Total Knowledge Base:**
- 100+ repositories in `/home/agent0/HX-Infrastructure/hx-knowledge/repos/`
- Organized by layer for systematic access
- Cross-referenced to agent knowledge requirements

---

### 3. Orchestration Guide
**File:** `hx-orchestration-guide.md`
**Size:** 1,022 lines
**Purpose:** Comprehensive multi-agent orchestration instructions for Agent Zero

**Key Sections:**

**Identity & Role:**
- Agent Zero as Universal PM Orchestrator
- Authority and responsibility definition
- Core principles (quality first, systematic approach, progressive execution)

**The 32 Specialist Agents (5 Core Team SMEs + 27 Technology SMEs):**
- Complete agent listing by specialty
- When to invoke each agent
- Knowledge requirements per agent
- Integration points and dependencies

**Orchestration Workflows:**
- **Service Deployment Workflow:**
  ```
  william (OS setup) → frank (identity/DNS) → Service Agent (deploy)
  → amanda (automation) → nathan (frontend)
  ```

- **RAG Pipeline Workflow:**
  ```
  diana + elena (crawl/NLP) → patricia (embedding) → robert (vector store)
  → marcus (knowledge graph)
  ```

- **LLM Application Workflow:**
  ```
  maya (LLM gateway) → laura (LangGraph) → george (MCP) → Frontend
  ```

- **Multi-Layer Deployment:**
  ```
  Layer 1 (Identity & Trust) → Layer 2 (Model & Inference)
  → Layer 3 (Data) → Layer 4 (Toolchain) → Layer 5+ (Apps)
  ```

**Coordination Patterns:**
- Sequential coordination (layer dependencies)
- Parallel coordination (independent services)
- Multi-agent synthesis (complex cross-layer work)
- Escalation paths (issue resolution)

**Quality Validation:**
- Agent output validation criteria
- Cross-layer integration verification
- Dependency validation
- Quality gate enforcement

**Best Practices:**
- Layer-aware coordination
- Knowledge vault utilization
- Documentation requirements
- Communication protocols

---

### 4. Orchestration Quick Reference
**File:** `hx-orchestration-quick-ref.md`
**Size:** 593 lines
**Purpose:** Quick reference guide for rapid agent lookup and common orchestration patterns

**Quick Reference Tables:**

**By Layer:**
- Quick lookup of agents by infrastructure layer
- Role summaries and primary responsibilities
- Server/service assignments

**By Capability:**
- Agents grouped by functional capability
- Security specialists
- Data specialists
- Infrastructure specialists
- Application specialists

**By Knowledge Domain:**
- Repository → Agent mappings
- Which agents need which knowledge
- Cross-domain knowledge requirements

**Common Patterns:**
- Frequently used orchestration sequences
- Standard deployment workflows
- Troubleshooting patterns
- Integration patterns

**Decision Trees:**
- When to invoke which agent
- Parallel vs. sequential coordination
- Single-agent vs. multi-agent tasks

**Server Mapping:**
- Which agent owns which server
- Server-to-service mappings
- Network zone assignments

---

## Agent Ecosystem Architecture

### Layer Structure (8 Layers)

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 0: Governance & Orchestration (Meta-Layer)           │
│  agent-zero (Orchestrator), alex (Platform Architect)       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Identity & Trust (Foundation - MUST BE FIRST)     │
│  frank (Samba), william (Ubuntu), yasmin (Docker),          │
│  amanda (Ansible)                                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Model & Inference                                  │
│  patricia (Ollama), maya (LiteLLM), laura (LangGraph)       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Data Plane                                         │
│  quinn (PostgreSQL), samuel (Redis), robert (Qdrant),       │
│  sarah (Qdrant UI)                                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 4: Agentic & Toolchain                                │
│  george (fastMCP), marcus (LightRAG), brian (AG-UI),        │
│  david (Crawl4AI MCP), diana (Crawl4AI Worker),             │
│  carlos (CodeRabbit), kevin (Continue.dev)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 5: Application (16 agents)                            │
│  Application-specific services and components                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 6: Integration & Testing                              │
│  isaac (CI/CD), julia (Testing & Quality)                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 7: App-Agnostic Lead Developers                       │
│  nathan (Frontend), fatima (Backend), victor (Full-Stack)   │
└─────────────────────────────────────────────────────────────┘
```

**Critical Dependency Rule:** Lower layers MUST be operational before upper layers deploy.

---

## Agent Coordination Patterns

### Pattern 1: Sequential Layer Deployment

**Use Case:** Deploying new service requiring foundation services

**Flow:**
1. **Layer 1 (Identity & Trust):** william → frank → amanda
2. **Layer 2 (Model & Inference):** patricia/maya/laura (as needed)
3. **Layer 3 (Data Plane):** quinn/samuel/robert (as needed)
4. **Layer 4 (Toolchain):** george/marcus (as needed)
5. **Layer 5+ (Application):** Service-specific agents

**Example: RAG Service Deployment**
```
william (OS setup on hx-rag-server)
→ frank (DNS A record, service account, SSL cert)
→ patricia (Ollama for embeddings)
→ robert (Qdrant vector store)
→ marcus (LightRAG knowledge graph)
→ isaac (CI/CD pipeline)
→ julia (testing validation)
```

---

### Pattern 2: Parallel Service Coordination

**Use Case:** Multiple independent services deploying concurrently

**Flow:**
- **Foundation (Sequential):** Layer 1 setup first
- **Services (Parallel):** Independent service deployments
- **Integration (Sequential):** Cross-service integration after all operational

**Example: Multiple Microservices**
```
Layer 1 Complete (william + frank + amanda)
    ↓
Parallel Deployments:
    Service A Agent → Service A deployed
    Service B Agent → Service B deployed
    Service C Agent → Service C deployed
    ↓
Integration (alex coordinates cross-service integration)
```

---

### Pattern 3: Multi-Agent Synthesis

**Use Case:** Complex work requiring multiple domain experts

**Flow:**
1. **agent-zero:** Analyzes task, identifies required agents
2. **Parallel Invocation:** Multiple agents work concurrently
3. **agent-zero Synthesis:** Integrates outputs from all agents
4. **Validation:** Cross-domain validation and conflict resolution

**Example: Platform-Wide Security Audit**
```
agent-zero coordinates:
    frank (Identity & Trust security)
    +
    william (OS security)
    +
    amanda (Automation security)
    +
    julia (Testing validation)
    ↓
agent-zero synthesizes findings
→ Unified security assessment
```

---

### Pattern 4: Troubleshooting Escalation

**Use Case:** Service issue requiring diagnostic investigation

**Flow:**
1. **Layer-Specific Agent:** Initial diagnosis at service layer
2. **Dependency Check:** Validate lower layer services
3. **Cross-Layer Analysis:** Multiple agents investigate
4. **alex (Architecture):** Architectural review if design issue
5. **agent-zero:** Synthesize findings, coordinate resolution

**Example: Service Connection Failure**
```
Service Agent: Identifies connection issue
    ↓
william: Checks OS-level networking
    ↓
frank: Validates DNS resolution and authentication
    ↓
quinn/samuel/robert: Check data layer connectivity
    ↓
agent-zero: Synthesizes findings, coordinates fix
```

---

## Key Specialist Agents

### Core Infrastructure Agents

**frank (Identity & Trust Infrastructure)**
- **Server:** hx-dc-server.hx.dev.local (192.168.10.200)
- **Services:** Samba DC, LDAP, Kerberos, DNS, PKI
- **Critical:** MUST be operational before any other services
- **Knowledge:** nginx, ansible-devel
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/frank.md`

**william (Ubuntu Systems Administrator)**
- **Servers:** All Ubuntu 24.04 LTS servers across platform
- **Services:** OS configuration, package management, system hardening
- **Critical:** Foundation for all service deployments
- **Knowledge:** ansible-devel, docker-install-master
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/william.md`

**amanda (Ansible Automation)**
- **Server:** hx-ansible-server.hx.dev.local (192.168.10.208)
- **Services:** Configuration management, automation, secrets (Ansible Vault)
- **Critical:** Automation and configuration consistency
- **Knowledge:** ansible-devel
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/amanda.md`

---

### Model & Inference Agents

**patricia (Ollama Cluster Manager)**
- **Servers:** hx-ollama-server-1/2/3 (192.168.10.212/213/214)
- **Services:** Self-hosted LLM inference, model management, embedding generation
- **Knowledge:** ollama-main, litellm-main
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/patricia.md`

**maya (LiteLLM Gateway)**
- **Server:** hx-litellm-server.hx.dev.local (192.168.10.211)
- **Services:** Unified LLM access, 50+ provider support, load balancing
- **Knowledge:** litellm-main, ollama-main
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/maya.md`

**laura (LangGraph Orchestration)**
- **Server:** hx-lang-server.hx.dev.local (192.168.10.204)
- **Services:** Graph-based agent orchestration, LangChain workflows
- **Knowledge:** langgraph-main, langchain, agentic-design-patterns-docs-main
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/laura.md`

---

### Data Plane Agents

**quinn (PostgreSQL Manager)**
- **Server:** hx-postgres-server.hx.dev.local (192.168.10.207)
- **Services:** Relational database, structured data storage
- **Knowledge:** postgres-master, prisma-main
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/quinn.md`

**robert (Qdrant Vector DB)**
- **Server:** hx-qdrant-server.hx.dev.local (192.168.10.210)
- **Services:** Vector storage, similarity search, semantic retrieval
- **Knowledge:** qdrant-master, qdrant-client-master, mcp-server-qdrant-master
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/robert.md`

**marcus (LightRAG Knowledge Graph)**
- **Server:** hx-lightrag-server.hx.dev.local (192.168.10.209)
- **Services:** Graph-based RAG, knowledge graph construction
- **Knowledge:** lightrag-main, qdrant-client-master
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/marcus.md`

---

### Testing & Quality Agents

**julia (Testing & Quality Specialist)**
- **Scope:** All services and deployments
- **Services:** Test-driven deployment, 100% coverage validation, defect management
- **Knowledge:** pytest-main, playwright-main, testing-best-practices
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/julia.md`

**isaac (CI/CD Pipeline)**
- **Server:** hx-cicd-server.hx.dev.local
- **Services:** Automated testing, deployment pipelines, integration workflows
- **Knowledge:** github-actions-main, gitlab-ci-main
- **Profile:** `/home/agent0/HX-Infrastructure/x-agents/isaac.md`

---

## Knowledge Vault Integration

### Repository Organization

**Location:** `/home/agent0/HX-Infrastructure/hx-knowledge/repos/`

**Structure by Layer:**
```
hx-knowledge/repos/
├── layer1-identity-trust/
│   ├── samba-repos/
│   ├── kerberos-repos/
│   ├── ssl-tls-repos/
│   └── ansible-repos/
├── layer2-model-inference/
│   ├── ollama-repos/
│   ├── litellm-repos/
│   └── langgraph-repos/
├── layer3-data-plane/
│   ├── postgres-repos/
│   ├── redis-repos/
│   └── qdrant-repos/
├── layer4-toolchain/
│   ├── mcp-repos/
│   ├── lightrag-repos/
│   └── crawl4ai-repos/
└── ...
```

**Agent Knowledge Access:**
- Each agent profile specifies required repositories
- Knowledge vault catalog maps repositories to agents
- Systematic knowledge loading during agent invocation

---

## Agent Profile System

### Profile Location
**Directory:** `/home/agent0/HX-Infrastructure/x-agents/`

**Profile Format:**
```markdown
# Agent Name

**Role:** [Agent role and specialty]
**Layer:** [Infrastructure layer]
**Server:** [Server hostname and IP]
**Services:** [Services managed]

## Responsibilities
[Detailed responsibility list]

## Knowledge Requirements
[Required repositories from knowledge vault]

## Integration Points
[Services and agents this agent integrates with]

## Invocation Criteria
[When agent-zero should invoke this agent]

## Output Format
[Expected deliverables and format]
```

**Total Profiles:** 32 agent profiles (5 Core Team SMEs + 27 Technology SMEs)

---

## Usage Guidelines

### When to Use Agent Inventory
- **New Service Planning:** Identify which agents needed
- **Dependency Analysis:** Understand layer dependencies
- **Knowledge Discovery:** Find which repositories an agent needs
- **Troubleshooting:** Identify agent responsible for service

### When to Use Knowledge Vault Catalog
- **Repository Discovery:** Find repositories by topic/layer
- **Agent Knowledge Prep:** Load repositories before agent invocation
- **Cross-Reference:** Map between agents and knowledge
- **Knowledge Gap Analysis:** Identify missing repositories

### When to Use Orchestration Guide
- **Complex Workflows:** Multi-agent coordination patterns
- **New Deployments:** Systematic service deployment
- **Architecture Planning:** Layer-aware design decisions
- **Quality Validation:** Agent output validation criteria

### When to Use Quick Reference
- **Rapid Lookup:** Quick agent identification
- **Common Patterns:** Standard orchestration sequences
- **Decision Support:** When to invoke which agents
- **Server Mapping:** Find agent by server assignment

---

## Integration with Claude Code Commands

### Relationship to Command Sets

**Set 1 (Workflows):**
- Workflows orchestrate agent invocations systematically
- Charter/Spec workflows may invoke alex (Platform Architect)
- Task/Execution workflows invoke service-specific agents

**Set 2 (Orchestrations):**
- Agent orchestration commands (cc-orchestrate-*.md) define invocation patterns
- One orchestration command per key specialist (alex, frank, william, julia)

**Set 5 (Agent Orchestration Commands):**
- cc-orchestrate-alex.md: Coordinates with alex (Platform Architect)
- cc-orchestrate-frank.md: Coordinates with frank (Security Specialist)
- cc-orchestrate-william.md: Coordinates with william (Infrastructure)
- cc-orchestrate-julia.md: Coordinates with julia (Testing & Quality)
- cc-agent-zero-synthesis.md: Multi-agent coordination patterns

**Agent Ecosystem Documents vs. Orchestration Commands:**
- **Ecosystem Documents (hx-agents/):** WHAT agents exist, their roles, capabilities
- **Orchestration Commands (commands/agents/):** HOW to invoke and coordinate agents

---

## Documentation Maintenance

### Update Triggers

**Agent Inventory Updates Needed When:**
- New agent added to ecosystem
- Agent role or responsibilities change
- Server assignments change
- Knowledge requirements change
- Layer assignments modified

**Knowledge Vault Catalog Updates Needed When:**
- New repository added to knowledge vault
- Repository organization changes
- Agent knowledge requirements change
- Cross-repository dependencies identified

**Orchestration Guide Updates Needed When:**
- New orchestration patterns established
- Workflow sequences change
- Best practices evolve
- Quality criteria modified

**Quick Reference Updates Needed When:**
- Any of the above documents updated
- Common patterns change
- Decision criteria modified

### Version Control

**Current Status:**
- Agent Inventory: Last Updated November 15, 2025
- Knowledge Vault Catalog: Last Updated November 15, 2025
- Orchestration Guide: Last Updated November 15, 2025
- Quick Reference: Last Updated November 15, 2025

**Recommended Update Frequency:**
- **Agent Inventory:** After any ecosystem changes
- **Knowledge Vault Catalog:** After repository additions/reorganization
- **Orchestration Guide:** Quarterly or after major workflow changes
- **Quick Reference:** Synchronized with other document updates

---

## File Statistics

**Total Documentation:** 3,350 lines
- Agent Inventory: 1,111 lines (33%)
- Orchestration Guide: 1,022 lines (31%)
- Knowledge Vault Catalog: 624 lines (19%)
- Orchestration Quick Ref: 593 lines (17%)

**Coverage:**
- 32 agents documented (5 Core Team SMEs + 27 Technology SMEs)
- 58 repositories cataloged in knowledge vault
- Agent orchestration patterns documented
- Server mappings and coordination patterns defined

---

## Related Documentation

**Infrastructure Documentation:**
- **Constitution:** `/home/agent0/HX-Infrastructure/constitution.md`
- **Architecture Standards:** `/home/agent0/HX-Infrastructure/standards/architecture-standards.md`
- **Network Topology:** `/home/agent0/HX-Infrastructure/network/network-topology.md`

**Command Documentation:**
- **Workflows:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/README.md`
- **Orchestrations:** `/home/agent0/HX-Infrastructure/.claude/commands/orchestrations/README.md`
- **Utilities:** `/home/agent0/HX-Infrastructure/.claude/commands/utilities/README.md`
- **Phase Commands:** `/home/agent0/HX-Infrastructure/.claude/commands/phases/README.md`
- **Agent Orchestration:** `/home/agent0/HX-Infrastructure/.claude/commands/agents/README.md`

**Agent Profiles:**
- **Profile Directory:** `/home/agent0/HX-Infrastructure/x-agents/`
- **32 Individual Profiles:** One per agent (5 Core Team SMEs + 27 Technology SMEs)

---

**Directory Maintained By:** HX-Infrastructure Team
**Primary User:** Agent Zero (Universal PM Orchestrator)
**Last Comprehensive Review:** 2025-11-21
**Status:** ✅ Production Documentation - Complete and Current
