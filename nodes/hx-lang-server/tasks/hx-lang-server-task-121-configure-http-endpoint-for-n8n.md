# Task: Configure HTTP Endpoint for n8n Integration

**Task ID**: hx-lang-server-task-121-configure-http-endpoint-for-n8n
**Phase**: Implementation (Phase 2)
**Assigned To**: Isabella (n8n Workflow Automation SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-101 (FastAPI structure), hx-lang-server-task-053 (Supervisor agent)
**Estimated Time**: 90 minutes

---

## Objective

Configure dedicated HTTP endpoint at `/invoke` for n8n HTTP Request node integration with support for async invocation, webhook callback registration, and thread_id for conversation continuity. This endpoint enables n8n workflows to orchestrate LangGraph agent workflows via REST API.

---

## Prerequisites

- [ ] FastAPI application structure created at `/opt/hx-lang-server/app/main.py`
- [ ] LangGraph supervisor agent implemented and functional
- [ ] PostgreSQL checkpoint persistence operational
- [ ] Pydantic models defined for request/response validation
- [ ] Redis session management functional

---

## Specification Reference

**From node-spec.md v2.1, Section: n8n Integration (Phase 2)**

Lines 104-108:
```
#### n8n Integration (Phase 2)
- FR-026: Service MUST expose HTTP endpoint for n8n HTTP Request node
- FR-027: Service MUST support webhook callback registration for async operations
- FR-028: Service MUST provide thread_id for conversation continuity in n8n workflows
```

Lines 543-557:
```yaml
# n8n HTTP Request Node Configuration
url: http://hx-lang-server.hx.dev.local:8100/invoke
method: POST
headers:
  Content-Type: application/json
body:
  query: "{{ $json.user_input }}"
  thread_id: "{{ $json.thread_id }}"
  callback_url: "{{ $webhook.url }}"
```

---

## Implementation Steps

### Step 1: Create n8n Integration Models

Create file: `/opt/hx-lang-server/app/api/models/n8n.py`

```python
"""
Pydantic models for n8n workflow integration.

Supports HTTP Request node configuration with webhook callbacks
and conversation continuity via thread_id.
"""

from pydantic import BaseModel, Field, HttpUrl, validator
from typing import Optional, Dict, Any
from datetime import datetime


class N8nInvokeRequest(BaseModel):
    """Request model for n8n HTTP Request node invocation."""

    query: str = Field(
        ...,
        description="User query to process with LangGraph agents",
        min_length=1,
        max_length=8000,
    )

    thread_id: Optional[str] = Field(
        None,
        description="Thread ID for conversation continuation (empty for new conversation)",
        pattern=r"^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$",
    )

    callback_url: Optional[HttpUrl] = Field(
        None,
        description="n8n webhook URL for async result delivery (empty for sync mode)",
    )

    config: Optional[Dict[str, Any]] = Field(
        None,
        description="Agent configuration overrides",
    )

    workflow_id: Optional[str] = Field(
        None,
        description="n8n workflow ID for tracking and logging",
    )

    execution_id: Optional[str] = Field(
        None,
        description="n8n execution ID for correlation",
    )

    @validator("query")
    def validate_query_not_empty(cls, v):
        """Ensure query is not just whitespace."""
        if not v.strip():
            raise ValueError("Query cannot be empty or whitespace only")
        return v.strip()


class N8nInvokeResponse(BaseModel):
    """Response model for n8n HTTP Request node."""

    thread_id: str = Field(
        ...,
        description="Thread ID for conversation continuity (use in subsequent calls)",
    )

    response: str = Field(
        ...,
        description="Agent response text",
    )

    query_type: str = Field(
        ...,
        description="Classified query type (general, code, rag, tool)",
    )

    worker_used: str = Field(
        ...,
        description="Worker agent that processed the query",
    )

    iteration_count: int = Field(
        ...,
        description="Number of graph iterations for this query",
    )

    async_mode: bool = Field(
        False,
        description="Whether response will be delivered via webhook",
    )

    status_url: Optional[str] = Field(
        None,
        description="URL to poll for async operation status",
    )

    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata (LLM used, duration, etc.)",
    )

    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Response timestamp (UTC)",
    )


class N8nErrorResponse(BaseModel):
    """Error response for n8n integration."""

    error: str = Field(..., description="Error message")
    error_code: str = Field(..., description="Error code")
    thread_id: Optional[str] = Field(None, description="Thread ID if available")
    request_id: str = Field(..., description="Request ID for debugging")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
```

### Step 2: Implement n8n HTTP Endpoint

Update `/opt/hx-lang-server/app/api/routes/agent.py`:

```python
"""
API routes for LangGraph agent invocation with n8n support.
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks, Request
from fastapi.responses import JSONResponse
from app.api.models.n8n import N8nInvokeRequest, N8nInvokeResponse, N8nErrorResponse
from app.services.agent_service import AgentService
from app.core.config import settings
import structlog
import uuid
from typing import Optional

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.post(
    "/invoke",
    response_model=N8nInvokeResponse,
    summary="Invoke LangGraph agent (n8n compatible)",
    description="Execute LangGraph agent workflow with support for n8n HTTP Request node",
    tags=["Agent", "n8n"],
)
async def invoke_agent_n8n(
    request: N8nInvokeRequest,
    background_tasks: BackgroundTasks,
    http_request: Request,
) -> N8nInvokeResponse:
    """
    Invoke LangGraph agent with n8n HTTP Request node support.

    Supports two modes:
    1. Synchronous: Returns response immediately (no callback_url)
    2. Asynchronous: Registers callback and returns immediately (with callback_url)

    Args:
        request: n8n invocation request with query and optional thread_id
        background_tasks: FastAPI background tasks for async processing
        http_request: FastAPI request object for request_id

    Returns:
        N8nInvokeResponse with thread_id for conversation continuity
    """
    request_id = str(uuid.uuid4())

    logger.info(
        "n8n_invoke_request",
        request_id=request_id,
        query_length=len(request.query),
        thread_id=request.thread_id,
        has_callback=bool(request.callback_url),
        workflow_id=request.workflow_id,
        execution_id=request.execution_id,
    )

    try:
        agent_service = AgentService()

        # Determine if async mode (webhook callback) or sync mode
        if request.callback_url:
            # Async mode: Schedule background task and return immediately
            thread_id = request.thread_id or str(uuid.uuid4())

            background_tasks.add_task(
                _process_async_invocation,
                agent_service=agent_service,
                request=request,
                thread_id=thread_id,
                request_id=request_id,
            )

            status_url = f"http://{settings.service_host}:{settings.service_port}/status/{thread_id}"

            return N8nInvokeResponse(
                thread_id=thread_id,
                response="Processing request asynchronously. Results will be sent to callback URL.",
                query_type="pending",
                worker_used="supervisor",
                iteration_count=0,
                async_mode=True,
                status_url=status_url,
                metadata={
                    "request_id": request_id,
                    "callback_url": str(request.callback_url),
                    "workflow_id": request.workflow_id,
                    "execution_id": request.execution_id,
                },
            )

        else:
            # Sync mode: Process and return result immediately
            result = await agent_service.invoke(
                query=request.query,
                thread_id=request.thread_id,
                config=request.config,
            )

            return N8nInvokeResponse(
                thread_id=result["thread_id"],
                response=result["response"],
                query_type=result["query_type"],
                worker_used=result["worker_used"],
                iteration_count=result["iteration_count"],
                async_mode=False,
                metadata={
                    "request_id": request_id,
                    "workflow_id": request.workflow_id,
                    "execution_id": request.execution_id,
                    "llm_used": result.get("llm_used"),
                    "duration_ms": result.get("duration_ms"),
                },
            )

    except Exception as e:
        logger.error(
            "n8n_invoke_error",
            request_id=request_id,
            error=str(e),
            thread_id=request.thread_id,
        )

        raise HTTPException(
            status_code=500,
            detail=N8nErrorResponse(
                error=str(e),
                error_code="INVOCATION_FAILED",
                thread_id=request.thread_id,
                request_id=request_id,
            ).dict(),
        )


async def _process_async_invocation(
    agent_service: AgentService,
    request: N8nInvokeRequest,
    thread_id: str,
    request_id: str,
) -> None:
    """
    Process async invocation and deliver result via webhook callback.

    This runs in a background task after the HTTP response is returned.
    """
    import httpx

    logger.info(
        "async_invocation_started",
        request_id=request_id,
        thread_id=thread_id,
    )

    try:
        # Execute agent workflow
        result = await agent_service.invoke(
            query=request.query,
            thread_id=thread_id,
            config=request.config,
        )

        # Prepare callback payload
        callback_payload = N8nInvokeResponse(
            thread_id=result["thread_id"],
            response=result["response"],
            query_type=result["query_type"],
            worker_used=result["worker_used"],
            iteration_count=result["iteration_count"],
            async_mode=True,
            metadata={
                "request_id": request_id,
                "workflow_id": request.workflow_id,
                "execution_id": request.execution_id,
                "llm_used": result.get("llm_used"),
                "duration_ms": result.get("duration_ms"),
            },
        )

        # Send callback to n8n webhook
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                str(request.callback_url),
                json=callback_payload.dict(),
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()

        logger.info(
            "async_callback_delivered",
            request_id=request_id,
            thread_id=thread_id,
            callback_status=response.status_code,
        )

    except Exception as e:
        logger.error(
            "async_invocation_failed",
            request_id=request_id,
            thread_id=thread_id,
            error=str(e),
        )
        # Attempt to send error to callback
        try:
            error_payload = N8nErrorResponse(
                error=str(e),
                error_code="ASYNC_INVOCATION_FAILED",
                thread_id=thread_id,
                request_id=request_id,
            )
            async with httpx.AsyncClient(timeout=10.0) as client:
                await client.post(
                    str(request.callback_url),
                    json=error_payload.dict(),
                )
        except Exception:
            logger.error("callback_error_delivery_failed", request_id=request_id)
```

### Step 3: Update Settings for n8n Configuration

Add to `/opt/hx-lang-server/app/core/config.py`:

```python
class Settings(BaseSettings):
    """Application settings."""

    # Service configuration
    service_host: str = "hx-lang-server.hx.dev.local"
    service_port: int = 8100

    # n8n integration
    n8n_callback_timeout: float = 10.0
    n8n_max_async_tasks: int = 20

    class Config:
        env_file = ".env"
```

### Step 4: Update Environment File

Add to `/opt/hx-lang-server/.env`:

```bash
# n8n Integration
SERVICE_HOST=hx-lang-server.hx.dev.local
SERVICE_PORT=8100
N8N_CALLBACK_TIMEOUT=10.0
N8N_MAX_ASYNC_TASKS=20
```

### Step 5: Register n8n Route in Main Application

Update `/opt/hx-lang-server/app/main.py`:

```python
from app.api.routes import agent

app.include_router(
    agent.router,
    prefix="/api",
    tags=["agent"],
)
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| n8n models | `/opt/hx-lang-server/app/api/models/n8n.py` | Request/response models |
| Agent routes | `/opt/hx-lang-server/app/api/routes/agent.py` | HTTP endpoint with async support |
| Updated config | `/opt/hx-lang-server/app/core/config.py` | n8n settings |
| Updated .env | `/opt/hx-lang-server/.env` | Environment variables |

---

## Verification Steps

### Step 1: Test Synchronous Invocation

```bash
# From any machine with network access to hx-lang-server
curl -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is LangGraph?",
    "workflow_id": "test-workflow",
    "execution_id": "test-exec-001"
  }'

# Expected: JSON response with thread_id, response, query_type, worker_used
# Verify: async_mode = false
```

### Step 2: Test Thread Continuity

```bash
# Step 1: Initial query
THREAD_ID=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello, my name is Alice"}' | jq -r '.thread_id')

echo "Thread ID: $THREAD_ID"

# Step 2: Follow-up query with thread_id
curl -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"What is my name?\", \"thread_id\": \"$THREAD_ID\"}"

# Expected: Response should reference "Alice"
```

### Step 3: Test Async Mode with Callback

```bash
# Requires n8n webhook URL or mock webhook endpoint
# This test should be performed with actual n8n workflow

# Mock webhook server (for testing without n8n)
python3 -m http.server 8888 &

# Send async request
curl -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Explain LangGraph agents",
    "callback_url": "http://localhost:8888/webhook",
    "workflow_id": "async-test"
  }'

# Expected: Immediate response with async_mode=true and status_url
# Check mock server logs for callback POST
```

### Step 4: Verify Error Handling

```bash
# Test empty query
curl -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": ""}'

# Expected: 422 Unprocessable Entity with validation error
```

---

## Acceptance Criteria

- [ ] `/invoke` endpoint responds to POST requests on port 8100
- [ ] Synchronous mode returns complete response immediately
- [ ] Asynchronous mode with `callback_url` returns immediately with status_url
- [ ] Thread ID is generated for new conversations and preserved for continuity
- [ ] Request validation rejects empty queries with 422 status code
- [ ] Callback payload delivered successfully to n8n webhook URL
- [ ] Error responses follow N8nErrorResponse schema
- [ ] Metadata includes workflow_id and execution_id when provided
- [ ] OpenAPI documentation includes n8n endpoint at `/docs`

---

## Rollback Procedure

If issues occur:

1. Disable n8n routes in main.py
2. Revert models and route changes
3. Restart service

```bash
cd /opt/hx-lang-server
git checkout app/api/models/n8n.py
git checkout app/api/routes/agent.py
sudo systemctl restart hx-lang-server
```

---

## Notes

- **Sync vs Async Mode:** Determined by presence of `callback_url` in request
- **Thread Continuity:** Critical for multi-turn conversations in n8n workflows
- **Callback Timeout:** 10 seconds default, configurable via environment
- **Background Tasks:** FastAPI BackgroundTasks ensures response before processing
- **Error Delivery:** Best-effort callback delivery for async errors

---

**Created By:** Isabella (n8n Workflow Automation SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: n8n Integration (FR-026, FR-027, FR-028)
