# Crawl4AI MCP Integration Contribution

**Contributor:** David Park (Crawl4AI MCP Subject Matter Expert)
**Date:** 2025-12-01
**Specification Version:** 1.0
**Charter Reference:** `/nodes/hx-lang-server/charter/charter.md` (APPROVED)
**Specification Draft:** `/nodes/hx-lang-server/specification/node-spec.md` (DRAFT)

---

## Executive Summary

This contribution provides detailed technical guidance for integrating Crawl4AI MCP server (hx-crawl4ai-mcp-server) with the hx-lang-server LangGraph orchestration platform. The integration enables LangGraph agents to perform web scraping, RAG corpus building, and semantic search operations via the Model Context Protocol (MCP).

**Key Integration Points:**
1. **MCP Client Implementation**: LangGraph uses `langchain-mcp-adapters` to connect to FastMCP gateway
2. **Tool Discovery**: 8 MCP tools available (5 active, 3 deferred to LightRAG)
3. **RAG Corpus Building**: Crawled content flows to PostgreSQL pgvector for semantic search
4. **Schema Isolation**: Separate PostgreSQL schemas for LangGraph checkpoints vs Crawl4AI content
5. **Advanced RAG Strategies**: Configurable hybrid search, reranking, contextual embeddings

**Critical Clarifications:**
- hx-lang-server is an **MCP CLIENT** (not MCP server) consuming tools from hx-crawl4ai-mcp-server
- Tool namespace prefixes required: `crawl4ai__smart_crawl_url` (not `smart_crawl_url`)
- PostgreSQL schema isolation mandatory to prevent conflicts between LangGraph and Crawl4AI
- Coordinate with Diana Wu (Crawl4AI Worker) to avoid duplicate crawl operations

---

## 1. Crawl4AI MCP Tool Catalog

### 1.1 Overview

The Crawl4AI MCP server (`hx-crawl4ai-mcp-server.hx.dev.local:11235`) exposes **8 MCP tools** through the FastMCP gateway. Of these, **5 tools** are actively used by Crawl4AI MCP, and **3 tools** are deferred to the LightRAG server for knowledge graph operations.

### 1.2 Active Crawl4AI MCP Tools (5 Tools)

#### Tool 1: `crawl_single_page`

**Purpose:** Scrape a single URL and store content in PostgreSQL

**Parameters:**
```python
{
    "url": str  # Target URL to crawl
}
```

**Response:**
```json
{
    "success": true,
    "url": "https://example.com",
    "chunks_stored": 12,
    "source_id": "abc123"
}
```

**Use Cases:**
- Quick single-page content retrieval
- Documentation page scraping
- Blog post or article extraction

**LangGraph Integration Pattern:**
```python
# Via langchain-mcp-adapters
result = await mcp_client.invoke_tool(
    "crawl4ai__crawl_single_page",
    {"url": "https://docs.example.com/api"}
)
```

---

#### Tool 2: `smart_crawl_url`

**Purpose:** Intelligently crawl URLs based on type detection (sitemap, text file, or recursive)

**Parameters:**
```python
{
    "url": str,           # Target URL
    "max_depth": int,     # Recursion depth (default: 3)
    "max_concurrent": int,# Parallel crawls (default: 10)
    "chunk_size": int     # Chunk size for splitting (default: 5000)
}
```

**Auto-Detection Logic:**
- If URL ends with `.xml` or contains `sitemap` → Parse sitemap and crawl all URLs
- If URL ends with `.txt` → Parse text file and crawl all listed URLs
- Otherwise → Recursive crawl starting from URL (respects max_depth)

**Response:**
```json
{
    "success": true,
    "crawl_type": "sitemap",  // or "txt_file", "recursive"
    "urls_crawled": 45,
    "chunks_stored": 234,
    "source_id": "xyz789"
}
```

**Use Cases:**
- Documentation site crawling (via sitemap.xml)
- Batch URL crawling (via .txt file)
- Website section crawling (recursive with depth limit)

**LangGraph Integration Pattern:**
```python
# Agent detects user wants to crawl documentation
if "crawl documentation" in query.lower():
    result = await mcp_client.invoke_tool(
        "crawl4ai__smart_crawl_url",
        {
            "url": "https://docs.example.com/sitemap.xml",
            "max_depth": 3,
            "max_concurrent": 10
        }
    )
```

**CRITICAL:** This tool uses `MemoryAdaptiveDispatcher` with default 10 concurrent sessions. LangGraph agents should **NOT** invoke multiple simultaneous `smart_crawl_url` operations on large sites to avoid overwhelming the Crawl4AI server.

---

#### Tool 3: `perform_rag_query`

**Purpose:** Semantic search over crawled content using PostgreSQL pgvector

**Parameters:**
```python
{
    "query": str,          # Search query
    "source": str,         # Optional: Filter by domain (e.g., "docs.example.com")
    "match_count": int     # Number of results (default: 5)
}
```

**Response:**
```json
{
    "success": true,
    "results": [
        {
            "chunk": "The API uses OAuth2 authentication...",
            "url": "https://docs.example.com/auth",
            "similarity": 0.87,
            "title": "Authentication Guide"
        }
    ],
    "query_embedding_created": true,
    "total_results": 3
}
```

**RAG Strategy Configuration:**

The tool behavior changes based on environment variables:

| Strategy | Environment Variable | Impact on Results |
|----------|---------------------|-------------------|
| **Hybrid Search** | `USE_HYBRID_SEARCH=true` | Combines pgvector similarity + keyword search |
| **Reranking** | `USE_RERANKING=true` | Cross-encoder reranking with `ms-marco-MiniLM-L-6-v2` |
| **Contextual Embeddings** | `USE_CONTEXTUAL_EMBEDDINGS=true` | Enriches embeddings with document context |

**Recommended Configuration for LangGraph:**
```bash
USE_HYBRID_SEARCH=true      # Better for technical docs
USE_RERANKING=true          # Minimal cost, high benefit
USE_CONTEXTUAL_EMBEDDINGS=false  # Expensive, use selectively
```

**LangGraph Integration Pattern:**
```python
# RAG Agent performing retrieval
rag_context = await mcp_client.invoke_tool(
    "crawl4ai__perform_rag_query",
    {
        "query": "How do I authenticate API requests?",
        "source": "docs.example.com",
        "match_count": 3
    }
)

# Pass retrieved context to LLM
response = await ollama_client.generate(
    model="gemma3:27b",
    prompt=f"Context: {rag_context}\n\nQuestion: {user_query}"
)
```

---

#### Tool 4: `get_available_sources`

**Purpose:** List all domains that have been crawled and stored

**Parameters:** None

**Response:**
```json
{
    "success": true,
    "sources": [
        {
            "source_id": "abc123",
            "domain": "docs.example.com",
            "total_chunks": 234,
            "last_updated": "2025-12-01T10:30:00Z"
        }
    ]
}
```

**Use Cases:**
- Discover available knowledge sources before RAG query
- Build dynamic source selection UI
- Validate if domain has been crawled

**LangGraph Integration Pattern:**
```python
# Agent checks available sources before querying
sources = await mcp_client.invoke_tool("crawl4ai__get_available_sources", {})

# Filter sources relevant to query
relevant_sources = [s for s in sources["sources"] if "docs" in s["domain"]]

# Perform targeted RAG query
for source in relevant_sources:
    results = await mcp_client.invoke_tool(
        "crawl4ai__perform_rag_query",
        {"query": user_query, "source": source["domain"]}
    )
```

---

#### Tool 5: `search_code_examples`

**Purpose:** Agentic RAG for code snippets (requires `USE_AGENTIC_RAG=true`)

**Parameters:**
```python
{
    "query": str,           # Code search query
    "source_id": str,       # Optional: Filter by source
    "match_count": int      # Number of results (default: 5)
}
```

**Response:**
```json
{
    "success": true,
    "code_examples": [
        {
            "code": "async def authenticate(api_key: str):\n    ...",
            "language": "python",
            "summary": "OAuth2 authentication example",
            "url": "https://docs.example.com/examples",
            "similarity": 0.92
        }
    ]
}
```

**Feature:** This tool performs **agentic RAG** by:
1. Extracting code blocks from crawled pages using regex
2. Generating AI summaries for each code block
3. Creating separate embeddings for code snippets
4. Storing in `code_examples` table (separate from `crawled_pages`)

**Use Cases:**
- API integration examples
- SDK usage patterns
- Code snippet retrieval for Code Agent

**LangGraph Integration Pattern:**
```python
# Code Agent searching for examples
if query_type == "code":
    examples = await mcp_client.invoke_tool(
        "crawl4ai__search_code_examples",
        {"query": "Python async API client example"}
    )

    # Pass code examples to Code LLM (Ollama2)
    response = await ollama_client.generate(
        model="qwen3-coder:30b",
        prompt=f"Examples:\n{examples}\n\nImplement: {user_request}"
    )
```

**CRITICAL:** This tool requires `USE_AGENTIC_RAG=true` in Crawl4AI MCP server configuration. If disabled, the tool returns an error.

---

### 1.3 Deferred Tools (Handled by LightRAG) (3 Tools)

These tools are **exposed by Crawl4AI MCP** but **delegate to the LightRAG server** for knowledge graph operations. LangGraph agents should prefer direct LightRAG integration over these tools.

#### Tool 6: `parse_github_repository`

**Purpose:** Clone GitHub repo and parse into Neo4j knowledge graph

**Status:** DEFERRED to LightRAG server (hx-literag-server.hx.dev.local)

**Recommendation:** LangGraph agents should integrate directly with LightRAG's repository parsing API rather than using this MCP tool.

---

#### Tool 7: `check_ai_script_hallucinations`

**Purpose:** Validate AI-generated Python scripts against knowledge graph

**Status:** DEFERRED to LightRAG server

**Recommendation:** LangGraph agents should use LightRAG's validation API directly.

---

#### Tool 8: `query_knowledge_graph`

**Purpose:** Explore Neo4j knowledge graph with natural language queries

**Status:** DEFERRED to LightRAG server

**Recommendation:** LangGraph agents should integrate directly with LightRAG's knowledge graph query API.

---

## 2. Integration Patterns for LangGraph

### 2.1 MCP Client Configuration

**Architecture Clarification:**
- **hx-lang-server** = MCP **CLIENT** (consumes tools)
- **hx-fastmcp-server** = MCP **GATEWAY** (routes tool requests)
- **hx-crawl4ai-mcp-server** = MCP **SERVER** (provides tools)

**Connection Flow:**
```
LangGraph Agent → langchain-mcp-adapters → FastMCP Gateway → Crawl4AI MCP Server
```

**Configuration Code:**

```python
from langchain_mcp_adapters.client import MultiServerMCPClient

# Initialize MCP client
mcp_client = MultiServerMCPClient(
    servers={
        "fastmcp": {
            "transport": "streamable_http",
            "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        }
    }
)

# Tool discovery
async def discover_tools():
    """Enumerate all tools available via FastMCP gateway."""
    tools = await mcp_client.get_tools()

    # Filter for Crawl4AI tools (namespace prefix: crawl4ai__)
    crawl4ai_tools = [
        tool for tool in tools
        if tool.name.startswith("crawl4ai__")
    ]

    return crawl4ai_tools

# Tool invocation with namespace prefix
async def invoke_crawl_tool(tool_name: str, params: dict):
    """Invoke Crawl4AI tool via FastMCP gateway."""
    # CRITICAL: FastMCP gateway prefixes tools with server name
    full_tool_name = f"crawl4ai__{tool_name}"

    result = await mcp_client.invoke_tool(full_tool_name, params)
    return result
```

---

### 2.2 Tool Agent Integration Pattern

**Tool Agent Role:** Orchestrates Crawl4AI MCP tool invocations based on user requests

**Example Implementation:**

```python
from langgraph.graph import StateGraph
from langchain_ollama import OllamaLLM

class ToolAgent:
    """LangGraph worker agent for MCP tool orchestration."""

    def __init__(self, mcp_client, ollama_client):
        self.mcp_client = mcp_client
        self.ollama_client = ollama_client

    async def execute(self, state: AgentState) -> AgentState:
        """Execute tool-based workflow."""
        query = state["messages"][-1].content

        # Classify tool operation
        if "crawl" in query.lower():
            result = await self._handle_crawl(query)
        elif "search" in query.lower() or "find" in query.lower():
            result = await self._handle_search(query)
        elif "sources" in query.lower():
            result = await self._handle_sources()
        else:
            result = "No tool operation detected."

        # Update state
        state["tool_results"] = result
        state["messages"].append(AIMessage(content=result))
        return state

    async def _handle_crawl(self, query: str):
        """Handle crawl requests."""
        # Extract URL from query (simplified)
        url = self._extract_url(query)

        # Determine crawl type
        if "sitemap" in query.lower() or url.endswith(".xml"):
            tool = "smart_crawl_url"
        else:
            tool = "crawl_single_page"

        # Invoke tool
        result = await self.mcp_client.invoke_tool(
            f"crawl4ai__{tool}",
            {"url": url}
        )

        return f"Crawled {result['urls_crawled']} pages, stored {result['chunks_stored']} chunks"

    async def _handle_search(self, query: str):
        """Handle RAG search requests."""
        result = await self.mcp_client.invoke_tool(
            "crawl4ai__perform_rag_query",
            {"query": query, "match_count": 5}
        )

        return result["results"]

    async def _handle_sources(self):
        """List available sources."""
        result = await self.mcp_client.invoke_tool(
            "crawl4ai__get_available_sources",
            {}
        )

        return result["sources"]
```

---

### 2.3 RAG Agent Integration Pattern

**RAG Agent Role:** Performs adaptive retrieval with iteration when initial results insufficient

**Integration with Crawl4AI MCP:**

```python
class RAGAgent:
    """LangGraph worker agent for adaptive RAG workflows."""

    def __init__(self, mcp_client, ollama_client, lightrag_client):
        self.mcp_client = mcp_client
        self.ollama_client = ollama_client
        self.lightrag_client = lightrag_client  # LightRAG for knowledge graph

    async def execute(self, state: AgentState) -> AgentState:
        """Execute adaptive RAG workflow."""
        query = state["messages"][-1].content

        # Stage 1: Check if content already crawled
        sources = await self._check_available_sources(query)

        if not sources:
            # Stage 2: Trigger crawl if needed
            await self._crawl_new_source(query)
            sources = await self._check_available_sources(query)

        # Stage 3: Perform semantic search (Crawl4AI MCP)
        crawl4ai_results = await self._search_crawl4ai(query, sources)

        # Stage 4: Optionally augment with LightRAG knowledge graph
        lightrag_results = await self._search_lightrag(query)

        # Stage 5: Combine results and check sufficiency
        combined_context = self._combine_results(crawl4ai_results, lightrag_results)

        if self._is_sufficient(combined_context):
            # Generate response
            response = await self._generate_response(query, combined_context)
        else:
            # Iterate: expand search or trigger more crawls
            response = await self._iterate_retrieval(query, state)

        # Update state
        state["rag_context"] = combined_context
        state["messages"].append(AIMessage(content=response))
        return state

    async def _check_available_sources(self, query: str) -> List[str]:
        """Check if relevant sources exist."""
        result = await self.mcp_client.invoke_tool(
            "crawl4ai__get_available_sources",
            {}
        )

        # Filter sources relevant to query (simple keyword matching)
        query_keywords = set(query.lower().split())
        relevant = [
            s["domain"] for s in result["sources"]
            if any(kw in s["domain"].lower() for kw in query_keywords)
        ]

        return relevant

    async def _search_crawl4ai(self, query: str, sources: List[str]) -> List[dict]:
        """Search across multiple sources."""
        results = []

        for source in sources[:3]:  # Limit to top 3 sources
            result = await self.mcp_client.invoke_tool(
                "crawl4ai__perform_rag_query",
                {
                    "query": query,
                    "source": source,
                    "match_count": 3
                }
            )
            results.extend(result["results"])

        return results

    async def _search_lightrag(self, query: str) -> dict:
        """Search LightRAG knowledge graph."""
        # Direct HTTP call to LightRAG server
        response = await self.lightrag_client.query(
            query=query,
            mode="hybrid"  # Combines local + global RAG
        )
        return response

    def _combine_results(self, crawl4ai_results, lightrag_results) -> str:
        """Merge Crawl4AI and LightRAG results."""
        # Combine crawled content with knowledge graph
        combined = ""

        # Add Crawl4AI semantic search results
        for result in crawl4ai_results[:3]:
            combined += f"[{result['url']}]\n{result['chunk']}\n\n"

        # Add LightRAG knowledge graph context
        combined += f"Knowledge Graph Context:\n{lightrag_results}\n"

        return combined

    def _is_sufficient(self, context: str) -> bool:
        """Check if context is sufficient to answer query."""
        # Simple heuristic: at least 500 characters of context
        return len(context) >= 500
```

---

### 2.4 Code Agent Integration Pattern

**Code Agent Role:** Search for code examples and generate implementations

**Integration with Crawl4AI MCP:**

```python
class CodeAgent:
    """LangGraph worker agent for code-related queries."""

    def __init__(self, mcp_client, ollama_client):
        self.mcp_client = mcp_client
        self.ollama_client = ollama_client  # Ollama2 (qwen3-coder:30b)

    async def execute(self, state: AgentState) -> AgentState:
        """Execute code generation workflow."""
        query = state["messages"][-1].content

        # Stage 1: Search for relevant code examples
        examples = await self._search_code_examples(query)

        # Stage 2: Generate code using Ollama2 with examples as context
        response = await self._generate_code(query, examples)

        # Update state
        state["tool_results"] = {"code_examples": examples}
        state["messages"].append(AIMessage(content=response))
        return state

    async def _search_code_examples(self, query: str) -> List[dict]:
        """Search for code examples via Crawl4AI MCP."""
        try:
            result = await self.mcp_client.invoke_tool(
                "crawl4ai__search_code_examples",
                {
                    "query": query,
                    "match_count": 5
                }
            )
            return result["code_examples"]
        except Exception as e:
            # Fallback if USE_AGENTIC_RAG=false
            print(f"Code search failed: {e}. Using general RAG search.")
            return await self._fallback_rag_search(query)

    async def _fallback_rag_search(self, query: str) -> List[dict]:
        """Fallback to general RAG if code search unavailable."""
        result = await self.mcp_client.invoke_tool(
            "crawl4ai__perform_rag_query",
            {"query": f"code example {query}", "match_count": 5}
        )
        return result["results"]

    async def _generate_code(self, query: str, examples: List[dict]) -> str:
        """Generate code using Ollama2 with examples."""
        # Format examples for prompt
        examples_text = "\n\n".join([
            f"Example {i+1}:\n```{ex['language']}\n{ex['code']}\n```\n{ex['summary']}"
            for i, ex in enumerate(examples[:3])
        ])

        prompt = f"""You are a code generation assistant. Use the following examples as reference:

{examples_text}

User Request: {query}

Generate production-ready code with comments and error handling:"""

        # Use Ollama2 (Code LLM)
        response = await self.ollama_client.generate(
            model="qwen3-coder:30b",
            prompt=prompt
        )

        return response
```

---

## 3. RAG Corpus Building Workflow

### 3.1 Content Flow Architecture

**End-to-End Flow:**

```
User Query → LangGraph Supervisor → Tool Agent
                                        ↓
                        Invoke: crawl4ai__smart_crawl_url
                                        ↓
                        Crawl4AI MCP Server
                        - AsyncWebCrawler scrapes pages
                        - Content chunked (5000 chars default)
                        - OpenAI embeddings generated
                                        ↓
                        PostgreSQL Storage (pgvector)
                        - Schema: crawl4ai_rag
                        - Tables: crawled_pages, code_examples, sources
                                        ↓
                        RAG Agent retrieves via perform_rag_query
                                        ↓
                        LLM generates response with context
```

**Key Decision Points:**

1. **When to Crawl vs Search:**
   - Check `get_available_sources` first
   - If source exists → Use `perform_rag_query`
   - If source missing → Use `smart_crawl_url` then search

2. **When to Use LightRAG vs Crawl4AI:**
   - **Crawl4AI:** Web content, documentation, articles
   - **LightRAG:** Knowledge graph, entity relationships, cross-document reasoning

3. **When to Use Code Search vs General RAG:**
   - **Code Search:** API examples, SDK usage, implementation patterns
   - **General RAG:** Conceptual explanations, architecture docs, tutorials

---

### 3.2 PostgreSQL Schema Isolation

**CRITICAL:** LangGraph and Crawl4AI MCP both use PostgreSQL but for different purposes. Schema isolation is **MANDATORY**.

**Schema Design:**

```sql
-- LangGraph checkpoints (hx_lang_server database)
CREATE SCHEMA langgraph AUTHORIZATION hx_lang_server;

-- Crawl4AI content storage (hx_lang_server database OR separate database)
CREATE SCHEMA crawl4ai_rag AUTHORIZATION hx_lang_server;

-- Set search path for LangGraph service account
ALTER USER hx_lang_server SET search_path TO langgraph, public;
```

**Option 1: Single Database with Schemas (Recommended)**

```
Database: hx_lang_server
├── Schema: langgraph
│   ├── checkpoints (LangGraph state)
│   ├── checkpoint_blobs
│   ├── checkpoint_writes
│   └── checkpoint_migrations
├── Schema: crawl4ai_rag
│   ├── crawled_pages (pgvector)
│   ├── code_examples (pgvector)
│   └── sources
└── Schema: public
```

**Option 2: Separate Databases (Alternative)**

```
Database: hx_lang_server
└── checkpoints (LangGraph only)

Database: hx_crawl4ai_rag
└── crawled_pages, code_examples, sources (Crawl4AI only)
```

**Recommendation:** Use **Option 1** (single database with schemas) for simpler backup/restore and connection pooling.

---

### 3.3 Crawl4AI PostgreSQL Schema Reference

**Table: `crawled_pages`**

```sql
CREATE TABLE crawl4ai_rag.crawled_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url TEXT NOT NULL,
    chunk TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    title TEXT,
    source_id UUID REFERENCES crawl4ai_rag.sources(id),
    embedding VECTOR(1536),  -- OpenAI text-embedding-3-small
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(url, chunk_index)
);

CREATE INDEX idx_crawled_pages_embedding ON crawl4ai_rag.crawled_pages
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

**Table: `code_examples`**

```sql
CREATE TABLE crawl4ai_rag.code_examples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL,
    language TEXT,
    summary TEXT,
    url TEXT NOT NULL,
    source_id UUID REFERENCES crawl4ai_rag.sources(id),
    embedding VECTOR(1536),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_code_examples_embedding ON crawl4ai_rag.code_examples
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

**Table: `sources`**

```sql
CREATE TABLE crawl4ai_rag.sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain TEXT NOT NULL UNIQUE,
    total_chunks INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT NOW()
);
```

**Connection Configuration:**

```python
# LangGraph connects to langgraph schema
postgres_conn = await AsyncConnection.connect(
    host="hx-postgres-server.hx.dev.local",
    dbname="hx_lang_server",
    user="hx_lang_server",
    password="${POSTGRES_PASSWORD}",
    options="-c search_path=langgraph,public"
)

# Crawl4AI MCP connects to crawl4ai_rag schema
# (This is handled by hx-crawl4ai-mcp-server, LangGraph doesn't need direct access)
```

---

### 3.4 Coordination with Diana Wu (Crawl4AI Worker)

**IMPORTANT:** Diana Wu operates the Crawl4AI Worker for batch crawling operations. LangGraph agents invoking Crawl4AI MCP tools should coordinate to avoid duplicate crawls.

**Coordination Strategy:**

1. **Check Before Crawling:**
   ```python
   # Before triggering crawl
   sources = await mcp_client.invoke_tool("crawl4ai__get_available_sources", {})

   if target_domain in [s["domain"] for s in sources["sources"]]:
       # Content already exists, use perform_rag_query
       pass
   else:
       # Safe to trigger crawl
       await mcp_client.invoke_tool("crawl4ai__smart_crawl_url", {"url": url})
   ```

2. **Rate Limiting:**
   - Implement Redis-based rate limiting for crawl operations
   - Max 5 concurrent crawls per LangGraph session
   - Max 100 crawl requests per hour per user

3. **Cache Lookup:**
   - Check `crawled_pages` table for recent crawls (last 24 hours)
   - Reuse existing content instead of re-crawling

---

## 4. Advanced RAG Strategies

### 4.1 Configuration Options

Crawl4AI MCP supports 5 advanced RAG strategies via environment variables:

| Strategy | Variable | Impact | Cost | Recommendation |
|----------|----------|--------|------|----------------|
| **Hybrid Search** | `USE_HYBRID_SEARCH=true` | Combines vector + keyword search | Free | **Enable by default** |
| **Reranking** | `USE_RERANKING=true` | Cross-encoder reranking | Free (local model) | **Enable by default** |
| **Contextual Embeddings** | `USE_CONTEXTUAL_EMBEDDINGS=true` | LLM enriches chunks with context | High (OpenAI API) | **Disable by default** |
| **Agentic RAG** | `USE_AGENTIC_RAG=true` | Code extraction + summarization | Medium (OpenAI API) | **Enable for code queries** |
| **Knowledge Graph** | `USE_KNOWLEDGE_GRAPH=true` | Neo4j integration | N/A | **Defer to LightRAG** |

---

### 4.2 Hybrid Search (Recommended)

**What It Does:**
1. Performs pgvector similarity search (top 20 results)
2. Performs keyword search using PostgreSQL `to_tsvector` (top 20 results)
3. Merges results using Reciprocal Rank Fusion (RRF)
4. Returns top N merged results

**Configuration:**
```bash
USE_HYBRID_SEARCH=true
```

**Performance Impact:**
- Latency: +50ms (keyword search overhead)
- Accuracy: +15% for technical documentation queries

**Use Case:** Technical documentation retrieval (API docs, SDK guides)

---

### 4.3 Reranking (Recommended)

**What It Does:**
1. Retrieves top N results from vector search
2. Applies cross-encoder model (`ms-marco-MiniLM-L-6-v2`)
3. Reranks results by relevance score
4. Returns reranked top K results

**Configuration:**
```bash
USE_RERANKING=true
```

**Performance Impact:**
- Latency: +100ms (cross-encoder inference)
- Accuracy: +10% improvement in result relevance

**Use Case:** All queries (minimal cost, high benefit)

---

### 4.4 Contextual Embeddings (Use Selectively)

**What It Does:**
1. For each chunk, generates contextual summary using OpenAI LLM
2. Prepends context to chunk before creating embedding
3. Stores contextual embedding in pgvector

**Configuration:**
```bash
USE_CONTEXTUAL_EMBEDDINGS=true
MODEL_CHOICE=gpt-4o-mini  # Cheap, fast LLM
```

**Performance Impact:**
- Crawl time: +500ms per chunk (OpenAI API call)
- Cost: $0.10 per 1000 chunks (gpt-4o-mini)
- Accuracy: +20% for context-dependent queries

**Use Case:** High-precision retrieval where cost is acceptable

**LangGraph Integration:**
```python
# Selectively enable contextual embeddings for critical queries
if user_tier == "premium" and query_requires_precision:
    # Trigger re-crawl with contextual embeddings
    await mcp_client.invoke_tool(
        "crawl4ai__smart_crawl_url",
        {"url": url, "use_contextual": True}
    )
```

---

### 4.5 Agentic RAG (Code Queries Only)

**What It Does:**
1. Extracts code blocks from crawled pages (```language ... ```)
2. Generates AI summary for each code block
3. Creates separate embeddings for code snippets
4. Stores in `code_examples` table

**Configuration:**
```bash
USE_AGENTIC_RAG=true
```

**Performance Impact:**
- Crawl time: +200ms per page (code extraction + summarization)
- Cost: $0.05 per 1000 code blocks (OpenAI API)

**Use Case:** Code Agent queries requiring implementation examples

---

## 5. Code Examples

### 5.1 Complete Tool Agent Implementation

```python
from langgraph.graph import StateGraph, END
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain_ollama import OllamaLLM
from typing import TypedDict, Annotated, List
from langchain_core.messages import BaseMessage, AIMessage, HumanMessage

class AgentState(TypedDict):
    messages: Annotated[List[BaseMessage], "Message history"]
    query_type: str
    current_worker: str
    tool_results: dict
    iteration_count: int

class CrawlToolAgent:
    """LangGraph worker agent for Crawl4AI MCP operations."""

    def __init__(self):
        # Initialize MCP client
        self.mcp_client = MultiServerMCPClient(
            servers={
                "fastmcp": {
                    "transport": "streamable_http",
                    "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
                }
            }
        )

        # Initialize Ollama client
        self.ollama = OllamaLLM(
            base_url="http://hx-ollama1-server.hx.dev.local:11434",
            model="gemma3:27b"
        )

    async def execute(self, state: AgentState) -> AgentState:
        """Main execution logic for Tool Agent."""
        query = state["messages"][-1].content

        # Classify tool operation
        if any(kw in query.lower() for kw in ["crawl", "scrape", "fetch"]):
            result = await self._handle_crawl(query)
        elif any(kw in query.lower() for kw in ["search", "find", "retrieve"]):
            result = await self._handle_search(query)
        elif "sources" in query.lower() or "available" in query.lower():
            result = await self._handle_sources()
        else:
            result = "No recognized tool operation in query."

        # Update state
        state["tool_results"] = result
        state["current_worker"] = "tool_agent"
        state["messages"].append(AIMessage(content=str(result)))

        return state

    async def _handle_crawl(self, query: str) -> dict:
        """Handle crawl operations."""
        # Extract URL (simplified - production should use regex)
        words = query.split()
        url = next((w for w in words if w.startswith("http")), None)

        if not url:
            return {"error": "No URL found in query"}

        # Check if source already exists
        sources_result = await self.mcp_client.invoke_tool(
            "crawl4ai__get_available_sources",
            {}
        )

        domain = self._extract_domain(url)
        exists = any(s["domain"] == domain for s in sources_result.get("sources", []))

        if exists:
            return {
                "status": "already_crawled",
                "message": f"Domain {domain} already in database. Use search instead.",
                "domain": domain
            }

        # Determine crawl tool
        if "sitemap" in query.lower() or url.endswith(".xml"):
            tool_result = await self.mcp_client.invoke_tool(
                "crawl4ai__smart_crawl_url",
                {
                    "url": url,
                    "max_depth": 3,
                    "max_concurrent": 10
                }
            )
        else:
            tool_result = await self.mcp_client.invoke_tool(
                "crawl4ai__crawl_single_page",
                {"url": url}
            )

        return {
            "status": "success",
            "tool_used": tool_result.get("crawl_type", "single_page"),
            "urls_crawled": tool_result.get("urls_crawled", 1),
            "chunks_stored": tool_result.get("chunks_stored", 0)
        }

    async def _handle_search(self, query: str) -> dict:
        """Handle search operations."""
        # Perform RAG query
        result = await self.mcp_client.invoke_tool(
            "crawl4ai__perform_rag_query",
            {
                "query": query,
                "match_count": 5
            }
        )

        # Format results for consumption
        formatted_results = []
        for r in result.get("results", []):
            formatted_results.append({
                "content": r["chunk"][:500],  # Truncate for context window
                "source": r["url"],
                "relevance": r["similarity"]
            })

        return {
            "status": "success",
            "results": formatted_results,
            "total_results": len(formatted_results)
        }

    async def _handle_sources(self) -> dict:
        """List available sources."""
        result = await self.mcp_client.invoke_tool(
            "crawl4ai__get_available_sources",
            {}
        )

        return {
            "status": "success",
            "sources": result.get("sources", [])
        }

    def _extract_domain(self, url: str) -> str:
        """Extract domain from URL."""
        from urllib.parse import urlparse
        return urlparse(url).netloc


# Usage in LangGraph supervisor
async def create_graph():
    """Create LangGraph with Tool Agent."""
    workflow = StateGraph(AgentState)

    # Initialize agents
    tool_agent = CrawlToolAgent()

    # Define agent node
    async def tool_agent_node(state: AgentState):
        return await tool_agent.execute(state)

    # Add nodes
    workflow.add_node("tool_agent", tool_agent_node)

    # Define conditional routing
    def route_query(state: AgentState):
        query_type = state.get("query_type", "general")
        if query_type == "tool":
            return "tool_agent"
        return END

    workflow.set_conditional_entry_point(route_query)
    workflow.add_edge("tool_agent", END)

    return workflow.compile()
```

---

### 5.2 RAG Query with Error Handling

```python
async def perform_rag_with_fallback(
    mcp_client: MultiServerMCPClient,
    query: str,
    source: Optional[str] = None
) -> dict:
    """
    Perform RAG query with error handling and fallback strategies.

    Args:
        mcp_client: MCP client instance
        query: Search query
        source: Optional domain filter

    Returns:
        RAG results with metadata
    """
    max_retries = 3
    retry_delay = 1.0

    for attempt in range(max_retries):
        try:
            # Attempt RAG query
            result = await mcp_client.invoke_tool(
                "crawl4ai__perform_rag_query",
                {
                    "query": query,
                    "source": source,
                    "match_count": 5
                }
            )

            # Check if results sufficient
            if not result.get("results"):
                # No results - try without source filter
                if source:
                    print(f"No results for source {source}, retrying without filter")
                    return await perform_rag_with_fallback(mcp_client, query, None)
                else:
                    return {
                        "status": "no_results",
                        "message": "No content found for query. Consider crawling relevant sources.",
                        "results": []
                    }

            return {
                "status": "success",
                "results": result["results"],
                "query": query,
                "source_filter": source
            }

        except Exception as e:
            if attempt < max_retries - 1:
                print(f"RAG query failed (attempt {attempt + 1}/{max_retries}): {e}")
                await asyncio.sleep(retry_delay)
                retry_delay *= 2
            else:
                return {
                    "status": "error",
                    "error": str(e),
                    "message": "RAG query failed after retries"
                }
```

---

### 5.3 Crawl Deduplication Check

```python
async def crawl_with_deduplication(
    mcp_client: MultiServerMCPClient,
    url: str,
    force_recrawl: bool = False
) -> dict:
    """
    Check if URL already crawled before triggering new crawl.

    Args:
        mcp_client: MCP client instance
        url: Target URL
        force_recrawl: Force re-crawl even if exists

    Returns:
        Crawl results or existing source info
    """
    from urllib.parse import urlparse

    # Extract domain
    domain = urlparse(url).netloc

    # Check existing sources
    sources_result = await mcp_client.invoke_tool(
        "crawl4ai__get_available_sources",
        {}
    )

    existing_source = next(
        (s for s in sources_result.get("sources", []) if s["domain"] == domain),
        None
    )

    if existing_source and not force_recrawl:
        # Content already exists
        last_updated = existing_source.get("last_updated", "Unknown")
        age_hours = (datetime.now() - datetime.fromisoformat(last_updated)).total_hours()

        if age_hours < 24:
            # Recent crawl, skip
            return {
                "status": "skipped",
                "reason": "Content crawled recently",
                "domain": domain,
                "chunks_available": existing_source["total_chunks"],
                "last_updated": last_updated,
                "age_hours": age_hours
            }

    # Proceed with crawl
    crawl_result = await mcp_client.invoke_tool(
        "crawl4ai__smart_crawl_url",
        {"url": url}
    )

    return {
        "status": "crawled",
        "domain": domain,
        **crawl_result
    }
```

---

## 6. Validation of Specification

### 6.1 Specification Review

I have reviewed the specification draft (`/nodes/hx-lang-server/specification/node-spec.md`) and provide the following validation:

**ACCURATE:**
- ✅ FR-017: Correctly identifies hx-lang-server as **MCP CLIENT** (not server)
- ✅ FR-018: Correctly routes through FastMCP gateway (hx-fastmcp-server.hx.dev.local)
- ✅ FR-019: Correctly mentions Crawl4AI MCP tool discovery
- ✅ FR-020: Correctly identifies tool namespace prefixes
- ✅ Lines 420-455: MCP client configuration is accurate

**REQUIRES CLARIFICATION:**

1. **PostgreSQL Schema Isolation (CRITICAL)**
   - **Current State:** Specification mentions PostgreSQL for checkpoints but doesn't address Crawl4AI MCP's PostgreSQL usage
   - **Issue:** Both services use PostgreSQL - risk of schema conflicts
   - **Recommendation:** Add explicit schema isolation requirement in Section "PostgreSQL Checkpoint Configuration" (lines 315-368)
   - **Proposed Addition:**
     ```markdown
     ### Schema Isolation (CRITICAL)

     LangGraph and Crawl4AI MCP both use PostgreSQL. Schema isolation is MANDATORY:

     ```sql
     -- LangGraph checkpoints
     CREATE SCHEMA langgraph AUTHORIZATION hx_lang_server;

     -- Crawl4AI MCP content (accessed via MCP tools, not direct SQL)
     CREATE SCHEMA crawl4ai_rag AUTHORIZATION hx_lang_server;

     -- Set search path
     ALTER USER hx_lang_server SET search_path TO langgraph, public;
     ```

     **Note:** LangGraph agents access Crawl4AI content via MCP tools only, NOT direct PostgreSQL queries.
     ```

2. **Crawl4AI MCP Port Number**
   - **Current State:** Line 579 lists "Crawl4AI MCP | hx-crawl4ai-mcp-server.hx.dev.local | 11235"
   - **Issue:** Port 11235 is correct BUT this is the SSE transport port (not exposed to LangGraph)
   - **Clarification:** LangGraph connects to **FastMCP gateway (port 8000)**, which internally routes to Crawl4AI MCP
   - **Recommendation:** Update line 579 to clarify routing:
     ```markdown
     | Crawl4AI MCP | hx-crawl4ai-mcp-server.hx.dev.local | 11235 (via FastMCP gateway) | Web crawling |
     ```

3. **RAG Corpus Building Workflow (MISSING)**
   - **Current State:** Specification mentions "LightRAG Integration" (FR-014 to FR-016) but doesn't describe how Crawl4AI MCP fits into RAG workflows
   - **Issue:** No guidance on when to use Crawl4AI vs LightRAG for retrieval
   - **Recommendation:** Add section after line 315:
     ```markdown
     ### Crawl4AI vs LightRAG Usage

     | Use Case | Service | Rationale |
     |----------|---------|-----------|
     | Web content retrieval | Crawl4AI MCP | Semantic search over crawled pages |
     | Knowledge graph queries | LightRAG | Entity relationships, cross-document reasoning |
     | Code example search | Crawl4AI MCP | Agentic RAG for code snippets |
     | Document entity extraction | LightRAG | Neo4j knowledge graph construction |

     **Workflow Pattern:**
     1. Check Crawl4AI sources: `get_available_sources`
     2. If missing, crawl: `smart_crawl_url`
     3. Search crawled content: `perform_rag_query`
     4. Optionally augment with LightRAG knowledge graph
     ```

4. **OpenAI API Cost Monitoring (MISSING)**
   - **Current State:** No mention of OpenAI API costs from Crawl4AI MCP embeddings
   - **Issue:** Crawl4AI uses OpenAI `text-embedding-3-small` for embeddings - costs can accumulate
   - **Recommendation:** Add to NFR section (after line 113):
     ```markdown
     - **NFR-006**: Monitor OpenAI API usage from Crawl4AI MCP operations
     - **NFR-007**: Alert if Crawl4AI embedding costs exceed $10/day threshold
     ```

5. **Coordination with Diana Wu (MISSING)**
   - **Current State:** No mention of Diana Wu (Crawl4AI Worker) coordination
   - **Issue:** LangGraph agents may trigger duplicate crawls if not coordinated with Diana
   - **Recommendation:** Add to "Dependencies" section (after line 581):
     ```markdown
     ### Operational Coordination

     | Coordinator | Service | Coordination Point |
     |-------------|---------|-------------------|
     | Diana Wu | Crawl4AI Worker | Avoid duplicate batch crawls |

     **Coordination Strategy:**
     - LangGraph checks `get_available_sources` before triggering crawls
     - If domain exists, use `perform_rag_query` instead of re-crawling
     - Rate limit: Max 5 concurrent crawls per LangGraph session
     ```

---

### 6.2 Specification Corrections

**Section: MCP Client Integration (Lines 416-455)**

**Current Text (Lines 427-446):**
```python
mcp_client = MultiServerMCPClient(
    servers={
        "fastmcp": {
            "transport": "streamable_http",
            "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        }
    }
)

# Tool discovery
tools = await mcp_client.get_tools()

# Tool invocation (handles namespace prefixes)
result = await mcp_client.invoke_tool("crawl4ai__smart_crawl_url", {
    "url": "https://example.com",
    "output_format": "markdown"
})
```

**Issue:** Parameter `output_format` does not exist in `smart_crawl_url` tool

**Corrected Code:**
```python
mcp_client = MultiServerMCPClient(
    servers={
        "fastmcp": {
            "transport": "streamable_http",
            "url": "http://hx-fastmcp-server.hx.dev.local:8000/mcp",
        }
    }
)

# Tool discovery
tools = await mcp_client.get_tools()

# Tool invocation (handles namespace prefixes)
result = await mcp_client.invoke_tool("crawl4ai__smart_crawl_url", {
    "url": "https://example.com/sitemap.xml",
    "max_depth": 3,
    "max_concurrent": 10,
    "chunk_size": 5000
})
```

---

### 6.3 Open Questions for Sophia (LangGraph Lead)

1. **Tool Registration Strategy:**
   - **Question:** Should LangGraph maintain a persistent tool registry, or discover tools on-demand for each query?
   - **Recommendation:** Persistent registry with hourly refresh (caching)

2. **MCP Protocol Version:**
   - **Question:** What MCP protocol version does `langchain-mcp-adapters` v0.1.0 support?
   - **Action Required:** Validate compatibility with FastMCP gateway (George Kim coordination)

3. **Error Handling for MCP Failures:**
   - **Question:** How should LangGraph handle Crawl4AI MCP unavailability (503 errors)?
   - **Recommendation:** Circuit breaker pattern with fallback to LightRAG-only mode

4. **Redis Caching for MCP Responses:**
   - **Question:** Should LangGraph cache Crawl4AI MCP responses in Redis to reduce duplicate tool invocations?
   - **Recommendation:** Cache `perform_rag_query` results for 10 minutes (TTL)

5. **Concurrent Crawl Limits:**
   - **Question:** What rate limits should LangGraph enforce for Crawl4AI tool invocations?
   - **Recommendation:** Max 5 concurrent crawls, max 100 crawl requests/hour per user

---

## 7. Recommendations for Specification Phase

### 7.1 High Priority Actions

1. **Add PostgreSQL Schema Isolation Section**
   - Location: After line 368 in specification
   - Content: Schema creation SQL, search path configuration, access patterns

2. **Clarify Crawl4AI vs LightRAG Usage**
   - Location: After line 315 (before PostgreSQL section)
   - Content: Decision matrix for service selection, workflow patterns

3. **Add OpenAI API Cost Monitoring**
   - Location: NFR section (after line 113)
   - Content: Cost tracking, alerting thresholds, budget controls

4. **Document Diana Wu Coordination**
   - Location: Dependencies section (after line 581)
   - Content: Coordination strategy, deduplication checks, rate limiting

5. **Correct MCP Tool Parameter Examples**
   - Location: Lines 427-446
   - Content: Accurate parameters for `smart_crawl_url` (remove `output_format`)

---

### 7.2 Medium Priority Actions

6. **Add RAG Strategy Configuration Guidance**
   - Location: Configuration Management section (after line 650)
   - Content: Recommended settings for `USE_HYBRID_SEARCH`, `USE_RERANKING`, etc.

7. **Document MCP Tool Namespace Handling**
   - Location: MCP Client Integration section (lines 416-455)
   - Content: Explain `crawl4ai__` prefix, tool discovery filtering

8. **Add Code Agent Example Integration**
   - Location: Architecture Overview section (after line 220)
   - Content: Code Agent using `search_code_examples` tool

9. **Document Error Handling Patterns**
   - Location: New section after API Specification (line 522)
   - Content: Circuit breaker, retries, fallback strategies

10. **Add Performance Benchmarking Requirements**
    - Location: Testing Strategy section (after line 885)
    - Content: MCP tool invocation latency targets, throughput tests

---

### 7.3 Low Priority Actions

11. **Document Crawl4AI MCP Internal Architecture**
    - Location: Appendix (new section)
    - Content: PostgreSQL schema, pgvector configuration, embedding model

12. **Add Migration Path to Ollama Embeddings**
    - Location: Appendix (future considerations)
    - Content: Replace OpenAI embeddings with local Ollama embeddings

13. **Document Multi-Source RAG Patterns**
    - Location: Examples section (new)
    - Content: Combining Crawl4AI + LightRAG results in single query

---

## 8. Conclusion

This contribution provides comprehensive technical guidance for integrating Crawl4AI MCP with hx-lang-server. The integration enables LangGraph agents to perform web scraping, RAG corpus building, and semantic search via the Model Context Protocol.

**Key Takeaways:**

1. **8 MCP Tools Available:** 5 active (crawling, RAG query, code search), 3 deferred to LightRAG
2. **MCP Client Pattern:** LangGraph → FastMCP Gateway → Crawl4AI MCP Server
3. **PostgreSQL Isolation Required:** Separate schemas for LangGraph checkpoints vs Crawl4AI content
4. **RAG Strategy Recommendations:** Enable hybrid search + reranking, disable contextual embeddings by default
5. **Coordination Required:** Check sources before crawling, coordinate with Diana Wu

**Critical Success Factors:**

- ✅ Namespace prefix handling (`crawl4ai__` prefix)
- ✅ PostgreSQL schema isolation (prevent conflicts)
- ✅ Crawl deduplication (avoid redundant operations)
- ✅ OpenAI API cost monitoring (budget controls)
- ✅ Error handling (circuit breaker for MCP failures)

**Next Steps:**

1. Sophia (LangGraph lead) incorporates recommendations into specification
2. George Kim (FastMCP) validates MCP protocol compatibility
3. Trinity (PostgreSQL DBA) creates schema isolation for LangGraph + Crawl4AI
4. William Chen (Infrastructure) provisions PostgreSQL database `hx_lang_server`

---

**Signature:** David Park, Crawl4AI MCP Subject Matter Expert
**Date:** 2025-12-01
**Status:** CONTRIBUTION COMPLETE - READY FOR SPECIFICATION INTEGRATION
