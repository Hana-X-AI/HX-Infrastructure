---
workflow: util-quality-gate
version: 1.1
date: 2025-11-20
status: APPROVED
type: utility-command
description: Quality gate validation utility for checking pass criteria, reporting status, documenting failures, and tracking gate history across workflows
applies_to: all_workflows, all_orchestrations, quality_management, phase_validation
author: HX-Infrastructure Team
last_updated: 2025-11-20
update_notes: Integration convention enhancement, state management clarity
---

<metadata>
**Workflow:** Quality Gate Utility - Validation and Status Management
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Integration convention enhancement, state management clarity)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Provide standardized quality gate validation across all workflows (Set 1) and orchestrations (Set 2), ensuring consistent pass/fail determination, actionable remediation guidance, and comprehensive gate tracking
</metadata>

<objective>
**Purpose:** Standardize quality gate validation across all HX-Infrastructure workflows and orchestrations, eliminating manual inconsistencies, providing clear pass/fail determinations with evidence, documenting actionable remediation steps for failures, and maintaining comprehensive gate history for project tracking.

**Utility Capabilities:**
- Validate quality gate pass criteria against evidence
- Report gate status (PASS/FAIL) with detailed justification
- Document gate failures with specific remediation actions
- Track gate history across project phases and iterations
- Validate cross-phase gate dependencies
- Generate gate status reports and compliance summaries
- Support all workflows (charter, spec, task, execution, closeout)
- Support all orchestrations (Alex, Frank, William, Julia, multi-agent)

**When to Use This Utility:**
- Before completing any workflow phase (charter, spec, task, execution, closeout)
- During orchestration phase transitions (decision→context→handoff→work→validate→integrate→follow-up)
- When validating deliverable quality before promotion
- During project status reviews requiring gate compliance reporting
- When investigating why a phase or orchestration cannot progress
- Before seeking approval or sign-off on project milestones
</objective>

<utility_overview>
**Core Function:**
This utility validates quality gates systematically by comparing stated pass criteria against provided evidence, determining PASS/FAIL status objectively, and generating actionable guidance for remediation when gates fail.

**Validation Process:**
1. **Identify Gate** - Determine which quality gate is being validated
2. **Load Criteria** - Retrieve pass criteria and fail actions for gate
3. **Gather Evidence** - Collect artifacts, documents, and status demonstrating criteria fulfillment
4. **Evaluate Criteria** - Compare evidence against each pass criterion
5. **Determine Status** - Calculate overall gate status (PASS/FAIL)
6. **Document Results** - Generate validation report with evidence and justification
7. **Provide Remediation** - If FAIL, specify exact actions needed to pass
8. **Track History** - Record gate validation in project gate log

**Key Principle:** Quality gates are objective checkpoints, not subjective opinions. Validation must be evidence-based and reproducible.
</utility_overview>

<quality_gate_registry>
**SET 1: Core Workflow Quality Gates**

Each workflow in Set 1 has phase-specific quality gates:

**Charter Workflow Gates:**
1. `charter_questions_gate` - Charter questions answered completely
2. `charter_draft_gate` - Charter draft meets structural requirements
3. `stakeholder_review_gate` - Stakeholder review completed with feedback incorporated
4. `charter_approval_gate` - Charter approved with documented sign-off

**Spec Workflow Gates:**
1. `spec_context_gate` - Specification context complete with all inputs
2. `spec_draft_gate` - Specification draft meets technical requirements
3. `spec_review_gate` - Technical review completed with issues resolved
4. `spec_approval_gate` - Specification approved for implementation

**Task Workflow Gates:**
1. `task_breakdown_gate` - Tasks properly decomposed with clear scope
2. `task_estimation_gate` - Tasks estimated with realistic effort
3. `task_dependency_gate` - Task dependencies mapped and validated
4. `task_approval_gate` - Task breakdown approved for execution

**Execution Workflow Gates:**
1. `execution_readiness_gate` - Execution prerequisites met (context, resources, dependencies)
2. `work_completion_gate` - Work completed meeting acceptance criteria
3. `validation_gate` - Deliverables validated against requirements
4. `integration_gate` - Deliverables integrated into project successfully

**Closeout Workflow Gates:**
1. `completion_verification_gate` - All deliverables complete and validated
2. `documentation_gate` - Documentation complete and compliant
3. `knowledge_capture_gate` - Lessons learned and precedents documented
4. `formal_closeout_gate` - Project formally closed with sign-off

**SET 2: Agent Orchestration Quality Gates**

Each orchestration in Set 2 has phase-specific quality gates:

**Alex Orchestration Gates:**
1. `decision_gate` - Architecture coordination need justified
2. `context_gate` - Architecture context complete
3. `handoff_gate` - Handoff to Alex successful
4. `work_gate` - Alex's architecture work complete
5. `validation_gate` - Architecture deliverables validated
6. `integration_gate` - Architecture guidance integrated
7. `followup_gate` - Architecture coordination documented

**Frank Orchestration Gates:**
1. `decision_gate` - Security coordination need justified
2. `context_gate` - Security context complete
3. `handoff_gate` - Handoff to Frank successful
4. `work_gate` - Frank's security work complete
5. `validation_gate` - Security deliverables validated
6. `integration_gate` - Security guidance integrated
7. `followup_gate` - Security coordination documented

**William Orchestration Gates:**
1. `decision_gate` - Infrastructure coordination need justified
2. `context_gate` - Infrastructure context complete
3. `handoff_gate` - Handoff to William successful
4. `work_gate` - William's infrastructure work complete
5. `validation_gate` - Infrastructure deliverables validated
6. `integration_gate` - Infrastructure guidance integrated
7. `followup_gate` - Infrastructure coordination documented

**Julia Orchestration Gates:**
1. `decision_gate` - Testing coordination need justified
2. `context_gate` - Testing context complete
3. `handoff_gate` - Handoff to Julia successful
4. `work_gate` - Julia's testing work complete
5. `validation_gate` - Testing deliverables validated
6. `integration_gate` - Testing guidance integrated
7. `followup_gate` - Testing coordination documented

**Multi-Agent Synthesis Gates:**
1. `analysis_gate` - Multi-agent need assessed
2. `strategy_gate` - Multi-agent coordination strategy complete
3. `coordination_gate` - Multi-agent coordination executed
4. `synthesis_gate` - Multi-agent outputs synthesized
5. `validation_gate` - Cross-domain correctness validated
6. `integration_gate` - Multi-agent guidance integrated
7. `learning_gate` - Multi-agent patterns documented
</quality_gate_registry>

<validation_procedures>
  <procedure name="Validate Single Quality Gate">
  **Purpose:** Validate a single quality gate and determine PASS/FAIL status
  
  **Inputs:**
  - Gate identifier (e.g., "charter_questions_gate", "spec_context_gate", "decision_gate")
  - Workflow or orchestration name (e.g., "charter-workflow", "orchestrate-alex")
  - Evidence artifacts (documents, deliverables, status information)
  - Current phase in workflow/orchestration
  
  **Validation Steps:**
  
  1. **Load Gate Definition**
     - Retrieve gate from appropriate workflow/orchestration file
     - Extract pass criteria list
     - Extract fail actions list
     - Note gate phase and purpose
  
  2. **Evaluate Each Pass Criterion**
     For each criterion in gate's pass criteria:
     - State the criterion clearly
     - Identify required evidence type
     - Check if evidence provided
     - Assess if evidence meets criterion
     - Mark criterion: MET or NOT MET
     - Document justification for determination
  
  3. **Calculate Overall Gate Status**
     - If ALL criteria MET → Gate status: PASS
     - If ANY criteria NOT MET → Gate status: FAIL
     - Count: X of Y criteria met
  
  4. **Generate Validation Report**
     - Gate identifier and workflow/orchestration
     - Overall status: PASS or FAIL
     - Detailed criterion-by-criterion evaluation
     - Evidence provided and assessment
     - Timestamp of validation
  
  5. **Provide Remediation (if FAIL)**
     - List specific criteria NOT MET
     - For each unmet criterion, provide fail action from gate definition
     - Estimate effort to achieve gate pass
     - Identify blockers preventing criteria fulfillment
  
  6. **Record Validation History**
     - Log validation attempt in gate history
     - Track validation date, validator, status
     - Link to evidence and validation report
     - Enable trend analysis (attempts to pass)
  
  **Outputs:**
  - Validation report (PASS/FAIL with evidence)
  - Remediation plan (if FAIL)
  - Gate history entry
  - Status summary for project tracking
  
  **Example Validation:**
  ```
  QUALITY GATE VALIDATION REPORT
  ══════════════════════════════════════════════════════════════════════
  Gate: spec_context_gate
  Workflow: Specification Workflow
  Phase: Context Preparation (Phase 2)
  Validation Date: 2025-11-20
  Validator: Agent Zero
  
  PASS CRITERIA EVALUATION:
  ──────────────────────────────────────────────────────────────────────
  1. Charter approved and available
     Status: ✓ MET
     Evidence: Charter-v1.0-APPROVED.md dated 2025-11-18
     
  2. Requirements completely specified
     Status: ✗ NOT MET
     Evidence: Requirements doc incomplete - missing non-functional requirements
     
  3. Constraints documented
     Status: ✓ MET
     Evidence: Constraints section complete in charter
     
  4. Dependencies identified
     Status: ✗ NOT MET
     Evidence: No dependency analysis document found
  
  5. Stakeholder input gathered
     Status: ✓ MET
     Evidence: Stakeholder feedback sessions documented
  
  OVERALL GATE STATUS: ❌ FAIL (3 of 5 criteria met)
  
  REMEDIATION REQUIRED:
  ──────────────────────────────────────────────────────────────────────
  Criterion 2 - Requirements completely specified:
    Action: Complete non-functional requirements section
    Deliverable: Updated requirements doc with NFRs
    Estimated Effort: 2-3 hours
    Owner: Requirements analyst
  
  Criterion 4 - Dependencies identified:
    Action: Create dependency analysis document
    Deliverable: Dependencies mapped with relationships
    Estimated Effort: 1-2 hours
    Owner: System architect
  
  ESTIMATED TIME TO PASS: 3-5 hours additional work
  
  NEXT STEPS:
  1. Address Criterion 2 (requirements completion)
  2. Address Criterion 4 (dependency analysis)
  3. Re-validate spec_context_gate
  4. Proceed to Phase 3 (handoff) only after gate passes
  ```
  </procedure>

  <procedure name="Validate Phase Transition">
  **Purpose:** Validate all quality gates in a phase before transitioning to next phase
  
  **Inputs:**
  - Workflow or orchestration name
  - Current phase number and name
  - Next phase number and name
  - All evidence artifacts for current phase
  
  **Validation Steps:**
  
  1. **Identify Phase Gates**
     - Determine which quality gate(s) guard current phase exit
     - Most phases have 1 gate, some have multiple
     - Example: Charter Phase 2 has `charter_questions_gate`
  
  2. **Validate Each Phase Gate**
     - Use "Validate Single Quality Gate" procedure for each gate
     - Collect all validation reports
     - Determine if ANY gate failed
  
  3. **Determine Phase Transition Readiness**
     - If ALL phase gates PASS → Phase transition APPROVED
     - If ANY phase gate FAIL → Phase transition BLOCKED
     - Document transition decision with justification
  
  4. **Generate Phase Transition Report**
     - Phase transition request (from X to Y)
     - All gate validation results
     - Overall transition status (APPROVED/BLOCKED)
     - Remediation plan if blocked
     - Estimated time to achieve readiness if blocked
  
  5. **Enforce Phase Transition Policy**
     - APPROVED: Document transition authorization, proceed to next phase
     - BLOCKED: Document block reason, provide remediation plan, prevent next phase start
  
  **Outputs:**
  - Phase transition report
  - Transition authorization (if approved)
  - Remediation plan (if blocked)
  - Phase history entry
  
  **Example Validation:**
  ```
  PHASE TRANSITION VALIDATION REPORT
  ══════════════════════════════════════════════════════════════════════
  Workflow: Specification Workflow
  Current Phase: Phase 2 (Context Preparation)
  Next Phase: Phase 3 (Team Formation)
  Validation Date: 2025-11-20
  
  PHASE EXIT GATE VALIDATION:
  ──────────────────────────────────────────────────────────────────────
  Gate: spec_context_gate
  Status: ❌ FAIL (3 of 5 criteria met)
  Details: See gate validation report above
  
  PHASE TRANSITION STATUS: 🚫 BLOCKED
  
  BLOCKING REASONS:
  1. Requirements not completely specified (missing NFRs)
  2. Dependencies not identified (no dependency analysis)
  
  REMEDIATION PLAN:
  ──────────────────────────────────────────────────────────────────────
  Total Effort: 3-5 hours
  Expected Ready Date: 2025-11-21
  
  Actions:
  1. Complete non-functional requirements → 2-3 hours
  2. Create dependency analysis → 1-2 hours
  3. Re-validate spec_context_gate → 30 min
  4. Re-request phase transition approval
  
  PHASE TRANSITION POLICY ENFORCEMENT:
  Phase 3 (Team Formation) SHALL NOT start until:
  ✓ spec_context_gate achieves PASS status
  ✓ Phase transition re-validated and approved
  
  NEXT STEPS:
  1. Execute remediation plan
  2. Re-validate quality gate
  3. Re-request phase transition validation
  ```
  </procedure>

  <procedure name="Validate Cross-Phase Dependencies">
  **Purpose:** Validate that downstream phases can use upstream phase outputs
  
  **Inputs:**
  - Workflow name
  - Upstream phase outputs (deliverables)
  - Downstream phase inputs (requirements)
  
  **Validation Steps:**
  
  1. **Map Phase Dependencies**
     - Identify what downstream phase needs from upstream
     - Example: Spec phase needs approved charter from Charter phase
     - Example: Execution phase needs approved tasks from Task phase
  
  2. **Validate Output Completeness**
     - Check if upstream phase delivered all required outputs
     - Verify outputs meet quality standards
     - Confirm outputs are accessible to downstream phase
  
  3. **Validate Input Requirements**
     - Check if downstream phase can receive outputs
     - Verify compatibility (format, completeness, quality)
     - Confirm no blocking issues prevent usage
  
  4. **Identify Dependency Gaps**
     - Note missing outputs
     - Note incompatible formats
     - Note quality issues blocking usage
  
  5. **Generate Dependency Validation Report**
     - Dependency mapping
     - Completeness assessment
     - Compatibility verification
     - Gap identification
     - Remediation plan for gaps
  
  **Outputs:**
  - Cross-phase dependency validation report
  - Gap remediation plan (if gaps exist)
  - Dependency compliance status
  </procedure>

  <procedure name="Generate Gate Status Dashboard">
  **Purpose:** Provide comprehensive view of all quality gates across project
  
  **Inputs:**
  - Project identifier
  - All workflow and orchestration gate histories
  - Current project phase
  
  **Dashboard Elements:**
  
  1. **Overall Gate Health**
     - Total gates in project: X
     - Gates passed: Y (Z%)
     - Gates failed: A (B%)
     - Gates not yet reached: C (D%)
  
  2. **Workflow Gate Status**
     - Charter workflow gates: status summary
     - Spec workflow gates: status summary
     - Task workflow gates: status summary
     - Execution workflow gates: status summary
     - Closeout workflow gates: status summary
  
  3. **Orchestration Gate Status**
     - Alex orchestration gates: status summary
     - Frank orchestration gates: status summary
     - William orchestration gates: status summary
     - Julia orchestration gates: status summary
     - Multi-agent synthesis gates: status summary
  
  4. **Problem Gates**
     - Gates with multiple failed attempts
     - Gates blocking phase transitions
     - Gates requiring immediate attention
  
  5. **Gate Trends**
     - Average attempts to pass per gate
     - Most commonly failed criteria
     - Remediation time patterns
  
  **Output:**
  - Gate status dashboard (formatted report)
  - Problem gate alerts
  - Trend analysis
  - Recommendations for process improvement
  </procedure>
</validation_procedures>

<gate_validation_standards>
**Evidence Requirements:**

Quality gate validation requires **objective, verifiable evidence**. Acceptable evidence types:

1. **Document Existence**
   - File exists at specified path
   - Document contains required sections
   - Document meets minimum length/completeness criteria

2. **Content Quality**
   - Required information present in document
   - Information meets quality standards (completeness, accuracy, clarity)
   - Cross-references validate correctly

3. **Approval Status**
   - Document has approval signature/notation
   - Approval date within acceptable timeframe
   - Approver has authority for approval

4. **Process Completion**
   - Required steps documented as completed
   - Deliverables from steps available
   - No blocking issues remain

5. **Stakeholder Confirmation**
   - Stakeholder feedback documented
   - Stakeholder concerns addressed or documented as acceptable risks
   - Stakeholder sign-off obtained

**Unacceptable Evidence:**
- "I think this is done" (opinion without verification)
- "This should be good enough" (subjective judgment)
- "We discussed this" (no documentation)
- "This always worked before" (no current validation)
- "Trust me" (no evidence provided)

**Evidence Documentation:**
All evidence must be:
- **Identifiable:** Clear reference (file path, document section, timestamp)
- **Accessible:** Validator can locate and verify evidence
- **Current:** Evidence reflects current project state (not outdated)
- **Relevant:** Evidence directly addresses pass criterion
- **Sufficient:** Evidence provides clear pass/fail determination
</gate_validation_standards>

<remediation_guidance>
**Remediation Plan Structure:**

When quality gate fails, remediation plan must specify:

1. **Unmet Criteria**
   - List each criterion NOT MET
   - Explain why criterion not met
   - Identify evidence gap or quality issue

2. **Required Actions**
   - Specific actions to meet each criterion
   - Deliverables resulting from actions
   - Acceptance criteria for deliverables

3. **Effort Estimation**
   - Estimated time to complete actions
   - Resources required (people, tools, information)
   - Dependencies on other work

4. **Ownership Assignment**
   - Who will execute remediation actions
   - Who will verify actions completed
   - Escalation path if actions blocked

5. **Timeline**
   - Start date for remediation
   - Expected completion date
   - Gate re-validation date

6. **Success Criteria**
   - How to know remediation succeeded
   - Evidence that will demonstrate criterion met
   - Re-validation process

**Remediation Prioritization:**

Not all unmet criteria equally important. Prioritize by:

1. **Critical Path Impact**
   - Does failure block next phase?
   - Does failure block other work?
   - How many downstream dependencies affected?

2. **Effort Required**
   - Quick fixes (< 1 hour) → High priority
   - Medium effort (1-4 hours) → Medium priority
   - Major rework (> 4 hours) → May need phase restart

3. **Risk Level**
   - High risk if not addressed → High priority
   - Medium risk → Medium priority
   - Low risk → Low priority (may accept)

4. **Stakeholder Impact**
   - User-facing issues → High priority
   - Internal quality issues → Medium priority
   - Process formalities → Low priority

**Remediation Tracking:**

Track remediation progress:
- Actions completed vs. planned
- Time spent vs. estimated
- Blockers encountered and resolved
- Re-validation attempts and results
</remediation_guidance>

<gate_history_management>
**State Management:**

This utility is **stateless** - the cc-util-quality-gate.md file contains instructions only.

**State artifacts** are created by following these instructions:
- **Gate History Log:** `/projects/{project-name}/quality-gates/history.md` (persistent)
- **Validation Reports:** `/projects/{project-name}/quality-gates/{gate-id}_validation_YYYYMMDD.md` (persistent)

These state artifacts are:
- Created during first validation
- Updated/appended during subsequent validations
- Persistent across sessions
- Project-specific (one history.md per project)

**Distinction:**
- Utility = Stateless instructions (this document)
- Artifacts = Stateful files (created per project)

**Gate History Purpose:**

Track all quality gate validation attempts to:
- Understand gate pass/fail patterns
- Identify problematic gates requiring process improvement
- Demonstrate project quality compliance
- Support retrospective analysis
- Improve estimation accuracy

**Gate History Entry Format:**

```
GATE HISTORY ENTRY
══════════════════════════════════════════════════════════════════════
Gate ID: spec_context_gate
Workflow: Specification Workflow
Validation Date: 2025-11-20 14:30:00
Validator: Agent Zero
Attempt Number: 2

VALIDATION RESULT: FAIL
Criteria Met: 3 of 5 (60%)
Unmet Criteria: 
  - Requirements completely specified
  - Dependencies identified

PREVIOUS ATTEMPTS:
Attempt 1: 2025-11-19 - FAIL (2 of 5 criteria met)
  Remediation: Added stakeholder input
  
REMEDIATION PLAN:
Effort: 3-5 hours
Expected Ready: 2025-11-21
Actions: Complete NFRs, create dependency analysis

NOTES:
Requirements completion delayed due to stakeholder availability
Dependency analysis blocked waiting for architecture decisions
```

**History Analysis:**

Analyze gate history to identify:
- Gates frequently failed (process improvement candidates)
- Common unmet criteria (training opportunities)
- Remediation time patterns (estimation improvements)
- Validation bottlenecks (resource allocation issues)
- Quality trends (improving or degrading over time)

**History Retention:**

Maintain gate history:
- **Active Project:** All history retained
- **Completed Project:** History archived with project documentation
- **Retention Period:** 2 years minimum for retrospective analysis
</gate_history_management>

<integration_with_workflows>
**Workflow Integration Points:**

Quality gate utility integrates with Set 1 workflows at specific points:

**Charter Workflow:**
- After Phase 1 (Questions) → Validate `charter_questions_gate`
- After Phase 2 (Draft) → Validate `charter_draft_gate`
- After Phase 3 (Review) → Validate `stakeholder_review_gate`
- After Phase 4 (Approval) → Validate `charter_approval_gate`

**Spec Workflow:**
- After Phase 1 (Context) → Validate `spec_context_gate`
- After Phase 2 (Draft) → Validate `spec_draft_gate`
- After Phase 3 (Review) → Validate `spec_review_gate`
- After Phase 4 (Approval) → Validate `spec_approval_gate`

**Task Workflow:**
- After Phase 1 (Breakdown) → Validate `task_breakdown_gate`
- After Phase 2 (Estimation) → Validate `task_estimation_gate`
- After Phase 3 (Dependencies) → Validate `task_dependency_gate`
- After Phase 4 (Approval) → Validate `task_approval_gate`

**Execution Workflow:**
- After Phase 1 (Readiness) → Validate `execution_readiness_gate`
- After Phase 2 (Work) → Validate `work_completion_gate`
- After Phase 3 (Validation) → Validate `validation_gate`
- After Phase 4 (Integration) → Validate `integration_gate`

**Closeout Workflow:**
- After Phase 1 (Verification) → Validate `completion_verification_gate`
- After Phase 2 (Documentation) → Validate `documentation_gate`
- After Phase 3 (Learning) → Validate `knowledge_capture_gate`
- After Phase 4 (Formal Closeout) → Validate `formal_closeout_gate`

**Orchestration Integration Points:**

Quality gate utility integrates with Set 2 orchestrations at phase boundaries:

**All Orchestrations (Alex, Frank, William, Julia):**
- After Phase 1 (Decision) → Validate `decision_gate`
- After Phase 2 (Context) → Validate `context_gate`
- After Phase 3 (Handoff) → Validate `handoff_gate`
- After Phase 4 (Work) → Validate `work_gate`
- After Phase 5 (Validate) → Validate `validation_gate`
- After Phase 6 (Integrate) → Validate `integration_gate`
- After Phase 7 (Follow-up) → Validate `followup_gate`

**Multi-Agent Synthesis:**
- After Phase 1 (Analysis) → Validate `analysis_gate`
- After Phase 2 (Strategy) → Validate `strategy_gate`
- After Phase 3 (Coordination) → Validate `coordination_gate`
- After Phase 4 (Synthesis) → Validate `synthesis_gate`
- After Phase 5 (Validation) → Validate `validation_gate`
- After Phase 6 (Integration) → Validate `integration_gate`
- After Phase 7 (Learning) → Validate `learning_gate`
</integration_with_workflows>

<integration_convention>
**How Commands Invoke This Utility:**

**From Workflow Commands (Set 1):**
At phase completion, workflow commands invoke utility with instructional reference:

Example from cc-charter-workflow.md at end of Phase 1:
"Before proceeding to Phase 2, use cc-util-quality-gate to validate
charter_questions_gate. Load pass criteria from Charter Workflow
<quality_gates> section under charter_questions_gate. Evaluate evidence at
/projects/{project-name}/charter/questions.md. Generate validation
report at /projects/{project-name}/quality-gates/charter_questions_gate.md"

**From Orchestration Commands (Set 2):**
At phase completion, orchestration commands invoke utility:

Example from cc-orchestrate-alex.md at end of Phase 2:
"Use cc-util-quality-gate to validate alex_context_gate. Load pass
criteria from Alex Orchestration quality gates section. Evaluate
evidence at /projects/{project-name}/orchestration/alex-context.md"

**Required Inputs:**
1. **Gate Identifier** - Specific gate name (e.g., "charter_questions_gate")
2. **Source Document** - Workflow/orchestration containing gate definition
3. **Evidence Paths** - Location(s) of artifacts demonstrating criteria met
4. **Project Name** - For report and history file organization
5. **Validator** - Who is performing validation (agent or human)

**Expected Outputs:**

1. **Validation Report** (Primary Output)
   - Format: Structured markdown with status, metrics, evidence, remediation
   - Location: `/projects/{project-name}/quality-gates/{gate-id}_validation_YYYYMMDD.md`
   - Contents: Gate status, criteria evaluation, evidence references, next steps

2. **Gate History Entry** (State Artifact)
   - Format: Appended entry in chronological gate history log
   - Location: `/projects/{project-name}/quality-gates/history.md`
   - Contents: Validation metadata, status, attempt number, remediation plan

3. **Status Summary** (Immediate Feedback)
   - Format: Concise status for workflow/orchestration to proceed or block
   - Contents: PASS/FAIL, criteria met count, progression decision

**State Management:**

**Stateless Component:**
- cc-util-quality-gate.md utility file (this document)
- Instructions for validation procedures
- No state maintained in utility itself

**Stateful Artifacts:**
- Gate validation reports: `/projects/{project-name}/quality-gates/{gate-id}_validation_YYYYMMDD.md`
- Gate history log: `/projects/{project-name}/quality-gates/history.md`
- Created/updated by following utility procedures
- Persistent across sessions

**File Organization:**
```
/projects/{project-name}/
  quality-gates/
    history.md                                  ← Master gate history
    charter_questions_gate_validation_20251120.md
    charter_draft_gate_validation_20251121.md
    spec_context_gate_validation_20251122.md
    ...
```

**Invocation Pattern Summary:**
1. Caller identifies gate needing validation
2. Caller references cc-util-quality-gate with specific gate ID and evidence
3. Validation report generated at standard location
4. History entry appended to project gate history
5. Status returned to caller (PASS → proceed, FAIL → block)
</integration_convention>

<usage_examples>
  <example name="Simple Gate Validation">
  **Scenario:** Validating charter questions gate after completing charter questions phase

  **Command:**
  ```
  Validate quality gate:
  - Gate: charter_questions_gate
  - Workflow: Charter Workflow
  - Evidence: Charter questions document at /home/agent0/HX-Infrastructure/projects/auth-system/charter/questions.md
  ```

  **Utility Process:**
  1. Load `charter_questions_gate` pass criteria
  2. Check evidence against each criterion
  3. Determine PASS/FAIL status
  4. Generate validation report
  5. Provide remediation if FAIL

  **Expected Output:**
  ```
  QUALITY GATE VALIDATION RESULT: ✓ PASS
  
  Gate: charter_questions_gate
  Criteria Met: 5 of 5 (100%)
  
  All charter questions answered completely.
  Phase transition to Charter Draft approved.
  ```
  </example>

  <example name="Phase Transition Validation">
  **Scenario:** Attempting to transition from Spec Context to Spec Draft phase

  **Command:**
  ```
  Validate phase transition:
  - Workflow: Specification Workflow
  - Current Phase: Phase 1 (Context Preparation)
  - Next Phase: Phase 2 (Team Formation & Draft)
  - Evidence directory: /home/agent0/HX-Infrastructure/projects/auth-system/spec/context/
  ```

  **Utility Process:**
  1. Identify phase exit gate: `spec_context_gate`
  2. Validate gate using provided evidence
  3. Determine if transition approved or blocked
  4. Generate phase transition report

  **Expected Output (if fail):**
  ```
  PHASE TRANSITION STATUS: 🚫 BLOCKED
  
  Blocking Gate: spec_context_gate
  Status: FAIL (3 of 5 criteria met)
  
  Unmet Criteria:
  - Requirements completely specified (missing NFRs)
  - Dependencies identified (no dependency doc)
  
  Remediation Required: 3-5 hours
  
  Phase 2 SHALL NOT start until gate passes.
  ```
  </example>

  <example name="Multi-Gate Dashboard">
  **Scenario:** Project status review requiring comprehensive gate health view

  **Command:**
  ```
  Generate gate status dashboard:
  - Project: auth-system
  - Include all workflows and orchestrations
  - Show problem gates requiring attention
  ```

  **Utility Process:**
  1. Load all gate histories for project
  2. Calculate gate health metrics
  3. Identify problem gates
  4. Analyze trends
  5. Generate formatted dashboard

  **Expected Output:**
  ```
  QUALITY GATE DASHBOARD - AUTH-SYSTEM PROJECT
  ══════════════════════════════════════════════════════════════════════
  Date: 2025-11-20
  
  OVERALL GATE HEALTH:
  Total Gates: 25
  Passed: 18 (72%)
  Failed: 3 (12%)
  Not Yet Reached: 4 (16%)
  
  WORKFLOW STATUS:
  ✓ Charter Workflow: 4/4 gates passed
  ⚠ Spec Workflow: 2/4 gates passed (spec_context_gate FAILED)
  ⏳ Task Workflow: 0/4 gates reached
  ⏳ Execution Workflow: 0/4 gates reached
  ⏳ Closeout Workflow: 0/4 gates reached
  
  ORCHESTRATION STATUS:
  ✓ Alex Orchestration: 7/7 gates passed
  ✓ Frank Orchestration: 5/7 gates passed (integration pending)
  ⏳ William Orchestration: Not invoked
  ⏳ Julia Orchestration: Not invoked
  
  PROBLEM GATES (Require Attention):
  🚨 spec_context_gate - FAILED (2 attempts)
     Blocking: Spec workflow progression
     Issues: Requirements incomplete, dependencies unmapped
     Estimated Fix: 3-5 hours
  
  RECOMMENDATIONS:
  1. Prioritize spec_context_gate remediation (blocking critical path)
  2. Continue Frank orchestration through integration phase
  3. Monitor charter-to-spec transition quality (2 attempts to pass spec gate)
  ```
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Evidence-Based Validation:** Quality gates pass or fail based on objective evidence, not subjective opinion. If evidence insufficient or absent, gate fails.

2. ⚠️ **All Criteria Required:** Gate passes only if ALL pass criteria met. Single unmet criterion = gate failure, regardless of other criteria.

3. ⚠️ **Phase Transition Enforcement:** Downstream phases SHALL NOT start until upstream phase gates pass. No exceptions for schedule pressure.

4. ⚠️ **Remediation Specificity:** Failed gates require specific remediation actions, not vague "work harder" guidance. Action plans must be concrete and achievable.

5. ⚠️ **History Tracking Mandatory:** All gate validation attempts must be recorded in gate history for project accountability and process improvement.

6. ⚠️ **Cross-Phase Dependencies:** Validate that upstream phase outputs meet downstream phase input requirements before transition approval.

7. ⚠️ **Quality Over Speed:** Never compromise gate pass criteria to meet schedule. Quality gates exist to prevent downstream problems more expensive than schedule delays.

8. ⚠️ **Dashboard Visibility:** Gate status must be visible to project stakeholders. Problem gates require immediate attention and should trigger alerts.
</critical_reminders>

<validation_checklist>
**Pre-Validation Checklist:**
- [ ] Gate identifier confirmed (correct gate for phase)
- [ ] Workflow or orchestration name verified
- [ ] Pass criteria loaded from source document
- [ ] Fail actions loaded from source document
- [ ] Evidence artifacts identified and accessible
- [ ] Validator authority confirmed

**Validation Execution Checklist:**
- [ ] Each pass criterion evaluated individually
- [ ] Evidence documented for each criterion
- [ ] Met/Not Met determination justified
- [ ] Overall gate status calculated correctly (ALL criteria required)
- [ ] Validation report generated with details
- [ ] Timestamp recorded

**Remediation Planning Checklist (if FAIL):**
- [ ] Unmet criteria listed specifically
- [ ] Fail actions identified for each unmet criterion
- [ ] Required actions specified concretely
- [ ] Effort estimated realistically
- [ ] Owners assigned to remediation actions
- [ ] Timeline established for re-validation
- [ ] Blockers identified if actions cannot proceed

**History Recording Checklist:**
- [ ] Gate history entry created
- [ ] Validation date and validator recorded
- [ ] Attempt number tracked
- [ ] Status (PASS/FAIL) logged
- [ ] Criteria met count documented
- [ ] Evidence references included
- [ ] Remediation plan linked (if FAIL)

**Phase Transition Checklist:**
- [ ] All phase exit gates identified
- [ ] Each exit gate validated
- [ ] Transition status determined (APPROVED/BLOCKED)
- [ ] Transition report generated
- [ ] Policy enforcement applied (block if any gate failed)
- [ ] Next phase start authorization documented (if approved)
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md` - Charter workflow quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-spec-workflow.md` - Spec workflow quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md` - Task workflow quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md` - Execution workflow quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-project-closeout-workflow.md` - Closeout workflow quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Alex orchestration quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Frank orchestration quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - William orchestration quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Julia orchestration quality gates
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-agent-zero-synthesis.md` - Multi-agent synthesis quality gates
- `/home/agent0/HX-Infrastructure/constitution.md` - Project governance and quality standards
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Documentation quality standards
</related_documents>

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready with Enhanced Integration Convention
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Integration convention enhancement, state management clarity)
**Compliance:** 100% semantic XML structure, standardized procedures, comprehensive validation guidance
**Next Steps:** Use this utility to validate quality gates across all workflows (Set 1) and orchestrations (Set 2)
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
</metadata_footer>