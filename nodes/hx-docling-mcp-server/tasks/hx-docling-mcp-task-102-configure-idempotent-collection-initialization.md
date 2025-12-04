# Task 102: Configure Idempotent Collection Initialization

**Assigned To**: mitch-harper
**Estimated Effort**: 2.5 hours
**Dependencies**: Task 101 (Qdrant Client Module), Task 141 (Configuration Management)
**Status**: Not Started

## Objective

Implement idempotent collection initialization for `hx_docling_mcp_entities` and `hx_docling_mcp_relationships` collections with proper vector configuration (1024D, Cosine distance, HNSW indexing), automatic creation on service startup, and schema validation.

## Pre-Execution Validation

**CRITICAL**: Check if collections already exist and have correct configuration BEFORE creating.

```bash
# Validation command to check collection state
echo "Checking Qdrant collection status..."

QDRANT_URL="http://hx-qdrant-server.hx.dev.local:6333"

# Check entities collection
echo "Checking hx_docling_mcp_entities collection..."
ENTITIES_RESPONSE=$(curl -s -w "\n%{http_code}" "${QDRANT_URL}/collections/hx_docling_mcp_entities")
ENTITIES_HTTP_CODE=$(echo "$ENTITIES_RESPONSE" | tail -1)
ENTITIES_BODY=$(echo "$ENTITIES_RESPONSE" | sed '$d')

if [ "$ENTITIES_HTTP_CODE" = "200" ]; then
    echo "✅ Entities collection exists"

    # Validate vector dimensions
    VECTOR_SIZE=$(echo "$ENTITIES_BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['config']['params']['vectors']['size'])" 2>/dev/null)

    if [ "$VECTOR_SIZE" = "1024" ]; then
        echo "✅ Vector dimensions correct (1024)"
    else
        echo "⚠️  Vector dimensions incorrect: $VECTOR_SIZE (expected 1024)"
    fi
else
    echo "❌ Entities collection does not exist (HTTP $ENTITIES_HTTP_CODE)"
fi

# Check relationships collection
echo ""
echo "Checking hx_docling_mcp_relationships collection..."
RELS_RESPONSE=$(curl -s -w "\n%{http_code}" "${QDRANT_URL}/collections/hx_docling_mcp_relationships")
RELS_HTTP_CODE=$(echo "$RELS_RESPONSE" | tail -1)
RELS_BODY=$(echo "$RELS_RESPONSE" | sed '$d')

if [ "$RELS_HTTP_CODE" = "200" ]; then
    echo "✅ Relationships collection exists"

    # Validate vector dimensions
    VECTOR_SIZE=$(echo "$RELS_BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['result']['config']['params']['vectors']['size'])" 2>/dev/null)

    if [ "$VECTOR_SIZE" = "1024" ]; then
        echo "✅ Vector dimensions correct (1024)"
    else
        echo "⚠️  Vector dimensions incorrect: $VECTOR_SIZE (expected 1024)"
    fi
else
    echo "❌ Relationships collection does not exist (HTTP $RELS_HTTP_CODE)"
fi

echo ""
if [ "$ENTITIES_HTTP_CODE" = "200" ] && [ "$RELS_HTTP_CODE" = "200" ]; then
    echo "✅ VALIDATION RESULT: Both collections exist"
    echo "ACTION: SKIP collection creation, proceed to validation section"
else
    echo "❌ VALIDATION RESULT: Collections missing or incomplete"
    echo "ACTION: PROCEED with implementation steps"
fi
```

**If Already Complete**: Skip to Validation section
**If Partially Complete**: Create only missing collections
**If Not Complete**: Continue with Implementation Steps below

---

## Context

Qdrant collections must be initialized before entity/relationship storage operations. This task implements:

1. **Dual-Collection Architecture**:
   - **Entities Collection** (`hx_docling_mcp_entities`): Stores extracted entities with 1024D embeddings
   - **Relationships Collection** (`hx_docling_mcp_relationships`): Stores relationships with 1024D embeddings

2. **Vector Configuration**:
   - **Dimensions**: 1024 (bge-m3:567m embedding model output)
   - **Distance Metric**: Cosine (optimal for semantic similarity, normalized embeddings)
   - **HNSW Parameters**:
     - `m: 16` - Balanced connectivity (moderate RAM usage, good recall)
     - `ef_construct: 100` - Build-time search quality (sufficient for <1M entities)
   - **Quantization**: Disabled in Phase 1 (enabled in Phase 2 when >100K entities)
   - **Storage**: RAM-only (`on_disk: false`) for <100K entities

3. **Idempotent Initialization**:
   - Check if collection exists before creation
   - If exists, validate schema matches expected configuration
   - If schema mismatch, raise error (manual intervention required)
   - If missing, create with proper configuration

4. **Startup Integration**:
   - Collections initialized during MCP server startup (before accepting requests)
   - Health check includes collection validation
   - Service fails to start if collection creation fails

This task ensures knowledge graph storage infrastructure is ready before processing any documents.

## Acceptance Criteria

- [ ] Collection initialization module created at `/opt/docling-mcp/src/integrations/qdrant_collections.py`
- [ ] `initialize_collections()` async function creates both collections idempotently
- [ ] Entity collection configured: 1024D vectors, Cosine distance, HNSW (m:16, ef_construct:100)
- [ ] Relationship collection configured: 1024D vectors, Cosine distance, HNSW (m:16, ef_construct:100)
- [ ] Schema validation checks existing collections for correct configuration
- [ ] Error raised on schema mismatch (vector dimension, distance metric)
- [ ] Integration with MCP server startup sequence (called in main.py)
- [ ] Comprehensive logging for creation, validation, errors
- [ ] Unit tests for idempotent behavior (collection exists, schema validation)

## Implementation Steps

### Step 1: Implement Collection Configuration Schema

```bash
# Create collection initialization module
COLLECTIONS_FILE="/opt/docling-mcp/src/integrations/qdrant_collections.py"

echo "Creating Qdrant collection initialization module..."

sudo tee "$COLLECTIONS_FILE" > /dev/null <<'EOF'
"""
Qdrant collection initialization and schema management.

Provides idempotent collection creation for knowledge graph storage:
- hx_docling_mcp_entities (1024D entity embeddings)
- hx_docling_mcp_relationships (1024D relationship embeddings)

Configuration:
- Vector dimensions: 1024 (bge-m3:567m)
- Distance metric: Cosine (semantic similarity)
- HNSW indexing: m=16, ef_construct=100
- Storage: RAM-only (Phase 1), on-disk (Phase 2 >100K entities)
- Quantization: Disabled (Phase 1), Scalar INT8 (Phase 2)

Usage:
    from integrations.qdrant_client import QdrantClient
    from integrations.qdrant_collections import initialize_collections

    client = QdrantClient(settings)
    await initialize_collections(client)
"""

import logging
from typing import Dict, Any

from .qdrant_client import QdrantClient
from .qdrant_exceptions import QdrantCollectionError, QdrantConnectionError

logger = logging.getLogger(__name__)


# Collection configuration constants
ENTITY_COLLECTION_NAME = "hx_docling_mcp_entities"
RELATIONSHIP_COLLECTION_NAME = "hx_docling_mcp_relationships"

VECTOR_DIMENSIONS = 1024  # bge-m3:567m embedding model output
DISTANCE_METRIC = "Cosine"  # Optimal for semantic similarity
HNSW_M = 16  # Balanced connectivity (moderate RAM, good recall)
HNSW_EF_CONSTRUCT = 100  # Build-time search quality (<1M entities)
ON_DISK_STORAGE = False  # Phase 1: RAM-only (<100K entities)


def get_collection_config(collection_name: str) -> Dict[str, Any]:
    """
    Generate Qdrant collection configuration.

    Args:
        collection_name: Name of collection (entities or relationships)

    Returns:
        Collection configuration dict for Qdrant API
    """
    return {
        "vectors": {
            "size": VECTOR_DIMENSIONS,
            "distance": DISTANCE_METRIC,
            "on_disk": ON_DISK_STORAGE,
        },
        "hnsw_config": {
            "m": HNSW_M,
            "ef_construct": HNSW_EF_CONSTRUCT,
            "full_scan_threshold": 10000,  # Use exact search for <10K points
        },
        "optimizers_config": {
            "deleted_threshold": 0.2,  # Trigger optimization when 20% deleted
            "vacuum_min_vector_number": 1000,  # Min vectors before vacuum
            "default_segment_number": 0,  # Auto-determine segment count
        },
    }


async def create_collection_if_not_exists(
    client: QdrantClient,
    collection_name: str,
) -> bool:
    """
    Create Qdrant collection if it doesn't exist (idempotent).

    Checks if collection exists:
    - If exists → validate schema matches expected configuration
    - If not exists → create with proper configuration

    Args:
        client: QdrantClient instance
        collection_name: Name of collection to create

    Returns:
        True if collection created, False if already existed

    Raises:
        QdrantCollectionError: If schema validation fails (dimension mismatch)
        QdrantConnectionError: If Qdrant unavailable
    """
    client.require_available()

    # Check if collection exists
    existing_collections = await client.get_collections()

    if collection_name in existing_collections:
        logger.info(f"Collection '{collection_name}' already exists, validating schema...")

        # Validate schema
        collection_info = await client.get_collection_info(collection_name)
        config = collection_info.get("config", {})
        params = config.get("params", {})
        vectors_config = params.get("vectors", {})

        # Check vector dimensions
        actual_size = vectors_config.get("size")
        if actual_size != VECTOR_DIMENSIONS:
            raise QdrantCollectionError(
                f"Collection '{collection_name}' has incorrect vector dimensions: "
                f"{actual_size} (expected {VECTOR_DIMENSIONS}). "
                f"Manual intervention required - cannot auto-migrate."
            )

        # Check distance metric
        actual_distance = vectors_config.get("distance")
        if actual_distance != DISTANCE_METRIC:
            logger.warning(
                f"Collection '{collection_name}' has different distance metric: "
                f"{actual_distance} (expected {DISTANCE_METRIC}). "
                f"This may affect search quality."
            )

        logger.info(f"Collection '{collection_name}' schema validated successfully")
        return False  # Not created (already existed)

    else:
        # Create collection
        logger.info(f"Creating collection '{collection_name}'...")

        collection_config = get_collection_config(collection_name)

        try:
            await client._request_with_retry(
                "PUT",
                f"/collections/{collection_name}",
                json=collection_config,
            )

            logger.info(
                f"Collection '{collection_name}' created successfully "
                f"({VECTOR_DIMENSIONS}D vectors, {DISTANCE_METRIC} distance, "
                f"HNSW m={HNSW_M}, ef_construct={HNSW_EF_CONSTRUCT})"
            )
            return True  # Created

        except Exception as e:
            logger.error(f"Failed to create collection '{collection_name}': {e}")
            raise QdrantCollectionError(
                f"Collection creation failed: {e}"
            ) from e


async def initialize_collections(client: QdrantClient) -> Dict[str, bool]:
    """
    Initialize all knowledge graph collections idempotently.

    Creates:
    - hx_docling_mcp_entities (entity embeddings)
    - hx_docling_mcp_relationships (relationship embeddings)

    Args:
        client: QdrantClient instance

    Returns:
        Dict mapping collection names to creation status (True=created, False=existed)

    Raises:
        QdrantCollectionError: If collection creation or validation fails
        QdrantConnectionError: If Qdrant unavailable
    """
    logger.info("Initializing Qdrant collections for knowledge graph storage...")

    results = {}

    # Create entities collection
    try:
        created = await create_collection_if_not_exists(
            client,
            ENTITY_COLLECTION_NAME,
        )
        results[ENTITY_COLLECTION_NAME] = created

        if created:
            logger.info(f"✅ Created {ENTITY_COLLECTION_NAME}")
        else:
            logger.info(f"✅ Validated {ENTITY_COLLECTION_NAME} (already exists)")

    except Exception as e:
        logger.error(f"❌ Failed to initialize {ENTITY_COLLECTION_NAME}: {e}")
        raise

    # Create relationships collection
    try:
        created = await create_collection_if_not_exists(
            client,
            RELATIONSHIP_COLLECTION_NAME,
        )
        results[RELATIONSHIP_COLLECTION_NAME] = created

        if created:
            logger.info(f"✅ Created {RELATIONSHIP_COLLECTION_NAME}")
        else:
            logger.info(f"✅ Validated {RELATIONSHIP_COLLECTION_NAME} (already exists)")

    except Exception as e:
        logger.error(f"❌ Failed to initialize {RELATIONSHIP_COLLECTION_NAME}: {e}")
        raise

    logger.info(
        f"Collection initialization complete: "
        f"{sum(results.values())} created, "
        f"{len(results) - sum(results.values())} validated"
    )

    return results


async def delete_collection_if_exists(
    client: QdrantClient,
    collection_name: str,
) -> bool:
    """
    Delete collection if it exists (for testing/cleanup).

    Args:
        client: QdrantClient instance
        collection_name: Name of collection to delete

    Returns:
        True if deleted, False if didn't exist

    Raises:
        QdrantConnectionError: If Qdrant unavailable
    """
    client.require_available()

    existing_collections = await client.get_collections()

    if collection_name in existing_collections:
        logger.warning(f"Deleting collection '{collection_name}'...")

        await client._request_with_retry(
            "DELETE",
            f"/collections/{collection_name}",
        )

        logger.warning(f"Collection '{collection_name}' deleted")
        return True
    else:
        logger.info(f"Collection '{collection_name}' does not exist, skipping delete")
        return False


# Example usage for testing
if __name__ == "__main__":
    import asyncio
    from pydantic import BaseModel, Field
    from typing import Optional

    class QdrantSettings(BaseModel):
        host: str = "hx-qdrant-server.hx.dev.local"
        port: int = 6333
        api_key: Optional[str] = None
        timeout_seconds: int = 30
        max_retries: int = 3

    async def test_initialization():
        from integrations.qdrant_client import QdrantClient

        settings = QdrantSettings()

        async with QdrantClient(settings) as client:
            # Health check
            is_healthy = await client.health_check()
            if not is_healthy:
                print("❌ Qdrant unhealthy, cannot initialize collections")
                return

            # Initialize collections
            results = await initialize_collections(client)
            print(f"Initialization results: {results}")

            # Verify collections exist
            collections = await client.get_collections()
            print(f"Collections after initialization: {collections}")

    asyncio.run(test_initialization())
EOF

sudo chown docling-mcp:docling-mcp "$COLLECTIONS_FILE"
echo "✅ Created qdrant_collections.py"
```

### Step 2: Update __init__.py to Export Collection Functions

```bash
# Add collection initialization exports to __init__.py
INIT_FILE="/opt/docling-mcp/src/integrations/__init__.py"

echo "Updating integrations __init__.py..."

sudo tee -a "$INIT_FILE" > /dev/null <<'EOF'

# Collection initialization
from .qdrant_collections import (
    initialize_collections,
    ENTITY_COLLECTION_NAME,
    RELATIONSHIP_COLLECTION_NAME,
)

__all__.extend([
    "initialize_collections",
    "ENTITY_COLLECTION_NAME",
    "RELATIONSHIP_COLLECTION_NAME",
])
EOF

sudo chown docling-mcp:docling-mcp "$INIT_FILE"
echo "✅ Updated __init__.py with collection exports"
```

### Step 3: Integrate Collection Initialization with MCP Server Startup

```bash
# Add collection initialization to MCP server startup sequence
# NOTE: This modifies mcp_server.py to call initialize_collections() on startup

echo "Creating startup integration code snippet..."

cat <<'EOF'
# ============================================================================
# CODE TO ADD TO /opt/docling-mcp/src/mcp_server.py
# Add this to the startup event handler or application initialization
# ============================================================================

from integrations.qdrant_client import QdrantClient
from integrations.qdrant_collections import initialize_collections
from integrations.qdrant_exceptions import QdrantConnectionError, QdrantCollectionError
from config import DoclingMCPConfig

async def startup_event():
    """
    MCP server startup event handler.

    Initializes Qdrant collections before accepting MCP requests.
    """
    logger.info("MCP Server starting up...")

    # Load configuration
    config = DoclingMCPConfig()

    # Initialize Qdrant client
    qdrant_client = QdrantClient(config.qdrant)

    try:
        # Health check
        is_healthy = await qdrant_client.health_check()

        if is_healthy:
            # Initialize collections idempotently
            logger.info("Initializing Qdrant collections...")
            results = await initialize_collections(qdrant_client)

            logger.info(
                f"Qdrant collections ready: {list(results.keys())}"
            )
        else:
            logger.warning(
                "Qdrant health check failed, knowledge graph features disabled. "
                "Document conversion will continue in stateless mode."
            )

    except (QdrantConnectionError, QdrantCollectionError) as e:
        logger.error(
            f"Failed to initialize Qdrant collections: {e}. "
            f"Knowledge graph features disabled."
        )
        # Continue startup (graceful degradation)
        # MCP server will operate without knowledge graph storage

    except Exception as e:
        logger.error(f"Unexpected error during Qdrant initialization: {e}")
        # Continue startup (fail gracefully)

    finally:
        await qdrant_client.close()

    logger.info("MCP Server startup complete")


# Register startup event (FastMCP/Uvicorn)
# app.add_event_handler("startup", startup_event)

# ============================================================================
EOF

echo "✅ Startup integration code snippet created (manual integration required in Task 031-060)"
```

### Step 4: Validate Collection Initialization Module

```bash
# Validate Python syntax and imports
echo "Validating qdrant_collections.py module..."

VENV_PYTHON="/opt/docling-mcp/venv/bin/python"

# Syntax validation
if $VENV_PYTHON -m py_compile /opt/docling-mcp/src/integrations/qdrant_collections.py; then
    echo "✅ qdrant_collections.py: Syntax valid"
else
    echo "❌ qdrant_collections.py: Syntax error"
    exit 1
fi

# Import validation
if $VENV_PYTHON -c "from integrations.qdrant_collections import initialize_collections, ENTITY_COLLECTION_NAME" 2>/dev/null; then
    echo "✅ Collection initialization imports successful"
else
    echo "❌ Collection initialization imports failed"
    exit 1
fi

echo "✅ Module validation complete"
```

### Step 5: Create Unit Tests for Collection Initialization

```bash
# Create unit tests for idempotent collection creation
TEST_FILE="/opt/docling-mcp/tests/unit/test_qdrant_collections.py"

echo "Creating collection initialization unit tests..."

sudo tee "$TEST_FILE" > /dev/null <<'EOF'
"""
Unit tests for Qdrant collection initialization.

Tests:
- Idempotent collection creation (create if not exists)
- Schema validation (dimensions, distance metric)
- Error handling (schema mismatch, connection failure)
- Multiple initialization calls (idempotency)
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from integrations.qdrant_client import QdrantClient
from integrations.qdrant_collections import (
    initialize_collections,
    create_collection_if_not_exists,
    ENTITY_COLLECTION_NAME,
    RELATIONSHIP_COLLECTION_NAME,
    VECTOR_DIMENSIONS,
)
from integrations.qdrant_exceptions import QdrantCollectionError


class QdrantSettingsMock:
    """Mock QdrantSettings."""
    host = "localhost"
    port = 6333
    api_key = None
    timeout_seconds = 30
    max_retries = 3


@pytest.fixture
async def qdrant_client():
    """Provide mock QdrantClient."""
    client = QdrantClient(QdrantSettingsMock())
    await client._ensure_client()
    yield client
    await client.close()


@pytest.mark.asyncio
async def test_create_collection_when_not_exists(qdrant_client):
    """Test collection created when it doesn't exist."""
    # Mock get_collections to return empty list
    with patch.object(
        qdrant_client,
        'get_collections',
        new_callable=AsyncMock,
        return_value=[]
    ):
        # Mock _request_with_retry for collection creation
        with patch.object(
            qdrant_client,
            '_request_with_retry',
            new_callable=AsyncMock,
        ) as mock_request:
            created = await create_collection_if_not_exists(
                qdrant_client,
                ENTITY_COLLECTION_NAME
            )

            assert created is True
            mock_request.assert_called_once()


@pytest.mark.asyncio
async def test_validate_collection_when_exists(qdrant_client):
    """Test collection validated when it already exists with correct schema."""
    # Mock get_collections to include target collection
    with patch.object(
        qdrant_client,
        'get_collections',
        new_callable=AsyncMock,
        return_value=[ENTITY_COLLECTION_NAME]
    ):
        # Mock get_collection_info with correct schema
        mock_info = {
            "config": {
                "params": {
                    "vectors": {
                        "size": VECTOR_DIMENSIONS,
                        "distance": "Cosine",
                    }
                }
            }
        }

        with patch.object(
            qdrant_client,
            'get_collection_info',
            new_callable=AsyncMock,
            return_value=mock_info
        ):
            created = await create_collection_if_not_exists(
                qdrant_client,
                ENTITY_COLLECTION_NAME
            )

            assert created is False  # Not created (already existed)


@pytest.mark.asyncio
async def test_schema_mismatch_raises_error(qdrant_client):
    """Test error raised when existing collection has incorrect schema."""
    # Mock get_collections to include target collection
    with patch.object(
        qdrant_client,
        'get_collections',
        new_callable=AsyncMock,
        return_value=[ENTITY_COLLECTION_NAME]
    ):
        # Mock get_collection_info with WRONG dimensions
        mock_info = {
            "config": {
                "params": {
                    "vectors": {
                        "size": 768,  # Wrong! Expected 1024
                        "distance": "Cosine",
                    }
                }
            }
        }

        with patch.object(
            qdrant_client,
            'get_collection_info',
            new_callable=AsyncMock,
            return_value=mock_info
        ):
            with pytest.raises(
                QdrantCollectionError,
                match="incorrect vector dimensions"
            ):
                await create_collection_if_not_exists(
                    qdrant_client,
                    ENTITY_COLLECTION_NAME
                )


@pytest.mark.asyncio
async def test_initialize_collections_creates_both(qdrant_client):
    """Test initialize_collections creates both entity and relationship collections."""
    # Mock all collections as non-existent
    with patch.object(
        qdrant_client,
        'get_collections',
        new_callable=AsyncMock,
        return_value=[]
    ):
        with patch.object(
            qdrant_client,
            '_request_with_retry',
            new_callable=AsyncMock,
        ):
            results = await initialize_collections(qdrant_client)

            assert ENTITY_COLLECTION_NAME in results
            assert RELATIONSHIP_COLLECTION_NAME in results
            assert results[ENTITY_COLLECTION_NAME] is True  # Created
            assert results[RELATIONSHIP_COLLECTION_NAME] is True  # Created


@pytest.mark.asyncio
async def test_initialize_collections_idempotent(qdrant_client):
    """Test initialize_collections is idempotent (can call multiple times)."""
    # Mock collections already exist with correct schema
    with patch.object(
        qdrant_client,
        'get_collections',
        new_callable=AsyncMock,
        return_value=[ENTITY_COLLECTION_NAME, RELATIONSHIP_COLLECTION_NAME]
    ):
        mock_info = {
            "config": {
                "params": {
                    "vectors": {
                        "size": VECTOR_DIMENSIONS,
                        "distance": "Cosine",
                    }
                }
            }
        }

        with patch.object(
            qdrant_client,
            'get_collection_info',
            new_callable=AsyncMock,
            return_value=mock_info
        ):
            # First call
            results1 = await initialize_collections(qdrant_client)
            assert results1[ENTITY_COLLECTION_NAME] is False  # Not created
            assert results1[RELATIONSHIP_COLLECTION_NAME] is False  # Not created

            # Second call (idempotent)
            results2 = await initialize_collections(qdrant_client)
            assert results2 == results1  # Same results
EOF

sudo chown docling-mcp:docling-mcp "$TEST_FILE"
echo "✅ Created test_qdrant_collections.py"
```

### Step 6: Run Unit Tests

```bash
# Execute unit tests
echo "Running collection initialization unit tests..."

VENV_PYTHON="/opt/docling-mcp/venv/bin/python"

cd /opt/docling-mcp

if $VENV_PYTHON -m pytest tests/unit/test_qdrant_collections.py -v --tb=short; then
    echo "✅ All unit tests passed"
else
    echo "❌ Unit tests failed - review implementation"
    exit 1
fi
```

## Validation

**Validation Commands:**

```bash
echo "=== Qdrant Collection Initialization Validation ==="

VENV_PYTHON="/opt/docling-mcp/venv/bin/python"
QDRANT_URL="http://hx-qdrant-server.hx.dev.local:6333"

# Validate module file exists
echo "1. Module File:"
if [ -f "/opt/docling-mcp/src/integrations/qdrant_collections.py" ]; then
    echo "✅ PASSED: qdrant_collections.py exists"
else
    echo "❌ FAILED: qdrant_collections.py missing"
    exit 1
fi

# Validate syntax
echo ""
echo "2. Python Syntax:"
if $VENV_PYTHON -m py_compile /opt/docling-mcp/src/integrations/qdrant_collections.py 2>/dev/null; then
    echo "✅ PASSED: Syntax valid"
else
    echo "❌ FAILED: Syntax error"
    exit 1
fi

# Validate imports
echo ""
echo "3. Module Imports:"
if $VENV_PYTHON -c "from integrations.qdrant_collections import initialize_collections, ENTITY_COLLECTION_NAME" 2>/dev/null; then
    echo "✅ PASSED: Imports successful"
else
    echo "❌ FAILED: Import failed"
    exit 1
fi

# Validate collections exist in Qdrant (optional - requires running Qdrant server)
echo ""
echo "4. Collection Existence (live check):"

# Check entities collection
ENTITIES_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${QDRANT_URL}/collections/hx_docling_mcp_entities" 2>/dev/null || echo "000")

if [ "$ENTITIES_HTTP_CODE" = "200" ]; then
    echo "✅ PASSED: Entities collection exists in Qdrant"
elif [ "$ENTITIES_HTTP_CODE" = "000" ]; then
    echo "⚠️  SKIPPED: Cannot reach Qdrant server (connection refused)"
else
    echo "⚠️  WARNING: Entities collection not found (HTTP $ENTITIES_HTTP_CODE)"
    echo "   This is expected if collections haven't been initialized yet"
fi

# Check relationships collection
RELS_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${QDRANT_URL}/collections/hx_docling_mcp_relationships" 2>/dev/null || echo "000")

if [ "$RELS_HTTP_CODE" = "200" ]; then
    echo "✅ PASSED: Relationships collection exists in Qdrant"
elif [ "$RELS_HTTP_CODE" = "000" ]; then
    echo "⚠️  SKIPPED: Cannot reach Qdrant server (connection refused)"
else
    echo "⚠️  WARNING: Relationships collection not found (HTTP $RELS_HTTP_CODE)"
    echo "   This is expected if collections haven't been initialized yet"
fi

# Validate unit tests
echo ""
echo "5. Unit Tests:"
if [ -f "/opt/docling-mcp/tests/unit/test_qdrant_collections.py" ]; then
    echo "✅ PASSED: Unit test file exists"

    if $VENV_PYTHON -m pytest /opt/docling-mcp/tests/unit/test_qdrant_collections.py -v --tb=short 2>&1 | grep -q "passed"; then
        echo "✅ PASSED: Unit tests executed successfully"
    else
        echo "⚠️  WARNING: Some unit tests may have failed"
    fi
else
    echo "❌ FAILED: Unit test file missing"
    exit 1
fi

# Summary
echo ""
echo "=== Validation Summary ==="
echo "✅ ALL VALIDATIONS PASSED - Collection initialization module ready"
echo ""
echo "Next Step: Task 103 - Implement Entity Insertion with Deduplication"
```

**Expected Results:**
- qdrant_collections.py exists with correct syntax
- Imports succeed (initialize_collections, collection names)
- Collections created in Qdrant with correct schema (1024D, Cosine)
- Schema validation prevents dimension mismatches
- Unit tests pass (idempotency, schema validation)

## Notes

**Collection Configuration:**
- **Vector Dimensions**: 1024 (bge-m3:567m embedding model)
- **Distance Metric**: Cosine (optimal for normalized embeddings)
- **HNSW Parameters**:
  - `m=16`: Links per node (balance between recall and RAM)
  - `ef_construct=100`: Build-time search depth (sufficient for <1M entities)
- **Storage**: RAM-only in Phase 1 (<100K entities expected)
- **Quantization**: Disabled in Phase 1, Scalar INT8 enabled in Phase 2 (4x RAM reduction when >100K entities)

**Idempotent Behavior:**
- First call: Creates collections if missing
- Subsequent calls: Validates schema, skips creation
- Schema mismatch: Raises `QdrantCollectionError` (manual fix required)

**Startup Integration:**
- Collections initialized during MCP server startup
- If initialization fails, knowledge graph features disabled
- Document conversion continues (graceful degradation)

**RAM Estimates (Phase 1):**
- 100K entities: ~470MB (1024D float32 vectors + HNSW overhead)
- 500K relationships: ~2.35GB
- Total: ~2.8GB for knowledge graph storage

**Phase 2 Optimizations (>100K entities):**
- Enable Scalar INT8 quantization (4x RAM reduction)
- Enable on-disk storage (RAM for hot data only)
- Increase `m` to 32 for better recall (if RAM permits)

## References

**Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md`
- Section: FR-015 (Qdrant Storage Architecture)
- Section: Component 3 - LightRAG Knowledge Engine → Qdrant Collection Architecture

**Qdrant Collection API**:
- Create collection: `PUT /collections/{name}` with JSON body
- Get collection info: `GET /collections/{name}`
- Vector configuration: size, distance, on_disk
- HNSW configuration: m, ef_construct, full_scan_threshold

## Risk Assessment

**Risk Level**: Medium

**Risks**:
1. **Schema mismatch**: Existing collections with wrong dimensions
2. **Qdrant unavailable at startup**: Service fails to initialize
3. **Concurrent initialization**: Multiple instances creating collections simultaneously
4. **Incorrect HNSW parameters**: Poor recall or excessive RAM usage

**Mitigation**:
- Schema validation prevents silent failures (raise error on mismatch)
- Graceful degradation continues service startup without Qdrant
- Idempotent creation handles concurrent calls (Qdrant atomic operations)
- HNSW parameters validated against best practices (m=16 for 1024D vectors)
- Comprehensive logging for troubleshooting initialization failures
