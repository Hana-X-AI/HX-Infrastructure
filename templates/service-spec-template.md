# Service Specification: [SERVICE NAME]

**Service Branch**: `[###-service-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No service description provided"
2. Extract key concepts from description
   → Identify: service purpose, dependencies, node requirements, integrations
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill Service Purpose & Requirements section
   → If no clear service purpose: ERROR "Cannot determine service requirements"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Dependencies and Integrations
7. Define Success Criteria
8. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove specific tech details"
9. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT the service does and WHY it's needed
- ❌ Avoid HOW to deploy (no specific commands, exact configs, file paths)
- 🎯 Written for infrastructure team and agents, focus on requirements

### Section Requirements
- **Mandatory sections**: Must be completed for every service
- **Optional sections**: Include only when relevant to the service
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "database service" without specifying which database), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - Specific technology/version (PostgreSQL vs MySQL, version requirements)
   - Port requirements and network configuration
   - Resource requirements (CPU, memory, storage)
   - Data persistence requirements
   - Backup and recovery requirements
   - Integration endpoints
   - Authentication/authorization requirements
   - Monitoring and logging requirements

---

## Service Purpose & Requirements *(mandatory)*

### Primary Purpose
[Describe what this service does and why it's being deployed - in plain language]

### Deployment Scenarios
1. **Given** [infrastructure state], **When** [service deployed], **Then** [expected outcome]
2. **Given** [configuration applied], **When** [service started], **Then** [expected behavior]

### Operational Requirements
- What happens when [service fails]?
- How does system handle [network interruption]?
- What are the recovery requirements?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Service MUST [specific capability, e.g., "accept connections on designated port"]
- **FR-002**: Service MUST [specific capability, e.g., "persist data to configured storage"]  
- **FR-003**: Service MUST [key behavior, e.g., "integrate with existing authentication system"]
- **FR-004**: Service MUST [operational requirement, e.g., "log all access attempts"]
- **FR-005**: Service MUST [performance requirement, e.g., "respond within 500ms"]

*Example of marking unclear requirements:*
- **FR-006**: Service MUST use [NEEDS CLARIFICATION: specific database not specified - PostgreSQL, MySQL, MongoDB?]
- **FR-007**: Service MUST store data with [NEEDS CLARIFICATION: retention policy not specified]

### Node Requirements *(mandatory)*
- **Target Node(s)**: [Which node(s) will host this service - e.g., agent0, database-node, or NEEDS CLARIFICATION]
- **Operating System**: [OS requirements - e.g., Ubuntu 24.04, any Linux, or NEEDS CLARIFICATION]
- **Resource Requirements**:
  - CPU: [e.g., 2 cores minimum, or NEEDS CLARIFICATION]
  - Memory: [e.g., 4GB RAM, or NEEDS CLARIFICATION]
  - Storage: [e.g., 100GB persistent storage, or NEEDS CLARIFICATION]
  - Network: [e.g., dedicated interface, specific ports, or NEEDS CLARIFICATION]

### Dependencies *(include if service has dependencies)*
- **External Services**: [List services this depends on - e.g., database service, authentication service]
- **System Dependencies**: [OS packages, libraries, runtimes - e.g., Python 3.11, Node.js 20]
- **Network Dependencies**: [External APIs, network services required]

### Integrations *(include if service integrates with others)*
- **Upstream Services**: [Services that will consume this service]
- **Downstream Services**: [Services this service will consume]
- **Integration Protocols**: [HTTP/REST, gRPC, message queue, database connection]

### Configuration Requirements *(mandatory)*
- **Environment Variables**: [Required environment configuration]
- **Configuration Files**: [Config files needed and their purpose]
- **Secrets Management**: [Credentials, API keys, certificates required]

### Security Requirements *(mandatory)*
- **Authentication**: [How service authenticates - e.g., API keys, OAuth, client certificates]
- **Authorization**: [Access control requirements]
- **Network Security**: [Firewall rules, network isolation requirements]
- **Data Security**: [Encryption at rest/in transit requirements]

### Backup & Recovery *(include if service manages data)*
- **Backup Requirements**: [Backup frequency, retention period]
- **Recovery Point Objective (RPO)**: [Acceptable data loss window]
- **Recovery Time Objective (RTO)**: [Acceptable downtime window]

### Monitoring & Observability *(mandatory)*
- **Health Checks**: [How to verify service is operational]
- **Key Metrics**: [What metrics must be monitored - e.g., response time, error rate, resource usage]
- **Logging Requirements**: [What must be logged and at what level]
- **Alerting Requirements**: [What conditions trigger alerts]

---

## Success Criteria *(mandatory)*

### Deployment Success
- **SC-001**: [Measurable metric, e.g., "Service responds to health check within 2 seconds"]
- **SC-002**: [Measurable metric, e.g., "All integration tests pass on first deployment"]
- **SC-003**: [Operational metric, e.g., "Service maintains 99.9% uptime during testing period"]

### Operational Success
- **SC-004**: [Performance metric, e.g., "95th percentile response time under 500ms"]
- **SC-005**: [Reliability metric, e.g., "Zero critical errors in 48-hour test period"]
- **SC-006**: [Business metric, e.g., "Successfully processes 1000 requests per minute"]

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [ ] No implementation details (specific commands, exact file paths, detailed configs)
- [ ] Focused on service requirements and operational needs
- [ ] Written for infrastructure team and agents
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous  
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and integrations identified
- [ ] Node requirements specified
- [ ] Security requirements defined
- [ ] Monitoring and observability requirements clear

### Infrastructure Alignment
- [ ] Aligns with HX Infrastructure constitution
- [ ] Node capacity verified (if target node known)
- [ ] Network topology considered
- [ ] Naming conventions will be followed

---

## Execution Status
*Updated by main() during processing*

- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] Service purpose defined
- [ ] Requirements generated
- [ ] Dependencies identified
- [ ] Success criteria defined
- [ ] Review checklist passed

---

## Related Documentation
*To be created during planning phase*

- `plan.md` - Deployment plan (created by /hx-plan command)
- `tasks/` - Deployment tasks (created after planning)
- `tests/` - Test suite (created during planning)

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-15  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git
