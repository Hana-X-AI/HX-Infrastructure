# Task 132: Implement Session Management Functionality

**Assigned To**: sri-patel
**Estimated Effort**: 3 hours
**Dependencies**: Task 131 (Redis client module)
**Status**: Not Started

## Objective

Implement session management module (`/opt/docling-mcp/src/session_manager.py`) with Redis-backed state persistence for multi-step document processing workflows, including session creation, document tracking, status management, and TTL handling with sliding window expiration.

## Pre-Execution Validation

**CRITICAL**: Check if session manager module already exists BEFORE creating it to prevent duplication.

```bash
# Check if session manager module file exists
if [ -f "/opt/docling-mcp/src/session_manager.py" ]; then
    echo "✅ VALIDATION RESULT: Session manager module already exists"
    echo "ACTION: SKIP task execution - validate module functionality instead"
    echo "NEXT: Test session creation with: python3 -c 'from src.session_manager import SessionManager; sm = SessionManager(); session_id = sm.create_session(\"test_user\"); print(f\"Session: {session_id}\")'"
    exit 0
else
    echo "❌ VALIDATION RESULT: Session manager module does NOT exist"
    echo "ACTION: PROCEED with module creation"
fi
```

**If Module Exists**: Skip to Validation section, verify session operations work correctly

**If Module Does Not Exist**: Continue with Implementation Steps below

---

## Context

Session management enables multi-step document processing workflows where AI agents can:
1. Create session with unique ID
2. Upload multiple documents to session
3. Process documents incrementally (entities, relationships, graphs)
4. Track processing status per document
5. Retrieve session state across MCP requests
6. Automatic cleanup via TTL with sliding window extension

**Key Requirements (FR-018, FR-020):**
- Session metadata stored in Redis hash: `session:<session_id>`
- Document list stored in Redis set: `session:<session_id>:documents`
- Processing status stored in Redis hash: `session:<session_id>:status`
- Active sessions indexed in Redis set: `sessions:active`
- TTL: 24 hours (default), sliding window extension on access (+4 hours)
- Graceful degradation if Redis unavailable (disable sessions, operate stateless)

## Acceptance Criteria

- [ ] Session manager module created at `/opt/docling-mcp/src/session_manager.py`
- [ ] `create_session()` method generates UUID v4 session IDs
- [ ] Session metadata stored in Redis hash with fields: user, created_at, last_accessed, ttl_hours, workflow_state
- [ ] `add_documents()` method adds document IDs to session set
- [ ] `update_status()` method tracks document processing status (pending/processing/completed/failed)
- [ ] `get_session()` method retrieves session metadata and extends TTL (sliding window)
- [ ] `list_sessions()` method returns all active session IDs
- [ ] `delete_session()` method performs atomic cleanup (MULTI/EXEC)
- [ ] TTL configuration: default 24 hours, max 168 hours, extension +4 hours
- [ ] Graceful degradation: Returns None if Redis unavailable
- [ ] Module integrates with RedisClient from Task 131

## Implementation Steps

### Step 1: Create Session Manager Module

```bash
# SSH to hx-docling-mcp-server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create session_manager.py module
sudo -u docling-mcp@hx.dev.local bash -c 'cat > /opt/docling-mcp/src/session_manager.py << '\''EOF'\''
"""
Session Manager Module for Docling MCP Server

Provides Redis-backed session state management for multi-step document
processing workflows with TTL-based expiration and sliding window extension.

Integration: Uses RedisClient from src.integrations.redis_client
"""

import uuid
import logging
from datetime import datetime, timezone
from typing import Optional, Dict, List, Set
from dataclasses import dataclass, asdict

from src.integrations.redis_client import (
    get_redis_client,
    RedisOperationError
)

logger = logging.getLogger(__name__)


@dataclass
class SessionMetadata:
    """
    Session metadata structure.

    Fields match Redis hash `session:<session_id>` schema.
    """
    session_id: str
    user: str
    created_at: str  # ISO8601 timestamp
    last_accessed: str  # ISO8601 timestamp
    ttl_hours: int
    workflow_state: str  # initialized|processing|completed


@dataclass
class SessionState:
    """
    Complete session state including metadata, documents, and status.
    """
    metadata: SessionMetadata
    documents: Set[str]  # Set of document IDs
    status: Dict[str, str]  # document_id -> status (pending/processing/completed/failed)


class SessionManager:
    """
    Manages MCP session lifecycle with Redis-backed persistence.

    Features:
    - UUID v4 session IDs
    - Redis hash for metadata storage
    - Redis set for document tracking
    - Redis hash for processing status
    - TTL with sliding window extension
    - Atomic session cleanup (MULTI/EXEC)
    - Graceful degradation if Redis unavailable
    """

    # Redis key prefixes
    SESSION_PREFIX = "session:"
    ACTIVE_SESSIONS_SET = "sessions:active"

    # Session configuration
    DEFAULT_TTL_HOURS = 24
    MAX_TTL_HOURS = 168  # 7 days
    TTL_EXTENSION_HOURS = 4

    # Workflow states
    STATE_INITIALIZED = "initialized"
    STATE_PROCESSING = "processing"
    STATE_COMPLETED = "completed"

    # Document processing states
    STATUS_PENDING = "pending"
    STATUS_PROCESSING = "processing"
    STATUS_COMPLETED = "completed"
    STATUS_FAILED = "failed"

    def __init__(
        self,
        ttl_hours: int = DEFAULT_TTL_HOURS,
        ttl_extension_hours: int = TTL_EXTENSION_HOURS,
        max_ttl_hours: int = MAX_TTL_HOURS
    ):
        """
        Initialize session manager.

        Args:
            ttl_hours: Default session TTL in hours (default: 24)
            ttl_extension_hours: TTL extension increment for sliding window (default: 4)
            max_ttl_hours: Maximum session TTL from creation (default: 168)
        """
        self.ttl_hours = ttl_hours
        self.ttl_extension_hours = ttl_extension_hours
        self.max_ttl_hours = max_ttl_hours

        # Get Redis client singleton
        self.redis_client = get_redis_client()

        if self.redis_client is None:
            logger.warning(
                "Redis client not initialized. Session management disabled. "
                "Service will operate in stateless mode."
            )
        elif not self.redis_client.is_available():
            logger.warning(
                "Redis unavailable. Session management disabled. "
                "Service will operate in stateless mode."
            )

        logger.info(
            f"Session manager initialized: ttl={ttl_hours}h, "
            f"extension={ttl_extension_hours}h, max={max_ttl_hours}h"
        )

    def is_available(self) -> bool:
        """
        Check if session management is available (Redis connected).

        Returns:
            True if Redis available, False otherwise
        """
        if self.redis_client is None:
            return False
        return self.redis_client.is_available()

    def create_session(
        self,
        user: str = "anonymous",
        ttl_hours: Optional[int] = None
    ) -> Optional[str]:
        """
        Create new session with unique ID.

        Args:
            user: User identifier (default: "anonymous")
            ttl_hours: Session TTL in hours (default: self.ttl_hours)

        Returns:
            Session ID (UUID v4 string), or None if Redis unavailable

        Raises:
            ValueError: If ttl_hours exceeds max_ttl_hours
        """
        if not self.is_available():
            logger.warning("Cannot create session: Redis unavailable")
            return None

        # Validate TTL
        ttl = ttl_hours if ttl_hours is not None else self.ttl_hours
        if ttl > self.max_ttl_hours:
            raise ValueError(
                f"TTL {ttl}h exceeds maximum {self.max_ttl_hours}h"
            )

        # Generate UUID v4 session ID
        session_id = str(uuid.uuid4())

        # Create session metadata
        now = datetime.now(timezone.utc).isoformat()
        metadata = {
            "user": user,
            "created_at": now,
            "last_accessed": now,
            "ttl_hours": str(ttl),
            "workflow_state": self.STATE_INITIALIZED
        }

        try:
            # Store session metadata in Redis hash
            session_key = f"{self.SESSION_PREFIX}{session_id}"

            with self.redis_client.pipeline() as pipe:
                # Set metadata hash
                for field, value in metadata.items():
                    pipe.hset(session_key, field, value)

                # Set TTL on session hash
                pipe.expire(session_key, ttl * 3600)  # Convert hours to seconds

                # Add session to active sessions index
                pipe.sadd(self.ACTIVE_SESSIONS_SET, session_id)

                # Execute atomically
                pipe.execute()

            logger.info(
                f"Session created: {session_id}, user={user}, ttl={ttl}h"
            )
            return session_id

        except RedisOperationError as e:
            logger.error(f"Failed to create session: {str(e)}")
            return None

    def add_documents(
        self,
        session_id: str,
        document_ids: List[str]
    ) -> bool:
        """
        Add documents to session and initialize status.

        Args:
            session_id: Session ID
            document_ids: List of document IDs to add

        Returns:
            True if successful, False if Redis unavailable or session not found
        """
        if not self.is_available():
            logger.warning("Cannot add documents: Redis unavailable")
            return False

        try:
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            docs_key = f"{session_key}:documents"
            status_key = f"{session_key}:status"

            # Check session exists
            if not self.redis_client.exists(session_key):
                logger.warning(f"Session not found: {session_id}")
                return False

            with self.redis_client.pipeline() as pipe:
                # Add documents to set
                pipe.sadd(docs_key, *document_ids)

                # Initialize status for each document
                for doc_id in document_ids:
                    pipe.hset(status_key, doc_id, self.STATUS_PENDING)

                # Update last_accessed timestamp
                now = datetime.now(timezone.utc).isoformat()
                pipe.hset(session_key, "last_accessed", now)

                # Extend TTL (sliding window)
                self._extend_ttl_pipeline(pipe, session_id, session_key)

                # Execute atomically
                pipe.execute()

            logger.info(
                f"Added {len(document_ids)} documents to session {session_id}"
            )
            return True

        except RedisOperationError as e:
            logger.error(f"Failed to add documents to session {session_id}: {str(e)}")
            return False

    def update_status(
        self,
        session_id: str,
        document_id: str,
        status: str
    ) -> bool:
        """
        Update processing status for document in session.

        Args:
            session_id: Session ID
            document_id: Document ID
            status: Processing status (pending|processing|completed|failed)

        Returns:
            True if successful, False otherwise

        Raises:
            ValueError: If status is invalid
        """
        if not self.is_available():
            logger.warning("Cannot update status: Redis unavailable")
            return False

        # Validate status
        valid_statuses = {
            self.STATUS_PENDING,
            self.STATUS_PROCESSING,
            self.STATUS_COMPLETED,
            self.STATUS_FAILED
        }
        if status not in valid_statuses:
            raise ValueError(f"Invalid status '{status}'. Must be one of {valid_statuses}")

        try:
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            status_key = f"{session_key}:status"

            # Check session exists
            if not self.redis_client.exists(session_key):
                logger.warning(f"Session not found: {session_id}")
                return False

            with self.redis_client.pipeline() as pipe:
                # Update status
                pipe.hset(status_key, document_id, status)

                # Update last_accessed timestamp
                now = datetime.now(timezone.utc).isoformat()
                pipe.hset(session_key, "last_accessed", now)

                # Extend TTL (sliding window)
                self._extend_ttl_pipeline(pipe, session_id, session_key)

                # Execute atomically
                pipe.execute()

            logger.debug(
                f"Updated status for document {document_id} in session {session_id}: {status}"
            )
            return True

        except RedisOperationError as e:
            logger.error(
                f"Failed to update status for document {document_id} in session {session_id}: {str(e)}"
            )
            return False

    def get_session(self, session_id: str) -> Optional[SessionState]:
        """
        Retrieve complete session state and extend TTL (sliding window).

        Args:
            session_id: Session ID

        Returns:
            SessionState object, or None if session not found or Redis unavailable
        """
        if not self.is_available():
            logger.warning("Cannot get session: Redis unavailable")
            return None

        try:
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            docs_key = f"{session_key}:documents"
            status_key = f"{session_key}:status"

            # Check session exists
            if not self.redis_client.exists(session_key):
                logger.warning(f"Session not found: {session_id}")
                return None

            # Get session metadata
            metadata_dict = self.redis_client.hgetall(session_key)

            # Get documents
            documents = self.redis_client.smembers(docs_key)

            # Get status
            status = self.redis_client.hgetall(status_key)

            # Update last_accessed and extend TTL
            with self.redis_client.pipeline() as pipe:
                now = datetime.now(timezone.utc).isoformat()
                pipe.hset(session_key, "last_accessed", now)

                # Extend TTL (sliding window)
                self._extend_ttl_pipeline(pipe, session_id, session_key)

                # Execute atomically
                pipe.execute()

            # Build SessionMetadata
            metadata = SessionMetadata(
                session_id=session_id,
                user=metadata_dict.get("user", "unknown"),
                created_at=metadata_dict.get("created_at", ""),
                last_accessed=metadata_dict.get("last_accessed", ""),
                ttl_hours=int(metadata_dict.get("ttl_hours", self.ttl_hours)),
                workflow_state=metadata_dict.get("workflow_state", self.STATE_INITIALIZED)
            )

            # Build SessionState
            session_state = SessionState(
                metadata=metadata,
                documents=documents,
                status=status
            )

            logger.debug(f"Retrieved session state: {session_id}")
            return session_state

        except RedisOperationError as e:
            logger.error(f"Failed to get session {session_id}: {str(e)}")
            return None

    def list_sessions(self) -> List[str]:
        """
        List all active session IDs.

        Returns:
            List of session IDs, or empty list if Redis unavailable
        """
        if not self.is_available():
            logger.warning("Cannot list sessions: Redis unavailable")
            return []

        try:
            session_ids = self.redis_client.smembers(self.ACTIVE_SESSIONS_SET)
            logger.debug(f"Listed {len(session_ids)} active sessions")
            return list(session_ids)

        except RedisOperationError as e:
            logger.error(f"Failed to list sessions: {str(e)}")
            return []

    def delete_session(self, session_id: str) -> bool:
        """
        Delete session and all associated data atomically.

        Args:
            session_id: Session ID

        Returns:
            True if successful, False otherwise
        """
        if not self.is_available():
            logger.warning("Cannot delete session: Redis unavailable")
            return False

        try:
            session_key = f"{self.SESSION_PREFIX}{session_id}"
            docs_key = f"{session_key}:documents"
            status_key = f"{session_key}:status"

            with self.redis_client.pipeline() as pipe:
                # Delete session metadata hash
                pipe.delete(session_key)

                # Delete documents set
                pipe.delete(docs_key)

                # Delete status hash
                pipe.delete(status_key)

                # Remove from active sessions index
                pipe.srem(self.ACTIVE_SESSIONS_SET, session_id)

                # Execute atomically
                pipe.execute()

            logger.info(f"Deleted session: {session_id}")
            return True

        except RedisOperationError as e:
            logger.error(f"Failed to delete session {session_id}: {str(e)}")
            return False

    def _extend_ttl_pipeline(
        self,
        pipe,
        session_id: str,
        session_key: str
    ):
        """
        Extend session TTL using sliding window (internal helper for pipeline).

        Args:
            pipe: Redis pipeline object
            session_id: Session ID
            session_key: Redis key for session metadata
        """
        # Get current TTL
        metadata = self.redis_client.hgetall(session_key)
        created_at_str = metadata.get("created_at")
        ttl_hours = int(metadata.get("ttl_hours", self.ttl_hours))

        if not created_at_str:
            logger.warning(f"Session {session_id} missing created_at, cannot extend TTL")
            return

        # Calculate time since creation
        created_at = datetime.fromisoformat(created_at_str)
        now = datetime.now(timezone.utc)
        hours_since_creation = (now - created_at).total_seconds() / 3600

        # Calculate new TTL (sliding window: add extension increment)
        new_ttl_hours = ttl_hours + self.ttl_extension_hours

        # Cap at max TTL from creation
        max_allowed_ttl = self.max_ttl_hours - hours_since_creation
        if new_ttl_hours > max_allowed_ttl:
            new_ttl_hours = max(0, max_allowed_ttl)

        # Update TTL in Redis (convert to seconds)
        new_ttl_seconds = int(new_ttl_hours * 3600)
        if new_ttl_seconds > 0:
            pipe.expire(session_key, new_ttl_seconds)
            pipe.expire(f"{session_key}:documents", new_ttl_seconds)
            pipe.expire(f"{session_key}:status", new_ttl_seconds)

            logger.debug(
                f"Extended TTL for session {session_id}: {new_ttl_hours:.1f}h "
                f"(max {max_allowed_ttl:.1f}h)"
            )
        else:
            logger.warning(
                f"Session {session_id} reached max TTL ({self.max_ttl_hours}h), "
                f"no extension applied"
            )


# Singleton instance (initialized by config.py)
_session_manager: Optional[SessionManager] = None


def get_session_manager() -> Optional[SessionManager]:
    """
    Get singleton session manager instance.

    Returns:
        SessionManager instance, or None if not initialized
    """
    return _session_manager


def initialize_session_manager(
    ttl_hours: int = SessionManager.DEFAULT_TTL_HOURS,
    ttl_extension_hours: int = SessionManager.TTL_EXTENSION_HOURS,
    max_ttl_hours: int = SessionManager.MAX_TTL_HOURS
) -> SessionManager:
    """
    Initialize singleton session manager instance.

    Args:
        ttl_hours: Default session TTL in hours
        ttl_extension_hours: TTL extension increment
        max_ttl_hours: Maximum session TTL from creation

    Returns:
        Initialized SessionManager instance
    """
    global _session_manager

    _session_manager = SessionManager(
        ttl_hours=ttl_hours,
        ttl_extension_hours=ttl_extension_hours,
        max_ttl_hours=max_ttl_hours
    )

    logger.info(
        f"Session manager singleton initialized: "
        f"ttl={ttl_hours}h, extension={ttl_extension_hours}h, max={max_ttl_hours}h"
    )
    return _session_manager
EOF'

# Verify file created
ls -la /opt/docling-mcp/src/session_manager.py
```

### Step 2: Test Session Manager Import

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test module import
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.session_manager import (
    SessionManager,
    SessionMetadata,
    SessionState,
    initialize_session_manager
)

print("✅ Session manager module imported successfully")
print("✅ Classes available: SessionManager, SessionMetadata, SessionState")
EOF
```

### Step 3: Test Session Operations

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test full session lifecycle
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.session_manager import initialize_session_manager

# Initialize Redis client
redis_client = initialize_redis_client(
    host="hx-redis-server.hx.dev.local",
    port=6379
)
print("✓ Redis client initialized")

# Initialize session manager
session_manager = initialize_session_manager(
    ttl_hours=24,
    ttl_extension_hours=4,
    max_ttl_hours=168
)
print("✓ Session manager initialized")

# Test session creation
session_id = session_manager.create_session(user="test_user")
if session_id:
    print(f"✓ Session created: {session_id}")
else:
    print("✗ Session creation failed")
    exit(1)

# Test add documents
success = session_manager.add_documents(
    session_id,
    ["doc1", "doc2", "doc3"]
)
if success:
    print("✓ Documents added to session")
else:
    print("✗ Failed to add documents")
    exit(1)

# Test update status
success = session_manager.update_status(session_id, "doc1", "processing")
if success:
    print("✓ Document status updated")
else:
    print("✗ Failed to update status")
    exit(1)

# Test get session
session_state = session_manager.get_session(session_id)
if session_state:
    print(f"✓ Session retrieved: {len(session_state.documents)} documents")
    print(f"  Metadata: user={session_state.metadata.user}, state={session_state.metadata.workflow_state}")
    print(f"  Documents: {session_state.documents}")
    print(f"  Status: {session_state.status}")
else:
    print("✗ Failed to retrieve session")
    exit(1)

# Test list sessions
sessions = session_manager.list_sessions()
print(f"✓ Active sessions: {len(sessions)}")

# Test delete session (cleanup)
success = session_manager.delete_session(session_id)
if success:
    print(f"✓ Session deleted: {session_id}")
else:
    print("✗ Failed to delete session")

print("\n✅ All session operations completed successfully")
EOF
```

## Validation

**Validation Commands (Run on hx-docling-mcp-server):**

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# 1. Verify session manager module file exists
test -f /opt/docling-mcp/src/session_manager.py && echo "PASS: Session manager module exists" || echo "FAIL: Module not found"

# 2. Verify module imports successfully
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.session_manager import SessionManager; print('PASS: Module imports successfully')" 2>&1 | grep -q "PASS" && echo "PASS: Import successful" || echo "FAIL: Import failed"

# 3. Verify session creation works
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.session_manager import initialize_session_manager

redis_client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)
session_manager = initialize_session_manager()

session_id = session_manager.create_session(user="validation_test")
if session_id and len(session_id) == 36:  # UUID v4 length
    print("PASS: Session creation successful, UUID format valid")
    # Cleanup
    session_manager.delete_session(session_id)
else:
    print("FAIL: Session creation failed or invalid UUID")
EOF

# 4. Verify session TTL configuration
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.session_manager import initialize_session_manager

redis_client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)
session_manager = initialize_session_manager(ttl_hours=1, ttl_extension_hours=2, max_ttl_hours=24)

if session_manager.ttl_hours == 1 and session_manager.ttl_extension_hours == 2 and session_manager.max_ttl_hours == 24:
    print("PASS: Session TTL configuration correct")
else:
    print(f"FAIL: TTL config incorrect: ttl={session_manager.ttl_hours}, ext={session_manager.ttl_extension_hours}, max={session_manager.max_ttl_hours}")
EOF

# 5. Verify graceful degradation (simulate Redis unavailable)
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.session_manager import SessionManager

# Create session manager without initializing Redis client
session_manager = SessionManager()

if not session_manager.is_available():
    session_id = session_manager.create_session(user="test")
    if session_id is None:
        print("PASS: Graceful degradation works (returns None when Redis unavailable)")
    else:
        print("FAIL: Should return None when Redis unavailable")
else:
    print("INFO: Redis is available, skipping unavailability test")
EOF
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Session manager module imports without errors
- Session creation generates valid UUID v4
- TTL configuration applied correctly
- Graceful degradation returns None when Redis unavailable
- Session operations (add documents, update status, get session) work correctly

## Notes

### Session Lifecycle

**1. Create Session:**
- Generate UUID v4 session ID
- Store metadata in Redis hash `session:<session_id>`
- Add to active sessions index `sessions:active`
- Set TTL (24 hours default)

**2. Add Documents:**
- Add document IDs to Redis set `session:<session_id>:documents`
- Initialize status to "pending" in `session:<session_id>:status`
- Update last_accessed timestamp
- Extend TTL (sliding window)

**3. Process Documents:**
- Update status in `session:<session_id>:status` (pending → processing → completed/failed)
- Update last_accessed timestamp on each status change
- Extend TTL (sliding window)

**4. Get Session:**
- Retrieve metadata, documents, and status
- Update last_accessed timestamp
- Extend TTL (sliding window)

**5. Delete Session:**
- Atomic cleanup via MULTI/EXEC
- Delete metadata hash, documents set, status hash
- Remove from active sessions index

### TTL Sliding Window Strategy

**Mechanism:**
- Initial TTL: 24 hours (configurable)
- Extension increment: +4 hours on each access
- Maximum TTL: 168 hours (7 days) from creation
- Automatic expiration via Redis EXPIRE

**Example Timeline:**
- T=0: Session created, TTL=24h
- T=20h: Session accessed, TTL extended to 24h (4h extension applied)
- T=40h: Session accessed, TTL extended to 28h
- T=168h: Maximum TTL reached, no further extensions
- Session expires automatically when TTL reached

**Why Sliding Window:**
- Active sessions stay alive
- Inactive sessions expire automatically
- No manual cleanup required (Redis handles expiration)
- Prevents unbounded session accumulation

### Redis Data Model

**Session Metadata Hash:**
```
Key: session:<session_id>
Type: Hash
Fields:
  - user: "test_user"
  - created_at: "2025-12-01T10:00:00+00:00"
  - last_accessed: "2025-12-01T12:30:00+00:00"
  - ttl_hours: "24"
  - workflow_state: "initialized"
TTL: 24 hours (initially)
```

**Documents Set:**
```
Key: session:<session_id>:documents
Type: Set
Members: ["doc1", "doc2", "doc3"]
TTL: Same as session metadata
```

**Status Hash:**
```
Key: session:<session_id>:status
Type: Hash
Fields:
  - doc1: "processing"
  - doc2: "completed"
  - doc3: "pending"
TTL: Same as session metadata
```

**Active Sessions Index:**
```
Key: sessions:active
Type: Set
Members: [<session_id_1>, <session_id_2>, ...]
TTL: None (persistent)
```

### Atomic Operations with MULTI/EXEC

**Why Atomic:**
- Prevent partial session creation (all-or-nothing)
- Ensure consistent state (metadata + documents + status)
- Avoid race conditions in multi-threaded environment

**Pipeline Usage:**
```python
with self.redis_client.pipeline() as pipe:
    pipe.hset(session_key, "user", user)
    pipe.sadd(docs_key, *document_ids)
    pipe.expire(session_key, ttl_seconds)
    pipe.execute()  # Atomic execution
```

### Graceful Degradation Behavior

**When Redis Unavailable:**
1. `is_available()` returns False
2. `create_session()` returns None
3. `add_documents()` returns False
4. `get_session()` returns None
5. Service logs WARNING: "Redis unavailable, operating in stateless mode"
6. MCP tools that require sessions return error response
7. Stateless MCP tools (document conversion) continue working

**Recovery:**
- Session manager checks Redis health on each operation
- When Redis recovers, `is_available()` returns True
- Session operations resume normally
- No manual intervention required

### Security Considerations

**Session Security (Phase 1):**
- No authentication on session IDs (internal network trust)
- Session IDs are UUID v4 (unguessable, but not cryptographically signed)
- No user authentication (user field is informational only)

**Phase 2 Enhancements (Future):**
- Session ID signing with HMAC
- User authentication integration
- Rate limiting per session
- IP address binding

### Troubleshooting

**If session creation fails:**
```bash
# Check Redis connectivity
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.integrations.redis_client import initialize_redis_client; client = initialize_redis_client(host='hx-redis-server.hx.dev.local', port=6379); print('PING:', client.ping())"

# Check Redis memory usage
redis-cli -h hx-redis-server.hx.dev.local INFO memory | grep used_memory_human

# Verify session keys in Redis
redis-cli -h hx-redis-server.hx.dev.local KEYS "session:*"
```

**If TTL not extending:**
```bash
# Check session TTL in Redis
redis-cli -h hx-redis-server.hx.dev.local TTL session:<session_id>

# Verify last_accessed timestamp updating
redis-cli -h hx-redis-server.hx.dev.local HGET session:<session_id> last_accessed
```

**If atomic operations fail:**
```bash
# Check for MULTI/EXEC errors in logs
journalctl -u docling-mcp.service | grep -i "pipeline\|multi\|exec"

# Verify Redis supports transactions
redis-cli -h hx-redis-server.hx.dev.local INFO server | grep redis_version
# Should be 5.0+ for pipeline support
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
  - Section 2.4.6: Session Management (FR-018, FR-020)
  - Section 3.5: Configuration Management (SessionSettings)
- **Task 131**: Redis Client Module (dependency)
- **Redis Commands**: https://redis.io/commands/
- **UUID v4**: https://docs.python.org/3/library/uuid.html

## Risk Assessment

**Risk**: Medium
- Session state loss if Redis fails (acceptable per specification - no critical data)
- TTL calculation errors could cause premature expiration
- Atomic operations critical for data consistency

**Mitigation**:
- Graceful degradation allows stateless operation
- TTL capped at maximum (168 hours) to prevent errors
- MULTI/EXEC ensures atomic session creation/deletion
- Comprehensive logging for troubleshooting
- Session data is ephemeral (no data loss impact)
