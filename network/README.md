# HX-Infrastructure Network Documentation

**Purpose:** Complete network architecture, topology, and operational procedures
**Status:** ACTIVE - Production network reference
**Last Updated:** 2025-11-21

---

## Directory Purpose

The `network/` directory contains comprehensive documentation of HX-Infrastructure's network architecture, topology, configuration, and operational procedures. This is the authoritative reference for all network-related design decisions, IP allocations, security zones, and troubleshooting procedures.

### Key Characteristics

**Comprehensive Network Documentation:**
- ✅ Complete network topology with diagrams
- ✅ Authoritative IP address allocation map
- ✅ Security zone architecture and trust boundaries
- ✅ Service port mappings and data flow patterns
- ✅ Systematic troubleshooting procedures
- ✅ Operational quality gates and testing procedures

**Current State Documentation:**
- Updated as network topology evolves
- Reflects actual production configuration
- Aligned with inventory and infrastructure standards
- Maintained by infrastructure team

---

## Network Documents

### network-topology.md
**File:** `/home/agent0/HX-Infrastructure/network/network-topology.md`
**Size:** 1,002 lines (37 KB)
**Version:** 1.1.1
**Last Updated:** 2025-11-15
**Status:** ✅ ACTIVE - Production Network Reference

**Purpose:**
Comprehensive network topology documentation for HX-Infrastructure's production network. Provides complete architectural reference including:
- High-level network overview and summary
- Physical network topology with Mermaid diagrams
- Complete IP address allocation map (30 nodes)
- Security zone architecture with trust boundaries
- Network quality gates and testing procedures
- Service port mapping reference
- Data flow patterns and integration diagrams
- High availability and disaster recovery planning
- Network expansion roadmap
- Operational network diagrams (SSH access, Kerberos auth)
- Network troubleshooting reference commands
- Configuration file examples (/etc/hosts, /etc/resolv.conf, network interfaces)

**Content Sections:**

1. **High-Level Network Overview**
   - Network: 192.168.10.0/24
   - Gateway: 192.168.10.1
   - DNS Server: 192.168.10.200 (hx-dc-server)
   - Domain: hx.dev.local
   - Total Hosts: 30 servers (28 deployed, 2 reserved)

2. **Physical Network Topology**
   - Complete Mermaid diagram showing all zones and connections
   - External network → Gateway → DMZ → Internal zones
   - 7 security zones mapped with all servers
   - Integration flow diagrams

3. **IP Address Allocation Map**
   - Complete table: IP → Hostname → FQDN → Zone → Status → Role
   - Current deployment: 25 operational, 3 in development, 2 reserved
   - Aligned with inventory/nodes.md

4. **Security Zone Architecture**
   - 7 zones with trust levels and dependencies:
     1. Identity & Trust Zone (.200-.203) - Highest trust
     2. DMZ / Ingress Layer (.202) - Medium trust
     3. Model & Inference Zone (.204-.206, .212) - Medium trust
     4. Data Plane Zone (.207-.211) - High trust
     5. Agentic & Toolchain Zone (.213-.220, .228-.229) - Medium trust
     6. Application Zone (.221-.223, .227) - Medium trust
     7. Integration & Governance Zone (.224-.226) - High trust
   - Trust relationships and authentication flows
   - Certificate chain architecture

5. **Network Quality Gates**
   - Pre-deployment requirements (foundation, connectivity, management)
   - Service deployment validation (network, security, documentation)
   - 100% compliance required before operational promotion

6. **Network Testing Procedures**
   - Connectivity test suite (DNS, reachability, ports, Kerberos, TLS)
   - Integration test suite (end-to-end application flows, data plane)
   - Performance baseline tests (latency, bandwidth)
   - Security validation tests (zone isolation)

7. **Service Port Mapping**
   - Complete port table for all critical services
   - Port allocation policy by service type
   - DNS/Auth: 53, 88, 389, 636
   - Web interfaces: 3000-3999, 5678, 8000-8999
   - LLM services: 11434, 4000
   - Data stores: 5432, 6333-6334, 6379
   - Monitoring: 9090-9099

8. **Data Flow Patterns**
   - User request flow: User → SSL → WebUI → LiteLLM → Ollama
   - Development flow: Developer → Dev → FastMCP → Tools → Storage
   - Data persistence: Vector, relational, cache patterns
   - Authentication flow: Kerberos ticket acquisition and validation

9. **High Availability and Disaster Recovery**
   - Current HA status (single points of failure identified)
   - Backup and recovery procedures with RPO/RTO targets
   - Mitigation strategies

10. **Network Expansion Roadmap**
    - Phase 1: Reserved deployments (coderabbit, shadcn)
    - Phase 2: High availability (secondary DC, PostgreSQL replication, Redis Sentinel)
    - Phase 3: Monitoring enhancement (Prometheus, Grafana, Alertmanager, tracing, logging)
    - Phase 4: Container orchestration (Kubernetes evaluation)
    - IP address reservation plan (.230-.254)

11. **Operational Network Diagrams**
    - SSH access pattern (administrative jump host via hx-control-node)
    - Kerberos authentication flow (8-step diagram)

12. **Network Troubleshooting Reference**
    - Connectivity verification commands
    - Common network issues table
    - Network health check script

13. **Appendix: Network Configuration Files**
    - Sample /etc/hosts (all 30 servers)
    - Sample /etc/resolv.conf
    - Sample /etc/network/interfaces

14. **Change Log**
    - Network changes history
    - Pending changes tracking

**Key Features:**
- Mermaid diagrams for visual clarity
- Complete IP allocation transparency
- Security zone segmentation documentation
- Comprehensive testing procedures
- Quality gates enforcement
- Disaster recovery planning

**Integration:**
Aligns perfectly with:
- `inventory/nodes.md` - IP allocations match exactly
- `standards/architecture-standards.md` - Service patterns comply
- `standards/testing-requirements.md` - Testing procedures documented

---

### network-troubleshooting.md
**File:** `/home/agent0/HX-Infrastructure/network/network-troubleshooting.md`
**Size:** 892 lines (22 KB)
**Version:** 1.0
**Last Updated:** 2025-11-15
**Status:** ✅ ACTIVE - Operational Procedures

**Purpose:**
Systematic troubleshooting procedures for diagnosing and resolving network issues in HX-Infrastructure production environment. Provides structured diagnostic approaches and resolution procedures.

**Content Sections:**

1. **Systematic Diagnostic Approach**
   - 6-step methodology:
     1. Define the problem
     2. Gather information
     3. Isolate the layer (OSI model)
     4. Test hypothesis
     5. Implement fix
     6. Prevent recurrence

2. **Layer-by-Layer Troubleshooting**
   - **Layer 1: Physical Connectivity**
     - Symptoms: Server unreachable, no network services
     - Diagnostics: Interface status, routing, physical link
     - Common causes: Interface down, cable unplugged, wrong IP
     - Resolutions: Bring interface up, restart networking, verify gateway

   - **Layer 2: DNS Resolution**
     - Symptoms: Cannot resolve hostnames, nslookup fails
     - Diagnostics: DNS resolution tests, /etc/resolv.conf check
     - Common causes: DNS server down, wrong nameserver, service not running
     - Resolutions: Fix resolv.conf, restart systemd-resolved, restart Samba DC

   - **Layer 3: Kerberos Authentication**
     - Symptoms: Auth failures, "Clock skew too great", SSO not working
     - Diagnostics: Time sync, ticket acquisition, KDC reachability
     - Common causes: Time skew >5min, KDC unreachable, wrong realm, no NTP
     - Resolutions: Synchronize time, configure NTP, restart timesyncd

   - **Layer 4: Port Connectivity**
     - Symptoms: "Connection refused", timeouts, services unreachable
     - Diagnostics: Port listening status, connectivity tests, firewall rules
     - Common service ports reference table
     - Common causes: Service not running, wrong interface, firewall, port conflict
     - Resolutions: Start service, check binding, allow ports, restart services

   - **Layer 5: TLS/SSL Issues**
     - Symptoms: Certificate errors, expired/untrusted certificates
     - Diagnostics: Certificate details, expiration, chain validation
     - Common causes: Certificate expired, not from trusted CA, wrong hostname
     - Resolutions: Request new certificate, install CA cert, restart service

3. **Common Network Issues**
   - **Issue 1: Server Cannot Reach Gateway**
     - Symptoms, diagnostics, expected output, resolution

   - **Issue 2: Domain Controller (hx-dc-server) Down**
     - Critical - affects all authentication
     - DNS, Kerberos, LDAP all impacted
     - Restart procedures, database check, backup restore

   - **Issue 3: Service Cannot Connect to Database**
     - PostgreSQL connectivity troubleshooting
     - pg_hba.conf configuration
     - Listen address configuration

   - **Issue 4: MCP Gateway Not Routing to Services**
     - FastMCP troubleshooting
     - Downstream service verification
     - Configuration updates

4. **Service-Specific Issues**
   - **Open WebUI (hx-webui-server)**
     - HTTPS access issues (reverse proxy)
     - LLM response issues (LiteLLM connection)
     - Authentication failures (Kerberos)

   - **LiteLLM API Gateway**
     - Models not loading
     - API requests failing

   - **Qdrant Vector Database**
     - Vector search not working
     - QMCP server connection issues

5. **Emergency Procedures**
   - **Emergency 1: Complete Network Outage**
     - Console access to control node
     - Network infrastructure checks
     - Restart networking

   - **Emergency 2: Domain Controller Failure**
     - Critical - affects all authentication
     - Samba AD DC restart procedures
     - Disk space checks
     - Database corruption handling
     - Backup restoration

   - **Emergency 3: Certificate Authority Failure**
     - Affects all TLS services
     - CA file verification
     - Backup restoration
     - Certificate refresh

6. **Diagnostic Tools Reference**
   - Essential network commands (ping, traceroute, nc, nmap, dig, nslookup)
   - Interface/routing commands (ip addr, ip route, ss, netstat)
   - TLS/SSL testing (openssl)
   - Kerberos testing (kinit, klist, kvno)
   - Service status commands (systemctl, journalctl, lsof)
   - Log viewing commands

7. **Escalation Path**
   - Documentation requirements
   - Defect report creation
   - Infrastructure team escalation
   - Emergency notification procedures

**Key Features:**
- Systematic diagnostic methodology (OSI model-based)
- Layer-by-layer troubleshooting guides
- Service-specific troubleshooting procedures
- Emergency response procedures
- Comprehensive command reference
- Escalation procedures

**Usage:**
Essential reference for:
- Network operators troubleshooting issues
- Infrastructure team resolving incidents
- Emergency response situations
- Training new operators

---

## Network Architecture Summary

### Network Configuration

**Network Segment:**
- Network: 192.168.10.0/24
- Subnet Mask: 255.255.255.0
- Gateway: 192.168.10.1
- Broadcast: 192.168.10.255
- Usable IPs: 192.168.10.2 - 192.168.10.254 (253 addresses)
- Allocated: 192.168.10.200-229 (30 servers)
- Available: 192.168.10.230-254 (25 addresses for expansion)

**DNS Configuration:**
- Primary DNS: 192.168.10.200 (hx-dc-server)
- Secondary DNS: 192.168.10.1 (Gateway fallback)
- Domain: hx.dev.local
- Search Domain: hx.dev.local

**Domain Configuration:**
- Domain: hx.dev.local
- Domain Controller: hx-dc-server (192.168.10.200)
- Kerberos Realm: HX.DEV.LOCAL
- Authentication: Kerberos/LDAP
- All servers domain-joined

---

## Security Zones

### Zone Hierarchy (Strictest → Most Permissive)

**1. Identity & Trust Zone (192.168.10.200-203)**
- **Trust Level:** Highest
- **Purpose:** Authentication, authorization, configuration management
- **Servers:** hx-dc-server, hx-ca-server, hx-control-node
- **Access:** Restricted - Admin only via hx-control-node
- **Key Services:** Samba AD, Kerberos, LDAP, DNS, Certificate Authority, Ansible

**2. DMZ / Ingress Layer (192.168.10.202)**
- **Trust Level:** Medium
- **Purpose:** TLS termination, reverse proxy, external ingress
- **Servers:** hx-ssl-server
- **Access:** Public HTTPS (443)
- **Key Services:** Nginx/Traefik reverse proxy

**3. Model & Inference Zone (192.168.10.204-206, 212)**
- **Trust Level:** Medium
- **Purpose:** LLM inference, embeddings, model gateway
- **Servers:** hx-ollama1/2/3-server, hx-litellm-server
- **Access:** Internal only, authenticated
- **Key Services:** Ollama, LiteLLM API Gateway

**4. Data Plane Zone (192.168.10.207-211)**
- **Trust Level:** High (persistent data)
- **Purpose:** Data storage, caching, vector databases
- **Servers:** hx-qdrant-server, hx-postgres-server, hx-redis-server, hx-qmcp-server, hx-qdrant-ui-server
- **Access:** Internal, authenticated services
- **Key Services:** PostgreSQL, Redis, Qdrant, QMCP

**5. Agentic & Toolchain Zone (192.168.10.213-220, 228-229)**
- **Trust Level:** Medium
- **Purpose:** MCP servers, workflow automation, tool orchestration
- **Servers:** hx-fastmcp-server, hx-n8n-server, hx-docling-server, hx-crawl4ai-server, etc.
- **Access:** Internal, orchestrated via Integration zone
- **Key Services:** FastMCP, N8N, Docling, Crawl4AI, LightRAG

**6. Application Zone (192.168.10.221-223, 227)**
- **Trust Level:** Medium
- **Purpose:** User-facing applications, dashboards, development
- **Servers:** hx-agui-server, hx-dev-server, hx-demo-server, hx-webui-server
- **Access:** Via DMZ (hx-ssl-server), authenticated users
- **Key Services:** Open WebUI, AG-UI, development environments

**7. Integration & Governance Zone (192.168.10.224-226)**
- **Trust Level:** High (control plane)
- **Purpose:** System integration, orchestration, observability
- **Servers:** hx-cc-server, hx-metric-server, hx-lang-server
- **Access:** Internal only, admin and system services
- **Key Services:** Claude Code, Prometheus, Grafana, LangGraph

---

## Data Flow Patterns

### Primary User Request Flow

```
User Workstation
    ↓ HTTPS (443)
Gateway (192.168.10.1)
    ↓
hx-ssl-server (192.168.10.202) - TLS Termination
    ↓ HTTP
hx-webui-server (192.168.10.227) - Open WebUI
    ↓ HTTP (4000)
hx-litellm-server (192.168.10.212) - API Gateway
    ↓ HTTP (11434)
hx-ollama1/2/3-server (192.168.10.204-206) - Model Inference
    ↑
Response flows back through same path
```

### Authentication Flow (All Services)

```
All Servers
    ↓ Request TGT (Port 88)
hx-dc-server (192.168.10.200) - Kerberos KDC
    ↓ Issue TGT
Client caches ticket
    ↓ Request service ticket
hx-dc-server (192.168.10.200) - KDC
    ↓ Issue service ticket
Target service validates ticket with KDC
    ↓
Access granted
```

### Data Persistence Flow

```
Services (Various)
    ↓
┌─────────────┬─────────────┬─────────────┐
│             │             │             │
▼             ▼             ▼             ▼
PostgreSQL    Redis         Qdrant        Object Storage
(5432)        (6379)        (6333)        (Future)
Relational    Cache         Vectors       Files/Blobs
```

---

## Critical Service Ports

| Service | Port(s) | Server | Protocol | Status |
|---------|---------|--------|----------|--------|
| DNS | 53 | hx-dc-server (.200) | TCP/UDP | ✅ |
| Kerberos KDC | 88 | hx-dc-server (.200) | TCP/UDP | ✅ |
| LDAP | 389, 636 | hx-dc-server (.200) | TCP | ✅ |
| HTTPS | 443 | hx-ssl-server (.202) | TCP | ✅ |
| PostgreSQL | 5432 | hx-postgres-server (.209) | TCP | ✅ |
| Redis | 6379 | hx-redis-server (.210) | TCP | ✅ |
| Redis UI | 8001 | hx-redis-server (.210) | TCP | ✅ |
| Qdrant API | 6333 | hx-qdrant-server (.207) | TCP | ✅ |
| Qdrant gRPC | 6334 | hx-qdrant-server (.207) | TCP | ✅ |
| Qdrant UI | 3000 | hx-qdrant-ui-server (.208) | TCP | ✅ |
| Ollama API | 11434 | hx-ollama1/2/3-server (.204-.206) | TCP | ✅ |
| LiteLLM API | 4000 | hx-litellm-server (.212) | TCP | ✅ |
| FastMCP Gateway | 8000 | hx-fastmcp-server (.213) | TCP | ✅ |
| N8N UI | 5678 | hx-n8n-server (.215) | TCP | ✅ |
| Open WebUI | 3000 | hx-webui-server (.227) | TCP | ✅ |
| Prometheus | 9090 | hx-metric-server (.225) | TCP | ✅ |
| Grafana | 3001 | hx-metric-server (.225) | TCP | ✅ |

---

## How to Use This Documentation

### For Network Planning
1. **Review network-topology.md** for complete architecture
2. **Check IP allocation map** for available addresses
3. **Understand security zones** before deploying new services
4. **Follow quality gates** for all deployments

### For Deployments
1. **Allocate IP address** in appropriate zone from topology.md
2. **Document in inventory/nodes.md** immediately
3. **Update network-topology.md** if zone changes
4. **Follow testing procedures** before operational promotion
5. **Update troubleshooting procedures** if new service introduces new failure modes

### For Troubleshooting
1. **Start with network-troubleshooting.md** systematic approach
2. **Run network health check script** (if available)
3. **Use layer-by-layer diagnostics** to isolate issue
4. **Consult service-specific sections** for known issues
5. **Follow emergency procedures** for critical outages
6. **Document findings** and update procedures

### For Operational Changes
1. **Plan change** using topology documentation
2. **Identify affected zones** and dependencies
3. **Update network-topology.md** before implementation
4. **Execute change** following documented procedures
5. **Validate** using testing procedures
6. **Update change log** in topology document

---

## Network Quality Gates

### Pre-Deployment Requirements

**Foundation Requirements:**
- [ ] IP address allocated and documented in network-topology.md
- [ ] IP address added to inventory/nodes.md
- [ ] FQDN registered in DNS (hx-dc-server)
- [ ] Server domain-joined to hx.dev.local
- [ ] Kerberos authentication functional
- [ ] TLS certificate issued by hx-ca-server
- [ ] Security zone assignment documented

**Network Connectivity:**
- [ ] Gateway reachable (192.168.10.1)
- [ ] DNS resolution functional
- [ ] NTP time synchronization configured
- [ ] Firewall rules configured per zone
- [ ] Port mappings documented

**Management Access:**
- [ ] Ansible control from hx-control-node functional
- [ ] SSH key authentication configured
- [ ] Logging configured (if hx-metric-server available)

### Service Deployment Quality Gates

**Network Validation:**
- [ ] Service port documented in network-topology.md port mapping
- [ ] Health check endpoint accessible
- [ ] Integration points tested
- [ ] DNS entries validated
- [ ] TLS certificate valid and trusted

**Security Validation:**
- [ ] Authentication mechanism tested
- [ ] Authorization rules verified
- [ ] Network segmentation validated
- [ ] Firewall rules tested
- [ ] Certificate expiration monitoring configured

**Documentation:**
- [ ] IP address in network-topology.md allocation table
- [ ] Service connectivity documented
- [ ] Dependencies mapped
- [ ] Troubleshooting procedures updated (if new service type)

---

## Testing Procedures

### Connectivity Test Suite

**DNS Resolution Test:**
```bash
# Test forward DNS
nslookup <hostname>.hx.dev.local 192.168.10.200

# Test reverse DNS
dig -x <ip-address> @192.168.10.200

# Pass Criteria: All deployed servers resolve in both directions
```

**Network Reachability Test:**
```bash
# Ping test from control node
for ip in {200..227}; do
  ping -c 1 192.168.10.$ip && echo "✅ .${ip}" || echo "❌ .${ip}"
done

# Pass Criteria: 100% success for all deployed servers
```

**Port Connectivity Test:**
```bash
# Test critical service ports
nc -zv hx-dc-server.hx.dev.local 88      # Kerberos
nc -zv hx-postgres-server.hx.dev.local 5432  # PostgreSQL
nc -zv hx-qdrant-server.hx.dev.local 6333    # Qdrant

# Pass Criteria: All critical services accessible
```

**Kerberos Authentication Test:**
```bash
# Test Kerberos ticket acquisition
kinit admin@HX.DEV.LOCAL
klist

# Pass Criteria: Tickets acquired successfully, no errors
```

**TLS Certificate Validation Test:**
```bash
# Test certificate chain
openssl s_client -connect hx-webui-server.hx.dev.local:443 -showcerts

# Check certificate expiration
echo | openssl s_client -connect hx-webui-server.hx.dev.local:443 2>/dev/null | \
  openssl x509 -noout -dates

# Pass Criteria: Valid certificate chain, not expiring within 30 days
```

### Integration Test Suite

**End-to-End Application Flow Test:**
```bash
# Test: User → SSL → WebUI → LiteLLM → Ollama
curl -k https://hx-ssl-server.hx.dev.local/webui
curl http://hx-litellm-server.hx.dev.local:4000/health
curl http://hx-ollama1-server.hx.dev.local:11434/api/tags

# Pass Criteria: Complete chain functional
```

**Data Plane Integration Test:**
```bash
# Test: Service → MCP → Data Store
curl http://hx-qdrant-server.hx.dev.local:6333/collections
psql -h hx-postgres-server.hx.dev.local -U <user> -c "SELECT version();"
redis-cli -h hx-redis-server.hx.dev.local PING

# Pass Criteria: All data stores accessible, no connection errors
```

---

## Disaster Recovery

### Backup Schedules

| Service | Component | Frequency | Retention | RPO | RTO |
|---------|-----------|-----------|-----------|-----|-----|
| hx-dc-server | AD Database | Daily | 30 days | 24h | 4h |
| hx-postgres-server | PostgreSQL | Hourly | 7 days | 1h | 2h |
| hx-qdrant-server | Vector DB | Daily | 14 days | 24h | 4h |
| hx-redis-server | Cache | None | N/A | N/A | 1h rebuild |
| hx-ca-server | Certificate DB | Weekly | 90 days | 7d | 24h |
| All Servers | VM Snapshots | Weekly | 4 weeks | 7d | 4-8h |

**RPO:** Recovery Point Objective (maximum acceptable data loss)
**RTO:** Recovery Time Objective (maximum acceptable downtime)

### Single Points of Failure (Current)

**Critical SPOFs:**
- ⚠️ hx-dc-server (Domain Controller) - All authentication depends on this
- ⚠️ hx-postgres-server (Database) - No replication configured
- ⚠️ hx-redis-server (Cache) - No sentinel cluster
- ⚠️ hx-ssl-server (Ingress) - No load balancer

**Mitigation:**
- Regular backups (see schedule above)
- VM snapshots for quick recovery
- Ansible configuration management for rapid rebuild
- Documented disaster recovery procedures

---

## Network Expansion Planning

### Phase 1 - Reserved Deployments (Immediate)
- Deploy hx-coderabbit-server (192.168.10.228)
- Deploy hx-shadcn-server (192.168.10.229)
- Complete validation of dev/demo/agui servers

### Phase 2 - High Availability (Future)
- Add secondary domain controller (hx-dc-server-2)
- Implement PostgreSQL streaming replication
- Add Redis Sentinel cluster for cache HA
- Deploy load balancer for web tier (hx-ssl-server-2)

### Phase 3 - Monitoring Enhancement (In Progress)
- Expand hx-metric-server capabilities
- Prometheus metrics collection ✅
- Grafana dashboards ✅
- Alertmanager notifications (Planned)
- Distributed tracing
- Centralized logging

### Phase 4 - Container Orchestration (Future)
- Evaluate Kubernetes cluster deployment
- Container registry for service images
- Ingress controller for containerized services

### IP Address Reservation
- 192.168.10.230-240: HA replicas and secondary services
- 192.168.10.241-250: Monitoring/logging expansion
- 192.168.10.251-254: Network infrastructure

---

## Integration with Other Documentation

### Infrastructure Documentation
- **inventory/nodes.md**: Server inventory must match network-topology.md IP allocations exactly
- **nodes/<node-name>/**: Individual node specifications reference network configuration

### Standards Documentation
- **standards/architecture-standards.md**: Network architecture follows standards
- **standards/naming-conventions.md**: Server naming matches conventions
- **standards/deployment-requirements.md**: Network quality gates referenced

### Agent Documentation
- **hx-agents/hx-agent-inventory.md**: Core Team and Technology SME agents (see inventory for current count)
- **hx-agents/hx-orchestration-guide.md**: Multi-agent coordination uses network services
- **.claude/commands/**: Commands reference network infrastructure

### Procedures Documentation
- **procedures/network-health-check.sh**: Automated diagnostic script (referenced in troubleshooting)
- **procedures/service-deployment.md**: Network quality gates enforced
- **procedures/test-execution.md**: Network testing procedures referenced

---

## Maintenance Guidelines

### Update Triggers

Network documentation MUST be updated when:
- ✅ New servers added to the network
- ✅ IP address changes occur
- ✅ Security zones are modified or new zones created
- ✅ Network topology changes (new segments, VLANs, routing)
- ✅ Service ports change or new services deployed
- ✅ Integration patterns evolve
- ✅ Quality gates are modified
- ✅ Testing procedures are updated
- ✅ New troubleshooting procedures discovered

### Update Timeline
- **Critical changes** (IP, zone, topology): Within 24 hours
- **Service ports, integrations**: Within 48 hours
- **Testing/troubleshooting procedures**: Next weekly review

### Weekly Review Checklist

**Network Topology Validation:**
- [ ] IP allocations match inventory/nodes.md?
- [ ] All security zones current?
- [ ] Service port mappings up to date?
- [ ] Data flow diagrams accurate?
- [ ] Change log current?

**Troubleshooting Procedures Validation:**
- [ ] All common issues documented?
- [ ] Emergency procedures tested?
- [ ] Diagnostic tools reference current?
- [ ] New service-specific issues added?

**Quality Standards:**
- [ ] Quality gates enforced for all deployments?
- [ ] Testing procedures validated?
- [ ] All tests passing?

---

## Related Documentation

### HX-Infrastructure Core
- `constitution.md` - Project principles and philosophy
- `README.md` - Repository overview and navigation
- `action-plan-v2-updated.md` - Project roadmap

### Inventory and State
- `inventory/nodes.md` - Complete server inventory (must match network topology)
- `inventory/services.md` - Service deployment status (when created)

### Standards and Guidelines
- `standards/naming-conventions.md` - Server naming standards
- `standards/architecture-standards.md` - Architecture guidelines
- `standards/deployment-requirements.md` - Deployment procedures
- `standards/testing-requirements.md` - Testing requirements

### Agent Documentation
- `hx-agents/hx-agent-inventory.md` - Agent inventory (see for current agent count)
- `hx-agents/hx-orchestration-guide.md` - Multi-agent workflows
- `CLAUDE.md` - Agent Zero orchestration

### Procedures (when created)
- `procedures/network-health-check.sh` - Automated diagnostics
- `procedures/service-deployment.md` - Deployment workflow
- `procedures/test-execution.md` - Testing procedures

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-21 | Initial network directory README | HX-Infrastructure Team |

---

## Document Metadata

**Document Type:** Directory Documentation - Network Overview
**Status:** ACTIVE - Authoritative Reference
**Maintained By:** HX-Infrastructure Team
**Review Frequency:** Weekly (or when network changes)
**Last Review:** 2025-11-21
**Next Review:** 2025-11-28

---

*The network directory contains authoritative documentation of HX-Infrastructure's network architecture. It serves as the single source of truth for network topology, IP allocations, security zones, and operational procedures. All network operators and deployment teams must consult and maintain this documentation.*
