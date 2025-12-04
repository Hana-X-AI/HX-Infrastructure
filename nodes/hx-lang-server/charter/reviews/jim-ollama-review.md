# Charter Review: Jim (Ollama SME)

**Review Date:** 2025-12-01
**Charter Version:** 1.1
**Reviewer Role:** Ollama Subject Matter Expert (Jim Harper)

---

## Executive Summary

The hx-lang-server charter demonstrates a solid understanding of the three-server Ollama architecture and proposes a sensible multi-Ollama routing strategy. The approach of routing general queries to ollama1, code queries to ollama2, and embeddings via LightRAG (which uses ollama3) aligns with our established specialization strategy. However, the charter requires clarification on query classification mechanisms, capacity planning validation, and explicit handling of the direct ollama3 bypass pattern for embeddings.

---

## Strengths

- **Correct Server Specialization Understanding**: Charter accurately identifies ollama1 for general inference, ollama2 for code-focused models, and ollama3 for embeddings - matching our established deployment strategy.

- **LightRAG Integration Approach**: Correctly routes embedding requests through LightRAG rather than direct ollama3 access, preserving the RAG pipeline abstraction and leveraging existing embedding workflows.

- **langchain-ollama Adoption**: Use of `langchain-ollama` adapter is the correct pattern for LangGraph integration with Ollama servers, providing proper abstraction and compatibility.

- **Phased Approach**: Starting with 2-3 worker agents before expanding allows validation of Ollama routing under controlled load before scaling.

- **Existing Infrastructure Leverage**: Charter explicitly states using existing Ollama servers without modifications, respecting operational stability.

- **Architecture Diagram Accuracy**: The diagram correctly shows Ollama1 (Gen) and Ollama2 (Code) as direct integration points, while embeddings flow through LightRAG.

---

## Concerns / Risks

### HIGH Severity

1. **Query Classification Mechanism Undefined**: Charter states "Dynamic routing to appropriate Ollama server based on query type" but does not specify HOW query classification will be performed.
   - **Risk**: Without explicit classification logic, routing may be inconsistent or require LLM-based classification (adding latency and cost).
   - **Recommendation**: Specify classification approach - keyword-based, embedding similarity, or router model.

2. **Ollama3 Embedding Access Path Unclear**: Charter mentions "Embeddings -> ollama3 (via LightRAG)" but LightRAG generates embeddings internally. The charter needs to clarify:
   - **Risk**: Ambiguity about whether LangGraph will generate its own embeddings or rely entirely on LightRAG.
   - **Recommendation**: Clarify that LangGraph should NOT access ollama3 directly; all embedding operations should flow through LightRAG API.

### MEDIUM Severity

3. **Capacity Validation Incomplete**: Risk R-001 mentions "LangGraph-Ollama integration complexity" but does not address capacity concerns. Current deployments:
   - **ollama1**: gemma3:27b (17GB), gpt-oss:20b (13GB), mistral:7b (4.4GB)
   - **ollama2**: qwen3-coder:30b (18GB), cogito:3b (2.2GB), qwen2.5:7b (4.7GB)
   - **ollama3**: bge-m3:567m (1.2GB), granite-docling (521MB), bge-reranker-v2-m3 (1.2GB), aipromptassistant (4.7GB)
   - **Risk**: LangGraph may increase concurrent requests significantly, impacting inference latency.
   - **Recommendation**: Add assumption about Ollama capacity and define load testing criteria.

4. **Model Selection Within Servers Not Specified**: Charter routes to servers but does not specify which models on each server. For example, ollama1 has 3 models (gemma3:27b, gpt-oss:20b, mistral:7b).
   - **Risk**: Default model selection may not align with query requirements.
   - **Recommendation**: Define model selection logic per server (e.g., default to mistral:7b for speed, escalate to gemma3:27b for complex reasoning).

5. **Fallback Strategy Missing**: No mention of what happens if an Ollama server is unavailable or overloaded.
   - **Risk**: Single point of failure for each query type.
   - **Recommendation**: Define fallback routing (e.g., ollama1 can handle code queries if ollama2 is down).

### LOW Severity

6. **Performance Targets May Be Aggressive**: API response target of <5 seconds for "simple query" is achievable for mistral:7b but may be challenging for 27B/30B models under concurrent load.
   - **Recommendation**: Differentiate latency targets by model size/server.

7. **num_gpu Parameter Not Mentioned**: LangGraph configuration should ensure Ollama requests specify proper GPU offloading.
   - **Recommendation**: Document that all Ollama integrations should verify 100% GPU utilization via `ollama ps`.

---

## Recommendations

### Must Address Before Specification

1. **Define Query Classification Strategy**
   - Option A: Keyword-based router (fast, deterministic)
   - Option B: Embedding-based router using existing LightRAG embeddings (semantic)
   - Option C: Small classifier model (qwen2.5:7b) on ollama2 for routing decisions
   - **My Recommendation**: Start with keyword-based for Phase 1, add semantic routing in Phase 2.

2. **Clarify Embedding Flow**
   - Add explicit statement: "hx-lang-server will NOT connect directly to hx-ollama3-server. All embedding operations will use hx-literag-server API endpoints."
   - This prevents bypassing LightRAG's embedding caching and graph augmentation.

3. **Add Ollama Capacity Assumption**
   - Add Assumption A-005: "Existing Ollama servers can handle 3x concurrent request increase from LangGraph routing without exceeding latency targets."
   - Validation: Load testing during Phase 1 development.

### Should Address in Specification

4. **Specify Default Models per Server**
   ```
   ollama1 (general):
     - Default: mistral:7b (fast inference)
     - Complex reasoning: gemma3:27b
     - Alternative: gpt-oss:20b

   ollama2 (code):
     - Default: qwen2.5:7b (fast code tasks)
     - Complex code: qwen3-coder:30b
     - Small tasks: cogito:3b

   ollama3 (embeddings - via LightRAG only):
     - Embeddings: bge-m3:567m
     - Reranking: bge-reranker-v2-m3
     - Document processing: granite-docling:258m
   ```

5. **Define Fallback Routing Table**
   | Primary | Query Type | Fallback | Notes |
   |---------|-----------|----------|-------|
   | ollama1 | General | ollama2 (qwen2.5:7b) | Degraded but functional |
   | ollama2 | Code | ollama1 (mistral:7b) | May have reduced code quality |
   | LightRAG | Embeddings | N/A (hard dependency) | Cannot bypass LightRAG |

6. **Add num_gpu Verification Step**
   - Include in deployment validation: "Verify all LangGraph-initiated Ollama requests show 100% GPU utilization in `ollama ps` output."

### Nice to Have

7. **Latency Monitoring Integration**
   - When hx-metric-server is operational, add Ollama latency metrics to Prometheus/Grafana.

8. **Model Warm-Up Strategy**
   - Document that LangGraph startup should issue test queries to pre-load models into GPU memory.

---

## Ollama Routing Assessment

### Proposed Architecture Evaluation

The charter's multi-Ollama routing design is **architecturally sound** but **operationally incomplete**. Here is my detailed assessment:

**What Works Well:**
1. **Three-tier specialization** aligns perfectly with our GPU optimization strategy - each server optimized for its workload type.
2. **LightRAG as embedding gateway** prevents direct ollama3 access, maintaining proper abstraction layers.
3. **langchain-ollama adapter** is the correct integration pattern for LangGraph.
4. **Architecture diagram** correctly shows data flow through appropriate servers.

**What Needs Work:**
1. **Classification logic is the critical missing piece** - without it, the router cannot make intelligent decisions.
2. **Model selection within servers** needs explicit rules - routing to ollama2 is insufficient if you do not specify qwen3-coder vs qwen2.5.
3. **Capacity planning** assumes infinite headroom - LangGraph will generate significantly more requests than current UI-driven usage.

**Recommended Routing Implementation:**

```python
# Suggested routing logic for langchain-ollama integration
class OllamaRouter:
    def route(self, query: str, context: dict) -> tuple[str, str]:
        """Returns (server, model) tuple."""

        # Code detection (high precision keywords)
        code_indicators = ['code', 'function', 'class', 'debug', 'refactor',
                          'python', 'javascript', 'typescript', 'sql', 'api']
        if any(kw in query.lower() for kw in code_indicators):
            complexity = self._estimate_complexity(query)
            if complexity == 'high':
                return ('hx-ollama2-server.hx.dev.local:11434', 'qwen3-coder:30b')
            return ('hx-ollama2-server.hx.dev.local:11434', 'qwen2.5:7b')

        # Embedding requests - ALWAYS via LightRAG
        if context.get('operation') == 'embedding':
            raise ValueError("Embeddings must route through LightRAG, not direct Ollama")

        # General queries
        complexity = self._estimate_complexity(query)
        if complexity == 'high':
            return ('hx-ollama1-server.hx.dev.local:11434', 'gemma3:27b')
        return ('hx-ollama1-server.hx.dev.local:11434', 'mistral:7b')
```

**LiteLLM Coordination:**
The charter correctly identifies coordination with Shane Black (LiteLLM SME). When implementing:
- LangGraph should use LiteLLM as the primary gateway where possible
- Direct Ollama access should be limited to cases requiring specific model control
- LiteLLM provides unified API, load balancing, and request logging

---

## Integration Considerations

### Coordination Required with Other SMEs

| SME | Topic | Action Required |
|-----|-------|-----------------|
| Shane Black (LiteLLM) | Model alias configuration | Define LangGraph-specific model aliases in LiteLLM config |
| Andy Dolton (LightRAG) | Embedding API contract | Confirm LightRAG embedding endpoint stability for LangGraph |
| Paul Anderson (Open WebUI) | Potential conflict | Ensure LangGraph requests do not starve Open WebUI direct access |
| Victor Hayes (Qdrant) | Vector dimensions | Confirm embedding dimensions match between LangGraph and existing collections |

### Current Ollama Server Load Baseline

Before LangGraph deployment, establish baselines:

```bash
# Run on each Ollama server to establish current utilization
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv
ollama ps  # Should show loaded models and GPU percentage
```

LangGraph deployment should not increase average GPU utilization beyond 80% sustained.

---

## Approval Status

- [ ] Approved as-is
- [x] Approved with minor changes
- [ ] Requires changes before approval
- [ ] Not approved

**Conditional Approval Notes:**
The charter is approved for progression to specification phase, provided the following are addressed in the specification document:
1. Query classification mechanism explicitly defined
2. Embedding flow clarified (LightRAG-only access)
3. Capacity assumption added to RAIDD log
4. Default model selection rules documented

These are specification-level details that do not require charter revision, but MUST be addressed before development.

---

**Signature:** Jim Harper, Ollama SME
**Date:** 2025-12-01

---

## Appendix: Current Ollama Deployments Reference

### hx-ollama1-server (.204) - General Purpose
| Model | Size | VRAM | Use Case |
|-------|------|------|----------|
| gemma3:27b | 17GB | ~20GB | Complex reasoning, analysis |
| gpt-oss:20b | 13GB | ~16GB | General chat, summarization |
| mistral:7b | 4.4GB | ~6GB | Fast inference, simple queries |

### hx-ollama2-server (.205) - Code Specialized
| Model | Size | VRAM | Use Case |
|-------|------|------|----------|
| qwen3-coder:30b | 18GB | ~22GB | Complex code generation |
| qwen2.5:7b | 4.7GB | ~6GB | Fast code tasks |
| cogito:3b | 2.2GB | ~4GB | Simple code formatting |

### hx-ollama3-server (.206) - Embeddings & Enhancement
| Model | Size | VRAM | Use Case |
|-------|------|------|----------|
| bge-m3:567m | 1.2GB | ~2GB | Text embeddings |
| granite-docling:258m | 521MB | ~1GB | Document processing |
| bge-reranker-v2-m3 | 1.2GB | ~2GB | Search result reranking |
| aipromptassistant | 4.7GB | ~6GB | Prompt enhancement |

**Note:** Ollama3 models are accessed via LightRAG (embeddings) or Open WebUI direct bypass (prompt enhancement). LangGraph should NOT access ollama3 directly.
