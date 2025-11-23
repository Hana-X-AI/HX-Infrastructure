---
workflow: util-raidd
version: 1.1
date: 2025-11-20
status: APPROVED
type: utility-command
description: RAIDD log management utility for tracking Risks, Assumptions, Issues, Dependencies, and Decisions across project lifecycle with structured logging, status tracking, and resolution management
applies_to: all_workflows, all_orchestrations, project_management, risk_management, decision_tracking
author: HX-Infrastructure Team
last_updated: 2025-11-20
update_notes: Enhanced integration convention clarity, infrastructure philosophy alignment
---

<metadata>
**Workflow:** RAIDD Log Management Utility - Project Tracking and Risk Management
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Enhanced integration convention header, infrastructure philosophy alignment)
**Status:** APPROVED - Production Ready
**Type:** Utility Command
**Purpose:** Provide systematic tracking of Risks, Assumptions, Issues, Dependencies, and Decisions throughout project lifecycle, enabling proactive risk management, issue resolution, dependency coordination, and decision documentation
</metadata>

<objective>
**Purpose:** Establish centralized RAIDD (Risks, Assumptions, Issues, Dependencies, Decisions) tracking system that captures project challenges, constraints, and decisions systematically, supports resolution management, provides status visibility, and enables retrospective analysis for process improvement.

**Utility Capabilities:**
- Log and track project Risks with mitigation strategies
- Document Assumptions requiring validation or monitoring
- Capture and manage Issues with priority-based resolution tracking
- Map Dependencies with blocking relationship management
- Record Decisions with rationale and alternatives considered
- Generate RAIDD status reports and summaries
- Track resolution progress and closure verification
- Support cross-workflow RAIDD continuity
- Enable retrospective RAIDD analysis for lessons learned
- Provide RAIDD dashboard for stakeholder visibility

**When to Use This Utility:**
- During project charter creation to capture initial RAIDD items
- Throughout specification development when risks/assumptions identified
- During task planning when dependencies and issues surface
- Throughout execution when decisions made or issues encountered
- During project status reviews requiring RAIDD visibility
- When generating project closeout reports with RAIDD summary
- During retrospectives analyzing how RAIDD items were managed
- Anytime a risk, assumption, issue, dependency, or decision needs documentation
</objective>

<utility_overview>
**Core Function:**
This utility provides structured RAIDD log management by capturing entries with standardized metadata (type, severity, status, owner), tracking status transitions (open → in progress → resolved → closed), supporting resolution documentation, and generating reports for project visibility.

**RAIDD Management Process:**
1. **Capture Entry** - Document new RAIDD item with type, description, metadata
2. **Assign Ownership** - Identify responsible party for addressing/monitoring item
3. **Set Priority/Severity** - Determine criticality and urgency
4. **Track Status** - Monitor status transitions through lifecycle
5. **Document Resolution** - Record resolution actions and outcomes
6. **Verify Closure** - Confirm item properly resolved before closing
7. **Generate Reports** - Create RAIDD summaries and dashboards for stakeholders
8. **Analyze Trends** - Identify RAIDD patterns for process improvement

**Key Principle:** RAIDD log is project memory - systematic capture prevents oversight, status tracking enables proactive management, resolution documentation supports learning.
</utility_overview>

<state_management>
**State Management Pattern:**

This utility is **stateless** - the cc-util-raidd.md file contains instructions and templates only.

**State artifacts** are created by following these instructions:
- **RAIDD Log:** `/projects/{project-name}/raidd/log.md` (persistent, primary artifact)
- **RAIDD Reports:** `/projects/{project-name}/raidd/reports/raidd-report-YYYYMMDD.md` (persistent)
- **RAIDD Dashboard:** `/projects/{project-name}/raidd/dashboard.md` (persistent, updated)
- **Resolution History:** `/projects/{project-name}/raidd/resolutions/` (persistent, per item)

These state artifacts are:
- Created during first RAIDD entry
- Updated/appended throughout project lifecycle
- Persistent across sessions
- Project-specific (one RAIDD log per project)

**Distinction:**
- **Utility** = Stateless instructions + templates (this document)
- **Artifacts** = Stateful files created per project (log, reports, dashboard, resolutions)

**RAIDD Log Evolution:**
The RAIDD log grows throughout project:
- Charter phase: Initial risks, assumptions, dependencies identified
- Spec phase: Technical assumptions, architectural decisions documented
- Task phase: Dependencies mapped, issues surfaced
- Execution phase: Issues resolved, decisions made, new risks identified
- Closeout phase: Final RAIDD summary, unresolved items documented

This evolution provides complete project tracking and supports retrospective analysis.
</state_management>

<raidd_entry_types>
**Entry Type Definitions:**

**R - Risk:**
Potential negative event or condition that may impact project success.

**Characteristics:**
- Future-oriented (hasn't happened yet)
- Has probability of occurrence (may or may not happen)
- Has potential impact if occurs
- Requires mitigation strategy to reduce probability or impact
- Should be monitored throughout project

**Risk Severity Levels:**
- **High:** Significant project impact if occurs, mitigation essential
- **Medium:** Moderate impact if occurs, mitigation recommended
- **Low:** Minor impact if occurs, monitoring sufficient

**Risk Status:**
- **Open:** Risk identified, mitigation strategy needed
- **Mitigating:** Mitigation actions in progress
- **Monitoring:** Mitigation in place, ongoing monitoring required
- **Occurred:** Risk materialized, became an Issue
- **Closed:** Risk no longer applicable (conditions changed)

**A - Assumption:**
Statement accepted as true without proof, requiring validation or monitoring.

**Characteristics:**
- Foundation for project decisions or plans
- Not yet validated or proven
- If assumption proves false, project may need adjustment
- Should be validated when possible
- Should be monitored throughout project

**Assumption Confidence Levels:**
- **High:** Strong confidence assumption is true, low validation urgency
- **Medium:** Moderate confidence, validation recommended
- **Low:** Weak confidence, validation essential

**Assumption Status:**
- **Open:** Assumption documented, validation needed
- **Validating:** Validation in progress
- **Validated:** Assumption confirmed as true
- **Invalidated:** Assumption proven false, adjustment needed
- **Monitoring:** Assumption holds but requires ongoing monitoring

**I - Issue:**
Current problem or obstacle blocking or impeding project progress.

**Characteristics:**
- Present-oriented (happening now)
- Has actual impact on project
- Requires resolution actions
- Has priority determining urgency of resolution
- May have dependencies or blockers preventing resolution

**Issue Priority Levels:**
- **P0 (Critical):** Blocks project progress, immediate resolution required
- **P1 (High):** Significant impact, resolution needed soon (within days)
- **P2 (Medium):** Moderate impact, resolution needed (within weeks)
- **P3 (Low):** Minor impact, resolution when convenient

**Issue Status:**
- **Open:** Issue identified, resolution plan needed
- **Investigating:** Root cause analysis in progress
- **In Progress:** Resolution actions underway
- **Resolved:** Resolution implemented, verification pending
- **Closed:** Resolution verified successful, issue closed
- **Deferred:** Issue postponed, will address later
- **Won't Fix:** Issue accepted, no resolution planned

**D - Dependency:**
Relationship where one element requires another element to exist or complete before proceeding.

**Characteristics:**
- Defines ordering constraints (A must complete before B can start)
- May be internal (within project) or external (outside project)
- May be blocking (prevents progress) or non-blocking (preferred but not required)
- Requires coordination between dependent parties
- May have dependency chains (A → B → C)

**Dependency Types:**
- **Technical:** Technology, API, library, or component dependency
- **Resource:** People, equipment, or funding dependency
- **Process:** Approval, review, or milestone dependency
- **External:** Third-party, vendor, or organizational dependency

**Dependency Status:**
- **Open:** Dependency identified, coordination needed
- **Coordinating:** Working with dependency owner
- **Waiting:** Blocked, waiting for dependency fulfillment
- **Fulfilled:** Dependency met, blocking removed
- **Closed:** Dependency no longer applicable

**D - Decision:**
Significant choice made affecting project direction, approach, or implementation.

**Characteristics:**
- Documents what was decided
- Captures why decision made (rationale)
- Records alternatives considered and rejected
- Identifies decision maker(s) and stakeholders consulted
- May be documented as Architecture Decision Record (ADR) for technical decisions

**Decision Impact Levels:**
- **Strategic:** Major project direction or approach
- **Architectural:** System structure, technology choices
- **Tactical:** Implementation approach, tool selection
- **Operational:** Process, procedure, or policy choice

**Decision Status:**
- **Proposed:** Decision proposed, awaiting approval
- **Approved:** Decision approved, implementation pending
- **Implemented:** Decision implemented and active
- **Reversed:** Decision reversed, superseded by new decision
- **Superseded:** Decision replaced by newer decision
</raidd_entry_types>

<raidd_log_structure>
**RAIDD Log Format:**

Each RAIDD log entry follows standardized structure:

```
RAIDD-{TYPE}-{NUMBER}: {One-line Summary}
══════════════════════════════════════════════════════════════════════
Type: [Risk|Assumption|Issue|Dependency|Decision]
ID: RAIDD-{TYPE}-{NUMBER}
Status: [Status appropriate to type]
Priority/Severity: [Priority or Severity level]
Date Opened: YYYY-MM-DD
Owner: [Responsible party]
Related Workflow/Orchestration: [Where identified]

DESCRIPTION:
[Detailed description of the RAIDD item]

[Type-specific sections follow]

HISTORY:
[Date] - [Status] - [Action/Update] - [Who]
...

TAGS: [tag1], [tag2], [tag3]
```

**Type-Specific Sections:**

**Risk Entry:**
```
RISK ASSESSMENT:
Probability: [High|Medium|Low]
Impact if Occurs: [Severity of impact]
Timeframe: [When risk might occur]

MITIGATION STRATEGY:
[Actions to reduce probability or impact]

TRIGGER INDICATORS:
[Signs that risk is materializing]

CONTINGENCY PLAN:
[What to do if risk occurs]
```

**Assumption Entry:**
```
ASSUMPTION RATIONALE:
[Why this assumption made]

VALIDATION APPROACH:
[How to validate assumption]

IMPACT IF INVALID:
[What happens if assumption proves false]

MONITORING CRITERIA:
[How to detect if assumption becoming invalid]
```

**Issue Entry:**
```
IMPACT:
[How issue affects project]

ROOT CAUSE (if known):
[Underlying cause of issue]

RESOLUTION PLAN:
[Actions to resolve issue]

BLOCKERS (if any):
[What prevents resolution]

TARGET RESOLUTION DATE: YYYY-MM-DD
```

**Dependency Entry:**
```
DEPENDENT: [What depends on this]
PREREQUISITE: [What this depends on]

DEPENDENCY TYPE: [Technical|Resource|Process|External]
BLOCKING: [Yes|No]

COORDINATION PLAN:
[How to manage dependency]

FULFILLMENT CRITERIA:
[How to know dependency met]

EXPECTED FULFILLMENT DATE: YYYY-MM-DD
```

**Decision Entry:**
```
DECISION MAKER(S): [Who decided]
STAKEHOLDERS CONSULTED: [Who provided input]

DECISION RATIONALE:
[Why this decision made]

ALTERNATIVES CONSIDERED:
1. [Alternative 1] - [Why rejected]
2. [Alternative 2] - [Why rejected]
...

IMPLICATIONS:
[Consequences of this decision]

REVERSIBILITY:
[Can decision be reversed? How easily?]
```

**File Organization:**
```
/projects/{project-name}/
  raidd/
    log.md                                    ← Master RAIDD log
    dashboard.md                              ← Current RAIDD status dashboard
    reports/
      raidd-report-20251120.md               ← Periodic reports
      raidd-report-20251201.md
      ...
    resolutions/
      RAIDD-ISSUE-001-resolution.md          ← Detailed resolution docs
      RAIDD-RISK-003-mitigation.md
      ...
```
</raidd_log_structure>

<management_procedures>
  <procedure name="Log New RAIDD Entry">
  **Purpose:** Capture new RAIDD item systematically
  
  **Entry Process:**
  
  1. **Determine Entry Type**
     - Is this a future risk or current issue?
     - Is this an unvalidated assumption?
     - Is this a dependency relationship?
     - Is this a significant decision?
  
  2. **Assign Entry ID**
     - Format: RAIDD-{TYPE}-{NUMBER}
     - Types: RISK, ASSUMPTION, ISSUE, DEPENDENCY, DECISION
     - Number: Sequential within type (RISK-001, RISK-002, etc.)
  
  3. **Complete Entry Metadata**
     - One-line summary (clear, concise)
     - Status (initial status for type)
     - Priority/Severity (based on type guidelines)
     - Date opened (current date)
     - Owner (responsible party)
     - Related workflow/orchestration (context)
  
  4. **Write Detailed Description**
     - What is the RAIDD item?
     - Why is it significant?
     - What is the context?
     - Include sufficient detail for understanding
  
  5. **Complete Type-Specific Sections**
     - Risk: Assessment, mitigation, triggers, contingency
     - Assumption: Rationale, validation, impact, monitoring
     - Issue: Impact, root cause, resolution plan, blockers
     - Dependency: Dependent/prerequisite, type, coordination
     - Decision: Decision maker, rationale, alternatives, implications
  
  6. **Add Initial History Entry**
     - Date opened
     - Initial status
     - "Entry created"
     - Who created
  
  7. **Apply Tags**
     - Domain tags (security, architecture, infrastructure, testing)
     - Phase tags (charter, spec, task, execution, closeout)
     - Custom tags as needed
  
  8. **Append to RAIDD Log**
     - Add entry to `/projects/{project-name}/raidd/log.md`
     - Maintain chronological order within type sections
     - Update RAIDD dashboard with new item
  
  **Outputs:**
  - RAIDD entry in log
  - Updated dashboard showing new item
  - Notification to owner (if applicable)
  </procedure>

  <procedure name="Update RAIDD Entry Status">
  **Purpose:** Track status transitions and progress on RAIDD items
  
  **Update Process:**
  
  1. **Locate RAIDD Entry**
     - Find entry by ID in RAIDD log
     - Verify current status
  
  2. **Determine New Status**
     - Based on entry type, identify valid status transitions
     - Ensure status transition is logical (Open → In Progress, not Open → Closed)
  
  3. **Document Status Change**
     - Update Status field in entry header
     - Add history entry with date, new status, reason, who
  
  4. **Update Status-Specific Information**
     - For risks moving to Mitigating: document mitigation actions underway
     - For issues moving to In Progress: update resolution plan progress
     - For assumptions moving to Validated: document validation evidence
     - For dependencies moving to Fulfilled: confirm fulfillment
     - For decisions moving to Implemented: document implementation
  
  5. **Update Related Entries**
     - If status change affects other RAIDD items, update them
     - Example: Dependency fulfilled may unblock issues
     - Example: Risk occurred becomes new issue
  
  6. **Update RAIDD Dashboard**
     - Reflect new status in dashboard
     - Update status counts and metrics
  
  7. **Notify Stakeholders**
     - Inform affected parties of status change
     - Escalate if needed (e.g., P0 issue not progressing)
  
  **Outputs:**
  - Updated RAIDD entry with new status
  - History entry documenting change
  - Updated dashboard
  - Stakeholder notifications (if applicable)
  </procedure>

  <procedure name="Resolve and Close RAIDD Items">
  **Purpose:** Properly resolve RAIDD items and verify closure
  
  **Resolution Process:**
  
  1. **Document Resolution**
     - For Risks: Document mitigation completion or risk no longer applicable
     - For Assumptions: Document validation results or monitoring conclusion
     - For Issues: Document resolution actions and outcomes
     - For Dependencies: Document fulfillment confirmation
     - For Decisions: Document implementation completion
  
  2. **Create Resolution Documentation**
     - Detailed resolution document in `/projects/{project-name}/raidd/resolutions/`
     - Include resolution approach, actions taken, results, verification
     - Link resolution doc from RAIDD entry
  
  3. **Update Status to Resolved**
     - Change status to "Resolved" (or type-specific equivalent)
     - Add history entry documenting resolution
     - Include resolution date and who resolved
  
  4. **Verify Resolution**
     - Confirm resolution addresses original RAIDD item
     - Verify no unintended side effects
     - Get stakeholder confirmation if needed
  
  5. **Close Entry**
     - Change status to "Closed" after verification
     - Add final history entry
     - Mark closure date
  
  6. **Update RAIDD Dashboard**
     - Move item to closed section
     - Update status counts
     - Update metrics (resolution time, etc.)
  
  7. **Extract Lessons Learned**
     - What worked well in resolution?
     - What could be improved?
     - Are there patterns to prevent similar items?
  
  **Special Cases:**
  - **Won't Fix Issues:** Document decision not to resolve and rationale
  - **Deferred Issues:** Document why deferred and revisit date
  - **Invalidated Assumptions:** Document impact and adjustments made
  - **Reversed Decisions:** Document why reversed and new decision
  
  **Outputs:**
  - Closed RAIDD entry
  - Resolution documentation
  - Updated dashboard
  - Lessons learned notes
  </procedure>

  <procedure name="Generate RAIDD Reports">
  **Purpose:** Create RAIDD status reports for stakeholders
  
  **Report Types:**
  
  **1. RAIDD Summary Report:**
  - Count of RAIDD items by type and status
  - High-priority/severity items requiring attention
  - Recent status changes
  - Items blocked or overdue
  - Trends since last report
  
  **2. Risk Report:**
  - All open risks by severity
  - Risk mitigation status
  - Risks approaching trigger indicators
  - New risks since last report
  
  **3. Issue Report:**
  - All open issues by priority
  - Issue resolution progress
  - Blocked issues requiring escalation
  - Issue aging analysis (time open)
  
  **4. Dependency Report:**
  - All active dependencies
  - Blocking dependencies
  - Dependencies waiting fulfillment
  - External dependencies requiring coordination
  
  **5. Decision Log:**
  - Recent decisions made
  - Decisions awaiting approval
  - Decision implementation status
  - Significant decisions for stakeholder awareness
  
  **Report Generation Process:**
  
  1. **Query RAIDD Log**
     - Extract entries matching report criteria
     - Group by type, status, priority
     - Calculate metrics
  
  2. **Format Report**
     - Use consistent report template
     - Include executive summary
     - Provide detailed sections by type
     - Highlight items requiring attention
  
  3. **Add Context**
     - Explain significant changes
     - Identify trends
     - Provide recommendations
  
  4. **Save Report**
     - Store in `/projects/{project-name}/raidd/reports/`
     - Use datestamp in filename
     - Update dashboard with report link
  
  5. **Distribute Report**
     - Share with stakeholders
     - Schedule regular reporting cadence
  
  **Outputs:**
  - Formatted RAIDD report
  - Dashboard update
  - Stakeholder distribution
  </procedure>

  <procedure name="Maintain RAIDD Dashboard">
  **Purpose:** Provide real-time RAIDD status visibility
  
  **Dashboard Contents:**
  
  1. **Summary Metrics**
     - Total RAIDD items: X
     - Open items: Y (by type)
     - Closed items: Z
     - Items requiring attention: A
  
  2. **Status Overview**
     - Risks: X open (High: Y, Medium: Z, Low: A)
     - Assumptions: B open (validation status)
     - Issues: C open (P0: D, P1: E, P2: F, P3: G)
     - Dependencies: H open (blocking: I)
     - Decisions: J pending approval
  
  3. **Items Requiring Attention**
     - P0 issues open > 3 days
     - High risks without mitigation plans
     - Blocked dependencies
     - Overdue resolution dates
  
  4. **Recent Activity**
     - Last 5 RAIDD entries created
     - Last 5 RAIDD items closed
     - Recent status changes
  
  5. **Trends**
     - RAIDD items opened vs. closed (last 30 days)
     - Average resolution time by type
     - Most common RAIDD types
  
  **Dashboard Update Process:**
  
  1. **Query Current RAIDD Log**
     - Extract all open items
     - Calculate metrics
     - Identify attention items
  
  2. **Update Dashboard File**
     - Refresh all sections
     - Update timestamp
     - Maintain dashboard at `/projects/{project-name}/raidd/dashboard.md`
  
  3. **Dashboard Cadence**
     - Update after each RAIDD log change
     - Minimum: Daily updates
     - Real-time for critical items
  
  **Outputs:**
  - Current RAIDD dashboard
  - Status visibility for all stakeholders
  </procedure>
</management_procedures>

<integration_with_workflows>
**Workflow Integration Points:**

RAIDD tracking integrates throughout project lifecycle:

**Charter Workflow:**
- Phase 1 (Questions): Capture initial assumptions about project
- Phase 2 (Draft): Document risks identified, key decisions on charter approach
- Phase 3 (Review): Log issues raised by stakeholders, dependencies on other initiatives
- Phase 4 (Approval): Record charter approval decision with rationale

**Spec Workflow:**
- Phase 1 (Context): Document assumptions underlying requirements
- Phase 2 (Team Formation & Draft): Log technical decisions, identify technical dependencies
- Phase 3 (Review): Capture issues found during review, document resolution
- Phase 4 (Approval): Record spec approval decision

**Task Workflow:**
- Phase 1 (Breakdown): Map dependencies between tasks, identify risks in task estimates
- Phase 2 (Estimation): Document assumptions in effort estimates
- Phase 3 (Team Assignment & Approval): Log resource dependencies, approval decision

**Execution Workflow:**
- Phase 1 (Readiness): Verify dependency fulfillment, document blocking issues
- Phase 2 (Work): Track issues encountered during work, log implementation decisions
- Phase 3 (Validation): Document validation issues, testing assumptions
- Phase 4 (Integration & Promotion): Log deployment decisions, integration issues

**Closeout Workflow:**
- Phase 1 (Verification): Verify all RAIDD items resolved or documented
- Phase 2 (Documentation): Include RAIDD summary in project documentation
- Phase 3 (Learning): Extract lessons from RAIDD management
- Phase 4 (Formal Closeout): Final RAIDD status in closeout report

**Orchestration Integration:**
RAIDD tracking also integrates with Set 2 orchestrations:
- Log assumptions made during orchestration
- Track dependencies on specialist outputs
- Document decisions from specialist coordination
- Capture issues encountered during orchestration
- Assess risks in multi-agent coordination
</integration_with_workflows>

<integration_convention>
**How Commands Invoke This Utility:**

This section documents how workflow commands (Set 1) and orchestration commands (Set 2) invoke the RAIDD utility. Invocation uses instructional reference pattern specifying entry type, description, and metadata.

**From Workflow Commands (Set 1):**
Throughout workflow phases, commands invoke RAIDD utility with instructional reference:

**Example from cc-charter-workflow.md Phase 1:**
"Use cc-util-raidd to log initial project assumptions. Document assumptions
about project scope, stakeholder availability, resource access, and
technical capabilities. Create RAIDD entries:
- RAIDD-ASSUMPTION-001: Stakeholder availability for weekly reviews
- RAIDD-ASSUMPTION-002: Access to production environment for testing
- RAIDD-DEPENDENCY-001: Approval from security team required before deployment

Log entries at /projects/auth-system/raidd/log.md"

**Example from cc-execution-workflow.md Phase 2:**
"Use cc-util-raidd to log issue blocking deployment. Create entry:
- RAIDD-ISSUE-003: Database migration fails in staging environment
- Priority: P0 (blocking deployment)
- Owner: William Chen
- Resolution plan: Investigate migration script, coordinate with DBA

Update RAIDD dashboard to show blocking issue."

**Example from cc-closeout-workflow.md Phase 3:**
"Use cc-util-raidd to generate final RAIDD summary for project documentation.
Include: Total RAIDD items (by type), resolution statistics, significant
decisions made, unresolved items with disposition, lessons learned from
RAIDD management."

**From Orchestration Commands (Set 2):**
Orchestrations invoke RAIDD utility to track coordination activities:

**Example from cc-orchestrate-alex.md Phase 4:**
"Use cc-util-raidd to log architectural decision. Create entry:
- RAIDD-DECISION-002: Select OAuth 2.0 for authentication
- Decision maker: Alex Rivera
- Rationale: Industry standard, library support, security best practices
- Alternatives: SAML (complex), custom JWT (reinventing wheel)
- Implications: Requires OAuth provider configuration

Document decision at /projects/auth-system/raidd/log.md"

**Required Inputs:**
1. **Entry Type** - Risk, Assumption, Issue, Dependency, or Decision
2. **Description** - Clear summary and detailed description
3. **Priority/Severity** - Appropriate level for entry type
4. **Owner** - Responsible party for addressing/monitoring
5. **Type-Specific Details** - Mitigation strategy, validation approach, resolution plan, etc.
6. **Context** - Related workflow/orchestration, phase, triggering event
7. **Project Name** - For file organization and RAIDD log location
8. **Tags** - Domain, phase, custom tags for filtering

**Expected Outputs:**

1. **RAIDD Log Entry** (Primary Output)
   - Format: Structured markdown with standardized sections
   - Location: `/projects/{project-name}/raidd/log.md` (appended)
   - Contents: Full RAIDD entry with metadata, description, type-specific sections, history

2. **Updated RAIDD Dashboard** (Status Artifact)
   - Format: Real-time dashboard with metrics and status overview
   - Location: `/projects/{project-name}/raidd/dashboard.md` (updated)
   - Contents: Summary metrics, status overview, items requiring attention, recent activity

3. **RAIDD Report** (Periodic Output)
   - Format: Formatted status report for stakeholders
   - Location: `/projects/{project-name}/raidd/reports/raidd-report-YYYYMMDD.md`
   - Contents: Summary by type, high-priority items, trends, recommendations

4. **Resolution Documentation** (Per-Item Artifact)
   - Format: Detailed resolution or mitigation documentation
   - Location: `/projects/{project-name}/raidd/resolutions/RAIDD-{TYPE}-{NUMBER}-resolution.md`
   - Contents: Resolution approach, actions, results, verification, lessons learned

**State Management:**

**Stateless Component:**
- cc-util-raidd.md utility file (this document)
- Instructions for RAIDD management procedures
- Entry type definitions and templates
- No state maintained in utility itself

**Stateful Artifacts:**
- RAIDD log: `/projects/{project-name}/raidd/log.md` (master log, appended throughout project)
- Dashboard: `/projects/{project-name}/raidd/dashboard.md` (current status, updated regularly)
- Reports: `/projects/{project-name}/raidd/reports/` (periodic snapshots)
- Resolutions: `/projects/{project-name}/raidd/resolutions/` (detailed resolution docs)
- Created/updated by following utility procedures
- Persistent across sessions
- Project-specific

**File Organization:**
```
/projects/{project-name}/
  raidd/
    log.md                                ← Master RAIDD log (append-only)
    dashboard.md                          ← Current RAIDD dashboard (updated)
    reports/
      raidd-report-20251120.md           ← Periodic reports
      raidd-report-20251201.md
      raidd-summary-closeout.md          ← Final summary for closeout
    resolutions/
      RAIDD-ISSUE-001-resolution.md      ← Resolution details
      RAIDD-RISK-003-mitigation.md       ← Mitigation details
      RAIDD-DECISION-005-implementation.md
```

**Invocation Pattern Summary:**
1. Caller identifies RAIDD item needing documentation (risk, assumption, issue, dependency, decision)
2. Caller references cc-util-raidd with entry type, description, metadata
3. RAIDD entry created/updated in project log
4. Dashboard updated to reflect new/changed item
5. Report generated when requested (periodic or on-demand)
6. Resolution documented when item closed
7. RAIDD visibility maintained throughout project lifecycle
</integration_convention>

<usage_examples>
  <example name="Log New Risk">
  **Scenario:** Identifying risk during specification phase
  
  **Command:**
  ```
  Log RAIDD risk:
  - Project: auth-system
  - Summary: Third-party OAuth provider outage risk
  - Severity: High
  - Description: Reliance on external OAuth provider creates availability risk
  - Owner: Frank Lucas
  ```
  
  **Utility Process:**
  1. Create RAIDD-RISK-001 entry
  2. Document risk assessment (high probability during provider maintenance)
  3. Define mitigation strategy (fallback authentication, provider SLA review)
  4. Set trigger indicators (provider status page changes, uptime alerts)
  5. Add to RAIDD log
  6. Update dashboard showing new high-severity risk
  
  **Output:**
  ```
  RAIDD-RISK-001: Third-party OAuth provider outage risk
  Type: Risk
  Status: Open
  Severity: High
  Owner: Frank Lucas
  
  RISK ASSESSMENT:
  Probability: Medium (provider has 99.9% SLA but maintenance windows exist)
  Impact: High (authentication unavailable during outage)
  Timeframe: Ongoing throughout project lifecycle
  
  MITIGATION STRATEGY:
  1. Review provider SLA and maintenance schedule
  2. Implement cached authentication tokens (4-hour TTL)
  3. Design fallback authentication mechanism for emergencies
  4. Set up provider status monitoring and alerts
  
  TRIGGER INDICATORS:
  - Provider status page shows "Degraded" or "Outage"
  - Authentication failure rate > 1%
  - Provider announces scheduled maintenance
  ```
  </example>

  <example name="Track Issue Resolution">
  **Scenario:** Managing P0 issue during execution
  
  **Command:**
  ```
  Log RAIDD issue:
  - Project: auth-system
  - Summary: Database migration fails in staging
  - Priority: P0
  - Owner: William Chen
  ```
  
  **Utility Process:**
  1. Create RAIDD-ISSUE-001 entry with P0 priority
  2. Document impact (blocks deployment)
  3. Update status: Open → Investigating → In Progress → Resolved → Closed
  4. Track resolution actions
  5. Verify resolution before closing
  6. Generate resolution documentation
  
  **Output (Final Closed State):**
  ```
  RAIDD-ISSUE-001: Database migration fails in staging
  Type: Issue
  Status: Closed
  Priority: P0 (Critical)
  Owner: William Chen
  Date Opened: 2025-11-20
  Date Closed: 2025-11-21
  
  IMPACT:
  Blocking deployment to staging environment, preventing validation phase
  
  ROOT CAUSE:
  Migration script used PostgreSQL-specific syntax incompatible with 
  staging database version (PostgreSQL 14 vs production PostgreSQL 16)
  
  RESOLUTION PLAN:
  1. Rewrite migration script with version-agnostic SQL
  2. Test against both PostgreSQL 14 and 16
  3. Update migration documentation with compatibility requirements
  4. Re-run migration in staging
  
  HISTORY:
  2025-11-20 09:00 - Open - Issue identified during deployment attempt - William
  2025-11-20 10:30 - Investigating - Root cause analysis started - William
  2025-11-20 14:00 - In Progress - Rewriting migration script - William
  2025-11-21 09:00 - Resolved - Migration successful in staging - William
  2025-11-21 10:00 - Closed - Verified by validation team - Julia
  
  RESOLUTION TIME: 25 hours (within P0 target of 48 hours)
  ```
  </example>

  <example name="Document Decision">
  **Scenario:** Recording architectural decision from Alex orchestration
  
  **Command:**
  ```
  Log RAIDD decision:
  - Project: auth-system
  - Summary: Select OAuth 2.0 for authentication
  - Decision Maker: Alex Rivera
  - Impact: Strategic
  ```
  
  **Utility Process:**
  1. Create RAIDD-DECISION-001 entry
  2. Document decision maker and stakeholders
  3. Record rationale and alternatives
  4. Identify implications and reversibility
  5. Add to RAIDD log and dashboard
  
  **Output:**
  ```
  RAIDD-DECISION-001: Select OAuth 2.0 for authentication
  Type: Decision
  Status: Approved
  Impact: Strategic
  Date: 2025-11-20
  Decision Maker: Alex Rivera (Platform Architect)
  Stakeholders Consulted: Frank Lucas (Security), William Chen (Infrastructure)
  
  DECISION RATIONALE:
  OAuth 2.0 provides industry-standard authentication with:
  - Proven security model with extensive auditing
  - Broad library and framework support
  - Separation of authentication and authorization concerns
  - Third-party integration capabilities (SSO, social login)
  - Active Directory integration via OAuth providers
  
  ALTERNATIVES CONSIDERED:
  1. SAML 2.0
     Rejected: Excessive complexity for requirements, limited modern tooling
  
  2. Custom JWT-based authentication
     Rejected: Reinventing wheel, security risks from custom implementation
  
  3. Session-based authentication
     Rejected: Doesn't support distributed architecture, API authentication limited
  
  IMPLICATIONS:
  - Requires OAuth 2.0 provider setup and configuration
  - Token management and refresh logic required in application
  - Third-party provider dependency (see RAIDD-RISK-001)
  - Enables future OAuth flows (authorization code, client credentials)
  
  REVERSIBILITY:
  Difficult - OAuth 2.0 will be deeply integrated into authentication layer.
  Reversal would require significant rework. Recommend thorough validation
  before implementation.
  ```
  </example>

  <example name="Generate RAIDD Report">
  **Scenario:** Creating weekly RAIDD status report
  
  **Command:**
  ```
  Generate RAIDD report:
  - Project: auth-system
  - Report Type: Summary
  - Date: 2025-11-20
  ```
  
  **Utility Process:**
  1. Query RAIDD log for all items
  2. Calculate metrics by type and status
  3. Identify high-priority items
  4. Format report with executive summary
  5. Save to reports directory
  
  **Output:**
  ```
  RAIDD STATUS REPORT - AUTH-SYSTEM PROJECT
  ══════════════════════════════════════════════════════════════════════
  Report Date: 2025-11-20
  Reporting Period: Week of 2025-11-18
  Project Phase: Specification Development
  
  EXECUTIVE SUMMARY:
  Project RAIDD items under control with 1 high-severity risk and 1 P0 
  issue resolved. Key architectural decision approved. No blocking items.
  
  SUMMARY METRICS:
  Total RAIDD Items: 12
  Open Items: 8 (67%)
  Closed Items: 4 (33%)
  Items Requiring Attention: 1 (high-severity risk)
  
  BY TYPE:
  Risks: 3 (Open: 2, Closed: 1)
    - High Severity: 1 (RAIDD-RISK-001)
    - Medium Severity: 1
    - Low Severity: 1
  
  Assumptions: 4 (Open: 3, Validated: 1)
    - High Confidence: 2
    - Medium Confidence: 2
  
  Issues: 2 (Open: 0, Closed: 2)
    - P0: 0 (RAIDD-ISSUE-001 resolved this week)
    - P1: 0
  
  Dependencies: 2 (Open: 2, Fulfilled: 0)
    - Blocking: 1 (security approval required)
    - Non-blocking: 1
  
  Decisions: 1 (Approved: 1)
    - Strategic: 1 (OAuth 2.0 selection)
  
  ITEMS REQUIRING ATTENTION:
  ⚠️ RAIDD-RISK-001 (High): Third-party OAuth provider outage risk
     Status: Mitigation strategy defined, implementation pending
     Next Steps: Implement cached authentication and fallback mechanism
  
  RECENT ACTIVITY:
  ✅ RAIDD-ISSUE-001 closed: Database migration issue resolved in 25 hours
  ✅ RAIDD-DECISION-001 approved: OAuth 2.0 selected for authentication
  🆕 RAIDD-DEPENDENCY-002 opened: Waiting for security team approval
  
  TRENDS:
  - Issue resolution time improving (P0 within 48h target)
  - Risk identification proactive (2 new risks logged during spec review)
  - Decision documentation thorough (alternatives considered)
  
  RECOMMENDATIONS:
  1. Prioritize RAIDD-RISK-001 mitigation implementation
  2. Follow up on RAIDD-DEPENDENCY-002 with security team
  3. Continue proactive risk identification in upcoming phases
  ```
  </example>
</usage_examples>

<critical_reminders>
1. ⚠️ **Capture Early:** Log RAIDD items as soon as identified. Delayed capture leads to forgotten issues and unmanaged risks.

2. ⚠️ **Be Specific:** Vague RAIDD entries ("Something might go wrong") are useless. Provide specific descriptions, impacts, and actions.

3. ⚠️ **Assign Ownership:** Every RAIDD item needs an owner responsible for monitoring or resolution. Unowned items languish.

4. ⚠️ **Track Status Actively:** RAIDD items with outdated status lose credibility. Update status regularly to reflect reality.

5. ⚠️ **Prioritize Correctly:** P0 issues require immediate attention. Don't over-prioritize everything or nothing gets urgency.

6. ⚠️ **Document Resolutions:** Resolution documentation prevents repeating mistakes and provides lessons learned.

7. ⚠️ **Dependencies Block Progress:** Actively manage dependencies, especially blocking ones. Coordinate with dependency owners.

8. ⚠️ **Decisions Need Rationale:** Future teams need to understand why decisions made. Document alternatives considered and trade-offs.

9. ⚠️ **Validate Assumptions:** Unvalidated assumptions become hidden risks. Validate when possible, monitor always.

10. ⚠️ **RAIDD Dashboard Visibility:** Dashboard must be current and accessible. Stale dashboards lead stakeholders to ignore them.

11. ⚠️ **Close Items Properly:** Don't close items prematurely. Verify resolution before closing. Don't leave "zombie" items open forever.

12. ⚠️ **Extract Learning:** RAIDD log is goldmine for retrospectives. Analyze patterns to improve processes.
</critical_reminders>

<validation_checklist>
**New RAIDD Entry Checklist:**
- [ ] Entry type correctly determined (Risk/Assumption/Issue/Dependency/Decision)
- [ ] Unique ID assigned (RAIDD-{TYPE}-{NUMBER})
- [ ] One-line summary clear and concise
- [ ] Detailed description provides sufficient context
- [ ] Priority/severity assigned appropriately
- [ ] Owner identified and responsible party notified
- [ ] Initial status set correctly for entry type
- [ ] Type-specific sections completed (mitigation, validation, resolution, etc.)
- [ ] Initial history entry added
- [ ] Tags applied for filtering and organization
- [ ] Entry appended to RAIDD log
- [ ] Dashboard updated with new item

**Status Update Checklist:**
- [ ] Current status verified before update
- [ ] New status is valid transition for entry type
- [ ] History entry added documenting status change
- [ ] Status-specific information updated
- [ ] Related RAIDD items checked for impact
- [ ] Dashboard updated to reflect status change
- [ ] Stakeholders notified if needed
- [ ] Escalation triggered if item overdue or blocked

**Resolution/Closure Checklist:**
- [ ] Resolution actions completed and documented
- [ ] Resolution documentation created in resolutions directory
- [ ] Resolution addresses original RAIDD item
- [ ] No unintended side effects from resolution
- [ ] Stakeholder confirmation obtained (if required)
- [ ] Status changed to Resolved then Closed after verification
- [ ] Final history entry added with closure date
- [ ] Dashboard updated showing closed item
- [ ] Lessons learned extracted and documented

**RAIDD Report Checklist:**
- [ ] Report period clearly specified
- [ ] All RAIDD items included in appropriate sections
- [ ] Metrics calculated accurately (counts, percentages, trends)
- [ ] High-priority/severity items highlighted
- [ ] Recent activity summarized
- [ ] Trends identified and explained
- [ ] Recommendations provided based on RAIDD analysis
- [ ] Report saved to reports directory with datestamp
- [ ] Dashboard updated with report link
- [ ] Report distributed to stakeholders
</validation_checklist>

<related_documents>
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-charter-workflow.md` - Charter RAIDD integration
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-spec-workflow.md` - Spec RAIDD integration
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-task-workflow.md` - Task RAIDD integration
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-execution-workflow.md` - Execution RAIDD integration
- `/home/agent0/HX-Infrastructure/.claude/commands/core/cc-closeout-workflow.md` - Closeout RAIDD summary
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-alex.md` - Alex orchestration RAIDD usage
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-frank.md` - Frank orchestration RAIDD usage
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-william.md` - William orchestration RAIDD usage
- `/home/agent0/HX-Infrastructure/.claude/commands/agents/cc-orchestrate-julia.md` - Julia orchestration RAIDD usage
- `/srv/cc/Governance/constitution.md` - Project governance principles
- `/home/agent0/HX-Infrastructure/standards/documentation-requirements.md` - Documentation standards
</related_documents>

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Enhanced integration convention header, infrastructure philosophy alignment)
**Compliance:** 100% semantic XML structure, comprehensive RAIDD tracking, standardized procedures
**Next Steps:** Use this utility throughout project lifecycle to capture Risks, Assumptions, Issues, Dependencies, and Decisions systematically
**Semantic XML Compliance:** All sections use semantic XML tags, critical reminders with ⚠️ markers, comprehensive validation checklists
**Integration:** Full calling convention with input/output specifications and state management patterns documented
**RAIDD Coverage:** Complete entry type definitions (5 types), management procedures (5 procedures), integration with all workflows and orchestrations
**Infrastructure Philosophy:** Appropriately infrastructure-agnostic - tracks risks, issues, decisions across all deployment models (bare metal, manual procedures, systemd services)
</metadata_footer>
