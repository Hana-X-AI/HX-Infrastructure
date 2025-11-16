# Test Execution Report: [TEST CASE ID]

**Test Result File**: [date]-[test-case-id]-[result].md  
**Execution Date**: [YYYY-MM-DD]  
**Execution Time**: [HH:MM:SS]  
**Test Case Reference**: `tc-[service]-[area]-[seq]-[description].md`  
**Result**: [PASS | FAIL | BLOCKED]

---

## Test Execution Summary

**Service**: [service-name]  
**Test Area**: [deployment | functionality | integration | health-check]  
**Executed By**: [Name or Agent identifier]  
**Test Environment**: [node-name, e.g., agent0]  
**Execution Duration**: [e.g., 3 minutes 45 seconds]

---

## Test Case Information

**Test ID**: tc-[service]-[area]-[seq]-[description]  
**Test Objective**: [Brief description from test case]  
**Requirements Validated**: [FR-001, SC-002, etc. from spec.md]  
**Priority**: [Critical | High | Medium | Low]

---

## Prerequisites Check

**Prerequisites Status**: [ALL MET | PARTIALLY MET | NOT MET]

- [x] [Prerequisite 1 - checked and met]
- [x] [Prerequisite 2 - checked and met]
- [ ] [Prerequisite 3 - NOT met - explain why if blocked]

**Prerequisite Issues:**
[If any prerequisites not met, explain impact on test execution]

---

## Execution Details

### Test Step Results

#### Step 1: [Step Description]
**Status**: [SUCCESS | FAILED | SKIPPED]  
**Timestamp**: [HH:MM:SS]

**Command Executed:**
```bash
[Actual command executed]
```

**Output:**
```
[Actual output from command]
```

**Expected vs Actual:**
- Expected: [What was expected]
- Actual: [What actually happened]
- **Match**: [YES | NO]

**Notes:**
[Any observations about this step]

---

#### Step 2: [Step Description]
**Status**: [SUCCESS | FAILED | SKIPPED]  
**Timestamp**: [HH:MM:SS]

**Command Executed:**
```bash
[Actual command executed]
```

**Output:**
```
[Actual output from command]
```

**Expected vs Actual:**
- Expected: [What was expected]
- Actual: [What actually happened]
- **Match**: [YES | NO]

**Notes:**
[Any observations about this step]

---

#### Step 3: [Step Description]
**Status**: [SUCCESS | FAILED | SKIPPED]  
**Timestamp**: [HH:MM:SS]

**Command Executed:**
```bash
[Actual command executed]
```

**Output:**
```
[Actual output from command]
```

**Expected vs Actual:**
- Expected: [What was expected]
- Actual: [What actually happened]
- **Match**: [YES | NO]

**Notes:**
[Any observations about this step]

---

[Add additional steps as needed]

---

## Expected Results Validation

### Expected Results Checklist

- [ ] [Expected result 1 - ACHIEVED | NOT ACHIEVED]
- [ ] [Expected result 2 - ACHIEVED | NOT ACHIEVED]
- [ ] [Expected result 3 - ACHIEVED | NOT ACHIEVED]
- [ ] No unexpected errors in logs - [YES | NO]
- [ ] All observable indicators present - [YES | NO]

### Results Summary

**Total Expected Results**: [X]  
**Results Achieved**: [Y]  
**Results Not Achieved**: [Z]  
**Achievement Rate**: [Y/X * 100]%

---

## Pass/Fail Analysis

### Pass Criteria Evaluation

**All Pass Criteria Met**: [YES | NO]

1. [Pass criterion 1] - [MET | NOT MET]
2. [Pass criterion 2] - [MET | NOT MET]
3. [Pass criterion 3] - [MET | NOT MET]

### Fail Criteria Evaluation

**Any Fail Criteria Triggered**: [YES | NO]

1. [Fail criterion 1] - [TRIGGERED | NOT TRIGGERED]
2. [Fail criterion 2] - [TRIGGERED | NOT TRIGGERED]
3. [Fail criterion 3] - [TRIGGERED | NOT TRIGGERED]

### Final Result Determination

**Result**: [PASS | FAIL | BLOCKED]

**Rationale:**
[Explain why this result was determined based on pass/fail criteria]

---

## Evidence and Artifacts

### Log Files
**Location**: [Path to log files]

**Relevant Log Excerpts:**
```
[Timestamp] [Log Level] [Message]
[Timestamp] [Log Level] [Message]
[Timestamp] [Log Level] [Message]
```

### Screenshots
- [Screenshot 1 description]: [Path or embedded image]
- [Screenshot 2 description]: [Path or embedded image]

### Configuration Files
**Files Checked:**
- [config file 1]: [Path] - [Status: correct/incorrect]
- [config file 2]: [Path] - [Status: correct/incorrect]

### System State
**Process Status:**
```
[Output from process check - e.g., ps, systemctl status]
```

**Resource Usage:**
```
[Output from resource check - e.g., free, df, top]
```

**Network Status:**
```
[Output from network check - e.g., netstat, ss, lsof]
```

---

## Defects Identified

**Defects Found**: [Number]

### Defect 1
**Defect ID**: defect-[service]-[severity]-[seq]-[description].md  
**Severity**: [critical | high | medium | low]  
**Summary**: [Brief description]  
**Impact on Test**: [How this affected test result]

### Defect 2
**Defect ID**: defect-[service]-[severity]-[seq]-[description].md  
**Severity**: [critical | high | medium | low]  
**Summary**: [Brief description]  
**Impact on Test**: [How this affected test result]

[Add additional defects as needed]

**No Defects**: [Check if no defects found]
- [x] Test passed with no issues

---

## Environment Information

### Node Details
**Node**: [node-name]  
**OS**: [OS and version]  
**Kernel**: [kernel version if relevant]  
**Uptime**: [system uptime]

### Service Details
**Service Version**: [version number]  
**Service Status**: [running | stopped | failed]  
**Service Config**: [config file version or hash]

### Network Details
**IP Address**: [IP]  
**Ports in Use**: [list of ports]  
**Network Connectivity**: [status of required connections]

### Resource Availability
**CPU Usage**: [percentage]  
**Memory Usage**: [used/total]  
**Disk Usage**: [used/total]  
**Load Average**: [1min, 5min, 15min]

---

## Deviations from Test Case

**Deviations Occurred**: [YES | NO]

### Deviation 1
**Description**: [What deviated from test case]  
**Reason**: [Why deviation occurred]  
**Impact**: [Impact on test validity]  
**Approved By**: [Who approved deviation]

### Deviation 2
[If multiple deviations]

**No Deviations**: [Check if test executed exactly as documented]
- [x] Test executed exactly as documented

---

## Observations and Notes

### Test Execution Notes
[Any observations during test execution - unexpected behavior, edge cases, performance observations]

### Environment Notes
[Any observations about the test environment - issues, configurations, peculiarities]

### Recommendations
**For Service:**
- [Recommendation for service improvement]
- [Recommendation for service improvement]

**For Test Case:**
- [Recommendation for test case improvement]
- [Recommendation for test case improvement]

**For Test Environment:**
- [Recommendation for environment improvement]

---

## Cleanup Status

**Cleanup Performed**: [YES | NO | PARTIAL]

**Cleanup Actions:**
- [x] [Cleanup action 1 - completed]
- [x] [Cleanup action 2 - completed]
- [ ] [Cleanup action 3 - not completed, reason: ...]

**Environment State After Cleanup:**
[Description of environment state after test completion]

---

## Repeatability

**Test is Repeatable**: [YES | NO]

**Repeatability Notes:**
[Can this test be run again with same results? Any dependencies on previous state?]

**Prerequisites for Re-execution:**
[What needs to be done to run this test again]

---

## Follow-up Actions

**Actions Required**: [YES | NO]

### Action Items
- [ ] [Action 1 - e.g., "Log defect for configuration issue"]
- [ ] [Action 2 - e.g., "Update test case documentation"]
- [ ] [Action 3 - e.g., "Re-run test after fix"]

**Assigned To**: [Name/Role]  
**Due Date**: [DATE]

---

## Sign-off

**Test Executed By**: [Name]  
**Signature**: [Signature]  
**Date**: [DATE]

**Reviewed By**: [Name]  
**Signature**: [Signature]  
**Date**: [DATE]

---

## Metrics

**Test Execution Metrics:**
- Planned Duration: [time]
- Actual Duration: [time]
- Variance: [difference]
- Steps Planned: [X]
- Steps Executed: [Y]
- Steps Skipped: [Z]
- Defects Found: [number]

---

## Related Documentation

**Test Case**: `tests/test-suite/[area]/tc-[service]-[area]-[seq]-[description].md`  
**Defects**: [Links to any defects logged]  
**Previous Executions**: [Links to previous execution results if re-run]

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
