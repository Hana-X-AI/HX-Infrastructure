# Task: Install LangChain Core Package

**Task ID**: hx-lang-server-task-022-install-langchain-core
**Phase**: Installation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-021 (LangGraph Framework)
**Work Stream**: 3 - Core Framework Installation
**Estimated Time**: 10 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Python Dependencies"

---

## Objective

Install LangChain v0.3.x as the LLM abstraction layer. LangChain provides the foundational abstractions for messages, prompts, and model interfaces that LangGraph builds upon.

---

## Prerequisites

- [ ] LangGraph v0.3.x installed (task-021)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`
- [ ] Network connectivity to PyPI

---

## Implementation Steps

### Step 1: Activate Virtual Environment

```bash
source /opt/hx-lang-server/venv/bin/activate
```

### Step 2: Install LangChain Core

```bash
pip install "langchain>=0.3.0"
```

### Step 3: Verify Installation

```bash
pip show langchain
python -c "import langchain; print(f'LangChain version: {langchain.__version__}')"
```

### Step 4: Verify Core Imports

```bash
python -c "
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough, RunnableLambda
print('LangChain core imports successful')
"
```

---

## Code Patterns Reference

LangChain v0.3.x uses the following import patterns for hx-lang-server:

```python
# Message types (used in AgentState)
from langchain_core.messages import (
    HumanMessage,
    AIMessage,
    SystemMessage,
    BaseMessage,
    ToolMessage
)

# Prompt templates
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

# Runnable composition
from langchain_core.runnables import RunnablePassthrough, RunnableLambda

# Output parsing
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| LangChain package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/langchain/` | Installed package |
| langchain-core package | `/opt/hx-lang-server/venv/lib/python3.11/site-packages/langchain_core/` | Core abstractions |

---

## Verification Steps

- [ ] `pip show langchain` returns version 0.3.x or higher
- [ ] `pip show langchain-core` shows compatible version
- [ ] Message imports work without error
- [ ] Prompt template imports work without error
- [ ] Runnable imports work without error

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate

# Version check
pip show langchain | grep -E "^(Name|Version):"
pip show langchain-core | grep -E "^(Name|Version):"

# Import verification
python -c "
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough, RunnableLambda
from langchain_core.output_parsers import StrOutputParser
import langchain
print(f'LangChain {langchain.__version__} installed and verified')
print('All core imports successful')
"
```

---

## Rollback Procedure

```bash
source /opt/hx-lang-server/venv/bin/activate
pip uninstall langchain langchain-core -y
pip cache purge
```

---

## Notes

- LangChain v0.3.x aligns with LangGraph v0.3.x per specification
- langchain-core is automatically installed as dependency
- Message types are essential for AgentState schema (Work Stream 6)
- Prompt templates used for query classification and agent prompts

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
