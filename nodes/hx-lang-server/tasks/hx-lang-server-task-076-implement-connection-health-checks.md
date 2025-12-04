# Task: Implement Connection Health Checks

**Task ID:** hx-lang-server-task-076-implement-connection-health-checks
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

Implement comprehensive health checks for Ollama server connections. These health checks will be integrated into the `/health` endpoint and used by the supervisor agent to determine service availability.

---

## Prerequisites

- [ ] Task 071 completed (Ollama1 connection configured)
- [ ] Task 072 completed (Ollama2 connection configured)
- [ ] httpx>=0.27.0 installed for async HTTP client

---

## Specification References

From node-spec.md (v2.1):
- **FR-024**: Service MUST provide health check endpoint at `/health`
- **Monitoring Section**: Health checks include ollama_general and ollama_code status
- **NFR-001**: API response time < 5 seconds for simple queries (95th percentile)

---

## Steps

### Step 1: Create Health Check Module

Create file `/opt/hx-lang-server/app/health/ollama_health.py`:

```python
"""
Ollama Health Check Module

Implements health checks for Ollama server connections.
Supports both hx-ollama1-server (general) and hx-ollama2-server (code).
"""

import asyncio
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Optional
import httpx
import structlog

logger = structlog.get_logger(__name__)


class HealthStatus(Enum):
    """Health check status values."""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"


@dataclass
class OllamaHealthResult:
    """Result of an Ollama health check."""
    server: str
    status: HealthStatus
    response_time_ms: Optional[float] = None
    model_count: Optional[int] = None
    error: Optional[str] = None
    checked_at: str = ""

    def __post_init__(self):
        if not self.checked_at:
            self.checked_at = datetime.utcnow().isoformat() + "Z"

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "server": self.server,
            "status": self.status.value,
            "response_time_ms": self.response_time_ms,
            "model_count": self.model_count,
            "error": self.error,
            "checked_at": self.checked_at,
        }


class OllamaHealthChecker:
    """
    Health checker for Ollama server connections.

    Checks connectivity, model availability, and response times
    for both general and code Ollama servers.
    """

    # Server configuration
    SERVERS = {
        "ollama_general": {
            "url": "http://hx-ollama1-server.hx.dev.local:11434",
            "name": "hx-ollama1-server (general)",
            "required_model_pattern": "gemma",
        },
        "ollama_code": {
            "url": "http://hx-ollama2-server.hx.dev.local:11434",
            "name": "hx-ollama2-server (code)",
            "required_model_pattern": "coder",
        },
    }

    # Thresholds
    HEALTHY_RESPONSE_MS = 1000  # < 1s = healthy
    DEGRADED_RESPONSE_MS = 5000  # < 5s = degraded, > 5s = unhealthy
    TIMEOUT_SECONDS = 10.0

    def __init__(self, timeout: float = TIMEOUT_SECONDS):
        """
        Initialize the health checker.

        Args:
            timeout: HTTP request timeout in seconds
        """
        self.timeout = timeout

    async def check_server(
        self,
        server_key: str,
        verify_model: bool = True,
    ) -> OllamaHealthResult:
        """
        Check health of a specific Ollama server.

        Args:
            server_key: Key from SERVERS dict ('ollama_general' or 'ollama_code')
            verify_model: Whether to verify expected model is available

        Returns:
            OllamaHealthResult with status and metrics
        """
        config = self.SERVERS.get(server_key)
        if not config:
            return OllamaHealthResult(
                server=server_key,
                status=HealthStatus.UNKNOWN,
                error=f"Unknown server key: {server_key}",
            )

        url = config["url"]
        server_name = config["name"]
        model_pattern = config.get("required_model_pattern", "")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                # Check API availability with timing
                start_time = asyncio.get_event_loop().time()
                response = await client.get(f"{url}/api/tags")
                end_time = asyncio.get_event_loop().time()

                response_ms = (end_time - start_time) * 1000

                if response.status_code != 200:
                    return OllamaHealthResult(
                        server=server_name,
                        status=HealthStatus.UNHEALTHY,
                        response_time_ms=response_ms,
                        error=f"API returned status {response.status_code}",
                    )

                # Parse models
                data = response.json()
                models = data.get("models", [])
                model_count = len(models)

                # Verify required model pattern if specified
                if verify_model and model_pattern:
                    has_required = any(
                        model_pattern.lower() in m["name"].lower()
                        for m in models
                    )
                    if not has_required:
                        return OllamaHealthResult(
                            server=server_name,
                            status=HealthStatus.DEGRADED,
                            response_time_ms=response_ms,
                            model_count=model_count,
                            error=f"Required model pattern '{model_pattern}' not found",
                        )

                # Determine status based on response time
                if response_ms < self.HEALTHY_RESPONSE_MS:
                    status = HealthStatus.HEALTHY
                elif response_ms < self.DEGRADED_RESPONSE_MS:
                    status = HealthStatus.DEGRADED
                else:
                    status = HealthStatus.UNHEALTHY

                return OllamaHealthResult(
                    server=server_name,
                    status=status,
                    response_time_ms=round(response_ms, 2),
                    model_count=model_count,
                )

        except httpx.TimeoutException:
            logger.warning(
                "ollama_health_check_timeout",
                server=server_name,
                timeout=self.timeout,
            )
            return OllamaHealthResult(
                server=server_name,
                status=HealthStatus.UNHEALTHY,
                error=f"Connection timeout ({self.timeout}s)",
            )

        except httpx.ConnectError as e:
            logger.error(
                "ollama_health_check_connection_error",
                server=server_name,
                error=str(e),
            )
            return OllamaHealthResult(
                server=server_name,
                status=HealthStatus.UNHEALTHY,
                error=f"Connection failed: {str(e)}",
            )

        except Exception as e:
            logger.error(
                "ollama_health_check_error",
                server=server_name,
                error=str(e),
            )
            return OllamaHealthResult(
                server=server_name,
                status=HealthStatus.UNHEALTHY,
                error=f"Unexpected error: {str(e)}",
            )

    async def check_all(self) -> dict[str, OllamaHealthResult]:
        """
        Check health of all configured Ollama servers.

        Returns:
            Dictionary mapping server keys to health results
        """
        results = {}

        # Check all servers concurrently
        tasks = [
            self.check_server(key)
            for key in self.SERVERS.keys()
        ]

        check_results = await asyncio.gather(*tasks, return_exceptions=True)

        for key, result in zip(self.SERVERS.keys(), check_results):
            if isinstance(result, Exception):
                results[key] = OllamaHealthResult(
                    server=self.SERVERS[key]["name"],
                    status=HealthStatus.UNHEALTHY,
                    error=str(result),
                )
            else:
                results[key] = result

        return results

    async def get_overall_status(self) -> tuple[HealthStatus, dict]:
        """
        Get overall Ollama health status.

        Returns:
            Tuple of (overall status, individual results)
        """
        results = await self.check_all()

        # Determine overall status
        statuses = [r.status for r in results.values()]

        if all(s == HealthStatus.HEALTHY for s in statuses):
            overall = HealthStatus.HEALTHY
        elif any(s == HealthStatus.UNHEALTHY for s in statuses):
            overall = HealthStatus.UNHEALTHY
        elif any(s == HealthStatus.DEGRADED for s in statuses):
            overall = HealthStatus.DEGRADED
        else:
            overall = HealthStatus.UNKNOWN

        return overall, {k: v.to_dict() for k, v in results.items()}


# Helper functions for integration with health endpoint

async def check_ollama_general() -> dict:
    """Check health of Ollama general server (hx-ollama1-server)."""
    checker = OllamaHealthChecker()
    result = await checker.check_server("ollama_general")
    return result.to_dict()


async def check_ollama_code() -> dict:
    """Check health of Ollama code server (hx-ollama2-server)."""
    checker = OllamaHealthChecker()
    result = await checker.check_server("ollama_code")
    return result.to_dict()


async def check_all_ollama() -> dict:
    """Check health of all Ollama servers."""
    checker = OllamaHealthChecker()
    overall, results = await checker.get_overall_status()
    return {
        "overall_status": overall.value,
        "servers": results,
    }
```

### Step 2: Integrate with Main Health Endpoint

Update `/opt/hx-lang-server/app/api/health.py` to include Ollama checks:

```python
from app.health.ollama_health import check_ollama_general, check_ollama_code

@app.get("/health")
async def health_check() -> HealthResponse:
    """Comprehensive health check including Ollama servers."""

    # Check Ollama servers
    ollama_general_health = await check_ollama_general()
    ollama_code_health = await check_ollama_code()

    dependencies = {
        # ... other dependencies ...
        "ollama_general": ollama_general_health,
        "ollama_code": ollama_code_health,
    }

    # ... rest of health check logic ...
```

### Step 3: Create Health Check CLI Tool

Create file `/opt/hx-lang-server/scripts/check_ollama_health.py`:

```python
#!/usr/bin/env python3
"""
CLI tool to check Ollama server health.
Usage: python check_ollama_health.py [--all|--general|--code]
"""

import asyncio
import sys
import json

# Add app to path
sys.path.insert(0, '/opt/hx-lang-server')

from app.health.ollama_health import (
    OllamaHealthChecker,
    check_ollama_general,
    check_ollama_code,
    check_all_ollama,
)


async def main():
    args = sys.argv[1:] if len(sys.argv) > 1 else ["--all"]

    if "--all" in args:
        result = await check_all_ollama()
        print(json.dumps(result, indent=2))

        # Exit code based on status
        if result["overall_status"] == "healthy":
            sys.exit(0)
        elif result["overall_status"] == "degraded":
            sys.exit(1)
        else:
            sys.exit(2)

    elif "--general" in args:
        result = await check_ollama_general()
        print(json.dumps(result, indent=2))
        sys.exit(0 if result["status"] == "healthy" else 1)

    elif "--code" in args:
        result = await check_ollama_code()
        print(json.dumps(result, indent=2))
        sys.exit(0 if result["status"] == "healthy" else 1)

    else:
        print("Usage: check_ollama_health.py [--all|--general|--code]")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
```

Make executable:
```bash
chmod +x /opt/hx-lang-server/scripts/check_ollama_health.py
```

### Step 4: Test Health Checks

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Test health check module
python3 << 'EOF'
import asyncio
import httpx

async def test_health_checks():
    print("Testing Ollama Health Checks")
    print("=" * 60)

    servers = {
        "ollama_general": "http://hx-ollama1-server.hx.dev.local:11434",
        "ollama_code": "http://hx-ollama2-server.hx.dev.local:11434",
    }

    for name, url in servers.items():
        print(f"\n{name}:")
        print(f"  URL: {url}")

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                start = asyncio.get_event_loop().time()
                response = await client.get(f"{url}/api/tags")
                end = asyncio.get_event_loop().time()

                response_ms = (end - start) * 1000

                if response.status_code == 200:
                    models = response.json().get("models", [])
                    print(f"  Status: HEALTHY")
                    print(f"  Response Time: {response_ms:.2f}ms")
                    print(f"  Model Count: {len(models)}")
                    if models:
                        print(f"  Models: {[m['name'] for m in models]}")
                else:
                    print(f"  Status: UNHEALTHY (HTTP {response.status_code})")

        except httpx.TimeoutException:
            print(f"  Status: UNHEALTHY (timeout)")
        except httpx.ConnectError as e:
            print(f"  Status: UNHEALTHY (connection failed)")
        except Exception as e:
            print(f"  Status: UNHEALTHY ({e})")

    print("\n" + "=" * 60)
    print("Health check test complete")

asyncio.run(test_health_checks())
EOF
```

---

## Acceptance Criteria

- [ ] OllamaHealthChecker class implemented with check_server and check_all methods
- [ ] Health check returns status, response_time_ms, model_count, and error fields
- [ ] Thresholds defined: < 1s = healthy, < 5s = degraded, > 5s = unhealthy
- [ ] Both ollama_general and ollama_code servers checked
- [ ] Model pattern verification implemented (gemma for general, coder for code)
- [ ] Helper functions for health endpoint integration created
- [ ] CLI tool for manual health checks created
- [ ] Health checks complete within 10 second timeout
- [ ] No hardcoded IP addresses (hostnames only)

---

## Verification Commands

```bash
# Verify module exists
ls -la /opt/hx-lang-server/app/health/ollama_health.py

# Verify CLI tool exists and is executable
ls -la /opt/hx-lang-server/scripts/check_ollama_health.py

# Run CLI health check
source /opt/hx-lang-server/venv/bin/activate
python /opt/hx-lang-server/scripts/check_ollama_health.py --all

# Test individual servers
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | jq '.models | length'
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | jq '.models | length'
```

---

## Rollback Procedure

1. Remove ollama_health.py module
2. Remove health endpoint integration
3. Remove CLI tool
4. Revert any api/health.py changes

---

## Related Tasks

- **Task 071:** Configure Ollama1 connection
- **Task 072:** Configure Ollama2 connection
- **Task 077:** Implement retry logic with backoff

---

## Notes

- Health checks are async for non-blocking operation
- Concurrent checks reduce total health check time
- Response time thresholds align with NFR-001 (< 5s for queries)
- Model pattern verification catches misconfigured servers
- Exit codes in CLI tool support integration with monitoring

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
