---
document: cc-util-handoff
version: 1.2
date: 2025-11-24
status: APPROVED
type: utility-command
description: Session handoff utility for generating comprehensive handoff documents enabling seamless project continuation across chat sessions with complete context preservation, current state capture, and clear next action instructions
applies_to: all_workflows, all_orchestrations, session_continuity, context_preservation, project_handoff
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-handoff.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Session Handoff Utility - Seamless Chat Session Continuation
**Version:** 1.2
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Enhanced integration convention header, added infrastructure-specific handoff considerations)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Provide systematic session handoff generation capturing complete project context, documenting current state comprehensively, specifying clear next actions, and enabling seamless project continuation in new chat sessions without information loss
</metadata>

<objective>
**Purpose:** Establish standardized session handoff process that preserves complete project context across chat boundaries, prevents information loss during session transitions, enables immediate productive continuation, maintains project momentum, and supports stateless agent workflow patterns.

**Utility Capabilities:**
- Generate comprehensive session handoff documents with complete context
- Capture current project state (phase, progress, status)
- Document recent accomplishments and current activities
- Specify clear next actions and continuation instructions
- Preserve critical context (RAIDD items, quality gates, artifacts)
- Create continuation prompts for new chat sessions
- Maintain handoff history for project tracking
- Support different handoff types (end-of-day, phase transition, complex task)
- Enable quick context loading in new sessions
- Prevent state loss in stateless agent workflows

**When to Use This Utility:**
- At end of productive work session before closing chat
- Before phase transitions requiring fresh context load
- When switching between complex tasks or workflows
- During long-running projects spanning multiple sessions
- Before project pauses or breaks (weekends, holidays)
- When handing off work to another team member
- Before major decision points requiring complete context
- During project closeout for final handoff generation
</objective>

<utility_overview>
**Core Function:**
This utility generates structured handoff documents by capturing current project state, documenting accomplishments and activities, identifying open items requiring attention, specifying clear next actions, and providing continuation instructions that enable immediate productive work in new chat sessions.

**Session Handoff Process:**
1. **Capture Context** - Document complete project state and current position
2. **Summarize Progress** - Record recent accomplishments and current activities
3. **Identify Open Items** - List pending tasks, blockers, decisions needed
4. **Specify Next Actions** - Clear instructions for continuing work
5. **Preserve Critical Data** - RAIDD items, quality gates, artifacts requiring attention
6. **Generate Continuation Prompt** - Ready-to-use prompt for new chat session
7. **Update Handoff History** - Track handoffs for project continuity
8. **Save Handoff Document** - Structured document for reference

**Key Principle:** Effective session handoffs enable zero-friction continuation - new chat sessions start immediately productive without re-establishing context.
</utility_overview>

<state_management>
**State Management Pattern:**

This utility is **stateless** - the cc-util-handoff.md file contains instructions and templates only.

**State artifacts** are created by following these instructions:
- **Handoff Documents:** `/projects/{project-name}/handoffs/handoff-YYYYMMDD-HHMM.md` (persistent)
- **Continuation Prompts:** `/projects/{project-name}/handoffs/prompts/continue-YYYYMMDD-HHMM.txt` (ready-to-paste)
- **Handoff History:** `/projects/{project-name}/handoffs/history.md` (persistent, chronological)
- **Master Tracker:** `/projects/{project-name}/handoffs/master-tracker.md` (persistent, current state)

These state artifacts are:
- Created during first handoff generation
- Appended throughout project lifecycle
- Persistent across sessions
- Project-specific (one handoffs directory per project)

**Distinction:**
- **Utility** = Stateless instructions + templates (this document)
- **Artifacts** = Stateful files created per project (handoffs, prompts, history, tracker)

**Handoff History Evolution:**
Session handoffs track project progression:
- Charter phase: Initial handoffs establishing project foundation
- Spec phase: Technical context handoffs with design decisions
- Execution phase: Frequent handoffs tracking implementation progress
- Closeout phase: Final handoff with complete project summary

This evolution provides complete project narrative and supports retrospective analysis.
</state_management>

<handoff_types>
**Handoff Type Definitions:**

**End-of-Session Handoff:**
Standard handoff at end of productive work session.

**When to Use:** End of focused work period before closing chat
**Duration:** 5-10 minutes to generate
**Context Depth:** Moderate - current phase, recent work, next steps
**Continuation:** Resume work from exact stopping point

**Key Sections:**
- Current phase and progress
- Work completed this session
- Current activity (what was being worked on)
- Next immediate actions (next 1-3 tasks)
- Open items requiring attention
- Continuation instructions

**Phase Transition Handoff:**
Handoff at workflow phase boundary requiring context reload.

**When to Use:** Between workflow phases (Charter → Spec → Task → Execution → Closeout)
**Duration:** 10-15 minutes to generate
**Context Depth:** Comprehensive - complete phase summary, transition context
**Continuation:** Begin next phase with full understanding of previous phase outcomes

**Key Sections:**
- Phase completion summary
- Phase deliverables and artifacts
- Quality gate validation results
- Lessons learned from phase
- Next phase prerequisites
- Phase transition context
- Detailed continuation instructions

**Complex Task Handoff:**
Handoff during complex, multi-step tasks requiring deep context preservation.

**When to Use:** Mid-task on complex activities (multi-agent orchestration, complex debugging, architectural decisions)
**Duration:** 15-20 minutes to generate
**Context Depth:** Deep - complete task context, decision history, current state
**Continuation:** Resume complex task without losing critical context

**Key Sections:**
- Task objective and scope
- Progress to date (steps completed)
- Current state (exactly where stopped)
- Decision history (choices made, rationale)
- Open questions and considerations
- Next sub-tasks in sequence
- Context documents to load
- Detailed continuation instructions

**Project Pause Handoff:**
Handoff before extended project pause (weekends, holidays, project holds).

**When to Use:** Before breaks longer than 2 days
**Duration:** 15-20 minutes to generate
**Context Depth:** Comprehensive - full project state, all open items
**Continuation:** Resume project after pause with complete context refresh

**Key Sections:**
- Complete project status summary
- All open RAIDD items
- All pending quality gates
- All artifacts in progress
- Blockers requiring resolution
- Timeline and schedule status
- Stakeholder communications pending
- Comprehensive continuation instructions

**Team Handoff:**
Handoff when transferring work to another team member.

**When to Use:** Work handoff to colleague, shift changes, vacation coverage
**Duration:** 20-30 minutes to generate
**Context Depth:** Comprehensive + explanatory - assume different person needs full context
**Continuation:** New team member can continue work independently

**Key Sections:**
- Project overview and objectives
- Current phase and progress
- Complete work history (not just recent)
- All open items with priority
- Known issues and workarounds
- Key stakeholder contacts
- Access requirements and credentials
- Detailed continuation instructions
- Background context and rationale

**Infrastructure-Specific Handoff (HX-Infrastructure Projects):**
Additional context capture for HX-Infrastructure bare-metal deployments.

**When to Use:** HX-Infrastructure projects with systemd services, bare-metal deployment, manual procedures
**Duration:** Add 5-10 minutes to standard handoff types
**Context Depth:** Infrastructure deployment state and checkpoints
**Continuation:** Resume deployment with exact system state context

**Additional Sections for Infrastructure Projects:**

**SYSTEMD SERVICE STATE:**
- Service Name: [service-name]
- Unit File: [path to .service file]
- Service Status: [active|inactive|failed]
- Last Status Change: [timestamp and reason]
- Unit File Changes This Session: [List modifications made]
- Restart Required: [Yes|No - If yes, why deferred]

**BARE-METAL DEPLOYMENT PROGRESS:**
- Target Server: [hx-servername] ([IP address])
- OS: Ubuntu 24 bare-metal
- Package Installation Status:
  - Installed: [List packages installed this session]
  - Pending: [List packages remaining]
  - Configuration Files Updated: [List with paths]
- Filesystem State:
  - Directories Created: [List]
  - Permissions Set: [List]
  - Mounts/Links: [List]

**MANUAL PROCEDURE CHECKPOINTS:**
- Procedure Document: [Path to procedure doc]
- Steps Completed: [List completed steps with numbers]
- Current Step: [Exact step being executed]
- Verification Checkpoints Passed: [List]
- Next Steps: [Sequence of remaining manual steps]

**ANSIBLE VAULT CONTEXT:**
- Vault Files Accessed: [List vault files used]
- Credentials Retrieved: [Which credentials, not values]
- Vault Updates Needed: [Any credential changes to apply]
- Vault Password Location: [Reference only]

**DOCKER DEV-ONLY STATE (if applicable):**
- Server: hx-dev-server (192.168.10.222) ONLY
- Purpose: Development/project isolation
- Container State: [Running containers, images]
- Volume Mounts: [Development volumes]
- NOTE: Production deployment separate (bare-metal)

**Example Infrastructure Handoff Entry:**
```
SYSTEMD SERVICE STATE:
Service Name: postgres.service
Unit File: /etc/systemd/system/postgres.service
Service Status: active (running) since 2025-11-20 14:30
Unit File Changes This Session:
  - Added TimeoutStartSec=60s
  - Modified User=postgres
Restart Required: Yes (deferred until after config validation)

BARE-METAL DEPLOYMENT PROGRESS:
Target Server: hx-postgres-server (192.168.10.212)
OS: Ubuntu 24 bare-metal
Package Installation Status:
  - Installed: postgresql-16, postgresql-contrib
  - Pending: pgadmin4, pg_backup scripts
  - Configuration Files Updated:
    - /etc/postgresql/16/main/postgresql.conf
    - /etc/postgresql/16/main/pg_hba.conf

MANUAL PROCEDURE CHECKPOINTS:
Procedure Document: /projects/auth-system/deployment/postgres-installation.md
Steps Completed: 1-7 (installation, configuration, base setup)
Current Step: Step 8 - Testing connections
Verification Checkpoints Passed:
  - Package installation verified
  - Config syntax validated
  - Service starts successfully
Next Steps:
  8. Complete connection testing
  9. Create application database
  10. Grant privileges
  11. Configure backups
```
</handoff_types>

<handoff_templates>
  <template name="End-of-Session Handoff Template">
  **Format:** Concise, action-oriented, quick continuation
  
  ```
  SESSION HANDOFF - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Handoff Date: YYYY-MM-DD HH:MM
  Session Duration: [X hours]
  Current Phase: [Phase name]
  Prepared By: [Name]
  
  CURRENT STATE:
  ──────────────────────────────────────────────────────────────────────
  Phase: [Current workflow phase]
  Progress: [X% complete]
  Status: [On track | Delayed | Blocked]
  
  WORK COMPLETED THIS SESSION:
  ──────────────────────────────────────────────────────────────────────
  1. [Accomplishment 1]
  2. [Accomplishment 2]
  3. [Accomplishment 3]
  
  Artifacts Created/Updated:
  - [ARTIFACT-XXX: Name - Status]
  - [ARTIFACT-YYY: Name - Status]
  
  CURRENT ACTIVITY:
  ──────────────────────────────────────────────────────────────────────
  Was Working On: [Specific task/activity in progress]
  Status: [Percentage complete or stage reached]
  Location: [File path or context location]
  
  NEXT IMMEDIATE ACTIONS (Resume Here):
  ──────────────────────────────────────────────────────────────────────
  1. [Next action 1 - Specific and actionable]
  2. [Next action 2 - Specific and actionable]
  3. [Next action 3 - Specific and actionable]
  
  OPEN ITEMS REQUIRING ATTENTION:
  ──────────────────────────────────────────────────────────────────────
  - [Open item 1 - Priority | Owner | Due date]
  - [Open item 2 - Priority | Owner | Due date]
  
  Blockers:
  - [Blocker description - Blocking what - Resolution approach]
  
  CONTINUATION INSTRUCTIONS:
  ──────────────────────────────────────────────────────────────────────
  To Continue in New Session:
  1. Load this handoff document
  2. Review "Current Activity" section for context
  3. Start with "Next Immediate Actions" #1
  4. Reference [specific files/documents] as needed
  
  Context Documents to Load:
  - [Document 1 path - Why needed]
  - [Document 2 path - Why needed]
  
  NOTES:
  [Any additional context, reminders, or important information]
  ```
  </template>

  <template name="Phase Transition Handoff Template">
  **Format:** Comprehensive phase summary, transition-focused
  
  ```
  PHASE TRANSITION HANDOFF - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Handoff Date: YYYY-MM-DD
  Completed Phase: [Phase name]
  Next Phase: [Phase name]
  Phase Transition: [X] → [Y]
  
  COMPLETED PHASE SUMMARY:
  ──────────────────────────────────────────────────────────────────────
  Phase: [Completed phase name]
  Duration: [Planned: X days | Actual: Y days]
  Status: ✓ Complete
  
  Phase Goals Achievement:
  - [Goal 1]: ✓ Achieved
  - [Goal 2]: ✓ Achieved
  - [Goal 3]: ⚠️ Partially achieved - [Explanation]
  
  PHASE DELIVERABLES:
  ──────────────────────────────────────────────────────────────────────
  Required Deliverables:
  - [ARTIFACT-XXX: Name - Status: Approved]
  - [ARTIFACT-YYY: Name - Status: Approved]
  
  Quality Gate Validation:
  - [Gate 1]: ✓ Passed
  - [Gate 2]: ✓ Passed
  
  LESSONS LEARNED FROM PHASE:
  ──────────────────────────────────────────────────────────────────────
  What Worked Well:
  - [Success factor 1]
  - [Success factor 2]
  
  What Could Be Improved:
  - [Improvement area 1 - Recommendation for next phase]
  
  NEXT PHASE CONTEXT:
  ──────────────────────────────────────────────────────────────────────
  Phase: [Next phase name]
  Objectives:
  - [Objective 1]
  - [Objective 2]
  
  Prerequisites Status:
  - [Prerequisite 1]: ✓ Met
  - [Prerequisite 2]: ✓ Met
  
  Expected Duration: [X days]
  Key Activities: [Brief list]
  
  CONTINUATION INSTRUCTIONS FOR NEXT PHASE:
  ──────────────────────────────────────────────────────────────────────
  To Begin Next Phase:
  1. Review completed phase deliverables at [paths]
  2. Load next phase workflow: [workflow command file]
  3. Execute Phase 1: [First phase step]
  4. Reference prior phase outputs as inputs
  
  Context Documents from Previous Phase:
  - [Critical document 1 - Why needed for next phase]
  - [Critical document 2 - Why needed for next phase]
  
  Carry-Forward Items:
  - [Open RAIDD item requiring attention in next phase]
  - [Unresolved question needing answer]
  ```
  </template>

  <template name="Complex Task Handoff Template">
  **Format:** Deep context, decision history, precise continuation
  
  ```
  COMPLEX TASK HANDOFF - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Handoff Date: YYYY-MM-DD HH:MM
  Task: [Complex task description]
  Started: YYYY-MM-DD
  Time Invested: [X hours]
  
  TASK OBJECTIVE AND SCOPE:
  ──────────────────────────────────────────────────────────────────────
  Objective: [What needs to be accomplished]
  Scope: [Boundaries of task]
  Success Criteria: [How to know task is complete]
  
  PROGRESS TO DATE:
  ──────────────────────────────────────────────────────────────────────
  Completed Steps:
  1. [Step 1] - ✓ Complete
  2. [Step 2] - ✓ Complete
  3. [Step 3] - 🔄 In Progress (70% complete)
  
  Current Sub-task: [Specific sub-task being worked on]
  Status: [Detailed status of current sub-task]
  
  EXACTLY WHERE STOPPED:
  ──────────────────────────────────────────────────────────────────────
  File/Location: [Exact file and line/section]
  Activity: [Precise activity - "Was editing X section, adding Y content"]
  Next Immediate Action: [Very next step - "Complete Y subsection, then move to Z"]
  
  DECISION HISTORY:
  ──────────────────────────────────────────────────────────────────────
  Key Decisions Made:
  1. [Decision 1] - Rationale: [Why] - Impact: [What this affects]
  2. [Decision 2] - Rationale: [Why] - Impact: [What this affects]
  
  Alternatives Considered and Rejected:
  - [Alternative approach] - Rejected because: [Reason]
  
  OPEN QUESTIONS AND CONSIDERATIONS:
  ──────────────────────────────────────────────────────────────────────
  Outstanding Questions:
  1. [Question 1] - Needs resolution before: [Milestone]
  2. [Question 2] - Impacts: [What this affects]
  
  Considerations for Next Steps:
  - [Consideration 1 - Why important]
  - [Consideration 2 - Potential issue to watch]
  
  NEXT SUB-TASKS IN SEQUENCE:
  ──────────────────────────────────────────────────────────────────────
  1. [Sub-task 1] - Estimated: [X time] - Prerequisites: [List]
  2. [Sub-task 2] - Estimated: [Y time] - Prerequisites: [List]
  3. [Sub-task 3] - Estimated: [Z time] - Prerequisites: [List]
  
  CONTEXT DOCUMENTS TO LOAD:
  ──────────────────────────────────────────────────────────────────────
  Essential Context:
  - [Document 1 path] - Contains: [What info] - Why needed: [Reason]
  - [Document 2 path] - Contains: [What info] - Why needed: [Reason]
  
  Reference Materials:
  - [Resource 1] - For: [Purpose]
  
  DETAILED CONTINUATION INSTRUCTIONS:
  ──────────────────────────────────────────────────────────────────────
  To Resume Complex Task:
  1. Load this handoff document completely
  2. Review "Decision History" to understand context
  3. Load all "Context Documents" listed above
  4. Navigate to "Exactly Where Stopped" location
  5. Read "Open Questions" to frame next decisions
  6. Execute "Next Immediate Action" from current status
  7. Proceed through "Next Sub-tasks in Sequence"
  
  Critical Context to Remember:
  - [Critical point 1 that must be kept in mind]
  - [Critical point 2 that must be kept in mind]
  
  NOTES:
  [Additional context, gotchas, reminders, discoveries made during work]
  ```
  </template>

  <template name="Master Tracker Template">
  **Format:** Living document tracking current project state
  
  ```
  MASTER PROJECT TRACKER - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Last Updated: YYYY-MM-DD HH:MM
  Current Phase: [Phase name]
  Overall Progress: [X%]
  Project Status: [On Track | At Risk | Delayed]
  
  CURRENT STATE SNAPSHOT:
  ──────────────────────────────────────────────────────────────────────
  Active Workflow: [Current workflow name]
  Active Phase: [Current phase name and number]
  Phase Progress: [X%]
  Next Milestone: [Milestone name - Due: YYYY-MM-DD]
  
  PROJECT HEALTH:
  Overall: [🟢 Green | 🟡 Yellow | 🔴 Red]
  Timeline: [On schedule | +X days | -Y days]
  Quality: [Meeting standards | Concerns | Issues]
  
  CRITICAL OPEN ITEMS (Require Immediate Attention):
  ──────────────────────────────────────────────────────────────────────
  P0 Issues:
  - [RAIDD-ISSUE-XXX: Description - Owner - Status]
  
  Blocking Dependencies:
  - [RAIDD-DEPENDENCY-YYY: Description - Waiting on]
  
  Critical Decisions Needed:
  - [RAIDD-DECISION-ZZZ: Decision required - By: Date]
  
  RECENT ACCOMPLISHMENTS (Last 7 Days):
  ──────────────────────────────────────────────────────────────────────
  - [Accomplishment 1 - Date]
  - [Accomplishment 2 - Date]
  - [Accomplishment 3 - Date]
  
  ARTIFACTS STATUS:
  ──────────────────────────────────────────────────────────────────────
  Total Artifacts: X
  - Approved: Y
  - Review: Z
  - Draft: A
  
  Recent Artifacts:
  - [ARTIFACT-XXX: Name - Status - Date]
  
  QUALITY GATES STATUS:
  ──────────────────────────────────────────────────────────────────────
  Current Phase Gates:
  - [Gate 1]: [Status]
  - [Gate 2]: [Status]
  
  Next Phase Gates:
  - [Gate 3]: Not yet reached
  
  RAIDD SUMMARY:
  ──────────────────────────────────────────────────────────────────────
  - Risks: X open (High: A, Medium: B, Low: C)
  - Issues: Y open (P0: D, P1: E, P2: F)
  - Assumptions: Z open (To validate: G)
  - Dependencies: W open (Blocking: H)
  - Decisions: V pending
  
  STAKEHOLDER COMMUNICATIONS:
  ──────────────────────────────────────────────────────────────────────
  Last Status Report: YYYY-MM-DD
  Next Status Report Due: YYYY-MM-DD
  Pending Stakeholder Actions:
  - [Action 1 - Stakeholder - Expected by]
  
  NEXT SESSION FOCUS:
  ──────────────────────────────────────────────────────────────────────
  Primary Objectives:
  1. [Objective 1]
  2. [Objective 2]
  3. [Objective 3]
  
  HANDOFF HISTORY:
  ──────────────────────────────────────────────────────────────────────
  Most Recent Handoff: [Date] - [Type] - [Path to handoff document]
  Total Handoffs: X
  See: /projects/{project-name}/handoffs/history.md
  ```
  </template>
</handoff_templates>

<generation_procedures>
  <procedure name="Generate End-of-Session Handoff">
  **Purpose:** Create standard handoff at end of work session
  
  **Generation Process:**
  
  1. **Capture Current State**
     - Current workflow and phase
     - Progress percentage
     - Overall status (on track, delayed, blocked)
  
  2. **Document Session Work**
     - List accomplishments completed this session
     - Identify artifacts created or updated
     - Quantify progress made (tasks, issues, gates)
  
  3. **Record Current Activity**
     - Exactly what was being worked on
     - How far progressed (%, stage, specific location)
     - File path or context location
  
  4. **Specify Next Actions**
     - List 3-5 immediate next actions
     - Make actions specific and actionable
     - Sequence actions in logical order
  
  5. **Identify Open Items**
     - Pending tasks requiring attention
     - Blockers preventing progress
     - Decisions needed
     - Include priority, owner, due date
  
  6. **Write Continuation Instructions**
     - Step-by-step how to resume work
     - Context documents to load
     - Where to start (reference to "Next Immediate Actions")
  
  7. **Add Notes**
     - Important reminders
     - Context that won't be obvious later
     - Gotchas or warnings
  
  8. **Generate Continuation Prompt**
     - Create ready-to-paste prompt for new session
     - Include handoff document reference
     - Specify starting point
  
  9. **Save Handoff**
     - Save to `/projects/{project-name}/handoffs/handoff-YYYYMMDD-HHMM.md`
     - Save continuation prompt to `/projects/{project-name}/handoffs/prompts/`
     - Update master tracker
     - Update handoff history
  
  **Outputs:**
  - End-of-session handoff document
  - Continuation prompt (ready to paste)
  - Updated master tracker
  - Handoff history entry
  </procedure>

  <procedure name="Generate Phase Transition Handoff">
  **Purpose:** Create comprehensive handoff at phase boundary
  
  **Generation Process:**
  
  1. **Summarize Completed Phase**
     - Phase goals and achievement status
     - Phase duration (planned vs. actual)
     - Completion confirmation
  
  2. **Document Phase Deliverables**
     - List all required deliverables with status
     - Confirm quality gate validation results
     - Reference artifact registry for complete list
  
  3. **Extract Phase Lessons**
     - What worked well (successes to repeat)
     - What could be improved (areas for growth)
     - Recommendations for next phase
  
  4. **Provide Next Phase Context**
     - Next phase objectives
     - Prerequisites status (verified met)
     - Expected duration
     - Key activities overview
  
  5. **Write Phase Transition Instructions**
     - How to begin next phase
     - Which workflow command to load
     - Context documents from previous phase to reference
     - Carry-forward items (open RAIDD, unresolved questions)
  
  6. **Save Phase Transition Handoff**
     - Comprehensive handoff document
     - Phase-specific continuation prompt
     - Update master tracker with phase change
     - Update handoff history
  
  **Outputs:**
  - Phase transition handoff document
  - Phase-specific continuation prompt
  - Updated master tracker (new phase)
  - Handoff history entry
  </procedure>

  <procedure name="Generate Complex Task Handoff">
  **Purpose:** Create deep-context handoff for complex activities
  
  **Generation Process:**
  
  1. **Document Task Context**
     - Task objective and scope
     - Success criteria
     - Background and rationale
  
  2. **Record Progress Detail**
     - Completed steps with status
     - Current sub-task with precise status
     - Time invested to date
  
  3. **Capture Exact Stopping Point**
     - Precise file and location (line number, section)
     - Exact activity ("Was editing X, adding Y")
     - Very next step to take
  
  4. **Document Decision History**
     - Key decisions made with rationale
     - Alternatives considered and rejected
     - Impact of decisions on task
  
  5. **List Open Questions**
     - Outstanding questions requiring resolution
     - Considerations for next steps
     - Potential issues to watch
  
  6. **Sequence Next Sub-tasks**
     - List next 3-5 sub-tasks in order
     - Estimate time for each
     - Identify prerequisites
  
  7. **Specify Context Documents**
     - Essential documents to load
     - What information each contains
     - Why each is needed for task
  
  8. **Write Detailed Continuation Instructions**
     - Step-by-step resumption process
     - Critical context to remember
     - Exact starting point
  
  9. **Add Detailed Notes**
     - Discoveries made during work
     - Gotchas encountered
     - Reminders for continuation
  
  10. **Save Complex Task Handoff**
      - Comprehensive handoff with deep context
      - Detailed continuation prompt
      - Update master tracker
      - Update handoff history
  
  **Outputs:**
  - Complex task handoff with deep context
  - Detailed continuation prompt
  - Updated master tracker
  - Handoff history entry
  </procedure>

  <procedure name="Update Master Tracker">
  **Purpose:** Maintain living document of current project state
  
  **Update Process:**
  
  1. **Update Current State Snapshot**
     - Active workflow and phase
     - Phase progress percentage
     - Next milestone and due date
  
  2. **Update Project Health**
     - Overall health indicator (Green/Yellow/Red)
     - Timeline status
     - Quality status
  
  3. **Update Critical Open Items**
     - P0 issues requiring immediate attention
     - Blocking dependencies
     - Critical decisions needed
  
  4. **Update Recent Accomplishments**
     - Last 7 days of accomplishments
     - Keep list fresh and current
  
  5. **Update Artifacts Status**
     - Total artifact counts by status
     - Recent artifact activity
  
  6. **Update Quality Gates**
     - Current phase gates status
     - Next phase gates preview
  
  7. **Update RAIDD Summary**
     - Current counts by type and severity
     - Highlight critical items
  
  8. **Update Stakeholder Communications**
     - Last status report date
     - Next status report due
     - Pending stakeholder actions
  
  9. **Update Next Session Focus**
     - Primary objectives for next session
     - Keep focused on immediate priorities
  
  10. **Update Handoff History Reference**
      - Most recent handoff date and type
      - Total handoff count
      - Link to full history
  
  11. **Save Master Tracker**
      - Overwrite with current state
      - Include "Last Updated" timestamp
      - Maintain at `/projects/{project-name}/handoffs/master-tracker.md`
  
  **Outputs:**
  - Updated master tracker with current state
  - Single source of truth for project status
  - Ready-to-use quick context for new sessions
  </procedure>

  <procedure name="Generate Continuation Prompt">
  **Purpose:** Create ready-to-paste prompt for new chat session
  
  **Prompt Generation Process:**
  
  1. **Start with Context Load**
     - "Load the following handoff document: [path]"
     - Reference master tracker for quick context
  
  2. **Provide Project Context**
     - Project name
     - Current phase
     - Brief current state (1-2 sentences)
  
  3. **Specify Starting Point**
     - "Resume work from: [Specific activity]"
     - Reference exact section in handoff document
  
  4. **List Context Documents**
     - "Also load these documents: [paths]"
     - Brief explanation why each needed
  
  5. **State First Action**
     - "Begin with: [Specific first action]"
     - Clear, actionable, specific
  
  6. **Format as Copy-Paste Prompt**
     - Plain text, easy to copy
     - No special formatting required
     - Ready to paste into new chat
  
  **Continuation Prompt Format:**
  ```
  Hi Claude,
  
  I'm continuing work on [Project Name]. Please load the following handoff
  document to understand current context:
  
  Handoff Document: [Path to handoff document]
  Master Tracker: [Path to master tracker]
  
  Current State:
  - Phase: [Current phase]
  - Status: [Brief status]
  - Was Working On: [Last activity]
  
  Please also load these context documents:
  - [Document 1 path] - [Why needed]
  - [Document 2 path] - [Why needed]
  
  Resume work by:
  [Specific first action from handoff document]
  
  Let me know when you've loaded the context and are ready to proceed.
  ```
  
  **Outputs:**
  - Ready-to-paste continuation prompt
  - Saved to `/projects/{project-name}/handoffs/prompts/continue-YYYYMMDD-HHMM.txt`
  - Can be copied directly into new chat session
  </procedure>
</generation_procedures>

<integration_with_workflows>
**Workflow Integration Points:**

Session handoffs integrate at natural breaking points:

**All Workflows:**
- End of work sessions (before closing chat)
- Between phases (phase transition handoffs)
- Before extended breaks (project pause handoffs)

**Charter Workflow:**
- After Phase 2 (Draft): Handoff before stakeholder review
- After Phase 4 (Approval): Phase transition to Spec workflow

**Spec Workflow:**
- After Phase 2 (Draft): Handoff during multi-day spec development
- After Phase 4 (Approval): Phase transition to Task workflow

**Task Workflow:**
- During Phase 1 (Breakdown): Handoff if complex task breakdown spans sessions
- After Phase 3 (Approval): Phase transition to Execution workflow

**Execution Workflow:**
- Frequent handoffs during Phase 2 (Work): Daily or per-task handoffs
- After Phase 4 (Integration): Phase transition to Closeout workflow

**Closeout Workflow:**
- After Phase 4 (Formal Closeout): Final project handoff for knowledge preservation

**Orchestration Integration:**
Multi-agent orchestrations benefit from complex task handoffs preserving specialist coordination context.
</integration_with_workflows>

<integration_convention>
**How Commands Invoke This Utility:**

This section documents how workflow commands (Set 1) and orchestration commands (Set 2) invoke the session handoff utility. Invocation uses instructional reference pattern specifying handoff type and current context.

**From Any Workflow/Orchestration:**
At natural stopping points, generate handoff:

**Example - End of Session:**
"Use cc-util-handoff to generate end-of-session handoff. Capture current
state: Execution Phase 2 (Work), 60% complete. Document work completed this
session: 3 tasks, 2 artifacts. Specify next actions: Complete deployment
script, validate configuration, run integration tests. Generate continuation
prompt for next session."

**Example - Phase Transition:**
"Use cc-util-handoff to generate phase transition handoff. Completed: Spec
Phase 4 (Approval). Deliverables: Specification v1.0 approved, 3 ADRs
documented. Quality gates: All passed. Next phase: Task Workflow Phase 1.
Generate comprehensive handoff with lessons learned and next phase context."

**Example - Complex Task:**
"Use cc-util-handoff to generate complex task handoff. Task: Multi-agent
synthesis for authentication architecture. Progress: Alex completed (ADRs),
Frank in progress (security review 70%). Exactly where stopped: Reviewing
Frank's security recommendations, Line 45 of security-review.md. Next:
Complete Frank's review, coordinate with William for infrastructure, then
synthesize. Generate detailed handoff with decision history."

**Required Inputs:**
1. **Handoff Type** - End-of-session, phase transition, complex task, project pause, team handoff
2. **Project Name** - For file organization
3. **Current State** - Phase, progress, status
4. **Session Work** - What was accomplished
5. **Current Activity** - Exactly what was being worked on
6. **Next Actions** - Immediate next steps (3-5 specific actions)
7. **Open Items** - Pending tasks, blockers, decisions
8. **Context Documents** - Paths to documents needing continuation

**Expected Outputs:**

1. **Handoff Document** (Primary Output)
   - Format: Structured markdown using appropriate template
   - Location: `/projects/{project-name}/handoffs/handoff-YYYYMMDD-HHMM.md`
   - Contents: Complete context, progress, next actions, continuation instructions

2. **Continuation Prompt** (Ready-to-Use)
   - Format: Plain text, copy-paste ready
   - Location: `/projects/{project-name}/handoffs/prompts/continue-YYYYMMDD-HHMM.txt`
   - Contents: Context load instructions, starting point, first action

3. **Updated Master Tracker** (Living Document)
   - Format: Current state snapshot
   - Location: `/projects/{project-name}/handoffs/master-tracker.md` (overwritten)
   - Contents: Current phase, critical items, recent work, next focus

4. **Handoff History Entry** (Chronological Log)
   - Format: Timestamped handoff record
   - Location: `/projects/{project-name}/handoffs/history.md` (appended)
   - Contents: Handoff date/time, type, phase, link to full handoff

**State Management:**

**Stateless Component:**
- cc-util-handoff.md utility file (this document)
- Instructions for handoff generation
- Handoff templates for different types
- No state maintained in utility itself

**Stateful Artifacts:**
- Handoff documents: `/projects/{project-name}/handoffs/handoff-YYYYMMDD-HHMM.md` (individual handoffs)
- Continuation prompts: `/projects/{project-name}/handoffs/prompts/` (ready-to-paste)
- Master tracker: `/projects/{project-name}/handoffs/master-tracker.md` (current state, overwritten)
- Handoff history: `/projects/{project-name}/handoffs/history.md` (chronological log, appended)
- Created/updated by following utility procedures
- Persistent across sessions
- Project-specific

**File Organization:**
```
/projects/{project-name}/
  handoffs/
    handoff-20251120-0900.md            ← Individual handoffs
    handoff-20251120-1700.md
    handoff-20251121-1600.md
    prompts/
      continue-20251120-0900.txt        ← Continuation prompts
      continue-20251120-1700.txt
    master-tracker.md                   ← Living current state
    history.md                          ← Chronological log
```

**Invocation Pattern Summary:**
1. Caller reaches natural stopping point (end of session, phase transition, complex task pause)
2. Caller references cc-util-handoff with handoff type and context
3. Utility captures current state, progress, next actions
4. Handoff document generated with comprehensive context
5. Continuation prompt created (ready-to-paste for new session)
6. Master tracker updated with current state
7. Handoff history appended
8. New session can load handoff and continue seamlessly
</integration_convention>

<usage_examples>
  <example name="End-of-Session Handoff">
  **Scenario:** End of work day, closing chat before resuming tomorrow
  
  **Command:**
  ```
  Generate handoff:
  - Type: End-of-Session
  - Project: auth-system
  - Current: Execution Phase 2 (Work), 65% complete
  - Completed: Deployment script, config file, 2 unit tests
  - Working On: Integration tests (3 of 5 complete)
  - Next: Finish integration tests, validate deployment, update runbook
  ```
  
  **Utility Process:**
  1. Capture current state (Execution 65%, on track)
  2. Document session work (3 artifacts, progress quantified)
  3. Record current activity (integration tests, 60% complete)
  4. Specify next 3 actions (finish tests, validate, document)
  5. Identify open items (1 blocker: staging environment access)
  6. Write continuation instructions
  7. Generate continuation prompt
  8. Update master tracker
  9. Save handoff
  
  **Output:** Handoff document with clear resume point, continuation prompt ready to paste tomorrow, master tracker shows current status. Tomorrow's session starts with "Load handoff-20251120-1700.md and continue with integration test #4."
  </example>

  <example name="Phase Transition Handoff">
  **Scenario:** Completing Spec workflow, transitioning to Task workflow
  
  **Command:**
  ```
  Generate handoff:
  - Type: Phase Transition
  - Completed Phase: Specification Workflow Phase 4 (Approval)
  - Deliverables: Spec v1.0 (approved), 3 ADRs (approved)
  - Quality Gates: All passed
  - Lessons: Stakeholder reviews worked well, need more upfront security input
  - Next Phase: Task Workflow Phase 1 (Breakdown)
  ```
  
  **Utility Process:**
  1. Summarize spec phase (goals achieved, 15 days actual vs. 12 planned)
  2. Document deliverables (ARTIFACT-005, ARTIFACT-014, 015, 016 all approved)
  3. Extract lessons learned
  4. Provide Task phase context (objectives, prerequisites, expected duration)
  5. Write phase transition instructions
  6. Generate phase-specific prompt
  7. Update master tracker (new phase)
  8. Save phase transition handoff
  
  **Output:** Comprehensive phase transition handoff with complete spec phase summary, lessons learned documented, Task workflow Phase 1 ready to start. New session loads handoff, reviews completed spec deliverables, begins task breakdown with full context.
  </example>

  <example name="Complex Task Handoff">
  **Scenario:** Mid-way through multi-agent orchestration, need to pause
  
  **Command:**
  ```
  Generate handoff:
  - Type: Complex Task
  - Task: Multi-agent authentication architecture synthesis
  - Progress: Alex complete (ADRs), Frank 70% (security review)
  - Stopped At: security-review.md, Line 45, reviewing Frank's recommendations
  - Decisions: OAuth 2.0 selected, Active Directory integration required
  - Next: Complete Frank review, coordinate William (infrastructure), synthesize
  ```
  
  **Utility Process:**
  1. Document task objective (complete architecture with all specialists)
  2. Record detailed progress (Alex outputs, Frank status)
  3. Capture exact stopping point (file, line, activity)
  4. Document decision history (OAuth decision, rationale, alternatives)
  5. List open questions (infrastructure capacity, deployment timeline)
  6. Sequence next sub-tasks (finish Frank, invoke William, synthesis)
  7. Specify context documents (Alex ADRs, Frank policies, architecture diagrams)
  8. Write detailed continuation instructions
  9. Add critical context notes
  10. Save complex task handoff
  
  **Output:** Deep-context handoff with decision history, exact resumption point, clear sequencing of remaining work. New session loads all context documents, reviews decisions made, resumes at Line 45 of security review without losing any context.
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Generate Before Closing:** Always create handoff before ending chat session. Don't trust memory - document everything.

2. ⚠️ **Specific Over Generic:** "Finish the spec" is useless. "Complete Security Considerations section in spec-v1.0.md, Lines 145-200" is actionable.

3. ⚠️ **Document Decisions:** Capture why choices were made, not just what was decided. Future you needs rationale.

4. ⚠️ **Exact Stopping Point:** "Was working on tests" insufficient. "Writing test case 4 in test-auth.py, Line 67, need to add assertion" enables immediate continuation.

5. ⚠️ **Master Tracker Current:** Keep master tracker as single source of truth. Update after every significant progress.

6. ⚠️ **Continuation Prompt Essential:** Ready-to-paste prompt eliminates friction in new sessions. Make it easy to continue.

7. ⚠️ **Complex Tasks Need Deep Context:** Don't skimp on context for complex work. Document decision history, open questions, considerations.

8. ⚠️ **Handoff Before Long Breaks:** Weekend/holiday breaks require comprehensive handoffs. Monday morning you will thank Friday afternoon you.

9. ⚠️ **Context Documents Listed:** Specify exactly which documents to load. "Load relevant docs" wastes time searching.

10. ⚠️ **No Assumptions About Future Context:** Stateless agents lose everything. Handoff must be complete, self-contained.

11. ⚠️ **Update Handoff History:** Chronological log of handoffs provides project narrative. Don't skip history updates.

12. ⚠️ **Test Continuation:** Best handoffs enable someone else to continue your work. Write for that audience.
</critical_reminders>

<validation_checklist>
**Handoff Generation Checklist:**
- [ ] Handoff type selected appropriate for situation
- [ ] Current state captured (phase, progress, status)
- [ ] Session work documented (accomplishments, artifacts)
- [ ] Current activity recorded with precision
- [ ] Next actions specified (3-5 specific, actionable)
- [ ] Open items identified (tasks, blockers, decisions)
- [ ] Context documents listed with paths
- [ ] Continuation instructions written step-by-step
- [ ] Exactly where stopped documented (file, line, activity)
- [ ] Decision history captured (for complex tasks)
- [ ] Notes added for important reminders

**Continuation Prompt Checklist:**
- [ ] Handoff document path specified
- [ ] Master tracker path specified
- [ ] Current state summarized briefly
- [ ] Context documents listed
- [ ] First action specified clearly
- [ ] Plain text format (copy-paste ready)
- [ ] Saved to prompts directory

**Master Tracker Update Checklist:**
- [ ] Current state snapshot updated
- [ ] Project health indicator current
- [ ] Critical open items listed
- [ ] Recent accomplishments updated (last 7 days)
- [ ] Artifacts status current
- [ ] Quality gates status current
- [ ] RAIDD summary current
- [ ] Next session focus specified
- [ ] Handoff history reference updated
- [ ] Last updated timestamp current

**Handoff History Update Checklist:**
- [ ] Handoff entry appended to history
- [ ] Date and time recorded
- [ ] Handoff type documented
- [ ] Current phase noted
- [ ] Link to full handoff document included
- [ ] Chronological order maintained
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-raidd.md` - RAIDD items for handoff
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-quality-gate.md` - Quality gate status
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md` - Artifact status
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-status-report.md` - Status reporting integration
- `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-project-closeout-workflow.md` - Final project handoff
</related_documents>

<metadata_footer>
**Version:** 1.2
**Status:** APPROVED - Production Ready
**Date:** 2025-11-24
**Last Updated:** 2025-11-24 (Enhanced integration convention header, added infrastructure-specific handoff considerations for systemd state, bare-metal deployment progress, manual procedure checkpoints)
**Compliance:** 100% semantic XML structure, comprehensive handoff generation, seamless continuation support
**Next Steps:** Use this utility at end of every session to enable seamless project continuation without information loss
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
**Handoff Coverage:** 6 handoff types (including infrastructure-specific) with complete templates, 5 generation procedures, continuation prompt automation, master tracker maintenance
**Infrastructure Philosophy:** Captures systemd service state, bare-metal deployment progress, manual procedure checkpoints, Ansible Vault context, Docker dev-only separation for HX-Infrastructure projects
</metadata_footer>
