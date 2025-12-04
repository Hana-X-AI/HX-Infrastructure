# Task: Install HTTP Client Packages

**Task ID**: hx-lang-server-task-025-install-http-client-packages
**Phase**: Installation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-021 (LangGraph Framework)
**Work Stream**: 3 - Core Framework Installation
**Estimated Time**: 10 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Python Dependencies"

---

## Objective

Install httpx and aiohttp packages for async HTTP client capabilities. These are required for communication with external services (LightRAG, Ollama health checks, webhook callbacks).

---

## Prerequisites

- [ ] Virtual environment active at `/opt/hx-lang-server/venv`
- [ ] Network connectivity to PyPI
- [ ] LangGraph installed (task-021) - establishes base environment

---

## Implementation Steps

### Step 1: Activate Virtual Environment

```bash
source /opt/hx-lang-server/venv/bin/activate
```

### Step 2: Install httpx

```bash
pip install "httpx>=0.27.0"
```

### Step 3: Install aiohttp

```bash
pip install "aiohttp>=3.10.0"
```

### Step 4: Verify Installations

```bash
pip show httpx
pip show aiohttp
python -c "import httpx; import aiohttp; print('HTTP clients imported successfully')"
```

---

## Code Patterns Reference

HTTP client usage patterns for hx-lang-server:

```python
import httpx
import aiohttp

# httpx - Primary async HTTP client (LightRAG, health checks)
async def check_lightrag_health():
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "http://hx-literag-server.hx.dev.local:8020/health",
            timeout=5.0
        )
        return response.json()

# httpx - POST request to LightRAG
async def query_lightrag(query: str, mode: str = "hybrid"):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://hx-literag-server.hx.dev.local:8020/query",
            json={"query": query, "mode": mode},
            timeout=30.0
        )
        return response.json()

# aiohttp - Webhook callbacks (n8n integration)
async def send_webhook_callback(callback_url: str, result: dict):
    async with aiohttp.ClientSession() as session:
        async with session.post(callback_url, json=result) as response:
            return response.status

# httpx with retry pattern
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
async def fetch_with_retry(url: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(url, timeout=10.0)
        response.raise_for_status()
        return response.json()
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| httpx package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/httpx/` | Async HTTP client |
| aiohttp package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/aiohttp/` | Async HTTP client |

---

## Verification Steps

- [ ] `pip show httpx` returns version 0.27.x or higher
- [ ] `pip show aiohttp` returns version 3.10.x or higher
- [ ] Both packages import without error
- [ ] Async client can be instantiated

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate

# Version checks
pip show httpx | grep -E "^(Name|Version):"
pip show aiohttp | grep -E "^(Name|Version):"

# Import and instantiation verification
python -c "
import httpx
import aiohttp
import asyncio

async def test_clients():
    # Test httpx client
    async with httpx.AsyncClient() as client:
        print(f'httpx AsyncClient: {type(client).__name__}')

    # Test aiohttp session
    async with aiohttp.ClientSession() as session:
        print(f'aiohttp ClientSession: {type(session).__name__}')

    print('Both HTTP clients verified')

asyncio.run(test_clients())
"
```

---

## Rollback Procedure

```bash
source /opt/hx-lang-server/venv/bin/activate
pip uninstall httpx aiohttp -y
pip cache purge
```

---

## Notes

- httpx v0.27.x provides modern async HTTP with HTTP/2 support
- aiohttp v3.10.x used primarily for webhook callbacks (n8n integration)
- Both support async context managers for proper connection handling
- Timeouts should always be specified to prevent hanging requests
- Used by: LightRAG client (Work Stream 8), Ollama health checks (Work Stream 7), n8n webhooks (Work Stream 11)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
