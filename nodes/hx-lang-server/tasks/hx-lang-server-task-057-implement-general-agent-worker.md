# Task: Implement General Agent Worker

**Task ID**: hx-lang-server-task-057-implement-general-agent-worker
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-053 (Supervisor Agent), hx-lang-server-task-023 (langchain-ollama)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 30 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "FR-010"

---

## Objective

Implement the General Agent worker that handles general conversational queries. Routes to Ollama1 (hx-ollama1-server) for basic conversation and queries that do not fit RAG, Code, or Tool categories.

---

## Prerequisites

- [ ] Supervisor agent implemented (task-053)
- [ ] langchain-ollama installed (task-023)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Implement General Agent Worker

Create `/opt/hx-lang-server/app/agents/workers/general_agent.py`:

```python
"""
General Agent Worker for hx-lang-server.

Handles general conversational queries by routing to Ollama1.
Used for:
- General conversation and greetings
- Simple questions
- Queries that don't fit RAG, Code, or Tool categories

Specification Reference:
- FR-010: Route general queries to hx-ollama1-server
"""

from typing import Optional
from langchain_ollama import ChatOllama
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.core.state import AgentState


class GeneralAgentWorker:
    """
    General Agent Worker.

    Handles general conversational queries using Ollama1.

    Attributes:
        llm: ChatOllama instance for Ollama1 (general LLM).
    """

    # General conversation system prompt
    GENERAL_SYSTEM_PROMPT = """You are a helpful, friendly AI assistant.
You provide clear, concise, and accurate responses to user questions.
Be conversational and engaging while remaining professional.
If you don't know something, say so honestly rather than making up information."""

    def __init__(
        self,
        llm: Optional[ChatOllama] = None,
        temperature: float = 0.7
    ):
        """
        Initialize the General agent worker.

        Args:
            llm: ChatOllama instance for Ollama1. Creates default if None.
            temperature: LLM temperature (higher for more creative responses).
        """
        self.llm = llm or ChatOllama(
            base_url="http://hx-ollama1-server.hx.dev.local:11434",
            model="gemma3:27b",
            temperature=temperature,
            num_ctx=8192  # 8KB context for general queries
        )

    async def _generate_response(
        self,
        query: str,
        messages: list
    ) -> str:
        """
        Generate conversational response using Ollama1.

        Args:
            query: User query.
            messages: Conversation history.

        Returns:
            Generated response string.
        """
        # Build messages with general system prompt
        system_message = SystemMessage(content=self.GENERAL_SYSTEM_PROMPT)
        user_message = HumanMessage(content=query)

        # Include conversation history
        prompt_messages = [system_message] + messages[:-1] + [user_message]

        try:
            response = await self.llm.ainvoke(prompt_messages)
            return response.content
        except Exception as e:
            return f"I apologize, but I encountered an error: {str(e)}"

    async def __call__(self, state: AgentState) -> AgentState:
        """
        Process state as a LangGraph node.

        Args:
            state: Current agent state.

        Returns:
            Updated agent state with general response.
        """
        # Get the latest user message
        if not state["messages"]:
            return state

        last_message = state["messages"][-1]
        if not isinstance(last_message, HumanMessage):
            query = "Hello"
        else:
            query = last_message.content

        # Generate response
        response_text = await self._generate_response(
            query=query,
            messages=state["messages"]
        )

        # Create response message
        response = AIMessage(content=response_text)

        # Return updated state
        return {
            **state,
            "messages": state["messages"] + [response],
            "current_worker": "general_agent"
        }


def create_general_agent(
    llm: Optional[ChatOllama] = None,
    temperature: float = 0.7
) -> GeneralAgentWorker:
    """
    Factory function to create General agent worker.

    Args:
        llm: Optional ChatOllama for Ollama1.
        temperature: LLM temperature (default 0.7).

    Returns:
        Configured GeneralAgentWorker instance.
    """
    return GeneralAgentWorker(
        llm=llm,
        temperature=temperature
    )
```

### Step 2: Update Workers Package

Update `/opt/hx-lang-server/app/agents/workers/__init__.py`:

```python
"""Worker agents for hx-lang-server."""

from .rag_agent import RAGAgentWorker, create_rag_agent
from .code_agent import CodeAgentWorker, create_code_agent
from .tool_agent import ToolAgentWorker, create_tool_agent
from .general_agent import GeneralAgentWorker, create_general_agent

__all__ = [
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent",
    "ToolAgentWorker",
    "create_tool_agent",
    "GeneralAgentWorker",
    "create_general_agent"
]
```

### Step 3: Update Agents Package

Update `/opt/hx-lang-server/app/agents/__init__.py`:

```python
"""Agents module for hx-lang-server."""

from .supervisor import SupervisorAgent, create_supervisor
from .workers.rag_agent import RAGAgentWorker, create_rag_agent
from .workers.code_agent import CodeAgentWorker, create_code_agent
from .workers.tool_agent import ToolAgentWorker, create_tool_agent
from .workers.general_agent import GeneralAgentWorker, create_general_agent

__all__ = [
    "SupervisorAgent",
    "create_supervisor",
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent",
    "ToolAgentWorker",
    "create_tool_agent",
    "GeneralAgentWorker",
    "create_general_agent"
]
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.agents.workers.general_agent import GeneralAgentWorker, create_general_agent

# Test instantiation
worker = create_general_agent()
print(f'General Agent Worker created')
print(f'LLM Model: {worker.llm.model}')
print(f'LLM Base URL: {worker.llm.base_url}')
print(f'Temperature: {worker.llm.temperature}')
print('\nGeneral Agent Worker implementation verified!')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| General Agent module | `/opt/hx-lang-server/app/agents/workers/general_agent.py` | GeneralAgentWorker implementation |

---

## Verification Steps

- [ ] `general_agent.py` file exists at correct location
- [ ] GeneralAgentWorker can be imported
- [ ] Worker can be instantiated without errors
- [ ] LLM configuration targets Ollama1
- [ ] Model is gemma3:27b

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.agents.workers.general_agent import create_general_agent; print('General Agent imports OK')"

# Configuration verification
python -c "
from app.agents.workers.general_agent import create_general_agent

w = create_general_agent()
assert w.llm.model == 'gemma3:27b', 'Wrong model'
assert 'ollama1' in w.llm.base_url, 'Wrong Ollama server'
print('General Agent configuration: PASS')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/agents/workers/general_agent.py
# Update __init__.py files to remove general_agent exports
```

---

## Notes

- General Agent routes to Ollama1 (hx-ollama1-server) per FR-010
- Uses gemma3:27b model for general conversation
- Higher temperature (0.7) for more natural conversation
- 8KB context sufficient for general queries
- Connection to Ollama1 tested in Work Stream 7 (Jim)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
