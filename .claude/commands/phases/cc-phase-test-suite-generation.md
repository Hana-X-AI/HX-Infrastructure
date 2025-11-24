---
document: cc-phase-test-suite-generation
version: 1.2
date: 2025-11-24
status: APPROVED
type: phase-command
description: Generate comprehensive test suite with 100% requirements coverage following test-driven deployment methodology to ensure service quality before operational promotion
applies_to: task_workflow, testing_phase, quality_assurance
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-test-suite-generation.md
last_updated: 2025-11-24
update_notes: Updated to v2.1 metadata format with location field
---

<metadata>
**Workflow:** Test Suite Generation - Comprehensive Quality Assurance
**Version:** 1.1
**Date:** 2025-11-20
**Last Updated:** 2025-11-20 (Standardized integration convention, infrastructure testing)
**Status:** APPROVED - Production Ready
**Type:** Phase Command
**Purpose:** Generate complete test suite with 100% requirements coverage, organized by test type, following test-driven deployment methodology to ensure service quality and prevent operational failures
</metadata>

<objective>
**Purpose:** Systematically generate comprehensive test suites that validate every requirement before deployment execution. Test suite generation is the critical quality gate that prevents defective services from reaching operational status by ensuring complete testing coverage before any deployment begins.

**Command Capabilities:**
- Generate test plan with requirements coverage matrix
- Create deployment validation tests (installation, configuration, startup)
- Create functionality tests (one per functional requirement)
- Create integration tests (for all integration points)
- Create health check tests (operational monitoring)
- Organize test cases by type and priority
- Generate test execution tracking documents
- Validate 100% requirements coverage
- Ensure test-driven deployment compliance

**When to Use This Command:**
- During task workflow testing phase (after plan.md complete, before deployment execution)
- When creating new service test suites
- When adding new requirements requiring new tests
- When validating test coverage completeness
- When preparing for test-driven deployment
- Before any deployment execution begins

**Integration Points:**
- **Called by:** cc-task-workflow.md (Testing Phase)
- **Inputs:** spec.md (requirements), plan.md (deployment plan), service details
- **Outputs:** test-plan.md, test cases (all types), test execution tracking
- **Prerequisites:** Specification and deployment plan complete and approved
</objective>

<utility_overview>
**Core Function:**
This phase command generates comprehensive test suites through four test type generations:

**Test Type 1: Deployment Validation Tests (Mandatory)**
Verify deployment executed correctly:
- Installation verification (files, versions, permissions)
- Configuration verification (files, values, environment)
- Dependencies verification (installed, versions, accessible)
- Service startup verification (starts, running, stable)
Minimum: 4 deployment tests

**Test Type 2: Functionality Tests (Mandatory)**
Verify service meets functional requirements:
- One test per functional requirement (FR-XXX)
- Core capabilities testing
- Error handling testing
- Edge case testing
Minimum: One per FR (typically 5-15 tests)

**Test Type 3: Integration Tests (Conditional)**
Verify service integrates with other systems:
- Database integration (if applicable)
- Service-to-service integration (if applicable)
- External API integration (if applicable)
- Message queue integration (if applicable)
Required only if service has integration points

**Test Type 4: Health Check Tests (Mandatory)**
Verify ongoing operational health:
- Health endpoint response
- Resource usage monitoring
- Error-free operation verification
Minimum: 3 health check tests

**Key Principle:** Tests written BEFORE deployment execution. Test-driven deployment requires all tests to fail initially (service not deployed), then pass after deployment (service operational). This validates both tests and deployment.

**Coverage Requirement:** 100% of functional requirements and success criteria must have corresponding tests. No exceptions.
</utility_overview>

<state_management>
**Stateless Component:**
- This phase command file (instructions + test generation frameworks + templates)
- Test generation methodology and test type definitions
- Coverage validation criteria and quality standards
- Reusable across all service deployments

**Stateful Artifacts:**
Phase command execution creates project-specific files:

**Test Suite Files:**
```
/services/{service-name}/tests/
  test-plan.md                           # Overall test strategy and coverage
  test-suite-index.md                    # All test cases organized by type
  test-execution-tracking.md             # Test run status and results
  test-suite/
    deployment/
      tc-{service}-deployment-001-verify-installation.md
      tc-{service}-deployment-002-verify-configuration.md
      tc-{service}-deployment-003-verify-dependencies.md
      tc-{service}-deployment-004-service-starts.md
    functionality/
      tc-{service}-functionality-001-{requirement}.md
      tc-{service}-functionality-002-{requirement}.md
      [one per FR-XXX requirement]
    integration/
      tc-{service}-integration-001-{system}-connection.md
      [if service has integrations]
    health-check/
      tc-{service}-health-001-endpoint.md
      tc-{service}-health-002-resources.md
      tc-{service}-health-003-no-errors.md
```

**File Naming Convention:**
- `tc-{service}-{area}-{seq}-{description}.md` - Individual test case
- Test areas: deployment, functionality, integration, health-check
- Sequential numbering within each area
- Use lowercase with hyphens

**File Locations:**
All test artifacts stored in `/services/{service-name}/tests/` with organized subdirectory structure by test type for easy navigation and execution.

**State Persistence:**
Test suite artifacts persist throughout project lifecycle, serving as:
- Validation gate before deployment
- Regression testing for future changes
- Documentation of service quality standards
- Training data for future test generation
- Historical record of service verification
</state_management>

<test_generation_framework>
**Test Case Structure:**

All test cases follow standardized template with these sections:

1. **Test Metadata**
   - Test ID (tc-{service}-{area}-{seq}-{description})
   - Service name
   - Test area (deployment/functionality/integration/health-check)
   - Creation date and status
   - Priority level (Critical/High/Medium/Low)

2. **Traceability**
   - Based on Spec: Links to requirement (FR-XXX, SC-XXX)
   - Based on Plan: Links to deployment plan section
   - Test type (Automated/Manual/Semi-Automated)
   - Estimated execution time

3. **Test Objective**
   - What test validates
   - Why test is important
   - Expected coverage

4. **Prerequisites**
   - Service state requirements
   - Dependency requirements
   - Environment requirements
   - Permission requirements

5. **Test Steps**
   - Numbered steps with actions
   - Expected behavior per step
   - Verification method per step
   - Commands/procedures to execute

6. **Expected Results**
   - Primary expected results (checklist)
   - Observable indicators (logs, files, processes)
   - System state changes

7. **Pass/Fail Criteria**
   - PASS criteria (all must be true)
   - FAIL criteria (any indicates failure)
   - Edge case handling

8. **Post-Test Actions**
   - Cleanup steps
   - State restoration
   - Result documentation

**Test Priority Levels:**

**Critical Priority:**
- Deployment validation tests
- Core functionality tests
- Health check tests
- Must pass for operational promotion

**High Priority:**
- Integration tests
- Error handling tests
- Performance tests
- Should pass for operational promotion

**Medium Priority:**
- Edge case tests
- Enhancement verification
- Nice-to-have features

**Low Priority:**
- Future enhancement validation
- Optional feature tests

**Requirements Coverage Matrix:**

Every test must trace to at least one requirement:

| Requirement | Test Case(s) | Coverage Status |
|-------------|--------------|-----------------|
| FR-001      | tc-{service}-functionality-001 | ✅ |
| FR-002      | tc-{service}-functionality-002, tc-{service}-functionality-003 | ✅ |
| SC-001      | tc-{service}-health-001 | ✅ |

Coverage must be 100% - every requirement has at least one test.
</test_generation_framework>

<test_generation_procedures>
  <procedure name="Generate Test Plan Document">
  **Purpose:** Create comprehensive test plan with strategy, scope, coverage matrix, and test case inventory

  **Prerequisites:**
  - spec.md complete with all requirements (FR-XXX, SC-XXX)
  - plan.md complete with deployment strategy
  - Service architecture understood

  **Inputs Required:**
  - `/services/{service-name}/spec.md` - All requirements
  - `/services/{service-name}/plan.md` - Deployment strategy
  - Service integration points identified
  - Testing environment details

  **Time Allocation:** 15-20 minutes

  **Execution Steps:**

  **STEP 1: Extract Requirements for Coverage (5 minutes)**
  Identify all requirements that need test coverage:

  **Actions:**
  1. Read spec.md completely
  2. Extract all functional requirements (FR-XXX)
  3. Extract all success criteria (SC-XXX)
  4. Identify integration points requiring tests
  5. Note any special testing considerations

  **Create requirements list:**
  ```markdown
  ## Requirements Requiring Test Coverage
  
  ### Functional Requirements (FR-XXX)
  - FR-001: [description]
  - FR-002: [description]
  - FR-003: [description]
  [All functional requirements listed]
  
  ### Success Criteria (SC-XXX)
  - SC-001: [description]
  - SC-002: [description]
  [All success criteria listed]
  
  ### Integration Points
  - Database: [system name]
  - Service API: [system name]
  - Message Queue: [system name]
  [All integration points listed]
  
  ### Special Testing Needs
  - [Any unique testing considerations]
  ```

  **Verification:**
  - [ ] All FR requirements extracted
  - [ ] All SC criteria extracted
  - [ ] Integration points identified
  - [ ] Special needs noted

  **STEP 2: Determine Test Case Count and Distribution (3-5 minutes)**
  Calculate how many test cases needed per type:

  **Actions:**
  1. Count requirements:
     - Functional requirements: {count}
     - Success criteria: {count}
     - Integration points: {count}

  2. Calculate minimum test cases:
     - Deployment: 4 (fixed minimum)
     - Functionality: {FR count} + error handling (typically FR + 2-3)
     - Integration: {integration points} * 1-2 tests each
     - Health Check: 3 (fixed minimum)

  3. Calculate total test suite size:
     ```
     Total = Deployment (4) + 
             Functionality (FR count + 2-3) +
             Integration (integration points * 1-2) +
             Health Check (3)
     
     Example:
     - 5 FRs + 3 error tests = 8 functionality tests
     - 2 integrations * 2 = 4 integration tests
     - Total: 4 + 8 + 4 + 3 = 19 tests
     ```

  **Verification:**
  - [ ] Requirement count accurate
  - [ ] Test case distribution calculated
  - [ ] Total test count reasonable (10-50 typical)
  - [ ] 100% requirements coverage planned

  **STEP 3: Create Test Plan Document (7-10 minutes)**
  Generate formal test plan document:

  **Actions:**
  1. Create `/services/{service-name}/tests/test-plan.md`
  2. Use test plan template:
     ```markdown
     # Test Plan: {Service Name}
     
     **Service:** {service-name}
     **Version:** {version}
     **Created:** {timestamp}
     **Test Author:** Agent Zero
     **Status:** Draft (Pending Review)
     
     ---
     
     ## 1. Test Strategy
     
     ### 1.1 Testing Approach
     This service follows Test-Driven Deployment (TDD):
     - All tests written BEFORE deployment execution
     - Tests MUST FAIL initially (service not deployed)
     - Deployment executed following plan.md
     - Tests MUST PASS after deployment
     - 100% test pass rate required for operational promotion
     
     ### 1.2 Test Objectives
     - Verify deployment executed correctly (deployment tests)
     - Verify all functional requirements met (functionality tests)
     - Verify integrations working (integration tests)
     - Verify service health monitoring (health check tests)
     
     ---
     
     ## 2. Test Scope
     
     ### 2.1 In Scope
     - All functional requirements (FR-XXX)
     - All success criteria (SC-XXX)
     - All deployment steps
     - All integration points
     - Health monitoring and operational readiness
     
     ### 2.2 Out of Scope
     - Performance benchmarking (separate testing)
     - Security penetration testing (separate testing)
     - Load testing (separate testing)
     - Future enhancement features not in spec.md
     
     ---
     
     ## 3. Test Environment
     
     **Environment Details:**
     - Host: {hostname}
     - OS: {operating system}
     - Network Zone: {zone}
     - Dependencies: {list dependencies}
     
     **Test Data:**
     - Location: /services/{service-name}/tests/test-data/
     - Test user accounts: {if applicable}
     - Sample data files: {if applicable}
     
     ---
     
     ## 4. Requirements Coverage Matrix
     
     | Requirement | Description | Test Case(s) | Status |
     |-------------|-------------|--------------|--------|
     | FR-001 | {description} | tc-{service}-functionality-001 | ⏳ Not Run |
     | FR-002 | {description} | tc-{service}-functionality-002 | ⏳ Not Run |
     | FR-003 | {description} | tc-{service}-functionality-003, tc-{service}-functionality-004 | ⏳ Not Run |
     | SC-001 | {description} | tc-{service}-health-001 | ⏳ Not Run |
     [All requirements with test mappings]
     
     **Coverage Summary:**
     - Total Requirements: {count}
     - Requirements with Tests: {count}
     - Coverage Percentage: 100% ✅
     
     ---
     
     ## 5. Test Case Inventory
     
     ### 5.1 Deployment Tests (4 tests)
     - tc-{service}-deployment-001-verify-installation
     - tc-{service}-deployment-002-verify-configuration
     - tc-{service}-deployment-003-verify-dependencies
     - tc-{service}-deployment-004-service-starts
     
     ### 5.2 Functionality Tests ({count} tests)
     - tc-{service}-functionality-001-{requirement}
     - tc-{service}-functionality-002-{requirement}
     [List all functionality tests]
     
     ### 5.3 Integration Tests ({count} tests)
     - tc-{service}-integration-001-{system}-connection
     [List all integration tests, or "N/A - No integrations" if none]
     
     ### 5.4 Health Check Tests (3 tests)
     - tc-{service}-health-001-endpoint
     - tc-{service}-health-002-resources
     - tc-{service}-health-003-no-errors
     
     **Total Test Cases:** {total count}
     
     ---
     
     ## 6. Test Execution Strategy
     
     ### 6.1 Pre-Deployment Execution (Expected: All FAIL)
     **Purpose:** Validate tests work, expect failures (service not deployed)
     
     **Execution Order:**
     1. Run deployment tests → Expect ALL FAIL
     2. Run functionality tests → Expect ALL FAIL
     3. Run integration tests → Expect ALL FAIL
     4. Run health check tests → Expect ALL FAIL
     
     **Gate:** All tests execute, all fail as expected → Proceed to deployment
     
     ### 6.2 Post-Deployment Execution (Required: All PASS)
     **Purpose:** Validate deployment successful, service operational
     
     **Execution Order:**
     1. Run deployment tests → Require ALL PASS
     2. Run functionality tests → Require ALL PASS
     3. Run integration tests → Require ALL PASS
     4. Run health check tests → Require ALL PASS
     
     **Gate:** 100% pass rate → Promote to operational
     
     ---
     
     ## 7. Pass/Fail Criteria
     
     ### Service Level Pass Criteria
     **Service deployment PASSES if:**
     - All deployment tests: PASS
     - All functionality tests: PASS
     - All integration tests: PASS (or N/A if no integrations)
     - All health check tests: PASS
     - Zero critical or high defects
     
     ### Service Level Fail Criteria
     **Service deployment FAILS if:**
     - Any deployment test: FAIL
     - Any functionality test: FAIL
     - Any integration test: FAIL
     - Any health check test: FAIL
     - Any critical defect found
     
     ---
     
     ## 8. Defect Management
     
     **Defect Logging:**
     - All test failures logged as defects
     - Defect template: /services/{service-name}/tests/defects/defect-{id}.md
     - Severity levels: Critical, High, Medium, Low
     
     **Resolution Requirements:**
     - Critical/High defects: Must fix before operational promotion
     - Medium defects: Fix or document as known issue
     - Low defects: Backlog for future release
     
     ---
     
     ## 9. Test Schedule
     
     **Test Creation:** {date range}
     **Test Review:** {date}
     **Pre-Deployment Test Run:** {date}
     **Deployment Execution:** {date}
     **Post-Deployment Test Run:** {date}
     **Operational Promotion:** {date} (if all tests pass)
     
     ---
     
     ## 10. Approvals
     
     **Test Plan Approved By:**
     - [ ] CAIO (Test strategy and coverage)
     - [ ] Deployment Lead (Test feasibility)
     - [ ] Quality Assurance (Test completeness)
     
     **Approval Date:** {date}
     ```

  **Verification:**
  - [ ] Test plan document created
  - [ ] All sections complete
  - [ ] Requirements coverage matrix shows 100%
  - [ ] Test case inventory complete
  - [ ] Test execution strategy clear
  - [ ] Ready for review and approval

  **Outputs Generated:**
  - `/services/{service-name}/tests/test-plan.md` (comprehensive test plan)

  **Quality Validation:**
  - [ ] 100% requirements coverage planned
  - [ ] Test case count reasonable
  - [ ] Test distribution appropriate
  - [ ] Test execution strategy follows TDD
  - [ ] Pass/fail criteria clear
  </procedure>

  <procedure name="Generate Deployment Validation Tests">
  **Purpose:** Create 4 mandatory deployment validation test cases to verify deployment execution

  **Prerequisites:**
  - Test plan created
  - plan.md reviewed (deployment steps understood)
  - Service installation details known

  **Inputs Required:**
  - `/services/{service-name}/plan.md` - Deployment steps
  - Installation location and method
  - Configuration file locations
  - Dependency list
  - Service startup method

  **Time Allocation:** 20-30 minutes (5-7 minutes per test)

  **Execution Steps:**

  **STEP 1: Generate Installation Verification Test (6-8 minutes)**
  Create test to verify service files installed correctly:

  **Actions:**
  1. Review installation section in plan.md
  2. Create `/services/{service-name}/tests/test-suite/deployment/tc-{service}-deployment-001-verify-installation.md`
  3. Use test case template with deployment-specific content:
     ```markdown
     # Test Case: Verify Installation
     
     **Test ID**: tc-{service}-deployment-001-verify-installation
     **Service**: {service-name}
     **Test Area**: deployment
     **Created**: {timestamp}
     **Status**: Not Run
     **Priority**: Critical
     
     ---
     
     ## Test Metadata
     
     **Based on Spec**: Deployment requirement
     **Based on Plan**: Installation section
     **Test Type**: Manual
     **Estimated Execution Time**: 5 minutes
     
     ---
     
     ## Test Objective
     
     **What This Test Validates:**
     Verifies that all service files, binaries, and resources are installed 
     in correct locations with correct versions and permissions.
     
     **Why This Test Is Important:**
     Incorrect installation prevents service from starting and functioning. 
     This is the foundation validation before any other tests.
     
     ---
     
     ## Prerequisites
     
     **Service State:**
     - [ ] Deployment executed (following plan.md)
     - [ ] Installation completed without errors
     
     **Dependencies:**
     - [ ] Access to installation directories
     - [ ] Ability to check file permissions
     
     **Permissions:**
     - [ ] Root or sudo access for file inspection
     
     ---
     
     ## Test Steps
     
     ### Step 1: Verify Service Binary Installed
     **Action:**
     ```bash
     which {service-command}
     # or
     ls -la {installation-path}/{service-binary}
     ```
     
     **Expected Behavior:**
     Binary file exists at expected location
     
     **How to Verify:**
     Command returns path to binary, file exists
     
     ---
     
     ### Step 2: Verify Installation Version
     **Action:**
     ```bash
     {service-command} --version
     ```
     
     **Expected Behavior:**
     Version matches expected version from plan.md
     
     **How to Verify:**
     Output shows correct version number: {expected-version}
     
     ---
     
     ### Step 3: Verify File Permissions
     **Action:**
     ```bash
     ls -la {installation-path}
     ```
     
     **Expected Behavior:**
     Files have correct ownership and permissions
     
     **How to Verify:**
     - Binary: {expected permissions, e.g., -rwxr-xr-x}
     - Owner: {expected owner, e.g., root or service account}
     - Group: {expected group}
     
     ---
     
     ### Step 4: Verify Required Directories Created
     **Action:**
     ```bash
     ls -ld {data-directory}
     ls -ld {config-directory}
     ls -ld {log-directory}
     ```
     
     **Expected Behavior:**
     All required directories exist with correct permissions
     
     **How to Verify:**
     Directories exist, have appropriate ownership and permissions
     
     ---
     
     ## Expected Results
     
     ### Primary Expected Results
     - [ ] Service binary installed at {installation-path}
     - [ ] Version is {expected-version}
     - [ ] File permissions are correct
     - [ ] All required directories created
     - [ ] No installation errors in logs
     
     ### Observable Indicators
     **Files:**
     - {installation-path}/{service-binary} exists
     - {config-directory}/ exists
     - {data-directory}/ exists
     - {log-directory}/ exists
     
     ---
     
     ## Pass/Fail Criteria
     
     ### PASS Criteria
     **Test PASSES if ALL of the following are true:**
     1. Service binary found at expected location
     2. Version matches plan.md specification
     3. File permissions correct (executable, proper ownership)
     4. All required directories exist
     5. No errors during installation verification
     
     ### FAIL Criteria
     **Test FAILS if ANY of the following are true:**
     1. Service binary not found
     2. Wrong version installed
     3. Incorrect file permissions
     4. Missing required directories
     5. Installation errors found
     
     ---
     
     ## Post-Test Actions
     
     **If Test Passes:**
     - [ ] Document installation verification complete
     - [ ] Proceed to configuration verification test
     
     **If Test Fails:**
     - [ ] Log defect with installation details
     - [ ] Review installation logs
     - [ ] Do not proceed to other tests until resolved
     
     ---
     
     ## Test Execution Log
     
     **Executed By:** [Name]
     **Execution Date:** [Date]
     **Execution Time:** [Time]
     **Result:** [PASS | FAIL]
     **Notes:** [Any observations during test execution]
     ```

  **Verification:**
  - [ ] Installation test created
  - [ ] Test steps match plan.md installation steps
  - [ ] Pass/fail criteria clear
  - [ ] All file locations specified

  **STEP 2: Generate Configuration Verification Test (6-8 minutes)**
  Create test to verify service configured correctly:

  **Actions:**
  1. Review configuration section in plan.md
  2. Create `/services/{service-name}/tests/test-suite/deployment/tc-{service}-deployment-002-verify-configuration.md`
  3. Generate test verifying:
     - Configuration files created
     - Configuration values correct
     - Environment variables set
     - Configuration syntax valid

  **Verification:**
  - [ ] Configuration test created
  - [ ] All config files checked
  - [ ] Environment variables verified
  - [ ] Configuration validation included

  **STEP 3: Generate Dependencies Verification Test (6-8 minutes)**
  Create test to verify all dependencies available:

  **Actions:**
  1. Review dependencies section in plan.md
  2. Create `/services/{service-name}/tests/test-suite/deployment/tc-{service}-deployment-003-verify-dependencies.md`
  3. Generate test verifying:
     - All dependency packages installed
     - Correct dependency versions
     - Dependencies accessible to service
     - Network connectivity to external dependencies

  **Verification:**
  - [ ] Dependencies test created
  - [ ] All dependencies checked
  - [ ] Version verification included
  - [ ] Network dependencies tested

  **STEP 4: Generate Service Startup Test (6-8 minutes)**
  Create test to verify service starts successfully:

  **Actions:**
  1. Review service management section in plan.md
  2. Create `/services/{service-name}/tests/test-suite/deployment/tc-{service}-deployment-004-service-starts.md`
  3. Generate test verifying:
     - Service starts without errors
     - Service process running
     - Process ID (PID) exists
     - Service logs show successful startup
     - Service responds to basic commands

  **Verification:**
  - [ ] Service startup test created
  - [ ] Process verification included
  - [ ] Log checking included
  - [ ] Basic command response tested

  **Outputs Generated:**
  - 4 deployment test case files in `/services/{service-name}/tests/test-suite/deployment/`

  **Quality Validation:**
  - [ ] All 4 mandatory deployment tests created
  - [ ] Tests follow template structure
  - [ ] Tests trace to plan.md sections
  - [ ] Pass/fail criteria specific and measurable
  - [ ] Tests can be executed independently
  </procedure>

  <procedure name="Generate Functionality Tests">
  **Purpose:** Create functionality test cases to verify all functional requirements met

  **Prerequisites:**
  - Test plan created
  - spec.md reviewed (all FR-XXX identified)
  - Service capabilities understood

  **Inputs Required:**
  - `/services/{service-name}/spec.md` - All FR-XXX requirements
  - Service API/interface documentation
  - Expected service behaviors

  **Time Allocation:** 5-8 minutes per functional requirement test

  **Execution Steps:**

  **STEP 1: Generate Test Per Functional Requirement (5-8 min each)**
  Create one test case for each FR-XXX requirement:

  **Actions for Each FR-XXX:**
  1. Read functional requirement from spec.md
  2. Identify what behavior validates this requirement
  3. Create `/services/{service-name}/tests/test-suite/functionality/tc-{service}-functionality-{seq}-{fr-description}.md`
  4. Use test case template:
     ```markdown
     # Test Case: Verify {Functional Requirement}
     
     **Test ID**: tc-{service}-functionality-{seq}-{fr-description}
     **Service**: {service-name}
     **Test Area**: functionality
     **Created**: {timestamp}
     **Status**: Not Run
     **Priority**: Critical
     
     ---
     
     ## Test Metadata
     
     **Based on Spec**: FR-{seq} - {requirement description from spec.md}
     **Based on Plan**: {relevant plan.md section}
     **Test Type**: [Automated | Manual]
     **Estimated Execution Time**: {time}
     
     ---
     
     ## Test Objective
     
     **What This Test Validates:**
     Verifies that the service implements {specific functionality from FR-XXX}.
     
     **Why This Test Is Important:**
     This functionality is a core requirement for service operation. 
     Failure means service does not meet specifications.
     
     ---
     
     ## Prerequisites
     
     **Service State:**
     - [ ] Service installed and running
     - [ ] Service accessible
     
     **Dependencies:**
     - [ ] {Any dependencies needed for this functionality}
     
     **Test Data:**
     - [ ] {Any test data needed}
     
     ---
     
     ## Test Steps
     
     [Generate specific test steps that validate the FR-XXX requirement]
     [Steps should be concrete, executable, and verifiable]
     
     ---
     
     ## Expected Results
     
     ### Primary Expected Results
     - [ ] {Specific expected result matching FR-XXX}
     - [ ] {Additional expected results}
     
     ---
     
     ## Pass/Fail Criteria
     
     ### PASS Criteria
     **Test PASSES if ALL of the following are true:**
     1. {FR-XXX requirement met}
     2. {Observable evidence of requirement met}
     3. {No errors during functionality execution}
     
     ### FAIL Criteria
     **Test FAILS if ANY of the following are true:**
     1. {FR-XXX requirement not met}
     2. {Errors during execution}
     3. {Unexpected behavior}
     
     ---
     
     ## Post-Test Actions
     
     **If Test Passes:**
     - [ ] Document FR-{seq} validated
     - [ ] Update coverage matrix
     
     **If Test Fails:**
     - [ ] Log defect referencing FR-{seq}
     - [ ] Document specific failure details
     - [ ] Block operational promotion
     ```

  **Verification per Test:**
  - [ ] Test traces to specific FR-XXX
  - [ ] Test steps validate requirement
  - [ ] Expected results match requirement
  - [ ] Pass/fail criteria specific

  **STEP 2: Generate Error Handling Tests (5-8 min each)**
  Create 2-3 tests for error handling:

  **Actions:**
  1. Create test for invalid input handling
  2. Create test for error message clarity
  3. Create test for service stability after errors
  4. Tests verify service handles errors gracefully

  **Verification:**
  - [ ] Error handling tests created
  - [ ] Invalid input scenarios covered
  - [ ] Error messages validated
  - [ ] Service stability verified

  **STEP 3: Generate Edge Case Tests (optional, 5-8 min each)**
  Create tests for edge cases if identified:

  **Actions:**
  1. Identify edge cases from spec.md
  2. Create tests for boundary conditions
  3. Create tests for unusual inputs
  4. Verify service handles edge cases correctly

  **Verification:**
  - [ ] Edge case tests created
  - [ ] Boundary conditions tested
  - [ ] Unusual scenarios covered

  **Outputs Generated:**
  - {FR count} + 2-3 functionality test files in `/services/{service-name}/tests/test-suite/functionality/`

  **Quality Validation:**
  - [ ] One test per FR-XXX requirement (100% coverage)
  - [ ] Error handling tests included
  - [ ] All tests trace to requirements
  - [ ] Tests follow template structure
  - [ ] Tests executable independently
  </procedure>

  <procedure name="Generate Integration and Health Check Tests">
  **Purpose:** Create integration tests (if needed) and health check tests

  **Prerequisites:**
  - Test plan created
  - Integration points identified (from spec.md and plan.md)
  - Health monitoring requirements understood

  **Inputs Required:**
  - Integration system details
  - Health check requirements
  - Monitoring specifications

  **Time Allocation:** 
  - Integration tests: 10-15 minutes per integration
  - Health check tests: 15-20 minutes total

  **Execution Steps:**

  **STEP 1: Generate Integration Tests (10-15 min per integration)**
  Create test for each integration point:

  **Actions for Each Integration:**
  1. Identify integration system (database, API, service, etc.)
  2. Create `/services/{service-name}/tests/test-suite/integration/tc-{service}-integration-{seq}-{system}-connection.md`
  3. Generate test verifying:
     - Connection to integrated system successful
     - Authentication works
     - Data can be exchanged
     - Error scenarios handled properly

  **If No Integrations:**
  - Note in test-plan.md: "Integration tests: N/A - No external integrations"
  - Do not create integration test directory

  **Verification per Integration Test:**
  - [ ] Connection test included
  - [ ] Authentication verified
  - [ ] Data exchange tested
  - [ ] Error handling verified

  **STEP 2: Generate Health Endpoint Test (5-7 minutes)**
  Create test for health monitoring endpoint:

  **Actions:**
  1. Create `/services/{service-name}/tests/test-suite/health-check/tc-{service}-health-001-endpoint.md`
  2. Generate test verifying:
     - Health endpoint responds
     - Response time acceptable (< 2 seconds)
     - Status indicates healthy
     - Response format correct

  **Verification:**
  - [ ] Health endpoint test created
  - [ ] Response time checked
  - [ ] Status validation included
  - [ ] Format verification included

  **STEP 3: Generate Resource Usage Test (5-7 minutes)**
  Create test for resource monitoring:

  **Actions:**
  1. Create `/services/{service-name}/tests/test-suite/health-check/tc-{service}-health-002-resources.md`
  2. Generate test verifying:
     - CPU usage within acceptable limits
     - Memory usage within acceptable limits
     - Disk usage acceptable
     - No resource leaks

  **Verification:**
  - [ ] Resource usage test created
  - [ ] CPU monitoring included
  - [ ] Memory monitoring included
  - [ ] Disk monitoring included

  **STEP 4: Generate Error-Free Operation Test (5-7 minutes)**
  Create test for operational stability:

  **Actions:**
  1. Create `/services/{service-name}/tests/test-suite/health-check/tc-{service}-health-003-no-errors.md`
  2. Generate test verifying:
     - No errors in logs
     - No crash/restart events
     - Service stable over time
     - No warning conditions

  **Verification:**
  - [ ] Error-free test created
  - [ ] Log checking included
  - [ ] Stability verification included
  - [ ] Warning detection included

  **Outputs Generated:**
  - Integration tests: {count} files in `/services/{service-name}/tests/test-suite/integration/` (or note N/A)
  - Health check tests: 3 files in `/services/{service-name}/tests/test-suite/health-check/`

  **Quality Validation:**
  - [ ] All integration points have tests (or N/A noted)
  - [ ] All 3 health check tests created
  - [ ] Tests follow template structure
  - [ ] Pass/fail criteria clear
  - [ ] Tests executable independently
  </procedure>

  <procedure name="Generate Test Suite Index and Tracking">
  **Purpose:** Create test suite index and execution tracking documents for test organization and result management

  **Prerequisites:**
  - All test cases generated
  - Test plan complete

  **Inputs Required:**
  - All generated test case files
  - Test plan.md

  **Time Allocation:** 10-15 minutes

  **Execution Steps:**

  **STEP 1: Generate Test Suite Index (5-7 minutes)**
  Create master index of all test cases:

  **Actions:**
  1. Create `/services/{service-name}/tests/test-suite-index.md`
  2. List all test cases organized by type:
     ```markdown
     # Test Suite Index: {Service Name}
     
     **Service:** {service-name}
     **Total Test Cases:** {total count}
     **Last Updated:** {timestamp}
     
     ---
     
     ## Test Suite Organization
     
     ### Deployment Tests (4 tests)
     | Test ID | Description | Priority | Status |
     |---------|-------------|----------|--------|
     | tc-{service}-deployment-001 | Verify Installation | Critical | ⏳ Not Run |
     | tc-{service}-deployment-002 | Verify Configuration | Critical | ⏳ Not Run |
     | tc-{service}-deployment-003 | Verify Dependencies | Critical | ⏳ Not Run |
     | tc-{service}-deployment-004 | Service Starts | Critical | ⏳ Not Run |
     
     ### Functionality Tests ({count} tests)
     | Test ID | Description | Requirement | Priority | Status |
     |---------|-------------|-------------|----------|--------|
     | tc-{service}-functionality-001 | {description} | FR-001 | Critical | ⏳ Not Run |
     | tc-{service}-functionality-002 | {description} | FR-002 | Critical | ⏳ Not Run |
     [List all functionality tests]
     
     ### Integration Tests ({count} tests or N/A)
     | Test ID | Description | Integration | Priority | Status |
     |---------|-------------|-------------|----------|--------|
     | tc-{service}-integration-001 | {description} | {system} | High | ⏳ Not Run |
     [List all integration tests, or "No integration tests - service has no integrations"]
     
     ### Health Check Tests (3 tests)
     | Test ID | Description | Priority | Status |
     |---------|-------------|----------|--------|
     | tc-{service}-health-001 | Health Endpoint | Critical | ⏳ Not Run |
     | tc-{service}-health-002 | Resource Usage | Critical | ⏳ Not Run |
     | tc-{service}-health-003 | No Errors | Critical | ⏳ Not Run |
     
     ---
     
     ## Test Execution Summary
     
     **Total Tests:** {count}
     **Tests Executed:** 0
     **Tests Passed:** 0
     **Tests Failed:** 0
     **Tests Blocked:** 0
     **Pass Rate:** 0%
     
     ---
     
     ## Test Files Location
     
     ```
     /services/{service-name}/tests/
     ├── test-plan.md
     ├── test-suite-index.md (this file)
     ├── test-execution-tracking.md
     └── test-suite/
         ├── deployment/
         │   ├── tc-{service}-deployment-001-verify-installation.md
         │   ├── tc-{service}-deployment-002-verify-configuration.md
         │   ├── tc-{service}-deployment-003-verify-dependencies.md
         │   └── tc-{service}-deployment-004-service-starts.md
         ├── functionality/
         │   ├── tc-{service}-functionality-001-{description}.md
         │   └── [additional functionality tests]
         ├── integration/
         │   └── [integration tests or N/A]
         └── health-check/
             ├── tc-{service}-health-001-endpoint.md
             ├── tc-{service}-health-002-resources.md
             └── tc-{service}-health-003-no-errors.md
     ```
     ```

  **Verification:**
  - [ ] Index document created
  - [ ] All test cases listed
  - [ ] Tests organized by type
  - [ ] File locations documented

  **STEP 2: Generate Test Execution Tracking (5-8 minutes)**
  Create test execution tracking document:

  **Actions:**
  1. Create `/services/{service-name}/tests/test-execution-tracking.md`
  2. Use tracking template:
     ```markdown
     # Test Execution Tracking: {Service Name}
     
     **Service:** {service-name}
     **Test Suite Version:** 1.0
     **Last Execution:** Not yet executed
     **Test Status:** ⏳ Pending Execution
     
     ---
     
     ## Test Execution History
     
     ### Pre-Deployment Test Run (Expected: All FAIL)
     **Purpose:** Validate tests work, expect failures (service not deployed)
     **Date:** [Planned date]
     **Executed By:** [Name]
     **Status:** ⏳ Not Started
     
     | Test Area | Tests Run | Passed | Failed | Result |
     |-----------|-----------|--------|--------|--------|
     | Deployment | 0/4 | 0 | 0 | ⏳ Pending |
     | Functionality | 0/{count} | 0 | 0 | ⏳ Pending |
     | Integration | 0/{count} | 0 | 0 | ⏳ Pending |
     | Health Check | 0/3 | 0 | 0 | ⏳ Pending |
     | **Total** | **0/{total}** | **0** | **0** | **⏳ Pending** |
     
     **Expected Outcome:** All tests FAIL (service not deployed yet) ✅
     
     ---
     
     ### Post-Deployment Test Run (Required: All PASS)
     **Purpose:** Validate deployment successful, service operational
     **Date:** [Planned date]
     **Executed By:** [Name]
     **Status:** ⏳ Not Started
     
     | Test Area | Tests Run | Passed | Failed | Result |
     |-----------|-----------|--------|--------|--------|
     | Deployment | 0/4 | 0 | 0 | ⏳ Pending |
     | Functionality | 0/{count} | 0 | 0 | ⏳ Pending |
     | Integration | 0/{count} | 0 | 0 | ⏳ Pending |
     | Health Check | 0/3 | 0 | 0 | ⏳ Pending |
     | **Total** | **0/{total}** | **0** | **0** | **⏳ Pending** |
     
     **Required Outcome:** All tests PASS (100% pass rate) for operational promotion
     
     ---
     
     ## Defects Found
     
     | Defect ID | Test ID | Severity | Description | Status |
     |-----------|---------|----------|-------------|--------|
     | [None yet] | - | - | - | - |
     
     ---
     
     ## Operational Promotion Status
     
     **Promotion Criteria:**
     - [ ] All deployment tests: PASS
     - [ ] All functionality tests: PASS
     - [ ] All integration tests: PASS (or N/A)
     - [ ] All health check tests: PASS
     - [ ] Zero critical or high defects
     - [ ] Test results reviewed and approved
     
     **Promotion Status:** ⏳ Not Ready (Testing not complete)
     **Promotion Date:** TBD (After 100% test pass rate achieved)
     
     ---
     
     ## Test Execution Notes
     
     [Space for notes during test execution]
     ```

  **Verification:**
  - [ ] Tracking document created
  - [ ] Pre-deployment tracking section included
  - [ ] Post-deployment tracking section included
  - [ ] Defect tracking section included
  - [ ] Promotion criteria section included

  **Outputs Generated:**
  - `/services/{service-name}/tests/test-suite-index.md` (master index)
  - `/services/{service-name}/tests/test-execution-tracking.md` (tracking document)

  **Quality Validation:**
  - [ ] All test cases indexed
  - [ ] Execution tracking ready
  - [ ] Defect tracking ready
  - [ ] Promotion criteria documented
  - [ ] Ready for test execution
  </procedure>
</test_generation_procedures>

<integration_convention>
**How Commands Invoke This Phase Command:**

This section documents how workflow commands (Set 1) invoke the test suite generation phase command. Invocation occurs during task workflow testing phase after deployment plan approval and before deployment execution.

**From Task Workflow (cc-task-workflow.md):**
This phase command is called during testing phase:

**Call: Testing Phase - After Plan.md Complete, Before Deployment**
```bash
# After deployment plan approved, before deployment execution
cd /home/agent0/HX-Infrastructure
cat .claude/commands/phases/cc-phase-test-suite-generation.md

# Execute: Generate Complete Test Suite
# Inputs: spec.md, plan.md
# Outputs: test-plan.md, all test cases, test-suite-index.md, test-execution-tracking.md
```

**Input Requirements:**

**Specification and Plan:**
- `/services/{service-name}/spec.md` - All requirements (FR-XXX, SC-XXX)
- `/services/{service-name}/plan.md` - Deployment strategy and steps
- Service architecture and integration points understood
- Testing environment details available

**Output Specifications:**

**Test Plan:**
```markdown
Format: Markdown with semantic structure
Location: /services/{service-name}/tests/test-plan.md
Structure:
  - Test strategy and objectives
  - Test scope (in/out of scope)
  - Test environment details
  - Requirements coverage matrix (100% coverage)
  - Test case inventory by type
  - Test execution strategy (pre/post deployment)
  - Pass/fail criteria
  - Defect management approach
Size: 300-500 lines
```

**Test Cases:**
```markdown
Format: Markdown following test case template
Locations:
  - /services/{service-name}/tests/test-suite/deployment/ (4 mandatory tests)
  - /services/{service-name}/tests/test-suite/functionality/ (one per FR-XXX + error handling)
  - /services/{service-name}/tests/test-suite/integration/ (one per integration or N/A)
  - /services/{service-name}/tests/test-suite/health-check/ (3 mandatory tests)
Structure: See test case template
Size: 100-200 lines per test case
Total: 10-50 test cases typical
```

**Test Suite Index:**
```markdown
Format: Markdown with tables
Location: /services/{service-name}/tests/test-suite-index.md
Structure:
  - All test cases organized by type
  - Test status tracking (Not Run, Pass, Fail, Blocked)
  - Test execution summary
  - File location reference
Size: 100-200 lines
```

**Test Execution Tracking:**
```markdown
Format: Markdown with execution tables
Location: /services/{service-name}/tests/test-execution-tracking.md
Structure:
  - Pre-deployment test run section
  - Post-deployment test run section
  - Defect tracking
  - Operational promotion status
Size: 150-250 lines
```

**File Organization:**
```
/services/{service-name}/
├── spec.md
├── plan.md
└── tests/
    ├── test-plan.md                      # ← Test strategy and coverage
    ├── test-suite-index.md               # ← All test cases indexed
    ├── test-execution-tracking.md        # ← Execution results
    └── test-suite/
        ├── deployment/                    # 4 mandatory tests
        │   ├── tc-{service}-deployment-001-verify-installation.md
        │   ├── tc-{service}-deployment-002-verify-configuration.md
        │   ├── tc-{service}-deployment-003-verify-dependencies.md
        │   └── tc-{service}-deployment-004-service-starts.md
        ├── functionality/                 # One per FR-XXX
        │   ├── tc-{service}-functionality-001-{description}.md
        │   └── [additional functionality tests]
        ├── integration/                   # Per integration or N/A
        │   └── [integration tests or N/A]
        └── health-check/                  # 3 mandatory tests
            ├── tc-{service}-health-001-endpoint.md
            ├── tc-{service}-health-002-resources.md
            └── tc-{service}-health-003-no-errors.md
```

**State Management:**
- Test suite documents are stateful artifacts (persist with service)
- Test execution results are stateful (updated during testing)
- Test plan and test cases are stateful (versioned with service)
- This command file is stateless (reusable test generation methodology)

**Error Handling:**

**If requirements incomplete:**
- Flag gaps in requirements coverage
- Generate tests for available requirements
- Document which requirements lack tests
- Block test plan approval until requirements complete

**If integration points unclear:**
- Generate integration tests based on available information
- Flag uncertainties in test case
- Recommend clarification before execution
- Allow test generation to proceed

**If test generation conflicts:**
- Use test plan as source of truth
- Document conflicts in test-plan.md
- Escalate to CAIO for resolution
- Do not proceed with conflicting tests

**Integration with Other Commands:**

**Used by:** cc-task-workflow.md (Testing Phase)
**Uses:** spec.md, plan.md (inputs)
**Outputs used by:**
- Test execution (manual process using generated tests)
- Defect management (cc-phase-defect-mgmt.md)
- Task result documentation (cc-phase-task-result-doc.md)
- Operational promotion decisions

**Workflow Context:**
```
Task Workflow Phase Sequence:
Phase 0: Task Assignment
Phase 1: Load Context (Spec, Plan)
Phase 2: Testing Phase ← This command
  - Generate Test Suite (this command)
  - Review Test Suite
  - Pre-Deployment Test Run (all fail expected)
Phase 3: Deployment Execution
Phase 4: Post-Deployment Testing (all pass required)
Phase 5: Results Documentation
Phase 6: Operational Promotion (if 100% pass rate)
```

**Quality Gates:**
```
Gate 1: Test Suite Completeness
- All requirements have tests (100% coverage)
- Test cases follow template
- Test plan approved

Gate 2: Pre-Deployment Test Execution
- All tests execute
- All tests FAIL (expected - service not deployed)

Gate 3: Post-Deployment Test Execution
- All tests execute
- All tests PASS (required - service operational)

Gate 4: Operational Promotion
- 100% pass rate
- Zero critical/high defects
- Results documented and approved
```
</integration_convention>

<critical_reminders>
⚠️ **Test-First Mandate:** Tests MUST be written BEFORE deployment execution. No deployment starts until complete test suite exists and is approved. This is non-negotiable.

⚠️ **100% Coverage Required:** Every functional requirement (FR-XXX) and success criterion (SC-XXX) must have at least one test. No exceptions. Partial coverage blocks deployment.

⚠️ **Template Compliance:** All test cases must follow standard template structure. Non-compliant tests rejected during review. Template ensures consistency and executability.

⚠️ **Traceability Required:** Every test must trace to specific requirement (FR-XXX, SC-XXX) or deployment step (plan.md). Untraceable tests indicate missing or incorrect tests.

⚠️ **Pre-Deployment Failure Expected:** Tests running before deployment MUST fail (service not deployed yet). If tests pass pre-deployment, tests are invalid (testing wrong thing).

⚠️ **Post-Deployment Pass Required:** Tests running after deployment MUST pass (service deployed correctly). Any failure blocks operational promotion until fixed.

⚠️ **Independent Tests:** Each test must be executable independently. No test dependencies allowed. Test order should not matter for correctness.

⚠️ **Concrete Verification:** Pass/fail criteria must be specific and measurable. "Service works" is not valid criteria. "Service responds on port 8080 within 2 seconds" is valid.

⚠️ **4+3 Minimum:** Every service needs minimum 4 deployment tests + 3 health check tests, regardless of simplicity. These are mandatory quality gates.

⚠️ **Error Testing Required:** Don't just test happy path. Error handling tests mandatory. Service must fail gracefully, not catastrophically.

⚠️ **Integration Testing Conditional:** If service has no integrations, note "N/A" in test plan. Don't create fake integration tests. But if integrations exist, they must be tested.

⚠️ **Documentation Discipline:** Test execution must be documented. No undocumented test runs. Results must be recorded in test-execution-tracking.md for audit trail.
</critical_reminders>

<validation_checklists>
  <checklist name="Test Plan Generation Validation">
  **Before test case generation begins:**

  **Requirements Extraction:**
  - [ ] All FR-XXX requirements extracted from spec.md
  - [ ] All SC-XXX success criteria extracted from spec.md
  - [ ] Integration points identified
  - [ ] Special testing needs noted

  **Coverage Planning:**
  - [ ] Test case count calculated
  - [ ] Test distribution determined (deployment/functionality/integration/health)
  - [ ] 100% requirements coverage planned
  - [ ] Requirements coverage matrix created

  **Test Plan Document:**
  - [ ] Test plan created in correct location
  - [ ] Test strategy section complete
  - [ ] Test scope section complete (in/out of scope)
  - [ ] Test environment section complete
  - [ ] Requirements coverage matrix shows 100%
  - [ ] Test case inventory section complete
  - [ ] Test execution strategy documented
  - [ ] Pass/fail criteria defined
  - [ ] Ready for review and approval
  </checklist>

  <checklist name="Test Case Generation Validation">
  **After all test cases generated:**

  **Deployment Tests (4 Mandatory):**
  - [ ] Installation verification test created
  - [ ] Configuration verification test created
  - [ ] Dependencies verification test created
  - [ ] Service startup test created
  - [ ] All deployment tests follow template
  - [ ] All deployment tests trace to plan.md

  **Functionality Tests:**
  - [ ] One test per FR-XXX requirement (100% coverage)
  - [ ] Error handling tests created (2-3 minimum)
  - [ ] Edge case tests created (if applicable)
  - [ ] All functionality tests follow template
  - [ ] All functionality tests trace to spec.md

  **Integration Tests:**
  - [ ] One test per integration point (or N/A documented)
  - [ ] Connection tests included
  - [ ] Authentication tests included
  - [ ] Data exchange tests included
  - [ ] All integration tests follow template

  **Health Check Tests (3 Mandatory):**
  - [ ] Health endpoint test created
  - [ ] Resource usage test created
  - [ ] Error-free operation test created
  - [ ] All health check tests follow template
  - [ ] All health check tests verify operational readiness

  **General Quality:**
  - [ ] All test cases follow template structure
  - [ ] All test cases have clear pass/fail criteria
  - [ ] All test cases are independently executable
  - [ ] All test cases have concrete verification steps
  - [ ] Test file naming convention followed
  - [ ] Tests organized in correct directories
  </checklist>

  <checklist name="Test Suite Completeness Validation">
  **Before test suite approval:**

  **Coverage Validation:**
  - [ ] 100% functional requirements coverage
  - [ ] 100% success criteria coverage
  - [ ] 100% deployment steps coverage
  - [ ] 100% integration points coverage (or N/A)
  - [ ] Requirements coverage matrix complete

  **Test Count Validation:**
  - [ ] Minimum 4 deployment tests
  - [ ] Minimum functionality tests (one per FR)
  - [ ] Minimum 3 health check tests
  - [ ] Integration tests appropriate (one per integration or N/A)
  - [ ] Total test count reasonable (10-50 typical)

  **Documentation Validation:**
  - [ ] Test plan document complete
  - [ ] All test cases created
  - [ ] Test suite index created
  - [ ] Test execution tracking created
  - [ ] File organization correct

  **Quality Validation:**
  - [ ] All tests follow template structure
  - [ ] All tests have traceability
  - [ ] All tests have concrete pass/fail criteria
  - [ ] All tests independently executable
  - [ ] No test dependencies
  - [ ] Professional formatting and clarity

  **Approval Readiness:**
  - [ ] Test suite reviewed by Quality Assurance
  - [ ] Test suite reviewed by Deployment Lead
  - [ ] Test suite approved by CAIO
  - [ ] Ready for pre-deployment test execution
  </checklist>

  <checklist name="Test Execution Readiness Validation">
  **Before test execution begins:**

  **Pre-Deployment Test Execution:**
  - [ ] Test suite complete and approved
  - [ ] Test environment prepared
  - [ ] Test data available
  - [ ] Test execution tracking ready
  - [ ] Service NOT deployed yet (tests should fail)

  **Post-Deployment Test Execution:**
  - [ ] Deployment execution complete
  - [ ] Service running
  - [ ] Test environment updated
  - [ ] Test execution tracking ready
  - [ ] Ready to verify deployment success

  **Defect Management:**
  - [ ] Defect template available
  - [ ] Defect tracking process understood
  - [ ] Severity levels defined
  - [ ] Resolution process documented

  **Promotion Criteria:**
  - [ ] Promotion criteria documented
  - [ ] Promotion process understood
  - [ ] 100% pass rate required
  - [ ] Zero critical/high defects required
  </checklist>
</validation_checklists>

<related_documents>
**Workflows:**
- [Task Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-task-workflow.md) - Calls this command during testing phase
- [Charter Workflow](/home/agent0/HX-Infrastructure/.claude/commands/workflows/cc-charter-workflow.md) - Success criteria inform tests

**Phase Commands:**
- [Defect Management](/home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-defect-mgmt.md) - Handles test failures
- [Task Result Documentation](/home/agent0/HX-Infrastructure/.claude/commands/phases/cc-phase-task-result-doc.md) - Documents test results

**Templates:**
- [Test Case Template](/home/agent0/HX-Infrastructure/templates/test-case-template.md) - Individual test case structure
- [Test Plan Template](/home/agent0/HX-Infrastructure/templates/test-plan-template.md) - Test plan structure
- [Test Execution Template](/home/agent0/HX-Infrastructure/templates/test-execution-template.md) - Execution tracking

**Standards:**
- [Testing Requirements](/home/agent0/HX-Infrastructure/standards/testing-requirements.md) - Testing standards and requirements
- [Documentation Requirements](/home/agent0/HX-Infrastructure/standards/documentation-requirements.md) - Test documentation formatting

**Reference:**
- [Constitution](/home/agent0/HX-Infrastructure/constitution.md) - Quality principles and testing mandate
- [Deployment Requirements](/home/agent0/HX-Infrastructure/standards/deployment-requirements.md) - Deployment validation needs

**Utilities:**
- [Documentation Linting](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-doc-lint.md) - Validate test document quality
- [Artifact Tracking](/home/agent0/HX-Infrastructure/.claude/commands/utilities/cc-util-artifact-tracker.md) - Track test suite as artifacts
</related_documents>

---

<metadata_footer>
**Version:** 1.1
**Status:** APPROVED - Production Ready
**Compliance:** Gold Standard v1.1 - All 11 required elements present
**Integration:** Ready for task workflow testing phase execution
**State:** Stateless command generating stateful test artifacts
**Last Review:** 2025-11-20
**Update:** Standardized integration convention header for consistency with utilities and other phase commands
**Infrastructure Philosophy:** Aligns with HX-Infrastructure testing requirements (systemd tests, bare metal deployment tests, manual procedure verification documented in testing-requirements.md)
</metadata_footer>
