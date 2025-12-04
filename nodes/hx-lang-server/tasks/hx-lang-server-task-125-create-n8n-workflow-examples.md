# Task: Create n8n Workflow Examples

**Task ID**: hx-lang-server-task-125-create-n8n-workflow-examples
**Phase**: Implementation (Phase 2)
**Assigned To**: Isabella (n8n Workflow Automation SME)
**Status**: Not Started
**Dependencies**: hx-lang-server-task-121 (n8n HTTP endpoint), hx-lang-server-task-123 (Custom node docs)
**Estimated Time**: 120 minutes

---

## Objective

Create a comprehensive library of n8n workflow examples demonstrating hx-lang-server integration patterns including simple queries, multi-turn conversations, async operations with polling, webhook callbacks, error handling, and RAG-enhanced workflows. These examples serve as templates for n8n workflow developers.

---

## Prerequisites

- [ ] hx-lang-server operational with `/invoke` endpoint
- [ ] Status polling endpoint `/status/{thread_id}` functional
- [ ] n8n server operational at hx-n8n-server.hx.dev.local:5678
- [ ] Understanding of n8n workflow JSON format

---

## Specification Reference

**From node-spec.md v2.1, Section: n8n Integration (Phase 2)**

Lines 543-579:
- HTTP endpoint configuration for n8n workflows
- Webhook callback registration and management
- Custom node requirements documentation

---

## Implementation Steps

### Step 1: Create Workflow Examples Directory Structure

```bash
# Create directory structure
mkdir -p /opt/hx-lang-server/docs/examples/n8n-workflows
cd /opt/hx-lang-server/docs/examples/n8n-workflows

# Directory layout:
# ├── 01-simple-query.json
# ├── 02-multi-turn-conversation.json
# ├── 03-async-with-webhook.json
# ├── 04-async-with-polling.json
# ├── 05-error-handling.json
# ├── 06-rag-document-query.json
# ├── 07-code-generation.json
# └── README.md
```

### Step 2: Create Simple Query Workflow

Create file: `/opt/hx-lang-server/docs/examples/n8n-workflows/01-simple-query.json`

```json
{
  "name": "HX-Lang-Server: Simple Query",
  "nodes": [
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "user_input",
              "value": "What is LangGraph and how does it work?"
            }
          ]
        },
        "options": {}
      },
      "id": "start-node",
      "name": "Start",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://hx-lang-server.hx.dev.local:8100/invoke",
        "authentication": "none",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $json.user_input }}"
            },
            {
              "name": "workflow_id",
              "value": "={{ $workflow.id }}"
            },
            {
              "name": "execution_id",
              "value": "={{ $execution.id }}"
            }
          ]
        },
        "options": {
          "timeout": 60000
        }
      },
      "id": "invoke-agent",
      "name": "Invoke Agent",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [470, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "response",
              "value": "={{ $json.response }}"
            },
            {
              "name": "thread_id",
              "value": "={{ $json.thread_id }}"
            },
            {
              "name": "query_type",
              "value": "={{ $json.query_type }}"
            },
            {
              "name": "worker_used",
              "value": "={{ $json.worker_used }}"
            }
          ]
        }
      },
      "id": "extract-response",
      "name": "Extract Response",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [690, 300]
    }
  ],
  "connections": {
    "Start": {
      "main": [
        [
          {
            "node": "Invoke Agent",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Invoke Agent": {
      "main": [
        [
          {
            "node": "Extract Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "pinData": {},
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "tags": ["hx-lang-server", "simple", "tutorial"],
  "meta": {
    "instanceId": "hx-n8n-server"
  }
}
```

### Step 3: Create Multi-Turn Conversation Workflow

Create file: `/opt/hx-lang-server/docs/examples/n8n-workflows/02-multi-turn-conversation.json`

```json
{
  "name": "HX-Lang-Server: Multi-Turn Conversation",
  "nodes": [
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "query1",
              "value": "Hello, my name is Alice and I work on AI infrastructure."
            },
            {
              "name": "query2",
              "value": "What is my name?"
            },
            {
              "name": "query3",
              "value": "What do I work on?"
            }
          ]
        }
      },
      "id": "setup-queries",
      "name": "Setup Queries",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://hx-lang-server.hx.dev.local:8100/invoke",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $json.query1 }}"
            }
          ]
        }
      },
      "id": "first-query",
      "name": "First Query",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [470, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "thread_id",
              "value": "={{ $json.thread_id }}"
            },
            {
              "name": "response1",
              "value": "={{ $json.response }}"
            }
          ]
        }
      },
      "id": "store-thread-id",
      "name": "Store Thread ID",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [690, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://hx-lang-server.hx.dev.local:8100/invoke",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $('Setup Queries').item.json.query2 }}"
            },
            {
              "name": "thread_id",
              "value": "={{ $json.thread_id }}"
            }
          ]
        }
      },
      "id": "second-query",
      "name": "Second Query",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [910, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "response2",
              "value": "={{ $json.response }}"
            }
          ]
        }
      },
      "id": "store-response2",
      "name": "Store Response 2",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [1130, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://hx-lang-server.hx.dev.local:8100/invoke",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $('Setup Queries').item.json.query3 }}"
            },
            {
              "name": "thread_id",
              "value": "={{ $('Store Thread ID').item.json.thread_id }}"
            }
          ]
        }
      },
      "id": "third-query",
      "name": "Third Query",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [1350, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "response3",
              "value": "={{ $json.response }}"
            },
            {
              "name": "thread_id",
              "value": "={{ $json.thread_id }}"
            },
            {
              "name": "total_iterations",
              "value": "={{ $json.iteration_count }}"
            }
          ]
        }
      },
      "id": "final-result",
      "name": "Final Result",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [1570, 300]
    }
  ],
  "connections": {
    "Setup Queries": {
      "main": [[{"node": "First Query", "type": "main", "index": 0}]]
    },
    "First Query": {
      "main": [[{"node": "Store Thread ID", "type": "main", "index": 0}]]
    },
    "Store Thread ID": {
      "main": [[{"node": "Second Query", "type": "main", "index": 0}]]
    },
    "Second Query": {
      "main": [[{"node": "Store Response 2", "type": "main", "index": 0}]]
    },
    "Store Response 2": {
      "main": [[{"node": "Third Query", "type": "main", "index": 0}]]
    },
    "Third Query": {
      "main": [[{"node": "Final Result", "type": "main", "index": 0}]]
    }
  },
  "tags": ["hx-lang-server", "conversation", "multi-turn"]
}
```

### Step 4: Create Async Polling Workflow

Create file: `/opt/hx-lang-server/docs/examples/n8n-workflows/04-async-with-polling.json`

```json
{
  "name": "HX-Lang-Server: Async with Polling",
  "nodes": [
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "query",
              "value": "Generate a comprehensive analysis of LangGraph architecture (this is a long task)"
            }
          ]
        }
      },
      "id": "setup",
      "name": "Setup",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://hx-lang-server.hx.dev.local:8100/invoke",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $json.query }}"
            },
            {
              "name": "callback_url",
              "value": "http://example.com/unused"
            }
          ]
        }
      },
      "id": "start-async",
      "name": "Start Async Task",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [470, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "thread_id",
              "value": "={{ $json.thread_id }}"
            }
          ]
        }
      },
      "id": "store-thread",
      "name": "Store Thread ID",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [690, 300]
    },
    {
      "parameters": {
        "unit": "seconds",
        "amount": 5
      },
      "id": "wait",
      "name": "Wait 5s",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1.1,
      "position": [910, 300]
    },
    {
      "parameters": {
        "url": "=http://hx-lang-server.hx.dev.local:8100/status/{{ $('Store Thread ID').item.json.thread_id }}",
        "authentication": "none",
        "options": {}
      },
      "id": "check-status",
      "name": "Check Status",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [1130, 300]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.status }}",
              "operation": "equals",
              "value2": "completed"
            }
          ]
        }
      },
      "id": "is-completed",
      "name": "Is Completed?",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2,
      "position": [1350, 300]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "final_response",
              "value": "={{ $json.result.response }}"
            },
            {
              "name": "thread_id",
              "value": "={{ $json.thread_id }}"
            },
            {
              "name": "iterations",
              "value": "={{ $json.iteration_count }}"
            }
          ]
        }
      },
      "id": "extract-result",
      "name": "Extract Result",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [1570, 200]
    }
  ],
  "connections": {
    "Setup": {
      "main": [[{"node": "Start Async Task", "type": "main", "index": 0}]]
    },
    "Start Async Task": {
      "main": [[{"node": "Store Thread ID", "type": "main", "index": 0}]]
    },
    "Store Thread ID": {
      "main": [[{"node": "Wait 5s", "type": "main", "index": 0}]]
    },
    "Wait 5s": {
      "main": [[{"node": "Check Status", "type": "main", "index": 0}]]
    },
    "Check Status": {
      "main": [[{"node": "Is Completed?", "type": "main", "index": 0}]]
    },
    "Is Completed?": {
      "main": [
        [{"node": "Extract Result", "type": "main", "index": 0}],
        [{"node": "Wait 5s", "type": "main", "index": 0}]
      ]
    }
  },
  "tags": ["hx-lang-server", "async", "polling"]
}
```

### Step 5: Create Error Handling Workflow

Create file: `/opt/hx-lang-server/docs/examples/n8n-workflows/05-error-handling.json`

```json
{
  "name": "HX-Lang-Server: Error Handling",
  "nodes": [
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "valid_query",
              "value": "What is LangGraph?"
            },
            {
              "name": "empty_query",
              "value": ""
            },
            {
              "name": "invalid_thread_id",
              "value": "00000000-0000-0000-0000-000000000000"
            }
          ]
        }
      },
      "id": "test-cases",
      "name": "Test Cases",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://hx-lang-server.hx.dev.local:8100/invoke",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "query",
              "value": "={{ $json.empty_query }}"
            }
          ]
        },
        "options": {
          "response": {
            "response": {
              "fullResponse": true,
              "neverError": true
            }
          }
        }
      },
      "id": "test-empty-query",
      "name": "Test Empty Query",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [470, 200]
    },
    {
      "parameters": {
        "conditions": {
          "number": [
            {
              "value1": "={{ $json.statusCode }}",
              "operation": "equals",
              "value2": 422
            }
          ]
        }
      },
      "id": "check-validation-error",
      "name": "Check Validation Error",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2,
      "position": [690, 200]
    },
    {
      "parameters": {
        "url": "=http://hx-lang-server.hx.dev.local:8100/status/{{ $('Test Cases').item.json.invalid_thread_id }}",
        "options": {
          "response": {
            "response": {
              "fullResponse": true,
              "neverError": true
            }
          }
        }
      },
      "id": "test-invalid-thread",
      "name": "Test Invalid Thread",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1,
      "position": [470, 400]
    },
    {
      "parameters": {
        "conditions": {
          "number": [
            {
              "value1": "={{ $json.statusCode }}",
              "operation": "equals",
              "value2": 404
            }
          ]
        }
      },
      "id": "check-not-found",
      "name": "Check Not Found",
      "type": "n8n-nodes-base.if",
      "typeVersion": 2,
      "position": [690, 400]
    },
    {
      "parameters": {
        "values": {
          "string": [
            {
              "name": "test_result",
              "value": "All error cases handled correctly"
            }
          ]
        }
      },
      "id": "success",
      "name": "Success",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [910, 300]
    }
  ],
  "connections": {
    "Test Cases": {
      "main": [
        [
          {"node": "Test Empty Query", "type": "main", "index": 0},
          {"node": "Test Invalid Thread", "type": "main", "index": 0}
        ]
      ]
    },
    "Test Empty Query": {
      "main": [[{"node": "Check Validation Error", "type": "main", "index": 0}]]
    },
    "Check Validation Error": {
      "main": [[{"node": "Success", "type": "main", "index": 0}]]
    },
    "Test Invalid Thread": {
      "main": [[{"node": "Check Not Found", "type": "main", "index": 0}]]
    },
    "Check Not Found": {
      "main": [[{"node": "Success", "type": "main", "index": 0}]]
    }
  },
  "tags": ["hx-lang-server", "error-handling", "testing"]
}
```

### Step 6: Create README for Workflow Examples

Create file: `/opt/hx-lang-server/docs/examples/n8n-workflows/README.md`

```markdown
# n8n Workflow Examples for HX-Lang-Server

This directory contains example n8n workflows demonstrating various integration patterns with hx-lang-server's LangGraph orchestration API.

## Available Examples

### 1. Simple Query (`01-simple-query.json`)
**Complexity:** Beginner
**Use Case:** Basic agent invocation

Demonstrates the simplest integration pattern: send a query, receive a response.

**Key Concepts:**
- HTTP Request node configuration
- Request body formatting
- Response data extraction

### 2. Multi-Turn Conversation (`02-multi-turn-conversation.json`)
**Complexity:** Intermediate
**Use Case:** Context-aware conversation

Shows how to maintain conversation context across multiple queries using thread_id.

**Key Concepts:**
- Thread ID extraction and storage
- Conversation continuity
- Sequential query chaining

### 3. Async with Webhook (`03-async-with-webhook.json`)
**Complexity:** Advanced
**Use Case:** Long-running tasks with callback

Demonstrates webhook callback pattern for async operations.

**Key Concepts:**
- Webhook node setup
- Callback URL registration
- Async result delivery

### 4. Async with Polling (`04-async-with-polling.json`)
**Complexity:** Intermediate
**Use Case:** Long-running tasks with status polling

Alternative to webhooks using status polling pattern.

**Key Concepts:**
- Async task initiation
- Status polling with Loop node
- Result extraction from status response

### 5. Error Handling (`05-error-handling.json`)
**Complexity:** Intermediate
**Use Case:** Robust error handling

Demonstrates handling of various error scenarios (422, 404, 500).

**Key Concepts:**
- Full response mode (neverError)
- Status code checking
- Error branching logic

### 6. RAG Document Query (`06-rag-document-query.json`)
**Complexity:** Advanced
**Use Case:** Knowledge base retrieval

Shows integration with RAG agent for document-based queries.

**Key Concepts:**
- Query classification for RAG routing
- Document retrieval workflow
- Context-aware responses

### 7. Code Generation (`07-code-generation.json`)
**Complexity:** Advanced
**Use Case:** Code generation with specialized LLM

Demonstrates routing code-related queries to specialized Ollama model.

**Key Concepts:**
- Query classification for code routing
- Code agent worker usage
- Formatted code output

## Importing Workflows

### Method 1: Import from File

1. Open n8n at http://hx-n8n-server.hx.dev.local:5678
2. Click **Workflows** → **Import from File**
3. Select JSON file from this directory
4. Click **Import**

### Method 2: Copy-Paste JSON

1. Open n8n workflow editor
2. Click **⋮** (three dots) → **Import from JSON**
3. Paste JSON content
4. Click **Import**

## Prerequisites

- n8n server operational at hx-n8n-server.hx.dev.local:5678
- hx-lang-server operational at hx-lang-server.hx.dev.local:8100
- Network connectivity between n8n and hx-lang-server

## Customizing Workflows

### Changing Query Text

Replace the `query` field value in Set or HTTP Request nodes:

```json
{
  "name": "query",
  "value": "Your custom question here"
}
```

### Adjusting Polling Interval

Change the Wait node `amount` parameter (in seconds):

```json
{
  "parameters": {
    "unit": "seconds",
    "amount": 10
  }
}
```

### Adding Workflow Metadata

Include workflow_id and execution_id for tracking:

```json
{
  "name": "workflow_id",
  "value": "={{ $workflow.id }}"
},
{
  "name": "execution_id",
  "value": "={{ $execution.id }}"
}
```

## Testing Workflows

### 1. Manual Testing

1. Import workflow
2. Click **Execute Workflow** button
3. Review execution results in right panel
4. Check node outputs for data flow

### 2. Automated Testing

Use n8n CLI for automated testing:

```bash
# Install n8n CLI
npm install -g n8n

# Execute workflow
n8n execute --workflow 01-simple-query.json

# View execution results
n8n executions:list
```

## Troubleshooting

### "Connection refused" Error

**Cause:** hx-lang-server not reachable
**Solution:** Verify service is running:

```bash
curl http://hx-lang-server.hx.dev.local:8100/health
```

### "Thread not found" Error

**Cause:** Thread ID expired or invalid
**Solution:** Start new conversation without thread_id

### Workflow Execution Timeout

**Cause:** Default timeout too short
**Solution:** Increase timeout in HTTP Request node options:

```json
{
  "options": {
    "timeout": 120000
  }
}
```

## Best Practices

1. **Error Handling:** Always use `neverError: true` and check status codes
2. **Timeouts:** Set appropriate timeouts based on expected response time
3. **Thread Management:** Store thread_id for conversation continuity
4. **Logging:** Include workflow_id and execution_id in requests
5. **Testing:** Test workflows with simple queries before complex operations

## Support

- **API Documentation:** http://hx-lang-server.hx.dev.local:8100/docs
- **Custom Node Docs:** `/opt/hx-lang-server/docs/n8n-custom-node-requirements.md`
- **Quick Start Guide:** `/opt/hx-lang-server/docs/n8n-integration-quick-start.md`

## Contributing

To add new workflow examples:

1. Create workflow in n8n UI
2. Export as JSON
3. Add to this directory with sequential numbering
4. Update this README with description
5. Include tags for categorization

---

**Version:** 1.0
**Last Updated:** 2025-12-04
**Maintained By:** Isabella (n8n Workflow Automation SME)
```

---

## Deliverables

| Deliverable | Path | Description |
|-------------|------|-------------|
| Simple query | `/opt/hx-lang-server/docs/examples/n8n-workflows/01-simple-query.json` | Basic invocation |
| Multi-turn | `/opt/hx-lang-server/docs/examples/n8n-workflows/02-multi-turn-conversation.json` | Conversation continuity |
| Async webhook | `/opt/hx-lang-server/docs/examples/n8n-workflows/03-async-with-webhook.json` | Webhook callbacks |
| Async polling | `/opt/hx-lang-server/docs/examples/n8n-workflows/04-async-with-polling.json` | Status polling |
| Error handling | `/opt/hx-lang-server/docs/examples/n8n-workflows/05-error-handling.json` | Error scenarios |
| RAG query | `/opt/hx-lang-server/docs/examples/n8n-workflows/06-rag-document-query.json` | Document retrieval |
| Code generation | `/opt/hx-lang-server/docs/examples/n8n-workflows/07-code-generation.json` | Code agent usage |
| README | `/opt/hx-lang-server/docs/examples/n8n-workflows/README.md` | Documentation |

---

## Verification Steps

### Step 1: Validate JSON Syntax

```bash
# Validate all workflow JSON files
for file in /opt/hx-lang-server/docs/examples/n8n-workflows/*.json; do
  echo "Validating $file"
  jq empty "$file" && echo "✓ Valid" || echo "✗ Invalid"
done
```

### Step 2: Import and Test in n8n

```bash
# Access n8n UI
open http://hx-n8n-server.hx.dev.local:5678

# For each workflow:
# 1. Import workflow JSON
# 2. Click "Execute Workflow"
# 3. Verify nodes execute successfully
# 4. Check response data matches expectations
```

### Step 3: Test Simple Query Workflow

```bash
# Import 01-simple-query.json in n8n
# Execute workflow
# Verify output contains:
# - thread_id (UUID format)
# - response (non-empty string)
# - query_type (e.g., "general")
# - worker_used (e.g., "rag_agent")
```

### Step 4: Test Multi-Turn Conversation

```bash
# Import 02-multi-turn-conversation.json
# Execute workflow
# Verify:
# - Same thread_id used across all queries
# - Second query response references "Alice"
# - Third query response mentions "AI infrastructure"
```

---

## Acceptance Criteria

- [ ] 7 workflow examples created covering different patterns
- [ ] All workflow JSON files validate successfully
- [ ] README documentation complete with import instructions
- [ ] Simple query workflow executes successfully in n8n
- [ ] Multi-turn conversation maintains thread context
- [ ] Async polling workflow completes successfully
- [ ] Error handling workflow catches validation errors
- [ ] All workflows include descriptive tags
- [ ] Troubleshooting section addresses common issues
- [ ] Examples demonstrate sync, async, and error patterns

---

## Rollback Procedure

Not applicable (documentation only, no code changes)

---

## Notes

- **Workflow Tags:** Used for organization and searchability in n8n
- **Node Positions:** Adjusted for clear visual flow in n8n canvas
- **Parameter References:** Use n8n expression syntax `={{ $json.field }}`
- **Version Compatibility:** Workflows tested with n8n 1.x
- **Real-World Usage:** Examples based on actual use case requirements

---

**Created By:** Isabella (n8n Workflow Automation SME)
**Date:** 2025-12-04
**Specification Reference:** node-spec.md v2.1, Section: n8n Integration
