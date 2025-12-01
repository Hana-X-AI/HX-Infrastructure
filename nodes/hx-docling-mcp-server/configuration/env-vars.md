# Environment Variables: hx-docling-mcp-server

**Node Name**: hx-docling-mcp-server
**Node IP**: 192.168.10.217
**Created**: 2025-11-30
**Status**: Specification Complete - Ready for Deployment

---

## Overview

This document specifies all environment variables required for the hx-docling-mcp-server node. These variables are loaded from `/opt/docling-mcp/.env.production` during service startup.

**Deployment Location**: `/opt/docling-mcp/.env.production`

---

## Environment Variables

### Service Configuration

```bash
# Service Identity
SERVICE_NAME=docling-mcp-server
NODE_IP=192.168.10.217
NODE_FQDN=hx-docling-mcp-server.hx.dev.local
ENVIRONMENT=production

# MCP Server Configuration
MCP_SERVER_HOST=0.0.0.0
MCP_SERVER_PORT=8000
MCP_TRANSPORT=http  # Options: http, sse, stdio
LOG_LEVEL=INFO  # Options: DEBUG, INFO, WARNING, ERROR
```

### Integration Configuration

```bash
# LiteLLM Integration (Model & Inference Layer)
LITELLM_API_BASE=http://192.168.10.212:4000
LITELLM_API_KEY=  # Optional - currently not required

# Qdrant Integration (Vector Database)
QDRANT_HOST=192.168.10.207
QDRANT_PORT=6333
QDRANT_API_KEY=  # Optional - currently not required
QDRANT_COLLECTION_ENTITIES=hx_docling_mcp_entities
QDRANT_COLLECTION_RELATIONSHIPS=hx_docling_mcp_relationships

# Redis Integration (Caching Layer)
REDIS_HOST=192.168.10.210
REDIS_PORT=6379
REDIS_PASSWORD=  # Optional - currently not required
REDIS_DB=0

# PostgreSQL Integration (Metadata Storage)
POSTGRES_HOST=192.168.10.208
POSTGRES_PORT=5432
POSTGRES_DB=docling_mcp
POSTGRES_USER=docling_mcp
POSTGRES_PASSWORD=  # Loaded from vault/credentials.yml

# hx-literag-server Integration (Knowledge Graph)
LIGHTRAG_API_URL=http://192.168.10.220:8000
```

### Security Configuration

```bash
# Service Account
SAMBA_ACCOUNT=docling-mcp@hx.dev.local
SAMBA_DOMAIN=hx.dev.local
SAMBA_PASSWORD=  # Loaded from vault/credentials.yml

# Vault Configuration
VAULT_PASSWORD_FILE=/opt/docling-mcp/vault/.vault_password
VAULT_CREDENTIALS_FILE=/opt/docling-mcp/vault/credentials.yml
```

### Processing Configuration

```bash
# Document Processing
MAX_DOCUMENT_SIZE_MB=100
SUPPORTED_FORMATS=pdf,docx,pptx,xlsx,html,md,txt,jpg,png
OCR_ENABLED=true
OCR_LANGUAGE=eng

# Knowledge Graph Configuration
ENABLE_KNOWLEDGE_GRAPH=true
ENTITY_EXTRACTION_MODEL=litellm  # Use LiteLLM for entity extraction
CHUNK_SIZE=4096
CHUNK_OVERLAP=512
```

### Performance Configuration

```bash
# Concurrency and Resource Limits
MAX_CONCURRENT_JOBS=10
WORKER_THREADS=4
MEMORY_LIMIT_GB=16

# Timeouts
REQUEST_TIMEOUT_SECONDS=300
LITELLM_TIMEOUT_SECONDS=60
QDRANT_TIMEOUT_SECONDS=30
REDIS_TIMEOUT_SECONDS=10
```

---

## Required Variables

The following variables MUST be set for the service to start:

1. **Service Identity**: `SERVICE_NAME`, `NODE_IP`, `ENVIRONMENT`
2. **LiteLLM**: `LITELLM_API_BASE` (default: http://192.168.10.212:4000)
3. **Qdrant**: `QDRANT_HOST` (default: 192.168.10.207)
4. **Redis**: `REDIS_HOST` (default: 192.168.10.210)
5. **PostgreSQL**: `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
6. **LightRAG**: `LIGHTRAG_API_URL` (default: http://192.168.10.220:8000)

---

## Optional Variables

The following variables have defaults and can be omitted:

- `MCP_SERVER_PORT` (default: 8000)
- `LOG_LEVEL` (default: INFO)
- `MAX_CONCURRENT_JOBS` (default: 10)
- `CHUNK_SIZE` (default: 4096)
- All authentication tokens (currently not required for internal services)

---

## Deployment Notes

### Loading from Vault

Sensitive credentials (POSTGRES_PASSWORD, SAMBA_PASSWORD) should be loaded from the Ansible Vault:

```bash
# Decrypt vault
ansible-vault view /opt/docling-mcp/vault/credentials.yml --vault-password-file=/opt/docling-mcp/vault/.vault_password

# Extract values and set in .env.production
POSTGRES_PASSWORD=$(ansible-vault view /opt/docling-mcp/vault/credentials.yml --vault-password-file=/opt/docling-mcp/vault/.vault_password | grep samba_password | awk '{print $2}' | tr -d '"')
```

### Validation

Before starting the service, validate all required variables are set:

```bash
source /opt/docling-mcp/.env.production
python3 -c "
import os
required = ['SERVICE_NAME', 'NODE_IP', 'LITELLM_API_BASE', 'QDRANT_HOST', 'REDIS_HOST', 'POSTGRES_HOST', 'LIGHTRAG_API_URL']
missing = [v for v in required if not os.getenv(v)]
if missing:
    print(f'ERROR: Missing required variables: {missing}')
    exit(1)
print('SUCCESS: All required variables set')
"
```

---

**Template Version**: 1.0
**Last Updated**: 2025-11-30
**Deployment Status**: Ready for production deployment
