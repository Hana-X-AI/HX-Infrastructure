# Task 127: Test LiteLLM Connectivity and Health Checks

**Assigned To**: shane-black
**Estimated Effort**: 1.5 hours
**Dependencies**: Task 121 (LiteLLM client), Task 126 (Environment variables)
**Status**: Not Started

## Objective

Validate connectivity to hx-litellm-server.hx.dev.local:4000, test health check endpoint, verify model availability, and execute test entity extraction request to confirm end-to-end LiteLLM integration functionality.

## Pre-Execution Validation

**CRITICAL**: Check if LiteLLM connectivity tests already performed to prevent redundant testing.

```bash
# Check if connectivity test results exist
if [ -f "/opt/docling-mcp/tests/litellm_connectivity_test_results.txt" ]; then
    echo "✅ VALIDATION RESULT: LiteLLM connectivity tests already performed"
    echo "ACTION: Review existing test results"
    cat /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
    exit 0
else
    echo "❌ VALIDATION RESULT: LiteLLM connectivity tests NOT performed"
    echo "ACTION: PROCEED with connectivity testing"
fi
```

**If Tests Exist**: Review test results, re-run if results are stale (>7 days old)

**If Tests Do Not Exist**: Continue with Implementation Steps below

---

## Context

Before deploying the Docling MCP Server to operational status, LiteLLM integration must be validated:

1. **Network Connectivity**: Verify hx-litellm-server.hx.dev.local resolves via DNS and TCP connection succeeds on port 4000
2. **Health Check**: Confirm LiteLLM Router `/health` endpoint responds with healthy status
3. **Model Availability**: Verify required models loaded on Ollama servers (gemma3:27b, qwen3-coder:30b, gpt-oss:20b)
4. **Entity Extraction**: Execute end-to-end test request to validate complete pipeline (LiteLLMClient → Router → Ollama → response parsing)

These tests ensure LiteLLM integration is operational before MCP tools depend on it for entity extraction.

## Acceptance Criteria

- [ ] DNS resolution test for hx-litellm-server.hx.dev.local succeeds
- [ ] TCP connection test on port 4000 succeeds
- [ ] LiteLLM health check endpoint returns HTTP 200 with healthy status
- [ ] Required models available: gemma3:27b, qwen3-coder:30b, gpt-oss:20b
- [ ] Test entity extraction request completes successfully (<10s latency)
- [ ] Response parsed correctly with valid JSON structure
- [ ] Extracted entities contain expected types (PERSON, ORGANIZATION, etc.)
- [ ] Test results documented in `/opt/docling-mcp/tests/litellm_connectivity_test_results.txt`
- [ ] Integration test script created for automated validation

## Implementation Steps

### Step 1: Test DNS Resolution

```bash
# Test DNS resolution for hx-litellm-server
echo "=== DNS Resolution Test ===" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

nslookup hx-litellm-server.hx.dev.local | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ PASS: DNS resolution successful" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
else
    echo "❌ FAIL: DNS resolution failed" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
    exit 1
fi

# Extract resolved IP address
IP_ADDRESS=$(nslookup hx-litellm-server.hx.dev.local | grep -A1 "Name:" | tail -1 | awk '{print $2}')
echo "Resolved IP: $IP_ADDRESS" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
```

### Step 2: Test TCP Connectivity

```bash
# Test TCP connection to port 4000
echo -e "\n=== TCP Connectivity Test ===" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

timeout 5 bash -c "cat < /dev/null > /dev/tcp/hx-litellm-server.hx.dev.local/4000" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ PASS: TCP connection to port 4000 successful" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
else
    echo "❌ FAIL: TCP connection to port 4000 failed" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
    exit 1
fi
```

### Step 3: Test LiteLLM Health Check Endpoint

```bash
# Test health check endpoint
echo -e "\n=== LiteLLM Health Check Test ===" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://hx-litellm-server.hx.dev.local:4000/health)

HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_CODE")

echo "HTTP Status Code: $HTTP_CODE" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "Response Body: $BODY" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ PASS: Health check returned HTTP 200" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
else
    echo "❌ FAIL: Health check returned HTTP $HTTP_CODE" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
    exit 1
fi
```

### Step 4: Test Model Availability

```bash
# Test model availability via LiteLLM /model/info endpoint (if available)
echo -e "\n=== Model Availability Test ===" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

REQUIRED_MODELS="gemma3:27b qwen3-coder:30b gpt-oss:20b"

for MODEL in $REQUIRED_MODELS; do
    echo "Testing model: $MODEL" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

    # Test model via chat completion request with minimal tokens
    MODEL_TEST=$(curl -s -X POST http://hx-litellm-server.hx.dev.local:4000/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d "{\"model\": \"ollama_chat/$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"test\"}], \"max_tokens\": 5}" \
      -w "\nHTTP_CODE:%{http_code}")

    MODEL_HTTP_CODE=$(echo "$MODEL_TEST" | grep "HTTP_CODE" | cut -d':' -f2)

    if [ "$MODEL_HTTP_CODE" == "200" ]; then
        echo "  ✅ PASS: Model $MODEL available" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
    else
        echo "  ❌ FAIL: Model $MODEL unavailable (HTTP $MODEL_HTTP_CODE)" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
        echo "  Response: $(echo "$MODEL_TEST" | grep -v "HTTP_CODE")" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
    fi
done
```

### Step 5: Test Entity Extraction End-to-End

```bash
# Create Python test script for entity extraction
sudo -u docling-mcp@hx.dev.local tee /opt/docling-mcp/tests/test_litellm_entity_extraction.py > /dev/null << 'EOF'
"""
End-to-end LiteLLM entity extraction test.

Tests:
- LiteLLMClient initialization
- Health check method
- Entity extraction via chat_completion
- Response parsing and validation
"""

import asyncio
import json
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.integrations.litellm_client import create_litellm_client_from_env
from src.prompts import PromptBuilder


async def test_entity_extraction():
    """Test entity extraction end-to-end."""
    print("=== Entity Extraction End-to-End Test ===\n")

    # Create client
    print("1. Creating LiteLLMClient...")
    client = create_litellm_client_from_env()
    print("   ✅ Client created\n")

    # Test health check
    print("2. Testing health check...")
    health = await client.health_check()
    print(f"   Health Status: {health['status']}")
    print(f"   Latency: {health['latency_ms']}ms")

    if health['status'] != 'healthy':
        print("   ❌ FAIL: LiteLLM server unhealthy")
        return False

    print("   ✅ PASS: Health check successful\n")

    # Test entity extraction
    print("3. Testing entity extraction...")

    test_text = "Amazon Web Services launched a new AI service in Seattle on March 15, 2024. CEO Andy Jassy announced the product."

    # Build prompt
    messages = PromptBuilder.build_entity_extraction_prompt(test_text)
    print(f"   Prompt messages: {len(messages)} (system + few-shot + user)")

    # Call LiteLLM
    print("   Sending request to LiteLLM...")
    import time
    start = time.time()

    try:
        response = await client.chat_completion(
            model="ollama_chat/gemma3:27b",
            messages=messages,
            temperature=0.1,
            top_p=0.9,
            max_tokens=2048,
        )

        latency = (time.time() - start) * 1000
        print(f"   ✅ Response received (latency: {latency:.0f}ms)\n")

        # Parse response
        content = response.choices[0]["message"]["content"]
        print(f"   Raw response content:\n{content}\n")

        # Validate JSON
        try:
            entities_data = json.loads(content)
            entities = entities_data.get("entities", [])

            print(f"   Extracted entities: {len(entities)}")
            for entity in entities[:5]:  # Show first 5
                print(f"     - {entity['text']} ({entity['type']}, confidence={entity['confidence']})")

            print(f"\n   Token usage: {response.usage}")

            # Validation checks
            if len(entities) == 0:
                print("   ⚠️  WARNING: No entities extracted")
                return False

            expected_types = ["PERSON", "ORGANIZATION", "LOCATION", "DATE", "PRODUCT"]
            extracted_types = set(e['type'] for e in entities)

            if not any(t in extracted_types for t in expected_types):
                print(f"   ❌ FAIL: No expected entity types found (extracted: {extracted_types})")
                return False

            print("   ✅ PASS: Entity extraction successful\n")
            return True

        except json.JSONDecodeError as e:
            print(f"   ❌ FAIL: Invalid JSON response: {str(e)}")
            return False

    except Exception as e:
        print(f"   ❌ FAIL: Entity extraction request failed: {str(e)}")
        return False

    finally:
        await client.close()


if __name__ == "__main__":
    result = asyncio.run(test_entity_extraction())

    if result:
        print("\n✅ ALL TESTS PASSED")
        sys.exit(0)
    else:
        print("\n❌ TESTS FAILED")
        sys.exit(1)
EOF

# Set ownership and permissions
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/test_litellm_entity_extraction.py
sudo chmod 755 /opt/docling-mcp/tests/test_litellm_entity_extraction.py

# Run test
echo -e "\n=== Entity Extraction End-to-End Test ===" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

source /opt/docling-mcp/venv/bin/activate
cd /opt/docling-mcp && python3 tests/test_litellm_entity_extraction.py 2>&1 | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
deactivate

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ PASS: Entity extraction test successful" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
else
    echo "❌ FAIL: Entity extraction test failed" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
fi
```

### Step 6: Generate Test Summary Report

```bash
# Generate summary report
echo -e "\n=== Test Summary Report ===" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "Test Date: $(date)" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "Test Host: $(hostname)" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "LiteLLM Server: hx-litellm-server.hx.dev.local:4000" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

TOTAL_TESTS=5
PASS_COUNT=$(grep -c "✅ PASS" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt || echo 0)
FAIL_COUNT=$(grep -c "❌ FAIL" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt || echo 0)

echo -e "\nResults:" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "  Total Tests: $TOTAL_TESTS" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "  Passed: $PASS_COUNT" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
echo "  Failed: $FAIL_COUNT" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\n✅ ALL LITELLM CONNECTIVITY TESTS PASSED" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
else
    echo -e "\n❌ SOME LITELLM CONNECTIVITY TESTS FAILED" | tee -a /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
fi

# Set ownership on test results file
sudo chown docling-mcp@hx.dev.local:domain\ users@hx.dev.local /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
sudo chmod 644 /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
```

## Validation

**Validation Commands:**

```bash
# 1. Verify test results file exists
test -f /opt/docling-mcp/tests/litellm_connectivity_test_results.txt && echo "PASS: Test results file exists" || echo "FAIL: Test results file missing"

# 2. Verify DNS resolution test passed
grep -q "DNS resolution successful" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt && echo "PASS: DNS resolution successful" || echo "FAIL: DNS resolution failed"

# 3. Verify TCP connectivity test passed
grep -q "TCP connection to port 4000 successful" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt && echo "PASS: TCP connectivity successful" || echo "FAIL: TCP connectivity failed"

# 4. Verify health check test passed
grep -q "Health check returned HTTP 200" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt && echo "PASS: Health check successful" || echo "FAIL: Health check failed"

# 5. Verify entity extraction test passed
grep -q "Entity extraction test successful" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt && echo "PASS: Entity extraction successful" || echo "FAIL: Entity extraction failed"

# 6. Verify no failed tests
FAIL_COUNT=$(grep -c "❌ FAIL" /opt/docling-mcp/tests/litellm_connectivity_test_results.txt || echo 0)
if [ $FAIL_COUNT -eq 0 ]; then
    echo "PASS: All connectivity tests passed"
else
    echo "FAIL: $FAIL_COUNT test(s) failed"
fi

# 7. Display test summary
echo -e "\n=== Test Summary ==="
tail -10 /opt/docling-mcp/tests/litellm_connectivity_test_results.txt
```

**Expected Outcomes:**
- All validation commands return "PASS"
- DNS resolves hx-litellm-server.hx.dev.local correctly
- TCP connection on port 4000 succeeds
- Health check endpoint returns HTTP 200 with healthy status
- Required models (gemma3:27b, qwen3-coder:30b, gpt-oss:20b) available
- Entity extraction test completes successfully (<10s latency)
- Extracted entities contain expected types (PERSON, ORGANIZATION, LOCATION, DATE, PRODUCT)

## Notes

### Why Connectivity Tests Required

**Pre-Deployment Validation**: Integration tests catch configuration errors before service deployment:
- Wrong IP address in configuration → DNS/TCP test fails
- LiteLLM server down → health check fails
- Models not loaded → model availability test fails
- Network firewall issues → TCP connection fails

**Cost**: Running connectivity tests prevents expensive debugging cycles during operational deployment.

### Health Check Endpoint

**Endpoint**: `GET http://hx-litellm-server.hx.dev.local:4000/health`

**Expected Response**:
```json
{
  "status": "healthy",
  "uptime": 86400,
  "models": ["ollama_chat/gemma3:27b", "ollama_chat/qwen3-coder:30b", ...]
}
```

**Unhealthy States**:
- LiteLLM Router starting up
- All Ollama servers down
- Database connection failed

### Model Availability Testing

**Method**: Minimal chat completion request with 5 max tokens

**Rationale**:
- Full entity extraction test is expensive (~2,000 tokens)
- Minimal test confirms model loaded and Router routing works
- 5 token response sufficient to validate model availability

**Failure Cases**:
- HTTP 503: Model not loaded on any Ollama server
- HTTP 404: Model name incorrect in configuration
- HTTP 429: Rate limit exceeded (retry after delay)

### Entity Extraction Test Validation

**Test Text**: "Amazon Web Services launched a new AI service in Seattle on March 15, 2024. CEO Andy Jassy announced the product."

**Expected Entities**:
- Amazon Web Services (ORGANIZATION)
- Seattle (LOCATION)
- March 15, 2024 (DATE)
- Andy Jassy (PERSON)
- AI service (PRODUCT)

**Pass Criteria**:
- JSON response parseable
- At least 3 entities extracted
- At least 2 different entity types present
- Confidence scores between 0.0-1.0
- Latency <10s

### Troubleshooting Failed Tests

**DNS Resolution Failure**:
```bash
# Verify DNS server configured
cat /etc/resolv.conf

# Test with different DNS server
nslookup hx-litellm-server.hx.dev.local 8.8.8.8

# Check /etc/hosts override
grep hx-litellm-server /etc/hosts
```

**TCP Connection Failure**:
```bash
# Test with telnet
telnet hx-litellm-server.hx.dev.local 4000

# Check firewall rules (should be disabled in HX-Infrastructure)
sudo iptables -L -n | grep 4000

# Test from different host
ssh agent0@hx-ollama1-server.hx.dev.local "nc -zv hx-litellm-server.hx.dev.local 4000"
```

**Health Check Failure**:
```bash
# Check LiteLLM service status
ssh agent0@hx-litellm-server.hx.dev.local "systemctl status litellm"

# Check LiteLLM logs
ssh agent0@hx-litellm-server.hx.dev.local "journalctl -u litellm -n 50"

# Test with verbose curl
curl -v http://hx-litellm-server.hx.dev.local:4000/health
```

**Model Unavailable**:
```bash
# Check Ollama server status
ssh agent0@hx-ollama1-server.hx.dev.local "systemctl status ollama"

# List loaded models
curl http://hx-ollama1-server.hx.dev.local:11434/api/tags

# Load model manually
curl -X POST http://hx-ollama1-server.hx.dev.local:11434/api/pull -d '{"name": "gemma3:27b"}'
```

**Entity Extraction Failure**:
```bash
# Test with curl directly
curl -X POST http://hx-litellm-server.hx.dev.local:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "ollama_chat/gemma3:27b", "messages": [{"role": "user", "content": "Extract entities from: Amazon launched a product"}], "max_tokens": 100}'

# Check prompt format
python3 -c "from src.prompts import PromptBuilder; print(PromptBuilder.build_entity_extraction_prompt('test'))"

# Enable debug logging
export LOG_LEVEL=DEBUG
python3 tests/test_litellm_entity_extraction.py
```

## References

- **Specification**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/specification/node-spec.md` (Section 4.3.4: LiteLLM Integration)
- **Task Framework**: `/home/agent0/HX-Infrastructure/nodes/hx-docling-mcp-server/tasks/task-framework.md` (Work Stream 8)
- **Task 121**: LiteLLM client module (dependency)
- **Task 124**: Prompt templates (used in entity extraction test)
- **Task 126**: Environment variables (LiteLLM configuration)

## Risk Assessment

**Risk**: Low
- Connectivity tests are non-destructive (read-only operations)
- Minimal load on LiteLLM server (5 requests total)
- Test failures provide clear diagnostics for troubleshooting
- Automated test script can be re-run any time

**Mitigation**:
- Test results documented for future reference
- Troubleshooting guide covers common failure modes
- Tests validate both infrastructure (DNS, TCP) and application layer (health check, entity extraction)
- Pass criteria clearly defined with quantifiable metrics
