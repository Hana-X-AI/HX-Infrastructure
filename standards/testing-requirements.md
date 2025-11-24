---
document: testing-requirements
version: 2.1
date: 2025-11-21
status: APPROVED
type: operational-standard
description: Testing requirements and standards for all HX Infrastructure services including test types, coverage, execution, and promotion criteria
applies_to: all_services, test_driven_deployment, quality_assurance, service_promotion
author: HX-Infrastructure Team
location: /home/agent0/HX-Infrastructure/standards/testing-requirements.md
last_updated: 2025-11-21
update_notes: Added comprehensive metadata, infrastructure integration, procedure alignment, version history, document maintenance
---

# Testing Requirements Standards
## Comprehensive Testing Standards for HX-Infrastructure Services

**Document Type:** Standard - Testing & Quality Assurance (Test-Driven Deployment)
**Version:** 2.1
**Date:** 2025-11-21
**Status:** ✅ APPROVED - CRITICAL QUALITY GATE - Required for All Service Promotion
**Location:** `/home/agent0/HX-Infrastructure/standards/testing-requirements.md`
**Previous Version:** 2.0 → 2.1 (comprehensive metadata, infrastructure integration, procedure alignment)

---

## Document Purpose

This document establishes testing standards for HX-Infrastructure ensuring all services have comprehensive test suites meeting infrastructure-specific requirements before promotion to operational status. **100% test pass rate is MANDATORY for promotion. No exceptions.**

### Target Audience
- **Julia Santos (Testing & Quality Specialist):** PRIMARY OWNER for testing standards, test plan review, test execution validation
- **Agent Zero (CC):** STATEFUL orchestrator validating testing completeness across all 5 project lifecycle phases
- **All Service Developers:** Must create comprehensive test suites following these standards
- **William Chen (Infrastructure Specialist):** Infrastructure-specific test validation
- **CAIO:** Final testing validation before operational promotion

### Scope
- Deployment validation tests (installation, configuration, dependencies, startup)
- Functionality tests (requirements coverage, core capabilities, error handling)
- Integration tests (database, services, APIs, message queues)
- Health check tests (endpoint, resources, stability)
- Infrastructure-specific tests (systemd, bare metal, Ansible Vault, manual deployment)
- Test-driven deployment workflow enforcement

### Authority
**Mandatory for all service promotion to operational status.** 100% test pass rate required across ALL test types. No exceptions. Testing compliance validated throughout all 5 project lifecycle phases.

---

<metadata>
**Document:** Testing Requirements Standards
**Type:** Standards - Quality Assurance
**Version:** 2.1
**Status:** ✅ APPROVED - Required for All Services
**Created:** 2025-11-15
**Last Updated:** 2025-11-21
</metadata>

<objective>
**Purpose:** Establish testing standards for HX Infrastructure ensuring all services have comprehensive test suites meeting infrastructure-specific requirements before promotion to operational status.

**Scope:** All services in HX-Infrastructure including:
- Deployment validation tests (installation, configuration, dependencies, startup)
- Functionality tests (requirements coverage, core capabilities, error handling)
- Integration tests (database, services, APIs, message queues)
- Health check tests (endpoint, resources, stability)
- Infrastructure-specific tests (systemd, bare metal, Ansible Vault, manual deployment)

**Authority:** Mandatory for all service promotion to operational status. 100% test pass rate required. No exceptions.
</objective>

---

<testing_principles>

<core_testing_principles>
**From Constitution:**
> "All services must have passing test suites before operational status."

**Testing Principles:**
1. **Test-First**: Tests written before deployment execution
2. **Comprehensive**: All requirements have tests
3. **Automated**: Tests can be run repeatedly
4. **Documented**: All tests have clear documentation
5. **Traceable**: Tests linked to requirements
6. **Independent**: Tests don't depend on each other
7. **Repeatable**: Same test, same result
8. **Infrastructure-Aware**: Tests verify deployment philosophy compliance
</core_testing_principles>

<test_driven_deployment_workflow>
**Required Workflow:**

```
1. Write spec.md (requirements)
     ↓
2. Write plan.md (deployment strategy)
     ↓
3. Write test suite (all test cases)
     ↓
4. Run tests - MUST FAIL (service not deployed yet)
     ↓
5. Execute deployment (following plan.md)
     ↓
6. Run tests - MUST PASS
     ↓
7. All tests pass → Promote to operational
```

**No Shortcuts:**
- Cannot deploy without tests
- Cannot skip test creation
- Cannot promote with failing tests
</test_driven_deployment_workflow>

</testing_principles>

---

<required_test_types>

<deployment_validation_tests>
**Type:** MANDATORY
**Purpose:** Verify deployment executed correctly
**Location:** `services/[service]/tests/test-suite/deployment/`

**Required Test Cases:**

1. **Installation Verification**
   ```markdown
   tc-[service]-deployment-001-verify-installation.md

   Verifies:
   - Service binary/files installed in correct location
   - Correct version installed
   - File permissions correct
   ```

2. **Configuration Verification**
   ```markdown
   tc-[service]-deployment-002-verify-configuration.md

   Verifies:
   - Configuration files created
   - Configuration values correct
   - Environment variables set
   ```

3. **Dependencies Verification**
   ```markdown
   tc-[service]-deployment-003-verify-dependencies.md

   Verifies:
   - All dependencies installed
   - Correct dependency versions
   - Dependencies accessible
   ```

4. **Service Startup**
   ```markdown
   tc-[service]-deployment-004-service-starts.md

   Verifies:
   - Service starts without errors
   - Service running
   - Process ID exists
   ```

**Minimum:** 4 deployment validation tests
**All deployment tests must PASS before proceeding to functionality tests**
</deployment_validation_tests>

<functionality_tests>
**Type:** MANDATORY
**Purpose:** Verify service meets functional requirements
**Location:** `services/[service]/tests/test-suite/functionality/`

**Required Coverage:**

1. **One test per functional requirement (FR-XXX)**
   - Each FR-001, FR-002, etc. must have corresponding test
   - Test validates requirement is met
   - Test named: `tc-[service]-functionality-[###]-[description].md`

2. **Core Capabilities Testing**
   ```markdown
   Examples:
   - If service processes data: Test data processing
   - If service exposes API: Test API endpoints
   - If service stores data: Test data persistence
   - If service authenticates: Test authentication
   ```

3. **Error Handling Testing**
   ```markdown
   tc-[service]-functionality-[###]-error-handling.md

   Verifies:
   - Service handles invalid input gracefully
   - Appropriate error messages returned
   - Service remains stable after errors
   ```

**Minimum:** One test per functional requirement
**All functionality tests must PASS for operational promotion**
</functionality_tests>

<integration_tests>
**Type:** CONDITIONAL
**Purpose:** Verify service integrates with other systems
**Location:** `services/[service]/tests/test-suite/integration/`

**Required IF:**
- Service integrates with database → Test database connection
- Service integrates with other services → Test service communication
- Service uses external APIs → Test API integration
- Service uses message queue → Test message publishing/consuming

**Test Cases:**
```markdown
tc-[service]-integration-001-[system]-connection.md

Verifies:
- Connection to integrated system successful
- Authentication works
- Data can be exchanged
- Error scenarios handled
```

**If NO integrations:** Integration test directory not required, note in test-plan.md
</integration_tests>

<health_check_tests>
**Type:** MANDATORY
**Purpose:** Verify ongoing operational health
**Location:** `services/[service]/tests/test-suite/health-check/`

**Required Test Cases:**

1. **Health Endpoint**
   ```markdown
   tc-[service]-health-001-endpoint.md

   Verifies:
   - Health endpoint responds
   - Response time acceptable (< 2 seconds)
   - Status indicates healthy
   ```

2. **Resource Usage**
   ```markdown
   tc-[service]-health-002-resources.md

   Verifies:
   - CPU usage within limits
   - Memory usage within limits
   - Disk usage acceptable
   ```

3. **No Error Conditions**
   ```markdown
   tc-[service]-health-003-no-errors.md

   Verifies:
   - No errors in logs
   - No crash/restart events
   - Service stable
   ```

**Minimum:** 3 health check tests
**All health check tests must PASS for operational promotion**
</health_check_tests>

</required_test_types>

---

<infrastructure_specific_testing>
**HX-Infrastructure Testing Requirements:**

All service testing MUST reflect HX-Infrastructure deployment philosophy:

<bare_metal_deployment_tests>
**Bare Metal Deployment Validation Tests (Production/Staging):**

Required test cases beyond standard deployment tests:

**1. Systemd Service Tests (MANDATORY):**
```markdown
tc-[service]-deployment-005-systemd-unit-file.md

**Objective:** Verify systemd unit file created and configured correctly

**Test Steps:**
1. Verify unit file exists:
   ```bash
   test -f /etc/systemd/system/[service-name].service
   echo "Expected: Exit code 0"
   ```

2. Verify unit file syntax:
   ```bash
   systemd-analyze verify /etc/systemd/system/[service-name].service
   echo "Expected: No errors"
   ```

3. Verify service enabled:
   ```bash
   systemctl is-enabled [service-name]
   echo "Expected: enabled"
   ```

4. Verify service running:
   ```bash
   systemctl is-active [service-name]
   echo "Expected: active"
   ```

5. Verify service status:
   ```bash
   systemctl status [service-name]
   echo "Expected: active (running)"
   ```

**Pass Criteria:**
- Unit file exists at correct location
- Unit file syntax valid
- Service enabled for automatic start
- Service currently running
- Service status shows no errors
```

**2. Native Package Tests (MANDATORY for packaged services):**
```markdown
tc-[service]-deployment-006-native-package.md

**Objective:** Verify service installed as native Ubuntu package

**Test Steps:**
1. Verify package installed:
   ```bash
   dpkg -l | grep [service-package-name]
   echo "Expected: Package listed"
   ```

2. Verify package version:
   ```bash
   dpkg -s [service-package-name] | grep Version
   echo "Expected: [expected-version]"
   ```

3. Verify package files:
   ```bash
   dpkg -L [service-package-name]
   echo "Expected: All files listed"
   ```

**Pass Criteria:**
- Package installed via dpkg/apt
- Correct version installed
- All package files present
```

**3. Host Filesystem Tests (MANDATORY):**
```markdown
tc-[service]-deployment-007-filesystem-layout.md

**Objective:** Verify service files deployed to correct host filesystem locations

**Test Steps:**
1. Verify service directory:
   ```bash
   test -d /opt/[service-name]
   echo "Expected: Directory exists"
   ```

2. Verify service ownership:
   ```bash
   stat -c '%U:%G' /opt/[service-name]
   echo "Expected: [service-user]:[service-group]"
   ```

3. Verify configuration directory:
   ```bash
   test -d /etc/[service-name]
   echo "Expected: Directory exists"
   ```

4. Verify log directory:
   ```bash
   test -d /var/log/[service-name]
   echo "Expected: Directory exists"
   ```

**Pass Criteria:**
- Service files in /opt/[service-name] or appropriate location
- Correct ownership and permissions
- Configuration in /etc/[service-name]
- Logs in /var/log/[service-name] or systemd journal
```

**4. Resource Allocation Tests (MANDATORY):**
```markdown
tc-[service]-health-004-bare-metal-resources.md

**Objective:** Verify service uses host resources correctly (not container limits)

**Test Steps:**
1. Verify CPU usage:
   ```bash
   top -b -n 1 -p $(pgrep -f [service-name]) | tail -1 | awk '{print $9}'
   echo "Expected: < [cpu-limit]%"
   ```

2. Verify memory usage:
   ```bash
   ps -p $(pgrep -f [service-name]) -o rss | tail -1
   echo "Expected: < [memory-limit] KB"
   ```

3. Verify process running on host (not in container):
   ```bash
   cat /proc/$(pgrep -f [service-name])/cgroup | grep -v docker
   echo "Expected: No docker cgroup"
   ```

**Pass Criteria:**
- CPU usage within limits
- Memory usage within limits
- Process running directly on host (not in container)
```
</bare_metal_deployment_tests>

<docker_dev_environment_tests>
**Docker Development Environment Tests (Dev Server Only):**

**Required ONLY for services deployed on hx-dev-server (see inventory/nodes.md for host details):**

**1. Docker Container Tests:**
```markdown
tc-[service]-deployment-008-docker-container.md

**Objective:** Verify Docker container deployed correctly (DEV ONLY)

**Prerequisites:**
- Service designated for dev server deployment
- CAIO approval for Docker deployment documented in spec.md
- Deployment target: hx-dev-server (see inventory/nodes.md)

**Test Steps:**
1. Verify container running:
   ```bash
   docker ps | grep [service-name]
   echo "Expected: Container running"
   ```

2. Verify container on dev server only:
   ```bash
   hostname
   echo "Expected: hx-dev-server"
   ```

3. Verify container purpose documented:
   ```bash
   grep -i "docker.*dev.*isolation" /services/[service]/spec.md
   echo "Expected: Documentation found"
   ```

4. Verify production deployment documented:
   ```bash
   grep -i "production.*bare.*metal" /services/[service]/spec.md
   echo "Expected: Documentation found"
   ```

**Pass Criteria:**
- Container running on hx-dev-server ONLY
- Purpose: Development environment isolation (Python/React/Next.js)
- CAIO approval documented
- Production bare metal deployment documented
```

**2. Container Constraint Tests:**
```markdown
tc-[service]-deployment-009-docker-constraints.md

**Objective:** Verify Docker deployment constraints enforced

**Test Steps:**
1. Verify NOT deployed to production/staging:
   ```bash
   hostname | grep -v "production\|staging"
   echo "Expected: Not production/staging server"
   ```

2. Verify approval documented:
   ```bash
   grep "CAIO approval.*Docker" /services/[service]/spec.md
   echo "Expected: Approval found with date"
   ```

3. Verify project isolation purpose:
   ```bash
   grep "isolation\|Python\|React\|Next.js" /services/[service]/spec.md
   echo "Expected: Isolation purpose documented"
   ```

**Pass Criteria:**
- Docker ONLY on dev server
- Explicit CAIO approval with date
- Project isolation purpose clear
```
</docker_dev_environment_tests>

<ansible_vault_tests>
**Ansible Vault Secret Access Tests:**

**Required for all services using secrets:**

**1. Vault Access Test:**
```markdown
tc-[service]-deployment-010-vault-access.md

**Objective:** Verify service can access secrets from Ansible Vault

**Test Steps:**
1. Verify vault file exists:
   ```bash
   test -f services/[service]/vault/secrets.yml
   echo "Expected: Vault file exists"
   ```

2. Verify vault file encrypted:
   ```bash
   head -1 services/[service]/vault/secrets.yml | grep "ANSIBLE_VAULT"
   echo "Expected: File encrypted"
   ```

3. Verify vault can be decrypted:
   ```bash
   ansible-vault view services/[service]/vault/secrets.yml \
     --vault-password-file=/srv/ansible/.vault_password | head -1
   echo "Expected: Decrypted content visible"
   ```

4. Verify service loaded secrets correctly:
   ```bash
   # Check service logs for secret loading (without exposing values)
   grep "Secrets loaded" /var/log/[service]/[service].log
   echo "Expected: Secrets loaded successfully"
   ```

**Pass Criteria:**
- Vault file exists and encrypted
- ansible-vault command successful
- Service loaded secrets without errors
- NO plaintext secrets in logs or config files
```

**2. Vault Scope Test:**
```markdown
tc-[service]-deployment-011-ansible-scope.md

**Objective:** Verify Ansible Vault used correctly (vault ONLY, no playbooks)

**Test Steps:**
1. Verify NO Ansible playbooks in deployment:
   ```bash
   find /services/[service]/ -name "*.yml" -o -name "*.yaml" | \
     grep -v "vault" | xargs grep -l "ansible" | wc -l
   echo "Expected: 0 (no playbooks)"
   ```

2. Verify deployment uses manual procedures:
   ```bash
   test -f /services/[service]/tasks/[service]-task-001-*.md
   echo "Expected: Manual task files exist"
   ```

3. Verify vault password file accessible:
   ```bash
   test -f /srv/ansible/.vault_password
   echo "Expected: Vault password file exists"
   ```

**Pass Criteria:**
- NO Ansible playbooks used for deployment
- Manual task files present
- Ansible Vault ONLY component used
```
</ansible_vault_tests>

<manual_deployment_verification_tests>
**Manual Deployment Verification Tests:**

**All services MUST verify manual deployment execution:**

**1. Manual Procedure Execution Test:**
```markdown
tc-[service]-deployment-012-manual-execution.md

**Objective:** Verify deployment followed manual procedures (no automation)

**Test Steps:**
1. Verify task files executed:
   ```bash
   ls /services/[service]/tasks/[service]-task-*.md | wc -l
   echo "Expected: > 0 task files"
   ```

2. Verify task execution documented:
   ```bash
   ls /services/[service]/tests/test-results/*deployment* | wc -l
   echo "Expected: >= number of deployment tasks"
   ```

3. Verify NO automation artifacts:
   ```bash
   find /services/[service]/ -name "ansible-playbook*" -o \
     -name "terraform*" -o -name "*.auto.tfvars" | wc -l
   echo "Expected: 0 (no automation artifacts)"
   ```

4. Verify operator action documented:
   ```bash
   grep "Operator Action" /services/[service]/tasks/*.md | wc -l
   echo "Expected: > 0 operator actions documented"
   ```

**Pass Criteria:**
- All tasks documented as manual procedures
- No automation tools used (Ansible playbooks, Terraform, etc.)
- Operator actions clearly documented
- Step-by-step verification performed
```
</manual_deployment_verification_tests>

<configuration_file_tests>
**Configuration File Tests:**

**Required for all services with configuration:**

**1. Manual Configuration Test:**
```markdown
tc-[service]-deployment-013-manual-config.md

**Objective:** Verify configuration created manually from templates

**Test Steps:**
1. Verify config file exists:
   ```bash
   test -f /etc/[service]/[service].conf
   echo "Expected: Config file exists"
   ```

2. Verify config template exists:
   ```bash
   test -f /services/[service]/templates/[service].conf.template
   echo "Expected: Template exists"
   ```

3. Verify config values substituted:
   ```bash
   grep -v '\${' /etc/[service]/[service].conf
   echo "Expected: All variables substituted"
   ```

4. Verify config syntax valid:
   ```bash
   [service-name] --validate-config /etc/[service]/[service].conf
   echo "Expected: Configuration valid"
   ```

**Pass Criteria:**
- Configuration file created manually from template
- All template variables substituted
- Configuration syntax valid
- No automation-generated config
```
</configuration_file_tests>

<infrastructure_test_summary>
**Test Suite Impact:**

**Minimum Test Cases for HX-Infrastructure Services:**

| Service Type | Standard Min | + Infrastructure Tests | New Total |
|--------------|-------------|------------------------|-----------|
| Simple | 12 | +6 | 18 |
| Medium | 20 | +8 | 28 |
| Complex | 32 | +10 | 42 |

**Infrastructure Test Distribution:**
- Systemd service tests: 1-2 tests
- Native package/filesystem tests: 2-3 tests
- Resource allocation tests: 1 test
- Vault access tests: 1-2 tests
- Manual deployment verification: 1-2 tests
- Configuration tests: 1 test
- Docker constraint tests (if dev server): 2 tests
</infrastructure_test_summary>

</infrastructure_specific_testing>

---

<test_coverage_requirements>

<requirements_coverage>
**100% requirement coverage MANDATORY:**

| Requirement Type | Coverage Required |
|-----------------|-------------------|
| Functional Requirements (FR-XXX) | 100% - Every FR must have test |
| Success Criteria (SC-XXX) | 100% - Every SC must have test |
| Deployment Steps | 100% - All steps verified |
| Integrations | 100% - All integration points tested |
| Infrastructure Philosophy | 100% - All deployment constraints tested |

**Coverage Matrix Required:**

```markdown
# Requirements Coverage Matrix

| Requirement | Test Case(s) | Coverage |
|-------------|--------------|----------|
| FR-001 | tc-[service]-functionality-001 | ✅ |
| FR-002 | tc-[service]-functionality-002 | ✅ |
| FR-003 | tc-[service]-functionality-003, tc-[service]-functionality-004 | ✅ |
| SC-001 | tc-[service]-health-001 | ✅ |
| Infrastructure: Systemd | tc-[service]-deployment-005 | ✅ |
| Infrastructure: Bare Metal | tc-[service]-deployment-007, tc-[service]-health-004 | ✅ |
```

**Must be documented in:** `services/[service]/tests/test-plan.md`
</requirements_coverage>

<test_suite_size_guidance>
**Minimum Test Cases:**
- Simple service (single purpose): 18-25 tests (includes infrastructure)
- Medium service (multiple capabilities): 28-40 tests (includes infrastructure)
- Complex service (many integrations): 42-60 tests (includes infrastructure)

**Test Distribution:**
- Deployment: ~25-35% (includes infrastructure tests)
- Functionality: ~35-45%
- Integration: ~10-20% (if applicable)
- Health Check: ~10-20%
</test_suite_size_guidance>

</test_coverage_requirements>

---

<test_driven_deployment>

<test_creation_timeline>
**Tests MUST be written BEFORE deployment execution:**

```
Timeline:

Day 1-2: Write spec.md and plan.md
Day 3-4: Write ALL test cases (including infrastructure tests)
    ↓
    Test cases reviewed and approved
    ↓
Day 5: Run tests - ALL FAIL (expected)
Day 6-7: Execute deployment
Day 8: Run tests - ALL PASS (required)
    ↓
    If tests pass → Promotion eligible
    If tests fail → Log defects, fix, retest
```

**No Deployment Before Tests:**
- ❌ Cannot start deployment without complete test suite
- ❌ Cannot write tests during deployment
- ❌ Cannot write tests after deployment
</test_creation_timeline>

<test_validation_gates>
**Gate 1: Test Suite Completeness**
- [ ] All requirements have tests
- [ ] Infrastructure tests included
- [ ] Test cases follow template
- [ ] Test cases peer reviewed
- [ ] Test plan approved

**Gate 2: Pre-Deployment Test Execution**
- [ ] All tests execute successfully
- [ ] All tests FAIL (as expected - service not deployed)
- [ ] Test results documented

**Gate 3: Post-Deployment Test Execution**
- [ ] All tests execute successfully
- [ ] All deployment tests PASS (standard + infrastructure)
- [ ] All functionality tests PASS
- [ ] All integration tests PASS (if applicable)
- [ ] All health check tests PASS
- [ ] All infrastructure tests PASS
- [ ] Test results documented

**Gate 4: Promotion Criteria**
- [ ] 100% test pass rate
- [ ] No critical or high severity defects
- [ ] Infrastructure compliance verified
- [ ] Test execution documented
- [ ] Test results reviewed and approved
</test_validation_gates>

</test_driven_deployment>

---

<test_documentation>

<test_plan>
**Type:** MANDATORY
**Location:** `services/[service]/tests/test-plan.md`

**Required Content:**
- Test strategy and objectives
- Test scope (in/out of scope)
- Test environment details (bare metal/Docker)
- Requirements coverage matrix
- Infrastructure test coverage
- Test case list
- Test execution schedule
- Pass/fail criteria
- Defect management approach

**Template:** `templates/testing/test-plan-template.md`
</test_plan>

<test_cases>
**Type:** MANDATORY
**Location:** `services/[service]/tests/test-suite/[area]/tc-[service]-[area]-[###]-[description].md`

**Required Content:**
- Test objective
- Prerequisites
- Test steps (detailed, executable)
- Expected results
- Pass/fail criteria
- Actual results (filled during execution)

**Naming Convention:**
```
tc-[service]-[area]-[###]-[description].md

Where:
- [service] = service name
- [area] = deployment | functionality | integration | health-check
- [###] = 001, 002, 003... (sequential per area)
- [description] = brief description
```

**Template:** `templates/testing/test-case-template.md`
</test_cases>

<test_execution_results>
**Type:** MANDATORY
**Location:** `services/[service]/tests/test-results/`

**Naming Convention:**
```
[date]-tc-[service]-[area]-[###]-[result].md

Where:
- [date] = YYYY-MM-DD
- [result] = pass | fail | blocked
```

**Required Content:**
- Execution timestamp
- Executed by (name or agent)
- Test results (step-by-step)
- Evidence (logs, screenshots, output)
- Defects found (if any)

**Template:** `templates/testing/test-execution-template.md`
</test_execution_results>

<test_suite_index>
**Type:** MANDATORY
**Location:** `services/[service]/tests/test-suite-index.md`

**Purpose:** Master catalog of all test cases

**Required Content:**
- Complete test case list
- Requirements coverage matrix
- Infrastructure test coverage
- Test execution summary
- Defect summary
- Test automation status
- Service promotion readiness

**Template:** `templates/testing/test-suite-index-template.md`
</test_suite_index>

</test_documentation>

---

<test_execution>

<test_execution_process>
**Standard Execution Flow:**

1. **Pre-Execution**
   - Verify prerequisites met
   - Document environment state (bare metal/Docker)
   - Clear previous test results (if re-running)

2. **Execution**
   - Execute tests in order: Deployment → Functionality → Integration → Health Check
   - Include infrastructure tests in deployment/health phases
   - Document each step
   - Capture evidence (logs, screenshots, output)
   - Record actual results

3. **Post-Execution**
   - Compare actual vs expected results
   - Determine pass/fail
   - Log defects for failures
   - Document execution results
   - Update test suite index
</test_execution_process>

<test_execution_order>
**MUST execute in this order:**

```
1. Deployment Validation Tests (standard + infrastructure)
   ↓ (all must pass before proceeding)
2. Functionality Tests
   ↓ (all must pass before proceeding)
3. Integration Tests (if applicable)
   ↓ (all must pass before proceeding)
4. Health Check Tests (standard + infrastructure)
```

**If any test fails:**
- STOP execution
- Log defect
- Fix issue
- Re-run ALL tests from beginning
</test_execution_order>

<test_independence>
**Tests MUST be independent:**
- Each test can run standalone
- No shared state between tests
- Tests don't depend on execution order (within same area)
- Tests clean up after themselves

**Test Isolation:**
```markdown
## Test Cleanup (Required in every test case)

### Post-Test Actions
1. Remove test data created
2. Reset service state
3. Clean up temporary files
4. Return environment to original state
```
</test_independence>

</test_execution>

---

<defect_management>

<defect_logging_requirements>
**All test failures MUST result in defect:**

**Defect Location:** `defects/`
**Naming:** `defect-[service]-[severity]-[###]-[description].md`
**Template:** `templates/testing/defect-template.md`

**Severity Definitions:**
- **Critical:** Service completely non-functional, blocks all testing
- **High:** Major functionality broken, blocks operational promotion
- **Medium:** Functionality impaired, workaround available
- **Low:** Minor issue, does not block promotion with justification
</defect_logging_requirements>

<defect_impact_on_testing>
**Critical/High Defects:**
- MUST be resolved before continuing testing
- MUST be resolved before operational promotion
- Block service promotion

**Medium Defects:**
- Should be resolved before promotion
- May proceed with documented justification
- Do not automatically block promotion

**Low Defects:**
- Can be backlogged
- Do not block promotion
- Track for future resolution
</defect_impact_on_testing>

<retest_requirements>
**After defect resolution:**
- Re-run the failed test
- If test passes → Mark defect resolved
- If test fails → Defect remains open, investigate further

**Full Regression Testing:**
- Run ALL tests after ANY code change
- Ensures fix didn't break other functionality
- Required before promotion
</retest_requirements>

</defect_management>

---

<service_promotion_criteria>

<test_based_promotion_requirements>
**Service can be promoted to operational ONLY if:**

**General Test Requirements:**
- [ ] Test plan complete and approved
- [ ] All required test cases written
- [ ] All tests executed
- [ ] 100% test pass rate
- [ ] All deployment validation tests PASS
- [ ] All functionality tests PASS
- [ ] All integration tests PASS (if applicable)
- [ ] All health check tests PASS
- [ ] Test results documented in test-results/
- [ ] Test suite index updated
- [ ] No critical severity defects
- [ ] No high severity defects
- [ ] Medium/low defects justified if present
- [ ] Requirements coverage matrix shows 100%

**Infrastructure Test Requirements:**
- [ ] Systemd service tests PASS (unit file, enabled, running, status)
- [ ] Bare metal deployment tests PASS (package, filesystem, resources)
- [ ] Manual deployment verification PASS (no automation artifacts)
- [ ] Ansible Vault tests PASS (vault access, scope verification)
- [ ] Docker constraint tests PASS (if dev server deployment)
- [ ] Configuration file tests PASS (manual template-based creation)

**Final Approval:**
- [ ] Test execution reviewed and approved
- [ ] Infrastructure compliance verified
</test_based_promotion_requirements>

<promotion_process>
**Step 1: Verify Test Completion**
```bash
# Check all tests have execution results
ls services/[service]/tests/test-results/

# Verify all pass
grep -r "FAIL" services/[service]/tests/test-results/
# Should return no results
```

**Step 2: Verify No Blocking Defects**
```bash
# Check for critical/high defects
ls defects/ | grep "[service]-critical"
ls defects/ | grep "[service]-high"
# Should return no unresolved defects
```

**Step 3: Verify Infrastructure Compliance**
```bash
# Verify systemd test passed
grep "systemd.*PASS" services/[service]/tests/test-results/*

# Verify bare metal test passed
grep "bare.*metal.*PASS" services/[service]/tests/test-results/*

# Verify manual deployment test passed
grep "manual.*PASS" services/[service]/tests/test-results/*
```

**Step 4: Review Coverage**
- Review `tests/test-suite-index.md`
- Verify 100% requirements coverage
- Verify 100% infrastructure test coverage
- Verify all success criteria tested

**Step 5: Approve Promotion**
- Infrastructure team reviews test results
- Verifies infrastructure compliance
- Approves promotion to operational
- Service moved from non-operational/ to operational/
</promotion_process>

</service_promotion_criteria>

---

<test_quality_checklist>
**Before approving test suite:**

**General Test Quality:**
- [ ] All test cases use template
- [ ] All test cases have clear objectives
- [ ] All test steps are detailed and executable
- [ ] Expected results are specific and measurable
- [ ] Pass/fail criteria are unambiguous
- [ ] Prerequisites are documented
- [ ] Test cases are independent
- [ ] Test cases clean up after themselves
- [ ] Test cases follow naming conventions
- [ ] Test coverage is 100% for requirements
- [ ] Test plan is complete
- [ ] Test execution process documented

**Infrastructure Test Quality:**
- [ ] Systemd service tests included
- [ ] Bare metal deployment tests included
- [ ] Manual deployment verification tests included
- [ ] Ansible Vault tests included (if using secrets)
- [ ] Docker constraint tests included (if dev server)
- [ ] Configuration file tests included
- [ ] Infrastructure compliance verified
</test_quality_checklist>

---

<quick_reference>

**Minimum Tests by Service Type (Including Infrastructure):**

| Service Type | Min Deployment | Min Functionality | Min Integration | Min Health Check | Total Min |
|-------------|----------------|-------------------|-----------------|------------------|-----------|
| Simple | 10 | 5 | 0 | 3 | 18 |
| Medium | 12 | 10 | 3 | 3 | 28 |
| Complex | 14 | 15 | 8 | 5 | 42 |

**Test Execution Timeline:**

| Phase | Duration | Activities |
|-------|----------|------------|
| Test Creation | 2-4 days | Write all test cases (including infrastructure) |
| Pre-Deploy Test | 1 day | Run tests (should fail) |
| Deployment | 2-3 days | Execute deployment |
| Post-Deploy Test | 1-2 days | Run tests (should pass) |
| Defect Resolution | 1-5 days | Fix any failures |
| Retest | 1 day | Verify fixes |

**Pass/Fail Thresholds:**

| Test Area | Pass Threshold | Promotion Blocker? |
|-----------|---------------|-------------------|
| Deployment (Standard) | 100% | Yes |
| Deployment (Infrastructure) | 100% | Yes |
| Functionality | 100% | Yes |
| Integration | 100% | Yes |
| Health Check (Standard) | 100% | Yes |
| Health Check (Infrastructure) | 100% | Yes |
| Overall | 100% | Yes |

</quick_reference>

---

<critical_reminders>
1. ⚠️ **Tests Before Deployment:** ALL test cases MUST be written BEFORE deployment execution. No exceptions.

2. ⚠️ **100% Pass Rate Required:** ALL tests MUST pass before service promotion to operational/. Zero tolerance for failures.

3. ⚠️ **100% Requirements Coverage:** Every FR and SC MUST have corresponding test case. No untested requirements.

4. ⚠️ **Test Execution Order:** MUST execute in order: Deployment → Functionality → Integration → Health. Stop on first failure.

5. ⚠️ **Systemd Service Tests:** ALL services MUST verify systemd unit file, service enabled, service running, service status.

6. ⚠️ **Bare Metal Deployment Tests:** ALL production/staging services MUST verify native package installation, host filesystem layout, no container cgroups.

7. ⚠️ **Manual Deployment Verification:** ALL services MUST verify deployment followed manual procedures. NO automation artifacts allowed.

8. ⚠️ **Ansible Vault Tests:** Services using secrets MUST verify vault access. Confirm Ansible Vault ONLY (no playbooks).

9. ⚠️ **Docker Dev-Only Tests:** Services using Docker MUST verify dev server only, CAIO approval documented, production bare metal documented.

10. ⚠️ **Defect Blocking:** Critical/high defects MUST be resolved before promotion. No exceptions, no workarounds.
</critical_reminders>

---

<validation_checklist>
**Test Suite Validation (Before Promotion):**

**General Test Requirements:**
- [ ] Test plan complete and approved
- [ ] All test cases written before deployment
- [ ] All test cases use template format
- [ ] Test cases peer reviewed
- [ ] Requirements coverage matrix shows 100%

**Standard Test Coverage:**
- [ ] Minimum 4 deployment validation tests
- [ ] One functionality test per functional requirement
- [ ] Integration tests for all integration points (if applicable)
- [ ] Minimum 3 health check tests
- [ ] All test areas executed in correct order

**Infrastructure-Specific Test Coverage:**
- [ ] Systemd service tests executed (unit file, enabled, running, status)
- [ ] Bare metal deployment tests executed (native package, filesystem, resources)
- [ ] Manual deployment verification executed (no automation artifacts)
- [ ] Ansible Vault tests executed (vault access, scope verification)
- [ ] Docker constraint tests executed (if dev server deployment)
- [ ] Configuration file tests executed (manual creation from template)

**Test Execution Requirements:**
- [ ] All tests executed
- [ ] 100% test pass rate achieved
- [ ] Test results documented in test-results/
- [ ] Test suite index updated
- [ ] Evidence captured (logs, screenshots, output)

**Defect Management:**
- [ ] No critical severity defects
- [ ] No high severity defects
- [ ] Medium/low defects justified if present
- [ ] All defects documented in defects/

**Documentation:**
- [ ] Test plan complete
- [ ] All test cases documented
- [ ] All test results documented
- [ ] Requirements coverage matrix updated
- [ ] Infrastructure test coverage documented
- [ ] Test suite index complete

**Promotion Readiness:**
- [ ] Infrastructure lead approval
- [ ] QA approval
- [ ] All blocking issues resolved
- [ ] Infrastructure compliance verified
- [ ] Service ready for operational/
</validation_checklist>

---

## Infrastructure Philosophy Integration

Testing requirements align with HX-Infrastructure deployment philosophy:

### Infrastructure-Specific Testing MANDATORY

**From deployment-requirements.md (authoritative source):**
All service testing MUST verify infrastructure philosophy compliance:
- ✅ **Bare metal deployment:** Tests verify native package installation, host filesystem, no container cgroups
- ✅ **Systemd service management:** Tests verify systemd unit file, service enabled, service running, service status
- ✅ **Manual procedures:** Tests verify deployment followed manual procedures (no automation artifacts)
- ✅ **Ansible Vault only:** Tests verify vault access, Ansible Vault scope (no playbook artifacts)
- ✅ **Docker dev-only:** Tests verify Docker only on hx-dev-server (see inventory/nodes.md) with CAIO approval

### Test Categories and Infrastructure Philosophy

**Deployment Validation Tests (Standard):**
- Installation verification
- Configuration verification
- Dependencies verification
- Service startup

**Deployment Validation Tests (Infrastructure-Specific):**
- Systemd unit file tests (MANDATORY)
- Native package tests (MANDATORY for production/staging)
- Manual deployment verification (MANDATORY)
- Ansible Vault tests (MANDATORY if using secrets)
- Docker constraint tests (MANDATORY if using Docker)
- Configuration file tests (manual creation from template)

### Procedure Alignment

Testing requirements are enforced across all 5 project lifecycle phases:

**Phase 1 (Charter Creation):**
- Initial feasibility includes testing strategy discussion
- Testing effort estimated in project planning

**Phase 2 (Specification Development):**
- Functional requirements documented (FR-XXX)
- Success criteria documented (SC-XXX)
- Test coverage planned (one test per requirement)
- Infrastructure testing requirements identified

**Phase 3 (Task Breakdown & Planning):**
- **CRITICAL PHASE:** Test plan created following test-plan-template.md
- All test cases written BEFORE deployment execution
- Test cases include infrastructure-specific tests
- Test suite peer reviewed
- Julia Santos validates test completeness
- Agent Zero blocks Phase 4 until test suite complete

**Phase 4 (Deployment Execution):**
- Pre-deployment tests executed (MUST FAIL - service not deployed)
- Deployment tasks executed following manual procedures
- Post-deployment tests executed (MUST PASS - service deployed)
- Julia Santos validates test results
- Defects logged and resolved
- Re-testing after defect resolution

**Phase 5 (Project Closeout):**
- **CRITICAL GATE:** 100% test pass rate validated
- Infrastructure-specific tests validated by William Chen
- Test results reviewed by Julia Santos
- CAIO validates complete testing before operational promotion
- Testing compliance REQUIRED for promotion

### Infrastructure Testing Philosophy

**Tests Must Validate Philosophy, Not Assume It:**
- ❌ **Wrong:** "Service deployed via Docker" (assumption)
- ✅ **Correct:** "Verify service deployed bare metal (check cgroups, filesystem, systemd)"

**Tests Must Be Infrastructure-Aware:**
- Production/staging services: Verify bare metal deployment
- Dev server services: Verify Docker constraints and CAIO approval documented
- All services: Verify systemd service management
- All services: Verify manual deployment procedures followed
- All services with secrets: Verify Ansible Vault (no playbooks)

---

<related_documents>

### Standards
- **`/home/agent0/HX-Infrastructure/standards/deployment-requirements.md`** - Infrastructure philosophy AUTHORITATIVE source, deployment process
- **`/home/agent0/HX-Infrastructure/standards/documentation-requirements.md`** - Test documentation requirements
- **`/home/agent0/HX-Infrastructure/standards/architecture-standards.md`** - Architecture testing requirements
- **`/home/agent0/HX-Infrastructure/standards/naming-conventions.md`** - Test case naming conventions

### Procedures (Lifecycle Integration)
- **`/home/agent0/HX-Infrastructure/procedures/node-deployment-workflow.md`** - Phase 0: Testing strategy planning
- **`/home/agent0/HX-Infrastructure/procedures/spec-workflow.md`** - Phase 2: Requirements and success criteria definition
- **`/home/agent0/HX-Infrastructure/procedures/task-workflow.md`** - Phase 3: Test plan and test case creation (CRITICAL PHASE)
- **`/home/agent0/HX-Infrastructure/procedures/task-execution-workflow.md`** - Phase 4: Test execution (pre/post-deployment)
- **`/home/agent0/HX-Infrastructure/procedures/project-closeout-workflow.md`** - Phase 5: Final testing validation and promotion gate

### Templates
- **`/home/agent0/HX-Infrastructure/templates/testing/`** - All testing templates
- **`/home/agent0/HX-Infrastructure/templates/testing/test-plan-template.md`** - Test plan template
- **`/home/agent0/HX-Infrastructure/templates/testing/test-case-template.md`** - Test case template
- **`/home/agent0/HX-Infrastructure/templates/testing/test-results-template.md`** - Test results template

### Commands
- **`/cc-agent-zero-orchestrator`** - Validates testing completeness across all phases
- **`/cc-julia-testing-specialist`** - Testing standards PRIMARY OWNER, test plan and test execution validation
- **`/cc-william-infra-specialist`** - Infrastructure-specific test validation

### Governance Documents
- **`/home/agent0/HX-Infrastructure/constitution.md`** - Test-driven deployment principle authority

### Agent Profiles
- **Julia Santos (Testing & Quality Specialist):** PRIMARY OWNER for testing standards, test plan review, test execution validation
- **William Chen (Infrastructure Specialist):** Infrastructure-specific test validation
- **Agent Zero (CC):** STATEFUL orchestrator validating testing completeness across all 5 phases
- **CAIO:** Final testing validation before operational promotion

</related_documents>

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-15 | Initial testing requirements standard with comprehensive test types | 1236 lines | HX-Infrastructure Team |
| 2.0 | 2025-11-20 | Converted to semantic XML structure, added infrastructure-specific testing requirements | No line change | HX-Infrastructure Team |
| 2.1 | 2025-11-21 | Added comprehensive metadata, infrastructure philosophy integration (infrastructure-specific testing mandatory), procedure alignment, expanded related documents, version history, document maintenance | +165 lines (est.) | Agent Zero (CC) |

**Key Updates in v2.1:**
- Added comprehensive document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose section emphasizing CRITICAL QUALITY GATE
- Added Infrastructure Philosophy Integration section (infrastructure-specific testing MANDATORY)
- Added Test Categories and Infrastructure Philosophy section
- Added Procedure Alignment section (testing enforcement across all 5 phases, Phase 3 CRITICAL)
- Added Infrastructure Testing Philosophy section (tests validate philosophy, not assume it)
- Expanded related documents section with comprehensive standards, procedures, templates, commands, governance, agents
- Added version history table (this table)
- Added document maintenance section
- Maintained 100% backward compatibility with v2.0

**Backward Compatibility:** 100% - All v2.0 testing requirements unchanged, only infrastructure philosophy explicit documentation and metadata enhancements added

---

## Document Maintenance

### Update Triggers
This document should be updated when:
- New test types identified across multiple services
- Infrastructure philosophy testing requirements change
- Test-driven deployment workflow modified
- Test pass rate thresholds change (currently 100%, non-negotiable)
- New infrastructure testing patterns emerge
- Test tooling or automation changes
- Defect patterns indicate testing gaps

### Review Frequency
- **Quarterly Review:** Julia Santos reviews testing effectiveness, pass rates, defect patterns
- **Post-Promotion Review:** After operational promotions, review testing completeness and effectiveness
- **Post-Incident Review:** After operational incidents, review testing gaps
- **Annual Review:** Comprehensive review of all testing requirements and infrastructure testing standards

### Compliance Enforcement
- **Phase 2:** Agent Zero validates requirements and success criteria completeness
- **Phase 3:** Julia Santos validates test plan completeness, Agent Zero blocks Phase 4 until testing complete
- **Phase 4:** Julia Santos validates test execution and results, William Chen validates infrastructure tests
- **Phase 5:** CAIO validates 100% test pass rate before operational promotion
- **Blocking Issue:** Incomplete testing or failed tests PREVENT operational promotion

### Change Control
- Changes to test pass rate thresholds require CAIO approval (currently 100%, non-negotiable)
- Changes to infrastructure-specific tests require William Chen review
- Changes to test-driven deployment workflow require procedure updates
- All changes maintain 100% backward compatibility or include migration procedures for existing test suites
- Version increments: Minor for enhancements, Major for breaking changes (requires justification)

### Quality Assurance
- **Test Plan Reviews:** Julia Santos reviews all test plans during Phase 3
- **Test Execution Validation:** Julia Santos validates all test executions during Phase 4
- **Infrastructure Test Validation:** William Chen validates infrastructure-specific tests during Phase 4
- **Defect Pattern Analysis:** Quarterly analysis of defects to identify testing gaps
- **Test Coverage Audits:** Quarterly audit of requirements coverage across all services

---

<metadata_footer>
**Version:** 2.1
**Status:** APPROVED - Mandatory for All Service Testing
**Date:** 2025-11-21
**Last Updated:** 2025-11-21 (Comprehensive metadata, infrastructure integration, procedure alignment, version history)
**Compliance:** All services MUST meet these testing requirements before promotion to operational/. No exceptions.
**Next Steps:** Create test plan and test suite for service. Follow TDD workflow exactly. Ensure infrastructure-specific tests included.
**Review Cycle:** Quarterly review and update based on testing lessons learned
**Semantic XML Compliance:** Fully converted to semantic XML structure matching HX-Infrastructure documentation standards
**Infrastructure Philosophy:** Tests must verify bare metal deployment (production/staging), systemd service management, manual procedures, Ansible Vault only (no playbooks), Docker dev-only constraints, native package installation
</metadata_footer>
