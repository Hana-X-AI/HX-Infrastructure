# Architecture Contribution: Alex Rivera (Platform Architect)

**Contribution Date:** 2025-12-01
**Specification Version:** 1.0
**Contributor Role:** Platform Architect
**Review Scope:** Architecture Validation, SOLID Principles, Component Interfaces, Failover Semantics, ADR Recommendations

---

## Executive Summary

The hx-lang-server specification demonstrates mature architectural thinking with well-defined component boundaries, appropriate technology selections, and solid integration patterns. The specification successfully addresses the HIGH severity concerns raised in my charter review, particularly around supervisor failover semantics, model routing classification, and MCP abstraction.

This contribution provides:
1. Validation of architectural decisions
2. SOLID principles compliance audit
3. Abstract interface definitions for key components
4. Supervisor failover protocol specification
5. ADR recommendations and drafts
6. Corrections and enhancements to the specification

---

## 1. Architecture Validation

### 1.1 Overall Architecture Assessment

**Rating: STRONG (4.5/5)**

The specification presents a well-layered architecture that correctly positions LangGraph as an orchestration layer:

```
API Layer (FastAPI) --> Orchestration Layer (LangGraph Supervisor) --> Worker Layer (Specialized Agents) --> Integration Layer (Ollama, LightRAG, MCP)
```

**Strengths Validated:**

| Aspect | Assessment | Evidence |
|--------|------------|----------|
| Layer Separation | EXCELLENT | Clear boundaries between FastAPI, Supervisor, Workers, and External Services |
| State Management | EXCELLENT | Dual persistence (PostgreSQL durable, Redis ephemeral) correctly applied |
| Integration Patterns | STRONG | HTTP-based integration with circuit breaker requirements |
| Technology Coherence | EXCELLENT | LangGraph ecosystem (checkpoint, adapters) well integrated |
| Scalability Design | APPROPRIATE | Single-instance supervisor acceptable for dev environment |

**Areas Requiring Attention:**

| Concern | Severity | Section Reference |
|---------|----------|-------------------|
| Supervisor health monitoring mechanism not fully specified | MEDIUM | Section 1.3 |
| Circuit breaker configuration values need validation | LOW | Section 3 |
| MCP Tool Registry abstraction pattern incomplete | MEDIUM | Section 1.4 |

### 1.2 Component Boundary Analysis

The specification correctly defines the following component boundaries:

```
+------------------+     +--------------------+     +-------------------+
|   FastAPI        |     |   LangGraph        |     |   External        |
|   Wrapper        |---->|   Supervisor       |---->|   Services        |
+------------------+     +--------------------+     +-------------------+
        |                        |                          |
   Responsibility:          Responsibility:            Responsibility:
   - HTTP handling          - State management         - LLM inference
   - Request validation     - Query classification     - RAG retrieval
   - Response formatting    - Worker routing           - Tool execution
   - Health endpoints       - Checkpoint coordination  - Data persistence
```

**Boundary Violations Identified:** None

**Boundary Clarifications Needed:**

1. **Query Classification Boundary**: The `QueryClassifier` should be a separate component injected into the Supervisor, not embedded within it. This enables testing in isolation and supports the Open/Closed Principle.

2. **MCP Client Boundary**: The `MultiServerMCPClient` should be abstracted behind an `IMCPToolProvider` interface to decouple the Tool Agent from specific MCP implementation details.

### 1.3 Supervisor Health Monitoring Design

The specification mentions graceful degradation but lacks explicit health monitoring protocol. I provide the following design:

```
+------------------+
|  Health Monitor  |
|   (Background)   |
+--------+---------+
         |
         v
+--------+---------+
|   Supervisor     |
|   Health State   |
+--------+---------+
         |
    +----+----+
    |         |
    v         v
+-------+ +-------+
|Healthy| |Degraded|
+-------+ +-------+
              |
              v
         +--------+
         |Recovery|
         +--------+
```

**Supervisor Health States:**

| State | Condition | Behavior |
|-------|-----------|----------|
| HEALTHY | All workers responsive, all dependencies connected | Normal operation |
| DEGRADED | 1+ workers unresponsive OR 1+ dependencies unavailable | Route to available workers, queue failed requests |
| RECOVERING | Attempting to restore failed components | Retry connections, rehydrate worker state |
| UNHEALTHY | Critical failure, cannot process requests | Return 503, log emergency state |

**Health Check Implementation:**

```python
class SupervisorHealthMonitor:
    """Background health monitor for supervisor agent."""

    CHECK_INTERVAL_SECONDS = 10
    MAX_CONSECUTIVE_FAILURES = 3

    def __init__(self, supervisor: ISupervisorAgent):
        self.supervisor = supervisor
        self.worker_health: dict[str, WorkerHealthStatus] = {}
        self.dependency_health: dict[str, DependencyHealthStatus] = {}

    async def check_health(self) -> SupervisorHealthState:
        """Periodic health check execution."""
        worker_results = await self._check_workers()
        dependency_results = await self._check_dependencies()

        if all(w.healthy for w in worker_results) and all(d.healthy for d in dependency_results):
            return SupervisorHealthState.HEALTHY
        elif any(w.critical for w in worker_results) or any(d.critical for d in dependency_results):
            return SupervisorHealthState.UNHEALTHY
        else:
            return SupervisorHealthState.DEGRADED
```

### 1.4 MCP Tool Registry Abstraction

The specification shows direct MCP client usage. To satisfy the Open/Closed Principle, I recommend the following abstraction:

```python
from abc import ABC, abstractmethod
from typing import Protocol

class IMCPTool(Protocol):
    """Protocol for individual MCP tools."""

    @property
    def name(self) -> str: ...

    @property
    def namespace(self) -> str: ...

    @property
    def description(self) -> str: ...

    async def invoke(self, parameters: dict) -> ToolResult: ...


class IMCPToolRegistry(ABC):
    """Abstract interface for MCP tool discovery and invocation."""

    @abstractmethod
    async def discover_tools(self) -> list[IMCPTool]:
        """Discover available tools from connected MCP servers."""
        pass

    @abstractmethod
    async def get_tool(self, fully_qualified_name: str) -> IMCPTool | None:
        """Get tool by fully qualified name (namespace__tool_name)."""
        pass

    @abstractmethod
    async def invoke_tool(self, fully_qualified_name: str, parameters: dict) -> ToolResult:
        """Invoke tool by name with parameters."""
        pass

    @abstractmethod
    def register_server(self, server_name: str, config: MCPServerConfig) -> None:
        """Register a new MCP server dynamically."""
        pass
```

This abstraction allows:
- Adding new MCP servers without modifying the Tool Agent
- Testing Tool Agent with mock tool registries
- Future extension to non-MCP tool providers

---

## 2. SOLID Principles Audit

### 2.1 Single Responsibility Principle (SRP)

**Compliance: STRONG (4/5)**

| Component | Responsibility | Compliance | Notes |
|-----------|---------------|------------|-------|
| FastAPI Wrapper | HTTP API exposure | COMPLIANT | Single responsibility for API handling |
| LangGraph Supervisor | Orchestration and routing | COMPLIANT | Focused on workflow coordination |
| RAG Agent | RAG operations | COMPLIANT | Single domain focus |
| Code Agent | Code operations | COMPLIANT | Single domain focus |
| Tool Agent | MCP tool execution | COMPLIANT | Single domain focus |
| QueryClassifier | Query classification | NEEDS EXTRACTION | Currently embedded in Supervisor |
| SessionManager | Session management | COMPLIANT | Single responsibility |
| AsyncPostgresSaver | Checkpoint persistence | COMPLIANT | Single responsibility |

**Recommendation:** Extract `QueryClassifier` into a separate injectable component.

### 2.2 Open/Closed Principle (OCP)

**Compliance: MODERATE (3.5/5)**

| Extension Point | Open for Extension | Closed for Modification | Notes |
|-----------------|-------------------|------------------------|-------|
| Worker Agents | YES | YES | New workers can be added via registry |
| MCP Tools | PARTIAL | NO | Currently requires code changes |
| Model Routing | NO | NO | Routing table is hardcoded |
| Query Classification | NO | NO | Keywords hardcoded in classifier |

**Recommendations:**

1. **MCP Tools**: Implement `IMCPToolRegistry` abstraction (see Section 1.4)

2. **Model Routing**: Create a `IModelRouter` interface with pluggable routing strategies:

```python
class IModelRouter(ABC):
    """Abstract interface for model routing decisions."""

    @abstractmethod
    async def route(self, query: str, classification: str) -> ModelEndpoint:
        """Route query to appropriate model endpoint."""
        pass

    @abstractmethod
    def register_route(self, classification: str, endpoint: ModelEndpoint) -> None:
        """Register new routing rule without code modification."""
        pass
```

3. **Query Classification**: Create a `IQueryClassifier` interface supporting pluggable classifiers:

```python
class IQueryClassifier(ABC):
    """Abstract interface for query classification."""

    @abstractmethod
    async def classify(self, query: str) -> ClassificationResult:
        """Classify query and return result with confidence."""
        pass

    @abstractmethod
    def register_pattern(self, pattern: str, classification: str) -> None:
        """Register new classification pattern dynamically."""
        pass
```

### 2.3 Liskov Substitution Principle (LSP)

**Compliance: STRONG (4/5)**

The specification defines a common worker interface, though not explicitly stated. I recommend formalizing:

```python
class IWorkerAgent(Protocol):
    """Protocol that all worker agents must implement."""

    @property
    def name(self) -> str:
        """Worker agent identifier."""
        ...

    @property
    def capabilities(self) -> list[str]:
        """List of capabilities this worker provides."""
        ...

    async def can_handle(self, state: AgentState) -> bool:
        """Determine if this worker can handle the current state."""
        ...

    async def process(self, state: AgentState) -> AgentState:
        """Process state and return updated state."""
        ...

    async def health_check(self) -> WorkerHealthStatus:
        """Return current health status."""
        ...
```

All worker agents (RAG, Code, Tool) MUST implement this protocol to ensure they are interchangeable where appropriate.

### 2.4 Interface Segregation Principle (ISP)

**Compliance: MODERATE (3.5/5)**

**Issues Identified:**

1. **HealthResponse Model**: Combines service health with dependency health in a single response. Consider separating:
   - `IServiceHealth`: Service-level health
   - `IDependencyHealth`: Dependency-level health
   - `IAggregateHealth`: Combined health reporting

2. **InvokeRequest Model**: Contains optional `config` dict that could contain many unrelated settings. Consider:
   - `IInvokeRequest`: Core invocation parameters
   - `IAgentConfig`: Agent-specific configuration
   - `ISessionConfig`: Session-specific configuration

**Recommended Interface Segregation:**

```python
class IInvokeRequest(Protocol):
    """Core invocation interface."""
    query: str
    thread_id: str | None
    session_id: str | None

class IAgentConfigurable(Protocol):
    """Interface for agent configuration."""
    max_iterations: int
    timeout_seconds: int
    worker_preferences: list[str]

class ISessionConfigurable(Protocol):
    """Interface for session configuration."""
    ttl_seconds: int
    checkpoint_frequency: str
```

### 2.5 Dependency Inversion Principle (DIP)

**Compliance: STRONG (4.5/5)**

The specification correctly:
- Injects configuration via Pydantic Settings
- Uses abstract checkpoint interface (AsyncPostgresSaver)
- Uses langchain abstractions for LLM integration

**Minor Enhancement:**

The PostgreSQL connection in Section "PostgreSQL Checkpoint Configuration" directly instantiates `AsyncConnection`. Recommend abstracting:

```python
class ICheckpointStore(ABC):
    """Abstract interface for checkpoint storage."""

    @abstractmethod
    async def save_checkpoint(self, thread_id: str, state: AgentState) -> str:
        """Save checkpoint and return checkpoint ID."""
        pass

    @abstractmethod
    async def load_checkpoint(self, thread_id: str, checkpoint_id: str | None = None) -> AgentState | None:
        """Load checkpoint, optionally by ID or latest."""
        pass

    @abstractmethod
    async def list_checkpoints(self, thread_id: str) -> list[CheckpointMetadata]:
        """List all checkpoints for a thread."""
        pass
```

### 2.6 SOLID Compliance Summary

| Principle | Score | Status |
|-----------|-------|--------|
| Single Responsibility | 4/5 | COMPLIANT with minor extraction needed |
| Open/Closed | 3.5/5 | NEEDS ATTENTION - abstractions required |
| Liskov Substitution | 4/5 | COMPLIANT - formalize worker protocol |
| Interface Segregation | 3.5/5 | MODERATE - split large interfaces |
| Dependency Inversion | 4.5/5 | STRONG - minor enhancement |
| **Overall** | **3.9/5** | **STRONG with improvements needed** |

---

## 3. Component Interface Definitions

### 3.1 Core Interfaces

```python
"""Core interfaces for hx-lang-server architecture."""

from abc import ABC, abstractmethod
from typing import Protocol, TypeVar, Generic
from dataclasses import dataclass
from enum import Enum


# ============================================================
# State Types
# ============================================================

@dataclass
class AgentState:
    """Immutable agent state representation."""
    messages: list[BaseMessage]
    query_type: str
    current_worker: str | None
    rag_context: str | None
    tool_results: dict | None
    iteration_count: int
    session_id: str
    thread_id: str
    user_id: str | None


class HealthState(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    RECOVERING = "recovering"


@dataclass
class WorkerHealthStatus:
    """Health status for individual worker."""
    worker_name: str
    state: HealthState
    last_check: datetime
    error_count: int
    last_error: str | None


@dataclass
class DependencyHealthStatus:
    """Health status for external dependency."""
    dependency_name: str
    state: HealthState
    latency_ms: float | None
    last_check: datetime


# ============================================================
# Worker Interfaces
# ============================================================

class IWorkerAgent(Protocol):
    """Protocol for all worker agents."""

    @property
    def name(self) -> str: ...

    @property
    def capabilities(self) -> list[str]: ...

    async def can_handle(self, state: AgentState) -> bool: ...

    async def process(self, state: AgentState) -> AgentState: ...

    async def health_check(self) -> WorkerHealthStatus: ...


class IWorkerRegistry(ABC):
    """Abstract registry for worker agents."""

    @abstractmethod
    def register(self, worker: IWorkerAgent) -> None:
        """Register a worker agent."""
        pass

    @abstractmethod
    def get(self, name: str) -> IWorkerAgent | None:
        """Get worker by name."""
        pass

    @abstractmethod
    def list_workers(self) -> list[IWorkerAgent]:
        """List all registered workers."""
        pass

    @abstractmethod
    def get_for_query_type(self, query_type: str) -> IWorkerAgent | None:
        """Get worker appropriate for query type."""
        pass


# ============================================================
# Classification Interfaces
# ============================================================

@dataclass
class ClassificationResult:
    """Query classification result."""
    query_type: str  # "general", "code", "rag", "tool"
    confidence: float  # 0.0 to 1.0
    method: str  # "keyword", "llm", "cached"


class IQueryClassifier(ABC):
    """Abstract interface for query classification."""

    @abstractmethod
    async def classify(self, query: str) -> ClassificationResult:
        """Classify query and return result with confidence."""
        pass

    @abstractmethod
    def register_pattern(self, pattern: str, classification: str) -> None:
        """Register new classification pattern."""
        pass


# ============================================================
# Routing Interfaces
# ============================================================

@dataclass
class ModelEndpoint:
    """Model endpoint configuration."""
    url: str
    model_name: str
    min_context_size: int
    capabilities: list[str]


class IModelRouter(ABC):
    """Abstract interface for model routing."""

    @abstractmethod
    async def route(self, query_type: str, context_size: int) -> ModelEndpoint:
        """Route to appropriate model endpoint."""
        pass

    @abstractmethod
    def register_endpoint(self, query_type: str, endpoint: ModelEndpoint) -> None:
        """Register model endpoint for query type."""
        pass


# ============================================================
# Persistence Interfaces
# ============================================================

@dataclass
class CheckpointMetadata:
    """Checkpoint metadata."""
    checkpoint_id: str
    thread_id: str
    created_at: datetime
    state_version: int


class ICheckpointStore(ABC):
    """Abstract interface for checkpoint persistence."""

    @abstractmethod
    async def save(self, thread_id: str, state: AgentState) -> str:
        """Save checkpoint, return checkpoint ID."""
        pass

    @abstractmethod
    async def load(self, thread_id: str, checkpoint_id: str | None = None) -> AgentState | None:
        """Load checkpoint by thread ID, optionally specific checkpoint."""
        pass

    @abstractmethod
    async def list(self, thread_id: str) -> list[CheckpointMetadata]:
        """List checkpoints for thread."""
        pass

    @abstractmethod
    async def delete(self, thread_id: str, checkpoint_id: str) -> bool:
        """Delete specific checkpoint."""
        pass


class ISessionStore(ABC):
    """Abstract interface for session storage."""

    @abstractmethod
    async def create(self, session_id: str, data: dict, ttl: int) -> None:
        """Create session with TTL."""
        pass

    @abstractmethod
    async def get(self, session_id: str) -> dict | None:
        """Get session data."""
        pass

    @abstractmethod
    async def extend(self, session_id: str, ttl: int) -> bool:
        """Extend session TTL."""
        pass

    @abstractmethod
    async def delete(self, session_id: str) -> bool:
        """Delete session."""
        pass


# ============================================================
# MCP Interfaces
# ============================================================

@dataclass
class ToolResult:
    """Result from MCP tool invocation."""
    success: bool
    result: Any
    error: str | None
    execution_time_ms: float


class IMCPTool(Protocol):
    """Protocol for MCP tool representation."""

    @property
    def name(self) -> str: ...

    @property
    def namespace(self) -> str: ...

    @property
    def fully_qualified_name(self) -> str: ...

    @property
    def description(self) -> str: ...

    @property
    def input_schema(self) -> dict: ...

    async def invoke(self, parameters: dict) -> ToolResult: ...


class IMCPToolRegistry(ABC):
    """Abstract interface for MCP tool management."""

    @abstractmethod
    async def discover(self) -> list[IMCPTool]:
        """Discover all available tools."""
        pass

    @abstractmethod
    async def get(self, fully_qualified_name: str) -> IMCPTool | None:
        """Get tool by fully qualified name."""
        pass

    @abstractmethod
    async def invoke(self, fully_qualified_name: str, parameters: dict) -> ToolResult:
        """Invoke tool directly."""
        pass

    @abstractmethod
    def register_server(self, server_name: str, url: str, transport: str) -> None:
        """Register new MCP server."""
        pass


# ============================================================
# Supervisor Interface
# ============================================================

class ISupervisorAgent(ABC):
    """Abstract interface for supervisor agent."""

    @abstractmethod
    async def invoke(self, request: InvokeRequest) -> InvokeResponse:
        """Invoke agent with request."""
        pass

    @abstractmethod
    async def stream(self, request: InvokeRequest) -> AsyncIterator[StreamEvent]:
        """Stream agent execution events."""
        pass

    @abstractmethod
    async def get_state(self, thread_id: str) -> AgentState | None:
        """Get current state for thread."""
        pass

    @abstractmethod
    async def health_check(self) -> SupervisorHealthState:
        """Get supervisor health state."""
        pass

    @abstractmethod
    def register_worker(self, worker: IWorkerAgent) -> None:
        """Register worker agent."""
        pass
```

### 3.2 Interface Dependency Graph

```
                    ISupervisorAgent
                          |
        +-----------------+------------------+
        |                 |                  |
  IWorkerRegistry   IQueryClassifier   IModelRouter
        |                                    |
   IWorkerAgent                       ModelEndpoint
        |
   +----+----+
   |         |
IMCPToolRegistry  ICheckpointStore
   |                   |
IMCPTool         ISessionStore
```

---

## 4. Failover Semantics

### 4.1 Supervisor Failover Protocol

The following failover protocol addresses the HIGH severity concern (H-001) from my charter review:

#### 4.1.1 Failure Detection

| Component | Detection Method | Detection Threshold |
|-----------|-----------------|---------------------|
| Worker Agent | Health check timeout | 3 consecutive failures (30 seconds) |
| PostgreSQL | Connection pool health | 1 failure + retry |
| Redis | Connection health | 2 consecutive failures |
| Ollama | HTTP health check | 3 consecutive failures |
| LightRAG | HTTP health check | 3 consecutive failures |
| MCP Gateway | HTTP health check | 3 consecutive failures |

#### 4.1.2 Failover Actions

```
+-------------------+     +-------------------+
|   Worker Failure  |---->|   Mark Degraded   |
+-------------------+     +--------+----------+
                                   |
                                   v
                          +--------+----------+
                          | Route to Alternate |
                          | (if available)     |
                          +--------+----------+
                                   |
                          +--------v----------+
                          |  Queue Failed     |
                          |  Requests         |
                          +--------+----------+
                                   |
                          +--------v----------+
                          |  Retry Worker     |
                          |  (3 attempts)     |
                          +--------+----------+
                                   |
              +--------------------+--------------------+
              |                                         |
              v                                         v
     +--------+----------+                    +---------+---------+
     |  Worker Recovered |                    |  Escalate to      |
     |  (Resume Normal)  |                    |  UNHEALTHY State  |
     +-------------------+                    +-------------------+
```

#### 4.1.3 State Recovery Protocol

When supervisor restarts after failure:

1. **Checkpoint Rehydration**: Load last known state from PostgreSQL
2. **Session Validation**: Verify active sessions in Redis still valid
3. **Worker Registration**: Re-register all worker agents
4. **Dependency Verification**: Verify all external dependencies reachable
5. **Request Resume**: Process any queued requests from before failure

```python
class SupervisorRecoveryProtocol:
    """Recovery protocol for supervisor agent restart."""

    async def recover(self) -> RecoveryResult:
        """Execute full recovery protocol."""

        # Step 1: Rehydrate checkpoints
        active_threads = await self.checkpoint_store.list_active_threads()
        for thread_id in active_threads:
            state = await self.checkpoint_store.load(thread_id)
            if state:
                await self.state_cache.set(thread_id, state)

        # Step 2: Validate sessions
        await self.session_store.prune_expired()

        # Step 3: Re-register workers
        for worker in self.worker_registry.list_workers():
            await worker.health_check()

        # Step 4: Verify dependencies
        dependency_status = await self._check_all_dependencies()

        # Step 5: Resume queued requests
        if dependency_status.all_healthy:
            await self._process_queued_requests()

        return RecoveryResult(
            threads_recovered=len(active_threads),
            workers_healthy=dependency_status.workers_healthy,
            dependencies_healthy=dependency_status.all_healthy
        )
```

#### 4.1.4 Maximum Task Duration Limits

| Task Type | Max Duration | Timeout Action |
|-----------|--------------|----------------|
| Simple Query | 30 seconds | Timeout error, checkpoint state |
| RAG Query | 60 seconds | Timeout error, checkpoint state |
| Tool Invocation | 120 seconds | Timeout error, checkpoint partial result |
| Multi-step Workflow | 300 seconds | Checkpoint per step, timeout at step level |

#### 4.1.5 Orphan Detection and Cleanup

```python
class OrphanDetector:
    """Detects and cleans up orphaned workflows."""

    MAX_CHECKPOINT_AGE_HOURS = 24
    MAX_SESSION_INACTIVE_HOURS = 2

    async def detect_orphans(self) -> list[OrphanedWorkflow]:
        """Identify workflows that appear orphaned."""
        orphans = []

        # Check for stale checkpoints
        stale_checkpoints = await self.checkpoint_store.find_older_than(
            hours=self.MAX_CHECKPOINT_AGE_HOURS
        )

        for checkpoint in stale_checkpoints:
            # Verify no active session exists
            session = await self.session_store.get(checkpoint.session_id)
            if not session:
                orphans.append(OrphanedWorkflow(
                    thread_id=checkpoint.thread_id,
                    last_activity=checkpoint.created_at,
                    reason="stale_checkpoint_no_session"
                ))

        return orphans

    async def cleanup_orphans(self, orphans: list[OrphanedWorkflow]) -> int:
        """Clean up identified orphans."""
        cleaned = 0
        for orphan in orphans:
            await self.checkpoint_store.archive(orphan.thread_id)
            cleaned += 1
        return cleaned
```

### 4.2 Worker Agent Recovery Patterns

#### 4.2.1 RAG Agent Recovery

```python
class RAGAgentRecovery:
    """Recovery patterns for RAG Agent failures."""

    async def recover_from_lightrag_failure(self, state: AgentState) -> AgentState:
        """Handle LightRAG unavailability."""
        # Fallback: Return cached context if available
        cached_context = await self.cache.get(f"rag:{state.thread_id}")
        if cached_context:
            return state.with_rag_context(cached_context, source="cache")

        # Fallback: Proceed without RAG context, inform user
        return state.with_warning("RAG unavailable, proceeding with base knowledge")
```

#### 4.2.2 Code Agent Recovery

```python
class CodeAgentRecovery:
    """Recovery patterns for Code Agent failures."""

    async def recover_from_ollama2_failure(self, state: AgentState) -> AgentState:
        """Handle Ollama2 (Code LLM) unavailability."""
        # Fallback: Route to Ollama1 with code-specific prompt enhancement
        return state.with_routing_override(
            target="ollama1",
            prompt_prefix="[Code Task] "
        )
```

#### 4.2.3 Tool Agent Recovery

```python
class ToolAgentRecovery:
    """Recovery patterns for Tool Agent failures."""

    async def recover_from_mcp_failure(self, state: AgentState) -> AgentState:
        """Handle MCP Gateway unavailability."""
        # No fallback for tool execution - tools are explicit capabilities
        return state.with_error(
            "MCP tools unavailable",
            recovery_action="retry_after_interval",
            retry_interval_seconds=60
        )
```

---

## 5. ADR Recommendations

### 5.1 Required ADRs

Based on my charter review and this specification analysis, the following ADRs are REQUIRED:

| ADR ID | Title | Priority | Status |
|--------|-------|----------|--------|
| ADR-001 | LangGraph Supervisor Pattern Selection | HIGH | Draft Provided |
| ADR-002 | Dual Persistence Strategy (PostgreSQL + Redis) | HIGH | Draft Provided |
| ADR-003 | Model Routing Strategy | HIGH | Draft Provided |
| ADR-004 | MCP Tool Integration Architecture | MEDIUM | Draft Provided |
| ADR-005 | Circuit Breaker Implementation | MEDIUM | Deferred to Planning |
| ADR-006 | n8n Integration Strategy | MEDIUM | Deferred to Phase 2 |

### 5.2 ADR-001: LangGraph Supervisor Pattern Selection

```markdown
# ADR-001: LangGraph Supervisor Pattern Selection

## Status
PROPOSED

## Context
hx-lang-server requires a multi-agent orchestration pattern to coordinate specialized worker agents (RAG, Code, Tool) for complex AI workflows. The system must support:
- Dynamic routing based on query classification
- State persistence across service restarts
- Human-in-the-loop approval workflows
- Iteration and conditional logic

## Decision
We will use the **LangGraph Supervisor Pattern** with a central supervisor agent that:
1. Receives all incoming requests
2. Classifies queries and routes to appropriate workers
3. Manages state transitions and checkpointing
4. Coordinates multi-step workflows

## Alternatives Considered

### Alternative 1: Flat Agent Pool
- All agents receive all requests and self-select
- Rejected: No central coordination, potential conflicts, no state management

### Alternative 2: Hierarchical Multi-Supervisor
- Multiple supervisors for different domains
- Rejected: Overcomplicated for current requirements, adds coordination overhead

### Alternative 3: Event-Driven Agent Mesh
- Agents communicate via message queue
- Rejected: Adds infrastructure complexity, harder to trace execution

## Consequences

### Positive
- Clear execution flow, easy to trace and debug
- Centralized state management simplifies persistence
- Single point for policy enforcement (rate limiting, authorization)
- Well-supported by LangGraph framework

### Negative
- Supervisor can become bottleneck at scale
- Single point of failure (mitigated by checkpoint persistence)
- All requests serialized through supervisor

## Validation
- Load test with 10 concurrent sessions
- Measure supervisor latency overhead
- Verify checkpoint recovery after failure

## References
- LangGraph Documentation: Multi-Agent Patterns
- Charter Section: Architecture Overview
```

### 5.3 ADR-002: Dual Persistence Strategy

```markdown
# ADR-002: Dual Persistence Strategy (PostgreSQL + Redis)

## Status
PROPOSED

## Context
hx-lang-server requires state management for:
1. **Durable State**: Conversation history, checkpoints, agent state snapshots
2. **Ephemeral State**: Active sessions, caches, rate limiting counters

Different access patterns require different storage characteristics.

## Decision
We will use a **dual persistence strategy**:
- **PostgreSQL** via `langgraph-checkpoint-postgres` for durable state
- **Redis** for ephemeral session state and caching

### PostgreSQL Responsibilities
- Conversation checkpoints (30-day retention)
- Agent state snapshots
- Thread branching history
- Schema migrations via checkpoint library

### Redis Responsibilities
- Active session data (1-hour TTL)
- LLM response cache (5-minute TTL)
- RAG result cache (10-minute TTL)
- Rate limiting counters (1-minute TTL)
- Query classification cache (30-minute TTL)

## Alternatives Considered

### Alternative 1: PostgreSQL Only
- Use PostgreSQL for all state
- Rejected: Poor performance for ephemeral high-frequency access patterns

### Alternative 2: Redis Only
- Use Redis for all state with persistence
- Rejected: Risk of data loss, not suitable for long-term checkpoint storage

### Alternative 3: SQLite + Redis
- SQLite for checkpoints, Redis for sessions
- Rejected: SQLite limitations for concurrent access

## Consequences

### Positive
- Each store optimized for its access pattern
- Redis provides low-latency session access
- PostgreSQL provides ACID guarantees for checkpoints
- Clear separation of concerns

### Negative
- Two systems to maintain
- Potential consistency issues between stores
- Additional operational complexity

## Validation
- Verify checkpoint persistence survives PostgreSQL restart
- Verify session data correctly expires in Redis
- Verify system operates correctly if Redis unavailable (degraded mode)

## References
- LangGraph Checkpoint Documentation
- Charter Section: State Management Requirements
```

### 5.4 ADR-003: Model Routing Strategy

```markdown
# ADR-003: Model Routing Strategy

## Status
PROPOSED

## Context
hx-lang-server must route queries to appropriate Ollama servers:
- hx-ollama1-server: General LLM (gemma3:27b)
- hx-ollama2-server: Code LLM (qwen3-coder:30b)
- hx-ollama3-server: Embeddings (via LightRAG only)

Routing decisions affect response quality and latency.

## Decision
We will use a **keyword-based classifier with LLM fallback**:

### Fast Path (Keyword Matching)
```python
CODE_KEYWORDS = ["code", "function", "class", "debug", "error", ...]
RAG_KEYWORDS = ["search", "find", "document", "knowledge", ...]
TOOL_KEYWORDS = ["crawl", "fetch", "scrape", "web", "url", ...]
```

### Slow Path (LLM Classification)
For ambiguous queries, use a lightweight LLM call to classify.

### Routing Table
| Classification | Target | Model | Min Context |
|----------------|--------|-------|-------------|
| general | ollama1 | gemma3:27b | 8KB |
| code | ollama2 | qwen3-coder:30b | 16KB |
| rag | ollama1 | gemma3:27b | 32KB |
| tool | ollama1 | gemma3:27b | 8KB |

### Confidence Thresholds
- Keyword match: confidence = 0.8
- LLM classification: confidence = variable (0.5-1.0)
- Below 0.5 confidence: default to "general"

## Alternatives Considered

### Alternative 1: LLM Classification Only
- Always use LLM to classify
- Rejected: Adds latency to every request

### Alternative 2: Embedding-Based Classification
- Use embeddings to match query to category
- Rejected: Requires additional infrastructure, overkill for current needs

### Alternative 3: Static Routing
- Route based on explicit user selection
- Rejected: Poor user experience, doesn't support automatic optimization

## Consequences

### Positive
- Fast classification for common patterns
- Accurate classification for ambiguous queries
- Extensible (add keywords without code changes)

### Negative
- Keyword lists require maintenance
- LLM fallback adds latency for edge cases
- Potential misclassification for novel query patterns

## Validation
- Test classification accuracy on 100 sample queries
- Measure classification latency (target: <10ms for keyword, <500ms for LLM)
- Verify fallback behavior when Ollama unavailable

## References
- Specification Section: Query Classification Mechanism
- Charter Section: Multi-Ollama Model Routing
```

### 5.5 ADR-004: MCP Tool Integration Architecture

```markdown
# ADR-004: MCP Tool Integration Architecture

## Status
PROPOSED

## Context
hx-lang-server must integrate with MCP tools via the FastMCP gateway. Requirements:
- Dynamic tool discovery
- Namespace-prefixed tool invocation
- Extensibility for new MCP servers
- Tool Agent must remain unchanged when tools are added

## Decision
We will implement an **MCP Tool Registry abstraction**:

### Architecture
```
Tool Agent --> IMCPToolRegistry --> MultiServerMCPClient --> FastMCP Gateway
```

### Interface Design
```python
class IMCPToolRegistry(ABC):
    async def discover(self) -> list[IMCPTool]
    async def get(self, fully_qualified_name: str) -> IMCPTool | None
    async def invoke(self, fully_qualified_name: str, parameters: dict) -> ToolResult
    def register_server(self, server_name: str, url: str, transport: str) -> None
```

### Namespace Handling
- All tools prefixed with server name: `{server}__{tool_name}`
- Registry handles prefix resolution
- Tool Agent uses fully qualified names

### Initial MCP Servers
- fastmcp: `http://hx-fastmcp-server.hx.dev.local:8000`
  - crawl4ai__smart_crawl_url
  - docling__convert_document

## Alternatives Considered

### Alternative 1: Direct MCP Client Usage
- Tool Agent directly uses MultiServerMCPClient
- Rejected: Violates Open/Closed Principle, hard to test

### Alternative 2: Plugin Architecture
- Each MCP tool as separate plugin
- Rejected: Overcomplicated, MCP already provides discovery

### Alternative 3: Configuration-Based Registration
- Define tools in config file
- Rejected: Loses dynamic discovery capability

## Consequences

### Positive
- Tool Agent unchanged when new tools added
- Easy to test with mock registry
- Supports dynamic tool discovery
- Clear abstraction boundary

### Negative
- Additional abstraction layer
- Must handle namespace prefixes correctly
- Tool capability changes require registry refresh

## Validation
- Verify tool discovery returns expected tools
- Verify tool invocation with namespace prefix works
- Verify new tool registration without code changes
- Test with mock registry for unit tests

## References
- langchain-mcp-adapters documentation
- Specification Section: MCP Client Integration
```

---

## 6. Specification Validation and Corrections

### 6.1 Validated Sections

The following specification sections are architecturally sound and require no changes:

| Section | Assessment |
|---------|------------|
| Executive Summary | VALID |
| Service Purpose & Requirements | VALID |
| Functional Requirements | VALID |
| Non-Functional Requirements | VALID |
| Node Requirements | VALID |
| System Architecture Diagram | VALID |
| State Persistence Architecture | VALID |
| PostgreSQL Checkpoint Configuration | VALID |
| Redis Integration | VALID |
| API Specification | VALID |
| Dependencies | VALID |
| Configuration Management | VALID |
| Security Requirements | VALID |
| systemd Service Configuration | VALID |
| Testing Strategy | VALID |
| Success Criteria | VALID |

### 6.2 Corrections Required

#### 6.2.1 Redis Key Schema Correction

**Current (Section: Redis Key Schema):**
```
| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `session:{session_id}` | Active session data | 1 hour |
```

**Correction Required:**
Add namespace prefix per HX-Infrastructure standards:

```
| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `hx-lang-server:session:{session_id}` | Active session data | 1 hour |
| `hx-lang-server:thread:{thread_id}:messages` | Message cache | 1 hour |
| `hx-lang-server:cache:llm:{hash}` | LLM response cache | 5 minutes |
| `hx-lang-server:cache:rag:{hash}` | RAG result cache | 10 minutes |
| `hx-lang-server:ratelimit:{user_id}` | Rate limiting | 1 minute |
| `hx-lang-server:classification:{hash}` | Query classification cache | 30 minutes |
```

**Rationale:** Prevents key collision with other services using the same Redis instance (M-003 from charter review).

#### 6.2.2 State Schema Version Field

**Current (Section: Agent State TypedDict):**
Missing version field for schema evolution.

**Correction Required:**
Add version field:

```python
class AgentState(TypedDict):
    """Core state schema for LangGraph supervisor."""

    # Schema version for backward compatibility
    schema_version: int  # Current: 1

    # ... rest of fields unchanged
```

**Rationale:** Supports schema evolution per FR-009 requirement.

#### 6.2.3 Circuit Breaker Configuration Addition

**Current (Section: Missing):**
No circuit breaker specification despite architecture standards requirement.

**Addition Required:**
Add section after "Monitoring & Observability":

```markdown
## Circuit Breaker Configuration

### Circuit Breaker Settings

| Dependency | Failure Threshold | Open Duration | Half-Open Probes |
|------------|-------------------|---------------|------------------|
| Ollama (General) | 5 failures / 30s | 60 seconds | 1 request / 10s |
| Ollama (Code) | 5 failures / 30s | 60 seconds | 1 request / 10s |
| LightRAG | 3 failures / 30s | 60 seconds | 1 request / 10s |
| MCP Gateway | 5 failures / 30s | 60 seconds | 1 request / 10s |
| PostgreSQL | 2 failures / 10s | 30 seconds | 1 request / 5s |
| Redis | 3 failures / 10s | 30 seconds | 1 request / 5s |

### Implementation

```python
from tenacity import retry, stop_after_attempt, wait_exponential
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=60)
@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
async def call_ollama(url: str, prompt: str) -> str:
    """Call Ollama with circuit breaker and retry."""
    ...
```
```

**Rationale:** Addresses L-001 from charter review.

### 6.3 Enhancement Recommendations

#### 6.3.1 Add Supervisor Health Protocol Section

Insert after "systemd Service Configuration":

```markdown
## Supervisor Health Protocol

### Health States

| State | Condition | API Response |
|-------|-----------|--------------|
| HEALTHY | All workers and dependencies operational | 200 OK |
| DEGRADED | 1+ workers unavailable OR 1+ dependencies degraded | 200 OK (partial) |
| RECOVERING | Attempting to restore failed components | 503 Retry-After |
| UNHEALTHY | Critical failure, cannot process requests | 503 Service Unavailable |

### Recovery Protocol

1. **Checkpoint Rehydration**: Load last state from PostgreSQL
2. **Session Validation**: Verify Redis sessions
3. **Worker Registration**: Re-register all workers
4. **Dependency Verification**: Check all external services
5. **Request Resume**: Process queued requests

### Maximum Task Duration

| Task Type | Max Duration | Timeout Action |
|-----------|--------------|----------------|
| Simple Query | 30 seconds | Timeout error |
| RAG Query | 60 seconds | Timeout error |
| Tool Invocation | 120 seconds | Timeout error |
| Multi-step Workflow | 300 seconds | Per-step timeout |
```

**Rationale:** Addresses H-001 from charter review.

#### 6.3.2 Add Model Routing Decision Boundary Section

Insert after "Query Classification Mechanism":

```markdown
### Routing Decision Boundaries

#### Classification Confidence Thresholds

| Confidence Range | Decision |
|------------------|----------|
| >= 0.8 | Use classification result |
| 0.5 - 0.8 | Use classification with warning log |
| < 0.5 | Default to "general", log for review |

#### Fallback Routing

When primary route unavailable:

| Primary | Fallback | Condition |
|---------|----------|-----------|
| ollama2 (code) | ollama1 | ollama2 health check fails |
| ollama1 (general) | NONE | Service degraded |
| LightRAG | Cache | LightRAG unavailable |
| MCP Gateway | NONE | Tools unavailable |
```

**Rationale:** Addresses H-003 from charter review.

---

## 7. Summary and Next Steps

### 7.1 Architecture Validation Summary

| Aspect | Status | Notes |
|--------|--------|-------|
| Overall Architecture | VALID | Well-structured, appropriate for requirements |
| Component Boundaries | VALID | Clear separation of concerns |
| Technology Selection | VALID | Coherent ecosystem |
| Integration Patterns | VALID | HTTP-based, loosely coupled |
| State Management | VALID | Dual persistence appropriate |
| Scalability | APPROPRIATE | Single-instance acceptable for dev |

### 7.2 SOLID Compliance Summary

| Principle | Compliance | Action Required |
|-----------|------------|-----------------|
| SRP | 4/5 | Extract QueryClassifier |
| OCP | 3.5/5 | Add IMCPToolRegistry, IModelRouter |
| LSP | 4/5 | Formalize IWorkerAgent protocol |
| ISP | 3.5/5 | Split large interfaces |
| DIP | 4.5/5 | Abstract checkpoint store |

### 7.3 Corrections Checklist

- [ ] Add `hx-lang-server:` namespace prefix to Redis keys
- [ ] Add `schema_version` field to AgentState TypedDict
- [ ] Add Circuit Breaker Configuration section
- [ ] Add Supervisor Health Protocol section
- [ ] Add Model Routing Decision Boundary section

### 7.4 ADR Creation Checklist

- [ ] Create ADR-001: LangGraph Supervisor Pattern Selection
- [ ] Create ADR-002: Dual Persistence Strategy
- [ ] Create ADR-003: Model Routing Strategy
- [ ] Create ADR-004: MCP Tool Integration Architecture
- [ ] Defer ADR-005 (Circuit Breaker) to Planning Phase
- [ ] Defer ADR-006 (n8n Integration) to Phase 2

### 7.5 Interface Implementation Checklist

The following interfaces MUST be implemented during development:

- [ ] `IWorkerAgent` - Protocol for all worker agents
- [ ] `IWorkerRegistry` - Worker agent registration and lookup
- [ ] `IQueryClassifier` - Query classification abstraction
- [ ] `IModelRouter` - Model routing abstraction
- [ ] `ICheckpointStore` - Checkpoint persistence abstraction
- [ ] `ISessionStore` - Session management abstraction
- [ ] `IMCPTool` - MCP tool protocol
- [ ] `IMCPToolRegistry` - MCP tool management abstraction
- [ ] `ISupervisorAgent` - Supervisor agent abstraction

---

## Approval

I approve this specification for progression to Planning Phase with the corrections and enhancements noted above.

**Conditions:**
1. Redis key namespace prefix MUST be implemented
2. State schema versioning MUST be implemented
3. Circuit breaker configuration MUST be added to specification
4. Supervisor health protocol MUST be added to specification
5. ADRs 001-004 MUST be created before implementation begins

---

**Signature:** Alex Rivera
**Role:** Platform Architect
**Date:** 2025-12-01

---

## Appendix A: Interface Implementation Examples

### A.1 IWorkerAgent Implementation Example

```python
class RAGAgent(IWorkerAgent):
    """RAG Worker Agent implementation."""

    def __init__(
        self,
        lightrag_client: ILightRAGClient,
        ollama_client: IOllamaClient,
        cache: ISessionStore,
    ):
        self._lightrag = lightrag_client
        self._ollama = ollama_client
        self._cache = cache

    @property
    def name(self) -> str:
        return "rag_agent"

    @property
    def capabilities(self) -> list[str]:
        return ["rag", "search", "knowledge_retrieval"]

    async def can_handle(self, state: AgentState) -> bool:
        return state.query_type == "rag"

    async def process(self, state: AgentState) -> AgentState:
        # Retrieve context from LightRAG
        context = await self._lightrag.query(
            state.messages[-1].content,
            mode="hybrid"
        )

        # Generate response with context
        response = await self._ollama.generate(
            prompt=self._build_prompt(state.messages, context),
            model="gemma3:27b"
        )

        return state.with_update(
            rag_context=context,
            messages=state.messages + [AIMessage(content=response)]
        )

    async def health_check(self) -> WorkerHealthStatus:
        try:
            lightrag_ok = await self._lightrag.ping()
            ollama_ok = await self._ollama.ping()

            if lightrag_ok and ollama_ok:
                return WorkerHealthStatus(
                    worker_name=self.name,
                    state=HealthState.HEALTHY,
                    last_check=datetime.utcnow(),
                    error_count=0,
                    last_error=None
                )
            else:
                return WorkerHealthStatus(
                    worker_name=self.name,
                    state=HealthState.DEGRADED,
                    last_check=datetime.utcnow(),
                    error_count=1,
                    last_error="Dependency unavailable"
                )
        except Exception as e:
            return WorkerHealthStatus(
                worker_name=self.name,
                state=HealthState.UNHEALTHY,
                last_check=datetime.utcnow(),
                error_count=1,
                last_error=str(e)
            )
```

### A.2 IMCPToolRegistry Implementation Example

```python
class MCPToolRegistry(IMCPToolRegistry):
    """MCP Tool Registry implementation using langchain-mcp-adapters."""

    def __init__(self):
        self._client = MultiServerMCPClient(servers={})
        self._tools: dict[str, IMCPTool] = {}
        self._initialized = False

    async def discover(self) -> list[IMCPTool]:
        if not self._initialized:
            await self._initialize()

        raw_tools = await self._client.get_tools()
        self._tools = {
            tool.name: MCPToolWrapper(tool)
            for tool in raw_tools
        }
        return list(self._tools.values())

    async def get(self, fully_qualified_name: str) -> IMCPTool | None:
        if not self._tools:
            await self.discover()
        return self._tools.get(fully_qualified_name)

    async def invoke(self, fully_qualified_name: str, parameters: dict) -> ToolResult:
        tool = await self.get(fully_qualified_name)
        if not tool:
            return ToolResult(
                success=False,
                result=None,
                error=f"Tool not found: {fully_qualified_name}",
                execution_time_ms=0
            )

        start = time.perf_counter()
        try:
            result = await tool.invoke(parameters)
            return ToolResult(
                success=True,
                result=result,
                error=None,
                execution_time_ms=(time.perf_counter() - start) * 1000
            )
        except Exception as e:
            return ToolResult(
                success=False,
                result=None,
                error=str(e),
                execution_time_ms=(time.perf_counter() - start) * 1000
            )

    def register_server(self, server_name: str, url: str, transport: str) -> None:
        self._client.servers[server_name] = {
            "transport": transport,
            "url": url,
        }
        self._initialized = False  # Force re-discovery
```

---

**End of Architecture Contribution**
