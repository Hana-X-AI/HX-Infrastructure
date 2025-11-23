---
workflow: util-status-report
version: 1.1
date: 2025-11-20
status: APPROVED
type: utility-command
description: Status reporting utility for generating project status reports, progress summaries, stakeholder communications, and executive dashboards with metrics, trends, and actionable insights
applies_to: all_workflows, all_orchestrations, project_management, stakeholder_communication, progress_tracking
author: HX-Infrastructure Team
last_updated: 2025-11-20
update_notes: Enhanced integration convention clarity, infrastructure philosophy alignment
---

<metadata>
**Workflow:** Status Reporting Utility - Project Communication and Progress Tracking
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Enhanced integration convention header, infrastructure philosophy alignment)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Provide systematic status reporting for project visibility, stakeholder communication, progress tracking, risk highlighting, and decision support through comprehensive, consistent, actionable reports
</metadata>

<objective>
**Purpose:** Establish standardized status reporting that communicates project progress clearly, highlights risks and blockers proactively, provides actionable insights for decision-making, maintains stakeholder alignment, and preserves historical project trajectory.

**Utility Capabilities:**
- Generate executive summary reports for leadership visibility
- Create detailed progress reports tracking milestones and deliverables
- Produce weekly/periodic status updates for regular communication cadence
- Generate phase completion reports for workflow transitions
- Create stakeholder-specific reports tailored to audience needs
- Compile project closeout reports with comprehensive summaries
- Integrate RAIDD, quality gate, and artifact data into unified view
- Track metrics and trends (velocity, completion rates, issue resolution)
- Provide risk and issue highlights requiring attention
- Support multiple report formats (executive, detailed, technical, operational)

**When to Use This Utility:**
- During regular status review cycles (weekly, bi-weekly)
- At phase completion requiring stakeholder communication
- Before quality gate reviews requiring status documentation
- During project steering committee meetings
- When escalations or decisions require status context
- For project closeout requiring comprehensive summary
- When stakeholders request project visibility
- During retrospectives analyzing project trajectory
</objective>

<utility_overview>
**Core Function:**
This utility generates structured status reports by aggregating data from RAIDD logs, quality gates, artifact registry, and workflow progress, formatting information for specific audiences, highlighting critical items requiring attention, and providing actionable recommendations.

**Status Reporting Process:**
1. **Determine Report Type** - Select appropriate report template (executive, weekly, phase, closeout)
2. **Gather Status Data** - Collect progress, RAIDD, quality gate, artifact information
3. **Calculate Metrics** - Compute completion percentages, velocity, resolution times
4. **Identify Highlights** - Flag risks, blockers, achievements requiring attention
5. **Format Report** - Structure information for target audience
6. **Add Recommendations** - Provide actionable next steps and decisions needed
7. **Generate Report** - Create formatted status report document
8. **Distribute Report** - Share with appropriate stakeholders

**Key Principle:** Effective status reports are clear, concise, actionable, and audience-appropriate. They highlight what matters most without overwhelming with detail.
</utility_overview>

<state_management>
**State Management Pattern:**

This utility is **stateless** - the cc-util-status-report.md file contains instructions and templates only.

**State artifacts** are created by following these instructions:
- **Status Reports:** `/projects/{project-name}/status-reports/{report-type}-YYYYMMDD.md` (persistent)
- **Executive Summaries:** `/projects/{project-name}/status-reports/executive/exec-summary-YYYYMMDD.md` (periodic)
- **Progress Tracking:** `/projects/{project-name}/status-reports/progress-tracking.md` (persistent, updated)
- **Metrics History:** `/projects/{project-name}/status-reports/metrics-history.md` (persistent, trend tracking)
- **Report Catalog:** `/projects/{project-name}/status-reports/catalog.md` (persistent, index)

These state artifacts are:
- Created during first report generation
- Appended/updated throughout project lifecycle
- Persistent across sessions
- Project-specific (one status-reports directory per project)

**Distinction:**
- **Utility** = Stateless instructions + templates (this document)
- **Artifacts** = Stateful files created per project (reports, summaries, metrics, catalog)

**Report Evolution:**
Status reports document project trajectory:
- Charter phase: Initial status, project kickoff
- Spec phase: Requirements progress, design decisions
- Task phase: Task breakdown complete, test suite ready
- Execution phase: Weekly progress, issue resolution, deliverable completion
- Closeout phase: Final summary, lessons learned, complete metrics

This evolution provides complete project history and supports retrospective analysis.
</state_management>

<report_types>
**Report Type Definitions:**

**Executive Summary Report:**
High-level status for leadership and executive stakeholders.

**Audience:** Executives, senior leadership, steering committee
**Frequency:** Monthly or on-demand
**Length:** 1-2 pages
**Focus:** Strategic status, major risks, critical decisions needed

**Key Sections:**
- Project health indicator (Red/Yellow/Green)
- Progress summary (% complete, major milestones)
- Top 3 achievements
- Top 3 risks/issues requiring escalation
- Critical decisions needed
- Budget/resource summary (if applicable)
- Next period focus

**Weekly Status Report:**
Regular cadence report for project team and immediate stakeholders.

**Audience:** Project team, product owners, technical leads
**Frequency:** Weekly
**Length:** 2-4 pages
**Focus:** Detailed progress, task completion, issue resolution, upcoming work

**Key Sections:**
- Progress summary (accomplishments this week)
- Metrics (tasks completed, issues resolved, quality gates passed)
- RAIDD highlights (new risks, resolved issues, key decisions)
- Quality gate status
- Artifact updates (new artifacts, approved deliverables)
- Blockers and impediments
- Next week plan
- Help needed

**Phase Completion Report:**
Status report at workflow phase completion.

**Audience:** Project stakeholders, phase reviewers, approvers
**Frequency:** At phase boundaries
**Length:** 3-5 pages
**Focus:** Phase deliverables, quality gate validation, transition readiness

**Key Sections:**
- Phase summary (goals, achievements)
- Deliverables completed
- Quality gate validation results
- Artifacts produced and approved
- RAIDD items addressed
- Lessons learned from phase
- Next phase readiness
- Approval request/confirmation

**Progress Detail Report:**
Comprehensive progress tracking report.

**Audience:** Project managers, technical leads, detailed stakeholders
**Frequency:** Bi-weekly or monthly
**Length:** 5-8 pages
**Focus:** Detailed metrics, trend analysis, comprehensive status

**Key Sections:**
- Overall progress (% complete by workflow/phase)
- Milestone tracking (planned vs. actual)
- Velocity metrics (task completion rate, issue resolution time)
- RAIDD detailed status (all open items by type)
- Quality gate compliance
- Artifact inventory status
- Resource utilization
- Budget tracking (if applicable)
- Trend analysis (improving/declining metrics)
- Forecast and projections

**Stakeholder Communication Report:**
Tailored report for specific stakeholder groups.

**Audience:** Varies by stakeholder (security team, infrastructure team, business owners)
**Frequency:** On-demand or periodic
**Length:** 2-3 pages
**Focus:** Stakeholder-specific concerns and interests

**Key Sections:**
- Executive summary for stakeholder
- Items requiring stakeholder input/decision
- Stakeholder-specific risks or concerns
- Deliverables affecting stakeholder domain
- Next steps involving stakeholder
- Questions for stakeholder

**Project Closeout Report:**
Comprehensive final report at project completion.

**Audience:** All stakeholders, leadership, future project teams
**Frequency:** Once at project closeout
**Length:** 10-15 pages
**Focus:** Complete project summary, outcomes, lessons learned

**Key Sections:**
- Executive summary
- Project objectives and outcomes achieved
- Complete deliverables inventory
- Final RAIDD summary (all closed items, disposition of open items)
- Quality metrics and compliance
- Budget and resource summary
- Timeline analysis (planned vs. actual)
- Lessons learned (what worked, what to improve)
- Recommendations for future projects
- Artifacts and knowledge preservation
- Project team acknowledgments
</report_types>

<report_templates>
  <template name="Executive Summary Report Template">
  **Format:** Concise, high-level, decision-oriented
  
  ```
  EXECUTIVE SUMMARY - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Report Date: YYYY-MM-DD
  Reporting Period: [Date range]
  Project Phase: [Current phase]
  Overall Health: [🟢 Green | 🟡 Yellow | 🔴 Red]
  
  PROJECT HEALTH INDICATOR:
  Status: [Green/Yellow/Red]
  Rationale: [One-sentence explanation of health status]
  
  PROGRESS SUMMARY:
  Overall Completion: [X%]
  Current Phase: [Phase name - X% complete]
  Major Milestones:
  - [Milestone 1]: ✓ Complete
  - [Milestone 2]: 🔄 In Progress (X%)
  - [Milestone 3]: ⏳ Not Started
  
  TOP 3 ACHIEVEMENTS:
  1. [Achievement 1 - Impact]
  2. [Achievement 2 - Impact]
  3. [Achievement 3 - Impact]
  
  TOP 3 RISKS/ISSUES REQUIRING ATTENTION:
  1. [Risk/Issue 1 - Impact - Mitigation/Resolution needed]
  2. [Risk/Issue 2 - Impact - Mitigation/Resolution needed]
  3. [Risk/Issue 3 - Impact - Mitigation/Resolution needed]
  
  CRITICAL DECISIONS NEEDED:
  1. [Decision 1 - Why needed - Decision deadline]
  2. [Decision 2 - Why needed - Decision deadline]
  
  BUDGET/RESOURCE SUMMARY (if applicable):
  Budget: [On track | At risk | Over budget]
  Resources: [Adequate | Constrained | Critical shortage]
  
  NEXT PERIOD FOCUS:
  - [Key objective 1]
  - [Key objective 2]
  - [Key objective 3]
  
  EXECUTIVE ACTION REQUIRED:
  [List any actions/approvals needed from executives]
  ```
  </template>

  <template name="Weekly Status Report Template">
  **Format:** Structured, detailed, action-oriented
  
  ```
  WEEKLY STATUS REPORT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Report Date: YYYY-MM-DD
  Reporting Period: [Week of MM/DD - MM/DD]
  Prepared By: [Name]
  Distribution: [Stakeholder list]
  
  PROGRESS SUMMARY - THIS WEEK:
  ──────────────────────────────────────────────────────────────────────
  Accomplishments:
  - [Accomplishment 1 - Details]
  - [Accomplishment 2 - Details]
  - [Accomplishment 3 - Details]
  
  Deliverables Completed:
  - [ARTIFACT-XXX: Deliverable name - Status: Approved]
  - [ARTIFACT-YYY: Deliverable name - Status: Review]
  
  METRICS - THIS WEEK:
  ──────────────────────────────────────────────────────────────────────
  Tasks Completed: X of Y planned (Z% completion rate)
  Issues Resolved: A of B open (C resolved this week)
  Quality Gates: D passed, E in progress
  New Artifacts: F registered, G approved
  
  RAIDD HIGHLIGHTS:
  ──────────────────────────────────────────────────────────────────────
  New Risks Identified: [Count]
  - [RAIDD-RISK-XXX: Brief description - Severity: High/Medium/Low]
  
  Issues Resolved: [Count]
  - [RAIDD-ISSUE-XXX: Brief description - Resolution summary]
  
  Key Decisions Made: [Count]
  - [RAIDD-DECISION-XXX: Brief description - Impact]
  
  Dependencies Status:
  - [Count] fulfilled this week
  - [Count] blocking, requiring coordination
  
  QUALITY GATE STATUS:
  ──────────────────────────────────────────────────────────────────────
  [Gate name]: ✓ Passed | 🔄 In Progress | ❌ Failed | ⏳ Not Started
  [Gate name]: Status - [Brief notes]
  
  BLOCKERS AND IMPEDIMENTS:
  ──────────────────────────────────────────────────────────────────────
  Current Blockers:
  1. [Blocker description - Impact - Owner - Target resolution date]
  2. [Blocker description - Impact - Owner - Target resolution date]
  
  Help Needed:
  - [Specific help request - From whom - By when]
  
  NEXT WEEK PLAN:
  ──────────────────────────────────────────────────────────────────────
  Objectives:
  1. [Objective 1 - Success criteria]
  2. [Objective 2 - Success criteria]
  3. [Objective 3 - Success criteria]
  
  Planned Deliverables:
  - [Deliverable 1 - Expected completion date]
  - [Deliverable 2 - Expected completion date]
  
  Quality Gates Targeted:
  - [Gate name - Validation planned for MM/DD]
  
  NOTES:
  [Any additional context, upcoming events, vacation notices, etc.]
  ```
  </template>

  <template name="Phase Completion Report Template">
  **Format:** Comprehensive phase summary, transition-focused
  
  ```
  PHASE COMPLETION REPORT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Phase: [Phase name]
  Completion Date: YYYY-MM-DD
  Phase Duration: [Planned: X days | Actual: Y days]
  Report Prepared By: [Name]
  
  PHASE SUMMARY:
  ──────────────────────────────────────────────────────────────────────
  Phase Goals:
  [Original goals for this phase]
  
  Goals Achievement:
  - [Goal 1]: ✓ Achieved | ⚠️ Partially achieved | ❌ Not achieved
  - [Goal 2]: Status - [Details]
  - [Goal 3]: Status - [Details]
  
  DELIVERABLES COMPLETED:
  ──────────────────────────────────────────────────────────────────────
  Required Deliverables:
  - [ARTIFACT-XXX: Name - Status: Approved - Compliance: Compliant]
  - [ARTIFACT-YYY: Name - Status: Approved - Compliance: Compliant]
  
  Additional Deliverables:
  - [Bonus deliverable - Value added]
  
  QUALITY GATE VALIDATION:
  ──────────────────────────────────────────────────────────────────────
  Phase Exit Gates:
  - [Gate name]: ✓ PASSED - [Criteria met: X of X]
  - [Gate name]: ✓ PASSED - [Details]
  
  Validation Results:
  [Summary of gate validation outcomes]
  
  RAIDD ITEMS ADDRESSED:
  ──────────────────────────────────────────────────────────────────────
  Risks Mitigated: [Count]
  Issues Resolved: [Count]
  Assumptions Validated: [Count]
  Dependencies Fulfilled: [Count]
  Decisions Documented: [Count]
  
  Open RAIDD Items:
  [List items remaining open with disposition]
  
  LESSONS LEARNED - THIS PHASE:
  ──────────────────────────────────────────────────────────────────────
  What Worked Well:
  - [Success factor 1]
  - [Success factor 2]
  
  What Could Be Improved:
  - [Improvement area 1]
  - [Improvement area 2]
  
  Recommendations for Next Phase:
  - [Recommendation 1]
  - [Recommendation 2]
  
  NEXT PHASE READINESS:
  ──────────────────────────────────────────────────────────────────────
  Prerequisites Met: [Yes/No/Partially]
  - [Prerequisite 1]: ✓ Met
  - [Prerequisite 2]: Status
  
  Blockers for Next Phase:
  [None | List any blockers preventing next phase start]
  
  Readiness Status: [Ready to proceed | Blockers must be resolved | Not ready]
  
  APPROVAL REQUEST:
  ──────────────────────────────────────────────────────────────────────
  Phase Completion Approval Requested From: [Approver names/roles]
  Approval Criteria:
  - [Criterion 1]: Met
  - [Criterion 2]: Met
  
  Requested Approval By: YYYY-MM-DD
  ```
  </template>

  <template name="Progress Detail Report Template">
  **Format:** Comprehensive metrics, trend analysis, detailed tracking
  
  ```
  PROGRESS DETAIL REPORT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Report Date: YYYY-MM-DD
  Reporting Period: [Date range]
  Report Type: [Bi-weekly | Monthly | On-demand]
  
  OVERALL PROGRESS:
  ──────────────────────────────────────────────────────────────────────
  Project Completion: [X%]
  
  By Workflow:
  - Charter Workflow: [100%] ✓ Complete
  - Spec Workflow: [X%] 🔄 In Progress
  - Task Workflow: [Y%] Status
  - Execution Workflow: [Z%] Status
  - Closeout Workflow: [0%] ⏳ Not Started
  
  By Phase (Current Workflow):
  - Phase 1: [100%] ✓
  - Phase 2: [X%] 🔄
  - Phase 3: [0%] ⏳
  
  MILESTONE TRACKING:
  ──────────────────────────────────────────────────────────────────────
  | Milestone | Planned Date | Actual Date | Status | Variance |
  |-----------|--------------|-------------|--------|----------|
  | [M1] | YYYY-MM-DD | YYYY-MM-DD | ✓ Complete | On time |
  | [M2] | YYYY-MM-DD | YYYY-MM-DD | 🔄 In Progress | +3 days |
  | [M3] | YYYY-MM-DD | - | ⏳ Not Started | - |
  
  VELOCITY METRICS:
  ──────────────────────────────────────────────────────────────────────
  Current Period:
  - Task Completion Rate: X tasks/week (Target: Y tasks/week)
  - Issue Resolution Time: A days average (Target: B days)
  - Quality Gate Pass Rate: C% first attempt (Target: D%)
  
  Historical Comparison:
  - Task Completion: [Trending up ↑ | Stable → | Trending down ↓]
  - Issue Resolution: [Improving ↑ | Stable → | Declining ↓]
  
  RAIDD DETAILED STATUS:
  ──────────────────────────────────────────────────────────────────────
  Risks:
  - Total: X (High: A, Medium: B, Low: C)
  - Status: Open: D, Mitigating: E, Monitoring: F, Closed: G
  
  Issues:
  - Total: Y (P0: A, P1: B, P2: C, P3: D)
  - Status: Open: E, In Progress: F, Resolved: G, Closed: H
  
  Assumptions:
  - Total: Z (High confidence: A, Medium: B, Low: C)
  - Status: Open: D, Validating: E, Validated: F
  
  Dependencies:
  - Total: W (Blocking: A, Non-blocking: B)
  - Status: Open: C, Waiting: D, Fulfilled: E
  
  Decisions:
  - Total: V (Strategic: A, Architectural: B, Tactical: C)
  - Status: Proposed: D, Approved: E, Implemented: F
  
  QUALITY GATE COMPLIANCE:
  ──────────────────────────────────────────────────────────────────────
  Total Gates: X
  Passed: Y (Z%)
  Failed/Pending: A
  
  Gate Pass Statistics:
  - First Attempt Pass Rate: B%
  - Average Attempts to Pass: C
  
  ARTIFACT INVENTORY STATUS:
  ──────────────────────────────────────────────────────────────────────
  Total Artifacts: X
  By Status:
  - Draft: A
  - Review: B
  - Approved: C (Target: D for this phase)
  - Deprecated: E
  
  By Type:
  - Documentation: F
  - Architecture: G
  - Code: H
  - Testing: I
  
  Compliance: J artifacts compliant, K non-compliant
  
  TREND ANALYSIS:
  ──────────────────────────────────────────────────────────────────────
  Improving Metrics:
  - [Metric name]: [Trend explanation]
  
  Declining Metrics:
  - [Metric name]: [Trend explanation - Corrective action]
  
  FORECAST AND PROJECTIONS:
  ──────────────────────────────────────────────────────────────────────
  Projected Completion Date: YYYY-MM-DD (Original: YYYY-MM-DD)
  Variance: [On track | +X days | -Y days]
  
  Completion Probability:
  - On Time: [Z%]
  - Within +1 week: [A%]
  - Beyond +1 week: [B%]
  
  Risk Factors Affecting Forecast:
  - [Risk factor 1 - Impact]
  - [Risk factor 2 - Impact]
  ```
  </template>

  <template name="Project Closeout Report Template">
  **Format:** Comprehensive final summary, lessons learned, knowledge preservation
  
  ```
  PROJECT CLOSEOUT REPORT - [PROJECT NAME]
  ══════════════════════════════════════════════════════════════════════
  Project Completion Date: YYYY-MM-DD
  Project Duration: [Planned: X days | Actual: Y days]
  Report Date: YYYY-MM-DD
  Prepared By: [Name]
  
  EXECUTIVE SUMMARY:
  ──────────────────────────────────────────────────────────────────────
  [2-3 paragraph summary of project, outcomes, success]
  
  PROJECT OBJECTIVES AND OUTCOMES:
  ──────────────────────────────────────────────────────────────────────
  Original Objectives:
  1. [Objective 1] - Status: ✓ Achieved | ⚠️ Partially | ❌ Not achieved
  2. [Objective 2] - Status
  3. [Objective 3] - Status
  
  Outcomes Achieved:
  - [Outcome 1 - Measurable result]
  - [Outcome 2 - Measurable result]
  
  COMPLETE DELIVERABLES INVENTORY:
  ──────────────────────────────────────────────────────────────────────
  [Reference artifact catalog]
  
  Summary:
  - Total Artifacts: X
  - Documentation: A artifacts
  - Architecture: B artifacts (C ADRs)
  - Code: D artifacts
  - Testing: E artifacts (F test cases)
  - All artifacts compliant and approved: [Yes/No]
  
  FINAL RAIDD SUMMARY:
  ──────────────────────────────────────────────────────────────────────
  Total RAIDD Items: X
  
  Risks:
  - Total: A (Closed: B, Occurred: C)
  - High severity mitigated: D
  
  Issues:
  - Total: E (Resolved: F, Won't Fix: G)
  - P0 issues: H (Average resolution time: I days)
  
  Assumptions:
  - Total: J (Validated: K, Invalidated: L, Monitoring: M)
  
  Dependencies:
  - Total: N (Fulfilled: O, Remained unfulfilled: P - Disposition)
  
  Decisions:
  - Total: Q (Implemented: R, Strategic decisions: S)
  
  QUALITY METRICS AND COMPLIANCE:
  ──────────────────────────────────────────────────────────────────────
  Quality Gates:
  - Total: X
  - Passed: Y (Z% first attempt pass rate)
  - Average attempts to pass: A
  
  Compliance:
  - All deliverables compliant: [Yes/No]
  - Standards compliance rate: B%
  
  TIMELINE ANALYSIS:
  ──────────────────────────────────────────────────────────────────────
  Original Timeline: [Start] to [End] = X days
  Actual Timeline: [Start] to [End] = Y days
  Variance: [On time | +Z days | -W days]
  
  Phase Duration Comparison:
  | Phase | Planned | Actual | Variance |
  |-------|---------|--------|----------|
  | Charter | X days | Y days | +/-Z |
  | Spec | A days | B days | +/-C |
  | Task | D days | E days | +/-F |
  | Execution | G days | H days | +/-I |
  | Closeout | J days | K days | +/-L |
  
  LESSONS LEARNED:
  ──────────────────────────────────────────────────────────────────────
  What Worked Well:
  1. [Success factor 1 - Why it worked]
  2. [Success factor 2 - Why it worked]
  3. [Success factor 3 - Why it worked]
  
  What Could Be Improved:
  1. [Improvement area 1 - How to improve]
  2. [Improvement area 2 - How to improve]
  3. [Improvement area 3 - How to improve]
  
  Surprises and Challenges:
  - [Challenge 1 - How addressed]
  - [Challenge 2 - How addressed]
  
  RECOMMENDATIONS FOR FUTURE PROJECTS:
  ──────────────────────────────────────────────────────────────────────
  Process Recommendations:
  1. [Recommendation 1]
  2. [Recommendation 2]
  
  Technical Recommendations:
  1. [Recommendation 1]
  2. [Recommendation 2]
  
  Resource Recommendations:
  1. [Recommendation 1]
  2. [Recommendation 2]
  
  ARTIFACTS AND KNOWLEDGE PRESERVATION:
  ──────────────────────────────────────────────────────────────────────
  All Artifacts Located At: [Path]
  Key Documentation: [List critical docs]
  Knowledge Vault Contributions: [List additions to knowledge vault]
  
  PROJECT TEAM ACKNOWLEDGMENTS:
  ──────────────────────────────────────────────────────────────────────
  Project Team:
  - [Name - Role - Key contributions]
  - [Name - Role - Key contributions]
  
  Special Recognition:
  - [Name - Exceptional contribution]
  ```
  </template>
</report_templates>

<generation_procedures>
  <procedure name="Generate Executive Summary Report">
  **Purpose:** Create high-level status report for leadership
  
  **Generation Process:**
  
  1. **Determine Report Period**
     - Monthly, quarterly, or on-demand
     - Date range covered
  
  2. **Assess Project Health**
     - Review RAIDD log for high-severity risks, P0/P1 issues
     - Check quality gate compliance
     - Evaluate timeline adherence
     - Determine health indicator:
       - 🟢 Green: On track, no major concerns
       - 🟡 Yellow: Some concerns, risks managed
       - 🔴 Red: Significant issues, escalation needed
  
  3. **Calculate Progress Metrics**
     - Overall completion percentage
     - Current phase completion
     - Major milestone status
  
  4. **Identify Top Achievements**
     - Select 3 most significant accomplishments
     - Focus on business value and impact
  
  5. **Identify Top Risks/Issues**
     - Select 3 most critical items requiring attention
     - Prioritize by impact and urgency
     - Include mitigation/resolution status
  
  6. **Determine Critical Decisions Needed**
     - Identify decisions blocking progress
     - Decisions with approaching deadlines
     - Strategic choices requiring executive input
  
  7. **Format Executive Summary**
     - Use executive summary template
     - Keep to 1-2 pages maximum
     - Use clear, non-technical language
     - Focus on business impact
  
  8. **Add Executive Actions Required**
     - List specific approvals needed
     - Decisions requiring executive input
     - Resources or support needed
  
  9. **Review and Refine**
     - Ensure clarity and conciseness
     - Verify accuracy of status
     - Remove unnecessary technical detail
  
  10. **Save and Distribute**
      - Save to `/projects/{project-name}/status-reports/executive/exec-summary-YYYYMMDD.md`
      - Distribute to executive stakeholder list
  
  **Outputs:**
  - Executive summary report (1-2 pages)
  - Distribution to leadership
  - Archive in report catalog
  </procedure>

  <procedure name="Generate Weekly Status Report">
  **Purpose:** Create regular cadence status update for project team
  
  **Generation Process:**
  
  1. **Define Reporting Period**
     - Week of [Date] to [Date]
     - Standard weekly cadence (e.g., every Monday)
  
  2. **Gather Progress Data**
     - Accomplishments this week (from workflow progress)
     - Deliverables completed (from artifact registry)
     - Tasks completed (from task tracking)
  
  3. **Calculate Weekly Metrics**
     - Tasks completed vs. planned
     - Issues resolved this week
     - Quality gates passed
     - New artifacts registered and approved
  
  4. **Query RAIDD Log**
     - New risks identified this week
     - Issues resolved this week
     - Key decisions made
     - Dependencies fulfilled or blocking
  
  5. **Check Quality Gate Status**
     - Gates passed, in progress, failed
     - Gates approaching validation
  
  6. **Identify Blockers and Impediments**
     - Current blockers preventing progress
     - Help needed from specific parties
  
  7. **Plan Next Week**
     - Objectives for next week
     - Planned deliverables
     - Quality gates targeted for validation
  
  8. **Format Weekly Report**
     - Use weekly status report template
     - Keep to 2-4 pages
     - Include specific details for team context
  
  9. **Add Notes Section**
     - Upcoming events (reviews, demos, meetings)
     - Vacation notices
     - Process changes
  
  10. **Save and Distribute**
      - Save to `/projects/{project-name}/status-reports/weekly-status-YYYYMMDD.md`
      - Distribute to project team and stakeholders
      - Update progress tracking log
  
  **Outputs:**
  - Weekly status report (2-4 pages)
  - Distribution to project team
  - Progress tracking update
  - Archive in report catalog
  </procedure>

  <procedure name="Generate Phase Completion Report">
  **Purpose:** Document phase completion and transition readiness
  
  **Generation Process:**
  
  1. **Identify Completed Phase**
     - Phase name and workflow
     - Completion date
     - Planned vs. actual duration
  
  2. **Review Phase Goals**
     - Original goals for phase
     - Achievement status for each goal
  
  3. **Compile Deliverables**
     - Query artifact registry for phase deliverables
     - Verify all required deliverables approved
     - List additional deliverables produced
  
  4. **Validate Quality Gates**
     - Confirm phase exit gates passed
     - Include gate validation reports
     - Document any gate remediation
  
  5. **Summarize RAIDD Activity**
     - Count RAIDD items addressed during phase
     - List open items with disposition
     - Highlight key decisions made
  
  6. **Extract Phase Lessons**
     - What worked well
     - What could be improved
     - Recommendations for next phase
  
  7. **Assess Next Phase Readiness**
     - Verify prerequisites met
     - Identify any blockers
     - Determine readiness status
  
  8. **Request Phase Approval**
     - Identify required approvers
     - List approval criteria
     - Set approval deadline
  
  9. **Format Phase Completion Report**
     - Use phase completion report template
     - Include comprehensive phase summary
     - Attach supporting artifacts
  
  10. **Save and Distribute**
      - Save to `/projects/{project-name}/status-reports/phase-completion-{phase}-YYYYMMDD.md`
      - Distribute to approvers and stakeholders
      - Update project status
  
  **Outputs:**
  - Phase completion report (3-5 pages)
  - Approval request documentation
  - Phase readiness assessment
  - Archive in report catalog
  </procedure>

  <procedure name="Generate Progress Detail Report">
  **Purpose:** Create comprehensive progress tracking with metrics and trends
  
  **Generation Process:**
  
  1. **Define Reporting Scope**
     - Bi-weekly, monthly, or on-demand
     - Date range and period covered
  
  2. **Calculate Overall Progress**
     - Completion percentage by workflow
     - Completion percentage by phase
     - Total project completion
  
  3. **Track Milestone Progress**
     - Compare planned vs. actual milestone dates
     - Calculate variance (on time, delayed)
     - Identify milestone risks
  
  4. **Compute Velocity Metrics**
     - Task completion rate (tasks/week)
     - Issue resolution time (days average)
     - Quality gate pass rate (% first attempt)
     - Compare to historical data and targets
  
  5. **Generate RAIDD Detail Status**
     - Query RAIDD log for complete status
     - Break down by type, severity/priority, status
     - Calculate RAIDD metrics
  
  6. **Assess Quality Gate Compliance**
     - Total gates, passed, failed/pending
     - Pass rate statistics
     - Gate validation trends
  
  7. **Compile Artifact Inventory Status**
     - Total artifacts by status and type
     - Compliance status
     - Artifact production rate
  
  8. **Analyze Trends**
     - Identify improving metrics (positive trends)
     - Identify declining metrics (negative trends)
     - Explain trend causes
     - Propose corrective actions for declining trends
  
  9. **Generate Forecast and Projections**
     - Project completion date
     - Variance from planned date
     - Completion probability
     - Risk factors affecting forecast
  
  10. **Format Progress Detail Report**
      - Use progress detail report template
      - Include comprehensive metrics and analysis
      - Add charts/graphs if helpful
  
  11. **Save and Distribute**
      - Save to `/projects/{project-name}/status-reports/progress-detail-YYYYMMDD.md`
      - Update metrics history with period data
      - Distribute to detailed stakeholders
  
  **Outputs:**
  - Progress detail report (5-8 pages)
  - Metrics history update
  - Trend analysis
  - Archive in report catalog
  </procedure>

  <procedure name="Generate Project Closeout Report">
  **Purpose:** Create comprehensive final project summary
  
  **Generation Process:**
  
  1. **Compile Project Overview**
     - Project duration (planned vs. actual)
     - Executive summary of project outcomes
  
  2. **Assess Objectives Achievement**
     - List original objectives
     - Determine achievement status
     - Document measurable outcomes
  
  3. **Generate Complete Deliverables Inventory**
     - Reference artifact catalog for complete list
     - Summarize artifacts by type
     - Confirm all artifacts approved and compliant
  
  4. **Create Final RAIDD Summary**
     - Total RAIDD items throughout project
     - Disposition of all items (closed, resolved, etc.)
     - Key statistics (resolution times, mitigation success)
  
  5. **Compile Quality Metrics**
     - Quality gate statistics
     - Compliance rates
     - First attempt pass rates
  
  6. **Analyze Timeline Performance**
     - Planned vs. actual timeline
     - Phase duration comparison
     - Variance analysis
  
  7. **Extract Comprehensive Lessons Learned**
     - What worked well (successes to repeat)
     - What could be improved (areas for growth)
     - Surprises and challenges (unexpected issues)
     - Document how challenges were addressed
  
  8. **Formulate Recommendations**
     - Process recommendations for future projects
     - Technical recommendations
     - Resource recommendations
  
  9. **Document Artifacts and Knowledge Preservation**
     - Location of all project artifacts
     - Key documentation references
     - Knowledge vault contributions
  
  10. **Acknowledge Project Team**
      - List project team members and roles
      - Document key contributions
      - Provide special recognition
  
  11. **Format Project Closeout Report**
      - Use project closeout report template
      - Comprehensive 10-15 page report
      - Professional formatting
  
  12. **Review and Finalize**
      - Review with project lead
      - Verify accuracy and completeness
      - Obtain final approvals
  
  13. **Save and Distribute**
      - Save to `/projects/{project-name}/status-reports/project-closeout-YYYYMMDD.md`
      - Distribute to all stakeholders and leadership
      - Archive with project documentation
      - Contribute to knowledge vault
  
  **Outputs:**
  - Project closeout report (10-15 pages)
  - Complete project summary
  - Lessons learned documentation
  - Knowledge vault contribution
  - Archive in report catalog
  </procedure>
</generation_procedures>

<integration_with_utilities>
**Utility Data Integration:**

Status reports aggregate data from other utilities:

**RAIDD Log (cc-util-raidd.md):**
- Query RAIDD log for risks, issues, assumptions, dependencies, decisions
- Extract counts by type, severity/priority, status
- Identify new items, resolved items, open items requiring attention
- Include RAIDD metrics in status reports

**Quality Gate (cc-util-quality-gate.md):**
- Query quality gate validation history
- Extract gate pass/fail statistics
- Calculate first attempt pass rates
- Include gate compliance in status reports

**Artifact Tracker (cc-util-artifact-tracker.md):**
- Query artifact registry for complete inventory
- Extract artifact counts by type and status
- Calculate compliance percentages
- Include artifact status in status reports

**Context Prep (cc-util-context-prep.md):**
- Reference orchestration context documents
- Include specialist coordination status
- Track multi-agent synthesis progress

**Integration Pattern:**
Status reporting utility queries other utility artifacts (RAIDD logs, quality gate histories, artifact registries) to aggregate data into unified project view. This prevents manual data collection and ensures consistency across reports.
</integration_with_utilities>

<integration_convention>
**How Commands Invoke This Utility:**

This section documents how workflow commands (Set 1) and orchestration commands (Set 2) invoke the status reporting utility. Invocation uses instructional reference pattern specifying report type, period, and target audience.

**From Workflow Commands (Set 1):**
At phase completion or regular intervals, commands invoke status reporting:

**Example from cc-execution-workflow.md Phase 4:**
"Use cc-util-status-report to generate phase completion report. Report type:
Phase Completion. Phase: Execution. Include quality gate validation results,
artifact inventory, RAIDD summary. Request approval for integration and
promotion to production."

**Example from cc-closeout-workflow.md Phase 4:**
"Use cc-util-status-report to generate project closeout report. Include
complete project summary, all deliverables, final RAIDD status, quality
metrics, timeline analysis, lessons learned, recommendations. Distribute
to all stakeholders and archive with project documentation."

**From Orchestration Commands (Set 2):**
Orchestrations may request status summaries for specialist coordination:

**Example from cc-agent-zero-synthesis.md Phase 7:**
"Use cc-util-status-report to generate multi-agent coordination summary.
Include specialist deliverables, cross-domain integration status, synthesis
outcomes, lessons learned from multi-agent coordination."

**From Project Management Context:**
Regular status reporting cadence:

**Weekly Status:**
"Use cc-util-status-report every Monday to generate weekly status report.
Include progress this week, metrics, RAIDD highlights, blockers, next week
plan. Distribute to project team."

**Monthly Executive Summary:**
"Use cc-util-status-report first of month to generate executive summary.
Include project health indicator, progress summary, top achievements, top
risks, critical decisions needed. Distribute to leadership."

**Required Inputs:**
1. **Report Type** - Executive, Weekly, Phase Completion, Progress Detail, Closeout
2. **Reporting Period** - Date range or period covered
3. **Project Name** - For file organization and context
4. **Phase/Workflow Context** - Current phase and workflow status
5. **Target Audience** - Executives, project team, stakeholders, leadership
6. **Data Sources** - RAIDD log, quality gates, artifact registry locations
7. **Distribution List** - Stakeholders to receive report
8. **Special Requests** - Any specific items to highlight or address

**Expected Outputs:**

1. **Status Report Document** (Primary Output)
   - Format: Structured markdown report using appropriate template
   - Location: `/projects/{project-name}/status-reports/{report-type}-YYYYMMDD.md`
   - Contents: Comprehensive status based on report type

2. **Progress Tracking Update** (Persistent Log)
   - Format: Progress tracking log with period metrics
   - Location: `/projects/{project-name}/status-reports/progress-tracking.md` (appended)
   - Contents: Period completion %, metrics, milestones, trends

3. **Metrics History Entry** (Trend Tracking)
   - Format: Time-series metrics data
   - Location: `/projects/{project-name}/status-reports/metrics-history.md` (appended)
   - Contents: Period metrics for trend analysis

4. **Report Catalog Entry** (Index)
   - Format: Catalog of all reports generated
   - Location: `/projects/{project-name}/status-reports/catalog.md` (updated)
   - Contents: Report index by type, date, audience

**State Management:**

**Stateless Component:**
- cc-util-status-report.md utility file (this document)
- Instructions for report generation procedures
- Report templates and formats
- No state maintained in utility itself

**Stateful Artifacts:**
- Status reports: `/projects/{project-name}/status-reports/{report-type}-YYYYMMDD.md` (individual reports)
- Progress tracking: `/projects/{project-name}/status-reports/progress-tracking.md` (persistent log)
- Metrics history: `/projects/{project-name}/status-reports/metrics-history.md` (trend data)
- Report catalog: `/projects/{project-name}/status-reports/catalog.md` (report index)
- Created/updated by following utility procedures
- Persistent across sessions
- Project-specific

**File Organization:**
```
/projects/{project-name}/
  status-reports/
    executive/
      exec-summary-20251120.md          ← Executive summaries
      exec-summary-20251220.md
    weekly-status-20251118.md           ← Weekly reports
    weekly-status-20251125.md
    phase-completion-charter-20251115.md ← Phase completions
    phase-completion-spec-20251205.md
    progress-detail-20251130.md         ← Detailed progress reports
    project-closeout-20251220.md        ← Final closeout report
    progress-tracking.md                ← Persistent progress log
    metrics-history.md                  ← Time-series metrics
    catalog.md                          ← Report index
```

**Invocation Pattern Summary:**
1. Caller determines report type needed (executive, weekly, phase, detail, closeout)
2. Caller references cc-util-status-report with report type and period
3. Utility queries RAIDD, quality gates, artifacts for data
4. Utility calculates metrics and identifies highlights
5. Report generated using appropriate template
6. Progress tracking and metrics history updated
7. Report saved to standard location
8. Report distributed to stakeholders
9. Report catalog updated
</integration_convention>

<usage_examples>
  <example name="Generate Weekly Status Report">
  **Scenario:** Monday morning weekly status report generation
  
  **Command:**
  ```
  Generate status report:
  - Project: auth-system
  - Report Type: Weekly Status
  - Period: Week of 2025-11-18 to 2025-11-22
  - Distribution: Project team, product owner, technical leads
  ```
  
  **Utility Process:**
  1. Query progress data (accomplishments, deliverables completed)
  2. Calculate weekly metrics (tasks, issues, gates, artifacts)
  3. Query RAIDD log for highlights (new risks, resolved issues, decisions)
  4. Check quality gate status
  5. Identify blockers and help needed
  6. Plan next week objectives
  7. Format using weekly status template
  8. Save and distribute
  
  **Output:** Weekly status report showing 8 tasks completed (90% completion rate), 3 issues resolved, 2 quality gates passed, 1 blocker requiring infrastructure team help, next week focused on deployment readiness
  </example>

  <example name="Generate Executive Summary">
  **Scenario:** Monthly executive summary for steering committee
  
  **Command:**
  ```
  Generate status report:
  - Project: auth-system
  - Report Type: Executive Summary
  - Period: November 2025
  - Audience: Executive steering committee
  ```
  
  **Utility Process:**
  1. Assess project health (review RAIDD, gates, timeline)
  2. Determine health indicator: 🟡 Yellow (one P0 issue blocking deployment)
  3. Calculate progress: 65% overall, execution phase 80% complete
  4. Identify top 3 achievements (OAuth implementation complete, security review passed, test coverage 95%)
  5. Identify top 3 risks/issues (deployment blocker, infrastructure resource constraint, third-party OAuth provider SLA concern)
  6. Determine critical decisions (production rollout date, resource allocation for infrastructure)
  7. Format executive summary (2 pages)
  8. Add executive action: Approve +1 infrastructure engineer allocation
  
  **Output:** 2-page executive summary with Yellow health indicator, clear risk escalation, specific decision request, concise progress summary
  </example>

  <example name="Generate Phase Completion Report">
  **Scenario:** Specification phase complete, requesting transition to Task phase
  
  **Command:**
  ```
  Generate status report:
  - Project: auth-system
  - Report Type: Phase Completion
  - Phase: Specification (Phase 4 - Approval)
  - Request approval for transition to Task phase
  ```
  
  **Utility Process:**
  1. Review spec phase goals (all achieved)
  2. Compile deliverables (specification v1.0 approved, 3 ADRs documented, technical designs complete)
  3. Validate quality gates (spec_approval_gate PASSED)
  4. Summarize RAIDD (2 assumptions validated, 1 architectural decision made, 3 dependencies identified for task phase)
  5. Extract lessons (stakeholder review process worked well, need more upfront security input next time)
  6. Assess next phase readiness (Ready - all prerequisites met)
  7. Request approval from product owner and technical lead
  8. Format phase completion report
  
  **Output:** Phase completion report documenting successful spec phase, all deliverables approved, ready to proceed to Task phase, requesting formal approval
  </example>

  <example name="Generate Progress Detail Report">
  **Scenario:** Monthly detailed progress report for project tracking
  
  **Command:**
  ```
  Generate status report:
  - Project: auth-system
  - Report Type: Progress Detail
  - Period: November 2025 (monthly)
  - Audience: Project manager, technical leads
  ```
  
  **Utility Process:**
  1. Calculate overall progress (65% complete, execution phase 80%)
  2. Track milestones (Design milestone complete on time, Implementation milestone +3 days)
  3. Compute velocity metrics (task completion 8 tasks/week target 7, issue resolution 2.5 days avg target 3 days - improving)
  4. Generate detailed RAIDD status (2 high risks, 1 P0 issue, 8 total open items)
  5. Check quality gate compliance (12 of 15 gates passed, 80% first attempt pass rate)
  6. Compile artifact inventory (45 artifacts, 38 approved, 93% compliant)
  7. Analyze trends (task completion trending up, issue resolution improving)
  8. Forecast completion (projected 2025-12-20, original 2025-12-15, +5 days variance)
  9. Format comprehensive report with metrics and charts
  
  **Output:** 7-page detailed progress report with complete metrics, trend analysis showing improving velocity, forecast indicating slight delay due to P0 issue, recommendations for maintaining momentum
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Audience-Appropriate Content:** Tailor report detail and language to audience. Executives need concise summaries, technical teams need detailed metrics.

2. ⚠️ **Timely Reporting:** Regular cadence builds trust. Weekly reports every Monday, monthly summaries first of month, phase reports immediately after completion.

3. ⚠️ **Highlight What Matters:** Don't bury critical issues in details. Top risks, blockers, and decisions needed should be prominent.

4. ⚠️ **Actionable Recommendations:** Reports should drive action. Always include clear next steps, decisions needed, help required.

5. ⚠️ **Data-Driven Status:** Base status on objective data from RAIDD, quality gates, artifacts. Avoid subjective "feels like" assessments.

6. ⚠️ **Honest Status Reporting:** Yellow/Red status indicators are not failures - they're reality. Honest reporting enables proper support.

7. ⚠️ **Trend Analysis Matters:** Single-point metrics are snapshots. Trends (improving/declining) tell the real story.

8. ⚠️ **Celebrate Achievements:** Don't focus only on problems. Highlighting accomplishments maintains morale and demonstrates progress.

9. ⚠️ **Consistent Format:** Using consistent templates enables comparison across periods. Don't reinvent report structure each time.

10. ⚠️ **Distribution Matters:** Reports only provide value if stakeholders receive and read them. Maintain accurate distribution lists.

11. ⚠️ **Archive Reports:** Status reports are project history. Archive all reports for retrospective analysis and audits.

12. ⚠️ **Follow Up on Actions:** Reports identifying help needed or decisions required must have follow-up to ensure action taken.
</critical_reminders>

<validation_checklist>
**Report Generation Checklist:**
- [ ] Report type selected appropriate for audience and purpose
- [ ] Reporting period clearly specified
- [ ] Data sources queried (RAIDD, quality gates, artifacts, progress)
- [ ] Metrics calculated accurately
- [ ] Project health/status assessed objectively
- [ ] Achievements highlighted
- [ ] Risks/issues requiring attention identified
- [ ] Recommendations provided (actionable, specific)
- [ ] Template used consistently
- [ ] Report length appropriate for type
- [ ] Language appropriate for audience
- [ ] Report saved to standard location
- [ ] Progress tracking updated (if applicable)
- [ ] Metrics history updated (if applicable)
- [ ] Report catalog updated
- [ ] Distribution list current
- [ ] Report distributed to stakeholders

**Executive Summary Checklist:**
- [ ] 1-2 pages maximum
- [ ] Project health indicator (Green/Yellow/Red) with rationale
- [ ] Progress summary with percentage complete
- [ ] Top 3 achievements listed
- [ ] Top 3 risks/issues identified with impact
- [ ] Critical decisions needed specified
- [ ] Executive actions required listed
- [ ] Non-technical language used
- [ ] Business value focus

**Weekly Status Checklist:**
- [ ] Accomplishments this week documented
- [ ] Deliverables completed listed
- [ ] Weekly metrics calculated
- [ ] RAIDD highlights included
- [ ] Quality gate status current
- [ ] Blockers and impediments identified
- [ ] Help needed specified
- [ ] Next week plan outlined
- [ ] Notes section included

**Phase Completion Checklist:**
- [ ] Phase goals and achievement status documented
- [ ] All deliverables listed with approval status
- [ ] Quality gate validation results included
- [ ] RAIDD items addressed summarized
- [ ] Lessons learned extracted
- [ ] Next phase readiness assessed
- [ ] Approval request specified with criteria
- [ ] Approvers identified
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-raidd.md` - RAIDD data source
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-quality-gate.md` - Quality gate data source
- `/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md` - Artifact inventory data source
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-execution-workflow.md` - Execution progress tracking
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-closeout-workflow.md` - Closeout reporting
- `/srv/cc/Governance/constitution.md` - Project governance and reporting requirements
</related_documents>

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Enhanced integration convention header, infrastructure philosophy alignment)
**Compliance:** 100% semantic XML structure, comprehensive status reporting, standardized templates
**Next Steps:** Use this utility throughout project lifecycle to generate status reports for stakeholders at appropriate intervals
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
**Report Coverage:** 6 report types with complete templates, 5 generation procedures, integration with all utilities and workflows
**Infrastructure Philosophy:** Appropriately infrastructure-agnostic - reports project status regardless of deployment model (bare metal, Docker dev, manual/automated)
</metadata_footer>
