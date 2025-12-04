# Task: Implement Graph Compilation with Checkpointing

**Task ID**: hx-lang-server-task-059-implement-graph-compilation
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-058 (Worker Registration), Work Stream 4 (PostgreSQL Integration)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 40 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration"

---

## Objective

Enhance the graph compilation to integrate with PostgreSQL checkpointing via langgraph-checkpoint-postgres. This enables durable state persistence across service restarts.

---

## Prerequisites

- [ ] Worker registration complete (task-058)
- [ ] langgraph-checkpoint-postgres installed (Work Stream 4)
- [ ] PostgreSQL database provisioned (Work Stream 4)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Create Checkpointer Module

Create `/opt/hx-lang-server/app/persistence/__init__.py`:

```bash
mkdir -p /opt/hx-lang-server/app/persistence
touch /opt/hx-lang-server/app/persistence/__init__.py
```

Create `/opt/hx-lang-server/app/persistence/checkpointer.py`:

```python
"""
PostgreSQL Checkpointer for hx-lang-server.

Provides durable state persistence using langgraph-checkpoint-postgres.
Enables conversation continuity across service restarts.

Configuration:
- Host: hx-postgres-server.hx.dev.local
- Port: 5432
- Database: hx_lang_server
- Schema: langgraph

Specification Reference: node-spec.md Section "PostgreSQL Checkpoint Configuration"
"""

from typing import Optional
import os
from contextlib import asynccontextmanager
from psycopg import AsyncConnection
from psycopg.rows import dict_row
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver


class CheckpointerConfig:
    """Configuration for PostgreSQL checkpointer."""

    def __init__(
        self,
        host: str = "hx-postgres-server.hx.dev.local",
        port: int = 5432,
        database: str = "hx_lang_server",
        user: str = "hx_lang_server",
        password: Optional[str] = None,
        schema: str = "langgraph"
    ):
        """
        Initialize checkpointer configuration.

        Args:
            host: PostgreSQL host.
            port: PostgreSQL port.
            database: Database name.
            user: Database user.
            password: Database password (from env if None).
            schema: Schema for checkpoint tables.
        """
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password or os.environ.get("POSTGRES_PASSWORD", "")
        self.schema = schema

    @property
    def connection_string(self) -> str:
        """Generate PostgreSQL connection string."""
        return (
            f"postgresql://{self.user}:{self.password}"
            f"@{self.host}:{self.port}/{self.database}"
        )


async def create_async_connection(config: CheckpointerConfig) -> AsyncConnection:
    """
    Create async PostgreSQL connection.

    CRITICAL: These parameters are REQUIRED for langgraph-checkpoint-postgres:
    - autocommit=True: Required for checkpoint commits
    - row_factory=dict_row: Required for checkpoint data format

    Args:
        config: CheckpointerConfig instance.

    Returns:
        Configured AsyncConnection.
    """
    conn = await AsyncConnection.connect(
        host=config.host,
        port=config.port,
        dbname=config.database,
        user=config.user,
        password=config.password,
        autocommit=True,  # REQUIRED for checkpoint commits
        row_factory=dict_row  # REQUIRED for langgraph-checkpoint-postgres
    )
    return conn


async def create_checkpointer(
    config: Optional[CheckpointerConfig] = None
) -> AsyncPostgresSaver:
    """
    Create AsyncPostgresSaver checkpointer.

    This checkpointer provides durable state persistence for LangGraph.

    Args:
        config: Optional configuration. Uses defaults if None.

    Returns:
        Configured AsyncPostgresSaver instance.

    Example:
        ```python
        checkpointer = await create_checkpointer()

        # Use with supervisor
        supervisor = SupervisorAgent(checkpointer=checkpointer)
        ```
    """
    if config is None:
        config = CheckpointerConfig()

    conn = await create_async_connection(config)
    checkpointer = AsyncPostgresSaver(conn)

    # Initialize tables if needed
    await checkpointer.setup()

    return checkpointer


@asynccontextmanager
async def get_checkpointer(config: Optional[CheckpointerConfig] = None):
    """
    Context manager for checkpointer lifecycle.

    Ensures proper cleanup of database connection.

    Args:
        config: Optional configuration.

    Yields:
        AsyncPostgresSaver instance.

    Example:
        ```python
        async with get_checkpointer() as checkpointer:
            supervisor = SupervisorAgent(checkpointer=checkpointer)
            await supervisor.invoke(...)
        ```
    """
    if config is None:
        config = CheckpointerConfig()

    conn = await create_async_connection(config)
    checkpointer = AsyncPostgresSaver(conn)

    try:
        await checkpointer.setup()
        yield checkpointer
    finally:
        await conn.close()


# Module-level checkpointer instance (initialized lazily)
_checkpointer: Optional[AsyncPostgresSaver] = None


async def get_default_checkpointer() -> AsyncPostgresSaver:
    """
    Get or create the default checkpointer instance.

    Returns:
        Shared AsyncPostgresSaver instance.
    """
    global _checkpointer
    if _checkpointer is None:
        _checkpointer = await create_checkpointer()
    return _checkpointer
```

### Step 2: Update Persistence Package

Update `/opt/hx-lang-server/app/persistence/__init__.py`:

```python
"""Persistence module for hx-lang-server."""

from .checkpointer import (
    CheckpointerConfig,
    create_async_connection,
    create_checkpointer,
    get_checkpointer,
    get_default_checkpointer
)

__all__ = [
    "CheckpointerConfig",
    "create_async_connection",
    "create_checkpointer",
    "get_checkpointer",
    "get_default_checkpointer"
]
```

### Step 3: Update Agent Factory with Checkpointing

Update `/opt/hx-lang-server/app/agents/factory.py` to add checkpointing support:

```python
"""
Agent Factory for hx-lang-server.

Provides factory functions for creating fully configured
LangGraph supervisor with all workers registered.
"""

from typing import Optional
from langchain_ollama import ChatOllama
from langgraph.checkpoint.base import BaseCheckpointSaver

from app.core.classifier import QueryClassifier
from app.agents.supervisor import SupervisorAgent
from app.agents.workers.rag_agent import create_rag_agent
from app.agents.workers.code_agent import create_code_agent
from app.agents.workers.tool_agent import create_tool_agent
from app.agents.workers.general_agent import create_general_agent


def create_llm_general() -> ChatOllama:
    """Create ChatOllama instance for general/RAG queries (Ollama1)."""
    return ChatOllama(
        base_url="http://hx-ollama1-server.hx.dev.local:11434",
        model="gemma3:27b",
        temperature=0.7,
        num_ctx=65536
    )


def create_llm_code() -> ChatOllama:
    """Create ChatOllama instance for code queries (Ollama2)."""
    return ChatOllama(
        base_url="http://hx-ollama2-server.hx.dev.local:11434",
        model="qwen3-coder:30b",
        temperature=0.2,
        num_ctx=65536
    )


def create_agent_system(
    checkpointer: Optional[BaseCheckpointSaver] = None,
    max_recursion_depth: int = 25,
    lightrag_url: str = "http://hx-literag-server.hx.dev.local:8020",
    fastmcp_url: str = "http://hx-fastmcp-server.hx.dev.local:8000"
) -> SupervisorAgent:
    """
    Create fully configured agent system with all workers.

    Args:
        checkpointer: Optional PostgreSQL checkpointer for persistence.
        max_recursion_depth: Maximum iterations (default 25).
        lightrag_url: LightRAG service URL.
        fastmcp_url: FastMCP gateway URL.

    Returns:
        SupervisorAgent with all workers registered and graph compiled.
    """
    llm_general = create_llm_general()
    llm_code = create_llm_code()

    classifier = QueryClassifier(llm=llm_general)

    supervisor = SupervisorAgent(
        classifier=classifier,
        max_recursion_depth=max_recursion_depth,
        checkpointer=checkpointer
    )

    supervisor.register_worker("rag_agent", create_rag_agent(llm=llm_general, lightrag_url=lightrag_url))
    supervisor.register_worker("code_agent", create_code_agent(llm=llm_code))
    supervisor.register_worker("tool_agent", create_tool_agent(llm=llm_general, fastmcp_url=fastmcp_url))
    supervisor.register_worker("general_agent", create_general_agent(llm=llm_general))

    supervisor.build_graph()
    supervisor.compile()

    return supervisor


async def create_agent_system_with_persistence(
    max_recursion_depth: int = 25,
    lightrag_url: str = "http://hx-literag-server.hx.dev.local:8020",
    fastmcp_url: str = "http://hx-fastmcp-server.hx.dev.local:8000"
) -> SupervisorAgent:
    """
    Create agent system with PostgreSQL checkpointing enabled.

    This is the recommended factory for production use.

    Args:
        max_recursion_depth: Maximum iterations (default 25).
        lightrag_url: LightRAG service URL.
        fastmcp_url: FastMCP gateway URL.

    Returns:
        SupervisorAgent with PostgreSQL checkpointing.
    """
    from app.persistence import get_default_checkpointer

    checkpointer = await get_default_checkpointer()

    return create_agent_system(
        checkpointer=checkpointer,
        max_recursion_depth=max_recursion_depth,
        lightrag_url=lightrag_url,
        fastmcp_url=fastmcp_url
    )


# Convenience aliases
create_supervisor_with_workers = create_agent_system
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.persistence.checkpointer import CheckpointerConfig, create_checkpointer

# Test configuration
config = CheckpointerConfig()
print(f'Host: {config.host}')
print(f'Port: {config.port}')
print(f'Database: {config.database}')
print(f'User: {config.user}')
print(f'Schema: {config.schema}')

print('\nCheckpointer configuration verified!')
"
```

---

## Code Structure

```
/opt/hx-lang-server/
├── app/
│   ├── agents/
│   │   ├── factory.py         # Updated with checkpointing
│   │   └── ...
│   └── persistence/
│       ├── __init__.py
│       └── checkpointer.py    # Checkpointer module (this task)
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Checkpointer module | `/opt/hx-lang-server/app/persistence/checkpointer.py` | PostgreSQL checkpointer |
| Updated factory | `/opt/hx-lang-server/app/agents/factory.py` | With persistence support |

---

## Verification Steps

- [ ] `checkpointer.py` file exists at correct location
- [ ] CheckpointerConfig can be imported
- [ ] Configuration defaults are correct
- [ ] create_agent_system_with_persistence() is available

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.persistence import CheckpointerConfig, create_checkpointer; print('Persistence imports OK')"

# Factory test
python -c "from app.agents.factory import create_agent_system_with_persistence; print('Factory with persistence OK')"
```

---

## Rollback Procedure

```bash
rm -rf /opt/hx-lang-server/app/persistence/
# Revert factory.py changes
```

---

## Notes

- PostgreSQL connection requires autocommit=True and row_factory=dict_row
- These parameters are REQUIRED by langgraph-checkpoint-postgres
- Database provisioning completed in Work Stream 4 (Trinity)
- Checkpointing enables conversation continuity per FR-008
- Checkpoint frequency is per-turn per specification

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
