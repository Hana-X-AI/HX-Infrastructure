# Task: Verify Complete Agent Implementation

**Task ID**: hx-lang-server-task-061-verify-agent-implementation
**Phase**: Implementation
**Assigned To**: Sophia (LangGraph Orchestration SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-051 through task-060 (All Agent Tasks)
**Work Stream**: 6 - LangGraph Agent Implementation
**Estimated Time**: 30 minutes
**Specification Reference**: `/nodes/hx-lang-server/specification/node-spec.md` Section "Architecture Overview"

---

## Objective

Verify the complete LangGraph agent implementation is functional. Run comprehensive verification tests covering all components: AgentState, QueryClassifier, Supervisor, all Workers, Factory, Checkpointing, and Human-in-Loop.

---

## Prerequisites

- [ ] All Work Stream 6 tasks (051-060) completed
- [ ] Virtual environment active at `/opt/hx-lang-server/venv`

---

## Implementation Steps

### Step 1: Create Comprehensive Verification Script

Create `/opt/hx-lang-server/scripts/verify_agent_implementation.py`:

```python
#!/usr/bin/env python3
"""
Comprehensive Agent Implementation Verification Script.

Verifies all Work Stream 6 components are correctly implemented
and functional before proceeding to integration work streams.
"""

import asyncio
import sys
from typing import Dict, Any, List, Tuple


def check_imports() -> List[Tuple[str, bool, str]]:
    """Check all required imports."""
    results = []

    # Core state
    try:
        from app.core.state import (
            AgentState,
            SCHEMA_VERSION,
            create_initial_state,
            validate_query_type,
            VALID_QUERY_TYPES
        )
        results.append(("app.core.state", True, "All exports available"))
    except Exception as e:
        results.append(("app.core.state", False, str(e)))

    # Classifier
    try:
        from app.core.classifier import QueryClassifier, get_classifier
        results.append(("app.core.classifier", True, "All exports available"))
    except Exception as e:
        results.append(("app.core.classifier", False, str(e)))

    # Supervisor
    try:
        from app.agents.supervisor import SupervisorAgent, create_supervisor
        results.append(("app.agents.supervisor", True, "All exports available"))
    except Exception as e:
        results.append(("app.agents.supervisor", False, str(e)))

    # Workers
    workers = [
        "app.agents.workers.rag_agent",
        "app.agents.workers.code_agent",
        "app.agents.workers.tool_agent",
        "app.agents.workers.general_agent"
    ]
    for worker in workers:
        try:
            __import__(worker)
            results.append((worker, True, "Import successful"))
        except Exception as e:
            results.append((worker, False, str(e)))

    # Factory
    try:
        from app.agents.factory import create_agent_system
        results.append(("app.agents.factory", True, "Factory available"))
    except Exception as e:
        results.append(("app.agents.factory", False, str(e)))

    # Persistence
    try:
        from app.persistence.checkpointer import CheckpointerConfig
        results.append(("app.persistence.checkpointer", True, "Checkpointer available"))
    except Exception as e:
        results.append(("app.persistence.checkpointer", False, str(e)))

    # Human-in-Loop
    try:
        from app.agents.human_in_loop import InterruptManager
        results.append(("app.agents.human_in_loop", True, "Human-in-loop available"))
    except Exception as e:
        results.append(("app.agents.human_in_loop", False, str(e)))

    return results


def verify_state_schema() -> Tuple[bool, str]:
    """Verify AgentState schema."""
    try:
        from app.core.state import AgentState, create_initial_state, SCHEMA_VERSION
        import typing

        # Check schema version
        assert SCHEMA_VERSION == "1.0", f"Schema version mismatch: {SCHEMA_VERSION}"

        # Check all required fields
        hints = typing.get_type_hints(AgentState)
        required_fields = [
            'schema_version', 'messages', 'query_type', 'current_worker',
            'rag_context', 'tool_results', 'iteration_count', 'session_id',
            'thread_id', 'user_id', 'created_at', 'updated_at'
        ]

        for field in required_fields:
            assert field in hints, f"Missing field: {field}"

        # Test state creation
        state = create_initial_state("test-session", "test-thread")
        assert state["schema_version"] == "1.0"
        assert state["session_id"] == "test-session"

        return True, f"Schema valid with {len(required_fields)} fields"
    except Exception as e:
        return False, str(e)


def verify_classifier() -> Tuple[bool, str]:
    """Verify QueryClassifier."""
    try:
        from app.core.classifier import QueryClassifier
        from app.core.state import QUERY_TYPE_CODE, QUERY_TYPE_RAG, QUERY_TYPE_TOOL

        classifier = QueryClassifier()

        # Test keyword classification
        assert classifier.classify_sync("debug my code") == QUERY_TYPE_CODE
        assert classifier.classify_sync("search for docs") == QUERY_TYPE_RAG
        assert classifier.classify_sync("crawl website") == QUERY_TYPE_TOOL
        assert classifier.classify_sync("hello") == "general"

        return True, "All classifications correct"
    except Exception as e:
        return False, str(e)


async def verify_supervisor() -> Tuple[bool, str]:
    """Verify SupervisorAgent."""
    try:
        from app.agents.supervisor import create_supervisor

        supervisor = create_supervisor()
        supervisor.build_graph()
        supervisor.compile()

        assert supervisor._compiled_graph is not None

        # Test invocation
        result = await supervisor.invoke(
            query="Hello",
            session_id="test",
            thread_id="test"
        )

        assert result is not None
        assert "query_type" in result
        assert "messages" in result

        return True, "Supervisor builds, compiles, and invokes"
    except Exception as e:
        return False, str(e)


async def verify_factory() -> Tuple[bool, str]:
    """Verify agent factory."""
    try:
        from app.agents.factory import create_agent_system

        agent = create_agent_system()

        # Check workers registered
        assert "rag_agent" in agent.workers
        assert "code_agent" in agent.workers
        assert "tool_agent" in agent.workers
        assert "general_agent" in agent.workers

        # Check graph compiled
        assert agent._compiled_graph is not None

        return True, "Factory creates system with 4 workers"
    except Exception as e:
        return False, str(e)


async def verify_routing() -> Tuple[bool, str]:
    """Verify query routing."""
    try:
        from app.agents.factory import create_agent_system

        agent = create_agent_system()

        # Test routing decisions
        tests = [
            ("Write Python code", "code"),
            ("Search the documentation", "rag"),
            ("Crawl this URL", "tool"),
            ("Hello there", "general"),
        ]

        for query, expected_type in tests:
            result = await agent.invoke(
                query=query,
                session_id="test",
                thread_id=f"test-{expected_type}"
            )
            actual_type = result["query_type"]
            if actual_type != expected_type:
                return False, f"Routing failed: '{query}' -> {actual_type}, expected {expected_type}"

        return True, "All queries routed correctly"
    except Exception as e:
        return False, str(e)


def verify_human_in_loop() -> Tuple[bool, str]:
    """Verify human-in-loop."""
    try:
        from app.agents.human_in_loop import InterruptManager, InterruptReason

        manager = InterruptManager()

        # Create interrupt
        interrupt = manager.create_interrupt(
            thread_id="test",
            reason=InterruptReason.TOOL_APPROVAL,
            message="Test interrupt",
            state={"test": True}
        )

        assert interrupt is not None
        assert not interrupt.resolved

        # Approve
        manager.approve("test", modifications={"approved": True})
        assert interrupt.resolved
        assert interrupt.approved

        return True, "Interrupt workflow functional"
    except Exception as e:
        return False, str(e)


async def main():
    """Run all verifications."""
    print("=" * 70)
    print("HX-LANG-SERVER AGENT IMPLEMENTATION VERIFICATION")
    print("Work Stream 6 - LangGraph Agent Implementation")
    print("=" * 70)

    all_passed = True

    # Phase 1: Import checks
    print("\n[Phase 1] Import Verification")
    print("-" * 40)
    import_results = check_imports()
    for module, success, message in import_results:
        status = "PASS" if success else "FAIL"
        print(f"  [{status}] {module}: {message}")
        if not success:
            all_passed = False

    # Phase 2: Component verification
    print("\n[Phase 2] Component Verification")
    print("-" * 40)

    # State schema
    success, msg = verify_state_schema()
    print(f"  [{'PASS' if success else 'FAIL'}] AgentState Schema: {msg}")
    if not success:
        all_passed = False

    # Classifier
    success, msg = verify_classifier()
    print(f"  [{'PASS' if success else 'FAIL'}] QueryClassifier: {msg}")
    if not success:
        all_passed = False

    # Supervisor
    success, msg = await verify_supervisor()
    print(f"  [{'PASS' if success else 'FAIL'}] SupervisorAgent: {msg}")
    if not success:
        all_passed = False

    # Factory
    success, msg = await verify_factory()
    print(f"  [{'PASS' if success else 'FAIL'}] Agent Factory: {msg}")
    if not success:
        all_passed = False

    # Routing
    success, msg = await verify_routing()
    print(f"  [{'PASS' if success else 'FAIL'}] Query Routing: {msg}")
    if not success:
        all_passed = False

    # Human-in-Loop
    success, msg = verify_human_in_loop()
    print(f"  [{'PASS' if success else 'FAIL'}] Human-in-Loop: {msg}")
    if not success:
        all_passed = False

    # Summary
    print("\n" + "=" * 70)
    if all_passed:
        print("VERIFICATION RESULT: ALL CHECKS PASSED")
        print("Work Stream 6 - LangGraph Agent Implementation: COMPLETE")
    else:
        print("VERIFICATION RESULT: SOME CHECKS FAILED")
        print("Review failures above before proceeding")
    print("=" * 70)

    return 0 if all_passed else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
```

### Step 2: Make Script Executable

```bash
chmod +x /opt/hx-lang-server/scripts/verify_agent_implementation.py
```

### Step 3: Run Verification

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

python scripts/verify_agent_implementation.py
```

---

## Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| Verification script | `/opt/hx-lang-server/scripts/verify_agent_implementation.py` | Comprehensive verification |

---

## Verification Steps

- [ ] All imports succeed
- [ ] AgentState schema valid with 12 fields
- [ ] QueryClassifier routes correctly
- [ ] SupervisorAgent builds and compiles
- [ ] Factory creates system with 4 workers
- [ ] Query routing works for all types
- [ ] Human-in-Loop workflow functional

### Verification Commands

```bash
source /opt/hx-lang-server/venv/bin/activate
cd /opt/hx-lang-server

# Run comprehensive verification
python scripts/verify_agent_implementation.py

# Expected output: "VERIFICATION RESULT: ALL CHECKS PASSED"
```

---

## Work Stream 6 Completion Criteria

Upon successful completion of this task:

- [ ] All 11 tasks (051-061) completed
- [ ] Verification script passes all checks
- [ ] Agent system ready for integration with:
  - Work Stream 4: PostgreSQL Integration
  - Work Stream 5: Redis Integration
  - Work Stream 7: Ollama Integration
  - Work Stream 8: LightRAG Integration
  - Work Stream 9: MCP Integration
  - Work Stream 10: FastAPI Application

---

## Rollback Procedure

Not applicable - this is a verification task.

---

## Notes

- This task gates progression to integration work streams
- All checks must pass before Work Stream 6 is considered complete
- Verification script can be run anytime to check system health
- Integration testing with external services in respective work streams

---

**Task Created By**: Sophia (LangGraph Orchestration SME)
**Task Created Date**: 2025-12-04
