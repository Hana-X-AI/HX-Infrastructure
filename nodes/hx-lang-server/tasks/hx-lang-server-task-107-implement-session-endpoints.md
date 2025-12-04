# Task: Implement Session Management Endpoints

**Task ID**: hx-lang-server-task-107-implement-session-endpoints
**Phase**: Implementation
**Status**: Not Started
**Dependencies**: hx-lang-server-task-104 (Pydantic models), hx-lang-server-task-041-050 (Redis integration)
**Estimated Time**: 75 minutes
**Assigned Agent**: bob-parker (FastAPI SME)

---

## Objective

Implement session management CRUD endpoints for creating, retrieving, and deleting sessions. Sessions group related conversation threads and provide session-scoped state management via Redis. The implementation supports session TTL, metadata storage, and integration with the n8n workflow automation patterns.

---

## Pre-Execution Validation

**CRITICAL**: Check if endpoints are already implemented BEFORE executing steps.

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python3 -c "
from app.routers.v1.sessions import router
import inspect
# Check for actual implementations
from app.routers.v1.sessions import create_session, get_session, delete_session
for fn in [create_session, get_session, delete_session]:
    source = inspect.getsource(fn)
    if 'not_implemented' in source.lower():
        raise Exception(f'{fn.__name__} is placeholder')
print('VALIDATION: Session endpoints implemented - SKIP task execution')
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "VALIDATION: Session endpoints not implemented - PROCEED with task"
fi
```

---

## Prerequisites

- [ ] Pydantic models created (Task 104): SessionCreateRequest, SessionResponse
- [ ] Application factory implemented (Task 102)
- [ ] Redis integration completed (Task 041-050 - Work Stream 5)
- [ ] Session service stub created (Task 105)

---

## Steps

### 1. Implement Sessions Router

```bash
sudo -u hx-lang-server bash
source /opt/hx-lang-server/venv/bin/activate

cat > /opt/hx-lang-server/app/routers/v1/sessions.py <<'EOF'
"""
Session management endpoints (CRUD for sessions).

Sessions group related conversation threads and provide
session-scoped state management via Redis.

Specification Reference:
- State Management section
- Redis Key Schema section
"""
import uuid
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
import structlog

from app.models import (
    SessionCreateRequest,
    SessionResponse,
    SessionListResponse,
    ErrorResponse,
)
from app.core.config import Settings, get_settings
from app.core.dependencies import get_session_manager, get_request_id
from app.services.session import SessionManager


logger = structlog.get_logger()

router = APIRouter()


@router.post(
    "/sessions",
    response_model=SessionResponse,
    status_code=201,
    responses={
        400: {"model": ErrorResponse, "description": "Invalid request"},
        500: {"model": ErrorResponse, "description": "Internal server error"},
    },
    summary="Create a new session",
    description="""
    Create a new session for grouping conversation threads.

    Sessions provide:
    - Grouping of related threads
    - Session-scoped metadata storage
    - Configurable TTL (time-to-live)

    Sessions are stored in Redis with automatic expiration.
    """,
)
async def create_session(
    request: SessionCreateRequest = None,
    settings: Settings = Depends(get_settings),
    session_manager: SessionManager = Depends(get_session_manager),
    request_id: str = Depends(get_request_id),
) -> SessionResponse:
    """
    Create a new session.

    Args:
        request: Optional session creation parameters
        settings: Application settings
        session_manager: Redis session manager
        request_id: Request ID for tracing

    Returns:
        Created session details
    """
    # Handle empty request body
    if request is None:
        request = SessionCreateRequest()

    session_id = f"session_{uuid.uuid4().hex[:12]}"
    now = datetime.utcnow()

    # Determine TTL
    ttl_seconds = request.ttl_seconds or settings.session_ttl_seconds
    expires_at = now + timedelta(seconds=ttl_seconds)

    logger.info(
        "session_create",
        request_id=request_id,
        session_id=session_id,
        user_id=request.user_id,
        ttl_seconds=ttl_seconds,
    )

    try:
        # Create session in Redis
        session_data = {
            "session_id": session_id,
            "user_id": request.user_id,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
            "expires_at": expires_at.isoformat(),
            "thread_count": 0,
            "metadata": request.metadata or {},
        }

        await session_manager.create_session(
            session_id=session_id,
            data=session_data,
            ttl_seconds=ttl_seconds,
        )

        return SessionResponse(
            session_id=session_id,
            user_id=request.user_id,
            created_at=now,
            updated_at=now,
            expires_at=expires_at,
            thread_count=0,
            metadata=request.metadata or {},
        )

    except Exception as e:
        logger.exception(
            "session_create_error",
            request_id=request_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=500,
            detail=ErrorResponse(
                error="Failed to create session",
                error_code="INTERNAL_ERROR",
                detail=str(e),
                request_id=request_id,
            ).model_dump(),
        )


@router.get(
    "/sessions/{session_id}",
    response_model=SessionResponse,
    responses={
        404: {"model": ErrorResponse, "description": "Session not found"},
        500: {"model": ErrorResponse, "description": "Internal server error"},
    },
    summary="Get session details",
    description="Retrieve details of an existing session including metadata and thread count.",
)
async def get_session(
    session_id: str,
    settings: Settings = Depends(get_settings),
    session_manager: SessionManager = Depends(get_session_manager),
    request_id: str = Depends(get_request_id),
) -> SessionResponse:
    """
    Get session by ID.

    Args:
        session_id: Session identifier
        settings: Application settings
        session_manager: Redis session manager
        request_id: Request ID for tracing

    Returns:
        Session details

    Raises:
        HTTPException: If session not found (404)
    """
    logger.info(
        "session_get",
        request_id=request_id,
        session_id=session_id,
    )

    try:
        session_data = await session_manager.get_session(session_id)

        if session_data is None:
            raise HTTPException(
                status_code=404,
                detail=ErrorResponse(
                    error="Session not found",
                    error_code="NOT_FOUND",
                    detail=f"Session {session_id} does not exist or has expired",
                    request_id=request_id,
                ).model_dump(),
            )

        # Extend session TTL on access (optional behavior)
        await session_manager.touch_session(session_id)

        return SessionResponse(
            session_id=session_data["session_id"],
            user_id=session_data.get("user_id"),
            created_at=datetime.fromisoformat(session_data["created_at"]),
            updated_at=datetime.fromisoformat(session_data["updated_at"]),
            expires_at=datetime.fromisoformat(session_data["expires_at"]),
            thread_count=session_data.get("thread_count", 0),
            metadata=session_data.get("metadata", {}),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(
            "session_get_error",
            request_id=request_id,
            session_id=session_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=500,
            detail=ErrorResponse(
                error="Failed to retrieve session",
                error_code="INTERNAL_ERROR",
                detail=str(e),
                request_id=request_id,
            ).model_dump(),
        )


@router.delete(
    "/sessions/{session_id}",
    status_code=204,
    responses={
        404: {"model": ErrorResponse, "description": "Session not found"},
        500: {"model": ErrorResponse, "description": "Internal server error"},
    },
    summary="Delete a session",
    description="Delete a session and optionally its associated threads.",
)
async def delete_session(
    session_id: str,
    delete_threads: bool = Query(
        default=False,
        description="Also delete all threads in this session",
    ),
    settings: Settings = Depends(get_settings),
    session_manager: SessionManager = Depends(get_session_manager),
    request_id: str = Depends(get_request_id),
):
    """
    Delete a session.

    Args:
        session_id: Session identifier
        delete_threads: Whether to delete associated threads
        settings: Application settings
        session_manager: Redis session manager
        request_id: Request ID for tracing

    Returns:
        204 No Content on success

    Raises:
        HTTPException: If session not found (404)
    """
    logger.info(
        "session_delete",
        request_id=request_id,
        session_id=session_id,
        delete_threads=delete_threads,
    )

    try:
        # Check if session exists
        session_data = await session_manager.get_session(session_id)
        if session_data is None:
            raise HTTPException(
                status_code=404,
                detail=ErrorResponse(
                    error="Session not found",
                    error_code="NOT_FOUND",
                    detail=f"Session {session_id} does not exist or has expired",
                    request_id=request_id,
                ).model_dump(),
            )

        # Delete associated threads if requested
        if delete_threads:
            await session_manager.delete_session_threads(session_id)

        # Delete session
        await session_manager.delete_session(session_id)

        logger.info(
            "session_deleted",
            request_id=request_id,
            session_id=session_id,
        )

        # Return 204 No Content (no response body)
        return None

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(
            "session_delete_error",
            request_id=request_id,
            session_id=session_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=500,
            detail=ErrorResponse(
                error="Failed to delete session",
                error_code="INTERNAL_ERROR",
                detail=str(e),
                request_id=request_id,
            ).model_dump(),
        )


@router.get(
    "/sessions",
    response_model=SessionListResponse,
    responses={
        500: {"model": ErrorResponse, "description": "Internal server error"},
    },
    summary="List sessions",
    description="List active sessions, optionally filtered by user_id.",
)
async def list_sessions(
    user_id: Optional[str] = Query(
        default=None,
        description="Filter sessions by user ID",
    ),
    limit: int = Query(
        default=50,
        ge=1,
        le=100,
        description="Maximum number of sessions to return",
    ),
    offset: int = Query(
        default=0,
        ge=0,
        description="Number of sessions to skip",
    ),
    settings: Settings = Depends(get_settings),
    session_manager: SessionManager = Depends(get_session_manager),
    request_id: str = Depends(get_request_id),
) -> SessionListResponse:
    """
    List active sessions.

    Args:
        user_id: Optional user ID filter
        limit: Maximum results
        offset: Pagination offset
        settings: Application settings
        session_manager: Redis session manager
        request_id: Request ID for tracing

    Returns:
        List of sessions with pagination info
    """
    logger.info(
        "session_list",
        request_id=request_id,
        user_id=user_id,
        limit=limit,
        offset=offset,
    )

    try:
        sessions, total = await session_manager.list_sessions(
            user_id=user_id,
            limit=limit,
            offset=offset,
        )

        session_responses = [
            SessionResponse(
                session_id=s["session_id"],
                user_id=s.get("user_id"),
                created_at=datetime.fromisoformat(s["created_at"]),
                updated_at=datetime.fromisoformat(s["updated_at"]),
                expires_at=datetime.fromisoformat(s["expires_at"]),
                thread_count=s.get("thread_count", 0),
                metadata=s.get("metadata", {}),
            )
            for s in sessions
        ]

        return SessionListResponse(
            sessions=session_responses,
            total=total,
        )

    except Exception as e:
        logger.exception(
            "session_list_error",
            request_id=request_id,
            error=str(e),
        )
        raise HTTPException(
            status_code=500,
            detail=ErrorResponse(
                error="Failed to list sessions",
                error_code="INTERNAL_ERROR",
                detail=str(e),
                request_id=request_id,
            ).model_dump(),
        )
EOF
```

### 2. Update Session Service

```bash
cat > /opt/hx-lang-server/app/services/session.py <<'EOF'
"""
Session management service.

This module manages ephemeral session state in Redis.
Full implementation in Work Stream 5 (Sri).

Specification Reference: Redis Integration section
"""
import json
from datetime import datetime
from typing import Dict, List, Optional, Tuple

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
        # In-memory storage for stub (Redis in production)
        self._sessions: Dict[str, dict] = {}

    def _key(self, suffix: str) -> str:
        """Generate namespaced key."""
        return f"{self.key_prefix}:{suffix}"

    async def create_session(
        self,
        session_id: str,
        data: dict,
        ttl_seconds: int = None,
    ) -> None:
        """
        Create a new session.

        TODO: Implement with Redis (Task 041-050)
        """
        # Stub: store in memory
        self._sessions[session_id] = data

    async def get_session(self, session_id: str) -> Optional[dict]:
        """
        Retrieve session data.

        TODO: Implement with Redis (Task 041-050)
        """
        return self._sessions.get(session_id)

    async def touch_session(self, session_id: str) -> None:
        """
        Update session last access time and extend TTL.

        TODO: Implement with Redis (Task 041-050)
        """
        if session_id in self._sessions:
            self._sessions[session_id]["updated_at"] = datetime.utcnow().isoformat()

    async def delete_session(self, session_id: str) -> bool:
        """
        Delete a session.

        TODO: Implement with Redis (Task 041-050)
        """
        if session_id in self._sessions:
            del self._sessions[session_id]
            return True
        return False

    async def delete_session_threads(self, session_id: str) -> int:
        """
        Delete all threads associated with a session.

        TODO: Implement with Redis (Task 041-050)
        """
        return 0  # Stub

    async def list_sessions(
        self,
        user_id: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Tuple[List[dict], int]:
        """
        List sessions with optional filtering.

        TODO: Implement with Redis (Task 041-050)
        """
        sessions = list(self._sessions.values())

        # Filter by user_id if provided
        if user_id:
            sessions = [s for s in sessions if s.get("user_id") == user_id]

        total = len(sessions)

        # Apply pagination
        sessions = sessions[offset:offset + limit]

        return sessions, total


_session_manager: SessionManager = None


async def get_session_manager(settings: Settings) -> SessionManager:
    """
    Get session manager instance.

    Factory function for dependency injection.
    """
    global _session_manager
    if _session_manager is None:
        _session_manager = SessionManager(settings)
    return _session_manager
EOF
```

### 3. Test Session Endpoints

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Test router imports
python3 -c "
from app.routers.v1.sessions import router, create_session, get_session, delete_session, list_sessions
print(f'Router created with {len(router.routes)} routes')
for route in router.routes:
    if hasattr(route, 'path'):
        print(f'  {route.path} - {route.methods}')
"

# Test session manager
python3 -c "
import asyncio
from app.services.session import get_session_manager
from app.core.config import get_settings

async def test():
    settings = get_settings()
    sm = await get_session_manager(settings)

    # Create session
    await sm.create_session('test_session', {'session_id': 'test_session', 'created_at': '2025-01-01T00:00:00'})
    print('Created session')

    # Get session
    session = await sm.get_session('test_session')
    assert session is not None
    print(f'Retrieved session: {session.get(\"session_id\")}')

    # List sessions
    sessions, total = await sm.list_sessions()
    print(f'Listed {len(sessions)} sessions (total: {total})')

    # Delete session
    await sm.delete_session('test_session')
    session = await sm.get_session('test_session')
    assert session is None
    print('Deleted session')

asyncio.run(test())
"
```

### 4. Document Implementation

```bash
cat > /opt/hx-lang-server/installation-records/sessions-endpoint-implementation.txt <<EOF
Session Endpoints Implementation Record
=======================================
Date: $(date -Iseconds)
Task: hx-lang-server-task-107-implement-session-endpoints

Files Created/Modified:
- /opt/hx-lang-server/app/routers/v1/sessions.py
- /opt/hx-lang-server/app/services/session.py (updated)

Endpoints:
- POST /api/v1/sessions - Create session
- GET /api/v1/sessions - List sessions
- GET /api/v1/sessions/{session_id} - Get session
- DELETE /api/v1/sessions/{session_id} - Delete session

Features:
- Session creation with optional metadata
- Configurable TTL
- User ID filtering
- Pagination support
- Thread cleanup option on delete

Verification: PASSED
EOF

chmod 644 /opt/hx-lang-server/installation-records/sessions-endpoint-implementation.txt
```

---

## Verification

**Success Criteria**:

- [ ] Router file is syntactically correct:
  ```bash
  python3 -m py_compile /opt/hx-lang-server/app/routers/v1/sessions.py
  ```

- [ ] All CRUD operations importable:
  ```bash
  python3 -c "from app.routers.v1.sessions import create_session, get_session, delete_session, list_sessions; print('PASS')"
  ```

- [ ] Endpoints registered in app:
  ```bash
  python3 -c "
  from app.main import app
  paths = [r.path for r in app.routes if hasattr(r, 'path')]
  assert '/api/v1/sessions' in paths
  assert '/api/v1/sessions/{session_id}' in paths
  print('PASS: Endpoints registered')
  "
  ```

- [ ] Session manager CRUD operations work:
  ```bash
  python3 -c "
  import asyncio
  from app.services.session import SessionManager
  from app.core.config import get_settings
  sm = SessionManager(get_settings())
  asyncio.run(sm.create_session('t1', {'session_id': 't1', 'created_at': '2025-01-01'}))
  assert asyncio.run(sm.get_session('t1')) is not None
  print('PASS: Session manager works')
  "
  ```

---

## Rollback

```bash
# Restore placeholder
cat > /opt/hx-lang-server/app/routers/v1/sessions.py <<'EOF'
"""Placeholder - See task-107."""
from fastapi import APIRouter
router = APIRouter()

@router.post("/sessions")
async def create_session():
    return {"status": "not_implemented"}

@router.get("/sessions/{session_id}")
async def get_session(session_id: str):
    return {"status": "not_implemented", "session_id": session_id}

@router.delete("/sessions/{session_id}")
async def delete_session(session_id: str):
    return {"status": "not_implemented"}
EOF
```

---

## Notes

### Session Lifecycle

1. **Creation**: POST /sessions creates session with unique ID
2. **Access**: GET operations extend TTL (touch)
3. **Expiration**: Automatic cleanup after TTL (Redis)
4. **Deletion**: Manual cleanup with optional thread deletion

### Redis Key Structure

Per specification, session keys use namespace prefix:
- `hx-lang-server:session:{session_id}` - Session data
- `hx-lang-server:session:{session_id}:threads` - Thread list

### n8n Integration

Sessions enable n8n workflows to:
- Group related conversations
- Track workflow state across invocations
- Clean up after workflow completion

---

## Related Tasks

**Prerequisites**:
- Task 104: Pydantic models
- Task 105: Invoke endpoint (session service stub)

**Dependencies (Other Work Streams)**:
- Task 041-050: Redis integration (Work Stream 5 - Sri)

**Next Tasks**:
- Task 108: Health endpoint
- Task 109: Ready endpoint

---

**Specification Reference**: `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`
- Section: State Management (FR-006, FR-007)
- Section: Redis Key Schema

**Task Template Version**: 1.0
**Created**: 2025-12-04
**Agent**: bob-parker (FastAPI SME)
