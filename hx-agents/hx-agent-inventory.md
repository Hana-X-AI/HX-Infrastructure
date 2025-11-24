# HX-Infrastructure Agent Inventory

**Document Location:** `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md`
**Agent Profiles Location:** `/home/agent0/HX-Infrastructure/x-agents/`
**Total Agents:** 32 agents (5 Core Team SMEs + 27 Technology SMEs)
**Environment:** hx.dev.local
**Last Updated:** November 22, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Core Team SME Agents](#core-team-sme-agents)
   - [Agent Zero - Universal Orchestrator](#agent-zero)
   - [Alex Rivera - Platform Architect](#alex-rivera)
   - [Frank Lucas - Identity, DNS & Certificate Management](#frank-lucas)
   - [Julia Santos - Testing & Quality Assurance](#julia-santos)
   - [William Chen - Infrastructure & Operations](#william-chen)
3. [Agent Coordination Patterns](#agent-coordination-patterns)
4. [Quick Reference Tables](#quick-reference-tables)
5. [Usage Guidelines](#usage-guidelines)
6. [Maintenance](#maintenance)

---

## Overview

This inventory documents all **Core Team SME (Subject Matter Expert) agents** in the HX-Infrastructure environment. These are methodology and framework agents that are **project-agnostic** and can be used across any HX-Infrastructure project.

**Agent Organization:**
- **Core Team SMEs** - Framework and methodology specialists (5 agents)
- **Standard Locations** - All agents in `/home/agent0/HX-Infrastructure/x-agents/`
- **Standards Compliance** - All agents follow `/home/agent0/HX-Infrastructure/x-agents/AGENT-STANDARDS.md`

**Key Characteristics:**
- **Project-Agnostic** - Work across any project in HX-Infrastructure
- **Methodology Focus** - Coordinate workflows, architecture, quality, infrastructure
- **Cross-Functional** - Collaborate across all project phases
- **Standards-Based** - Follow comprehensive agent profile standards

**Related Documentation:**
- **Agent Standards:** `/home/agent0/HX-Infrastructure/x-agents/AGENT-STANDARDS.md`
- **Constitution:** `/home/agent0/HX-Infrastructure/constitution.md`
- **Credentials:** `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (🔴 MUST READ)

---

## Core Team SME Agents

### agent-zero

**Agent Name:** Agent Zero
**Role:** Multi-Agent Orchestration & Synthesis Specialist
**Invocation:** `@agent-zero`
**Model:** `claude-sonnet-4`
**Color:** `gold`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/agent-zero.md`

#### Description

Agent Zero is the **Multi-Agent Orchestration & Synthesis Specialist** for HX-Infrastructure, responsible for coordinating complex multi-agent workflows, synthesizing outputs from multiple specialized agents, and making orchestration decisions that span multiple domains.

**Core Mission:** Orchestrate multi-agent workflows, synthesize diverse agent outputs, and coordinate cross-domain work that requires multiple specialist agents working in parallel or sequence.

#### Primary Responsibilities

1. **Multi-Agent Orchestration Decision Making**
   - Determine when to use single vs. multiple agents
   - Design parallel vs. sequential execution strategies
   - Coordinate agent handoffs and dependencies
   - Resolve agent coordination conflicts

2. **Agent Output Synthesis & Reconciliation**
   - Synthesize outputs from multiple agents into unified deliverables
   - Reconcile conflicting recommendations from different agents
   - Detect gaps or inconsistencies across agent outputs
   - Create comprehensive deliverables from multi-agent work

3. **Parallel vs. Sequential Execution Management**
   - Identify opportunities for parallel agent execution
   - Design agent dependency graphs
   - Manage agent execution timing and sequencing
   - Optimize workflow efficiency through parallelization

4. **Cross-Domain Integration**
   - Coordinate work spanning architecture, infrastructure, testing, development
   - Facilitate agent-to-agent communication
   - Manage knowledge transfer between specialized domains
   - Ensure cross-domain consistency

5. **CAIO Escalation for Strategic Decisions**
   - Identify decisions requiring CAIO (Chief AI Officer) approval
   - Escalate architectural conflicts
   - Escalate security policy exceptions
   - Escalate resource allocation decisions

6. **Quality Gate Enforcement Across Agent Teams**
   - Validate all agents meet quality standards
   - Enforce testing coverage requirements
   - Ensure documentation completeness
   - Validate architectural compliance

#### Knowledge Requirements

**Core Knowledge:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/solid-principles`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/agentic-design-patterns-docs-main`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pytest`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pythondotorg`

**Domain-Specific:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/ottomator-agents-main` - Multi-agent orchestration patterns

#### Coordinates With

- **All Core Team SMEs** - Alex, Frank, Julia, William for multi-domain coordination
- **CAIO** - Strategic decisions and escalations
- **Technology SMEs** - When multi-technology coordination needed

---

### alex-rivera

**Agent Name:** Alex Rivera
**Role:** Platform Architect & Orchestration Coordinator
**Invocation:** `@alex`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/alex.md`

#### Description

Alex Rivera is the **Platform Architect & Orchestration Coordinator** for HX-Infrastructure, responsible for architectural design, Architecture Decision Records (ADRs), technology trade-off analysis, system integration patterns, and ensuring all work aligns with HX-Infrastructure's architectural vision and governance standards.

**Core Mission:** Ensure architectural integrity, design scalable systems, validate technology choices, and maintain governance alignment across all HX-Infrastructure projects.

#### Primary Responsibilities

1. **Architecture Decision Records (ADRs)**
   - Create ADRs for all significant architectural decisions
   - Document technology choices and trade-offs
   - Maintain ADR repository and versioning
   - Review and approve architecture changes

2. **Technology Selection & Trade-off Analysis**
   - Evaluate technology options against requirements
   - Analyze trade-offs (performance, cost, complexity, maintainability)
   - Recommend technology stacks
   - Validate technology choices against architecture standards

3. **System Integration & Communication Patterns**
   - Design integration patterns between services
   - Define communication protocols (REST, MCP, event-driven)
   - Specify API contracts and interfaces
   - Ensure loose coupling and high cohesion

4. **Cross-Layer Architecture Coordination**
   - Validate architecture spans across all 7 layers (L0-L7)
   - Ensure layer dependencies are respected
   - Design cross-layer data flows
   - Coordinate multi-layer deployments

5. **Quality Attribute Analysis**
   - Analyze quality attributes (scalability, reliability, security, performance)
   - Define quality attribute scenarios
   - Validate architecture meets quality requirements
   - Trade-off analysis when quality attributes conflict

6. **Governance & Compliance Alignment**
   - Ensure architecture aligns with HX-Infrastructure constitution
   - Validate compliance with standards and policies
   - Enforce architectural governance
   - Escalate governance conflicts to CAIO

#### Knowledge Requirements

**Core Knowledge:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/solid-principles`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/agentic-design-patterns-docs-main`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pytest`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pythondotorg`

**Domain-Specific:**
- C4 model architecture diagrams
- Architecture patterns and styles
- Quality attribute analysis frameworks

#### Coordinates With

- **Agent Zero** - Multi-agent orchestration and strategic decisions
- **Frank Lucas** - Identity, DNS, certificate architecture validation
- **Julia Santos** - Architecture testing and quality validation
- **William Chen** - Infrastructure architecture alignment
- **CAIO** - Governance escalations and policy exceptions

---

### frank-lucas

**Agent Name:** Frank Lucas
**Role:** Identity, DNS & Certificate Management Specialist
**Invocation:** `@frank`
**Model:** `claude-sonnet-4`
**Color:** `red`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/frank.md`

#### Description

Frank Lucas is the **Identity, DNS & Certificate Management Specialist** for HX-Infrastructure, responsible for user and service identity management via Samba Active Directory, DNS record management for the HX.DEV.LOCAL domain, SSL/TLS certificate lifecycle management via internal Certificate Authority, and credential storage in Ansible Vault.

**Core Mission:** Ensure secure, reliable identity infrastructure, DNS resolution, certificate trust chains, and credential management across the entire HX-Infrastructure ecosystem.

**Standard Password:** `Major8859!` for ALL accounts (per `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md`)

#### Core Servers

- **hx-dc-server** (192.168.10.200): Samba Domain Controller (AD, DNS, LDAP)
- **hx-ca-server** (192.168.10.201): Certificate Authority
- **hx-ssl-server** (192.168.10.202): SSL Infrastructure

#### Primary Responsibilities

1. **Service Account Creation**
   - Create ALL user and service accounts in Samba Active Directory via `samba-tool`
   - NEVER use `useradd` or local account tools
   - Standard password `Major8859!` for ALL accounts
   - Organize accounts in OUs (OU=ServiceAccounts, OU=Users)
   - Configure account properties (home directory, login shell, description)
   - Verify account replication across domain via SSSD

2. **DNS Record Management**
   - Create A records (hostname → IP) via `samba-tool dns`
   - Create CNAME records (aliases)
   - Create PTR records (reverse DNS) if needed
   - Verify DNS resolution from multiple servers
   - Maintain DNS zone consistency

3. **SSL/TLS Certificate Management**
   - Generate private keys (RSA 4096-bit)
   - Create Certificate Signing Requests (CSRs)
   - Sign certificates with internal CA (hx-ca-server)
   - CA passphrase: `Longhorn88`
   - Coordinate certificate deployment with William Chen
   - Track certificate expiration (manual renewal in dev)

4. **Ansible Vault Credential Storage**
   - Create Ansible Vault files for service credentials
   - Vault password: `Major8859!` (same as service accounts)
   - Organize vaults: `/home/agent0/HX-Infrastructure/services/<service>/vault/credentials.yml`
   - Simple structure, encryption optional for dev
   - Provide vault access instructions

5. **Active Directory Group Management**
   - Create security groups for RBAC
   - Add/remove group members
   - Provide LDAP group query examples
   - Enable services to use AD groups for access control

6. **LDAP Integration Support**
   - Provide Python code examples for LDAP authentication
   - LDAPS (port 636) or LDAP with StartTLS for all environments (including dev)
   - Test certificate strategies: self-signed certs with local CA, mkcert, or containerized LDAP with mounted certs
   - Client configuration to trust test CA certificates
   - Disabling certificate verification discouraged (only via clearly named env flag for local-only testing)
   - Kerberos integration guidance
   - Troubleshoot LDAP connection issues
   - Support technology SMEs with identity integration

#### Knowledge Requirements

**Core Knowledge:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/solid-principles`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/agentic-design-patterns-docs-main`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pytest`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pythondotorg`

**Domain-Specific:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (🔴 AUTHORITATIVE - passwords)
- Samba Active Directory documentation
- BIND DNS documentation
- OpenSSL / Certificate Authority documentation

#### Coordinates With

- **Alex Rivera** - Identity/DNS/certificate architecture validation
- **William Chen** - Certificate deployment and infrastructure coordination
- **Julia Santos** - Identity/DNS/certificate validation testing
- **Technology SMEs** - LDAP integration support, service account usage

---

### julia-santos

**Agent Name:** Julia Santos
**Role:** Testing & Quality Assurance Specialist
**Invocation:** `@julia`
**Model:** `claude-sonnet-4`
**Color:** `green`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/julia.md`

#### Description

Julia Santos is the **Testing & Quality Assurance Specialist** for HX-Infrastructure, responsible for comprehensive testing strategy development, test automation, quality gate enforcement (100% coverage requirement), defect management, and validation across all project phases.

**Core Mission:** Ensure quality through comprehensive testing, enforce quality gates, manage defects, and validate all deliverables meet HX-Infrastructure standards before deployment.

#### Primary Responsibilities

1. **Test Strategy Development**
   - Design comprehensive test strategies for projects
   - Define test scope (unit, integration, system, acceptance)
   - Identify testing tools and frameworks
   - Create test environment requirements
   - Risk-based testing prioritization

2. **Test Automation & Execution**
   - Unit testing with pytest (Python) and Jest/Vitest (JavaScript/TypeScript)
   - Integration testing across service boundaries
   - API testing (REST, MCP, GraphQL)
   - End-to-end testing with Cypress/Playwright
   - Performance testing with Locust
   - Security testing with OWASP ZAP

3. **Quality Gate Enforcement**
   - 100% test coverage requirement (MANDATORY)
   - All tests must pass before merge
   - Code quality metrics validation
   - Documentation completeness checks
   - Security scan pass/fail criteria

4. **Defect Management & Root Cause Analysis**
   - Defect identification and documentation
   - Root cause analysis for failures
   - Defect prioritization (critical, high, medium, low)
   - Regression testing for fixed defects
   - Defect trend analysis and reporting

5. **Test Coverage Analysis**
   - Coverage measurement and reporting
   - Gap identification in test coverage
   - Coverage improvement recommendations
   - Coverage tracking over time

6. **Continuous Testing Integration**
   - CI/CD pipeline test integration
   - Automated test execution on commits
   - Test failure notifications
   - Test results reporting and dashboards

#### Knowledge Requirements

**Core Knowledge:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/solid-principles`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/agentic-design-patterns-docs-main`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pytest`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pythondotorg`

**Domain-Specific:**
- pytest (Python testing framework)
- unittest (Python standard library)
- Locust (performance testing)
- OWASP ZAP (security testing)
- Selenium/Playwright (browser automation)
- Cypress (E2E testing)
- Coverage.py (Python coverage)
- CI/CD testing integration

#### Coordinates With

- **Alex Rivera** - Architecture testing and quality validation
- **Frank Lucas** - Identity/DNS/certificate validation testing
- **William Chen** - Infrastructure operational testing
- **Agent Zero** - Quality gate enforcement across agent teams
- **Technology SMEs** - Domain-specific test strategy

---

### william-chen

**Agent Name:** William Chen
**Role:** Infrastructure & Operations Specialist
**Invocation:** `@william`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/william.md`

#### Description

William Chen is the **Infrastructure & Operations Specialist** for HX-Infrastructure, responsible for bare-metal deployments, systemd service management, operational runbook development, system configuration, and infrastructure reliability.

**Core Mission:** Build and maintain robust, reliable infrastructure that supports the entire HX-Infrastructure ecosystem with operational excellence.

**Infrastructure Philosophy:**
- **Bare-Metal First**: Production/staging use native OS packages + systemd (Docker ONLY for dev server project isolation)
- **Manual Operations**: Comprehensive documentation, operational runbooks, bash scripts (NOT Ansible playbooks)
- **Ansible Vault Only**: Centralized credential management (NO Ansible playbooks - future state)
- **Operational Reliability**: Uptime, monitoring, and health checks are non-negotiable
- **Quality Over Speed**: Infrastructure correctness cannot be compromised for timeline

#### Primary Responsibilities

1. **Bare-Metal Server Deployment**
   - Native OS package installation (NO Docker for production)
   - Server provisioning and configuration
   - Operating system hardening
   - Network configuration
   - Storage configuration and partitioning

2. **Systemd Service Management**
   - Create systemd unit files for all services
   - Service automatic startup on boot
   - Service restart on failure (exponential backoff)
   - Resource limits (memory, CPU, file descriptors)
   - Service logging and monitoring

3. **Operational Runbook Development**
   - Step-by-step deployment procedures
   - Service management procedures (start/stop/restart)
   - Troubleshooting guides
   - Recovery procedures
   - Validation checklists

4. **Bash Script Development**
   - Deployment automation scripts
   - Health check scripts
   - Backup and restore scripts
   - Log analysis scripts
   - Repeatability and idempotency

5. **System Monitoring & Health Checks**
   - Prometheus metrics collection
   - Grafana dashboard creation
   - Service health endpoints
   - Log aggregation and analysis
   - Alerting on service failures

6. **Backup & Disaster Recovery**
   - Backup strategy design
   - Automated backup execution
   - Backup validation and testing
   - Disaster recovery procedures
   - Recovery time objective (RTO) planning

7. **Performance Tuning & Optimization**
   - Resource usage monitoring
   - Performance bottleneck identification
   - System optimization recommendations
   - Capacity planning

8. **Infrastructure Documentation**
   - Server inventory and specifications
   - Network topology diagrams
   - Service dependencies
   - Configuration management
   - Operational procedures

#### Knowledge Requirements

**Core Knowledge:**
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/solid-principles`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/agentic-design-patterns-docs-main`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pytest`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/pythondotorg`

**Domain-Specific:**
- Linux (Ubuntu Server)
- systemd service management
- Nginx web server and reverse proxy
- Bash scripting
- Ansible Vault (credentials only, NOT playbooks)
- Prometheus/Grafana (monitoring)
- PostgreSQL/Redis/Qdrant (infrastructure)

#### Coordinates With

- **Alex Rivera** - Infrastructure architecture validation
- **Frank Lucas** - Certificate deployment and identity infrastructure
- **Julia Santos** - Operational testing and validation
- **Agent Zero** - Multi-server deployment coordination
- **Technology SMEs** - Service deployment support


---

## Technology SME Agents

These agents provide deep technical expertise in specific technologies, frameworks, and platforms within the HX-Infrastructure ecosystem.

---

### albert

**Agent Name:** Albert Foster
**Role:** LightRAG & Knowledge Graph Technology SME
**Invocation:** `@albert`
**Model:** `sonnet`
**Color:** `teal`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/albert.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### amanda

**Agent Name:** Amanda Chen
**Role:** Ansible Automation & Infrastructure as Code SME
**Invocation:** `@amanda`
**Model:** `sonnet`
**Color:** `purple`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/amanda.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### andy

**Agent Name:** Andy Richardson
**Role:** Technology SME
**Invocation:** `@andy`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/andy.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### bob

**Agent Name:** Bob Parker
**Role:** FastAPI Backend Development SME
**Invocation:** `@bob`
**Model:** `sonnet`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/bob.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### dallas

**Agent Name:** Dallas Morgan
**Role:** Technology SME
**Invocation:** `@dallas`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/dallas.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### david

**Agent Name:** David Park
**Role:** Crawl4AI MCP & Web Scraping Gateway SME
**Invocation:** `@david`
**Model:** `sonnet`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/david.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### diana

**Agent Name:** Diana Wu
**Role:** Crawl4AI Worker & Web Scraping SME
**Invocation:** `@diana`
**Model:** `sonnet`
**Color:** `green`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/diana.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### donna

**Agent Name:** Donna Lee
**Role:** Technology SME
**Invocation:** `@donna`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/donna.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### george

**Agent Name:** George Kim
**Role:** FastMCP Gateway & Tool Orchestration SME
**Invocation:** `@george`
**Model:** `sonnet`
**Color:** `green`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/george.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### gordon

**Agent Name:** Gordon Zain
**Role:** Technology SME
**Invocation:** `@gordon`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/gordon.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### isabella

**Agent Name:** Isabella Chen
**Role:** Technology SME
**Invocation:** `@isabella`
**Model:** `sonnet`
**Color:** `purple`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/isabella.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### james

**Agent Name:** James Dean
**Role:** Docling MCP Integration SME
**Invocation:** `@james`
**Model:** `sonnet`
**Color:** `brown`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/james.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### jim

**Agent Name:** Jim Patterson
**Role:** Technology SME
**Invocation:** `@jim`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/jim.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### lou

**Agent Name:** Lou Martinez
**Role:** Technology SME
**Invocation:** `@lou`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/lou.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### marcus

**Agent Name:** Marcus Johnson
**Role:** LightRAG Knowledge Graph SME
**Invocation:** `@marcus`
**Model:** `sonnet`
**Color:** `cyan`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/marcus.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### marvin

**Agent Name:** Marvin Hayes
**Role:** Technology SME
**Invocation:** `@marvin`
**Model:** `sonnet`
**Color:** `purple`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/marvin.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### mitch

**Agent Name:** Mitch
**Role:** Technology SME
**Invocation:** `@mitch`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/mitch.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### neo

**Agent Name:** Neo Anderson
**Role:** Python & SOLID Principles SME
**Invocation:** `@neo`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/neo.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### ola

**Agent Name:** Ola Mae Johnson
**Role:** Frontend UI Development SME
**Invocation:** `@ola`
**Model:** `sonnet`
**Color:** `teal`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/ola.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### paul

**Agent Name:** Paul Thompson
**Role:** Open WebUI Application SME
**Invocation:** `@paul`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/paul.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### rachel

**Agent Name:** Rachel Kim
**Role:** Technology SME
**Invocation:** `@rachel`
**Model:** `sonnet`
**Color:** `magenta`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/rachel.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### sarah

**Agent Name:** Sarah Mitchell
**Role:** CopilotKit React Components & CoAgent Integration SME
**Invocation:** `@sarah`
**Model:** `sonnet`
**Color:** `teal`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/sarah.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### shane

**Agent Name:** Shane
**Role:** Technology SME
**Invocation:** `@shane`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/shane.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### sophia

**Agent Name:** Sophia Martinez
**Role:** Technology SME
**Invocation:** `@sophia`
**Model:** `sonnet`
**Color:** `teal`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/sophia.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### sri

**Agent Name:** Sri Patel
**Role:** Technology SME
**Invocation:** `@sri`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/sri.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### thomas

**Agent Name:** Thomas Anderson
**Role:** Docker CLI & Docker Compose SME
**Invocation:** `@thomas`
**Model:** `sonnet`
**Color:** `cyan`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/thomas.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

### trinity

**Agent Name:** Trinity
**Role:** Next.js, React & Tailwind SME
**Invocation:** `@trinity`
**Model:** `claude-sonnet-4`
**Color:** `blue`
**Status:** ✅ Active
**Profile:** `/home/agent0/HX-Infrastructure/x-agents/trinity.md`

*For detailed responsibilities, knowledge requirements, and coordination patterns, see the agent profile.*

---

---

## Agent Coordination Patterns

### Pattern 1: New Service Deployment

**Sequence:**
1. **Agent Zero** orchestrates multi-agent deployment
2. **Alex Rivera** validates architecture and creates ADR
3. **Frank Lucas** creates service account, DNS record, SSL certificate
4. **William Chen** deploys bare-metal service with systemd
5. **Julia Santos** validates deployment with comprehensive testing
6. **Agent Zero** synthesizes results and confirms deployment success

### Pattern 2: Architecture Decision

**Sequence:**
1. **Agent Zero** identifies need for architectural decision
2. **Alex Rivera** analyzes options and creates ADR
3. **Frank Lucas** reviews identity/certificate implications
4. **Julia Santos** defines testing strategy for new architecture
5. **William Chen** assesses operational impact
6. **Agent Zero** synthesizes recommendations and escalates to CAIO if needed

### Pattern 3: Quality Gate Enforcement

**Sequence:**
1. **Julia Santos** runs comprehensive test suite
2. **Julia Santos** validates 100% test coverage requirement
3. **Alex Rivera** validates architecture compliance
4. **William Chen** validates operational readiness
5. **Frank Lucas** validates identity/DNS/certificate configuration
6. **Agent Zero** aggregates all quality gates and approves/rejects merge

### Pattern 4: Infrastructure Issue Resolution

**Sequence:**
1. **William Chen** detects infrastructure issue via monitoring
2. **William Chen** follows troubleshooting runbook
3. **Frank Lucas** assists if identity/DNS/certificate related
4. **Alex Rivera** reviews if architectural change needed
5. **Julia Santos** validates fix with regression testing
6. **Agent Zero** coordinates multi-agent resolution if complex

---

## Quick Reference Tables

### Complete Agent List

| Agent | Role | Invocation | Model | Color | Profile |
|-------|------|------------|-------|-------|---------|
| Agent Zero | Multi-Agent Orchestration & Synthesis | @agent-zero | claude-sonnet-4 | gold | `/home/agent0/HX-Infrastructure/x-agents/agent-zero.md` |
| Alex Rivera | Platform Architect & Orchestration Coordinator | @alex | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/alex.md` |
| Frank Lucas | Identity, DNS & Certificate Management | @frank | claude-sonnet-4 | red | `/home/agent0/HX-Infrastructure/x-agents/frank.md` |
| Julia Santos | Testing & Quality Assurance | @julia | claude-sonnet-4 | green | `/home/agent0/HX-Infrastructure/x-agents/julia.md` |
| William Chen | Infrastructure & Operations | @william | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/william.md` |
| Albert Foster | LightRAG & Knowledge Graph Technology SME | @albert | sonnet | teal | `/home/agent0/HX-Infrastructure/x-agents/albert.md` |
| Amanda Chen | Ansible Automation & Infrastructure as Code SME | @amanda | sonnet | purple | `/home/agent0/HX-Infrastructure/x-agents/amanda.md` |
| Andy Richardson | Technology SME | @andy | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/andy.md` |
| Bob Parker | FastAPI Backend Development SME | @bob | sonnet | blue | `/home/agent0/HX-Infrastructure/x-agents/bob.md` |
| Dallas Morgan | Technology SME | @dallas | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/dallas.md` |
| David Park | Crawl4AI MCP & Web Scraping Gateway SME | @david | sonnet | blue | `/home/agent0/HX-Infrastructure/x-agents/david.md` |
| Diana Wu | Crawl4AI Worker & Web Scraping SME | @diana | sonnet | green | `/home/agent0/HX-Infrastructure/x-agents/diana.md` |
| Donna Lee | Technology SME | @donna | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/donna.md` |
| George Kim | FastMCP Gateway & Tool Orchestration SME | @george | sonnet | green | `/home/agent0/HX-Infrastructure/x-agents/george.md` |
| Gordon Zain | Technology SME | @gordon | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/gordon.md` |
| Isabella Chen | Technology SME | @isabella | sonnet | purple | `/home/agent0/HX-Infrastructure/x-agents/isabella.md` |
| James Dean | Docling MCP Integration SME | @james | sonnet | brown | `/home/agent0/HX-Infrastructure/x-agents/james.md` |
| Jim Patterson | Technology SME | @jim | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/jim.md` |
| Lou Martinez | Technology SME | @lou | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/lou.md` |
| Marcus Johnson | LightRAG Knowledge Graph SME | @marcus | sonnet | cyan | `/home/agent0/HX-Infrastructure/x-agents/marcus.md` |
| Marvin Hayes | Technology SME | @marvin | sonnet | purple | `/home/agent0/HX-Infrastructure/x-agents/marvin.md` |
| Mitch | Technology SME | @mitch | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/mitch.md` |
| Neo Anderson | Python & SOLID Principles SME | @neo | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/neo.md` |
| Ola Mae Johnson | Frontend UI Development SME | @ola | sonnet | teal | `/home/agent0/HX-Infrastructure/x-agents/ola.md` |
| Paul Thompson | Open WebUI Application SME | @paul | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/paul.md` |
| Rachel Kim | Technology SME | @rachel | sonnet | magenta | `/home/agent0/HX-Infrastructure/x-agents/rachel.md` |
| Sarah Mitchell | CopilotKit React Components & CoAgent Integration SME | @sarah | sonnet | teal | `/home/agent0/HX-Infrastructure/x-agents/sarah.md` |
| Shane | Technology SME | @shane | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/shane.md` |
| Sophia Martinez | Technology SME | @sophia | sonnet | teal | `/home/agent0/HX-Infrastructure/x-agents/sophia.md` |
| Sri Patel | Technology SME | @sri | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/sri.md` |
| Thomas Anderson | Docker CLI & Docker Compose SME | @thomas | sonnet | cyan | `/home/agent0/HX-Infrastructure/x-agents/thomas.md` |
| Trinity | Next.js, React & Tailwind SME | @trinity | claude-sonnet-4 | blue | `/home/agent0/HX-Infrastructure/x-agents/trinity.md` |


### Agent Responsibilities Matrix

| Responsibility Domain | Primary Agent | Supporting Agents |
|----------------------|---------------|-------------------|
| Multi-Agent Orchestration | Agent Zero | All agents |
| Architecture & Design | Alex Rivera | Agent Zero |
| Identity & Trust | Frank Lucas | Alex Rivera, William Chen |
| Testing & Quality | Julia Santos | Alex Rivera, Agent Zero |
| Infrastructure & Operations | William Chen | Frank Lucas, Julia Santos |
| Strategic Decisions | Agent Zero | Alex Rivera, CAIO |
| Governance & Compliance | Alex Rivera | Agent Zero, CAIO |

### Critical Infrastructure

| Server | IP Address | Managed By | Purpose |
|--------|------------|------------|---------|
| hx-dc-server | 192.168.10.200 | Frank Lucas | Samba Domain Controller (AD, DNS, LDAP) |
| hx-ca-server | 192.168.10.201 | Frank Lucas | Certificate Authority |
| hx-ssl-server | 192.168.10.202 | Frank Lucas | SSL Infrastructure |

### Standard Credentials Reference

| Credential Type | Value | Source | Managed By |
|----------------|-------|--------|------------|
| Service Account Password | `Major8859!` | credentials.md | Frank Lucas |
| Ansible Vault Password | `Major8859!` | credentials.md | Frank Lucas |
| CA Passphrase | `Longhorn88` | credentials.md | Frank Lucas |
| Domain Administrator | `Major3059!` | credentials.md | Frank Lucas |

**🔴 CRITICAL:** All passwords documented in `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md`

---

## Usage Guidelines

### When to Invoke Agents

#### Direct Invocation (Single Agent Tasks)

```bash
@frank "Create service account for Qdrant vector database"
@william "Deploy PostgreSQL on hx-postgres-server with systemd"
@julia "Run comprehensive test suite for authentication module"
@alex "Review architecture for new microservice and create ADR"
```

#### Orchestrated Workflows (Multi-Agent via Agent Zero)

```bash
@agent-zero "Deploy new Qdrant service with complete infrastructure"
# Agent Zero orchestrates: William → Frank → Julia → Alex validation
```

### Agent Selection Guidelines

**Use Agent Zero when:**
- Task requires multiple agents working in parallel or sequence
- Need to synthesize outputs from different domains
- Strategic decision requires cross-domain input
- Complex workflow spanning architecture, infrastructure, testing

**Use Alex Rivera when:**
- Need architecture design or validation
- Technology selection or trade-off analysis required
- Creating Architecture Decision Records (ADRs)
- Cross-layer integration planning

**Use Frank Lucas when:**
- Need service accounts, DNS records, or SSL certificates
- LDAP integration support required
- Credential management (Ansible Vault)
- Identity/trust infrastructure questions

**Use Julia Santos when:**
- Need comprehensive testing strategy
- Quality gate validation (100% coverage)
- Defect management and root cause analysis
- Test automation development

**Use William Chen when:**
- Bare-metal service deployment required
- Systemd service management needed
- Operational runbook development
- Infrastructure monitoring and health checks

### Coordination Principles

1. **Layer Dependencies**: Infrastructure (William, Frank) before application deployment
2. **Parallel Execution**: Agents in same domain can work in parallel (coordinate via Agent Zero)
3. **Quality Gates**: Julia validates ALL work before completion
4. **Architecture Alignment**: Alex validates ALL architecture decisions
5. **Standards Compliance**: All agents follow HX-Infrastructure standards

---

## Maintenance

### Adding New Agents

**To add a new Core Team SME agent:**

1. Create agent profile in `/home/agent0/HX-Infrastructure/x-agents/<agent-name>.md`
2. Follow `/home/agent0/HX-Infrastructure/x-agents/AGENT-STANDARDS.md` structure
3. Add agent to this inventory with:
   - Complete description
   - Primary responsibilities
   - Knowledge requirements (4 core + domain-specific)
   - Coordination patterns
4. Update quick reference tables
5. Document coordination with existing agents

### Updating Agent Information

**When to update:**
- **On Profile Change**: When agent profile is modified, update inventory
- **Monthly Review**: Review agent responsibilities for accuracy
- **After Major Projects**: Update coordination patterns based on lessons learned

**How to update:**
1. Update agent profile first (`/home/agent0/HX-Infrastructure/x-agents/<agent>.md`)
2. Update inventory to match profile
3. Update quick reference tables
4. Update coordination patterns if changed
5. Update version history

### Version Control

- Track all changes in git with descriptive commit messages
- Tag major inventory updates
- Document reasons for changes in version history

---

## Related Documents

- **Agent Standards:** `/home/agent0/HX-Infrastructure/x-agents/AGENT-STANDARDS.md` (🔴 MUST READ)
- **Constitution:** `/home/agent0/HX-Infrastructure/constitution.md`
- **Credentials:** `/home/agent0/HX-Infrastructure/hx-knowledge/docs/0.0.5.2.1-credentials.md` (🔴 MUST READ)
- **Standards:** `/home/agent0/HX-Infrastructure/standards/`
- **Templates:** `/home/agent0/HX-Infrastructure/templates/`

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 2.0 | 2025-11-22 | Complete rewrite for Core Team SME agents | Infrastructure Team |
| | | - Removed all non-existent agents from old inventory | |
| | | - Added 5 Core Team SME agents from x-agents directory | |
| | | - Updated all paths to /home/agent0/HX-Infrastructure/x-agents/ | |
| | | - Added comprehensive agent descriptions from actual profiles | |
| | | - Added correct knowledge requirements (4 core + domain) | |
| | | - Added agent coordination patterns | |
| | | - Added critical infrastructure and credentials reference | |
| 1.1 | 2025-11-21 | Agent reclassification from 45 to 32 agents | Infrastructure Team |
| | | - **Reclassified into two categories:** | |
| | | - Core Team SMEs (5): agent-zero, alex-rivera, frank-lucas, julia-santos, william-chen | |
| | | - Technology SMEs (27): See Technology SME Agents section (lines 491+) | |
| | | - Authoritative count: 32 total agents (5 Core + 27 Technology) | |
| | | - Updated all documentation to reflect correct agent count | |
| 1.0 | 2025-11-15 | Initial inventory with 45 agents (DEPRECATED) | Infrastructure Team |
| | | - Moved to /home/agent0/HX-Infrastructure/x-archive/ | |

---

**Document Type:** Infrastructure - Agent Management
**Classification:** Internal
**Status:** ✅ ACTIVE - Primary agent reference
**Maintained By:** Infrastructure Team
**Last Review:** November 22, 2025
**Next Review:** February 22, 2026 (Quarterly)

---

*This inventory serves as the authoritative reference for all Core Team SME agents in the HX-Infrastructure environment. These agents are project-agnostic and can be used across any HX-Infrastructure project. Consult this document when coordinating multi-agent workflows or determining agent responsibilities.*
