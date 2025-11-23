# Service Architecture Standards
## Architecture and Design Standards for HX-Infrastructure Services

**Document Type:** Standard - Architecture & Design Patterns
**Version:** 1.1
**Date:** 2025-11-21
**Status:** ✅ APPROVED - Required for All Service Deployments
**Location:** `/home/agent0/HX-Infrastructure/standards/architecture-standards.md`
**Previous Version:** 1.0 → 1.1 (comprehensive metadata, infrastructure integration, procedure alignment)

---

## Document Purpose

This document establishes architecture standards for all services deployed in HX-Infrastructure. Every service must document its architecture following these standards to ensure consistency, maintainability, proper integration, and compliance with infrastructure philosophy.

### Target Audience
- **Alex Rivera (Platform Architect):** Primary authority for architecture decisions and ADR creation
- **Service Architects:** Developers designing service architecture
- **Agent Zero (CC):** Validates architecture documentation during specification phase
- **All Agents:** Reference for architecture documentation requirements

### Scope
- Architecture documentation requirements
- API design standards (REST, GraphQL, gRPC, WebSocket)
- Integration points and communication patterns
- Data model and storage standards
- Security architecture requirements
- Scalability and performance considerations
- Deployment architecture (aligned with infrastructure philosophy)

---

## Table of Contents

1. [Architecture Documentation Requirements](#1-architecture-documentation-requirements)
2. [API Design Standards](#2-api-design-standards)
3. [Integration Points Standards](#3-integration-points-standards)
4. [Data Model Standards](#4-data-model-standards)
5. [Service Communication Patterns](#5-service-communication-patterns)
6. [Security Architecture](#6-security-architecture)
7. [Scalability and Performance](#7-scalability-and-performance)
8. [Deployment Architecture](#8-deployment-architecture)

---

## 1. Architecture Documentation Requirements

### 1.1 Required Architecture Documentation

Every service MUST include:

**Location**: `services/[operational|non-operational]/[service]/deployment/architecture.md`

**Required Sections**:
1. **Service Overview**
   - Purpose and responsibilities
   - Service boundaries
   - Key capabilities

2. **System Context**
   - External dependencies
   - Upstream consumers
   - Downstream dependencies

3. **Component Architecture**
   - Internal components
   - Component interactions
   - Technology stack

4. **Data Architecture**
   - Data models
   - Data flow
   - Storage requirements

5. **API Architecture** (if service exposes APIs)
   - API design
   - Endpoints
   - Authentication/authorization

6. **Integration Architecture**
   - Integration points
   - Communication protocols
   - Error handling

7. **Deployment Architecture**
   - Node placement
   - Resource requirements
   - Network configuration

8. **Security Architecture**
   - Authentication mechanisms
   - Authorization model
   - Data protection

---

### 1.2 Architecture Diagram Requirements

**All services MUST include**:

1. **System Context Diagram**
   - Service and its external dependencies
   - Data flow direction
   - Communication protocols

2. **Component Diagram**
   - Internal service components
   - Component relationships
   - Technology labels

3. **Deployment Diagram** (if complex)
   - Node placement
   - Network zones
   - Resource allocation

**Diagram Format**:
- Preferred: Mermaid (markdown-compatible)
- Acceptable: PlantUML, draw.io, Lucidchart
- Storage: `services/[service]/deployment/diagrams/`

---

## 2. API Design Standards

### 2.1 API Types

**Supported API Types**:
- REST (JSON) - Primary choice for most services
- GraphQL - For complex data queries
- gRPC - For high-performance service-to-service
- WebSocket - For real-time bidirectional communication

**API Type Selection Criteria**:

| Use Case | Recommended Type | Rationale |
|----------|-----------------|-----------|
| CRUD operations | REST | Simple, widely supported |
| Complex queries | GraphQL | Flexible, reduces over-fetching |
| High-performance microservices | gRPC | Binary protocol, type safety |
| Real-time updates | WebSocket | Bidirectional, low latency |

---

### 2.2 REST API Standards

**URL Structure**:
```
https://[service].[domain]/api/v[version]/[resource]/[identifier]
```

**Examples**:
```
https://api-gateway.hx.dev.local/api/v1/users/12345
https://database-service.hx.dev.local/api/v1/records?filter=active
```

**HTTP Methods**:
- `GET` - Retrieve resource(s)
- `POST` - Create new resource
- `PUT` - Update entire resource
- `PATCH` - Update partial resource
- `DELETE` - Delete resource

**Status Codes** (use standard HTTP):
- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Invalid request
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `500 Internal Server Error` - Server error

**Response Format**:
```json
{
  "status": "success",
  "data": {
    // Resource data
  },
  "metadata": {
    "timestamp": "2025-11-15T10:30:00Z",
    "version": "v1"
  }
}
```

**Error Response Format**:
```json
{
  "status": "error",
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "User with ID 12345 not found",
    "details": {}
  },
  "metadata": {
    "timestamp": "2025-11-15T10:30:00Z",
    "request_id": "abc-123-def"
  }
}
```

---

### 2.3 API Versioning

**Version Strategy**: URL path versioning

**Format**: `/api/v[major]/[resource]`

**Version Lifecycle**:
- v1 → v2: Maintain v1 for 6 months minimum
- Deprecation warning: 3 months before removal
- Breaking changes: Require new major version

**Version Documentation**:
```markdown
## API Versions

### v2 (Current)
- Status: Active
- Introduced: 2025-11-15
- Deprecation: None

### v1 (Deprecated)
- Status: Deprecated
- Deprecation Date: 2025-08-15
- End of Life: 2026-02-15
- Migration Guide: [link]
```

---

### 2.4 API Authentication & Authorization

**Authentication Methods**:

1. **API Keys** (Service-to-Service)
   - Header: `X-API-Key: [key]`
   - Use for: Internal service communication
   - Stored in: Service vault

2. **OAuth 2.0** (User Authentication)
   - Bearer tokens
   - Use for: User-facing APIs
   - Token expiration: 1 hour (access), 30 days (refresh)

3. **mTLS** (Mutual TLS)
   - Client certificates
   - Use for: High-security service communication
   - Certificate rotation: Every 90 days

**Authorization Model**:
- Role-Based Access Control (RBAC)
- Principle of least privilege
- Document required roles/permissions per endpoint

---

### 2.5 API Documentation

**Required API Documentation**:

**Location**: `services/[service]/deployment/api-documentation.md`

**Format**: OpenAPI 3.0 specification

**Required Elements**:
```yaml
openapi: 3.0.0
info:
  title: [Service] API
  version: 1.0.0
  description: [Service description]
  contact:
    name: [Team]
    email: [email]

servers:
  - url: https://[service].hx.dev.local/api/v1
    description: Development

paths:
  /[resource]:
    get:
      summary: [Description]
      parameters: [...]
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema: [...]
```

---

## 3. Integration Points Standards

### 3.1 Integration Documentation

**Every integration point MUST be documented**:

**Location**: `services/[service]/deployment/integrations.md`

**Required Information per Integration**:

```markdown
## Integration: [System Name]

### Integration Type
[Synchronous | Asynchronous | Event-Driven | Batch]

### Communication Protocol
[REST API | gRPC | Message Queue | Database | File Transfer]

### Direction
[Inbound | Outbound | Bidirectional]

### Data Format
[JSON | XML | Protobuf | CSV | Binary]

### Authentication
[Method and credentials location]

### Error Handling
[Retry logic, fallback behavior, error propagation]

### Performance Requirements
[Latency, throughput, batch size]

### Dependencies
[What this service depends on from the integration]

### Contract/Schema
[Link to API spec, message schema, or data contract]
```

---

### 3.2 Integration Patterns

**Synchronous Integrations**:
- Use for: Real-time queries, CRUD operations
- Timeout: 30 seconds maximum
- Retry: 3 attempts with exponential backoff
- Circuit breaker: Required for external systems

**Asynchronous Integrations**:
- Use for: Non-blocking operations, event processing
- Message queue: Redis, RabbitMQ, Kafka
- Acknowledgment: Required
- Dead letter queue: Required for failed messages

**Event-Driven Integrations**:
- Use for: Loose coupling, pub/sub patterns
- Event schema: JSON, versioned
- Event store: Required for audit
- Idempotency: Required

---

### 3.3 Integration Testing Requirements

**All integrations MUST have**:

1. **Contract Tests**
   - Verify API contract compatibility
   - Run on every deployment
   - Located: `services/[service]/tests/test-suite/integration/`

2. **Integration Tests**
   - Test end-to-end integration flow
   - Include error scenarios
   - Mock external systems in test environment

3. **Health Checks**
   - Verify integration availability
   - Check authentication validity
   - Monitor regularly

---

## 4. Data Model Standards

### 4.1 Data Model Documentation

**Location**: `services/[service]/deployment/data-model.md`

**Required Sections**:

```markdown
## Entities

### Entity: [Name]

**Purpose**: [What this entity represents]

**Attributes**:
| Attribute | Type | Required | Description | Constraints |
|-----------|------|----------|-------------|-------------|
| id | UUID | Yes | Unique identifier | Primary key |
| name | String | Yes | Entity name | Max 255 chars |
| created_at | Timestamp | Yes | Creation time | Auto-generated |

**Relationships**:
- [Relationship type] with [Other Entity]
- [1:1 | 1:N | N:M]

**Validation Rules**:
- [Rule 1]
- [Rule 2]

**Indexes**:
- Primary: id
- Secondary: [field]

## Data Flow

[Description of how data moves through the system]

## Data Retention

[Retention policy and archival strategy]
```

---

### 4.2 Database Standards

**Database Selection**:

| Use Case | Database | Rationale |
|----------|----------|-----------|
| Relational data | PostgreSQL | ACID, rich features |
| Document store | MongoDB | Flexible schema |
| Key-value cache | Redis | High performance |
| Time series | InfluxDB | Optimized for metrics |
| Graph data | Neo4j | Relationship queries |

**Naming Conventions**:
- Tables: `snake_case`, plural (e.g., `user_accounts`)
- Columns: `snake_case` (e.g., `created_at`)
- Indexes: `idx_[table]_[column]` (e.g., `idx_users_email`)
- Foreign keys: `fk_[table]_[referenced_table]`

**Schema Migrations**:
- Tool: Flyway, Liquibase, or framework-specific
- Versioning: Sequential numbering
- Rollback: Always include rollback script
- Testing: Test on staging before production

---

## 5. Service Communication Patterns

### 5.1 Synchronous Communication

**Use When**:
- Immediate response required
- Simple request/response
- Low latency critical

**Implementation**:
- REST API (primary)
- gRPC (high performance)
- Direct database access (avoid if possible)

**Requirements**:
- Timeout handling
- Retry logic
- Circuit breaker
- Health checks

---

### 5.2 Asynchronous Communication

**Use When**:
- Fire and forget
- Long-running operations
- Decoupled services

**Implementation**:
- Message queue (Redis, RabbitMQ)
- Event stream (Kafka)
- Background jobs (Celery)

**Requirements**:
- Message acknowledgment
- Dead letter queue
- Idempotency
- Monitoring

---

### 5.3 Event-Driven Architecture

**Event Types**:

1. **Domain Events**
   - Represent state changes
   - Past tense (e.g., `UserCreated`, `OrderShipped`)
   - Immutable

2. **Integration Events**
   - Cross-boundary communication
   - Versioned
   - Schema-validated

**Event Schema**:
```json
{
  "event_id": "uuid",
  "event_type": "UserCreated",
  "event_version": "1.0",
  "timestamp": "2025-11-15T10:30:00Z",
  "source_service": "user-service",
  "data": {
    // Event-specific payload
  },
  "metadata": {
    "correlation_id": "abc-123",
    "causation_id": "def-456"
  }
}
```

---

## 6. Security Architecture

### 6.1 Authentication Architecture

**Required Elements**:
- Authentication method documented
- Credential storage (vault location)
- Token/session management
- Password policies (if applicable)

**Standard Patterns**:
```markdown
## Authentication

### Method
[API Key | OAuth 2.0 | mTLS | LDAP]

### Implementation
[How authentication is implemented]

### Credentials
Stored in: `services/[service]/vault/secrets.yml`

### Token Expiration
Access: [duration]
Refresh: [duration]
```

---

### 6.2 Authorization Architecture

**Required Elements**:
- Authorization model (RBAC, ABAC)
- Role definitions
- Permission matrix
- Enforcement points

**Permission Matrix Example**:

| Role | Resource | Create | Read | Update | Delete |
|------|----------|--------|------|--------|--------|
| Admin | Users | ✅ | ✅ | ✅ | ✅ |
| User | Users | ❌ | ✅ (self) | ✅ (self) | ❌ |
| Service | Users | ✅ | ✅ | ✅ | ❌ |

---

### 6.3 Data Protection

**Encryption Requirements**:
- **Data at Rest**: Encrypt sensitive data (PII, credentials, financial)
- **Data in Transit**: TLS 1.2+ for all external communication
- **Data in Use**: Memory encryption for highly sensitive data

**Sensitive Data Handling**:
```markdown
## Sensitive Data

### Classified as Sensitive
- User passwords (hashed)
- API keys (encrypted)
- Personal information (encrypted)
- Financial data (encrypted)

### Storage
- Database: Column-level encryption
- Files: File-level encryption
- Backups: Full-disk encryption

### Access
- Audit logged
- Role-based access
- Encryption key rotation: Quarterly
```

---

## 7. Scalability and Performance

### 7.1 Performance Requirements

**Document per Service**:

```markdown
## Performance Requirements

### Response Time
- p50: < [X]ms
- p95: < [Y]ms
- p99: < [Z]ms

### Throughput
- Requests per second: [N]
- Concurrent connections: [M]

### Resource Usage
- CPU: < [X]%
- Memory: < [Y]GB
- Disk I/O: < [Z] IOPS
```

---

### 7.2 Scalability Architecture

**Horizontal Scaling**:
- Stateless service design
- Load balancing strategy
- Session management (external store)
- Database read replicas

**Vertical Scaling**:
- Resource limits
- Upgrade path
- Capacity planning

**Caching Strategy**:
```markdown
## Caching

### Cache Layers
1. Application cache (in-memory)
2. Distributed cache (Redis)
3. CDN (if applicable)

### Cache Invalidation
- Strategy: [TTL | Event-based | Manual]
- TTL: [duration]

### Cache Keys
- Format: `[service]:[resource]:[id]`
- Example: `user-service:user:12345`
```

---

## 8. Deployment Architecture

### 8.1 Deployment Topology

**Document**:
```markdown
## Deployment Topology

### Node Placement
Service deployed on: [node-name]

### Resource Allocation
- CPU: [cores]
- Memory: [GB]
- Storage: [GB]
- Network: [configuration]

### Port Mapping
| Port | Protocol | Purpose | Access |
|------|----------|---------|--------|
| 8080 | HTTP | API | Internal |
| 8443 | HTTPS | API (TLS) | External |

### Service Dependencies
- Depends on: [services]
- Required by: [services]
```

---

### 8.2 High Availability Architecture

**If HA Required**:

```markdown
## High Availability

### HA Strategy
[Active-Active | Active-Passive | N+1 Redundancy]

### Failover
- Automatic: [Yes/No]
- Failover time: [duration]
- Data consistency: [Eventual | Strong]

### Load Balancing
- Method: [Round-robin | Least connections | IP hash]
- Health check: [endpoint and frequency]

### State Management
- Session storage: [Redis | Database | Sticky sessions]
- Shared state: [How state is shared across instances]
```

---

## Architecture Review Checklist

**Before service promotion to operational**:

- [ ] Architecture document complete
- [ ] System context diagram included
- [ ] Component diagram included
- [ ] API documentation complete (if applicable)
- [ ] Integration points documented
- [ ] Data model documented
- [ ] Security architecture defined
- [ ] Performance requirements specified
- [ ] Deployment topology documented
- [ ] Reviewed by architecture team
- [ ] Aligns with constitution principles

---

## Infrastructure Philosophy Integration

Architecture standards align with HX-Infrastructure philosophy:

**Deployment Architecture (Section 8):**
- All deployment architecture must specify bare-metal deployment (Ubuntu 24.04 LTS).
- systemd service management required for all services.
- Manual deployment procedures documented (no automation playbooks).
- Ansible Vault for all credentials.

**Service Communication:**
- Services communicate over internal network (192.168.10.0/24)
- DNS resolution via hx-dc-server (Samba AD)
- TLS certificates from hx-ca-server (internal CA)

**Integration with Procedures:**
- Architecture documented during spec-workflow.md (Phase 2)
- Alex Rivera reviews all architecture documents
- Architecture Decision Records (ADRs) required for significant decisions

---

## Related Documents

**Standards Documentation:**
- `naming-conventions.md` - File and directory naming for architecture artifacts
- `deployment-requirements.md` - Infrastructure philosophy deployment standards (bare-metal, systemd, manual procedures)
- `testing-requirements.md` - Testing architecture and coverage requirements
- `documentation-requirements.md` - Architecture documentation format standards
- `credentials-vault-management.md` - Ansible Vault architecture for credentials

**Procedure Documentation:**
- `/home/agent0/HX-Infrastructure/procedures/spec-workflow.md` - Architecture documented in Phase 2 (specification)
- `/home/agent0/HX-Infrastructure/procedures/charter-workflow.md` - Architecture considerations in charter
- `/home/agent0/HX-Infrastructure/procedures/core-project-team.md` - Alex Rivera's role as platform architect

**Command Documentation:**
- `.claude/commands/agents/cc-orchestrate-alex.md` - Alex Rivera orchestration for architecture decisions
- `.claude/commands/workflows/` - Workflow commands enforce architecture documentation

**Agent Profiles:**
- `.claude/agents/alex.md` - Alex Rivera (Platform Architect) - Primary architecture authority

**Governance:**
- `/home/agent0/HX-Infrastructure/constitution.md` - Infrastructure principles and philosophy
- `/home/agent0/HX-Infrastructure/README.md` - Repository overview

---

## Version History

| Version | Date | Changes | Lines Changed | Author |
|---------|------|---------|---------------|--------|
| 1.0 | 2025-11-15 | Initial architecture standards with comprehensive API, integration, data, security, and deployment standards | 737 lines | HX-Infrastructure Team |
| 1.1 | 2025-11-21 | Added comprehensive metadata, infrastructure philosophy integration, procedure alignment, related documents, version history | +43 lines | Agent Zero (CC) |

**Key Updates in v1.1:**
- Added comprehensive document metadata header (Type, Version, Date, Status, Location)
- Added Document Purpose and Target Audience sections
- Added Infrastructure Philosophy Integration section (bare-metal, systemd, manual procedures)
- Added service communication standards (DNS, TLS, internal network)
- Expanded Related Documents with procedures, commands, agent profiles
- Added version history table (this table)
- Maintained 100% backward compatibility with v1.0

**Backward Compatibility:** 100% - All v1.0 architecture standards unchanged, only documentation enhancements added

---

## Document Maintenance

**Document Type:** Standard - Architecture & Design Patterns
**Status:** APPROVED - Required for All Service Deployments
**Maintained By:** Alex Rivera (Platform Architect) and HX-Infrastructure Team
**Review Frequency:** Annual (or when architecture patterns evolve)
**Last Review:** 2025-11-21
**Next Review:** 2026-11-21

**Update Triggers:**
- New architecture patterns adopted
- New API standards required
- Infrastructure philosophy changes
- Integration pattern updates
- Security requirement changes
- Performance standard updates

**Architecture Review Process:**
- Alex Rivera reviews all architecture documents
- ADRs required for significant architecture decisions
- Architecture compliance verified during specification phase (spec-workflow.md)

---

**End of Architecture Standards**

*This standard defines architecture and design requirements for all HX-Infrastructure services. Architecture documentation is mandatory during specification phase and must align with infrastructure philosophy (bare-metal, systemd, manual procedures, Ansible Vault). Alex Rivera serves as primary architecture authority and reviews all architecture decisions.*
