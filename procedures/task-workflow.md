# Task Breakdown Workflow
## Team-Based Task Generation from Approved Specification

**Document Type:** Procedure - Project Lifecycle Workflow (Phase 3: Task Breakdown & Testing)
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Production Ready v1.1
**Location:** `/home/agent0/HX-Infrastructure/procedures/task-workflow.md`

**Purpose:** Define systematic workflow for generating comprehensive task breakdown with multi-agent task generation
**Trigger:** Specification approved
**Input:** Approved node-spec.md, RAIDD log, Backlog, Defects log
**Output:** Approved task breakdown with individual task files + comprehensive test suite (100% coverage)
**Previous Version:** 1.0 → 1.1 (infrastructure philosophy integration, command documentation, comprehensive metadata)

---

## Document Purpose

This procedure defines the **Task Breakdown Workflow** - the third major phase in the HX-Infrastructure project lifecycle. Following an approved specification, this workflow systematically generates a comprehensive, sequenced task breakdown with 100% test coverage through coordinated multi-agent task generation.

### Target Audience
- **Agent Zero (CC):** Primary coordinator and synthesizer across all 8 workflow phases
- **Core Team (Alex, Frank, William):** Task generation for their respective domains
- **Project-Specific Agents:** Domain specialists (Drew, database agents, framework agents) for specialized task generation
- **Julia Chen (Testing Agent):** Test suite generation after task breakdown approved
- **CAIO:** Final approval authority for task breakdown and test suite

### Related Documents
- **Prerequisites:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Specification must be approved before this workflow
- **Next Phase:** `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md` - Executes approved tasks
- **Context Loading:** `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Critical for Phases 3 and 7
- **Team Structure:** `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team composition and roles
- **Testing Process:** `/home/agent0/HX-Infrastructure/procedures/testing-knowledge-research-process.md` - Julia's research workflow (Phase 7)
- **Standards:** `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - File naming and template usage
- **Standards:** `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage requirement

---

## 🎯 Workflow Overview

**Task generation is a team-based process where each agent generates tasks for their domain:**

1. **Pre-Work:** Agent Zero validates prerequisites and creates task structure framework
2. **Team Task Generation:** Team members load context and immediately generate their domain tasks (continuous process)
3. **Synthesis:** Agent Zero sequences, numbers, and organizes all tasks
4. **Clarification:** Agent Zero asks CAIO for decisions on conflicts/dependencies
5. **Approval:** CAIO approves task breakdown
6. **Test Suite Generation:** Julia (Testing Agent) generates complete test suite (sub-workflow with team review)
7. **Updates:** Post-approval artifact updates

**Key Principles:**
- **Stateless agents:** Must generate and create tasks immediately after context load to preserve state
- **Infrastructure philosophy:** All tasks must align with bare metal, systemd, manual procedures, Ansible Vault standards
- **Test-driven deployment:** Tests written BEFORE execution (100% coverage requirement)
- **Team review:** ALL team members review test suite for gaps (remediation loop if needed)

**Critical Difference from Spec Phase:** Agents GENERATE tasks (not edit existing), and task file creation happens during generation (not after)

---

## HX-Infrastructure Philosophy Alignment

All tasks generated through this workflow MUST align with HX-Infrastructure deployment philosophy:

### Infrastructure Requirements
- **Bare metal first:** Production/staging deployment tasks target Ubuntu 24.04 LTS bare metal servers (not Docker)
- **Docker dev-only:** Container-based tasks allowed ONLY on hx-dev-server (192.168.10.222) for development/project isolation
- **Systemd service management:** All service installation/configuration tasks must include systemd unit creation and management
- **Manual procedures only:** Task documentation must provide step-by-step manual procedures (no automation, no Ansible playbooks)
- **Ansible Vault only:** All credential-related tasks must store secrets in Ansible Vault (no inline secrets, no local users)

### Task Generation Implications
- **William Thompson:** Primary owner of infrastructure philosophy - his tasks define deployment approach
- **Infrastructure tasks:** Must include bare metal provisioning, systemd configuration, manual procedure documentation
- **Security tasks (Frank):** Must coordinate with William for domain join, DNS, certificate tasks on bare metal
- **Testing tasks (Julia):** Must validate systemd service health, bare metal deployment success, manual procedure completeness

### Quality Gate: Infrastructure Philosophy Compliance
- Before task breakdown approval, Agent Zero validates ALL tasks comply with infrastructure philosophy
- Any task requiring Docker for production → Flag as violation, must use bare metal
- Any task automating deployment → Flag as violation, must provide manual procedure
- Any task with inline credentials → Flag as violation, must use Ansible Vault

**See also:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Infrastructure philosophy documented in specification

---

## 📋 Complete Workflow Phases

### **PHASE 0: Prerequisites Check**

**Agent Zero Validates:**
```
✓ Specification Status: APPROVED
✓ Directory Structure: Created during charter initiation
✓ Templates: Copied to appropriate directories during charter phase
✓ RAIDD Log: Updated from spec phase
✓ Backlog: Updated from spec phase  
✓ Defects Log: Reviewed (if any issues documented)
✓ Team Assignments: Documented
✓ Knowledge Vault Assignments: Documented from charter/spec phases

If ANY prerequisite missing → Block and notify CAIO
```

**Documents to Validate:**
- `/nodes/[node-name]/node-spec.md` (Status: APPROVED)
- `/nodes/[node-name]/team-assignments.md` (Team identified)
- `/nodes/[node-name]/reviews/knowledge-vault/` (Research complete)
- `/home/agent0/HX-Infrastructure/docs/raidd-log.md` (Updated from spec)
- `/home/agent0/HX-Infrastructure/docs/backlog.md` (Updated from spec)
- `/home/agent0/HX-Infrastructure/docs/defect-log.md` (Reviewed)

**Directory Structure (created during charter initiation):**
```
/nodes/[node-name]/
├── charter.md (from charter-template.md)
├── node-spec.md (from node-template.md)
├── tasks/ (directory for task files)
├── tests/ (directory structure for test suite)
│   ├── test-plan.md (from test-plan-template.md)
│   ├── test-suite-index.md (from test-suite-index-template.md)
│   ├── test-suite/ (category subdirectories)
│   │   ├── deployment/
│   │   ├── functionality/
│   │   ├── integration/
│   │   ├── health-check/
│   │   └── security/
│   └── test-executions/ (for test run records)
├── reviews/
│   ├── team-member/ (subdirs per agent)
│   └── knowledge-vault/ (research findings)
└── STATUS.md

All templates copied per standards/naming-conventions.md
Team members use templates and rename per naming conventions
```

**Note:** Agent Zero maintains state from spec phase - already has full context

✓ **GATE:** All prerequisites met → Agent Zero proceeds to Phase 1

---

### **PHASE 1: Task Structure Framework**

**Responsible:** Agent Zero (CC) ONLY

**Agent Zero Activities:**
```
1. Review approved specification:
   ├─ Technical requirements
   ├─ Architecture design
   ├─ Integration points
   ├─ Dependencies
   ├─ Success criteria
   └─ Deployment approach

2. Create task structure framework:
   ├─ Identify major work streams from spec
   ├─ Map work streams to agent expertise:
   │   • Alex → Architecture, integration tasks
   │   • Frank → Identity, DNS, security tasks  
   │   • William → OS, system, infrastructure tasks
   │   • [Drew] → Agentic patterns tasks (if applicable)
   │   • [Others] → Domain-specific tasks (if applicable)
   ├─ Define task categories:
   │   • Pre-deployment preparation
   │   • Installation & configuration
   │   • Integration setup
   │   • Post-deployment documentation
   │   • [Test Suite placeholder - handled separately]
   └─ Create initial task numbering schema

3. Document framework:
   Location: /nodes/[node-name]/tasks/task-framework.md
   Contents:
   ├─ Task categories defined
   ├─ Agent assignments to categories
   ├─ Task numbering schema: [node-name]-task-001, -002, etc.
   ├─ Placeholder for "Build Test Suite" task (to be assigned later)
   └─ Dependencies identified from spec
```

**Key Decision:**
```
Agent Zero determines task sequence BEFORE team generation:
- Pre-deployment tasks first (001-0XX)
- Installation tasks next (0XX-0XX)  
- Integration tasks after (0XX-0XX)
- Post-deployment tasks last (0XX-0XX)
- Test Suite task assigned AFTER all other tasks approved (separate phase)

Julia (Testing Agent) NOT included in initial task generation
```

**Time Estimate:** 45-60 minutes

**Output:** Task framework with clear categories, agent assignments, and numbering schema

---

### **PHASE 2: Team Member Addition (if needed)**

**Agent Zero Evaluates:**
```
Does project need additional agents beyond core team?

Examples:
- Agentic system? → Add Drew Pearson (Agentic Patterns)
- Database-heavy? → Add Patricia (PostgreSQL) or Robert (Redis)  
- Application framework? → Add Maya (Django), Laura (Node.js), etc.
- MCP integration? → Add George (FastMCP), Oliver (MCP Backend)

Decision:
- Review specification technical requirements
- Check team-assignments.md
- Add agents with relevant expertise for task generation
```

**If agents added:**
```
1. Update team-assignments.md
2. Assign task categories to new agents
3. Update task-framework.md with new agent responsibilities
4. Notify new agents to begin context loading for task generation
```

**Note:** Julia (Testing Agent) is NOT added at this phase - she joins later for test suite generation

---

### **PHASE 3: Team Context Loading + Immediate Task Generation**

**Responsible:** ALL team members (EXCEPT Agent Zero and Julia)

**CRITICAL:** This is ONE CONTINUOUS PROCESS. Stateless agents must generate and create task files immediately after loading context, otherwise they lose state.

**Each Team Member Performs:**

```
STEP 1: Context Loading (30-35 minutes)
   
   See: /home/agent0/HX-Infrastructure/procedures/context-loading-process.md - "TASK GENERATION PHASE" checklist
   
   Required reading:
   ├─ Approved charter
   ├─ Approved specification  
   ├─ Task framework from Agent Zero
   ├─ RAIDD log
   ├─ Backlog
   ├─ Defect log (if exists)
   ├─ Knowledge vault assignments
   └─ Team assignments

STEP 2: IMMEDIATE Task Generation (45-90 minutes)
   ↓ DO NOT PAUSE BETWEEN STEP 1 AND STEP 2 ↓
   
   While context is fresh:
   ├─ Review assigned task categories from framework
   ├─ Generate detailed tasks for assigned domain:
   │   • Alex → Architecture/integration tasks
   │   • Frank → Identity/DNS/security tasks
   │   • William → OS/system/infrastructure tasks
   │   • Drew → Agentic patterns tasks (if applicable)
   │   • [Others] → Domain-specific tasks
   │
   ├─ For each task generated:
   │   ├─ Define clear objective
   │   ├─ List prerequisites
   │   ├─ Detail specific steps
   │   ├─ Specify exact file paths/deliverables
   │   ├─ Identify dependencies on other tasks
   │   ├─ Mark [P] if can run in parallel
   │   ├─ Include verification steps
   │   └─ Document rollback approach
   │
   └─ IMMEDIATELY create task files:
       Location: /nodes/[node-name]/tasks/
       Naming: [node-name]-task-0XX-<description>.md
       (Use placeholder numbers - Agent Zero will renumber sequentially)

STEP 3: Document Completion (10 minutes)
   
   Location: /nodes/[node-name]/reviews/team-member/[agent-name]/task-generation-contribution.md
   
   Document:
   ├─ Tasks generated (list with placeholders)
   ├─ Dependencies identified
   ├─ Parallel execution markers [P] applied
   ├─ Integration points noted
   └─ Questions/concerns for Agent Zero
```

**Why Continuous Process?**
```
❌ WRONG: Load context → Wait → Generate tasks later
   Result: Agent loses state, must reload context again

✅ CORRECT: Load context → Immediately generate tasks → Create files → Complete
   Result: Agent maintains fresh context throughout task generation
```

**Task Generation Template:**
```markdown
# Task: [Brief Description]

**Task ID**: [node-name]-task-0XX-[description] (placeholder)
**Phase**: [Pre-Deployment|Installation|Integration|Post-Deployment]
**Assigned To**: [agent-name]
**Status**: Not Started
**Dependencies**: [Task IDs this depends on - use placeholders]
**Can Run in Parallel**: [Yes [P] | No]
**Estimated Time**: [time estimate]

## Objective
[What this task accomplishes - specific and measurable]

## Prerequisites
- [ ] [Required condition 1]
- [ ] [Required condition 2]
- [ ] [Dependency on other task]

## Steps
1. [Detailed step 1 with exact commands/paths]
2. [Detailed step 2 with exact commands/paths]
3. [Detailed step 3 with exact commands/paths]

## Deliverables
- [Specific file/config/service created]
- [Exact location/path]

## Verification Steps
- [ ] [How to verify task completed successfully]
- [ ] [Expected output/state]
- [ ] [Validation command]

## Rollback Procedure
[How to undo this task if needed - specific steps]

## Integration Points
[How this task integrates with other tasks]

## Notes
[Any additional context, decisions made, or considerations]
```

**Contribution Documentation Template:**
```markdown
# Task Generation Contribution: [Agent Name]
**Agent:** [agent-name]
**Date:** [YYYY-MM-DD]
**Phase:** Task Generation
**Context Load Time:** [X minutes]
**Task Generation Time:** [Y minutes]
**Total Time:** [X+Y minutes]

## Context Loading Confirmed
- [x] Approved charter
- [x] Approved specification
- [x] Task framework
- [x] RAIDD log
- [x] Backlog
- [x] Defect log (if exists)
- [x] Knowledge vault assignments
- [x] Team assignments
- [x] IMMEDIATELY proceeded to task generation (no pause)

## Task Categories Assigned
- [Category 1]: [Purpose]
- [Category 2]: [Purpose]

## Tasks Generated
| Placeholder ID | Description | Phase | Parallel? | Dependencies |
|---------------|-------------|-------|-----------|-------------|
| [node]-task-0XX | [description] | [phase] | [P] or No | [deps] |
| [node]-task-0XX | [description] | [phase] | [P] or No | [deps] |

## Dependencies Identified
1. [Task X] depends on [Task Y] because [reason]
2. [Task A] depends on [Task B] because [reason]

## Integration Points
1. [How my tasks integrate with Alex's architecture tasks]
2. [How my tasks integrate with Frank's security tasks]

## Parallel Execution Opportunities
- Tasks [list] can run in parallel because [reason]
- Tasks [list] must be sequential because [reason]

## Questions for Agent Zero or Team
1. [Question about dependency]
2. [Question about sequencing]

## Concerns Raised
1. [Concern with rationale]
2. [Risk identified]
```

**Agent Zero tracks:**
```
Waiting for task generation from:
[ ] Alex
[ ] Frank  
[ ] William
[ ] Drew Pearson (if applicable)
[ ] [Others]

Note: Julia (Testing Agent) NOT in this phase - comes later

All contributions received? → Proceed to Phase 4
```

---

### **PHASE 4: Agent Zero Synthesis & Sequencing**

**Responsible:** Agent Zero (CC) ONLY

**Agent Zero Activities:**
```
1. Collect all generated tasks:
   ├─ Read all task files from /nodes/[node-name]/tasks/
   ├─ Read all contribution documents
   ├─ Compile complete task inventory
   └─ Note all dependencies, concerns, questions

2. Resolve conflicts and overlaps:
   ├─ Identify duplicate tasks (same objective, different authors)
   ├─ Merge or eliminate duplicates
   ├─ Resolve conflicting approaches
   ├─ Document resolution decisions in RAIDD log
   └─ Clarify ambiguous dependencies

3. Sequence tasks by dependencies:
   ├─ Build dependency graph
   ├─ Identify critical path
   ├─ Group parallel tasks [P]
   ├─ Ensure proper ordering:
   │   • Pre-deployment first
   │   • Installation after pre-deployment
   │   • Configuration after installation
   │   • Integration after configuration
   │   • Post-deployment last
   └─ Validate no circular dependencies

4. Renumber tasks sequentially:
   ├─ Assign final task numbers: [node-name]-task-001, -002, -003...
   ├─ Update all task files with correct numbers
   ├─ Update all dependency references
   └─ Update parallel execution groupings

5. Add "Build Test Suite" task:
   ├─ Insert at appropriate point (after core tasks, before final deployment)
   ├─ Assign to Julia (Testing Agent)
   ├─ Task ID: [node-name]-task-0XX-build-test-suite.md
   ├─ Mark as depends on: All core installation/configuration tasks
   ├─ Will trigger Julia's sub-workflow (Phase 7)
   └─ Does NOT include individual test creation tasks (Julia generates those)

6. Create task breakdown summary:
   Location: /nodes/[node-name]/tasks/task-breakdown-summary.md
   Contents:
   ├─ Complete task list (numbered)
   ├─ Dependency graph visualization
   ├─ Parallel execution groups
   ├─ Critical path identified
   ├─ Time estimates (per task and total)
   ├─ Agent assignments
   └─ Key integration points

7. Prepare clarification questions:
   ├─ Identify areas needing CAIO decision
   ├─ Note conflicting recommendations
   ├─ Flag high-risk dependencies
   └─ Document trade-offs requiring approval
```

**Synthesis Checklist:**
```
- [ ] All agent tasks collected
- [ ] Duplicates resolved
- [ ] Tasks sequenced by dependencies
- [ ] Tasks renumbered sequentially  
- [ ] Parallel tasks marked [P]
- [ ] "Build Test Suite" task added
- [ ] Integration points validated
- [ ] Dependency graph created
- [ ] Summary document created
- [ ] Clarification questions prepared
```

**Time Estimate:** 2-4 hours

**Output:** Complete, sequenced, numbered task breakdown ready for CAIO review

---

### **PHASE 5: Clarification Questions to CAIO**

**Agent Zero presents questions requiring CAIO decisions:**

```
DEPENDENCY QUESTIONS:
Q1. [Task sequencing question - which approach?]
Q2. [Dependency conflict - how to resolve?]

SCOPE QUESTIONS:
Q3. [Task scope ambiguity - include or defer?]
Q4. [Integration approach - option A or B?]

RISK QUESTIONS:
Q5. [High-risk task - mitigation approach?]
Q6. [Resource constraint - adjustment needed?]

TIMELINE QUESTIONS:
Q7. [Critical path concerns - acceptable?]
Q8. [Parallel execution limits - realistic?]
```

**CAIO Response:**
```
- Answers all questions
- Makes decisions on conflicts
- Approves trade-offs
- Confirms sequencing approach
- May request adjustments to task breakdown
```

**Agent Zero Actions:**
```
- Incorporate CAIO decisions
- Update task files as needed
- Update dependency graph
- Update summary document
- Mark questions as resolved
- Prepare final task breakdown for approval
```

**Time Estimate:** 1-2 hours (including CAIO response time)

---

### **PHASE 6: Final Review & Approval**

**CAIO Reviews:**
```
Reviews complete task breakdown:
├─ Task breakdown summary
├─ Dependency graph
├─ Individual task files (sample review)
├─ Critical path analysis
├─ Time estimates
├─ Resource requirements
└─ Integration approach

Approval criteria:
├─ All tasks clearly defined
├─ Dependencies logical and complete
├─ No P0/P1 unresolved issues
├─ Sequencing makes sense
├─ Parallel execution marked appropriately
├─ "Build Test Suite" task properly positioned
├─ Integration points clear
└─ Ready for execution
```

**Approval Loop:**
```
IF CAIO requests changes:
   ├─ Agent Zero makes adjustments
   ├─ Updates affected task files
   ├─ Updates summary and dependencies
   └─ Resubmit for approval
   
LOOP until CAIO satisfied
```

**CAIO Final Approval:**
```
"Task breakdown approved"

Agent Zero Actions:
├─ Update task-breakdown-summary.md:
│   ├─ Status: Draft → Approved
│   ├─ Approval date
│   └─ Approval signature
├─ Lock task sequence (no changes without re-approval)
└─ Prepare for test suite generation phase
```

✓ **GATE:** Task Breakdown Approved → Proceed to Test Suite Generation (Phase 7)

---

### **PHASE 7: Test Suite Generation (SUB-WORKFLOW)**

**Trigger:** Task breakdown approved by CAIO  
**Responsible:** Julia (Testing Agent) + Agent Zero for review

**⚠️ CRITICAL PROCESS DOCUMENT: Julia MUST follow `testing-knowledge-research-process.md` during STEP 1**

**PURPOSE:** Generate complete test suite AFTER knowing all deployment tasks

**Why Separate Phase:**
```
- Testing requires knowledge of ALL deployment tasks
- Tests must validate every installation, configuration, integration task
- Test plan must cover complete system deployment
- Cannot create comprehensive tests without knowing full scope
- Julia needs complete context: Charter + Spec + ALL Tasks
```

**Julia's Sub-Workflow:**

```
STEP 1: Context Loading for Test Suite (30-40 minutes)
   
   Julia loads complete context:
   ├─ Approved charter (goals, success criteria)
   ├─ Approved specification (requirements, architecture)
   ├─ Approved task breakdown (ALL tasks)
   ├─ Task dependencies and sequencing
   ├─ Integration points
   ├─ RAIDD log (risks to test for)
   ├─ Defect log (known issues to verify)
   └─ Knowledge vault repositories (CRITICAL):
       **FOLLOW: testing-knowledge-research-process.md**
       
       Systematic research process:
       ├─ Identify primary knowledge repositories
       ├─ Locate testing directories and files
       ├─ Analyze testing structure and patterns
       ├─ Extract test examples (basic, integration, error, mocking)
       ├─ Identify testing best practices
       └─ Document comprehensive findings
       
       Research outputs:
       ├─ Testing framework identified (pytest, jest, junit, etc.)
       ├─ Testing tools documented (mocking, coverage, CI/CD)
       ├─ Test organization structure defined
       ├─ Test patterns extracted (at least 3 examples)
       ├─ Pre-built tests identified for leverage/adaptation
       ├─ Coverage requirements documented
       └─ Testing strategy defined
   
   CRITICAL: Julia MUST follow testing-knowledge-research-process.md to:
   • Systematically research knowledge vault repos
   • Identify recommended testing tools for the technology
   • Locate example test files that demonstrate proper testing
   • Extract test case patterns used in the technology's repo
   • Document best practices for testing this specific technology
   • Find pre-built tests we can leverage or adapt
   • Identify gaps or areas commonly missed in testing
   
   Example: If working with MCP technology, research MCP repo for:
   • Example test files showing how to test MCP servers
   • Test patterns used by the MCP developers
   • Tools recommended for MCP testing (pytest plugins, etc.)
   • Test coverage approaches in MCP examples
   • Pre-built MCP tests we can adapt
   
   Documentation Required:
   Location: /nodes/[node-name]/reviews/team-member/julia/testing-knowledge-research.md
   (See testing-knowledge-research-process.md for template)

STEP 2: IMMEDIATE Test Suite Generation (90-120 minutes)
   ↓ DO NOT PAUSE - CONTINUOUS PROCESS ↓
   
   Julia generates complete test suite using insights from knowledge vault:
   
   A. Create Test Plan:
      Location: /nodes/[node-name]/tests/test-plan.md
      (Use test-plan-template.md, rename per naming-conventions.md)
      
      Contents:
      ├─ Test strategy (TDD approach)
      ├─ Test tools (from knowledge vault research)
      ├─ Test categories:
      │   • Deployment validation tests
      │   • Functionality tests  
      │   • Integration tests
      │   • Health check tests
      │   • Security tests (if applicable)
      ├─ Test coverage matrix (maps tests to tasks)
      ├─ Test execution sequence
      ├─ Reference to knowledge vault examples
      └─ Success criteria from charter/spec
   
   B. Create Test Suite Index:
      Location: /nodes/[node-name]/tests/test-suite-index.md
      (Use test-suite-index-template.md, rename per naming-conventions.md)
      Contents:
      ├─ Complete test inventory
      ├─ Test organization by category
      ├─ Test ID numbering schema
      └─ Test dependencies
   
   C. Generate Individual Test Cases:
      Location: /nodes/[node-name]/tests/test-suite/[category]/
      (Use test-case-template.md, rename per naming-conventions.md)
      
      For EACH deployment task, create corresponding test(s):
      
      Example mapping:
      • Task: Install PostgreSQL 
        → Test: tc-[node]-deployment-001-verify-postgres-installation.md
      
      • Task: Configure Ollama service
        → Test: tc-[node]-deployment-002-verify-ollama-config.md
      
      • Task: Setup Redis connection
        → Test: tc-[node]-integration-001-verify-redis-connection.md
      
      Each test case file includes:
      ├─ Test objective (what it validates)
      ├─ Prerequisites (what must be done first)
      ├─ Test steps (detailed procedure)
      ├─ Expected results
      ├─ Pass/fail criteria
      ├─ Maps to specific task ID(s)
      ├─ Maps to spec requirement(s)
      └─ Reference to knowledge vault examples (if applicable)
   
   D. Create Test Execution Templates:
      Location: /nodes/[node-name]/tests/test-executions/
      (Use test-execution-template.md for format)
      Template for recording test runs during deployment

STEP 3: Document Test Suite Generation (10 minutes)
   
   Location: /nodes/[node-name]/reviews/team-member/julia/test-suite-generation.md
   
   Document:
   ├─ Knowledge vault research completed:
   │   ├─ Repos reviewed for test guidance
   │   ├─ Test tools identified from repos
   │   ├─ Example test files reviewed
   │   ├─ Test patterns extracted
   │   └─ Best practices incorporated
   ├─ Test plan created
   ├─ Test suite index created  
   ├─ Test cases generated (count by category)
   ├─ Coverage matrix (tasks → tests mapping)
   ├─ Test dependencies
   ├─ Test tools selected (from knowledge vault)
   └─ Verification approach
```

**Test Case Template (Julia uses):**
```markdown
# Test Case: [Test Description]

**Test ID**: tc-[node]-[category]-###-[description]
**Category**: [deployment|functionality|integration|health-check|security]
**Status**: Not Run
**Maps to Task(s)**: [task-ID-list]
**Maps to Spec**: [spec section reference]
**Maps to Charter**: [success criteria reference]

## Test Objective
[What this test validates - clear and measurable]

## Prerequisites
- [ ] Task [ID] completed: [description]
- [ ] Task [ID] completed: [description]
- [ ] [Environment state required]

## Test Steps
1. [Detailed test step 1]
2. [Detailed test step 2]
3. [Detailed test step 3]

## Expected Results
- [ ] [Expected outcome 1]
- [ ] [Expected outcome 2]
- [ ] [Expected outcome 3]

## Pass/Fail Criteria
**PASS IF:**
- All expected results achieved
- [Specific condition 1]
- [Specific condition 2]

**FAIL IF:**
- Any expected result not achieved
- [Specific failure condition]

## Actual Results
[To be filled during test execution]

## Test Execution Log
[Reference to test execution document when run]

## Notes
[Dependencies on other tests, special considerations]
```

**Team Review of Test Suite:**

```
After Julia completes test suite generation:

PHASE 7A: ALL Team Members Review Test Suite

Responsible: ALL team members (Alex, Frank, William, Drew, etc.)

Each team member reviews:
├─ Test plan (strategy and tools)
├─ Test suite index (inventory)
├─ Test cases in their domain
├─ Coverage for their generated tasks
└─ Integration test coverage

Review checklist (per team member):
- [ ] All my tasks have corresponding tests
- [ ] Test cases cover all success criteria in my domain
- [ ] Test tools appropriate for the technology
- [ ] Test steps are clear and executable
- [ ] Expected results are measurable
- [ ] Integration points are tested
- [ ] No gaps in test coverage for my domain
- [ ] Tests leverage best practices from knowledge vault

Document reviews:
Location: /nodes/[node-name]/reviews/team-member/[agent-name]/test-suite-review.md

Each agent documents:
├─ Tests reviewed
├─ Coverage assessment
├─ Gaps identified (if any)
├─ Issues found (if any)
├─ Recommendations (if any)
└─ Approval or concerns

```

**Remediation Loop (if gaps/issues found):**

```
If ANY team member identifies gaps or issues:

1. Agent Zero collects all review feedback:
   ├─ Read all test-suite-review.md files
   ├─ Compile list of gaps and issues
   ├─ Categorize by severity (P0/P1 vs P2/P3)
   └─ Prioritize by impact

2. Agent Zero routes to Julia for remediation:
   ├─ Provide consolidated feedback
   ├─ Highlight critical gaps (P0/P1)
   ├─ Specify what needs to be added/fixed
   └─ Set timeline for remediation

3. Julia remediates:
   ├─ Address all P0/P1 gaps (critical)
   ├─ Address P2/P3 issues (important)
   ├─ Add missing test cases
   ├─ Fix issues in existing tests
   ├─ Update test plan/index if needed
   └─ Document changes made

4. Julia notifies Agent Zero:
   ├─ Lists all changes made
   ├─ References team feedback addressed
   └─ Confirms remediation complete

5. Agent Zero reviews remediation:
   ├─ Verify all gaps addressed
   ├─ Check all issues resolved
   ├─ Validate test coverage now complete
   └─ If issues remain → Loop back to Julia
   
LOOP until Agent Zero confirms all gaps/issues resolved
```

**Agent Zero Final Review of Test Suite:**

```
After team review and remediation (if needed):

1. Agent Zero final validation:
   ├─ Test plan completeness
   ├─ Test coverage (every task has test(s))
   ├─ All team gaps addressed
   ├─ All team issues resolved
   ├─ Test dependencies logical
   ├─ Test execution sequence valid
   └─ Test cases follow TDD approach

2. Comprehensive checklist:
   - [ ] Every deployment task has validation test
   - [ ] Every configuration task has verification test
   - [ ] Integration points have integration tests
   - [ ] Health checks included
   - [ ] Test plan references charter success criteria
   - [ ] Test suite index complete
   - [ ] Test cases use proper templates and naming conventions
   - [ ] All team review feedback addressed
   - [ ] No unresolved P0/P1 gaps or issues
   - [ ] Knowledge vault best practices incorporated

3. Agent Zero approval decision:
   IF all criteria met:
      ├─ Test suite complete and comprehensive
      ├─ Ready for CAIO review
      └─ Proceed to CAIO approval
   
   IF criteria NOT met:
      ├─ Route back to Julia for additional remediation
      └─ Loop until criteria met
```

**CAIO Approval of Test Suite:**

```
CAIO reviews:
├─ Test plan (strategy and coverage)
├─ Test suite index (complete inventory)
├─ Sample test cases (quality check)
└─ Coverage matrix (tasks to tests mapping)

Approval criteria:
├─ 100% task coverage (per testing-requirements.md)
├─ TDD approach followed (tests before execution)
├─ Success criteria from charter tested
├─ All requirements from spec tested
└─ No P0/P1 gaps in test coverage

CAIO: "Test suite approved"

Agent Zero Actions:
├─ Update test-plan.md status: Draft → Approved
├─ Lock test suite (no changes without re-approval)
└─ Test suite ready for execution phase
```

**Time Estimate for Phase 7:** 
- Julia's test suite generation: 2-3 hours
- Team review: 1-2 hours (can be parallel)
- Remediation (if needed): 1-2 hours
- Agent Zero final review: 30 minutes
- CAIO approval: 30 minutes
- **Total: 4-8 hours** (depends on gaps found)

✓ **GATE:** Test Suite Approved → Proceed to Post-Approval Updates (Phase 8)

---

### **PHASE 8: Post-Approval Updates**

**Responsible:** Agent Zero (CC) ONLY

**Agent Zero Activities:**

```
1. Review and Update RAIDD Log:
   Location: /home/agent0/HX-Infrastructure/docs/raidd-log.md
   
   Add entries based on task breakdown:
   ├─ RISKS from task dependencies:
   │   • Critical path risks
   │   • Integration point risks
   │   • Resource constraints
   │   • Technical complexity risks
   │
   ├─ ASSUMPTIONS from task sequencing:
   │   • Parallel execution assumptions
   │   • Dependency assumptions
   │   • Time estimate assumptions
   │   • Resource availability assumptions
   │
   ├─ ISSUES discovered during task generation:
   │   • Conflicts that were resolved
   │   • Ambiguities that needed clarification
   │   • Technical constraints
   │
   ├─ DEPENDENCIES from task analysis:
   │   • External service dependencies
   │   • Infrastructure dependencies
   │   • Data dependencies
   │   • Team dependencies
   │
   └─ DECISIONS made during synthesis:
       • Sequencing decisions
       • Approach selections
       • Trade-off decisions
       • Scope decisions

2. Review and Update Backlog:
   Location: /home/agent0/HX-Infrastructure/docs/backlog.md
   
   Add deferred items:
   ├─ Tasks identified but deferred (out of initial scope)
   ├─ Optimizations to consider later
   ├─ Nice-to-have features mentioned
   ├─ Future enhancement opportunities
   └─ Reference task breakdown and spec

3. Review and Update Defect Log (if applicable):
   Location: /home/agent0/HX-Infrastructure/docs/defect-log.md
   
   If task generation revealed issues:
   ├─ Document any spec ambiguities discovered
   ├─ Note any charter gaps found
   ├─ Record clarifications that should have been in spec
   └─ Reference node/task for context

4. Update Project Status:
   Location: /nodes/[node-name]/STATUS.md
   
   Update status:
   ├─ Phase: Specification → Task Breakdown → Test Suite → Ready for Execution
   ├─ Task Breakdown: APPROVED
   ├─ Test Suite: APPROVED
   ├─ Date approved
   ├─ Total tasks: [count]
   ├─ Estimated time: [total]
   └─ Next phase: Execution

5. Create Execution Readiness Checklist:
   Location: /nodes/[node-name]/execution-readiness.md
   
   Checklist:
   - [ ] All tasks defined and numbered
   - [ ] All dependencies documented
   - [ ] Test suite complete (100% coverage)
   - [ ] RAIDD log updated
   - [ ] Backlog updated
   - [ ] Defect log reviewed
   - [ ] Resource requirements identified
   - [ ] Prerequisites verified
   - [ ] Execution sequence validated
   - [ ] Rollback procedures documented (per task)

6. Prepare for Execution Phase:
   ├─ Task breakdown locked and approved
   ├─ Test suite locked and approved
   ├─ All artifacts updated
   ├─ Ready to begin execution
   └─ Next: Execute tasks per approved sequence
```

**Time Estimate:** 30-45 minutes

**Output:** All centralized artifacts updated, task breakdown and test suite approved and locked, ready for execution phase

---

## 📊 Workflow Visualization

```
┌─────────────────────────────────────────────┐
│ PHASE 0: Prerequisites Check                │
│ Agent Zero validates all inputs             │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 1: Task Structure Framework           │
│ Agent Zero creates framework and categories │
│ Time: 45-60 min                             │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 2: Team Addition (if needed)          │
│ Agent Zero adds project-specific agents     │
│ NOTE: Julia NOT added yet (comes Phase 7)   │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 3: Context Load + Task Generation     │
│ Team loads context and IMMEDIATELY          │
│ generates tasks for their domain            │
│ CONTINUOUS PROCESS (no pause)               │
│ Time: 75-125 min per agent (parallel)       │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 4: Agent Zero Synthesis               │
│ Sequence, number, resolve conflicts         │
│ Add "Build Test Suite" task placeholder     │
│ Time: 2-4 hours                             │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 5: Clarification Questions            │
│ Agent Zero asks CAIO for decisions          │
│ Time: 1-2 hours (includes CAIO response)    │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 6: Final Review & Approval            │
│ CAIO reviews and approves task breakdown    │
│ Loop until approved                         │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 7: Test Suite Generation              │
│ Julia loads context (Charter+Spec+Tasks)    │
│ Researches knowledge vault for test tools   │
│ IMMEDIATELY generates complete test suite   │
│ CONTINUOUS PROCESS (no pause)               │
│ → TEAM REVIEWS test suite (all members)     │
│ → Remediation loop (if gaps found)          │
│ → Agent Zero final review                   │
│ → CAIO approves                             │
│ Time: 4-8 hours                             │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ PHASE 8: Post-Approval Updates              │
│ Agent Zero updates RAIDD/Backlog/Defects    │
│ Time: 30-45 minutes                         │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ COMPLETE: Ready for Execution Phase         │
└─────────────────────────────────────────────┘
```

---

## ⏱️ Time Estimates

| Phase | Time | Who | Can Parallel? |
|-------|------|-----|---------------|
| 0. Prerequisites | 15 min | Agent Zero | No |
| 1. Task Framework | 45-60 min | Agent Zero | No |
| 2. Team Addition | 15 min | Agent Zero | No |
| 3. Context + Task Gen | 75-125 min | All agents (except Julia) | Yes (CONTINUOUS) |
| 4. Synthesis | 2-4 hours | Agent Zero | No |
| 5. Clarification | 1-2 hours | Agent Zero + CAIO | No |
| 6. Review/Approval | 1 hour | CAIO | No |
| 7. Test Suite Gen | 4-8 hours | Julia + Team + reviews | Partial (team review parallel) |
| 8. Post-Approval | 30-45 min | Agent Zero | No |

**Total Sequential Time:** ~10-17 hours  
**Total Parallel-Optimized:** ~9-15 hours (Phase 3 agents work in parallel, Phase 7 team review parallel)

**Note:** Times assume:
- Clear approved specification
- Complete knowledge from charter/spec phases
- No major conflicts in task generation
- Efficient team coordination
- **Phases 3 and 7 are continuous (no break between context load and generation)**
- **Phase 7 includes team review and potential remediation loop**

---

## ✅ Quality Gates

**Gate 1: Prerequisites Complete**
- Specification approved ✓
- RAIDD/Backlog/Defects updated from spec ✓
- Team assignments documented ✓
- Knowledge vault assignments documented ✓

**Gate 2: Framework Ready**
- Task categories defined ✓
- Agent assignments made ✓
- Numbering schema established ✓
- "Build Test Suite" placeholder created ✓

**Gate 3: Team Task Generation Complete**
- All agents completed continuous context-load-and-generate ✓
- All domain tasks created ✓
- No break between context load and task generation ✓

**Gate 4: Synthesis Complete**
- Tasks sequenced properly ✓
- Tasks numbered sequentially ✓
- Dependencies validated ✓
- Conflicts resolved ✓
- Summary document created ✓

**Gate 5: Clarification Complete**
- All CAIO questions answered ✓
- Decisions incorporated ✓

**Gate 6: Task Breakdown Approval**
- CAIO approved ✓
- No P0/P1 unresolved issues ✓
- Ready for test suite generation ✓

**Gate 7: Test Suite Complete**
- Julia researched knowledge vault for test tools/examples ✓
- Julia generated complete test suite (continuous) ✓
- ALL team members reviewed test suite ✓
- Remediation completed (if gaps found) ✓
- Agent Zero final review and approval ✓
- CAIO approved ✓
- 100% task coverage ✓
- TDD approach followed ✓
- Templates used and renamed per naming-conventions.md ✓

**Gate 8: Artifacts Updated**
- RAIDD log updated ✓
- Backlog updated ✓
- Defect log updated (if needed) ✓
- Status updated ✓
- Execution readiness confirmed ✓

---

## 🚨 Issue Escalation

**If issues arise during task generation:**

### **P0/P1 Critical Issues:**
```
Examples:
- Fundamental conflict with specification
- Missing critical dependency discovered
- Technical impossibility identified
- Circular dependency in tasks

Action:
1. Agent identifies issue during task generation
2. Agent documents in contribution
3. Agent Zero reviews during synthesis
4. Agent Zero escalates to CAIO immediately
5. May require spec revision
6. Pause task workflow until resolved
7. Resume when resolution clear
```

### **P2/P3 Non-Critical Issues:**
```
Examples:
- Task sequencing question
- Resource estimation uncertainty
- Minor technical approach debate
- Optimization opportunity

Action:
1. Agent documents in contribution
2. Agent Zero evaluates during synthesis
3. Agent Zero makes decision or asks CAIO in clarification phase
4. Documents decision in RAIDD log
5. Continue task workflow
```

---

## 📁 Review Storage Structure

```
/nodes/[node-name]/
├── tasks/
│   ├── task-framework.md (Agent Zero creates)
│   ├── task-breakdown-summary.md (Agent Zero creates)
│   ├── [node-name]-task-001-<description>.md
│   ├── [node-name]-task-002-<description>.md
│   ├── [node-name]-task-003-<description>.md
│   ├── ...
│   └── [node-name]-task-0XX-build-test-suite.md (triggers Julia)
│
├── tests/
│   ├── test-plan.md (Julia creates)
│   ├── test-suite-index.md (Julia creates)
│   ├── test-suite/
│   │   ├── deployment/
│   │   │   ├── tc-[node]-deployment-001-*.md
│   │   │   ├── tc-[node]-deployment-002-*.md
│   │   │   └── ...
│   │   ├── functionality/
│   │   │   ├── tc-[node]-functionality-001-*.md
│   │   │   └── ...
│   │   ├── integration/
│   │   │   ├── tc-[node]-integration-001-*.md
│   │   │   └── ...
│   │   ├── health-check/
│   │   │   ├── tc-[node]-health-001-*.md
│   │   │   └── ...
│   │   └── security/ (if applicable)
│   │       └── tc-[node]-security-001-*.md
│   │
│   └── test-executions/
│       └── [YYYY-MM-DD]-tc-[node]-[category]-###-r[N].md
│
└── reviews/
    ├── team-member/
    │   ├── alex/
    │   │   ├── context-load-tasks.md
    │   │   └── task-generation-contribution.md
    │   ├── frank/
    │   │   ├── context-load-tasks.md
    │   │   └── task-generation-contribution.md
    │   ├── william/
    │   │   ├── context-load-tasks.md
    │   │   └── task-generation-contribution.md
    │   ├── drew-pearson/ (if added)
    │   │   ├── context-load-tasks.md
    │   │   └── task-generation-contribution.md
    │   └── julia/
    │       ├── context-load-test-suite.md
    │       ├── testing-knowledge-research.md (CRITICAL - from testing-knowledge-research-process.md)
    │       └── test-suite-generation.md
    │
    └── knowledge-vault/
        └── [date]-research-findings.md (from charter)
```

---

## Claude Code Command Infrastructure Integration

### How Commands Invoke This Workflow

**Set 1: Workflow Commands (Primary Integration)**
- **`cc-task-workflow.md`:** Primary command that implements this entire workflow
  - Invokes this procedure for systematic task breakdown execution
  - Coordinates all 8 phases from prerequisites through post-approval updates
  - Integrates Phase 7 (test suite generation sub-workflow)
  - Enforces infrastructure philosophy compliance throughout

**Set 3: Utility Commands (Supporting Tools)**
- **`artifact-tracker`:** Tracks all task files and test cases generated (deliverable tracking)
- **`doc-lint`:** Validates task file format, naming conventions, template usage
- **`status-report`:** Reports progress through 8 phases, team contribution status
- **`raidd`:** Updates RAIDD log in Phase 8 with task-related risks, decisions, dependencies

**Set 4: Phase Commands (Sub-Workflows)**
- **`cc-phase-knowledge-research.md`:** Julia uses for testing knowledge vault research (Phase 7 STEP 1)
- **`cc-phase-test-suite-generation.md`:** Julia's test suite generation process (Phase 7)
- **`cc-phase-task-result-doc.md`:** Documents task generation results for each team member

**Set 5: Agent Orchestration (Multi-Agent Coordination)**
- **`cc-orchestrate-alex.md`:** Coordinates Alex's architecture task generation (Phase 3)
- **`cc-orchestrate-frank.md`:** Coordinates Frank's security/identity task generation (Phase 3)
- **`cc-orchestrate-william.md`:** Coordinates William's infrastructure task generation (Phase 3)
- **`cc-orchestrate-julia.md`:** Coordinates Julia's test suite generation (Phase 7)
- **`cc-agent-zero-synthesis.md`:** Meta-orchestration for Phase 4 synthesis and conflict resolution

### Command Workflow Integration Pattern

```
User: "Generate task breakdown for hx-webui-server"
↓
cc-task-workflow.md (Set 1) executes this procedure
↓
PHASE 0-2: Agent Zero validates prerequisites and creates framework
↓
PHASE 3: Team task generation
├─ cc-orchestrate-alex.md (Set 5) → Alex generates architecture tasks
├─ cc-orchestrate-frank.md (Set 5) → Frank generates security tasks
├─ cc-orchestrate-william.md (Set 5) → William generates infrastructure tasks
└─ cc-phase-task-result-doc.md (Set 4) → Documents contributions
↓
PHASE 4: Agent Zero synthesis
└─ cc-agent-zero-synthesis.md (Set 5) → Resolves conflicts, sequences tasks
↓
PHASE 5-6: Clarification and approval
└─ artifact-tracker (Set 3) → Tracks all task files generated
↓
PHASE 7: Test suite generation
├─ cc-orchestrate-julia.md (Set 5) → Coordinates Julia
├─ cc-phase-knowledge-research.md (Set 4) → Julia researches knowledge vault
├─ cc-phase-test-suite-generation.md (Set 4) → Julia generates test suite
└─ Team review → Remediation loop → Agent Zero review → CAIO approval
↓
PHASE 8: Post-approval updates
├─ raidd (Set 3) → Updates RAIDD log with task risks/decisions
├─ status-report (Set 3) → Updates project status
└─ doc-lint (Set 3) → Validates all task and test files
```

---

## 🔗 Related Documents

**Core Workflows:**
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team structure and roles
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Context loading checklists
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Charter creation workflow (Phase 1)
- `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Specification workflow (Phase 2)
- `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md` - Task execution workflow (Phase 4 - follows this)
- `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` - Project closeout workflow (Phase 5 - final)

**Testing Processes:**
- **`testing-knowledge-research-process.md`** - **CRITICAL: Julia must follow this for Phase 7 STEP 1**

**Claude Code Commands:**
- **Set 1:** `.claude/commands/workflows/cc-task-workflow.md` - Primary workflow command
- **Set 3:** `.claude/commands/utilities/` - Supporting utilities (artifact-tracker, doc-lint, status-report, raidd)
- **Set 4:** `.claude/commands/phases/` - Sub-workflow commands (knowledge-research, test-suite-generation, task-result-doc)
- **Set 5:** `.claude/commands/agents/` - Agent orchestration commands (alex, frank, william, julia, agent-zero-synthesis)

**Templates:**
- Task Template: (individual task files use inline template provided in this document)
- Service Tasks Template: `/home/agent0/HX-Infrastructure/templates/service-tasks-template.md` (reference for task structure)
- Test Plan Template: `/home/agent0/HX-Infrastructure/templates/test-plan-template.md`
- Test Case Template: `/home/agent0/HX-Infrastructure/templates/test-case-template.md`
- Test Execution Template: `/home/agent0/HX-Infrastructure/templates/test-execution-template.md`
- Test Suite Index Template: `/home/agent0/HX-Infrastructure/templates/test-suite-index-template.md`

**Standards:**
- `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - File naming and template usage (CRITICAL for Phase 3 and 7)
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage requirement (CRITICAL for Phase 7)
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Task documentation standards
- `/home/agent0/HX-Infrastructure/standards/architecture-standards.md` - Architecture task requirements

**Agent Documentation:**
- `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` - Core Team and Technology SME agents (authoritative list)
- `/home/agent0/HX-Infrastructure/hx-agents/hx-orchestration-guide.md` - Multi-agent coordination patterns
- **Agent Profiles:**
  - `.claude/agents/william.md` - Infrastructure specialist (bare metal, systemd, manual procedures)
  - `.claude/agents/alex.md` - Platform architect (architecture, integration)
  - `.claude/agents/frank.md` - Security specialist (identity, DNS, credentials)
  - `.claude/agents/julia.md` - Testing & quality specialist (test-driven deployment, 100% coverage)

---

## 📋 Success Criteria

**Task breakdown is successful when:**

1. ✅ All domain tasks generated by respective experts
2. ✅ Tasks properly sequenced with clear dependencies
3. ✅ Tasks numbered sequentially per naming-conventions.md
4. ✅ Parallel execution opportunities identified [P]
5. ✅ Templates used and renamed per standards/naming-conventions.md
6. ✅ "Build Test Suite" task properly positioned
7. ✅ Julia researched knowledge vault for test tools/examples/patterns
8. ✅ Test suite comprehensive (100% task coverage)
9. ✅ Test suite follows TDD approach (tests before execution)
10. ✅ Test suite leverages best practices from knowledge vault
11. ✅ All charter success criteria have corresponding tests
12. ✅ All spec requirements have corresponding tests
13. ✅ ALL team members reviewed test suite
14. ✅ All test gaps/issues remediated
15. ✅ No P0/P1 unresolved issues
16. ✅ Agent Zero final approval (task breakdown AND test suite)
17. ✅ CAIO approved (task breakdown AND test suite)
18. ✅ All artifacts updated (RAIDD, Backlog, Defects)
19. ✅ Ready for execution phase

---

## 🔑 Key Differences from Spec Workflow

### **Task Generation vs. Spec Editing:**
```
Spec Workflow:
- Agent Zero creates draft spec
- Team members EDIT existing spec
- Continuous: Load context → Edit → Complete

Task Workflow:
- Agent Zero creates framework
- Team members GENERATE new tasks (not edit)
- Continuous: Load context → Generate → Create files → Complete
```

### **Testing Approach:**
```
Spec Workflow:
- Julia participates in spec editing
- Testing requirements embedded in spec

Task Workflow:
- Julia NOT in initial task generation
- Julia joins AFTER task approval (Phase 7)
- Julia researches knowledge vault for test tools/examples/patterns
- Generates complete test suite as sub-workflow
- Needs full context: Charter + Spec + ALL Tasks
- Test suite generation is separate, continuous process
- ALL team members review test suite for gaps
- Remediation loop if gaps/issues found
- Agent Zero final review before CAIO approval
```

### **File Creation Timing:**
```
Spec Workflow:
- One file (spec) edited by multiple agents
- File exists before team edits

Task Workflow:
- Multiple files (tasks) created by agents
- Files created DURING generation (not after)
- Each agent creates their own task files
- Prevents state loss for stateless agents
```

### **Approval Sequence:**
```
Spec Workflow:
- Single approval: Specification

Task Workflow:
- Two approvals:
  1. Task breakdown approval (Phase 6)
  2. Test suite approval (Phase 7)
```

---

## ⚠️ Critical Reminders

**For Directory Structure:**
- All directories created during charter initiation
- All templates copied to appropriate directories during charter phase
- Team members MUST use templates provided
- Team members MUST rename files per standards/naming-conventions.md
- Applies to ALL phases including test suite generation

**For Stateless Agents:**
- Context load + task generation + file creation = ONE continuous process
- Do NOT pause between context load and task generation
- Do NOT pause between task generation and file creation
- Breaking continuity = lose state = must reload context

**For Agent Zero:**
- Maintains state throughout workflow
- Does NOT need to reload context
- Synthesizes all agent contributions
- Makes sequencing and numbering decisions
- Coordinates between phases
- Routes test gaps/issues to Julia for remediation

**For Julia (Testing Agent):**
- NOT included in initial task generation (Phase 3)
- Joins only for test suite generation (Phase 7)
- **MUST follow testing-knowledge-research-process.md during Phase 7 STEP 1**
- MUST research knowledge vault for test tools/examples/patterns
- MUST document findings in testing-knowledge-research.md
- Requires complete context: Charter + Spec + ALL Tasks
- Generates comprehensive test suite (100% coverage)
- Context load + knowledge vault research + test suite generation = continuous process
- Test suite subject to team review
- Must remediate all gaps/issues identified by team
- Uses test templates and renames per naming-conventions.md

**For Team Members (Test Review):**
- ALL team members review Julia's test suite
- Check coverage for their domain tasks
- Identify gaps or issues
- Document reviews in test-suite-review.md
- Agent Zero coordinates remediation if needed

**For CAIO:**
- Two approval points:
  1. Task breakdown (Phase 6)
  2. Test suite (Phase 7 - after team review and remediation)
- Can request changes at either approval point
- Both must be approved before execution phase

---

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-17 | Initial task breakdown workflow with 8-phase structure, team-based task generation, Julia's test suite sub-workflow | 1,419 lines | HX-Infrastructure Team |
| 1.1 | 2025-11-21 | Infrastructure philosophy integration, command infrastructure documentation, comprehensive metadata, related documents expansion | +148 lines | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added proper document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose and Target Audience sections
- Added comprehensive Related Documents section
- Added HX-Infrastructure Philosophy Alignment section (bare metal, systemd, manual procedures, Ansible Vault)
- Added Claude Code Command Infrastructure Integration section (Sets 1, 3, 4, 5)
- Added command workflow integration pattern diagram
- Expanded Related Documents with all workflow phases, commands, templates, standards, agent profiles
- Added version history table (this table)

**Backward Compatibility:** 100% - All v1.0 workflow phases unchanged, only documentation enhancements added

---

## Document Maintenance

**Document Type:** Procedure - Project Lifecycle Workflow (Phase 3: Task Breakdown & Testing)
**Status:** APPROVED - Production Ready v1.1
**Maintained By:** Agent Zero (CC) and HX-Infrastructure Team
**Review Frequency:** Quarterly (or when workflow process changes)
**Last Review:** 2025-11-21
**Next Review:** 2026-02-21

**Update Triggers:**
- Changes to task generation process or phases
- Changes to test suite generation workflow
- Changes to infrastructure philosophy requirements
- Changes to Claude Code command infrastructure
- Changes to team structure or agent roles
- Changes to quality gates or approval criteria
- Template updates affecting task/test file formats

**Related Workflow Documents:**
- This document is part of the 5-phase HX-Infrastructure project lifecycle
- **Phase 1:** charter-workflow.md
- **Phase 2:** spec-workflow.md
- **Phase 3:** task-workflow.md (this document)
- **Phase 4:** task-execution-workflow.md
- **Phase 5:** project-closeout-workflow.md

---

**End of Task Breakdown Workflow Documentation**

*This procedure defines the systematic, team-based task generation workflow for HX-Infrastructure projects. Following an approved specification, this workflow produces a comprehensive task breakdown with 100% test coverage through coordinated multi-agent task generation, test suite generation, and team review processes. All tasks must align with HX-Infrastructure philosophy: bare metal deployment, systemd service management, manual procedures, and Ansible Vault credential management.*
