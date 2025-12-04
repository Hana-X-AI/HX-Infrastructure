# Task: Implement /api/v1/invoke Endpoint

**Task ID**: hx-lang-server-task-105-implement-invoke-endpoint
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-104 (Pydantic models), hx-lang-server-task-051 (LangGraph supervisor)
**Estimated Time**: 90 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Implement the synchronous agent invocation endpoint at `POST /api/v1/invoke`. This endpoint receives user queries, routes them through the LangGraph supervisor agent, and returns the complete response. The implementation includes request validation, query classification, agent invocation with `ainvoke()`, checkpoint persistence, and structured response formatting.

---

## Pre-Execution Validation

**CRITICAL**: Check if endpoint is already implemented BEFORE executing steps.

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Check for complete implementation
python3 -c "
from app.routers.v1.invoke import router, invoke_agent
import inspect
# Check if invoke_agent has actual implementation (not just placeholder)
source = inspect.getsource(invoke_agent)
if 'not_implemented' in source.lower():
    raise Exception('Still placeholder')
print('VALIDATION: Invoke endpoint implemented - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Invoke endpoint not implemented - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] Pydantic models created (Task 104): InvokeRequest, InvokeResponse
- [ ] Application factory implemented (Task 102)
- [ ] Configuration module implemented (Task 103)
- [ ] LangGraph supervisor agent implemented (Task 051 - Work Stream 6)
- [ ] PostgreSQL checkpointer configured (Task 031-040 - Work Stream 4)
- [ ] Redis session manager configured (Task 041-050 - Work Stream 5)

---

## Steps

### 1. Create Invoke Router Implementation

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

cat > /opt/hx-lang-server/app/routers/v1/invoke.py <<'EOF'
"""
Synchronous agent invocation endpoint (POST /api/v1/invoke).

This endpoint provides synchronous agent invocation where the complete
response is returned after agent processing completes.

Specification Reference:
- FR-021: REST API via FastAPI on port 8100
- FR-022: Async endpoints using async def with ainvoke()
- FR-001: LangGraph supervisor pattern
"""
import time
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import JSONResponse
import structlog

from app.models import InvokeRequest, InvokeResponse, ErrorResponse
from app.core.config import Settings, get_settings
from app.core.dependencies import (
    get_supervisor_agent,
    get_session_manager,
    get_request_id,
)
from app.services.query_classifier import classify_query
from app.agents.supervisor import SupervisorAgent
from app.services.session import SessionManager


logger = structlog.get_logger()

router = APIRouter()


@router.post(
    "/invoke",
    response_model=InvokeResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Invalid request"},
        429: {"model": ErrorResponse, "description": "Rate limit exceeded"},
        500: {"model": ErrorResponse, "description": "Internal server error"},
        503: {"model": ErrorResponse, "description": "Service unavailable"},
    },
    summary="Invoke agent synchronously",
    description="""
    Invoke the LangGraph supervisor agent with a user query.

    The agent:
    1. Classifies the query type (general, code, rag, tool)
    2. Routes to the appropriate worker agent
    3. Processes the query with the selected LLM
    4. Returns the complete response

    For streaming responses, use POST /api/v1/stream instead.
    """,
)
async def invoke_agent(
    request: InvokeRequest,
    http_request: Request,
    settings: Settings = Depends(get_settings),
    supervisor: SupervisorAgent = Depends(get_supervisor_agent),
    session_manager: SessionManager = Depends(get_session_manager),
    request_id: str = Depends(get_request_id),
) -> InvokeResponse:
    """
    Synchronous agent invocation endpoint.

    Args:
        request: Validated invoke request with query and optional thread_id
        http_request: FastAPI request object for metadata
        settings: Application settings
        supervisor: LangGraph supervisor agent instance
        session_manager: Redis session manager
        request_id: Unique request identifier for tracing

    Returns:
        InvokeResponse with agent response and metadata

    Raises:
        HTTPException: On validation errors, rate limits, or service failures
    """
    start_time = time.time()

    logger.info(
        "invoke_request_received",
        request_id=request_id,
        query_length=len(request.query),
        thread_id=request.thread_id,
        session_id=request.session_id,
    )

    try:
        # Determine or create thread_id
        thread_id = request.thread_id or f"thread_{uuid.uuid4().hex[:12]}"

        # Create or extend session
        session_id = request.session_id or f"session_{uuid.uuid4().hex[:12]}"
        await session_manager.touch_session(session_id)

        # Classify query type for routing
        query_type = await classify_query(
            query=request.query,
            settings=settings,
        )

        logger.info(
            "query_classified",
            request_id=request_id,
            query_type=query_type,
            thread_id=thread_id,
        )

        # Prepare agent input state
        agent_input = {
            "messages": [{"role": "user", "content": request.query}],
            "query_type": query_type,
            "session_id": session_id,
            "thread_id": thread_id,
        }

        # Apply config overrides if provided
        agent_config = {
            "configurable": {
                "thread_id": thread_id,
            },
            "recursion_limit": settings.max_recursion_depth,
        }

        if request.config:
            if "max_iterations" in request.config:
                agent_config["recursion_limit"] = min(
                    request.config["max_iterations"],
                    settings.max_recursion_depth,
                )

        # Invoke supervisor agent (async)
        result = await supervisor.ainvoke(
            input=agent_input,
            config=agent_config,
        )

        # Extract response from result
        response_message = _extract_response(result)
        worker_used = result.get("current_worker", "supervisor")
        iteration_count = result.get("iteration_count", 1)

        # Calculate processing time
        processing_time_ms = int((time.time() - start_time) * 1000)

        logger.info(
            "invoke_request_completed",
            request_id=request_id,
            thread_id=thread_id,
            query_type=query_type,
            worker_used=worker_used,
            iteration_count=iteration_count,
            processing_time_ms=processing_time_ms,
        )

        return InvokeResponse(
            thread_id=thread_id,
            response=response_message,
            query_type=query_type,
            worker_used=worker_used,
            iteration_count=iteration_count,
            metadata={
                "request_id": request_id,
                "session_id": session_id,
                "processing_time_ms": processing_time_ms,
                "llm_used": _get_llm_for_query_type(query_type, settings),
            },
        )

    except TimeoutError as e:
        logger.error(
            "invoke_timeout",
            request_id=request_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=504,
            detail=ErrorResponse(
                error="Request timeout",
                error_code="TIMEOUT",
                detail="Agent invocation exceeded timeout limit",
                request_id=request_id,
            ).model_dump(),
        )

    except ConnectionError as e:
        logger.error(
            "invoke_service_unavailable",
            request_id=request_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=503,
            detail=ErrorResponse(
                error="Service unavailable",
                error_code="OLLAMA_UNAVAILABLE",
                detail=str(e),
                request_id=request_id,
            ).model_dump(),
        )

    except Exception as e:
        logger.exception(
            "invoke_error",
            request_id=request_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=500,
            detail=ErrorResponse(
                error="Internal server error",
                error_code="INTERNAL_ERROR",
                detail=str(e) if settings.debug else None,
                request_id=request_id,
            ).model_dump(),
        )


def _extract_response(result: dict) -> str:
    """
    Extract the response message from agent result.

    The result structure depends on the LangGraph state schema.
    """
    messages = result.get("messages", [])
    if messages:
        # Get last AI message
        for msg in reversed(messages):
            if isinstance(msg, dict) and msg.get("role") == "assistant":
                return msg.get("content", "")
            # Handle LangChain message objects
            if hasattr(msg, "type") and msg.type == "ai":
                return msg.content

    return result.get("response", "No response generated")


def _get_llm_for_query_type(query_type: str, settings: Settings) -> str:
    """
    Return the LLM identifier used for a query type.
    """
    if query_type == "code":
        return f"ollama2:{settings.ollama_code_model}"
    return f"ollama1:{settings.ollama_general_model}"
EOF
```

### 2. Create Dependencies Module

```bash
cat > /opt/hx-lang-server/app/core/dependencies.py <<'EOF'
"""
FastAPI dependency injection providers.

This module provides dependency functions for injecting
services and utilities into API endpoints.

Usage:
    @router.get("/endpoint")
    async def endpoint(service: Service = Depends(get_service)):
        ...
"""
import uuid
from typing import Optional

from fastapi import Depends, Request

from app.core.config import Settings, get_settings


async def get_request_id(request: Request) -> str:
    """
    Get or generate a unique request ID for tracing.

    Checks X-Request-ID header first, generates UUID if not present.
    """
    request_id = request.headers.get("X-Request-ID")
    if not request_id:
        request_id = f"req_{uuid.uuid4().hex[:12]}"
    return request_id


async def get_supervisor_agent(settings: Settings = Depends(get_settings)):
    """
    Get the LangGraph supervisor agent instance.

    This dependency is implemented in Work Stream 6 (Sophia).
    Currently returns a stub for API structure testing.

    TODO: Implement actual supervisor agent (Task 051-070)
    """
    from app.agents.supervisor import get_supervisor
    return await get_supervisor(settings)


async def get_session_manager(settings: Settings = Depends(get_settings)):
    """
    Get the Redis session manager instance.

    This dependency is implemented in Work Stream 5 (Sri).
    Currently returns a stub for API structure testing.

    TODO: Implement actual session manager (Task 041-050)
    """
    from app.services.session import get_session_manager as _get_session_manager
    return await _get_session_manager(settings)


async def get_checkpointer(settings: Settings = Depends(get_settings)):
    """
    Get the PostgreSQL checkpointer instance.

    This dependency is implemented in Work Stream 4 (Trinity).
    Currently returns a stub for API structure testing.

    TODO: Implement actual checkpointer (Task 031-040)
    """
    from app.integrations.postgres import get_checkpointer as _get_checkpointer
    return await _get_checkpointer(settings)


async def get_ollama_client(
    query_type: str,
    settings: Settings = Depends(get_settings),
):
    """
    Get the appropriate Ollama client based on query type.

    This dependency is implemented in Work Stream 7 (Jim).

    TODO: Implement actual Ollama client (Task 071-080)
    """
    from app.integrations.ollama import get_ollama_client as _get_ollama
    return await _get_ollama(query_type, settings)


async def get_lightrag_client(settings: Settings = Depends(get_settings)):
    """
    Get the LightRAG HTTP client.

    This dependency is implemented in Work Stream 8 (Andy).

    TODO: Implement actual LightRAG client (Task 081-090)
    """
    from app.integrations.lightrag import get_lightrag_client as _get_lightrag
    return await _get_lightrag(settings)


async def get_mcp_client(settings: Settings = Depends(get_settings)):
    """
    Get the MCP client (langchain-mcp-adapters).

    This dependency is implemented in Work Stream 9 (George).

    TODO: Implement actual MCP client (Task 091-100)
    """
    from app.integrations.mcp import get_mcp_client as _get_mcp
    return await _get_mcp(settings)
EOF
```

### 3. Create Query Classifier Service Stub

```bash
mkdir -p /opt/hx-lang-server/app/services

cat > /opt/hx-lang-server/app/services/__init__.py <<'EOF'
"""Services package for business logic."""
EOF

cat > /opt/hx-lang-server/app/services/query_classifier.py <<'EOF'
"""
Query classification service for Ollama routing.

This module classifies user queries to determine which
worker agent and LLM should handle them.

Specification Reference: Query Classification Mechanism section
"""
from typing import Optional

from app.core.config import Settings


# Keyword sets for classification (from specification)
CODE_KEYWORDS = {
    "code", "function", "class", "debug", "error",
    "python", "javascript", "sql", "api", "implement",
    "variable", "loop", "algorithm", "compile", "syntax",
}

RAG_KEYWORDS = {
    "search", "find", "document", "knowledge",
    "what is", "explain", "how does", "tell me about",
    "information", "lookup", "retrieve",
}

TOOL_KEYWORDS = {
    "crawl", "fetch", "scrape", "web", "url",
    "download", "extract from", "get page",
}


async def classify_query(
    query: str,
    settings: Optional[Settings] = None,
) -> str:
    """
    Classify a user query for routing to appropriate worker.

    Classification strategy (from specification):
    1. Keyword-based classification (fast path)
    2. LLM fallback for ambiguous queries (slow path)

    Args:
        query: User query text
        settings: Application settings (for LLM fallback config)

    Returns:
        Query type: "code", "rag", "tool", or "general"
    """
    query_lower = query.lower()

    # Check for code-related keywords
    if any(kw in query_lower for kw in CODE_KEYWORDS):
        return "code"

    # Check for tool-related keywords
    if any(kw in query_lower for kw in TOOL_KEYWORDS):
        return "tool"

    # Check for RAG-related keywords
    if any(kw in query_lower for kw in RAG_KEYWORDS):
        return "rag"

    # Default to general (could add LLM fallback here)
    # TODO: Implement LLM fallback for ambiguous queries
    return "general"
EOF
```

### 4. Create Session Service Stub

```bash
cat > /opt/hx-lang-server/app/services/session.py <<'EOF'
"""
Session management service.

This module manages ephemeral session state in Redis.
Full implementation in Work Stream 5 (Sri).

Specification Reference: Redis Integration section
"""
from typing import Optional

from app.core.config import Settings


class SessionManager:
    """
    Manages session state in Redis.

    Stub implementation for API testing.
    Full implementation: Tasks 041-050 (Work Stream 5)
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self.key_prefix = settings.redis_key_prefix

    async def touch_session(self, session_id: str) -> None:
        """
        Create or extend session TTL.

        TODO: Implement with Redis (Task 041-050)
        """
        pass  # Stub - Redis implementation in Work Stream 5

    async def get_session(self, session_id: str) -> Optional[dict]:
        """
        Retrieve session data.

        TODO: Implement with Redis (Task 041-050)
        """
        return None  # Stub

    async def delete_session(self, session_id: str) -> bool:
        """
        Delete a session.

        TODO: Implement with Redis (Task 041-050)
        """
        return True  # Stub


async def get_session_manager(settings: Settings) -> SessionManager:
    """
    Get session manager instance.

    Factory function for dependency injection.
    """
    return SessionManager(settings)
EOF
```

### 5. Create Supervisor Agent Stub

```bash
mkdir -p /opt/hx-lang-server/app/agents

cat > /opt/hx-lang-server/app/agents/__init__.py <<'EOF'
"""LangGraph agents package."""
EOF

cat > /opt/hx-lang-server/app/agents/supervisor.py <<'EOF'
"""
LangGraph supervisor agent.

This module implements the supervisor agent that orchestrates
worker agents based on query classification.

Full implementation in Work Stream 6 (Sophia).

Specification Reference: Core Agent Orchestration section
"""
from typing import Any, Dict

from app.core.config import Settings


class SupervisorAgent:
    """
    LangGraph supervisor agent stub.

    Full implementation: Tasks 051-070 (Work Stream 6)
    """

    def __init__(self, settings: Settings):
        self.settings = settings

    async def ainvoke(
        self,
        input: Dict[str, Any],
        config: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Invoke the supervisor agent asynchronously.

        Stub implementation returns mock response.
        Full implementation uses LangGraph StateGraph.

        Args:
            input: Agent input state
            config: Agent configuration

        Returns:
            Result state with response
        """
        # Stub response for API structure testing
        return {
            "messages": [
                {"role": "user", "content": input.get("messages", [{}])[0].get("content", "")},
                {"role": "assistant", "content": "Supervisor agent stub response. "
                                                  "Full implementation pending Work Stream 6."},
            ],
            "query_type": input.get("query_type", "general"),
            "current_worker": "stub_worker",
            "iteration_count": 1,
        }


_supervisor: SupervisorAgent = None


async def get_supervisor(settings: Settings) -> SupervisorAgent:
    """
    Get or create supervisor agent instance.

    Uses singleton pattern for shared agent instance.
    """
    global _supervisor
    if _supervisor is None:
        _supervisor = SupervisorAgent(settings)
    return _supervisor
EOF
```

### 6. Test Endpoint Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test router imports
python3 -c "
from app.routers.v1.invoke import router, invoke_agent
print(f'Router created with {len(router.routes)} routes')
for route in router.routes:
    print(f'  {route.path} - {route.methods}')
"

# Test query classifier
python3 -c "
import asyncio
from app.services.query_classifier import classify_query

async def test():
    # Test code classification
    q = await classify_query('Write a Python function to sort a list')
    assert q == 'code', f'Expected code, got {q}'
    print(f'PASS: Code query classified as {q}')

    # Test RAG classification
    q = await classify_query('What is dependency injection?')
    assert q == 'rag', f'Expected rag, got {q}'
    print(f'PASS: RAG query classified as {q}')

    # Test tool classification
    q = await classify_query('Crawl this URL and extract the content')
    assert q == 'tool', f'Expected tool, got {q}'
    print(f'PASS: Tool query classified as {q}')

    # Test general classification
    q = await classify_query('Hello, how are you?')
    assert q == 'general', f'Expected general, got {q}'
    print(f'PASS: General query classified as {q}')

asyncio.run(test())
"

# Test supervisor stub
python3 -c "
import asyncio
from app.agents.supervisor import get_supervisor
from app.core.config import get_settings

async def test():
    settings = get_settings()
    supervisor = await get_supervisor(settings)

    result = await supervisor.ainvoke(
        input={'messages': [{'role': 'user', 'content': 'test'}], 'query_type': 'general'},
        config={'configurable': {'thread_id': 'test_thread'}}
    )

    print(f'Supervisor invoked: {len(result.get(\"messages\", []))} messages')
    print(f'Worker used: {result.get(\"current_worker\")}')

asyncio.run(test())
"
```

### 7. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/invoke-endpoint-implementation.txt <<EOF
Invoke Endpoint Implementation Record
=====================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-105-implement-invoke-endpoint

Files Created/Modified:
- /opt/hx-lang-server/app/routers/v1/invoke.py
- /opt/hx-lang-server/app/core/dependencies.py
- /opt/hx-lang-server/app/services/query_classifier.py
- /opt/hx-lang-server/app/services/session.py
- /opt/hx-lang-server/app/agents/supervisor.py

Endpoint: POST /api/v1/invoke
Request Model: InvokeRequest
Response Model: InvokeResponse

Features Implemented:
- Request validation with Pydantic
- Query classification for routing
- Thread ID generation/continuation
- Session management integration
- Structured logging
- Error handling with ErrorResponse
- OpenAPI documentation

Stubs Created (for integration work streams):
- SupervisorAgent (Work Stream 6 - Sophia)
- SessionManager (Work Stream 5 - Sri)
- Query classifier (full impl in Work Stream 6)

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/invoke-endpoint-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] Router file is syntactically correct:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/routers/v1/invoke.py
  echo "PASS: Syntax OK"
  ```

- [ ] Router can be imported:
  ```bash
  python3 -c "from app.routers.v1.invoke import router; print('PASS: Router imports')"
  ```

- [ ] Query classifier works correctly:
  ```bash
  python3 -c "
  import asyncio
  from app.services.query_classifier import classify_query
  assert asyncio.run(classify_query('write python code')) == 'code'
  print('PASS: Classifier works')
  "
  ```

- [ ] Endpoint registered in app:
  ```bash
  python3 -c "
  from app.main import app
  paths = [r.path for r in app.routes if hasattr(r, 'path')]
  assert '/api/v1/invoke' in paths
  print('PASS: Endpoint registered')
  "
  ```

- [ ] Response model matches specification:
  ```bash
  python3 -c "
  from app.models import InvokeResponse
  fields = InvokeResponse.model_fields.keys()
  required = {'thread_id', 'response', 'query_type', 'worker_used', 'iteration_count', 'metadata'}
  assert required.issubset(fields)
  print('PASS: Response model complete')
  "
  ```

---

## Rollback

If implementation needs to be reverted:

```bash
# Restore placeholder router
cat > /opt/hx-lang-server/app/routers/v1/invoke.py <<'EOF'
"""Placeholder - See task-105."""
from fastapi import APIRouter
router = APIRouter()

@router.post("/invoke")
async def invoke_agent():
    return {"status": "not_implemented"}
EOF

# Remove service stubs if needed
rm -f /opt/hx-lang-server/app/services/query_classifier.py
rm -f /opt/hx-lang-server/app/services/session.py
rm -f /opt/hx-lang-server/app/agents/supervisor.py
```

---

## Notes

### Endpoint Design

The `/invoke` endpoint follows RESTful design:
- **POST** method for state-changing operation
- JSON request/response bodies
- Structured error responses
- Request ID for tracing

### Async Pattern

Per FR-022, the endpoint uses `async def` with `ainvoke()`:
```python
result = await supervisor.ainvoke(input, config)
```

This enables non-blocking processing of LLM calls.

### Query Classification

The classifier uses a two-tier approach (from specification):
1. **Fast path**: Keyword matching (sub-millisecond)
2. **Slow path**: LLM classification (fallback, not yet implemented)

### Integration Points

This task creates stubs for integration with other work streams:
- **Work Stream 5 (Sri)**: Redis session management
- **Work Stream 6 (Sophia)**: LangGraph supervisor agent
- **Work Stream 7 (Jim)**: Ollama LLM integration

The stubs enable API structure testing while full implementations are developed in parallel.

---

## Related Tasks

**Prerequisites**:
- Task 104: Pydantic models (InvokeRequest, InvokeResponse)
- Task 103: Configuration (Settings class)

**Dependencies (Other Work Streams)**:
- Task 051-070: LangGraph supervisor (Work Stream 6)
- Task 041-050: Redis session manager (Work Stream 5)

**Next Tasks**:
- Task 106: Implement /stream endpoint (SSE streaming)
- Task 107: Implement session management endpoints

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: API Specification > POST /invoke
- Section: Query Classification Mechanism
- FR-021: REST API via FastAPI
- FR-022: Async endpoints with ainvoke()

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
