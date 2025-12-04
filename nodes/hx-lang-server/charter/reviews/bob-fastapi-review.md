# Charter Review: Bob (FastAPI SME)

**Review Date:** 2025-12-01
**Charter Version:** 1.1
**Reviewer Role:** FastAPI SME

## Executive Summary

The hx-lang-server charter presents a well-structured vision for a LangGraph-based orchestration hub with FastAPI as the API layer. The architecture is fundamentally sound, with appropriate technology choices and clear integration points. However, the charter would benefit from more specific guidance on FastAPI patterns for async LangGraph integration, middleware requirements for production readiness, and SOLID principles application at the API layer.

## Strengths

- **Clear API Wrapper Role**: The FastAPI wrapper is correctly positioned as the API exposure layer, separate from the LangGraph orchestration logic (Lines 263-264). This separation of concerns aligns with Single Responsibility Principle.

- **Appropriate Technology Stack**: The choice of FastAPI with Pydantic validation and async support (Lines 271-282) is optimal for an LLM orchestration service that requires high concurrency with I/O-bound operations.

- **Phased Delivery Approach**: Breaking the project into Phase 1 (Core LangGraph + RAG) and Phase 2 (n8n + MCP) allows incremental API endpoint development and testing.

- **PostgreSQL Checkpointing Integration**: Using `langgraph-checkpoint-postgres` with `psycopg3` async driver (Lines 277, 281) demonstrates awareness of async patterns needed for non-blocking state persistence.

- **Redis Session Management**: Integration with Redis for ephemeral state (Lines 286-290) complements the durable PostgreSQL storage and follows industry best practices for session handling.

- **n8n Integration Consideration**: The HTTP endpoint + webhook + custom node approach (Lines 93, 157-159) provides flexible integration options for workflow automation.

- **SOLID Principles Mandate**: Explicit requirement for SOLID OOP principles (Line 135) sets a quality standard for implementation.

## Concerns / Risks

### HIGH Severity

1. **Missing API Endpoint Specification**: The charter does not define the specific FastAPI endpoints required. Without clear endpoint contracts, there is risk of scope creep and inconsistent API design.
   - **Recommendation**: Define core endpoints in specification phase:
     - `POST /v1/invoke` - Synchronous agent invocation
     - `POST /v1/invoke/async` - Async invocation with callback
     - `GET /v1/threads/{thread_id}` - Thread state retrieval
     - `POST /v1/threads/{thread_id}/messages` - Continue conversation
     - `GET /v1/health` - Health check endpoint
     - `GET /v1/health/ready` - Readiness probe
     - `POST /v1/webhooks/n8n` - n8n webhook receiver

2. **Async/Await Pattern Complexity with LangGraph**: LangGraph operations are inherently I/O-bound (LLM calls, database checkpoints, tool invocations). The charter should explicitly address the async execution model.
   - **Recommendation**: All path operations interacting with LangGraph MUST use `async def` with proper awaiting. This includes:
     ```python
     @app.post("/v1/invoke")
     async def invoke_agent(request: InvokeRequest) -> InvokeResponse:
         result = await graph.ainvoke(...)  # Use ainvoke, not invoke
         return result
     ```

3. **Missing Request Timeout Configuration**: LLM operations can be slow (5+ seconds as noted in Line 183). Without proper timeout handling, slow requests can exhaust connection pools.
   - **Recommendation**: Implement request timeout middleware and document expected response times per endpoint type.

### MEDIUM Severity

4. **No Middleware Stack Definition**: The charter mentions "custom endpoints and middleware" (Line 264) but does not specify which middleware components are required.
   - **Recommendation**: Define required middleware stack:
     - `CORSMiddleware` - For n8n and future AG-UI integration
     - Request ID injection middleware - For distributed tracing
     - Request logging middleware - For operational visibility
     - Error handling middleware - For consistent error responses
     - Rate limiting middleware (optional) - For resource protection

5. **Pydantic Model Strategy Not Defined**: While Pydantic is listed (Line 280), there is no guidance on model organization for the complex LangGraph state structures.
   - **Recommendation**: Define Pydantic model hierarchy:
     - `schemas/requests/` - Input validation models
     - `schemas/responses/` - Output serialization models
     - `schemas/state/` - LangGraph state models
     - `schemas/agents/` - Agent configuration models

6. **Missing Error Response Contract**: The charter does not define how errors from LangGraph agents, Ollama timeouts, or integration failures should be returned to clients.
   - **Recommendation**: Define standard error response schema following RFC 7807 Problem Details pattern.

7. **No Authentication/Authorization Discussion**: For a development environment (Line 128), this may be acceptable, but the charter should explicitly state the security posture.
   - **Recommendation**: Document that authentication is out of scope for Phase 1 dev environment, but design endpoints to support future authentication via FastAPI dependency injection.

### LOW Severity

8. **Background Task Strategy Missing**: Long-running agent workflows may benefit from FastAPI's `BackgroundTasks` or external task queues. This is not addressed.
   - **Recommendation**: For synchronous webhook callbacks, consider `BackgroundTasks` pattern for non-blocking response.

9. **OpenAPI Documentation Customization**: The charter should specify OpenAPI documentation requirements for n8n integration and developer experience.
   - **Recommendation**: Configure custom OpenAPI metadata, operation summaries, and examples for all endpoints.

10. **Health Check Depth Not Specified**: Line 187 mentions "Integration connectivity: Target all services reachable" but does not detail health check implementation.
    - **Recommendation**: Define health check levels:
      - `/health` - Basic liveness (FastAPI responsive)
      - `/health/ready` - Readiness (all dependencies connected)
      - `/health/deep` - Deep health (sample LLM invocation)

## Recommendations

### API Architecture Recommendations

1. **Use FastAPI Router Organization**:
   ```
   app/
   +-- main.py              # FastAPI app factory
   +-- routers/
   |   +-- invoke.py        # Agent invocation endpoints
   |   +-- threads.py       # Thread/conversation management
   |   +-- health.py        # Health check endpoints
   |   +-- webhooks.py      # n8n webhook receivers
   +-- dependencies/
   |   +-- langgraph.py     # LangGraph graph dependency
   |   +-- database.py      # PostgreSQL session dependency
   |   +-- redis.py         # Redis client dependency
   +-- middleware/
   |   +-- request_id.py    # Request correlation
   |   +-- logging.py       # Structured logging
   +-- schemas/
   |   +-- invoke.py        # Request/response models
   |   +-- thread.py        # Thread state models
   |   +-- error.py         # Error response models
   ```

2. **Implement Dependency Injection for LangGraph**:
   ```python
   async def get_graph() -> CompiledGraph:
       """Dependency that provides the LangGraph instance."""
       return app.state.graph

   @app.post("/v1/invoke")
   async def invoke(
       request: InvokeRequest,
       graph: CompiledGraph = Depends(get_graph)
   ) -> InvokeResponse:
       ...
   ```

3. **Configure CORS for n8n Integration**:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["http://hx-n8n-server.hx.dev.local"],
       allow_methods=["GET", "POST"],
       allow_headers=["*"],
       allow_credentials=True
   )
   ```

4. **Use Lifespan Context for Resource Management**:
   ```python
   @asynccontextmanager
   async def lifespan(app: FastAPI):
       # Startup: Initialize connections
       app.state.pg_pool = await create_pg_pool()
       app.state.redis = await create_redis_client()
       app.state.graph = build_graph()
       yield
       # Shutdown: Cleanup
       await app.state.pg_pool.close()
       await app.state.redis.close()
   ```

### Webhook Integration Recommendations

5. **n8n Webhook Pattern**: For n8n webhook callbacks (async workflow completion), implement:
   ```python
   @router.post("/v1/invoke/async")
   async def invoke_async(
       request: AsyncInvokeRequest,
       background_tasks: BackgroundTasks
   ) -> AsyncInvokeResponse:
       task_id = str(uuid4())
       background_tasks.add_task(
           execute_and_callback,
           task_id,
           request.callback_url,
           request.input
       )
       return AsyncInvokeResponse(task_id=task_id, status="accepted")
   ```

### Testing Recommendations

6. **API Testing Strategy**: Use `httpx.AsyncClient` with FastAPI's TestClient for async endpoint testing:
   ```python
   @pytest.mark.asyncio
   async def test_invoke_endpoint():
       async with AsyncClient(app=app, base_url="http://test") as client:
           response = await client.post("/v1/invoke", json={...})
           assert response.status_code == 200
   ```

## API Design Assessment

The charter correctly positions FastAPI as a thin API layer over LangGraph, which is the appropriate architectural pattern. The API should:

1. **Be Stateless**: All state should reside in PostgreSQL checkpoints and Redis sessions, not in the FastAPI process.

2. **Support Streaming**: Consider adding Server-Sent Events (SSE) endpoints for real-time agent output streaming - this is not mentioned in the charter but would significantly improve user experience.

3. **Provide OpenAPI First**: Generate complete OpenAPI schemas that n8n and future AG-UI can consume for integration.

4. **Handle Concurrency Properly**: With multiple Ollama servers (Lines 251-255), the API should use async patterns to maximize throughput while respecting individual Ollama instance capacity.

The architecture diagram (Lines 229-261) correctly shows FastAPI as the entry point, with clear separation between the API layer and the LangGraph orchestration layer. This is a sound design that supports future scalability.

## SOLID Principles in FastAPI

The charter mandates SOLID principles (Line 135). Here is how they apply to the FastAPI layer:

### Single Responsibility Principle (SRP)
- Each router should handle one resource type (invoke, threads, health)
- Each dependency should provide one type of resource (database session, LangGraph instance)
- Each middleware should handle one cross-cutting concern

### Open/Closed Principle (OCP)
- Use FastAPI's dependency injection to extend behavior without modifying existing endpoints
- Design Pydantic models with inheritance for extensibility
- Use abstract base classes for agent interfaces

### Liskov Substitution Principle (LSP)
- All agent implementations should be interchangeable through common interfaces
- Response models should maintain consistent structure across agent types

### Interface Segregation Principle (ISP)
- Define focused dependencies rather than large "god" dependencies
- Split routers by client needs (n8n webhooks vs direct API consumers)
- Create targeted Pydantic models rather than all-encompassing ones

### Dependency Inversion Principle (DIP)
- FastAPI endpoints should depend on abstractions (graph protocol), not concrete implementations
- Use dependency injection for all external services (PostgreSQL, Redis, Ollama)
- Configuration should be injected via Pydantic Settings, not hardcoded

**Example of SOLID-compliant endpoint**:
```python
from abc import ABC, abstractmethod
from typing import Protocol

class GraphProtocol(Protocol):
    """Abstract graph interface following DIP."""
    async def ainvoke(self, input: dict, config: dict) -> dict: ...

async def get_graph() -> GraphProtocol:
    """DI factory following SRP - only provides graph instance."""
    return app.state.graph

@router.post("/v1/invoke")  # Single responsibility: handle invocation
async def invoke(
    request: InvokeRequest,  # ISP: focused request model
    graph: GraphProtocol = Depends(get_graph)  # DIP: depend on abstraction
) -> InvokeResponse:  # OCP: response model can be extended
    return await graph.ainvoke(request.dict(), {})
```

## Approval Status

[X] Approved with minor changes

**Required Changes Before Specification Phase**:
1. Define core API endpoint structure (at least endpoint paths and HTTP methods)
2. Explicitly mandate async/await patterns for all LangGraph interactions
3. Define required middleware stack for production readiness
4. Add health check endpoint specification
5. Document error response contract

**Optional Enhancements for Specification Phase**:
- SSE streaming endpoint consideration
- Request timeout strategy
- Rate limiting approach

The charter provides a solid foundation for the hx-lang-server project. With the minor additions noted above, the FastAPI API layer will be well-positioned for successful implementation.

**Signature:** Bob (FastAPI SME)
**Date:** 2025-12-01

---

## Appendix: Reference Documents Consulted

- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/async.md` - Async/await patterns
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/tutorial/dependencies/index.md` - Dependency injection
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/tutorial/middleware.md` - Middleware patterns
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/advanced/middleware.md` - Advanced middleware
- `/home/agent0/HX-Infrastructure/hx-knowledge/repos/fastapi/docs/en/docs/tutorial/cors.md` - CORS configuration
