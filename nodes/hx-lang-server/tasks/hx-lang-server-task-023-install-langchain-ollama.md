# Task: Install langchain-ollama Package

**Task ID**: hx-lang-server-task-023-install-langchain-ollama
**Phase**: Installation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-022 (LangChain Core)
**Work Stream**: 3 - Core Framework Installation
**Estimated Time**: 10 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "LLM Integration"

---

## Objective

Install langchain-ollama package to enable integration with Ollama LLM servers. This package provides the ChatOllama class for connecting to hx-ollama1-server (general) and hx-ollama2-server (code).

---

## Prerequisites

- [ ] LangChain v0.3.x installed (task-022)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`
- [ ] Network connectivity to PyPI

---

## Implementation Steps

### Step 1: Activate Virtual Environment

```bash
source /opt/hx-lang-server/venv/bin/activate
```

### Step 2: Install langchain-ollama

```bash
pip install "langchain-ollama>=0.2.0"
```

### Step 3: Verify Installation

```bash
pip show langchain-ollama
python -c "import langchain_ollama; print('langchain-ollama imported successfully')"
```

### Step 4: Verify ChatOllama Import

```bash
python -c "
from langchain_ollama import ChatOllama
print('ChatOllama import successful')
print(f'ChatOllama class available: {ChatOllama}')
"
```

---

## Code Patterns Reference

langchain-ollama usage pattern for hx-lang-server:

```python
from langchain_ollama import ChatOllama

# General LLM (hx-ollama1-server)
general_llm = ChatOllama(
    base_url="http://hx-ollama1-server.hx.dev.local:11434",
    model="gemma3:27b",
    temperature=0.7,
    num_ctx=8192  # 8KB context for general queries
)

# Code LLM (hx-ollama2-server)
code_llm = ChatOllama(
    base_url="http://hx-ollama2-server.hx.dev.local:11434",
    model="qwen3-coder:30b",
    temperature=0.2,
    num_ctx=65536  # 64KB context for code operations (CAIO decision)
)

# Usage with messages
from langchain_core.messages import HumanMessage
response = await general_llm.ainvoke([HumanMessage(content="Hello")])
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| langchain-ollama package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/langchain_ollama/` | Installed package |

---

## Verification Steps

- [ ] `pip show langchain-ollama` returns version 0.2.x or higher
- [ ] `from langchain_ollama import ChatOllama` imports without error
- [ ] ChatOllama class is accessible and instantiable

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate

# Version check
pip show langchain-ollama | grep -E "^(Name|Version):"

# Import verification
python -c "
from langchain_ollama import ChatOllama

# Verify class can be instantiated (no connection test yet)
llm = ChatOllama(
    base_url='http://localhost:11434',
    model='test'
)
print(f'ChatOllama instantiated: {type(llm).__name__}')
print('langchain-ollama installed and verified')
"
```

---

## Rollback Procedure

```bash
source /opt/hx-lang-server/venv/bin/activate
pip uninstall langchain-ollama -y
pip cache purge
```

---

## Notes

- langchain-ollama v0.2.x is required per specification
- ChatOllama supports async operations via `ainvoke()` - critical for FastAPI async endpoints
- Connection to actual Ollama servers tested in Work Stream 7 (Jim - Ollama Integration)
- Context size (`num_ctx`) configuration is per-model, set during LLM instantiation
- CAIO decision: 64KB context for RAG and Code operations

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
