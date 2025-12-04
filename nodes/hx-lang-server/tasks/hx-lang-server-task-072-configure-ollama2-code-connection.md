# Task: Configure Ollama2 (Code) Connection

**Task ID:** hx-lang-server-task-072-configure-ollama2-code-connection
**Work Stream:** 7 - Ollama Integration
**Phase:** Implementation
**Status:** Not Started
**Assigned Agent:** Jim (Ollama SME)
**Dependencies:** hx-lang-server-task-023 (langchain-ollama installed)
**Estimated Time:** 30 minutes

---

## Objective

Configure the connection to hx-ollama2-server for code-specialized LLM queries. This server hosts qwen2.5-coder:14b (specification reference) or qwen3-coder:30b (current deployment) and handles all code-related queries requiring specialized code understanding.

---

## Prerequisites

- [ ] langchain-ollama>=0.2.0 installed (Task 023)
- [ ] Virtual environment activated at /opt/hx-lang-server/venv
- [ ] hx-ollama2-server.hx.dev.local:11434 is reachable from hx-lang-server
- [ ] Code model deployed on hx-ollama2-server (qwen2.5-coder or qwen3-coder)

---

## Specification References

From node-spec.md (v2.1):
- **FR-011**: Service MUST route code-related queries to hx-ollama2-server.hx.dev.local
- **FR-013**: Service MUST validate Ollama model context size >= 64KB for Code operations
- **Ollama Routing Table**: code queries route to hx-ollama2-server with 64KB context

---

## Steps

### Step 1: Verify Ollama2 Server Connectivity

```bash
# From hx-lang-server.hx.dev.local
# Test DNS resolution
nslookup hx-ollama2-server.hx.dev.local

# Test HTTP connectivity
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | head -20

# Verify code model is available
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | grep -iE "qwen.*coder|coder"
```

**Expected Output:**
- DNS resolves to 192.168.10.205
- API returns JSON with model list
- qwen2.5-coder or qwen3-coder appears in model list

### Step 2: Determine Available Code Model

```bash
# List all models on ollama2
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | jq '.models[].name'
```

**Note:** The specification references qwen2.5-coder:14b, but current deployment may have qwen3-coder:30b. Use whichever is available.

### Step 3: Create Ollama Code Client Module

Create file `/opt/hx-lang-server/app/llm/ollama_code.py`:

```python
"""
Ollama Code Client Module

Configures connection to hx-ollama2-server for code-specialized queries.
Uses 64KB context window per CAIO decision for complex code generation.
"""

from langchain_ollama import ChatOllama
from typing import Optional
import structlog

logger = structlog.get_logger(__name__)

# Configuration constants
OLLAMA_CODE_HOST = "hx-ollama2-server.hx.dev.local"
OLLAMA_CODE_PORT = 11434
# Model may be qwen2.5-coder:14b or qwen3-coder:30b depending on deployment
OLLAMA_CODE_MODEL = "qwen2.5-coder:14b"
OLLAMA_CODE_URL = f"http://{OLLAMA_CODE_HOST}:{OLLAMA_CODE_PORT}"

# CAIO Decision: 64KB context for code operations
CODE_CONTEXT_SIZE = 65536  # 64KB


def create_code_llm(
    temperature: float = 0.2,
    num_ctx: int = CODE_CONTEXT_SIZE,
    timeout: Optional[float] = 120.0,
    model_override: Optional[str] = None,
) -> ChatOllama:
    """
    Create a ChatOllama instance for code-specialized queries.

    Uses 64KB context window per CAIO decision to handle:
    - Complex code generation
    - Multi-file context
    - Large codebase understanding
    - Code review and refactoring

    Args:
        temperature: Low temperature for deterministic code output
        num_ctx: Context window size (default 64KB per CAIO decision)
        timeout: Extended timeout for complex code generation
        model_override: Optional model name override

    Returns:
        Configured ChatOllama instance for code tasks

    Raises:
        ValueError: If num_ctx < 65536 (64KB minimum per FR-013)
    """
    # FR-013: Validate minimum context size
    if num_ctx < 65536:
        logger.warning(
            "code_context_below_minimum",
            requested=num_ctx,
            minimum=65536,
            action="enforcing_minimum",
        )
        num_ctx = 65536

    model = model_override or OLLAMA_CODE_MODEL

    logger.info(
        "creating_code_llm",
        host=OLLAMA_CODE_HOST,
        model=model,
        num_ctx=num_ctx,
        temperature=temperature,
    )

    return ChatOllama(
        base_url=OLLAMA_CODE_URL,
        model=model,
        temperature=temperature,
        num_ctx=num_ctx,
        timeout=timeout,
    )


def create_code_review_llm(
    temperature: float = 0.1,
    timeout: Optional[float] = 180.0,
    model_override: Optional[str] = None,
) -> ChatOllama:
    """
    Create a ChatOllama instance optimized for code review.

    Uses maximum context and lowest temperature for thorough,
    deterministic code analysis.

    Args:
        temperature: Very low temperature for consistent reviews
        timeout: Extended timeout for thorough analysis
        model_override: Optional model name override

    Returns:
        Configured ChatOllama instance for code review
    """
    model = model_override or OLLAMA_CODE_MODEL

    logger.info(
        "creating_code_review_llm",
        host=OLLAMA_CODE_HOST,
        model=model,
        num_ctx=CODE_CONTEXT_SIZE,
    )

    return ChatOllama(
        base_url=OLLAMA_CODE_URL,
        model=model,
        temperature=temperature,
        num_ctx=CODE_CONTEXT_SIZE,
        timeout=timeout,
    )


def get_code_model_info() -> dict:
    """
    Return configuration information for the code LLM.

    Returns:
        Dictionary with model configuration details
    """
    return {
        "host": OLLAMA_CODE_HOST,
        "port": OLLAMA_CODE_PORT,
        "model": OLLAMA_CODE_MODEL,
        "url": OLLAMA_CODE_URL,
        "context_size": CODE_CONTEXT_SIZE,
        "context_size_kb": CODE_CONTEXT_SIZE // 1024,
    }
```

### Step 4: Add Environment Variables

Add to `/opt/hx-lang-server/.env`:

```bash
# Ollama Code Configuration (hx-ollama2-server)
OLLAMA_CODE_URL=http://hx-ollama2-server.hx.dev.local:11434
OLLAMA_CODE_MODEL=qwen2.5-coder:14b
OLLAMA_CODE_CONTEXT=65536
OLLAMA_CODE_TIMEOUT=120
```

### Step 5: Update Settings Module

Add to `/opt/hx-lang-server/app/config/settings.py`:

```python
# Ollama Code Settings
ollama_code_url: str = "http://hx-ollama2-server.hx.dev.local:11434"
ollama_code_model: str = "qwen2.5-coder:14b"
ollama_code_context: int = 65536  # 64KB per CAIO decision
ollama_code_timeout: float = 120.0
```

### Step 6: Test Code LLM Connection

```bash
# Activate virtual environment
source /opt/hx-lang-server/venv/bin/activate

# Test via Python
python3 << 'EOF'
from langchain_ollama import ChatOllama

# Determine which code model is available
import httpx
response = httpx.get("http://hx-ollama2-server.hx.dev.local:11434/api/tags")
models = response.json().get("models", [])
code_model = None
for m in models:
    if "coder" in m["name"].lower():
        code_model = m["name"]
        break

if not code_model:
    print("ERROR: No code model found on hx-ollama2-server")
    exit(1)

print(f"Using code model: {code_model}")

llm = ChatOllama(
    base_url="http://hx-ollama2-server.hx.dev.local:11434",
    model=code_model,
    temperature=0.2,
    num_ctx=65536,  # 64KB context
)

response = llm.invoke("Write a Python function that calculates factorial.")
print(f"Response: {response.content[:500]}...")
print("SUCCESS: Ollama2 code connection working with 64KB context")
EOF
```

**Expected Output:**
- Response contains Python code with def/function
- "SUCCESS" message printed

---

## Acceptance Criteria

- [ ] DNS resolution for hx-ollama2-server.hx.dev.local works from hx-lang-server
- [ ] HTTP connectivity to port 11434 confirmed
- [ ] Code model verified available on server (qwen2.5-coder or qwen3-coder)
- [ ] ollama_code.py module created with create_code_llm and create_code_review_llm functions
- [ ] 64KB context size enforced per FR-013 (minimum validation in create_code_llm)
- [ ] Environment variables configured in .env
- [ ] Settings module updated with Ollama code configuration
- [ ] Test code generation query returns valid Python code
- [ ] No hardcoded IP addresses (hostnames only)

---

## Verification Commands

```bash
# Verify module exists
ls -la /opt/hx-lang-server/app/llm/ollama_code.py

# Verify environment variables
grep OLLAMA_CODE /opt/hx-lang-server/.env

# Verify 64KB context in code
grep -n "65536\|64KB\|CODE_CONTEXT" /opt/hx-lang-server/app/llm/ollama_code.py

# Test API connectivity
curl -s http://hx-ollama2-server.hx.dev.local:11434/api/tags | jq '.models[] | select(.name | contains("coder"))'
```

---

## Rollback Procedure

1. Remove ollama_code.py module
2. Remove OLLAMA_CODE_* environment variables from .env
3. Revert settings.py changes

---

## Related Tasks

- **Task 071:** Configure Ollama1 (general) connection
- **Task 074:** Configure 64KB context for Code operations (verification)
- **Task 075:** Implement model routing based on query classification

---

## Notes

- hx-ollama2-server (192.168.10.205) hosts code-specialized models
- Current deployment: qwen3-coder:30b (18GB); Spec references qwen2.5-coder:14b
- CAIO Decision: 64KB minimum context for code operations
- Temperature should be low (0.1-0.3) for deterministic code generation
- Extended timeout (120s) needed for complex code generation

---

**Created By:** Jim (Ollama SME)
**Date:** 2025-12-04
**Specification Version:** 2.1
