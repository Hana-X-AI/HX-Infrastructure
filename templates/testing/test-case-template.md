# Test Case: [TEST DESCRIPTION]

**Test ID**: tc-[service]-[area]-[seq]-[description]  
**Service**: [service-name]  
**Test Area**: [deployment | functionality | integration | health-check]  
**Created**: [DATE]  
**Status**: Not Run  
**Priority**: [Critical | High | Medium | Low]

---

## Test Metadata

**Based on Spec**: [Reference to spec.md requirement - e.g., FR-001, SC-002]  
**Based on Plan**: [Reference to plan.md section - e.g., "Deployment Architecture", "Configuration Spec"]  
**Test Type**: [Automated | Manual | Semi-Automated]  
**Estimated Execution Time**: [e.g., 5 minutes]

---

## Test Objective

**What This Test Validates:**
[Clear statement of what this test is verifying - should trace back to a requirement in spec.md or implementation detail in plan.md]

**Why This Test Is Important:**
[Brief explanation of why this validation matters for service operation]

---

## Prerequisites

**Service State:**
- [ ] Service is [installed | configured | running | stopped]
- [ ] [Other required service state]

**Dependencies:**
- [ ] [Required dependency 1 - e.g., database service running]
- [ ] [Required dependency 2 - e.g., network connectivity established]
- [ ] [Required dependency 3 - e.g., test data loaded]

**Environment:**
- [ ] Test environment configured
- [ ] Test data/resources available
- [ ] Required tools/utilities available

**Permissions:**
- [ ] [Required access level - e.g., root access, service account]

---

## Test Setup

### Pre-Test Actions
1. [Action to prepare for test - e.g., "Verify service is stopped"]
2. [Action to prepare for test - e.g., "Clear logs"]
3. [Action to prepare for test - e.g., "Set environment variables"]

### Test Data
**Required Test Data:**
- [Data item 1 - e.g., "Sample configuration file"]
- [Data item 2 - e.g., "Test user credentials"]
- [Data item 3 - e.g., "Test input file"]

**Test Data Location:**
- [Where test data is stored or how to generate it]

---

## Test Steps

### Step 1: [Action Description]
**Action:**
```bash
[Exact command or action to perform]
```

**Expected Behavior:**
[What should happen during this step]

**How to Verify:**
[How to confirm expected behavior - e.g., check output, check logs, check file]

---

### Step 2: [Action Description]
**Action:**
```bash
[Exact command or action to perform]
```

**Expected Behavior:**
[What should happen during this step]

**How to Verify:**
[How to confirm expected behavior]

---

### Step 3: [Action Description]
**Action:**
```bash
[Exact command or action to perform]
```

**Expected Behavior:**
[What should happen during this step]

**How to Verify:**
[How to confirm expected behavior]

---

[Add additional steps as needed]

---

## Expected Results

### Primary Expected Results
- [ ] [Expected result 1 - specific, measurable, verifiable]
- [ ] [Expected result 2 - specific, measurable, verifiable]
- [ ] [Expected result 3 - specific, measurable, verifiable]

### Observable Indicators
**Logs:**
- [Expected log message or pattern]
- [Location of log file to check]

**Files:**
- [Expected file created/modified]
- [Expected file content/permissions]

**Process Status:**
- [Expected process state - e.g., running, stopped]
- [Expected resource usage]

**Network:**
- [Expected port status]
- [Expected network connections]

**System State:**
- [Expected system state change]

---

## Pass/Fail Criteria

### PASS Criteria
**Test PASSES if ALL of the following are true:**
1. [Specific pass condition 1]
2. [Specific pass condition 2]
3. [Specific pass condition 3]
4. No unexpected errors in logs
5. All expected results achieved

### FAIL Criteria
**Test FAILS if ANY of the following are true:**
1. [Specific fail condition 1]
2. [Specific fail condition 2]
3. [Specific fail condition 3]
4. Any expected result not achieved
5. Unexpected errors in logs

### BLOCKED Criteria
**Test is BLOCKED if:**
1. [Blocking condition 1 - e.g., prerequisite not met]
2. [Blocking condition 2 - e.g., dependency service unavailable]
3. Test cannot execute due to environment issues

---

## Actual Results

**Execution Date**: [DATE]  
**Executed By**: [Name]  
**Test Result**: [PASS | FAIL | BLOCKED]

### Actual Observations
[Record what actually happened during test execution]

**Step 1 Results:**
[What actually occurred]

**Step 2 Results:**
[What actually occurred]

**Step 3 Results:**
[What actually occurred]

### Evidence
**Screenshots/Logs:**
- [Link or path to evidence files]

**Command Output:**
```
[Paste actual command output here]
```

**Log Excerpts:**
```
[Paste relevant log entries here]
```

---

## Defects

**Defects Found:**
- [Link to defect: `defect-[service]-[severity]-[seq]-[description].md`]
- [Link to defect if multiple found]

**Defect Summary:**
[Brief description of defects found during this test]

---

## Test Cleanup

### Post-Test Actions
1. [Cleanup action 1 - e.g., "Stop service"]
2. [Cleanup action 2 - e.g., "Remove test data"]
3. [Cleanup action 3 - e.g., "Reset configuration"]

### Environment Reset
- [ ] Test environment returned to original state
- [ ] Test data removed
- [ ] Temporary files cleaned up

---

## Notes and Observations

### General Notes
[Any additional observations, edge cases discovered, or context]

### Recommendations
[Any recommendations for improving the test or the service based on test execution]

### Dependencies on Other Tests
[List any other test cases that must pass/fail before this test, or tests that depend on this one]

---

## Test History

| Execution Date | Executed By | Result | Notes |
|---------------|-------------|--------|-------|
| [DATE] | [Name] | [PASS/FAIL/BLOCKED] | [Brief note] |
| [DATE] | [Name] | [PASS/FAIL/BLOCKED] | [Brief note] |

---

## Automation Notes (if applicable)

**Automation Status**: [Not Automated | Partially Automated | Fully Automated]

**Automation Details:**
- [Script location if automated]
- [Automation framework used]
- [Integration with CI/CD]

**Manual Steps Required:**
- [Any steps that cannot be automated]

---

## Related Documentation

**Related Specifications:**
- `spec.md` - [Specific section reference]
- `plan.md` - [Specific section reference]

**Related Test Cases:**
- `tc-[service]-[area]-[seq]-[description].md` - [Relationship]
- `tc-[service]-[area]-[seq]-[description].md` - [Relationship]

**Related Defects:**
- `defect-[service]-[severity]-[seq]-[description].md`

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
