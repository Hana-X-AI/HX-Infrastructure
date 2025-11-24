---
document: cc-task-execution-workflow
version: 1.1
date: 2025-11-24
status: APPROVED
type: workflow-command
description: Systematic execution of approved tasks with test-driven deployment and comprehensive result documentation
applies_to: all_node_deployments
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
prerequisites:
  - approved_task_breakdown
  - approved_test_suite
  - infrastructure_ready
estimated_duration: varies (1-5 days typical, up to 2 weeks for complex systems)
output_artifacts:
  - task-results
  - test-execution-results
  - execution-completion-report
  - operational-node-service
---

<metadata>
**Workflow:** Task Execution
**Version:** 1.1
**Date Created:** 2025-11-24
**Status:** APPROVED - Production Workflow
**Type:** Workflow Command
**Purpose:** Systematic Execution of Approved Tasks with Test-Driven Deployment
**Trigger:** Task breakdown and test suite approved
**Input:** Approved task breakdown, approved test suite, all prerequisites met
**Output:** All tasks executed, tests passed, node/service operational
</metadata>

<objective>
**Purpose:** Define systematic workflow for executing approved tasks with comprehensive result documentation following test-driven deployment approach.

**What This Achieves:**
- Transforms approved task breakdown into operational node/service through disciplined execution
- Ensures quality through test-driven deployment (TDD) approach
- Validates functionality through comprehensive test execution
- Produces operational system with complete documentation of execution results

**Key Innovation:** Continuous process pattern where context load + execution + documentation happen in ONE unbroken session to prevent state loss for stateless agents. Test-driven deployment ensures quality gates before operational promotion.

**Critical Success Factor:** Test-driven deployment is non-negotiable. Tests must pass before operational promotion. Comprehensive documentation of every task execution ensures accountability and enables troubleshooting.
</objective>

<workflow_overview>
**High-Level Flow:**
```
Pre-Execution Check → Task Assignment → Task-by-Task Execution (TDD) →
Continuous Coordination → Test Suite Execution → Completion Verification →
CAIO Approval → Operational Promotion → Post-Execution Updates
```

**Duration Varies Based On:**
- Number of tasks (10-100+)
- Task complexity (minutes to hours each)
- Parallel execution opportunities
- Issues encountered
- Test suite size

**Typical Timelines:**
- Simple Service: 4-8 hours
- Standard Node Deployment: 1-5 days
- Complex System: 1-2 weeks

**Key Participants:**
- **Agent Zero:** Coordinator, verifier, orchestrator throughout execution
- **Team Members:** Execute assigned tasks following TDD approach
- **Julia (Testing Agent):** Executes comprehensive test suite AFTER implementation
- **CAIO:** Final approver for operational promotion
</workflow_overview>

<key_principles>
1. **Test-Driven Deployment (TDD):** Write tests BEFORE executing implementation tasks (where applicable)
2. **Continuous Process:** Context load + execution + documentation = ONE process (stateless agents)
3. **Dependency Respect:** Execute tasks in approved sequence, respect dependencies
4. **Quality Gates:** Tests must pass before operational promotion
5. **Comprehensive Documentation:** Every task execution documented with results
6. **Critical Difference:** Planning phases CREATE documentation; Execution phase EXECUTES tasks and DOCUMENTS results
</key_principles>

<phases>
<phase id="0" name="Pre-Execution Readiness Check" gate="pre-execution-ready">
<description>
Agent Zero validates all prerequisites are met and infrastructure is ready before beginning task execution. This gate prevents starting execution without complete readiness.
</description>

<inputs>
- `/nodes/[node-name]/tasks/task-breakdown-summary.md` (Status: APPROVED)
- `/nodes/[node-name]/tests/test-plan.md` (Status: APPROVED)
- `/nodes/[node-name]/tests/test-suite-index.md` (Complete)
- All individual task files (present and numbered)
- All test case files (present and mapped to tasks)
- Infrastructure availability
- Network connectivity
- Required credentials
</inputs>

<actions>
**Agent Zero validates:**

1. **Document Readiness**
   - Task breakdown approved and locked
   - Test suite approved and locked
   - All task files created and numbered sequentially
   - All test files created and mapped to tasks
   - Task dependencies documented
   - Parallel tasks identified [P]
   - Critical path identified

2. **Infrastructure Readiness**
   - Target infrastructure accessible
   - Network connectivity verified to target node
   - Required ports available
   - Credentials available in vault (if needed)
   - Backup completed (if modifying existing systems)

3. **Team Readiness**
   - Team assignments confirmed
   - Agents available for execution
   - Communication protocols established

4. **Create Execution Tracking**
   Location: `/nodes/[node-name]/execution-tracking.md`

   Contents:
   - Task status matrix (Not Started/In Progress/Complete/Failed)
   - Agent assignments
   - Execution timeline
   - Dependency tracking
   - Test execution tracking
   - Issue tracking

5. **Brief Team on Execution Approach**
   - Task sequence and batches
   - TDD requirement (tests before implementation where applicable)
   - Parallel execution strategy
   - Documentation requirements (continuous process)
   - Communication protocol
   - Rollback procedures documented per task

**Quality Checks:**
- [ ] Task breakdown approved and locked
- [ ] Test suite approved and locked
- [ ] All prerequisites met
- [ ] Infrastructure ready and accessible
- [ ] Team briefed and ready
- [ ] Execution tracking system in place
</actions>

<outputs>
- execution-tracking.md created
- Team briefed
- Infrastructure verified ready
- All prerequisites met

**Gate Decision:**
- ✅ **PASS:** All prerequisites met, team briefed → Proceed to Phase 1
- ❌ **FAIL:** Missing prerequisites → Block and notify CAIO

**Status Update:**
- Execution readiness confirmed
- Ready to begin task execution
</outputs>

<duration>30-45 minutes</duration>
</phase>

<phase id="1" name="Task Assignment and Prioritization" gate="none">
<description>
Agent Zero assigns tasks to agents based on expertise and creates execution batches respecting dependencies and parallel execution opportunities.
</description>

<inputs>
- Approved task breakdown with dependencies
- Task-to-agent mappings from task generation phase
- Parallel execution markers [P]
</inputs>

<actions>
**Agent Zero performs:**

1. **Review Task Breakdown**
   - Pre-deployment tasks (001-0XX)
   - Installation tasks (0XX-0XX)
   - Integration tasks (0XX-0XX)
   - Post-deployment tasks (0XX-0XX)
   - Test suite execution (Julia - AFTER implementation)

2. **Assign to Agents Based on Expertise**
   - Alex → Architecture/integration tasks
   - Frank → Identity/DNS/security tasks
   - William → OS/system/infrastructure tasks
   - Drew → Agentic patterns tasks (if applicable)
   - Julia → Test execution (AFTER implementation tasks)
   - Others → Domain-specific tasks

3. **Create Execution Batches**
   Batch 1 (Sequential): Pre-deployment tasks (no dependencies)
   Batch 2 (May parallel): Installation tasks (some can run [P])
   Batch 3 (Sequential): Integration tasks (depend on Batch 2)
   Batch 4 (May parallel): Post-deployment documentation [P]
   Batch 5 (Sequential): Test execution (after ALL implementation)

4. **Identify Parallel Execution Groups**
   - Group A (Parallel): Tasks marked [P] with no dependencies
   - Group B (Parallel): Independent configuration tasks [P]
   - Sequential: Tasks with dependencies execute in order

5. **Document Assignments**
   Location: `/nodes/[node-name]/task-assignments-execution.md`

   Format: Table showing Task ID, Description, Assigned Agent, Batch, Status

**Quality Checks:**
- All tasks assigned to appropriate agents
- Execution batches respect dependencies
- Parallel opportunities identified
- Assignments documented
</actions>

<outputs>
- task-assignments-execution.md created
- Execution batches defined
- Parallel groups identified
- Team knows their task assignments
- Ready to begin execution

**Status Update:**
- Task assignments complete
- Execution plan established
</outputs>

<duration>30-45 minutes</duration>
</phase>

<phase id="2" name="Task-by-Task Execution (TDD Approach)" gate="none">
<description>
**CRITICAL CONTINUOUS PROCESS:** Each agent executes assigned tasks following test-driven deployment approach in ONE continuous session:
1. Load context (charter + spec + tasks + tests + infrastructure)
2. IMMEDIATE task execution (verify prerequisites, execute steps, verify completion)
3. IMMEDIATE result documentation (capture everything while context fresh)
4. Session ends

**Breaking this continuity causes state loss and incomplete documentation.**

**TDD Requirement:** For implementation tasks - write test(s) FIRST (if not already written by Julia), verify test FAILS initially, execute implementation, verify test PASSES after implementation.
</description>

<critical_pattern>
**Execution Pattern: Continuous Process**
```
Agent Executing Task
    ↓
STEP 1: Context Loading (15-20 min)
    Charter + Spec + Task breakdown + Assigned task(s) +
    Dependencies + Tests + RAIDD + Defects + Infrastructure details
    ↓
STEP 2: IMMEDIATE Task Execution (varies by task complexity)
    ↓ DO NOT PAUSE ↓
    A. Read task file (objective, prerequisites, steps, deliverables, verification, rollback)
    B. Verify prerequisites met
    C. Execute task steps (follow exactly, capture output/logs)
    D. Verify task completion (run verification steps, check deliverables)
    E. Test validation (run corresponding tests, verify passes)
    ↓
STEP 3: IMMEDIATE Result Documentation (10-15 min)
    ↓ DO NOT PAUSE ↓
    Document: Status, timestamps, steps executed, output/logs, verification results,
    test results, issues, deviations, defects, next steps
    ↓
Session Ends
```

**Why Continuous?**
❌ WRONG: Load context → Execute → Wait → Document later = Agent loses state, forgets details
✅ CORRECT: Load → Execute → Document immediately = Agent maintains context, captures all details
</critical_pattern>

<inputs>
**For Each Agent Executing Tasks:**
- Approved charter.md (goals, success criteria)
- Approved node-spec.md (requirements)
- Approved task breakdown (ALL tasks)
- Assigned task(s) for execution
- Task dependencies
- Test suite (tests for their tasks)
- RAIDD log (risks to be aware of)
- Defect log (known issues)
- Infrastructure details (target node, IPs, ports)
- Credentials (from vault, if needed)
</inputs>

<actions>
**Each Agent performs for each assigned task:**

**STEP 1: Context Loading (15-20 minutes)**

Reference: `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - "TASK EXECUTION PHASE" checklist

Load execution context:
1. Approved charter (goals, success criteria) - 2 min
2. Approved specification (requirements) - 5 min
3. Approved task breakdown (ALL tasks) - 3 min
4. Assigned task(s) for execution - 3 min
5. Task dependencies - 1 min
6. Test suite (tests for their tasks) - 2 min
7. RAIDD log (risks to be aware of) - 1 min
8. Defect log (known issues) - 1 min
9. Infrastructure details (target node, IPs, ports) - 1 min
10. Credentials (from vault, if needed) - 1 min

**STEP 2: IMMEDIATE Task Execution (varies by task)**
↓ DO NOT PAUSE BETWEEN STEP 1 AND STEP 2 ↓

While context is fresh:

**A. Read Assigned Task File**
- Task objective
- Prerequisites
- Detailed steps
- Deliverables
- Verification steps
- Rollback procedure

**B. Verify Prerequisites Met**
- Check all prerequisite conditions
- Verify dependent tasks completed
- Confirm infrastructure ready
- If prerequisites NOT met → Document and wait/notify Agent Zero

**C. Execute Task Steps**
- Follow steps exactly as documented in task file
- Execute commands/actions
- Create deliverables
- Capture output/logs
- Note any deviations or issues

**D. Verify Task Completion**
- Run verification steps from task file
- Check deliverables created
- Validate expected state achieved
- If verification fails → Document issue as defect

**E. Test Validation (if applicable)**
- Run corresponding test(s) for this task
- Verify test passes
- If test fails → Document as defect
- If test passes → Task complete

**STEP 3: IMMEDIATE Result Documentation (10-15 minutes)**
↓ DO NOT PAUSE - DOCUMENT IMMEDIATELY ↓

Location: `/nodes/[node-name]/task-results/[task-id]-result.md`

Document (comprehensive template provided in workflow):
- Task completion status (Complete/Failed/Blocked)
- Execution timestamp (start and end time)
- Prerequisites verified (with timestamps)
- Steps executed (what was done, commands run, output captured)
- Deliverables created (table with paths and verification)
- Verification results (expected vs actual for each check)
- Test execution (test ID, result PASS/FAIL, output, defects if failed)
- Issues encountered (severity, impact, resolution)
- Deviations from plan (what differed, why, approved by whom, impact)
- Defects created (table with defect IDs, titles, severity, status)
- Rollback capability (can it be rolled back, procedure, tested?)
- Integration points validated (table)
- Next steps (dependent tasks unblocked, follow-up required)
- Time breakdown (planned vs actual)
- Agent notes (observations, recommendations, lessons learned)
- Approval (self-verified, Agent Zero review status)

**Quality Checks (per agent execution):**
- Context fully loaded before execution
- Task executed IMMEDIATELY after context load (no pause)
- Results documented IMMEDIATELY after execution (no pause)
- Documentation comprehensive and complete
- All output captured
- Issues/defects properly documented
- Session completed in one continuous block
</actions>

<outputs>
**Per Task Executed:**
- `[task-id]-result.md` in `/nodes/[node-name]/task-results/`
- Deliverables created per task requirements
- Test execution results
- Defects created (if issues found)
- execution-tracking.md updated with task status

**Collective Output (throughout execution):**
- Growing collection of task results
- Progress tracking in real-time
- Defect log populated
- System progressively built out

**Continuous Updates:**
- Agent notifies Agent Zero after each task completion
- execution-tracking.md continuously updated
- Next dependent tasks unblocked as prerequisites complete
</outputs>

<duration>Varies significantly (minutes to hours per task, days for all tasks)</duration>
</phase>

<phase id="3" name="Continuous Execution Coordination" gate="none">
<description>
Agent Zero coordinates execution throughout Phase 2, monitoring progress, unblocking dependencies, reviewing results, managing issues, and communicating status. This is an ongoing parallel activity during task execution.
</description>

<inputs>
- execution-tracking.md (continuously updated)
- Task result files as they're completed
- Defect files as they're created
- Team communications
</inputs>

<actions>
**Agent Zero performs ongoing coordination:**

1. **Monitor Execution Tracking**
   - Update task statuses as reported
   - Track which tasks complete
   - Identify blocked tasks
   - Note failed tasks
   - Calculate progress percentage

2. **Unblock Dependencies**
   - When task completes → notify dependent agents
   - Verify prerequisites for next tasks
   - Release next batch if batch complete
   - Coordinate parallel execution

3. **Review Task Results**
   - Read each [task-id]-result.md as completed
   - Verify verification passed
   - Check test execution results
   - Identify issues or defects
   - Approve completion or request remediation

4. **Issue Management**
   - Review defects created
   - Triage severity and priority (P0/P1/P2/P3)
   - Assign remediation to appropriate agent
   - Track resolution progress
   - Update RAIDD log with new risks
   - Escalate critical issues to CAIO

5. **Communication**
   - Daily progress updates to CAIO
   - Alert on blockers immediately
   - Escalate critical issues (P0/P1)
   - Celebrate milestones (batch completion, critical path on track)

**Quality Checks:**
- Execution tracking always current
- Dependencies properly managed
- Issues triaged quickly
- Communication timely
- Progress visible
</actions>

<outputs>
- Continuously updated execution-tracking.md
- Real-time coordination of team
- Issues triaged and assigned
- Blockers resolved
- CAIO informed of progress

**Status Update:**
- Ongoing throughout execution
- Provides visibility and control
</outputs>

<duration>Ongoing throughout Phase 2 (Agent Zero maintains state)</duration>
</phase>

<phase id="4" name="Test Suite Execution" gate="tests-passed">
<description>
**Trigger:** ALL implementation tasks complete

Julia (Testing Agent) executes comprehensive test suite systematically by category, documents all results, and provides overall assessment for operational promotion.
</description>

<inputs>
- Completed implementation tasks (all deliverables created)
- Approved test suite (test plan + test suite index + individual test cases)
- Infrastructure in deployed state
- Defects from implementation (if any)
</inputs>

<actions>
**Julia performs:**

**STEP 1: Pre-Test Verification (15 minutes)**
- Verify all implementation tasks complete
- Verify all deliverables created
- Verify infrastructure in expected state
- Review any defects from implementation

**STEP 2: Test Execution by Category (varies by suite size)**

Execute tests systematically:

**A. Deployment Validation Tests (run first)**
- Installation verification tests
- Configuration verification tests
- Dependency verification tests
- Service startup tests

**B. Functionality Tests (run second)**
- Core functionality tests
- Feature tests
- Error handling tests

**C. Integration Tests (run third)**
- External service integration tests
- Database integration tests
- API integration tests
- Inter-component tests

**D. Health Check Tests (run fourth)**
- Health endpoint tests
- Resource usage tests
- Performance baseline tests
- Monitoring tests

**E. Security Tests (run last, if applicable)**
- Authentication tests
- Authorization tests
- Security configuration tests

**STEP 3: Test Result Documentation (per test)**

For EACH test executed:
Location: `/nodes/[node-name]/tests/test-executions/[YYYY-MM-DD]-[test-id]-r[N].md`
(Use test-execution-template.md)

Document:
- Test execution timestamp
- Test steps performed
- Actual results vs expected
- Pass/Fail determination
- Screenshots/logs (if applicable)
- Defects created (if test failed)
- Recommendations

**STEP 4: Test Suite Summary**

Location: `/nodes/[node-name]/tests/test-execution-summary.md`

Summary:
- Total tests executed
- Tests passed/failed/skipped
- Coverage achieved (should be 100%)
- Defects created
- Overall assessment
- Recommendation (promote to operational or fix defects first)

**Test Execution Decision Tree:**
- If ALL tests pass → Proceed to Phase 5
- If SOME tests fail (P2/P3 severity) → Create defects, Agent Zero triages, may proceed with known issues or require fixes
- If CRITICAL tests fail (P0/P1 severity) → STOP, create critical defects, Agent Zero escalates to CAIO, must fix before promotion, retest after fixes

**Quality Checks:**
- All tests executed
- Results comprehensively documented
- Failures properly investigated
- Defects created for all failures
- Summary assessment accurate
</actions>

<outputs>
- Individual test execution result files
- test-execution-summary.md with overall assessment
- Defects created for test failures (if any)
- Recommendation for operational promotion

**Gate: Tests Passed**
Pass Criteria:
- ✅ All tests executed
- ✅ Coverage requirement met (100%)
- ✅ Critical tests passed
- ✅ Test failures triaged (P0 defects must be resolved)

**Status Update:**
- Test suite complete
- Results documented
- Ready for completion verification
</outputs>

<duration>2-4 hours (varies by test suite size)</duration>
</phase>

<phase id="5" name="Completion Verification" gate="verification-complete">
<description>
Agent Zero performs comprehensive verification of entire execution, validates all quality gates, and creates final execution completion report for CAIO review.
</description>

<inputs>
- All task result files
- All test execution result files
- execution-tracking.md (final state)
- Defect log (current state)
- Charter success criteria
- Specification requirements
</inputs>

<actions>
**Agent Zero performs comprehensive verification:**

**Verification Checklist:**

1. **Task Completion**
   - [ ] All tasks executed
   - [ ] All task results documented
   - [ ] All verifications passed
   - [ ] All deliverables created
   - [ ] No blocked tasks remaining

2. **Test Execution**
   - [ ] All tests executed
   - [ ] Test results documented
   - [ ] Coverage requirement met (100%)
   - [ ] Test failures triaged
   - [ ] Critical tests passed

3. **Quality Gates**
   - [ ] No P0 defects open
   - [ ] P1 defects documented with mitigation
   - [ ] All success criteria from charter met
   - [ ] All requirements from spec implemented
   - [ ] Infrastructure stable

4. **Documentation**
   - [ ] All task results documented
   - [ ] All test executions documented
   - [ ] All defects documented
   - [ ] Execution tracking complete
   - [ ] Lessons learned captured

5. **Operational Readiness**
   - [ ] Service running and stable
   - [ ] Health checks passing
   - [ ] Monitoring configured
   - [ ] Logging configured
   - [ ] Alerting configured (if applicable)
   - [ ] Documentation complete
   - [ ] Runbook created (if needed)

**Create Final Report:**

Location: `/nodes/[node-name]/execution-completion-report.md`

Comprehensive report including:
- Executive summary
- Execution metrics (planned vs actual)
- Success criteria assessment (from charter)
- Quality gates status
- Open issues (defects with severity and mitigation)
- Lessons learned (what went well, what could improve, recommendations)
- Agent Zero recommendation (promote to operational / fix issues first / rollback)
- Justification and next steps

**Quality Checks:**
- All verification criteria met or documented exceptions
- Report comprehensive and accurate
- Clear recommendation with justification
</actions>

<outputs>
- execution-completion-report.md with full assessment
- Final execution-tracking.md
- Comprehensive verification complete
- Clear recommendation for CAIO

**Gate: Verification Complete**
Pass Criteria:
- ✅ Agent Zero verified all quality gates
- ✅ Completion report created
- ✅ Recommendation documented
- ✅ Ready for CAIO review

**Status Update:**
- Verification complete
- Report ready for CAIO
</outputs>

<duration>1-2 hours</duration>
</phase>

<phase id="6" name="CAIO Final Approval" gate="caio-approved">
<description>
CAIO reviews execution completion report, validates quality gates, and makes final decision to approve operational promotion, approve with conditions, require remediation, or direct rollback.
</description>

<inputs>
- execution-completion-report.md
- execution-tracking.md
- test-execution-summary.md
- Open defects (severity and mitigation)
- Success criteria assessment
- Agent Zero recommendation
</inputs>

<actions>
**CAIO reviews:**

1. **Execution Completion**
   - All critical tasks complete
   - All critical tests pass
   - Success criteria assessment
   - Quality gates status

2. **Quality Assessment**
   - No P0 defects open
   - P1 defects acceptable with mitigation
   - Service operational and healthy
   - Documentation complete

3. **Decision Options**

**Option A: Approve for Operational Promotion**
- All criteria met
- Ready for operational use
- Proceed to Phase 7

**Option B: Approve with Conditions**
- Generally ready but specific conditions to monitor
- Document conditions
- Proceed to Phase 7 with conditions

**Option C: Require Remediation**
- Issues need to be fixed first
- Fix issues, re-test, re-submit for approval

**Option D: Rollback**
- Issues too severe
- Rollback deployment
- Fix and retry later

**Document Approval:**

Location: `/nodes/[node-name]/caio-operational-approval.md`

Document:
- Review summary
- Decision (Approved / Approved with Conditions / Remediation Required / Rollback)
- Approval conditions (if applicable)
- Open items accepted (defects with acceptance rationale)
- Signature and timestamp

**Quality Checks:**
- CAIO has reviewed all key documents
- Decision clearly documented
- Conditions (if any) specific and measurable
- Acceptance rationale for open issues documented
</actions>

<outputs>
- caio-operational-approval.md with formal decision
- Clear authorization or specific remediation requirements

**Gate: CAIO Approved**
Pass Criteria:
- ✅ CAIO reviewed execution completion
- ✅ Approval documented (with or without conditions)
- ✅ Ready for operational promotion

**Fail Actions:**
- If remediation required: Fix issues, re-test, re-submit
- If rollback directed: Execute rollback procedures, fix root cause, retry deployment

**Status Update:**
- CAIO decision documented
- If approved: Ready for operational promotion (Phase 7)
</outputs>

<duration>30-60 minutes</duration>
</phase>

<phase id="7" name="Promotion to Operational" gate="none">
<description>
Agent Zero executes operational promotion by updating all status documents, inventory, network documentation, configuring monitoring, and creating operational documentation.
</description>

<inputs>
- CAIO approval (documented)
- Deployed node/service (operational and tested)
</inputs>

<actions>
**Agent Zero executes promotion:**

1. **Update Node/Service Status**
   - `/nodes/[node-name]/STATUS.md`: Ready for Execution → OPERATIONAL
   - `/nodes/[node-name]/node-spec.md`: Status section → OPERATIONAL
   - Mark deployment date

2. **Update Inventory**
   - `/inventory/nodes.md`: Add node with OPERATIONAL status
   - `/inventory/services.md` (if service): Add with OPERATIONAL status
   - Update resource allocations

3. **Update Network Documentation**
   - `/network/network-topology.md`: Add node/service to topology
   - `/network/port-mapping.md`: Document ports used
   - Update connectivity matrix

4. **Move Service to Operational Directory (if applicable)**
   - FROM: `/services/non-operational/[service-name]/`
   - TO: `/services/operational/[service-name]/`
   - Include: All specification, tasks, tests, execution documentation, runbooks

5. **Create Operational Documentation**
   - Runbook (if needed)
   - Troubleshooting guide
   - Monitoring setup documentation
   - Alerting configuration
   - Maintenance procedures

6. **Configure Monitoring**
   - Add to monitoring system
   - Configure health checks
   - Set up alerting rules
   - Create dashboard (if applicable)

**Quality Checks:**
- All status updates complete
- Inventory accurate
- Network documentation updated
- Monitoring configured and active
- Operational documentation complete
</actions>

<outputs>
- Node/service status: OPERATIONAL
- All documentation updated
- Monitoring configured
- Service in operational directory
- Complete operational package

**Status Update:**
- Promoted to operational
- Ready for production use
</outputs>

<duration>30-45 minutes</duration>
</phase>

<phase id="8" name="Post-Execution Updates" gate="none">
<description>
Agent Zero performs final artifact updates, documents lessons learned, and completes execution workflow. All centralized artifacts updated to reflect execution results.
</description>

<inputs>
- Execution completion report
- Defects created during execution
- Lessons learned throughout process
</inputs>

<actions>
**Agent Zero performs:**

1. **Update RAIDD Log (10 min)**
   Location: `/home/agent0/HX-Infrastructure/docs/raidd-log.md`

   Add/Update entries:
   - RISKS identified during execution
   - ASSUMPTIONS validated or invalidated
   - ISSUES encountered and resolved
   - DEPENDENCIES confirmed
   - DECISIONS made during execution

2. **Update Backlog (5 min)**
   Location: `/home/agent0/HX-Infrastructure/docs/backlog.md`

   Add deferred items:
   - Future enhancements identified
   - Optimizations to consider
   - Technical debt created
   - Follow-up work needed

3. **Update Defect Log (5 min)**
   Location: `/home/agent0/HX-Infrastructure/docs/defect-log.md`

   Update defect statuses:
   - Mark resolved defects
   - Keep open defects with mitigation
   - Add newly discovered defects
   - Track remediation plans

4. **Document Lessons Learned (15 min)**
   Location: `/nodes/[node-name]/lessons-learned.md`

   Capture:
   - What worked well
   - What could be improved
   - Process improvements
   - Tool/technique effectiveness
   - Recommendations for future deployments

5. **Update Project Metrics (5 min)**
   - Node count (operational vs planned)
   - Service count (operational vs planned)
   - Test coverage achieved
   - Deployment success rate
   - Time to deployment (planned vs actual)

6. **Archive Execution Artifacts (10 min)**
   - All task results
   - All test executions
   - All defects
   - Execution tracking
   - Completion report
   - CAIO approval

**Quality Checks:**
- All centralized artifacts updated
- Lessons learned documented
- Metrics current
- Execution artifacts archived
- Workflow complete
</actions>

<outputs>
- All centralized artifacts updated (RAIDD, Backlog, Defects)
- lessons-learned.md created
- Project metrics updated
- Execution artifacts archived
- Workflow complete

**Status Update:**
- Node/service operational
- All documentation complete
- Execution workflow complete
- Ready for operational use

**Next Workflow:** Project Closeout Workflow (`cc-project-closeout-workflow.md`) - when project fully complete
</outputs>

<duration>45-60 minutes</duration>
</phase>
</phases>

<quality_gates>
<gate name="pre-execution-ready" phase="0">
**Gate Question:** Are all prerequisites met to begin task execution?

**Pass Criteria:**
- ✅ Task breakdown approved and locked
- ✅ Test suite approved and locked
- ✅ All prerequisites met
- ✅ Infrastructure ready and accessible
- ✅ Team briefed

**Fail Actions:**
- Block execution workflow
- Notify CAIO of specific gaps
- Do NOT proceed until resolved
</gate>

<gate name="tests-passed" phase="4">
**Gate Question:** Have all critical tests passed and failures properly triaged?

**Pass Criteria:**
- ✅ All tests executed
- ✅ Coverage requirement met (100%)
- ✅ Critical tests passed
- ✅ P0 defects resolved (cannot proceed with P0 open)
- ✅ P1 defects documented and mitigated

**Fail Actions:**
- If critical tests fail: STOP, create P0 defects, escalate to CAIO, must fix before promotion
- If coverage insufficient: Execute missing tests
- Do NOT proceed to operational promotion with P0 defects
</gate>

<gate name="verification-complete" phase="5">
**Gate Question:** Has Agent Zero verified all quality gates and execution completeness?

**Pass Criteria:**
- ✅ All tasks complete and documented
- ✅ All tests executed and documented
- ✅ Quality gates met or exceptions documented
- ✅ Operational readiness confirmed
- ✅ Completion report created

**Fail Actions:**
- If gaps found: Complete missing work
- If quality gates not met: Remediate or document acceptable risk
</gate>

<gate name="caio-approved" phase="6">
**Gate Question:** Has CAIO formally approved operational promotion?

**Pass Criteria:**
- ✅ CAIO reviewed completion report
- ✅ Approval documented
- ✅ Conditions (if any) documented
- ✅ Open items acceptance documented

**Fail Actions:**
- If remediation required: Fix issues, re-test, re-submit
- If rollback directed: Execute rollback, fix root cause, retry
</gate>
</quality_gates>

<issue_management>
<classification>
**Issue Severity Classification:**

**P0 - Critical:**
- Deployment completely blocked
- Data loss or corruption
- Security vulnerability
- Service down and cannot recover
**Action:** Stop execution, escalate to CAIO immediately

**P1 - High:**
- Major functionality not working
- Significant performance issue
- Test failure on critical path
- Deployment can continue with workaround
**Action:** Document, create defect, workaround if possible, escalate

**P2 - Medium:**
- Minor functionality issue
- Non-critical test failure
- Performance acceptable but not optimal
- Quality concern
**Action:** Document, create defect, continue execution, fix later

**P3 - Low:**
- Cosmetic issue
- Nice-to-have not working
- Minor optimization opportunity
**Action:** Document in backlog, continue execution
</classification>

<defect_creation>
**When to Create Defect:**
- Test fails
- Verification step fails
- Issue impacts quality or functionality
- Deviation from specification
- Security concern
- Performance below expectations

**Defect Location:**
`/nodes/[node-name]/defects/defect-[node]-[severity]-###-[description].md`

**Defect Content:**
- Description
- Steps to reproduce
- Expected vs actual behavior
- Impact
- Related items (task, test, spec requirement)
- Root cause (if known)
- Remediation plan
- Assignment
- Resolution (when resolved)
</defect_creation>

<rollback>
**When to Rollback:**
- Critical (P0) issue cannot be resolved quickly
- System stability compromised
- Data integrity at risk
- CAIO directs rollback

**Rollback Process:**
1. Agent Zero initiates rollback (document decision, notify team)
2. Execute task-specific rollback procedures in reverse order
3. Post-rollback verification (system stable, no data loss)
4. Post-rollback actions (root cause analysis, fix, update plans, retry when ready)
</rollback>
</issue_management>

<related_documents>
**Workflow Context:**
- **Previous:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Creates approved task breakdown and test suite
- **Next:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-project-closeout-workflow.md` - Closes out completed project

**Procedure Files:**
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Context loading for execution phase
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team structure

**Templates:**
- `/home/agent0/HX-Infrastructure/templates/test-execution-template.md` - Test execution result template
- `/home/agent0/HX-Infrastructure/templates/defect-template.md` - Defect documentation template

**Standards:**
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - Testing requirements (100% coverage)
- `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Deployment standards

**Reference Documents:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance principles
</related_documents>

<critical_reminders>
**DO:**
- ✅ Use continuous process pattern (context → execute → document = ONE session)
- ✅ Follow TDD approach (write tests before implementation where applicable)
- ✅ Document results IMMEDIATELY while context fresh
- ✅ Respect task dependencies and sequence
- ✅ Execute verification steps for every task
- ✅ Create defects for all issues found
- ✅ Update execution-tracking.md continuously
- ✅ Run all tests after implementation complete
- ✅ Get CAIO approval before operational promotion
- ✅ Update all centralized artifacts

**DON'T:**
- ❌ Pause between context load and execution (causes state loss)
- ❌ Pause between execution and documentation (lose details)
- ❌ Skip task verification steps
- ❌ Skip test execution
- ❌ Proceed to operational with P0 defects open
- ❌ Skip CAIO approval
- ❌ Promote to operational without monitoring configured
- ❌ Skip lessons learned documentation

**For Stateless Agents:**
- Context load + execution + documentation = ONE continuous process
- Do NOT pause between steps
- Breaking continuity = losing state = incomplete documentation = UNACCEPTABLE

**For Agent Zero:**
- Maintains state throughout execution phase
- Coordinates all activities
- Monitors progress continuously
- Reviews all results
- Triages all defects
- Makes rollback decisions (with CAIO approval)
- Final verification before CAIO

**For Julia (Testing Agent):**
- Executes test suite AFTER all implementation complete
- Follows systematic test execution by category
- Documents all results comprehensively
- Creates defects for failures
- Provides clear recommendation

**For CAIO:**
- Final approval authority
- Reviews execution completion report
- Can approve, approve with conditions, require remediation, or direct rollback
- Approval required before operational promotion

**For All:**
- Quality over speed - always
- Test-driven deployment - non-negotiable
- Documentation comprehensive - required
- Defect tracking complete - mandatory
- Safety first - rollback if needed
</critical_reminders>

<validation_checklist>
**Before operational promotion, verify:**

**Execution:**
- [ ] All tasks executed according to plan
- [ ] All task results documented comprehensively
- [ ] All verifications passed
- [ ] All deliverables created

**Testing:**
- [ ] All tests executed
- [ ] Test coverage requirement met (100%)
- [ ] Critical tests passed
- [ ] Test failures triaged and acceptable

**Quality:**
- [ ] No P0 defects open
- [ ] P1 defects documented with mitigation
- [ ] All success criteria from charter met
- [ ] All requirements from spec implemented
- [ ] Service/node operational and healthy

**Documentation:**
- [ ] All task results documented
- [ ] All test executions documented
- [ ] All defects documented
- [ ] Execution tracking complete
- [ ] Lessons learned captured

**Operational:**
- [ ] Service running and stable
- [ ] Health checks passing
- [ ] Monitoring configured
- [ ] Logging configured
- [ ] Alerting configured (if applicable)
- [ ] Operational documentation complete
- [ ] Runbook created (if needed)

**Approvals:**
- [ ] Agent Zero verified
- [ ] CAIO approved (with or without conditions)

**Artifacts:**
- [ ] RAIDD log updated
- [ ] Backlog updated
- [ ] Defect log updated
- [ ] Inventory updated
- [ ] Network documentation updated
- [ ] Status updated to OPERATIONAL
</validation_checklist>

<metadata_footer>
**Document Version:** 1.1
**Last Updated:** 2025-11-24
**Status:** APPROVED - Production Workflow
**Maintained By:** Agent Zero (CC)
**Related Workflows:** Charter Creation → Specification Development → Task Breakdown → **Task Execution** → Project Closeout
**Purpose:** Systematic execution of approved tasks with test-driven deployment and comprehensive documentation
</metadata_footer>
