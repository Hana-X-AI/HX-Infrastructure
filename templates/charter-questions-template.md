# Charter Clarifying Questions Template
## Round 1 - Initial Scope & Intent Questions

**Purpose:** Template for CC to use when asking initial clarifying questions for any node deployment charter  
**When to Use:** Phase 3 of charter workflow, after parsing CAIO's natural input  
**Version:** 1.0

---

## 📋 CC Response Format

```
Thank you for the comprehensive overview of [NODE-NAME] deployment!

I've parsed your input and organized it into preliminary charter sections. 
Before I conduct the deep dive on the knowledge repositories, I have [N] 
clarifying questions to ensure I fully understand your vision and requirements.

These questions will help me focus my research and generate an accurate charter.
```

---

## ❓ Question Categories & Templates

### **SCOPE QUESTIONS**

#### **Q1: Feature Implementation Priority**
```
You mentioned implementing [DESCRIBE FEATURES/CAPABILITIES].

Based on initial review, this includes:
• [Capability 1]
• [Capability 2]
• [Capability 3]
• [Additional capabilities...]

Should I prioritize these in phases, or is the goal to deploy 
all capabilities simultaneously in this initial deployment?

If phased:
- Which capabilities are MUST-HAVE for phase 1?
- Which can be deferred to future enhancements?
```

#### **Q2: Integration Scope**
```
You mentioned integration with [INTEGRATION-POINT-1] and [INTEGRATION-POINT-2].

Clarification needed:
• Is [INTEGRATION-COMPONENT] IN SCOPE for this charter?
  - OR is it a separate project/charter?
• If in scope:
  - Should it be deployed as part of [NODE-NAME]?
  - OR as a separate service/component?
  - Should it be tested as part of this deployment?

This affects scope, timeline, and success criteria significantly.
```

---

### **INTEGRATION QUESTIONS**

#### **Q3: Processing Pipeline Integration**
```
You described this [PIPELINE/WORKFLOW]:
[COMPONENT-1] → [COMPONENT-2] → [COMPONENT-3] → [COMPONENT-4]

Questions:
• Is the full pipeline integration IN SCOPE for this charter?
  - OR just the [PRIMARY-NODE] deployment?
• If full pipeline in scope:
  - Should the [INTEGRATION-POINT] be tested end-to-end?
  - What's the success criteria for [KEY-OUTPUT]?
  - Should [FINAL-DESTINATION] be validated?

• If just [PRIMARY-NODE] in scope:
  - Where does this charter end?
  - Is pipeline integration a separate phase/charter?
```

#### **Q4: Dependency Integration**
```
You mentioned integrating with [DEPENDENT-SERVICE] [DESCRIBE-ROLE].

Clarification:
• Is [DEPENDENT-SERVICE] ALREADY operational?
  - If yes: I'll treat it as dependency (verify operational)
  - If no: Should [SERVICE] deployment be in THIS charter?

• Integration method:
  - Direct API calls?
  - Queue-based (async processing)?
  - What protocol? (HTTP, gRPC, other?)

This affects architecture and deployment plan.
```

---

### **SUCCESS CRITERIA QUESTIONS**

#### **Q5: Deployment Success Definition**
```
What defines "successful deployment" for this project?

Please rank in priority:
[ ] [PRIMARY-FUNCTIONALITY] operational
[ ] Integration with [DEPENDENT-SERVICE] verified
[ ] [INTEGRATION-COMPONENT] functional
[ ] Full [PIPELINE] tested end-to-end
[ ] Performance benchmarks met (if so, what benchmarks?)
[ ] Documentation complete
[ ] Other: _______________

Top 3 success criteria:
1. 
2. 
3. 
```

#### **Q6: Testing Requirements**
```
You mentioned testing [SPECIFIC-PROCESS/COMPONENT].

Testing scope:
• Unit tests: Individual component functionality?
• Integration tests: End-to-end pipeline?
• Performance tests: Throughput, latency benchmarks?
• Load tests: Concurrent [OPERATION] processing?

What level of testing is required for deployment approval?
```

---

### **INFRASTRUCTURE QUESTIONS**

#### **Q7: Infrastructure Requirements**
```
You mentioned [INFRASTRUCTURE-COMPONENT-1] and [INFRASTRUCTURE-COMPONENT-2].

Questions:
• Does [NODE-NAME] require [COMPONENT] for its operation?
  - I'll verify this during repo deep dive
• If required:
  - Use existing [EXISTING-SERVER] ([IP-ADDRESS])?
  - OR deploy new instances?

• Is [RELATED-COMPONENT] needed?
  - If so, is that in scope or separate?
```

#### **Q8: Deployment Method**
```
You specified [DEPLOYMENT-CONSTRAINTS] deployment.

Confirmation:
• Installation method: [METHOD-OPTIONS]?
• Service management: systemd service?
• Configuration management: Manual procedures + systemd (no Ansible playbooks)
• Secret management: Ansible Vault only (credentials storage; no playbooks)
• Updates/maintenance: Manual or automated?

This affects the deployment plan and operational procedures.
```

---

### **TIMELINE & PHASING QUESTIONS**

#### **Q9: Timeline Expectations**
```
Do you have a target timeline for this deployment?

• Hard deadline: [date] - Must be operational by...
• Soft target: [timeframe] - Prefer completion within...
• Quality-first: No specific deadline, done when done right

This helps me estimate phases and resource allocation.
```

---

## 📊 Repository List Confirmation Template

**After parsing CAIO input, CC identifies repositories needed:**

```
Based on your input and initial analysis, I've identified these 
repositories for deep dive:

PRIMARY:
• [primary-repo] - [primary-purpose]

INTEGRATION REPOSITORIES:
• [integration-repo-1] - [purpose]
• [integration-repo-2] - [purpose]
• [integration-repo-3] - [purpose]

SUPPORTING REPOSITORIES:
• [supporting-repo-1] - [purpose]
• [supporting-repo-2] - [purpose]

ARCHITECTURE & STANDARDS:
• architecture-standards.md - Deployment patterns
• deployment-requirements.md - Standards compliance

Have I identified all crucial repositories for this deployment?

Are there any other repositories I should review that would impact:
• Technical implementation?
• Integration patterns?
• Architecture decisions?
• Deployment approach?

Please confirm or add missing repositories before I begin deep dive.
```

---

## 📝 Response Format Options

**Provide CAIO with flexible response options:**

```
How to Respond:

Option 1: Answer all questions inline
Q1: [Your answer]
Q2: [Your answer]
...
Repository List: [Confirmed / Add: repo-name, repo-name]

Option 2: Prioritize and answer critical ones first
Critical answers needed:
Q[X], Q[Y], Q[Z] [Your answers]
Others can be determined during research/refinement

Option 3: Provide additional context
Let me clarify some background first...
[Additional context]
Then answers to questions...
```

---

## 🎯 Customization Guidelines for CC

**When using this template:**

1. **Replace placeholders** with specifics from CAIO's input:
   - [NODE-NAME] → actual node name
   - [INTEGRATION-POINT] → specific service/system
   - [CAPABILITY-X] → actual features mentioned

2. **Adjust question count** based on complexity:
   - Simple deployment: 5-7 questions
   - Complex integration: 8-10 questions
   - Don't overwhelm with questions

3. **Focus questions** based on what CAIO provided:
   - If scope unclear → More scope questions
   - If integrations complex → More integration questions
   - If success undefined → More success criteria questions

4. **Repository list** should be exhaustive:
   - Primary repo (the main technology)
   - All integration points mentioned
   - Related/supporting repos
   - Always ask CAIO to confirm/add

5. **Adapt language** to match CAIO's input style:
   - Technical input → Technical questions
   - High-level input → Clarifying detail questions

---

## ⚠️ Important Reminders for CC

**Before sending questions to CAIO:**

```
CHECK:
├─ [ ] All placeholders replaced with specifics
├─ [ ] Questions directly related to CAIO's input
├─ [ ] Repository list is comprehensive
├─ [ ] Questions are clear and unambiguous
├─ [ ] Response options provided
└─ [ ] Question count appropriate (not overwhelming)

AVOID:
├─ Generic questions that could apply to any project
├─ Questions answered in CAIO's original input
├─ Technical jargon without context
├─ Asking for information you'll find in repo research
└─ Too many questions (>10 is overwhelming)
```

---

## 📋 Next Steps After CAIO Answers

```
Once CAIO responds:

1. ✓ Confirm repository list is complete
   
2. ✓ Proceed to Knowledge Vault Deep Dive
   Duration: 30-45 minutes
   Use: knowledge-vault-research-plan-template.md
   
3. ✓ Document technical findings
   
4. ✓ Prepare Round 2 questions (post-research)
   - Technical decisions based on repo findings
   - Options discovered during research
   - Gaps that need CAIO input
   
5. ✓ Generate charter draft
   - Based on CAIO answers + research
   - All sections populated
   - Ready for CAIO review
```

---

## 🔗 Related Documents

**Workflows:**
- [Charter Workflow](/home/agent0/HX-Infrastructure/procedures/charter-workflow.md)

**Templates:**
- [Knowledge Vault Research Template](/home/agent0/HX-Infrastructure/templates/knowledge-vault-research-template.md) (Next Phase)
- [Charter Template](/home/agent0/HX-Infrastructure/templates/charter-template.md) (Final Output)

**Reference:**
- [Constitution](/home/agent0/HX-Infrastructure/constitution.md)
- [Knowledge Vault Catalog](/home/agent0/HX-Infrastructure/hx-agents/hx-knowledge-vault-catalog.md)

---

**Template Version:** 1.0
**Last Updated:** 2025-11-16
**Used In:** Phase 3 of Charter Creation Workflow
**Maintained By:** Agent Zero (CC)
