# Task: Implement Retry Logic with Backoff

**Task ID:** hx-lang-server-task-077-implement-retry-logic
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:**
- hx-lang-server-task-071 (Ollama1 connection)
- hx-lang-server-task-072 (Ollama2 connection)
**Estimated Time:** 45 minutes

---

## Objective

Implement retry logic with exponential backoff for Ollama server connections. This ensures resilience against transient failures and network issues while preventing cascade failures through circuit breaker patterns.

---

## Prerequisites

- [ ] Task 071 completed (Ollama1 connection configured)
- [ ] Task 072 completed (Ollama2 connection configured)
- [ ] httpx>=0.27.0 installed for async HTTP client
- [ ] tenacity library available (or implement custom retry)

---

## Specification References

From node-spec.md (v2.1):
- **Operational Requirements**: Retry logic with exponential backoff for Ollama/LightRAG connections
- **Operational Requirements**: Circuit breaker prevents cascade failures
- **NFR-001**: API response time < 5 seconds for simple queries (95th percentile)

---

## Steps

### Step 1: Install Retry Library (If Not Present)

```bash
# Check if tenacity is available
source /opt/hx-lang-server/venv/bin/activate
pip show tenacity || pip install tenacity>=8.2.0

# Alternatively, we can implement custom retry logic
```

### Step 2: Create Retry Configuration Module

Create file `/opt/hx-lang-server/app/llm/retry_config.py`:

```python
"""
Retry Configuration for Ollama Connections

Implements exponential backoff retry logic and circuit breaker pattern
for resilient Ollama server communication.
"""

import asyncio
import random
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from functools import wraps
from typing import Callable, Optional, Type, TypeVar, Any
import structlog

logger = structlog.get_logger(__name__)

T = TypeVar("T")


class CircuitState(Enum):
    """Circuit breaker states."""
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing if service recovered


@dataclass
class RetryConfig:
    """Configuration for retry behavior."""
    max_attempts: int = 3
    initial_delay: float = 1.0  # seconds
    max_delay: float = 30.0     # seconds
    exponential_base: float = 2.0
    jitter: bool = True
    jitter_range: float = 0.5   # +/- 50% of delay

    # Retryable exceptions
    retryable_exceptions: tuple = (
        ConnectionError,
        TimeoutError,
        asyncio.TimeoutError,
    )


@dataclass
class CircuitBreakerConfig:
    """Configuration for circuit breaker behavior."""
    failure_threshold: int = 5      # Failures before opening circuit
    success_threshold: int = 2      # Successes in half-open before closing
    reset_timeout: float = 60.0     # Seconds before half-open attempt


class CircuitBreaker:
    """
    Circuit breaker implementation for Ollama connections.

    Prevents cascade failures by stopping requests to failing services.
    """

    def __init__(
        self,
        name: str,
        config: Optional[CircuitBreakerConfig] = None,
    ):
        """
        Initialize circuit breaker.

        Args:
            name: Identifier for this circuit breaker
            config: Circuit breaker configuration
        """
        self.name = name
        self.config = config or CircuitBreakerConfig()

        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure_time: Optional[datetime] = None

        logger.info(
            "circuit_breaker_initialized",
            name=name,
            failure_threshold=self.config.failure_threshold,
            reset_timeout=self.config.reset_timeout,
        )

    @property
    def state(self) -> CircuitState:
        """Get current circuit state, checking for timeout transitions."""
        if self._state == CircuitState.OPEN:
            # Check if reset timeout has passed
            if self._last_failure_time:
                elapsed = (datetime.utcnow() - self._last_failure_time).total_seconds()
                if elapsed >= self.config.reset_timeout:
                    self._state = CircuitState.HALF_OPEN
                    self._success_count = 0
                    logger.info(
                        "circuit_half_open",
                        name=self.name,
                        elapsed_seconds=elapsed,
                    )

        return self._state

    def record_success(self) -> None:
        """Record a successful operation."""
        if self._state == CircuitState.HALF_OPEN:
            self._success_count += 1
            if self._success_count >= self.config.success_threshold:
                self._state = CircuitState.CLOSED
                self._failure_count = 0
                logger.info(
                    "circuit_closed",
                    name=self.name,
                    success_count=self._success_count,
                )
        elif self._state == CircuitState.CLOSED:
            # Reset failure count on success
            if self._failure_count > 0:
                self._failure_count = max(0, self._failure_count - 1)

    def record_failure(self) -> None:
        """Record a failed operation."""
        self._failure_count += 1
        self._last_failure_time = datetime.utcnow()

        if self._state == CircuitState.HALF_OPEN:
            # Any failure in half-open goes back to open
            self._state = CircuitState.OPEN
            logger.warning(
                "circuit_reopened",
                name=self.name,
            )
        elif self._state == CircuitState.CLOSED:
            if self._failure_count >= self.config.failure_threshold:
                self._state = CircuitState.OPEN
                logger.warning(
                    "circuit_opened",
                    name=self.name,
                    failure_count=self._failure_count,
                )

    def allow_request(self) -> bool:
        """Check if a request should be allowed."""
        current_state = self.state  # Triggers timeout check

        if current_state == CircuitState.CLOSED:
            return True
        elif current_state == CircuitState.HALF_OPEN:
            return True  # Allow test request
        else:
            return False

    def get_status(self) -> dict:
        """Get circuit breaker status."""
        return {
            "name": self.name,
            "state": self.state.value,
            "failure_count": self._failure_count,
            "success_count": self._success_count,
            "last_failure": self._last_failure_time.isoformat() if self._last_failure_time else None,
        }


def calculate_delay(
    attempt: int,
    config: RetryConfig,
) -> float:
    """
    Calculate delay for retry attempt using exponential backoff.

    Args:
        attempt: Current attempt number (1-based)
        config: Retry configuration

    Returns:
        Delay in seconds
    """
    # Exponential backoff
    delay = config.initial_delay * (config.exponential_base ** (attempt - 1))

    # Cap at max delay
    delay = min(delay, config.max_delay)

    # Add jitter to prevent thundering herd
    if config.jitter:
        jitter_amount = delay * config.jitter_range
        delay = delay + random.uniform(-jitter_amount, jitter_amount)
        delay = max(0.1, delay)  # Minimum 100ms

    return delay


class RetryableOllamaClient:
    """
    Ollama client wrapper with retry and circuit breaker support.
    """

    def __init__(
        self,
        name: str,
        retry_config: Optional[RetryConfig] = None,
        circuit_config: Optional[CircuitBreakerConfig] = None,
    ):
        """
        Initialize retryable client.

        Args:
            name: Client identifier (e.g., "ollama_general")
            retry_config: Retry configuration
            circuit_config: Circuit breaker configuration
        """
        self.name = name
        self.retry_config = retry_config or RetryConfig()
        self.circuit_breaker = CircuitBreaker(name, circuit_config)

    async def execute_with_retry(
        self,
        func: Callable[..., Any],
        *args,
        **kwargs,
    ) -> Any:
        """
        Execute function with retry logic and circuit breaker.

        Args:
            func: Async function to execute
            *args: Positional arguments for func
            **kwargs: Keyword arguments for func

        Returns:
            Result of function execution

        Raises:
            Exception: If all retries fail or circuit is open
        """
        # Check circuit breaker
        if not self.circuit_breaker.allow_request():
            logger.warning(
                "request_rejected_circuit_open",
                client=self.name,
                state=self.circuit_breaker.state.value,
            )
            raise RuntimeError(
                f"Circuit breaker open for {self.name}. "
                f"Service unavailable."
            )

        last_exception = None

        for attempt in range(1, self.retry_config.max_attempts + 1):
            try:
                logger.debug(
                    "retry_attempt",
                    client=self.name,
                    attempt=attempt,
                    max_attempts=self.retry_config.max_attempts,
                )

                result = await func(*args, **kwargs)

                # Success - record and return
                self.circuit_breaker.record_success()

                if attempt > 1:
                    logger.info(
                        "retry_succeeded",
                        client=self.name,
                        attempt=attempt,
                    )

                return result

            except self.retry_config.retryable_exceptions as e:
                last_exception = e
                self.circuit_breaker.record_failure()

                logger.warning(
                    "retry_failed",
                    client=self.name,
                    attempt=attempt,
                    error=str(e),
                    error_type=type(e).__name__,
                )

                # Check if more retries available
                if attempt < self.retry_config.max_attempts:
                    # Check circuit breaker before next attempt
                    if not self.circuit_breaker.allow_request():
                        logger.warning(
                            "circuit_opened_during_retry",
                            client=self.name,
                        )
                        break

                    delay = calculate_delay(attempt, self.retry_config)
                    logger.info(
                        "retry_waiting",
                        client=self.name,
                        delay_seconds=round(delay, 2),
                        next_attempt=attempt + 1,
                    )
                    await asyncio.sleep(delay)

            except Exception as e:
                # Non-retryable exception
                self.circuit_breaker.record_failure()
                logger.error(
                    "non_retryable_error",
                    client=self.name,
                    error=str(e),
                    error_type=type(e).__name__,
                )
                raise

        # All retries exhausted
        logger.error(
            "all_retries_exhausted",
            client=self.name,
            attempts=self.retry_config.max_attempts,
        )
        raise last_exception or RuntimeError(f"All retries exhausted for {self.name}")

    def get_status(self) -> dict:
        """Get client and circuit breaker status."""
        return {
            "name": self.name,
            "retry_config": {
                "max_attempts": self.retry_config.max_attempts,
                "initial_delay": self.retry_config.initial_delay,
                "max_delay": self.retry_config.max_delay,
            },
            "circuit_breaker": self.circuit_breaker.get_status(),
        }


# Pre-configured clients for Ollama servers

OLLAMA_GENERAL_CLIENT = RetryableOllamaClient(
    name="ollama_general",
    retry_config=RetryConfig(
        max_attempts=3,
        initial_delay=1.0,
        max_delay=10.0,
    ),
    circuit_config=CircuitBreakerConfig(
        failure_threshold=5,
        reset_timeout=60.0,
    ),
)

OLLAMA_CODE_CLIENT = RetryableOllamaClient(
    name="ollama_code",
    retry_config=RetryConfig(
        max_attempts=3,
        initial_delay=2.0,  # Longer initial delay for code (larger responses)
        max_delay=15.0,
    ),
    circuit_config=CircuitBreakerConfig(
        failure_threshold=5,
        reset_timeout=60.0,
    ),
)
```

### Step 3: Integrate Retry Logic with LLM Clients

Update `/opt/hx-lang-server/app/llm/ollama_general.py` to use retry:

```python
from app.llm.retry_config import OLLAMA_GENERAL_CLIENT

async def invoke_with_retry(
    llm: ChatOllama,
    query: str,
) -> str:
    """
    Invoke LLM with retry logic.

    Args:
        llm: ChatOllama instance
        query: User query

    Returns:
        LLM response content
    """
    async def _invoke():
        response = await llm.ainvoke(query)
        return response.content

    return await OLLAMA_GENERAL_CLIENT.execute_with_retry(_invoke)
```

### Step 4: Add Environment Variables

Add to `/opt/hx-lang-server/.env`:

```bash
# Retry Configuration
OLLAMA_RETRY_MAX_ATTEMPTS=3
OLLAMA_RETRY_INITIAL_DELAY=1.0
OLLAMA_RETRY_MAX_DELAY=30.0

# Circuit Breaker Configuration
OLLAMA_CIRCUIT_FAILURE_THRESHOLD=5
OLLAMA_CIRCUIT_RESET_TIMEOUT=60
```

### Step 5: Test Retry Logic

```bash
source /opt/hx-lang-server/venv/bin/activate

python3 << 'EOF'
import asyncio
import sys
sys.path.insert(0, '/opt/hx-lang-server')

from app.llm.retry_config import (
    RetryConfig,
    CircuitBreaker,
    CircuitBreakerConfig,
    RetryableOllamaClient,
    calculate_delay,
)

async def test_retry_logic():
    print("Testing Retry Logic")
    print("=" * 60)

    # Test delay calculation
    config = RetryConfig()
    print("\nDelay calculation (exponential backoff):")
    for attempt in range(1, 6):
        delay = calculate_delay(attempt, config)
        print(f"  Attempt {attempt}: {delay:.2f}s")

    # Test circuit breaker
    print("\nCircuit Breaker Test:")
    cb = CircuitBreaker("test", CircuitBreakerConfig(failure_threshold=3))

    print(f"  Initial state: {cb.state.value}")

    # Record failures
    for i in range(3):
        cb.record_failure()
        print(f"  After failure {i+1}: {cb.state.value}")

    print(f"  Allow request when open: {cb.allow_request()}")

    # Test retryable client with mock
    print("\nRetryable Client Test:")
    client = RetryableOllamaClient("test_client")

    attempt_count = [0]

    async def mock_success():
        attempt_count[0] += 1
        if attempt_count[0] < 2:
            raise ConnectionError("Simulated failure")
        return "Success!"

    try:
        result = await client.execute_with_retry(mock_success)
        print(f"  Result after retries: {result}")
        print(f"  Total attempts: {attempt_count[0]}")
    except Exception as e:
        print(f"  Failed: {e}")

    print("\n" + "=" * 60)
    print("Retry logic test complete")

asyncio.run(test_retry_logic())
EOF
```

---

## Acceptance Criteria

- [ ] RetryConfig dataclass with configurable max_attempts, delays, jitter
- [ ] CircuitBreaker class with CLOSED/OPEN/HALF_OPEN states
- [ ] calculate_delay function implements exponential backoff with jitter
- [ ] RetryableOllamaClient wraps async functions with retry logic
- [ ] Circuit breaker opens after failure_threshold consecutive failures
- [ ] Circuit breaker transitions to half-open after reset_timeout
- [ ] Pre-configured clients for ollama_general and ollama_code
- [ ] Environment variables for retry/circuit configuration
- [ ] Integration with LLM client modules
- [ ] Tests pass for retry and circuit breaker logic

---

## Verification Commands

```bash
# Verify module exists
ls -la /opt/hx-lang-server/app/llm/retry_config.py

# Verify retry configuration
grep -n "RetryConfig\|CircuitBreaker" /opt/hx-lang-server/app/llm/retry_config.py

# Verify environment variables
grep -E "RETRY|CIRCUIT" /opt/hx-lang-server/.env

# Run retry tests
source /opt/hx-lang-server/venv/bin/activate
python -c "from app.llm.retry_config import *; print('Import OK')"
```

---

## Rollback Procedure

1. Remove retry_config.py module
2. Remove retry integration from LLM clients
3. Remove retry/circuit environment variables
4. Test direct LLM invocation without retry

---

## Related Tasks

- **Task 071:** Configure Ollama1 connection
- **Task 072:** Configure Ollama2 connection
- **Task 076:** Implement connection health checks
- **Task 078:** Create integration tests

---

## Notes

- Exponential backoff with jitter prevents thundering herd problem
- Circuit breaker prevents cascade failures to failing services
- Separate retry configs for general (faster) vs code (longer timeout)
- Circuit stays open for 60s before half-open test
- 5 consecutive failures open the circuit
- 2 successes in half-open close the circuit

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
