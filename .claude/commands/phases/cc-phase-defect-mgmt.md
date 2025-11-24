---
document: cc-phase-defect-mgmt
version: 1.2
date: 2025-11-24
status: APPROVED
type: phase-command
description: Comprehensive defect lifecycle management from discovery through resolution and closure, ensuring quality gates maintained and defects systematically tracked and resolved
applies_to: testing_phase, quality_assurance, defect_tracking
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-defect-mgmt.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Defect Management - Complete Lifecycle Tracking
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-21 (v1.1 - Integration convention standardization)
**Status:** APPROVED - Production Ready
**Type:** Phase Command
**Purpose:** Systematically manage defects from discovery through resolution and closure, maintaining quality standards and ensuring no critical issues slip through to operational deployment
</metadata>

<objective>
**Purpose:** Provide comprehensive defect lifecycle management that ensures every test failure is documented, tracked, prioritized, resolved, verified, and closed with appropriate quality gates preventing defective services from reaching operational status.

**Command Capabilities:**
- Log defects from test failures with complete evidence
- Classify defects by severity (Critical/High/Medium/Low)
- Track defect lifecycle status (Open/In Progress/Resolved/Closed)
- Document root cause analysis and resolutions
- Manage workarounds for blocking defects
- Verify defect resolutions through re-testing
- Block operational promotion for critical/high defects
- Generate defect metrics and reports
- Update centralized defect tracking

**When to Use This Command:**
- When test failure occurs during testing phase
- When defect discovered during deployment or operations
- When reviewing defect status for promotion decisions
- When resolving logged defects
- When verifying defect fixes
- When closing defects after verification
- For defect metrics and quality reporting

**Integration Points:**
- **Called by:** Testing execution, deployment validation, operational monitoring
- **Inputs:** Test failure details, error evidence, system diagnostics
- **Outputs:** Defect documents, defect tracking updates, resolution verification
- **Blocks:** Operational promotion (for Critical/High defects)
</objective>

<utility_overview>
**Core Function:**
This phase command manages the complete defect lifecycle through six phases:

**Phase 1: Defect Discovery and Logging**
When test fails or issue discovered:
- Capture complete defect information
- Classify severity based on impact
- Document reproduction steps
- Collect evidence (logs, errors, screenshots)
- Assign initial priority and owner
- Log in defect tracking system

**Phase 2: Impact Assessment**
Determine defect impact:
- Assess deployment impact (blocks deployment?)
- Assess operational impact (affects operations?)
- Assess requirements impact (which requirements not met?)
- Determine if workaround available
- Decide if blocks operational promotion

**Phase 3: Root Cause Analysis**
Investigate defect cause:
- Analyze evidence and diagnostics
- Identify root cause
- Document contributing factors
- Determine resolution approach
- Estimate resolution effort

**Phase 4: Resolution**
Fix the defect:
- Implement resolution plan
- Document changes made
- Update affected files/configs
- Track resolution time
- Prepare for verification

**Phase 5: Verification**
Verify fix works:
- Re-run failed test(s)
- Run full regression suite
- Verify defect resolved
- Document verification results
- Update defect status

**Phase 6: Closure**
Close verified defects:
- Confirm all closure criteria met
- Document lessons learned
- Update documentation
- Notify stakeholders
- Archive defect record

**Key Principle:** Every test failure MUST result in logged defect. No exceptions. Critical/High defects MUST be resolved before operational promotion. Medium defects require justification to defer. Low defects can be backlogged.

**Quality Gate:** Zero Critical or High defects allowed for operational promotion. This is non-negotiable quality standard.
</utility_overview>

<state_management>
**Stateless Component:**
- This phase command file (instructions + defect management methodology)
- Defect lifecycle processes and severity definitions
- Quality gates and promotion blocking rules
- Reusable across all services and projects

**Stateful Artifacts:**
Phase command execution creates project-specific files:

**Defect Files:**
```
/services/{service-name}/defects/
  defect-{service}-critical-001-{description}.md
  defect-{service}-high-001-{description}.md
  defect-{service}-medium-001-{description}.md
  defect-{service}-low-001-{description}.md
  defect-summary-{date}.md                     # Defect status summary
```

**Centralized Tracking:**
```
/home/agent0/HX-Infrastructure/docs/
  defect-log.md                                # Updated with new defects
  quality-metrics.md                           # Updated with defect metrics
```

**File Naming Convention:**
- `defect-{service}-{severity}-{seq}-{description}.md` - Individual defect
- Severity: critical, high, medium, low (lowercase)
- Sequential numbering per severity level
- Description: brief lowercase-with-hyphens identifier
- Example: `defect-docling-critical-001-service-wont-start.md`

**File Locations:**
Defect files stored in `/services/{service-name}/defects/` with service for direct association with affected service. Centralized defect log in `/home/agent0/HX-Infrastructure/docs/` provides cross-project visibility.

**State Persistence:**
Defect documents persist permanently, serving as:
- Quality audit trail
- Root cause analysis knowledge base
- Problem resolution patterns
- Metrics for process improvement
- Historical reference for similar issues
</state_management>

<defect_management_framework>
**Defect Severity Definitions:**

**Critical Severity:**
Defects that completely prevent service from functioning:
- Service completely non-functional
- Complete service failure (won't start, crashes immediately)
- Data loss or corruption
- Security breach or vulnerability exposed
- System down with no workaround
- **Impact:** Blocks ALL testing, blocks deployment, blocks promotion
- **Resolution:** Immediate priority, must fix before proceeding

**High Severity:**
Defects that break major functionality:
- Major functionality broken or non-functional
- Significant impact to operations
- Workaround not available or very difficult
- Multiple users/systems affected
- Service degradation severe
- **Impact:** Blocks operational promotion, requires resolution
- **Resolution:** High priority, must fix before promotion

**Medium Severity:**
Defects that impair functionality but have workarounds:
- Functionality impaired but partially working
- Workaround available and reasonable
- Limited impact to operations
- Some users/systems affected
- Performance degradation moderate
- **Impact:** Should be resolved, may defer with justification
- **Resolution:** Medium priority, resolve or document workaround

**Low Severity:**
Minor defects with minimal impact:
- Minor issue or cosmetic problem
- Enhancement request
- Minimal impact to operations
- Single user or edge case affected
- Documentation issues
- **Impact:** Does not block promotion
- **Resolution:** Low priority, can be backlogged

**Defect Status Lifecycle:**

```
Open → In Progress → Resolved → Closed
  ↓         ↓           ↓
Deferred  Duplicate   Not a Defect
```

**Status Definitions:**
- **Open:** Newly logged, awaiting investigation or assignment
- **In Progress:** Actively being worked on, resolution in development
- **Resolved:** Fix implemented, awaiting verification
- **Closed:** Verified and closed, defect resolved
- **Deferred:** Postponed to future release, workaround documented
- **Duplicate:** Duplicate of existing defect, reference original
- **Not a Defect:** Investigation determined not actually a defect

**Promotion Blocking Rules:**

**Critical Defects:**
- ❌ BLOCKS deployment execution
- ❌ BLOCKS operational promotion
- ❌ NO exceptions - must be resolved

**High Defects:**
- ⚠️ May proceed with deployment if workaround available
- ❌ BLOCKS operational promotion
- ❌ Must be resolved before operational status

**Medium Defects:**
- ✅ Does not block deployment
- ⚠️ May block promotion without justification
- ✅ Can be deferred with documented rationale

**Low Defects:**
- ✅ Does not block deployment
- ✅ Does not block promotion
- ✅ Can be backlogged for future resolution
</defect_management_framework>

<defect_management_procedures>
  <procedure name="Log Defect from Test Failure">
  **Purpose:** Create comprehensive defect document when test fails or issue discovered

  **Prerequisites:**
  - Test failure occurred OR issue discovered
  - Test case available (if from testing)
  - Error evidence available

  **Inputs Required:**
  - Test case file (if from testing): `tc-{service}-{area}-{seq}-{description}.md`
  - Test execution results
  - Error messages and logs
  - System diagnostics

  **Time Allocation:** 20-30 minutes per defect

  **Execution Steps:**

  **STEP 1: Gather Defect Evidence (5-7 minutes)**
  Collect all information about the defect:

  **Actions:**
  1. Document what test failed (or what issue observed)
  2. Capture error messages
  3. Collect relevant log excerpts
  4. Document system state at failure
  5. Capture reproduction steps

  **Evidence Collection:**
  ```markdown
  ## Evidence Gathered
  
  **Test Failed:** tc-{service}-{area}-{seq}-{description}.md
  **Failure Point:** Step {n} of test
  
  **Error Message:**
  ```
  [exact error message]
  ```
  
  **Log Location:** {log file path}
  **Log Excerpt:**
  ```
  [relevant log lines]
  ```
  
  **System State:**
  - Service Status: {running/stopped/crashed}
  - Process ID: {pid or "none"}
  - CPU Usage: {percentage}
  - Memory Usage: {percentage}
  - Disk Space: {available}
  
  **Configuration:**
  - Config file: {path}
  - Key settings: {relevant settings}
  ```

  **Verification:**
  - [ ] Test failure documented
  - [ ] Error messages captured
  - [ ] Logs collected
  - [ ] System state recorded
  - [ ] Reproduction steps noted

  **STEP 2: Classify Defect Severity (3-5 minutes)**
  Determine defect severity level:

  **Actions:**
  1. Assess impact using severity criteria
  2. Determine if service functional
  3. Check for workaround availability
  4. Assess user/system impact

  **Severity Decision Tree:**
  ```
  Is service completely non-functional?
  ├─ YES → Critical
  └─ NO ↓
  
  Is major functionality broken?
  ├─ YES → Is workaround available?
  │        ├─ NO → High
  │        └─ YES → Medium
  └─ NO ↓
  
  Is functionality impaired?
  ├─ YES → Medium
  └─ NO → Low
  ```

  **Document Severity Classification:**
  ```markdown
  ## Severity Classification: {Critical | High | Medium | Low}
  
  **Justification:**
  - [X] {Checked criterion from severity definition}
  - [X] {Checked criterion from severity definition}
  
  **Impact Assessment:**
  - Service functional: {Yes | Partially | No}
  - Workaround available: {Yes | No}
  - Users affected: {count or "all"}
  - Operations impact: {description}
  ```

  **Verification:**
  - [ ] Severity assigned using criteria
  - [ ] Severity justified with checked criteria
  - [ ] Impact assessed
  - [ ] Workaround status documented

  **STEP 3: Document Reproduction Steps (4-6 minutes)**
  Create clear reproduction steps:

  **Actions:**
  1. List prerequisites for reproduction
  2. Document exact steps to reproduce
  3. Note reproduction rate (always/sometimes/once)
  4. Verify steps reproduce issue

  **Reproduction Documentation:**
  ```markdown
  ## Steps to Reproduce
  
  **Reproducibility:** {Always | Sometimes | Once | Cannot Reproduce}
  **Reproduction Rate:** {percentage}%
  
  ### Prerequisites
  1. {Prerequisite 1 - e.g., Service installed}
  2. {Prerequisite 2 - e.g., Configuration X applied}
  3. {Prerequisite 3 - e.g., Dependency Y running}
  
  ### Reproduction Steps
  1. {Step 1 - exact action}
     ```bash
     {command if applicable}
     ```
  
  2. {Step 2 - exact action}
     ```bash
     {command if applicable}
     ```
  
  3. {Step 3 - exact action}
  
  ### Expected Result
  {What should happen}
  
  ### Actual Result
  {What actually happens - the defect}
  ```

  **Verification:**
  - [ ] Prerequisites listed
  - [ ] Steps clear and exact
  - [ ] Reproduction rate noted
  - [ ] Expected vs actual documented

  **STEP 4: Create Defect Document (8-12 minutes)**
  Generate formal defect documentation:

  **Actions:**
  1. Determine sequential defect number for severity level
  2. Create defect file: `/services/{service-name}/defects/defect-{service}-{severity}-{seq}-{description}.md`
  3. Use defect template with all collected information

  **Defect Document Structure:**
  ```markdown
  # Defect: {Brief Description}
  
  **Defect ID:** defect-{service}-{severity}-{seq}-{description}
  **Service:** {service-name}
  **Severity:** {critical | high | medium | low}
  **Status:** Open
  **Created:** {timestamp}
  **Updated:** {timestamp}
  
  ---
  
  ## Defect Summary
  
  **Brief Description:**
  {One-sentence description of defect}
  
  **Impact:**
  {Brief description of impact on service operation or deployment}
  
  **Affected Component:**
  {Which part of service affected - e.g., configuration, installation, functionality}
  
  ---
  
  ## Severity Classification
  [From Step 2]
  
  ---
  
  ## Defect Details
  
  ### Discovery Information
  **Discovered During:** {Testing | Deployment | Operations}
  **Discovered By:** {name or agent}
  **Discovery Date:** {date}
  **Test Case:** {test case file if applicable}
  **Test Execution:** {test execution file if applicable}
  
  ### Environment
  **Node:** {node-name}
  **OS:** {operating system and version}
  **Service Version:** {version}
  **Configuration:** {relevant configuration details}
  
  ---
  
  ## Defect Description
  
  ### Detailed Description
  {Comprehensive description - what is wrong, expected vs actual}
  
  ### Expected Behavior
  {What should happen / how service should behave}
  
  ### Actual Behavior
  {What actually happens / how service actually behaves}
  
  ### Business Impact
  {How this defect impacts business, operations, or deployment timeline}
  
  ---
  
  ## Steps to Reproduce
  [From Step 3]
  
  ---
  
  ## Evidence and Diagnostics
  [From Step 1]
  
  ---
  
  ## Root Cause Analysis
  
  **Root Cause Identified:** UNDER INVESTIGATION
  
  ### Root Cause
  [To be determined during investigation]
  
  ### Contributing Factors
  [To be documented during investigation]
  
  ### Analysis Notes
  [Initial observations and hypotheses]
  
  ---
  
  ## Impact Assessment
  
  ### Deployment Impact
  **Blocks Deployment:** {YES | NO}
  **Blocks Promotion to Operational:** {YES | NO}
  
  **Impact Details:**
  {How defect affects deployment or service promotion}
  
  ### Operational Impact
  **Affects Operations:** {YES | NO}
  **Affects Users:** {YES | NO}
  **Number of Users Affected:** {number or "all"}
  
  ### Requirements Impact
  **Requirements Not Met:**
  - {FR-XXX}: {How requirement not met}
  - {SC-XXX}: {How success criteria not met}
  
  ---
  
  ## Workaround
  
  **Workaround Available:** {YES | NO}
  
  [Workaround details if available, or "Under investigation"]
  
  ---
  
  ## Resolution
  
  ### Resolution Status
  **Status:** Open
  **Assigned To:** {name/role}
  **Priority:** {Immediate | High | Medium | Low}
  **Target Resolution Date:** {date based on severity}
  
  ### Resolution Plan
  [To be developed during investigation]
  
  ---
  
  ## Verification
  [To be completed after resolution]
  
  ---
  
  ## Prevention
  [To be documented after resolution]
  
  ---
  
  ## Communication
  
  ### Stakeholders Notified
  - [ ] Service Owner
  - [ ] Tech Lead
  - [ ] CAIO
  - [ ] Operations Team (if critical/high)
  
  ---
  
  ## Metrics
  [To be calculated during lifecycle]
  
  ---
  
  ## History and Updates
  
  ### Update Log
  | Date | Updated By | Status Change | Notes |
  |------|-----------|---------------|-------|
  | {date} | {name} | Created | Initial defect logged |
  
  ---
  
  ## Closure
  [To be completed when defect closed]
  ```

  **Verification:**
  - [ ] Defect document created
  - [ ] All evidence included
  - [ ] Severity justified
  - [ ] Reproduction steps clear
  - [ ] Impact assessed
  - [ ] Status appropriate
  - [ ] Ready for assignment

  **Outputs Generated:**
  - `/services/{service-name}/defects/defect-{service}-{severity}-{seq}-{description}.md`

  **Quality Validation:**
  - [ ] Defect ID unique
  - [ ] Severity appropriate
  - [ ] Evidence complete
  - [ ] Reproduction possible
  - [ ] Impact clear
  - [ ] Stakeholders identified
  </procedure>

  <procedure name="Resolve Defect">
  **Purpose:** Implement resolution for logged defect and document changes made

  **Prerequisites:**
  - Defect logged and assigned
  - Root cause identified
  - Resolution approach determined

  **Inputs Required:**
  - Defect document: `/services/{service-name}/defects/defect-{service}-{severity}-{seq}-{description}.md`
  - Root cause analysis
  - Resolution plan

  **Time Allocation:** Variable based on defect complexity

  **Execution Steps:**

  **STEP 1: Perform Root Cause Analysis (15-30 minutes)**
  Investigate and identify root cause:

  **Actions:**
  1. Review defect evidence
  2. Analyze logs and diagnostics
  3. Reproduce defect in controlled environment
  4. Identify root cause
  5. Document contributing factors

  **Root Cause Documentation:**
  ```markdown
  ## Root Cause Analysis (Updated)
  
  **Root Cause Identified:** YES
  
  ### Root Cause
  {Detailed explanation of what is causing this defect}
  
  Example: "Service fails to start because systemd service file 
  references incorrect binary path. Service file points to 
  /usr/bin/docling but actual binary is /usr/local/bin/docling."
  
  ### Contributing Factors
  1. {Factor 1 - e.g., Installation script uses non-standard path}
  2. {Factor 2 - e.g., Service file template not updated}
  3. {Factor 3 - e.g., No validation of binary path during installation}
  
  ### Analysis Notes
  {Detailed investigation notes, hypotheses tested, conclusions}
  ```

  **Verification:**
  - [ ] Root cause identified
  - [ ] Contributing factors documented
  - [ ] Analysis notes thorough
  - [ ] Resolution approach clear

  **STEP 2: Develop Resolution Plan (10-15 minutes)**
  Create plan to resolve defect:

  **Actions:**
  1. Determine resolution steps
  2. Identify files to modify
  3. Estimate resolution effort
  4. Plan verification approach

  **Resolution Plan:**
  ```markdown
  ## Resolution (Updated)
  
  ### Resolution Plan
  
  **Approach:**
  {Description of resolution approach}
  
  Example: "Update systemd service file to reference correct 
  binary path at /usr/local/bin/docling"
  
  **Resolution Steps:**
  1. Update service file: /etc/systemd/system/docling.service
  2. Change ExecStart line to /usr/local/bin/docling
  3. Reload systemd daemon
  4. Restart service
  5. Verify service starts successfully
  
  **Files to Modify:**
  - /etc/systemd/system/docling.service
  - [Additional files]
  
  **Estimated Effort:** {time estimate}
  
  **Verification Plan:**
  1. Re-run tc-docling-deployment-004-service-starts.md
  2. Run full deployment test suite
  3. Verify no regression in other tests
  ```

  **Verification:**
  - [ ] Resolution approach clear
  - [ ] Steps specific and executable
  - [ ] Files identified
  - [ ] Effort estimated
  - [ ] Verification planned

  **STEP 3: Implement Resolution (Variable time)**
  Execute resolution plan:

  **Actions:**
  1. Make planned changes
  2. Document exactly what changed
  3. Track time spent
  4. Update defect status to "In Progress"

  **Implementation Documentation:**
  ```markdown
  ## Resolution (Updated)
  
  ### Resolution Implementation
  
  **Resolved By:** {name}
  **Resolution Date:** {date}
  **Resolution Time:** {actual time spent}
  
  **What Was Changed:**
  {Detailed description of changes made}
  
  Example: "Modified systemd service file to reference correct 
  binary path. Changed ExecStart directive from /usr/bin/docling 
  to /usr/local/bin/docling."
  
  **Files Modified:**
  - /etc/systemd/system/docling.service:
    * Line 9: ExecStart=/usr/bin/docling (OLD)
    * Line 9: ExecStart=/usr/local/bin/docling (NEW)
  
  **Configuration Changes:**
  - [Config change 1]
  - [Config change 2]
  
  **Commands Executed:**
  ```bash
  sudo nano /etc/systemd/system/docling.service
  sudo systemctl daemon-reload
  sudo systemctl restart docling
  ```
  ```

  **Verification:**
  - [ ] Changes implemented
  - [ ] Changes documented in detail
  - [ ] Time tracked
  - [ ] Commands recorded
  - [ ] Status updated to "Resolved"

  **STEP 4: Update Defect Document (5-10 minutes)**
  Update defect with resolution information:

  **Actions:**
  1. Update resolution section
  2. Change status to "Resolved"
  3. Add update log entry
  4. Notify stakeholders

  **Status Update:**
  ```markdown
  **Status:** Resolved (was: In Progress)
  **Updated:** {timestamp}
  
  ## History and Updates (Updated)
  
  | Date | Updated By | Status Change | Notes |
  |------|-----------|---------------|-------|
  | {original} | {name} | Created | Initial defect logged |
  | {date} | {name} | Open → In Progress | Root cause identified, resolution started |
  | {date} | {name} | In Progress → Resolved | Resolution implemented, awaiting verification |
  ```

  **Verification:**
  - [ ] Status updated to "Resolved"
  - [ ] Resolution documented
  - [ ] Update log current
  - [ ] Ready for verification

  **Outputs Generated:**
  - Updated defect document with resolution

  **Quality Validation:**
  - [ ] Root cause documented
  - [ ] Resolution complete
  - [ ] Changes documented
  - [ ] Ready for verification
  </procedure>

  <procedure name="Verify Defect Resolution">
  **Purpose:** Verify defect resolution through re-testing and regression testing

  **Prerequisites:**
  - Defect status "Resolved"
  - Resolution implemented
  - Test environment available

  **Inputs Required:**
  - Defect document with resolution
  - Original test case that failed
  - Full test suite for regression

  **Time Allocation:** 30-45 minutes

  **Execution Steps:**

  **STEP 1: Re-run Failed Test (10-15 minutes)**
  Execute test that originally failed:

  **Actions:**
  1. Locate original failed test
  2. Execute test following test steps
  3. Document test result
  4. Compare to expected result

  **Test Execution:**
  ```markdown
  ## Verification (Updated)
  
  ### Verification Plan
  **How Resolution Will Be Verified:**
  1. Re-run tc-{service}-{area}-{seq}-{description}.md
  2. Verify test passes
  3. Run full regression suite
  4. Verify no new failures introduced
  
  ### Verification Results
  **Verified By:** {name}
  **Verification Date:** {date}
  **Verification Status:** {PASS | FAIL}
  
  **Test Re-run Results:**
  Test: tc-{service}-{area}-{seq}-{description}.md
  Result: {PASS | FAIL}
  
  **Verification Notes:**
  {Detailed results of test execution}
  
  Example: "Test tc-docling-deployment-004-service-starts.md 
  executed successfully. Service started without errors. All 
  verification checks passed. Health endpoint responding 
  correctly."
  ```

  **Verification:**
  - [ ] Test executed
  - [ ] Result documented
  - [ ] Pass/fail determined
  - [ ] Notes detailed

  **STEP 2: Run Regression Tests (15-25 minutes)**
  Execute full test suite to check for regression:

  **Actions:**
  1. Run all deployment tests
  2. Run all functionality tests
  3. Run all integration tests
  4. Run all health check tests
  5. Document results

  **Regression Testing:**
  ```markdown
  ### Regression Testing Results
  
  **Tests Re-run:**
  - Deployment Tests: {count} executed, {count} passed, {count} failed
  - Functionality Tests: {count} executed, {count} passed, {count} failed
  - Integration Tests: {count} executed, {count} passed, {count} failed
  - Health Check Tests: {count} executed, {count} passed, {count} failed
  
  **Total:** {count} executed, {count} passed ({percentage}% pass rate)
  
  **New Failures:**
  - {Test ID}: {Reason} [If any new failures]
  - None [If no new failures]
  
  **Regression Status:** {No Regression | Regression Detected}
  ```

  **Verification:**
  - [ ] All tests executed
  - [ ] Results documented
  - [ ] New failures identified (if any)
  - [ ] Regression status determined

  **STEP 3: Update Defect Status (5-10 minutes)**
  Update defect based on verification results:

  **Actions:**
  1. If test passed and no regression → Status "Closed"
  2. If test failed or regression → Status back to "In Progress"
  3. Update verification section
  4. Add update log entry

  **Status Update (If Verification Passes):**
  ```markdown
  **Status:** Closed (was: Resolved)
  **Updated:** {timestamp}
  
  ## History and Updates (Updated)
  
  | Date | Updated By | Status Change | Notes |
  |------|-----------|---------------|-------|
  | {previous entries} | ... | ... | ... |
  | {date} | {name} | Resolved → Closed | Verification passed, no regression |
  ```

  **Status Update (If Verification Fails):**
  ```markdown
  **Status:** In Progress (was: Resolved)
  **Updated:** {timestamp}
  
  ## History and Updates (Updated)
  
  | Date | Updated By | Status Change | Notes |
  |------|-----------|---------------|-------|
  | {previous entries} | ... | ... | ... |
  | {date} | {name} | Resolved → In Progress | Verification failed, further investigation needed |
  
  **Verification Failure Notes:**
  {Why verification failed, what still needs to be done}
  ```

  **Verification:**
  - [ ] Status updated appropriately
  - [ ] Verification results documented
  - [ ] Update log current
  - [ ] If failed, investigation notes added

  **Outputs Generated:**
  - Updated defect document with verification results

  **Quality Validation:**
  - [ ] Verification complete
  - [ ] Results documented
  - [ ] Status appropriate
  - [ ] Ready for closure (if passed) or further work (if failed)
  </procedure>

  <procedure name="Update Centralized Defect Tracking">
  **Purpose:** Update centralized defect log with new defects and status changes

  **Prerequisites:**
  - Defect logged or status changed
  - Defect document complete

  **Inputs Required:**
  - Defect document
  - Centralized defect log: `/home/agent0/HX-Infrastructure/docs/defect-log.md`

  **Time Allocation:** 5-10 minutes

  **Execution Steps:**

  **STEP 1: Update Centralized Defect Log (3-5 minutes)**
  Add or update defect in central tracking:

  **Actions:**
  1. Open defect log
  2. Add new defect entry or update existing
  3. Update defect metrics
  4. Save changes

  **Defect Log Update:**
  ```markdown
  ## Active Defects
  
  ### Critical Defects
  | ID | Service | Description | Status | Assigned | Created | Updated |
  |----|---------|-------------|--------|----------|---------|---------|
  | defect-{service}-critical-001 | {service} | {brief} | {status} | {owner} | {date} | {date} |
  
  ### High Defects
  | ID | Service | Description | Status | Assigned | Created | Updated |
  |----|---------|-------------|--------|----------|---------|---------|
  | defect-{service}-high-001 | {service} | {brief} | {status} | {owner} | {date} | {date} |
  
  ### Medium Defects
  [Similar table]
  
  ### Low Defects
  [Similar table]
  
  ## Defect Metrics
  
  **Current Status:**
  - Total Active Defects: {count}
  - Critical: {count}
  - High: {count}
  - Medium: {count}
  - Low: {count}
  
  **Defects This Period:**
  - Opened: {count}
  - Resolved: {count}
  - Closed: {count}
  
  **Resolution Time:**
  - Average Time to Resolve: {days} days
  - Critical Defects: {days} days average
  - High Defects: {days} days average
  ```

  **Verification:**
  - [ ] Defect log updated
  - [ ] Metrics updated
  - [ ] All information accurate

  **STEP 2: Generate Defect Summary (2-5 minutes)**
  Create defect summary for service:

  **Actions:**
  1. Count defects by severity
  2. Calculate metrics
  3. Assess promotion readiness
  4. Create summary document

  **Defect Summary:**
  ```markdown
  # Defect Summary: {Service Name}
  
  **Service:** {service-name}
  **Summary Date:** {date}
  **Generated By:** {name}
  
  ---
  
  ## Defect Overview
  
  **Total Defects:** {count}
  - Critical: {count}
  - High: {count}
  - Medium: {count}
  - Low: {count}
  
  **Defects by Status:**
  - Open: {count}
  - In Progress: {count}
  - Resolved: {count}
  - Closed: {count}
  
  ---
  
  ## Critical Defects
  
  {List each critical defect with brief status}
  
  ## High Defects
  
  {List each high defect with brief status}
  
  ---
  
  ## Operational Promotion Assessment
  
  **Promotion Blocked By:**
  - Critical Defects: {count} [List defect IDs]
  - High Defects: {count} [List defect IDs]
  
  **Promotion Status:** {🔴 BLOCKED | 🟡 CONDITIONAL | 🟢 READY}
  
  **Rationale:**
  {Explanation of promotion status}
  
  ---
  
  ## Resolution Timeline
  
  **Critical Defects Target Resolution:** {date}
  **High Defects Target Resolution:** {date}
  **Estimated Promotion Date:** {date}
  ```

  **Verification:**
  - [ ] Summary created
  - [ ] Counts accurate
  - [ ] Promotion status clear
  - [ ] Timeline realistic

  **Outputs Generated:**
  - Updated centralized defect log
  - `/services/{service-name}/defects/defect-summary-{date}.md`

  **Quality Validation:**
  - [ ] Central tracking updated
  - [ ] Summary accurate
  - [ ] Promotion status clear
  - [ ] Stakeholders can assess readiness
  </procedure>
</defect_management_procedures>

<integration_convention>
**How Commands Invoke This Phase Command:**

This section documents how workflow commands (Set 1) and testing processes invoke the defect management phase command. Invocation occurs throughout testing, deployment validation, and operational monitoring whenever defects are discovered, resolved, or verified.

**From Testing Execution and Quality Assurance:**

This phase command is called during testing and quality assurance:

**Call: Test Failure - Log Defect Immediately**
```bash
# When test fails during execution
cd /home/agent0/HX-Infrastructure
cat .claude/commands/phases/cc-phase-defect-mgmt.md

# Execute: Log Defect from Test Failure
# Inputs: test case, test results, error evidence
# Outputs: defect document, updated tracking
```

**Input Requirements:**

**For Defect Logging:**
- Test case file (if from testing)
- Test execution results
- Error messages and logs
- System diagnostics
- Reproduction information

**Output Specifications:**

**Defect Document:**
```markdown
Format: Markdown following defect template
Location: /services/{service-name}/defects/defect-{service}-{severity}-{seq}-{description}.md
Structure:
  - Defect summary and severity
  - Discovery and environment details
  - Defect description (expected vs actual)
  - Reproduction steps
  - Evidence and diagnostics
  - Root cause analysis
  - Impact assessment
  - Workaround (if available)
  - Resolution plan and implementation
  - Verification results
  - Prevention measures
  - Communication and metrics
  - History and closure
Size: 200-400 lines
```

**Defect Summary:**
```markdown
Format: Markdown with tables and metrics
Location: /services/{service-name}/defects/defect-summary-{date}.md
Structure:
  - Defect overview (counts by severity/status)
  - Critical and high defects list
  - Operational promotion assessment
  - Resolution timeline
Size: 100-200 lines
```

**File Organization:**
```
/services/{service-name}/
├── tests/
│   ├── test-suite/
│   └── test-execution-tracking.md
└── defects/
    ├── defect-{service}-critical-001-{desc}.md
    ├── defect-{service}-high-001-{desc}.md
    ├── defect-{service}-medium-001-{desc}.md
    ├── defect-{service}-low-001-{desc}.md
    └── defect-summary-{date}.md

/home/agent0/HX-Infrastructure/docs/
├── defect-log.md                    # ← Updated
└── quality-metrics.md               # ← Updated
```

**State Management:**
- Defect documents are permanent stateful artifacts
- Defect status changes tracked in update log
- Centralized defect log updated
- This command file is stateless (reusable methodology)

**Integration with Other Commands:**

**Used by:** Testing execution, deployment validation
**Uses:** Test cases, test results, system diagnostics
**Outputs used by:**
- Operational promotion decisions (blocks promotion)
- Task result documentation
- Quality metrics reporting
- Process improvement

**Workflow Context:**
```
Testing Workflow:
Phase 1: Test Execution
Phase 2: Test Failure Detected → Log Defect (this command)
Phase 3: Defect Resolution
Phase 4: Verification → Update Defect Status (this command)
Phase 5: Defect Closure → Update Tracking (this command)
Phase 6: Promotion Decision (considers defects)
```

**Quality Gates:**
```
Gate 1: Defect Logging
- Every test failure logs defect
- No test failures without defects

Gate 2: Promotion Blocking
- Zero Critical defects for promotion
- Zero High defects for promotion
- Medium defects require justification
- Low defects do not block

Gate 3: Resolution Verification
- Defects resolved through re-testing
- Regression testing confirms no new issues
- Verification must pass before closure
```
</integration_convention>

<critical_reminders>
⚠️ **Every Failure Logged:** Every test failure MUST result in logged defect. No exceptions. Test failures without defects are audit violations.

⚠️ **Severity Discipline:** Severity must be assigned using defined criteria, not subjective opinion. Critical/High must meet specific criteria.

⚠️ **Promotion Blocking:** Critical and High defects MUST block operational promotion. No compromises, no exceptions, no shortcuts.

⚠️ **Evidence Required:** Every defect must have complete evidence (logs, errors, reproduction steps). Defects without evidence cannot be resolved.

⚠️ **Reproduction Steps:** Reproduction steps must be clear enough for someone else to reproduce. "It doesn't work" is not reproduction steps.

⚠️ **Root Cause Required:** Defects cannot be "resolved" without identified root cause. Symptom fixing without root cause analysis causes recurrence.

⚠️ **Verification Required:** Resolution must be verified through re-testing. Claiming defect resolved without verification is quality violation.

⚠️ **Regression Testing:** Resolution must not break other functionality. Full regression testing required after any defect fix.

⚠️ **Status Accuracy:** Defect status must reflect reality. "Resolved" means fix implemented and awaiting verification, not "we think it's fixed."

⚠️ **Central Tracking:** Centralized defect log must be updated for every defect and status change. Central tracking is source of truth.

⚠️ **No Deferring Critical/High:** Critical and High defects cannot be deferred. They must be resolved. Medium defects require justification to defer.

⚠️ **Communication Required:** Stakeholders must be notified of Critical/High defects immediately. Surprises during promotion are unacceptable.
</critical_reminders>

<validation_checklists>
  <checklist name="Defect Logging Validation">
  **Before defect logging complete:**

  **Evidence Collection:**
  - [ ] Test failure or issue documented
  - [ ] Error messages captured
  - [ ] Log excerpts collected
  - [ ] System state recorded
  - [ ] Reproduction steps documented

  **Severity Classification:**
  - [ ] Severity assigned using criteria
  - [ ] Severity justified with checked criteria
  - [ ] Impact assessed
  - [ ] Workaround status determined
  - [ ] Promotion blocking status clear

  **Reproduction:**
  - [ ] Prerequisites listed
  - [ ] Steps clear and executable
  - [ ] Reproduction rate noted
  - [ ] Expected vs actual documented

  **Defect Document:**
  - [ ] Defect ID unique and follows naming convention
  - [ ] All sections complete
  - [ ] Evidence included
  - [ ] Impact assessed
  - [ ] Status appropriate
  - [ ] Stakeholders identified
  </checklist>

  <checklist name="Defect Resolution Validation">
  **Before marking defect resolved:**

  **Root Cause:**
  - [ ] Root cause identified
  - [ ] Contributing factors documented
  - [ ] Analysis thorough
  - [ ] Resolution approach clear

  **Resolution:**
  - [ ] Resolution implemented
  - [ ] Changes documented in detail
  - [ ] Files modified listed
  - [ ] Commands recorded
  - [ ] Time tracked

  **Documentation:**
  - [ ] Resolution section updated
  - [ ] Status changed to "Resolved"
  - [ ] Update log current
  - [ ] Stakeholders notified

  **Readiness:**
  - [ ] Ready for verification
  - [ ] Test plan for verification clear
  - [ ] Regression testing planned
  </checklist>

  <checklist name="Defect Verification Validation">
  **Before closing defect:**

  **Test Re-run:**
  - [ ] Original failed test executed
  - [ ] Test result documented
  - [ ] Pass/fail determined
  - [ ] Notes detailed

  **Regression Testing:**
  - [ ] Full test suite executed
  - [ ] Results documented
  - [ ] New failures identified (if any)
  - [ ] Regression status determined

  **Status Update:**
  - [ ] Status updated appropriately
  - [ ] Verification results documented
  - [ ] Update log current
  - [ ] If failed, investigation notes added

  **Closure Criteria (if passing):**
  - [ ] Root cause identified
  - [ ] Resolution implemented
  - [ ] Resolution verified
  - [ ] Tests re-run and passing
  - [ ] No regression detected
  - [ ] Documentation updated
  - [ ] Stakeholders notified
  </checklist>

  <checklist name="Centralized Tracking Update Validation">
  **Before considering tracking complete:**

  **Defect Log:**
  - [ ] New defect added to central log
  - [ ] Status changes reflected
  - [ ] Metrics updated
  - [ ] Log current and accurate

  **Defect Summary:**
  - [ ] Counts accurate by severity
  - [ ] Counts accurate by status
  - [ ] Promotion status assessed
  - [ ] Timeline realistic

  **Quality Gates:**
  - [ ] Promotion blocking status clear
  - [ ] Critical/High defects identified
  - [ ] Resolution timeline documented
  - [ ] Stakeholders informed
  </checklist>
</validation_checklists>

<related_documents>
**Workflows:**
- [Task Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md) - Defects logged during testing
- [Charter Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md) - Success criteria validate against defects

**Phase Commands:**
- [Test Suite Generation](/home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-test-suite-generation.md) - Tests that can fail and generate defects
- [Task Result Documentation](/home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-task-result-doc.md) - Defects documented in results

**Templates:**
- [Defect Template](/home/agent0/HX-Infrastructure/templates/defect-template.md) - Defect document structure
- [Test Case Template](/home/agent0/HX-Infrastructure/templates/test-case-template.md) - Tests that can fail

**Standards:**
- [Testing Requirements](/home/agent0/HX-Infrastructure/standards/testing-requirements.md) - Defect management requirements
- [Documentation Requirements](/home/agent0/HX-Infrastructure/standards/documentation-requirements.md) - Defect documentation standards

**Reference:**
- [Constitution](/home/agent0/HX-Infrastructure/constitution.md) - Quality principles and defect prevention
- [Defect Log](/home/agent0/HX-Infrastructure/docs/defect-log.md) - Centralized defect tracking
- [Quality Metrics](/home/agent0/HX-Infrastructure/docs/quality-metrics.md) - Defect metrics

**Utilities:**
- [Artifact Tracking](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md) - Track defect documents
- [Status Reporting](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-status-report.md) - Include defect status
</related_documents>

---

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready
**Compliance:** Gold Standard v1.1 - All 11 required elements present
**Integration:** Ready for testing and quality assurance execution
**State:** Stateless command generating stateful defect artifacts
**Last Review:** 2025-11-21
**Update:** Standardized integration convention header to match utility pattern, infrastructure philosophy alignment
**Infrastructure Philosophy:** Appropriately infrastructure-agnostic - defect management methodology applies universally to all deployment models. Infrastructure-specific defects (systemd service failures, bare-metal deployment issues, manual procedure problems) captured through standard defect logging process with infrastructure context in evidence and diagnostics sections.
</metadata_footer>
