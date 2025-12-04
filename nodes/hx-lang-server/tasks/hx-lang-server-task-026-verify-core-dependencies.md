# Task: Verify Core Framework Dependencies

**Task ID**: hx-lang-server-task-026-verify-core-dependencies
**Phase**: Installation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-021, task-022, task-023, task-024, task-025
**Work Stream**: 3 - Core Framework Installation
**Estimated Time**: 15 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Python Dependencies"

---

## Objective

Verify all core framework dependencies are correctly installed with compatible versions and can work together. This task validates the complete Work Stream 3 installation before proceeding to integration work streams.

---

## Prerequisites

- [ ] LangGraph v0.3.x installed (task-021)
- [ ] LangChain v0.3.x installed (task-022)
- [ ] langchain-ollama v0.2.x installed (task-023)
- [ ] langchain-mcp-adapters v0.1.x installed (task-024)
- [ ] httpx and aiohttp installed (task-025)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Activate Virtual Environment

```bash
source /opt/hx-lang-server/venv/bin/activate
```

### Step 2: Generate Requirements Snapshot

```bash
pip freeze > /opt/hx-lang-server/requirements-core-framework.txt
```

### Step 3: Run Comprehensive Import Test

```bash
python -c "
# Core Framework Import Verification
print('=' * 60)
print('HX-LANG-SERVER CORE FRAMEWORK VERIFICATION')
print('=' * 60)

# LangGraph
print('\n[1/5] LangGraph...')
import langgraph
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import create_react_agent
print(f'  Version: {langgraph.__version__}')
print('  Imports: StateGraph, START, END, add_messages, create_react_agent')

# LangChain
print('\n[2/5] LangChain...')
import langchain
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough
print(f'  Version: {langchain.__version__}')
print('  Imports: Messages, Prompts, Runnables')

# langchain-ollama
print('\n[3/5] langchain-ollama...')
from langchain_ollama import ChatOllama
print('  Import: ChatOllama')

# langchain-mcp-adapters
print('\n[4/5] langchain-mcp-adapters...')
from langchain_mcp_adapters.client import MultiServerMCPClient
print('  Import: MultiServerMCPClient')

# HTTP clients
print('\n[5/5] HTTP Clients...')
import httpx
import aiohttp
print(f'  httpx version: {httpx.__version__}')
print(f'  aiohttp version: {aiohttp.__version__}')

print('\n' + '=' * 60)
print('ALL CORE FRAMEWORK DEPENDENCIES VERIFIED SUCCESSFULLY')
print('=' * 60)
"
```

### Step 4: Version Compatibility Check

```bash
python -c "
from packaging import version
import langgraph
import langchain

# Check version constraints
lg_version = version.parse(langgraph.__version__)
lc_version = version.parse(langchain.__version__)

print('Version Compatibility Check:')
print(f'  LangGraph: {lg_version} >= 0.3.0? {lg_version >= version.parse(\"0.3.0\")}')
print(f'  LangChain: {lc_version} >= 0.3.0? {lc_version >= version.parse(\"0.3.0\")}')

if lg_version >= version.parse('0.3.0') and lc_version >= version.parse('0.3.0'):
    print('\nVersion compatibility: PASS')
else:
    print('\nVersion compatibility: FAIL')
    exit(1)
"
```

### Step 5: Create Verification Test Script

Create `/opt/hx-lang-server/scripts/verify_core_framework.py`:

```python
#!/usr/bin/env python3
"""
Core Framework Verification Script for hx-lang-server
Run this to verify all core dependencies are correctly installed.
"""

import sys
from typing import Dict, Any

def verify_langgraph() -> Dict[str, Any]:
    """Verify LangGraph installation."""
    try:
        import langgraph
        from langgraph.graph import StateGraph, START, END
        from langgraph.graph.message import add_messages
        from langgraph.prebuilt import create_react_agent
        return {
            "status": "OK",
            "version": langgraph.__version__,
            "imports": ["StateGraph", "START", "END", "add_messages", "create_react_agent"]
        }
    except Exception as e:
        return {"status": "FAIL", "error": str(e)}

def verify_langchain() -> Dict[str, Any]:
    """Verify LangChain installation."""
    try:
        import langchain
        from langchain_core.messages import HumanMessage, AIMessage, BaseMessage
        from langchain_core.prompts import ChatPromptTemplate
        from langchain_core.runnables import RunnablePassthrough
        return {
            "status": "OK",
            "version": langchain.__version__,
            "imports": ["Messages", "Prompts", "Runnables"]
        }
    except Exception as e:
        return {"status": "FAIL", "error": str(e)}

def verify_ollama() -> Dict[str, Any]:
    """Verify langchain-ollama installation."""
    try:
        from langchain_ollama import ChatOllama
        return {"status": "OK", "imports": ["ChatOllama"]}
    except Exception as e:
        return {"status": "FAIL", "error": str(e)}

def verify_mcp() -> Dict[str, Any]:
    """Verify langchain-mcp-adapters installation."""
    try:
        from langchain_mcp_adapters.client import MultiServerMCPClient
        return {"status": "OK", "imports": ["MultiServerMCPClient"]}
    except Exception as e:
        return {"status": "FAIL", "error": str(e)}

def verify_http() -> Dict[str, Any]:
    """Verify HTTP client installations."""
    try:
        import httpx
        import aiohttp
        return {
            "status": "OK",
            "httpx_version": httpx.__version__,
            "aiohttp_version": aiohttp.__version__
        }
    except Exception as e:
        return {"status": "FAIL", "error": str(e)}

def main():
    """Run all verifications."""
    print("=" * 60)
    print("HX-LANG-SERVER CORE FRAMEWORK VERIFICATION")
    print("=" * 60)

    results = {
        "LangGraph": verify_langgraph(),
        "LangChain": verify_langchain(),
        "langchain-ollama": verify_ollama(),
        "langchain-mcp-adapters": verify_mcp(),
        "HTTP Clients": verify_http()
    }

    all_ok = True
    for name, result in results.items():
        status = result.get("status", "UNKNOWN")
        print(f"\n{name}: {status}")
        if status == "OK":
            for key, value in result.items():
                if key != "status":
                    print(f"  {key}: {value}")
        else:
            all_ok = False
            print(f"  ERROR: {result.get('error', 'Unknown error')}")

    print("\n" + "=" * 60)
    if all_ok:
        print("VERIFICATION RESULT: ALL CHECKS PASSED")
        sys.exit(0)
    else:
        print("VERIFICATION RESULT: SOME CHECKS FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

```bash
chmod +x /opt/hx-lang-server/scripts/verify_core_framework.py
python /opt/hx-lang-server/scripts/verify_core_framework.py
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Requirements snapshot | `/opt/hx-lang-server/requirements-core-framework.txt` | Frozen dependencies |
| Verification script | `/opt/hx-lang-server/scripts/verify_core_framework.py` | Reusable verification |

---

## Verification Steps

- [ ] All 5 packages import without errors
- [ ] LangGraph version is 0.3.x or higher
- [ ] LangChain version is 0.3.x or higher
- [ ] No dependency conflicts reported by pip
- [ ] Verification script exits with code 0

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate

# Final comprehensive verification
python /opt/hx-lang-server/scripts/verify_core_framework.py

# Check for dependency conflicts
pip check

# List all installed packages
pip list | grep -E "(langgraph|langchain|httpx|aiohttp)"
```

---

## Rollback Procedure

If verification fails:

```bash
source /opt/hx-lang-server/venv/bin/activate

# Check for conflicts
pip check

# Reinstall from scratch if needed
pip uninstall langgraph langchain langchain-core langchain-ollama langchain-mcp-adapters httpx aiohttp -y
pip cache purge

# Reinstall in order
pip install "langgraph>=0.3.0"
pip install "langchain>=0.3.0"
pip install "langchain-ollama>=0.2.0"
pip install "langchain-mcp-adapters>=0.1.0"
pip install "httpx>=0.27.0" "aiohttp>=3.10.0"
```

---

## Notes

- This task gates progression to Work Streams 4-9 (integration work)
- Requirements snapshot enables reproducible installations
- Verification script can be run post-deployment for health checks
- Any dependency conflict must be resolved before proceeding
- Work Stream 3 is complete when this task passes

---

## Work Stream 3 Completion Criteria

Upon successful completion of this task:

- [ ] All core framework packages installed
- [ ] All imports verified
- [ ] Version requirements met (LangGraph 0.3.x, LangChain 0.3.x)
- [ ] No dependency conflicts
- [ ] Requirements snapshot created
- [ ] Verification script created and passing

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
