# RAIDD Log: [PROJECT/SERVICE NAME]

**Document Type**: Project Management - RAIDD Tracking  
**Created**: [DATE]  
**Project/Service**: [NAME]  
**Owner**: [NAME/ROLE]  
**Status**: [Active | Archived]  
**Location**: `[Path - root for project-level, services/<service>/ for service-level]`

---

## Document Purpose

This RAIDD Log tracks the five critical project management factors:
- **R**isks - Potential issues that may impact success
- **A**ssumptions - Beliefs or conditions taken as true
- **I**ssues - Current problems requiring resolution
- **D**ependencies - External factors or prerequisites
- **D**ecisions - Key choices made during execution

**Scope**: [Project-wide | Service-specific | Phase-specific]

---

## Quick Reference

### Current Status Summary

| Category | Total | Critical | High | Medium | Low | Resolved |
|----------|-------|----------|------|--------|-----|----------|
| **Risks** | 0 | 0 | 0 | 0 | 0 | 0 |
| **Assumptions** | 0 | - | - | - | - | 0 |
| **Issues** | 0 | 0 | 0 | 0 | 0 | 0 |
| **Dependencies** | 0 | 0 | 0 | 0 | 0 | 0 |
| **Decisions** | 0 | - | - | - | - | 0 |

**Last Updated**: [DATE]

---

## 1. Risks

**Definition**: Potential events or conditions that could negatively impact the project/service if they occur.

### Risk Assessment Criteria

| Likelihood | Impact | Priority |
|------------|--------|----------|
| High       | High   | Critical |
| High       | Medium | High     |
| Medium     | High   | High     |
| Medium     | Medium | Medium   |
| Low        | Any    | Low      |

### Active Risks

#### R-001: [Risk Title]

**Status**: [Open | Monitoring | Mitigated | Closed]  
**Identified**: [DATE]  
**Owner**: [NAME/ROLE]  
**Likelihood**: [High | Medium | Low]  
**Impact**: [High | Medium | Low]  
**Priority**: [Critical | High | Medium | Low]

**Description:**
[Describe the risk - what could go wrong and under what conditions]

**Impact if Realized:**
- [Impact 1 - e.g., "Delays deployment by 2 weeks"]
- [Impact 2 - e.g., "Requires architectural redesign"]
- [Impact 3 - e.g., "Costs $X in rework"]

**Mitigation Strategy:**
- [Mitigation 1 - preventive action]
- [Mitigation 2 - risk reduction approach]

**Contingency Plan:**
[What we'll do if the risk occurs]

**Triggers/Indicators:**
- [Early warning sign 1]
- [Early warning sign 2]

**Status Updates:**
- [DATE]: [Status update - what changed, current likelihood/impact]

---

#### R-002: [Risk Title]

[Same structure as R-001]

---

### Resolved Risks

#### R-XXX: [Risk Title] - CLOSED

**Closed**: [DATE]  
**Resolution**: [How it was resolved - mitigated, avoided, or accepted]  
**Lessons Learned**: [What we learned from this risk]

---

## 2. Assumptions

**Definition**: Conditions or facts accepted as true without proof, upon which the project/service plan depends.

### Assumption Validation Criteria

| Status | Definition |
|--------|------------|
| Unvalidated | Assumption not yet confirmed |
| Validated | Confirmed through evidence or testing |
| Invalid | Proven false - requires plan adjustment |
| At Risk | Showing signs of being invalid |

### Active Assumptions

#### A-001: [Assumption Title]

**Status**: [Unvalidated | Validated | Invalid | At Risk]  
**Identified**: [DATE]  
**Owner**: [NAME/ROLE]  
**Validation Due**: [DATE]  
**Impact if Invalid**: [High | Medium | Low]

**Assumption:**
[State the assumption clearly - "We assume that..."]

**Basis:**
[Why we believe this is true - evidence, prior experience, expert opinion]

**Validation Method:**
[How we'll confirm this assumption - test, research, stakeholder confirmation]

**Impact if Invalid:**
- [Impact 1 - what changes if this assumption is wrong]
- [Impact 2]

**Validation Evidence:**
- [DATE]: [Evidence collected - e.g., "Confirmed by vendor", "Tested successfully"]

**Status Updates:**
- [DATE]: [Update on validation progress]

---

#### A-002: [Assumption Title]

[Same structure as A-001]

---

### Invalidated Assumptions

#### A-XXX: [Assumption Title] - INVALID

**Invalidated**: [DATE]  
**Reason**: [Why assumption proved false]  
**Plan Adjustment**: [How we adjusted plans in response]  
**Lessons Learned**: [What we learned]

---

## 3. Issues

**Definition**: Current problems or obstacles that are actively blocking progress or degrading quality.

### Issue Severity Criteria

| Severity | Definition | Response Time |
|----------|------------|---------------|
| Critical | Blocks all progress, system down | Immediate (< 4 hours) |
| High | Blocks key functionality, major impact | Same day (< 24 hours) |
| Medium | Degraded functionality, workaround exists | Within 3 days |
| Low | Minor inconvenience, cosmetic | Within 1 week |

### Open Issues

#### I-001: [Issue Title]

**Status**: [Open | In Progress | Blocked | Resolved]  
**Reported**: [DATE]  
**Owner**: [NAME/ROLE]  
**Severity**: [Critical | High | Medium | Low]  
**Priority**: [P0 | P1 | P2 | P3]  
**Target Resolution**: [DATE]

**Description:**
[Describe the issue - what's wrong, what's the impact]

**Impact:**
- [Impact 1 - what's affected]
- [Impact 2 - who's affected]

**Root Cause:**
[If known - what's causing this issue]

**Resolution Plan:**
1. [Step 1 to resolve]
2. [Step 2 to resolve]
3. [Step 3 to resolve]

**Blockers:**
[Anything preventing resolution - dependencies, resources, decisions needed]

**Workaround:**
[Temporary solution if available]

**Status Updates:**
- [DATE]: [Progress update, what's been done, what's next]

**Related Items:**
- **Dependencies**: [D-XXX if blocked by external factor]
- **Decisions**: [DE-XXX if decision needed]
- **Risks**: [R-XXX if issue could escalate]

---

#### I-002: [Issue Title]

[Same structure as I-001]

---

### Resolved Issues

#### I-XXX: [Issue Title] - RESOLVED

**Resolved**: [DATE]  
**Resolution**: [How it was fixed]  
**Resolution Time**: [Hours/days from report to resolution]  
**Lessons Learned**: [What we learned from this issue]

---

## 4. Dependencies

**Definition**: External factors, resources, or deliverables that the project/service relies upon.

### Dependency Type Classification

| Type | Definition | Examples |
|------|------------|----------|
| Technical | Infrastructure, services, APIs | Database server, third-party API |
| Resource | People, equipment, budget | Developer availability, hardware |
| Process | Approvals, reviews, gates | Security review, budget approval |
| External | Vendor deliveries, partner work | External service deployment |

### Active Dependencies

#### D-001: [Dependency Title]

**Status**: [Pending | In Progress | Satisfied | Blocked | At Risk]  
**Identified**: [DATE]  
**Owner**: [NAME/ROLE (internal)] | [EXTERNAL PARTY]  
**Type**: [Technical | Resource | Process | External]  
**Criticality**: [Critical | High | Medium | Low]  
**Required By**: [DATE - when we need this]  
**Current ETA**: [DATE - when it's expected]

**Description:**
[What we depend on - be specific]

**Required For:**
- [What we can't do without this dependency]
- [Milestone or task blocked by this]

**Provider/Source:**
[Who/what provides this - person, team, vendor, service]

**Acceptance Criteria:**
[How we'll know this dependency is satisfied]

**Risk Assessment:**
- **Likelihood of Delay**: [High | Medium | Low]
- **Impact if Delayed**: [High | Medium | Low]
- **Mitigation**: [What we're doing to reduce dependency risk]

**Fallback Plan:**
[Alternative if dependency fails or delays]

**Status Updates:**
- [DATE]: [Progress update from provider, ETA changes]

**Related Items:**
- **Risks**: [R-XXX if dependency at risk]
- **Issues**: [I-XXX if dependency causing problems]

---

#### D-002: [Dependency Title]

[Same structure as D-001]

---

### Satisfied Dependencies

#### D-XXX: [Dependency Title] - SATISFIED

**Satisfied**: [DATE]  
**Delivery**: [On-time | Early | Late by X days]  
**Quality**: [Met expectations | Exceeded | Below - required rework]  
**Lessons Learned**: [What we learned about this dependency]

---

## 5. Decisions

**Definition**: Key choices made during the project/service lifecycle that shape direction, architecture, or approach.

### Decision Authority Levels

| Level | Scope | Examples | Authority |
|-------|-------|----------|-----------|
| Strategic | Project direction, major architecture | Framework choice, deployment model | Project Lead + Stakeholders |
| Tactical | Implementation approach, design | API design, database schema | Technical Lead |
| Operational | Day-to-day execution | Naming conventions, tools | Team consensus |

### Active Decisions

#### DE-001: [Decision Title]

**Status**: [Proposed | Under Review | Approved | Rejected | Deferred]  
**Proposed**: [DATE]  
**Decision Maker**: [NAME/ROLE]  
**Authority Level**: [Strategic | Tactical | Operational]  
**Decision Required By**: [DATE]  
**Implementation Impact**: [High | Medium | Low]

**Context:**
[Why this decision is needed - background, problem statement]

**Options Considered:**

**Option A**: [Option name]
- **Pros**: [Benefit 1], [Benefit 2]
- **Cons**: [Drawback 1], [Drawback 2]
- **Cost/Effort**: [Estimate]

**Option B**: [Option name]
- **Pros**: [Benefit 1], [Benefit 2]
- **Cons**: [Drawback 1], [Drawback 2]
- **Cost/Effort**: [Estimate]

**Option C**: [Option name] (if applicable)
- **Pros**: [Benefit 1], [Benefit 2]
- **Cons**: [Drawback 1], [Drawback 2]
- **Cost/Effort**: [Estimate]

**Recommendation:**
[Which option is recommended and why]

**Decision Criteria:**
- [Criterion 1 - e.g., "Aligns with constitution principles"]
- [Criterion 2 - e.g., "Minimizes complexity"]
- [Criterion 3 - e.g., "Reduces cost"]

**Stakeholders Consulted:**
- [NAME/ROLE]: [Opinion/input]
- [NAME/ROLE]: [Opinion/input]

**Constitution Alignment:**
[How this decision aligns with project constitution principles]

**Approval Status:**
- [ ] Technical review complete
- [ ] Stakeholder sign-off obtained
- [ ] Constitution compliance verified
- [ ] Documentation updated

**Status Updates:**
- [DATE]: [Discussion progress, feedback received]

**Related Items:**
- **Risks**: [R-XXX if decision carries risk]
- **Assumptions**: [A-XXX if decision based on assumption]
- **Dependencies**: [D-XXX if decision depends on external factor]

---

#### DE-002: [Decision Title]

[Same structure as DE-001]

---

### Finalized Decisions

#### DE-XXX: [Decision Title] - APPROVED

**Approved**: [DATE]  
**Decision**: [What was decided - be specific]  
**Rationale**: [Why this option was chosen]  
**Implementation**: [How it was implemented or will be implemented]  
**Owner**: [Who's responsible for implementation]  
**Review Date**: [DATE - when we'll review if decision was correct]  
**Lessons Learned**: [What we learned from this decision]

---

## Document Maintenance

### Update Frequency

**Regular Updates**: Weekly during active development  
**Status Review**: Every sprint/iteration  
**Full Audit**: Monthly or at major milestones

### Update Triggers

Update this log immediately when:
- ✅ New risk identified or risk status changes
- ✅ Assumption validated or invalidated
- ✅ Issue raised or resolved
- ✅ Dependency added or status changes
- ✅ Decision proposed, approved, or rejected

### Archival Policy

**When to Archive**:
- Project/service completed
- All items resolved or transferred
- Regular archival at major milestones

**Archive Location**: `[Path]/archive/raidd-log-YYYY-MM-DD.md`

---

## Change Log

| Version | Date | Changes | Updated By |
|---------|------|---------|------------|
| 1.0 | [DATE] | Initial RAIDD log created | [NAME] |
| 1.1 | [DATE] | [Description of changes] | [NAME] |

---

## Related Documents

**Project Documents:**
- `constitution.md` - Project principles and governance
- `README.md` - Project overview
- `action-plan-v2.1.md` - Project roadmap

**Service Documents** (if service-level log):
- `charter.md` - Service vision and purpose
- `spec.md` - Service requirements
- `plan.md` - Deployment plan
- `deployment/architecture.md` - Technical design

**Standards:**
- `standards/documentation-requirements.md` - Documentation standards
- `standards/deployment-requirements.md` - Deployment requirements

---

## RAIDD Log Checklist

**Use this checklist when creating or updating a RAIDD log:**

### Content Completeness
- [ ] All 5 categories (R-A-I-D-D) have at least one entry OR marked as "None current"
- [ ] Each entry has unique ID with proper prefix (R-, A-, I-, D-, DE-)
- [ ] Status summary table is accurate and current
- [ ] All dates in ISO format (YYYY-MM-DD)
- [ ] All entries have assigned owners
- [ ] All entries have status updates within last 7 days (for active items)

### Quality Checks
- [ ] Risks have mitigation strategies defined
- [ ] Assumptions have validation methods specified
- [ ] Issues have resolution plans with steps
- [ ] Dependencies have fallback plans
- [ ] Decisions have options evaluated with pros/cons
- [ ] All critical/high severity items reviewed by leadership
- [ ] Constitution alignment verified for all decisions

### Cross-References
- [ ] Related RAIDD items cross-referenced (Risks → Dependencies, Issues → Decisions, etc.)
- [ ] Links to relevant project documents included
- [ ] Change log updated with latest modifications

### Stakeholder Communication
- [ ] Critical items communicated to stakeholders
- [ ] Blocked items escalated appropriately
- [ ] Decisions requiring approval have sign-off obtained

---

**Template Version**: 1.0  
**Last Updated**: 2025-11-16  
**Repository**: https://github.com/Hana-X-AI/HX-Infrastructure.git

---

## Template Usage Guidance

### When to Use This Template

**Project-Level RAIDD Log:**
- Create at project inception
- Track project-wide risks, decisions, dependencies
- Location: Root directory (`raidd-log.md`)

**Service-Level RAIDD Log:**
- Create for each major service deployment
- Track service-specific items
- Location: `services/<service-type>/<service-name>/raidd-log.md`

### How to Fill Out

1. **Copy template** to appropriate location
2. **Update header** with project/service name, dates, owner
3. **Add entries** as items are identified (don't wait)
4. **Update regularly** - weekly minimum, daily for active projects
5. **Cross-reference** related items to show connections
6. **Archive** resolved items but keep for lessons learned

### Integration with Workflow

**During Planning:**
- Document assumptions made during spec/charter creation
- Identify dependencies on external services/teams
- Record architectural decisions with rationale

**During Implementation:**
- Log risks as they're identified
- Track issues with resolution progress
- Update dependency status from providers

**During Review:**
- Validate assumptions against actual results
- Assess if risks materialized
- Document lessons learned from issues

### Tips for Effective RAIDD Management

**Risks:**
- Be specific about likelihood and impact
- Update mitigation status regularly
- Don't ignore low-probability high-impact risks

**Assumptions:**
- Validate early and often
- Document invalidated assumptions - they're valuable learning
- Convert assumptions to decisions when validated

**Issues:**
- Log immediately when identified
- Include workarounds even if temporary
- Track resolution time to improve estimates

**Dependencies:**
- Identify early in planning
- Monitor ETA changes closely
- Have fallback plans for critical dependencies

**Decisions:**
- Document rationale, not just the choice
- Include rejected options and why
- Review decisions periodically for correctness

---

*This RAIDD log template supports HX-Infrastructure's quality-first, systematic approach to project management. Use it to maintain visibility into the five critical factors that determine project success.*
