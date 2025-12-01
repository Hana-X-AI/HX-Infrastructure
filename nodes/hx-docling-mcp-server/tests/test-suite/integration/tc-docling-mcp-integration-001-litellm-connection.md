# Test Case: LiteLLM Gateway Connection

**Test ID**: tc-docling-mcp-integration-001
**Test Area**: Integration Testing
**Priority**: HIGH
**Status**: Draft
**Created**: 2025-11-27
**Owner**: julia-santos

---

## Test Objective

Verify LiteLLM Gateway connection and model routing for entity extraction.

---

## Test Coverage

**Requirements Covered**:
- FR-021: Integrate with LiteLLM Gateway (hx-litellm-server:4000)
- FR-012: Use Ollama models via LiteLLM for entity extraction
- Charter SC-005: LiteLLM Integration

---

## Test Steps

### Step 1: Verify LiteLLM Gateway Reachable

**Action**:
```bash
curl -s http://192.168.10.212:4000/health
curl -s http://192.168.10.212:4000/v1/models
```

**Expected**: LiteLLM responds, shows available models

---

### Step 2: Verify Required Models Available

**Action**:
```bash
curl -s http://192.168.10.212:4000/v1/models | jq '.data[] | select(.id | contains("gemma3:27b"))'
curl -s http://192.168.10.212:4000/v1/models | jq '.data[] | select(.id | contains("gpt-oss:20b"))'
curl -s http://192.168.10.212:4000/v1/models | jq '.data[] | select(.id | contains("granite-docling:258m"))'
```

**Expected**: gemma3:27b, gpt-oss:20b, granite-docling:258m all available

**Pass Criteria**: All 3 required models accessible via LiteLLM

---

### Step 3: Test Model Invocation via LiteLLM

**Action**:
```bash
curl -X POST http://192.168.10.212:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ollama/gemma3:27b",
    "messages": [{"role": "user", "content": "Extract entities from: Apple Inc. CEO Tim Cook announced..."}]
  }'
```

**Expected**: LiteLLM routes request to Ollama1, returns entity extraction response

---

### Step 4: Verify Docling MCP Server Uses LiteLLM for Entity Extraction

**Action**:
```bash
# Check application logs for LiteLLM connection
sudo journalctl -u docling-mcp.service -n 50 | grep "LiteLLM"

# Verify environment variable set
grep "LITELLM_BASE_URL=http://192.168.10.212:4000" /etc/docling-mcp/.env
```

**Expected**: Service configured to use LiteLLM gateway

---

## Pass/Fail Criteria

**PASS**: LiteLLM reachable, models available, service configured correctly

**FAIL**: Cannot connect to LiteLLM or models unavailable

---

## Defect Logging

**IF FAIL**: Create `defect-docling-mcp-high-int-001-litellm-unavailable.md`

---

**Test Case Version**: 1.0
