# Claude Code Commands - Core Workflow Commands (Set 1)

**Purpose:** End-to-end workflow orchestration from project inception through operational deployment
**Pattern:** Phase-based workflows with quality gates and multi-agent coordination
**Version:** Mixed (v1.0-v1.3 depending on workflow maturity)
**Status:** ✅ COMPLETE - All 5 core workflows production ready

## Overview

This directory contains the core workflow commands that orchestrate complete project lifecycles in the HX-Infrastructure ecosystem. Each workflow guides Claude Code (Agent Zero) through systematic, phase-based processes from initial concept through operational deployment and project closure.

**Key Principle:** Workflows provide comprehensive end-to-end orchestration, while phase commands (Set 4) extract specific operations for focused execution.

---

## The Complete Project Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    HX-Infrastructure Project Lifecycle           │
└─────────────────────────────────────────────────────────────────┘

Phase 1: CHARTER (cc-charter-workflow.md)
├── Natural input from CAIO
├── Repository identification & research
├── Initial & post-research questions
├── Charter generation & approval
└── Output: Approved charter.md
         ↓
Phase 2: SPECIFICATION (cc-spec-workflow.md)
├── Charter review & context loading
├── Design development (architecture, security, infrastructure)
├── Requirements documentation
├── Testing strategy definition
└── Output: Approved spec.md
         ↓
Phase 3: TASK BREAKDOWN (cc-task-workflow.md)
├── Spec analysis & task decomposition
├── Test suite generation (100% coverage)
├── Deployment planning
├── Task prioritization & sequencing
└── Output: Task files + comprehensive test suite
         ↓
Phase 4: EXECUTION (cc-task-execution-workflow.md)
├── Task execution with test-driven deployment
├── Continuous testing & validation
├── Defect management & resolution
├── Result documentation & operational handoff
└── Output: Deployed service + execution results
         ↓
Phase 5: CLOSEOUT (cc-project-closeout-workflow.md)
├── Final validation & verification
├── Knowledge capture & documentation
├── Artifact inventory & archival
├── Operational handoff & closure
└── Output: Closed project + lessons learned

         ↓
    OPERATIONAL STATUS
```

---

## Commands in This Set

### ✅ Workflow 1: Charter Creation
**File:** cc-charter-workflow.md
**Version:** 1.2 (with CAIO refinements)
**Size:** 799 lines (25.28 KB)
**Status:** ✅ APPROVED - Production Ready v1.2
**Purpose:** Transform unstructured CAIO input into comprehensive, approved project charter through knowledge-first approach

**Phases:** 8 phases
1. Natural Input from CAIO (5-15 min)
2. CC Acknowledges & Parses (10-15 min)
3. Repository Confirmation Gate (5-10 min)
4. Initial Clarifying Questions (15-20 min)
5. Knowledge Vault Deep Dive (30-45 min per repo)
6. Post-Research Questions (NEW v1.2) (10-15 min)
7. Charter Generation & Review Loop (20-30 min)
8. Charter Approval & Post-Approval Actions (10-15 min)

**Duration:** 2-4 hours (depends on research depth)
**Output:** Approved `charter.md` in `/nodes/{node-name}/`

**Key Features:**
- Two-round question pattern (pre-research and post-research)
- Knowledge-first approach with repository research
- Multi-tier research (Primary 30-45min, Integration 15-30min, Supporting 10-15min)
- CAIO-driven iterative refinement
- Post-approval RAIDD logging and backlog updates

**Phase Commands Invoked:**
- **Phase 4:** cc-phase-charter-questions.md (initial questions)
- **Phase 5:** cc-phase-knowledge-research.md (repository research)
- **Phase 6:** cc-phase-charter-questions.md (post-research questions)

**Quality Gates:**
- Repository Confirmation Gate (Phase 3)
- Charter Approval Gate (Phase 8)

**When to Use:**
- Starting any new node deployment in HX-Infrastructure
- Defining scope and requirements for new service
- Establishing foundation before specification development

**v1.2 Key Innovation:** Post-research questions ensure informed technical decisions after knowledge discovery

---

### ✅ Workflow 2: Specification Development
**File:** cc-spec-workflow.md
**Version:** 1.3 (team-based multi-agent specification)
**Size:** 1,229 lines (48.09 KB)
**Status:** ✅ APPROVED - Production Ready v1.3
**Purpose:** Team-based specification development with multi-agent contributions from architecture, security, infrastructure, and testing specialists

**Phases:** 4 phases
1. Charter Review & Context Loading (15-20 min)
2. Design Development with Specialist Coordination (60-90 min)
3. Requirements Documentation & Validation (30-45 min)
4. Specification Approval & Handoff (15-20 min)

**Duration:** 2-3 hours
**Output:** Approved `spec.md` in `/nodes/{node-name}/`

**Key Features:**
- Multi-agent coordination (Alex, Frank, William, Julia)
- Comprehensive design sections (architecture, security, infrastructure, testing)
- Requirements traceability (FR, NFR, SC)
- Testing strategy integrated from start
- CAIO-driven iterative refinement
- Handoff preparation for task breakdown

**Specialist Agents Coordinated:**
- **Alex (Platform Architect):** Architecture design, layer placement, integration patterns, ADRs
- **Frank (Security Specialist):** Security requirements, authentication/authorization, credentials
- **William (Infrastructure Specialist):** Infrastructure requirements, bare metal deployment, systemd services
- **Julia (Testing Specialist):** Testing strategy, quality gates, success criteria

**Design Sections Generated:**
- Architecture design (layers, components, integration)
- Security design (authentication, authorization, credentials)
- Infrastructure design (deployment, networking, services)
- Testing strategy (test categories, coverage, quality gates)
- Operational design (monitoring, backup, disaster recovery)

**Quality Gates:**
- Design Validation Gate (Phase 3)
- Specification Approval Gate (Phase 4)

**When to Use:**
- After charter approval
- Transforming charter requirements into detailed technical specification
- Coordinating multi-domain design decisions

**v1.3 Key Innovation:** Team-based approach with specialist agent contributions ensures comprehensive, expert-informed specifications

---

### ✅ Workflow 3: Task Breakdown
**File:** cc-task-workflow.md
**Version:** 1.0
**Size:** 1,615 lines (63.41 KB)
**Status:** ✅ APPROVED - Production Ready v1.0
**Purpose:** Transform approved specification into executable tasks with comprehensive test suite following test-driven deployment methodology

**Phases:** 3 phases
1. Specification Analysis & Task Generation (30-45 min)
2. Test Suite Generation Sub-Workflow (90-120 min)
3. Task Validation & Handoff (20-30 min)

**Duration:** 2.5-3.5 hours
**Output:**
- Task files in `/nodes/{node-name}/tasks/`
- Comprehensive test suite in `/nodes/{node-name}/tests/test-suite/`
- Test plan and execution tracking

**Key Features:**
- Test-driven deployment methodology
- 100% requirements coverage mandate
- Comprehensive test suite generation (8 test categories)
- Task decomposition with clear acceptance criteria
- Task prioritization and sequencing
- Deployment planning integration

**Test Categories (8 categories, 100% coverage):**
1. Deployment Tests (TC-D-xxx)
2. Functionality Tests (TC-F-xxx)
3. Integration Tests (TC-I-xxx)
4. Health Check Tests (TC-H-xxx)
5. Security Tests (TC-S-xxx)
6. Performance Tests (TC-P-xxx)
7. Backup/Recovery Tests (TC-B-xxx)
8. Runbook/Operations Tests (TC-R-xxx)

**Phase Commands Invoked:**
- **Phase 2:** cc-phase-test-suite-generation.md (comprehensive test suite)

**Quality Gates:**
- Test Suite Completeness Gate (Phase 2)
- Task Validation Gate (Phase 3)

**When to Use:**
- After specification approval
- Breaking down spec into executable tasks
- Generating test suite for test-driven deployment

**Test-Driven Deployment Principle:** Tests written BEFORE implementation, 100% coverage REQUIRED, NO operational promotion without passing tests

---

### ✅ Workflow 4: Task Execution
**File:** cc-task-execution-workflow.md
**Version:** 1.0
**Size:** 1,219 lines (38.63 KB)
**Status:** ✅ APPROVED - Production Ready v1.0
**Purpose:** Systematic execution of approved tasks with test-driven deployment, continuous validation, defect management, and comprehensive result documentation

**Phases:** 4 phases
1. Pre-Execution Preparation (15-20 min)
2. Implementation with Test-Driven Deployment (60-180 min, task-dependent)
3. Validation & Quality Gates (30-45 min)
4. Result Documentation & Operational Handoff (30-45 min)

**Duration:** 2.5-5 hours (task-dependent)
**Output:**
- Deployed service/component
- Test execution results
- Task result documentation
- Operational handoff package

**Key Features:**
- Test-driven deployment enforcement
- Continuous testing during implementation
- Defect management and resolution
- Quality gate validation
- Comprehensive result documentation
- Operational handoff preparation

**Execution Pattern:**
1. Load task and test suite
2. Execute tests (pre-implementation baseline - should fail)
3. Implement task deliverables
4. Re-execute tests (post-implementation - should pass)
5. Validate quality gates
6. Document results
7. Prepare operational handoff

**Phase Commands Invoked:**
- **Phase 2:** cc-phase-defect-mgmt.md (when tests fail)
- **Phase 4:** cc-phase-task-result-doc.md (result documentation)

**Quality Gates:**
- Pre-Execution Validation Gate (Phase 1)
- Test Execution Gate (Phase 3) - 100% pass rate required
- Quality Gate Validation (Phase 3) - All gates must pass
- Operational Readiness Gate (Phase 4)

**When to Use:**
- After task breakdown complete and approved
- Executing deployment tasks systematically
- Test-driven deployment of services

**Critical Rule:** Zero tolerance for test failures. Critical/High defects BLOCK operational promotion.

---

### ✅ Workflow 5: Project Closeout
**File:** cc-project-closeout-workflow.md
**Version:** 1.0
**Size:** 1,058 lines (31.46 KB)
**Status:** ✅ APPROVED - Production Ready v1.0
**Purpose:** Systematic project closure with centralized artifact updates, knowledge capture, formal operational handoff, and project archival

**Phases:** 4 phases
1. Final Validation & Verification (30-45 min)
2. Knowledge Capture & Documentation (45-60 min)
3. Operational Handoff & Transition (30-45 min)
4. Project Closure & Archival (20-30 min)

**Duration:** 2-3 hours
**Output:**
- Final project summary
- Complete artifact inventory
- Operational handoff documentation
- Lessons learned document
- Project closure report

**Key Features:**
- Final validation of all deliverables
- Comprehensive knowledge capture
- Lessons learned documentation
- Operational handoff with runbooks
- Centralized tracking updates (RAIDD, backlog, defects)
- Project archival and closure

**Validation Checklist:**
- All tasks completed and closed
- All tests passing (100% pass rate)
- All defects resolved (zero Critical/High)
- All documentation complete and approved
- All artifacts registered and tracked
- All operational requirements met
- All handoffs prepared and approved

**Knowledge Capture:**
- Technical lessons learned
- Process improvements identified
- Best practices documented
- Common issues and solutions
- Reusable patterns captured

**Operational Handoff:**
- Service runbooks complete
- Monitoring configured and validated
- Backup/recovery procedures documented
- Support escalation paths defined
- Knowledge transfer completed

**Quality Gates:**
- Final Validation Gate (Phase 1)
- Knowledge Capture Completeness Gate (Phase 2)
- Operational Handoff Approval Gate (Phase 3)
- Project Closure Approval Gate (Phase 4)

**When to Use:**
- After all tasks executed and service operational
- When transitioning from development to operations
- Closing out project systematically

**Closure Principle:** No project closed until operations team has accepted handoff and all knowledge captured

---

## Workflow Relationships

### Sequential Workflow Dependencies

```
Charter → Specification → Task Breakdown → Task Execution → Project Closeout
   ↓            ↓              ↓                 ↓                ↓
charter.md   spec.md      tasks/ + tests/    deployed       closed project
```

**Each workflow depends on previous:**
- **Spec Workflow** requires approved charter
- **Task Workflow** requires approved spec
- **Execution Workflow** requires tasks and test suite
- **Closeout Workflow** requires completed execution

### Workflow Outputs Feed Next Workflow

**Charter → Specification:**
- Charter requirements → Spec requirements section
- Charter scope → Spec design boundaries
- Charter success criteria → Spec validation criteria

**Specification → Task Breakdown:**
- Spec requirements → Task decomposition
- Spec design → Implementation tasks
- Spec testing strategy → Test suite generation

**Task Breakdown → Execution:**
- Tasks → Execution sequence
- Test suite → Validation criteria
- Deployment plan → Implementation guidance

**Execution → Closeout:**
- Deployed service → Final validation
- Execution results → Knowledge capture
- Operational state → Handoff preparation

---

## Workflow Orchestration Patterns

### Pattern 1: Single Workflow Execution

**Scenario:** Execute one workflow independently

**Example:** Generate charter for new service
```
Invoke: cc-charter-workflow.md
Input: CAIO natural language requirements
Output: Approved charter.md
```

### Pattern 2: Sequential Workflow Chain

**Scenario:** Execute complete project lifecycle

**Example:** Deploy new service from concept to operations
```
1. cc-charter-workflow.md → charter.md
2. cc-spec-workflow.md → spec.md
3. cc-task-workflow.md → tasks/ + tests/
4. cc-task-execution-workflow.md → deployed service
5. cc-project-closeout-workflow.md → closed project
```

### Pattern 3: Iterative Workflow Execution

**Scenario:** Refine output through multiple iterations

**Example:** Charter refinement through CAIO feedback
```
cc-charter-workflow.md (iteration 1) → CAIO review
→ cc-charter-workflow.md (iteration 2) → CAIO review
→ cc-charter-workflow.md (iteration 3) → Approved
```

### Pattern 4: Parallel Task Execution

**Scenario:** Execute multiple tasks concurrently

**Example:** Deploy multiple independent services
```
Task 1: cc-task-execution-workflow.md (service A)
Task 2: cc-task-execution-workflow.md (service B)
Task 3: cc-task-execution-workflow.md (service C)
→ All parallel execution, coordinated closeout
```

---

## Integration with Other Command Sets

### Workflows Invoke Phase Commands (Set 4)

**Charter Workflow:**
- cc-phase-charter-questions.md (Phase 4, Phase 6)
- cc-phase-knowledge-research.md (Phase 5)

**Task Workflow:**
- cc-phase-test-suite-generation.md (Phase 2)

**Execution Workflow:**
- cc-phase-defect-mgmt.md (Phase 2, when defects occur)
- cc-phase-task-result-doc.md (Phase 4)

### Workflows Invoke Utilities (Set 3)

**All Workflows Use:**
- **artifact-tracker:** Register workflow artifacts
- **doc-lint:** Validate workflow documentation
- **quality-gate:** Validate workflow phase gates
- **raidd:** Track workflow risks, issues, decisions
- **status-report:** Generate workflow progress reports
- **handoff:** Capture workflow state at transitions

**Specific Examples:**

**Charter Workflow:**
- artifact-tracker: Register charter.md, questions, research
- raidd: Log charter assumptions, decisions, risks

**Spec Workflow:**
- context-prep: Prepare context for specialist agents
- artifact-tracker: Register spec.md, designs, ADRs

**Task Workflow:**
- artifact-tracker: Register tasks, test suite
- quality-gate: Validate test coverage (100% requirement)

**Execution Workflow:**
- artifact-tracker: Register deployment artifacts, results
- raidd: Track execution issues, risks

**Closeout Workflow:**
- artifact-tracker: Generate final artifact inventory
- status-report: Generate final project summary

### Workflows Coordinate Agent Orchestration (Set 5)

**Spec Workflow Coordinates:**
- cc-orchestrate-alex.md (architecture design)
- cc-orchestrate-frank.md (security design)
- cc-orchestrate-william.md (infrastructure design)
- cc-orchestrate-julia.md (testing strategy)
- cc-agent-zero-synthesis.md (multi-agent coordination)

**Example Multi-Agent Coordination in Spec Workflow:**
```
Phase 2: Design Development
├── Invoke Alex (architecture) via cc-orchestrate-alex.md
├── Invoke Frank (security) via cc-orchestrate-frank.md
├── Invoke William (infrastructure) via cc-orchestrate-william.md
├── Invoke Julia (testing) via cc-orchestrate-julia.md
└── Synthesize outputs via cc-agent-zero-synthesis.md
```

---

## Quality Gates Throughout Workflows

### Charter Workflow Gates
- **Repository Confirmation Gate** (Phase 3)
- **Charter Approval Gate** (Phase 8)

### Spec Workflow Gates
- **Design Validation Gate** (Phase 3)
- **Specification Approval Gate** (Phase 4)

### Task Workflow Gates
- **Test Suite Completeness Gate** (Phase 2) - 100% coverage required
- **Task Validation Gate** (Phase 3)

### Execution Workflow Gates
- **Pre-Execution Validation Gate** (Phase 1)
- **Test Execution Gate** (Phase 3) - 100% pass rate required
- **Quality Gate Validation** (Phase 3) - All gates must pass
- **Operational Readiness Gate** (Phase 4)

### Closeout Workflow Gates
- **Final Validation Gate** (Phase 1)
- **Knowledge Capture Completeness Gate** (Phase 2)
- **Operational Handoff Approval Gate** (Phase 3)
- **Project Closure Approval Gate** (Phase 4)

**Gate Enforcement:** All gates are BLOCKING - workflow cannot proceed until gate criteria met

---

## Infrastructure Philosophy Integration

All workflows align with HX-Infrastructure deployment philosophy:

### Bare Metal First
- **Charter:** Scope defines bare metal deployment targets
- **Spec:** Infrastructure design specifies bare metal configuration
- **Task:** Deployment tasks target bare metal (Ubuntu 24)
- **Execution:** Implementation deploys to bare metal servers

### Docker Dev-Only Exception
- **Charter:** Documents dev environment requirements
- **Spec:** Specifies dev containers on hx-dev-server (192.168.10.222)
- **Task:** Separates dev tasks from production tasks
- **Execution:** Dev containers allowed only on dev server

### Systemd Service Management
- **Charter:** Requirements include systemd service definition
- **Spec:** Service design includes systemd unit file specification
- **Task:** Tasks include systemd unit creation and validation
- **Execution:** Service deployed and managed via systemd

### Manual Procedures Only
- **Charter:** Scope excludes automation (Ansible playbooks)
- **Spec:** Deployment design documents manual procedures
- **Task:** Tasks provide step-by-step manual procedures
- **Execution:** Manual execution following documented procedures

### Ansible Vault Credentials
- **Charter:** Security requirements mandate Ansible Vault
- **Spec:** Credentials design specifies vault structure
- **Task:** Tasks include vault credential setup
- **Execution:** All credentials stored in Ansible Vault

---

## Workflow Statistics

### Overview
**Total Workflows:** 5
**Total Lines:** 5,920 lines
**Total Size:** 206.87 KB
**Average Size:** 1,184 lines per workflow
**Total Phases:** 23 phases across all workflows
**Average Phases:** 4.6 phases per workflow

### Size Distribution
1. **cc-task-workflow.md:** 1,615 lines (largest, most complex)
2. **cc-spec-workflow.md:** 1,229 lines
3. **cc-task-execution-workflow.md:** 1,219 lines
4. **cc-project-closeout-workflow.md:** 1,058 lines
5. **cc-charter-workflow.md:** 799 lines (smallest, most streamlined)

### Duration Estimates
- **Charter:** 2-4 hours
- **Specification:** 2-3 hours
- **Task Breakdown:** 2.5-3.5 hours
- **Task Execution:** 2.5-5 hours (task-dependent)
- **Closeout:** 2-3 hours

**Total Lifecycle:** ~12-19 hours for complete project (varies by complexity)

---

## Best Practices

### Workflow Execution Guidelines

**1. Always Start with Charter**
- ✅ Every project begins with charter workflow
- ✅ Never skip charter for "simple" projects
- ❌ Don't proceed to spec without approved charter

**2. Follow Sequential Order**
- ✅ Execute workflows in order (Charter → Spec → Task → Execution → Closeout)
- ✅ Complete each workflow before starting next
- ❌ Don't skip workflows or execute out of order

**3. Respect Quality Gates**
- ✅ All gates are blocking - must satisfy criteria
- ✅ Document gate failures and remediation
- ❌ Don't bypass gates or proceed without approval

**4. Engage Specialists Appropriately**
- ✅ Invoke specialist agents when criteria met
- ✅ Prepare context thoroughly before handoffs
- ❌ Don't invoke specialists without adequate context

**5. Document Everything**
- ✅ Use artifact-tracker to register all deliverables
- ✅ Use raidd to track all decisions and issues
- ❌ Don't skip documentation "for speed"

### Workflow Iteration Guidelines

**Charter Iterations:**
- Expected: 1-3 iterations for approval
- CAIO provides feedback, CC refines
- Each iteration improves clarity and completeness

**Spec Iterations:**
- Expected: 1-2 iterations for approval
- CAIO + specialists provide feedback
- Focus on technical correctness and feasibility

**Task Iterations:**
- Expected: Minimal (tasks derived directly from spec)
- Iteration primarily for test coverage gaps

**Execution Iterations:**
- Expected: Test failures drive iterations
- Defect → Resolution → Re-test cycle
- Continue until 100% test pass rate

### Context Preservation

**Between Workflow Phases:**
- Use handoff utility to capture state
- Document current phase completion status
- List artifacts produced
- Note blockers or dependencies

**Between Chat Sessions:**
- Use handoff utility before context limits
- Comprehensive state capture including RAIDD
- Clear next actions for continuation
- Reference all relevant files with locations

---

## Common Scenarios

### Scenario 1: New Service Deployment (Full Lifecycle)

**Objective:** Deploy new RAG service from concept to operations

**Workflow Sequence:**
1. **Charter Workflow** (3 hours)
   - CAIO provides requirements for RAG service
   - Research LightRAG, Qdrant repositories
   - Generate and approve charter

2. **Spec Workflow** (2.5 hours)
   - Design with Alex (architecture), Frank (security), William (infrastructure)
   - Document requirements (FR, NFR, SC)
   - Approve specification

3. **Task Workflow** (3 hours)
   - Break spec into deployment tasks
   - Generate comprehensive test suite (100% coverage)
   - Approve tasks and tests

4. **Execution Workflow** (4 hours, multiple tasks)
   - Execute deployment tasks systematically
   - Run tests, manage defects, validate quality gates
   - Document results and prepare handoff

5. **Closeout Workflow** (2.5 hours)
   - Final validation, knowledge capture
   - Operational handoff to ops team
   - Close project formally

**Total Duration:** ~15 hours (varies by complexity)

---

### Scenario 2: Charter-Only Development

**Objective:** Define project scope and requirements without immediate implementation

**Workflow:**
1. **Charter Workflow** only
   - Complete charter development
   - Approve charter
   - Park project (defer spec/implementation)

**Use Case:** Strategic planning, future roadmap, feasibility assessment

---

### Scenario 3: Spec Update for Existing Service

**Objective:** Update specification for already-deployed service

**Workflow:**
1. Review existing charter and spec
2. **Spec Workflow** (update mode)
   - Update design sections as needed
   - Coordinate with relevant specialists
   - Approve updated spec
3. **Task Workflow** (if changes require implementation)
4. **Execution Workflow** (if tasks generated)

---

### Scenario 4: Emergency Defect Resolution

**Objective:** Fix critical production defect

**Workflow:**
1. **Execution Workflow** (expedited)
   - Load existing task/spec context
   - cc-phase-defect-mgmt.md (log defect)
   - Implement fix
   - Execute regression tests
   - Verify defect resolved
   - Document results

**Note:** May skip certain phases for critical fixes, but NEVER skip testing

---

## Version History

### Charter Workflow (v1.2)
- **v1.2:** Added post-research questions phase (key innovation)
- **v1.1:** Enhanced repository research structure
- **v1.0:** Initial release

### Spec Workflow (v1.3)
- **v1.3:** Team-based multi-agent specification approach
- **v1.2:** Enhanced design sections
- **v1.1:** Improved requirements traceability
- **v1.0:** Initial release

### Task Workflow (v1.0)
- **v1.0:** Initial release with test-driven deployment

### Execution Workflow (v1.0)
- **v1.0:** Initial release with comprehensive validation

### Closeout Workflow (v1.0)
- **v1.0:** Initial release

---

## Future Enhancements

**Planned Improvements:**
1. **Workflow Metrics:** Track workflow execution times, iteration counts, success rates
2. **Template Library:** Expand templates for common service patterns
3. **Automation:** Partial automation of repetitive workflow steps
4. **Checkpointing:** Enhanced checkpoint/resume capabilities for long workflows
5. **Parallel Execution:** Support for parallel workflow execution where appropriate

**Potential New Workflows:**
- **Service Update Workflow:** Systematic updates to operational services
- **Migration Workflow:** Service migration between environments
- **Decommission Workflow:** Systematic service retirement
- **Incident Response Workflow:** Structured incident investigation and resolution

---

## Related Documentation

**Command Sets:**
- **Set 2 (Orchestrations):** `/home/agent0/HX-Infrastructure/.claude/commands/orchestrations/README.md`
- **Set 3 (Utilities):** `/home/agent0/HX-Infrastructure/.claude/commands/utilities/README.md`
- **Set 4 (Phase Commands):** `/home/agent0/HX-Infrastructure/.claude/commands/phases/README.md`
- **Set 5 (Agent Orchestration):** `/home/agent0/HX-Infrastructure/.claude/commands/agents/README.md`

**Standards:**
- **Constitution:** `/home/agent0/HX-Infrastructure/constitution.md`
- **Architecture Standards:** `/home/agent0/HX-Infrastructure/standards/architecture-standards.md`
- **Documentation Requirements:** `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md`
- **Testing Requirements:** `/home/agent0/HX-Infrastructure/standards/testing-requirements.md`

**Project Structure:**
- **Node Directory:** `/nodes/{node-name}/` (workflow outputs)
- **Docs Directory:** `/home/agent0/HX-Infrastructure/docs/` (centralized tracking)

---

**Last Updated:** 2025-11-21
**Maintainer:** HX-Infrastructure Team
**Status:** ✅ PRODUCTION READY
**Total Workflows:** 5 workflows (complete project lifecycle)
**Coverage:** Complete orchestration from concept through operational deployment
**Maturity:** Production-proven workflows (v1.0-v1.3)
