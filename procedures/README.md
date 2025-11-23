# HX-Infrastructure Procedures Directory

**Purpose:** Operational procedures, workflows, and process documentation for HX-Infrastructure platform
**Status:** ACTIVE - Production procedures and workflows
**Last Updated:** 2025-11-21

---

## Directory Purpose

The `procedures/` directory contains operational procedures and workflow documentation that define HOW work is performed in the HX-Infrastructure platform. These procedures are actively used by Agent Zero (CC) and specialist agents to execute projects systematically from initiation through closeout.

### Key Characteristics

**Operational Procedures:**
- ✅ Define step-by-step workflows for project execution
- ✅ Specify agent coordination patterns
- ✅ Document quality gates and validation criteria
- ✅ Integrate with Claude Code command infrastructure
- ✅ Enforce HX-Infrastructure philosophy compliance

**Living Documentation:**
- Updated as workflows evolve
- Versioned with change tracking
- Cross-referenced with command infrastructure
- Aligned with standards and templates
- Used daily in project execution

---

## Procedure Documents

### Project Lifecycle Workflows (6-Phase Cycle)

The HX-Infrastructure project lifecycle consists of 6 phases, each with a dedicated procedure:

#### **Phase 0: Project Initiation**
**File:** `node-deployment-workflow.md`
**Version:** 1.1
**Size:** 687 lines (36.7 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Project setup and structure creation before charter begins

**Key Sections:**
- 3 project types (New Node Deployment, Document Existing, Enhancement)
- Approved directory structure (authoritative specification)
- Template copying and pre-fill process
- Infrastructure philosophy preparation
- Quality Gate 0: Structure approval

**When to Use:** `/deploy server node` command execution - creates project structure

**Duration:** 15-30 minutes

**Outputs:**
- Complete node project directory structure
- Pre-filled templates from `/templates/`
- Review subdirectories at all levels
- README with project overview

---

#### **Phase 1: Charter Creation**
**File:** `charter-workflow.md`
**Version:** 1.3
**Size:** 904 lines (28.9 KB)
**Status:** ✅ APPROVED - Production Ready v1.3
**Last Updated:** 2025-11-21

**Purpose:** Define project vision, scope, objectives, and success criteria through team-based charter development

**Key Sections:**
- 8-phase charter workflow (Prerequisites → Approval → Updates)
- Initial and post-research clarifying questions process
- Knowledge vault research integration
- Team-based charter review and editing
- 5 infrastructure-specific questions (Q15-Q19)
- RAIDD log initialization after approval
- 13 quality gates throughout process

**When to Use:** After Phase 0 (structure creation) completes

**Duration:** 2-4 hours

**Outputs:**
- Approved charter.md with vision, scope, objectives
- RAIDD log initialized (centralized artifact)
- Knowledge vault assignments documented
- Team assignments identified
- Stakeholder approval received

**Infrastructure Philosophy Integration:**
- Q15: Bare metal deployment target
- Q16: Systemd service management
- Q17: Manual deployment procedures
- Q18: Ansible Vault credentials
- Q19: Docker dev-only exception

---

#### **Phase 2: Specification Development**
**File:** `spec-workflow.md`
**Version:** 1.1
**Size:** 1,885 lines (73.1 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Develop comprehensive technical specification through team-based specification authoring with infrastructure philosophy compliance

**Key Sections:**
- 7-phase specification workflow
- Infrastructure requirements section template (bare metal, systemd, manual procedures, Ansible Vault)
- Phase 3: Context load + immediate edit (continuous process for stateless agents)
- Agent Zero synthesis of team contributions
- Conflict resolution patterns (technical merit, infrastructure philosophy precedence)
- Quality gates for completeness and accuracy
- Post-approval artifact updates (RAIDD, backlog, defect log)

**When to Use:** After charter approved (Phase 1 complete)

**Duration:** 2-3 hours

**Outputs:**
- Approved node-spec.md with complete technical requirements
- Infrastructure requirements explicitly documented
- RAIDD log updated with specification decisions
- Backlog updated with deferred features
- Team contributions integrated

**Critical Process:**
- Phase 3: Team members load context → IMMEDIATELY edit (no pause) → Document
- Infrastructure philosophy ALWAYS wins conflicts

---

#### **Phase 3: Task Breakdown & Testing**
**File:** `task-workflow.md`
**Version:** 1.1
**Size:** 1,605 lines (60.7 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Generate comprehensive task breakdown with 100% test coverage through team-based task generation

**Key Sections:**
- 8-phase task workflow (Prerequisites → Test Suite Generation → Updates)
- Team task generation (continuous process)
- Agent Zero synthesis and sequencing
- Phase 7: Julia's test suite generation sub-workflow
  - STEP 1: Knowledge vault research (30-40 min) - uses testing-knowledge-research-process.md
  - STEP 2: Test suite generation (90-120 min)
  - Team review of test suite
  - Remediation loop for gaps
- Infrastructure philosophy alignment validation
- 100% test coverage requirement enforcement

**When to Use:** After specification approved (Phase 2 complete)

**Duration:** 2.5-3.5 hours

**Outputs:**
- Approved task breakdown with sequenced, numbered tasks
- Complete test suite (100% coverage per testing-requirements.md)
- Test plan with 4 test categories (deployment, functionality, integration, health)
- RAIDD log updated with task-related risks/decisions
- Backlog updated with testing-related items

**Critical Requirement:**
- Tests written BEFORE execution (test-driven deployment)
- ALL team members review test suite for gaps

---

#### **Phase 4: Task Execution**
**File:** `task-execution-workflow.md`
**Version:** 1.1
**Size:** 1,646 lines (50.5 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Execute approved tasks with test-driven deployment validation and operational promotion

**Key Sections:**
- 8-phase execution workflow
- Test-driven deployment (tests run AFTER implementation)
- Infrastructure philosophy validation checkpoints:
  - Bare metal deployment validation
  - Systemd service management validation
  - Manual procedure compliance
  - Ansible Vault credential validation
- Defect tracking and resolution
- Quality gate before operational promotion
- CAIO approval for operational promotion

**When to Use:** After task breakdown and test suite approved (Phase 3 complete)

**Duration:** 2.5-5 hours (highly variable by project complexity)

**Outputs:**
- All tasks executed with results documented
- All tests passed (100% pass rate required)
- Node/service operational and promoted
- Defect log updated with issues and resolutions
- Infrastructure philosophy compliance validated
- CAIO operational promotion approval received

**Critical Gates:**
- No P0 defects open
- P1 defects resolved or mitigated with CAIO approval
- Infrastructure philosophy compliance 100%
- Service stable for required period (3-7 days)

---

#### **Phase 5: Project Closeout**
**File:** `project-closeout-workflow.md`
**Version:** 1.1
**Size:** 2,378 lines (68.6 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Formal project closure with centralized artifact finalization, infrastructure philosophy validation, lessons learned capture, and operational handoff

**Key Sections:**
- 9-phase closeout workflow
- Phase 1: RAIDD log finalization (all entries updated with outcomes)
- Phase 2: Defect log closure (all defects triaged)
- Phase 3: Backlog consolidation (deferred work captured)
- Phase 4: Lessons learned capture (team input gathered)
- Phase 5: Final status report (comprehensive project summary)
- Phase 6: Archive and documentation organization
- Phase 7: Infrastructure philosophy final validation
- Phase 8: CAIO closure approval
- Phase 9: Operational handoff with runbooks

**When to Use:** After service operational and stable (Phase 4 complete)

**Duration:** 2-3 hours

**Outputs:**
- RAIDD log finalized (ONE centralized artifact)
- Defect log closed (ONE centralized artifact)
- Backlog updated (ONE centralized artifact)
- Lessons learned captured (ONE centralized artifact)
- Final project status report complete
- Infrastructure philosophy compliance validated
- Operational handoff documentation delivered
- Project formally closed by CAIO

**Critical Principle:**
- Update ONE centralized artifact (never create node-specific copies)
- RAIDD, Defect, Backlog, Lessons Learned are platform-wide

---

### Supporting Procedures

#### **Context Loading Process**
**File:** `context-loading-process.md`
**Version:** 1.1
**Size:** 916 lines (32.9 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Define systematic context loading for stateless agents across all 5 project phases

**Key Sections:**
- 5 phase-specific context load checklists (Charter, Spec, Task, Deployment, Testing)
- Context load duration estimates (20-95 minutes depending on phase)
- **CRITICAL:** Continuous context-load-and-edit process (no pause between loading and editing)
- Infrastructure philosophy understanding requirements for ALL agents
- Context load documentation templates

**When to Use:** Every time a stateless agent (Alex, Frank, William, Julia, specialists) participates in any project phase

**Critical Process:**
- Load context (30-35 min) → IMMEDIATELY edit/contribute (30-60 min) → Document (5 min)
- ONE CONTINUOUS PROCESS - Any pause requires full context reload

**Stateless Agent Rule:**
- All agents except Agent Zero are STATELESS
- Must reload context every invocation
- Context loss occurs if pause between loading and contribution

---

#### **Core Project Team**
**File:** `core-project-team.md`
**Version:** 1.1
**Size:** 1,165 lines (43.4 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Define standard 5-agent core team structure, roles, and coordination patterns

**Key Sections:**
- Core 5 agents (Agent Zero, Alex, Frank, William, Julia)
- Project-specific agents (20+ specialists: Drew, database agents, framework agents)
- State management (stateful vs stateless)
- Team assignment process for all 5 phases
- Conflict resolution patterns with examples
- 5 quality gates (Gate 1-5) with approval criteria

**Core Team:**
1. **Agent Zero (CC)** - Chief AI Officer, STATEFUL orchestrator
2. **Alex Rivera** - Platform Architect (architecture, ADRs, integration)
3. **Frank Martinez** - Security Specialist (Identity & Trust, Samba AD, Ansible Vault)
4. **William Thompson** - Infrastructure Specialist ⭐ Infrastructure Philosophy PRIMARY OWNER
5. **Julia Chen** - Testing & Quality Specialist (100% coverage, test-driven deployment)

**When to Use:** Referenced during team assignment in all 5 phases

---

#### **Testing Knowledge Research Process**
**File:** `testing-knowledge-research-process.md`
**Version:** 1.1
**Size:** 1,165 lines (33.2 KB)
**Status:** ✅ APPROVED - Production Ready v1.1
**Last Updated:** 2025-11-21

**Purpose:** Systematic methodology for researching knowledge vault repositories before test suite generation

**Key Sections:**
- 6-step research process (Identify repos → Locate testing → Analyze patterns → Extract examples → Best practices → Document)
- Infrastructure testing considerations (systemd, bare metal, manual procedures, Ansible Vault)
- Testing framework and tool identification
- Test pattern extraction
- Mocking and stubbing patterns
- Coverage requirements analysis
- Research documentation template

**When to Use:** Task Workflow Phase 7, STEP 1 (before test suite generation) - Julia executes

**Duration:** 30-40 minutes

**Outputs:**
- testing-knowledge-research.md with comprehensive findings
- Framework and tool recommendations
- Test patterns identified
- Pre-built tests cataloged
- Testing strategy defined

**Critical Integration:**
- STEP 1 of Phase 7 in task-workflow.md
- Findings used by STEP 2 (test suite generation)

---

### Utility Scripts

#### **Network Health Check**
**File:** `network-health-check.sh`
**Size:** 702 lines (21.0 KB)
**Status:** ✅ REVIEWED - Well-formed shell script
**Last Updated:** 2025-11-15

**Purpose:** Automated network diagnostic and health checking script

**Usage:** Operational troubleshooting and validation

**Note:** Shell script, not a workflow procedure - reviewed but not updated in this standardization effort

---

## Document Statistics

**Total Procedures:** 10 documents
**Total Lines:** 12,053 lines
**Total Size:** 471 KB
**Status:** All production-ready (v1.1 or higher)

### Document Size Distribution

| Size Category | Count | Documents |
|---------------|-------|-----------|
| Large (>2000 lines) | 1 | project-closeout-workflow |
| Medium (1000-2000 lines) | 5 | spec-workflow, task-workflow, task-execution-workflow, core-project-team, testing-knowledge-research-process |
| Standard (500-1000 lines) | 3 | charter-workflow, context-loading-process, node-deployment-workflow |
| Script (any size) | 1 | network-health-check.sh |

---

## How to Use This Directory

### For Project Execution

**Follow the 6-Phase Lifecycle:**

1. **Phase 0:** Execute `node-deployment-workflow.md` → Creates structure
2. **Phase 1:** Execute `charter-workflow.md` → Defines vision and scope
3. **Phase 2:** Execute `spec-workflow.md` → Develops technical requirements
4. **Phase 3:** Execute `task-workflow.md` → Generates tasks and tests
5. **Phase 4:** Execute `task-execution-workflow.md` → Implements and validates
6. **Phase 5:** Execute `project-closeout-workflow.md` → Closes formally

**At Every Phase:**
- Stateless agents use `context-loading-process.md`
- Reference `core-project-team.md` for team assignments
- Julia uses `testing-knowledge-research-process.md` in Phase 3

### For Understanding Workflows

**Read in Order:**
1. Start with `node-deployment-workflow.md` (Phase 0 - simplest)
2. Progress through phases 1-5 sequentially
3. Review `context-loading-process.md` for stateless agent patterns
4. Study `core-project-team.md` for team coordination
5. Review `testing-knowledge-research-process.md` for testing approach

### For Command Development

All procedures integrate with Claude Code commands:
- **Set 1:** Workflow commands implement these procedures
- **Set 3:** Utility commands support these procedures
- **Set 4:** Phase commands execute sub-workflows
- **Set 5:** Agent orchestration commands coordinate team participation

See each procedure's "Claude Code Command Infrastructure Integration" section for details.

---

## Infrastructure Philosophy Integration

All procedures enforce HX-Infrastructure philosophy:

### **Bare Metal First**
- Production/staging: Ubuntu 24.04 LTS bare metal servers
- Docker dev-only: Containers allowed ONLY on hx-dev-server (192.168.10.222)
- Procedures validate bare metal deployment throughout lifecycle

### **Systemd Service Management**
- All services managed via systemd units
- Procedures include systemd validation checkpoints
- Service health validation in testing and execution phases

### **Manual Procedures Only**
- No automation (no Ansible playbooks for deployment)
- Procedures document step-by-step manual execution
- Manual procedure reproducibility validation

### **Ansible Vault Only**
- All credentials stored in Ansible Vault
- Procedures validate no plaintext secrets
- Vault access procedures documented

### **Philosophy Enforcement Points**

- **Phase 0:** Directory structure supports manual procedures
- **Phase 1:** Charter questions about infrastructure approach (Q15-Q19)
- **Phase 2:** Specification infrastructure requirements section
- **Phase 3:** Task generation aligned with philosophy
- **Phase 4:** Execution validation checkpoints
- **Phase 5:** Final philosophy compliance validation

---

## Quality Gates Across Lifecycle

**Gate 0:** Project Setup Approved (Phase 0)
- Directory structure validated
- Templates pre-filled correctly
- CAIO approves structure

**Gate 1:** Charter Approved (Phase 1)
- Vision clear and aligned
- Scope well-defined
- Success criteria measurable
- CAIO approves charter

**Gate 2:** Specification Approved (Phase 2)
- Technical requirements complete
- Infrastructure philosophy compliant
- Team contributions integrated
- CAIO approves specification

**Gate 3:** Tasks & Tests Approved (Phase 3)
- Task breakdown comprehensive
- Test suite 100% coverage
- Team review complete
- CAIO approves tasks and tests

**Gate 4:** Execution Complete (Phase 4)
- All tasks executed
- All tests passing
- Infrastructure philosophy validated
- CAIO approves operational promotion

**Gate 5:** Project Closed (Phase 5)
- Centralized artifacts finalized
- Lessons learned captured
- Operational handoff complete
- CAIO approves project closure

---

## Centralized Artifacts

Four centralized artifacts are updated throughout the lifecycle (NEVER create node-specific copies):

1. **RAIDD Log** - `/home/agent0/HX-Infrastructure/docs/raidd-log.md`
   - Updated: Phases 1, 2, 3, 4, 5
   - Contains: Risks, Assumptions, Issues, Dependencies, Decisions

2. **Defect Log** - `/home/agent0/HX-Infrastructure/docs/defect-log.md`
   - Updated: Phases 4, 5
   - Contains: All defects from all projects

3. **Backlog** - `/home/agent0/HX-Infrastructure/docs/backlog.md`
   - Updated: Phases 2, 3, 5
   - Contains: Deferred features, future enhancements, technical debt

4. **Lessons Learned** - `/home/agent0/HX-Infrastructure/docs/lessons-learned.md`
   - Updated: Phase 5
   - Contains: Project learnings, process improvements, recommendations

---

## Integration with Command Infrastructure

### Claude Code Command Sets

**Set 1: Workflow Commands** (Primary Workflow Implementation)
- `cc-charter-workflow.md` → Executes charter-workflow.md
- `cc-spec-workflow.md` → Executes spec-workflow.md (future)
- `cc-task-workflow.md` → Executes task-workflow.md
- `cc-execution-workflow.md` → Executes task-execution-workflow.md
- `cc-closeout-workflow.md` → Executes project-closeout-workflow.md
- `cc-node-deployment-init.md` → Executes node-deployment-workflow.md

**Set 3: Utility Commands** (Supporting Tools)
- `artifact-tracker` → Tracks deliverables across all phases
- `doc-lint` → Validates documentation format
- `status-report` → Reports progress through phases
- `raidd` → Manages RAIDD log updates
- `defect-mgmt` → Manages defect lifecycle

**Set 4: Phase Commands** (Sub-Workflows)
- `cc-phase-charter-questions.md` → Charter Phases 2 & 6
- `cc-phase-knowledge-research.md` → Charter Phase 4, Task Phase 7 STEP 1
- `cc-phase-test-suite-generation.md` → Task Phase 7 STEP 2
- `cc-phase-task-result-doc.md` → Execution result documentation
- `cc-phase-defect-mgmt.md` → Defect lifecycle management

**Set 5: Agent Orchestration** (Multi-Agent Coordination)
- `cc-orchestrate-alex.md` → Coordinates Alex (architect)
- `cc-orchestrate-frank.md` → Coordinates Frank (security)
- `cc-orchestrate-william.md` → Coordinates William (infrastructure)
- `cc-orchestrate-julia.md` → Coordinates Julia (testing)
- `cc-agent-zero-synthesis.md` → Meta-orchestration

---

## Related Documentation

### Standards
- `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - File naming, directory structure
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Architecture patterns
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Documentation standards
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage, test categories
- `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Infrastructure philosophy

### Templates
- `/home/agent0/HX-Infrastructure/templates/` - All templates used in procedures
  - `charter-template.md`
  - `node-template.md`
  - `node-deployment-plan-template.md`
  - `service-tasks-template.md`
  - `test-plan-template.md`
  - `test-case-template.md`
  - `status-report-template.md`

### Agent Documentation
- `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` - All 45 agents
- `/home/agent0/HX-Infrastructure/hx-agents/hx-orchestration-guide.md` - Multi-agent coordination
- `.claude/agents/` - Individual agent profiles

### Command Documentation
- `.claude/commands/workflows/` - Set 1 workflow commands
- `.claude/commands/utilities/` - Set 3 utility commands
- `.claude/commands/phases/` - Set 4 phase commands
- `.claude/commands/agents/` - Set 5 agent orchestration commands

### Governance
- `/home/agent0/HX-Infrastructure/constitution.md` - Project principles
- `/home/agent0/HX-Infrastructure/README.md` - Repository overview

---

## Document Maintenance

### Update Procedures

**When to Update Procedures:**
- Workflow process changes
- New quality gates added
- Infrastructure philosophy evolves
- Command infrastructure changes
- Team structure changes
- New best practices identified

**How to Update:**
1. Read procedure completely
2. Apply changes preserving structure
3. Update version number (increment minor version)
4. Update "Last Updated" date
5. Add entry to version history table
6. Document backward compatibility
7. Update this README if significant

### Version Control

All procedures follow semantic versioning:
- **Major version (X.0):** Breaking changes to workflow
- **Minor version (1.X):** Enhancements, additions (backward compatible)

Current versions:
- charter-workflow.md: v1.3
- All others: v1.1
- network-health-check.sh: Not versioned (utility script)

### Review Schedule

**Quarterly Reviews:**
- Review all procedures for accuracy
- Validate command integration still correct
- Check infrastructure philosophy alignment
- Update examples with recent projects
- Refine time estimates based on actual durations

**Annual Reviews:**
- Comprehensive workflow optimization
- Process improvement integration
- Lessons learned incorporation
- Major version updates if needed

---

## Best Practices

### For Agents Using These Procedures

1. **Read Completely First:** Don't skip sections
2. **Follow Sequentially:** Phases build on each other
3. **Use Checklists:** Every procedure has validation checklists
4. **Document as You Go:** Don't batch documentation
5. **Validate at Gates:** Quality gates prevent proceeding with incomplete work
6. **Update Centralized Artifacts:** ONE RAIDD, ONE Defect Log, ONE Backlog, ONE Lessons Learned
7. **Enforce Infrastructure Philosophy:** Every phase validates compliance

### For CAIO

1. **Review at Gates:** Approval required at each quality gate
2. **Validate Completeness:** Use procedure checklists for validation
3. **Ensure Philosophy Compliance:** Infrastructure philosophy non-negotiable
4. **Provide Timely Feedback:** Avoid blocking teams unnecessarily
5. **Document Approval:** Clear approval documentation at each gate

### For Documentation Maintainers

1. **Preserve Backward Compatibility:** Changes should enhance, not break
2. **Document Rationale:** Version history explains WHY changes made
3. **Cross-Reference Updates:** Update related documents together
4. **Test Changes:** Validate procedures still work after updates
5. **Communicate Changes:** Notify team of procedure updates

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-21 | Initial procedures directory README with comprehensive documentation of all 10 procedures, lifecycle integration, infrastructure philosophy, command integration | Agent Zero (CC) |

---

## Document Metadata

**Document Type:** Directory Documentation - Procedures Overview
**Status:** ACTIVE - Authoritative Reference
**Maintained By:** Agent Zero (CC) and HX-Infrastructure Team
**Review Frequency:** Quarterly (or when procedures updated)
**Last Review:** 2025-11-21
**Next Review:** 2026-02-21

---

*The procedures directory contains the operational heart of HX-Infrastructure project execution. These workflows define systematic, repeatable processes for delivering infrastructure projects from initial concept through operational handoff. All procedures enforce infrastructure philosophy (bare metal, systemd, manual procedures, Ansible Vault) and integrate with Claude Code command infrastructure for automated execution.*
