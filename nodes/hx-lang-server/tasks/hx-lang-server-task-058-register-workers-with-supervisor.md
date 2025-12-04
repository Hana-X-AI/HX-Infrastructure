# Task: Register Workers with Supervisor

**Task ID**: hx-lang-server-task-058-register-workers-with-supervisor
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-054, task-055, task-056, task-057 (All Workers)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 30 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Architecture Overview"

---

## Objective

Create a factory function that assembles the complete LangGraph supervisor with all worker agents registered. This provides a single entry point for creating a fully configured agent system.

---

## Prerequisites

- [ ] RAG Agent implemented (task-054)
- [ ] Code Agent implemented (task-055)
- [ ] Tool Agent implemented (task-056)
- [ ] General Agent implemented (task-057)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Create Agent Factory Module

Create `/opt/hx-lang-server/app/agents/factory.py`:

```python
"""
Agent Factory for hx-lang-server.

Provides factory functions for creating fully configured
LangGraph supervisor with all workers registered.

This is the main entry point for instantiating the agent system.
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
    """
    Create ChatOllama instance for general/RAG queries (Ollama1).

    Returns:
        Configured ChatOllama for hx-ollama1-server.
    """
    return ChatOllama(
        base_url="http://hx-ollama1-server.hx.dev.local:11434",
        model="gemma3:27b",
        temperature=0.7,
        num_ctx=65536  # 64KB for RAG operations
    )


def create_llm_code() -> ChatOllama:
    """
    Create ChatOllama instance for code queries (Ollama2).

    Returns:
        Configured ChatOllama for hx-ollama2-server.
    """
    return ChatOllama(
        base_url="http://hx-ollama2-server.hx.dev.local:11434",
        model="qwen3-coder:30b",
        temperature=0.2,
        num_ctx=65536  # 64KB for code operations
    )


def create_agent_system(
    checkpointer: Optional[BaseCheckpointSaver] = None,
    max_recursion_depth: int = 25,
    lightrag_url: str = "http://hx-literag-server.hx.dev.local:8020",
    fastmcp_url: str = "http://hx-fastmcp-server.hx.dev.local:8000"
) -> SupervisorAgent:
    """
    Create fully configured agent system with all workers.

    This is the main factory function for creating the complete
    LangGraph agent system with supervisor and all workers registered.

    Args:
        checkpointer: Optional PostgreSQL checkpointer for persistence.
        max_recursion_depth: Maximum iterations (default 25).
        lightrag_url: LightRAG service URL.
        fastmcp_url: FastMCP gateway URL.

    Returns:
        SupervisorAgent with all workers registered and graph compiled.

    Example:
        ```python
        from app.agents.factory import create_agent_system

        # Create agent system
        agent = create_agent_system()

        # Invoke
        result = await agent.invoke(
            query="Write a Python function",
            session_id="session-1",
            thread_id="thread-1"
        )
        ```
    """
    # Create shared LLM instances
    llm_general = create_llm_general()
    llm_code = create_llm_code()

    # Create classifier with LLM fallback
    classifier = QueryClassifier(llm=llm_general)

    # Create supervisor
    supervisor = SupervisorAgent(
        classifier=classifier,
        max_recursion_depth=max_recursion_depth,
        checkpointer=checkpointer
    )

    # Create workers
    rag_worker = create_rag_agent(
        llm=llm_general,
        lightrag_url=lightrag_url
    )
    code_worker = create_code_agent(llm=llm_code)
    tool_worker = create_tool_agent(
        llm=llm_general,
        fastmcp_url=fastmcp_url
    )
    general_worker = create_general_agent(llm=llm_general)

    # Register workers with supervisor
    supervisor.register_worker("rag_agent", rag_worker)
    supervisor.register_worker("code_agent", code_worker)
    supervisor.register_worker("tool_agent", tool_worker)
    supervisor.register_worker("general_agent", general_worker)

    # Build and compile graph
    supervisor.build_graph()
    supervisor.compile()

    return supervisor


# Convenience alias
create_supervisor_with_workers = create_agent_system
```

### Step 2: Update Agents Package Exports

Update `/opt/hx-lang-server/app/agents/__init__.py`:

```python
"""Agents module for hx-lang-server."""

from .supervisor import SupervisorAgent, create_supervisor
from .workers.rag_agent import RAGAgentWorker, create_rag_agent
from .workers.code_agent import CodeAgentWorker, create_code_agent
from .workers.tool_agent import ToolAgentWorker, create_tool_agent
from .workers.general_agent import GeneralAgentWorker, create_general_agent
from .factory import (
    create_agent_system,
    create_supervisor_with_workers,
    create_llm_general,
    create_llm_code
)

__all__ = [
    # Supervisor
    "SupervisorAgent",
    "create_supervisor",
    # Workers
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent",
    "ToolAgentWorker",
    "create_tool_agent",
    "GeneralAgentWorker",
    "create_general_agent",
    # Factory
    "create_agent_system",
    "create_supervisor_with_workers",
    "create_llm_general",
    "create_llm_code"
]
```

### Step 3: Create Integration Test

Create `/opt/hx-lang-server/tests/test_agent_factory.py`:

```python
"""Integration tests for agent factory."""

import pytest
import asyncio
from app.agents.factory import create_agent_system


class TestAgentFactory:
    """Test agent factory creates functional system."""

    def test_create_agent_system(self):
        """Test agent system creation."""
        agent = create_agent_system()

        # Verify supervisor created
        assert agent is not None
        assert hasattr(agent, 'invoke')
        assert hasattr(agent, 'workers')

        # Verify all workers registered
        assert 'rag_agent' in agent.workers
        assert 'code_agent' in agent.workers
        assert 'tool_agent' in agent.workers
        assert 'general_agent' in agent.workers

        # Verify graph compiled
        assert agent._compiled_graph is not None

    @pytest.mark.asyncio
    async def test_invoke_general_query(self):
        """Test invoking with a general query."""
        agent = create_agent_system()

        result = await agent.invoke(
            query="Hello, how are you?",
            session_id="test-session",
            thread_id="test-thread"
        )

        assert result is not None
        assert result["query_type"] == "general"
        assert result["current_worker"] == "general_agent"

    @pytest.mark.asyncio
    async def test_invoke_code_query(self):
        """Test invoking with a code query."""
        agent = create_agent_system()

        result = await agent.invoke(
            query="Write a Python function to sort a list",
            session_id="test-session",
            thread_id="test-thread"
        )

        assert result is not None
        assert result["query_type"] == "code"
        assert result["current_worker"] == "code_agent"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
import asyncio
from app.agents.factory import create_agent_system

async def test():
    # Create full agent system
    agent = create_agent_system()

    print('Agent System Created Successfully!')
    print(f'Workers registered: {list(agent.workers.keys())}')
    print(f'Max recursion depth: {agent.max_recursion_depth}')
    print(f'Graph compiled: {agent._compiled_graph is not None}')

    # Test invocation (without actual Ollama connection)
    print('\nAgent system ready for invocation!')

asyncio.run(test())
"
```

---

## Code Structure

```
/opt/hx-lang-server/
├── app/
│   └── agents/
│       ├── __init__.py
│       ├── supervisor.py
│       ├── factory.py          # Agent Factory (this task)
│       └── workers/
│           ├── __init__.py
│           ├── rag_agent.py
│           ├── code_agent.py
│           ├── tool_agent.py
│           └── general_agent.py
└── tests/
    └── test_agent_factory.py
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Factory module | `/opt/hx-lang-server/app/agents/factory.py` | Agent system factory |
| Integration test | `/opt/hx-lang-server/tests/test_agent_factory.py` | Factory tests |

---

## Verification Steps

- [ ] `factory.py` file exists at correct location
- [ ] create_agent_system() can be called
- [ ] All 4 workers are registered
- [ ] Graph is compiled after creation
- [ ] Factory can be imported from app.agents

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.agents import create_agent_system; print('Factory imports OK')"

# Full verification
python -c "
from app.agents.factory import create_agent_system

agent = create_agent_system()

# Verify all workers
workers = ['rag_agent', 'code_agent', 'tool_agent', 'general_agent']
for w in workers:
    assert w in agent.workers, f'Missing worker: {w}'
    print(f'[OK] {w} registered')

# Verify graph
assert agent._compiled_graph is not None
print('[OK] Graph compiled')

print('\nAgent Factory verification: PASS')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/agents/factory.py
rm /opt/hx-lang-server/tests/test_agent_factory.py
# Revert __init__.py changes
```

---

## Notes

- This task completes the agent assembly process
- create_agent_system() is the main entry point for creating agents
- Shared LLM instances reduce resource usage
- Checkpointer integration tested in Work Stream 4 (Trinity)
- This factory is used by FastAPI endpoints (Work Stream 10)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
