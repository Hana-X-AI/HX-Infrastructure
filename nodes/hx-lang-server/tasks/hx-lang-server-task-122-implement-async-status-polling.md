# Task: Implement Async Status Polling Endpoint

**Task ID**: hx-lang-server-task-122-implement-async-status-polling
**Phase**: Implementation (Phase 2)
**Assigned To**: Isabella (n8n Workflow Automation SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-121 (n8n HTTP endpoint), hx-lang-server-task-042 (Redis session manager)
**Estimated Time**: 60 minutes

---

## Objective

Implement `/status/{thread_id}` endpoint to allow n8n workflows to poll for async operation status and retrieve completed results. This enables n8n workflows to implement polling patterns for long-running agent operations instead of webhook callbacks.

---

## Prerequisites

- [ ] n8n HTTP endpoint `/invoke` implemented with async support
- [ ] Redis session manager functional with namespace prefix
- [ ] Thread ID generation working for new conversations
- [ ] Agent service stores intermediate status in Redis

---

## Specification Reference

**From node-spec.md v2.1, Section: API Specification**

Lines 479-487:
```
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/invoke` | Synchronous agent invocation |
| POST | `/stream` | Streaming agent invocation (SSE) |
| GET | `/health` | Health check |
| GET | `/ready` | Readiness check |
| GET | `/threads/{thread_id}` | Get thread history |
```

**n8n Integration Requirements:**
- FR-028: Service MUST provide thread_id for conversation continuity in n8n workflows

---

## Implementation Steps

### Step 1: Create Status Models

Create file: `/opt/hx-lang-server/app/api/models/status.py`

```python
"""
Models for async operation status polling.

Supports n8n polling patterns for long-running agent operations.
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, Literal
from datetime import datetime
from enum import Enum


class OperationStatus(str, Enum):
    """Status of async operation."""

    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    TIMEOUT = "timeout"


class StatusResponse(BaseModel):
    """Response model for status polling."""

    thread_id: str = Field(
        ...,
        description="Thread ID for this operation",
    )

    status: OperationStatus = Field(
        ...,
        description="Current operation status",
    )

    progress_percent: Optional[int] = Field(
        None,
        description="Progress percentage (0-100) if available",
        ge=0,
        le=100,
    )

    current_worker: Optional[str] = Field(
        None,
        description="Currently active worker agent",
    )

    iteration_count: int = Field(
        0,
        description="Number of graph iterations completed",
    )

    result: Optional[Dict[str, Any]] = Field(
        None,
        description="Final result (only when status=COMPLETED)",
    )

    error: Optional[str] = Field(
        None,
        description="Error message (only when status=FAILED)",
    )

    error_code: Optional[str] = Field(
        None,
        description="Error code for debugging",
    )

    created_at: datetime = Field(
        ...,
        description="Operation start time (UTC)",
    )

    updated_at: datetime = Field(
        ...,
        description="Last status update time (UTC)",
    )

    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional operation metadata",
    )


class ThreadHistoryResponse(BaseModel):
    """Response model for thread history retrieval."""

    thread_id: str = Field(
        ...,
        description="Thread ID",
    )

    messages: list[Dict[str, Any]] = Field(
        ...,
        description="Message history for this thread",
    )

    total_iterations: int = Field(
        ...,
        description="Total iterations across all queries",
    )

    created_at: datetime = Field(
        ...,
        description="Thread creation time (UTC)",
    )

    last_activity: datetime = Field(
        ...,
        description="Last activity time (UTC)",
    )
```

### Step 2: Implement Redis Status Tracking

Update `/opt/hx-lang-server/app/services/agent_service.py`:

```python
"""
Agent service with status tracking for async operations.
"""

import json
from datetime import datetime
from app.core.redis_config import get_redis_client
from app.core.config import settings
from app.api.models.status import OperationStatus
import structlog

logger = structlog.get_logger(__name__)


class AgentService:
    """Service for LangGraph agent invocation with status tracking."""

    def __init__(self):
        self.redis_client = None

    async def _get_redis(self):
        """Get Redis client lazily."""
        if self.redis_client is None:
            self.redis_client = await get_redis_client(settings.redis_url)
        return self.redis_client

    async def update_status(
        self,
        thread_id: str,
        status: OperationStatus,
        progress_percent: Optional[int] = None,
        current_worker: Optional[str] = None,
        iteration_count: int = 0,
        result: Optional[dict] = None,
        error: Optional[str] = None,
        error_code: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> None:
        """
        Update operation status in Redis for polling.

        Args:
            thread_id: Thread ID for status tracking
            status: Current operation status
            progress_percent: Optional progress indicator
            current_worker: Currently active worker
            iteration_count: Graph iteration count
            result: Final result (for COMPLETED status)
            error: Error message (for FAILED status)
            error_code: Error code for debugging
            metadata: Additional metadata
        """
        redis = await self._get_redis()

        status_key = f"hx-lang-server:status:{thread_id}"

        # Get existing status to preserve created_at
        existing = await redis.get(status_key)
        if existing:
            existing_data = json.loads(existing)
            created_at = existing_data.get("created_at", datetime.utcnow().isoformat())
        else:
            created_at = datetime.utcnow().isoformat()

        status_data = {
            "thread_id": thread_id,
            "status": status.value,
            "progress_percent": progress_percent,
            "current_worker": current_worker,
            "iteration_count": iteration_count,
            "result": result,
            "error": error,
            "error_code": error_code,
            "created_at": created_at,
            "updated_at": datetime.utcnow().isoformat(),
            "metadata": metadata or {},
        }

        # Store status with TTL (1 hour for completed/failed, 10 min for active)
        ttl = 3600 if status in [OperationStatus.COMPLETED, OperationStatus.FAILED] else 600

        await redis.setex(
            status_key,
            ttl,
            json.dumps(status_data),
        )

        logger.info(
            "status_updated",
            thread_id=thread_id,
            status=status.value,
            iteration_count=iteration_count,
        )

    async def get_status(self, thread_id: str) -> Optional[dict]:
        """
        Retrieve operation status from Redis.

        Args:
            thread_id: Thread ID to look up

        Returns:
            Status data dictionary or None if not found
        """
        redis = await self._get_redis()
        status_key = f"hx-lang-server:status:{thread_id}"

        status_json = await redis.get(status_key)
        if status_json:
            return json.loads(status_json)
        return None

    async def invoke(
        self,
        query: str,
        thread_id: Optional[str] = None,
        config: Optional[dict] = None,
    ) -> dict:
        """
        Invoke agent with status tracking.

        This method is updated to call update_status at key points.
        """
        import uuid

        thread_id = thread_id or str(uuid.uuid4())

        # Update status: PENDING
        await self.update_status(
            thread_id=thread_id,
            status=OperationStatus.PENDING,
            progress_percent=0,
            metadata={"query_length": len(query)},
        )

        try:
            # Update status: PROCESSING
            await self.update_status(
                thread_id=thread_id,
                status=OperationStatus.PROCESSING,
                progress_percent=25,
                current_worker="supervisor",
            )

            # TODO: Actual LangGraph invocation
            # For now, mock response
            result = {
                "thread_id": thread_id,
                "response": f"Mock response for: {query[:50]}...",
                "query_type": "general",
                "worker_used": "rag_agent",
                "iteration_count": 3,
                "llm_used": "hx-ollama1-server",
                "duration_ms": 1234,
            }

            # Update status: COMPLETED
            await self.update_status(
                thread_id=thread_id,
                status=OperationStatus.COMPLETED,
                progress_percent=100,
                iteration_count=result["iteration_count"],
                result=result,
            )

            return result

        except Exception as e:
            # Update status: FAILED
            await self.update_status(
                thread_id=thread_id,
                status=OperationStatus.FAILED,
                error=str(e),
                error_code="INVOCATION_ERROR",
            )
            raise
```

### Step 3: Implement Status Polling Endpoint

Create `/opt/hx-lang-server/app/api/routes/status.py`:

```python
"""
API routes for async operation status polling.
"""

from fastapi import APIRouter, HTTPException
from app.api.models.status import StatusResponse, ThreadHistoryResponse, OperationStatus
from app.services.agent_service import AgentService
import structlog

logger = structlog.get_logger(__name__)
router = APIRouter()


@router.get(
    "/status/{thread_id}",
    response_model=StatusResponse,
    summary="Poll async operation status",
    description="Check status of async agent invocation for n8n polling",
    tags=["Status", "n8n"],
)
async def get_operation_status(thread_id: str) -> StatusResponse:
    """
    Poll status of async operation by thread_id.

    Used by n8n workflows to implement polling pattern:
    1. POST /invoke with callback_url (returns immediately with thread_id)
    2. Poll GET /status/{thread_id} until status = COMPLETED or FAILED
    3. Retrieve result from response when complete

    Args:
        thread_id: Thread ID returned from /invoke endpoint

    Returns:
        StatusResponse with current operation status

    Raises:
        404: Thread ID not found or expired
    """
    logger.info("status_poll", thread_id=thread_id)

    agent_service = AgentService()
    status_data = await agent_service.get_status(thread_id)

    if not status_data:
        raise HTTPException(
            status_code=404,
            detail={
                "error": "Thread not found or status expired",
                "error_code": "THREAD_NOT_FOUND",
                "thread_id": thread_id,
            },
        )

    return StatusResponse(**status_data)


@router.get(
    "/threads/{thread_id}",
    response_model=ThreadHistoryResponse,
    summary="Get thread conversation history",
    description="Retrieve full conversation history for a thread",
    tags=["Threads"],
)
async def get_thread_history(thread_id: str) -> ThreadHistoryResponse:
    """
    Retrieve conversation history for a thread.

    This pulls checkpoint data from PostgreSQL to reconstruct
    the full message history for this thread.

    Args:
        thread_id: Thread ID

    Returns:
        ThreadHistoryResponse with message history

    Raises:
        404: Thread ID not found
    """
    logger.info("thread_history_request", thread_id=thread_id)

    # TODO: Implement checkpoint retrieval from PostgreSQL
    # For now, return mock data
    raise HTTPException(
        status_code=501,
        detail={
            "error": "Thread history not yet implemented",
            "error_code": "NOT_IMPLEMENTED",
            "thread_id": thread_id,
        },
    )


@router.delete(
    "/threads/{thread_id}",
    summary="Delete thread and history",
    description="Delete thread checkpoint data and Redis status",
    tags=["Threads"],
)
async def delete_thread(thread_id: str) -> dict:
    """
    Delete thread checkpoint data and Redis status.

    This removes:
    - PostgreSQL checkpoint data
    - Redis status tracking
    - Redis session cache

    Args:
        thread_id: Thread ID to delete

    Returns:
        Confirmation message
    """
    logger.info("thread_delete_request", thread_id=thread_id)

    # TODO: Implement checkpoint deletion
    # For now, return mock response
    raise HTTPException(
        status_code=501,
        detail={
            "error": "Thread deletion not yet implemented",
            "error_code": "NOT_IMPLEMENTED",
            "thread_id": thread_id,
        },
    )
```

### Step 4: Register Status Routes

Update `/opt/hx-lang-server/app/main.py`:

```python
from app.api.routes import agent, status

app.include_router(
    status.router,
    prefix="/api",
    tags=["status"],
)
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Status models | `/opt/hx-lang-server/app/api/models/status.py` | Status response models |
| Status routes | `/opt/hx-lang-server/app/api/routes/status.py` | Polling endpoints |
| Updated agent service | `/opt/hx-lang-server/app/services/agent_service.py` | Status tracking |

---

## Verification Steps

### Step 1: Test Status Polling Flow

```bash
# Step 1: Initiate async operation (with mock callback)
THREAD_ID=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Long running task", "callback_url": "http://example.com/webhook"}' \
  | jq -r '.thread_id')

echo "Thread ID: $THREAD_ID"

# Step 2: Poll status immediately
curl -s http://hx-lang-server.hx.dev.local:8100/status/$THREAD_ID | jq

# Expected: status = "pending" or "processing"

# Step 3: Poll after operation completes
sleep 5
curl -s http://hx-lang-server.hx.dev.local:8100/status/$THREAD_ID | jq

# Expected: status = "completed" with result populated
```

### Step 2: Test Status Not Found

```bash
# Poll with non-existent thread_id
curl -s http://hx-lang-server.hx.dev.local:8100/status/00000000-0000-0000-0000-000000000000 | jq

# Expected: 404 with error_code = "THREAD_NOT_FOUND"
```

### Step 3: Verify Status TTL

```bash
# Create operation
THREAD_ID=$(curl -s -X POST http://hx-lang-server.hx.dev.local:8100/invoke \
  -H "Content-Type: application/json" \
  -d '{"query": "Test query"}' | jq -r '.thread_id')

# Wait for TTL expiration (10 minutes for active, 1 hour for completed)
# Check Redis key exists
redis-cli -h hx-redis-server.hx.dev.local GET "hx-lang-server:status:$THREAD_ID"

# Expected: Key exists with JSON status data
```

### Step 4: Test OpenAPI Documentation

```bash
# Open browser to OpenAPI docs
open http://hx-lang-server.hx.dev.local:8100/docs

# Verify:
# - /status/{thread_id} endpoint documented
# - Request/response schemas visible
# - Try it out button works
```

---

## Acceptance Criteria

- [ ] `/status/{thread_id}` endpoint responds with StatusResponse
- [ ] Status values: PENDING, PROCESSING, COMPLETED, FAILED, TIMEOUT
- [ ] Progress percentage updates during processing (0-100)
- [ ] Result populated when status = COMPLETED
- [ ] Error message populated when status = FAILED
- [ ] 404 error for non-existent or expired thread_id
- [ ] Redis TTL: 10 minutes for active, 1 hour for completed/failed
- [ ] Status updates at key points: pending → processing → completed
- [ ] OpenAPI documentation includes status polling endpoint

---

## Rollback Procedure

If issues occur:

```bash
cd /opt/hx-lang-server
git checkout app/api/models/status.py
git checkout app/api/routes/status.py
git checkout app/services/agent_service.py
sudo systemctl restart hx-lang-server
```

---

## Notes

- **Polling Pattern:** n8n Loop node polls /status/{thread_id} every 5 seconds until completed
- **TTL Strategy:** Short TTL for active operations to prevent stale data, longer for results
- **Progress Updates:** Optional progress_percent helps n8n display progress bars
- **Thread History:** Endpoint stub created, to be implemented with checkpoint retrieval

---

**Created By:** Isabella (n8n Workflow Automation SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, API Specification (FR-028)
