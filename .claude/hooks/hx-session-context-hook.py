#!/usr/bin/env python3
"""
Hook: HX-Infrastructure Session Context Injection
Event: SessionStart
Purpose: Inject critical lessons learned and infrastructure philosophy at session start

This ensures Agent Zero is reminded of past failures BEFORE making new mistakes.
"""

import json
import os
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

**Reference:** {lessons_path} (23 "Never Again" commitments)
"""

def get_lessons_path():
    """
    Compute the path to lessons-learned.md relative to the repository root.
    Supports environment variable override for flexibility.
    """
    # Allow environment variable override
    if 'LESSONS_PATH' in os.environ:
        return os.environ['LESSONS_PATH']
    
    # Compute relative to script location: .claude/hooks/ -> repo root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(os.path.dirname(script_dir))  # Go up two levels
    lessons_path = os.path.join(repo_root, 'lessons-learned.md')
    
    # Validate file exists
    if not os.path.isfile(lessons_path):
        print(f"[WARNING] lessons-learned.md not found at expected location: {lessons_path}", file=sys.stderr)
        return "lessons-learned.md (path not resolved)"
    
    return lessons_path

def main():
    # Attempt to read input (optional for SessionStart hooks)
    input_data = None
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        # Input is optional for SessionStart - log but continue
        print(f"[DEBUG] No valid JSON input received (this is normal for SessionStart): {e}", file=sys.stderr)
    except Exception as e:
        # Unexpected errors should be logged and exit with error code
        print(f"[ERROR] Unexpected error reading hook input: {e}", file=sys.stderr)
        sys.exit(1)

    # Resolve lessons-learned.md path portably
    lessons_path = get_lessons_path()
    
    # Format the context with the resolved path
    context_message = CRITICAL_REMINDERS.format(lessons_path=lessons_path)
    
    # Inject critical context at session start
    # Note: input_data is available if provided, but not required for this hook
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context_message
        }
    }))
    sys.exit(0)

if __name__ == '__main__':
    main()
