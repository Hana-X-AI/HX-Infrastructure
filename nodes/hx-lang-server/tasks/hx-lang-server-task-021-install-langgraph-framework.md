# Task: Install LangGraph Framework

**Task ID**: hx-lang-server-task-021-install-langgraph-framework
**Phase**: Installation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-011 (System Dependencies), hx-lang-server-task-012 (Virtual Environment)
**Work Stream**: 3 - Core Framework Installation
**Estimated Time**: 15 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Python Dependencies"

---

## Objective

Install LangGraph v0.3.x (latest stable version) as the core agent orchestration framework. This is the foundational package for all agent workflow capabilities per CAIO decision to use latest v0.3.x.

---

## Prerequisites

- [ ] Python 3.11+ virtual environment created at `/opt/hx-lang-server/venv`
- [ ] Virtual environment activated
- [ ] pip upgraded to latest version
- [ ] Network connectivity to PyPI (pypi.org)

---

## Implementation Steps

### Step 1: Activate Virtual Environment

```bash
source /opt/hx-lang-server/venv/bin/activate
```

### Step 2: Verify Python Version

```bash
python --version
# Expected: Python 3.11.x or higher
```

### Step 3: Install LangGraph Core Package

```bash
pip install "langgraph>=0.3.0"
```

### Step 4: Verify Installation

```bash
pip show langgraph
# Verify version is 0.3.x
python -c "import langgraph; print(f'LangGraph version: {langgraph.__version__}')"
```

### Step 5: Verify Core Imports

```bash
python -c "
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import create_react_agent
print('LangGraph core imports successful')
"
```

---

## Code Patterns Reference

LangGraph v0.3.x uses the following import patterns:

```python
# Core graph construction
from langgraph.graph import StateGraph, START, END

# Message handling
from langgraph.graph.message import add_messages

# Prebuilt agents
from langgraph.prebuilt import create_react_agent

# State annotations
from typing import TypedDict, Annotated
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| LangGraph package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/langgraph/` | Installed package |
| Installation record | pip freeze output | Version confirmation |

---

## Verification Steps

- [ ] `pip show langgraph` returns version 0.3.x or higher
- [ ] `from langgraph.graph import StateGraph, START, END` imports without error
- [ ] `from langgraph.graph.message import add_messages` imports without error
- [ ] `from langgraph.prebuilt import create_react_agent` imports without error

### Verification Commands

```bash
# Full verification script
source /opt/hx-lang-server/venv/bin/activate
pip show langgraph | grep -E "^(Name|Version):"
python -c "
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import create_react_agent
import langgraph
print(f'LangGraph {langgraph.__version__} installed and verified')
print('All core imports successful')
"
```

---

## Rollback Procedure

```bash
source /opt/hx-lang-server/venv/bin/activate
pip uninstall langgraph -y
pip cache purge
```

---

## Notes

- LangGraph v0.3.x is required per CAIO decision (2025-12-04)
- This package provides: StateGraph, conditional edges, checkpointing support
- Additional packages (langgraph-checkpoint-postgres) installed in Work Stream 4
- Version constraint `>=0.3.0` ensures latest stable release

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
