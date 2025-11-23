---
workflow: task-breakdown
version: 1.0
date: 2025-11-17
status: APPROVED
type: workflow-command
description: Team-based task generation from approved specification with comprehensive test suite sub-workflow
applies_to: all_node_types
prerequisites:
  - approved_specification
  - raidd_log_updated
  - team_assignments_complete
estimated_duration: 10-17 hours
output_artifacts:
  - task-breakdown-summary.md
  - individual-task-files
  - complete-test-suite
---

<metadata>
**Workflow:** Task Breakdown
**Version:** 1.0
**Date Created:** 2025-11-17
**Status:** APPROVED - Production Workflow
**Type:** Workflow Command
**Purpose:** Team-Based Task Generation from Approved Specification
**Trigger:** Specification approved
**Input:** Approved node-spec.md, RAIDD log, Backlog, Defects log
**Output:** Approved task breakdown with individual task files + complete test suite
</metadata>

<objective>
**Purpose:** Define systematic workflow for generating comprehensive task breakdown with multi-agent task generation and complete test suite.

**What This Achieves:**
- Transforms approved specification into actionable, sequenced tasks through team collaboration
- Ensures comprehensive coverage through domain expert task generation
- Validates execution readiness through complete test suite (100% task coverage)
- Produces approved task breakdown and test suite ready for execution phase

**Key Innovation:** Two-phase approach - (1) Team generates deployment tasks independently, (2) Julia generates comprehensive test suite AFTER knowing all tasks. Stateless agents must generate and create task files immediately after context load to preserve state.

**Critical Success Factor:** Task generation and test suite generation are separate but integrated phases. Cannot create comprehensive tests without knowing full deployment scope. All team members review test suite for gaps.
</objective>

<workflow_overview>
**High-Level Flow:**
```
Prerequisites Check → Task Framework → Team Addition (if needed) →
Team Task Generation (Parallel/Independent) → Synthesis & Sequencing →
Clarification Questions → Task Breakdown Approval →
Test Suite Generation (Julia Sub-Workflow + Team Review) → Post-Approval Updates
```

**Duration Breakdown:**
- Phase 0: 15 minutes (prerequisites validation)
- Phase 1: 45-60 minutes (task framework creation)
- Phase 2: 15 minutes (team member addition if needed)
- Phase 3: 75-125 minutes per agent (parallel task generation)
- Phase 4: 2-4 hours (synthesis and sequencing)
- Phase 5: 1-2 hours (clarification questions)
- Phase 6: 1 hour (task breakdown approval)
- Phase 7: 4-8 hours (test suite generation + team review + remediation)
- Phase 8: 30-45 minutes (post-approval updates)

**Total Sequential:** 10-17 hours
**Total Parallel-Optimized:** 9-15 hours (Phase 3 agents work in parallel, Phase 7 team review parallel)

**Key Participants:**
- **Agent Zero:** Framework creator, orchestrator, synthesizer, final reviewer
- **CAIO:** Decision maker, approver (two approval gates: tasks + tests)
- **Team Members (except Julia):** Domain task generators (Alex, Frank, William, Drew, etc.)
- **Julia (Testing Agent):** Test suite generator (joins Phase 7 only, not Phase 3)
- **All Team Members:** Test suite reviewers (Phase 7)
</workflow_overview>

<phases>
<phase id="0" name="Prerequisites Check" gate="prerequisites-met">
<description>
Validate all required inputs exist and specification is approved before beginning task breakdown. This gate prevents starting task generation with incomplete context.
</description>

<inputs>
**Required Documents:**
- `/nodes/[node-name]/node-spec.md` (Status: APPROVED)
- `/nodes/[node-name]/team-assignments.md` (Team identified)
- `/nodes/[node-name]/reviews/knowledge-vault/` (Research complete from charter/spec)
- `/home/agent0/HX-Infrastructure/docs/raidd-log.md` (Updated from spec phase)
- `/home/agent0/HX-Infrastructure/docs/backlog.md` (Updated from spec phase)
- `/home/agent0/HX-Infrastructure/docs/defect-log.md` (Reviewed)

**Required State:**
- Specification status: APPROVED
- Node directory structure created (during charter initiation)
- Templates copied to appropriate directories (during charter phase)
- All templates ready for use and renaming per naming-conventions.md
</inputs>

<actions>
**Agent Zero validates:**

1. **Specification Status Check**
   ```bash
   grep "status: APPROVED" /nodes/[node-name]/node-spec.md
   ```

2. **Directory Structure Validation**
   Verify structure created during charter initiation:
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
   ```

3. **Template Availability Check**
   - All templates copied per `/home/agent0/HX-Infrastructure/standards/naming-conventions.md`
   - Team members can use templates and rename per naming conventions

4. **Artifact Currency Check**
   - RAIDD log updated from spec phase
   - Backlog updated from spec phase
   - Defect log reviewed (if any issues documented)

5. **Team Assignments Validation**
   - Team assignments documented
   - Knowledge vault assignments documented from charter/spec phases

**Pass Criteria:**
- Specification status = APPROVED
- Directory structure complete
- Templates available
- Artifacts current
- Team assignments documented

**Note:** Agent Zero maintains state from spec phase - already has full context, no need to reload
</actions>

<outputs>
**Gate Decision:**
- ✅ **PASS:** All prerequisites met → Proceed to Phase 1
- ❌ **FAIL:** Missing prerequisites → Block and notify CAIO

**Status Update:**
- Prerequisites validated
- Task breakdown workflow officially initiated
</outputs>

<duration>15 minutes</duration>
</phase>

<phase id="1" name="Task Structure Framework" gate="none">
<description>
Agent Zero creates task structure framework by analyzing approved specification and mapping work streams to agent expertise. This framework guides team task generation in Phase 3.
</description>

<inputs>
- Approved node-spec.md
- Team assignments from charter/spec phases
- Agent Zero's maintained state from spec phase
</inputs>

<actions>
**Agent Zero performs:**

1. **Review Approved Specification (30-45 min)**
   - Technical requirements
   - Architecture design
   - Integration points
   - Dependencies
   - Success criteria
   - Deployment approach

2. **Create Task Structure Framework**
   - Identify major work streams from spec
   - Map work streams to agent expertise:
     - Alex → Architecture, integration tasks
     - Frank → Identity, DNS, security tasks
     - William → OS, system, infrastructure tasks
     - Drew → Agentic patterns tasks (if applicable)
     - Others → Domain-specific tasks (if applicable)
   - Define task categories:
     - Pre-deployment preparation
     - Installation & configuration
     - Integration setup
     - Post-deployment documentation
     - [Test Suite placeholder - handled separately]
   - Create initial task numbering schema

3. **Document Framework**
   Location: `/nodes/[node-name]/tasks/task-framework.md`

   Contents:
   - Task categories defined
   - Agent assignments to categories
   - Task numbering schema: `[node-name]-task-001, -002, etc.`
   - Placeholder for "Build Test Suite" task (to be assigned later)
   - Dependencies identified from spec

4. **Determine Task Sequence**
   Agent Zero determines task sequence BEFORE team generation:
   - Pre-deployment tasks first (001-0XX)
   - Installation tasks next (0XX-0XX)
   - Configuration after installation
   - Integration tasks after configuration
   - Post-deployment tasks last (0XX-0XX)
   - Test Suite task assigned AFTER all other tasks approved (separate phase)

**Key Decision:**
Julia (Testing Agent) NOT included in initial task generation. Julia joins Phase 7 for test suite generation.

**Quality Checks:**
- All major work streams identified
- Clear agent-to-category mapping
- Logical task sequence established
- Framework document complete
</actions>

<outputs>
- `task-framework.md` with clear categories, agent assignments, and numbering schema
- Initial task sequence plan
- Foundation for Phase 3 team task generation

**Status Update:**
- Framework ready
- Team can begin task generation
</outputs>

<duration>45-60 minutes</duration>
</phase>

<phase id="2" name="Team Member Addition (if needed)" gate="none">
<description>
Agent Zero evaluates whether additional specialist agents beyond core team are needed based on specification technical requirements. Julia (Testing Agent) is NOT added at this phase - she joins later for test suite generation (Phase 7).
</description>

<inputs>
- Approved specification technical requirements
- Current team-assignments.md
- HX-Infrastructure agent roster
</inputs>

<actions>
**Agent Zero evaluates:**

Does project need additional agents beyond core team?

**Examples of additions:**
- Agentic system? → Add Drew Pearson (Agentic Patterns)
- Database-heavy? → Add Patricia (PostgreSQL) or Robert (Redis)
- Application framework? → Add Maya (Django), Laura (Node.js), etc.
- MCP integration? → Add George (FastMCP), Oliver (MCP Backend)

**Decision Process:**
1. Review specification technical requirements
2. Check current team-assignments.md
3. Identify expertise gaps
4. Add agents with relevant expertise for task generation

**If agents added:**
1. Update `/nodes/[node-name]/team-assignments.md`
2. Assign task categories to new agents
3. Update `task-framework.md` with new agent responsibilities
4. Notify new agents to begin context loading for task generation

**Note:** Julia (Testing Agent) is NOT added at this phase. She joins Phase 7 for test suite generation after task breakdown is approved.

**Quality Checks:**
- Team composition matches specification technical domains
- No expertise gaps for task generation
- Clear role assignments for new agents
</actions>

<outputs>
- Updated team-assignments.md (if changes made)
- Updated task-framework.md with new agent responsibilities (if applicable)
- Finalized team roster for task generation

**Status Update:**
- Team composition finalized
- Ready for parallel task generation (Phase 3)
</outputs>

<duration>15 minutes</duration>
</phase>

<phase id="3" name="Team Context Loading + Immediate Task Generation" gate="none">
<description>
**CRITICAL CONTINUOUS PROCESS PATTERN:** Each team member (EXCEPT Agent Zero and Julia) operates independently in a continuous session:
1. Load context (charter + spec + task framework)
2. Read assigned task categories
3. Generate detailed tasks for their domain
4. IMMEDIATELY create task files
5. Document completion
6. Session ends

This is NOT a waiting workflow. Agents do NOT coordinate in real-time. Agent Zero synthesizes all contributions in Phase 4.

**Why Continuous?** Stateless agents lose state if they pause. Context load → task generation → file creation MUST happen in ONE unbroken session.

**Critical Difference from Spec Workflow:** Agents GENERATE tasks (not edit existing), and task file creation happens DURING generation (not after).
</description>

<critical_pattern>
**Continuous Process Pattern:**
```
Team Member Invoked (not Julia)
    ↓
Context Loading (30-35 min: charter + spec + framework + RAIDD + backlog + defects + knowledge vault)
    ↓
IMMEDIATE Task Generation (45-90 min: generate tasks for assigned domain)
    ↓
IMMEDIATE File Creation (during generation: create task files with placeholder numbers)
    ↓
Document Completion (10 min: contribution summary)
    ↓
Session Ends (no waiting for other agents)
```

**Key Rules:**
- Each agent works independently
- No inter-agent coordination required
- Julia NOT in this phase (comes Phase 7)
- All context in charter, spec, framework
- Task files created DURING generation (prevents state loss)
- Agent Zero synthesizes later (Phase 4)
</critical_pattern>

<inputs>
**For Each Team Member (except Julia):**
- Approved charter.md
- Approved node-spec.md
- task-framework.md (from Phase 1)
- RAIDD log (current state)
- Backlog (current state)
- Defect log (if exists)
- Knowledge vault assignments
- Team assignments
</inputs>

<actions>
**Each Team Member performs:**

**STEP 1: Context Loading (30-35 minutes)**

Reference: `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - "TASK GENERATION PHASE" checklist

Required reading:
1. Approved charter (5 min)
2. Approved specification (10 min)
3. Task framework from Agent Zero (5 min)
4. RAIDD log (2 min)
5. Backlog (2 min)
6. Defect log if exists (1 min)
7. Knowledge vault assignments (5 min)
8. Team assignments (1 min)

**STEP 2: IMMEDIATE Task Generation (45-90 minutes)**
↓ DO NOT PAUSE BETWEEN STEP 1 AND STEP 2 ↓

While context is fresh:
- Review assigned task categories from framework
- Generate detailed tasks for assigned domain:
  - **Alex** → Architecture/integration tasks
  - **Frank** → Identity/DNS/security tasks
  - **William** → OS/system/infrastructure tasks
  - **Drew** → Agentic patterns tasks (if applicable)
  - **Others** → Domain-specific tasks

For each task generated:
1. Define clear objective
2. List prerequisites
3. Detail specific steps
4. Specify exact file paths/deliverables
5. Identify dependencies on other tasks
6. Mark [P] if can run in parallel
7. Include verification steps
8. Document rollback approach

**IMMEDIATELY create task files:**
- Location: `/nodes/[node-name]/tasks/`
- Naming: `[node-name]-task-0XX-<description>.md`
- Use placeholder numbers (Agent Zero will renumber sequentially)

**Why Immediate File Creation?**
- Prevents state loss for stateless agents
- Task generation and file creation are ONE continuous process
- Breaking continuity = losing context = must reload

**STEP 3: Document Completion (10 minutes)**

Location: `/nodes/[node-name]/reviews/team-member/[agent-name]/task-generation-contribution.md`

Document:
- Tasks generated (list with placeholders)
- Dependencies identified
- Parallel execution markers [P] applied
- Integration points noted
- Questions/concerns for Agent Zero

**Quality Checks (per agent):**
- Context fully loaded (all required documents read)
- Tasks generated IMMEDIATELY after context load (no pause)
- All task files created during generation
- Tasks are specific and actionable (no generics)
- Contribution documented
- Session completed in one continuous block
</actions>

<outputs>
**Per Team Member:**
- Multiple task files created in `/nodes/[node-name]/tasks/`
- task-generation-contribution.md documenting their work
- Tasks with placeholder numbers ready for Agent Zero sequencing

**Collective Output (after all agents complete):**
- Full set of deployment tasks from all domains
- Each domain covered by expert who generated tasks
- Ready for Agent Zero synthesis and sequencing

**Typical File Output After Phase 3:**
```
/nodes/[node-name]/tasks/
├── [node]-task-0XX-[alex-task-1].md
├── [node]-task-0XX-[alex-task-2].md
├── [node]-task-0XX-[frank-task-1].md
├── [node]-task-0XX-[frank-task-2].md
├── [node]-task-0XX-[william-task-1].md
├── [node]-task-0XX-[william-task-2].md
└── ... (more tasks with placeholder numbers)
```

**Agent Zero tracks completion:**
- [ ] Alex
- [ ] Frank
- [ ] William
- [ ] Drew Pearson (if applicable)
- [ ] [Others]

Note: Julia NOT in this phase - comes Phase 7

All contributions received? → Proceed to Phase 4
</outputs>

<duration>75-125 minutes per agent (agents work in parallel or sequentially, no coordination required)</duration>
</phase>

<phase id="4" name="Agent Zero Synthesis & Sequencing" gate="synthesis-complete">
<description>
Agent Zero reviews all team-generated tasks, resolves conflicts, builds dependency graph, sequences tasks properly, assigns final sequential numbers, and prepares task breakdown summary.
</description>

<inputs>
- All task files from `/nodes/[node-name]/tasks/` (with placeholder numbers)
- All task-generation-contribution.md files from team members
- Approved specification as source of truth
- Agent Zero's maintained state
</inputs>

<actions>
**Agent Zero performs:**

1. **Collect All Generated Tasks (10 min)**
   - Read all task files from `/nodes/[node-name]/tasks/`
   - Read all contribution documents from `/nodes/[node-name]/reviews/team-member/*/task-generation-contribution.md`
   - Compile complete task inventory
   - Note all dependencies, concerns, questions

2. **Resolve Conflicts and Overlaps (30-60 min)**
   - Identify duplicate tasks (same objective, different authors)
   - Merge or eliminate duplicates
   - Resolve conflicting approaches
   - Document resolution decisions in RAIDD log
   - Clarify ambiguous dependencies

3. **Sequence Tasks by Dependencies (60-90 min)**
   - Build dependency graph
   - Identify critical path
   - Group parallel tasks [P]
   - Ensure proper ordering:
     - Pre-deployment first
     - Installation after pre-deployment
     - Configuration after installation
     - Integration after configuration
     - Post-deployment last
   - Validate no circular dependencies

4. **Renumber Tasks Sequentially (30 min)**
   - Assign final task numbers: `[node-name]-task-001, -002, -003...`
   - Update all task files with correct numbers
   - Update all dependency references
   - Update parallel execution groupings

5. **Add "Build Test Suite" Task (15 min)**
   - Insert at appropriate point (after core tasks, before final deployment)
   - Assign to Julia (Testing Agent)
   - Task ID: `[node-name]-task-0XX-build-test-suite.md`
   - Mark as depends on: All core installation/configuration tasks
   - Will trigger Julia's sub-workflow (Phase 7)
   - Does NOT include individual test creation tasks (Julia generates those)

6. **Create Task Breakdown Summary (30 min)**
   Location: `/nodes/[node-name]/tasks/task-breakdown-summary.md`

   Contents:
   - Complete task list (numbered)
   - Dependency graph visualization
   - Parallel execution groups
   - Critical path identified
   - Time estimates (per task and total)
   - Agent assignments
   - Key integration points

7. **Prepare Clarification Questions (30 min)**
   - Identify areas needing CAIO decision
   - Note conflicting recommendations
   - Flag high-risk dependencies
   - Document trade-offs requiring approval

**Quality Checks:**
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
</actions>

<outputs>
- Complete, sequenced, numbered task breakdown
- task-breakdown-summary.md with full analysis
- "Build Test Suite" task properly positioned
- Clarification questions document (if needed)
- Ready for CAIO review

**Gate: Synthesis Complete**
Pass Criteria:
- ✅ All team tasks integrated
- ✅ No circular dependencies
- ✅ Logical sequencing established
- ✅ Sequential numbering applied
- ✅ Summary document comprehensive
</outputs>

<duration>2-4 hours</duration>
</phase>

<phase id="5" name="Clarification Questions to CAIO" gate="none">
<description>
Agent Zero identifies ambiguities, conflicts, or decision points from task synthesis and presents targeted questions to CAIO before final approval.
</description>

<inputs>
- Synthesized task breakdown
- Task breakdown summary
- Questions identified during Phase 4
</inputs>

<actions>
**Agent Zero presents questions requiring CAIO decisions:**

**Question Categories:**

1. **DEPENDENCY QUESTIONS:**
   - Task sequencing questions (which approach?)
   - Dependency conflicts (how to resolve?)

2. **SCOPE QUESTIONS:**
   - Task scope ambiguity (include or defer?)
   - Integration approach (option A or B?)

3. **RISK QUESTIONS:**
   - High-risk task (mitigation approach?)
   - Resource constraint (adjustment needed?)

4. **TIMELINE QUESTIONS:**
   - Critical path concerns (acceptable?)
   - Parallel execution limits (realistic?)

**CAIO provides:**
- Answers to all questions
- Decisions on conflicts
- Approval of trade-offs
- Confirmation of sequencing approach
- May request adjustments to task breakdown

**Agent Zero actions after CAIO response:**
- Incorporate CAIO decisions
- Update task files as needed
- Update dependency graph
- Update summary document
- Mark questions as resolved
- Prepare final task breakdown for approval

**Quality Checks:**
- All questions answered by CAIO
- Decisions incorporated into task breakdown
- Task files updated with decisions
- Summary reflects CAIO input
</actions>

<outputs>
- Clarification questions presented and answered
- CAIO decisions documented
- Task breakdown updated with clarifications
- Ready for formal CAIO approval (Phase 6)

**Status Update:**
- All ambiguities resolved
- Task breakdown reflects CAIO decisions
</outputs>

<duration>1-2 hours (includes CAIO response time)</duration>
</phase>

<phase id="6" name="Final Review & Approval" gate="task-breakdown-approved">
<description>
CAIO performs final review of complete task breakdown, validates sequencing and dependencies, and provides formal approval before test suite generation.
</description>

<inputs>
- Complete task breakdown summary
- Dependency graph
- Individual task files (sample review)
- Critical path analysis
- Time estimates
- Resource requirements
</inputs>

<actions>
**CAIO reviews:**

1. **Task Breakdown Completeness**
   - All tasks clearly defined
   - Dependencies logical and complete
   - No P0/P1 unresolved issues
   - Sequencing makes sense
   - Parallel execution marked appropriately
   - "Build Test Suite" task properly positioned
   - Integration points clear
   - Ready for execution

**Approval Criteria:**
- All tasks clearly defined
- Dependencies logical and complete
- No P0/P1 unresolved issues
- Sequencing makes sense
- Parallel execution marked appropriately
- "Build Test Suite" task properly positioned
- Integration points clear
- Ready for execution

**Approval Loop:**

IF CAIO requests changes:
1. Agent Zero makes adjustments
2. Updates affected task files
3. Updates summary and dependencies
4. Resubmit for approval
LOOP until CAIO satisfied

**CAIO Final Approval:**
"Task breakdown approved"

**Agent Zero actions after approval:**
1. Update task-breakdown-summary.md:
   - Status: Draft → Approved
   - Approval date
   - Approval signature
2. Lock task sequence (no changes without re-approval)
3. Prepare for test suite generation phase
</actions>

<outputs>
**If APPROVED:**
- task-breakdown-summary.md with status: APPROVED
- Approval date documented
- Task sequence locked
- Ready for test suite generation (Phase 7)

**If REVISIONS REQUIRED:**
- Specific change list from CAIO
- Return to Agent Zero for adjustments
- Re-submit after updates

**Gate: Task Breakdown Approved**
Pass Criteria:
- ✅ CAIO formal approval documented
- ✅ Task breakdown status = APPROVED
- ✅ No P0/P1 unresolved issues
- ✅ Ready for test suite generation
</outputs>

<duration>1 hour (including review cycles if needed)</duration>
</phase>

<phase id="7" name="Test Suite Generation (SUB-WORKFLOW)" gate="test-suite-approved" new="true">
<description>
**Julia generates complete test suite AFTER task breakdown approval.** This is a separate sub-workflow because comprehensive testing requires knowledge of ALL deployment tasks.

**Why Separate Phase:**
- Testing requires knowledge of ALL deployment tasks
- Tests must validate every installation, configuration, integration task
- Test plan must cover complete system deployment
- Cannot create comprehensive tests without knowing full scope
- Julia needs complete context: Charter + Spec + ALL Tasks

**Sub-Workflow Includes:**
1. Julia's context loading and knowledge vault research (CRITICAL)
2. Julia's test suite generation (continuous process)
3. ALL team members review test suite
4. Remediation loop (if gaps/issues found)
5. Agent Zero final review
6. CAIO approval
</description>

<critical_process>
**⚠️ CRITICAL:** Julia MUST follow `testing-knowledge-research-process.md` during STEP 1

**Purpose of Knowledge Vault Research:**
- Identify recommended testing tools for the technology
- Locate example test files demonstrating proper testing
- Extract test case patterns used in the technology's repo
- Document best practices for testing this specific technology
- Find pre-built tests we can leverage or adapt
- Identify gaps or areas commonly missed in testing
</critical_process>

<inputs>
**For Julia:**
- Approved charter.md (goals, success criteria)
- Approved node-spec.md (requirements, architecture)
- Approved task breakdown (ALL tasks)
- Task dependencies and sequencing
- Integration points
- RAIDD log (risks to test for)
- Defect log (known issues to verify)
- Knowledge vault repositories (CRITICAL for test research)
</inputs>

<actions>
**STEP 1: Julia's Context Loading and Knowledge Vault Research (30-40 minutes)**

Julia loads complete context:
1. Approved charter (goals, success criteria) - 5 min
2. Approved specification (requirements, architecture) - 10 min
3. Approved task breakdown (ALL tasks) - 10 min
4. Task dependencies and sequencing - 2 min
5. Integration points - 2 min
6. RAIDD log (risks to test for) - 2 min
7. Defect log (known issues to verify) - 1 min
8. **Knowledge vault repositories (CRITICAL)** - 5-10 min

**FOLLOW: testing-knowledge-research-process.md**

Systematic research process:
- Identify primary knowledge repositories
- Locate testing directories and files
- Analyze testing structure and patterns
- Extract test examples (basic, integration, error, mocking)
- Identify testing best practices
- Document comprehensive findings

Research outputs:
- Testing framework identified (pytest, jest, junit, etc.)
- Testing tools documented (mocking, coverage, CI/CD)
- Test organization structure defined
- Test patterns extracted (at least 3 examples)
- Pre-built tests identified for leverage/adaptation
- Coverage requirements documented
- Testing strategy defined

**Documentation Required:**
Location: `/nodes/[node-name]/reviews/team-member/julia/testing-knowledge-research.md`

**STEP 2: IMMEDIATE Test Suite Generation (90-120 minutes)**
↓ DO NOT PAUSE - CONTINUOUS PROCESS ↓

Julia generates complete test suite using insights from knowledge vault:

**A. Create Test Plan**
Location: `/nodes/[node-name]/tests/test-plan.md`
(Use test-plan-template.md, rename per naming-conventions.md)

Contents:
- Test strategy (TDD approach)
- Test tools (from knowledge vault research)
- Test categories:
  - Deployment validation tests
  - Functionality tests
  - Integration tests
  - Health check tests
  - Security tests (if applicable)
- Test coverage matrix (maps tests to tasks)
- Test execution sequence
- Reference to knowledge vault examples
- Success criteria from charter/spec

**B. Create Test Suite Index**
Location: `/nodes/[node-name]/tests/test-suite-index.md`
(Use test-suite-index-template.md, rename per naming-conventions.md)

Contents:
- Complete test inventory
- Test organization by category
- Test ID numbering schema
- Test dependencies

**C. Generate Individual Test Cases**
Location: `/nodes/[node-name]/tests/test-suite/[category]/`
(Use test-case-template.md, rename per naming-conventions.md)

For EACH deployment task, create corresponding test(s):

Example mapping:
- Task: Install PostgreSQL
  → Test: `tc-[node]-deployment-001-verify-postgres-installation.md`
- Task: Configure Ollama service
  → Test: `tc-[node]-deployment-002-verify-ollama-config.md`
- Task: Setup Redis connection
  → Test: `tc-[node]-integration-001-verify-redis-connection.md`

Each test case file includes:
- Test objective (what it validates)
- Prerequisites (what must be done first)
- Test steps (detailed procedure)
- Expected results
- Pass/fail criteria
- Maps to specific task ID(s)
- Maps to spec requirement(s)
- Reference to knowledge vault examples (if applicable)

**D. Create Test Execution Templates**
Location: `/nodes/[node-name]/tests/test-executions/`
Template for recording test runs during deployment

**STEP 3: Julia Documents Test Suite Generation (10 minutes)**

Location: `/nodes/[node-name]/reviews/team-member/julia/test-suite-generation.md`

Document:
- Knowledge vault research completed
- Test plan created
- Test suite index created
- Test cases generated (count by category)
- Coverage matrix (tasks → tests mapping)
- Test dependencies
- Test tools selected (from knowledge vault)
- Verification approach

**STEP 4: ALL Team Members Review Test Suite**

Responsible: ALL team members (Alex, Frank, William, Drew, etc.)

Each team member reviews:
- Test plan (strategy and tools)
- Test suite index (inventory)
- Test cases in their domain
- Coverage for their generated tasks
- Integration test coverage

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
Location: `/nodes/[node-name]/reviews/team-member/[agent-name]/test-suite-review.md`

Each agent documents:
- Tests reviewed
- Coverage assessment
- Gaps identified (if any)
- Issues found (if any)
- Recommendations (if any)
- Approval or concerns

**STEP 5: Remediation Loop (if gaps/issues found)**

If ANY team member identifies gaps or issues:

1. Agent Zero collects all review feedback:
   - Read all test-suite-review.md files
   - Compile list of gaps and issues
   - Categorize by severity (P0/P1 vs P2/P3)
   - Prioritize by impact

2. Agent Zero routes to Julia for remediation:
   - Provide consolidated feedback
   - Highlight critical gaps (P0/P1)
   - Specify what needs to be added/fixed
   - Set timeline for remediation

3. Julia remediates:
   - Address all P0/P1 gaps (critical)
   - Address P2/P3 issues (important)
   - Add missing test cases
   - Fix issues in existing tests
   - Update test plan/index if needed
   - Document changes made

4. Julia notifies Agent Zero:
   - Lists all changes made
   - References team feedback addressed
   - Confirms remediation complete

5. Agent Zero reviews remediation:
   - Verify all gaps addressed
   - Check all issues resolved
   - Validate test coverage now complete
   - If issues remain → Loop back to Julia

LOOP until Agent Zero confirms all gaps/issues resolved

**STEP 6: Agent Zero Final Review**

After team review and remediation (if needed):

Agent Zero final validation:
- Test plan completeness
- Test coverage (every task has test(s))
- All team gaps addressed
- All team issues resolved
- Test dependencies logical
- Test execution sequence valid
- Test cases follow TDD approach

Comprehensive checklist:
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

Agent Zero approval decision:
- IF all criteria met → Test suite complete, ready for CAIO review
- IF criteria NOT met → Route back to Julia for additional remediation

**STEP 7: CAIO Approval of Test Suite**

CAIO reviews:
- Test plan (strategy and coverage)
- Test suite index (complete inventory)
- Sample test cases (quality check)
- Coverage matrix (tasks to tests mapping)

Approval criteria:
- 100% task coverage (per testing-requirements.md)
- TDD approach followed (tests before execution)
- Success criteria from charter tested
- All requirements from spec tested
- No P0/P1 gaps in test coverage

CAIO: "Test suite approved"

Agent Zero Actions:
- Update test-plan.md status: Draft → Approved
- Lock test suite (no changes without re-approval)
- Test suite ready for execution phase
</actions>

<outputs>
**After Julia's Generation:**
- Complete test plan
- Test suite index with full inventory
- Individual test case files (100% task coverage)
- Test execution templates
- Julia's documentation

**After Team Review:**
- All team review documents
- Consolidated gaps/issues list (if any)

**After Remediation (if needed):**
- Updated test suite addressing all gaps
- Julia's remediation documentation

**After Agent Zero Review:**
- Final validation confirmation
- Approval to proceed to CAIO

**After CAIO Approval:**
- Test suite status: APPROVED
- Test suite locked
- Ready for execution phase

**Gate: Test Suite Approved**
Pass Criteria:
- ✅ Julia researched knowledge vault for test tools/examples
- ✅ Julia generated complete test suite (continuous process)
- ✅ ALL team members reviewed test suite
- ✅ Remediation completed (if gaps found)
- ✅ Agent Zero final review passed
- ✅ CAIO approved test suite
- ✅ 100% task coverage
- ✅ TDD approach followed
</outputs>

<duration>4-8 hours total (depends on gaps found and remediation needed)</duration>
</phase>

<phase id="8" name="Post-Approval Updates" gate="none">
<description>
After both task breakdown and test suite are approved, Agent Zero updates all centralized artifacts to complete the workflow and prepare for execution phase.
</description>

<inputs>
- Approved task breakdown
- Approved test suite
- RAIDD log (current state)
- Backlog (current state)
- Defect log (if applicable)
</inputs>

<actions>
**Agent Zero performs:**

1. **Update RAIDD Log (10 min)**
   Location: `/home/agent0/HX-Infrastructure/docs/raidd-log.md`

   Add entries based on task breakdown:
   - **RISKS** from task dependencies:
     - Critical path risks
     - Integration point risks
     - Resource constraints
     - Technical complexity risks

   - **ASSUMPTIONS** from task sequencing:
     - Parallel execution assumptions
     - Dependency assumptions
     - Time estimate assumptions
     - Resource availability assumptions

   - **ISSUES** discovered during task generation:
     - Conflicts that were resolved
     - Ambiguities that needed clarification
     - Technical constraints

   - **DEPENDENCIES** from task analysis:
     - External service dependencies
     - Infrastructure dependencies
     - Data dependencies
     - Team dependencies

   - **DECISIONS** made during synthesis:
     - Sequencing decisions
     - Approach selections
     - Trade-off decisions
     - Scope decisions

2. **Update Backlog (5 min)**
   Location: `/home/agent0/HX-Infrastructure/docs/backlog.md`

   Add deferred items:
   - Tasks identified but deferred (out of initial scope)
   - Optimizations to consider later
   - Nice-to-have features mentioned
   - Future enhancement opportunities
   - Reference task breakdown and spec

3. **Update Defect Log (if applicable) (5 min)**
   Location: `/home/agent0/HX-Infrastructure/docs/defect-log.md`

   If task generation revealed issues:
   - Document any spec ambiguities discovered
   - Note any charter gaps found
   - Record clarifications that should have been in spec
   - Reference node/task for context

4. **Update Project Status (5 min)**
   Location: `/nodes/[node-name]/STATUS.md`

   Update status:
   - Phase: Specification → Task Breakdown → Test Suite → Ready for Execution
   - Task Breakdown: APPROVED
   - Test Suite: APPROVED
   - Date approved
   - Total tasks: [count]
   - Estimated time: [total]
   - Next phase: Execution

5. **Create Execution Readiness Checklist (10 min)**
   Location: `/nodes/[node-name]/execution-readiness.md`

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

6. **Prepare for Execution Phase**
   - Task breakdown locked and approved
   - Test suite locked and approved
   - All artifacts updated
   - Ready to begin execution
   - Next: Execute tasks per approved sequence
</actions>

<outputs>
- All centralized artifacts updated (RAIDD, Backlog, Defects)
- Project STATUS.md updated
- Execution readiness checklist created
- Task breakdown and test suite approved and locked
- Ready for execution phase

**Status Update:**
- Task breakdown complete
- Test suite complete
- Artifacts current
- Execution phase ready to begin

**Next Workflow:** Task Execution Workflow (`cc-task-execution-workflow.md`)
</outputs>

<duration>30-45 minutes</duration>
</phase>
</phases>

<quality_gates>
<gate name="prerequisites-met" phase="0">
**Gate Question:** Are all prerequisites for task breakdown met?

**Pass Criteria:**
- ✅ Specification status = APPROVED
- ✅ Directory structure created (during charter initiation)
- ✅ Templates copied to appropriate directories
- ✅ RAIDD/Backlog/Defects updated from spec
- ✅ Team assignments documented
- ✅ Knowledge vault assignments documented

**Fail Actions:**
- Block task breakdown workflow
- Notify CAIO of specific gaps
- Do NOT proceed until resolved
</gate>

<gate name="synthesis-complete" phase="4">
**Gate Question:** Has Agent Zero successfully synthesized all team tasks into coherent, sequenced breakdown?

**Pass Criteria:**
- ✅ All team tasks collected and reviewed
- ✅ Duplicates and conflicts resolved
- ✅ Tasks sequenced by dependencies
- ✅ Tasks renumbered sequentially
- ✅ Parallel tasks marked [P]
- ✅ "Build Test Suite" task added
- ✅ Dependency graph created and validated
- ✅ Summary document complete

**Fail Actions:**
- If conflicts unresolvable: Escalate to CAIO
- If gaps in coverage: Identify missing agent and add
- If circular dependencies: Rework sequencing
</gate>

<gate name="task-breakdown-approved" phase="6">
**Gate Question:** Has CAIO formally approved the task breakdown?

**Pass Criteria:**
- ✅ CAIO has reviewed task breakdown summary
- ✅ Approval status documented
- ✅ No P0/P1 unresolved issues
- ✅ Task sequence locked
- ✅ Ready for test suite generation

**Fail Actions:**
- If revisions requested: Return to Phase 4, address, resubmit
- If scope concerns: May need to return to spec
- Loop until approved
</gate>

<gate name="test-suite-approved" phase="7">
**Gate Question:** Has test suite been generated, reviewed, remediated, and approved?

**Pass Criteria:**
- ✅ Julia researched knowledge vault for test tools/examples
- ✅ Julia generated complete test suite (continuous process)
- ✅ ALL team members reviewed test suite
- ✅ Remediation completed (if gaps found)
- ✅ Agent Zero final review passed
- ✅ CAIO approved test suite
- ✅ 100% task coverage confirmed
- ✅ TDD approach followed
- ✅ Templates used and renamed per naming-conventions.md

**Fail Actions:**
- If gaps found: Remediation loop with Julia
- If coverage insufficient: Julia adds missing tests
- If CAIO requests changes: Update and resubmit
- Loop until approved
</gate>
</quality_gates>

<special_notes>
<note name="Continuous Process for Stateless Agents">
**Critical Rule:** Context load + task generation + file creation = ONE continuous process

**Why Important:**
- Stateless agents lose state if they pause
- Breaking continuity requires full context reload
- File creation during generation prevents state loss

**Application:**
- Phase 3: Team members must generate AND create task files in one session
- Phase 7: Julia must load context, research knowledge vault, AND generate test suite in one session

**Wrong Approach:** Load context → Wait → Generate tasks later (agent loses state)
**Correct Approach:** Load context → Immediately generate → Immediately create files → Complete (agent maintains state)
</note>

<note name="Julia's Separate Role in Test Suite Generation">
**Why Julia Doesn't Join Phase 3:**
- Testing requires knowledge of ALL deployment tasks
- Cannot create comprehensive tests without complete scope
- Julia needs Charter + Spec + ALL Tasks before generating test suite

**Julia's Workflow:**
- Joins only in Phase 7 (after task breakdown approved)
- Loads complete context including ALL tasks
- Researches knowledge vault for test tools/patterns (CRITICAL)
- Generates comprehensive test suite with 100% coverage
- Test suite reviewed by ALL team members
- Remediation loop if gaps found
- Agent Zero final review before CAIO approval
</note>

<note name="Two Approval Gates">
**Gate 1: Task Breakdown Approval (Phase 6)**
- CAIO approves deployment task sequence
- Locks task breakdown

**Gate 2: Test Suite Approval (Phase 7)**
- CAIO approves comprehensive test suite
- Locks test suite

**Why Two Gates:**
- Cannot generate tests without knowing all tasks
- Test suite must validate complete deployment scope
- Both must be approved before execution phase
</note>

<note name="Test Suite Team Review and Remediation">
**ALL team members review test suite:**
- Ensures no gaps in coverage for their domain
- Validates test quality and appropriateness
- Identifies missing tests or issues

**Remediation Loop:**
- If ANY team member finds gaps/issues → Julia remediates
- Agent Zero coordinates feedback to Julia
- Julia addresses all P0/P1 gaps (critical)
- Agent Zero validates remediation complete
- Loops until no gaps remain

**Purpose:**
- Ensures 100% test coverage from multiple perspectives
- Validates test quality before execution
- Prevents discovering gaps during execution phase
</note>
</special_notes>

<related_documents>
**Workflow Context:**
- **Previous:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Creates approved specification
- **Next:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md` - Executes approved tasks

**Procedure Files:**
- `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Detailed process documentation
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Context loading checklists
- `/home/agent0/HX-Infrastructure/procedures/testing-knowledge-research-process.md` - **CRITICAL for Julia Phase 7**

**Templates:**
- `/home/agent0/HX-Infrastructure/templates/service-tasks-template.md` - Reference for task structure
- `/home/agent0/HX-Infrastructure/templates/testing/test-plan-template.md` - Test plan template
- `/home/agent0/HX-Infrastructure/templates/testing/test-case-template.md` - Test case template
- `/home/agent0/HX-Infrastructure/templates/testing/test-execution-template.md` - Test execution template
- `/home/agent0/HX-Infrastructure/templates/testing/test-suite-index-template.md` - Test suite index template

**Standards:**
- `/home/agent0/HX-Infrastructure/standards/naming-conventions.md` - File naming standards
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - Testing requirements (100% coverage)

**Reference Documents:**
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team structure and roles
- `/home/agent0/HX-Infrastructure/hx-agents/hx-agent-inventory.md` - Agent capabilities
</related_documents>

<critical_reminders>
**DO:**
- ✅ Use continuous process pattern (context → generate → create files = ONE session)
- ✅ Have Julia research knowledge vault for test tools/examples/patterns (Phase 7 STEP 1)
- ✅ Have ALL team members review test suite (Phase 7 STEP 4)
- ✅ Run remediation loop if test gaps found (Phase 7 STEP 5)
- ✅ Create task files DURING generation (not after)
- ✅ Add "Build Test Suite" task in Phase 4 (triggers Julia)
- ✅ Sequence tasks by dependencies before numbering
- ✅ Mark parallel tasks with [P]
- ✅ Get two approvals: task breakdown AND test suite
- ✅ Use templates and rename per naming-conventions.md
- ✅ Update all centralized artifacts (RAIDD, Backlog, Defects)

**DON'T:**
- ❌ Include Julia in Phase 3 task generation (she joins Phase 7)
- ❌ Break continuous process (context → generate → files must be ONE session)
- ❌ Skip knowledge vault research (Julia MUST research test tools/patterns)
- ❌ Skip team review of test suite (ALL members must review)
- ❌ Proceed without 100% test coverage
- ❌ Create test suite before task breakdown approval
- ❌ Let team members pause between context load and task generation
- ❌ Create task files after generation (creates state loss risk)
- ❌ Proceed to execution without both approvals (tasks AND tests)
- ❌ Skip remediation if test gaps found

**For Directory Structure:**
- All directories created during charter initiation
- All templates copied to appropriate directories during charter phase
- Team members MUST use templates provided
- Team members MUST rename files per naming-conventions.md
- Applies to ALL phases including test suite generation

**For Stateless Agents:**
- Context load + task generation + file creation = ONE continuous process
- Do NOT pause between steps
- Breaking continuity = losing state = must reload context

**For Julia (Testing Agent):**
- NOT included in Phase 3 task generation
- Joins only for Phase 7 test suite generation
- **MUST follow testing-knowledge-research-process.md during Phase 7 STEP 1**
- MUST research knowledge vault for test tools/examples/patterns
- MUST document findings in testing-knowledge-research.md
- Requires complete context: Charter + Spec + ALL Tasks
- Generates comprehensive test suite (100% coverage)
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
</critical_reminders>

<validation_checklist>
**Before proceeding to execution phase, verify:**

**Task Breakdown:**
- [ ] All domain tasks generated by respective experts
- [ ] Tasks properly sequenced with clear dependencies
- [ ] Tasks numbered sequentially per naming-conventions.md
- [ ] Parallel execution opportunities identified [P]
- [ ] "Build Test Suite" task properly positioned
- [ ] No P0/P1 unresolved issues
- [ ] CAIO approved task breakdown

**Test Suite:**
- [ ] Julia researched knowledge vault for test tools/examples/patterns
- [ ] Testing framework identified from knowledge vault
- [ ] Test plan created using template
- [ ] Test suite index complete
- [ ] Individual test cases generated for ALL tasks
- [ ] 100% task coverage confirmed
- [ ] TDD approach followed (tests before execution)
- [ ] Test suite leverages best practices from knowledge vault
- [ ] All charter success criteria have corresponding tests
- [ ] All spec requirements have corresponding tests
- [ ] ALL team members reviewed test suite
- [ ] All test gaps/issues remediated
- [ ] Agent Zero final approval completed
- [ ] CAIO approved test suite
- [ ] Templates used and renamed per naming-conventions.md

**Artifacts:**
- [ ] RAIDD log fully updated
- [ ] Backlog updated with deferred items
- [ ] Defect log updated (if applicable)
- [ ] STATUS.md shows both approvals
- [ ] Execution readiness checklist complete

**Ready for Execution:**
- [ ] Task breakdown locked
- [ ] Test suite locked
- [ ] All centralized artifacts current
- [ ] Ready for task execution workflow
</validation_checklist>

<visual_diagram>
**Task Breakdown Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 0: Prerequisites Check (15 min)                       │
│ Agent Zero validates all inputs                             │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: prerequisites-met gate
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: Task Structure Framework (45-60 min)               │
│ Agent Zero creates framework and categories                 │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: Team Addition (if needed) (15 min)                 │
│ Agent Zero adds project-specific agents                     │
│ NOTE: Julia NOT added yet (comes Phase 7)                   │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: Context Load + Task Generation - PARALLEL          │
│ Team (not Julia) loads context and IMMEDIATELY              │
│ generates tasks + creates files                             │
│ CONTINUOUS PROCESS (no pause)                               │
│ Time: 75-125 min per agent (can work in parallel)           │
└────────────────────┬────────────────────────────────────────┘
                     │ All team task files created
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 4: Agent Zero Synthesis (2-4 hours)                   │
│ • Collect all tasks                                         │
│ • Resolve conflicts                                         │
│ • Sequence by dependencies                                  │
│ • Renumber sequentially                                     │
│ • Add "Build Test Suite" task                               │
│ • Create summary                                            │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: synthesis-complete gate
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 5: Clarification Questions (1-2 hours)                │
│ Agent Zero asks CAIO for decisions                          │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 6: Final Review & Approval (1 hour)                   │
│ CAIO reviews and approves task breakdown                    │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: task-breakdown-approved gate
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 7: Test Suite Generation SUB-WORKFLOW (4-8 hours)     │
│                                                             │
│ Julia Sub-Workflow:                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 1: Context Load + Knowledge Vault Research         │ │
│ │ (30-40 min - MUST follow testing-knowledge-research)    │ │
│ └─────────────────────────────────────────────────────────┘ │
│                           ↓                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 2: IMMEDIATE Test Suite Generation (90-120 min)    │ │
│ │ • Test plan • Test index • Individual test cases        │ │
│ │ CONTINUOUS PROCESS (no pause)                           │ │
│ └─────────────────────────────────────────────────────────┘ │
│                           ↓                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 3: Julia Documents Generation (10 min)             │ │
│ └─────────────────────────────────────────────────────────┘ │
│                           ↓                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 4: ALL Team Members Review Test Suite             │ │
│ │ (each reviews their domain coverage - can be parallel)  │ │
│ └─────────────────────────────────────────────────────────┘ │
│                           ↓                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 5: Remediation Loop (if gaps found)                │ │
│ │ Agent Zero → Julia → Fixes → Agent Zero validates       │ │
│ │ LOOP until no gaps remain                               │ │
│ └─────────────────────────────────────────────────────────┘ │
│                           ↓                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 6: Agent Zero Final Review                         │ │
│ │ Validates 100% coverage, all gaps addressed             │ │
│ └─────────────────────────────────────────────────────────┘ │
│                           ↓                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ STEP 7: CAIO Approval                                   │ │
│ │ Reviews and approves test suite                         │ │
│ └─────────────────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────────────┘
                     │ PASS: test-suite-approved gate
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 8: Post-Approval Updates (30-45 min)                  │
│ • Update RAIDD/Backlog/Defects                              │
│ • Update STATUS.md                                          │
│ • Create execution readiness checklist                      │
└────────────────────┬────────────────────────────────────────┘
                     ↓
            ┌────────────────────┐
            │ COMPLETE           │
            │ Ready for Task     │
            │ Execution Workflow │
            └────────────────────┘
```

**Key: Continuous Process Patterns**

**Phase 3 - Team Task Generation:**
```
Each Team Member (not Julia):
┌─────────────────────────────────────┐
│ 1. LOAD CONTEXT (30-35 min)        │
│    Charter + Spec + Framework +     │
│    RAIDD + Backlog + Defects +      │
│    Knowledge vault                  │
├─────────────────────────────────────┤
│ 2. IMMEDIATE TASK GENERATION        │
│    (45-90 min)                      │
│    Generate tasks for domain        │
├─────────────────────────────────────┤
│ 3. IMMEDIATE FILE CREATION          │
│    (during generation)              │
│    Create task files with           │
│    placeholder numbers              │
├─────────────────────────────────────┤
│ 4. DOCUMENT COMPLETION (10 min)    │
│    Contribution summary             │
├─────────────────────────────────────┤
│ 5. END SESSION                      │
│    No waiting for other agents      │
└─────────────────────────────────────┘
```

**Phase 7 - Julia Test Suite Generation:**
```
Julia's Workflow:
┌─────────────────────────────────────┐
│ 1. LOAD CONTEXT (30-40 min)        │
│    Charter + Spec + ALL Tasks +     │
│    RAIDD + Defects +                │
│    KNOWLEDGE VAULT RESEARCH ★       │
│    (CRITICAL - follow process doc)  │
├─────────────────────────────────────┤
│ 2. IMMEDIATE TEST GENERATION        │
│    (90-120 min)                     │
│    Test plan + Index + All tests    │
├─────────────────────────────────────┤
│ 3. DOCUMENT GENERATION (10 min)    │
│    Research + generation summary    │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│ TEAM REVIEW (all members)           │
│ Each reviews domain coverage        │
│ Documents gaps/issues               │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│ REMEDIATION LOOP (if needed)        │
│ Agent Zero → Julia → Fixes →        │
│ Agent Zero validates → Loop         │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│ AGENT ZERO FINAL REVIEW             │
│ 100% coverage confirmed             │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│ CAIO APPROVAL                       │
│ Test suite approved                 │
└─────────────────────────────────────┘
```
</visual_diagram>

<metadata_footer>
**Document Version:** 1.0
**Last Updated:** 2025-11-17
**Status:** APPROVED - Production Workflow
**Maintained By:** Agent Zero (CC)
**Related Workflows:** Charter Creation → Specification Development → **Task Breakdown** → Task Execution → Project Closeout
**Purpose:** Team-based task generation with comprehensive test suite sub-workflow
</metadata_footer>
