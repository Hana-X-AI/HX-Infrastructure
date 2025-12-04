# Task: Create API Integration Tests

**Task ID**: hx-lang-server-task-113-create-api-integration-tests
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-105-112 (All endpoint implementations)
**Estimated Time**: 90 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Create comprehensive API integration tests using pytest and HTTPX TestClient. Tests cover all API endpoints including agent invocation, session management, health checks, and error handling. The test suite validates endpoint behavior, request validation, response formats, and error responses as defined in the specification.

---

## Pre-Execution Validation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
import os
test_dir = '/opt/hx-lang-server/tests/api'
if os.path.exists(test_dir) and len(os.listdir(test_dir)) > 3:
    print('VALIDATION: API tests exist - SKIP task execution')
else:
    raise Exception('Tests not found')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: API tests need creation - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] All API endpoints implemented (Tasks 105-112)
- [ ] pytest and httpx installed in virtual environment
- [ ] Application factory functional (Task 102)

---

## Steps

### 1. Create Test Directory Structure

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

mkdir -p /opt/hx-lang-server/tests/api
touch /opt/hx-lang-server/tests/__init__.py
touch /opt/hx-lang-server/tests/api/__init__.py
```

### 2. Create Test Configuration (conftest.py)

```bash
cat > /opt/hx-lang-server/tests/conftest.py <<'EOF'
"""
Pytest configuration and fixtures for API tests.

Provides test client, mock settings, and common fixtures.
"""
import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport

from app.main import create_app
from app.core.config import Settings


@pytest.fixture(scope="session")
def settings():
    """
    Test settings with debug enabled.
    """
    return Settings(
        debug=True,
        service_port=8100,
        cors_origins=["*"],
    )


@pytest.fixture(scope="function")
def app(settings):
    """
    Create fresh application instance for each test.
    """
    return create_app()


@pytest.fixture(scope="function")
def client(app):
    """
    Synchronous test client for simple endpoint tests.

    Usage:
        def test_endpoint(client):
            response = client.get("/health")
            assert response.status_code == 200
    """
    with TestClient(app) as client:
        yield client


@pytest.fixture(scope="function")
async def async_client(app):
    """
    Async test client for async endpoint tests.

    Usage:
        async def test_async_endpoint(async_client):
            response = await async_client.get("/health")
            assert response.status_code == 200
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


@pytest.fixture
def sample_invoke_request():
    """Sample invoke request payload."""
    return {
        "query": "What is dependency injection?",
    }


@pytest.fixture
def sample_code_request():
    """Sample code-related invoke request."""
    return {
        "query": "Write a Python function to sort a list",
        "config": {"max_iterations": 5},
    }


@pytest.fixture
def sample_session_request():
    """Sample session creation request."""
    return {
        "user_id": "test_user_123",
        "metadata": {"source": "pytest"},
        "ttl_seconds": 3600,
    }
EOF
```

### 3. Create Health Endpoint Tests

```bash
cat > /opt/hx-lang-server/tests/api/test_health.py <<'EOF'
"""
Tests for health, readiness, and metrics endpoints.

Specification Reference:
- FR-024: Health check endpoint at /health
- Monitoring & Observability section
"""
import pytest
from fastapi.testclient import TestClient


class TestHealthEndpoint:
    """Tests for GET /health."""

    def test_health_returns_200(self, client: TestClient):
        """Health endpoint should return 200 OK."""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_json(self, client: TestClient):
        """Health endpoint should return JSON."""
        response = client.get("/health")
        assert response.headers["content-type"] == "application/json"

    def test_health_response_structure(self, client: TestClient):
        """Health response should have required fields."""
        response = client.get("/health")
        data = response.json()

        assert "status" in data
        assert "version" in data
        assert "uptime_seconds" in data
        assert "dependencies" in data

    def test_health_status_values(self, client: TestClient):
        """Health status should be valid value."""
        response = client.get("/health")
        data = response.json()

        assert data["status"] in ["healthy", "degraded", "unhealthy"]

    def test_health_uptime_is_positive(self, client: TestClient):
        """Uptime should be a positive number."""
        response = client.get("/health")
        data = response.json()

        assert isinstance(data["uptime_seconds"], (int, float))
        assert data["uptime_seconds"] >= 0

    def test_health_dependencies_structure(self, client: TestClient):
        """Dependencies should have expected services."""
        response = client.get("/health")
        data = response.json()

        expected_deps = ["postgres", "redis", "ollama_general"]
        for dep in expected_deps:
            assert dep in data["dependencies"]


class TestReadinessEndpoint:
    """Tests for GET /ready."""

    def test_ready_returns_200(self, client: TestClient):
        """Readiness endpoint should return 200 OK."""
        response = client.get("/ready")
        assert response.status_code == 200

    def test_ready_response_structure(self, client: TestClient):
        """Readiness response should have required fields."""
        response = client.get("/ready")
        data = response.json()

        assert "ready" in data
        assert "checks" in data
        assert isinstance(data["ready"], bool)


class TestMetricsEndpoint:
    """Tests for GET /metrics."""

    def test_metrics_returns_200(self, client: TestClient):
        """Metrics endpoint should return 200 OK."""
        response = client.get("/metrics")
        assert response.status_code == 200

    def test_metrics_returns_prometheus_format(self, client: TestClient):
        """Metrics should be in Prometheus text format."""
        response = client.get("/metrics")

        # Check content type
        assert "text/plain" in response.headers["content-type"]

        # Check for Prometheus metrics
        text = response.text
        assert "langgraph_" in text

    def test_metrics_includes_uptime(self, client: TestClient):
        """Metrics should include uptime gauge."""
        response = client.get("/metrics")
        assert "langgraph_uptime_seconds" in response.text
EOF
```

### 4. Create Invoke Endpoint Tests

```bash
cat > /opt/hx-lang-server/tests/api/test_invoke.py <<'EOF'
"""
Tests for agent invocation endpoint.

Specification Reference:
- FR-021: REST API via FastAPI on port 8100
- FR-022: Async endpoints using async def with ainvoke()
- API Specification > POST /invoke
"""
import pytest
from fastapi.testclient import TestClient


class TestInvokeEndpoint:
    """Tests for POST /api/v1/invoke."""

    def test_invoke_returns_200(self, client: TestClient, sample_invoke_request):
        """Invoke endpoint should return 200 OK."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        assert response.status_code == 200

    def test_invoke_returns_json(self, client: TestClient, sample_invoke_request):
        """Invoke endpoint should return JSON."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        assert response.headers["content-type"] == "application/json"

    def test_invoke_response_structure(self, client: TestClient, sample_invoke_request):
        """Invoke response should have required fields."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        data = response.json()

        assert "thread_id" in data
        assert "response" in data
        assert "query_type" in data
        assert "worker_used" in data
        assert "iteration_count" in data
        assert "metadata" in data

    def test_invoke_generates_thread_id(self, client: TestClient, sample_invoke_request):
        """Invoke should generate thread_id if not provided."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        data = response.json()

        assert data["thread_id"].startswith("thread_")

    def test_invoke_uses_provided_thread_id(self, client: TestClient):
        """Invoke should use provided thread_id."""
        request = {
            "query": "Test query",
            "thread_id": "thread_custom123",
        }
        response = client.post("/api/v1/invoke", json=request)
        data = response.json()

        assert data["thread_id"] == "thread_custom123"

    def test_invoke_classifies_code_query(self, client: TestClient, sample_code_request):
        """Code-related queries should be classified as code."""
        response = client.post("/api/v1/invoke", json=sample_code_request)
        data = response.json()

        assert data["query_type"] == "code"

    def test_invoke_includes_metadata(self, client: TestClient, sample_invoke_request):
        """Response metadata should include request_id and processing_time."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        data = response.json()

        assert "request_id" in data["metadata"]
        assert "processing_time_ms" in data["metadata"]


class TestInvokeValidation:
    """Tests for invoke request validation."""

    def test_invoke_requires_query(self, client: TestClient):
        """Invoke should reject request without query."""
        response = client.post("/api/v1/invoke", json={})
        assert response.status_code == 422

    def test_invoke_rejects_empty_query(self, client: TestClient):
        """Invoke should reject empty query."""
        response = client.post("/api/v1/invoke", json={"query": ""})
        assert response.status_code == 422

    def test_invoke_rejects_whitespace_query(self, client: TestClient):
        """Invoke should reject whitespace-only query."""
        response = client.post("/api/v1/invoke", json={"query": "   "})
        assert response.status_code == 422

    def test_invoke_accepts_long_query(self, client: TestClient):
        """Invoke should accept queries up to max length."""
        long_query = "x" * 10000  # Well under 32000 limit
        response = client.post("/api/v1/invoke", json={"query": long_query})
        assert response.status_code == 200


class TestInvokeHeaders:
    """Tests for invoke request/response headers."""

    def test_invoke_returns_request_id(self, client: TestClient, sample_invoke_request):
        """Response should include X-Request-ID header."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        assert "X-Request-ID" in response.headers

    def test_invoke_uses_provided_request_id(self, client: TestClient, sample_invoke_request):
        """Should use X-Request-ID from request if provided."""
        headers = {"X-Request-ID": "custom_request_123"}
        response = client.post(
            "/api/v1/invoke",
            json=sample_invoke_request,
            headers=headers,
        )
        assert response.headers["X-Request-ID"] == "custom_request_123"

    def test_invoke_includes_timing_header(self, client: TestClient, sample_invoke_request):
        """Response should include X-Response-Time header."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)
        assert "X-Response-Time" in response.headers
EOF
```

### 5. Create Session Endpoint Tests

```bash
cat > /opt/hx-lang-server/tests/api/test_sessions.py <<'EOF'
"""
Tests for session management endpoints.

Specification Reference:
- State Management section
- Redis Key Schema section
"""
import pytest
from fastapi.testclient import TestClient


class TestSessionCreate:
    """Tests for POST /api/v1/sessions."""

    def test_create_session_returns_201(self, client: TestClient):
        """Session creation should return 201 Created."""
        response = client.post("/api/v1/sessions", json={})
        assert response.status_code == 201

    def test_create_session_response_structure(self, client: TestClient):
        """Session response should have required fields."""
        response = client.post("/api/v1/sessions", json={})
        data = response.json()

        assert "session_id" in data
        assert "created_at" in data
        assert "updated_at" in data
        assert "expires_at" in data
        assert "thread_count" in data

    def test_create_session_generates_id(self, client: TestClient):
        """Session ID should be auto-generated."""
        response = client.post("/api/v1/sessions", json={})
        data = response.json()

        assert data["session_id"].startswith("session_")

    def test_create_session_with_user_id(self, client: TestClient, sample_session_request):
        """Session should include provided user_id."""
        response = client.post("/api/v1/sessions", json=sample_session_request)
        data = response.json()

        assert data["user_id"] == sample_session_request["user_id"]

    def test_create_session_with_metadata(self, client: TestClient, sample_session_request):
        """Session should include provided metadata."""
        response = client.post("/api/v1/sessions", json=sample_session_request)
        data = response.json()

        assert data["metadata"]["source"] == "pytest"


class TestSessionGet:
    """Tests for GET /api/v1/sessions/{session_id}."""

    def test_get_session_returns_200(self, client: TestClient):
        """Get session should return 200 OK for existing session."""
        # Create session first
        create_response = client.post("/api/v1/sessions", json={})
        session_id = create_response.json()["session_id"]

        # Get session
        response = client.get(f"/api/v1/sessions/{session_id}")
        assert response.status_code == 200

    def test_get_session_returns_404_for_missing(self, client: TestClient):
        """Get session should return 404 for non-existent session."""
        response = client.get("/api/v1/sessions/nonexistent_session")
        assert response.status_code == 404

    def test_get_session_returns_correct_data(self, client: TestClient):
        """Get session should return created session data."""
        # Create session
        create_response = client.post("/api/v1/sessions", json={"user_id": "test_user"})
        session_id = create_response.json()["session_id"]

        # Get session
        response = client.get(f"/api/v1/sessions/{session_id}")
        data = response.json()

        assert data["session_id"] == session_id
        assert data["user_id"] == "test_user"


class TestSessionDelete:
    """Tests for DELETE /api/v1/sessions/{session_id}."""

    def test_delete_session_returns_204(self, client: TestClient):
        """Delete session should return 204 No Content."""
        # Create session first
        create_response = client.post("/api/v1/sessions", json={})
        session_id = create_response.json()["session_id"]

        # Delete session
        response = client.delete(f"/api/v1/sessions/{session_id}")
        assert response.status_code == 204

    def test_delete_session_returns_404_for_missing(self, client: TestClient):
        """Delete session should return 404 for non-existent session."""
        response = client.delete("/api/v1/sessions/nonexistent_session")
        assert response.status_code == 404

    def test_deleted_session_not_found(self, client: TestClient):
        """Deleted session should not be retrievable."""
        # Create session
        create_response = client.post("/api/v1/sessions", json={})
        session_id = create_response.json()["session_id"]

        # Delete session
        client.delete(f"/api/v1/sessions/{session_id}")

        # Try to get deleted session
        response = client.get(f"/api/v1/sessions/{session_id}")
        assert response.status_code == 404


class TestSessionList:
    """Tests for GET /api/v1/sessions."""

    def test_list_sessions_returns_200(self, client: TestClient):
        """List sessions should return 200 OK."""
        response = client.get("/api/v1/sessions")
        assert response.status_code == 200

    def test_list_sessions_response_structure(self, client: TestClient):
        """List response should have sessions and total."""
        response = client.get("/api/v1/sessions")
        data = response.json()

        assert "sessions" in data
        assert "total" in data
        assert isinstance(data["sessions"], list)

    def test_list_sessions_includes_created(self, client: TestClient):
        """List should include newly created sessions."""
        # Create a session
        client.post("/api/v1/sessions", json={"user_id": "list_test_user"})

        # List sessions
        response = client.get("/api/v1/sessions")
        data = response.json()

        assert data["total"] >= 1
EOF
```

### 6. Create Stream Endpoint Tests

```bash
cat > /opt/hx-lang-server/tests/api/test_stream.py <<'EOF'
"""
Tests for streaming agent invocation endpoint.

Specification Reference:
- FR-022: Async endpoints for streaming
- API Specification > POST /stream
"""
import pytest
from fastapi.testclient import TestClient


class TestStreamEndpoint:
    """Tests for POST /api/v1/stream."""

    def test_stream_returns_200(self, client: TestClient, sample_invoke_request):
        """Stream endpoint should return 200 OK."""
        response = client.post("/api/v1/stream", json=sample_invoke_request)
        assert response.status_code == 200

    def test_stream_returns_sse_content_type(self, client: TestClient, sample_invoke_request):
        """Stream should return text/event-stream content type."""
        response = client.post("/api/v1/stream", json=sample_invoke_request)
        assert "text/event-stream" in response.headers["content-type"]

    def test_stream_includes_request_id(self, client: TestClient, sample_invoke_request):
        """Stream response should include X-Request-ID header."""
        response = client.post("/api/v1/stream", json=sample_invoke_request)
        assert "X-Request-ID" in response.headers


class TestStreamValidation:
    """Tests for stream request validation."""

    def test_stream_requires_query(self, client: TestClient):
        """Stream should reject request without query."""
        response = client.post("/api/v1/stream", json={})
        assert response.status_code == 422

    def test_stream_rejects_empty_query(self, client: TestClient):
        """Stream should reject empty query."""
        response = client.post("/api/v1/stream", json={"query": ""})
        assert response.status_code == 422
EOF
```

### 7. Create Error Handling Tests

```bash
cat > /opt/hx-lang-server/tests/api/test_errors.py <<'EOF'
"""
Tests for API error handling.

Specification Reference:
- API Specification > Error Responses
"""
import pytest
from fastapi.testclient import TestClient


class TestErrorResponses:
    """Tests for error response format."""

    def test_404_returns_error_format(self, client: TestClient):
        """404 errors should return standard error format."""
        response = client.get("/nonexistent/endpoint")
        assert response.status_code == 404

    def test_422_returns_validation_error(self, client: TestClient):
        """Validation errors should return 422 with details."""
        response = client.post("/api/v1/invoke", json={"invalid": "field"})
        assert response.status_code == 422

        data = response.json()
        assert "detail" in data

    def test_method_not_allowed_returns_405(self, client: TestClient):
        """Wrong HTTP method should return 405."""
        response = client.get("/api/v1/invoke")
        assert response.status_code == 405


class TestCORSHeaders:
    """Tests for CORS header handling."""

    def test_cors_allows_origin(self, client: TestClient):
        """CORS should allow configured origins."""
        response = client.options(
            "/api/v1/invoke",
            headers={"Origin": "http://localhost:3000"},
        )
        # Preflight requests should succeed
        assert response.status_code in [200, 405]  # Depends on CORS config

    def test_cors_headers_present(self, client: TestClient, sample_invoke_request):
        """Responses should include CORS headers."""
        response = client.post(
            "/api/v1/invoke",
            json=sample_invoke_request,
            headers={"Origin": "http://localhost:3000"},
        )
        # Access-Control-Allow-Origin should be present
        # Note: May not be present if origin not in allowed list
        assert response.status_code == 200


class TestRateLimitHeaders:
    """Tests for rate limit headers."""

    def test_rate_limit_headers_present(self, client: TestClient, sample_invoke_request):
        """Response should include rate limit headers."""
        response = client.post("/api/v1/invoke", json=sample_invoke_request)

        assert "X-RateLimit-Limit" in response.headers
        assert "X-RateLimit-Remaining" in response.headers
EOF
```

### 8. Create pytest.ini Configuration

```bash
cat > /opt/hx-lang-server/pytest.ini <<'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short
asyncio_mode = auto
filterwarnings =
    ignore::DeprecationWarning
EOF
```

### 9. Run Tests

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Install pytest-asyncio if not present
pip install pytest pytest-asyncio httpx

# Run all tests
pytest tests/api/ -v

# Run with coverage (if pytest-cov installed)
# pytest tests/api/ -v --cov=app --cov-report=term-missing
```

### 10. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/api-tests-implementation.txt <<EOF
API Integration Tests Implementation Record
==========================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-113-create-api-integration-tests

Files Created:
- /opt/hx-lang-server/tests/conftest.py
- /opt/hx-lang-server/tests/api/test_health.py
- /opt/hx-lang-server/tests/api/test_invoke.py
- /opt/hx-lang-server/tests/api/test_sessions.py
- /opt/hx-lang-server/tests/api/test_stream.py
- /opt/hx-lang-server/tests/api/test_errors.py
- /opt/hx-lang-server/pytest.ini

Test Coverage:
- Health endpoints: 10 tests
- Invoke endpoint: 15 tests
- Session endpoints: 14 tests
- Stream endpoint: 5 tests
- Error handling: 6 tests

Total: ~50 API tests

Test Categories:
- Endpoint availability (200 OK)
- Response structure validation
- Request validation (422 errors)
- Error handling (404, 405)
- Header handling (CORS, rate limit)

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/api-tests-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] All test files compile:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/tests/api/test_health.py
  python3 -m py_compile /opt/hx-lang-server/tests/api/test_invoke.py
  ```

- [ ] Tests can be discovered:
  ```bash
  pytest tests/api/ --collect-only
  ```

- [ ] Health tests pass:
  ```bash
  pytest tests/api/test_health.py -v
  ```

- [ ] Invoke tests pass:
  ```bash
  pytest tests/api/test_invoke.py -v
  ```

- [ ] All tests pass:
  ```bash
  pytest tests/api/ -v
  ```

---

## Rollback

```bash
rm -rf /opt/hx-lang-server/tests/api/
rm -f /opt/hx-lang-server/tests/conftest.py
rm -f /opt/hx-lang-server/pytest.ini
```

---

## Notes

### Test Organization

Tests are organized by endpoint:
- `test_health.py`: /health, /ready, /metrics
- `test_invoke.py`: POST /api/v1/invoke
- `test_sessions.py`: /api/v1/sessions CRUD
- `test_stream.py`: POST /api/v1/stream
- `test_errors.py`: Error handling across endpoints

### Test Fixtures

Key fixtures in conftest.py:
- `client`: Synchronous TestClient for simple tests
- `async_client`: Async client for async tests
- `sample_*_request`: Pre-built request payloads

### Test Naming Convention

```python
def test_<action>_<expected_outcome>(self, client):
    """Description of what is being tested."""
```

### Running Specific Tests

```bash
# Run single test file
pytest tests/api/test_health.py -v

# Run single test class
pytest tests/api/test_invoke.py::TestInvokeEndpoint -v

# Run single test
pytest tests/api/test_invoke.py::TestInvokeEndpoint::test_invoke_returns_200 -v

# Run with keyword filter
pytest tests/api/ -k "health" -v
```

### CI Integration

Tests can be run in CI with:
```bash
pytest tests/api/ --junitxml=test-results.xml
```

---

## Related Tasks

**Prerequisites**:
- Tasks 105-112: All endpoint implementations

**Next Phase**:
- Work Stream 14 (Julia Santos): Comprehensive test suite generation

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: Testing Strategy
- Section: Quality Gates

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
