# Task: Configure Ollama1 (General) Connection

**Task ID:** hx-lang-server-task-071-configure-ollama1-general-connection
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:** hx-lang-server-task-023 (langchain-ollama installed)
**Estimated Time:** 30 minutes

---

## Objective

Configure the connection to hx-ollama1-server for general-purpose LLM queries. This server hosts gemma3:27b and handles general queries, RAG queries, and tool queries as defined in the Ollama Routing Table.

---

## Prerequisites

- [ ] langchain-ollama>=0.2.0 installed (Task 023)
- [ ] Virtual environment activated at /opt/hx-lang-server/venv
- [ ] hx-ollama1-server.hx.dev.local:11434 is reachable from hx-lang-server
- [ ] gemma3:27b model is deployed on hx-ollama1-server

---

## Specification References

From node-spec.md (v2.1):
- **FR-010**: Service MUST route general queries to hx-ollama1-server.hx.dev.local
- **Ollama Routing Table**: general, rag, tool queries route to hx-ollama1-server with gemma3:27b

---

## Steps

### Step 1: Verify Ollama1 Server Connectivity

```bash
# From hx-lang-server.hx.dev.local
# Test DNS resolution
nslookup hx-ollama1-server.hx.dev.local

# Test HTTP connectivity
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | head -20

# Verify gemma3:27b model is available
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | grep -i gemma3
```

**Expected Output:**
- DNS resolves to 192.168.10.204
- API returns JSON with model list
- gemma3:27b appears in model list

### Step 2: Create Ollama Client Module

Create file `/opt/hx-lang-server/app/llm/ollama_general.py`:

```python
"""
Ollama General Client Module

Configures connection to hx-ollama1-server for general-purpose queries.
Handles: general, rag, and tool query types.
"""

from langchain_ollama import ChatOllama
from typing import Optional
import structlog

logger = structlog.get_logger(__name__)

# Configuration constants
OLLAMA_GENERAL_HOST = "hx-ollama1-server.hx.dev.local"
OLLAMA_GENERAL_PORT = 11434
OLLAMA_GENERAL_MODEL = "gemma3:27b"
OLLAMA_GENERAL_URL = f"http://{OLLAMA_GENERAL_HOST}:{OLLAMA_GENERAL_PORT}"


def create_general_llm(
    temperature: float = 0.7,
    num_ctx: int = 8192,  # 8KB default for general queries
    timeout: Optional[float] = 60.0,
) -> ChatOllama:
    """
    Create a ChatOllama instance for general-purpose queries.

    Args:
        temperature: Sampling temperature (0.0-1.0)
        num_ctx: Context window size in tokens
        timeout: Request timeout in seconds

    Returns:
        Configured ChatOllama instance
    """
    logger.info(
        "creating_general_llm",
        host=OLLAMA_GENERAL_HOST,
        model=OLLAMA_GENERAL_MODEL,
        num_ctx=num_ctx,
    )

    return ChatOllama(
        base_url=OLLAMA_GENERAL_URL,
        model=OLLAMA_GENERAL_MODEL,
        temperature=temperature,
        num_ctx=num_ctx,
        timeout=timeout,
    )


def create_rag_llm(
    temperature: float = 0.3,
    timeout: Optional[float] = 120.0,
) -> ChatOllama:
    """
    Create a ChatOllama instance for RAG queries.

    Uses 64KB context window per CAIO decision for entity extraction
    and complex retrieval-augmented generation.

    Args:
        temperature: Lower temperature for factual responses
        timeout: Extended timeout for RAG processing

    Returns:
        Configured ChatOllama instance with 64KB context
    """
    # CAIO Decision: 64KB context for RAG operations
    RAG_CONTEXT_SIZE = 65536  # 64KB

    logger.info(
        "creating_rag_llm",
        host=OLLAMA_GENERAL_HOST,
        model=OLLAMA_GENERAL_MODEL,
        num_ctx=RAG_CONTEXT_SIZE,
    )

    return ChatOllama(
        base_url=OLLAMA_GENERAL_URL,
        model=OLLAMA_GENERAL_MODEL,
        temperature=temperature,
        num_ctx=RAG_CONTEXT_SIZE,
        timeout=timeout,
    )


def create_tool_llm(
    temperature: float = 0.5,
    num_ctx: int = 8192,  # 8KB for tool queries
    timeout: Optional[float] = 60.0,
) -> ChatOllama:
    """
    Create a ChatOllama instance for tool invocation queries.

    Args:
        temperature: Moderate temperature for tool selection
        num_ctx: Context window size
        timeout: Request timeout

    Returns:
        Configured ChatOllama instance
    """
    logger.info(
        "creating_tool_llm",
        host=OLLAMA_GENERAL_HOST,
        model=OLLAMA_GENERAL_MODEL,
        num_ctx=num_ctx,
    )

    return ChatOllama(
        base_url=OLLAMA_GENERAL_URL,
        model=OLLAMA_GENERAL_MODEL,
        temperature=temperature,
        num_ctx=num_ctx,
        timeout=timeout,
    )
```

### Step 3: Add Environment Variables

Add to `/opt/hx-lang-server/.env`:

```bash
# Ollama General Configuration (hx-ollama1-server)
OLLAMA_GENERAL_URL=http://hx-ollama1-server.hx.dev.local:11434
OLLAMA_GENERAL_MODEL=gemma3:27b
OLLAMA_GENERAL_TIMEOUT=60
```

### Step 4: Update Settings Module

Add to `/opt/hx-lang-server/app/config/settings.py`:

```python
# Ollama General Settings
ollama_general_url: str = "http://hx-ollama1-server.hx.dev.local:11434"
ollama_general_model: str = "gemma3:27b"
ollama_general_timeout: float = 60.0
```

### Step 5: Test General LLM Connection

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Test via Python
python3 << 'EOF'
from langchain_ollama import ChatOllama

llm = ChatOllama(
    base_url="http://hx-ollama1-server.hx.dev.local:11434",
    model="gemma3:27b",
    temperature=0.7,
    num_ctx=8192,
)

response = llm.invoke("What is 2 + 2?")
print(f"Response: {response.content}")
print("SUCCESS: Ollama1 general connection working")
EOF
```

**Expected Output:**
- Response contains "4" or explanation
- "SUCCESS" message printed

---

## Acceptance Criteria

- [ ] DNS resolution for hx-ollama1-server.hx.dev.local works from hx-lang-server
- [ ] HTTP connectivity to port 11434 confirmed
- [ ] gemma3:27b model verified available on server
- [ ] ollama_general.py module created with create_general_llm, create_rag_llm, create_tool_llm functions
- [ ] Environment variables configured in .env
- [ ] Settings module updated with Ollama general configuration
- [ ] Test query returns valid response from gemma3:27b
- [ ] No hardcoded IP addresses (hostnames only)

---

## Verification Commands

```bash
# Verify module exists
ls -la /opt/hx-lang-server/app/llm/ollama_general.py

# Verify environment variables
grep OLLAMA_GENERAL /opt/hx-lang-server/.env

# Test API connectivity
curl -s http://hx-ollama1-server.hx.dev.local:11434/api/tags | jq '.models[] | select(.name | contains("gemma3"))'
```

---

## Rollback Procedure

1. Remove ollama_general.py module
2. Remove OLLAMA_GENERAL_* environment variables from .env
3. Revert settings.py changes

---

## Related Tasks

- **Task 072:** Configure Ollama2 (code) connection
- **Task 073:** Configure 64KB context for RAG operations
- **Task 075:** Implement model routing based on query classification

---

## Notes

- hx-ollama1-server (192.168.10.204) hosts general-purpose models
- gemma3:27b is the primary model (17GB VRAM)
- Context sizes: 8KB for general/tool, 64KB for RAG (CAIO decision)
- All external service references use hostnames, not IP addresses

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
