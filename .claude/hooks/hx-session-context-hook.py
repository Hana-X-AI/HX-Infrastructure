#!/usr/bin/env python3
"""
Hook: HX-Infrastructure Session Context Injection
Event: SessionStart
Purpose: Inject critical lessons learned and infrastructure philosophy at session start

This ensures Agent Zero is reminded of past failures BEFORE making new mistakes.
"""

import json
import sys

CRITICAL_REMINDERS = """
## MANDATORY PRE-ACTION REMINDERS - Agent Zero

### Infrastructure Philosophy (MEMORIZE THIS):
1. **ALL FIREWALLS ARE DISABLED** - Never mention firewall configuration
2. **MANUAL PROCEDURES ONLY** - No automation scripts, no Ansible playbooks
3. **Documentation = Deliverable** - Write manual steps for humans to execute
4. **Ansible Vault ONLY for credentials** - No Ansible playbooks ever

### File Structure Rules (VERIFY BEFORE EVERY WRITE):
- `charter.md` → MUST be in `charter/` subdirectory
- `node-spec.md` → MUST be in `specification/` subdirectory
- Only `README.md` allowed in project root
- ALL file names lowercase with hyphens (no UPPERCASE)

### Before EVERY Action:
1. Read the project charter FIRST
2. Check lessons-learned.md for past mistakes
3. Verify file paths match standards BEFORE writing
4. No assumptions - verify everything

### Known Violations to NEVER Repeat:
- ❌ Firewall configuration (firewalls are OFF)
- ❌ Ansible playbooks (manual procedures only)
- ❌ Deployment scripts (document manual steps instead)
- ❌ Automation of any kind (backup, cleanup, etc.)
- ❌ Files in project root (use proper subdirectories)
- ❌ UPPERCASE filenames (use lowercase-with-hyphens)

**Reference:** /home/agent0/HX-Infrastructure/lessons-learned.md (23 "Never Again" commitments)
"""

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    # Inject critical context at session start
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": CRITICAL_REMINDERS
        }
    }))
    sys.exit(0)

if __name__ == '__main__':
    main()
