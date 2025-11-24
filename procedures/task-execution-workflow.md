# Task Execution Workflow
## Systematic Execution of Approved Tasks with Test-Driven Deployment

**Document Type:** Procedure - Project Lifecycle Workflow (Phase 4: Task Execution)
**Version:** 1.1
**Date:** 2025-11-21
**Status:** APPROVED - Production Ready v1.1
**Location:** `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md`

**Purpose:** Define systematic workflow for executing approved tasks with comprehensive result documentation and test-driven deployment
**Trigger:** Task breakdown and test suite approved
**Input:** Approved task breakdown, approved test suite, all prerequisites met
**Output:** All tasks executed, tests passed, node/service operational and promoted
**Previous Version:** 1.0 → 1.1 (infrastructure philosophy integration, command documentation, comprehensive metadata)

---

## Document Purpose

This procedure defines the **Task Execution Workflow** - the fourth major phase in the HX-Infrastructure project lifecycle. Following approved task breakdown and test suite, this workflow systematically executes all tasks with test-driven deployment validation, comprehensive documentation, and operational promotion.

### Target Audience
- **Agent Zero (CC):** Primary coordinator for all 8 execution phases
- **Core Team (Alex, Frank, William):** Task execution for their respective domains
- **Project-Specific Agents:** Specialized task execution (Drew, database agents, framework agents)
- **Julia Santos (Testing Agent):** Test suite execution after implementation tasks complete
- **CAIO:** Final approval authority for operational promotion

### Related Documents
- **Prerequisites:** `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Task breakdown and test suite must be approved
- **Next Phase:** `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` - Final documentation and handoff
- **Context Loading:** `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Critical for Phase 2
- **Team Structure:** `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team roles during execution
- **Standards:** `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage validation
- **Standards:** `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Deployment approach validation

---

## 🎯 Workflow Overview

**Task execution is a disciplined, test-driven process:**

1. **Pre-Execution:** Agent Zero validates readiness and assigns tasks
2. **Task Execution:** Team members execute tasks following TDD approach (continuous process)
3. **Test Execution:** Tests run after implementation (validation)
4. **Issue Resolution:** Defects tracked and resolved systematically
5. **Verification:** Agent Zero validates all tasks complete and tests pass
6. **Final Approval:** CAIO approves operational promotion
7. **Post-Execution:** Update all artifacts, promote to operational

**Key Principles:**
- **Test-Driven Deployment (TDD):** Tests written BEFORE implementation, validated AFTER
- **Infrastructure Philosophy Compliance:** All execution validates bare metal, systemd, manual procedures, Ansible Vault
- **Continuous Process:** Context load + execution + documentation = ONE process (stateless agents)
- **Dependency Respect:** Execute tasks in approved sequence, respect dependencies
- **Quality Gates:** Tests must pass before operational promotion
- **Comprehensive Documentation:** Every task execution documented with results

**Critical Difference from Planning Phases:**
- Planning phases = CREATE documentation (charter, spec, tasks, tests)
- Execution phase = EXECUTE tasks and DOCUMENT results

---

## HX-Infrastructure Philosophy Validation

All task execution MUST validate compliance with HX-Infrastructure deployment philosophy:

### Infrastructure Philosophy Checkpoints During Execution

**Bare Metal Deployment Validation:**
- Verify all installation tasks target Ubuntu 24.04 LTS bare metal servers (not Docker containers)
- Confirm no production deployment uses Docker (exception: hx-dev-server for dev/isolation only)
- Validate server provisioning completed on physical or VM infrastructure

**Systemd Service Management Validation:**
- Verify systemd service units created for all services
- Confirm services enabled and started via systemd
- Validate service health via `systemctl status` checks
- Test service restart and recovery procedures

**Manual Procedure Compliance:**
- Verify all deployment steps executed manually (no Ansible playbooks for deployment automation)
- Confirm step-by-step procedures documented in task result files
- Validate reproducibility of manual procedures
- Document any deviations from manual approach

**Ansible Vault Credential Validation:**
- Verify all credentials stored in Ansible Vault (no inline secrets, no local users)
- Confirm credentials retrieved via `ansible-vault view` commands
- Validate no plaintext secrets in configuration files
- Test credential rotation procedures

### Quality Gate: Infrastructure Philosophy Compliance (Phase 5)

Before CAIO approval, Agent Zero validates:
- [ ] All services deployed on bare metal (or approved dev exception)
- [ ] All services managed via systemd units
- [ ] All procedures executed manually and documented
- [ ] All credentials in Ansible Vault

**See also:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Infrastructure philosophy requirements in specification

---

## 📋 Complete Workflow Phases

### **PHASE 0: Pre-Execution Readiness Check**

**Agent Zero Validates:**
```
✓ Task Breakdown: APPROVED and LOCKED
✓ Test Suite: APPROVED and LOCKED
✓ All Prerequisites: Met and verified
✓ Team Assignments: Clear and documented
✓ Infrastructure: Ready (target node accessible)
✓ Credentials: Available in vault (if needed)
✓ Backups: Completed (if modifying existing systems)
✓ Rollback Plan: Documented per task

If ANY prerequisite missing → Block and notify CAIO
```

**Documents to Validate:**
- `/nodes/[node-name]/tasks/task-breakdown-summary.md` (Status: APPROVED)
- `/nodes/[node-name]/tests/test-plan.md` (Status: APPROVED)
- `/nodes/[node-name]/tests/test-suite-index.md` (Complete)
- All individual task files present and numbered
- All test case files present and mapped to tasks
- Infrastructure prerequisites verified
- Network connectivity confirmed
- Required credentials available

**Execution Readiness Checklist:**
```
Pre-Execution Validation:
- [ ] Task breakdown approved and locked
- [ ] Test suite approved and locked
- [ ] All task files created and numbered
- [ ] All test files created and mapped
- [ ] Task dependencies documented
- [ ] Parallel tasks identified [P]
- [ ] Critical path identified
- [ ] Team assignments confirmed
- [ ] Target infrastructure accessible
- [ ] Network connectivity verified
- [ ] Required ports available
- [ ] Credentials available in vault
- [ ] Backup completed (if applicable)
- [ ] Rollback procedures documented
- [ ] Execution order validated
```

**Agent Zero Actions:**
```
1. Review task breakdown:
   ├─ Confirm all tasks numbered sequentially
   ├─ Verify dependencies clear
   ├─ Identify execution batches
   └─ Note parallel execution opportunities [P]

2. Create execution tracking:
   Location: /nodes/[node-name]/execution-tracking.md
   Contents:
   ├─ Task status matrix (Not Started/In Progress/Complete/Failed)
   ├─ Agent assignments
   ├─ Execution timeline
   ├─ Dependency tracking
   ├─ Test execution tracking
   └─ Issue tracking

3. Review test suite:
   ├─ Confirm all tasks have corresponding tests
   ├─ Verify test execution order
   ├─ Note test dependencies
   └─ Prepare test execution schedule

4. Brief team on execution approach:
   ├─ Task sequence
   ├─ TDD requirement (tests before implementation)
   ├─ Parallel execution strategy
   ├─ Documentation requirements
   └─ Communication protocol
```

✓ **GATE:** All prerequisites met, team briefed → Proceed to Phase 1

---

### **PHASE 1: Task Assignment and Prioritization**

**Agent Zero Assigns Tasks:**

```
Task Assignment Strategy:

1. Review task breakdown:
   ├─ Pre-deployment tasks (001-0XX)
   ├─ Installation tasks (0XX-0XX)
   ├─ Integration tasks (0XX-0XX)
   ├─ Post-deployment tasks (0XX-0XX)
   └─ Test suite execution (Julia)

2. Assign to agents based on expertise:
   ├─ Alex → Architecture/integration tasks
   ├─ Frank → Identity/DNS/security tasks
   ├─ William → OS/system/infrastructure tasks
   ├─ Drew → Agentic patterns tasks (if applicable)
   ├─ Julia → Test execution (AFTER implementation tasks)
   └─ [Others] → Domain-specific tasks

3. Create execution batches:
   Batch 1 (Sequential): Pre-deployment tasks (no dependencies)
   Batch 2 (May parallel): Installation tasks (some can run [P])
   Batch 3 (Sequential): Integration tasks (depend on Batch 2)
   Batch 4 (May parallel): Post-deployment documentation [P]
   Batch 5 (Sequential): Test execution (after ALL implementation)

4. Document assignments:
   Location: /nodes/[node-name]/task-assignments-execution.md
   Format:
   | Task ID | Description | Assigned To | Batch | Status |
   |---------|-------------|-------------|-------|--------|
   | [node]-task-001 | [desc] | [agent] | 1 | Not Started |
   | [node]-task-002 | [desc] | [agent] | 1 | Not Started |
```

**Parallel Execution Groups:**
```
Identify which tasks can run simultaneously:

Group A (Parallel): Tasks marked [P] with no dependencies
├─ [node]-task-003 [P] - Backup configurations
├─ [node]-task-004 [P] - Download packages
└─ [node]-task-005 [P] - Verify network ports

Group B (Parallel): Configuration tasks [P]
├─ [node]-task-012 [P] - Create config file A
├─ [node]-task-013 [P] - Create config file B
└─ [node]-task-014 [P] - Create config file C

Sequential: Tasks with dependencies
├─ [node]-task-006 - Install system deps (blocks task-007)
├─ [node]-task-007 - Install service (depends on task-006)
└─ [node]-task-008 - Configure service (depends on task-007)
```

**Time Estimate:** 30-45 minutes

**Output:** 
- Task assignments documented
- Execution batches defined
- Parallel groups identified
- Team ready to begin execution

---

### **PHASE 2: Task-by-Task Execution (TDD Approach)**

**For Each Task, Agent Performs:**

**⚠️ CRITICAL TDD REQUIREMENT:**
```
For Implementation Tasks:
1. Write test(s) FIRST (if not already written by Julia)
2. Verify test FAILS initially
3. Execute implementation task
4. Verify test PASSES after implementation
5. Document results

For Test Creation Tasks:
- Tests written during task breakdown (Phase 3 of task workflow)
- Already complete when execution begins
```

#### **EXECUTION PATTERN: Continuous Process**

**Each Agent Executing Tasks:**

```
STEP 1: Context Loading (15-20 minutes)
   
   See: /home/agent0/HX-Infrastructure/procedures/context-loading-process.md - "TASK EXECUTION PHASE" checklist
   
   Agent loads execution context:
   ├─ Approved charter (goals, success criteria)
   ├─ Approved specification (requirements)
   ├─ Approved task breakdown (ALL tasks)
   ├─ Assigned task(s) for execution
   ├─ Task dependencies
   ├─ Test suite (tests for their tasks)
   ├─ RAIDD log (risks to be aware of)
   ├─ Defect log (known issues)
   ├─ Infrastructure details (target node, IPs, ports)
   └─ Credentials (from vault, if needed)

STEP 2: IMMEDIATE Task Execution (varies by task)
   ↓ DO NOT PAUSE BETWEEN STEP 1 AND STEP 2 ↓
   
   While context is fresh:
   
   A. Read assigned task file:
      ├─ Task objective
      ├─ Prerequisites
      ├─ Detailed steps
      ├─ Deliverables
      ├─ Verification steps
      └─ Rollback procedure
   
   B. Verify prerequisites met:
      ├─ Check all prerequisite conditions
      ├─ Verify dependent tasks completed
      ├─ Confirm infrastructure ready
      └─ If prerequisites NOT met → Document and wait
   
   C. Execute task steps:
      ├─ Follow steps exactly as documented
      ├─ Execute commands/actions
      ├─ Create deliverables
      ├─ Capture output/logs
      └─ Note any deviations or issues
   
   D. Verify task completion:
      ├─ Run verification steps from task
      ├─ Check deliverables created
      ├─ Validate expected state achieved
      └─ If verification fails → Document issue as defect
   
   E. Test validation (if applicable):
      ├─ Run corresponding test(s) for this task
      ├─ Verify test passes
      ├─ If test fails → Document as defect
      └─ If test passes → Task complete

STEP 3: IMMEDIATE Result Documentation (10-15 minutes)
   ↓ DO NOT PAUSE - DOCUMENT IMMEDIATELY ↓
   
   Location: /nodes/[node-name]/task-results/[task-id]-result.md
   
   Document:
   ├─ Task completion status (Complete/Failed/Blocked)
   ├─ Execution timestamp (start and end)
   ├─ Steps executed (what was done)
   ├─ Output/logs captured
   ├─ Verification results
   ├─ Test execution results (pass/fail)
   ├─ Issues encountered (if any)
   ├─ Deviations from plan (if any)
   ├─ Defects created (if any)
   └─ Next steps (if blocked or failed)
```

**Why Continuous Process?**
```
❌ WRONG: Load context → Execute task → Wait → Document later
   Result: Agent loses state, forgets details, incomplete documentation

✅ CORRECT: Load context → Execute → Document immediately → Complete
   Result: Agent maintains context, captures all details, complete documentation
```

#### **Task Result Documentation Template**

```markdown
# Task Execution Result: [Task ID]

**Task ID:** [node-name]-task-###-[description]
**Task Title:** [task title from task file]
**Assigned To:** [agent-name]
**Execution Date:** [YYYY-MM-DD]
**Execution Time:** [HH:MM] - [HH:MM] (duration: [X] minutes)
**Status:** [Complete | Failed | Blocked | Partial]

---

## Task Objective
[What this task was supposed to accomplish - from task file]

## Prerequisites Verified
- [x] [Prerequisite 1] - Verified at [timestamp]
- [x] [Prerequisite 2] - Verified at [timestamp]
- [x] [Prerequisite 3] - Verified at [timestamp]

## Execution Steps

### Step 1: [Step description]
**Command/Action:** `[exact command or action]`
**Output:**
```
[captured output or result]
```
**Status:** ✅ Success | ❌ Failed | ⚠️ Warning

### Step 2: [Step description]
**Command/Action:** `[exact command or action]`
**Output:**
```
[captured output or result]
```
**Status:** ✅ Success | ❌ Failed | ⚠️ Warning

### Step 3: [Step description]
**Command/Action:** `[exact command or action]`
**Output:**
```
[captured output or result]
```
**Status:** ✅ Success | ❌ Failed | ⚠️ Warning

[Continue for all steps...]

---

## Deliverables Created

| Deliverable | Location | Status | Verified |
|------------|----------|--------|----------|
| [file/config/service] | [path] | Created | ✅ Yes |
| [file/config/service] | [path] | Created | ✅ Yes |

---

## Verification Results

### Verification Step 1: [Verification description]
**Method:** [how verified]
**Expected:** [expected result]
**Actual:** [actual result]
**Result:** ✅ Pass | ❌ Fail

### Verification Step 2: [Verification description]
**Method:** [how verified]
**Expected:** [expected result]
**Actual:** [actual result]
**Result:** ✅ Pass | ❌ Fail

[Continue for all verification steps...]

**Overall Verification:** ✅ All checks passed | ❌ [X] checks failed

---

## Test Execution

### Test: [Test ID] - [Test description]
**Test File:** [path to test case file]
**Execution Time:** [HH:MM]
**Result:** ✅ PASS | ❌ FAIL
**Test Output:**
```
[test execution output]
```

**If FAIL:**
- **Failure Reason:** [why test failed]
- **Defect Created:** [defect-ID]
- **Next Steps:** [remediation plan]

[Repeat for each test mapped to this task]

---

## Issues Encountered

### Issue 1: [Issue description]
**Severity:** [Critical | High | Medium | Low]
**Impact:** [what was impacted]
**Resolution:** [how resolved or "See defect [ID]"]
**Time Lost:** [X minutes]

### Issue 2: [Issue description]
**Severity:** [Critical | High | Medium | Low]
**Impact:** [what was impacted]
**Resolution:** [how resolved or "See defect [ID]"]
**Time Lost:** [X minutes]

[If no issues: "None encountered"]

---

## Deviations from Plan

### Deviation 1: [What was different]
**Original Plan:** [what task file said]
**Actual Execution:** [what was actually done]
**Reason:** [why deviation occurred]
**Approved By:** [Agent Zero | CAIO | Emergency decision]
**Impact:** [impact of deviation]

[If no deviations: "Task executed exactly as planned"]

---

## Defects Created

| Defect ID | Title | Severity | Status | Link |
|-----------|-------|----------|--------|------|
| [defect-ID] | [title] | [severity] | Open | [path to defect file] |
| [defect-ID] | [title] | [severity] | Open | [path to defect file] |

[If no defects: "No defects identified"]

---

## Rollback Capability

**Can this task be rolled back?** [Yes | No | Partial]

**Rollback Procedure:**
[If Yes: document rollback steps]
[If No: explain why and what forward-fix would be needed]
[If Partial: explain what can/cannot be rolled back]

**Rollback Tested?** [Yes | No]
[If Yes: document test results]

---

## Integration Points Validated

| Integration | Status | Notes |
|-------------|--------|-------|
| [Service/component] | ✅ Verified | [how verified] |
| [Service/component] | ✅ Verified | [how verified] |

---

## Next Steps

**Dependent Tasks Unblocked:**
- [task-ID]: Now ready for execution
- [task-ID]: Now ready for execution

**Follow-up Required:**
- [Action item 1]
- [Action item 2]

**Status Update:**
- Updated execution-tracking.md: Task status → Complete
- Notified Agent Zero: Task complete, verification passed

---

## Time Breakdown

| Phase | Duration |
|-------|----------|
| Context Loading | [X] minutes |
| Prerequisite Verification | [X] minutes |
| Task Execution | [X] minutes |
| Verification | [X] minutes |
| Test Execution | [X] minutes |
| Documentation | [X] minutes |
| **Total** | **[Total] minutes** |

**Planned Time:** [X] minutes (from task estimate)
**Actual Time:** [Y] minutes
**Variance:** [+/-X] minutes

---

## Agent Notes

[Any additional notes, observations, recommendations, or lessons learned]

---

## Approval

**Self-Verified:** [agent-name] - [timestamp]
**Agent Zero Review:** [Pending | Approved | Issues found]
**Issues to Address:** [List any issues Agent Zero identified]
```

---

### **PHASE 3: Continuous Execution Coordination**

**Agent Zero Coordinates Execution:**

```
Ongoing Coordination Activities:

1. Monitor execution-tracking.md:
   ├─ Update task statuses as reported
   ├─ Track which tasks complete
   ├─ Identify blocked tasks
   ├─ Note failed tasks
   └─ Calculate progress percentage

2. Unblock dependencies:
   ├─ When task completes → notify dependent agents
   ├─ Verify prerequisites for next tasks
   ├─ Release next batch if batch complete
   └─ Coordinate parallel execution

3. Review task results:
   ├─ Read each [task-id]-result.md as completed
   ├─ Verify verification passed
   ├─ Check test execution results
   ├─ Identify issues or defects
   └─ Approve completion or request remediation

4. Issue management:
   ├─ Review defects created
   ├─ Triage severity and priority
   ├─ Assign remediation
   ├─ Track resolution
   └─ Update RAIDD log with new risks

5. Communication:
   ├─ Daily progress updates to CAIO
   ├─ Alert on blockers immediately
   ├─ Escalate critical issues
   └─ Celebrate milestones
```

**Execution Tracking Document:**

Location: `/nodes/[node-name]/execution-tracking.md`

```markdown
# Task Execution Tracking: [Node Name]

**Start Date:** [YYYY-MM-DD]
**Target Completion:** [YYYY-MM-DD]
**Status:** [In Progress | Complete | Blocked | Failed]

---

## Progress Summary

**Total Tasks:** [N]
**Completed:** [X] ([%])
**In Progress:** [Y]
**Blocked:** [Z]
**Failed:** [A]

**Tests Passed:** [M]/[Total]
**Defects Open:** [B]
**Critical Blockers:** [C]

---

## Task Status Matrix

| Task ID | Description | Assigned | Batch | Status | Tests | Issues |
|---------|-------------|----------|-------|--------|-------|--------|
| task-001 | [desc] | [agent] | 1 | ✅ Complete | ✅ Pass | None |
| task-002 | [desc] | [agent] | 1 | 🔄 In Progress | - | None |
| task-003 | [desc] | [agent] | 2 | ⏸️ Blocked | - | Waiting |
| task-004 | [desc] | [agent] | 2 | ❌ Failed | ❌ Fail | defect-001 |

Legend:
- ⏸️ Not Started
- 🔄 In Progress
- ✅ Complete
- ❌ Failed
- ⏸️ Blocked

---

## Current Batch Status

**Batch 1: Pre-Deployment** [Status: Complete]
- All tasks complete
- All verifications passed
- Ready for Batch 2

**Batch 2: Installation** [Status: In Progress]
- [X]/[N] tasks complete
- [Y] tasks in progress
- [Z] tasks blocked
- Blocker: [description]

---

## Critical Path Status

Critical Path Tasks:
1. task-001 → ✅ Complete (on time)
2. task-007 → 🔄 In Progress (on track)
3. task-015 → ⏸️ Not Started (on schedule)
4. task-023 → ⏸️ Not Started (on schedule)

**Critical Path Status:** ✅ On Track | ⚠️ At Risk | ❌ Delayed

---

## Blockers and Issues

### Active Blockers
1. **Task-003:** Waiting for [prerequisite]
   - Impact: Blocks tasks [list]
   - ETA Resolution: [date/time]
   - Assigned: [who's resolving]

### Open Issues
1. **defect-001:** [title]
   - Severity: [level]
   - Impact: [description]
   - Status: [Open | In Progress | Resolved]
   - Assigned: [agent]

---

## Test Execution Status

**Deployment Tests:** [X]/[N] passed
**Functionality Tests:** [X]/[N] passed
**Integration Tests:** [X]/[N] passed
**Health Check Tests:** [X]/[N] passed

**Overall Test Status:** [X]% passed

---

## Timeline

**Actual vs Planned:**
- Planned Start: [date]
- Actual Start: [date]
- Planned Complete: [date]
- Projected Complete: [date]
- Variance: [+/- days]

---

## Last Updated
**Date:** [YYYY-MM-DD HH:MM]
**By:** Agent Zero
**Next Update:** [YYYY-MM-DD HH:MM]
```

---

### **PHASE 4: Test Suite Execution**

**Trigger:** ALL implementation tasks complete

**Julia (Testing Agent) Executes Test Suite:**

```
Julia's Test Execution Process:

STEP 1: Pre-Test Verification (15 minutes)
   ├─ Verify all implementation tasks complete
   ├─ Verify all deliverables created
   ├─ Verify infrastructure in expected state
   └─ Review any defects from implementation

STEP 2: Test Execution (varies by test suite size)
   
   Execute tests by category:
   
   A. Deployment Validation Tests (run first):
      ├─ Installation verification tests
      ├─ Configuration verification tests
      ├─ Dependency verification tests
      └─ Service startup tests
   
   B. Functionality Tests (run second):
      ├─ Core functionality tests
      ├─ Feature tests
      └─ Error handling tests
   
   C. Integration Tests (run third):
      ├─ External service integration tests
      ├─ Database integration tests
      ├─ API integration tests
      └─ Inter-component tests
   
   D. Health Check Tests (run fourth):
      ├─ Health endpoint tests
      ├─ Resource usage tests
      ├─ Performance baseline tests
      └─ Monitoring tests
   
   E. Security Tests (run last, if applicable):
      ├─ Authentication tests
      ├─ Authorization tests
      └─ Security configuration tests

STEP 3: Test Result Documentation (per test)
   
   For EACH test executed:
   Location: /nodes/[node-name]/tests/test-executions/[YYYY-MM-DD]-[test-id]-r[N].md
   (Use test-execution-template.md)
   
   Document:
   ├─ Test execution timestamp
   ├─ Test steps performed
   ├─ Actual results
   ├─ Pass/Fail determination
   ├─ Screenshots/logs (if applicable)
   ├─ Defects created (if failed)
   └─ Recommendations

STEP 4: Test Suite Summary
   
   Location: /nodes/[node-name]/tests/test-execution-summary.md
   
   Summary:
   ├─ Total tests executed
   ├─ Tests passed
   ├─ Tests failed
   ├─ Tests skipped (with reason)
   ├─ Coverage achieved
   ├─ Defects created
   ├─ Overall assessment
   └─ Recommendation (promote to operational or fix defects)
```

**Test Execution Decision Tree:**
```
If ALL tests pass:
   → Proceed to Phase 5 (Verification)

If SOME tests fail (P2/P3 severity):
   → Create defects
   → Agent Zero triages
   → May proceed with known issues
   → Or may require fixes before promotion

If CRITICAL tests fail (P0/P1 severity):
   → STOP execution
   → Create critical defects
   → Agent Zero escalates to CAIO
   → Must fix before operational promotion
   → Retest after fixes
```

---

### **PHASE 5: Completion Verification**

**Agent Zero Comprehensive Verification:**

```
Verification Checklist:

1. Task Completion:
   - [ ] All tasks executed
   - [ ] All task results documented
   - [ ] All verifications passed
   - [ ] All deliverables created
   - [ ] No blocked tasks remaining

2. Test Execution:
   - [ ] All tests executed
   - [ ] Test results documented
   - [ ] Coverage requirement met (100% per testing-requirements.md)
   - [ ] Test failures triaged
   - [ ] Critical tests passed

3. Quality Gates:
   - [ ] No P0 defects open
   - [ ] P1 defects documented with mitigation
   - [ ] All success criteria from charter met
   - [ ] All requirements from spec implemented
   - [ ] Infrastructure stable

4. Documentation:
   - [ ] All task results documented
   - [ ] All test executions documented
   - [ ] All defects documented
   - [ ] Execution tracking complete
   - [ ] Lessons learned captured

5. Operational Readiness:
   - [ ] Service running and stable
   - [ ] Health checks passing
   - [ ] Monitoring configured
   - [ ] Logging configured
   - [ ] Alerting configured (if applicable)
   - [ ] Documentation complete
   - [ ] Runbook created (if needed)
```

**Agent Zero Creates Final Report:**

Location: `/nodes/[node-name]/execution-completion-report.md`

```markdown
# Execution Completion Report: [Node Name]

**Execution Start:** [date]
**Execution Complete:** [date]
**Total Duration:** [X days/hours]
**Overall Status:** [Success | Success with Issues | Failed]

---

## Executive Summary

[High-level summary of execution: what was deployed, overall success, major issues]

---

## Execution Metrics

| Metric | Planned | Actual | Variance |
|--------|---------|--------|----------|
| Total Tasks | [N] | [N] | - |
| Tasks Completed | [N] | [X] | [+/-] |
| Tests Executed | [N] | [X] | [+/-] |
| Tests Passed | [N] | [X] | [+/-] |
| Defects Created | - | [X] | - |
| Duration | [N hours] | [X hours] | [+/-] |

---

## Success Criteria Assessment

| Criterion (from Charter) | Status | Evidence |
|--------------------------|--------|----------|
| [criterion 1] | ✅ Met | [reference] |
| [criterion 2] | ✅ Met | [reference] |
| [criterion 3] | ⚠️ Partial | [explanation] |

---

## Quality Gates Status

- **Task Completion:** ✅ All tasks complete
- **Test Coverage:** ✅ 100% coverage achieved
- **Test Pass Rate:** [X]% ([Y]/[Z] tests passed)
- **Critical Tests:** ✅ All passed
- **P0 Defects:** ✅ None open
- **P1 Defects:** [N] open (documented, mitigated)
- **Operational Health:** ✅ Service healthy and stable

---

## Open Issues

| Defect ID | Severity | Title | Status | Mitigation |
|-----------|----------|-------|--------|------------|
| [ID] | P1 | [title] | Open | [mitigation] |
| [ID] | P2 | [title] | Open | [planned fix] |

---

## Lessons Learned

### What Went Well
1. [Success 1]
2. [Success 2]

### What Could Be Improved
1. [Improvement 1]
2. [Improvement 2]

### Recommendations for Future Deployments
1. [Recommendation 1]
2. [Recommendation 2]

---

## Recommendation

**Agent Zero Recommendation:** [Promote to Operational | Fix Issues First | Rollback]

**Justification:** [rationale for recommendation]

**Next Steps:** [what needs to happen next]
```

---

### **PHASE 6: CAIO Final Approval**

**CAIO Reviews:**
```
CAIO reviews execution completion:
├─ Execution completion report
├─ Execution tracking document
├─ Test execution summary
├─ Open defects (severity and mitigation)
├─ Success criteria assessment
└─ Agent Zero recommendation

Approval Criteria:
├─ All critical tasks complete
├─ All critical tests pass
├─ No P0 defects open
├─ P1 defects acceptable with mitigation
├─ Service operational and healthy
├─ Success criteria met (or acceptable gaps documented)
└─ Documentation complete

Decision Options:
1. **Approve for Operational Promotion** → Proceed to Phase 7
2. **Approve with Conditions** → Document conditions, proceed to Phase 7
3. **Require Remediation** → Fix issues, re-test, re-submit
4. **Rollback** → Issues too severe, rollback deployment
```

**CAIO Approval Documentation:**

Location: `/nodes/[node-name]/caio-operational-approval.md`

```markdown
# CAIO Operational Approval: [Node Name]

**Date:** [YYYY-MM-DD]
**Reviewed By:** [CAIO name]
**Decision:** [Approved | Approved with Conditions | Remediation Required | Rollback]

---

## Review Summary

[CAIO's assessment of execution and readiness]

---

## Approval Conditions (if applicable)

1. [Condition 1]
2. [Condition 2]

---

## Open Items Accepted

| Item | Severity | Acceptance Rationale |
|------|----------|---------------------|
| [defect] | P1 | [why acceptable] |

---

## Signature

**Approved By:** [CAIO name]
**Date:** [YYYY-MM-DD]
**Time:** [HH:MM]
```

✓ **GATE:** CAIO Approved → Proceed to Phase 7 (Promotion to Operational)

---

### **PHASE 7: Promotion to Operational**

**Agent Zero Executes Promotion:**

```
Promotion Actions:

1. Update node/service status:
   ├─ /nodes/[node-name]/STATUS.md
   │   └─ Status: Ready for Execution → OPERATIONAL
   ├─ /nodes/[node-name]/node-spec.md
   │   └─ Status section: OPERATIONAL
   └─ Mark deployment date

2. Update inventory:
   ├─ /inventory/nodes.md
   │   └─ Add node with OPERATIONAL status
   ├─ /inventory/services.md (if service)
   │   └─ Add service with OPERATIONAL status
   └─ Update resource allocations

3. Update network documentation:
   ├─ /network/network-topology.md
   │   └─ Add node/service to topology
   ├─ /network/port-mapping.md
   │   └─ Document ports used
   └─ Update connectivity matrix

4. Move service to operational directory (if applicable):
   FROM: /services/non-operational/[service-name]/
   TO: /services/operational/[service-name]/
   
   Include:
   ├─ All specification documents
   ├─ All task files and results
   ├─ All test files and results
   ├─ All execution documentation
   └─ Operational runbooks

5. Create operational documentation:
   ├─ Runbook (if needed)
   ├─ Troubleshooting guide
   ├─ Monitoring setup
   ├─ Alerting configuration
   └─ Maintenance procedures

6. Configure monitoring:
   ├─ Add to monitoring system
   ├─ Configure health checks
   ├─ Set up alerting rules
   └─ Create dashboard (if applicable)
```

---

### **PHASE 8: Post-Execution Updates**

**Agent Zero Final Updates:**

```
1. Review and Update RAIDD Log:
   Location: /home/agent0/HX-Infrastructure/docs/raidd-log.md
   
   Add/Update entries:
   ├─ RISKS identified during execution
   ├─ ASSUMPTIONS validated or invalidated
   ├─ ISSUES encountered and resolved
   ├─ DEPENDENCIES confirmed
   └─ DECISIONS made during execution

2. Review and Update Backlog:
   Location: /home/agent0/HX-Infrastructure/docs/backlog.md
   
   Add deferred items:
   ├─ Future enhancements identified
   ├─ Optimizations to consider
   ├─ Technical debt created
   └─ Follow-up work needed

3. Review and Update Defect Log:
   Location: /home/agent0/HX-Infrastructure/docs/defect-log.md
   
   Update defect statuses:
   ├─ Mark resolved defects
   ├─ Keep open defects with mitigation
   ├─ Add newly discovered defects
   └─ Track remediation plans

4. Document lessons learned:
   Location: /nodes/[node-name]/lessons-learned.md
   
   Capture:
   ├─ What worked well
   ├─ What could be improved
   ├─ Process improvements
   ├─ Tool/technique effectiveness
   └─ Recommendations for future

5. Update project metrics:
   ├─ Node count (operational vs planned)
   ├─ Service count (operational vs planned)
   ├─ Test coverage achieved
   ├─ Deployment success rate
   └─ Time to deployment

6. Archive execution artifacts:
   ├─ All task results
   ├─ All test executions
   ├─ All defects
   ├─ Execution tracking
   └─ Completion report
```

**Time Estimate:** 45-60 minutes

**Output:** All artifacts updated, node/service operational, documentation complete

---

## ⏱️ Time Estimates

| Phase | Time | Who | Notes |
|-------|------|-----|-------|
| 0. Pre-Execution Check | 30-45 min | Agent Zero | Setup and validation |
| 1. Task Assignment | 30-45 min | Agent Zero | Assignment and prioritization |
| 2. Task Execution | Varies | All agents | Depends on task complexity |
| 3. Coordination | Ongoing | Agent Zero | Throughout execution |
| 4. Test Suite Execution | 2-4 hours | Julia | Comprehensive testing |
| 5. Completion Verification | 1-2 hours | Agent Zero | Full validation |
| 6. CAIO Approval | 30-60 min | CAIO | Review and decision |
| 7. Operational Promotion | 30-45 min | Agent Zero | Status updates |
| 8. Post-Execution Updates | 45-60 min | Agent Zero | Final artifact updates |

**Total Time:** Varies significantly based on:
- Number of tasks (could be 10-100+)
- Task complexity (minutes to hours each)
- Parallel execution opportunities
- Issues encountered
- Test suite size

**Typical Node Deployment:** 1-5 days
**Simple Service:** 4-8 hours
**Complex System:** 1-2 weeks

---

## ✅ Quality Gates

**Gate 1: Pre-Execution Ready**
- Task breakdown approved ✓
- Test suite approved ✓
- Prerequisites met ✓
- Team briefed ✓

**Gate 2: Task Assignments Complete**
- All tasks assigned ✓
- Execution batches defined ✓
- Dependencies clear ✓

**Gate 3: Implementation Complete**
- All tasks executed ✓
- All verifications passed ✓
- All deliverables created ✓

**Gate 4: Tests Pass**
- All tests executed ✓
- Critical tests pass ✓
- Coverage requirement met ✓
- Defects triaged ✓

**Gate 5: Verification Complete**
- Agent Zero verified ✓
- Quality gates met ✓
- Documentation complete ✓
- Operational readiness confirmed ✓

**Gate 6: CAIO Approval**
- CAIO reviewed ✓
- CAIO approved (with or without conditions) ✓

**Gate 7: Operational**
- Promoted to operational ✓
- Inventory updated ✓
- Monitoring configured ✓

**Gate 8: Artifacts Updated**
- RAIDD log updated ✓
- Backlog updated ✓
- Defect log updated ✓
- Lessons learned documented ✓

---

## 🚨 Issue Management During Execution

### **Issue Classification:**

```
P0 - Critical:
- Deployment completely blocked
- Data loss or corruption
- Security vulnerability
- Service down and cannot recover
Action: Stop execution, escalate to CAIO immediately

P1 - High:
- Major functionality not working
- Significant performance issue
- Test failure on critical path
- Deployment can continue with workaround
Action: Document, create defect, workaround if possible, escalate

P2 - Medium:
- Minor functionality issue
- Non-critical test failure
- Performance acceptable but not optimal
- Quality concern
Action: Document, create defect, continue execution, fix later

P3 - Low:
- Cosmetic issue
- Nice-to-have not working
- Minor optimization opportunity
Action: Document in backlog, continue execution
```

### **Defect Creation Process:**

**When to Create Defect:**
- Test fails
- Verification step fails
- Issue impacts quality or functionality
- Deviation from specification
- Security concern
- Performance below expectations

**Defect Documentation:**

Location: `/nodes/[node-name]/defects/defect-[node]-[severity]-###-[description].md`
(Use defect-template.md)

```markdown
# Defect: [Short Title]

**Defect ID:** defect-[node]-[severity]-###-[description]
**Severity:** [P0 | P1 | P2 | P3]
**Status:** [Open | In Progress | Resolved | Closed | Won't Fix]
**Created By:** [agent-name]
**Created Date:** [YYYY-MM-DD]
**Discovered During:** [Task execution | Test execution | Verification]

---

## Description
[Clear description of the issue]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Impact
[Impact on functionality, users, system]

## Related Items
- **Task:** [task-ID]
- **Test:** [test-ID]
- **Spec Requirement:** [requirement reference]

## Root Cause (if known)
[Analysis of what caused the issue]

## Remediation Plan
[How to fix the issue]

## Assigned To
[agent-name or "Unassigned"]

## Resolution (when resolved)
[How the issue was resolved]
[Date resolved]
[Resolved by]
```

### **Rollback Procedures:**

**When to Rollback:**
- Critical (P0) issue cannot be resolved quickly
- System stability compromised
- Data integrity at risk
- CAIO directs rollback

**Rollback Process:**
```
1. Agent Zero initiates rollback:
   ├─ Document rollback decision
   ├─ Notify team
   ├─ Execute rollback procedures (per task)
   └─ Verify system returned to pre-deployment state

2. Execute task-specific rollback:
   ├─ Follow rollback procedures from each task
   ├─ Execute in reverse order
   ├─ Verify each rollback step
   └─ Document rollback results

3. Post-rollback verification:
   ├─ System returned to stable state
   ├─ No data loss
   ├─ Services operational (if were before)
   └─ Document lessons learned

4. Post-rollback actions:
   ├─ Root cause analysis
   ├─ Fix issues
   ├─ Update task/test plans
   ├─ Re-execute when ready
   └─ Update RAIDD log
```

---

## 📁 File Structure

```
/nodes/[node-name]/
├── charter.md (APPROVED)
├── node-spec.md (APPROVED)
├── STATUS.md (tracks phase: Execution → Operational)
│
├── tasks/ (from task workflow)
│   ├── task-breakdown-summary.md (APPROVED)
│   ├── [node]-task-001-[description].md
│   ├── [node]-task-002-[description].md
│   └── ...
│
├── task-results/ (NEW - execution results)
│   ├── [node]-task-001-result.md
│   ├── [node]-task-002-result.md
│   └── ...
│
├── tests/ (from task workflow)
│   ├── test-plan.md (APPROVED)
│   ├── test-suite-index.md
│   ├── test-suite/
│   │   └── [test cases]
│   └── test-executions/ (NEW - execution results)
│       ├── [YYYY-MM-DD]-tc-[node]-[category]-###-r1.md
│       └── ...
│
├── defects/ (NEW - if issues found)
│   ├── defect-[node]-p1-001-[description].md
│   └── ...
│
├── execution-tracking.md (NEW - progress tracking)
├── execution-completion-report.md (NEW - final report)
├── caio-operational-approval.md (NEW - CAIO approval)
├── lessons-learned.md (NEW - post-execution)
│
└── reviews/ (from previous phases)
    └── [existing review documents]
```

---

## Claude Code Command Infrastructure Integration

### How Commands Invoke This Workflow

**Set 1: Workflow Commands (Primary Integration)**
- **`cc-task-execution-workflow.md`:** Primary command implementing this entire workflow
  - Invokes this procedure for systematic task execution
  - Coordinates all 8 phases from pre-execution through post-execution updates
  - Enforces test-driven deployment and infrastructure philosophy compliance
  - Manages defect tracking and issue escalation

**Set 3: Utility Commands (Supporting Tools)**
- **`artifact-tracker`:** Tracks all task results, test executions, defects generated
- **`doc-lint`:** Validates task result documentation format and completeness
- **`status-report`:** Reports execution progress, task completion rates, test pass rates
- **`raidd`:** Updates RAIDD log in Phase 8 with execution risks, issues, decisions
- **`defect-mgmt`:** Manages defect lifecycle from creation through resolution

**Set 4: Phase Commands (Sub-Workflows)**
- **`cc-phase-task-result-doc.md`:** Documents task execution results (Phase 2)
- **`cc-phase-defect-mgmt.md`:** Manages defect tracking and resolution (Phases 2-5)

**Set 5: Agent Orchestration (Multi-Agent Coordination)**
- **`cc-orchestrate-william.md`:** Coordinates William's infrastructure task execution (Phase 2)
- **`cc-orchestrate-alex.md`:** Coordinates Alex's architecture/integration task execution (Phase 2)
- **`cc-orchestrate-frank.md`:** Coordinates Frank's security/identity task execution (Phase 2)
- **`cc-orchestrate-julia.md`:** Coordinates Julia's test suite execution (Phase 4)

### Command Workflow Integration Pattern

```
User: "Execute approved tasks for hx-webui-server"
↓
cc-task-execution-workflow.md (Set 1) executes this procedure
↓
PHASE 0-1: Agent Zero validates readiness and assigns tasks
└─ artifact-tracker (Set 3) → Initializes execution tracking
↓
PHASE 2: Task execution
├─ cc-orchestrate-william.md (Set 5) → William executes infrastructure tasks
├─ cc-orchestrate-alex.md (Set 5) → Alex executes architecture tasks
├─ cc-orchestrate-frank.md (Set 5) → Frank executes security tasks
├─ cc-phase-task-result-doc.md (Set 4) → Documents each task result
└─ cc-phase-defect-mgmt.md (Set 4) → Tracks issues/defects
↓
PHASE 3: Continuous coordination
├─ status-report (Set 3) → Progress tracking
└─ Agent Zero monitors execution-tracking.md
↓
PHASE 4: Test suite execution
├─ cc-orchestrate-julia.md (Set 5) → Julia executes all tests
└─ doc-lint (Set 3) → Validates test execution documentation
↓
PHASE 5: Completion verification
└─ Agent Zero validates infrastructure philosophy compliance
↓
PHASE 6: CAIO approval
└─ CAIO reviews execution completion report
↓
PHASE 7-8: Operational promotion and updates
├─ inventory updates (nodes.md, services.md)
├─ raidd (Set 3) → Updates RAIDD log with execution outcomes
└─ status-report (Set 3) → Final status update
```

---

## 🔗 Related Documents

**Core Workflows (5-Phase Lifecycle):**
- **Phase 1:** `.claude/commands/workflows/cc-charter-workflow.md` - Charter creation
- **Phase 2:** `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Specification development
- **Phase 3:** `/home/agent0/HX-Infrastructure/procedures/task-workflow.md` - Task breakdown and test suite generation
- **Phase 4:** `/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md` - Task execution (this document)
- **Phase 5:** `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` - Final documentation and handoff

**Testing Documentation:**
- `/home/agent0/HX-Infrastructure/procedures/testing-knowledge-research-process.md` - Test research process
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - 100% coverage requirement

**Claude Code Commands:**
- **Set 1:** `.claude/commands/workflows/cc-task-execution-workflow.md` - Primary execution workflow command
- **Set 3:** `.claude/commands/utilities/` - Supporting utilities (artifact-tracker, doc-lint, status-report, raidd, defect-mgmt)
- **Set 4:** `.claude/commands/phases/` - Sub-workflow commands (task-result-doc, defect-mgmt)
- **Set 5:** `.claude/commands/agents/` - Agent orchestration commands (william, alex, frank, julia)

**Templates:**
- `/home/agent0/HX-Infrastructure/templates/testing/test-execution-template.md` - Test result documentation
- `/home/agent0/HX-Infrastructure/templates/testing/defect-template.md` - Defect tracking documentation

**Standards:**
- `/home/agent0/HX-Infrastructure/standards/testing-requirements.md` - Test-driven deployment standards
- `/home/agent0/HX-Infrastructure/standards/deployment-requirements.md` - Infrastructure philosophy deployment standards
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Result documentation standards

**Core Documentation:**
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Team structure and roles during execution
- `/home/agent0/HX-Infrastructure/procedures/context-loading-process.md` - Context loading for execution phase
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance principles and manual procedures philosophy

**Agent Profiles:**
- `x-agents/william.md` - Infrastructure specialist (bare metal, systemd, manual procedures execution)
- `x-agents/alex.md` - Platform architect (architecture/integration task execution)
- `x-agents/frank.md` - Security specialist (identity, DNS, credentials task execution)
- `x-agents/julia.md` - Testing & quality specialist (test suite execution, defect management)

---

## 📋 Success Criteria

**Execution is successful when:**

1. ✅ All tasks executed according to plan
2. ✅ All task results documented comprehensively
3. ✅ All verifications passed
4. ✅ All deliverables created
5. ✅ All tests executed
6. ✅ Test coverage requirement met (100%)
7. ✅ Critical tests passed
8. ✅ No P0 defects open
9. ✅ P1 defects acceptable and mitigated
10. ✅ All success criteria from charter met
11. ✅ All requirements from spec implemented
12. ✅ Service/node operational and healthy
13. ✅ Monitoring configured
14. ✅ Documentation complete
15. ✅ Agent Zero verified
16. ✅ CAIO approved
17. ✅ Promoted to operational status
18. ✅ All artifacts updated (RAIDD, Backlog, Defects)
19. ✅ Lessons learned documented

---

## ⚠️ Critical Reminders

**For All Agents Executing Tasks:**
- Context load + execution + documentation = ONE continuous process
- Do NOT pause between loading context and executing
- Do NOT pause between executing and documenting
- Document results IMMEDIATELY while context fresh
- Follow TDD approach (write tests before implementation, where applicable)
- Breaking continuity = lose state = incomplete documentation

**For Agent Zero:**
- Maintains state throughout execution phase
- Coordinates all execution activities
- Monitors progress continuously
- Reviews all task results
- Triages all defects
- Makes rollback decisions (with CAIO approval if needed)
- Final verification before CAIO review

**For Julia (Testing Agent):**
- Executes test suite AFTER all implementation tasks complete
- Follows test execution procedures systematically
- Documents all test results comprehensively
- Creates defects for test failures
- Provides test execution summary
- Recommends operational promotion or remediation

**For CAIO:**
- Final approval authority for operational promotion
- Reviews execution completion report
- Reviews open defects and mitigations
- Can approve, approve with conditions, require remediation, or direct rollback
- Approval required before operational promotion

**For All:**
- Quality over speed - always
- Test-driven deployment - non-negotiable
- Documentation comprehensive - required
- Defect tracking complete - mandatory
- Safety first - rollback if needed

---

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-17 | Initial task execution workflow with 8-phase structure, TDD approach, defect management, operational promotion | 1,444 lines | HX-Infrastructure Team |
| 1.1 | 2025-11-21 | Infrastructure philosophy validation integration, command infrastructure documentation, comprehensive metadata | +165 lines | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added proper document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose and Target Audience sections
- Added comprehensive Related Documents section
- Added HX-Infrastructure Philosophy Validation section (bare metal, systemd, manual procedures, Ansible Vault checkpoints)
- Added infrastructure philosophy compliance quality gate (Phase 5)
- Added Claude Code Command Infrastructure Integration section (Sets 1, 3, 4, 5)
- Added command workflow integration pattern diagram
- Expanded Related Documents with all workflow phases, commands, templates, standards, agent profiles
- Added version history table (this table)

**Backward Compatibility:** 100% - All v1.0 workflow phases unchanged, only validation checkpoints and documentation enhancements added

---

## Document Maintenance

**Document Type:** Procedure - Project Lifecycle Workflow (Phase 4: Task Execution)
**Status:** APPROVED - Production Ready v1.1
**Maintained By:** Agent Zero (CC) and HX-Infrastructure Team
**Review Frequency:** Quarterly (or when execution process changes)
**Last Review:** 2025-11-21
**Next Review:** 2026-02-21

**Update Triggers:**
- Changes to task execution process or phases
- Changes to test-driven deployment approach
- Changes to infrastructure philosophy validation requirements
- Changes to defect management procedures
- Changes to operational promotion criteria
- Changes to Claude Code command infrastructure
- Template updates affecting task result or test execution documentation

**Related Workflow Documents:**
- This document is part of the 5-phase HX-Infrastructure project lifecycle
- **Phase 1:** charter-workflow.md
- **Phase 2:** spec-workflow.md
- **Phase 3:** task-workflow.md
- **Phase 4:** task-execution-workflow.md (this document)
- **Phase 5:** project-closeout-workflow.md

---

**End of Task Execution Workflow Documentation**

*This procedure defines the systematic, test-driven task execution workflow for HX-Infrastructure projects. Following approved task breakdown and test suite, this workflow executes all tasks with comprehensive validation, test execution, defect management, and operational promotion. All execution must validate infrastructure philosophy compliance: bare metal deployment, systemd service management, manual procedures, and Ansible Vault credential management.*
