# Task: Implement Human-in-the-Loop Support

**Task ID**: hx-lang-server-task-060-implement-human-in-loop
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-059 (Graph Compilation with Checkpointing)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 45 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "FR-004"

---

## Objective

Implement human-in-the-loop interrupt capabilities that allow pausing agent execution for human approval at critical decision points. This is essential for agent approval workflows.

---

## Prerequisites

- [ ] Graph compilation with checkpointing complete (task-059)
- [ ] PostgreSQL checkpointer operational (Work Stream 4)
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Create Human-in-the-Loop Module

Create `/opt/hx-lang-server/app/agents/human_in_loop.py`:

```python
"""
Human-in-the-Loop Support for hx-lang-server.

Provides mechanisms for pausing agent execution and waiting for
human approval at critical decision points.

Features:
- Interrupt points before critical operations
- State modification during paused execution
- Resume execution after approval
- Timeout handling for abandoned approvals

Specification Reference: FR-004 - Human-in-the-loop interrupts
"""

from typing import Optional, Dict, Any, Callable
from enum import Enum
from datetime import datetime, timedelta
from langgraph.graph import StateGraph


class InterruptReason(Enum):
    """Reasons for human-in-the-loop interrupts."""
    TOOL_APPROVAL = "tool_approval"
    HIGH_RISK_ACTION = "high_risk_action"
    CLARIFICATION_NEEDED = "clarification_needed"
    MANUAL_REVIEW = "manual_review"
    CUSTOM = "custom"


class HumanInLoopConfig:
    """Configuration for human-in-the-loop behavior."""

    def __init__(
        self,
        require_tool_approval: bool = False,
        approval_timeout_minutes: int = 30,
        interrupt_on_high_cost: bool = False,
        high_cost_threshold: float = 0.0
    ):
        """
        Initialize human-in-loop configuration.

        Args:
            require_tool_approval: Require approval before tool execution.
            approval_timeout_minutes: Timeout for pending approvals.
            interrupt_on_high_cost: Interrupt for high-cost operations.
            high_cost_threshold: Cost threshold for interrupts.
        """
        self.require_tool_approval = require_tool_approval
        self.approval_timeout = timedelta(minutes=approval_timeout_minutes)
        self.interrupt_on_high_cost = interrupt_on_high_cost
        self.high_cost_threshold = high_cost_threshold


class InterruptRequest:
    """Represents a human-in-the-loop interrupt request."""

    def __init__(
        self,
        thread_id: str,
        reason: InterruptReason,
        message: str,
        state_snapshot: Dict[str, Any],
        timestamp: Optional[datetime] = None
    ):
        """
        Initialize interrupt request.

        Args:
            thread_id: Conversation thread ID.
            reason: Reason for interrupt.
            message: Human-readable description.
            state_snapshot: Copy of agent state at interrupt.
            timestamp: When interrupt was created.
        """
        self.thread_id = thread_id
        self.reason = reason
        self.message = message
        self.state_snapshot = state_snapshot
        self.timestamp = timestamp or datetime.utcnow()
        self.resolved = False
        self.approved: Optional[bool] = None
        self.modifications: Dict[str, Any] = {}


class InterruptManager:
    """
    Manages human-in-the-loop interrupts.

    Tracks pending interrupts and handles approval workflow.
    """

    def __init__(self, config: Optional[HumanInLoopConfig] = None):
        """
        Initialize interrupt manager.

        Args:
            config: Human-in-loop configuration.
        """
        self.config = config or HumanInLoopConfig()
        self._pending_interrupts: Dict[str, InterruptRequest] = {}

    def create_interrupt(
        self,
        thread_id: str,
        reason: InterruptReason,
        message: str,
        state: Dict[str, Any]
    ) -> InterruptRequest:
        """
        Create a new interrupt request.

        Args:
            thread_id: Thread ID for the conversation.
            reason: Reason for interrupt.
            message: Description for human reviewer.
            state: Current agent state.

        Returns:
            InterruptRequest for tracking.
        """
        interrupt = InterruptRequest(
            thread_id=thread_id,
            reason=reason,
            message=message,
            state_snapshot=dict(state)  # Copy state
        )
        self._pending_interrupts[thread_id] = interrupt
        return interrupt

    def get_pending(self, thread_id: str) -> Optional[InterruptRequest]:
        """Get pending interrupt for thread."""
        return self._pending_interrupts.get(thread_id)

    def approve(
        self,
        thread_id: str,
        modifications: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Approve a pending interrupt.

        Args:
            thread_id: Thread ID with pending interrupt.
            modifications: Optional state modifications.

        Returns:
            True if approval processed, False if no pending interrupt.
        """
        interrupt = self._pending_interrupts.get(thread_id)
        if interrupt is None:
            return False

        interrupt.resolved = True
        interrupt.approved = True
        if modifications:
            interrupt.modifications = modifications

        return True

    def reject(self, thread_id: str) -> bool:
        """
        Reject a pending interrupt.

        Args:
            thread_id: Thread ID with pending interrupt.

        Returns:
            True if rejection processed.
        """
        interrupt = self._pending_interrupts.get(thread_id)
        if interrupt is None:
            return False

        interrupt.resolved = True
        interrupt.approved = False
        return True

    def is_approved(self, thread_id: str) -> Optional[bool]:
        """Check if interrupt is approved (None if not resolved)."""
        interrupt = self._pending_interrupts.get(thread_id)
        if interrupt is None or not interrupt.resolved:
            return None
        return interrupt.approved

    def get_modifications(self, thread_id: str) -> Dict[str, Any]:
        """Get state modifications for approved interrupt."""
        interrupt = self._pending_interrupts.get(thread_id)
        if interrupt is None:
            return {}
        return interrupt.modifications

    def clear_interrupt(self, thread_id: str) -> None:
        """Clear resolved interrupt from pending."""
        self._pending_interrupts.pop(thread_id, None)

    def cleanup_expired(self) -> int:
        """
        Clean up expired interrupts.

        Returns:
            Number of expired interrupts removed.
        """
        now = datetime.utcnow()
        expired = []

        for thread_id, interrupt in self._pending_interrupts.items():
            if (now - interrupt.timestamp) > self.config.approval_timeout:
                expired.append(thread_id)

        for thread_id in expired:
            del self._pending_interrupts[thread_id]

        return len(expired)


def create_interrupt_node(
    interrupt_manager: InterruptManager,
    reason: InterruptReason,
    message_fn: Callable[[Dict[str, Any]], str]
) -> Callable:
    """
    Create a LangGraph node that triggers an interrupt.

    Args:
        interrupt_manager: InterruptManager instance.
        reason: Reason for interrupt.
        message_fn: Function to generate interrupt message from state.

    Returns:
        Node function for use in StateGraph.

    Example:
        ```python
        interrupt_node = create_interrupt_node(
            manager,
            InterruptReason.TOOL_APPROVAL,
            lambda state: f"Approve tool execution: {state['tool_name']}"
        )
        graph.add_node("approval", interrupt_node, interrupt_before=True)
        ```
    """
    async def interrupt_node(state: Dict[str, Any]) -> Dict[str, Any]:
        thread_id = state.get("thread_id", "unknown")
        message = message_fn(state)

        # Create interrupt request
        interrupt_manager.create_interrupt(
            thread_id=thread_id,
            reason=reason,
            message=message,
            state=state
        )

        # Mark state as awaiting approval
        return {
            **state,
            "_interrupt_pending": True,
            "_interrupt_reason": reason.value,
            "_interrupt_message": message
        }

    return interrupt_node


# Global interrupt manager instance
_interrupt_manager: Optional[InterruptManager] = None


def get_interrupt_manager() -> InterruptManager:
    """Get or create the global interrupt manager."""
    global _interrupt_manager
    if _interrupt_manager is None:
        _interrupt_manager = InterruptManager()
    return _interrupt_manager
```

### Step 2: Update Persistence Package

Update `/opt/hx-lang-server/app/persistence/__init__.py`:

```python
"""Persistence module for hx-lang-server."""

from .checkpointer import (
    CheckpointerConfig,
    create_async_connection,
    create_checkpointer,
    get_checkpointer,
    get_default_checkpointer
)

__all__ = [
    "CheckpointerConfig",
    "create_async_connection",
    "create_checkpointer",
    "get_checkpointer",
    "get_default_checkpointer"
]
```

### Step 3: Update Agents Package

Update `/opt/hx-lang-server/app/agents/__init__.py` to include human-in-loop:

```python
"""Agents module for hx-lang-server."""

from .supervisor import SupervisorAgent, create_supervisor
from .workers.rag_agent import RAGAgentWorker, create_rag_agent
from .workers.code_agent import CodeAgentWorker, create_code_agent
from .workers.tool_agent import ToolAgentWorker, create_tool_agent
from .workers.general_agent import GeneralAgentWorker, create_general_agent
from .factory import (
    create_agent_system,
    create_agent_system_with_persistence,
    create_supervisor_with_workers,
    create_llm_general,
    create_llm_code
)
from .human_in_loop import (
    InterruptReason,
    HumanInLoopConfig,
    InterruptRequest,
    InterruptManager,
    create_interrupt_node,
    get_interrupt_manager
)

__all__ = [
    # Supervisor
    "SupervisorAgent",
    "create_supervisor",
    # Workers
    "RAGAgentWorker",
    "create_rag_agent",
    "CodeAgentWorker",
    "create_code_agent",
    "ToolAgentWorker",
    "create_tool_agent",
    "GeneralAgentWorker",
    "create_general_agent",
    # Factory
    "create_agent_system",
    "create_agent_system_with_persistence",
    "create_supervisor_with_workers",
    "create_llm_general",
    "create_llm_code",
    # Human-in-Loop
    "InterruptReason",
    "HumanInLoopConfig",
    "InterruptRequest",
    "InterruptManager",
    "create_interrupt_node",
    "get_interrupt_manager"
]
```

### Step 4: Verify Implementation

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python -c "
from app.agents.human_in_loop import (
    InterruptManager,
    InterruptReason,
    HumanInLoopConfig,
    get_interrupt_manager
)

# Create manager
manager = InterruptManager()

# Test interrupt workflow
state = {'thread_id': 'test-thread', 'query': 'test query'}
interrupt = manager.create_interrupt(
    thread_id='test-thread',
    reason=InterruptReason.TOOL_APPROVAL,
    message='Approve tool execution',
    state=state
)

print(f'Interrupt created: {interrupt.thread_id}')
print(f'Reason: {interrupt.reason.value}')
print(f'Resolved: {interrupt.resolved}')

# Approve with modifications
manager.approve('test-thread', modifications={'approved_by': 'user'})
print(f'After approval - Approved: {interrupt.approved}')
print(f'Modifications: {interrupt.modifications}')

print('\nHuman-in-Loop implementation verified!')
"
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Human-in-Loop module | `/opt/hx-lang-server/app/agents/human_in_loop.py` | Interrupt management |

---

## Verification Steps

- [ ] `human_in_loop.py` file exists at correct location
- [ ] InterruptManager can be imported
- [ ] Interrupt workflow (create, approve, reject) works
- [ ] State modifications are preserved

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Import test
python -c "from app.agents import InterruptManager, InterruptReason; print('Human-in-Loop imports OK')"

# Workflow test
python -c "
from app.agents.human_in_loop import InterruptManager, InterruptReason

m = InterruptManager()
m.create_interrupt('t1', InterruptReason.TOOL_APPROVAL, 'Test', {})
assert m.is_approved('t1') is None  # Not resolved yet
m.approve('t1')
assert m.is_approved('t1') == True
print('Human-in-Loop workflow: PASS')
"
```

---

## Rollback Procedure

```bash
rm /opt/hx-lang-server/app/agents/human_in_loop.py
# Revert __init__.py changes
```

---

## Notes

- Human-in-the-loop per FR-004 specification
- Requires checkpointing for state persistence during interrupts
- Approval timeouts prevent abandoned threads
- State modifications allow human input before resumption
- Integration with FastAPI endpoints in Work Stream 10 (Bob)

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
