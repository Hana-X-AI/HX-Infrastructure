# Defect: JSON Parsing Failures Should Trigger Fallback

**Defect ID**: defect-docling-mcp-medium-006-json-parse-no-fallback
**Service**: hx-docling-mcp-server
**Severity**: medium
**Status**: Resolved
**Created**: 2025-12-01
**Updated**: 2025-12-01
**Resolved**: 2025-12-01

---

## Defect Summary

**Brief Description:**
JSON parsing failures in `_parse_entity_response` (line 384) return silent failure (`success=False`) instead of triggering the fallback mechanism. This is inconsistent with documented fallback behavior (lines 565-569) which lists "Invalid JSON response" as a fallback trigger.

**Impact:**
When primary model returns invalid JSON, the system returns failure instead of attempting fallback model. This reduces service resilience and contradicts documented fallback strategy.

**Affected Component:**
Task 122 - Configure LiteLLM Model Routing Strategy (lines 384-392: JSON error handling, lines 565-569: fallback documentation)

---

## Severity Classification

**Severity**: Medium

**Justification:**
- [X] Functionality impaired but partially working
- [X] Inconsistent with documented behavior (fallback strategy)
- [X] Reduces service resilience (no fallback on JSON errors)
- [X] Workaround available (re-call with different model manually)

**Impact Assessment:**
- Service functional: Partially (returns failure instead of attempting fallback)
- Workaround available: Yes (caller can retry with fallback model)
- Users affected: All users when primary model returns malformed JSON
- Operations impact: Reduced resilience - single model failure causes complete failure instead of fallback attempt

---

## Defect Details

### Discovery Information
**Discovered During:** Code Review (Pre-Implementation)
**Discovered By:** CodeRabbit AI Code Review
**Discovery Date**: 2025-12-01
**Task File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-122-configure-model-routing.md`
**Code Lines**: Lines 384-392 (JSON error handling), lines 565-569 (fallback documentation)

### Environment
**Node**: hx-docling-mcp-server.hx.dev.local (192.168.10.217)
**OS**: Ubuntu 24.04 LTS
**Service Version**: Not yet deployed
**Configuration**: Task implementation code (pre-deployment)

---

## Defect Description

### Detailed Description
The current implementation has inconsistent error handling for different failure types:

**LLM Call Errors (HTTP 503, timeout, etc.):**
```python
# In extract_entities method (not shown in excerpt)
try:
    response = await self.litellm_client.chat_completion(...)
    result = self._parse_entity_response(response, model)
except (HTTPError, TimeoutException) as e:
    # TRIGGERS FALLBACK ✓
    logger.warning(f"Entity extraction failed with {model}: {str(e)}")
    if fallback_model:
        # Try fallback model
```

**JSON Parsing Errors (line 384):**
```python
# In _parse_entity_response method
except json.JSONDecodeError as e:
    logger.error(f"Failed to parse entity extraction response: {str(e)}")
    return {
        "entities": [],
        "model": model,
        "tokens_used": response.usage["total_tokens"],
        "success": False,
        "error": "Invalid JSON response",  # RETURNS FAILURE, NO FALLBACK ✗
    }
```

**Documented Fallback Behavior (lines 565-569):**
```markdown
### Fallback Behavior

**Trigger Conditions**:
- HTTP 503 (model unavailable)
- HTTP 408 (timeout)
- Connection errors
- Invalid JSON response  # ← DOCUMENTED BUT NOT IMPLEMENTED
```

**Inconsistency:**
- Documentation states "Invalid JSON response" triggers fallback
- Implementation returns silent failure without triggering fallback
- This violates principle of least surprise and reduces service resilience

### Expected Behavior
JSON parsing failures should propagate exception to outer exception handler, triggering fallback mechanism:

```python
except json.JSONDecodeError as e:
    logger.error(f"Failed to parse entity extraction response: {str(e)}")
    raise ValueError(f"Invalid JSON response from model {model}: {str(e)}")
```

This propagates error to `extract_entities` exception handler, which triggers fallback as documented.

### Actual Behavior
JSON parsing failures return `success=False` dict without triggering fallback, causing complete failure when primary model returns invalid JSON.

### Business Impact
- Reduced service resilience (single model failure causes total failure)
- Inconsistent behavior between failure types (HTTP errors trigger fallback, JSON errors don't)
- Contradicts documented fallback strategy
- Users experience failures that could be avoided with fallback

---

## Steps to Reproduce

**Reproducibility**: Always (with invalid JSON response)
**Reproduction Rate**: 100%

### Prerequisites
1. Task 122 implemented with current error handling
2. Primary model configured to return invalid JSON (simulate via mock)

### Reproduction Steps
1. Configure model router with primary and fallback models:
   ```python
   router = ModelRouter(litellm_client=client)
   ```

2. Call entity extraction with mock response returning invalid JSON:
   ```python
   # Simulate primary model returning invalid JSON
   mock_response = {
       "choices": [{"message": {"content": "NOT VALID JSON"}}],
       "usage": {"total_tokens": 100}
   }

   result = router._parse_entity_response(mock_response, "gemma3:27b")
   ```

3. Observe result:
   ```python
   # Current behavior: Returns failure dict
   assert result["success"] == False
   assert result["error"] == "Invalid JSON response"
   # Fallback model NOT attempted
   ```

### Expected Result
Exception raised, propagates to `extract_entities` exception handler, fallback model attempted.

### Actual Result
Returns `{"success": False, "error": "Invalid JSON response"}` without attempting fallback.

---

## Evidence and Diagnostics

### Code Location
**File**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-122-configure-model-routing.md`
**Lines**: 384-392 (error handling), 565-569 (fallback documentation)

### Code Excerpt

**Current Implementation (INCORRECT):**
```python
# Lines 384-392
except json.JSONDecodeError as e:
    logger.error(f"Failed to parse entity extraction response: {str(e)}")
    return {
        "entities": [],
        "model": model,
        "tokens_used": response.usage["total_tokens"],
        "success": False,  # SILENT FAILURE - NO FALLBACK
        "error": "Invalid JSON response",
    }
```

**Documented Fallback Triggers (lines 565-569):**
```markdown
**Trigger Conditions**:
- HTTP 503 (model unavailable)
- HTTP 408 (timeout)
- Connection errors
- Invalid JSON response  # ← SAYS JSON ERRORS TRIGGER FALLBACK
```

**Correct Implementation:**
```python
# Lines 384-392
except json.JSONDecodeError as e:
    logger.error(f"Failed to parse entity extraction response: {str(e)}")
    raise ValueError(f"Invalid JSON response from model {model}: {str(e)}")
    # Propagates to extract_entities exception handler → triggers fallback
```

### Root Cause Evidence
The `_parse_entity_response` method is a helper that parses already-received responses. It doesn't have access to fallback logic (which lives in `extract_entities` caller). By returning `success=False` dict instead of raising exception, it prevents outer exception handler from triggering fallback.

---

## Root Cause Analysis

**Root Cause Identified**: YES

### Root Cause
Error handling architecture inconsistency. HTTP errors (503, timeout) are raised as exceptions (triggering fallback), but JSON parsing errors are caught and returned as `success=False` dict (preventing fallback).

### Contributing Factors
1. **Separation of concerns**: `_parse_entity_response` doesn't know about fallback strategy (lives in `extract_entities`)
2. **Inconsistent error signaling**: Some errors use exceptions, others use return values
3. **Documentation-implementation gap**: Documentation lists JSON errors as fallback trigger, but implementation doesn't propagate them

### Analysis Notes
This is an architectural decision about how to signal errors:
- **Exception pattern**: Errors propagate up call stack, allowing caller to handle with fallback logic
- **Return value pattern**: Errors captured in return dict, caller must check `success` field

Current implementation mixes both patterns inconsistently. HTTP errors use exception pattern (correct for fallback). JSON errors use return value pattern (incorrect - prevents fallback).

**Recommendation**: Use exception pattern for all errors that should trigger fallback.

---

## Impact Assessment

### Deployment Impact
**Blocks Deployment**: NO
**Blocks Promotion to Operational**: NO (Medium severity with workaround)

**Impact Details:**
Reduces service resilience but does not prevent deployment. Can proceed with reduced fallback coverage, or fix before deployment for full resilience.

### Operational Impact
**Affects Operations**: YES (reduced resilience)
**Affects Users**: YES (failures that could be avoided)
**Number of Users Affected**: All users when primary model returns invalid JSON

### Requirements Impact
**Requirements Not Met:**
- Acceptance Criteria (Task 122 line 54): "Automatic fallback to secondary model on HTTP 503/timeout" - Should also include JSON errors
- Fallback Documentation (lines 565-569): States "Invalid JSON response" triggers fallback, but implementation doesn't match

---

## Workaround

**Workaround Available**: YES

### Workaround Details

**Option 1: Fix Error Handling (RECOMMENDED)**

Raise exception on JSON parsing failure to trigger fallback:

```python
except json.JSONDecodeError as e:
    logger.error(f"Failed to parse entity extraction response: {str(e)}")
    raise ValueError(f"Invalid JSON response from model {model}: {str(e)}")
```

**Option 2: Caller Checks `success` Field**

Modify `extract_entities` to check `success` field and trigger fallback manually:

```python
result = self._parse_entity_response(response, model)
if not result["success"]:
    # Trigger fallback on parsing failure
    if fallback_model:
        logger.warning(f"JSON parsing failed with {model}, trying fallback")
        # Attempt fallback
```

**Recommendation**: Option 1 (raise exception) is cleaner and consistent with HTTP error handling.

---

## Resolution

### Resolution Status
**Status**: Open
**Assigned To**: shane-black
**Priority**: Medium
**Target Resolution Date**: Before Task 122 implementation

### Resolution Plan

**Approach:**
Change error handling to raise exception on JSON parsing failure, propagating error to outer exception handler which triggers fallback.

**Resolution Steps:**

1. **Update `_parse_entity_response` error handling** (lines 384-392):

   **Current (INCORRECT):**
   ```python
   except json.JSONDecodeError as e:
       logger.error(f"Failed to parse entity extraction response: {str(e)}")
       return {
           "entities": [],
           "model": model,
           "tokens_used": response.usage["total_tokens"],
           "success": False,
           "error": "Invalid JSON response",
       }
   ```

   **Corrected:**
   ```python
   except json.JSONDecodeError as e:
       logger.error(f"Failed to parse entity extraction response from {model}: {str(e)}")
       raise ValueError(f"Invalid JSON response from model {model}: {str(e)}")
   ```

2. **Update acceptance criteria** (line 54):

   **Current:**
   ```markdown
   - [ ] Automatic fallback to secondary model on HTTP 503/timeout
   ```

   **Updated:**
   ```markdown
   - [ ] Automatic fallback to secondary model on HTTP 503/timeout/invalid JSON
   ```

3. **Verify fallback documentation** (lines 565-569):

   Documentation already states JSON errors trigger fallback - implementation now matches documentation.

**Files to Modify:**
- `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/hx-docling-mcp-task-122-configure-model-routing.md` (lines 54, 384-392)

**Estimated Effort**: 10 minutes (change error handling, update acceptance criteria)

**Verification Plan:**
1. Create test with primary model returning invalid JSON
2. Verify exception raised from `_parse_entity_response`
3. Verify exception propagates to `extract_entities` exception handler
4. Verify fallback model attempted
5. Verify fallback succeeds if fallback model returns valid JSON
6. Verify RuntimeError raised if both models fail (documented behavior)

---

## Verification
[To be completed after resolution]

---

## Prevention

**Prevention Measures** (to be implemented):
1. **Consistent error signaling**: All errors that should trigger fallback must use exception pattern
2. **Documentation-implementation alignment**: Verify documented behavior matches implementation
3. **Test coverage for error paths**: Test all documented fallback trigger conditions
4. **Architecture decision records**: Document error handling strategy (exceptions vs return values) and when to use each

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
**Impact Scope**: Moderate (reduces service resilience, inconsistent with documentation)

---

## History and Updates

### Update Log
| Date | Updated By | Status Change | Notes |
|------|-----------|---------------|-------|
| 2025-12-01 | agent-zero | Created | Defect logged from CodeRabbit code review during Phase 6 approval |

---

## Closure
[To be completed when defect closed]
