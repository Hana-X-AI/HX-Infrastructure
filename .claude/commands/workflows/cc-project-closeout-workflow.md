---
document: cc-project-closeout-workflow
version: 1.1
date: 2025-11-24
status: APPROVED
type: workflow-command
description: Systematic project closure with centralized artifact updates, knowledge capture, and formal handoff to operations
applies_to: all_completed_projects
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-project-closeout-workflow.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
prerequisites:
  - operational_status_achieved
  - stability_period_complete
  - caio_operational_approval
  - monitoring_configured
estimated_duration: 8-12 hours over 3-5 days
output_artifacts:
  - updated_centralized_artifacts
  - lessons_learned_document
  - final_status_report
  - project_archive
---

<metadata>
**Workflow:** Project Closeout
**Version:** 1.0
**Date Created:** 2025-11-17
**Status:** APPROVED - Production Workflow
**Type:** Workflow Command
**Purpose:** Systematic Closure with Centralized Artifact Updates and Knowledge Capture
**Trigger:** Node/service operational and stable
**Input:** Operational node/service, execution completion report, all project artifacts
**Output:** Project formally closed, all centralized artifacts updated, lessons learned captured, final report complete
</metadata>

<objective>
**Purpose:** Define systematic workflow for formal project closure with comprehensive documentation updates and knowledge transfer.

**What This Achieves:**
- Formally closes completed project with CAIO approval
- Updates all centralized artifacts (RAIDD, Defect Log, Backlog) with project outcomes
- Captures lessons learned for organizational knowledge base
- Transfers operational responsibility to operations team with complete documentation
- Creates final project report documenting complete story

**Key Innovation:** Centralized artifact updates (ONE RAIDD log, ONE defect log, ONE backlog for entire project - not per-node copies). Knowledge capture ensures organizational learning from every project.

**Critical Success Factor:** Formal closure with CAIO approval required. Cannot skip closeout even if service is operational. Proper closeout enables continuous organizational improvement.
</objective>

<workflow_overview>
**High-Level Flow:**
```
Pre-Closeout Check → RAIDD Update → Defect Log Update → Backlog Update →
Lessons Learned → Final Report → Archive → CAIO Approval → Operational Handoff
```

**Duration:** 8-12 hours spread over 3-5 days (allows for stability period observation)

**Key Participants:**
- **Agent Zero:** Closeout coordinator, artifact updater, report creator
- **CAIO:** Project closure approver
- **Operations Team:** Receives handoff with runbooks and documentation
</workflow_overview>

<key_principles>
1. **Centralized Updates:** Update ONE centralized RAIDD, Defect Log, Backlog (not per-project copies)
2. **Knowledge Capture:** Document what was learned for future projects
3. **Comprehensive Documentation:** Final report tells complete project story
4. **Operational Readiness:** Ensure operations team has everything needed
5. **Formal Closure:** CAIO approval required for project closure
6. **Critical Difference:** Execution deploys and documents results; Closeout finalizes documentation, captures knowledge, formal closure
</key_principles>

<phases>
<phase id="0" name="Pre-Closeout Readiness Check" gate="closeout-ready">
<description>
Agent Zero validates service/node is stable and ready for formal project closure. Stability period ensures operational readiness before closing project.
</description>

<inputs>
- `/nodes/[node-name]/STATUS.md` (Status: OPERATIONAL)
- `/nodes/[node-name]/execution-completion-report.md` (Complete)
- `/nodes/[node-name]/caio-operational-approval.md` (Approved)
- `/nodes/[node-name]/tests/test-execution-summary.md` (Tests passed)
- Monitoring dashboards (if applicable) showing healthy status
- Stability period observation (no critical incidents)
</inputs>

<actions>
**Agent Zero validates:**

1. **Execution Status Validation**
   - Execution status: COMPLETE
   - Operational status: Service/node operational and stable
   - Test status: All critical tests passing
   - Defect status: No P0 defects, P1 defects mitigated
   - CAIO approval: Operational promotion approved

2. **Stability Period Validation**
   Verify service stable for recommended period:
   - No critical incidents
   - No service outages
   - Performance within acceptable ranges
   - Resource utilization stable
   - No emergency interventions required
   - Operations team comfortable with service

   **Recommended stability periods:**
   - Simple service: 3 days
   - Standard service: 5 days
   - Complex/critical service: 7 days
   - High-risk deployment: 14 days

3. **Operational Readiness Validation**
   - Monitoring configured and alerting
   - Operations team trained (if needed)
   - Runbook complete (if needed)
   - All defects triaged (P0/P1 resolved or mitigated)
   - Execution documentation complete
   - Ready to update centralized artifacts

**Closeout Readiness Checklist:**
- [ ] Service/node operational for [X] days
- [ ] No critical incidents during stability period
- [ ] All tests passing consistently
- [ ] Monitoring configured and alerting
- [ ] Operations team trained (if needed)
- [ ] Runbook complete (if needed)
- [ ] All defects triaged (P0/P1 resolved or mitigated)
- [ ] Execution documentation complete
- [ ] Ready to update centralized artifacts

**Quality Checks:**
- Stability period observed
- Service healthy and stable
- Operational readiness confirmed
- Team comfortable with service
</actions>

<outputs>
- Stability period confirmed
- Service validated as operational
- Closeout readiness confirmed

**Gate Decision:**
- ✅ **PASS:** All prerequisites met, stable for required period → Proceed to Phase 1
- ❌ **FAIL:** Not ready for closeout → Wait for stability or resolve issues

**Status Update:**
- Project ready for formal closeout
- Can begin artifact updates
</outputs>

<duration>1-2 hours (validation) + stability period observation (days)</duration>
</phase>

<phase id="1" name="RAIDD Log Final Update" gate="none">
<description>
Update centralized RAIDD log with final project outcomes. Review all RAIDD entries (Risks, Assumptions, Issues, Dependencies, Decisions) and document actual outcomes vs. original assessment.

**CRITICAL:** This is the ONE centralized RAIDD log for entire project at `/home/agent0/HX-Infrastructure/docs/raidd-log.md`. Do NOT create node-specific RAIDD logs.
</description>

<inputs>
- All RAIDD entries from project phases (charter, spec, task, execution)
- Project execution outcomes
- Final project status
</inputs>

<actions>
**Agent Zero performs:**

1. **Review All RAIDD Entries for Project**
   - Entries created during charter phase
   - Entries created during spec phase
   - Entries created during task phase
   - Entries created during execution phase
   - Identify all entries related to [node-name]

2. **Update RISKS with Actual Outcomes**
   For each risk identified:
   - Did risk materialize? (Yes/No)
   - If yes: How was it handled? Impact on project (time, cost, quality)
   - If no: Why not? (was mitigation effective?)
   - Lessons learned about risk management

3. **Update ASSUMPTIONS with Validation**
   For each assumption:
   - Was assumption correct? (Yes/No/Partial)
   - If incorrect: What was actual reality? Impact of incorrect assumption
   - How to validate this in future projects

4. **Update ISSUES with Resolution**
   For each issue:
   - Resolution status (Resolved/Mitigated/Accepted)
   - How issue was resolved
   - Time to resolution
   - Impact on project
   - Prevention strategy for future

5. **Update DEPENDENCIES with Actual Status**
   For each dependency:
   - Was dependency met? (Yes/No/Partial)
   - Any delays or issues with dependency?
   - Impact on project timeline
   - Recommendations for managing this dependency

6. **Update DECISIONS with Outcomes**
   For each decision:
   - Was decision correct? (Yes/No/Revisit)
   - Actual impact of decision
   - Would we make same decision again?
   - Lessons learned from decision

7. **Create Project Summary**
   - Total RAIDD entries for project
   - RAIDD management effectiveness assessment
   - Key takeaways

**Quality Checks:**
- All RAIDD entries reviewed
- All outcomes documented
- Lessons learned captured
- Summary complete
</actions>

<outputs>
- RAIDD log updated with complete project outcomes
- All entries closed with actual results
- Project RAIDD summary created
- Organizational learning captured

**Status Update:**
- RAIDD log current for this project
- Ready for defect log update
</outputs>

<duration>1-2 hours</duration>
</phase>

<phase id="2" name="Defect Log Final Update" gate="none">
<description>
Update centralized defect log with final defect statuses. Close resolved defects, document mitigated defects, and ensure no P0 defects remain open.

**CRITICAL:** This is the ONE centralized defect log at `/home/agent0/HX-Infrastructure/docs/defect-log.md`. Do NOT create node-specific defect logs.
</description>

<inputs>
- All defects created during project (execution, testing, post-deployment)
- Defect resolution outcomes
- CAIO approvals for accepted defects
</inputs>

<actions>
**Agent Zero performs:**

1. **Review All Defects for Project**
   - Defects created during execution
   - Defects created during testing
   - Defects discovered post-deployment
   - Identify all defects related to [node-name]

2. **Update RESOLVED Defects**
   For each resolved defect:
   - Resolution date
   - Resolution approach
   - Who resolved it
   - Time to resolution
   - Verification that fix works
   - Prevention strategy documented

3. **Update MITIGATED Defects**
   For each mitigated defect:
   - Mitigation approach documented
   - Workaround effectiveness assessed
   - Risk of mitigation documented
   - Future fix planned (added to backlog)
   - Monitoring in place

4. **Update ACCEPTED Defects**
   For each accepted defect:
   - Why accepted (not fixing)
   - Risk assessment documented
   - Impact documented
   - CAIO approval confirmed
   - Monitoring in place

5. **Close Project Defect Tracking**
   - All defects triaged
   - No P0 defects open
   - P1 defects resolved or mitigated with CAIO approval
   - P2/P3 defects documented
   - Future fixes added to backlog

6. **Defect Prevention Analysis**
   - Defect sources identified
   - Testing effectiveness assessed
   - Process improvements identified
   - Recommendations for future projects

**Quality Checks:**
- All defects reviewed and final status set
- No P0 defects open
- All P1 defects resolved/mitigated with approval
- Prevention analysis complete
</actions>

<outputs>
- Defect log updated with all final statuses
- Defect metrics and analysis complete
- Prevention strategies documented
- No critical defects open

**Status Update:**
- Defect log current for this project
- Ready for backlog update
</outputs>

<duration>1-2 hours</duration>
</phase>

<phase id="3" name="Backlog Final Update" gate="none">
<description>
Update centralized backlog with deferred work and future enhancements. Consolidate all items identified throughout project and prioritize for future work.

**CRITICAL:** This is the ONE centralized backlog at `/home/agent0/HX-Infrastructure/docs/backlog.md`. Do NOT create node-specific backlogs.
</description>

<inputs>
- Out-of-scope items from charter
- Deferred features from spec
- Future enhancements identified during execution
- Optimization opportunities discovered
- Technical debt created
- Mitigated defects needing future fixes
</inputs>

<actions>
**Agent Zero performs:**

1. **Gather Backlog Items from Project**
   - Out-of-scope items from charter
   - Deferred features from spec
   - Future enhancements identified during execution
   - Optimization opportunities discovered
   - Technical debt created
   - Mitigated defects needing future fixes

2. **Consolidate and Organize**
   - Remove duplicates
   - Merge similar items
   - Categorize by type (enhancement/optimization/fix/debt)
   - Prioritize by value and effort
   - Assign rough sizing

3. **Add Context for Each Item**
   - Why deferred (rationale)
   - Business value if implemented
   - Technical complexity
   - Dependencies
   - Recommended timeline
   - Reference to source (charter/spec/defect)

4. **Cross-Reference Defects**
   - Link mitigated defects to backlog items
   - Link accepted defects to backlog items
   - Ensure traceability

5. **Prioritize Backlog**
   - Must-have for next phase
   - Should-have (high value)
   - Could-have (nice to have)
   - Won't-have (low value, documented for future)
   - Technical debt (must address eventually)

**Quality Checks:**
- All deferred items captured
- No duplicates
- Clear prioritization
- Context documented for each item
- Cross-references complete
</actions>

<outputs>
- Backlog updated with consolidated items
- Items prioritized and categorized
- Context and rationale documented
- Technical debt tracked

**Status Update:**
- Backlog current for this project
- Future work clearly documented
- Ready for lessons learned
</outputs>

<duration>1-2 hours</duration>
</phase>

<phase id="4" name="Lessons Learned Consolidation" gate="none">
<description>
Capture comprehensive lessons learned from project for organizational knowledge base. Document what went well, what could improve, and recommendations for future projects.
</description>

<inputs>
- Lessons learned documents from each phase
- Execution outcomes
- RAIDD outcomes
- Defect analysis
- Team observations
</inputs>

<actions>
**Agent Zero performs:**

1. **Gather Lessons from All Sources**
   - lessons-learned.md from node directory (execution phase)
   - Charter phase observations
   - Spec phase observations
   - Task phase observations
   - Execution phase observations
   - RAIDD analysis
   - Defect prevention analysis
   - Team member feedback

2. **Categorize Lessons Learned**
   **What Went Well:**
   - Process successes
   - Tool effectiveness
   - Team collaboration
   - Technical approaches
   - Risk management

   **What Could Be Improved:**
   - Process weaknesses
   - Tool limitations
   - Communication gaps
   - Technical challenges
   - Estimation accuracy

   **Recommendations for Future Projects:**
   - Process improvements
   - Tool changes
   - Training needs
   - Documentation enhancements
   - Quality improvements

3. **Extract Key Insights**
   - Most valuable lessons (top 5)
   - Critical success factors
   - Critical failure points avoided
   - Innovations worth repeating
   - Mistakes to avoid

4. **Create Organizational Knowledge Document**
   Location: `/home/agent0/HX-Infrastructure/lessons-learned/[node-name]-lessons-learned.md`

   Or add to: `/home/agent0/HX-Infrastructure/docs/lessons-learned.md` (if centralized)

   Include:
   - Project summary
   - Timeline and metrics
   - What went well
   - What could improve
   - Key insights
   - Recommendations
   - Specific examples
   - Actionable improvements

**Quality Checks:**
- Lessons comprehensive
- Actionable recommendations
- Specific examples included
- Insights valuable for future
- Documented for organizational access
</actions>

<outputs>
- Lessons learned document created
- Organizational knowledge captured
- Actionable recommendations documented
- Key insights highlighted

**Status Update:**
- Project knowledge captured
- Organizational learning enabled
- Ready for final status report
</outputs>

<duration>2-3 hours</duration>
</phase>

<phase id="5" name="Final Status Report Creation" gate="none">
<description>
Create comprehensive final project status report documenting complete project story from charter through operational deployment.
</description>

<inputs>
- Charter
- Specification
- Task breakdown
- Execution completion report
- RAIDD final status
- Defect final status
- Backlog items
- Lessons learned
- All project metrics
</inputs>

<actions>
**Agent Zero creates final report:**

**Location:** `/nodes/[node-name]/final-project-report.md`

**Report Structure:**

1. **Executive Summary**
   - Project overview
   - Final status
   - Success criteria met
   - Key achievements
   - Outstanding items (if any)

2. **Project Timeline**
   - Charter approved: [date]
   - Spec approved: [date]
   - Tasks approved: [date]
   - Execution start: [date]
   - Operational promotion: [date]
   - Project closed: [date]
   - Total duration: [X days/weeks]

3. **Success Criteria Assessment**
   From charter - status of each criterion:
   - Criterion 1: Met/Not Met/Partially Met
   - Criterion 2: Met/Not Met/Partially Met
   - Overall: [X]% criteria met

4. **Requirements Traceability**
   - Total requirements from spec: [N]
   - Implemented: [X]
   - Deferred: [Y]
   - Modified: [Z]

5. **Quality Metrics**
   - Tasks completed: [N]/[Total]
   - Tests executed: [N]/[Total]
   - Test pass rate: [%]
   - Defects found: [N]
   - Defects resolved: [X]
   - Code quality: [assessment]

6. **Schedule Performance**
   - Planned duration: [X]
   - Actual duration: [Y]
   - Variance: [+/- Z days]
   - Critical path performance: [On time/Delayed]

7. **RAIDD Summary**
   - Risks: [N] identified, [X] materialized, [Y] mitigated
   - Assumptions: [N] made, [X] validated
   - Issues: [N] encountered, [X] resolved
   - Dependencies: [N] identified, [X] met
   - Decisions: [N] made, [X] correct

8. **Defect Summary**
   - Total defects: [N]
   - P0: [X] - All resolved
   - P1: [Y] - Status
   - P2/P3: [Z] - Status

9. **Backlog Summary**
   - Total items deferred: [N]
   - High priority: [X]
   - Technical debt: [Y]

10. **Lessons Learned Summary**
    - Top 3 successes
    - Top 3 improvements
    - Top 3 recommendations

11. **Operational Status**
    - Service status: OPERATIONAL
    - Stability: [assessment]
    - Performance: [assessment]
    - Monitoring: Configured
    - Operations readiness: [assessment]

12. **Outstanding Items**
    - Open defects with mitigation
    - Backlog items created
    - Future enhancements identified

13. **Team Contributions**
    - Agent Zero: [role and contribution]
    - Team members: [contributions]
    - CAIO: [decisions and approvals]

14. **Final Recommendation**
    - Project status: SUCCESS/SUCCESS WITH CONDITIONS/PARTIAL SUCCESS
    - Operational recommendation: APPROVED FOR PRODUCTION
    - Follow-up required: [Yes/No - if yes, what]

**Quality Checks:**
- Report comprehensive and accurate
- All sections complete
- Metrics correct
- Cross-references validated
- Professional quality
</actions>

<outputs>
- Final project report created
- Complete project story documented
- All metrics and outcomes recorded
- Professional summary for stakeholders

**Status Update:**
- Project fully documented
- Ready for archival
</outputs>

<duration>2-3 hours</duration>
</phase>

<phase id="6" name="Archive and Documentation Organization" gate="none">
<description>
Organize and archive all project artifacts for long-term retention and future reference. Ensure all documentation is properly structured and accessible.
</description>

<inputs>
- All project files in `/nodes/[node-name]/`
- Final project report
- Updated centralized artifacts
</inputs>

<actions>
**Agent Zero performs:**

1. **Verify Directory Structure**
   Ensure complete organization:
   ```
   /nodes/[node-name]/
   ├── charter.md (APPROVED)
   ├── node-spec.md (APPROVED)
   ├── STATUS.md (OPERATIONAL)
   ├── final-project-report.md (NEW)
   ├── tasks/
   │   ├── task-breakdown-summary.md
   │   └── [all task files]
   ├── task-results/
   │   └── [all result files]
   ├── tests/
   │   ├── test-plan.md
   │   ├── test-suite-index.md
   │   ├── test-suite/ (all test cases)
   │   └── test-executions/ (all results)
   ├── defects/
   │   └── [all defect files]
   ├── reviews/
   │   ├── team-member/ (contributions)
   │   └── knowledge-vault/ (research)
   ├── execution-tracking.md
   ├── execution-completion-report.md
   ├── caio-operational-approval.md
   ├── lessons-learned.md
   └── caio-project-closure-approval.md (after Phase 7)
   ```

2. **Create Archive Summary**
   Location: `/nodes/[node-name]/ARCHIVE-INDEX.md`

   Contents:
   - Project overview
   - File inventory
   - Key documents index
   - Access information
   - Retention policy

3. **Validate Documentation Completeness**
   - [ ] Charter complete and approved
   - [ ] Specification complete and approved
   - [ ] Task breakdown complete
   - [ ] All task results documented
   - [ ] Test suite complete
   - [ ] All test results documented
   - [ ] All defects documented
   - [ ] Execution report complete
   - [ ] Lessons learned captured
   - [ ] Final report created

4. **Update Central Indexes**
   - Update `/nodes/README.md` or node index with project completion
   - Ensure project listed in completed projects
   - Cross-reference to archive location

5. **Set File Permissions (if applicable)**
   - Read-only for archival documents
   - Appropriate access controls

**Quality Checks:**
- All files present and organized
- Directory structure complete
- Documentation comprehensive
- Archive index created
- Central indexes updated
</actions>

<outputs>
- Complete project archive organized
- ARCHIVE-INDEX.md created
- Central indexes updated
- Documentation accessible for future reference

**Status Update:**
- Project fully archived
- Ready for CAIO closure approval
</outputs>

<duration>1-2 hours</duration>
</phase>

<phase id="7" name="CAIO Project Closure Approval" gate="caio-closure-approved">
<description>
CAIO reviews final project report and approves formal project closure. This is the final approval gate for project.
</description>

<inputs>
- Final project report
- Updated centralized artifacts (RAIDD, Defect, Backlog)
- Lessons learned document
- Archive organization
- Operational status confirmation
</inputs>

<actions>
**CAIO reviews:**

1. **Project Completion Review**
   - Final project report
   - Success criteria assessment
   - Operational status confirmation
   - Outstanding items review

2. **Quality Assessment**
   - Requirements met
   - Quality metrics acceptable
   - Defects properly resolved/mitigated
   - Documentation complete

3. **Knowledge Capture Review**
   - Lessons learned comprehensive
   - RAIDD outcomes documented
   - Backlog items clear
   - Organizational learning captured

4. **Operational Readiness**
   - Service stable and operational
   - Operations team ready
   - Runbooks complete (if needed)
   - Monitoring configured

5. **Approval Decision**

   **Option A: Approve Project Closure**
   - Project completed successfully
   - Ready for formal closure
   - Proceed to Phase 8

   **Option B: Approve with Conditions**
   - Generally complete but follow-up needed
   - Document conditions
   - Proceed to Phase 8 with follow-up plan

   **Option C: Require Additional Work**
   - Gaps in documentation or closure
   - Complete missing items
   - Re-submit for approval

**Document Closure Approval:**

Location: `/nodes/[node-name]/caio-project-closure-approval.md`

Document:
- Review summary
- Decision (Approved / Approved with Conditions / Additional Work Required)
- Conditions (if applicable)
- Follow-up items (if any)
- Signature and timestamp

**Quality Checks:**
- CAIO has reviewed all key documents
- Decision clearly documented
- Conditions (if any) specific and measurable
- Approval formally recorded
</actions>

<outputs>
- caio-project-closure-approval.md created
- Formal closure decision documented
- Follow-up plan (if needed)

**Gate: CAIO Closure Approved**
Pass Criteria:
- ✅ CAIO reviewed final report
- ✅ Closure approved (with or without conditions)
- ✅ Ready for operational handoff

**Fail Actions:**
- If additional work required: Complete gaps, re-submit

**Status Update:**
- CAIO approval documented
- Project formally approved for closure
- Ready for operational handoff
</outputs>

<duration>1-2 hours</duration>
</phase>

<phase id="8" name="Operational Handoff and Final Steps" gate="none">
<description>
Complete operational handoff to operations team and perform final administrative closure tasks.
</description>

<inputs>
- CAIO closure approval
- Complete project documentation
- Runbooks (if applicable)
- Monitoring configuration
</inputs>

<actions>
**Agent Zero performs:**

1. **Operational Handoff**
   - Brief operations team on service (if not already done)
   - Provide runbooks and operational documentation
   - Review monitoring and alerting setup
   - Ensure operations team has access to all needed resources
   - Answer any operational questions

2. **Final Status Updates**
   - Update `/nodes/[node-name]/STATUS.md`: Add "Project Closed" date
   - Update project tracking systems with closure date
   - Mark project as CLOSED in any project management tools

3. **Final Notifications**
   - Notify team members of project closure
   - Thank team for contributions
   - Share lessons learned link

4. **Handoff Documentation**
   Location: `/nodes/[node-name]/operational-handoff.md`

   Document:
   - Handoff date
   - Operations team contacts
   - Service overview
   - Runbook location
   - Monitoring dashboards
   - Escalation procedures
   - Known issues (if any)
   - Support contacts

5. **Project Closure Checklist**
   - [ ] CAIO closure approved
   - [ ] All centralized artifacts updated
   - [ ] Lessons learned documented
   - [ ] Final report created
   - [ ] Archive organized
   - [ ] Operations team briefed
   - [ ] Handoff documentation complete
   - [ ] Status updates complete
   - [ ] Team notified

6. **Celebrate Success**
   - Acknowledge team contributions
   - Recognize achievements
   - Share success story (if appropriate)

**Quality Checks:**
- Operations team ready
- Handoff documentation complete
- All closure tasks complete
- Team recognized
</actions>

<outputs>
- Operational handoff complete
- operational-handoff.md created
- Final status updates complete
- Team notified and recognized
- Project formally CLOSED

**Status Update:**
- Project fully closed
- Operations team owns service
- All documentation complete
- Organizational learning captured

**Workflow Complete:**
Project closeout workflow successfully completed. Node/service operational, project formally closed, knowledge captured.
</outputs>

<duration>2-3 hours</duration>
</phase>
</phases>

<quality_gates>
<gate name="closeout-ready" phase="0">
**Gate Question:** Is project ready for formal closeout?

**Pass Criteria:**
- ✅ Service/node operational and stable
- ✅ Stability period observed (no critical incidents)
- ✅ All critical tests passing
- ✅ No P0 defects open
- ✅ CAIO operational approval received
- ✅ Monitoring configured
- ✅ Operations team ready

**Fail Actions:**
- If not stable: Wait for stability period
- If defects open: Resolve P0 defects
- Do NOT proceed with closeout until ready
</gate>

<gate name="caio-closure-approved" phase="7">
**Gate Question:** Has CAIO formally approved project closure?

**Pass Criteria:**
- ✅ CAIO reviewed final report
- ✅ Closure approval documented
- ✅ Follow-up plan documented (if applicable)

**Fail Actions:**
- If additional work required: Complete gaps, re-submit
</gate>
</quality_gates>

<related_documents>
**Workflow Context:**
- **Previous:** `/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-execution-workflow.md` - Executes tasks and promotes to operational
- **This is the final workflow** - Completes project lifecycle

**Procedure Files:**
- `/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md` - Detailed process documentation

**Centralized Artifacts:**
- `/home/agent0/HX-Infrastructure/docs/raidd-log.md` - ONE centralized RAIDD log
- `/home/agent0/HX-Infrastructure/docs/defect-log.md` - ONE centralized defect log
- `/home/agent0/HX-Infrastructure/docs/backlog.md` - ONE centralized backlog
- `/home/agent0/HX-Infrastructure/docs/lessons-learned.md` - Centralized lessons (if used)

**Reference Documents:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Governance principles
</related_documents>

<critical_reminders>
**DO:**
- ✅ Wait for stability period before closeout (3-14 days based on complexity)
- ✅ Update ONE centralized RAIDD log (not per-project copies)
- ✅ Update ONE centralized defect log (not per-project copies)
- ✅ Update ONE centralized backlog (not per-project copies)
- ✅ Capture comprehensive lessons learned
- ✅ Create final project report
- ✅ Organize complete project archive
- ✅ Get CAIO closure approval
- ✅ Complete operational handoff
- ✅ Recognize team contributions

**DON'T:**
- ❌ Skip closeout workflow (even if service is operational)
- ❌ Create node-specific copies of centralized artifacts
- ❌ Close project without CAIO approval
- ❌ Skip lessons learned documentation
- ❌ Forget to update centralized artifacts
- ❌ Skip operational handoff
- ❌ Close with P0 defects open

**For Agent Zero:**
- Coordinator of entire closeout process
- Updates all centralized artifacts
- Creates final report
- Organizes archive
- Facilitates CAIO approval
- Completes operational handoff

**For CAIO:**
- Final approval authority for project closure
- Reviews final report
- Approves formal closure
- Can require additional work if needed

**For Operations Team:**
- Receives operational responsibility
- Gets runbooks and documentation
- Trained on service (if needed)
- Owns ongoing operations

**Centralized Artifacts Critical:**
- ONE RAIDD log for entire HX-Infrastructure
- ONE Defect log for entire HX-Infrastructure
- ONE Backlog for entire HX-Infrastructure
- Do NOT create per-project or per-node copies
- Update centralized artifacts with project outcomes
</critical_reminders>

<validation_checklist>
**Before CAIO closure approval (end of Phase 6), verify:**

**Stability:**
- [ ] Service operational for required stability period
- [ ] No critical incidents during stability
- [ ] Performance stable and acceptable
- [ ] Operations team comfortable

**Centralized Artifacts:**
- [ ] RAIDD log updated with all outcomes
- [ ] Defect log updated with all statuses
- [ ] Backlog updated with all deferred items
- [ ] No P0 defects open
- [ ] All P1 defects resolved/mitigated with approval

**Knowledge Capture:**
- [ ] Lessons learned comprehensive
- [ ] What went well documented
- [ ] What could improve documented
- [ ] Recommendations specific and actionable
- [ ] Key insights captured

**Documentation:**
- [ ] Final project report complete
- [ ] All metrics and outcomes documented
- [ ] Project archive organized
- [ ] ARCHIVE-INDEX.md created
- [ ] Handoff documentation prepared

**Operational:**
- [ ] Service operational and stable
- [ ] Monitoring configured
- [ ] Runbooks complete (if needed)
- [ ] Operations team ready
- [ ] Support processes in place

**Approvals:**
- [ ] All phase approvals received
- [ ] CAIO operational approval documented
- [ ] Ready for CAIO closure approval
</validation_checklist>

<metadata_footer>
**Document Version:** 1.0
**Last Updated:** 2025-11-17
**Status:** APPROVED - Production Workflow
**Maintained By:** Agent Zero (CC)
**Related Workflows:** Charter Creation → Specification Development → Task Breakdown → Task Execution → **Project Closeout**
**Purpose:** Systematic closure with centralized artifact updates and knowledge capture
</metadata_footer>
