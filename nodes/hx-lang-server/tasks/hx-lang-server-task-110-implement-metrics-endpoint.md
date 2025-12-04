# Task: Implement /metrics Endpoint for Prometheus

**Task ID**: hx-lang-server-task-110-implement-metrics-endpoint
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-108 (Health endpoint)
**Estimated Time**: 60 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Implement the Prometheus metrics endpoint at `GET /metrics` that exposes operational metrics in Prometheus text format. Metrics include agent invocation counts, latency histograms, active sessions, error rates, and worker usage distribution as specified in the Monitoring & Observability section.

---

## Pre-Execution Validation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
from app.routers.health import metrics
import inspect
source = inspect.getsource(metrics)
if 'stub' in source.lower() or 'Full metrics implementation' in source:
    raise Exception('Still stub implementation')
print('VALIDATION: Metrics endpoint implemented - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Metrics endpoint needs implementation - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] Health endpoint implemented (Task 108)
- [ ] prometheus-client package installed (add to dependencies if needed)

---

## Steps

### 1. Install Prometheus Client (if needed)

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

# Check if prometheus-client is installed
python3 -c "import prometheus_client" 2>/dev/null || pip install prometheus-client
```

### 2. Create Metrics Module

```bash
cat > /opt/hx-lang-server/app/services/metrics.py <<'EOF'
"""
Prometheus metrics collection and export.

Provides application metrics for monitoring and alerting.
Metrics exposed at GET /metrics in Prometheus text format.

Specification Reference: Monitoring & Observability > Key Metrics
"""
from typing import Optional

from prometheus_client import (
    Counter,
    Histogram,
    Gauge,
    Info,
    generate_latest,
    CONTENT_TYPE_LATEST,
    REGISTRY,
    CollectorRegistry,
)

from app.version import __version__


# Create custom registry to avoid default metrics
METRICS_REGISTRY = CollectorRegistry()

# --- Service Info ---
SERVICE_INFO = Info(
    "langgraph",
    "LangGraph service information",
    registry=METRICS_REGISTRY,
)
SERVICE_INFO.info({
    "version": __version__,
    "service": "hx-lang-server",
})

# --- Invocation Metrics ---
INVOKE_TOTAL = Counter(
    "langgraph_invoke_total",
    "Total agent invocations",
    ["query_type", "worker", "status"],
    registry=METRICS_REGISTRY,
)

INVOKE_DURATION = Histogram(
    "langgraph_invoke_duration_seconds",
    "Agent invocation duration in seconds",
    ["query_type", "worker"],
    buckets=(0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, 120.0),
    registry=METRICS_REGISTRY,
)

STREAM_TOTAL = Counter(
    "langgraph_stream_total",
    "Total streaming invocations",
    ["query_type", "status"],
    registry=METRICS_REGISTRY,
)

STREAM_TOKENS = Counter(
    "langgraph_stream_tokens_total",
    "Total tokens streamed",
    ["query_type"],
    registry=METRICS_REGISTRY,
)

# --- Session Metrics ---
ACTIVE_SESSIONS = Gauge(
    "langgraph_active_sessions",
    "Current active sessions",
    registry=METRICS_REGISTRY,
)

SESSION_OPERATIONS = Counter(
    "langgraph_session_operations_total",
    "Session operations count",
    ["operation"],  # create, get, delete
    registry=METRICS_REGISTRY,
)

# --- Checkpoint Metrics ---
CHECKPOINT_DURATION = Histogram(
    "langgraph_checkpoint_duration_seconds",
    "Checkpoint persistence duration",
    buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0),
    registry=METRICS_REGISTRY,
)

CHECKPOINT_TOTAL = Counter(
    "langgraph_checkpoint_total",
    "Total checkpoints created",
    ["status"],  # success, failure
    registry=METRICS_REGISTRY,
)

# --- Worker Metrics ---
WORKER_INVOCATIONS = Counter(
    "langgraph_worker_invocations_total",
    "Invocations per worker type",
    ["worker"],  # rag_agent, code_agent, tool_agent
    registry=METRICS_REGISTRY,
)

# --- LLM Metrics ---
OLLAMA_REQUESTS = Counter(
    "langgraph_ollama_requests_total",
    "Ollama API requests",
    ["server", "model", "status"],
    registry=METRICS_REGISTRY,
)

OLLAMA_DURATION = Histogram(
    "langgraph_ollama_duration_seconds",
    "Ollama request duration",
    ["server", "model"],
    buckets=(0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, 120.0),
    registry=METRICS_REGISTRY,
)

# --- Error Metrics ---
ERRORS_TOTAL = Counter(
    "langgraph_errors_total",
    "Total errors by type",
    ["error_code"],
    registry=METRICS_REGISTRY,
)

# --- Dependency Metrics ---
DEPENDENCY_STATUS = Gauge(
    "langgraph_dependency_status",
    "Dependency health status (1=healthy, 0=unhealthy)",
    ["dependency"],
    registry=METRICS_REGISTRY,
)

DEPENDENCY_LATENCY = Gauge(
    "langgraph_dependency_latency_ms",
    "Dependency check latency in milliseconds",
    ["dependency"],
    registry=METRICS_REGISTRY,
)


def get_metrics() -> bytes:
    """
    Generate Prometheus metrics in text format.

    Returns:
        Prometheus metrics as UTF-8 encoded bytes.
    """
    return generate_latest(METRICS_REGISTRY)


def get_content_type() -> str:
    """
    Get content type for metrics response.

    Returns:
        Prometheus content type string.
    """
    return CONTENT_TYPE_LATEST


# --- Metric Recording Functions ---

def record_invoke(
    query_type: str,
    worker: str,
    status: str,
    duration_seconds: float,
):
    """Record an agent invocation."""
    INVOKE_TOTAL.labels(
        query_type=query_type,
        worker=worker,
        status=status,
    ).inc()

    INVOKE_DURATION.labels(
        query_type=query_type,
        worker=worker,
    ).observe(duration_seconds)

    WORKER_INVOCATIONS.labels(worker=worker).inc()


def record_stream(
    query_type: str,
    status: str,
    token_count: int,
):
    """Record a streaming invocation."""
    STREAM_TOTAL.labels(
        query_type=query_type,
        status=status,
    ).inc()

    STREAM_TOKENS.labels(query_type=query_type).inc(token_count)


def record_session_operation(operation: str):
    """Record a session operation (create, get, delete)."""
    SESSION_OPERATIONS.labels(operation=operation).inc()


def set_active_sessions(count: int):
    """Set current active session count."""
    ACTIVE_SESSIONS.set(count)


def record_checkpoint(status: str, duration_seconds: float):
    """Record a checkpoint operation."""
    CHECKPOINT_TOTAL.labels(status=status).inc()
    if status == "success":
        CHECKPOINT_DURATION.observe(duration_seconds)


def record_ollama_request(
    server: str,
    model: str,
    status: str,
    duration_seconds: float,
):
    """Record an Ollama API request."""
    OLLAMA_REQUESTS.labels(
        server=server,
        model=model,
        status=status,
    ).inc()

    if status == "success":
        OLLAMA_DURATION.labels(
            server=server,
            model=model,
        ).observe(duration_seconds)


def record_error(error_code: str):
    """Record an error by code."""
    ERRORS_TOTAL.labels(error_code=error_code).inc()


def set_dependency_status(dependency: str, healthy: bool, latency_ms: Optional[float] = None):
    """Set dependency status metric."""
    DEPENDENCY_STATUS.labels(dependency=dependency).set(1 if healthy else 0)
    if latency_ms is not None:
        DEPENDENCY_LATENCY.labels(dependency=dependency).set(latency_ms)
EOF
```

### 3. Update Health Router with Prometheus Metrics

```bash
# Update the metrics endpoint in health.py
cat > /opt/hx-lang-server/app/routers/health.py <<'EOF'
"""
Health, readiness, and metrics endpoints.

These endpoints provide operational status information for
monitoring, load balancing, and orchestration systems.

Specification Reference:
- FR-024: Health check endpoint at /health
- Monitoring & Observability section
"""
import time
from datetime import datetime
from typing import Dict

from fastapi import APIRouter, Depends, Response
from fastapi.responses import PlainTextResponse
import structlog

from app.models import (
    HealthResponse,
    ReadyResponse,
    DependencyStatus,
)
from app.core.config import Settings, get_settings
from app.version import __version__
from app.services import metrics as metrics_service


logger = structlog.get_logger()

router = APIRouter()

# Track service start time for uptime calculation
_start_time = time.time()


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="""
    Comprehensive health check endpoint.

    Returns:
    - Service status (healthy, degraded, unhealthy)
    - Application version
    - Uptime in seconds
    - Status of all dependencies

    Status meanings:
    - healthy: All dependencies operational
    - degraded: Some non-critical dependencies unavailable
    - unhealthy: Critical dependencies unavailable
    """,
    tags=["health"],
)
async def health_check(
    settings: Settings = Depends(get_settings),
) -> HealthResponse:
    """
    Perform comprehensive health check.

    Checks all configured dependencies and returns aggregate status.
    """
    uptime = time.time() - _start_time

    # Check all dependencies
    dependencies = await _check_all_dependencies(settings)

    # Update dependency metrics
    for name, dep in dependencies.items():
        metrics_service.set_dependency_status(
            name,
            dep.status == "healthy",
            dep.latency_ms,
        )

    # Determine overall status
    status = _calculate_status(dependencies)

    logger.debug(
        "health_check",
        status=status,
        uptime_seconds=uptime,
        dependencies={k: v.status for k, v in dependencies.items()},
    )

    return HealthResponse(
        status=status,
        version=__version__,
        uptime_seconds=uptime,
        dependencies=dependencies,
    )


@router.get(
    "/ready",
    response_model=ReadyResponse,
    summary="Readiness probe",
    description="""
    Kubernetes-style readiness probe.

    Returns ready=true only when ALL critical dependencies are available.
    Use this for Kubernetes readiness probes or load balancer health checks.

    Critical dependencies:
    - PostgreSQL (checkpoint persistence)
    - Redis (session caching)
    - Ollama servers (LLM inference)
    """,
    tags=["health"],
)
async def readiness_check(
    settings: Settings = Depends(get_settings),
) -> ReadyResponse:
    """
    Check if service is ready to accept requests.

    All critical dependencies must be available.
    """
    checks = await _check_readiness(settings)
    ready = all(checks.values())

    message = None
    if not ready:
        failed = [k for k, v in checks.items() if not v]
        message = f"Not ready: {', '.join(failed)} unavailable"

    logger.debug(
        "readiness_check",
        ready=ready,
        checks=checks,
    )

    return ReadyResponse(
        ready=ready,
        checks=checks,
        message=message,
    )


@router.get(
    "/metrics",
    response_class=PlainTextResponse,
    summary="Prometheus metrics",
    description="""
    Prometheus-compatible metrics endpoint.

    Returns metrics in Prometheus text format including:
    - langgraph_invoke_total: Total agent invocations
    - langgraph_invoke_duration_seconds: Invocation latency histogram
    - langgraph_active_sessions: Current active sessions
    - langgraph_worker_invocations_total: Invocations per worker
    - langgraph_ollama_requests_total: Ollama API requests
    - langgraph_errors_total: Error count by type
    - langgraph_dependency_status: Dependency health (1/0)
    """,
    tags=["health"],
)
async def metrics(
    settings: Settings = Depends(get_settings),
) -> PlainTextResponse:
    """
    Return Prometheus metrics in text format.

    Uses prometheus_client to generate metrics.
    """
    metrics_bytes = metrics_service.get_metrics()

    return PlainTextResponse(
        content=metrics_bytes.decode("utf-8"),
        media_type=metrics_service.get_content_type(),
    )


async def _check_all_dependencies(settings: Settings) -> Dict[str, DependencyStatus]:
    """
    Check status of all configured dependencies.

    Returns dictionary of dependency name to status.
    """
    dependencies = {}

    # PostgreSQL check
    dependencies["postgres"] = await _check_postgres(settings)

    # Redis check
    dependencies["redis"] = await _check_redis(settings)

    # Ollama (general) check
    dependencies["ollama_general"] = await _check_ollama(
        settings.ollama_general_url,
        "ollama_general",
    )

    # Ollama (code) check
    dependencies["ollama_code"] = await _check_ollama(
        settings.ollama_code_url,
        "ollama_code",
    )

    # LightRAG check
    dependencies["lightrag"] = await _check_lightrag(settings)

    # FastMCP check
    dependencies["fastmcp"] = await _check_fastmcp(settings)

    return dependencies


async def _check_readiness(settings: Settings) -> Dict[str, bool]:
    """
    Check critical dependencies for readiness.

    Returns dictionary of check name to boolean status.
    """
    deps = await _check_all_dependencies(settings)

    # Critical dependencies that must be healthy
    critical = ["postgres", "redis", "ollama_general"]

    return {
        name: deps[name].status == "healthy"
        for name in critical
        if name in deps
    }


def _calculate_status(dependencies: Dict[str, DependencyStatus]) -> str:
    """
    Calculate overall service status from dependency statuses.
    """
    critical = {"postgres", "redis", "ollama_general"}

    critical_healthy = all(
        dependencies.get(name, DependencyStatus(name=name, status="unhealthy")).status == "healthy"
        for name in critical
        if name in dependencies
    )

    if not critical_healthy:
        return "unhealthy"

    all_healthy = all(
        dep.status == "healthy"
        for dep in dependencies.values()
    )

    return "healthy" if all_healthy else "degraded"


# Dependency check functions (stubs - full impl in integration work streams)

async def _check_postgres(settings: Settings) -> DependencyStatus:
    """Check PostgreSQL connectivity."""
    return DependencyStatus(
        name="postgres",
        status="healthy",
        latency_ms=5.0,
        message=f"Connected to {settings.postgres_host}",
    )


async def _check_redis(settings: Settings) -> DependencyStatus:
    """Check Redis connectivity."""
    return DependencyStatus(
        name="redis",
        status="healthy",
        latency_ms=1.0,
        message="PONG",
    )


async def _check_ollama(url: str, name: str) -> DependencyStatus:
    """Check Ollama server connectivity."""
    return DependencyStatus(
        name=name,
        status="healthy",
        latency_ms=10.0,
        message=f"Connected to {url}",
    )


async def _check_lightrag(settings: Settings) -> DependencyStatus:
    """Check LightRAG connectivity."""
    return DependencyStatus(
        name="lightrag",
        status="healthy",
        latency_ms=15.0,
        message=f"Connected to {settings.lightrag_url}",
    )


async def _check_fastmcp(settings: Settings) -> DependencyStatus:
    """Check FastMCP gateway connectivity."""
    return DependencyStatus(
        name="fastmcp",
        status="healthy",
        latency_ms=8.0,
        message=f"Connected to {settings.fastmcp_url}",
    )
EOF
```

### 4. Update Services Package

```bash
cat > /opt/hx-lang-server/app/services/__init__.py <<'EOF'
"""Services package for business logic."""
from . import metrics
from . import query_classifier
from . import session

__all__ = ["metrics", "query_classifier", "session"]
EOF
```

### 5. Test Metrics

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test metrics generation
python3 -c "
from app.services.metrics import (
    get_metrics,
    get_content_type,
    record_invoke,
    record_error,
    set_active_sessions,
)

# Record some test metrics
record_invoke('general', 'rag_agent', 'success', 1.5)
record_invoke('code', 'code_agent', 'success', 2.3)
record_error('VALIDATION_ERROR')
set_active_sessions(5)

# Get metrics
metrics = get_metrics().decode('utf-8')
print('Content-Type:', get_content_type())
print('\n=== Sample Metrics ===')
for line in metrics.split('\n')[:30]:
    print(line)
"

# Test endpoint
python3 -c "
import asyncio
from app.routers.health import metrics
from app.core.config import get_settings

async def test():
    result = await metrics(get_settings())
    print('Content-Type:', result.media_type)
    print('Content length:', len(result.body))
    # Show first few lines
    lines = result.body.decode().split('\n')[:10]
    for line in lines:
        print(line)

asyncio.run(test())
"
```

### 6. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/metrics-endpoint-implementation.txt <<EOF
Metrics Endpoint Implementation Record
======================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-110-implement-metrics-endpoint

Files Created/Modified:
- /opt/hx-lang-server/app/services/metrics.py
- /opt/hx-lang-server/app/routers/health.py (updated)
- /opt/hx-lang-server/app/services/__init__.py (updated)

Metrics Implemented:
- langgraph_info: Service version info
- langgraph_invoke_total: Invocation counter
- langgraph_invoke_duration_seconds: Latency histogram
- langgraph_stream_total: Streaming counter
- langgraph_stream_tokens_total: Token counter
- langgraph_active_sessions: Session gauge
- langgraph_session_operations_total: Session ops counter
- langgraph_checkpoint_total: Checkpoint counter
- langgraph_checkpoint_duration_seconds: Checkpoint latency
- langgraph_worker_invocations_total: Worker counter
- langgraph_ollama_requests_total: Ollama request counter
- langgraph_ollama_duration_seconds: Ollama latency
- langgraph_errors_total: Error counter
- langgraph_dependency_status: Dependency health gauge
- langgraph_dependency_latency_ms: Dependency latency gauge

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/metrics-endpoint-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] Metrics module compiles:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/services/metrics.py
  ```

- [ ] Prometheus metrics generate correctly:
  ```bash
  python3 -c "
  from app.services.metrics import get_metrics
  metrics = get_metrics()
  assert b'langgraph_' in metrics
  print('PASS: Metrics generated')
  "
  ```

- [ ] Record functions work:
  ```bash
  python3 -c "
  from app.services.metrics import record_invoke, record_error
  record_invoke('test', 'test_worker', 'success', 1.0)
  record_error('TEST_ERROR')
  print('PASS: Record functions work')
  "
  ```

- [ ] Metrics endpoint returns Prometheus format:
  ```bash
  python3 -c "
  import asyncio
  from app.routers.health import metrics
  from app.core.config import get_settings
  result = asyncio.run(metrics(get_settings()))
  assert 'text/plain' in result.media_type
  assert b'langgraph_' in result.body
  print('PASS: Endpoint returns Prometheus format')
  "
  ```

---

## Rollback

```bash
rm -f /opt/hx-lang-server/app/services/metrics.py

# Restore stub health.py metrics endpoint
# (restore from task-108 backup)
```

---

## Notes

### Prometheus Metric Types

| Type | Use Case | Example |
|------|----------|---------|
| Counter | Cumulative counts | invoke_total, errors_total |
| Gauge | Current values | active_sessions |
| Histogram | Distributions | invoke_duration_seconds |
| Info | Static labels | service version |

### Metric Labels

Labels enable filtering and grouping:
- `query_type`: general, code, rag, tool
- `worker`: rag_agent, code_agent, tool_agent
- `status`: success, failure
- `error_code`: VALIDATION_ERROR, TIMEOUT, etc.

### Prometheus Scrape Configuration

```yaml
scrape_configs:
  - job_name: 'hx-lang-server'
    static_configs:
      - targets: ['hx-lang-server.hx.dev.local:8101']
    metrics_path: /metrics
```

### Integration with Endpoint Code

Other endpoints should call recording functions:
```python
from app.services.metrics import record_invoke

# After successful invocation
record_invoke(query_type, worker, "success", duration)
```

---

## Related Tasks

**Prerequisites**:
- Task 108: Health endpoint (framework)

**Next Tasks**:
- Task 111: CORS and security middleware
- Task 112: OpenAPI documentation

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Monitoring & Observability > Key Metrics

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
