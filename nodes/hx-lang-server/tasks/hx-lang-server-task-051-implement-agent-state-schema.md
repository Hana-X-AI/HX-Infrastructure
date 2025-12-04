# Task: Implement AgentState TypedDict Schema

**Task ID**: hx-lang-server-task-051-implement-agent-state-schema
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-026 (Core Dependencies Verified)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 30 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "State Schema Design"

---

## Objective

Implement the AgentState TypedDict that defines the core state schema for the LangGraph supervisor agent. This state is shared across all agent nodes and persisted via PostgreSQL checkpointing.

---

## Prerequisites

- [ ] Core framework dependencies verified (task-026)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`
- [ ] Application directory structure exists: `/opt/hx-lang-server/app/`

---

## Implementation Steps

### Step 1: Create State Module Directory

```bash
mkdir -p /opt/hx-lang-server/app/core
touch /opt/hx-lang-server/app/__init__.py
touch /opt/hx-lang-server/app/core/__init__.py
```

### Step 2: Implement AgentState Schema

Create `/opt/hx-lang-server/app/core/state.py`:

```python
"""
AgentState TypedDict for hx-lang-server LangGraph supervisor.

This module defines the core state schema shared across all agent nodes.
The state is persisted via PostgreSQL checkpointing (langgraph-checkpoint-postgres).

Schema Version: 1.0
Specification Reference: node-spec.md Section "State Schema Design"
"""

from typing import TypedDict, Annotated, List, Optional
from datetime import datetime
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage


class AgentState(TypedDict):
    """
    Core state schema for LangGraph supervisor.

    This TypedDict defines all fields that are:
    - Shared across supervisor and worker agents
    - Persisted to PostgreSQL checkpoints
    - Used for conditional routing decisions

    Attributes:
        schema_version: Version string for backward compatibility.
                       Increment on breaking changes (e.g., "1.0" -> "2.0").
        messages: Conversation history with add_messages reducer for appending.
        query_type: Classification result ("general", "code", "rag", "tool").
        current_worker: Name of the active worker agent (None if supervisor).
        rag_context: Retrieved context from LightRAG (None if not applicable).
        tool_results: Results from MCP tool invocations (None if not used).
        iteration_count: Counter for recursion limit enforcement.
        session_id: Unique session identifier.
        thread_id: Conversation thread identifier for continuity.
        user_id: Optional user identifier for multi-user scenarios.
        created_at: ISO 8601 timestamp of state creation.
        updated_at: ISO 8601 timestamp of last state update.
    """

    # Schema version for backward compatibility (per Alex Rivera's review)
    schema_version: str  # "1.0" - increment on breaking changes

    # Message history with reducer for appending
    messages: Annotated[List[BaseMessage], add_messages]

    # Query classification result
    query_type: str  # "general", "code", "rag", "tool"

    # Active worker assignment
    current_worker: Optional[str]

    # RAG context from LightRAG
    rag_context: Optional[str]

    # Tool invocation results
    tool_results: Optional[dict]

    # Iteration counter for recursion limits
    iteration_count: int

    # Session metadata
    session_id: str
    thread_id: str
    user_id: Optional[str]
    created_at: str  # ISO 8601 timestamp
    updated_at: str  # ISO 8601 timestamp


# Constants for query types
QUERY_TYPE_GENERAL = "general"
QUERY_TYPE_CODE = "code"
QUERY_TYPE_RAG = "rag"
QUERY_TYPE_TOOL = "tool"

VALID_QUERY_TYPES = {
    QUERY_TYPE_GENERAL,
    QUERY_TYPE_CODE,
    QUERY_TYPE_RAG,
    QUERY_TYPE_TOOL
}

# Current schema version
SCHEMA_VERSION = "1.0"


def create_initial_state(
    session_id: str,
    thread_id: str,
    user_id: Optional[str] = None
) -> AgentState:
    """
    Create initial state for a new conversation.

    Args:
        session_id: Unique session identifier.
        thread_id: Conversation thread identifier.
        user_id: Optional user identifier.

    Returns:
        AgentState with initialized values.
    """
    now = datetime.utcnow().isoformat() + "Z"

    return AgentState(
        schema_version=SCHEMA_VERSION,
        messages=[],
        query_type=QUERY_TYPE_GENERAL,
        current_worker=None,
        rag_context=None,
        tool_results=None,
        iteration_count=0,
        session_id=session_id,
        thread_id=thread_id,
        user_id=user_id,
        created_at=now,
        updated_at=now
    )


def validate_query_type(query_type: str) -> bool:
    """Validate that query_type is one of the allowed values."""
    return query_type in VALID_QUERY_TYPES
```

### Step 3: Add Exports to Package Init

Update `/opt/hx-lang-server/app/core/__init__.py`:

```python
"""Core module for hx-lang-server."""

from .state import (
    AgentState,
    SCHEMA_VERSION,
    QUERY_TYPE_GENERAL,
    QUERY_TYPE_CODE,
    QUERY_TYPE_RAG,
    QUERY_TYPE_TOOL,
    VALID_QUERY_TYPES,
    create_initial_state,
    validate_query_type
)

__all__ = [
    "AgentState",
    "SCHEMA_VERSION",
    "QUERY_TYPE_GENERAL",
    "QUERY_TYPE_CODE",
    "QUERY_TYPE_RAG",
    "QUERY_TYPE_TOOL",
    "VALID_QUERY_TYPES",
    "create_initial_state",
    "validate_query_type"
]
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.core.state import (
    AgentState,
    SCHEMA_VERSION,
    create_initial_state,
    validate_query_type,
    VALID_QUERY_TYPES
)

# Test state creation
state = create_initial_state(
    session_id='test-session-001',
    thread_id='test-thread-001',
    user_id='test-user'
)

print(f'Schema Version: {SCHEMA_VERSION}')
print(f'Valid Query Types: {VALID_QUERY_TYPES}')
print(f'Created State:')
for key, value in state.items():
    print(f'  {key}: {value}')

# Test validation
assert validate_query_type('code') == True
assert validate_query_type('invalid') == False
print('\nAgentState schema implementation verified!')
"
```

---

## Code Structure

```
/opt/hx-lang-server/
├── app/
│   ├── __init__.py
│   └── core/
│       ├── __init__.py
│       └── state.py          # AgentState TypedDict (this task)
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| State module | `/opt/hx-lang-server/app/core/state.py` | AgentState TypedDict |
| Package init | `/opt/hx-lang-server/app/core/__init__.py` | Module exports |

---

## Verification Steps

- [ ] `state.py` file exists at correct location
- [ ] AgentState TypedDict can be imported
- [ ] create_initial_state() returns valid state
- [ ] All required fields present in state
- [ ] schema_version field is "1.0"
- [ ] validate_query_type() works correctly

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.core.state import AgentState, create_initial_state, SCHEMA_VERSION; print(f'Schema version: {SCHEMA_VERSION}')"

# Full verification
python -c "
from app.core.state import AgentState, create_initial_state, VALID_QUERY_TYPES
import typing

# Verify TypedDict fields
hints = typing.get_type_hints(AgentState)
required_fields = [
    'schema_version', 'messages', 'query_type', 'current_worker',
    'rag_context', 'tool_results', 'iteration_count', 'session_id',
    'thread_id', 'user_id', 'created_at', 'updated_at'
]

for field in required_fields:
    assert field in hints, f'Missing field: {field}'

print(f'All {len(required_fields)} required fields present')
print('AgentState schema verification: PASS')
"
```

---

## Rollback Procedure

```bash
rm -rf /opt/hx-lang-server/app/core/
# Recreate empty structure
mkdir -p /opt/hx-lang-server/app/core
touch /opt/hx-lang-server/app/__init__.py
touch /opt/hx-lang-server/app/core/__init__.py
```

---

## Notes

- schema_version field added per Alex Rivera's architecture review
- created_at and updated_at timestamps added per synthesis enhancement
- Messages use add_messages reducer for automatic message appending
- State is checkpointed to PostgreSQL per-turn (Work Stream 4)
- Query types align with Ollama routing table (Work Stream 7)
- This is the foundation for all LangGraph agent functionality

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
