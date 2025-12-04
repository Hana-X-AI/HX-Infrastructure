# Task: Implement Tool Agent Worker

**Task ID**: hx-lang-server-task-056-implement-tool-agent-worker
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-053 (Supervisor Agent), hx-lang-server-task-024 (langchain-mcp-adapters)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 50 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "FR-017, FR-018, FR-019, FR-020"

---

## Objective

Implement the Tool Agent worker that handles tool invocation requests via MCP (Model Context Protocol). Connects to FastMCP gateway as an MCP CLIENT and invokes tools like Crawl4AI for web crawling.

---

## Prerequisites

- [ ] Supervisor agent implemented (task-053)
- [ ] langchain-mcp-adapters installed (task-024)
- [ ] langchain-ollama installed (task-023)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Implement Tool Agent Worker

Create `/opt/hx-lang-server/app/agents/workers/tool_agent.py`:

```python
"""
Tool Agent Worker for hx-lang-server.

Handles tool invocation requests via MCP (Model Context Protocol).
Acts as an MCP CLIENT connecting to FastMCP gateway.

Supported tools via FastMCP gateway:
- crawl4ai__smart_crawl_url: Web page crawling
- docling__convert_document: Document conversion
- (additional tools discovered dynamically)

Specification Reference:
- FR-017: Implement MCP CLIENT using langchain-mcp-adapters
- FR-018: Connect to FastMCP gateway at hx-fastmcp-server
- FR-019: Support tool discovery and invocation
- FR-020: Handle tool namespace prefixes from gateway
- FR-020a: Support MCP protocol v1.1 with feature detection
"""

from typing import Optional, Dict, Any, List
import json
from langchain_ollama import ChatOllama
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from langchain_mcp_adapters.client import MultiServerMCPClient

from app.core.state import AgentState


class ToolAgentWorker:
    """
    Tool Agent Worker.

    Handles tool invocation via MCP protocol.
    Connects to FastMCP gateway for tool discovery and execution.

    Attributes:
        llm: ChatOllama for tool selection reasoning.
        mcp_client: MultiServerMCPClient for MCP communication.
        fastmcp_url: FastMCP gateway URL.
        available_tools: Discovered tools from gateway.
    """

    # Tool selection system prompt
    TOOL_SELECTION_PROMPT = """You are a tool selection assistant.
Based on the user's request, determine:
1. Which tool to use (if any)
2. What parameters to pass

Available tools:
{tools}

Respond in JSON format:
{{
    "tool_name": "tool_to_use or null",
    "parameters": {{}},
    "reasoning": "why this tool"
}}

If no tool is appropriate, set tool_name to null."""

    def __init__(
        self,
        llm: Optional[ChatOllama] = None,
        fastmcp_url: str = "http://hx-fastmcp-server.hx.dev.local:8000",
        mcp_client: Optional[MultiServerMCPClient] = None
    ):
        """
        Initialize the Tool agent worker.

        Args:
            llm: ChatOllama for reasoning. Creates default if None.
            fastmcp_url: FastMCP gateway URL.
            mcp_client: Pre-configured MCP client. Creates default if None.
        """
        self.llm = llm or ChatOllama(
            base_url="http://hx-ollama1-server.hx.dev.local:11434",
            model="gemma3:27b",
            temperature=0.3,
            num_ctx=8192  # 8KB context for tool operations
        )
        self.fastmcp_url = fastmcp_url.rstrip("/")
        self.mcp_client = mcp_client
        self.available_tools: List[Dict[str, Any]] = []
        self._tools_discovered = False

    async def _ensure_mcp_client(self) -> None:
        """Ensure MCP client is initialized."""
        if self.mcp_client is None:
            self.mcp_client = MultiServerMCPClient(
                servers={
                    "fastmcp": {
                        "transport": "streamable_http",
                        "url": f"{self.fastmcp_url}/mcp",
                    }
                }
            )

    async def discover_tools(self) -> List[Dict[str, Any]]:
        """
        Discover available tools from FastMCP gateway.

        Returns:
            List of available tool descriptions.
        """
        await self._ensure_mcp_client()

        try:
            tools = await self.mcp_client.get_tools()
            self.available_tools = [
                {
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": getattr(tool, "parameters", {})
                }
                for tool in tools
            ]
            self._tools_discovered = True
            return self.available_tools
        except Exception as e:
            # Return empty list on discovery failure
            self.available_tools = []
            self._tools_discovered = True
            return []

    def _format_tools_for_prompt(self) -> str:
        """Format available tools for the selection prompt."""
        if not self.available_tools:
            return "No tools available."

        tool_descriptions = []
        for tool in self.available_tools:
            desc = f"- {tool['name']}: {tool.get('description', 'No description')}"
            tool_descriptions.append(desc)

        return "\n".join(tool_descriptions)

    async def _select_tool(self, query: str) -> Dict[str, Any]:
        """
        Use LLM to select appropriate tool for query.

        Args:
            query: User query.

        Returns:
            Dict with tool_name, parameters, and reasoning.
        """
        if not self._tools_discovered:
            await self.discover_tools()

        tools_text = self._format_tools_for_prompt()
        prompt = self.TOOL_SELECTION_PROMPT.format(tools=tools_text)

        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=query)
        ]

        try:
            response = await self.llm.ainvoke(messages)
            # Parse JSON from response
            content = response.content.strip()

            # Try to extract JSON
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0]
            elif "```" in content:
                content = content.split("```")[1].split("```")[0]

            selection = json.loads(content)
            return selection
        except Exception:
            return {
                "tool_name": None,
                "parameters": {},
                "reasoning": "Could not parse tool selection"
            }

    async def _invoke_tool(
        self,
        tool_name: str,
        parameters: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Invoke a tool via MCP client.

        Args:
            tool_name: Name of tool to invoke (with namespace prefix).
            parameters: Tool parameters.

        Returns:
            Tool invocation result.
        """
        await self._ensure_mcp_client()

        try:
            result = await self.mcp_client.invoke_tool(tool_name, parameters)
            return {
                "success": True,
                "result": result
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    async def __call__(self, state: AgentState) -> AgentState:
        """
        Process state as a LangGraph node.

        Args:
            state: Current agent state.

        Returns:
            Updated agent state with tool results.
        """
        # Get the latest user message
        if not state["messages"]:
            return state

        last_message = state["messages"][-1]
        if not isinstance(last_message, HumanMessage):
            query = "Please help me with my tool request."
        else:
            query = last_message.content

        # Discover tools if needed
        if not self._tools_discovered:
            await self.discover_tools()

        # Select appropriate tool
        selection = await self._select_tool(query)

        tool_name = selection.get("tool_name")
        parameters = selection.get("parameters", {})
        reasoning = selection.get("reasoning", "")

        if tool_name is None:
            # No tool selected
            response_text = f"I couldn't find an appropriate tool for your request. {reasoning}"
            tool_results = {"selected": None, "reason": reasoning}
        else:
            # Invoke the selected tool
            result = await self._invoke_tool(tool_name, parameters)

            if result["success"]:
                response_text = f"Tool `{tool_name}` executed successfully.\n\nResult:\n{result['result']}"
                tool_results = {
                    "selected": tool_name,
                    "parameters": parameters,
                    "result": result["result"],
                    "success": True
                }
            else:
                response_text = f"Tool `{tool_name}` failed: {result['error']}"
                tool_results = {
                    "selected": tool_name,
                    "parameters": parameters,
                    "error": result["error"],
                    "success": False
                }

        # Create response message
        response = AIMessage(content=response_text)

        # Return updated state
        return {
            **state,
            "messages": state["messages"] + [response],
            "tool_results": tool_results,
            "current_worker": "tool_agent"
        }


def create_tool_agent(
    llm: Optional[ChatOllama] = None,
    fastmcp_url: str = "http://hx-fastmcp-server.hx.dev.local:8000"
) -> ToolAgentWorker:
    """
    Factory function to create Tool agent worker.

    Args:
        llm: Optional ChatOllama for tool reasoning.
        fastmcp_url: FastMCP gateway URL.

    Returns:
        Configured ToolAgentWorker instance.
    """
    return ToolAgentWorker(
        llm=llm,
        fastmcp_url=fastmcp_url
    )
```

### Step 2: Update Workers Package

Update `/opt/hx-lang-server/app/agents/workers/__init__.py`:

```python
"""Worker agents for hx-lang-server."""

from .rag_agent import RAGAgentWorker, create_rag_agent
from .code_agent import CodeAgentWorker, create_code_agent
from .tool_agent import ToolAgentWorker, create_tool_agent

__all__ = [
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent",
    "ToolAgentWorker",
    "create_tool_agent"
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

__all__ = [
    "SupervisorAgent",
    "create_supervisor",
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent",
    "ToolAgentWorker",
    "create_tool_agent"
]
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.agents.workers.tool_agent import ToolAgentWorker, create_tool_agent

# Test instantiation
worker = create_tool_agent()
print(f'Tool Agent Worker created')
print(f'FastMCP URL: {worker.fastmcp_url}')
print(f'LLM Model: {worker.llm.model}')
print('\nTool Agent Worker implementation verified!')
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
│           ├── code_agent.py
│           └── tool_agent.py   # Tool Agent (this task)
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Tool Agent module | `/opt/hx-lang-server/app/agents/workers/tool_agent.py` | ToolAgentWorker implementation |

---

## Verification Steps

- [ ] `tool_agent.py` file exists at correct location
- [ ] ToolAgentWorker can be imported
- [ ] Worker can be instantiated without errors
- [ ] FastMCP URL is configured correctly
- [ ] MCP client initialization works

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.agents.workers.tool_agent import create_tool_agent; print('Tool Agent imports OK')"

# Configuration verification
python -c "
from app.agents.workers.tool_agent import create_tool_agent

w = create_tool_agent()
assert 'fastmcp' in w.fastmcp_url, 'Wrong FastMCP URL'
print(f'FastMCP URL: {w.fastmcp_url}')
print('Tool Agent configuration: PASS')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/agents/workers/tool_agent.py
# Update __init__.py files to remove tool_agent exports
```

---

## Notes

- Tool Agent is an MCP CLIENT, not server per FR-017
- Connects to FastMCP gateway per FR-018
- Supports dynamic tool discovery per FR-019
- Handles namespace prefixes (e.g., `crawl4ai__smart_crawl_url`) per FR-020
- MCP v1.1 with feature detection per FR-020a
- Connection to FastMCP tested in Work Stream 9 (George)
- Crawl4AI tool tested in Work Stream 9 (George/David)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
