# Context Loading Process
## For Stateless Agents in HX-Infrastructure Projects

**Document Type:** Procedure - Agent Operations
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Production Ready
**Location:** `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md`

---

## Document Purpose

This procedure defines the systematic context loading process for stateless specialist agents participating in HX-Infrastructure projects. It ensures consistent knowledge baselines, quality contributions, and efficient context management across all project phases.

**Problem Statement:**
Sub-agents (Alex Rivera, Julia Chen, Frank Martinez, William Thompson, and other specialists) are STATELESS:
- No memory between invocations
- Cannot assume knowledge from previous interactions
- Must reload full context each time they contribute

**Solution:**
Systematic context loading checklists ensure:
- Consistent knowledge baseline across all agents
- Quality contributions informed by complete context
- Reduced errors from missing information
- Efficient context reload process
- Immediate action while context is fresh

**Related Documents:**
- `hx-agents/hx-agent-inventory.md` - 45 specialist agents and capabilities
- `hx-agents/hx-orchestration-guide.md` - Multi-agent coordination patterns
- `.claude/commands/agents/` - Agent orchestration commands (Set 5)
- `.claude/commands/utilities/cc-context-prep.md` - Context preparation utility
- `procedures/core-project-team.md` - Agent roles and responsibilities

**Target Audience:**
- Specialist agents (Alex, Frank, William, Julia, others)
- Agent Zero (for orchestrating context preparation)
- Infrastructure team members

---

## 📊 State Management Overview

### **Agent Zero (CC) - STATEFUL** ✅

```
✓ Maintains state throughout project lifecycle
✓ Remembers all previous work and decisions
✓ Does NOT need context reload
✓ Orchestrates all phases continuously

Participates in:
- Charter creation (creates and owns it)
- Specification development (orchestrates all contributions)
- Task breakdown (coordinates task generation)
- Deployment execution (orchestrates implementation)
- Testing coordination (manages quality assurance)
- Project closeout (finalizes documentation)
- All phases continuously with full context
```

**Agent Zero Role:**
- Primary orchestrator and systems integrator
- Maintains project state across all phases
- Prepares context for specialist agent invocations
- Coordinates multi-agent collaboration
- Synthesizes specialist contributions

### **All Other Agents - STATELESS** ⚠️

```
✗ NO memory between invocations
✗ Fresh start each contribution
✗ Context lost immediately after contribution
✓ MUST reload context EVERY time invoked

Participates in:
- Discrete review/contribution tasks
- Must reload before EACH task
- Immediate action required after context load
```

**Specialist Agent Examples:**
- **Alex Rivera** (Platform Architect) - Architecture decisions, ADRs
- **Frank Martinez** (Security Specialist) - Identity & Trust, Samba AD, Kerberos
- **William Thompson** (Infrastructure Specialist) - Bare metal deployment, systemd, manual procedures
- **Julia Chen** (Testing & Quality Specialist) - Test-driven deployment, 100% coverage
- **Laura Patel** (Langchain Specialist) - Agent framework integration
- **Marcus Johnson** (LightRAG Specialist) - RAG knowledge graph implementation
- **Amanda Rodriguez** (Ansible Automation) - Fleet-wide configuration management
- Others as documented in `hx-agents/hx-agent-inventory.md`

---

## 📋 Context Loading Checklists

### **CHARTER PHASE: Pre-Review Context Load**

**When:** Before agent reviews charter draft or provides charter feedback

**Time Estimate:** 20-30 minutes

**Orchestration:** Agent Zero uses `cc-context-prep.md` (Set 3) to prepare context package

**Checklist:**
```
□ 1. Read project kickoff information
     Location: Provided by Agent Zero in invocation
     Purpose: Understand project goals and scope
     Source: CAIO brain dump + Agent Zero parsing

□ 2. Read assigned knowledge vault repositories
     Location: /home/agent0/HX-Infrastructure/hx-knowledge/repos/[repo-name]
     Assignments: Provided by Agent Zero in context package
     Purpose: Deep understanding of relevant technologies
     Focus: Agent-specific repository assignments

□ 3. Review HX-Infrastructure standards documents
     Required Reading:
     - /home/agent0/HX-Infrastructure/constitution.md (project principles)
     - /home/agent0/HX-Infrastructure/standards/architecture-standards.md (architecture patterns)
     - /home/agent0/HX-Infrastructure/standards/deployment-requirements.md (infrastructure philosophy)
     - /home/agent0/HX-Infrastructure/standards/testing-requirements.md (quality standards)
     - /home/agent0/HX-Infrastructure/standards/naming-conventions.md (naming standards)

□ 4. Review infrastructure inventory and topology
     - /home/agent0/HX-Infrastructure/inventory/nodes.md (current infrastructure state)
     - /home/agent0/HX-Infrastructure/network/network-topology.md (network architecture)
     Purpose: Understand current infrastructure baseline

□ 5. Read charter draft (if reviewing charter)
     Location: /nodes/[node-name]/charter.md
     Status: DRAFT (review mode)
     Focus: Sections relevant to agent expertise

□ 6. Note agent role and responsibilities
     From: /home/agent0/HX-Infrastructure/procedures/core-project-team.md
     Reference: hx-agents/hx-agent-inventory.md (agent capabilities)
     Focus: Understand contribution expectations
```

**Infrastructure Philosophy Alignment (HX-Infrastructure):**
All agents MUST understand and apply:
- **Bare metal first:** Production/staging on Ubuntu 24 bare metal servers
- **Docker dev-only:** Containers allowed only on hx-dev-server (192.168.10.222)
- **Systemd service management:** All services managed via systemd
- **Manual procedures only:** No automation (no Ansible playbooks for procedures)
- **Ansible Vault only:** All credentials in Ansible Vault

**Output:** Agent ready to provide informed charter review with infrastructure philosophy compliance

---

### **SPECIFICATION PHASE: Pre-Contribution Context Load**

**When:** Before agent contributes to specification document

**Time Estimate:** 35-45 minutes for context load

**⚠️ CRITICAL:** After loading context, agent MUST immediately edit specification. Do NOT pause. Stateless agents lose context if there's a gap between loading and editing.

**Orchestration:** Agent Zero uses `cc-orchestrate-[agent].md` (Set 5) to coordinate specialist contribution

**Checklist:**
```
□ 1. Read approved charter
     Location: /nodes/[node-name]/charter.md
     Status: Must be APPROVED (not DRAFT)
     Focus: Vision, scope, success criteria, infrastructure philosophy
     Key Sections: All sections, especially infrastructure philosophy

□ 2. Re-read assigned knowledge vault repositories
     Location: /home/agent0/HX-Infrastructure/hx-knowledge/repos/[repo-name]
     Note: Same assignments from charter phase
     Focus: Technical details, implementation patterns, configuration examples
     Purpose: Refresh technical understanding for specification work

□ 3. Read RAIDD log
     Location: /home/agent0/HX-Infrastructure/raidd-log.md (centralized)
     Alternative: /nodes/[node-name]/raidd-log.md (project-specific)
     Focus: Risks, assumptions, issues, dependencies, decisions
     Note: Review project-specific entries relevant to agent expertise
     Action: Identify risks/assumptions affecting agent's contribution

□ 4. Read backlog
     Location: /home/agent0/HX-Infrastructure/backlog.md (centralized)
     Alternative: /nodes/[node-name]/backlog.md (project-specific)
     Focus: Deferred items, future enhancements, out-of-scope features
     Note: Understand what's OUT of scope to avoid scope creep

□ 5. Read defect log (if exists)
     Location: /home/agent0/HX-Infrastructure/defect-log.md
     Focus: Known issues, workarounds, blockers
     Note: May not exist in early phases

□ 6. Read knowledge vault research findings
     Location: /nodes/[node-name]/research/[date]-research-findings.md
     Alternative: Provided by Agent Zero in context package
     Focus: Agent Zero's technical research from charter phase
     Note: DON'T need to re-research, just read findings
     Purpose: Leverage Agent Zero's research work

□ 7. Read initial specification draft
     Location: /nodes/[node-name]/node-spec.md
     Status: DRAFT from Agent Zero (base specification)
     Focus: Sections relevant to agent's expertise
     Action: Identify sections needing agent contribution

□ 8. Read team assignments
     Location: /nodes/[node-name]/team-assignments.md
     Alternative: Provided by Agent Zero in context package
     Focus: Agent's responsibilities and section ownership
     Action: Understand contribution boundaries and dependencies

□ 9. Review current infrastructure state (if infrastructure-related)
     - Inventory: /home/agent0/HX-Infrastructure/inventory/nodes.md
     - Network: /home/agent0/HX-Infrastructure/network/network-topology.md
     Purpose: Ensure specification aligns with actual infrastructure
     Focus: IP allocations, security zones, existing services
```

**IMMEDIATELY AFTER COMPLETING CHECKLIST:**
```
⚠️ DO NOT PAUSE - Proceed immediately to editing specification while context is fresh!

□ 10. Open specification and begin editing
      Location: /nodes/[node-name]/node-spec.md
      Action: Edit assigned sections while context is active
      Mode: Direct editing, not planning or drafting

      REMEMBER: Stateless agents lose context if you wait!
      The editing must happen continuously with context loading as ONE process.

      If you pause to do something else, you WILL lose context and
      need to reload everything from scratch.
```

**Infrastructure Philosophy Application:**
During specification contribution, agents ensure:
- Bare metal deployment documented (IP, hostname, zone)
- Systemd service unit requirements specified
- Manual procedure outlines included
- Ansible Vault credential requirements identified
- Network topology integration documented

**Output:** Agent ready to contribute informed edits to specification + IMMEDIATE editing while context fresh

---

### **TASK PHASE: Pre-Task Review Context Load**

**When:** Before agent reviews task breakdown or task documentation

**Time Estimate:** 30-40 minutes

**Orchestration:** Agent Zero coordinates via task workflow

**Checklist:**
```
□ 1. Read approved charter
     Location: /nodes/[node-name]/charter.md
     Status: Must be APPROVED
     Focus: Quick refresh of vision and scope

□ 2. Read approved specification
     Location: /nodes/[node-name]/node-spec.md
     Status: Must be APPROVED
     Focus: Technical requirements relevant to tasks
     Action: Identify specification sections affecting agent's tasks

□ 3. Read task breakdown
     Location: /nodes/[node-name]/tasks/
     Focus: Tasks assigned to agent or related to agent expertise
     Action: Understand task dependencies and sequencing

□ 4. Read RAIDD log
     Location: /home/agent0/HX-Infrastructure/raidd-log.md
     Focus: Recent updates from specification phase
     Action: Review risks affecting task execution

□ 5. Read test suite
     Location: /nodes/[node-name]/tests/
     Focus: Tests related to agent's tasks
     Purpose: Understand test-driven deployment requirements
     Note: Tests written BEFORE implementation (Julia Chen's methodology)

□ 6. Review task assignments
     Location: /nodes/[node-name]/tasks/task-assignments.md
     Focus: Agent's assigned tasks and responsibilities
     Action: Understand task boundaries and acceptance criteria
```

**Output:** Agent ready to execute or review tasks with full context

---

### **DEPLOYMENT PHASE: Pre-Review Context Load**

**When:** Before agent reviews deployment plan or execution

**Time Estimate:** 40-50 minutes

**Orchestration:** Agent Zero coordinates via execution workflow

**Checklist:**
```
□ 1. Read approved charter
     Location: /nodes/[node-name]/charter.md
     Status: Must be APPROVED
     Focus: Vision, success criteria, constraints

□ 2. Read approved specification
     Location: /nodes/[node-name]/node-spec.md
     Status: Must be APPROVED
     Focus: Technical requirements, architecture, configuration

□ 3. Read task execution results
     Location: /nodes/[node-name]/task-results/
     Focus: Completed tasks, test results, issues encountered
     Action: Understand what has been implemented

□ 4. Read RAIDD log
     Location: /home/agent0/HX-Infrastructure/raidd-log.md
     Focus: Recent updates from task execution phase
     Action: Review deployment risks and decisions

□ 5. Read defect log
     Location: /home/agent0/HX-Infrastructure/defect-log.md
     Focus: Known issues affecting deployment
     Action: Identify blockers or workarounds needed

□ 6. Read deployment plan draft (if reviewing)
     Location: /nodes/[node-name]/deployment/plan.md
     Status: DRAFT from Agent Zero
     Focus: Sections relevant to agent's expertise

□ 7. Review deployment architecture
     Location: /nodes/[node-name]/deployment/deployment-architecture.md
     Focus: Architecture validation, infrastructure alignment
     Action: Verify deployment approach matches specification

□ 8. Review configuration specification
     Location: /nodes/[node-name]/deployment/configuration-spec.md
     Focus: Configuration requirements, systemd units, credentials
     Action: Validate configuration completeness

□ 9. Review test results
     Location: /nodes/[node-name]/tests/test-executions/
     Focus: Test execution outcomes, pass/fail status
     Action: Verify quality gates passed before deployment
```

**Infrastructure Deployment Validation:**
Agents validate deployment aligns with HX-Infrastructure philosophy:
- Bare metal target server identified with IP/hostname
- Systemd service unit created and validated
- Manual deployment procedure documented
- Ansible Vault credentials configured
- Network topology updated (if new server)

**Output:** Agent ready to provide informed deployment review

---

### **TESTING PHASE: Pre-Testing Context Load**

**When:** Before agent executes or reviews tests

**Time Estimate:** 30-40 minutes

**Orchestration:** Julia Chen (Testing Specialist) orchestrates test-driven deployment

**Checklist:**
```
□ 1. Read approved charter
     Location: /nodes/[node-name]/charter.md
     Focus: Success criteria, acceptance criteria
     Action: Understand what "done" means

□ 2. Read approved specification
     Location: /nodes/[node-name]/node-spec.md
     Focus: Requirements for 100% test coverage
     Action: Identify all testable requirements

□ 3. Read test suite
     Location: /nodes/[node-name]/tests/
     Focus: All test categories (deployment, functionality, integration, health)
     Action: Understand test coverage and execution order

□ 4. Read task execution results
     Location: /nodes/[node-name]/task-results/
     Focus: Implementation status, what has been deployed
     Action: Verify implementation complete before testing

□ 5. Read defect log
     Location: /home/agent0/HX-Infrastructure/defect-log.md
     Focus: Known issues, expected test failures
     Action: Understand test baseline and acceptable failures
```

**100% Requirements Coverage:**
Julia Chen ensures ALL requirements have corresponding tests:
- Deployment tests (bare metal provisioning, systemd service)
- Functionality tests (core features, use cases)
- Integration tests (dependencies, API contracts)
- Health check tests (monitoring, alerting)

**Output:** Agent ready to execute or validate test suite

---

## ⏱️ Time Management

### **Estimated Context Load Times by Phase:**

| Phase | Context Load Time | Reading Volume | Documents | Notes |
|-------|------------------|----------------|-----------|-------|
| Charter Review | 20-30 min | ~50-100 pages | 6-8 docs | Initial knowledge acquisition |
| Spec Contribution | 35-45 min | ~80-120 pages | 9-10 docs | Includes re-reading repos + immediate editing |
| Task Review | 30-40 min | ~60-90 pages | 6-7 docs | Focus on task-specific context |
| Deployment Review | 40-50 min | ~100-150 pages | 9-10 docs | Cumulative documentation review |
| Testing Phase | 30-40 min | ~60-100 pages | 5-6 docs | Focus on test artifacts and results |

**Time Variation Factors:**
- Agent familiarity with technology
- Project complexity
- Number of assigned repositories
- Documentation quality and clarity
- Agent's domain expertise match
- Phase of project (later phases = more cumulative documentation)

**Efficiency Guidelines:**
- First-time context load: Use full time estimate
- Follow-up within same phase: Context refresh only (10-15 min)
- After gap >1 week: Full context reload required
- New phase transition: Full context reload required

---

## 🎯 Context Loading Guidelines

### **Reading Strategy:**

**1. Prioritize Critical Documents**
```
CRITICAL (must read thoroughly):
- Charter (vision, scope, success criteria, infrastructure philosophy)
- RAIDD log (risks, assumptions, decisions affecting agent)
- Current work product (spec, tasks, deployment plan, etc.)
- HX-Infrastructure standards (architecture, deployment, testing)

IMPORTANT (focused reading):
- Knowledge vault repos (technical details, implementation patterns)
- Standards documents (compliance, patterns, conventions)
- Infrastructure inventory (current state, available resources)

REFERENCE (scan for relevant sections):
- Backlog (deferred items, understand out-of-scope)
- Defect log (known issues, workarounds)
- Team assignments (contribution boundaries)
```

**2. Focus on Agent Expertise**
```
Alex Rivera (Platform Architect):
- Architecture sections in all documents
- Integration patterns and multi-layer design
- ADR requirements
- System design decisions
- Agentic patterns

Frank Martinez (Security Specialist):
- Authentication/authorization sections
- Samba AD, Kerberos, LDAP requirements
- Certificate needs (hx-ca-server)
- Identity & Trust layer integration
- Credentials management (Ansible Vault)

William Thompson (Infrastructure Specialist):
- Bare metal deployment sections
- Systemd service requirements
- Manual procedure documentation
- Network configuration
- Infrastructure philosophy compliance

Julia Chen (Testing & Quality Specialist):
- Testing requirements across all documents
- Quality criteria and acceptance criteria
- 100% requirements coverage validation
- Defect management
- Test-driven deployment methodology
```

**3. Take Notes During Reading**
```
Document key points:
- Questions for Agent Zero
- Concerns or risks identified
- Missing information or gaps
- Conflicting requirements
- Infrastructure philosophy violations
- Integration dependencies
- Resource constraints
```

---

## 📝 Context Load Documentation

### **Agents document context load completion:**

**Location:** `/nodes/[node-name]/context-loads/[agent-name]-[phase]-[date].md`

**Template:**
```markdown
# Context Load: [Phase Name]

**Agent:** [agent-name] ([agent-role])
**Date:** [YYYY-MM-DD]
**Phase:** [Charter/Specification/Task/Deployment/Testing]
**Time Spent:** [XX] minutes

---

## Documents Reviewed

### Critical Documents
- [x] Approved charter (/nodes/[node-name]/charter.md)
- [x] HX-Infrastructure standards (architecture, deployment, testing)
- [x] Current work product ([specific document])
- [x] RAIDD log (project-specific entries)

### Technical Context
- [x] Assigned repos: [list with focus areas]
- [x] Knowledge research findings
- [x] Infrastructure inventory (nodes.md)
- [x] Network topology

### Project Artifacts
- [x] Backlog (out-of-scope understanding)
- [ ] Defect log (none exists yet / reviewed)
- [x] Team assignments (role clarity)

---

## Time Breakdown
- **Reading:** [XX] minutes
- **Note-taking:** [XX] minutes
- **Total:** [XX] minutes

---

## Key Observations

### Infrastructure Philosophy Compliance
1. [Observation about bare metal deployment]
2. [Observation about systemd service management]
3. [Observation about manual procedures]

### Technical Findings
1. [Technical observation from reading]
2. [Integration concern or opportunity]
3. [Architecture alignment note]

### Risks and Concerns
1. [Risk identified during context review]
2. [Concern requiring clarification]

---

## Questions for Agent Zero

1. **[Question Category]:** [Specific question]
2. **[Question Category]:** [Specific question]
3. **[Question Category]:** [Specific question]

---

## Agent-Specific Focus Areas

**My Expertise:** [agent-role]

**Contribution Sections:**
- [Section 1 of work product agent will contribute to]
- [Section 2 of work product agent will contribute to]

**Dependencies:**
- [Other agent contributions needed first]
- [Infrastructure prerequisites]

---

## Ready to Contribute

✓ Context loaded successfully
✓ Infrastructure philosophy understood and will be applied
✓ Technical understanding sufficient for contribution
✓ Questions documented for Agent Zero
✓ Ready to contribute to [phase] immediately

**Next Action:** [Specific next step - e.g., "Edit specification sections 3.2, 4.1, 5.3"]
```

**Purpose of Documentation:**
- Demonstrates systematic context loading
- Captures agent observations and questions
- Provides audit trail of agent preparation
- Helps Agent Zero identify gaps or issues
- Supports continuous process improvement

---

## 🚨 Red Flags During Context Load

**Stop and notify Agent Zero immediately if:**

### **CRITICAL ISSUES (Blocking):**
```
□ Charter not approved (cannot proceed to specification)
□ Specification not approved (cannot proceed to tasks)
□ Major conflicts in requirements (contradictory statements)
□ Missing critical information (gaps in charter/spec)
□ Undefined infrastructure dependencies (unknown prerequisites)
□ P0/P1 defects blocking progress (critical/high severity)
□ Infrastructure philosophy violations (bare metal/systemd/manual procedures)
```

### **CLARIFICATION NEEDED (Non-Blocking):**
```
□ Ambiguous requirements (multiple interpretations possible)
□ Contradictory statements (conflicts between documents)
□ Unclear scope boundaries (in-scope vs. out-of-scope)
□ Missing architecture details (integration patterns undefined)
□ Insufficient technical detail (implementation approach unclear)
□ Infrastructure philosophy not explicit (assumptions about deployment)
```

### **PROCESS ISSUES (Workflow):**
```
□ Required documents missing (expected artifacts not found)
□ Documents not at expected status (DRAFT when APPROVED expected)
□ Team assignments unclear (role boundaries ambiguous)
□ Knowledge repository access issues (repos not available)
□ Agent assignments conflicting (overlapping responsibilities)
```

**Action When Red Flag Identified:**
1. Document the issue clearly in context load documentation
2. Tag Agent Zero for immediate attention
3. Do NOT proceed with contribution until resolved
4. Wait for Agent Zero resolution before continuing

---

## ✅ Context Load Validation

**Agent confirms readiness by checking all criteria:**

### **Comprehension Validation:**
```
□ I understand project vision and goals
□ I understand project scope (in-scope and out-of-scope)
□ I understand my role and specific responsibilities
□ I understand HX-Infrastructure philosophy and will apply it
□ I understand current risks and assumptions affecting my work
```

### **Technical Validation:**
```
□ I have reviewed all assigned knowledge vault repositories
□ I have sufficient technical understanding to contribute
□ I understand integration points and dependencies
□ I understand infrastructure constraints (bare metal, systemd, etc.)
□ I know where to find additional technical reference if needed
```

### **Work Product Validation:**
```
□ I have read the current work product I'm contributing to
□ I have identified my contribution areas/sections
□ I understand what other agents have contributed (dependencies)
□ I know quality expectations for my contribution
□ I understand acceptance criteria
```

### **Readiness Validation:**
```
□ I have questions documented (if any) for Agent Zero
□ I am ready to provide informed contribution immediately
□ I will apply infrastructure philosophy throughout contribution
□ I understand I must act immediately (no pause - context loss)
```

**If ANY box unchecked:**
- Continue context loading until all criteria met
- Ask Agent Zero for clarification
- Do NOT proceed with contribution until fully ready

---

## 🔄 Context Refresh vs Full Load

### **Full Context Load Required:**
- **First contribution to a project** (no prior context)
- **After significant time gap** (>1 week since last contribution)
- **When entering new phase** (charter → spec → task → deployment → testing)
- **After major project changes** (charter amendments, spec revisions)
- **When infrastructure philosophy updated** (deployment approach changes)

**Time Required:** 20-50 minutes (depending on phase)

### **Context Refresh Sufficient:**
- **Quick follow-up within same phase** (<1 week since last contribution)
- **Addressing specific feedback** (Agent Zero requests revision)
- **Minor revisions to previous contribution** (small edits, clarifications)
- **No phase transition** (still in same workflow phase)

**Context Refresh Checklist:**
```
□ Re-read RAIDD log (new entries only since last contribution)
□ Re-read updated work product (changes since last review)
□ Review Agent Zero's feedback (specific requests)
□ Review other agents' contributions (if dependencies changed)
□ Quick check: Any infrastructure philosophy changes?

Time: 10-15 minutes
```

**When in Doubt:** Perform full context load. Better to over-prepare than contribute with stale context.

---

## 📊 Efficiency Tips

### **1. Structured Reading Approach:**
```
First Pass (10 min): Skim all documents, note structure and key sections
  - Get overview of project state
  - Identify sections relevant to agent expertise
  - Note missing information

Second Pass (20 min): Deep read critical sections
  - Charter vision, scope, success criteria
  - Technical requirements related to agent role
  - Infrastructure philosophy sections
  - RAIDD entries affecting agent contributions

Third Pass (10 min): Note-taking and question formulation
  - Document key observations
  - Formulate questions for Agent Zero
  - Identify contribution areas
  - Validate readiness criteria
```

### **2. Agent-Specific Reading Focus:**
```
Focus reading on sections relevant to expertise:

Architecture Agent (Alex):
  - Skip: Detailed testing procedures, OS configuration minutiae
  - Focus: Architecture sections, integration patterns, ADR requirements

Testing Agent (Julia):
  - Skip: Low-level OS configuration, network routing details
  - Focus: Requirements for testing, acceptance criteria, quality gates

Security Agent (Frank):
  - Skip: Application logic details, UI/UX considerations
  - Focus: Authentication, authorization, Samba AD, Kerberos, certificates

Infrastructure Agent (William):
  - Skip: Application architecture abstractions, business logic
  - Focus: Bare metal deployment, systemd services, manual procedures, network
```

### **3. Leverage Previous Work:**
```
If agent contributed in previous phase:
  - Review own previous contributions first (5 min)
  - Check what changed since last contribution (5 min)
  - Focus new reading on updated sections (10 min)
  - Total time savings: ~10-15 minutes
```

### **4. Use Agent Zero's Context Package:**
```
Agent Zero prepares context packages via cc-context-prep.md:
  - Pre-selected documents relevant to agent
  - Key sections highlighted
  - Specific questions to investigate
  - Reduces reading volume by 20-30%
```

---

## 🎯 Success Criteria

**Context loading is successful when:**

1. ✅ **Comprehension:** Agent understands project goals, scope, and vision
2. ✅ **Technical Knowledge:** Agent has technical knowledge needed to contribute
3. ✅ **Risk Awareness:** Agent knows current risks, assumptions, and decisions
4. ✅ **Scope Clarity:** Agent understands what's in/out of scope
5. ✅ **Documentation Review:** Agent has read all required documents
6. ✅ **Infrastructure Philosophy:** Agent understands and will apply HX-Infrastructure standards
7. ✅ **Quality Readiness:** Agent ready to provide high-quality contribution
8. ✅ **Documentation:** Agent documented context load completion
9. ✅ **Blockers Identified:** Agent identified any blockers or questions
10. ✅ **Immediate Action:** Agent ready to act immediately (no pause)

**Failure Indicators:**
- Agent asks basic questions already answered in documents
- Agent violates infrastructure philosophy (e.g., suggests automation instead of manual procedures)
- Agent contributions conflict with charter scope
- Agent unaware of critical risks or decisions
- Agent suggests deferred items from backlog

---

## 🔗 Integration with Command Infrastructure

### **Context Preparation Commands:**

1. **cc-context-prep.md** (Set 3 - Utilities)
   - Agent Zero uses this to prepare context packages
   - Gathers relevant documents for specialist
   - Highlights key sections and questions

2. **cc-orchestrate-[agent].md** (Set 5 - Agent Orchestration)
   - Orchestration commands include context preparation steps
   - Defines what context specialist needs
   - Provides handoff protocols with context

3. **cc-handoff.md** (Set 3 - Utilities)
   - Structured handoff includes context package
   - Ensures specialist has everything needed
   - Tracks context handoff completion

### **Workflow Integration:**

Context loading is integrated into all workflow phases:
- **Charter Workflow:** Context load before charter review
- **Spec Workflow:** Context load before specification contribution
- **Task Workflow:** Context load before task execution/review
- **Execution Workflow:** Context load before deployment review
- **Closeout Workflow:** Context load before final validation

---

## 📚 Related Documentation

### **HX-Infrastructure Core:**
- `constitution.md` - Project principles and philosophy
- `README.md` - Repository overview
- `action-plan-v2-updated.md` - Project roadmap

### **Standards:**
- `standards/architecture-standards.md` - Architecture patterns (always reviewed)
- `standards/deployment-requirements.md` - Infrastructure philosophy (always reviewed)
- `standards/testing-requirements.md` - Quality standards (always reviewed)
- `standards/naming-conventions.md` - Naming standards
- `standards/documentation-requirements.md` - Documentation format

### **Infrastructure State:**
- `inventory/nodes.md` - Current infrastructure baseline
- `network/network-topology.md` - Network architecture

### **Agent Documentation:**
- `hx-agents/hx-agent-inventory.md` - 45 specialist agents and capabilities
- `hx-agents/hx-orchestration-guide.md` - Multi-agent coordination patterns
- `.claude/commands/agents/` - Agent orchestration commands (Set 5)

### **Workflow Procedures:**
- `procedures/charter-workflow.md` - Charter creation process
- `procedures/spec-workflow.md` - Specification development process
- `procedures/task-workflow.md` - Task breakdown and execution
- `procedures/task-execution-workflow.md` - Implementation workflow
- `procedures/project-closeout-workflow.md` - Project closeout process

### **Team Documentation:**
- `procedures/core-project-team.md` - Agent roles and responsibilities

---

## Document Maintenance

**Update Triggers:**
- New agent types added to ecosystem
- New project phases introduced
- Infrastructure philosophy changes
- Context loading process improvements discovered
- New document types added to project artifacts

**Version History:**

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-16 | Initial context loading process documentation | Infrastructure Team |
| 1.1 | 2025-11-21 | HX-Infrastructure standards integration, infrastructure philosophy emphasis, command infrastructure integration, expanded checklists for all phases | HX-Infrastructure Team |

---

**Document Information:**
- **Version:** 1.1
- **Status:** APPROVED - Production Ready
- **Maintained By:** HX-Infrastructure Team
- **Review Frequency:** After each multi-agent project (continuous improvement)
- **Last Review:** 2025-11-21
- **Next Review:** After next multi-agent project completion

---

*This context loading procedure ensures stateless specialist agents receive comprehensive, systematic context before each contribution. It prevents knowledge gaps, reduces errors, and ensures consistent application of HX-Infrastructure standards across all agent contributions.*
