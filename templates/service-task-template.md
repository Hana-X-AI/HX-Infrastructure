# Deployment Tasks: [SERVICE NAME]

**Input**: Deployment documents from `/services/non-operational/[service-name]/`
**Prerequisites**: plan.md (required), deployment-research.md, deployment-architecture.md, configuration-spec.md

## Execution Flow (main)
```
1. Load plan.md from service directory
   → If not found: ERROR "No deployment plan found"
   → Extract: technology, target node, deployment strategy
2. Load design documents:
   → deployment-architecture.md: Extract components → deployment tasks
   → configuration-spec.md: Extract configs → configuration tasks
   → tests/test-plan.md: Extract test requirements → test tasks
3. Generate tasks by category:
   → Pre-Deployment: backups, verification, preparation
   → Installation: dependencies, service installation, configuration
   → Test Creation: write all test cases (TDD approach)
   → Verification: execute test suite
   → Post-Deployment: documentation, inventory updates
4. Apply task rules:
   → Independent tasks = mark [P] for parallel
   → Dependent tasks = sequential (no [P])
   → Test creation before verification (TDD)
5. Number tasks sequentially ([service]-task-001, -002...)
6. Generate dependency graph
7. Validate task completeness:
   → All test cases have creation tasks?
   → All configurations have tasks?
   → All components have installation tasks?
8. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (independent tasks, no dependencies)
- Include exact file paths and specific details
- Each task file: `[service]-task-###-<description>.md`

## Task File Location
**All task files stored in**: `services/non-operational/[service-name]/tasks/`

Example: `services/non-operational/api-gateway/tasks/api-gateway-task-001-verify-node-capacity.md`

## Phase 3.1: Pre-Deployment Preparation
- [ ] [service]-task-001 Verify target node capacity and compatibility
- [ ] [service]-task-002 [P] Backup existing configurations (if applicable)
- [ ] [service]-task-003 [P] Download installation packages/images
- [ ] [service]-task-004 [P] Verify network connectivity and ports available
- [ ] [service]-task-005 Document pre-deployment node state

## Phase 3.2: Installation & Configuration
- [ ] [service]-task-006 Install system dependencies (OS packages, libraries)
- [ ] [service]-task-007 Install [service] software/binary
- [ ] [service]-task-008 Create service directories and set permissions
- [ ] [service]-task-009 [P] Create configuration files from templates
- [ ] [service]-task-010 [P] Configure environment variables
- [ ] [service]-task-011 [P] Set up logging configuration
- [ ] [service]-task-012 Configure service startup (systemd/init/docker)
- [ ] [service]-task-013 Apply security configurations
- [ ] [service]-task-014 [P] Configure firewall rules (if needed)

## Phase 3.3: Test Creation (TDD) ⚠️ MUST COMPLETE BEFORE 3.4
**CRITICAL: These tests MUST be written and initially FAIL before running verification**

### Deployment Validation Tests
- [ ] [service]-task-015 [P] Write test: Verify service installation in tests/test-suite/deployment/tc-[service]-deployment-001-verify-installation.md
- [ ] [service]-task-016 [P] Write test: Verify configuration applied in tests/test-suite/deployment/tc-[service]-deployment-002-verify-config.md
- [ ] [service]-task-017 [P] Write test: Verify dependencies installed in tests/test-suite/deployment/tc-[service]-deployment-003-verify-dependencies.md
- [ ] [service]-task-018 [P] Write test: Verify service starts in tests/test-suite/deployment/tc-[service]-deployment-004-service-starts.md

### Functionality Tests
- [ ] [service]-task-019 [P] Write test: Core functionality test 1 in tests/test-suite/functionality/tc-[service]-functionality-001-*.md
- [ ] [service]-task-020 [P] Write test: Core functionality test 2 in tests/test-suite/functionality/tc-[service]-functionality-002-*.md
- [ ] [service]-task-021 [P] Write test: Error handling test in tests/test-suite/functionality/tc-[service]-functionality-003-error-handling.md

### Integration Tests (if applicable)
- [ ] [service]-task-022 [P] Write test: Service integration test 1 in tests/test-suite/integration/tc-[service]-integration-001-*.md
- [ ] [service]-task-023 [P] Write test: Service integration test 2 in tests/test-suite/integration/tc-[service]-integration-002-*.md

### Health Check Tests
- [ ] [service]-task-024 [P] Write test: Health endpoint check in tests/test-suite/health-check/tc-[service]-health-001-endpoint.md
- [ ] [service]-task-025 [P] Write test: Resource usage check in tests/test-suite/health-check/tc-[service]-health-002-resources.md

## Phase 3.4: Service Verification (ONLY after tests are written and failing)
- [ ] [service]-task-026 Run all deployment validation tests
- [ ] [service]-task-027 Run all functionality tests
- [ ] [service]-task-028 Run all integration tests (if applicable)
- [ ] [service]-task-029 Run all health check tests
- [ ] [service]-task-030 Document all test results with timestamps

## Phase 3.5: Post-Deployment & Documentation
- [ ] [service]-task-031 Update inventory/services.md with service entry
- [ ] [service]-task-032 Update nodes/[node]/services-deployed.md
- [ ] [service]-task-033 Update inventory/nodes.md with resource changes
- [ ] [service]-task-034 [P] Update network/topology.md (if network changes)
- [ ] [service]-task-035 [P] Update network/port-mapping.md (if port changes)
- [ ] [service]-task-036 [P] Document deployment issues/learnings
- [ ] [service]-task-037 Create service monitoring dashboard/alerts (if applicable)
- [ ] [service]-task-038 Verify rollback procedure works

## Phase 3.6: Promotion to Operational (After ALL tests pass)
- [ ] [service]-task-039 Verify all success criteria from spec.md met
- [ ] [service]-task-040 Verify no critical or high severity defects
- [ ] [service]-task-041 Move service from non-operational/ to operational/
- [ ] [service]-task-042 Update service status to OPERATIONAL

## Dependencies
**Critical Path**:
- Pre-deployment (001-005) → Installation (006-014) → Test Creation (015-025) → Verification (026-030) → Post-deployment (031-038) → Promotion (039-042)

**Specific Dependencies**:
- Task 006 blocks Task 007 (system deps before service)
- Task 007 blocks Task 008-014 (service installed before config)
- Tasks 015-025 block Task 026-030 (tests written before execution)
- Task 026-030 block Task 039-042 (verification before promotion)
- Task 009 requires Task 008 (directories before config files)

**Parallel Execution Groups**:
- Tasks 002, 003, 004 can run in parallel (independent preparation)
- Tasks 009, 010, 011, 014 can run in parallel (different config files)
- Tasks 015-025 can run in parallel (independent test creation)
- Tasks 031, 034, 035, 036 can run in parallel (independent documentation)

## Parallel Execution Example
```
# Launch tasks 015-018 together (deployment test creation):
Task: "Write deployment validation test 1"
Task: "Write deployment validation test 2"
Task: "Write deployment validation test 3"
Task: "Write deployment validation test 4"

# Launch tasks 019-021 together (functionality test creation):
Task: "Write functionality test 1"
Task: "Write functionality test 2"
Task: "Write error handling test"
```

## Task File Template Reference
Each task file should follow this structure:
```markdown
# Task: [Brief Description]

**Task ID**: [service]-task-###-[description]
**Phase**: [Pre-Deployment|Installation|Test Creation|Verification|Post-Deployment|Promotion]
**Status**: Not Started
**Dependencies**: [List task IDs this depends on]
**Estimated Time**: [time estimate]

## Objective
[What this task accomplishes]

## Prerequisites
- [ ] [Required condition 1]
- [ ] [Required condition 2]

## Steps
1. [Detailed step 1]
2. [Detailed step 2]
3. [Detailed step 3]

## Verification
- [ ] [How to verify task completed successfully]

## Rollback
[How to undo this task if needed]

## Notes
[Any additional context or considerations]
```

## Test Case Template Reference
Each test case file should follow this structure:
```markdown
# Test Case: [Test Description]

**Test ID**: tc-[service]-[area]-###-[description]
**Test Area**: [deployment|functionality|integration|health-check]
**Status**: Not Run
**Based on Spec**: [Reference to spec.md requirement]
**Based on Plan**: [Reference to plan.md section]

## Test Objective
[What this test validates]

## Prerequisites
- [ ] [Service installed]
- [ ] [Configuration applied]
- [ ] [Dependencies available]

## Test Steps
1. [Test step 1]
2. [Test step 2]
3. [Test step 3]

## Expected Results
- [ ] [Expected outcome 1]
- [ ] [Expected outcome 2]

## Actual Results
[To be filled during test execution]

## Pass/Fail Criteria
**PASS**: [Conditions for pass]
**FAIL**: [Conditions for fail]

## Notes
[Any additional context]
```

## Task Generation Rules
*Applied during main() execution*

1. **From Deployment Architecture**:
   - Each component → installation task
   - Each configuration → configuration task
   - Network changes → firewall/network tasks
   
2. **From Configuration Spec**:
   - Each config file → configuration task [P]
   - Each environment variable → task (may combine)
   - Secrets → secure configuration tasks
   
3. **From Test Plan**:
   - Each test case → test creation task [P]
   - Test execution → verification tasks
   
4. **From Inventory**:
   - Each inventory update → documentation task [P]

5. **Ordering**:
   - Pre-deployment → Installation → Test Creation → Verification → Post-deployment → Promotion
   - Dependencies block parallel execution
   - All tests created before any verification runs

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All components from architecture have installation tasks
- [ ] All configurations have configuration tasks
- [ ] All test cases have creation tasks
- [ ] Test creation comes before verification
- [ ] Parallel tasks are truly independent
- [ ] Each task specifies exact deliverable
- [ ] Dependencies are explicitly documented
- [ ] Rollback considerations included
- [ ] Inventory updates included
- [ ] Service promotion criteria clear

## Notes
- [P] tasks = independent, can run concurrently
- Verify tests fail initially (TDD approach)
- Document issues in defects/ directory with proper naming
- Commit/track after each task completion
- Update task files with actual results

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git  
*Based on HX Infrastructure Constitution v1.0 - See `/constitution.md`*
