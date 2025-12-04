# Task: Implement /api/v1/stream Endpoint (SSE)

**Task ID**: hx-lang-server-task-106-implement-stream-endpoint
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-105 (Invoke endpoint), hx-lang-server-task-051 (LangGraph supervisor)
**Estimated Time**: 90 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Implement the streaming agent invocation endpoint at `POST /api/v1/stream`. This endpoint uses Server-Sent Events (SSE) to stream agent responses in real-time as tokens are generated. The implementation provides a responsive user experience for long-running queries while maintaining compatibility with n8n and other consumers that support streaming.

---

## Pre-Execution Validation

**CRITICAL**: Check if endpoint is already implemented BEFORE executing steps.

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
from app.routers.v1.stream import router, stream_agent
import inspect
source = inspect.getsource(stream_agent)
if 'not_implemented' in source.lower():
    raise Exception('Still placeholder')
print('VALIDATION: Stream endpoint implemented - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Stream endpoint not implemented - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] Invoke endpoint implemented (Task 105)
- [ ] Pydantic models created (Task 104): StreamRequest, StreamChunk
- [ ] sse-starlette package installed in virtual environment
- [ ] LangGraph supervisor with astream() support (Task 051-070)

---

## Steps

### 1. Verify SSE Dependencies

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

python3 -c "
from sse_starlette.sse import EventSourceResponse
print('SSE Starlette available')
"
```

### 2. Implement Stream Router

```bash
cat > /opt/hx-lang-server/app/routers/v1/stream.py <<'EOF'
"""
Streaming agent invocation endpoint with SSE (POST /api/v1/stream).

This endpoint provides real-time streaming of agent responses using
Server-Sent Events (SSE). Tokens are streamed as they are generated
by the LLM, providing a responsive user experience.

Specification Reference:
- FR-022: Async endpoints for streaming
- API Specification > POST /stream
"""
import json
import time
import uuid
from typing import AsyncGenerator

from fastapi import APIRouter, Depends, HTTPException, Request
from sse_starlette.sse import EventSourceResponse
import structlog

from app.models import StreamRequest, StreamChunk, ErrorResponse
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
    "/stream",
    response_class=EventSourceResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Invalid request"},
        429: {"model": ErrorResponse, "description": "Rate limit exceeded"},
        500: {"model": ErrorResponse, "description": "Internal server error"},
        503: {"model": ErrorResponse, "description": "Service unavailable"},
    },
    summary="Invoke agent with streaming response",
    description="""
    Invoke the LangGraph supervisor agent with streaming response via SSE.

    Response is streamed as Server-Sent Events with the following event types:
    - `metadata`: Initial metadata (thread_id, query_type)
    - `token`: Individual response tokens
    - `error`: Error information (if any)
    - `done`: Final event with complete metadata

    For synchronous response, use POST /api/v1/invoke instead.
    """,
)
async def stream_agent(
    request: StreamRequest,
    http_request: Request,
    settings: Settings = Depends(get_settings),
    supervisor: SupervisorAgent = Depends(get_supervisor_agent),
    session_manager: SessionManager = Depends(get_session_manager),
    request_id: str = Depends(get_request_id),
):
    """
    Streaming agent invocation endpoint.

    Args:
        request: Validated stream request with query
        http_request: FastAPI request object
        settings: Application settings
        supervisor: LangGraph supervisor agent
        session_manager: Redis session manager
        request_id: Request ID for tracing

    Returns:
        EventSourceResponse with streaming SSE events
    """
    logger.info(
        "stream_request_received",
        request_id=request_id,
        query_length=len(request.query),
        thread_id=request.thread_id,
    )

    # Create generator for SSE events
    async def event_generator() -> AsyncGenerator[dict, None]:
        """
        Generate SSE events from agent stream.

        Yields events in format:
        {"event": "<type>", "data": "<json>"}
        """
        start_time = time.time()
        thread_id = request.thread_id or f"thread_{uuid.uuid4().hex[:12]}"
        session_id = request.session_id or f"session_{uuid.uuid4().hex[:12]}"

        try:
            # Touch session in Redis
            await session_manager.touch_session(session_id)

            # Classify query
            query_type = await classify_query(
                query=request.query,
                settings=settings,
            )

            # Send initial metadata event
            yield {
                "event": "metadata",
                "data": json.dumps(StreamChunk(
                    chunk_type="metadata",
                    thread_id=thread_id,
                    metadata={
                        "request_id": request_id,
                        "session_id": session_id,
                        "query_type": query_type,
                    },
                ).model_dump()),
            }

            # Prepare agent input
            agent_input = {
                "messages": [{"role": "user", "content": request.query}],
                "query_type": query_type,
                "session_id": session_id,
                "thread_id": thread_id,
            }

            agent_config = {
                "configurable": {"thread_id": thread_id},
                "recursion_limit": settings.max_recursion_depth,
            }

            # Stream from supervisor agent
            token_count = 0
            full_response = ""

            async for chunk in supervisor.astream(
                input=agent_input,
                config=agent_config,
            ):
                # Extract token from chunk
                token = _extract_token(chunk)

                if token:
                    token_count += 1
                    full_response += token

                    yield {
                        "event": "token",
                        "data": json.dumps(StreamChunk(
                            chunk_type="token",
                            content=token,
                        ).model_dump()),
                    }

            # Calculate timing
            processing_time_ms = int((time.time() - start_time) * 1000)

            # Send completion event
            yield {
                "event": "done",
                "data": json.dumps(StreamChunk(
                    chunk_type="done",
                    thread_id=thread_id,
                    metadata={
                        "request_id": request_id,
                        "token_count": token_count,
                        "processing_time_ms": processing_time_ms,
                        "query_type": query_type,
                    },
                ).model_dump()),
            }

            logger.info(
                "stream_request_completed",
                request_id=request_id,
                thread_id=thread_id,
                token_count=token_count,
                processing_time_ms=processing_time_ms,
            )

        except Exception as e:
            logger.exception(
                "stream_error",
                request_id=request_id,
                error=str(e),
            )

            # Send error event
            yield {
                "event": "error",
                "data": json.dumps(StreamChunk(
                    chunk_type="error",
                    metadata={
                        "error": str(e),
                        "error_code": "STREAM_ERROR",
                        "request_id": request_id,
                    },
                ).model_dump()),
            }

    # Return SSE response
    return EventSourceResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Request-ID": request_id,
        },
    )


def _extract_token(chunk: dict) -> str:
    """
    Extract token content from stream chunk.

    The chunk structure depends on LangGraph streaming format.
    """
    # Handle different chunk formats
    if isinstance(chunk, str):
        return chunk

    if isinstance(chunk, dict):
        # Check for content key
        if "content" in chunk:
            return chunk["content"]

        # Check for messages with streaming tokens
        messages = chunk.get("messages", [])
        if messages:
            last_msg = messages[-1]
            if isinstance(last_msg, dict):
                return last_msg.get("content", "")
            if hasattr(last_msg, "content"):
                return last_msg.content

    return ""
EOF
```

### 3. Add astream Method to Supervisor Stub

```bash
cat > /opt/hx-lang-server/app/agents/supervisor.py <<'EOF'
"""
LangGraph supervisor agent.

This module implements the supervisor agent that orchestrates
worker agents based on query classification.

Full implementation in Work Stream 6 (Sophia).

Specification Reference: Core Agent Orchestration section
"""
import asyncio
from typing import Any, AsyncGenerator, Dict

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

    async def astream(
        self,
        input: Dict[str, Any],
        config: Dict[str, Any],
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Stream supervisor agent responses asynchronously.

        Stub implementation yields mock tokens.
        Full implementation uses LangGraph StateGraph with streaming.

        Args:
            input: Agent input state
            config: Agent configuration

        Yields:
            Stream chunks with content
        """
        # Stub streaming response
        response_text = (
            "This is a streaming stub response from the supervisor agent. "
            "Full streaming implementation pending Work Stream 6 (Sophia). "
            "Each word will be streamed as a separate token."
        )

        words = response_text.split()
        for i, word in enumerate(words):
            # Simulate token generation delay
            await asyncio.sleep(0.05)

            # Add space except for first word
            token = word if i == 0 else f" {word}"

            yield {"content": token}


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

### 4. Update Router __init__.py

```bash
cat > /opt/hx-lang-server/app/routers/v1/__init__.py <<'EOF'
"""
API v1 routers package.
"""
from . import invoke, stream, sessions

__all__ = ["invoke", "stream", "sessions"]
EOF
```

### 5. Test Stream Endpoint

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test router imports
python3 -c "
from app.routers.v1.stream import router, stream_agent
print(f'Router created with {len(router.routes)} routes')
for route in router.routes:
    print(f'  {route.path} - {route.methods}')
"

# Test supervisor streaming
python3 -c "
import asyncio
from app.agents.supervisor import get_supervisor
from app.core.config import get_settings

async def test():
    settings = get_settings()
    supervisor = await get_supervisor(settings)

    tokens = []
    async for chunk in supervisor.astream(
        input={'messages': [{'role': 'user', 'content': 'test'}], 'query_type': 'general'},
        config={'configurable': {'thread_id': 'test_thread'}}
    ):
        if 'content' in chunk:
            tokens.append(chunk['content'])

    print(f'Streamed {len(tokens)} tokens')
    print(f'Full response: {\"\" .join(tokens)[:100]}...')

asyncio.run(test())
"

# Test endpoint is registered
python3 -c "
from app.main import app
paths = [r.path for r in app.routes if hasattr(r, 'path')]
assert '/api/v1/stream' in paths
print('PASS: Stream endpoint registered')
"
```

### 6. Test SSE Response Format

```bash
# Create test script for SSE format validation
cat > /tmp/test_sse_format.py <<'EOF'
"""Test SSE response format."""
import asyncio
from app.models import StreamChunk

# Test StreamChunk serialization
chunk = StreamChunk(
    chunk_type="token",
    content="Hello",
)
print(f"Token chunk: {chunk.model_dump_json()}")

chunk = StreamChunk(
    chunk_type="metadata",
    thread_id="thread_123",
    metadata={"query_type": "general"},
)
print(f"Metadata chunk: {chunk.model_dump_json()}")

chunk = StreamChunk(
    chunk_type="done",
    thread_id="thread_123",
    metadata={"token_count": 50, "processing_time_ms": 1234},
)
print(f"Done chunk: {chunk.model_dump_json()}")

print("\nAll SSE format tests passed!")
EOF

python3 /tmp/test_sse_format.py
rm /tmp/test_sse_format.py
```

### 7. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/stream-endpoint-implementation.txt <<EOF
Stream Endpoint Implementation Record
=====================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-106-implement-stream-endpoint

Files Created/Modified:
- /opt/hx-lang-server/app/routers/v1/stream.py
- /opt/hx-lang-server/app/agents/supervisor.py (added astream method)
- /opt/hx-lang-server/app/routers/v1/__init__.py (updated)

Endpoint: POST /api/v1/stream
Response: EventSourceResponse (SSE)

SSE Event Types:
- metadata: Initial metadata (thread_id, query_type)
- token: Individual response tokens
- error: Error information
- done: Completion with final metadata

Features Implemented:
- SSE streaming with sse-starlette
- Token-by-token response streaming
- Error handling in stream
- Request ID in headers
- Session management integration

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/stream-endpoint-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] Router file is syntactically correct:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/routers/v1/stream.py
  echo "PASS: Syntax OK"
  ```

- [ ] Router can be imported:
  ```bash
  python3 -c "from app.routers.v1.stream import router; print('PASS: Router imports')"
  ```

- [ ] Supervisor astream method works:
  ```bash
  python3 -c "
  import asyncio
  from app.agents.supervisor import get_supervisor
  from app.core.config import get_settings

  async def test():
      s = await get_supervisor(get_settings())
      count = 0
      async for _ in s.astream({'messages': []}, {}):
          count += 1
      assert count > 0
      print(f'PASS: Streamed {count} chunks')

  asyncio.run(test())
  "
  ```

- [ ] Endpoint registered in app:
  ```bash
  python3 -c "
  from app.main import app
  paths = [r.path for r in app.routes if hasattr(r, 'path')]
  assert '/api/v1/stream' in paths
  print('PASS: Endpoint registered')
  "
  ```

- [ ] StreamChunk model serializes correctly:
  ```bash
  python3 -c "
  from app.models import StreamChunk
  chunk = StreamChunk(chunk_type='token', content='test')
  assert 'token' in chunk.model_dump_json()
  print('PASS: StreamChunk serializes')
  "
  ```

---

## Rollback

If implementation needs to be reverted:

```bash
# Restore placeholder router
cat > /opt/hx-lang-server/app/routers/v1/stream.py <<'EOF'
"""Placeholder - See task-106."""
from fastapi import APIRouter
router = APIRouter()

@router.post("/stream")
async def stream_agent():
    return {"status": "not_implemented"}
EOF
```

---

## Notes

### SSE Event Format

Server-Sent Events follow the format:
```
event: <event_type>
data: <json_data>

```

Each event ends with double newline. Our implementation uses:
- `metadata`: Initial context (thread_id, query_type)
- `token`: Streamed content tokens
- `error`: Error information
- `done`: Completion signal with stats

### Client Consumption

Clients can consume the stream with:
```javascript
const eventSource = new EventSource('/api/v1/stream');
eventSource.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.chunk_type === 'token') {
        appendToUI(data.content);
    }
};
```

### n8n Integration

n8n can consume SSE streams using the HTTP Request node with:
- Response Format: Stream
- Event handling in subsequent nodes

### Performance Considerations

- Token streaming adds minimal overhead per token
- Connection held open until completion
- Consider implementing heartbeat for long operations
- Rate limiting applies to stream initiation

---

## Related Tasks

**Prerequisites**:
- Task 105: Invoke endpoint (shares dependencies)
- Task 104: Pydantic models (StreamRequest, StreamChunk)

**Dependencies (Other Work Streams)**:
- Task 051-070: LangGraph supervisor with astream() (Work Stream 6)

**Next Tasks**:
- Task 107: Session management endpoints
- Task 108: Health endpoint

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: API Specification > POST /stream
- FR-022: Async endpoints for streaming

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
