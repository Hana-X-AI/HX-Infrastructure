# Specification Contribution: Bob (FastAPI SME)

**Contribution Date:** 2025-12-01
**Spec Version:** 1.0
**Focus Areas:** FastAPI, Pydantic, async patterns, middleware, dependency injection, OpenAPI documentation

---

## Executive Summary

This contribution provides detailed FastAPI implementation guidance for the hx-lang-server specification. The current spec draft (v1.0) contains a solid foundation but requires enhancement in several critical areas: complete endpoint contract definitions, comprehensive Pydantic models, production-ready middleware stack, and robust async patterns for LangGraph integration. This document provides production-ready code examples and specific recommendations to ensure the API layer is performant, maintainable, and follows SOLID principles.

---

## 1. Endpoint Enhancements

### 1.1 Current Spec Gap Analysis

The spec defines 8 endpoints (Lines 461-470) but lacks HTTP status codes, request/response contracts, and error scenarios. The following enhanced endpoint specification addresses these gaps.

### 1.2 Complete Endpoint Contract

| Method | Path | Purpose | Success | Error Codes |
|--------|------|---------|---------|-------------|
| POST | `/v1/invoke` | Synchronous agent invocation | 200 | 400, 422, 500, 503 |
| POST | `/v1/invoke/async` | Async invocation with callback | 202 | 400, 422, 500 |
| POST | `/v1/stream` | Streaming agent invocation (SSE) | 200 | 400, 422, 500, 503 |
| GET | `/v1/threads/{thread_id}` | Get thread history | 200 | 404, 500 |
| POST | `/v1/threads/{thread_id}/messages` | Continue conversation | 200 | 404, 422, 500, 503 |
| DELETE | `/v1/threads/{thread_id}` | Delete thread | 204 | 404, 500 |
| GET | `/health` | Basic liveness check | 200 | - |
| GET | `/health/ready` | Readiness check (dependencies) | 200 | 503 |
| GET | `/health/deep` | Deep health check (LLM ping) | 200 | 503 |
| POST | `/v1/webhooks` | Register webhook callback | 201 | 400, 422 |
| DELETE | `/v1/webhooks/{webhook_id}` | Remove webhook | 204 | 404 |
| GET | `/v1/webhooks` | List registered webhooks | 200 | - |

### 1.3 API Versioning Strategy

**Recommendation:** Use URL path versioning (`/v1/`) as shown above. This aligns with n8n integration requirements and allows future API evolution without breaking existing clients.

```python
from fastapi import APIRouter

# Version 1 router
v1_router = APIRouter(prefix="/v1", tags=["v1"])

# Mount to main app
app.include_router(v1_router)
```

### 1.4 Streaming Endpoint (SSE) - CRITICAL ADDITION

The spec mentions `/stream` but lacks implementation details. For LangGraph agent streaming, Server-Sent Events (SSE) is essential for real-time output. This requires the `sse-starlette` package.

```python
from sse_starlette.sse import EventSourceResponse
from typing import AsyncGenerator

@router.post("/v1/stream")
async def stream_invoke(
    request: InvokeRequest,
    graph: CompiledGraph = Depends(get_graph),
) -> EventSourceResponse:
    """Stream agent responses via Server-Sent Events."""

    async def event_generator() -> AsyncGenerator[dict, None]:
        config = {"configurable": {"thread_id": request.thread_id or str(uuid4())}}

        async for event in graph.astream_events(
            {"messages": [HumanMessage(content=request.query)]},
            config=config,
            version="v2"
        ):
            if event["event"] == "on_chat_model_stream":
                chunk = event["data"]["chunk"]
                yield {
                    "event": "token",
                    "data": json.dumps({
                        "content": chunk.content,
                        "thread_id": config["configurable"]["thread_id"]
                    })
                }
            elif event["event"] == "on_chain_end":
                yield {
                    "event": "complete",
                    "data": json.dumps({"status": "complete"})
                }

    return EventSourceResponse(event_generator())
```

**Add to requirements:**
```
sse-starlette>=2.1.0
```

---

## 2. Pydantic Model Completeness

### 2.1 Current Spec Assessment

The spec (Lines 474-522) provides basic InvokeRequest, InvokeResponse, HealthResponse, and ErrorResponse models. The following additions complete the model hierarchy.

### 2.2 Complete Request Models

```python
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime
from uuid import UUID, uuid4

class InvokeRequest(BaseModel):
    """Request model for synchronous agent invocation."""

    query: str = Field(
        ...,
        min_length=1,
        max_length=32000,
        description="User query to process",
        examples=["Explain the architecture of hx-lang-server"]
    )
    thread_id: Optional[str] = Field(
        None,
        pattern=r"^[a-zA-Z0-9-]{36}$",
        description="Thread ID for conversation continuation (UUID format)"
    )
    session_id: Optional[str] = Field(
        None,
        description="Session ID for caching context"
    )
    query_type_override: Optional[Literal["general", "code", "rag", "tool"]] = Field(
        None,
        description="Override automatic query classification"
    )
    config: Optional[Dict[str, Any]] = Field(
        default_factory=dict,
        description="Agent configuration overrides"
    )

    @field_validator("query")
    @classmethod
    def validate_query_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Query cannot be empty or whitespace only")
        return v.strip()


class AsyncInvokeRequest(InvokeRequest):
    """Request model for async invocation with webhook callback."""

    callback_url: str = Field(
        ...,
        pattern=r"^https?://",
        description="Webhook URL for result delivery"
    )
    callback_headers: Optional[Dict[str, str]] = Field(
        default_factory=dict,
        description="Headers to include in callback request"
    )


class ThreadMessageRequest(BaseModel):
    """Request model for adding message to existing thread."""

    query: str = Field(..., min_length=1, max_length=32000)
    config: Optional[Dict[str, Any]] = Field(default_factory=dict)


class WebhookRegistration(BaseModel):
    """Request model for webhook registration."""

    url: str = Field(..., pattern=r"^https?://")
    events: List[Literal["agent_complete", "agent_error", "checkpoint_created"]] = Field(
        default=["agent_complete", "agent_error"]
    )
    secret: Optional[str] = Field(None, min_length=32, description="Webhook signing secret")
    active: bool = Field(default=True)
```

### 2.3 Complete Response Models

```python
class MessageContent(BaseModel):
    """Individual message in conversation history."""

    role: Literal["user", "assistant", "system", "tool"]
    content: str
    timestamp: datetime
    metadata: Optional[Dict[str, Any]] = None


class InvokeResponse(BaseModel):
    """Response model for agent invocation."""

    thread_id: str = Field(..., description="Thread ID for continuation")
    response: str = Field(..., description="Agent response content")
    query_type: Literal["general", "code", "rag", "tool"]
    worker_used: str = Field(..., description="Worker agent that handled request")
    iteration_count: int = Field(..., ge=0, description="Number of agent iterations")
    rag_sources: Optional[List[str]] = Field(None, description="RAG sources used (if applicable)")
    tool_calls: Optional[List[Dict[str, Any]]] = Field(None, description="Tool invocations (if applicable)")
    metadata: Dict[str, Any] = Field(default_factory=dict)
    processing_time_ms: float = Field(..., description="Total processing time in milliseconds")
    request_id: str = Field(..., description="Unique request identifier for tracing")

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "thread_id": "550e8400-e29b-41d4-a716-446655440000",
                "response": "The hx-lang-server provides LangGraph orchestration...",
                "query_type": "rag",
                "worker_used": "rag_agent",
                "iteration_count": 2,
                "rag_sources": ["docs/architecture.md"],
                "metadata": {"llm_model": "gemma3:27b"},
                "processing_time_ms": 2340.5,
                "request_id": "req_abc123"
            }]
        }
    }


class AsyncInvokeResponse(BaseModel):
    """Response for async invocation acceptance."""

    task_id: str = Field(..., description="Task ID for status polling")
    status: Literal["accepted", "queued"] = "accepted"
    thread_id: str
    estimated_completion_seconds: Optional[int] = None


class ThreadHistoryResponse(BaseModel):
    """Response for thread history retrieval."""

    thread_id: str
    messages: List[MessageContent]
    created_at: datetime
    last_updated: datetime
    message_count: int
    current_worker: Optional[str] = None


class WebhookResponse(BaseModel):
    """Response for webhook registration."""

    webhook_id: str
    url: str
    events: List[str]
    active: bool
    created_at: datetime


class WebhookListResponse(BaseModel):
    """Response for webhook listing."""

    webhooks: List[WebhookResponse]
    total: int
```

### 2.4 Health Check Models (Enhanced)

```python
class DependencyHealth(BaseModel):
    """Health status of a single dependency."""

    name: str
    status: Literal["healthy", "degraded", "unhealthy"]
    latency_ms: Optional[float] = None
    error: Optional[str] = None
    last_check: datetime


class HealthResponse(BaseModel):
    """Comprehensive health check response."""

    status: Literal["healthy", "degraded", "unhealthy"]
    version: str
    uptime_seconds: float
    dependencies: Dict[str, DependencyHealth]
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "status": "healthy",
                "version": "1.0.0",
                "uptime_seconds": 3600.5,
                "dependencies": {
                    "postgres": {"name": "postgres", "status": "healthy", "latency_ms": 2.3},
                    "redis": {"name": "redis", "status": "healthy", "latency_ms": 0.8},
                    "ollama_general": {"name": "ollama_general", "status": "healthy", "latency_ms": 45.2}
                },
                "timestamp": "2025-12-01T10:30:00Z"
            }]
        }
    }


class ReadinessResponse(BaseModel):
    """Readiness probe response."""

    ready: bool
    checks: Dict[str, bool]
    message: Optional[str] = None
```

### 2.5 Error Response Models (RFC 7807 Compliant)

```python
class ProblemDetail(BaseModel):
    """RFC 7807 Problem Details for HTTP APIs."""

    type: str = Field(
        default="about:blank",
        description="URI reference identifying the problem type"
    )
    title: str = Field(..., description="Short human-readable summary")
    status: int = Field(..., ge=400, le=599, description="HTTP status code")
    detail: Optional[str] = Field(None, description="Detailed explanation")
    instance: Optional[str] = Field(None, description="URI reference to specific occurrence")
    request_id: str = Field(..., description="Request ID for correlation")
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    # Extension fields
    error_code: Optional[str] = Field(None, description="Application-specific error code")
    validation_errors: Optional[List[Dict[str, Any]]] = Field(
        None,
        description="Validation error details (for 422 responses)"
    )

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "type": "https://hx-lang-server.hx.dev.local/errors/ollama-unavailable",
                "title": "Ollama Service Unavailable",
                "status": 503,
                "detail": "Failed to connect to hx-ollama1-server.hx.dev.local:11434",
                "instance": "/v1/invoke",
                "request_id": "req_abc123",
                "error_code": "OLLAMA_UNAVAILABLE"
            }]
        }
    }
```

---

## 3. Middleware Stack

### 3.1 Required Middleware Configuration

The spec mentions middleware (Lines 154-158) but lacks explicit configuration. The following middleware stack is production-ready.

```python
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from uuid import uuid4
import time
import structlog

logger = structlog.get_logger()


# 1. Request ID Middleware (FIRST in chain - wraps all requests)
class RequestIDMiddleware(BaseHTTPMiddleware):
    """Inject request ID for distributed tracing."""

    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or str(uuid4())
        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


# 2. Request Logging Middleware
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Structured logging for all requests."""

    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()

        # Log request
        logger.info(
            "request_started",
            method=request.method,
            path=request.url.path,
            request_id=getattr(request.state, "request_id", "unknown"),
            client_ip=request.client.host if request.client else "unknown",
        )

        response = await call_next(request)

        # Log response
        process_time = (time.perf_counter() - start_time) * 1000
        logger.info(
            "request_completed",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=round(process_time, 2),
            request_id=getattr(request.state, "request_id", "unknown"),
        )

        response.headers["X-Process-Time-Ms"] = str(round(process_time, 2))
        return response


# 3. Request Timeout Middleware (CRITICAL for LLM operations)
class RequestTimeoutMiddleware(BaseHTTPMiddleware):
    """Enforce request timeout for long-running operations."""

    def __init__(self, app, timeout_seconds: float = 60.0):
        super().__init__(app)
        self.timeout_seconds = timeout_seconds

    async def dispatch(self, request: Request, call_next):
        import asyncio

        # Skip timeout for streaming endpoints
        if request.url.path.endswith("/stream"):
            return await call_next(request)

        try:
            return await asyncio.wait_for(
                call_next(request),
                timeout=self.timeout_seconds
            )
        except asyncio.TimeoutError:
            logger.warning(
                "request_timeout",
                path=request.url.path,
                timeout_seconds=self.timeout_seconds,
                request_id=getattr(request.state, "request_id", "unknown"),
            )
            return Response(
                content='{"detail": "Request timeout"}',
                status_code=504,
                media_type="application/json"
            )


# Application setup with middleware order (CRITICAL - order matters!)
def create_app() -> FastAPI:
    app = FastAPI(
        title="hx-lang-server",
        version="1.0.0",
        description="LangGraph Orchestration Hub for HX-Infrastructure",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json"
    )

    # Middleware added in REVERSE order of execution
    # (last added = first executed)

    # 4. GZip compression (innermost)
    app.add_middleware(GZipMiddleware, minimum_size=1000)

    # 3. Request timeout (wraps response generation)
    app.add_middleware(RequestTimeoutMiddleware, timeout_seconds=60.0)

    # 2. Request logging (needs request_id from outer middleware)
    app.add_middleware(RequestLoggingMiddleware)

    # 1. Request ID injection (outermost - first executed)
    app.add_middleware(RequestIDMiddleware)

    # CORS configuration for n8n integration
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://hx-n8n-server.hx.dev.local:5678",
            "http://hx-n8n-server.hx.dev.local",
        ],
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID", "X-Process-Time-Ms"],
    )

    return app
```

### 3.2 Middleware Execution Order

```
Request Flow:
  [Client]
    -> CORS (preflight handling)
    -> RequestIDMiddleware (inject X-Request-ID)
    -> RequestLoggingMiddleware (log request start)
    -> RequestTimeoutMiddleware (enforce timeout)
    -> GZipMiddleware (compression)
    -> [Path Operation Handler]
    -> GZipMiddleware (compress response)
    -> RequestTimeoutMiddleware (pass through)
    -> RequestLoggingMiddleware (log request end)
    -> RequestIDMiddleware (add X-Request-ID header)
    -> CORS (add CORS headers)
  [Client]
```

---

## 4. Async Patterns for LangGraph Integration

### 4.1 Critical Async Requirements

**MANDATORY:** All LangGraph operations MUST use async methods:
- Use `graph.ainvoke()` NOT `graph.invoke()`
- Use `graph.astream_events()` for streaming
- Use `AsyncPostgresSaver` for checkpoints
- Use `redis.asyncio` for Redis operations

### 4.2 LangGraph Dependency Injection

```python
from typing import Annotated
from fastapi import Depends
from langgraph.graph import StateGraph
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
import redis.asyncio as redis

# Type aliases for cleaner signatures
GraphDep = Annotated[CompiledGraph, Depends(get_graph)]
RedisDep = Annotated[redis.Redis, Depends(get_redis)]
CheckpointerDep = Annotated[AsyncPostgresSaver, Depends(get_checkpointer)]


async def get_graph() -> CompiledGraph:
    """
    Dependency that provides the compiled LangGraph instance.

    The graph is initialized once at startup and stored in app.state.
    This follows Dependency Inversion Principle - endpoints depend on
    the abstract graph interface, not concrete implementation.
    """
    from app.main import app
    return app.state.graph


async def get_checkpointer() -> AsyncPostgresSaver:
    """Dependency for PostgreSQL checkpoint saver."""
    from app.main import app
    return app.state.checkpointer


async def get_redis() -> redis.Redis:
    """Dependency for Redis async client."""
    from app.main import app
    return app.state.redis


# Example endpoint using dependencies
@router.post("/v1/invoke", response_model=InvokeResponse)
async def invoke_agent(
    request: InvokeRequest,
    graph: GraphDep,
    redis_client: RedisDep,
) -> InvokeResponse:
    """
    Synchronous agent invocation.

    All I/O operations are async:
    - LangGraph: ainvoke()
    - Redis: async get/set
    - PostgreSQL: automatic via AsyncPostgresSaver
    """
    request_id = str(uuid4())
    start_time = time.perf_counter()

    # Generate or use provided thread_id
    thread_id = request.thread_id or str(uuid4())

    # Check Redis cache for classification
    cache_key = f"classification:{hash(request.query)}"
    cached_type = await redis_client.get(cache_key)

    # Configure thread for checkpoint persistence
    config = {
        "configurable": {
            "thread_id": thread_id,
        },
        "recursion_limit": 25,
    }

    # CRITICAL: Use ainvoke for async execution
    result = await graph.ainvoke(
        {"messages": [HumanMessage(content=request.query)]},
        config=config
    )

    processing_time = (time.perf_counter() - start_time) * 1000

    return InvokeResponse(
        thread_id=thread_id,
        response=result["messages"][-1].content,
        query_type=result.get("query_type", "general"),
        worker_used=result.get("current_worker", "unknown"),
        iteration_count=result.get("iteration_count", 1),
        metadata={"llm_model": result.get("llm_model")},
        processing_time_ms=processing_time,
        request_id=request_id,
    )
```

### 4.3 Lifespan Context Manager (Resource Management)

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from psycopg import AsyncConnection
import redis.asyncio as redis

from app.config import settings
from app.graph import build_supervisor_graph


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Async context manager for application lifespan.

    Startup: Initialize all async resources
    Shutdown: Clean up connections properly

    Following SOLID:
    - SRP: Each resource has dedicated initialization
    - DIP: Resources injected via app.state, not global variables
    """
    # ========== STARTUP ==========

    # 1. PostgreSQL connection for checkpointing
    pg_conn = await AsyncConnection.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        dbname=settings.postgres_db,
        user=settings.postgres_user,
        password=settings.postgres_password,
        autocommit=True,  # REQUIRED for langgraph-checkpoint-postgres
        prepare_threshold=0,  # Disable for pgBouncer compatibility
    )
    app.state.checkpointer = AsyncPostgresSaver(pg_conn)

    # 2. Initialize checkpoint tables (idempotent)
    await app.state.checkpointer.setup()

    # 3. Redis connection pool
    app.state.redis_pool = redis.ConnectionPool.from_url(
        settings.redis_url,
        max_connections=20,
        socket_timeout=5.0,
        socket_connect_timeout=5.0,
        retry_on_timeout=True,
    )
    app.state.redis = redis.Redis(connection_pool=app.state.redis_pool)

    # 4. Build and compile LangGraph
    app.state.graph = build_supervisor_graph(
        checkpointer=app.state.checkpointer,
        settings=settings,
    )

    # 5. Record startup time
    app.state.startup_time = time.time()

    logger.info("application_startup_complete", version=settings.version)

    yield  # Application runs here

    # ========== SHUTDOWN ==========

    logger.info("application_shutdown_started")

    # 1. Close Redis
    await app.state.redis.close()
    await app.state.redis_pool.disconnect()

    # 2. Close PostgreSQL
    await pg_conn.close()

    logger.info("application_shutdown_complete")


# Create app with lifespan
app = FastAPI(lifespan=lifespan)
```

### 4.4 Background Tasks for Async Operations

```python
from fastapi import BackgroundTasks
import httpx

async def send_webhook_callback(
    callback_url: str,
    callback_headers: dict,
    result: InvokeResponse,
    secret: Optional[str] = None,
) -> None:
    """Background task to deliver webhook callback."""

    payload = result.model_dump_json()

    headers = {
        "Content-Type": "application/json",
        "X-Webhook-Event": "agent_complete",
        **callback_headers,
    }

    if secret:
        import hmac
        import hashlib
        signature = hmac.new(
            secret.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()
        headers["X-Webhook-Signature"] = f"sha256={signature}"

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.post(
                callback_url,
                content=payload,
                headers=headers,
            )
            logger.info(
                "webhook_callback_sent",
                url=callback_url,
                status_code=response.status_code,
            )
        except httpx.RequestError as e:
            logger.error(
                "webhook_callback_failed",
                url=callback_url,
                error=str(e),
            )


@router.post("/v1/invoke/async", response_model=AsyncInvokeResponse, status_code=202)
async def invoke_async(
    request: AsyncInvokeRequest,
    graph: GraphDep,
    background_tasks: BackgroundTasks,
) -> AsyncInvokeResponse:
    """
    Async agent invocation with webhook callback.

    Returns immediately with task_id.
    Result delivered via callback_url when complete.
    """
    task_id = str(uuid4())
    thread_id = request.thread_id or str(uuid4())

    async def execute_and_callback():
        try:
            result = await graph.ainvoke(
                {"messages": [HumanMessage(content=request.query)]},
                config={"configurable": {"thread_id": thread_id}},
            )
            response = InvokeResponse(
                thread_id=thread_id,
                response=result["messages"][-1].content,
                query_type=result.get("query_type", "general"),
                worker_used=result.get("current_worker", "unknown"),
                iteration_count=result.get("iteration_count", 1),
                metadata={},
                processing_time_ms=0,
                request_id=task_id,
            )
            await send_webhook_callback(
                request.callback_url,
                request.callback_headers,
                response,
            )
        except Exception as e:
            logger.error("async_invoke_failed", task_id=task_id, error=str(e))

    background_tasks.add_task(execute_and_callback)

    return AsyncInvokeResponse(
        task_id=task_id,
        status="accepted",
        thread_id=thread_id,
    )
```

---

## 5. Code Examples

### 5.1 Complete Application Structure

```
/opt/hx-lang-server/
+-- app/
|   +-- __init__.py
|   +-- main.py              # FastAPI app factory with lifespan
|   +-- config.py            # Pydantic Settings configuration
|   +-- routers/
|   |   +-- __init__.py
|   |   +-- invoke.py        # /v1/invoke, /v1/invoke/async, /v1/stream
|   |   +-- threads.py       # /v1/threads/{thread_id}
|   |   +-- health.py        # /health, /health/ready, /health/deep
|   |   +-- webhooks.py      # /v1/webhooks
|   +-- dependencies/
|   |   +-- __init__.py
|   |   +-- graph.py         # LangGraph dependency
|   |   +-- database.py      # PostgreSQL/Redis dependencies
|   +-- middleware/
|   |   +-- __init__.py
|   |   +-- request_id.py    # Request correlation
|   |   +-- logging.py       # Structured logging
|   |   +-- timeout.py       # Request timeout
|   +-- schemas/
|   |   +-- __init__.py
|   |   +-- requests.py      # Request models
|   |   +-- responses.py     # Response models
|   |   +-- errors.py        # Error models
|   |   +-- health.py        # Health check models
|   +-- services/
|   |   +-- __init__.py
|   |   +-- session.py       # Redis session management
|   |   +-- webhook.py       # Webhook delivery service
|   +-- graph/
|   |   +-- __init__.py
|   |   +-- supervisor.py    # LangGraph supervisor agent
|   |   +-- workers/
|   |   |   +-- rag_agent.py
|   |   |   +-- code_agent.py
|   |   |   +-- tool_agent.py
|   |   +-- state.py         # AgentState TypedDict
+-- tests/
|   +-- conftest.py          # pytest fixtures
|   +-- test_invoke.py       # Invoke endpoint tests
|   +-- test_health.py       # Health check tests
+-- .env                     # Environment configuration
+-- pyproject.toml           # Dependencies
```

### 5.2 Main Application (app/main.py)

```python
"""
hx-lang-server FastAPI Application

This module implements the FastAPI wrapper for LangGraph orchestration.
Follows HX-Infrastructure standards for bare-metal deployment with systemd.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import structlog

from app.config import settings
from app.middleware.request_id import RequestIDMiddleware
from app.middleware.logging import RequestLoggingMiddleware
from app.middleware.timeout import RequestTimeoutMiddleware
from app.routers import invoke, threads, health, webhooks
from app.dependencies.database import setup_postgres, setup_redis, cleanup_resources
from app.graph import build_supervisor_graph

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for resource initialization."""

    # Startup
    app.state.pg_conn = await setup_postgres(settings)
    app.state.checkpointer = await app.state.pg_conn.get_checkpointer()
    app.state.redis = await setup_redis(settings)
    app.state.graph = build_supervisor_graph(
        checkpointer=app.state.checkpointer,
        settings=settings,
    )
    app.state.startup_time = time.time()

    logger.info("application_startup", version=settings.version)

    yield

    # Shutdown
    await cleanup_resources(app.state)
    logger.info("application_shutdown")


def create_app() -> FastAPI:
    """Application factory following SOLID principles."""

    app = FastAPI(
        title="hx-lang-server",
        description="LangGraph Orchestration Hub for HX-Infrastructure",
        version=settings.version,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # Middleware stack (reverse order of execution)
    app.add_middleware(GZipMiddleware, minimum_size=1000)
    app.add_middleware(RequestTimeoutMiddleware, timeout_seconds=60.0)
    app.add_middleware(RequestLoggingMiddleware)
    app.add_middleware(RequestIDMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID", "X-Process-Time-Ms"],
    )

    # Register routers
    app.include_router(health.router, tags=["Health"])
    app.include_router(invoke.router, prefix="/v1", tags=["Invoke"])
    app.include_router(threads.router, prefix="/v1", tags=["Threads"])
    app.include_router(webhooks.router, prefix="/v1", tags=["Webhooks"])

    return app


app = create_app()
```

### 5.3 Health Check Router (app/routers/health.py)

```python
"""Health check endpoints following Kubernetes probe patterns."""

from datetime import datetime
from fastapi import APIRouter, Depends, Response
import httpx
import redis.asyncio as redis
from psycopg import AsyncConnection
import time

from app.dependencies.database import get_redis, get_pg_connection
from app.config import settings
from app.schemas.health import (
    HealthResponse,
    ReadinessResponse,
    DependencyHealth,
)

router = APIRouter()


async def check_postgres(conn: AsyncConnection) -> DependencyHealth:
    """Check PostgreSQL connectivity."""
    start = time.perf_counter()
    try:
        async with conn.cursor() as cur:
            await cur.execute("SELECT 1")
        latency = (time.perf_counter() - start) * 1000
        return DependencyHealth(
            name="postgres",
            status="healthy",
            latency_ms=latency,
            last_check=datetime.utcnow(),
        )
    except Exception as e:
        return DependencyHealth(
            name="postgres",
            status="unhealthy",
            error=str(e),
            last_check=datetime.utcnow(),
        )


async def check_redis(client: redis.Redis) -> DependencyHealth:
    """Check Redis connectivity."""
    start = time.perf_counter()
    try:
        await client.ping()
        latency = (time.perf_counter() - start) * 1000
        return DependencyHealth(
            name="redis",
            status="healthy",
            latency_ms=latency,
            last_check=datetime.utcnow(),
        )
    except Exception as e:
        return DependencyHealth(
            name="redis",
            status="unhealthy",
            error=str(e),
            last_check=datetime.utcnow(),
        )


async def check_ollama(url: str, name: str) -> DependencyHealth:
    """Check Ollama server connectivity."""
    start = time.perf_counter()
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{url}/api/version")
            response.raise_for_status()
        latency = (time.perf_counter() - start) * 1000
        return DependencyHealth(
            name=name,
            status="healthy",
            latency_ms=latency,
            last_check=datetime.utcnow(),
        )
    except Exception as e:
        return DependencyHealth(
            name=name,
            status="unhealthy",
            error=str(e),
            last_check=datetime.utcnow(),
        )


@router.get("/health", response_model=HealthResponse)
async def health_check(
    redis_client: redis.Redis = Depends(get_redis),
    pg_conn: AsyncConnection = Depends(get_pg_connection),
) -> HealthResponse:
    """
    Basic health check endpoint.

    Returns overall service health and dependency status.
    Used by load balancers and monitoring systems.
    """
    from app.main import app

    # Check all dependencies concurrently
    import asyncio

    postgres_health, redis_health, ollama1_health, ollama2_health = await asyncio.gather(
        check_postgres(pg_conn),
        check_redis(redis_client),
        check_ollama(settings.ollama_general_url, "ollama_general"),
        check_ollama(settings.ollama_code_url, "ollama_code"),
    )

    dependencies = {
        "postgres": postgres_health,
        "redis": redis_health,
        "ollama_general": ollama1_health,
        "ollama_code": ollama2_health,
    }

    # Determine overall status
    unhealthy_count = sum(1 for d in dependencies.values() if d.status == "unhealthy")

    if unhealthy_count == 0:
        status = "healthy"
    elif unhealthy_count < len(dependencies):
        status = "degraded"
    else:
        status = "unhealthy"

    uptime = time.time() - app.state.startup_time

    return HealthResponse(
        status=status,
        version=settings.version,
        uptime_seconds=uptime,
        dependencies=dependencies,
        timestamp=datetime.utcnow(),
    )


@router.get("/health/ready", response_model=ReadinessResponse)
async def readiness_check(
    response: Response,
    redis_client: redis.Redis = Depends(get_redis),
    pg_conn: AsyncConnection = Depends(get_pg_connection),
) -> ReadinessResponse:
    """
    Readiness probe for Kubernetes/systemd.

    Returns 200 if service can accept requests.
    Returns 503 if critical dependencies unavailable.
    """
    checks = {}

    # PostgreSQL is CRITICAL
    try:
        async with pg_conn.cursor() as cur:
            await cur.execute("SELECT 1")
        checks["postgres"] = True
    except Exception:
        checks["postgres"] = False

    # Redis is CRITICAL
    try:
        await redis_client.ping()
        checks["redis"] = True
    except Exception:
        checks["redis"] = False

    ready = all(checks.values())

    if not ready:
        response.status_code = 503

    return ReadinessResponse(
        ready=ready,
        checks=checks,
        message=None if ready else "Critical dependencies unavailable",
    )


@router.get("/health/deep")
async def deep_health_check(response: Response):
    """
    Deep health check with LLM ping.

    Executes a minimal LLM inference to verify end-to-end functionality.
    WARNING: This is expensive - use sparingly.
    """
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            result = await client.post(
                f"{settings.ollama_general_url}/api/generate",
                json={
                    "model": settings.ollama_general_model,
                    "prompt": "Respond with OK",
                    "stream": False,
                    "options": {"num_predict": 5},
                },
            )
            result.raise_for_status()

        return {"status": "healthy", "llm_responsive": True}

    except Exception as e:
        response.status_code = 503
        return {"status": "unhealthy", "llm_responsive": False, "error": str(e)}
```

### 5.4 Testing Example (tests/test_invoke.py)

```python
"""
Pytest tests for invoke endpoints.

Uses httpx.AsyncClient for async testing as recommended by FastAPI docs.
"""

import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from app.main import app


@pytest.fixture
def mock_graph():
    """Mock LangGraph for unit testing."""
    mock = AsyncMock()
    mock.ainvoke.return_value = {
        "messages": [
            {"role": "user", "content": "test query"},
            {"role": "assistant", "content": "test response"},
        ],
        "query_type": "general",
        "current_worker": "rag_agent",
        "iteration_count": 1,
    }
    return mock


@pytest.mark.asyncio
async def test_invoke_success(mock_graph):
    """Test successful synchronous invocation."""

    with patch.object(app.state, "graph", mock_graph):
        async with AsyncClient(
            transport=ASGITransport(app=app),
            base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/invoke",
                json={"query": "What is LangGraph?"}
            )

    assert response.status_code == 200
    data = response.json()
    assert "thread_id" in data
    assert data["response"] == "test response"
    assert data["query_type"] == "general"


@pytest.mark.asyncio
async def test_invoke_empty_query():
    """Test validation rejects empty query."""

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        response = await client.post(
            "/v1/invoke",
            json={"query": "   "}  # Whitespace only
        )

    assert response.status_code == 422
    data = response.json()
    assert "validation_errors" in data or "detail" in data


@pytest.mark.asyncio
async def test_invoke_with_thread_continuation(mock_graph):
    """Test conversation continuation with thread_id."""

    thread_id = str(uuid4())

    with patch.object(app.state, "graph", mock_graph):
        async with AsyncClient(
            transport=ASGITransport(app=app),
            base_url="http://test"
        ) as client:
            response = await client.post(
                "/v1/invoke",
                json={
                    "query": "Continue the conversation",
                    "thread_id": thread_id
                }
            )

    assert response.status_code == 200
    data = response.json()
    assert data["thread_id"] == thread_id


@pytest.mark.asyncio
async def test_health_endpoint():
    """Test basic health check."""

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        response = await client.get("/health")

    assert response.status_code in [200, 503]  # Depends on dependencies
    data = response.json()
    assert "status" in data
    assert "version" in data
    assert "dependencies" in data


@pytest.mark.asyncio
async def test_request_id_header():
    """Test request ID is returned in response headers."""

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        response = await client.get("/health")

    assert "X-Request-ID" in response.headers
    assert len(response.headers["X-Request-ID"]) == 36  # UUID format
```

---

## 6. Spec Validation

### 6.1 Confirmed Correct Content

The following spec sections are accurate and should remain unchanged:

| Section | Lines | Assessment |
|---------|-------|------------|
| API port 8100 | 139 | Correct |
| Async endpoint mandate | 96 | Correct (FR-022) |
| Pydantic Settings usage | 651-686 | Correct pattern |
| systemd service config | 799-824 | Correct for bare-metal |
| PostgreSQL connection kwargs | 324-328 | Correct (autocommit, prepare_threshold) |
| Redis connection pool | 376-387 | Correct async pattern |
| Health check structure | 721-741 | Correct approach |

### 6.2 Corrections Required

| Issue | Location | Current | Correction |
|-------|----------|---------|------------|
| Missing SSE streaming details | Line 464 | `/stream` mentioned | Add SSE implementation with `sse-starlette` |
| Incomplete endpoint list | Lines 461-470 | 8 endpoints | Add `/v1/invoke/async`, `/health/ready`, `/health/deep`, webhook list |
| Missing middleware stack | Implicit | Not specified | Add explicit middleware configuration |
| Missing request timeout | Not present | - | Add RequestTimeoutMiddleware (60s default) |
| Missing API versioning | Implicit | `/invoke` | Prefix with `/v1/` for future compatibility |
| Error response incomplete | Lines 504-522 | Basic model | Enhance with RFC 7807 ProblemDetail |

---

## 7. Recommended Changes to node-spec.md

### 7.1 Section 7 (API Specification) - Lines 457-524

**Replace with enhanced endpoint table from Section 1.2 of this document.**

**Add new subsection:**

```markdown
### Streaming Support

The service supports Server-Sent Events (SSE) for real-time agent output streaming.

**Endpoint:** `POST /v1/stream`
**Response:** `text/event-stream`

**Event Types:**
- `token` - Individual token from LLM response
- `tool_call` - Tool invocation event
- `complete` - Stream completion marker
- `error` - Error event

**Dependency:** `sse-starlette>=2.1.0`
```

### 7.2 New Section: Middleware Stack

**Add after Line 524:**

```markdown
### Middleware Configuration

The FastAPI application includes the following middleware stack (in execution order):

1. **CORSMiddleware** - Cross-origin request handling for n8n integration
2. **RequestIDMiddleware** - Request correlation with X-Request-ID header
3. **RequestLoggingMiddleware** - Structured logging for all requests
4. **RequestTimeoutMiddleware** - 60-second timeout for non-streaming requests
5. **GZipMiddleware** - Response compression for payloads > 1KB

**CORS Origins:**
- `http://hx-n8n-server.hx.dev.local:5678`
- Future: AG-UI frontend origin
```

### 7.3 Dependencies Section - Line 584

**Add to requirements:**

```
# Streaming
sse-starlette>=2.1.0

# Testing
pytest>=8.0.0
pytest-asyncio>=0.24.0
httpx>=0.27.0
```

### 7.4 Error Handling Section

**Add after Line 524:**

```markdown
### Error Response Contract

All error responses follow RFC 7807 Problem Details format:

| Field | Type | Description |
|-------|------|-------------|
| type | string | URI identifying error type |
| title | string | Human-readable summary |
| status | integer | HTTP status code |
| detail | string | Detailed explanation |
| instance | string | Request path |
| request_id | string | Correlation ID |
| error_code | string | Application error code |

**Error Codes:**
- `INVALID_REQUEST` (400) - Malformed request
- `VALIDATION_ERROR` (422) - Pydantic validation failure
- `THREAD_NOT_FOUND` (404) - Thread ID not found
- `RATE_LIMITED` (429) - Too many requests
- `OLLAMA_UNAVAILABLE` (503) - Ollama server unreachable
- `LIGHTRAG_UNAVAILABLE` (503) - LightRAG service unreachable
- `CHECKPOINT_FAILED` (500) - PostgreSQL checkpoint error
- `REQUEST_TIMEOUT` (504) - Request exceeded 60s timeout
```

---

## 8. SOLID Principles Verification

### 8.1 Application of SOLID in FastAPI Layer

| Principle | Application | Evidence |
|-----------|-------------|----------|
| **SRP** | Each router handles single resource type | invoke.py, threads.py, health.py, webhooks.py |
| **SRP** | Each middleware has single concern | RequestIDMiddleware, LoggingMiddleware, TimeoutMiddleware |
| **OCP** | New endpoints without modifying existing | Router prefix pattern allows extension |
| **OCP** | Pydantic model inheritance | AsyncInvokeRequest extends InvokeRequest |
| **LSP** | All routers are APIRouter instances | Consistent include_router() behavior |
| **ISP** | Focused dependencies | get_graph(), get_redis(), get_checkpointer() |
| **DIP** | Config via Pydantic Settings | No hardcoded values in endpoint code |
| **DIP** | Dependencies via Depends() | Endpoints depend on abstractions |

### 8.2 Compliance Confirmation

The code examples in this contribution document follow all SOLID principles as mandated by the charter (Line 135). The separation of routers, dependencies, middleware, and schemas ensures maintainability and testability.

---

## Summary of Contributions

| Category | Items Added |
|----------|-------------|
| Endpoints | 4 new endpoints (/v1/invoke/async, /health/ready, /health/deep, /v1/webhooks list) |
| Pydantic Models | 12 complete models with validation |
| Middleware | 4 production-ready middleware components |
| Async Patterns | Lifespan context manager, dependency injection, background tasks |
| Code Examples | Complete application structure, 5 production files |
| Spec Corrections | 6 items requiring update |

---

**Signature:** Bob (FastAPI SME)
**Date:** 2025-12-01

---

## Appendix: Reference Documents Consulted

- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/async.md`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/tutorial/dependencies/index.md`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/advanced/middleware.md`
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/advanced/events.md`
- `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/charter/charter.md`
- `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/charter/reviews/bob-fastapi-review.md`
- `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
