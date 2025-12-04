# Task: Document n8n Custom Node Requirements

**Task ID**: hx-lang-server-task-123-document-n8n-custom-node-requirements
**Phase**: Implementation (Phase 2)
**Assigned To**: Isabella (n8n Workflow Automation SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-121 (n8n HTTP endpoint), hx-lang-server-task-122 (Status polling)
**Estimated Time**: 90 minutes

---

## Objective

Create comprehensive documentation for n8n custom node development to integrate with hx-lang-server, including node operations, parameter schemas, credential configuration, and example workflows. This enables n8n workflow developers to build native integrations with LangGraph agents.

---

## Prerequisites

- [ ] n8n HTTP endpoint operational at `/invoke`
- [ ] Status polling endpoint operational at `/status/{thread_id}`
- [ ] OpenAPI specification available at `/docs`
- [ ] Understanding of n8n node development structure

---

## Specification Reference

**From node-spec.md v2.1, Section: n8n Integration (Phase 2)**

Lines 571-579:
```
### Custom Node Requirements (Phase 2)

| Operation | Description |
|-----------|-------------|
| executeAgent | Invoke agent with query |
| checkStatus | Poll for async operation status |
| getResponse | Retrieve completed response |
| listThreads | List active conversation threads |
```

---

## Implementation Steps

### Step 1: Create Custom Node Requirements Document

Create file: `/opt/hx-lang-server/docs/n8n-custom-node-requirements.md`

```markdown
# n8n Custom Node Requirements: HX-Lang-Server

**Version:** 1.0
**Date:** 2025-12-04
**Target n8n Version:** 1.x
**hx-lang-server API Version:** v1

---

## Overview

This document defines requirements for developing a custom n8n node to integrate with hx-lang-server's LangGraph orchestration API. The custom node provides native n8n integration beyond basic HTTP Request nodes.

**Node Name:** `hx-lang-server`
**Node Type:** Regular Node
**Credentials:** API Key (future), None (current development)

---

## Node Operations

The custom node MUST implement the following operations:

### 1. Execute Agent (executeAgent)

**Operation ID:** `executeAgent`
**Description:** Invoke LangGraph agent with query and optional conversation context
**HTTP Method:** POST
**Endpoint:** `http://hx-lang-server.hx.dev.local:8100/invoke`

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| query | string | Yes | - | User query to process |
| threadId | string | No | (auto-generated) | Thread ID for conversation continuity |
| mode | options | No | sync | Execution mode: sync or async |
| callbackUrl | string | Conditional | - | Required if mode=async |
| workflowId | string | No | - | n8n workflow ID for tracking |
| executionId | string | No | - | n8n execution ID for correlation |
| config | json | No | {} | Agent configuration overrides |

**Returns:**

```typescript
interface ExecuteAgentResponse {
  thread_id: string;
  response: string;
  query_type: "general" | "code" | "rag" | "tool";
  worker_used: string;
  iteration_count: number;
  async_mode: boolean;
  status_url?: string;
  metadata: Record<string, any>;
  timestamp: string;
}
```

**n8n Parameter Schema:**

```typescript
{
  displayName: 'Query',
  name: 'query',
  type: 'string',
  required: true,
  default: '',
  placeholder: 'Enter your question or request',
  description: 'The query to send to the LangGraph agent',
  typeOptions: {
    rows: 4,
  },
},
{
  displayName: 'Thread ID',
  name: 'threadId',
  type: 'string',
  required: false,
  default: '',
  placeholder: 'Leave empty for new conversation',
  description: 'Thread ID for continuing an existing conversation',
},
{
  displayName: 'Execution Mode',
  name: 'mode',
  type: 'options',
  required: true,
  default: 'sync',
  options: [
    {
      name: 'Synchronous',
      value: 'sync',
      description: 'Wait for response (up to 60 seconds)',
    },
    {
      name: 'Asynchronous',
      value: 'async',
      description: 'Return immediately, poll for result',
    },
  ],
},
{
  displayName: 'Callback URL',
  name: 'callbackUrl',
  type: 'string',
  required: false,
  default: '',
  displayOptions: {
    show: {
      mode: ['async'],
    },
  },
  description: 'Webhook URL for async result delivery',
},
```

---

### 2. Check Status (checkStatus)

**Operation ID:** `checkStatus`
**Description:** Poll status of async agent operation
**HTTP Method:** GET
**Endpoint:** `http://hx-lang-server.hx.dev.local:8100/status/{thread_id}`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| threadId | string | Yes | Thread ID to check status |

**Returns:**

```typescript
interface StatusResponse {
  thread_id: string;
  status: "pending" | "processing" | "completed" | "failed" | "timeout";
  progress_percent?: number;
  current_worker?: string;
  iteration_count: number;
  result?: ExecuteAgentResponse;
  error?: string;
  error_code?: string;
  created_at: string;
  updated_at: string;
  metadata: Record<string, any>;
}
```

**n8n Parameter Schema:**

```typescript
{
  displayName: 'Thread ID',
  name: 'threadId',
  type: 'string',
  required: true,
  default: '={{ $json.thread_id }}',
  description: 'Thread ID from executeAgent operation',
},
```

---

### 3. Get Thread History (getThreadHistory)

**Operation ID:** `getThreadHistory`
**Description:** Retrieve full conversation history for a thread
**HTTP Method:** GET
**Endpoint:** `http://hx-lang-server.hx.dev.local:8100/threads/{thread_id}`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| threadId | string | Yes | Thread ID to retrieve |

**Returns:**

```typescript
interface ThreadHistoryResponse {
  thread_id: string;
  messages: Array<{
    role: "user" | "assistant" | "system";
    content: string;
    timestamp: string;
  }>;
  total_iterations: number;
  created_at: string;
  last_activity: string;
}
```

**n8n Parameter Schema:**

```typescript
{
  displayName: 'Thread ID',
  name: 'threadId',
  type: 'string',
  required: true,
  default: '={{ $json.thread_id }}',
  description: 'Thread ID to retrieve history',
},
```

---

### 4. Delete Thread (deleteThread)

**Operation ID:** `deleteThread`
**Description:** Delete thread checkpoint data and history
**HTTP Method:** DELETE
**Endpoint:** `http://hx-lang-server.hx.dev.local:8100/threads/{thread_id}`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| threadId | string | Yes | Thread ID to delete |

**Returns:**

```typescript
interface DeleteThreadResponse {
  message: string;
  thread_id: string;
  deleted_at: string;
}
```

---

## Node Credentials

**Credential Name:** `hxLangServerApi`
**Credential Type:** API Key (future implementation)

**Current Development:** No authentication required (internal HX network)

**Future Credential Properties:**

```typescript
{
  displayName: 'API Key',
  name: 'apiKey',
  type: 'string',
  typeOptions: {
    password: true,
  },
  required: true,
  default: '',
},
{
  displayName: 'Base URL',
  name: 'baseUrl',
  type: 'string',
  required: true,
  default: 'http://hx-lang-server.hx.dev.local:8100',
},
```

---

## Error Handling

The custom node MUST handle these error scenarios:

### 1. Validation Errors (422)

```typescript
{
  error: "Validation failed",
  error_code: "VALIDATION_ERROR",
  detail: [
    {
      loc: ["body", "query"],
      msg: "Field required",
      type: "value_error.missing"
    }
  ]
}
```

**Node Behavior:** Display validation errors in n8n UI with field names

### 2. Not Found Errors (404)

```typescript
{
  error: "Thread not found or status expired",
  error_code: "THREAD_NOT_FOUND",
  thread_id: "..."
}
```

**Node Behavior:** Throw NodeOperationError with clear message

### 3. Server Errors (500, 503)

```typescript
{
  error: "Internal server error",
  error_code: "INVOCATION_FAILED",
  request_id: "..."
}
```

**Node Behavior:** Retry with exponential backoff (max 3 retries)

---

## Example n8n Workflows

### Workflow 1: Simple Agent Query

```json
{
  "name": "Simple Agent Query",
  "nodes": [
    {
      "parameters": {
        "operation": "executeAgent",
        "query": "What is LangGraph?",
        "mode": "sync"
      },
      "name": "HX Lang Server",
      "type": "hx-lang-server",
      "position": [250, 300]
    }
  ]
}
```

### Workflow 2: Multi-Turn Conversation

```json
{
  "name": "Multi-Turn Conversation",
  "nodes": [
    {
      "parameters": {
        "operation": "executeAgent",
        "query": "Hello, my name is Alice",
        "mode": "sync"
      },
      "name": "Initial Query",
      "type": "hx-lang-server",
      "position": [250, 300]
    },
    {
      "parameters": {
        "operation": "executeAgent",
        "query": "What is my name?",
        "threadId": "={{ $json.thread_id }}",
        "mode": "sync"
      },
      "name": "Follow-up Query",
      "type": "hx-lang-server",
      "position": [450, 300]
    }
  ]
}
```

### Workflow 3: Async with Polling

```json
{
  "name": "Async Agent with Polling",
  "nodes": [
    {
      "parameters": {
        "operation": "executeAgent",
        "query": "Complex task requiring time",
        "mode": "async"
      },
      "name": "Start Async Task",
      "type": "hx-lang-server",
      "position": [250, 300]
    },
    {
      "parameters": {
        "unit": "seconds",
        "amount": 5
      },
      "name": "Wait",
      "type": "n8n-nodes-base.wait",
      "position": [450, 300]
    },
    {
      "parameters": {
        "operation": "checkStatus",
        "threadId": "={{ $json.thread_id }}"
      },
      "name": "Check Status",
      "type": "hx-lang-server",
      "position": [650, 300]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.status }}",
              "value2": "completed"
            }
          ]
        }
      },
      "name": "If Completed",
      "type": "n8n-nodes-base.if",
      "position": [850, 300]
    }
  ]
}
```

---

## Testing Requirements

The custom node MUST pass these tests:

### Unit Tests

- [ ] executeAgent with valid query returns response
- [ ] executeAgent with threadId continues conversation
- [ ] executeAgent async mode returns immediately
- [ ] checkStatus returns valid StatusResponse
- [ ] getThreadHistory retrieves messages
- [ ] deleteThread removes thread data
- [ ] Error handling for 404, 422, 500 status codes
- [ ] Retry logic with exponential backoff

### Integration Tests

- [ ] End-to-end sync execution flow
- [ ] End-to-end async execution with polling
- [ ] Multi-turn conversation with thread_id
- [ ] Thread history retrieval after multiple queries
- [ ] Error scenarios (invalid query, expired thread)

---

## Development Resources

### n8n Node Development

- **Documentation:** https://docs.n8n.io/integrations/creating-nodes/
- **Node Template:** https://github.com/n8n-io/n8n-nodes-starter
- **TypeScript Types:** `@types/n8n` package

### hx-lang-server API

- **OpenAPI Spec:** http://hx-lang-server.hx.dev.local:8100/docs
- **Health Check:** http://hx-lang-server.hx.dev.local:8100/health
- **Node Spec:** `/home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md`

### Testing

- **n8n Test Framework:** `@n8n/n8n-test-framework`
- **Local n8n:** http://hx-n8n-server.hx.dev.local:5678

---

## Deployment

### Installation

```bash
# Clone custom node repository
git clone https://github.com/Hana-X-AI/n8n-nodes-hx-lang-server.git
cd n8n-nodes-hx-lang-server

# Install dependencies
npm install

# Build node
npm run build

# Link for local development
npm link

# In n8n installation directory
cd ~/.n8n/custom
npm link n8n-nodes-hx-lang-server

# Restart n8n
systemctl restart n8n
```

### Configuration

Add to n8n environment variables:

```bash
# Enable custom nodes
N8N_CUSTOM_EXTENSIONS=/opt/n8n/custom

# hx-lang-server endpoint
HX_LANG_SERVER_URL=http://hx-lang-server.hx.dev.local:8100
```

---

## Maintenance

### Version Compatibility

| n8n Version | Node Version | hx-lang-server API |
|-------------|--------------|---------------------|
| 1.x | 1.0.x | v1 |

### Changelog

- **1.0.0** (2025-12-04): Initial custom node specification

---

## Support

**Issues:** https://github.com/Hana-X-AI/n8n-nodes-hx-lang-server/issues
**Documentation:** `/opt/hx-lang-server/docs/n8n-integration.md`
**Contact:** Isabella (n8n Workflow Automation SME)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-04
**Status:** APPROVED for development
```

### Step 2: Create Quick Start Guide

Create file: `/opt/hx-lang-server/docs/n8n-integration-quick-start.md`

```markdown
# n8n Integration Quick Start Guide

**Target Audience:** n8n Workflow Developers
**Time to Complete:** 15 minutes
**Prerequisites:** n8n installed and running

---

## Using HTTP Request Node (No Custom Node Required)

This is the simplest way to integrate hx-lang-server with n8n workflows.

### Step 1: Add HTTP Request Node

1. In n8n workflow editor, click **+** to add node
2. Search for "HTTP Request"
3. Select **HTTP Request** node

### Step 2: Configure for Sync Execution

**Method:** POST
**URL:** `http://hx-lang-server.hx.dev.local:8100/invoke`
**Body Content Type:** JSON
**Body:**

```json
{
  "query": "{{ $json.user_input }}",
  "thread_id": "{{ $json.thread_id }}",
  "workflow_id": "{{ $workflow.id }}",
  "execution_id": "{{ $execution.id }}"
}
```

**Response Format:** JSON

### Step 3: Access Response Data

The response will be available in `{{ $json }}`:

- `{{ $json.thread_id }}` - Use for follow-up queries
- `{{ $json.response }}` - Agent's response text
- `{{ $json.query_type }}` - Query classification
- `{{ $json.worker_used }}` - Which worker handled query

### Example Workflow: Simple Q&A

```
[Manual Trigger] → [HTTP Request: hx-lang-server] → [Display Response]
```

**HTTP Request Configuration:**
- URL: `http://hx-lang-server.hx.dev.local:8100/invoke`
- Method: POST
- Body: `{"query": "Explain LangGraph"}`

---

## Multi-Turn Conversations

### Step 1: Store Thread ID

After first query, extract thread_id:

**Set Node Configuration:**
```json
{
  "thread_id": "={{ $json.thread_id }}"
}
```

### Step 2: Pass Thread ID to Subsequent Queries

**HTTP Request Body:**
```json
{
  "query": "Tell me more about that",
  "thread_id": "={{ $json.thread_id }}"
}
```

### Example Workflow: Conversation Flow

```
[Trigger] → [Query 1] → [Set thread_id] → [Query 2] → [Query 3]
```

Each query uses the same `thread_id` for continuity.

---

## Async Execution with Webhook

For long-running tasks, use async mode with callback.

### Step 1: Add Webhook Node

1. Add **Webhook** node (Trigger type)
2. Set **Path:** `/lang-server-callback`
3. Set **Method:** POST
4. Note the webhook URL (e.g., `http://hx-n8n-server.hx.dev.local:5678/webhook/lang-server-callback`)

### Step 2: Configure HTTP Request for Async

**Body:**
```json
{
  "query": "Complex task requiring time",
  "callback_url": "{{ $node.Webhook.webhookUrl }}"
}
```

### Step 3: Handle Callback

The webhook will receive the result when processing completes.

**Workflow Structure:**
```
[Webhook Trigger] → [HTTP Request (async)] → [Wait for Callback]
                                                      ↓
[Process Result] ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
```

---

## Polling Pattern (Alternative to Webhook)

### Step 1: Start Async Task

**HTTP Request Body:**
```json
{
  "query": "Long running task",
  "callback_url": "http://example.com/unused"
}
```

**Extract:** `{{ $json.thread_id }}`

### Step 2: Add Loop Node

1. Add **Loop** node (type: While)
2. **Condition:** `{{ $json.status }} !== "completed"`
3. **Max Iterations:** 60 (5 minutes with 5s delays)

### Step 3: Add Wait and Status Check

**Inside Loop:**
```
[Wait 5s] → [HTTP GET /status/{thread_id}] → [Check status]
```

**HTTP Request:**
- URL: `http://hx-lang-server.hx.dev.local:8100/status/{{ $json.thread_id }}`
- Method: GET

### Step 4: Extract Result

When `status === "completed"`, result is in `{{ $json.result }}`.

---

## Troubleshooting

### Error: "Thread not found"

**Cause:** Thread ID expired or invalid
**Solution:** Start new conversation without thread_id

### Error: "Validation failed"

**Cause:** Empty query or malformed request
**Solution:** Check query field is not empty

### Timeout on Sync Request

**Cause:** Query taking > 60 seconds
**Solution:** Use async mode with callback or polling

### No Response from Callback

**Cause:** Webhook URL not reachable
**Solution:** Check n8n webhook is active and accessible from hx-lang-server

---

## Best Practices

1. **Store thread_id:** Always capture thread_id for conversation continuity
2. **Use async for long tasks:** Queries > 10 seconds should use async mode
3. **Handle errors:** Add error handling nodes for 404, 422, 500 responses
4. **Log workflow/execution IDs:** Include in requests for debugging
5. **Test with simple queries:** Verify connectivity before complex workflows

---

## Next Steps

- **Custom Node:** For advanced features, develop custom n8n node (see `n8n-custom-node-requirements.md`)
- **Examples:** More workflow templates in `/opt/hx-lang-server/docs/examples/`
- **API Reference:** Full API docs at http://hx-lang-server.hx.dev.local:8100/docs

---

**Quick Start Version:** 1.0
**Last Updated:** 2025-12-04
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Custom node requirements | `/opt/hx-lang-server/docs/n8n-custom-node-requirements.md` | Full specification for custom node development |
| Quick start guide | `/opt/hx-lang-server/docs/n8n-integration-quick-start.md` | HTTP Request node usage guide |

---

## Verification Steps

### Step 1: Review Documentation Completeness

```bash
# Verify files created
ls -lh /opt/hx-lang-server/docs/n8n-*.md

# Check word count (should be comprehensive)
wc -w /opt/hx-lang-server/docs/n8n-custom-node-requirements.md
wc -w /opt/hx-lang-server/docs/n8n-integration-quick-start.md
```

### Step 2: Validate Against Specification

```bash
# Cross-reference with node-spec.md
grep -A 10 "Custom Node Requirements" /home/agent0/HX-Infrastructure/nodes/hx-lang-server/specification/node-spec.md

# Verify all operations documented:
# - executeAgent ✓
# - checkStatus ✓
# - getThreadHistory ✓
# - deleteThread ✓
```

### Step 3: Test Quick Start Guide Instructions

Follow quick start guide step-by-step in n8n to verify:
- [ ] HTTP Request node configuration works
- [ ] Response data accessible as documented
- [ ] Multi-turn conversation example functional
- [ ] Error handling examples accurate

---

## Acceptance Criteria

- [ ] Custom node requirements document created with all 4 operations
- [ ] n8n parameter schemas defined for each operation
- [ ] TypeScript interfaces provided for all responses
- [ ] Error handling documentation complete
- [ ] Example workflows included (simple, multi-turn, async)
- [ ] Quick start guide created for HTTP Request node usage
- [ ] Testing requirements specified
- [ ] Deployment instructions documented
- [ ] Troubleshooting section included
- [ ] Best practices documented

---

## Rollback Procedure

Not applicable (documentation only, no code changes)

---

## Notes

- **Custom Node Development:** Phase 2 enhancement, HTTP Request node sufficient for initial integration
- **OpenAPI Spec:** Developers can generate n8n nodes from `/docs` endpoint
- **Version Compatibility:** Document updated as hx-lang-server API evolves
- **Community:** Documentation enables community-contributed n8n nodes

---

**Created By:** Isabella (n8n Workflow Automation SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: n8n Integration (Custom Node Requirements)
