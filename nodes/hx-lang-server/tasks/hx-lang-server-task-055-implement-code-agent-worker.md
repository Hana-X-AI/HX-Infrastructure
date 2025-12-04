# Task: Implement Code Agent Worker

**Task ID**: hx-lang-server-task-055-implement-code-agent-worker
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-053 (Supervisor Agent), hx-lang-server-task-023 (langchain-ollama)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 40 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "FR-011, FR-013"

---

## Objective

Implement the Code Agent worker that handles code-related queries. Routes to Ollama2 (hx-ollama2-server) which runs qwen3-coder:30b for specialized code generation and debugging.

---

## Prerequisites

- [ ] Supervisor agent implemented (task-053)
- [ ] langchain-ollama installed (task-023)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Implement Code Agent Worker

Create `/opt/hx-lang-server/app/agents/workers/code_agent.py`:

```python
"""
Code Agent Worker for hx-lang-server.

Handles code-related queries by routing to Ollama2 (qwen3-coder:30b).
Specialized for:
- Code generation
- Debugging and error analysis
- Code refactoring
- API implementation
- Algorithm development

Specification Reference:
- FR-011: Route code-related queries to hx-ollama2-server
- FR-013: Validate Ollama model context size >= 64KB for Code operations
"""

from typing import Optional
from langchain_ollama import ChatOllama
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.core.state import AgentState


class CodeAgentWorker:
    """
    Code Agent Worker.

    Handles code-related queries using Ollama2 with qwen3-coder model.

    Attributes:
        llm: ChatOllama instance for Ollama2 (code LLM).
    """

    # Code-focused system prompt
    CODE_SYSTEM_PROMPT = """You are an expert software engineer and coding assistant.
You specialize in:
- Writing clean, efficient, and well-documented code
- Debugging errors and fixing bugs
- Refactoring for better performance and readability
- Implementing algorithms and data structures
- API design and implementation
- Best practices and design patterns

When providing code:
1. Include clear comments explaining the logic
2. Follow the language's idiomatic conventions
3. Handle edge cases and errors appropriately
4. Suggest improvements when relevant

Be concise but thorough in your explanations."""

    def __init__(
        self,
        llm: Optional[ChatOllama] = None,
        temperature: float = 0.2
    ):
        """
        Initialize the Code agent worker.

        Args:
            llm: ChatOllama instance for Ollama2. Creates default if None.
            temperature: LLM temperature (lower = more deterministic for code).
        """
        self.llm = llm or ChatOllama(
            base_url="http://hx-ollama2-server.hx.dev.local:11434",
            model="qwen3-coder:30b",
            temperature=temperature,
            num_ctx=65536  # 64KB context for code (CAIO decision)
        )

    async def _generate_code_response(
        self,
        query: str,
        messages: list
    ) -> str:
        """
        Generate code-focused response using Ollama2.

        Args:
            query: User query about code.
            messages: Conversation history.

        Returns:
            Generated code response string.
        """
        # Build messages with code-focused system prompt
        system_message = SystemMessage(content=self.CODE_SYSTEM_PROMPT)
        user_message = HumanMessage(content=query)

        # Include relevant conversation history
        prompt_messages = [system_message] + messages[:-1] + [user_message]

        try:
            response = await self.llm.ainvoke(prompt_messages)
            return response.content
        except Exception as e:
            return f"[Code generation error: {str(e)}]"

    async def __call__(self, state: AgentState) -> AgentState:
        """
        Process state as a LangGraph node.

        Args:
            state: Current agent state.

        Returns:
            Updated agent state with code response.
        """
        # Get the latest user message
        if not state["messages"]:
            return state

        last_message = state["messages"][-1]
        if not isinstance(last_message, HumanMessage):
            query = "Please help me with my coding question."
        else:
            query = last_message.content

        # Generate code-focused response
        response_text = await self._generate_code_response(
            query=query,
            messages=state["messages"]
        )

        # Create response message
        response = AIMessage(content=response_text)

        # Return updated state
        return {
            **state,
            "messages": state["messages"] + [response],
            "current_worker": "code_agent"
        }


def create_code_agent(
    llm: Optional[ChatOllama] = None,
    temperature: float = 0.2
) -> CodeAgentWorker:
    """
    Factory function to create Code agent worker.

    Args:
        llm: Optional ChatOllama for Ollama2.
        temperature: LLM temperature (default 0.2 for code).

    Returns:
        Configured CodeAgentWorker instance.
    """
    return CodeAgentWorker(
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

__all__ = [
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent"
]
```

### Step 3: Update Agents Package

Update `/opt/hx-lang-server/app/agents/__init__.py`:

```python
"""Agents module for hx-lang-server."""

from .supervisor import SupervisorAgent, create_supervisor
from .workers.rag_agent import RAGAgentWorker, create_rag_agent
from .workers.code_agent import CodeAgentWorker, create_code_agent

__all__ = [
    "SupervisorAgent",
    "create_supervisor",
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent"
]
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.agents.workers.code_agent import CodeAgentWorker, create_code_agent

# Test instantiation
worker = create_code_agent()
print(f'Code Agent Worker created')
print(f'LLM Model: {worker.llm.model}')
print(f'LLM Base URL: {worker.llm.base_url}')
print(f'Context Size: {worker.llm.num_ctx}')
print('\nCode Agent Worker implementation verified!')
"
```

---

## Code Structure

```
/opt/hx-lang-server/
├── app/
│   └── agents/
│       └── workers/
│           ├── __init__.py
│           ├── rag_agent.py
│           └── code_agent.py   # Code Agent (this task)
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Code Agent module | `/opt/hx-lang-server/app/agents/workers/code_agent.py` | CodeAgentWorker implementation |

---

## Verification Steps

- [ ] `code_agent.py` file exists at correct location
- [ ] CodeAgentWorker can be imported
- [ ] Worker can be instantiated without errors
- [ ] LLM configuration targets Ollama2
- [ ] Model is qwen3-coder:30b
- [ ] Context size is 64KB per CAIO decision
- [ ] Temperature is low (0.2) for deterministic code

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.agents.workers.code_agent import create_code_agent; print('Code Agent imports OK')"

# Configuration verification
python -c "
from app.agents.workers.code_agent import create_code_agent

w = create_code_agent()
assert w.llm.model == 'qwen3-coder:30b', 'Wrong model'
assert 'ollama2' in w.llm.base_url, 'Wrong Ollama server'
assert w.llm.num_ctx == 65536, 'Wrong context size'
assert w.llm.temperature == 0.2, 'Wrong temperature'
print('Code Agent configuration: PASS')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/agents/workers/code_agent.py
# Update __init__.py files to remove code_agent exports
```

---

## Notes

- Code Agent routes to Ollama2 (hx-ollama2-server) per FR-011
- Uses qwen3-coder:30b model specialized for code
- 64KB context size for complex code operations (CAIO decision)
- Lower temperature (0.2) for more deterministic code generation
- Connection to Ollama2 tested in Work Stream 7 (Jim)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
