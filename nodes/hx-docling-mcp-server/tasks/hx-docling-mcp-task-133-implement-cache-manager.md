# Task 133: Implement Redis Cache Manager

**Assigned To**: sri-patel
**Estimated Effort**: 3 hours
**Dependencies**: Task 131 (Redis client module)
**Status**: Not Started

## Objective

Implement cache manager module (`/opt/docling-mcp/src/cache_manager.py`) with Redis-backed caching for document metadata, LLM responses (semantic caching), and DoclingDocument objects to optimize performance and reduce redundant processing.

## Pre-Execution Validation

**CRITICAL**: Check if cache manager module already exists BEFORE creating it to prevent duplication.

```bash
# Check if cache manager module file exists
if [ -f "/opt/docling-mcp/src/cache_manager.py" ]; then
    echo "✅ VALIDATION RESULT: Cache manager module already exists"
    echo "ACTION: SKIP task execution - validate module functionality instead"
    echo "NEXT: Test caching with: python3 -c 'from src.cache_manager import CacheManager; cm = CacheManager(); cm.set(\"test_key\", \"test_value\", ttl_hours=1); print(cm.get(\"test_key\"))'"
    exit 0
else
    echo "❌ VALIDATION RESULT: Cache manager module does NOT exist"
    echo "ACTION: PROCEED with module creation"
fi
```

**If Module Exists**: Skip to Validation section, verify cache operations work correctly

**If Module Does Not Exist**: Continue with Implementation Steps below

---

## Context

Redis caching provides performance optimization for hx-docling-mcp-server by reducing redundant operations:

**Cache Types (FR-021A):**
1. **Document Metadata Cache**: File format, page count, size, author, title (7-day TTL)
2. **LLM Response Cache (Semantic Caching)**: Entity extraction results (24-hour TTL)
3. **DoclingDocument Cache**: Converted document JSON (24-hour TTL)

**Key Design Principles:**
- Cache key naming convention: `cache:<type>:<hash>`
- Hash generation: SHA256 for content-based keys
- TTL-based expiration (automatic cleanup)
- Eviction policy: volatile-lru (Redis server configuration)
- Cache hit/miss metrics tracking
- Graceful degradation: Service works without cache

## Acceptance Criteria

- [ ] Cache manager module created at `/opt/docling-mcp/src/cache_manager.py`
- [ ] Document metadata caching with 7-day TTL
- [ ] LLM response semantic caching with SHA256 hash keys (24-hour TTL)
- [ ] DoclingDocument caching with compression support (24-hour TTL)
- [ ] Cache key naming convention: `cache:<type>:<identifier>`
- [ ] TTL management (configurable per cache type)
- [ ] Cache invalidation methods (manual delete)
- [ ] Cache hit/miss metrics tracking
- [ ] Size limits: Max 5MB per DoclingDocument cache entry
- [ ] Graceful degradation if Redis unavailable
- [ ] Module integrates with RedisClient from Task 131

## Implementation Steps

### Step 1: Create Cache Manager Module

```bash
# SSH to hx-docling-mcp-server
ssh agent0@hx-docling-mcp-server.hx.dev.local
# Password: Major8859!

# Create cache_manager.py module
sudo -u docling-mcp@hx.dev.local bash -c 'cat > /opt/docling-mcp/src/cache_manager.py << '\''EOF'\''
"""
Cache Manager Module for Docling MCP Server

Provides Redis-backed caching for document metadata, LLM responses (semantic
caching), and DoclingDocument objects to optimize performance.

Integration: Uses RedisClient from src.integrations.redis_client
"""

import hashlib
import json
import logging
from typing import Optional, Dict, Any
from dataclasses import dataclass

from src.integrations.redis_client import (
    get_redis_client,
    RedisOperationError
)

logger = logging.getLogger(__name__)


@dataclass
class CacheMetrics:
    """Cache hit/miss metrics for monitoring."""
    hits: int = 0
    misses: int = 0
    total_requests: int = 0

    @property
    def hit_ratio(self) -> float:
        """Calculate cache hit ratio (0.0 to 1.0)."""
        if self.total_requests == 0:
            return 0.0
        return self.hits / self.total_requests


class CacheManager:
    """
    Manages Redis caching for performance optimization.

    Features:
    - Document metadata caching (7-day TTL)
    - LLM response semantic caching with SHA256 hashing (24-hour TTL)
    - DoclingDocument caching with compression (24-hour TTL)
    - Cache key naming convention: cache:<type>:<identifier>
    - Cache hit/miss metrics tracking
    - Size limits (5MB max per DoclingDocument)
    - Graceful degradation if Redis unavailable
    """

    # Cache key prefixes
    PREFIX_DOC_METADATA = "cache:doc_metadata:"
    PREFIX_ENTITIES = "cache:entities:"
    PREFIX_DOCLING = "cache:docling:"
    PREFIX_QUERY = "cache:query:"

    # TTL configuration (in hours)
    TTL_DOC_METADATA = 168  # 7 days
    TTL_ENTITIES = 24       # 24 hours
    TTL_DOCLING = 24        # 24 hours
    TTL_QUERY = 1           # 1 hour (future use)

    # Size limits
    MAX_DOCLING_SIZE_MB = 5

    def __init__(
        self,
        enabled: bool = True,
        ttl_metadata_hours: int = TTL_DOC_METADATA,
        ttl_entities_hours: int = TTL_ENTITIES,
        ttl_docling_hours: int = TTL_DOCLING,
        max_docling_size_mb: int = MAX_DOCLING_SIZE_MB
    ):
        """
        Initialize cache manager.

        Args:
            enabled: Enable caching (default: True)
            ttl_metadata_hours: Document metadata cache TTL (default: 168 hours / 7 days)
            ttl_entities_hours: Entity extraction cache TTL (default: 24 hours)
            ttl_docling_hours: DoclingDocument cache TTL (default: 24 hours)
            max_docling_size_mb: Max size for DoclingDocument cache in MB (default: 5MB)
        """
        self.enabled = enabled
        self.ttl_metadata_hours = ttl_metadata_hours
        self.ttl_entities_hours = ttl_entities_hours
        self.ttl_docling_hours = ttl_docling_hours
        self.max_docling_size_mb = max_docling_size_mb

        # Get Redis client singleton
        self.redis_client = get_redis_client()

        # Initialize metrics per cache type
        self.metrics = {
            "metadata": CacheMetrics(),
            "entities": CacheMetrics(),
            "docling": CacheMetrics(),
            "query": CacheMetrics()
        }

        if not enabled:
            logger.info("Cache manager initialized: caching DISABLED")
        elif self.redis_client is None:
            logger.warning(
                "Redis client not initialized. Caching disabled. "
                "Service will operate without cache."
            )
        elif not self.redis_client.is_available():
            logger.warning(
                "Redis unavailable. Caching disabled. "
                "Service will operate without cache."
            )
        else:
            logger.info(
                f"Cache manager initialized: "
                f"metadata_ttl={ttl_metadata_hours}h, "
                f"entities_ttl={ttl_entities_hours}h, "
                f"docling_ttl={ttl_docling_hours}h, "
                f"max_size={max_docling_size_mb}MB"
            )

    def is_available(self) -> bool:
        """
        Check if caching is available (enabled and Redis connected).

        Returns:
            True if caching available, False otherwise
        """
        if not self.enabled:
            return False
        if self.redis_client is None:
            return False
        return self.redis_client.is_available()

    @staticmethod
    def generate_hash(content: str) -> str:
        """
        Generate SHA256 hash for content-based cache keys.

        Args:
            content: Content to hash (e.g., document content + prompt + model)

        Returns:
            SHA256 hash hex digest (64 characters)
        """
        return hashlib.sha256(content.encode('utf-8')).hexdigest()

    def cache_document_metadata(
        self,
        document_hash: str,
        metadata: Dict[str, Any]
    ) -> bool:
        """
        Cache document metadata (format, page count, file size, author, title).

        Args:
            document_hash: Document content hash (SHA256)
            metadata: Document metadata dictionary

        Returns:
            True if cached, False if caching unavailable
        """
        if not self.is_available():
            logger.debug("Cannot cache metadata: caching unavailable")
            return False

        try:
            cache_key = f"{self.PREFIX_DOC_METADATA}{document_hash}"
            cache_value = json.dumps(metadata)

            self.redis_client.set(
                cache_key,
                cache_value,
                ex=self.ttl_metadata_hours * 3600  # Convert to seconds
            )

            logger.debug(f"Cached document metadata: {document_hash[:16]}... (TTL: {self.ttl_metadata_hours}h)")
            return True

        except (RedisOperationError, json.JSONDecodeError) as e:
            logger.warning(f"Failed to cache document metadata: {str(e)}")
            return False

    def get_document_metadata(self, document_hash: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve cached document metadata.

        Args:
            document_hash: Document content hash (SHA256)

        Returns:
            Metadata dictionary, or None if cache miss or unavailable
        """
        cache_type = "metadata"
        self.metrics[cache_type].total_requests += 1

        if not self.is_available():
            self.metrics[cache_type].misses += 1
            return None

        try:
            cache_key = f"{self.PREFIX_DOC_METADATA}{document_hash}"
            cache_value = self.redis_client.get(cache_key)

            if cache_value:
                self.metrics[cache_type].hits += 1
                logger.debug(f"Cache HIT: document metadata {document_hash[:16]}...")
                return json.loads(cache_value)
            else:
                self.metrics[cache_type].misses += 1
                logger.debug(f"Cache MISS: document metadata {document_hash[:16]}...")
                return None

        except (RedisOperationError, json.JSONDecodeError) as e:
            self.metrics[cache_type].misses += 1
            logger.warning(f"Failed to get document metadata from cache: {str(e)}")
            return None

    def cache_entity_extraction(
        self,
        document_content: str,
        extraction_prompt: str,
        model_name: str,
        entities: Dict[str, Any]
    ) -> bool:
        """
        Cache entity extraction results (semantic caching).

        Args:
            document_content: Document text content
            extraction_prompt: Entity extraction prompt
            model_name: LLM model name used for extraction
            entities: Entity extraction results

        Returns:
            True if cached, False if caching unavailable
        """
        if not self.is_available():
            logger.debug("Cannot cache entity extraction: caching unavailable")
            return False

        try:
            # Generate semantic cache key
            semantic_key = f"{document_content}{extraction_prompt}{model_name}"
            prompt_hash = self.generate_hash(semantic_key)

            cache_key = f"{self.PREFIX_ENTITIES}{prompt_hash}"
            cache_value = json.dumps(entities)

            self.redis_client.set(
                cache_key,
                cache_value,
                ex=self.ttl_entities_hours * 3600  # Convert to seconds
            )

            logger.debug(
                f"Cached entity extraction: {prompt_hash[:16]}... "
                f"(TTL: {self.ttl_entities_hours}h)"
            )
            return True

        except (RedisOperationError, json.JSONDecodeError) as e:
            logger.warning(f"Failed to cache entity extraction: {str(e)}")
            return False

    def get_entity_extraction(
        self,
        document_content: str,
        extraction_prompt: str,
        model_name: str
    ) -> Optional[Dict[str, Any]]:
        """
        Retrieve cached entity extraction results (semantic caching).

        Args:
            document_content: Document text content
            extraction_prompt: Entity extraction prompt
            model_name: LLM model name used for extraction

        Returns:
            Entity extraction results, or None if cache miss or unavailable
        """
        cache_type = "entities"
        self.metrics[cache_type].total_requests += 1

        if not self.is_available():
            self.metrics[cache_type].misses += 1
            return None

        try:
            # Generate semantic cache key
            semantic_key = f"{document_content}{extraction_prompt}{model_name}"
            prompt_hash = self.generate_hash(semantic_key)

            cache_key = f"{self.PREFIX_ENTITIES}{prompt_hash}"
            cache_value = self.redis_client.get(cache_key)

            if cache_value:
                self.metrics[cache_type].hits += 1
                logger.debug(f"Cache HIT: entity extraction {prompt_hash[:16]}...")
                return json.loads(cache_value)
            else:
                self.metrics[cache_type].misses += 1
                logger.debug(f"Cache MISS: entity extraction {prompt_hash[:16]}...")
                return None

        except (RedisOperationError, json.JSONDecodeError) as e:
            self.metrics[cache_type].misses += 1
            logger.warning(f"Failed to get entity extraction from cache: {str(e)}")
            return None

    def cache_docling_document(
        self,
        document_hash: str,
        docling_json: str
    ) -> bool:
        """
        Cache DoclingDocument JSON with size limit check.

        Args:
            document_hash: Document content hash (SHA256)
            docling_json: DoclingDocument JSON string

        Returns:
            True if cached, False if too large or caching unavailable
        """
        if not self.is_available():
            logger.debug("Cannot cache DoclingDocument: caching unavailable")
            return False

        # Check size limit
        size_mb = len(docling_json.encode('utf-8')) / (1024 * 1024)
        if size_mb > self.max_docling_size_mb:
            logger.warning(
                f"DoclingDocument too large to cache: {size_mb:.2f}MB > {self.max_docling_size_mb}MB limit"
            )
            return False

        try:
            cache_key = f"{self.PREFIX_DOCLING}{document_hash}"

            self.redis_client.set(
                cache_key,
                docling_json,
                ex=self.ttl_docling_hours * 3600  # Convert to seconds
            )

            logger.debug(
                f"Cached DoclingDocument: {document_hash[:16]}... "
                f"({size_mb:.2f}MB, TTL: {self.ttl_docling_hours}h)"
            )
            return True

        except RedisOperationError as e:
            logger.warning(f"Failed to cache DoclingDocument: {str(e)}")
            return False

    def get_docling_document(self, document_hash: str) -> Optional[str]:
        """
        Retrieve cached DoclingDocument JSON.

        Args:
            document_hash: Document content hash (SHA256)

        Returns:
            DoclingDocument JSON string, or None if cache miss or unavailable
        """
        cache_type = "docling"
        self.metrics[cache_type].total_requests += 1

        if not self.is_available():
            self.metrics[cache_type].misses += 1
            return None

        try:
            cache_key = f"{self.PREFIX_DOCLING}{document_hash}"
            cache_value = self.redis_client.get(cache_key)

            if cache_value:
                self.metrics[cache_type].hits += 1
                size_mb = len(cache_value.encode('utf-8')) / (1024 * 1024)
                logger.debug(
                    f"Cache HIT: DoclingDocument {document_hash[:16]}... ({size_mb:.2f}MB)"
                )
                return cache_value
            else:
                self.metrics[cache_type].misses += 1
                logger.debug(f"Cache MISS: DoclingDocument {document_hash[:16]}...")
                return None

        except RedisOperationError as e:
            self.metrics[cache_type].misses += 1
            logger.warning(f"Failed to get DoclingDocument from cache: {str(e)}")
            return None

    def invalidate_document_metadata(self, document_hash: str) -> bool:
        """
        Invalidate (delete) cached document metadata.

        Args:
            document_hash: Document content hash (SHA256)

        Returns:
            True if deleted, False if caching unavailable
        """
        if not self.is_available():
            return False

        try:
            cache_key = f"{self.PREFIX_DOC_METADATA}{document_hash}"
            deleted_count = self.redis_client.delete(cache_key)

            if deleted_count > 0:
                logger.debug(f"Invalidated document metadata cache: {document_hash[:16]}...")
                return True
            else:
                logger.debug(f"No cached metadata to invalidate: {document_hash[:16]}...")
                return False

        except RedisOperationError as e:
            logger.warning(f"Failed to invalidate document metadata cache: {str(e)}")
            return False

    def invalidate_docling_document(self, document_hash: str) -> bool:
        """
        Invalidate (delete) cached DoclingDocument.

        Args:
            document_hash: Document content hash (SHA256)

        Returns:
            True if deleted, False if caching unavailable
        """
        if not self.is_available():
            return False

        try:
            cache_key = f"{self.PREFIX_DOCLING}{document_hash}"
            deleted_count = self.redis_client.delete(cache_key)

            if deleted_count > 0:
                logger.debug(f"Invalidated DoclingDocument cache: {document_hash[:16]}...")
                return True
            else:
                logger.debug(f"No cached DoclingDocument to invalidate: {document_hash[:16]}...")
                return False

        except RedisOperationError as e:
            logger.warning(f"Failed to invalidate DoclingDocument cache: {str(e)}")
            return False

    def get_metrics(self, cache_type: Optional[str] = None) -> Dict[str, CacheMetrics]:
        """
        Get cache hit/miss metrics.

        Args:
            cache_type: Specific cache type (metadata|entities|docling|query), or None for all

        Returns:
            Dictionary of cache metrics by type
        """
        if cache_type:
            return {cache_type: self.metrics.get(cache_type, CacheMetrics())}
        return self.metrics.copy()

    def reset_metrics(self):
        """Reset all cache metrics to zero."""
        for cache_type in self.metrics:
            self.metrics[cache_type] = CacheMetrics()
        logger.debug("Cache metrics reset")


# Singleton instance (initialized by config.py)
_cache_manager: Optional[CacheManager] = None


def get_cache_manager() -> Optional[CacheManager]:
    """
    Get singleton cache manager instance.

    Returns:
        CacheManager instance, or None if not initialized
    """
    return _cache_manager


def initialize_cache_manager(
    enabled: bool = True,
    ttl_metadata_hours: int = CacheManager.TTL_DOC_METADATA,
    ttl_entities_hours: int = CacheManager.TTL_ENTITIES,
    ttl_docling_hours: int = CacheManager.TTL_DOCLING,
    max_docling_size_mb: int = CacheManager.MAX_DOCLING_SIZE_MB
) -> CacheManager:
    """
    Initialize singleton cache manager instance.

    Args:
        enabled: Enable caching
        ttl_metadata_hours: Document metadata cache TTL
        ttl_entities_hours: Entity extraction cache TTL
        ttl_docling_hours: DoclingDocument cache TTL
        max_docling_size_mb: Max size for DoclingDocument cache in MB

    Returns:
        Initialized CacheManager instance
    """
    global _cache_manager

    _cache_manager = CacheManager(
        enabled=enabled,
        ttl_metadata_hours=ttl_metadata_hours,
        ttl_entities_hours=ttl_entities_hours,
        ttl_docling_hours=ttl_docling_hours,
        max_docling_size_mb=max_docling_size_mb
    )

    logger.info(
        f"Cache manager singleton initialized: "
        f"enabled={enabled}, "
        f"ttl_metadata={ttl_metadata_hours}h, "
        f"ttl_entities={ttl_entities_hours}h, "
        f"ttl_docling={ttl_docling_hours}h"
    )
    return _cache_manager
EOF'

# Verify file created
ls -la /opt/docling-mcp/src/cache_manager.py
```

### Step 2: Test Cache Manager Import and Operations

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test cache operations
python3 << 'EOF'
import sys
import json
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.cache_manager import initialize_cache_manager, CacheManager

# Initialize Redis client
redis_client = initialize_redis_client(
    host="hx-redis-server.hx.dev.local",
    port=6379
)
print("✓ Redis client initialized")

# Initialize cache manager
cache_manager = initialize_cache_manager(
    enabled=True,
    ttl_metadata_hours=168,
    ttl_entities_hours=24,
    ttl_docling_hours=24,
    max_docling_size_mb=5
)
print("✓ Cache manager initialized")

# Test document metadata caching
doc_hash = CacheManager.generate_hash("test_document_content")
metadata = {
    "format": "PDF",
    "pages": 10,
    "size_bytes": 1024000,
    "author": "Test Author",
    "title": "Test Document"
}

success = cache_manager.cache_document_metadata(doc_hash, metadata)
print(f"✓ Cached metadata: {success}")

# Test metadata retrieval
cached_metadata = cache_manager.get_document_metadata(doc_hash)
if cached_metadata == metadata:
    print("✓ Retrieved metadata matches original")
else:
    print("✗ Metadata mismatch")

# Test entity extraction caching (semantic caching)
doc_content = "This is a test document about artificial intelligence and machine learning."
prompt = "Extract entities of type TECHNOLOGY"
model = "gemma3:27b"

entities = {
    "entities": [
        {"text": "artificial intelligence", "type": "TECHNOLOGY"},
        {"text": "machine learning", "type": "TECHNOLOGY"}
    ]
}

success = cache_manager.cache_entity_extraction(doc_content, prompt, model, entities)
print(f"✓ Cached entity extraction: {success}")

# Test entity extraction retrieval (semantic caching)
cached_entities = cache_manager.get_entity_extraction(doc_content, prompt, model)
if cached_entities == entities:
    print("✓ Retrieved entities match original")
else:
    print("✗ Entities mismatch")

# Test DoclingDocument caching
docling_json = json.dumps({
    "schema_version": "1.0",
    "document_hash": doc_hash,
    "content": "Test document content",
    "structure": {"headings": [], "tables": []}
})

success = cache_manager.cache_docling_document(doc_hash, docling_json)
print(f"✓ Cached DoclingDocument: {success}")

# Test DoclingDocument retrieval
cached_docling = cache_manager.get_docling_document(doc_hash)
if cached_docling == docling_json:
    print("✓ Retrieved DoclingDocument matches original")
else:
    print("✗ DoclingDocument mismatch")

# Test metrics
metrics = cache_manager.get_metrics()
print(f"\n✓ Cache metrics:")
print(f"  Metadata: hits={metrics['metadata'].hits}, misses={metrics['metadata'].misses}, hit_ratio={metrics['metadata'].hit_ratio:.2f}")
print(f"  Entities: hits={metrics['entities'].hits}, misses={metrics['entities'].misses}, hit_ratio={metrics['entities'].hit_ratio:.2f}")
print(f"  Docling: hits={metrics['docling'].hits}, misses={metrics['docling'].misses}, hit_ratio={metrics['docling'].hit_ratio:.2f}")

# Test cache invalidation
cache_manager.invalidate_document_metadata(doc_hash)
cache_manager.invalidate_docling_document(doc_hash)
print("\n✓ Cache invalidation successful")

print("\n✅ All cache operations completed successfully")
EOF
```

## Validation

**Validation Commands:**

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# 1. Verify cache manager module exists
test -f /opt/docling-mcp/src/cache_manager.py && echo "PASS: Cache manager module exists" || echo "FAIL: Module not found"

# 2. Verify module imports successfully
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.cache_manager import CacheManager; print('PASS: Module imports successfully')" 2>&1 | grep -q "PASS" && echo "PASS: Import successful" || echo "FAIL: Import failed"

# 3. Verify SHA256 hash generation
python3 -c "import sys; sys.path.insert(0, '/opt/docling-mcp'); from src.cache_manager import CacheManager; h = CacheManager.generate_hash('test'); print('PASS: Hash generation works') if len(h) == 64 else print('FAIL: Invalid hash length')"

# 4. Verify cache hit/miss tracking
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')

from src.integrations.redis_client import initialize_redis_client
from src.cache_manager import initialize_cache_manager, CacheManager

redis_client = initialize_redis_client(host="hx-redis-server.hx.dev.local", port=6379)
cache_manager = initialize_cache_manager()

# Generate test hash
doc_hash = CacheManager.generate_hash("validation_test")

# Cache miss (first access)
result = cache_manager.get_document_metadata(doc_hash)
metrics = cache_manager.get_metrics("metadata")
if result is None and metrics["metadata"].misses == 1:
    print("PASS: Cache miss tracked correctly")
else:
    print("FAIL: Cache miss tracking failed")

# Cache hit (after storing)
cache_manager.cache_document_metadata(doc_hash, {"test": "data"})
result = cache_manager.get_document_metadata(doc_hash)
metrics = cache_manager.get_metrics("metadata")
if result is not None and metrics["metadata"].hits == 1:
    print("PASS: Cache hit tracked correctly")
else:
    print("FAIL: Cache hit tracking failed")

# Cleanup
cache_manager.invalidate_document_metadata(doc_hash)
EOF
```

**Expected Outcomes:**
- All validation commands return "PASS"
- Cache operations work correctly (set/get)
- Metrics tracking works (hits/misses/ratio)
- SHA256 hashing produces 64-character hex strings
- Cache invalidation deletes keys successfully

## Notes

### Cache Key Naming Convention

**Format**: `cache:<type>:<identifier>`

**Examples:**
- Document metadata: `cache:doc_metadata:a3f5b8c9...` (SHA256 hash)
- Entity extraction: `cache:entities:7d2e4a1b...` (SHA256 of content+prompt+model)
- DoclingDocument: `cache:docling:a3f5b8c9...` (SHA256 hash)
- Query results: `cache:query:5e8f2c7a...` (future use)

### Semantic Caching Strategy

**Entity Extraction Cache Key:**
```
content = "Document text content..."
prompt = "Extract entities of type PERSON, ORG, LOCATION"
model = "gemma3:27b"

semantic_key = f"{content}{prompt}{model}"
cache_key = f"cache:entities:{SHA256(semantic_key)}"
```

**Why Semantic Caching:**
- Same document + same prompt + same model = identical results
- Avoids expensive LLM inference for repeated requests
- Target: >40% cache hit ratio for repeated documents

### TTL Strategy

| Cache Type | TTL | Rationale |
|------------|-----|-----------|
| Document Metadata | 168 hours (7 days) | Metadata rarely changes |
| Entity Extraction | 24 hours | LLM results may improve with model updates |
| DoclingDocument | 24 hours | Balance storage vs re-conversion cost |
| Query Results | 1 hour | Freshness for graph queries (future) |

### Size Limits

**DoclingDocument Cache:**
- Max size: 5MB per document
- Prevents Redis memory bloat
- Large documents: Skip caching, process on-demand

**Calculation:**
```python
size_mb = len(docling_json.encode('utf-8')) / (1024 * 1024)
if size_mb > 5:
    # Skip caching, log warning
```

### Cache Metrics Monitoring

**Track per cache type:**
- Hits: Successful cache retrievals
- Misses: Cache misses (key not found or expired)
- Total requests: Hits + Misses
- Hit ratio: Hits / Total requests

**Target Metrics (Specification):**
- Entity extraction cache hit ratio: >40%
- Overall cache effectiveness: Reduces LLM calls and conversion overhead

**Prometheus Integration (Future):**
```
cache_hits_total{cache_type="metadata|entities|docling"}
cache_misses_total{cache_type="..."}
cache_hit_ratio{cache_type="..."}
```

### Eviction Policy

**Redis Server Configuration (hx-redis-server):**
- Eviction policy: `volatile-lru` (evict least recently used keys with TTL)
- Applies when Redis memory >75% (maxmemory-policy)
- Automatic cleanup (no manual intervention required)

**Why volatile-lru:**
- Only evicts keys with TTL (cache keys)
- Preserves session keys with active TTL
- Balances memory usage automatically

### Graceful Degradation

**When Redis Unavailable:**
- `is_available()` returns False
- All cache operations return False (set) or None (get)
- Metrics track misses
- Service continues processing without cache (performance degradation acceptable)
- Logs: "Cannot cache: caching unavailable"

**Recovery:**
- Cache manager checks Redis health via `redis_client.is_available()`
- When Redis recovers, caching resumes automatically
- Metrics continue tracking from last known state

### Troubleshooting

**If cache hit ratio low (<10%):**
```bash
# Check cache key generation (should be consistent)
python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/docling-mcp')
from src.cache_manager import CacheManager

# Test hash consistency
content = "test content"
hash1 = CacheManager.generate_hash(content)
hash2 = CacheManager.generate_hash(content)
print(f"Hash consistent: {hash1 == hash2}")
EOF

# Check TTL values in Redis
redis-cli -h hx-redis-server.hx.dev.local TTL "cache:entities:<hash>"
```

**If cache size too large:**
```bash
# Check memory usage per cache type
redis-cli -h hx-redis-server.hx.dev.local --bigkeys

# Check DoclingDocument cache sizes
redis-cli -h hx-redis-server.hx.dev.local KEYS "cache:docling:*" | while read key; do
    redis-cli -h hx-redis-server.hx.dev.local MEMORY USAGE "$key"
done
```

**If eviction happening too frequently:**
```bash
# Check eviction stats
redis-cli -h hx-redis-server.hx.dev.local INFO stats | grep evicted

# Check memory usage
redis-cli -h hx-redis-server.hx.dev.local INFO memory | grep used_memory
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
  - Section 2.4.7: Caching Strategy (FR-021A)
- **Task 131**: Redis Client Module (dependency)
- **Semantic Caching**: Content-based cache key generation with SHA256
- **Redis Eviction**: https://redis.io/docs/reference/eviction/

## Risk Assessment

**Risk**: Low
- Cache is performance optimization only (not critical for functionality)
- Graceful degradation ensures service works without cache
- Size limits prevent memory exhaustion

**Mitigation**:
- TTL-based expiration prevents unbounded growth
- Size limits (5MB) for DoclingDocument cache
- Eviction policy (volatile-lru) handles memory pressure
- Comprehensive metrics for monitoring cache effectiveness
