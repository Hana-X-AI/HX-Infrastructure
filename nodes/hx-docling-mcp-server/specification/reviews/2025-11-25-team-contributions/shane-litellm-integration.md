# LiteLLM Integration Enhancement for Section 4.3.4

This document contains the enhanced LiteLLM integration content to be inserted into node-spec.md Section 4 (Integration Manager).

---

**4. Integration Manager** (External Service Clients)
- **Purpose**: Manage connections to LiteLLM, Qdrant, Redis with resilience and performance optimization
- **Responsibilities**:
  - Connection pool management (Redis, LiteLLM HTTP connection pooling)
  - Health check execution (LiteLLM `/health`, Qdrant `/health`, Redis `PING`)
  - Retry logic with exponential backoff and circuit breaking
  - Graceful degradation (disable features if dependencies unavailable)
  - Credential management (API keys from environment, Ansible Vault integration)
  - Request routing and load balancing (LiteLLM Router model fallback)
  - Response caching for identical entity extraction requests (cost optimization)
- **Technology**: httpx (HTTP client for LiteLLM), redis-py (Redis client), qdrant-client (Qdrant)
- **Interfaces**:
  - **Input**: Integration requests (LLM completion, vector upsert, session get/set)
  - **Output**: Integration responses (JSON, success/failure status, retry metadata)

## 4.1. LiteLLM Gateway Integration

### LiteLLM Client Configuration
- **Base URL**: `http://hx-litellm-server.hx.dev.local:4000` (LiteLLM proxy endpoint)
- **API Key Handling**: Optional API key from environment variable `LITELLM_API_KEY` (future OAuth2 support)
- **Timeout Configuration**:
  - Connection timeout: 10 seconds (establish TCP connection to LiteLLM proxy)
  - Read timeout: 120 seconds (wait for LLM completion response, handles slow model inference)
  - Write timeout: 5 seconds (send request payload)
- **Connection Pooling**: httpx AsyncClient with connection pool (max 20 connections, max 100 keepalive connections)
- **Streaming vs Batch**: Batch completions only (no streaming for entity extraction, deterministic output required)
- **Rate Limiting**: Client-side rate limiter (max 10 concurrent requests to LiteLLM, queue excess requests)
- **Backoff Strategy**: Exponential backoff with jitter (initial 1s, max 60s, multiplier 2.0, jitter ±20%)

### Model Selection Strategy
- **Primary Model (General Text)**: `gemma3:27b` via hx-ollama1-server
  - Use case: General document entity extraction (business documents, reports, articles)
  - Model routing: LiteLLM routes to `ollama/gemma3:27b` → Ollama1 backend
  - Latency: **Estimated ~2-5 seconds for 1K token entity extraction (P95)** — based on typical Gemma-27B inference speeds, unvalidated on HX hardware
  - Quality: **Estimated high accuracy for named entities (PERSON, ORG, LOCATION, DATE)** — based on published Gemma benchmarks, not NER-specific
- **Secondary Model (Technical/Code)**: `qwen3-coder:30b` via hx-ollama2-server
  - Use case: Technical documentation, source code, API documentation entity extraction
  - Model routing: LiteLLM routes to `ollama/qwen3-coder:30b` → Ollama2 backend
  - Latency: **Estimated ~3-7 seconds for 1K token entity extraction (P95)** — based on QwenCoder-30B model size and inference complexity, unvalidated on HX hardware
  - Quality: **Estimated excellent for technical entities (FUNCTION, CLASS, API_ENDPOINT, DEPENDENCY)** — based on QwenCoder specialization, not benchmarked
- **Fallback Model**: `gpt-oss:20b` via hx-ollama1-server
  - Use case: Fallback when primary models unavailable or overloaded
  - Model routing: LiteLLM Router automatically falls back on 503/timeout
  - Latency: **Estimated ~1-3 seconds for 1K token entity extraction (faster, lower quality)** — based on smaller model size, unvalidated on HX hardware

### Model Fallback Strategy (LiteLLM Router-Based)
1. **First attempt**: Use primary model (gemma3:27b or qwen3-coder:30b based on document type)
2. **On 503/timeout**: LiteLLM Router automatically retries with fallback model (gpt-oss:20b)
3. **On repeated failures**: Circuit breaker opens, disable entity extraction for 60 seconds
4. **Circuit breaker recovery**: Attempt health check after 60s, re-enable if healthy

### Model Performance Characteristics

**⚠️ CRITICAL: All Performance Metrics Are Estimates Pending Validation**

The following metrics are **preliminary estimates** based on published model benchmarks and typical inference characteristics. **NO INTERNAL BENCHMARKS HAVE BEEN RUN** on HX-Infrastructure hardware. All metrics require validation before deployment.

---

**F1 Score Estimates** (Entity Extraction Accuracy):

- **gemma3:27b**: **Estimated F1 0.85+** — based on Google Gemma model family published NLP benchmarks (MMLU, HellaSwag), not NER-specific
  - **Provenance**: Public Gemma technical report performance claims, NOT HX-Infrastructure validation
  - **Assumptions**: 
    - General-domain text (business documents, news articles, reports)
    - Standard entity types: PERSON, ORGANIZATION, LOCATION, DATE, EVENT
    - Few-shot prompting with 2-3 examples per entity type
  - **Validation Methodology Required**:
    - **Dataset**: CoNLL-2003 NER benchmark (testb split, 3,684 sentences) OR custom HX dataset with 500+ documents
    - **Entity Classes**: PERSON, ORG, LOCATION, MISC (CoNLL-2003 standard) or extended HX taxonomy
    - **Metric Calculation**: F1 macro-averaged across entity types using `seqeval` library (strict boundary matching)
    - **Evaluation Script**: Python script using Ollama Python SDK → `ollama.generate()` → parse JSON → compare against ground truth
    - **Hardware**: hx-ollama1-server — specs needed: CPU/GPU, RAM, Ollama version
    - **Payload**: 1K token documents (avg 200 words, ~4-5 paragraphs)
    - **Runs**: Minimum 3 runs with different random seeds, report mean ± std dev
    - **Quantization**: Document if using FP16, INT8, or other quantization (impacts accuracy)

- **qwen3-coder:30b**: **Estimated F1 0.90+** — based on Qwen-Coder family code understanding benchmarks (HumanEval, MBPP), NOT entity extraction
  - **Provenance**: Published QwenCoder technical report, NOT HX-Infrastructure validation
  - **Assumptions**: 
    - Technical documentation, source code comments, API documentation
    - Technical entity types: FUNCTION, CLASS, MODULE, API_ENDPOINT, LIBRARY, FRAMEWORK, DEPENDENCY
    - Code-aware prompting with technical few-shot examples
  - **Validation Methodology Required**:
    - **Dataset**: Custom technical corpus (500+ Python/TypeScript files with annotated entities) OR Stack Overflow dataset
    - **Entity Classes**: CLASS, FUNCTION, LIBRARY, FRAMEWORK, API, DEPENDENCY, CONFIG_PARAM
    - **Metric Calculation**: F1 macro-averaged using custom entity matcher (code token boundaries differ from text)
    - **Evaluation Script**: Same as gemma3 but with code-specific tokenization and boundary rules
    - **Hardware**: hx-ollama2-server — specs needed: CPU/GPU, RAM, Ollama version
    - **Payload**: 1K token code documents (avg 50-100 lines of code with docstrings)
    - **Runs**: Minimum 3 runs, report mean ± std dev
    - **Quantization**: Document quantization method (QwenCoder may use specialized quantization)

- **gpt-oss:20b**: **Estimated F1 0.75+** — based on smaller parameter count vs gemma3, NO published benchmarks
  - **Provenance**: Assumption only (smaller model = lower accuracy), NO benchmark data available
  - **Assumptions**: 
    - Fallback model for general use when primary models unavailable
    - Same entity types as gemma3 but lower expected recall
  - **Validation Methodology Required**:
    - **Dataset**: Same as gemma3 (CoNLL-2003 or custom dataset)
    - **Baseline Comparison**: Run side-by-side with gemma3 to measure degradation
    - **Hardware**: hx-ollama1-server — same hardware as gemma3 for fair comparison
    - **Expected Result**: 10-15% lower F1 vs gemma3, validate if acceptable for fallback use

---

**Latency Estimates** (P95 Response Time):

- **gemma3:27b**: **Estimated 3-5s P95** — based on typical 27B parameter model inference times, NOT HX hardware
  - **Provenance**: Industry benchmarks for Gemma-27B on similar hardware (A100, H100 GPUs), NOT HX validation
  - **Assumptions**:
    - Input: 1K tokens (~200 words, typical document chunk)
    - Output: 500 tokens (JSON array with 5-10 entities, verbose format)
    - Concurrent load: 1-3 requests (low contention)
  - **Validation Methodology Required**:
    - **Hardware Details**: hx-ollama1-server — document CPU model, GPU (if any), RAM, disk type (SSD/NVMe)
    - **OS/Runtime**: Ubuntu version, Ollama version, Python version, CUDA version (if GPU)
    - **Test Payload**: 100 real documents, 1K tokens each, representative entity density
    - **Concurrency**: Test at 1, 5, 10, 20 concurrent requests to measure P95 under load
    - **Sampling Strategy**: Run 500+ requests, sort latencies, take 95th percentile value
    - **P95 Calculation**: `sorted_latencies[int(0.95 * len(latencies))]` in Python
    - **Warmup**: Discard first 10 requests (model loading/caching)
    - **Metric Collection**: Use `time.perf_counter()` for microsecond precision

- **qwen3-coder:30b**: **Estimated 5-7s P95** — based on larger parameter count (30B vs 27B), NOT HX hardware
  - **Provenance**: Extrapolation from gemma3 estimate (+40% latency for +11% parameters), NO benchmark data
  - **Assumptions**: Same as gemma3 but slower inference due to larger model size
  - **Validation Methodology Required**:
    - **Hardware Details**: hx-ollama2-server — document specs (may differ from Ollama1)
    - **Test Payload**: 100 technical documents (code files, API docs) with 1K tokens
    - Same methodology as gemma3 but with technical corpus

- **gpt-oss:20b**: **Estimated 1-3s P95** — based on smaller model size and quantization, NOT HX hardware
  - **Provenance**: Assumption (smaller model = faster), NO benchmark data
  - **Assumptions**: INT8 or INT4 quantization for faster inference (unconfirmed)
  - **Validation Methodology Required**: Same as gemma3, document actual quantization used

---

**Token Throughput Estimates**:

- **gemma3:27b**: **Estimated ~100 tokens/sec** — based on published Gemma throughput benchmarks, NOT HX hardware
- **qwen3-coder:30b**: **Estimated ~60 tokens/sec** — extrapolation from gemma3, NOT HX hardware
- **gpt-oss:20b**: **Estimated ~200 tokens/sec** — assumption based on quantization, NO data

**Provenance**: All throughput estimates derived from public model cards (Hugging Face, Google AI), NOT validated.

---

**Validation Action Items** (MUST COMPLETE BEFORE DEPLOYMENT):

1. **Benchmark F1 Scores**:
   - Run entity extraction on CoNLL-2003 (gemma3, gpt-oss) and custom technical corpus (qwen3-coder)
   - Document dataset size, entity classes, metric calculation (F1 macro/micro), evaluation script
   - Report results: F1 score, precision, recall, confusion matrix, per-entity breakdown

2. **Benchmark Latency P95**:
   - Run 500+ requests per model on actual HX hardware (Ollama1, Ollama2)
   - Document hardware specs: CPU, GPU, RAM, disk, OS, Ollama version, quantization
   - Test under load: 1, 5, 10, 20 concurrent requests
   - Calculate P95: `sorted_latencies[int(0.95 * len(latencies))]`
   - Report: P50, P95, P99 latency, max latency, std dev

3. **Benchmark Throughput**:
   - Measure tokens/sec output rate during latency tests
   - Report: mean throughput, min/max, std dev

4. **Document Results**:
   - Create `nodes/hx-docling-mcp-server/benchmarks/litellm-models-benchmark-results.md`
   - Include: raw data, charts, analysis, hardware details, reproduction steps
   - Update this specification with actual measured performance (replace estimates)

5. **Timeline**: Complete validation during Phase 2 (Setup & Configuration) before Phase 3 (Task Breakdown)

### Cost Optimization (Prefer Local Ollama)
- **Cost Tier 1 (Free)**: Ollama1/2 local models (gemma3, qwen3-coder, gpt-oss) - zero cost per token
- **Cost Tier 2 (Fallback)**: No external API providers in Phase 1 (future: OpenAI/Anthropic if quality insufficient)
- **Caching Strategy**: Cache entity extraction results for identical document chunks (SHA-256 hash key)
  - Cache backend: Redis with 7-day TTL for extraction results
  - Cache key format: `extraction_cache:{model_name}:{content_hash}`
  - Expected cache hit rate: 15-30% for repeated document processing workflows
  - Cost savings: 15-30% reduction in LLM API calls via caching

### Prompt Engineering for Entity Extraction

**Prompt Template Structure**:
```python
ENTITY_EXTRACTION_PROMPT = """
You are an expert entity extraction system. Extract entities from the following document text.

Return ONLY a JSON array of entities with this exact structure:
[
  {
    "name": "entity name exactly as it appears",
    "type": "PERSON|ORG|LOCATION|DATE|PRODUCT|CONCEPT|FUNCTION|CLASS|API_ENDPOINT",
    "confidence": 0.0-1.0,
    "context": "surrounding sentence for disambiguation"
  }
]

Rules:
- Extract only factual entities mentioned in the text
- Preserve exact capitalization and spelling
- Assign confidence based on contextual clarity (explicit mention = 1.0, inferred = 0.5-0.8)
- Include enough context for disambiguation (e.g., "Apple Inc." vs "apple fruit")
- Return empty array [] if no entities found

Document text:
{document_chunk}

Output (JSON only, no explanation):
"""

RELATIONSHIP_EXTRACTION_PROMPT = """
You are an expert relationship extraction system. Extract relationships between entities.

Given these entities: {entity_list}

Extract relationships from this text:
{document_chunk}

Return ONLY a JSON array of relationships:
[
  {
    "subject": "entity name from entity_list",
    "predicate": "relationship verb (e.g., employed_by, located_in, depends_on)",
    "object": "entity name from entity_list",
    "confidence": 0.0-1.0
  }
]

Rules:
- Only create relationships between entities in entity_list
- Use concise predicate verbs (2-3 words max)
- Confidence based on relationship clarity (explicit = 1.0, inferred = 0.5-0.8)
- Return empty array [] if no valid relationships

Output (JSON only, no explanation):
"""
```

**Few-Shot Examples** (Included in Prompt for Quality):

These complete examples will be embedded in the entity extraction prompt to guide the LLM with expected output format and entity extraction patterns.

**Example 1 - General Text (PERSON, ORG, LOCATION entities)**:
```
Input: "John Smith works at Acme Corp in Seattle and reports to Sarah Johnson, the VP of Engineering."

Output (JSON only):
[
  {
    "name": "John Smith",
    "type": "PERSON",
    "confidence": 1.0,
    "context": "works at Acme Corp, reports to Sarah Johnson"
  },
  {
    "name": "Acme Corp",
    "type": "ORGANIZATION",
    "confidence": 1.0,
    "context": "employer in Seattle, has VP of Engineering"
  },
  {
    "name": "Seattle",
    "type": "LOCATION",
    "confidence": 1.0,
    "context": "location of Acme Corp headquarters"
  },
  {
    "name": "Sarah Johnson",
    "type": "PERSON",
    "confidence": 1.0,
    "context": "VP of Engineering at Acme Corp, John Smith's manager"
  },
  {
    "name": "VP of Engineering",
    "type": "ROLE",
    "confidence": 0.9,
    "context": "Sarah Johnson's position at Acme Corp"
  }
]
```

**Example 2 - Technical Text (LIBRARY, FRAMEWORK, TECHNOLOGY entities)**:
```
Input: "FastAPI depends on Pydantic for request validation and uses Starlette as its ASGI framework. The application connects to PostgreSQL via SQLAlchemy ORM."

Output (JSON only):
[
  {
    "name": "FastAPI",
    "type": "FRAMEWORK",
    "confidence": 1.0,
    "context": "web framework using Starlette ASGI, depends on Pydantic"
  },
  {
    "name": "Pydantic",
    "type": "LIBRARY",
    "confidence": 1.0,
    "context": "data validation library used by FastAPI"
  },
  {
    "name": "Starlette",
    "type": "FRAMEWORK",
    "confidence": 1.0,
    "context": "ASGI framework underlying FastAPI"
  },
  {
    "name": "ASGI",
    "type": "TECHNOLOGY",
    "confidence": 0.9,
    "context": "asynchronous server gateway interface protocol"
  },
  {
    "name": "PostgreSQL",
    "type": "DATABASE",
    "confidence": 1.0,
    "context": "database connected via SQLAlchemy ORM"
  },
  {
    "name": "SQLAlchemy",
    "type": "LIBRARY",
    "confidence": 1.0,
    "context": "ORM library for PostgreSQL database access"
  }
]
```

**Example 3 - Ambiguous Entities (Disambiguation Required)**:
```
Input: "Apple released new products at their Cupertino campus. The apple orchards in Washington produce high-quality fruit."

Output (JSON only):
[
  {
    "name": "Apple",
    "type": "ORGANIZATION",
    "confidence": 1.0,
    "context": "technology company releasing products at Cupertino campus"
  },
  {
    "name": "Cupertino",
    "type": "LOCATION",
    "confidence": 1.0,
    "context": "location of Apple company campus"
  },
  {
    "name": "apple",
    "type": "PRODUCT",
    "confidence": 0.95,
    "context": "fruit produced in Washington orchards (lowercase indicates fruit, not company)"
  },
  {
    "name": "Washington",
    "type": "LOCATION",
    "confidence": 1.0,
    "context": "state where apple orchards are located"
  }
]

Note: Disambiguation achieved through:
1. Context clues ("released products" vs "orchards produce")
2. Capitalization patterns (Apple company vs apple fruit)
3. Relationship inference (company→campus, orchard→fruit)
```

**System Prompts for Entity Normalization**:
- **Name normalization**: "Google Inc." → "Google", "J. Smith" → "John Smith" (expand abbreviations)
- **Type consistency**: ORGANIZATION (not ORG, Company, Business) - enforce canonical types
- **Deduplication hints**: "If entity appears multiple times with slight variations, use most complete form"

**LLM Parameter Settings** (Deterministic Entity Extraction):
- **Temperature**: 0.1 (low temperature for deterministic, factual extraction - avoid creative variation)
- **Top_p**: 0.9 (nucleus sampling to avoid rare token selection)
- **Max_tokens**: 2048 (sufficient for ~100 entities in JSON response)
- **Stop sequences**: `["\n\n\n", "```"]` (prevent runaway generation beyond JSON)
- **Presence_penalty**: 0.0 (no penalty, extract all entities even if repetitive)
- **Frequency_penalty**: 0.0 (no penalty, allow entity names to repeat in context)

### Error Handling & Resilience

**LiteLLM Error Types**:
1. **Timeout Errors** (408, connection timeout exceeds 120s)
   - Cause: Model inference too slow, Ollama server overloaded
   - Handling: Retry with exponential backoff (1s, 2s, 4s), fallback to faster model (gpt-oss:20b)
   - Logging: `WARN LiteLLM timeout for model={model_name} after {timeout}s, retrying with fallback`

2. **Rate Limit Errors** (429, too many requests)
   - Cause: LiteLLM proxy rate limiting, Ollama server queue full
   - Handling: Exponential backoff with jitter (1s ± 0.2s, 2s ± 0.4s, 4s ± 0.8s, max 60s)
   - Logging: `WARN LiteLLM rate limit hit, backing off {delay}s`

3. **Model Unavailable Errors** (503, model not loaded or server down)
   - Cause: Ollama model not loaded, Ollama server restart, LiteLLM routing failure
   - Handling: LiteLLM Router automatic fallback to secondary model, if all fail → circuit breaker
   - Logging: `ERROR LiteLLM model {model_name} unavailable, fallback to {fallback_model}`

4. **Invalid Response Errors** (200 but malformed JSON, incomplete entities)
   - Cause: LLM hallucination, truncated response, non-JSON output
   - Handling: JSON schema validation, retry with stricter prompt ("Output ONLY JSON array, no markdown")
   - **Retry Budget**: Invalid response retries consume from shared MAX_RETRIES = 3 budget (not independent)
   - **Constant**: INVALID_RESPONSE_MAX_RETRIES = 2 (max retry attempts after initial call, uses shared budget)
   - Logging: `ERROR LiteLLM returned invalid JSON: {response_preview}, retrying with strict prompt (attempt {attempt}/{MAX_RETRIES}, invalid_response_retry {invalid_retry_count}/{INVALID_RESPONSE_MAX_RETRIES})`
   - **Clarification**: Total 3 attempts = 1 original + 2 retries. Each invalid response retry consumes from the shared MAX_RETRIES counter.

**Retry Logic with Exponential Backoff**:
```python
# Pseudocode - Shared retry budget for all error types
MAX_RETRIES = 3  # Total attempts including original (1 original + 2 retries)
INVALID_RESPONSE_MAX_RETRIES = 2  # Max retries for invalid JSON (shares MAX_RETRIES budget)
INITIAL_DELAY = 1.0  # seconds
MAX_DELAY = 60.0
BACKOFF_MULTIPLIER = 2.0
JITTER_PERCENT = 0.2

invalid_response_retry_count = 0

for attempt in range(1, MAX_RETRIES + 1):
    try:
        response = await litellm_client.completion(...)
        
        # Validate JSON response
        try:
            parsed = json.loads(response)
            return parsed  # Success
        except json.JSONDecodeError as e:
            invalid_response_retry_count += 1
            if attempt == MAX_RETRIES or invalid_response_retry_count > INVALID_RESPONSE_MAX_RETRIES:
                logger.error(f"Invalid JSON response exhausted retries: attempt={attempt}/{MAX_RETRIES}, invalid_retries={invalid_response_retry_count}/{INVALID_RESPONSE_MAX_RETRIES}")
                raise  # Max retries exhausted (shared budget)
            logger.warning(f"Invalid JSON response, retrying with strict prompt: attempt={attempt}/{MAX_RETRIES}, invalid_retry={invalid_response_retry_count}/{INVALID_RESPONSE_MAX_RETRIES}")
            continue  # Retry with stricter prompt
            
    except (TimeoutError, RateLimitError) as e:
        if attempt == MAX_RETRIES:
            logger.error(f"Network/rate-limit error exhausted retries: attempt={attempt}/{MAX_RETRIES}, error={type(e).__name__}")
            raise  # Max retries exhausted (shared budget)
        delay = min(INITIAL_DELAY * (BACKOFF_MULTIPLIER ** (attempt - 1)), MAX_DELAY)
        jitter = delay * JITTER_PERCENT * (random.random() * 2 - 1)  # ±20%
        await asyncio.sleep(delay + jitter)
        logger.warning(f"Network/rate-limit retry: attempt={attempt}/{MAX_RETRIES}, error={type(e).__name__}, backoff={delay + jitter:.2f}s")
```

**Circuit Breaker for Repeated Failures**:
- **Failure Threshold**: 5 consecutive LiteLLM errors (any type) within 60-second window
- **Open State Duration**: 60 seconds (disable entity extraction, return cached results or skip)
- **Half-Open State**: After 60s, attempt single health check request to LiteLLM
  - **Health Check Endpoint**: `GET http://hx-litellm-server.hx.dev.local:4000/health`
  - **Expected Response**: 200 OK with `{"status": "ok"}` body (LiteLLM standard health response)
  - **Health Check Timeout**: 5 seconds (matches pre-start validation timeout from line 11)
  - **Implementation Note**: Use httpx.AsyncClient with 5s timeout to call `GET /health` endpoint
  - **Recovery**: If health check returns 200 OK, transition circuit breaker from HALF_OPEN → CLOSED and resume normal operation
  - **Failure Handling**: If health check fails or times out, keep circuit breaker OPEN for another 60s
- **State Tracking**: Redis-backed circuit breaker state (key: `circuit_breaker:litellm`, values: CLOSED|OPEN|HALF_OPEN)
- **Operator Visibility**: Circuit breaker state exposed via MCP server `/metrics` endpoint and logged at INFO level on state transitions

**Graceful Degradation (LiteLLM Unavailable)**:
- **Scenario**: LiteLLM gateway down, all Ollama servers unreachable, circuit breaker open
- **Degradation Behavior**:
  1. Skip entity extraction step in knowledge graph generation
  2. Store raw DoclingDocument text in Qdrant (text-only retrieval, no entity-based queries)
  3. Return MCP tool response with warning: `"entity_extraction": "disabled", "reason": "LiteLLM unavailable"`
- **User Notification**: MCP tool response includes `"degraded_mode": true` flag
- **Monitoring Alert**: Trigger alert if degraded mode active >5 minutes

**Error Logging and Alerting**:
- **Log Level**: ERROR for failures, WARN for retries, INFO for successful fallbacks
- **Structured Logging** (JSON format):
  ```json
  {
    "timestamp": "2025-11-25T10:30:45Z",
    "level": "ERROR",
    "component": "integration_manager.litellm",
    "error_type": "model_unavailable",
    "model": "gemma3:27b",
    "retry_count": 3,
    "fallback_model": "gpt-oss:20b",
    "request_id": "abc-123",
    "document_id": "doc-456"
  }
  ```
- **Metrics**: Prometheus counters for error types, retry counts, fallback invocations, circuit breaker state changes

### Performance Optimization

**Batch Processing for Multiple Documents**:
- **Batch Size**: Process up to 10 documents concurrently with separate LiteLLM requests
- **Concurrency Control**: Semaphore limiting max 10 concurrent LiteLLM calls (prevent overload)
- **Batch Timeout**: 300 seconds total for batch (individual request timeout still 120s)

**Parallel Requests** (Max Concurrent LiteLLM Calls):
- **Max Concurrency**: 10 simultaneous asyncio tasks calling LiteLLM
- **Queue Management**: If >10 requests pending, queue in Redis-backed task queue (FIFO)
- **Backpressure**: Return 429 rate limit error to MCP client if queue depth >100

**Response Caching for Identical Extraction Requests**:
- **Cache Key**: SHA-256 hash of `(model_name, document_chunk, prompt_template_version)`
- **Cache Storage**: Redis with structured key `extraction_cache:{model}:{hash}`
- **Cache Value**: JSON entity/relationship extraction result
- **Cache TTL**: 7 days (604800 seconds)
- **Cache Hit Rate Target**: 20-30% for typical document processing workflows
- **Cache Invalidation**: On prompt template version change, invalidate all cached results (new Redis key namespace)

**Token Usage Tracking and Optimization**:
- **Token Counting**: Use `tiktoken` library to count input/output tokens before sending to LiteLLM
- **Cost Tracking**: Log token usage per request (input tokens, output tokens, total cost if using paid API)
- **Optimization Strategies**:
  1. **Chunk Size Optimization**: Test entity extraction quality vs chunk size (1K, 2K, 4K tokens), select optimal
  2. **Prompt Compression**: Remove verbose instructions, keep only essential few-shot examples
  3. **Model Selection**: Use cheaper/faster gpt-oss:20b for low-value documents, reserve gemma3:27b for high-value
- **Metrics**:
  - `litellm_tokens_total{type="input|output", model="gemma3:27b|qwen3-coder:30b|gpt-oss:20b"}`: Counter
  - `litellm_cost_usd_total{model="..."}`: Counter (future, for paid APIs)
  - `litellm_request_duration_seconds{model="..."}`: Histogram (P50, P95, P99)

---

## Enhanced FR-021 to FR-024 (Integration Requirements)

Replace current FR-021 to FR-024 with:

- **FR-021**: Service MUST integrate with LiteLLM Gateway (hx-litellm-server:4000) for multi-provider LLM abstraction:
  - **Client Configuration**: httpx AsyncClient with 10s connect timeout, 120s read timeout, connection pool (max 20, keepalive 100)
  - **Model Routing**: Primary gemma3:27b (general text), secondary qwen3-coder:30b (technical), fallback gpt-oss:20b
  - **Rate Limiting**: Client-side limit of 10 concurrent requests, queue excess with backpressure (max queue depth 100)
  - **Health Checks**: LiteLLM `/health` endpoint check before entity extraction, 30-second interval
  - **Error Handling**: Timeout (retry + fallback), rate limit (exponential backoff with jitter), model unavailable (Router fallback), invalid response (strict prompt retry)

- **FR-022**: Service MUST implement LiteLLM prompt engineering for high-quality entity extraction:
  - **Prompt Templates**: ENTITY_EXTRACTION_PROMPT and RELATIONSHIP_EXTRACTION_PROMPT with structured JSON schema
  - **Few-Shot Examples**: Include 3 examples (general text, technical text, ambiguous case) in each prompt
  - **LLM Parameters**: Temperature 0.1 (deterministic), top_p 0.9, max_tokens 2048, stop sequences to prevent runaway
  - **Response Validation**: JSON schema validation, retry on malformed output with stricter prompt (max 2 retries)

- **FR-023**: Service MUST implement resilience patterns for LiteLLM integration:
  - **Retry Logic**: 3 attempts with exponential backoff (initial 1s, multiplier 2.0, max 60s) and jitter (±20%)
  - **Circuit Breaker**: Open after 5 consecutive failures in 60s window, disable extraction for 60s, half-open health check recovery
  - **Graceful Degradation**: Skip entity extraction if LiteLLM unavailable, store raw text in Qdrant, return `degraded_mode: true` flag
  - **State Tracking**: Redis-backed circuit breaker state (key: `circuit_breaker:litellm`)

- **FR-024**: Service MUST optimize LiteLLM integration performance and cost:
  - **Response Caching**: SHA-256 hash of (model, document_chunk, prompt_version) → Redis cache with 7-day TTL, target 20-30% hit rate
  - **Batch Processing**: Support up to 10 concurrent documents with semaphore limiting max 10 LiteLLM calls
  - **Token Tracking**: Count input/output tokens with tiktoken, log cost metrics (Prometheus counters)
  - **Model Selection**: Use gpt-oss:20b for low-value documents, reserve gemma3:27b/qwen3-coder:30b for high-value

- **FR-025**: Service MUST log all LiteLLM integration operations with structured logging:
  - **Log Format**: JSON with timestamp, level, component, error_type, model, retry_count, request_id, document_id
  - **Log Levels**: ERROR (failures), WARN (retries, rate limits), INFO (successful fallbacks)
  - **Metrics**: Prometheus counters for errors, retries, fallbacks, circuit breaker states; histograms for request duration and token usage
