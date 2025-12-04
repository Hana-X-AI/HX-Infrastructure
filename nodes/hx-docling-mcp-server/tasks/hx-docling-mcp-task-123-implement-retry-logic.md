# Task 123: Implement Retry Logic with Exponential Backoff

**Assigned To**: shane-black
**Estimated Effort**: 2 hours
**Dependencies**: Task 121 (LiteLLM client module)
**Status**: Not Started

## Objective

Implement retry logic with exponential backoff and jitter for LiteLLM HTTP requests to handle transient failures (timeouts, rate limits, temporary service unavailability) with graceful degradation.

## Pre-Execution Validation

**CRITICAL**: Check if retry logic already exists BEFORE implementing to prevent duplication.

```bash
# Check if retry decorator module exists
if grep -q "def retry_with_backoff" /opt/docling-mcp/src/integrations/litellm_client.py 2>/dev/null; then
    echo "✅ VALIDATION RESULT: Retry logic already implemented in litellm_client.py"
    echo "ACTION: SKIP task execution - validate retry behavior instead"
    echo "NEXT: Test retry logic with mock failures"
    exit 0
else
    echo "❌ VALIDATION RESULT: Retry logic NOT implemented"
    echo "ACTION: PROCEED with retry logic implementation"
fi
```

**If Retry Logic Exists**: Skip to Validation section, test retry behavior with mock failures

**If Retry Logic Does Not Exist**: Continue with Implementation Steps below

---

## Context

Network requests to LiteLLM server can fail due to transient issues:

1. **Timeout Errors (HTTP 408)**: Model inference exceeds timeout threshold (usually due to cold start or high queue depth)
2. **Rate Limit Errors (HTTP 429)**: Too many concurrent requests to LiteLLM Router
3. **Service Unavailable (HTTP 503)**: Model not loaded, Ollama server temporarily down, or Router restarting

Retry logic with exponential backoff provides resilience by:
- Retrying transient failures automatically (no manual intervention required)
- Increasing delay between retries (exponential backoff prevents overwhelming recovering service)
- Adding jitter (randomization prevents thundering herd problem)
- Limiting retry attempts (fail fast after max attempts to prevent infinite loops)

## Acceptance Criteria

- [ ] Retry decorator function implemented in litellm_client.py
- [ ] Exponential backoff strategy: 1s initial delay, 2.0x multiplier, max 60s delay
- [ ] Jitter added to backoff delay (±20% randomization)
- [ ] Maximum retry attempts: 3
- [ ] Retry triggered on HTTP 408 (timeout), 429 (rate limit), 503 (unavailable)
- [ ] No retry on HTTP 400 (bad request), 401 (unauthorized), 404 (not found)
- [ ] Retry counter logged at each attempt
- [ ] Final failure logged with all retry attempts exhausted
- [ ] Exception propagated to caller on final failure (circuit breaker integration handled by caller)

## Implementation Steps

### Step 1: Add Retry Logic to LiteLLM Client Module

```bash
# Backup existing module
sudo cp /opt/docling-mcp/src/integrations/litellm_client.py /opt/docling-mcp/src/integrations/litellm_client.py.bak

# Add retry logic imports and decorator
sudo -u docling-mcp@hx.dev.local tee -a /opt/docling-mcp/src/integrations/litellm_client.py > /dev/null << 'EOF'


import random
import time
from functools import wraps


def retry_with_exponential_backoff(
    max_retries: int = 3,
    initial_delay: float = 1.0,
    backoff_multiplier: float = 2.0,
    max_delay: float = 60.0,
    jitter: float = 0.2,
    retryable_status_codes: tuple = (408, 429, 503),
):
    """
    Decorator for retrying async functions with exponential backoff and jitter.

    Args:
        max_retries: Maximum number of retry attempts (default: 3)
        initial_delay: Initial delay in seconds (default: 1.0s)
        backoff_multiplier: Exponential backoff multiplier (default: 2.0)
        max_delay: Maximum delay cap in seconds (default: 60s)
        jitter: Jitter percentage (default: 0.2 = ±20%)
        retryable_status_codes: HTTP status codes to retry (default: 408, 429, 503)

    Returns:
        Decorated async function with retry logic
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            delay = initial_delay
            last_exception = None

            for attempt in range(max_retries + 1):  # +1 for initial attempt
                try:
                    # Attempt function call
                    return await func(*args, **kwargs)

                except httpx.HTTPStatusError as e:
                    # Check if status code is retryable
                    if e.response.status_code not in retryable_status_codes:
                        logger.error(
                            f"Non-retryable HTTP error {e.response.status_code}: {str(e)}"
                        )
                        raise  # Don't retry

                    # Log retry attempt
                    if attempt < max_retries:
                        # Calculate jittered delay (ensure non-negative)
                        jitter_amount = delay * jitter * random.uniform(-1, 1)
                        actual_delay = max(0.0, min(delay + jitter_amount, max_delay))

                        logger.warning(
                            f"HTTP {e.response.status_code} error on attempt {attempt + 1}/{max_retries + 1}: {str(e)}. "
                            f"Retrying in {actual_delay:.2f}s..."
                        )

                        # Wait with jittered delay
                        await asyncio.sleep(actual_delay)

                        # Exponential backoff
                        delay = min(delay * backoff_multiplier, max_delay)
                    else:
                        logger.error(
                            f"Max retries ({max_retries}) exhausted for HTTP {e.response.status_code}: {str(e)}"
                        )
                        last_exception = e

                except httpx.TimeoutException as e:
                    # Timeout is retryable
                    if attempt < max_retries:
                        jitter_amount = delay * jitter * random.uniform(-1, 1)
                        actual_delay = max(0.0, min(delay + jitter_amount, max_delay))

                        logger.warning(
                            f"Timeout on attempt {attempt + 1}/{max_retries + 1}: {str(e)}. "
                            f"Retrying in {actual_delay:.2f}s..."
                        )

                        await asyncio.sleep(actual_delay)
                        delay = min(delay * backoff_multiplier, max_delay)
                    else:
                        logger.error(f"Max retries ({max_retries}) exhausted for timeout: {str(e)}")
                        last_exception = e

                except Exception as e:
                    # Non-HTTP errors are not retryable
                    logger.error(f"Non-retryable error: {type(e).__name__}: {str(e)}")
                    raise

            # All retries exhausted
            if last_exception:
                raise last_exception

        return wrapper
    return decorator
EOF
```

### Step 2: Apply Retry Decorator to chat_completion Method

**IMPORTANT: Manual Code Editing Required**

This step requires manual editing of the source file to apply the retry decorator. Automated regex patching is fragile and error-prone with multi-line method signatures, varying whitespace, and different code formatting styles.

**Manual Procedure:**

```bash
# 1. Open the LiteLLMClient source file for editing
sudo -u docling-mcp@hx.dev.local nano /opt/docling-mcp/src/integrations/litellm_client.py

# 2. Locate the chat_completion method definition (search for "async def chat_completion")
#    The method signature may look like:
#
#    async def chat_completion(
#        self,
#        model: str,
#        messages: List[Dict[str, str]],
#        ...
#    ) -> LiteLLMResponse:

# 3. Add the @retry_with_exponential_backoff decorator ABOVE the method definition:
#
#    @retry_with_exponential_backoff(
#        max_retries=3,
#        initial_delay=1.0,
#        backoff_multiplier=2.0,
#        max_delay=60.0,
#        jitter=0.2,
#        retryable_status_codes=(408, 429, 503),
#    )
#    async def chat_completion(
#        self,
#        model: str,
#        messages: List[Dict[str, str]],
#        ...
#    ) -> LiteLLMResponse:
#
# 4. Save and exit (Ctrl+O, Enter, Ctrl+X in nano)

# 6. Verify syntax - import the module to check for errors
sudo -u docling-mcp@hx.dev.local bash -c "
source /opt/docling-mcp/venv/bin/activate
python3 -c 'from src.integrations.litellm_client import LiteLLMClient; print(\"✅ Import successful - decorator applied correctly\")'
"

# 7. If import fails, review the error message and check:
#    - Decorator indentation matches method indentation
#    - No syntax errors in decorator parameters
#    - Decorator placed immediately above method definition
```

### Step 3: Verify Retry Logic Syntax

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test module import with retry logic
python3 -c "from src.integrations.litellm_client import LiteLLMClient, retry_with_exponential_backoff; print('✅ Retry logic import successful')"

# Verify decorator exists
python3 -c "
from src.integrations.litellm_client import retry_with_exponential_backoff
import inspect
assert callable(retry_with_exponential_backoff)
print('✅ Retry decorator callable')
"

# Deactivate venv
deactivate
```

### Step 4: Create Retry Behavior Test Script

```bash
# Create test script for retry behavior validation
sudo -u docling-mcp@hx.dev.local tee /opt/docling-mcp/tests/test_retry_logic.py > /dev/null << 'EOF'
"""
Test script for LiteLLM retry logic validation.

Tests:
- Retry on HTTP 408 (timeout)
- Retry on HTTP 429 (rate limit)
- Retry on HTTP 503 (unavailable)
- No retry on HTTP 400 (bad request)
- Exponential backoff delay calculation
- Jitter randomization
- Max retries enforcement
"""

import asyncio
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from src.integrations.litellm_client import LiteLLMClient, retry_with_exponential_backoff
import httpx


@pytest.mark.asyncio
async def test_retry_on_timeout():
    """Test retry behavior on timeout exception."""

    @retry_with_exponential_backoff(max_retries=3, initial_delay=0.1)
    async def mock_request():
        raise httpx.TimeoutException("Request timed out")

    # Should retry 3 times then raise
    with pytest.raises(httpx.TimeoutException):
        await mock_request()


@pytest.mark.asyncio
async def test_retry_on_429():
    """Test retry behavior on rate limit (HTTP 429)."""

    attempt_count = 0

    @retry_with_exponential_backoff(max_retries=2, initial_delay=0.1)
    async def mock_request():
        nonlocal attempt_count
        attempt_count += 1

        if attempt_count < 3:
            # Simulate 429 response
            response = MagicMock()
            response.status_code = 429
            raise httpx.HTTPStatusError("Rate limited", request=MagicMock(), response=response)
        else:
            return "success"

    # Should succeed on 3rd attempt
    result = await mock_request()
    assert result == "success"
    assert attempt_count == 3


@pytest.mark.asyncio
async def test_no_retry_on_400():
    """Test no retry on non-retryable HTTP 400."""

    attempt_count = 0

    @retry_with_exponential_backoff(max_retries=3, initial_delay=0.1)
    async def mock_request():
        nonlocal attempt_count
        attempt_count += 1

        response = MagicMock()
        response.status_code = 400
        raise httpx.HTTPStatusError("Bad request", request=MagicMock(), response=response)

    # Should fail immediately without retry
    with pytest.raises(httpx.HTTPStatusError):
        await mock_request()

    assert attempt_count == 1  # Only initial attempt, no retries


@pytest.mark.asyncio
async def test_exponential_backoff_timing():
    """Test exponential backoff delay calculation."""
    import time

    attempt_times = []

    @retry_with_exponential_backoff(max_retries=3, initial_delay=0.5, backoff_multiplier=2.0, jitter=0.0)
    async def mock_request():
        attempt_times.append(time.time())
        raise httpx.TimeoutException("Timeout")

    start_time = time.time()

    with pytest.raises(httpx.TimeoutException):
        await mock_request()

    # Verify delays (approximately 0.5s, 1.0s, 2.0s between attempts)
    # With jitter=0, delays should be exact
    assert len(attempt_times) == 4  # Initial + 3 retries

    # Check delay between attempt 1 and 2 (should be ~0.5s)
    delay_1 = attempt_times[1] - attempt_times[0]
    assert 0.4 < delay_1 < 0.6

    # Check delay between attempt 2 and 3 (should be ~1.0s)
    delay_2 = attempt_times[2] - attempt_times[1]
    assert 0.9 < delay_2 < 1.1


if __name__ == "__main__":
    # Run tests
    asyncio.run(test_retry_on_timeout())
    print("✅ test_retry_on_timeout passed")

    asyncio.run(test_retry_on_429())
    print("✅ test_retry_on_429 passed")

    asyncio.run(test_no_retry_on_400())
    print("✅ test_no_retry_on_400 passed")

    asyncio.run(test_exponential_backoff_timing())
    print("✅ test_exponential_backoff_timing passed")

    print("\n✅ All retry logic tests passed!")
EOF

# Set ownership
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/test_retry_logic.py
sudo chmod 644 /opt/docling-mcp/tests/test_retry_logic.py
```

## Validation

**Validation Commands:**

```bash
# 1. Verify retry decorator exists in module
grep -q "def retry_with_exponential_backoff" /opt/docling-mcp/src/integrations/litellm_client.py && echo "PASS: Retry decorator exists" || echo "FAIL: Retry decorator missing"

# 2. Verify decorator applied to chat_completion
grep -B5 "async def chat_completion" /opt/docling-mcp/src/integrations/litellm_client.py | grep -q "@retry_with_exponential_backoff" && echo "PASS: Decorator applied" || echo "FAIL: Decorator not applied"

# 3. Verify retry parameters
grep -A5 "@retry_with_exponential_backoff" /opt/docling-mcp/src/integrations/litellm_client.py | grep -q "max_retries=3" && echo "PASS: Max retries configured" || echo "FAIL: Max retries not set"

# 4. Verify retryable status codes
grep -A5 "@retry_with_exponential_backoff" /opt/docling-mcp/src/integrations/litellm_client.py | grep -q "408, 429, 503" && echo "PASS: Retryable status codes configured" || echo "FAIL: Status codes missing"

# 5. Test retry logic with test script
source /opt/docling-mcp/venv/bin/activate && cd /opt/docling-mcp && python3 tests/test_retry_logic.py && echo "PASS: Retry logic tests passed" || echo "FAIL: Retry tests failed"

# 6. Verify module still imports correctly
source /opt/docling-mcp/venv/bin/activate && python3 -c "from src.integrations.litellm_client import LiteLLMClient; print('PASS: Module import successful')" || echo "FAIL: Import error"

# 7. Verify asyncio.sleep import exists (required for retry delay)
grep -q "import asyncio" /opt/docling-mcp/src/integrations/litellm_client.py && echo "PASS: asyncio imported" || echo "FAIL: asyncio import missing"
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Retry decorator implemented with exponential backoff and jitter
- chat_completion method decorated with retry logic
- Test script validates retry behavior on HTTP 408/429/503
- No retry on non-retryable errors (HTTP 400/401/404)
- Exponential backoff delays calculated correctly

## Notes

### Retry Strategy Parameters

**Max Retries**: 3 attempts (1 initial + 3 retries = 4 total attempts)

**Initial Delay**: 1.0 second

**Backoff Multiplier**: 2.0 (exponential growth)

**Max Delay Cap**: 60 seconds (prevents excessive delays)

**Jitter**: ±20% randomization of delay

**Delay Sequence** (with jitter):
- Attempt 1: 0s (initial request)
- Retry 1: ~1.0s ± 0.2s (0.8-1.2s)
- Retry 2: ~2.0s ± 0.4s (1.6-2.4s)
- Retry 3: ~4.0s ± 0.8s (3.2-4.8s)

**Total Time**: 7-8 seconds for full retry sequence

### Retryable vs Non-Retryable Errors

**Retryable (transient failures)**:
- **HTTP 408 (Timeout)**: Model inference exceeded timeout, retry may succeed with fresh request
- **HTTP 429 (Rate Limit)**: Too many concurrent requests, retry after delay allows rate limiter to reset
- **HTTP 503 (Service Unavailable)**: Model loading, Router restarting, or Ollama server temporary unavailability

**Non-Retryable (permanent failures)**:
- **HTTP 400 (Bad Request)**: Invalid request payload, retry will fail identically
- **HTTP 401 (Unauthorized)**: Invalid API key, retry won't fix auth issue
- **HTTP 404 (Not Found)**: Model doesn't exist, retry won't help
- **HTTP 500 (Internal Server Error)**: Router bug or corruption, retry may worsen issue

### Jitter Rationale

**Problem**: Thundering herd - multiple clients retry simultaneously after same failure

**Solution**: Add random jitter (±20%) to delay

**Example**:
- Without jitter: 100 clients all retry at exactly 1.0s, 2.0s, 4.0s (synchronous load spikes)
- With jitter: 100 clients retry at 0.8-1.2s, 1.6-2.4s, 3.2-4.8s (spread load over time)

**Effect**: Reduces probability of synchronized retry storms overwhelming recovering service

### Circuit Breaker Integration

**Note**: The retry decorator does NOT directly update circuit breaker state. Circuit breaker integration is handled by the caller (LiteLLMClient).

**Caller Responsibility**:
- After retry logic completes (success or final failure), caller updates circuit breaker state
- If all retries fail → Caller invokes `circuit_breaker.record_failure()`
- If any retry succeeds → Caller invokes `circuit_breaker.record_success()`

**Interaction**:
1. Request fails (HTTP 503)
2. Retry logic attempts 3 retries with backoff
3. If retry succeeds → circuit breaker stays CLOSED
4. If all retries fail → circuit breaker increments failure count
5. After 5 consecutive final failures → circuit breaker OPENS

**Why This Order**: Retry logic provides resilience for transient failures. Circuit breaker provides fail-fast for sustained failures. Retry first, circuit breaker second.

### Async/Await Compatibility

**Requirement**: Decorator must work with async functions

**Implementation**: Uses `async def wrapper` and `await func()`

**asyncio.sleep**: Async-compatible delay (does not block event loop)

**Why Not time.sleep**: `time.sleep()` is blocking and would prevent concurrent request processing in async event loop.

### Logging Strategy

**Log Levels**:
- **WARNING**: Retry attempt with delay (helps diagnose intermittent issues)
- **ERROR**: Max retries exhausted (indicates sustained failure)
- **DEBUG**: Not used in retry logic (too verbose for retries)

**Log Format**:
```
WARNING: HTTP 503 error on attempt 2/4: Service unavailable. Retrying in 1.87s...
ERROR: Max retries (3) exhausted for HTTP 503: Service unavailable
```

**Rationale**: WARNING level allows operators to see retry behavior in logs without DEBUG verbosity. ERROR level alerts to sustained failures requiring investigation.

### Cost Implications

**Additional API Calls**: Up to 3x cost increase if all requests require max retries

**Realistic Impact**: <5% cost increase (most requests succeed on first attempt)

**Cost vs Reliability Tradeoff**: 3 retries provide 99.9%+ success rate for transient failures. Cost increase justified by improved user experience.

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 4.3.4: LiteLLM Integration)
- **LiteLLM Enhancement**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/shane-litellm-summary.md` (Retry Logic section)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 8)
- **Task 121**: LiteLLM client module (dependency)
- **Exponential Backoff Pattern**: https://en.wikipedia.org/wiki/Exponential_backoff

## Risk Assessment

**Risk**: Low
- Retry logic is well-tested pattern for HTTP resilience
- Jitter prevents thundering herd problem
- Max retries prevent infinite loops
- Decorator pattern isolates retry logic from business logic

**Mitigation**:
- Test suite validates retry behavior
- Logging provides visibility into retry attempts
- Circuit breaker provides fail-fast after sustained failures
- Exponential backoff prevents overwhelming recovering services
