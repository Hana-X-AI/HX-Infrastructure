# Claude Code Commands - Agent Orchestration Commands (Set 5)

**Purpose:** Multi-agent coordination and specialist orchestration patterns for Agent Zero and specialist agents
**Pattern:** Workflow commands with phase-based orchestration
**Version:** Mixed (v1.0-v2.0 depending on command)
**Status:** ✅ COMPLETE - 5 agent orchestration commands

## Overview

This directory contains orchestration commands that define how Agent Zero (Chief AI Officer) coordinates work with specialist agents across the HX-Infrastructure ecosystem. Each command provides systematic patterns for context preparation, handoffs, quality validation, and integration of specialist expertise.

## Commands in This Set

### ✅ Command 1: Agent Zero Synthesis (Meta-Orchestration)
**File:** cc-agent-zero-synthesis.md
**Version:** 1.1
**Size:** 1,567 lines (92.85 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Agent:** Agent Zero (Chief AI Officer)
**Purpose:** Multi-agent coordination synthesis patterns for orchestrating complex work requiring multiple specialist agents simultaneously or sequentially
**Domains Coordinated:** Architecture (Alex), Security (Frank), Infrastructure (William), Testing (Julia)

**Key Features:**
- 7-phase meta-orchestration workflow
- Multi-agent coordination strategies (sequential vs. parallel)
- Cross-domain synthesis and conflict resolution
- Context flow management across agents
- Multi-agent output integration
- Coordination pattern documentation and learning

**When to Use:**
- Tasks requiring expertise from multiple domains (architecture + security + infrastructure + testing)
- When specialist outputs must be integrated and synthesized
- When conflicts between specialist recommendations need resolution
- When cross-domain dependencies require multi-agent coordination

---

### ✅ Command 2: Alex Orchestration (Platform Architect)
**File:** cc-orchestrate-alex.md
**Version:** 1.0
**Size:** 1,216 lines (45.30 KB)
**Status:** ✅ APPROVED - Ready for use
**Agent:** Alex Rivera (Platform Architect)
**Purpose:** Orchestration patterns for coordinating development and architecture work with Alex
**Specialty:** Architecture decisions, multi-layer changes, ADRs, platform evolution, agentic patterns

**Key Features:**
- Decision criteria for when to invoke Alex
- Context preparation for architectural decisions
- Structured handoff protocols
- ADR creation and validation workflows
- Multi-layer change coordination
- Architecture documentation integration

**When to Invoke Alex:**
- Changes affecting 2+ architecture layers
- New services/components being added to platform
- Security zone boundaries involved
- Multi-agent coordination required
- Architectural patterns unclear
- Network topology changes
- ADR creation needed

---

### ✅ Command 3: Frank Orchestration (Security Specialist)
**File:** cc-orchestrate-frank.md
**Version:** 1.0
**Size:** 1,323 lines (50.25 KB)
**Status:** ✅ APPROVED - Ready for use
**Agent:** Frank Martinez (Security Specialist)
**Purpose:** Orchestration patterns for coordinating security, identity, and trust infrastructure work with Frank
**Specialty:** Identity & Trust layer, Samba AD, authentication/authorization, security architecture, credentials management

**Key Features:**
- Security decision criteria and invocation triggers
- Identity & Trust layer coordination
- Samba AD integration patterns
- Credentials and secrets management (Ansible Vault)
- Security zone validation
- Authentication/authorization workflows

**When to Invoke Frank:**
- Identity & Trust layer changes (Samba AD, authentication, authorization)
- Security architecture decisions
- Credentials management (Ansible Vault)
- Security zone boundary changes
- Authentication mechanism changes
- Access control implementations

---

### ✅ Command 4: Julia Orchestration (Testing & Quality Specialist)
**File:** cc-orchestrate-julia.md
**Version:** 1.0
**Size:** 1,527 lines (95.63 KB)
**Status:** ✅ APPROVED - Ready for use
**Agent:** Julia Chen (Testing & Quality Specialist)
**Purpose:** Orchestration patterns for coordinating testing, quality assurance, and validation work with Julia
**Specialty:** Test-driven deployment, 100% requirements coverage, defect management, quality gates

**Key Features:**
- Testing strategy coordination
- Test-driven deployment workflows
- 100% requirements coverage validation
- Defect lifecycle management
- Quality gate enforcement
- Testing documentation and metrics

**When to Invoke Julia:**
- Test suite generation (100% coverage requirement)
- Test-driven deployment planning
- Quality gate validation
- Defect management and resolution
- Testing strategy development
- Requirements coverage verification

---

### ✅ Command 5: William Orchestration (Infrastructure Specialist)
**File:** cc-orchestrate-william.md
**Version:** 2.0
**Size:** 1,069 lines (53.30 KB)
**Status:** ✅ APPROVED - Production Ready v2.0
**Agent:** William Thompson (Infrastructure Specialist)
**Purpose:** Orchestration patterns for coordinating operational infrastructure work with William
**Specialty:** Bare metal deployment, systemd services, manual procedures, network configuration, server provisioning

**Key Features:**
- Infrastructure decision criteria
- Bare metal deployment coordination
- Systemd service management patterns
- Manual procedure documentation workflows
- Network configuration validation
- Server provisioning coordination

**When to Invoke William:**
- Bare metal server deployment (production/staging)
- Systemd service unit creation/modification
- Network configuration changes
- Manual procedure documentation
- Server provisioning and configuration
- Infrastructure troubleshooting

**Infrastructure Philosophy (v2.0):**
- Bare metal first for production/staging (Ubuntu 24)
- Docker dev-only on hx-dev-server (192.168.10.222)
- Ansible Vault only for credentials
- Manual procedures (no automation/Ansible playbooks)
- Systemd service management required

---

## Set 5 Progress

**Completed:** 5 of 5 (100%) ✅
**Version Status:** Mixed (1 at v1.1, 1 at v2.0, 3 at v1.0)
**Total Lines:** 6,702 lines across 5 commands
**Total Size:** 337.33 KB
**Command Types:** 1 meta-orchestration + 4 specialist orchestrations

## Orchestration Architecture

### Agent Hierarchy

```text
Agent Zero (Chief AI Officer)
├── Meta-Orchestration: cc-agent-zero-synthesis.md
└── Specialist Orchestrations:
    ├── Alex Rivera (Platform Architect) - cc-orchestrate-alex.md
    ├── Frank Martinez (Security Specialist) - cc-orchestrate-frank.md
    ├── Julia Chen (Testing & Quality Specialist) - cc-orchestrate-julia.md
    └── William Thompson (Infrastructure Specialist) - cc-orchestrate-william.md
```

### Orchestration Patterns

**Single-Agent Coordination:**
When task requires expertise from one specialist domain:
- Agent0 → Context Prep → Alex (architecture only)
- Agent0 → Context Prep → Frank (security only)
- Agent0 → Context Prep → Julia (testing only)
- Agent0 → Context Prep → William (infrastructure only)

**Multi-Agent Coordination (Sequential):**
When task requires multiple domains with dependencies:
- Agent0 → Alex (architecture) → Frank (security) → William (infrastructure) → Julia (testing)
- Example: New service deployment (architecture first, then security, then infrastructure, then testing)

**Multi-Agent Coordination (Parallel):**
When task requires multiple domains without hard dependencies:
- Agent0 → (Alex + Frank + William) → Synthesis → Julia (final validation)
- Example: Platform-wide security audit (architecture, security, infrastructure assessed concurrently)

**Multi-Agent Synthesis:**
When outputs from multiple specialists must be integrated:
- Agent0 → Multiple Specialists → Agent Zero Synthesis → Unified Deliverable
- Example: Platform evolution planning (architecture + security + infrastructure + testing guidance synthesized)

---

## Common Orchestration Workflows

### Workflow 1: New Service Deployment
**Agents Involved:** Alex → William → Julia (sequential)
1. **Alex (Architecture):** Service design, layer placement, integration patterns
2. **William (Infrastructure):** Bare metal provisioning, systemd service, network config
3. **Julia (Testing):** Test suite generation, 100% coverage validation, quality gates

### Workflow 2: Security Architecture Change
**Agents Involved:** Alex + Frank (parallel) → Synthesis
1. **Alex (Architecture):** Architecture layer implications, ADR creation
2. **Frank (Security):** Security controls, authentication mechanisms, credentials
3. **Agent Zero:** Synthesize architecture + security recommendations

### Workflow 3: Platform Evolution Planning
**Agents Involved:** Alex + Frank + William + Julia (parallel) → Synthesis
1. **Alex:** Architecture evolution roadmap
2. **Frank:** Security implications and requirements
3. **William:** Infrastructure capacity and constraints
4. **Julia:** Testing strategy and quality gates
5. **Agent Zero:** Synthesize all specialist inputs into unified platform evolution plan

### Workflow 4: Complex Multi-Layer Change
**Agents Involved:** Alex → Frank → William → Julia (sequential with synthesis)
1. **Alex:** Architecture design across layers
2. **Frank:** Security validation and enhancements
3. **William:** Infrastructure implementation
4. **Julia:** Comprehensive testing
5. **Agent Zero:** Continuous synthesis and coordination

---

## Command Structure

All orchestration commands follow a consistent structure:

### Standard Sections
1. **Metadata:** Command identification, version, status, agent information
2. **Objective:** Purpose, achievements, when to use, when not to use
3. **Workflow Overview:** High-level flow, duration, participants, outputs
4. **Phases:** Detailed phase-by-phase orchestration guidance
5. **Decision Gates:** Criteria for proceeding or escalating
6. **Context Preparation:** What information the specialist needs
7. **Handoff Protocols:** How to effectively invoke the specialist
8. **Output Validation:** Quality checks for specialist deliverables
9. **Integration Patterns:** How to incorporate specialist guidance
10. **Escalation Paths:** When and how to escalate issues

### Phase Pattern
Each orchestration command uses a phase-based structure:
- **Phase 0:** Decision Point (Do we need this specialist?)
- **Phase 1:** Context Preparation (Gather necessary information)
- **Phase 2:** Handoff & Invocation (Invoke specialist with context)
- **Phase 3:** Monitoring (Track specialist progress)
- **Phase 4:** Output Validation (Quality check deliverables)
- **Phase 5:** Integration (Incorporate into broader work)
- **Phase 6:** Follow-up (Documentation, learning, next steps)

---

## Specialist Agent Capabilities

### Alex Rivera (Platform Architect)
**Core Capabilities:**
- Architecture Decision Records (ADRs)
- Multi-layer architecture design
- Service integration patterns
- Agentic design patterns
- Network topology planning
- Cross-service coordination
- Platform evolution strategy

**Output Types:**
- ADR documents
- Architecture diagrams
- Integration specifications
- Design patterns documentation
- Platform roadmaps

---

### Frank Martinez (Security Specialist)
**Core Capabilities:**
- Identity & Trust layer (Samba AD)
- Authentication mechanisms (Kerberos, LDAP)
- Authorization frameworks (RBAC, ACLs)
- Credentials management (Ansible Vault)
- Security zone architecture
- Access control implementations
- Security compliance validation

**Output Types:**
- Security architecture designs
- Samba AD configurations
- Authentication specifications
- Authorization models
- Security compliance reports
- Credentials management procedures

---

### Julia Chen (Testing & Quality Specialist)
**Core Capabilities:**
- Test-driven deployment methodology
- 100% requirements coverage
- Test suite generation (8 categories)
- Defect lifecycle management
- Quality gate enforcement
- Testing metrics and reporting
- Verification and validation

**Output Types:**
- Comprehensive test suites
- Test execution results
- Defect reports and resolutions
- Quality metrics dashboards
- Coverage analysis
- Testing documentation

---

### William Thompson (Infrastructure Specialist)
**Core Capabilities:**
- Bare metal server deployment
- Systemd service management
- Network configuration (VLANs, routing, DNS)
- Manual procedure documentation
- Server provisioning
- Infrastructure troubleshooting
- Performance optimization

**Output Types:**
- Systemd service units
- Network configurations
- Deployment procedures
- Infrastructure diagrams
- Troubleshooting guides
- Performance reports

---

## Decision Criteria Summary

### When to Use Single-Agent Orchestration
- Task confined to one specialist domain
- No cross-domain dependencies
- Clear domain boundaries
- Specialist expertise sufficient alone
- Integration complexity low

### When to Use Multi-Agent Orchestration (Sequential)
- Task spans multiple domains with dependencies
- Outputs from one specialist inform next specialist
- Clear ordering of specialist involvement
- Example: Architecture → Security → Infrastructure → Testing

### When to Use Multi-Agent Orchestration (Parallel)
- Task spans multiple domains without hard dependencies
- Specialists can work concurrently
- Synthesis phase needed to integrate outputs
- Time-sensitive requiring parallel work
- Example: Security audit across architecture + infrastructure + testing

### When to Use Agent Zero Synthesis
- Multiple specialist outputs need integration
- Conflicts between specialist recommendations
- Cross-domain trade-offs require resolution
- Unified deliverable from diverse inputs
- Complex coordination requiring meta-orchestration

---

## Integration with Other Command Sets

### Set 1: Workflows
Agent orchestration commands are **invoked by** workflow commands when specialist expertise is needed:
- Charter Workflow → May invoke Alex (architecture), Frank (security)
- Spec Workflow → May invoke Alex (design), Julia (testing strategy)
- Task Workflow → May invoke William (infrastructure), Julia (testing)
- Execution Workflow → May invoke William (deployment), Julia (validation)
- Closeout Workflow → May invoke all specialists for final validation

### Set 3: Utilities
Orchestration commands **invoke** utility commands for supporting tasks:
- artifact-tracker: Track specialist deliverables
- doc-lint: Validate specialist documentation
- status-report: Report on specialist work progress
- raidd: Update risks, assumptions, issues, decisions from specialists

### Set 4: Phase Commands
Specialist agents **execute** phase commands as needed:
- charter-questions: Julia may use for testing requirements questions
- test-suite-generation: Julia executes for test suite creation
- defect-mgmt: Julia manages defects through lifecycle
- task-result-doc: All specialists document results

---

## Quality Standards

**All orchestration commands ensure:**
- Clear invocation criteria (when to involve specialist)
- Comprehensive context preparation (what specialist needs)
- Structured handoff protocols (how to invoke effectively)
- Output validation (quality checks on deliverables)
- Integration patterns (how to use specialist guidance)
- Documentation and learning (capturing coordination patterns)

**Orchestration Quality Gates:**
- ✅ Specialist invocation justified with clear rationale
- ✅ Context complete before specialist handoff
- ✅ Specialist outputs validated for quality and correctness
- ✅ Integration of specialist guidance documented
- ✅ Coordination patterns captured for future reference

---

## Usage Examples

### Example 1: Single-Agent Orchestration (Alex)
```text
Task: Design integration pattern for new RAG service

Decision: Invoke Alex (architecture only)
- Architecture decision needed
- Single domain (architecture)
- No security/infrastructure/testing dependencies yet

Orchestration:
1. Use cc-orchestrate-alex.md
2. Prepare context (service requirements, existing architecture)
3. Invoke Alex for integration pattern design
4. Validate ADR and design
5. Integrate into service charter
```

### Example 2: Multi-Agent Sequential (Alex → Frank → William)
```text
Task: Deploy Samba AD server for Identity & Trust layer

Decision: Sequential multi-agent coordination
- Architecture design needed (Alex)
- Security configuration needed (Frank)
- Infrastructure deployment needed (William)
- Dependencies: Architecture → Security → Infrastructure

Orchestration:
1. Alex: Architecture design (where Samba AD fits, integration patterns)
2. Frank: Security configuration (Kerberos, LDAP, trust relationships)
3. William: Infrastructure deployment (bare metal, systemd, network)
4. Agent Zero: Synthesize and coordinate handoffs
```

### Example 3: Multi-Agent Parallel (Alex + Frank + William + Julia)
```text
Task: Plan platform-wide observability enhancement

Decision: Parallel multi-agent with synthesis
- Architecture implications (Alex)
- Security considerations (Frank)
- Infrastructure requirements (William)
- Testing strategy (Julia)
- All can work concurrently, synthesis needed

Orchestration:
1. Use cc-agent-zero-synthesis.md (meta-orchestration)
2. Invoke Alex + Frank + William + Julia in parallel
3. Collect diverse specialist outputs
4. Agent Zero synthesizes into unified observability plan
5. Resolve any conflicts or contradictions
6. Document integrated approach
```

---

## Best Practices

### Context Preparation
- ✅ Gather all relevant information before invoking specialist
- ✅ Provide clear task description and success criteria
- ✅ Include constraints, dependencies, and assumptions
- ✅ Reference related documentation and previous decisions
- ❌ Don't invoke specialist without adequate context

### Specialist Handoffs
- ✅ Use structured handoff protocol from orchestration command
- ✅ Clearly state what you need from specialist
- ✅ Specify deliverable formats and quality expectations
- ✅ Provide timeline and priority information
- ❌ Don't assume specialist has implicit context

### Output Validation
- ✅ Validate specialist outputs against quality criteria
- ✅ Check for completeness, correctness, consistency
- ✅ Ensure specialist guidance is actionable
- ✅ Request clarification if outputs unclear
- ❌ Don't blindly accept specialist outputs without validation

### Integration
- ✅ Systematically integrate specialist guidance into work
- ✅ Document how specialist input was used
- ✅ Track specialist recommendations in project artifacts
- ✅ Update related documentation with specialist insights
- ❌ Don't let specialist guidance go unused or undocumented

### Learning
- ✅ Document coordination patterns that worked well
- ✅ Capture multi-agent synthesis approaches
- ✅ Note conflict resolution strategies
- ✅ Update orchestration commands with learnings
- ❌ Don't repeat coordination mistakes

---

## Version History

### Agent Zero Synthesis (v1.1)
- **v1.1 (2025-11-20):** Infrastructure philosophy integration
  - Added bare metal first principle
  - Added Docker dev-only exception
  - Added Ansible Vault only credentials
  - Added manual procedures requirement
  - Added systemd service management requirement

### William Orchestration (v2.0)
- **v2.0:** Infrastructure philosophy explicit integration
  - Bare metal deployment patterns
  - Systemd service management requirements
  - Manual procedure documentation requirements
  - Ansible Vault credentials management
  - Docker dev-only exception handling

### Other Commands (v1.0)
- Alex, Frank, Julia orchestration commands at v1.0 (initial release)

---

## Future Enhancements

**Planned Improvements:**
1. **Orchestration Metrics:** Track specialist utilization, coordination patterns, integration success
2. **Conflict Resolution Patterns:** Document common specialist disagreements and resolution approaches
3. **Context Templates:** Standardized context preparation templates per specialist
4. **Output Templates:** Standardized deliverable formats from each specialist
5. **Orchestration Playbooks:** Common coordination scenarios with proven patterns

**Potential New Commands:**
- Additional specialist orchestration commands as ecosystem grows
- Domain-specific synthesis commands (e.g., security+architecture synthesis)
- Orchestration troubleshooting and escalation commands

---

**Last Updated:** 2025-11-21
**Maintainer:** HX-Infrastructure Team
**Status:** ✅ PRODUCTION READY
**Total Commands:** 5 orchestration commands (1 meta + 4 specialist)
**Coverage:** Complete specialist ecosystem orchestration
