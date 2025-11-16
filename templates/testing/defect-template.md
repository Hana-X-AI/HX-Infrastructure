# Defect: [BRIEF DESCRIPTION]

**Defect ID**: defect-[service]-[severity]-[seq]-[description]  
**Service**: [service-name]  
**Severity**: [critical | high | medium | low]  
**Status**: [Open | In Progress | Resolved | Closed | Deferred]  
**Created**: [DATE]  
**Updated**: [DATE]

---

## Defect Summary

**Brief Description:**
[One-sentence description of the defect]

**Impact:**
[Brief description of impact on service operation or deployment]

**Affected Component:**
[Which part of the service is affected - e.g., configuration, installation, functionality]

---

## Severity Classification

**Severity**: [critical | high | medium | low]

**Severity Justification:**

### Critical (selected if applies)
- [ ] Service completely non-functional
- [ ] Complete service failure
- [ ] Data loss or corruption
- [ ] Security breach or vulnerability
- [ ] System down

### High (selected if applies)
- [ ] Major functionality broken
- [ ] Significant impact to operations
- [ ] Workaround not available or difficult
- [ ] Multiple users/systems affected
- [ ] Service degradation

### Medium (selected if applies)
- [ ] Functionality impaired
- [ ] Workaround available
- [ ] Limited impact to operations
- [ ] Some users/systems affected
- [ ] Performance degradation

### Low (selected if applies)
- [ ] Minor issue
- [ ] Cosmetic problem
- [ ] Enhancement request
- [ ] Minimal impact to operations
- [ ] Single user affected

---

## Defect Details

### Discovery Information
**Discovered During**: [Testing | Deployment | Operations | Other]  
**Discovered By**: [Name or Agent]  
**Discovery Date**: [DATE]  
**Test Case** (if found during testing): `tc-[service]-[area]-[seq]-[description].md`  
**Test Execution** (if found during testing): `[date]-tc-[service]-[area]-[seq]-[result].md`

### Environment
**Node**: [node-name where defect observed]  
**OS**: [Operating system and version]  
**Service Version**: [version if applicable]  
**Configuration**: [relevant configuration details]

---

## Defect Description

### Detailed Description
[Comprehensive description of the defect - what is wrong, what was expected vs what happened]

### Expected Behavior
[What should happen / how the service should behave]

### Actual Behavior
[What actually happens / how the service actually behaves]

### Business Impact
[How this defect impacts the business, operations, or deployment timeline]

---

## Steps to Reproduce

**Reproducibility**: [Always | Sometimes | Once | Cannot Reproduce]  
**Reproduction Rate**: [e.g., 100%, 50%, one-time occurrence]

### Prerequisites
1. [Prerequisite 1]
2. [Prerequisite 2]
3. [Prerequisite 3]

### Reproduction Steps
1. [Step 1 to reproduce]
2. [Step 2 to reproduce]
3. [Step 3 to reproduce]
4. [Step 4 to reproduce]

### Result
[What happens when steps are followed]

---

## Evidence and Diagnostics

### Error Messages
```
[Exact error message(s)]
```

### Log Files
**Log Location**: [path to log file]

**Relevant Log Excerpts:**
```
[timestamp] [level] [message]
[timestamp] [level] [message]
[timestamp] [level] [message]
```

### Screenshots/Output
[Description of screenshot 1]: [path or embedded]
[Description of screenshot 2]: [path or embedded]

### Command Output
**Command Executed:**
```bash
[command that demonstrates the issue]
```

**Output:**
```
[actual output showing the defect]
```

### System State
**Process Status:**
```
[relevant process information]
```

**Resource Usage:**
```
[relevant resource information if applicable]
```

**Network Status:**
```
[relevant network information if applicable]
```

**Configuration:**
```
[relevant configuration that may contribute to defect]
```

---

## Root Cause Analysis

**Root Cause Identified**: [YES | NO | UNDER INVESTIGATION]

### Root Cause
[Detailed explanation of what is causing this defect]

### Contributing Factors
1. [Factor 1 - e.g., missing dependency]
2. [Factor 2 - e.g., incorrect configuration]
3. [Factor 3 - e.g., environment constraint]

### Analysis Notes
[Any additional analysis, investigation notes, or hypotheses]

---

## Impact Assessment

### Deployment Impact
**Blocks Deployment**: [YES | NO]  
**Blocks Promotion to Operational**: [YES | NO]

**Impact Details:**
[How this defect affects deployment or service promotion]

### Operational Impact
**Affects Operations**: [YES | NO]  
**Affects Users**: [YES | NO]  
**Number of Users Affected**: [number or "all"]

**Impact Details:**
[How this defect affects ongoing operations]

### Requirements Impact
**Requirements Not Met:**
- [FR-001]: [How requirement is not met]
- [SC-002]: [How success criteria is not met]

---

## Workaround

**Workaround Available**: [YES | NO]

### Workaround Description
[If workaround exists, describe how to work around the defect]

### Workaround Steps
1. [Workaround step 1]
2. [Workaround step 2]
3. [Workaround step 3]

### Workaround Limitations
[Any limitations or side effects of the workaround]

**No Workaround**:
[If no workaround, explain why and what blocking this causes]

---

## Resolution

### Resolution Status
**Status**: [Open | In Progress | Resolved | Closed | Deferred]  
**Assigned To**: [Name/Role]  
**Priority**: [Immediate | High | Medium | Low]  
**Target Resolution Date**: [DATE]

### Resolution Plan
[Describe the plan to resolve this defect]

**Resolution Steps:**
1. [Resolution step 1]
2. [Resolution step 2]
3. [Resolution step 3]

**Estimated Effort**: [time estimate]

### Resolution Implementation
**Resolved By**: [Name]  
**Resolution Date**: [DATE]  
**Resolution Time**: [actual time spent]

**What Was Changed:**
[Detailed description of changes made to resolve defect]

**Files Modified:**
- [file 1]: [what was changed]
- [file 2]: [what was changed]

**Configuration Changes:**
- [config 1]: [what was changed]
- [config 2]: [what was changed]

---

## Verification

### Verification Plan
**How Resolution Will Be Verified:**
1. [Verification step 1]
2. [Verification step 2]
3. [Verification step 3]

### Verification Results
**Verified By**: [Name]  
**Verification Date**: [DATE]  
**Verification Status**: [PASS | FAIL]

**Verification Notes:**
[Results of verification - was defect truly resolved?]

### Re-test Required
**Re-run Tests**: [YES | NO]

**Tests to Re-run:**
- `tc-[service]-[area]-[seq]-[description].md`
- `tc-[service]-[area]-[seq]-[description].md`

**Re-test Results:**
[Results of re-running affected tests]

---

## Prevention

### How to Prevent in Future
[Recommendations for preventing similar defects in future deployments]

**Process Improvements:**
- [Process improvement 1]
- [Process improvement 2]

**Documentation Updates:**
- [Documentation to update 1]
- [Documentation to update 2]

**Automation Opportunities:**
- [Automation idea 1]
- [Automation idea 2]

### Related Issues
**Similar Defects:**
- `defect-[service]-[severity]-[seq]-[description].md` - [Relationship]

**Related Test Cases:**
- `tc-[service]-[area]-[seq]-[description].md` - [Relationship]

---

## Communication

### Stakeholders Notified
- [ ] [Stakeholder 1]
- [ ] [Stakeholder 2]
- [ ] Infrastructure team
- [ ] Service owner

### Notification Date
**Initial Notification**: [DATE]  
**Resolution Notification**: [DATE]

### Communication Notes
[Any important communication about this defect]

---

## Metrics

**Defect Metrics:**
- Time to Detect: [time from deployment to discovery]
- Time to Report: [time from discovery to logging]
- Time to Resolve: [time from logging to resolution]
- Time to Verify: [time from resolution to verification]
- Total Lifecycle: [total time open to closed]

---

## History and Updates

### Update Log

| Date | Updated By | Status Change | Notes |
|------|-----------|---------------|-------|
| [DATE] | [Name] | Open → In Progress | [Note] |
| [DATE] | [Name] | In Progress → Resolved | [Note] |
| [DATE] | [Name] | Resolved → Closed | [Note] |

### Discussion Thread
**Comment 1** - [Date] - [Author]:
[Comment text]

**Comment 2** - [Date] - [Author]:
[Comment text]

---

## Closure

### Closure Criteria
- [ ] Root cause identified
- [ ] Resolution implemented
- [ ] Resolution verified
- [ ] Tests re-run and passing
- [ ] Documentation updated
- [ ] Stakeholders notified
- [ ] Prevention measures identified

### Closure Sign-off
**Closed By**: [Name]  
**Closure Date**: [DATE]  
**Closure Reason**: [Resolved | Duplicate | Not a Defect | Deferred | Won't Fix]

**Closure Notes:**
[Final notes on defect closure]

---

## Related Documentation

**Service Documentation:**
- `services/[operational|non-operational]/[service]/spec.md`
- `services/[operational|non-operational]/[service]/plan.md`

**Test Documentation:**
- Test case where defect found
- Test execution report
- Re-test results

**Configuration:**
- Configuration files affected
- Node specifications

---

## Attachments

**Additional Files:**
- [attachment 1]: [description and location]
- [attachment 2]: [description and location]

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
