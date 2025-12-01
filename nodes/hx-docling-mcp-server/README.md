# Node Specification: [NODE NAME]

**Node Name**: [node-name]  
**Created**: [DATE]  
**Last Updated**: [DATE]  
**Status**: [Active | Provisioning | Maintenance | Retired]

---

## Node Overview

### Purpose
[Brief description of this node's primary purpose and role in the infrastructure]

### Location
**Physical Location**: [e.g., On-premises data center, Cloud provider, Home lab]  
**Network Location**: [e.g., DMZ, Internal network, Subnet X.X.X.X/24]  
**Rack/Position**: [If applicable - e.g., Rack 3, Position U12-U15]

---

## Hardware Specifications

### Physical Hardware
**Manufacturer**: [e.g., Dell, HP, Custom Build, Virtual]  
**Model**: [e.g., PowerEdge R740, ProLiant DL380, VM]  
**Serial Number**: [If applicable]  
**Asset Tag**: [If applicable]

### Processor
**CPU Model**: [e.g., Intel Xeon Silver 4214, AMD EPYC 7543]  
**CPU Cores**: [Physical cores]  
**CPU Threads**: [Logical cores/threads]  
**CPU Speed**: [e.g., 2.20 GHz base, 3.20 GHz boost]  
**CPU Count**: [Number of physical CPUs]

### Memory
**Total RAM**: [e.g., 64GB, 128GB]  
**RAM Type**: [e.g., DDR4 ECC]  
**RAM Speed**: [e.g., 2933 MHz]  
**RAM Configuration**: [e.g., 8x 8GB modules, 4x 32GB modules]

### Storage

#### Primary Storage
**Type**: [SSD, NVMe, HDD, Network]  
**Capacity**: [e.g., 500GB]  
**Model**: [e.g., Samsung 970 EVO Plus]  
**Mount Point**: [e.g., /]  
**File System**: [e.g., ext4, xfs, btrfs]

#### Secondary Storage
**Type**: [SSD, NVMe, HDD, Network]  
**Capacity**: [e.g., 2TB]  
**Model**: [Disk model]  
**Mount Point**: [e.g., /data, /var/lib]  
**File System**: [e.g., ext4, xfs, btrfs]

#### Additional Storage
[List any additional storage devices, NAS mounts, etc.]

**Total Storage Capacity**: [Sum of all storage]  
**Used Storage**: [Current usage]  
**Available Storage**: [Free space]

### Network Interfaces

#### Interface 1
**Interface Name**: [e.g., eth0, ens18]  
**MAC Address**: [XX:XX:XX:XX:XX:XX]  
**IP Address**: [Static IP or DHCP]  
**Subnet Mask**: [e.g., 255.255.255.0]  
**Gateway**: [Default gateway IP]  
**Speed**: [e.g., 1Gbps, 10Gbps]  
**Purpose**: [e.g., Primary network, Management]

#### Interface 2
**Interface Name**: [e.g., eth1, ens19]  
**MAC Address**: [XX:XX:XX:XX:XX:XX]  
**IP Address**: [Static IP or DHCP]  
**Subnet Mask**: [e.g., 255.255.255.0]  
**Speed**: [e.g., 1Gbps]  
**Purpose**: [e.g., Storage network, Backup]

### Graphics
**GPU**: [None | Integrated | Dedicated GPU model]  
**GPU Purpose**: [N/A | Display | Compute | AI/ML workload]

### Power
**Power Supply**: [Wattage and redundancy - e.g., Dual 750W redundant]  
**UPS**: [Connected to UPS? Model if applicable]  
**Power Consumption**: [Average watts under load]

---

## Operating System

### OS Details
**Distribution**: [e.g., Ubuntu, Debian, CentOS, RHEL]  
**Version**: [e.g., Ubuntu 24.04 LTS]  
**Kernel Version**: [e.g., 6.8.0-48-generic]  
**Architecture**: [e.g., x86_64, ARM64]

### Installation
**Installation Date**: [DATE]  
**Installation Method**: [e.g., ISO, PXE boot, Cloud init]  
**Partition Scheme**: [Brief description of partition layout]

### Updates
**Update Policy**: [e.g., Automatic security updates, Manual updates]  
**Last Updated**: [DATE]  
**Update Schedule**: [e.g., Weekly, Monthly, As needed]

---

## Network Configuration

### Hostname
**Hostname**: [fully qualified domain name]  
**Short Name**: [hostname]  
**Domain**: [domain name]

### DNS
**Primary DNS**: [DNS server IP]  
**Secondary DNS**: [DNS server IP]  
**Search Domains**: [list of search domains]

### Firewall
**Firewall Status**: [Enabled | Disabled]  
**Firewall Solution**: [e.g., ufw, firewalld, iptables]  
**Default Policy**: [e.g., Deny all incoming, Allow all outgoing]

### Open Ports
| Port | Protocol | Service | Purpose | Source Restriction |
|------|----------|---------|---------|-------------------|
| 22 | TCP | SSH | Remote administration | [IP range or "Any"] |
| 80 | TCP | HTTP | Web service | [IP range or "Any"] |
| 443 | TCP | HTTPS | Secure web service | [IP range or "Any"] |
| [port] | [TCP/UDP] | [service] | [purpose] | [restriction] |

### Network Routes
**Default Gateway**: [IP address]  
**Static Routes**: [List any static routes if configured]

---

## Resource Allocation

### Current Resource Usage
**As of**: [DATE/TIME]

**CPU Usage**: [e.g., 25%]  
**Memory Usage**: [e.g., 32GB used / 64GB total (50%)]  
**Disk Usage**: [e.g., 250GB used / 500GB total (50%)]  
**Network Usage**: [e.g., 100Mbps average]  
**Load Average**: [1min, 5min, 15min]

### Resource Limits
**CPU Limit**: [Maximum expected CPU usage - e.g., 80%]  
**Memory Limit**: [Maximum memory allocation - e.g., 56GB of 64GB]  
**Disk Limit**: [Maximum disk usage - e.g., 400GB of 500GB]

### Capacity Planning
**Current Capacity**: [e.g., 60% utilized]  
**Projected Growth**: [e.g., 10% per quarter]  
**Capacity Warning Threshold**: [e.g., 75%]  
**Capacity Critical Threshold**: [e.g., 90%]

---

## Deployed Services

### Active Services
[Reference to services-deployed.md for complete list]

**Total Services**: [number]  
**Operational Services**: [number]  
**Non-Operational Services**: [number]

### Service Summary
| Service Name | Status | Port(s) | Resource Usage |
|-------------|--------|---------|----------------|
| [service-1] | Operational | [ports] | [CPU/Mem] |
| [service-2] | Operational | [ports] | [CPU/Mem] |
| [service-3] | Non-operational | [ports] | [CPU/Mem] |

**Detailed Service Documentation**: See `nodes/[node-name]/services-deployed.md`

---

## Access and Authentication

### User Accounts
**Primary Admin**: [username]  
**Service Accounts**: [list service accounts if any]  

### SSH Access
**SSH Status**: [Enabled | Disabled]  
**SSH Port**: [e.g., 22 or custom port]  
**Authentication Method**: [Key-based | Password | Both]  
**Allowed Users**: [list of users with SSH access]  
**SSH Key Location**: [where authorized_keys are managed]

### Sudo Access
**Users with sudo**: [list users]  
**Sudo Policy**: [e.g., Password required, NOPASSWD for specific commands]

### Remote Access
**Console Access**: [e.g., iDRAC, iLO, Physical console]  
**VPN Required**: [YES | NO]  
**Bastion Host**: [If applicable]

---

## Backup and Recovery

### Backup Configuration
**Backup Status**: [Enabled | Disabled | Partial]  
**Backup Method**: [e.g., Rsync, Timeshift, Commercial solution]  
**Backup Schedule**: [e.g., Daily at 2:00 AM]  
**Backup Retention**: [e.g., 7 daily, 4 weekly, 12 monthly]

### Backup Targets
**Local Backup**: [Path and capacity]  
**Remote Backup**: [Location and method]  
**Cloud Backup**: [Provider and configuration]

### Recovery
**Recovery Point Objective (RPO)**: [e.g., 24 hours]  
**Recovery Time Objective (RTO)**: [e.g., 4 hours]  
**Last Successful Backup**: [DATE/TIME]  
**Last Recovery Test**: [DATE]

### Critical Data Locations
- [/path/to/critical/data1] - [Description]
- [/path/to/critical/data2] - [Description]

---

## Monitoring and Alerting

### Monitoring Status
**Monitoring Enabled**: [YES | NO]  
**Monitoring Solution**: [e.g., Prometheus, Nagios, Zabbix, Custom]  
**Metrics Collection Interval**: [e.g., 60 seconds]

### Monitored Metrics
- [ ] CPU usage
- [ ] Memory usage
- [ ] Disk usage
- [ ] Network bandwidth
- [ ] Service availability
- [ ] Temperature (if applicable)
- [ ] System logs
- [ ] Security events

### Alerting
**Alerting Enabled**: [YES | NO]  
**Alert Destination**: [e.g., Email, Slack, PagerDuty]  
**Alert Thresholds**:
- CPU: > [percentage]%
- Memory: > [percentage]%
- Disk: > [percentage]%
- Service Down: Immediate

### Logs
**Log Location**: [e.g., /var/log/]  
**Log Retention**: [e.g., 30 days local, 90 days remote]  
**Log Forwarding**: [Enabled to central logging? Location?]

---

## Maintenance

### Maintenance Schedule
**Regular Maintenance**: [e.g., First Sunday of each month]  
**Maintenance Window**: [e.g., 2:00 AM - 6:00 AM]  
**Last Maintenance**: [DATE]  
**Next Scheduled Maintenance**: [DATE]

### Maintenance History
| Date | Type | Performed By | Description | Downtime |
|------|------|--------------|-------------|----------|
| [DATE] | [Planned/Unplanned] | [Name] | [Description] | [Duration] |
| [DATE] | [Planned/Unplanned] | [Name] | [Description] | [Duration] |

### Known Issues
1. [Issue description] - Status: [Open/In Progress/Resolved]
2. [Issue description] - Status: [Open/In Progress/Resolved]

### Pending Updates
- [ ] [Update 1 - e.g., OS security patches]
- [ ] [Update 2 - e.g., Firmware update]
- [ ] [Update 3 - e.g., Service upgrade]

---

## Security

### Security Posture
**Security Baseline**: [e.g., CIS Ubuntu 24.04 Benchmark]  
**Last Security Audit**: [DATE]  
**Compliance Requirements**: [e.g., None, PCI-DSS, HIPAA]

### Security Controls
- [ ] Firewall enabled and configured
- [ ] SSH key-based authentication
- [ ] Fail2ban or similar intrusion prevention
- [ ] Regular security updates
- [ ] Encrypted storage (if applicable)
- [ ] SELinux/AppArmor (if applicable)

### Security Monitoring
**IDS/IPS**: [Enabled | Disabled - Solution name]  
**Security Log Monitoring**: [Enabled | Disabled]  
**Failed Login Attempts**: [Monitored | Not monitored]

---

## High Availability and Redundancy

### HA Configuration
**HA Status**: [Standalone | Part of HA cluster]  
**HA Solution**: [e.g., None, Keepalived, Pacemaker]  
**Cluster Members**: [List if part of cluster]

### Redundancy
**Power Redundancy**: [Single PSU | Dual PSU | UPS backed]  
**Network Redundancy**: [Single NIC | Bonded NICs | Multiple paths]  
**Storage Redundancy**: [None | RAID level | Replicated]

### Failover
**Failover Capability**: [YES | NO]  
**Failover Partner**: [Node name if applicable]  
**Failover Time**: [Expected failover duration]

---

## Dependencies

### Upstream Dependencies
**This node depends on:**
- [Dependency 1 - e.g., Network infrastructure]
- [Dependency 2 - e.g., DNS server]
- [Dependency 3 - e.g., Authentication server]

### Downstream Dependencies
**Services/nodes that depend on this node:**
- [Dependent 1 - e.g., Application servers]
- [Dependent 2 - e.g., Worker nodes]

---

## Operational Procedures

### Startup Procedure
1. [Step 1 - e.g., Power on node]
2. [Step 2 - e.g., Verify network connectivity]
3. [Step 3 - e.g., Start critical services]
4. [Step 4 - e.g., Verify all services operational]

### Shutdown Procedure
1. [Step 1 - e.g., Stop non-critical services]
2. [Step 2 - e.g., Stop critical services in order]
3. [Step 3 - e.g., Flush file system buffers]
4. [Step 4 - e.g., Shutdown OS]

### Emergency Procedures
**Emergency Contact**: [Name, Phone, Email]  
**Escalation Path**: [Who to contact in what order]

**Common Emergency Scenarios:**
1. **Node Unresponsive**: [Steps to diagnose and recover]
2. **Disk Full**: [Steps to free space]
3. **Service Failure**: [Steps to restart/recover]
4. **Network Outage**: [Steps to diagnose and recover]

---

## Configuration Management

### Configuration Files Location
**System Configs**: `/etc/`  
**Service Configs**: [List key service config directories]  
**Custom Configs**: [Any custom configuration locations]

### Configuration Backup
**Config Backup Status**: [Enabled | Disabled]  
**Config Backup Location**: [Where configs are backed up]  
**Last Config Backup**: [DATE]

### Configuration Version Control
**Version Controlled**: [YES | NO]  
**Repository**: [Git repo URL if applicable]  
**Last Commit**: [DATE/HASH]

---

## Documentation

### Related Documentation
- `services-deployed.md` - Services running on this node
- `configuration/` - Configuration files and details
- `/inventory/nodes.md` - Node inventory
- `/network/network-topology.md` - Network topology

### Diagrams
**Block Diagram**: [Link to diagram showing node architecture]  
**Network Diagram**: [Link to network connectivity diagram]  
**Service Diagram**: [Link to service deployment diagram]

---

## Contact Information

### Node Owner
**Primary Owner**: [Name]  
**Email**: [email]  
**Phone**: [phone]

### Technical Contact
**Primary Admin**: [Name]  
**Email**: [email]  
**Phone**: [phone]

### Escalation
**L2 Support**: [Name/Team]  
**L3 Support**: [Name/Team]

---

## Change History

| Date | Changed By | Change Description | Version |
|------|-----------|-------------------|---------|
| [DATE] | [Name] | Initial node specification | 1.0 |
| [DATE] | [Name] | [Description of change] | 1.1 |

---

## Notes

### General Notes
[Any additional information about this node that doesn't fit elsewhere]

### Quirks and Known Behavior
[Any unusual behavior or quirks about this node that operators should know]

### Future Plans
[Any planned upgrades, migrations, or changes to this node]

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
