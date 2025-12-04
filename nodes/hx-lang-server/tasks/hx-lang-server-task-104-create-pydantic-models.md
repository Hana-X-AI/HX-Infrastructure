# Task: Create Pydantic Request/Response Models

**Task ID**: hx-lang-server-task-104-create-pydantic-models
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-101 (FastAPI application structure), hx-lang-server-task-103 (Pydantic config)
**Estimated Time**: 60 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Create comprehensive Pydantic models for API request validation and response serialization. These models define the contract for all API endpoints including agent invocation, session management, health checks, and error responses. Models align with the specification's Request/Response Models section and support automatic OpenAPI schema generation.

---

## Pre-Execution Validation

**CRITICAL**: Check if models are already implemented BEFORE executing steps.

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
from app.models.requests import InvokeRequest
from app.models.responses import InvokeResponse, HealthResponse
from app.models.errors import ErrorResponse
print('VALIDATION: Models complete - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Models incomplete - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] FastAPI application structure created (Task 101)
- [ ] Pydantic v2.9+ installed in virtual environment
- [ ] models/ directory exists at `/opt/hx-lang-server/app/models/`

---

## Steps

### 1. Create Request Models

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

cat > /opt/hx-lang-server/app/models/requests.py <<'EOF'
"""
Pydantic models for API request validation.

These models define the structure for incoming API requests,
providing validation and automatic OpenAPI schema generation.

Specification Reference: API Specification > Request/Response Models
"""
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, field_validator


class InvokeRequest(BaseModel):
    """
    Request model for synchronous agent invocation (POST /api/v1/invoke).

    Specification Reference: FR-021, FR-022
    """
    query: str = Field(
        ...,
        min_length=1,
        max_length=32000,
        description="User query to process",
        json_schema_extra={"example": "Explain the concept of dependency injection"}
    )
    thread_id: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Thread ID for conversation continuation. "
                    "If not provided, a new thread is created.",
        json_schema_extra={"example": "thread_abc123"}
    )
    session_id: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Session ID for grouping related conversations",
        json_schema_extra={"example": "session_xyz789"}
    )
    config: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Agent configuration overrides",
        json_schema_extra={
            "example": {
                "max_iterations": 10,
                "timeout_seconds": 60
            }
        }
    )

    @field_validator("query")
    @classmethod
    def validate_query_not_empty(cls, v: str) -> str:
        """Ensure query is not just whitespace."""
        if not v.strip():
            raise ValueError("Query cannot be empty or whitespace only")
        return v.strip()


class StreamRequest(BaseModel):
    """
    Request model for streaming agent invocation (POST /api/v1/stream).

    Similar to InvokeRequest but explicitly for SSE streaming responses.
    Specification Reference: FR-022
    """
    query: str = Field(
        ...,
        min_length=1,
        max_length=32000,
        description="User query to process with streaming response"
    )
    thread_id: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Thread ID for conversation continuation"
    )
    session_id: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Session ID for grouping related conversations"
    )
    config: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Agent configuration overrides"
    )

    @field_validator("query")
    @classmethod
    def validate_query_not_empty(cls, v: str) -> str:
        """Ensure query is not just whitespace."""
        if not v.strip():
            raise ValueError("Query cannot be empty or whitespace only")
        return v.strip()


class SessionCreateRequest(BaseModel):
    """
    Request model for creating a new session (POST /api/v1/sessions).

    Specification Reference: State Management section
    """
    user_id: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Optional user identifier",
        json_schema_extra={"example": "user_12345"}
    )
    metadata: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Optional session metadata",
        json_schema_extra={
            "example": {
                "source": "n8n",
                "workflow_id": "wf_abc123"
            }
        }
    )
    ttl_seconds: Optional[int] = Field(
        default=None,
        ge=300,
        le=86400,
        description="Session TTL override (300-86400 seconds)"
    )


class WebhookRegisterRequest(BaseModel):
    """
    Request model for webhook callback registration (POST /webhooks).

    Specification Reference: n8n Integration section
    """
    callback_url: str = Field(
        ...,
        description="URL to receive webhook callbacks",
        json_schema_extra={"example": "http://hx-n8n-server.hx.dev.local:5678/webhook/callback"}
    )
    events: List[str] = Field(
        default=["task_complete"],
        description="Events to subscribe to",
        json_schema_extra={"example": ["task_complete", "task_error"]}
    )
    secret: Optional[str] = Field(
        default=None,
        max_length=256,
        description="Shared secret for webhook signature verification"
    )

    @field_validator("callback_url")
    @classmethod
    def validate_callback_url(cls, v: str) -> str:
        """Validate callback URL format."""
        if not v.startswith(("http://", "https://")):
            raise ValueError("callback_url must be a valid HTTP(S) URL")
        return v
EOF
```

### 2. Create Response Models

```bash
cat > /opt/hx-lang-server/app/models/responses.py <<'EOF'
"""
Pydantic models for API response serialization.

These models define the structure for outgoing API responses,
ensuring consistent response formats across all endpoints.

Specification Reference: API Specification > Request/Response Models
"""
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class InvokeResponse(BaseModel):
    """
    Response model for agent invocation (POST /api/v1/invoke).

    Specification Reference: API Specification section
    """
    thread_id: str = Field(
        ...,
        description="Thread ID for this conversation",
        json_schema_extra={"example": "thread_abc123"}
    )
    response: str = Field(
        ...,
        description="Agent response text",
        json_schema_extra={"example": "Dependency injection is a design pattern..."}
    )
    query_type: str = Field(
        ...,
        description="Classified query type: general, code, rag, tool",
        json_schema_extra={"example": "rag"}
    )
    worker_used: str = Field(
        ...,
        description="Worker agent that processed the query",
        json_schema_extra={"example": "rag_agent"}
    )
    iteration_count: int = Field(
        ...,
        ge=0,
        description="Number of agent iterations performed",
        json_schema_extra={"example": 3}
    )
    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional response metadata",
        json_schema_extra={
            "example": {
                "llm_used": "ollama1",
                "model": "gemma3:27b",
                "processing_time_ms": 2345
            }
        }
    )


class StreamChunk(BaseModel):
    """
    Model for individual chunks in streaming response (SSE).

    Used with POST /api/v1/stream endpoint.
    """
    chunk_type: str = Field(
        ...,
        description="Type: token, metadata, error, done",
        json_schema_extra={"example": "token"}
    )
    content: Optional[str] = Field(
        default=None,
        description="Token content for 'token' chunks"
    )
    metadata: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Metadata for 'metadata' chunks"
    )
    thread_id: Optional[str] = Field(
        default=None,
        description="Thread ID (included in first and last chunks)"
    )


class SessionResponse(BaseModel):
    """
    Response model for session operations.

    Specification Reference: State Management section
    """
    session_id: str = Field(
        ...,
        description="Unique session identifier",
        json_schema_extra={"example": "session_xyz789"}
    )
    user_id: Optional[str] = Field(
        default=None,
        description="Associated user ID"
    )
    created_at: datetime = Field(
        ...,
        description="Session creation timestamp"
    )
    updated_at: datetime = Field(
        ...,
        description="Last activity timestamp"
    )
    expires_at: datetime = Field(
        ...,
        description="Session expiration timestamp"
    )
    thread_count: int = Field(
        default=0,
        ge=0,
        description="Number of threads in this session"
    )
    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Session metadata"
    )


class SessionListResponse(BaseModel):
    """
    Response model for listing sessions.
    """
    sessions: List[SessionResponse] = Field(
        default_factory=list,
        description="List of sessions"
    )
    total: int = Field(
        ...,
        ge=0,
        description="Total number of sessions"
    )


class ThreadResponse(BaseModel):
    """
    Response model for thread retrieval (GET /threads/{thread_id}).

    Specification Reference: API Endpoints section
    """
    thread_id: str = Field(
        ...,
        description="Thread identifier"
    )
    session_id: Optional[str] = Field(
        default=None,
        description="Parent session ID"
    )
    message_count: int = Field(
        ...,
        ge=0,
        description="Number of messages in thread"
    )
    created_at: datetime = Field(
        ...,
        description="Thread creation timestamp"
    )
    updated_at: datetime = Field(
        ...,
        description="Last message timestamp"
    )
    messages: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Thread message history"
    )


class DependencyStatus(BaseModel):
    """
    Status of a single dependency service.
    """
    name: str = Field(
        ...,
        description="Dependency name",
        json_schema_extra={"example": "postgres"}
    )
    status: str = Field(
        ...,
        description="Status: healthy, degraded, unhealthy",
        json_schema_extra={"example": "healthy"}
    )
    latency_ms: Optional[float] = Field(
        default=None,
        description="Connection latency in milliseconds"
    )
    message: Optional[str] = Field(
        default=None,
        description="Additional status message"
    )


class HealthResponse(BaseModel):
    """
    Response model for health check endpoint (GET /health).

    Specification Reference: Monitoring & Observability section
    """
    status: str = Field(
        ...,
        description="Overall status: healthy, degraded, unhealthy",
        json_schema_extra={"example": "healthy"}
    )
    version: str = Field(
        ...,
        description="Application version",
        json_schema_extra={"example": "1.0.0"}
    )
    uptime_seconds: float = Field(
        ...,
        ge=0,
        description="Service uptime in seconds"
    )
    dependencies: Dict[str, DependencyStatus] = Field(
        default_factory=dict,
        description="Status of all dependencies"
    )


class ReadyResponse(BaseModel):
    """
    Response model for readiness probe (GET /ready).

    Returns detailed status of all critical dependencies.
    """
    ready: bool = Field(
        ...,
        description="True if service is ready to accept requests"
    )
    checks: Dict[str, bool] = Field(
        default_factory=dict,
        description="Individual readiness checks",
        json_schema_extra={
            "example": {
                "postgres": True,
                "redis": True,
                "ollama_general": True,
                "ollama_code": True,
                "lightrag": True
            }
        }
    )
    message: Optional[str] = Field(
        default=None,
        description="Additional readiness information"
    )


class WebhookResponse(BaseModel):
    """
    Response model for webhook registration.
    """
    webhook_id: str = Field(
        ...,
        description="Unique webhook identifier"
    )
    callback_url: str = Field(
        ...,
        description="Registered callback URL"
    )
    events: List[str] = Field(
        ...,
        description="Subscribed events"
    )
    created_at: datetime = Field(
        ...,
        description="Registration timestamp"
    )


class MetricsResponse(BaseModel):
    """
    Response model for Prometheus metrics (GET /metrics).

    Returns metrics in Prometheus text format.
    """
    content_type: str = Field(
        default="text/plain; version=0.0.4; charset=utf-8",
        description="Prometheus metrics content type"
    )
    metrics: str = Field(
        ...,
        description="Prometheus metrics in text format"
    )
EOF
```

### 3. Create Error Models

```bash
cat > /opt/hx-lang-server/app/models/errors.py <<'EOF'
"""
Pydantic models for error responses.

Standardized error response format for all API endpoints.
Specification Reference: API Specification > Error Responses
"""
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


# Error code constants (from specification)
ERROR_CODES = {
    "INVALID_REQUEST": 400,
    "VALIDATION_ERROR": 422,
    "UNAUTHORIZED": 401,
    "FORBIDDEN": 403,
    "NOT_FOUND": 404,
    "RATE_LIMITED": 429,
    "INTERNAL_ERROR": 500,
    "OLLAMA_UNAVAILABLE": 503,
    "LIGHTRAG_UNAVAILABLE": 503,
    "POSTGRES_UNAVAILABLE": 503,
    "REDIS_UNAVAILABLE": 503,
    "CHECKPOINT_FAILED": 500,
    "MCP_ERROR": 502,
    "TIMEOUT": 504,
}


class ErrorDetail(BaseModel):
    """
    Detailed error information for validation errors.
    """
    loc: List[str] = Field(
        ...,
        description="Location of error in request",
        json_schema_extra={"example": ["body", "query"]}
    )
    msg: str = Field(
        ...,
        description="Error message",
        json_schema_extra={"example": "field required"}
    )
    type: str = Field(
        ...,
        description="Error type",
        json_schema_extra={"example": "value_error.missing"}
    )


class ErrorResponse(BaseModel):
    """
    Standard error response model.

    Used for all API error responses to provide consistent format.
    Specification Reference: Error Responses section
    """
    error: str = Field(
        ...,
        description="Human-readable error message",
        json_schema_extra={"example": "Request validation failed"}
    )
    error_code: str = Field(
        ...,
        description="Machine-readable error code",
        json_schema_extra={"example": "VALIDATION_ERROR"}
    )
    detail: Optional[str] = Field(
        default=None,
        description="Additional error details",
        json_schema_extra={"example": "Query field is required"}
    )
    request_id: str = Field(
        ...,
        description="Request ID for tracing",
        json_schema_extra={"example": "req_abc123xyz"}
    )
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Error timestamp (UTC)"
    )
    path: Optional[str] = Field(
        default=None,
        description="Request path that caused error"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "error": "Request validation failed",
                "error_code": "VALIDATION_ERROR",
                "detail": "Query field is required",
                "request_id": "req_abc123xyz",
                "timestamp": "2025-12-04T10:30:00Z",
                "path": "/api/v1/invoke"
            }
        }
    }


class ValidationErrorResponse(BaseModel):
    """
    Specialized error response for validation errors (422).

    Includes detailed field-level error information.
    """
    error: str = Field(
        default="Validation error",
        description="Error message"
    )
    error_code: str = Field(
        default="VALIDATION_ERROR",
        description="Error code"
    )
    detail: List[ErrorDetail] = Field(
        ...,
        description="List of validation errors"
    )
    request_id: str = Field(
        ...,
        description="Request ID for tracing"
    )


class RateLimitErrorResponse(BaseModel):
    """
    Specialized error response for rate limiting (429).

    Includes retry information.
    """
    error: str = Field(
        default="Rate limit exceeded",
        description="Error message"
    )
    error_code: str = Field(
        default="RATE_LIMITED",
        description="Error code"
    )
    retry_after_seconds: int = Field(
        ...,
        description="Seconds to wait before retry",
        json_schema_extra={"example": 60}
    )
    limit: int = Field(
        ...,
        description="Rate limit (requests per window)",
        json_schema_extra={"example": 100}
    )
    window_seconds: int = Field(
        ...,
        description="Rate limit window in seconds",
        json_schema_extra={"example": 60}
    )
    request_id: str = Field(
        ...,
        description="Request ID for tracing"
    )


class ServiceUnavailableResponse(BaseModel):
    """
    Specialized error response for service unavailability (503).

    Used when dependencies like Ollama, LightRAG, etc. are unavailable.
    """
    error: str = Field(
        ...,
        description="Error message",
        json_schema_extra={"example": "Ollama service unavailable"}
    )
    error_code: str = Field(
        ...,
        description="Error code: OLLAMA_UNAVAILABLE, LIGHTRAG_UNAVAILABLE, etc."
    )
    service: str = Field(
        ...,
        description="Name of unavailable service",
        json_schema_extra={"example": "ollama_general"}
    )
    retry_after_seconds: Optional[int] = Field(
        default=None,
        description="Suggested retry delay"
    )
    request_id: str = Field(
        ...,
        description="Request ID for tracing"
    )
EOF
```

### 4. Update Models Package __init__.py

```bash
cat > /opt/hx-lang-server/app/models/__init__.py <<'EOF'
"""
Pydantic models package for API request/response handling.

Exports all model classes for convenient importing:
    from app.models import InvokeRequest, InvokeResponse, ErrorResponse
"""
from app.models.requests import (
    InvokeRequest,
    StreamRequest,
    SessionCreateRequest,
    WebhookRegisterRequest,
)
from app.models.responses import (
    InvokeResponse,
    StreamChunk,
    SessionResponse,
    SessionListResponse,
    ThreadResponse,
    HealthResponse,
    ReadyResponse,
    DependencyStatus,
    WebhookResponse,
    MetricsResponse,
)
from app.models.errors import (
    ERROR_CODES,
    ErrorDetail,
    ErrorResponse,
    ValidationErrorResponse,
    RateLimitErrorResponse,
    ServiceUnavailableResponse,
)

__all__ = [
    # Requests
    "InvokeRequest",
    "StreamRequest",
    "SessionCreateRequest",
    "WebhookRegisterRequest",
    # Responses
    "InvokeResponse",
    "StreamChunk",
    "SessionResponse",
    "SessionListResponse",
    "ThreadResponse",
    "HealthResponse",
    "ReadyResponse",
    "DependencyStatus",
    "WebhookResponse",
    "MetricsResponse",
    # Errors
    "ERROR_CODES",
    "ErrorDetail",
    "ErrorResponse",
    "ValidationErrorResponse",
    "RateLimitErrorResponse",
    "ServiceUnavailableResponse",
]
EOF
```

### 5. Test Model Imports and Validation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test all models can be imported
python3 -c "
from app.models import (
    InvokeRequest, StreamRequest, SessionCreateRequest,
    InvokeResponse, HealthResponse, SessionResponse,
    ErrorResponse, ERROR_CODES
)
print('All models imported successfully')
"

# Test InvokeRequest validation
python3 -c "
from app.models import InvokeRequest
from pydantic import ValidationError

# Valid request
req = InvokeRequest(query='Test query')
print(f'Valid request: query={req.query}')

# Test whitespace rejection
try:
    InvokeRequest(query='   ')
    print('FAIL: Should reject whitespace-only query')
except ValidationError as e:
    print('PASS: Whitespace-only query rejected')

# Test query length limit
try:
    InvokeRequest(query='x' * 33000)
    print('FAIL: Should reject oversized query')
except ValidationError:
    print('PASS: Oversized query rejected')
"

# Test response models
python3 -c "
from datetime import datetime
from app.models import InvokeResponse, HealthResponse

# Create InvokeResponse
resp = InvokeResponse(
    thread_id='thread_123',
    response='Test response',
    query_type='general',
    worker_used='rag_agent',
    iteration_count=2,
    metadata={'model': 'gemma3:27b'}
)
print(f'InvokeResponse created: {resp.thread_id}')

# Create HealthResponse
health = HealthResponse(
    status='healthy',
    version='1.0.0',
    uptime_seconds=3600.5,
    dependencies={}
)
print(f'HealthResponse created: status={health.status}')
"

# Test error models
python3 -c "
from datetime import datetime
from app.models import ErrorResponse, ERROR_CODES

# Create error response
err = ErrorResponse(
    error='Test error',
    error_code='VALIDATION_ERROR',
    detail='Details here',
    request_id='req_123'
)
print(f'ErrorResponse: {err.error_code} -> HTTP {ERROR_CODES[err.error_code]}')
"
```

### 6. Test JSON Schema Generation

```bash
python3 -c "
from app.models import InvokeRequest, InvokeResponse, ErrorResponse
import json

# Generate JSON schemas (for OpenAPI)
print('=== InvokeRequest Schema ===')
print(json.dumps(InvokeRequest.model_json_schema(), indent=2))

print('\n=== InvokeResponse Schema ===')
print(json.dumps(InvokeResponse.model_json_schema(), indent=2))
"
```

### 7. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/models-implementation.txt <<EOF
Pydantic Models Implementation Record
=====================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-104-create-pydantic-models

Files Created:
- /opt/hx-lang-server/app/models/requests.py
- /opt/hx-lang-server/app/models/responses.py
- /opt/hx-lang-server/app/models/errors.py
- /opt/hx-lang-server/app/models/__init__.py (updated)

Request Models:
- InvokeRequest (POST /api/v1/invoke)
- StreamRequest (POST /api/v1/stream)
- SessionCreateRequest (POST /api/v1/sessions)
- WebhookRegisterRequest (POST /webhooks)

Response Models:
- InvokeResponse (agent invocation result)
- StreamChunk (SSE streaming chunks)
- SessionResponse (session CRUD)
- ThreadResponse (thread history)
- HealthResponse (health check)
- ReadyResponse (readiness probe)
- WebhookResponse (webhook registration)
- MetricsResponse (Prometheus metrics)

Error Models:
- ErrorResponse (standard error)
- ValidationErrorResponse (422 errors)
- RateLimitErrorResponse (429 errors)
- ServiceUnavailableResponse (503 errors)

Validation Tests: PASSED
JSON Schema Generation: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/models-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] All model files are syntactically correct:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/models/requests.py
  python3 -m py_compile /opt/hx-lang-server/app/models/responses.py
  python3 -m py_compile /opt/hx-lang-server/app/models/errors.py
  echo "PASS: All models compile"
  ```

- [ ] All models importable from package:
  ```bash
  python3 -c "from app.models import InvokeRequest, InvokeResponse, ErrorResponse"
  echo "PASS: Package imports work"
  ```

- [ ] Request validation works:
  ```bash
  python3 -c "
  from app.models import InvokeRequest
  from pydantic import ValidationError
  try:
      InvokeRequest(query='')
      exit(1)
  except ValidationError:
      print('PASS: Empty query rejected')
  "
  ```

- [ ] Response serialization works:
  ```bash
  python3 -c "
  from app.models import InvokeResponse
  r = InvokeResponse(thread_id='t1', response='r', query_type='q', worker_used='w', iteration_count=1)
  assert r.model_dump_json()
  print('PASS: Serialization works')
  "
  ```

- [ ] JSON schemas generate correctly:
  ```bash
  python3 -c "
  from app.models import InvokeRequest
  schema = InvokeRequest.model_json_schema()
  assert 'query' in schema['properties']
  print('PASS: JSON schema generated')
  "
  ```

---

## Rollback

If implementation needs to be reverted:

```bash
rm -f /opt/hx-lang-server/app/models/requests.py
rm -f /opt/hx-lang-server/app/models/responses.py
rm -f /opt/hx-lang-server/app/models/errors.py

# Restore minimal __init__.py
cat > /opt/hx-lang-server/app/models/__init__.py <<'EOF'
"""Models package - placeholder."""
EOF
```

---

## Notes

### Model Design Principles

1. **Explicit Field Definitions**: All fields have type hints, descriptions, and examples
2. **Validation at the Edge**: Request models validate input before business logic
3. **Consistent Error Format**: All errors use ErrorResponse pattern
4. **OpenAPI Ready**: Examples and descriptions generate comprehensive docs

### Pydantic V2 Features Used

- `model_config` for configuration
- `field_validator` for custom validation
- `model_json_schema()` for schema generation
- `model_dump_json()` for serialization

### Response Model Guidelines

- Include examples in json_schema_extra for OpenAPI docs
- Use `datetime` for timestamps (auto-serialized to ISO format)
- Use `Dict[str, Any]` for flexible metadata fields
- Include default_factory for mutable defaults

### Error Code Mapping

The ERROR_CODES dict maps error codes to HTTP status codes:
- 4xx for client errors (validation, auth, rate limit)
- 5xx for server errors (service unavailable, internal)

---

## Related Tasks

**Prerequisites**:
- Task 101: Application structure
- Task 103: Pydantic config

**Next Tasks**:
- Task 105: Implement /invoke endpoint (uses InvokeRequest/InvokeResponse)
- Task 106: Implement /stream endpoint (uses StreamRequest/StreamChunk)
- Task 107: Implement session endpoints (uses SessionRequest/SessionResponse)

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: API Specification > Request/Response Models
- Section: Error Responses

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
