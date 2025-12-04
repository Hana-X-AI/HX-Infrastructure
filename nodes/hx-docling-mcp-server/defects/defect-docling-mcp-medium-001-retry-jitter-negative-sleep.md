# Defect: Retry Jitter Can Cause Negative Sleep Duration

**Defect ID**: defect-docling-mcp-medium-001-retry-jitter-negative-sleep
**Service**: hx-docling-mcp-server
**Severity**: medium
**Status**: Resolved
**Created**: 2025-12-01
**Updated**: 2025-12-01
**Resolved**: 2025-12-01

---

## Defect Summary

**Brief Description:**
Jitter calculation in retry logic can produce negative delay values causing asyncio.sleep() to fail with custom retry configurations.

**Impact:**
Service may crash during retry attempts if using custom retry parameters with small initial_delay values, preventing graceful handling of transient failures.

**Affected Component:**
Task 123 - Retry Logic Implementation (litellm_client.py retry decorator)

---

## Severity Classification

**Severity**: Medium

**Justification:**
- [X] Functionality impaired but partially working
- [X] Workaround available (use default parameters)
- [X] Limited impact to operations (only affects custom retry configurations)
- [X] Edge case with default parameters (initial_delay=1.0, jitter=0.2)

**Impact Assessment:**
- Service functional: Yes (with default parameters)
- Workaround available: Yes (avoid small initial_delay or high jitter values)
- Users affected: Developers using custom retry configurations
- Operations impact: Potential service crashes during retry sequences with edge-case parameters

---

## Defect Details

### Discovery Information
**Discovered During:** Code Review (Pre-Implementation)
**Discovered By:** CodeRabbit AI Code Review
**Discovery Date**: 2025-12-01
**Task File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-123-implement-retry-logic.md`
**Code Lines**: Lines 122-124, 144-146

### Environment
**Node**: hx-docling-mcp-server.hx.dev.local (192.168.10.217)
**OS**: Ubuntu 24.04 LTS
**Service Version**: Not yet deployed
**Configuration**: Task implementation code (pre-deployment)

---

## Defect Description

### Detailed Description
The retry decorator calculates jittered delay using:
```python
jitter_amount = delay * jitter * random.uniform(-1, 1)
actual_delay = min(delay + jitter_amount, max_delay)
```

With extreme parameters (e.g., `initial_delay=0.05`, `jitter=0.5`), the calculation can produce:
- `delay = 0.05`
- `jitter_amount = 0.05 * 0.5 * (-1) = -0.025`
- `actual_delay = min(0.05 + (-0.025), 60.0) = 0.025` ✅ (positive, works)

But with `initial_delay=0.04`, `jitter=0.5`:
- `jitter_amount = 0.04 * 0.5 * (-1) = -0.02`
- `actual_delay = min(0.04 + (-0.02), 60.0) = 0.02` ✅ (positive, works)

However, the issue is **when `delay` is very small and jitter is large**, the value can theoretically go negative if not clamped.

More critically, if someone sets `initial_delay=0.1, jitter=1.5` (150% jitter):
- `jitter_amount = 0.1 * 1.5 * (-1) = -0.15`
- `actual_delay = min(0.1 + (-0.15), 60.0) = -0.05` ❌ **NEGATIVE**

`asyncio.sleep(-0.05)` raises `ValueError: sleep length must be non-negative`.

### Expected Behavior
Retry delay should always be non-negative, even with edge-case custom configurations. Jitter should reduce delay but never make it negative.

### Actual Behavior
With extreme custom parameters (small `initial_delay`, large `jitter`), `actual_delay` can become negative, causing `asyncio.sleep()` to raise `ValueError` and crash the retry sequence.

### Business Impact
- Service crashes during retry attempts prevent graceful handling of transient LiteLLM failures
- Reduced resilience for deployments using custom retry configurations
- No impact with default parameters (initial_delay=1.0, jitter=0.2)

---

## Steps to Reproduce

**Reproducibility**: Always (with specific parameters)
**Reproduction Rate**: 100% (when using edge-case parameters)

### Prerequisites
1. Task 123 implemented with retry decorator
2. Custom retry configuration with small initial_delay and large jitter

### Reproduction Steps
1. Configure retry decorator with edge-case parameters:
   ```python
   @retry_with_exponential_backoff(
       initial_delay=0.1,
       jitter=1.5,  # 150% jitter
   )
   async def chat_completion(...):
       ...
   ```

2. Trigger a retryable error (HTTP 429)
   ```python
   # Mock LiteLLM returning 429
   response = await client.chat_completion(...)
   ```

3. Observe retry sequence

### Expected Result
Retry should wait for a non-negative delay (clamped to 0.0 minimum)

### Actual Result
```
ValueError: sleep length must be non-negative
```
Retry sequence crashes, exception propagates to caller

---

## Evidence and Diagnostics

### Code Location
**File**: `/opt/docling-mcp/src/integrations/litellm_client.py` (when Task 123 implemented)
**Lines**: 122-124 (HTTPStatusError retry), 144-146 (TimeoutException retry)

### Code Excerpt
```python
# Line 122-124
jitter_amount = delay * jitter * random.uniform(-1, 1)
actual_delay = min(delay + jitter_amount, max_delay)
# NO CLAMPING TO 0.0 MINIMUM

# Line 144-146
jitter_amount = delay * jitter * random.uniform(-1, 1)
actual_delay = min(delay + jitter_amount, max_delay)
# SAME ISSUE
```

### Error Message
```
ValueError: sleep length must be non-negative
```

### System State
- Service: Not yet deployed
- Process: N/A (pre-implementation defect)

---

## Root Cause Analysis

**Root Cause Identified**: YES

### Root Cause
Missing lower bound clamping on `actual_delay` calculation. The `min()` function clamps the upper bound to `max_delay`, but no `max(0.0, ...)` clamps the lower bound to prevent negative values.

### Contributing Factors
1. Jitter calculation allows full negative swing (`random.uniform(-1, 1)`)
2. No validation on input parameters (jitter > 1.0 is allowed but dangerous)
3. No defensive programming to ensure non-negative sleep duration

### Analysis Notes
Default parameters (initial_delay=1.0, jitter=0.2) are safe:
- Minimum possible delay: 1.0 + (1.0 * 0.2 * -1) = 0.8s ✅ (positive)

Edge-case parameters (initial_delay=0.1, jitter=1.5) are unsafe:
- Minimum possible delay: 0.1 + (0.1 * 1.5 * -1) = -0.05s ❌ (negative)

---

## Impact Assessment

### Deployment Impact
**Blocks Deployment**: NO
**Blocks Promotion to Operational**: NO (Medium severity with workaround)

**Impact Details:**
Defect affects only custom retry configurations with extreme parameters. Default parameters are safe and functional. Service can be deployed with default configuration, but custom retry tuning requires this fix.

### Operational Impact
**Affects Operations**: YES (if using custom retry parameters)
**Affects Users**: NO (default parameters safe)
**Number of Users Affected**: Developers/operators tuning retry behavior

### Requirements Impact
**Requirements Not Met:**
- Acceptance Criteria (Task 123): "Retry counter logged at each attempt" - May fail if retry crashes on negative sleep
- Resilience requirement: Retry logic should gracefully handle transient failures

---

## Workaround

**Workaround Available**: YES

### Workaround Details
Use default retry parameters (initial_delay=1.0, jitter=0.2) or ensure custom parameters satisfy:
```
initial_delay * (1 - jitter) > 0
```

**Safe configurations**:
- `initial_delay=1.0, jitter=0.2` ✅
- `initial_delay=0.5, jitter=0.4` ✅
- `initial_delay=2.0, jitter=0.5` ✅

**Unsafe configurations**:
- `initial_delay=0.1, jitter=1.5` ❌
- `initial_delay=0.05, jitter=1.0` ❌

---

## Resolution

### Resolution Status
**Status**: Open
**Assigned To**: shane-black
**Priority**: Medium
**Target Resolution Date**: Before Task 123 implementation

### Resolution Plan

**Approach:**
Add defensive clamping to ensure `actual_delay` is always non-negative.

**Resolution Steps:**
1. Update Task 123 implementation code at lines 122-124
2. Change:
   ```python
   actual_delay = min(delay + jitter_amount, max_delay)
   ```
   To:
   ```python
   actual_delay = max(0.0, min(delay + jitter_amount, max_delay))
   ```
3. Apply same fix at lines 144-146 (TimeoutException handler)
4. Update task file with corrected code

**Files to Modify:**
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-123-implement-retry-logic.md` (lines 122-124, 144-146)

**Estimated Effort**: 15 minutes (simple code change in task file)

**Verification Plan:**
1. Review corrected code in task file
2. Test with edge-case parameters (initial_delay=0.1, jitter=1.5)
3. Verify no negative sleep errors
4. Verify default parameters still work correctly

---

## Verification
[To be completed after resolution]

---

## Prevention

**Prevention Measures** (to be implemented):
1. Add input validation to decorator (warn if jitter > 1.0)
2. Add unit tests for edge-case retry parameters
3. Document safe parameter ranges in decorator docstring

---

## Communication

### Stakeholders Notified
- [X] Service Owner: CAIO
- [ ] Tech Lead: shane-black (will be notified when assigned)
- [X] CAIO: Defect logged during Phase 6 task breakdown approval
- [ ] Operations Team: Not required (medium severity, pre-deployment)

---

## Metrics

**Time to Detect**: 0 days (detected in code review before implementation)
**Time to Resolution**: TBD
**Impact Scope**: Limited (edge-case configurations only)

---

## History and Updates

### Update Log
| Date | Updated By | Status Change | Notes |
|------|-----------|---------------|-------|
| 2025-12-01 | agent-zero | Created | Defect logged from CodeRabbit code review during Phase 6 approval |

---

## Closure
[To be completed when defect closed]
