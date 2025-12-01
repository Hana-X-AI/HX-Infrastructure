# Task 025: Configure Client-Side Entity Deduplication Strategy

**Task ID**: hx-docling-mcp-task-025
**Task Type**: Configuration
**Component**: Knowledge Graph Post-Processing - Client-Side Deduplication
**Priority**: MEDIUM
**Estimated Duration**: 2 hours
**Dependencies**: Task 022 (Entity Extraction via HTTP), Task 023 (Relationship Extraction via HTTP)
**Assigned To**: andy-taylor (LightRAG SME)

---

## Architecture Context

**CRITICAL**: This task implements **client-side** deduplication of entities AFTER retrieval from hx-literag-server HTTP API.

**Server-Side Processing** (hx-literag-server):
- Entity extraction via LightRAG
- Initial deduplication during knowledge graph construction
- Primary entity resolution

**Client-Side Processing** (THIS TASK):
- Additional deduplication for entities from multiple API calls
- Cross-document entity consolidation
- Merging entities across chunked document processing

---

## Objective

Implement client-side entity deduplication using string similarity (Jaro-Winkler) to merge duplicate entities returned from multiple hx-literag-server API calls, particularly when processing chunked documents.

---

## Dependencies

### Python Packages

This task requires the `jellyfish` library for string similarity computation (Jaro-Winkler distance).

**Installation**:
```bash
pip install jellyfish>=1.0.0
```

**Add to requirements.txt**:
```
jellyfish>=1.0.0
```

**Verification**:
```bash
python -c "import jellyfish; print(jellyfish.__version__)"
```

---

## Prerequisites

**Before starting this task, verify**:

```bash
# 1. Task 022 complete (EntityProcessor exists)
ls -la /opt/docling-mcp/application/docling_mcp/processors/entity_processor.py

# 2. Task 023 complete (RelationshipProcessor exists)
ls -la /opt/docling-mcp/application/docling_mcp/processors/relationship_processor.py

# 3. jellyfish installed
source /opt/docling-mcp/venv/bin/activate
python -c "import jellyfish; print('OK')"
```

**All prerequisites must pass before proceeding.**

---

## Acceptance Criteria

- [ ] Client-side deduplication module created at `/opt/docling-mcp/application/docling_mcp/processors/entity_deduplicator.py`
- [ ] String similarity-based deduplication functional (Jaro-Winkler ≥0.87 threshold)
- [ ] Canonical entity selection with tie-breaking rules (highest confidence, most metadata)
- [ ] Relationship ID update logic implemented
- [ ] Unit tests passing (minimum 5 test cases)
- [ ] Integration with EntityProcessor working
- [ ] Documentation complete

---

## Implementation Steps

### Step 1: Create Client-Side Entity Deduplicator Module

**File**: `/opt/docling-mcp/application/docling_mcp/processors/entity_deduplicator.py`

```python
"""
Client-Side Entity Deduplication for Knowledge Graph Post-Processing.

This module handles deduplication of entities AFTER retrieval from
hx-literag-server HTTP API. Primary use case: merging duplicate entities
across multiple API calls when processing chunked documents.

Algorithm:
1. Group entities by type (Person with Person, Organization with Organization)
2. Compute string similarity (Jaro-Winkler)
3. Merge entities with similarity ≥0.87
4. Select canonical entity (highest confidence, most metadata)
5. Update relationship references
"""

import structlog
import jellyfish
from typing import List, Dict, Tuple
from collections import defaultdict
from docling_mcp.clients.literag_client import Entity, Relationship

logger = structlog.get_logger(__name__)


class EntityDeduplicator:
    """
    Client-side entity deduplication using string similarity.

    Deduplication Threshold:
    - String similarity: ≥0.87 (Jaro-Winkler)
    - Tie-breaking: Highest confidence, most metadata, first occurrence
    """

    def __init__(self, similarity_threshold: float = 0.87):
        """
        Initialize entity deduplicator.

        Args:
            similarity_threshold: Jaro-Winkler similarity threshold (default: 0.87)
        """
        self.similarity_threshold = similarity_threshold
        logger.info("Entity deduplicator initialized", threshold=similarity_threshold)

    def compute_string_similarity(self, text1: str, text2: str) -> float:
        """
        Compute Jaro-Winkler string similarity.

        Preprocessing:
        - Lowercase
        - Remove common suffixes (Inc., Corp., Ltd.)
        - Collapse multiple spaces to single space

        Args:
            text1: First entity text
            text2: Second entity text

        Returns:
            Similarity score 0.0-1.0
        """
        # Preprocessing
        normalized1 = self._normalize_entity_text(text1)
        normalized2 = self._normalize_entity_text(text2)

        # Jaro-Winkler similarity
        similarity = jellyfish.jaro_winkler_similarity(normalized1, normalized2)

        return similarity

    def _normalize_entity_text(self, text: str) -> str:
        """
        Normalize entity text for string matching.

        Args:
            text: Raw entity text

        Returns:
            Normalized text
        """
        # Lowercase
        text = text.lower()

        # Remove common organizational suffixes
        suffixes = ["inc.", "corp.", "ltd.", "llc", "co.", "corporation", "incorporated"]
        for suffix in suffixes:
            if text.endswith(suffix):
                text = text[:-len(suffix)].strip()

        # Collapse multiple spaces
        text = " ".join(text.split())

        return text

    def deduplicate_entities(
        self,
        entities: List[Entity]
    ) -> Tuple[List[Entity], Dict[str, str]]:
        """
        Deduplicate entities using string similarity.

        Algorithm:
        1. Group entities by type
        2. Within each type, compute pairwise string similarity
        3. Merge entities with similarity ≥ threshold
        4. Select canonical entity (tie-breaking rules)

        Args:
            entities: List of entities from hx-literag-server

        Returns:
            Tuple of (deduplicated_entities, entity_text_mapping)
            where entity_text_mapping maps old text → canonical text
        """
        # Group entities by type
        entities_by_type = defaultdict(list)
        for entity in entities:
            entities_by_type[entity.type].append(entity)

        canonical_entities = []
        entity_text_mapping = {}  # old_text → canonical_text

        # Process each type group
        for entity_type, type_entities in entities_by_type.items():
            logger.info(f"Deduplicating {len(type_entities)} entities of type {entity_type}")

            # Deduplicate within type
            deduplicated, mapping = self._deduplicate_entity_group(type_entities)

            canonical_entities.extend(deduplicated)
            entity_text_mapping.update(mapping)

        dedup_rate = (1 - len(canonical_entities) / len(entities)) * 100 if entities else 0

        logger.info(
            "Deduplication complete",
            original_count=len(entities),
            deduplicated_count=len(canonical_entities),
            deduplication_rate=f"{dedup_rate:.1f}%"
        )

        return canonical_entities, entity_text_mapping

    def _deduplicate_entity_group(
        self,
        entities: List[Entity]
    ) -> Tuple[List[Entity], Dict[str, str]]:
        """
        Deduplicate entities within same type.

        Args:
            entities: List of entities with same type

        Returns:
            Tuple of (canonical_entities, text_mapping)
        """
        if len(entities) <= 1:
            return entities, {}

        # Find merge candidates (pairwise similarity computation)
        merge_pairs = []
        for i in range(len(entities)):
            for j in range(i + 1, len(entities)):
                similarity = self.compute_string_similarity(
                    entities[i].text,
                    entities[j].text
                )

                if similarity >= self.similarity_threshold:
                    merge_pairs.append((i, j, similarity))
                    logger.debug(
                        f"Merge candidate: '{entities[i].text}' + '{entities[j].text}' "
                        f"(similarity: {similarity:.3f})"
                    )

        if not merge_pairs:
            # No duplicates found
            return entities, {}

        # Build merge graph and find connected components
        canonical_entities, mapping = self._resolve_entities(entities, merge_pairs)

        return canonical_entities, mapping

    def _resolve_entities(
        self,
        entities: List[Entity],
        merge_pairs: List[Tuple[int, int, float]]
    ) -> Tuple[List[Entity], Dict[str, str]]:
        """
        Resolve entity merges and select canonical entities.

        Tie-breaking rules:
        1. Highest confidence
        2. Most metadata fields
        3. First occurrence

        Args:
            entities: List of entities
            merge_pairs: List of (index1, index2, similarity) tuples

        Returns:
            Tuple of (canonical_entities, text_mapping)
        """
        # Build merge graph
        merge_graph = defaultdict(set)
        for i, j, _ in merge_pairs:
            merge_graph[i].add(j)
            merge_graph[j].add(i)

        # Find connected components (entities to merge)
        visited = set()
        canonical_entities = []
        entity_text_mapping = {}

        for i in range(len(entities)):
            if i in visited:
                continue

            # Find connected component
            component = self._find_connected_component(i, merge_graph)
            visited.update(component)

            # Select canonical entity (tie-breaking rules)
            canonical_idx = max(
                component,
                key=lambda idx: (
                    entities[idx].confidence,
                    len(entities[idx].metadata) if entities[idx].metadata else 0,
                    -idx  # Negative to prefer earlier index
                )
            )

            canonical_entity = entities[canonical_idx]

            # Merge metadata from all entities in component
            if len(component) > 1:
                merged_metadata = {}
                for idx in component:
                    if entities[idx].metadata:
                        merged_metadata.update(entities[idx].metadata)

                canonical_entity.metadata = merged_metadata

                logger.debug(
                    f"Merged {len(component)} entities into canonical: '{canonical_entity.text}' "
                    f"(confidence: {canonical_entity.confidence:.2f}, metadata fields: {len(merged_metadata)})"
                )

            canonical_entities.append(canonical_entity)

            # Build mapping (all non-canonical → canonical)
            for idx in component:
                if idx != canonical_idx:
                    entity_text_mapping[entities[idx].text] = canonical_entity.text

        return canonical_entities, entity_text_mapping

    def _find_connected_component(
        self,
        start: int,
        graph: Dict[int, set]
    ) -> set:
        """
        Find connected component in merge graph using BFS.

        Args:
            start: Starting node index
            graph: Adjacency list representation

        Returns:
            Set of node indices in connected component
        """
        visited = {start}
        queue = [start]

        while queue:
            node = queue.pop(0)
            for neighbor in graph[node]:
                if neighbor not in visited:
                    visited.add(neighbor)
                    queue.append(neighbor)

        return visited

    def update_relationships(
        self,
        relationships: List[Relationship],
        entity_text_mapping: Dict[str, str]
    ) -> List[Relationship]:
        """
        Update relationship entity references after deduplication.

        Args:
            relationships: List of relationships from hx-literag-server
            entity_text_mapping: old_text → canonical_text mapping

        Returns:
            Updated relationships with canonical entity references
        """
        updated_relationships = []

        for rel in relationships:
            # Update source/target entity references
            source = entity_text_mapping.get(rel.source, rel.source)
            target = entity_text_mapping.get(rel.target, rel.target)

            # Create updated relationship
            updated_rel = Relationship(
                source=source,
                target=target,
                type=rel.type,
                confidence=rel.confidence,
                metadata=rel.metadata
            )
            updated_relationships.append(updated_rel)

        # Deduplicate relationships (same source/type/target)
        deduplicated_rels = self._deduplicate_relationships(updated_relationships)

        dedup_rate = (1 - len(deduplicated_rels) / len(relationships)) * 100 if relationships else 0

        logger.info(
            "Relationship update complete",
            original_count=len(relationships),
            deduplicated_count=len(deduplicated_rels),
            deduplication_rate=f"{dedup_rate:.1f}%"
        )

        return deduplicated_rels

    def _deduplicate_relationships(
        self,
        relationships: List[Relationship]
    ) -> List[Relationship]:
        """
        Deduplicate relationships with same source/type/target.

        Args:
            relationships: List of relationships

        Returns:
            Deduplicated relationship list
        """
        unique_rels = {}

        for rel in relationships:
            key = (rel.source, rel.type, rel.target)

            if key not in unique_rels:
                unique_rels[key] = rel
            else:
                # Keep highest confidence
                existing = unique_rels[key]
                if rel.confidence > existing.confidence:
                    unique_rels[key] = rel

        return list(unique_rels.values())
```

### Step 2: Update EntityProcessor to Use Deduplicator

**File**: `/opt/docling-mcp/application/docling_mcp/processors/entity_processor.py` (modify existing)

Add the following import and update the `_deduplicate_entities` method:

```python
# Add import at top of file
from docling_mcp.processors.entity_deduplicator import EntityDeduplicator

# Update EntityProcessor.__init__
class EntityProcessor:
    def __init__(self, literag_client: LiteRAGClient, chunk_size: int = 4096, chunk_overlap: int = 512):
        self.client = literag_client
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.deduplicator = EntityDeduplicator(similarity_threshold=0.87)  # Add this
        logger.info("Entity processor initialized", chunk_size=chunk_size, chunk_overlap=chunk_overlap)

# Replace _deduplicate_entities method
    def _deduplicate_entities(self, entities: List[Entity]) -> List[Entity]:
        """
        Remove duplicate entities using client-side deduplicator.

        Args:
            entities: List of entities with potential duplicates

        Returns:
            Deduplicated entity list
        """
        deduplicated, _ = self.deduplicator.deduplicate_entities(entities)
        return deduplicated
```

### Step 3: Create Unit Tests

**File**: `/opt/docling-mcp/application/tests/test_entity_deduplicator.py`

```python
"""Unit tests for Entity Deduplicator."""

import pytest
from docling_mcp.processors.entity_deduplicator import EntityDeduplicator
from docling_mcp.clients.literag_client import Entity


@pytest.fixture
def deduplicator():
    """Entity deduplicator with default threshold."""
    return EntityDeduplicator(similarity_threshold=0.87)


def test_string_similarity_high(deduplicator):
    """Test string similarity for similar entities."""
    sim = deduplicator.compute_string_similarity("IBM Research", "IBM Research Lab")
    assert sim >= 0.85, f"String similarity {sim} should be ≥0.85"


def test_string_similarity_low(deduplicator):
    """Test string similarity for dissimilar entities."""
    sim = deduplicator.compute_string_similarity("IBM", "Microsoft")
    assert sim < 0.85, f"String similarity {sim} should be <0.85"


def test_normalize_entity_text(deduplicator):
    """Test entity text normalization."""
    normalized = deduplicator._normalize_entity_text("IBM Corporation Inc.")
    assert normalized == "ibm corporation", f"Should normalize to 'ibm corporation', got '{normalized}'"


def test_deduplicate_entities_merge(deduplicator):
    """Test entity deduplication merges similar entities."""
    entities = [
        Entity(text="IBM Research", type="ORGANIZATION", confidence=0.95, metadata={"industry": "technology"}),
        Entity(text="IBM Research Lab", type="ORGANIZATION", confidence=0.88, metadata={"location": "USA"})
    ]

    deduplicated, mapping = deduplicator.deduplicate_entities(entities)

    # Should merge into 1 canonical entity
    assert len(deduplicated) == 1, "Should merge similar entities"
    assert "IBM Research Lab" in mapping, "Should create entity text mapping"
    assert mapping["IBM Research Lab"] == "IBM Research", "Should map to higher confidence entity"

    # Should merge metadata
    canonical = deduplicated[0]
    assert "industry" in canonical.metadata, "Should preserve metadata from canonical entity"
    assert "location" in canonical.metadata, "Should merge metadata from duplicate entity"


def test_deduplicate_entities_no_merge(deduplicator):
    """Test entity deduplication does not merge dissimilar entities."""
    entities = [
        Entity(text="IBM Research", type="ORGANIZATION", confidence=0.95, metadata={}),
        Entity(text="Microsoft Research", type="ORGANIZATION", confidence=0.94, metadata={})
    ]

    deduplicated, mapping = deduplicator.deduplicate_entities(entities)

    # Should NOT merge (low similarity)
    assert len(deduplicated) == 2, "Should not merge dissimilar entities"
    assert len(mapping) == 0, "Should have no entity text mapping"


def test_deduplicate_entities_type_separation(deduplicator):
    """Test entities of different types are not merged."""
    entities = [
        Entity(text="Python", type="TECHNOLOGY", confidence=0.95, metadata={}),
        Entity(text="Python", type="LANGUAGE", confidence=0.94, metadata={})
    ]

    deduplicated, mapping = deduplicator.deduplicate_entities(entities)

    # Should NOT merge (different types)
    assert len(deduplicated) == 2, "Should not merge entities of different types"
    assert len(mapping) == 0, "Should have no entity text mapping"


def test_update_relationships(deduplicator):
    """Test relationship entity reference updates."""
    from docling_mcp.clients.literag_client import Relationship

    relationships = [
        Relationship(source="IBM Research Lab", target="Python", type="USES", confidence=0.90, metadata={}),
        Relationship(source="IBM Research", target="Python", type="USES", confidence=0.85, metadata={})
    ]

    entity_text_mapping = {"IBM Research Lab": "IBM Research"}

    updated = deduplicator.update_relationships(relationships, entity_text_mapping)

    # Should deduplicate to 1 relationship (same source after mapping)
    assert len(updated) == 1, "Should deduplicate relationships with same source/type/target"
    assert updated[0].source == "IBM Research", "Should use canonical entity reference"
    assert updated[0].confidence == 0.90, "Should keep highest confidence"
```

### Step 4: Execute Tests

```bash
# Activate venv
source /opt/docling-mcp/venv/bin/activate

# Install jellyfish if not already installed
pip install jellyfish>=1.0.0

# Run unit tests
cd /opt/docling-mcp/application
pytest tests/test_entity_deduplicator.py -v
```

**Expected Result**: All 7 tests PASS

---

## Validation

### Validation Commands

```bash
# 1. Verify deduplicator file exists
ls -la /opt/docling-mcp/application/docling_mcp/processors/entity_deduplicator.py

# 2. Verify imports work
source /opt/docling-mcp/venv/bin/activate
python -c "from docling_mcp.processors.entity_deduplicator import EntityDeduplicator; print('OK')"

# 3. Test deduplication
python -c "
from docling_mcp.processors.entity_deduplicator import EntityDeduplicator
from docling_mcp.clients.literag_client import Entity

dedup = EntityDeduplicator()
entities = [
    Entity(text='IBM', type='ORGANIZATION', confidence=0.95, metadata={}),
    Entity(text='IBM Corp', type='ORGANIZATION', confidence=0.90, metadata={})
]
deduplicated, mapping = dedup.deduplicate_entities(entities)
print(f'Deduplication: {len(entities)} → {len(deduplicated)} entities')
print(f'Mapping: {mapping}')
"

# 4. Run test suite
pytest tests/test_entity_deduplicator.py -v
```

### Success Criteria

- ✅ Deduplicator file created with correct structure
- ✅ String similarity computation functional (Jaro-Winkler)
- ✅ Entity deduplication working (similarity threshold 0.87)
- ✅ Canonical entity selection with tie-breaking rules
- ✅ Relationship ID update logic functional
- ✅ All unit tests passing (7 tests)
- ✅ Integration with EntityProcessor working

---

## Documentation

**File**: `/opt/docling-mcp/documentation/client-side-entity-deduplication.md`

```markdown
# Client-Side Entity Deduplication

## Architecture

**Service**: hx-docling-mcp-server (local processing)
**Component**: EntityDeduplicator
**Processing**: Client-side (AFTER hx-literag-server API calls)

## Purpose

Deduplicates entities returned from multiple hx-literag-server API calls,
particularly when processing chunked documents where the same entity may
appear in multiple chunks.

## Configuration

- **Similarity Threshold**: 0.87 (Jaro-Winkler)
- **Tie-Breaking**: Highest confidence → Most metadata → First occurrence
- **Type Separation**: Entities of different types are never merged

## Usage

```python
from docling_mcp.processors.entity_deduplicator import EntityDeduplicator
from docling_mcp.clients.literag_client import Entity

# Initialize
deduplicator = EntityDeduplicator(similarity_threshold=0.87)

# Deduplicate entities
deduplicated, mapping = deduplicator.deduplicate_entities(entities)

# Update relationships
updated_relationships = deduplicator.update_relationships(relationships, mapping)
```

## Algorithm

1. **Type Grouping**: Group entities by type (Person, Organization, etc.)
2. **Pairwise Similarity**: Compute Jaro-Winkler similarity for all pairs within type
3. **Threshold Filtering**: Identify merge candidates (similarity ≥ 0.87)
4. **Connected Components**: Find entity groups to merge
5. **Canonical Selection**: Select canonical entity (tie-breaking rules)
6. **Metadata Merging**: Merge metadata from all entities in group
7. **Relationship Update**: Update entity references in relationships
```

---

## Rollback Procedure

```bash
# Remove deduplicator file
rm -f /opt/docling-mcp/application/docling_mcp/processors/entity_deduplicator.py

# Remove test file
rm -f /opt/docling-mcp/application/tests/test_entity_deduplicator.py

# Remove documentation
rm -f /opt/docling-mcp/documentation/client-side-entity-deduplication.md

# Restore EntityProcessor to original version (without deduplicator integration)
# (Requires manual edit or git restore if version-controlled)
```

---

## Dependencies

**Blocks**:
- Task 026: Configure LiteLLM Integration (may use deduplication results)

**Depends On**:
- Task 022: Configure Entity Extraction via HTTP (provides entities to deduplicate)
- Task 023: Configure Relationship Extraction via HTTP (provides relationships to update)

---

## Notes

### Architecture Clarification

**Server-Side Deduplication** (hx-literag-server):
- Primary entity resolution during knowledge graph construction
- Occurs BEFORE entities are returned via HTTP API
- Uses LightRAG's internal deduplication logic

**Client-Side Deduplication** (THIS TASK):
- Secondary deduplication for cross-chunk entity consolidation
- Occurs AFTER entities are retrieved from HTTP API
- Useful when same entity appears in multiple document chunks
- Lightweight string similarity (no vector embeddings)

### Performance Considerations

- **String-only similarity**: No vector embeddings (faster than hybrid approach)
- **O(n²) complexity**: Pairwise comparison within type groups
- **Type grouping**: Reduces search space (Person only compared with Person)
- **Suitable for**: <10,000 entities per document (typical case)

### Benefits

1. **Cross-chunk consolidation**: Merges entities from overlapping chunks
2. **Metadata enrichment**: Combines metadata from duplicate entities
3. **Relationship simplification**: Reduces redundant relationships
4. **Local control**: Client-side deduplication allows customization

---

**Task Completed By**: _________________
**Date Completed**: _________________
**Verified By**: _________________
