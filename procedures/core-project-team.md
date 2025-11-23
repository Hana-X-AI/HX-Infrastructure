# Core Project Team
## Standard Agent Assignments for All HX-Infrastructure Projects

**Document Type:** Procedure - Team Structure and Roles
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Production Ready
**Location:** `/home/agent0/HX-Infrastructure/procedures/core-project-team.md`

---

## Document Purpose

This document defines the core team of specialist agents that participate in EVERY HX-Infrastructure project. It establishes standard agent roles, responsibilities, state management requirements, and team coordination patterns to ensure consistent multi-perspective validation across all phases of project execution.

**Source:** `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` (45 specialist agents)

**Related Documents:**
- `hx-agents/hx-agent-inventory.md` - Complete 45-agent specialist ecosystem
- `hx-agents/hx-orchestration-guide.md` - Multi-agent coordination patterns
- `.claude/commands/agents/` - Agent orchestration commands (Set 5)
- `procedures/context-loading-process.md` - Context loading for stateless agents
- `constitution.md` - Project governance and principles

**Target Audience:**
- Agent Zero (Chief AI Officer / Universal PM Orchestrator)
- CAIO (project sponsors and stakeholders)
- All specialist agents (core and project-specific)
- Infrastructure team members

---

## 🎯 Team Philosophy

**Core Principle:** Every HX-Infrastructure project requires a core team of agents providing essential perspectives across all critical domains:

1. **Architecture** - System design, integration patterns, multi-layer coordination
2. **Security & Identity** - Authentication, authorization, Samba AD, Kerberos, certificates
3. **Infrastructure** - Bare metal deployment, systemd services, manual procedures
4. **Testing & Quality** - Test-driven deployment, 100% requirements coverage, quality gates
5. **Orchestration** - Project coordination, governance, decision authority

**Additional specialist agents** join based on project-specific technology needs:
- Database specialists (PostgreSQL, Redis, Qdrant)
- Application framework specialists (Django, Langchain, FastMCP)
- Infrastructure automation (Ansible, observability)
- Domain-specific experts (RAG, MCP, web scraping, etc.)

**Infrastructure Philosophy Integration:**
All core agents understand and apply HX-Infrastructure philosophy:
- **Bare metal first:** Production/staging on Ubuntu 24 bare metal servers
- **Docker dev-only:** Containers allowed only on hx-dev-server (192.168.10.222)
- **Systemd service management:** All services managed via systemd
- **Manual procedures only:** No automation (no Ansible playbooks for procedures)
- **Ansible Vault only:** All credentials in Ansible Vault

---

## 👥 Core Team Members (Standard on ALL Projects)

### **Agent Zero (CC) - Universal PM Orchestrator** ✅ STATEFUL

**Role:** Chief AI Officer / Universal PM Orchestrator & Governance
**Agent Name:** agent-zero
**Profile:** `/home/agent0/.claude/agents/agent-zero.md`
**State:** STATEFUL - Maintains context throughout entire project lifecycle

**Responsibilities:**
- Project orchestration and coordination across all phases
- Constitutional compliance and governance enforcement
- Decision authority and conflict resolution
- Quality validation at all approval gates
- Multi-agent coordination and synthesis
- Context preparation for specialist agents
- RAIDD log maintenance
- Backlog management
- **MAINTAINS STATE** throughout project lifecycle

**Infrastructure Philosophy Enforcement:**
- Ensures all agents apply bare metal deployment approach
- Validates systemd service management requirements
- Verifies manual procedure documentation completeness
- Confirms Ansible Vault credential management
- Enforces Docker dev-only exceptions

**Always Participates In:**
- Charter creation (creates and owns charter)
- Specification development (orchestrates all contributions)
- Task breakdown (coordinates task generation)
- Deployment execution (orchestrates implementation)
- Testing coordination (manages quality assurance)
- Project closeout (finalizes all documentation)
- All approval gates (final decision authority)

**Knowledge Requirements:**
- `agentic-design-patterns-docs-main` - Agent architecture patterns
- `ottomator-agents-main` - Multi-agent orchestration
- All HX-Infrastructure standards and documentation
- Complete knowledge vault access

**Claude Code Command Integration:**
- Uses all workflow commands (Set 1: Charter, Spec, Task, Execution, Closeout)
- Invokes all orchestration commands (Set 5: orchestrate-alex, frank, william, julia)
- Uses all utility commands (Set 3: context-prep, handoff, raidd, artifact-tracker, etc.)

---

### **Alex Rivera - Platform Architect** ⭐ CORE - STATELESS

**Role:** Platform Architecture Specialist
**Agent Name:** alex
**Profile:** `/home/agent0/.claude/agents/alex.md`
**State:** STATELESS - Must reload context each invocation

**Responsibilities:**
- Architecture decisions and ADR (Architecture Decision Record) creation
- Platform architecture design and validation
- Multi-layer integration planning (across 8 infrastructure layers)
- Cross-service coordination patterns
- Governance and architecture standards alignment
- System design and agentic architecture patterns
- Network topology and security zone validation

**Infrastructure Philosophy Application:**
- Validates architecture aligns with bare metal deployment
- Ensures multi-layer designs respect infrastructure philosophy
- Reviews network zone placement and security boundaries
- Validates service integration patterns for manual deployment

**Participates In:**
- Charter review (architecture perspective, feasibility validation)
- Specification development (architecture sections, integration patterns)
- Deployment plan review (architecture validation, topology updates)
- Integration testing (cross-service validation)
- ADR creation (major architectural decisions)

**Knowledge Requirements:**
- `agentic-design-patterns-docs-main` - Agentic design patterns
- Architecture and integration documentation (project-specific)
- HX-Infrastructure architecture standards (always reviewed)

**Claude Code Command Integration:**
- Invoked via `cc-orchestrate-alex.md` (Set 5)
- May invoke agent-zero-synthesis for complex multi-layer changes

**Context Loading:** Must follow charter/spec/deployment context load checklists (20-50 min depending on phase)

---

### **Frank Martinez - Security Specialist** ⭐ CORE - STATELESS

**Role:** Identity & Trust Infrastructure Specialist
**Agent Name:** frank
**Profile:** `/home/agent0/.claude/agents/frank.md`
**State:** STATELESS - Must reload context each invocation

**Responsibilities:**
- Samba DC (Active Directory) management and integration
- Centralized authentication (Kerberos) and authorization (LDAP)
- DNS services and A record provisioning
- PKI and certificate management (hx-ca-server integration)
- Computer account and service principal management
- Security zone architecture and trust relationships
- Identity & Trust layer (Layer 1) coordination

**Infrastructure Philosophy Application:**
- Ensures authentication integrates with bare metal servers
- Validates Ansible Vault credential management
- Reviews certificate requirements for all services
- Ensures DNS entries for all deployed servers

**Participates In:**
- Charter review (identity, DNS, security perspective)
- Specification development (authentication, authorization, DNS, certificate sections)
- Deployment plan review (DNS records, certificates, Kerberos principals)
- Identity integration testing (Kerberos ticket acquisition, LDAP queries)
- Security validation (trust relationships, access control)

**Knowledge Requirements:**
- `nginx` - Reverse proxy, SSL/TLS configuration
- `nginx-master` - Web server source, proxy patterns
- `ansible-devel` - Configuration automation patterns
- Samba AD documentation (Kerberos, LDAP)
- PKI and certificate management

**Claude Code Command Integration:**
- Invoked via `cc-orchestrate-frank.md` (Set 5)
- Coordinates with William for server domain-joining

**Context Loading:** Must follow charter/spec/deployment context load checklists (20-50 min depending on phase)

---

### **William Thompson - Infrastructure Specialist** ⭐ CORE - STATELESS

**Role:** Bare Metal Infrastructure & Ubuntu Systems Specialist
**Agent Name:** william
**Profile:** `/home/agent0/.claude/agents/william.md`
**State:** STATELESS - Must reload context each invocation

**Responsibilities:**
- Ubuntu 24.04 LTS bare metal server deployment
- Systemd service unit creation and management
- Manual deployment procedure documentation
- OS configuration and package management
- System security and hardening
- Network configuration (interfaces, routing, firewall)
- Performance tuning and optimization
- Kernel and system-level troubleshooting

**Infrastructure Philosophy PRIMARY OWNER:**
William is the authoritative specialist for HX-Infrastructure philosophy:
- **Bare metal deployment:** Provisions Ubuntu 24 servers on physical hardware
- **Systemd service management:** Creates and manages all systemd units
- **Manual procedures:** Documents step-by-step deployment procedures
- **Network configuration:** Configures server networking (IP, routes, DNS)
- **Docker dev-only:** Enforces Docker only on hx-dev-server

**Participates In:**
- Charter review (OS/system, infrastructure perspective)
- Specification development (infrastructure, systemd, manual procedure sections)
- Deployment plan review (OS requirements, systemd units, manual steps)
- System-level testing (service health, network connectivity, performance)
- Manual procedure validation (deployability, completeness)

**Knowledge Requirements:**
- Ubuntu documentation (24.04 LTS focus)
- Systemd service management
- System administration best practices
- Security hardening guidelines
- Network configuration (netplan, systemd-networkd)

**Claude Code Command Integration:**
- Invoked via `cc-orchestrate-william.md` (Set 5)
- Coordinates with Frank for domain-joining and DNS
- Coordinates with Amanda for Ansible Vault credential deployment

**Context Loading:** Must follow charter/spec/deployment context load checklists (20-50 min depending on phase)

---

### **Julia Chen - Testing & Quality Specialist** ⭐ CORE - STATELESS

**Role:** Testing & Quality Assurance Specialist
**Agent Name:** julia
**Profile:** `/home/agent0/.claude/agents/julia.md`
**State:** STATELESS - Must reload context each invocation

**Responsibilities:**
- Test-driven deployment methodology (tests written BEFORE implementation)
- Testing strategy development and test plan creation
- 100% requirements coverage validation (mandatory for all deployments)
- Test suite generation (8 categories: deployment, functionality, integration, health)
- Defect lifecycle management (discovery, assessment, resolution, verification)
- Quality gate enforcement (blocking gates for critical/high severity defects)
- Test execution and results validation
- Quality assurance across all services and infrastructure

**Infrastructure Philosophy Application:**
- Generates deployment tests (bare metal provisioning, systemd service health)
- Creates manual procedure verification tests
- Validates network connectivity and DNS resolution
- Tests Ansible Vault credential access
- Ensures infrastructure quality gates passed

**Participates In:**
- Charter review (testing perspective, quality requirements)
- Specification development (testing sections, acceptance criteria)
- Test plan creation (before implementation begins)
- Test suite generation (100% requirements coverage)
- Test execution and results validation
- Defect management (throughout project lifecycle)
- Quality validation gates (all phases)

**Knowledge Requirements:**
- `cypress` - E2E testing framework (PRIMARY for web UIs)
- `pytest` - Python testing (PRIMARY for Python services)
- Project-specific testing documentation
- HX-Infrastructure testing requirements (always reviewed)

**Claude Code Command Integration:**
- Invoked via `cc-orchestrate-julia.md` (Set 5)
- Uses `cc-phase-test-suite-generation.md` (Set 4)
- Uses `cc-phase-defect-mgmt.md` (Set 4)

**Context Loading:** Must follow charter/spec/deployment context load checklists (20-50 min depending on phase)

---

## 🎭 Project-Specific Agents (Join Based on Technology)

**Agents join based on project technology stack, domain requirements, or infrastructure needs:**

### **Infrastructure & Automation Specialists:**

**Amanda Rodriguez** - Ansible Automation Specialist
- Role: Fleet-wide configuration management, Ansible Vault credential deployment
- When: Multi-server deployments, credential management, fleet coordination
- Knowledge: `ansible-devel`, Ansible Vault patterns
- Invoked via: `cc-orchestrate-amanda.md` (when available)

**Nathan Kim** - Metrics & Observability Specialist
- Role: Prometheus, Grafana, monitoring, alerting, telemetry
- When: Observability requirements, monitoring dashboards
- Infrastructure: hx-metric-server (192.168.10.225)

**Isaac Morgan** - CI/CD Specialist
- Role: Jenkins, GitLab CI, automated pipelines, deployment automation
- When: Continuous integration/deployment requirements

### **Database Specialists:**

**Patricia Wong** - PostgreSQL Specialist
- Role: PostgreSQL deployment, schema design, replication, performance
- When: Relational database requirements
- Infrastructure: hx-postgres-server (192.168.10.209)

**Robert Zhang** - Redis Specialist
- Role: Redis caching, pub/sub, data structures, performance
- When: Caching layer, session storage, real-time requirements
- Infrastructure: hx-redis-server (192.168.10.210)

**Marcus Johnson** - LightRAG Specialist
- Role: RAG knowledge graphs, LightRAG implementation, vector embeddings
- When: RAG knowledge base requirements, semantic search
- Infrastructure: hx-literag-server (192.168.10.220)

**Quinn Taylor** - Qdrant Specialist
- Role: Qdrant vector database, collections, embeddings, QMCP
- When: Vector search, semantic similarity, RAG pipelines
- Infrastructure: hx-qdrant-server (192.168.10.207), hx-qmcp-server (192.168.10.211)

### **Application Framework Specialists:**

**Laura Patel** - Langchain Specialist
- Role: Langchain agent frameworks, LangGraph, agent orchestration
- When: Langchain-based agent systems
- Infrastructure: hx-lang-server (192.168.10.226, planned)

**Maya Rodriguez** - Django Specialist
- Role: Django applications, REST APIs, Django ORM
- When: Django web application requirements

**George Kim** - FastMCP Gateway Specialist
- Role: FastMCP gateway, MCP protocol, tool orchestration
- When: MCP tool integration, tool gateway requirements
- Infrastructure: hx-fastmcp-server (192.168.10.213)

**Brian Lee** - AG-UI Protocol Specialist
- Role: AG-UI protocol, agent-to-frontend communication, event streaming
- When: Agent-driven UI requirements, real-time agent interfaces
- Infrastructure: hx-agui-server (192.168.10.221, planned)

### **Data Collection & Processing Specialists:**

**Diana Wu** - Crawl4AI Worker Specialist
- Role: Web scraping, Crawl4AI workers, corpus building
- When: Web content extraction, knowledge base building
- Infrastructure: hx-crawl4ai-server (192.168.10.219)

**David Park** - Crawl4AI MCP Orchestrator
- Role: Crawl4AI MCP orchestration, scraping safety, policy enforcement
- When: MCP-based web scraping, crawl coordination
- Infrastructure: hx-crawl4ai-mcp-server (192.168.10.218)

**Olivia Martinez** - Docling Specialist
- Role: Document parsing, PDF extraction, structured content
- When: Document processing requirements
- Infrastructure: hx-docling-server (192.168.10.216)

### **Integration & Protocol Specialists:**

**Kevin Wright** - N8N Specialist
- Role: N8N workflow automation, integrations
- When: Workflow automation requirements
- Infrastructure: hx-n8n-server (192.168.10.215)

**Carlos Martinez** - CodeRabbit MCP Specialist
- Role: CodeRabbit AI code review, MCP integration
- When: Automated code review requirements
- Infrastructure: hx-coderabbit-server (192.168.10.228, reserved)

**Paul Anderson** - Shadcn MCP Specialist
- Role: Shadcn UI components, MCP integration
- When: UI component library requirements
- Infrastructure: hx-shadcn-server (192.168.10.229, planned)

### **Model & Inference Specialists:**

**Elena Foster** - Ollama Specialist
- Role: Ollama model serving, model management, inference
- When: LLM inference requirements, model deployment
- Infrastructure: hx-ollama1/2/3-server (192.168.10.204-206)

**Sarah Johnson** - LiteLLM Specialist
- Role: LiteLLM API gateway, model routing, unified API
- When: Multi-model API gateway requirements
- Infrastructure: hx-litellm-server (192.168.10.212)

**Hannah Brooks** - Open WebUI Specialist
- Role: Open WebUI deployment, user interfaces, chat interfaces
- When: Web UI for LLM interactions
- Infrastructure: hx-webui-server (192.168.10.227)

**See:** `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` for complete 45-agent ecosystem

---

## 📋 Team Assignment Process

### **Phase 0: Charter Creation**

**Duration:** 2-4 hours
**Orchestration:** Agent Zero coordinates all core agent reviews

**Core Team Participates:**
1. ✅ **Agent Zero (CC)** - Orchestration, charter generation, synthesis
2. ✅ **Alex Rivera** - Architecture review, feasibility validation
3. ✅ **Julia Chen** - Testing requirements review, quality criteria
4. ✅ **Frank Martinez** - Identity/DNS review, security requirements
5. ✅ **William Thompson** - Infrastructure review, deployment feasibility

**Knowledge Vault Assignments:**
- Agent Zero assigns repositories based on agent expertise
- Documented in charter or `/nodes/[node-name]/team-assignments.md`
- Each agent receives specific repos to review (see context loading process)

**Infrastructure Philosophy Validation:**
- All core agents review deployment approach
- William validates bare metal feasibility
- Frank validates authentication integration
- Julia validates testing approach for infrastructure

**Process Flow:**
```
1. CAIO provides project vision (brain dump)
2. Agent Zero parses and identifies knowledge repositories
3. Agent Zero confirms repo list with CAIO
4. Agent Zero asks initial clarifying questions
5. Agent Zero conducts knowledge vault deep dive
6. Agent Zero generates charter draft
7. Core agents review charter (parallel invocations)
8. Agent Zero synthesizes feedback
9. CAIO reviews and approves charter
10. Agent Zero executes post-approval actions (RAIDD, backlog, agent assignments)
```

**Output:** Approved charter with multi-perspective validation

---

### **Phase 1: Specification Development**

**Duration:** 2-3 hours
**Orchestration:** Agent Zero coordinates all specialist contributions

**Core Team Participates:**
1. ✅ **Agent Zero (CC)** - Orchestration, base specification generation, synthesis
2. ✅ **Alex Rivera** - Architecture sections (integration patterns, ADRs)
3. ✅ **Julia Chen** - Testing sections (test plan, coverage requirements)
4. ✅ **Frank Martinez** - Identity/DNS sections (authentication, certificates)
5. ✅ **William Thompson** - Infrastructure sections (systemd, manual procedures)

**Plus:** Project-specific agents based on technology stack:
- Database agents (if database requirements)
- Framework agents (if specific framework used)
- Integration agents (if specialized integrations)

**Infrastructure Philosophy Documentation:**
- William ensures systemd service unit requirements specified
- William documents manual procedure outline
- Frank documents Ansible Vault credential requirements
- Alex validates network topology integration
- Julia generates infrastructure testing requirements

**Process Flow:**
```
1. Agent Zero generates base specification from charter
2. Agent Zero prepares context packages for each specialist
3. Specialists load context (35-45 min each, see context loading process)
4. Specialists edit their sections IMMEDIATELY (while context fresh)
5. Agent Zero synthesizes all contributions
6. Agent Zero resolves conflicts and fills gaps
7. Specialists review synthesized specification
8. CAIO reviews and approves specification
```

**⚠️ CRITICAL:** Stateless agents must edit immediately after context load. Pause = context loss.

**Output:** Comprehensive approved specification with multi-agent contributions

---

### **Phase 2: Task Breakdown & Planning**

**Duration:** 2.5-3.5 hours
**Orchestration:** Agent Zero coordinates task generation and test suite creation

**Core Team Participates:**
1. ✅ **Agent Zero (CC)** - Task breakdown, sequencing, assignments
2. ✅ **Julia Chen** - Test suite generation (100% requirements coverage)
3. ✅ **Alex Rivera** - Task validation for architecture alignment
4. ✅ **Frank Martinez** - Task validation for identity/DNS requirements
5. ✅ **William Thompson** - Task validation for infrastructure requirements

**Plus:** Project-specific agents validate tasks for their domains

**Infrastructure Philosophy Task Generation:**
- William ensures bare metal deployment tasks included
- William ensures systemd service creation tasks included
- William ensures manual procedure documentation tasks included
- Frank ensures DNS record creation tasks included
- Frank ensures certificate request tasks included

**Process Flow:**
```
1. Agent Zero breaks specification into atomic tasks
2. Julia generates comprehensive test suite (BEFORE implementation)
3. Core agents validate task completeness
4. Agent Zero sequences tasks based on dependencies
5. Agent Zero assigns tasks to team members or automation
6. CAIO reviews and approves task plan
```

**Julia's Test-Driven Deployment:**
- Tests written BEFORE implementation begins
- 100% requirements coverage mandatory
- 8 test categories generated
- Quality gates established

**Output:** Task breakdown with sequencing, test suite with 100% coverage

---

### **Phase 3: Deployment Execution**

**Duration:** 2.5-5 hours (depends on complexity)
**Orchestration:** Agent Zero coordinates execution and testing

**Core Team Participates:**
1. ✅ **Agent Zero (CC)** - Orchestration, progress tracking, defect management
2. ✅ **William Thompson** - Infrastructure deployment execution (primary executor)
3. ✅ **Frank Martinez** - DNS records, certificates, domain-joining
4. ✅ **Julia Chen** - Test execution, defect management, quality validation
5. ✅ **Alex Rivera** - Integration validation, architecture compliance

**Plus:** Project-specific agents execute technology-specific tasks

**Infrastructure Philosophy Execution:**
- William provisions bare metal server
- William creates systemd service unit
- William documents manual deployment procedure
- Frank provisions DNS A records
- Frank issues certificate from hx-ca-server
- Frank joins server to domain
- Amanda deploys Ansible Vault credentials (if multi-server)

**Process Flow:**
```
1. Execute tasks in dependency order
2. Run tests continuously (test-driven deployment)
3. Log defects immediately when discovered
4. Resolve blocking defects before proceeding
5. Update RAIDD log with risks/issues/decisions
6. Validate quality gates at checkpoints
7. William documents actual deployment steps (manual procedures)
8. Julia validates 100% test pass before promotion
```

**Quality Gates:**
- Tests must pass before proceeding
- Critical/High defects BLOCK progress
- Manual procedures must be documented and validated

**Output:** Deployed service, passing tests, documented procedures, operational readiness

---

### **Phase 4: Project Closeout**

**Duration:** 2-3 hours
**Orchestration:** Agent Zero coordinates final validation and documentation

**Core Team Participates:**
1. ✅ **Agent Zero (CC)** - Final validation, documentation compilation, lessons learned
2. ✅ **Alex Rivera** - Architecture documentation validation, ADR completion
3. ✅ **Julia Chen** - Test results validation, defect closure verification
4. ✅ **Frank Martinez** - Identity/DNS documentation validation
5. ✅ **William Thompson** - Manual procedure validation, infrastructure documentation

**Infrastructure Philosophy Validation:**
- William validates manual procedures complete and accurate
- William confirms systemd service operational
- Frank confirms DNS records active
- Frank confirms certificate valid and trusted
- Julia confirms all infrastructure tests passing

**Process Flow:**
```
1. Validate all quality gates passed
2. Confirm all tests passing (100% pass required)
3. Close all defects (or document acceptable deferments)
4. Validate documentation complete
5. Generate lessons learned
6. Update knowledge vault with project artifacts
7. CAIO final acceptance
```

**Output:** Operational service, complete documentation, lessons learned, knowledge captured

---

## 🔄 State Management

### **Agent Zero (CC) - MAINTAINS STATE** ✅

```
Charter Phase → Spec Phase → Task Phase → Execution Phase → Closeout Phase
     ↓              ↓             ↓              ↓                ↓
 Remembers      Remembers     Remembers      Remembers       Remembers

Agent Zero MAINTAINS CONTINUOUS STATE:
✓ Remembers all charter content (created it)
✓ Remembers all specification decisions
✓ Remembers all RAIDD log entries (maintains it)
✓ Remembers all task assignments
✓ Remembers all defects and resolutions
✓ Remembers all agent contributions
✓ Can synthesize across entire project lifecycle

Does NOT need to re-review:
✗ Knowledge vault repos (already researched in charter)
✗ Previous phase artifacts (has continuous context)
```

**Advantage:**
- Provides continuity across all phases
- Synthesizes diverse specialist contributions
- Resolves conflicts with full project context
- Makes informed decisions throughout lifecycle

### **All Other Agents - STATELESS** ⚠️

```
Each Invocation = Fresh Start
NO MEMORY between invocations

MUST review before EVERY contribution:
✓ Approved charter (vision, scope, success criteria)
✓ Assigned knowledge vault repos (technical understanding)
✓ RAIDD log (current risks, assumptions, decisions)
✓ Backlog (understand out-of-scope)
✓ Defect log (known issues affecting work)
✓ Current work product (spec, tasks, plan, etc.)
✓ HX-Infrastructure standards (architecture, deployment, testing)
✓ Infrastructure state (inventory, network topology)
```

**Challenge:**
- Context loading time required (20-50 min per phase)
- Must act immediately after context load (or lose context)
- Cannot assume knowledge from previous contributions

**Mitigation:**
- Systematic context loading checklists (see context-loading-process.md)
- Agent Zero prepares context packages (via cc-context-prep.md)
- Documentation captures all decisions and rationale

---

## ⚙️ Context Loading Requirements

### **For Stateless Agents (Alex, Frank, William, Julia, all specialists)**

**Before Charter Review:**
```
Duration: 20-30 minutes

Must Review:
1. Project kickoff information (from Agent Zero)
2. Assigned knowledge vault repositories
3. HX-Infrastructure standards (architecture, deployment, testing)
4. Infrastructure inventory (nodes.md) and network topology
5. Charter draft (if reviewing)
6. Agent role and responsibilities

Infrastructure Philosophy Understanding Required:
- Bare metal deployment approach
- Systemd service management
- Manual procedure documentation
- Ansible Vault credential management
- Docker dev-only exceptions
```

**Before Specification Contribution:**
```
Duration: 35-45 minutes

Must Review:
1. Approved charter (vision, scope, infrastructure philosophy)
2. Re-read assigned knowledge vault repositories
3. RAIDD log (project-specific entries)
4. Backlog (out-of-scope understanding)
5. Defect log (if exists)
6. Knowledge research findings (from Agent Zero)
7. Initial specification draft (from Agent Zero)
8. Team assignments (contribution boundaries)
9. Infrastructure state (if infrastructure-related)

⚠️ CRITICAL: Must edit specification IMMEDIATELY after context load!
Pause = context loss = must reload from scratch
```

**Before Task Execution/Review:**
```
Duration: 30-40 minutes

Must Review:
1. Approved charter
2. Approved specification
3. Task breakdown and assignments
4. RAIDD log (recent updates)
5. Test suite (understand test-driven deployment)
6. Task assignments and acceptance criteria
```

**Before Deployment Review:**
```
Duration: 40-50 minutes

Must Review:
1. Approved charter
2. Approved specification
3. Task execution results
4. RAIDD log (deployment risks)
5. Defect log (known issues)
6. Deployment plan draft
7. Deployment architecture
8. Configuration specification
9. Test results (quality gate status)
```

**See:** `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` for detailed checklists and templates

---

## 🎯 Conflict Resolution

**When agents disagree or recommend different approaches:**

### **Resolution Process:**

1. **Agent Zero has final decision authority**
   - Considers all specialist perspectives
   - Makes informed decision based on project goals
   - Balances trade-offs across domains

2. **Decision documented in RAIDD log**
   - Logged as key decision (D-XXX format)
   - Rationale captured
   - Alternatives considered documented
   - Trade-offs explained

3. **Alternatives noted for future reference**
   - Deferred approaches added to backlog
   - Future optimization opportunities captured
   - Learning captured for similar situations

### **Example Conflict Resolution:**

```markdown
RAIDD Log Entry:
Decision D-003: Database Choice for User Session Storage

CONTEXT:
hx-webui-server requires user session storage with high performance.

RECOMMENDATIONS:
- Alex (Architecture): PostgreSQL - relational integrity, ACID compliance
- Robert (Redis): Redis - sub-millisecond latency, session use case optimized
- Patricia (PostgreSQL): PostgreSQL - data durability, backup integration

AGENT ZERO DECISION: Redis for session storage

RATIONALE:
1. Session data is ephemeral (acceptable data loss on Redis restart)
2. Sub-millisecond latency critical for user experience
3. Session use case aligns with Redis strengths
4. PostgreSQL still used for persistent user data (hybrid approach)

ALTERNATIVES CONSIDERED:
- Pure PostgreSQL: Rejected due to latency requirements
- Pure Redis: Accepted for sessions, PostgreSQL for persistent data

DEFERRED TO BACKLOG:
- Redis Sentinel cluster (HA) - future optimization (item B-042)
- Session data analytics (PostgreSQL integration) - future enhancement (item B-043)

COORDINATION:
- Robert (Redis) implements session storage
- Patricia (PostgreSQL) implements persistent user data
- Alex validates hybrid architecture alignment
```

### **Conflict Resolution Patterns:**

**Technical Disagreements:**
- Evaluate based on requirements (charter success criteria)
- Consider infrastructure philosophy alignment
- Balance performance vs. maintainability vs. complexity

**Infrastructure Philosophy Conflicts:**
- Infrastructure philosophy takes precedence (bare metal, systemd, manual)
- If conflict with requirements, escalate to CAIO
- Document as assumption in RAIDD log

**Scope Disagreements:**
- Charter is authoritative (approved scope)
- Out-of-scope items go to backlog
- Scope changes require charter amendment

---

## 📊 Team Size Guidelines

**Typical Team Sizes by Project Complexity:**

| Project Complexity | Core Agents | Additional Agents | Total | Duration |
|-------------------|-------------|-------------------|-------|----------|
| Simple (single service) | 5 | 1-2 | 6-7 | 1-2 weeks |
| Medium (multi-service) | 5 | 3-5 | 8-10 | 2-4 weeks |
| Complex (platform evolution) | 5 | 6-10 | 11-15 | 4-8 weeks |

**Notes:**
- **Core 5** (Agent Zero, Alex, Julia, Frank, William) participate in EVERY project
- **Additional agents** selected based on technology stack and domain needs
- **Infrastructure philosophy** applied regardless of team size
- **Context loading time** increases with team size (coordination overhead)

### **Example Team Compositions:**

**Simple Project: Single LLM Service Deployment**
- Core 5: Agent Zero, Alex, Julia, Frank, William
- Additional: Elena (Ollama), Sarah (LiteLLM)
- Total: 7 agents
- Focus: Basic service deployment with infrastructure philosophy compliance

**Medium Project: RAG Knowledge Base Deployment**
- Core 5: Agent Zero, Alex, Julia, Frank, William
- Additional: Marcus (LightRAG), Quinn (Qdrant), Elena (Ollama), Diana (Crawl4AI)
- Total: 9 agents
- Focus: Multi-service integration with RAG pipeline

**Complex Project: Platform Observability Enhancement**
- Core 5: Agent Zero, Alex, Julia, Frank, William
- Additional: Nathan (Metrics), Patricia (PostgreSQL), Robert (Redis), Marcus (LightRAG), Quinn (Qdrant), Isaac (CI/CD), Amanda (Ansible)
- Total: 12 agents
- Focus: Platform-wide enhancement across multiple layers

---

## ✅ Quality Gates

**Core team provides multi-perspective validation at key approval gates:**

### **Gate 1: Charter Approval** ✅

**Participants:** All core agents + CAIO + Agent Zero

**Validation Criteria:**
- ✅ All core agents reviewed charter (Alex, Julia, Frank, William)
- ✅ Architecture feasible (Alex validation)
- ✅ Testing approach defined (Julia validation)
- ✅ Identity/DNS requirements clear (Frank validation)
- ✅ Infrastructure approach viable (William validation)
- ✅ Infrastructure philosophy explicitly documented
- ✅ Feedback incorporated into charter
- ✅ CAIO approves vision and scope
- ✅ Agent Zero approves charter quality

**Blocking Issues:**
- Infrastructure philosophy not explicit
- Core agent has unresolved concerns
- CAIO does not approve scope

---

### **Gate 2: Specification Approval** ✅

**Participants:** All core agents + project-specific agents + CAIO + Agent Zero

**Validation Criteria:**
- ✅ All core agents contributed to specification
- ✅ Architecture sections complete (Alex contribution)
- ✅ Testing sections complete with 100% coverage plan (Julia contribution)
- ✅ Identity/DNS sections complete (Frank contribution)
- ✅ Infrastructure sections complete with systemd/manual procedures (William contribution)
- ✅ Project-specific sections complete (specialist contributions)
- ✅ Infrastructure philosophy documented in specification
- ✅ No P0/P1 unresolved issues in RAIDD log
- ✅ CAIO approves technical approach
- ✅ Agent Zero approves specification quality

**Blocking Issues:**
- Missing infrastructure philosophy documentation
- P0/P1 defects or issues unresolved
- Core agent section incomplete
- CAIO does not approve technical approach

---

### **Gate 3: Task Plan Approval** ✅

**Participants:** All core agents + CAIO + Agent Zero

**Validation Criteria:**
- ✅ All requirements covered by tasks
- ✅ Test suite generated with 100% coverage (Julia)
- ✅ Infrastructure tasks included (bare metal, systemd, manual procedures)
- ✅ Identity/DNS tasks included (DNS records, certificates, domain-join)
- ✅ Task dependencies identified and sequenced
- ✅ Task assignments clear and feasible
- ✅ CAIO approves task plan
- ✅ Agent Zero approves execution approach

**Blocking Issues:**
- Infrastructure tasks missing (deployment, systemd, manual procedures)
- Test suite not generated or incomplete coverage
- Task dependencies unresolved

---

### **Gate 4: Deployment Readiness** ✅

**Participants:** All core agents + CAIO + Agent Zero

**Validation Criteria:**
- ✅ All tasks completed
- ✅ All tests passing (100% pass required - Julia validation)
- ✅ Manual procedures documented and validated (William)
- ✅ Infrastructure deployed (bare metal, systemd operational - William)
- ✅ DNS records active (Frank)
- ✅ Certificates valid (Frank)
- ✅ Integration validated (Alex)
- ✅ No P0/P1 defects blocking deployment
- ✅ CAIO approves operational promotion
- ✅ Agent Zero approves deployment quality

**Blocking Issues:**
- Tests failing (any failure blocks promotion)
- P0/P1 defects unresolved
- Manual procedures incomplete or unvalidated
- Infrastructure not operational

---

### **Gate 5: Project Closeout** ✅

**Participants:** All core agents + CAIO + Agent Zero

**Validation Criteria:**
- ✅ Service operational and stable
- ✅ All documentation complete (architecture, manual procedures, testing)
- ✅ All defects closed or deferred to backlog
- ✅ Lessons learned documented
- ✅ Knowledge vault updated
- ✅ CAIO final acceptance
- ✅ Agent Zero approves project completion

**Blocking Issues:**
- Documentation incomplete
- Unresolved defects not properly deferred
- Service not stable

---

## 📝 Team Assignment Documentation

**For each project, document team assignments in:**

**Location:** `/nodes/[node-name]/team-assignments.md`

**Template:**
```markdown
# Team Assignments: [Node Name]

**Project:** [project-name]
**Date:** [YYYY-MM-DD]
**Status:** [Active/Complete]

---

## Core Team (Standard)

**Agent Zero (CC) - Universal PM Orchestrator**
- Role: Orchestration, coordination, decision authority
- Participates: All phases
- State: STATEFUL - maintains context throughout

**Alex Rivera - Platform Architect**
- Role: Architecture design, ADRs, integration patterns
- Participates: Charter review, specification, deployment validation
- State: STATELESS - context load required each phase

**Julia Chen - Testing & Quality Specialist**
- Role: Test-driven deployment, 100% coverage, quality gates
- Participates: Charter review, specification, test generation, test execution, quality validation
- State: STATELESS - context load required each phase

**Frank Martinez - Security Specialist**
- Role: Identity & Trust, Samba AD, Kerberos, certificates, DNS
- Participates: Charter review, specification, deployment (DNS/certs)
- State: STATELESS - context load required each phase

**William Thompson - Infrastructure Specialist**
- Role: Bare metal deployment, systemd, manual procedures, network config
- Participates: Charter review, specification, deployment execution, manual procedure documentation
- State: STATELESS - context load required each phase

---

## Project-Specific Agents

**[Agent Name] - [Role]**
- Role: [Specialty/domain]
- Participates: [Phases where involved]
- Knowledge: [Assigned repos]
- State: STATELESS - context load required

[Repeat for each project-specific agent]

---

## Knowledge Vault Assignments

**Agent Zero:**
- [Primary repos researched during charter phase]
- [All HX-Infrastructure standards]

**Alex (Architecture):**
- [Architecture-related repos]
- agentic-design-patterns-docs-main
- [Project-specific architecture repos]

**Julia (Testing):**
- [Testing framework repos]
- cypress (if web UI)
- pytest (if Python)
- [Project-specific testing repos]

**Frank (Security):**
- [Security/identity repos]
- nginx (SSL/TLS)
- ansible-devel (configuration patterns)
- [Project-specific security repos]

**William (Infrastructure):**
- [Infrastructure repos]
- [Systemd documentation]
- [Ubuntu documentation]
- [Project-specific infrastructure repos]

**[Project-Specific Agents]:**
- [Agent name]: [Assigned repos]

---

## Infrastructure Philosophy

**Deployment Approach:** Bare metal (Ubuntu 24)
**Target Server:** [hostname] (IP: [192.168.10.XXX])
**Network Zone:** [Security Zone name]
**Service Management:** Systemd
**Deployment Process:** Manual procedures
**Credentials:** Ansible Vault
**Docker:** Not used (or dev-only on hx-dev-server if exception)

---

## Communication

**Primary Orchestrator:** Agent Zero
**Decision Authority:** Agent Zero (final decisions)
**Conflict Resolution:** Agent Zero arbitration, documented in RAIDD log
**Context Handoffs:** Via cc-context-prep.md and cc-handoff.md

---

## Quality Gates

- ✅ Charter Approval (all core agents + CAIO + Agent Zero)
- ✅ Specification Approval (all agents + CAIO + Agent Zero)
- ✅ Task Plan Approval (all core agents + CAIO + Agent Zero)
- ✅ Deployment Readiness (all core agents + CAIO + Agent Zero)
- ✅ Project Closeout (all core agents + CAIO + Agent Zero)
```

---

## 🔗 Related Documentation

### **Agent Documentation:**
- **Agent Inventory:** `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` (45 agents)
- **Orchestration Guide:** `/home/agent0/HX-Infrastructure/hx-agents/hx-orchestration-guide.md`
- **Knowledge Vault Catalog:** `/home/agent0/HX-Infrastructure/hx-agents/hx-knowledge-vault-catalog.md`
- **Agent Profiles:** `/home/agent0/.claude/agents/` (individual agent specifications)

### **HX-Infrastructure Core:**
- **Constitution:** `/home/agent0/HX-Infrastructure/constitution.md` (governance principles)
- **README:** `/home/agent0/HX-Infrastructure/README.md` (repository overview)
- **Action Plan:** `/home/agent0/HX-Infrastructure/action-plan-v2-updated.md` (project roadmap)

### **Standards:**
- **Architecture Standards:** `standards/architecture-standards.md`
- **Deployment Requirements:** `standards/deployment-requirements.md` (infrastructure philosophy)
- **Testing Requirements:** `standards/testing-requirements.md`
- **Documentation Requirements:** `standards/documentation-requirements.md`

### **Procedures:**
- **Context Loading:** `procedures/context-loading-process.md` (CRITICAL for stateless agents)
- **Charter Workflow:** `procedures/charter-workflow.md`
- **Spec Workflow:** `procedures/spec-workflow.md`
- **Task Workflow:** `procedures/task-workflow.md`
- **Execution Workflow:** `procedures/task-execution-workflow.md`
- **Closeout Workflow:** `procedures/project-closeout-workflow.md`

### **Claude Code Commands:**
- **Workflows (Set 1):** `.claude/commands/workflows/` (Charter, Spec, Task, Execution, Closeout)
- **Utilities (Set 3):** `.claude/commands/utilities/` (context-prep, handoff, raidd, etc.)
- **Phase Commands (Set 4):** `.claude/commands/phases/` (charter-questions, knowledge-research, test-suite-generation, etc.)
- **Agent Orchestration (Set 5):** `.claude/commands/agents/` (orchestrate-alex, frank, william, julia, agent-zero-synthesis)

---

## Document Maintenance

**Update Triggers:**
- New core agent added or role changed
- New specialist agent added to ecosystem
- Infrastructure philosophy updates
- Quality gate criteria changes
- Team coordination patterns evolve
- Conflict resolution patterns identified

**Version History:**

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-16 | Initial core project team documentation | Infrastructure Team |
| 1.1 | 2025-11-21 | Infrastructure philosophy emphasis, expanded agent profiles, quality gates detail, context loading requirements, Claude Code integration | HX-Infrastructure Team |

---

**Document Information:**
- **Version:** 1.1
- **Status:** APPROVED - Production Ready
- **Maintained By:** HX-Infrastructure Team
- **Review Frequency:** After each multi-agent project (continuous improvement)
- **Last Review:** 2025-11-21
- **Next Review:** After next multi-agent project completion

---

*This core project team procedure defines the standard 5-agent core team (Agent Zero, Alex, Frank, William, Julia) that participates in every HX-Infrastructure project. It establishes roles, responsibilities, state management requirements, and quality gates to ensure consistent multi-perspective validation across all project phases while maintaining strict adherence to HX-Infrastructure philosophy.*
