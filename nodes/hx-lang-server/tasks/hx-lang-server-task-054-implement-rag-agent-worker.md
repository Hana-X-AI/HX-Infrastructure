# Task: Implement RAG Agent Worker

**Task ID**: hx-lang-server-task-054-implement-rag-agent-worker
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-053 (Supervisor Agent), hx-lang-server-task-023 (langchain-ollama)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 45 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "FR-010, FR-014, FR-015, FR-016"

---

## Objective

Implement the RAG Agent worker that handles retrieval-augmented generation queries. Routes to Ollama1 (hx-ollama1-server) for LLM inference and integrates with LightRAG for context retrieval.

---

## Prerequisites

- [ ] Supervisor agent implemented (task-053)
- [ ] langchain-ollama installed (task-023)
- [ ] httpx installed (task-025) for LightRAG HTTP client
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Create Workers Module Directory

```bash
mkdir -p /opt/hx-lang-server/app/agents/workers
touch /opt/hx-lang-server/app/agents/workers/__init__.py
```

### Step 2: Implement RAG Agent Worker

Create `/opt/hx-lang-server/app/agents/workers/rag_agent.py`:

```python
"""
RAG Agent Worker for hx-lang-server.

Handles retrieval-augmented generation queries by:
1. Querying LightRAG for relevant context
2. Augmenting the prompt with retrieved context
3. Generating response via Ollama1 (general LLM)

Supports adaptive retrieval with iteration when initial results insufficient.

Specification Reference:
- FR-010: Route general queries to hx-ollama1-server
- FR-014: Integrate with hx-literag-server via HTTP API
- FR-015: Support adaptive retrieval with iteration
- FR-016: Support LightRAG query modes
"""

from typing import Optional, Literal
import httpx
from langchain_ollama import ChatOllama
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from app.core.state import AgentState


# LightRAG query modes
LightRAGMode = Literal["local", "global", "hybrid", "mix"]


class RAGAgentWorker:
    """
    RAG Agent Worker.

    Performs retrieval-augmented generation using LightRAG for context
    and Ollama1 for response generation.

    Attributes:
        llm: ChatOllama instance for Ollama1.
        lightrag_url: URL for LightRAG service.
        default_mode: Default LightRAG query mode.
        min_context_length: Minimum context length before iteration.
        max_iterations: Maximum retrieval iterations.
    """

    # RAG prompt template
    RAG_PROMPT = """You are a knowledgeable assistant. Use the following context to answer the user's question.
If the context doesn't contain relevant information, say so and provide what help you can.

Context:
{context}

Answer the question based on the context above. Be concise and accurate."""

    def __init__(
        self,
        llm: Optional[ChatOllama] = None,
        lightrag_url: str = "http://hx-literag-server.hx.dev.local:8020",
        default_mode: LightRAGMode = "hybrid",
        min_context_length: int = 100,
        max_iterations: int = 3
    ):
        """
        Initialize the RAG agent worker.

        Args:
            llm: ChatOllama instance for Ollama1. Creates default if None.
            lightrag_url: LightRAG service URL.
            default_mode: Default query mode.
            min_context_length: Minimum context before considered sufficient.
            max_iterations: Max retrieval attempts.
        """
        self.llm = llm or ChatOllama(
            base_url="http://hx-ollama1-server.hx.dev.local:11434",
            model="gemma3:27b",
            temperature=0.7,
            num_ctx=65536  # 64KB context for RAG (CAIO decision)
        )
        self.lightrag_url = lightrag_url.rstrip("/")
        self.default_mode = default_mode
        self.min_context_length = min_context_length
        self.max_iterations = max_iterations

    async def _query_lightrag(
        self,
        query: str,
        mode: LightRAGMode = "hybrid"
    ) -> str:
        """
        Query LightRAG for relevant context.

        Args:
            query: Search query.
            mode: Query mode (local, global, hybrid, mix).

        Returns:
            Retrieved context string.
        """
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.lightrag_url}/query",
                    json={
                        "query": query,
                        "mode": mode,
                        "top_k": 5
                    },
                    timeout=30.0
                )
                response.raise_for_status()

                data = response.json()
                # LightRAG returns context in 'result' or 'response' field
                context = data.get("result", data.get("response", ""))
                return context if isinstance(context, str) else str(context)

        except httpx.HTTPError as e:
            # Return empty context on HTTP errors
            return f"[RAG retrieval failed: {str(e)}]"
        except Exception as e:
            return f"[RAG error: {str(e)}]"

    async def _adaptive_retrieve(
        self,
        query: str,
        mode: LightRAGMode = "hybrid"
    ) -> str:
        """
        Perform adaptive retrieval with iteration.

        If initial retrieval returns insufficient context,
        try alternative modes.

        Args:
            query: Search query.
            mode: Initial query mode.

        Returns:
            Best retrieved context.
        """
        # Try initial mode
        context = await self._query_lightrag(query, mode)

        if len(context) >= self.min_context_length:
            return context

        # Try alternative modes if initial insufficient
        alternative_modes: list[LightRAGMode] = ["mix", "global", "local"]
        for alt_mode in alternative_modes:
            if alt_mode == mode:
                continue

            alt_context = await self._query_lightrag(query, alt_mode)
            if len(alt_context) > len(context):
                context = alt_context

            if len(context) >= self.min_context_length:
                break

        return context

    async def _generate_response(
        self,
        query: str,
        context: str,
        messages: list
    ) -> str:
        """
        Generate response using Ollama1 with RAG context.

        Args:
            query: User query.
            context: Retrieved RAG context.
            messages: Conversation history.

        Returns:
            Generated response string.
        """
        # Build prompt with context
        system_message = SystemMessage(content=self.RAG_PROMPT.format(context=context))
        user_message = HumanMessage(content=query)

        prompt_messages = [system_message] + messages[:-1] + [user_message]

        try:
            response = await self.llm.ainvoke(prompt_messages)
            return response.content
        except Exception as e:
            return f"[RAG generation error: {str(e)}]"

    async def __call__(self, state: AgentState) -> AgentState:
        """
        Process state as a LangGraph node.

        Args:
            state: Current agent state.

        Returns:
            Updated agent state with RAG response.
        """
        # Get the latest user message
        if not state["messages"]:
            return state

        last_message = state["messages"][-1]
        if not isinstance(last_message, HumanMessage):
            query = "Please help me with my question."
        else:
            query = last_message.content

        # Perform adaptive retrieval
        context = await self._adaptive_retrieve(query, self.default_mode)

        # Generate response with context
        response_text = await self._generate_response(
            query=query,
            context=context,
            messages=state["messages"]
        )

        # Create response message
        response = AIMessage(content=response_text)

        # Return updated state
        return {
            **state,
            "messages": state["messages"] + [response],
            "rag_context": context,
            "current_worker": "rag_agent"
        }


def create_rag_agent(
    llm: Optional[ChatOllama] = None,
    lightrag_url: str = "http://hx-literag-server.hx.dev.local:8020",
    default_mode: LightRAGMode = "hybrid"
) -> RAGAgentWorker:
    """
    Factory function to create RAG agent worker.

    Args:
        llm: Optional ChatOllama for Ollama1.
        lightrag_url: LightRAG service URL.
        default_mode: Default query mode.

    Returns:
        Configured RAGAgentWorker instance.
    """
    return RAGAgentWorker(
        llm=llm,
        lightrag_url=lightrag_url,
        default_mode=default_mode
    )
```

### Step 3: Update Workers Package

Update `/opt/hx-lang-server/app/agents/workers/__init__.py`:

```python
"""Worker agents for hx-lang-server."""

from .rag_agent import RAGAgentWorker, create_rag_agent

__all__ = [
    "RAGAgentWorker",
    "create_rag_agent"
]
```

### Step 4: Update Agents Package

Update `/opt/hx-lang-server/app/agents/__init__.py`:

```python
"""Agents module for hx-lang-server."""

from .supervisor import SupervisorAgent, create_supervisor
from .workers.rag_agent import RAGAgentWorker, create_rag_agent

__all__ = [
    "SupervisorAgent",
    "create_supervisor",
    "RAGAgentWorker",
    "create_rag_agent"
]
```

### Step 5: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.agents.workers.rag_agent import RAGAgentWorker, create_rag_agent

# Test instantiation
worker = create_rag_agent()
print(f'RAG Agent Worker created')
print(f'LLM: {worker.llm.model}')
print(f'LightRAG URL: {worker.lightrag_url}')
print(f'Default Mode: {worker.default_mode}')
print('\nRAG Agent Worker implementation verified!')
"
```

---

## Code Structure

```
/opt/hx-lang-server/
├── app/
│   ├── __init__.py
│   ├── core/
│   │   └── ...
│   └── agents/
│       ├── __init__.py
│       ├── supervisor.py
│       └── workers/
│           ├── __init__.py
│           └── rag_agent.py    # RAG Agent (this task)
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| RAG Agent module | `/opt/hx-lang-server/app/agents/workers/rag_agent.py` | RAGAgentWorker implementation |
| Workers package | `/opt/hx-lang-server/app/agents/workers/__init__.py` | Worker exports |

---

## Verification Steps

- [ ] `rag_agent.py` file exists at correct location
- [ ] RAGAgentWorker can be imported
- [ ] Worker can be instantiated without errors
- [ ] LLM configuration targets Ollama1
- [ ] Context size is 64KB per CAIO decision

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.agents.workers.rag_agent import create_rag_agent; print('RAG Agent imports OK')"

# Configuration verification
python -c "
from app.agents.workers.rag_agent import create_rag_agent

w = create_rag_agent()
assert w.llm.model == 'gemma3:27b', 'Wrong model'
assert 'ollama1' in w.llm.base_url, 'Wrong Ollama server'
assert w.llm.num_ctx == 65536, 'Wrong context size'
print('RAG Agent configuration: PASS')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/agents/workers/rag_agent.py
# Update __init__.py files to remove rag_agent exports
```

---

## Notes

- RAG Agent routes to Ollama1 (hx-ollama1-server) per FR-010
- Integrates with LightRAG via HTTP API per FR-014
- Supports adaptive retrieval with iteration per FR-015
- Supports all LightRAG query modes per FR-016
- 64KB context size for RAG operations (CAIO decision)
- LightRAG integration tested in Work Stream 8 (Andy)
- Connection to Ollama tested in Work Stream 7 (Jim)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
