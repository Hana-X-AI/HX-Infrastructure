# Network Configuration: hx-docling-mcp-server

**Node Name**: hx-docling-mcp-server
**Node IP**: 192.168.10.217
**Created**: 2025-11-30
**Status**: Specification Complete - Ready for Deployment

---

## Network Identity

| Parameter | Value |
|-----------|-------|
| **Hostname** | hx-docling-mcp-server |
| **FQDN** | hx-docling-mcp-server.hx.dev.local |
| **IP Address** | 192.168.10.217 |
| **Subnet** | 192.168.10.0/24 |
| **Gateway** | 192.168.10.1 |
| **DNS Server** | 192.168.10.200 (hx-dc-server) |
| **Domain** | hx.dev.local |

---

## Network Settings

**Interface Configuration**: `/etc/netplan/01-netcfg.yaml`

```yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.10.217/24]
      gateway4: 192.168.10.1
      nameservers:
        addresses: [192.168.10.200]
        search: [hx.dev.local]
```

**DNS Configuration**: `/etc/resolv.conf`

```
search hx.dev.local
nameserver 192.168.10.200
```

---

## Firewall Rules

**HX-Infrastructure Policy**: ALL firewalls are DISABLED per infrastructure standard.

Network security provided by infrastructure-level network isolation (192.168.10.0/24 internal network with no external exposure).

---

## Port Assignments

### Service Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 8000 | TCP | MCP Server | HTTP/SSE transport for MCP protocol |
| 9000 | TCP | Health Check | Service health monitoring endpoint |

### Outbound Connections

| Target Service | IP | Port | Protocol |
|----------------|-----|------|----------|
| hx-dc-server | 192.168.10.200 | 53 | UDP (DNS) |
| hx-postgres-server | 192.168.10.208 | 5432 | TCP |
| hx-redis-server | 192.168.10.210 | 6379 | TCP |
| hx-litellm-server | 192.168.10.212 | 4000 | TCP |
| hx-qdrant-server | 192.168.10.207 | 6333 | TCP |
| hx-literag-server | 192.168.10.220 | 8000 | TCP |

---

**Template Version**: 1.0
**Last Updated**: 2025-11-30
**Deployment Status**: Ready for production deployment
