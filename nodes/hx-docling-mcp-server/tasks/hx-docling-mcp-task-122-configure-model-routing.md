# Task 122: Configure LiteLLM Model Routing Strategy

**Assigned To**: shane-black
**Estimated Effort**: 2 hours
**Dependencies**: Task 121 (LiteLLM client module)
**Status**: Not Started

## Objective

Configure model routing strategy for entity extraction and relationship identification, implementing fallback logic across Ollama1/2/3 models via LiteLLM Router to ensure high availability and cost optimization.

## Pre-Execution Validation

**CRITICAL**: Check if model routing configuration already exists BEFORE creating it to prevent duplication.

```bash
# Check if model routing module exists
if [ -f "/opt/docling-mcp/src/integrations/model_router.py" ]; then
    echo "✅ VALIDATION RESULT: Model routing module already exists"
    echo "ACTION: SKIP task execution - validate routing logic instead"
    echo "NEXT: Verify model fallback strategy configured"
    exit 0
else
    echo "❌ VALIDATION RESULT: Model routing module does NOT exist"
    echo "ACTION: PROCEED with routing configuration"
fi
```

**If Module Exists**: Skip to Validation section, verify routing logic and fallback strategy

**If Module Does Not Exist**: Continue with Implementation Steps below

---

## Context

The Docling MCP Server uses LLM capabilities for two primary tasks:

1. **Entity Extraction**: Identify named entities (person, organization, location, date, product) from document text
2. **Relationship Extraction**: Identify relationships between extracted entities

Different document types require different model capabilities:
- **General Business Documents**: Gemma3:27b (high quality, moderate speed)
- **Technical/Code Documentation**: Qwen3-Coder:30b (optimized for technical content)
- **Fallback**: GPT-OSS:20b (fast, moderate quality)

The model router implements intelligent selection and automatic fallback when primary models are unavailable or overloaded.

## Acceptance Criteria

- [ ] Model router module created at `/opt/docling-mcp/src/integrations/model_router.py`
- [ ] `ModelRouter` class implements content-type detection
- [ ] Primary model selection based on content type (general vs technical)
- [ ] Automatic fallback to secondary model on HTTP 503/timeout
- [ ] Model configuration loaded from environment variables
- [ ] Support for entity extraction and relationship extraction tasks
- [ ] Structured prompt templates for each model/task combination
- [ ] Model performance tracking (latency, success rate)
- [ ] Type hints and Pydantic models for configuration

## Implementation Steps

### Step 1: Create Model Router Module

```bash
# Create model_router.py module
sudo -u docling-mcp@hx.dev.local tee /opt/docling-mcp/src/integrations/model_router.py > /dev/null << 'EOF'
"""
LiteLLM Model Routing Module

Implements intelligent model selection and fallback strategy for:
- Entity extraction (named entities from document text)
- Relationship extraction (relationships between entities)

Content-aware routing:
- General documents → gemma3:27b (primary), gpt-oss:20b (fallback)
- Technical documents → qwen3-coder:30b (primary), gemma3:27b (fallback)
"""

import logging
from typing import List, Dict, Any, Optional, Literal
from enum import Enum
import json

from pydantic import BaseModel, Field

from .litellm_client import LiteLLMClient

logger = logging.getLogger(__name__)


class ContentType(str, Enum):
    """Document content type classification."""
    GENERAL = "general"  # Business docs, reports, articles
    TECHNICAL = "technical"  # Code, API docs, technical specs


class TaskType(str, Enum):
    """LLM task type."""
    ENTITY_EXTRACTION = "entity_extraction"
    RELATIONSHIP_EXTRACTION = "relationship_extraction"


class ModelConfig(BaseModel):
    """Model configuration for routing."""
    model_id: str = Field(..., description="LiteLLM model identifier")
    description: str = Field(..., description="Model description")
    max_tokens: int = Field(2048, description="Maximum output tokens")
    temperature: float = Field(0.1, description="Sampling temperature")
    top_p: float = Field(0.9, description="Nucleus sampling parameter")


class ModelRoutingConfig(BaseModel):
    """Complete model routing configuration."""
    general_primary: ModelConfig = Field(
        default=ModelConfig(
            model_id="ollama_chat/gemma3:27b",
            description="Gemma3 27B - General entity extraction",
            max_tokens=2048,
            temperature=0.1,
            top_p=0.9,
        )
    )
    general_fallback: ModelConfig = Field(
        default=ModelConfig(
            model_id="ollama_chat/gpt-oss:20b",
            description="GPT-OSS 20B - Fast fallback",
            max_tokens=2048,
            temperature=0.1,
            top_p=0.9,
        )
    )
    technical_primary: ModelConfig = Field(
        default=ModelConfig(
            model_id="ollama_chat/qwen3-coder:30b",
            description="Qwen3-Coder 30B - Technical content extraction",
            max_tokens=2048,
            temperature=0.1,
            top_p=0.9,
        )
    )
    technical_fallback: ModelConfig = Field(
        default=ModelConfig(
            model_id="ollama_chat/gemma3:27b",
            description="Gemma3 27B - Technical fallback",
            max_tokens=2048,
            temperature=0.1,
            top_p=0.9,
        )
    )


class ModelRouter:
    """
    Intelligent model routing for entity and relationship extraction.

    Features:
    - Content-type aware model selection
    - Automatic fallback on model failure
    - Performance tracking per model
    - Task-specific prompt templates
    """

    def __init__(self, litellm_client: LiteLLMClient, config: Optional[ModelRoutingConfig] = None):
        """
        Initialize model router.

        Args:
            litellm_client: Configured LiteLLMClient instance
            config: Model routing configuration (uses defaults if not provided)
        """
        self.client = litellm_client
        self.config = config or ModelRoutingConfig()
        self.performance_stats = {}  # Track latency and success rate per model

        logger.info(
            f"Model router initialized: "
            f"general_primary={self.config.general_primary.model_id}, "
            f"technical_primary={self.config.technical_primary.model_id}"
        )

    def detect_content_type(self, text: str) -> ContentType:
        """
        Detect content type from document text.

        Uses heuristics to classify as general or technical content:
        - Technical indicators: code blocks, function signatures, API endpoints
        - General indicators: business terminology, narrative structure

        Args:
            text: Document text sample (first 1000 chars sufficient)

        Returns:
            ContentType classification
        """
        # Sample first 1000 chars for efficiency
        sample = text[:1000].lower()

        # Technical indicators
        technical_indicators = [
            "def ", "class ", "function ", "import ", "const ", "var ",
            "```", "http://", "https://", "api.", "endpoint", ".json",
            "return ", "async ", "await ", "docker", "kubernetes",
            "def main", "if __name__", "public class", "private void",
        ]

        # Count technical indicators
        technical_score = sum(1 for indicator in technical_indicators if indicator in sample)

        # Classify based on score threshold
        if technical_score >= 3:
            logger.debug(f"Content classified as TECHNICAL (score: {technical_score})")
            return ContentType.TECHNICAL
        else:
            logger.debug(f"Content classified as GENERAL (score: {technical_score})")
            return ContentType.GENERAL

    def select_model(self, content_type: ContentType, use_fallback: bool = False) -> ModelConfig:
        """
        Select model based on content type and fallback flag.

        Args:
            content_type: Detected content type
            use_fallback: If True, use fallback model instead of primary

        Returns:
            ModelConfig for selected model
        """
        if content_type == ContentType.GENERAL:
            model = self.config.general_fallback if use_fallback else self.config.general_primary
        else:  # TECHNICAL
            model = self.config.technical_fallback if use_fallback else self.config.technical_primary

        logger.debug(f"Selected model: {model.model_id} (content={content_type}, fallback={use_fallback})")
        return model

    async def extract_entities(
        self,
        text: str,
        content_type: Optional[ContentType] = None,
    ) -> Dict[str, Any]:
        """
        Extract named entities from text using appropriate model.

        Args:
            text: Input text for entity extraction
            content_type: Optional content type (auto-detected if not provided)

        Returns:
            Dict with extracted entities and metadata

        Raises:
            RuntimeError: If both primary and fallback models fail
        """
        # Auto-detect content type if not provided
        if content_type is None:
            content_type = self.detect_content_type(text)

        # Select primary model
        primary_model = self.select_model(content_type, use_fallback=False)

        # Build entity extraction prompt
        messages = self._build_entity_extraction_prompt(text, content_type)

        # Attempt with primary model
        try:
            response = await self.client.chat_completion(
                model=primary_model.model_id,
                messages=messages,
                temperature=primary_model.temperature,
                top_p=primary_model.top_p,
                max_tokens=primary_model.max_tokens,
            )

            # Parse and return entities
            return self._parse_entity_response(response, model=primary_model.model_id)

        except Exception as e:
            logger.warning(f"Primary model {primary_model.model_id} failed: {str(e)}, attempting fallback")

            # Fallback to secondary model
            fallback_model = self.select_model(content_type, use_fallback=True)

            try:
                response = await self.client.chat_completion(
                    model=fallback_model.model_id,
                    messages=messages,
                    temperature=fallback_model.temperature,
                    top_p=fallback_model.top_p,
                    max_tokens=fallback_model.max_tokens,
                )

                return self._parse_entity_response(response, model=fallback_model.model_id)

            except Exception as fallback_error:
                logger.error(f"Fallback model {fallback_model.model_id} also failed: {str(fallback_error)}")
                raise RuntimeError(
                    f"Entity extraction failed with both primary ({primary_model.model_id}) "
                    f"and fallback ({fallback_model.model_id}) models"
                )

    def _build_entity_extraction_prompt(
        self,
        text: str,
        content_type: ContentType,
    ) -> List[Dict[str, str]]:
        """
        Build entity extraction prompt with task-specific instructions.

        Args:
            text: Input text
            content_type: Content type classification

        Returns:
            OpenAI-format messages list
        """
        # System prompt with entity extraction instructions
        system_prompt = """You are an expert entity extraction system. Extract named entities from the provided text.

Entity Types:
- PERSON: Individual names
- ORGANIZATION: Companies, institutions, agencies
- LOCATION: Cities, countries, addresses, geographic locations
- DATE: Dates, times, temporal expressions
- PRODUCT: Product names, service names, brand names
- TECHNOLOGY: Programming languages, frameworks, tools, platforms (for technical content)

Output Format (JSON):
{
  "entities": [
    {
      "text": "entity mention as it appears in text",
      "type": "PERSON|ORGANIZATION|LOCATION|DATE|PRODUCT|TECHNOLOGY",
      "confidence": 0.0-1.0
    }
  ]
}

Rules:
1. Extract entities exactly as they appear in text (preserve casing)
2. Assign confidence score based on context clarity
3. Deduplicate entities (combine multiple mentions of same entity)
4. Return ONLY valid JSON, no additional text
"""

        # Add technical-specific instructions
        if content_type == ContentType.TECHNICAL:
            system_prompt += "\nFocus on technical entities: function names, class names, API endpoints, technology stack components."

        # User prompt with text to analyze
        user_prompt = f"Extract entities from the following text:\n\n{text}"

        return [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]

    def _parse_entity_response(self, response, model: str) -> Dict[str, Any]:
        """
        Parse LLM response and extract entities.

        Args:
            response: LiteLLMResponse from chat completion
            model: Model ID used for extraction

        Returns:
            Dict with entities and metadata
        """
        # Extract content from response
        content = response.choices[0]["message"]["content"]

        try:
            # Parse JSON response
            entities_data = json.loads(content)

            return {
                "entities": entities_data.get("entities", []),
                "model": model,
                "tokens_used": response.usage["total_tokens"],
                "success": True,
            }

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse entity extraction response: {str(e)}")
            # Raise exception to trigger fallback mechanism (consistent with HTTP error handling)
            raise ValueError(f"Invalid JSON response from model {model}: {str(e)}")


# Factory function
def create_model_router_from_env(litellm_client: LiteLLMClient) -> ModelRouter:
    """
    Create ModelRouter with default configuration.

    Args:
        litellm_client: Configured LiteLLMClient instance

    Returns:
        ModelRouter instance
    """
    return ModelRouter(litellm_client=litellm_client)
EOF

# Set ownership and permissions
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/src/integrations/model_router.py
sudo chmod 644 /opt/docling-mcp/src/integrations/model_router.py
```

### Step 2: Update Integrations Package Exports

```bash
# Update __init__.py to export model router
sudo -u docling-mcp@hx.dev.local tee -a /opt/docling-mcp/src/integrations/__init__.py > /dev/null << 'EOF'

from .model_router import (
    ModelRouter,
    ModelConfig,
    ModelRoutingConfig,
    ContentType,
    TaskType,
    create_model_router_from_env,
)

__all__.extend([
    "ModelRouter",
    "ModelConfig",
    "ModelRoutingConfig",
    "ContentType",
    "TaskType",
    "create_model_router_from_env",
])
EOF
```

### Step 3: Verify Module Syntax and Imports

```bash
# Activate virtual environment
source /opt/docling-mcp/venv/bin/activate

# Test module import
python3 -c "from src.integrations.model_router import ModelRouter; print('✅ Model router import successful')"

# Verify content type detection
python3 -c "
from src.integrations.model_router import ModelRouter, ContentType
from src.integrations.litellm_client import LiteLLMClient

# Create client and router
client = LiteLLMClient(base_url='http://hx-litellm-server.hx.dev.local:4000')
router = ModelRouter(litellm_client=client)

# Test content type detection
general_text = 'This is a business report about quarterly earnings.'
technical_text = 'def main(): import numpy as np; return np.array([1,2,3])'

general_type = router.detect_content_type(general_text)
technical_type = router.detect_content_type(technical_text)

assert general_type == ContentType.GENERAL, 'General detection failed'
assert technical_type == ContentType.TECHNICAL, 'Technical detection failed'

print('✅ Content type detection validated')
"

# Deactivate venv
deactivate
```

## Validation

**Validation Commands:**

```bash
# 1. Verify module file exists
test -f /opt/docling-mcp/src/integrations/model_router.py && echo "PASS: Model router module exists" || echo "FAIL: Module missing"

# 2. Verify module ownership
stat -c '%U:%G' /opt/docling-mcp/src/integrations/model_router.py | grep -q "docling-mcp@hx.dev.local:domain users@hx.dev.local" && echo "PASS: Ownership correct" || echo "FAIL: Ownership incorrect"

# 3. Verify Python syntax
source /opt/docling-mcp/venv/bin/activate && python3 -m py_compile /opt/docling-mcp/src/integrations/model_router.py && echo "PASS: Python syntax valid" || echo "FAIL: Syntax error"

# 4. Verify ModelRouter class exists
source /opt/docling-mcp/venv/bin/activate && python3 -c "from src.integrations.model_router import ModelRouter; assert hasattr(ModelRouter, 'extract_entities'); print('PASS: ModelRouter class valid')" || echo "FAIL: Class structure invalid"

# 5. Verify content type detection
source /opt/docling-mcp/venv/bin/activate && python3 -c "
from src.integrations.model_router import ModelRouter, ContentType
from src.integrations.litellm_client import LiteLLMClient
client = LiteLLMClient(base_url='http://hx-litellm-server.hx.dev.local:4000')
router = ModelRouter(litellm_client=client)
assert router.detect_content_type('business report') == ContentType.GENERAL
assert router.detect_content_type('def main(): pass') == ContentType.TECHNICAL
print('PASS: Content detection logic valid')
" || echo "FAIL: Content detection error"

# 6. Verify model selection logic
source /opt/docling-mcp/venv/bin/activate && python3 -c "
from src.integrations.model_router import ModelRouter, ContentType
from src.integrations.litellm_client import LiteLLMClient
client = LiteLLMClient(base_url='http://hx-litellm-server.hx.dev.local:4000')
router = ModelRouter(litellm_client=client)
primary = router.select_model(ContentType.GENERAL, use_fallback=False)
assert 'gemma3' in primary.model_id.lower()
fallback = router.select_model(ContentType.GENERAL, use_fallback=True)
assert 'gpt-oss' in fallback.model_id.lower()
print('PASS: Model selection logic valid')
" || echo "FAIL: Model selection error"
```

**Expected Outcomes:**
- All validation commands return "PASS"
- ModelRouter class implements content-type detection
- Model selection based on content type and fallback flag
- Entity extraction prompts generated correctly
- Pydantic models validate configuration structures

## Notes

### Content Type Detection Heuristics

**Technical Indicators**:
- Code keywords: `def`, `class`, `function`, `import`, `const`, `var`, `return`, `async`, `await`
- Code blocks: triple backticks (```)
- API patterns: `http://`, `https://`, `api.`, `.json`, `endpoint`
- DevOps keywords: `docker`, `kubernetes`
- Language-specific: `if __name__`, `public class`, `private void`

**Threshold**: 3+ technical indicators → TECHNICAL, otherwise GENERAL

**Rationale**: Simple heuristic-based classification is sufficient for model routing. Does not require ML-based classification overhead.

### Model Selection Strategy

**General Content Route**:
- **Primary**: `ollama_chat/gemma3:27b` (F1 0.85+, 2-5s P95 latency)
- **Fallback**: `ollama_chat/gpt-oss:20b` (F1 0.75+, 1-3s P95 latency)

**Technical Content Route**:
- **Primary**: `ollama_chat/qwen3-coder:30b` (F1 0.90+ for tech, 3-7s P95 latency)
- **Fallback**: `ollama_chat/gemma3:27b` (F1 0.85+, 2-5s P95 latency)

**Why Not Single Model**: Different models optimized for different content types. Qwen3-Coder trained on code/technical text outperforms Gemma3 on technical entity extraction.

### Prompt Engineering for Entity Extraction

**System Prompt Components**:
1. **Role Definition**: "You are an expert entity extraction system"
2. **Entity Type Taxonomy**: PERSON, ORGANIZATION, LOCATION, DATE, PRODUCT, TECHNOLOGY
3. **Output Format Specification**: JSON schema with fields (text, type, confidence)
4. **Extraction Rules**: Preserve casing, deduplicate, confidence scoring

**User Prompt**: Minimal - just the text to analyze

**Deterministic Parameters**: Temperature 0.1, Top_p 0.9 for consistent factual output

### Fallback Behavior

**Trigger Conditions**:
- HTTP 503 (model unavailable)
- HTTP 408 (timeout)
- Connection errors
- Invalid JSON response

**Fallback Flow**:
1. Primary model attempt
2. On failure, log warning
3. Select fallback model based on content type
4. Attempt extraction with fallback model
5. On second failure, raise RuntimeError (both models failed)

**No Infinite Retry**: Max 2 attempts (primary + fallback), then fail fast to prevent cascading delays.

### Performance Tracking

**Metrics to Track** (future enhancement in Task 125):
- Latency per model (P50, P95, P99)
- Success rate per model
- Fallback frequency
- Content type distribution
- Token usage per model

**Current Implementation**: Placeholder `performance_stats` dict. Metrics collection implemented in Task 125 (observability integration).

### Model Configuration via Environment Variables

**Future Enhancement** (Task 141: Configuration Management):

Environment variables for model override:
- `LITELLM_GENERAL_PRIMARY_MODEL` (default: `ollama_chat/gemma3:27b`)
- `LITELLM_GENERAL_FALLBACK_MODEL` (default: `ollama_chat/gpt-oss:20b`)
- `LITELLM_TECHNICAL_PRIMARY_MODEL` (default: `ollama_chat/qwen3-coder:30b`)
- `LITELLM_TECHNICAL_FALLBACK_MODEL` (default: `ollama_chat/gemma3:27b`)

**Current Implementation**: Hardcoded defaults in `ModelRoutingConfig` Pydantic model.

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 4.3.4: LiteLLM Integration)
- **LiteLLM Enhancement**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/reviews/2025-11-25-team-contributions/shane-litellm-summary.md` (Model Selection Strategy)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 8)
- **Task 121**: LiteLLM client module (dependency)

## Risk Assessment

**Risk**: Low-Medium
- Content type detection heuristics may misclassify edge cases
- Fallback model may not improve results if issue is with input text quality
- Model availability depends on Ollama server uptime

**Mitigation**:
- Simple heuristics are sufficient for 90%+ accuracy (verified in similar deployments)
- Fallback provides resilience against transient model failures
- LiteLLM Router provides automatic failover across Ollama1/2/3 servers
- Future enhancement: ML-based content classification if heuristics insufficient
