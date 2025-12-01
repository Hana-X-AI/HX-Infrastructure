# Task: Redis Session Management Integration

**Task ID**: hx-docling-mcp-task-032
**Category**: MCP Tools - State Management
**Owner**: james-rodriguez
**Dependencies**: hx-docling-mcp-task-026 (LiteLLM Integration), hx-docling-mcp-task-028 (Redis Configuration)
**Parallel Execution**: No (requires Redis configured and LiteLLM integration)

## Objective

Integrate Redis-backed session management for MCP tools to support multi-step document processing workflows, state persistence, and LLM response caching.

## Prerequisites

- Redis client configured and operational (Task 028 complete)
- LiteLLM integration complete (Task 026 complete) for LLM response caching
- All MCP tools registered (Tasks 009-012 complete)
- Document processing pipeline integrated (Task 031 complete)

## Steps

### 1. Create Session Management Module

```bash
# Create session manager implementation
cat > /opt/docling-mcp/application/docling_mcp/session/manager.py <<'EOF'
"""
Redis-Based Session Management for MCP Tools.

Supports multi-step document processing workflows:
- Session creation and lifecycle
- Document association with sessions
- Processing state tracking
- Configurable TTL with sliding window extension
- Graceful degradation if Redis unavailable
"""

import logging
import uuid
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import redis.asyncio as redis

logger = logging.getLogger(__name__)

class SessionManager:
    """Manage MCP tool sessions with Redis backend."""

    def __init__(self, redis_client: Optional[redis.Redis] = None):
        """
        Initialize session manager.

        Args:
            redis_client: Redis client (None for in-memory fallback)
        """
        self.redis = redis_client
        self.in_memory_sessions: Dict[str, Dict] = {}  # Fallback if Redis unavailable
        self.default_ttl_hours = 24
        self.max_ttl_hours = 168  # 7 days hard limit
        self.extension_hours = 4  # Sliding window extension

        if redis_client is None:
            logger.warning("SessionManager initialized without Redis - using in-memory fallback (non-persistent)")
        else:
            logger.info("SessionManager initialized with Redis backend")

    async def create_session(
        self,
        user: str = "anonymous",
        ttl_hours: Optional[int] = None
    ) -> str:
        """
        Create new session with unique ID.

        Args:
            user: User identifier
            ttl_hours: Session TTL in hours (default: 24, max: 168)

        Returns:
            Session ID (UUID v4)
        """
        session_id = str(uuid.uuid4())
        ttl_hours = min(ttl_hours or self.default_ttl_hours, self.max_ttl_hours)

        session_metadata = {
            "user": user,
            "created_at": datetime.now().isoformat(),
            "last_accessed": datetime.now().isoformat(),
            "ttl_hours": ttl_hours,
            "workflow_state": "initialized"
        }

        if self.redis:
            # Store in Redis
            session_key = f"session:{session_id}"
            await self.redis.hset(session_key, mapping=session_metadata)
            await self.redis.expire(session_key, ttl_hours * 3600)
            await self.redis.sadd("sessions:active", session_id)
            logger.info(f"Session created in Redis: {session_id} (TTL: {ttl_hours}h)")
        else:
            # Fallback to in-memory
            self.in_memory_sessions[session_id] = session_metadata
            logger.warning(f"Session created in-memory (non-persistent): {session_id}")

        return session_id

    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve session metadata.

        Args:
            session_id: Session ID

        Returns:
            Session metadata dict or None if not found
        """
        if self.redis:
            session_key = f"session:{session_id}"
            metadata = await self.redis.hgetall(session_key)

            if not metadata:
                logger.debug(f"Session not found: {session_id}")
                return None

            # Extend TTL (sliding window)
            await self._extend_ttl(session_id)

            # Update last_accessed
            await self.redis.hset(session_key, "last_accessed", datetime.now().isoformat())

            return metadata
        else:
            # Fallback to in-memory
            session = self.in_memory_sessions.get(session_id)
            if session:
                session["last_accessed"] = datetime.now().isoformat()
            return session

    async def add_document_to_session(self, session_id: str, document_id: str):
        """
        Associate document with session.

        Args:
            session_id: Session ID
            document_id: Document ID (from convert_document)
        """
        if self.redis:
            doc_set_key = f"session:{session_id}:documents"
            await self.redis.sadd(doc_set_key, document_id)

            # Initialize document status
            status_key = f"session:{session_id}:status"
            await self.redis.hset(status_key, document_id, "pending")

            logger.debug(f"Document added to session: {document_id} → {session_id}")
        else:
            # Fallback to in-memory
            session = self.in_memory_sessions.get(session_id)
            if session:
                if "documents" not in session:
                    session["documents"] = []
                if "status" not in session:
                    session["status"] = {}

                if document_id not in session["documents"]:
                    session["documents"].append(document_id)
                session["status"][document_id] = "pending"

    async def update_document_status(
        self,
        session_id: str,
        document_id: str,
        status: str
    ):
        """
        Update document processing status.

        Args:
            session_id: Session ID
            document_id: Document ID
            status: New status (pending, processing, completed, failed)
        """
        if self.redis:
            status_key = f"session:{session_id}:status"
            await self.redis.hset(status_key, document_id, status)
            logger.debug(f"Document status updated: {document_id} → {status}")
        else:
            # Fallback to in-memory
            session = self.in_memory_sessions.get(session_id)
            if session and "status" in session:
                session["status"][document_id] = status

    async def get_session_documents(self, session_id: str) -> List[str]:
        """
        Get all documents associated with session.

        Args:
            session_id: Session ID

        Returns:
            List of document IDs
        """
        if self.redis:
            doc_set_key = f"session:{session_id}:documents"
            documents = await self.redis.smembers(doc_set_key)
            return list(documents)
        else:
            # Fallback to in-memory
            session = self.in_memory_sessions.get(session_id)
            return session.get("documents", []) if session else []

    async def delete_session(self, session_id: str):
        """
        Delete session and all associated data.

        Args:
            session_id: Session ID
        """
        if self.redis:
            # Use MULTI/EXEC for atomic cleanup
            async with self.redis.pipeline() as pipe:
                pipe.srem("sessions:active", session_id)
                pipe.delete(f"session:{session_id}")
                pipe.delete(f"session:{session_id}:documents")
                pipe.delete(f"session:{session_id}:status")
                await pipe.execute()

            logger.info(f"Session deleted: {session_id}")
        else:
            # Fallback to in-memory
            if session_id in self.in_memory_sessions:
                del self.in_memory_sessions[session_id]

    async def list_active_sessions(self) -> List[str]:
        """
        List all active session IDs.

        Returns:
            List of session IDs
        """
        if self.redis:
            sessions = await self.redis.smembers("sessions:active")
            return list(sessions)
        else:
            return list(self.in_memory_sessions.keys())

    async def _extend_ttl(self, session_id: str):
        """
        Extend session TTL using sliding window strategy.

        Args:
            session_id: Session ID
        """
        if not self.redis:
            return

        session_key = f"session:{session_id}"

        # Get current TTL and created_at
        ttl_seconds = await self.redis.ttl(session_key)
        metadata = await self.redis.hgetall(session_key)

        if not metadata:
            return

        created_at = datetime.fromisoformat(metadata.get("created_at"))
        max_lifetime = timedelta(hours=self.max_ttl_hours)

        # Check if session exceeded max lifetime
        if datetime.now() - created_at > max_lifetime:
            logger.warning(f"Session {session_id} exceeded max lifetime ({self.max_ttl_hours}h), not extending TTL")
            return

        # Extend TTL by extension_hours
        new_ttl_seconds = ttl_seconds + (self.extension_hours * 3600)
        await self.redis.expire(session_key, new_ttl_seconds)
        logger.debug(f"Extended session TTL: {session_id} (+{self.extension_hours}h)")

# Global session manager instance
_session_manager: Optional[SessionManager] = None

def get_session_manager() -> SessionManager:
    """Get global SessionManager instance."""
    if _session_manager is None:
        raise RuntimeError("SessionManager not initialized. Call initialize_session_manager() first.")
    return _session_manager

def initialize_session_manager(redis_client: Optional[redis.Redis]):
    """Initialize global SessionManager instance."""
    global _session_manager
    _session_manager = SessionManager(redis_client)
    logger.info("Global SessionManager initialized")

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/session/manager.py
chmod 644 /opt/docling-mcp/application/docling_mcp/session/manager.py
```

### 2. Create Session MCP Tools

```bash
# Create MCP tools for session management
cat > /opt/docling-mcp/application/docling_mcp/tools/session_tools.py <<'EOF'
"""
MCP Tools for Session Management.

Provides 4 session-related tools:
- create_session
- get_session_status
- add_document_to_session
- delete_session
"""

import logging
from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

from fastmcp import FastMCP
from ..session.manager import get_session_manager

logger = logging.getLogger(__name__)

# ============================================================================
# Pydantic Models
# ============================================================================

class CreateSessionInput(BaseModel):
    """Input schema for create_session tool."""
    user: str = Field(
        default="anonymous",
        max_length=100,
        description="User identifier for session tracking"
    )
    ttl_hours: Optional[int] = Field(
        default=24,
        ge=1,
        le=168,
        description="Session TTL in hours (default: 24, max: 168)"
    )

class SessionOutput(BaseModel):
    """Output schema for session creation."""
    session_id: str = Field(..., description="Unique session ID (UUID v4)")
    created_at: str = Field(..., description="Session creation timestamp (ISO8601)")
    ttl_hours: int = Field(..., description="Session TTL in hours")

class GetSessionStatusInput(BaseModel):
    """Input schema for get_session_status tool."""
    session_id: str = Field(..., description="Session ID to query")

class SessionStatusOutput(BaseModel):
    """Output schema for session status."""
    session_id: str = Field(..., description="Session ID")
    user: str = Field(..., description="User identifier")
    created_at: str = Field(..., description="Creation timestamp")
    last_accessed: str = Field(..., description="Last access timestamp")
    workflow_state: str = Field(..., description="Current workflow state")
    documents: List[str] = Field(..., description="Associated document IDs")
    document_status: Dict[str, str] = Field(..., description="Per-document processing status")

# ============================================================================
# Tool Implementations
# ============================================================================

def register_session_tools(mcp: FastMCP):
    """Register session management tools."""
    logger.info("Registering session management tools...")

    @mcp.tool(
        name="create_session",
        description="Create new session for multi-step document processing workflows with configurable TTL."
    )
    async def create_session(input: CreateSessionInput) -> SessionOutput:
        """Create new session."""
        session_manager = get_session_manager()
        session_id = await session_manager.create_session(
            user=input.user,
            ttl_hours=input.ttl_hours
        )

        return SessionOutput(
            session_id=session_id,
            created_at=datetime.now().isoformat(),
            ttl_hours=input.ttl_hours or 24
        )

    @mcp.tool(
        name="get_session_status",
        description="Get session status including associated documents and processing state."
    )
    async def get_session_status(input: GetSessionStatusInput) -> SessionStatusOutput:
        """Get session status."""
        session_manager = get_session_manager()
        session = await session_manager.get_session(input.session_id)

        if not session:
            raise ValueError(f"Session not found: {input.session_id}")

        documents = await session_manager.get_session_documents(input.session_id)

        # Fetch per-document statuses from session manager
        document_status = {}
        try:
            # Iterate through documents and fetch individual statuses
            for doc_id in documents:
                status = await session_manager.get_document_status(doc_id)
                if status:
                    document_status[doc_id] = status
        except Exception as e:
            logger.warning(f"Failed to retrieve document statuses: {e}")
            document_status = {}

        return SessionStatusOutput(
            session_id=input.session_id,
            user=session.get("user", "unknown"),
            created_at=session.get("created_at", ""),
            last_accessed=session.get("last_accessed", ""),
            workflow_state=session.get("workflow_state", "unknown"),
            documents=documents,
            document_status=document_status
        )

    logger.info("Session management tools registered")

EOF

# Set ownership and permissions
chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/docling_mcp/tools/session_tools.py
chmod 644 /opt/docling-mcp/application/docling_mcp/tools/session_tools.py
```

### 3. Integrate Session Management with Server

```bash
# Update server.py to initialize session manager
cat >> /opt/docling-mcp/application/docling_mcp/server.py <<'EOF'

# Import session management
from .session.manager import initialize_session_manager
from .integrations.redis_client import get_redis_client

def initialize_session_management():
    """Initialize session management with Redis backend."""
    logger.info("Initializing session management...")

    redis_client = get_redis_client()  # From Task 028
    initialize_session_manager(redis_client)

    logger.info("✓ Session management initialized")

# Import and register session tools
from .tools.session_tools import register_session_tools

# Initialize session management BEFORE server startup
initialize_session_management()

# Register session tools
register_session_tools(mcp)
logger.info("Session management tools registered with MCP server")

EOF
```

### 4. Create Session Management Tests

```bash
# Create session management tests
cat > /opt/docling-mcp/application/tests/test_session_management.py <<'EOF'
"""
Test Redis-based session management.
"""

import pytest
from docling_mcp.session.manager import SessionManager
from docling_mcp.server import mcp

@pytest.mark.asyncio
async def test_create_session():
    """Test session creation."""
    result = await mcp.call_tool("create_session", {"user": "test_user", "ttl_hours": 24})

    assert "session_id" in result
    assert result["ttl_hours"] == 24

@pytest.mark.asyncio
async def test_session_document_association():
    """Test adding documents to session."""
    from docling_mcp.session.manager import get_session_manager

    manager = get_session_manager()
    session_id = await manager.create_session("test_user")

    # Add document to session
    await manager.add_document_to_session(session_id, "doc_123")

    # Verify document associated
    documents = await manager.get_session_documents(session_id)
    assert "doc_123" in documents

@pytest.mark.asyncio
async def test_session_graceful_degradation():
    """Test session manager works without Redis."""
    manager = SessionManager(redis_client=None)  # No Redis

    session_id = await manager.create_session("test_user")
    session = await manager.get_session(session_id)

    assert session is not None
    assert session["user"] == "test_user"

EOF

chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/application/tests/test_session_management.py
chmod 644 /opt/docling-mcp/application/tests/test_session_management.py
```

## Deliverables

- Session manager: `/opt/docling-mcp/application/docling_mcp/session/manager.py`
- Session MCP tools: `/opt/docling-mcp/application/docling_mcp/tools/session_tools.py`
- Server session initialization (added to server.py)
- Session management tests: `/opt/docling-mcp/application/tests/test_session_management.py`

## Verification

### Success Criteria

```bash
cd /opt/docling-mcp/application

# 1. Session manager imports
python -c "from docling_mcp.session.manager import SessionManager, get_session_manager" && echo "PASS: Session manager imports"

# 2. Initialize session manager
python <<'PYEOF'
from docling_mcp.server import initialize_session_management
initialize_session_management()
print("PASS: Session management initialized")
PYEOF

# 3. Run session management tests
pytest tests/test_session_management.py -v

# Expected: All session tests pass

# 4. Test create_session tool
python -c "
import asyncio
from docling_mcp.server import mcp
result = asyncio.run(mcp.call_tool('create_session', {'user': 'test_user'}))
assert 'session_id' in result
print('PASS: create_session tool works')
"

# 5. Test graceful degradation (without Redis)
python -c "
import asyncio
from docling_mcp.session.manager import SessionManager

async def test():
    manager = SessionManager(redis_client=None)
    session_id = await manager.create_session('test_user')
    assert session_id
    print('PASS: Graceful degradation works without Redis')

asyncio.run(test())
"
```

### Expected Output

All verification checks should output "PASS".

## Rollback

If session management integration fails:

```bash
# 1. Remove session manager
rm -f /opt/docling-mcp/application/docling_mcp/session/manager.py
rm -f /opt/docling-mcp/application/docling_mcp/tools/session_tools.py

# 2. Remove session initialization from server.py

# 3. Document failure reason
echo "Session management integration failed on $(date): <reason>" >> /opt/docling-mcp/deployment-failures.log
```

## Notes

- **Graceful Degradation**: Service continues operating in stateless mode if Redis unavailable
- **Sliding Window TTL**: Session TTL extends on each access (configurable extension increment)
- **Maximum Lifetime**: Hard limit of 168 hours (7 days) even with sliding window extensions
- **In-Memory Fallback**: Non-persistent sessions if Redis unavailable (useful for development)

## References

- **Specification**: Section 3.2.2 "Session Management" - FR-018 through FR-020 (Session requirements)
- **Contribution Review**: `james-rodriguez-task-contribution.md` (lines 226-242: Redis session management documentation)
- **Dependencies**: Task 026 (LiteLLM Integration), Task 028 (Redis Configuration)
