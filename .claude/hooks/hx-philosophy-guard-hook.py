#!/usr/bin/env python3
"""
Hook: HX-Infrastructure Philosophy Guard
Event: UserPromptSubmit
Purpose: Block or warn when prompts contain known violation patterns

This catches violations BEFORE Claude acts on them.

File permissions: This script must be executable (chmod +x).
"""

import json
import sys
import re

# Patterns that indicate philosophy violations
VIOLATION_PATTERNS = [
    # Firewall violations
    (r'\b(configure|setup|enable|create)\s+firewall',
     "BLOCKED: Firewalls are DISABLED in HX-Infrastructure. Never configure firewalls."),

    (r'\bfirewall\s+(rule|config|script)',
     "BLOCKED: Firewalls are DISABLED in HX-Infrastructure. No firewall work needed."),

    # Automation violations
    (r'\b(ansible|playbook)\b(?!.*vault)',
     "BLOCKED: Ansible playbooks are forbidden. Only Ansible Vault for credentials is allowed."),

    (r'\b(automation|automate)\s+(script|backup|cleanup|deployment)',
     "BLOCKED: HX-Infrastructure uses MANUAL PROCEDURES only. Document manual steps instead of automating."),

    (r'\bcreate\s+(deployment|backup|cleanup)\s+script',
     "BLOCKED: No scripts. Create manual procedure documentation instead."),

    # File location violations
    (r'write.*charter\.md.*(?<!charter/)$',
     "WARNING: charter.md must be in charter/ subdirectory, not project root."),

    (r'write.*node-spec\.md.*(?<!specification/)$',
     "WARNING: node-spec.md must be in specification/ subdirectory, not project root."),
]

# Patterns that require reading charter first
CHARTER_CHECK_PATTERNS = [
    r'\b(next\s+phase|phase\s+\d|what\'?s\s+next)',
    r'\b(deploy|implementation|planning)\s+(phase|step)',
]

def check_violations(prompt: str) -> tuple:
    """Check for violation patterns. Returns (should_block, message)."""
    prompt_lower = prompt.lower()

    for pattern, message in VIOLATION_PATTERNS:
        if re.search(pattern, prompt_lower):
            if message.startswith("BLOCKED"):
                return (True, message)
            else:
                # Warning - add context but don't block
                return (False, message)

    # Check if this is a phase transition question
    for pattern in CHARTER_CHECK_PATTERNS:
        if re.search(pattern, prompt_lower):
            reminder = (
                "\n\n**MANDATORY:** Before answering phase/planning questions, "
                "you MUST read the project charter first. "
                "See lessons-learned.md commitment #19."
            )
            return (False, reminder)

    return (False, None)

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    prompt = input_data.get('prompt', '')

    should_block, message = check_violations(prompt)

    if should_block:
        # Exit 2 blocks the prompt, stderr goes to user
        print(message, file=sys.stderr)
        sys.exit(2)
    elif message:
        # Add warning as context
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": message
            }
        }))
        sys.exit(0)
    else:
        sys.exit(0)

if __name__ == '__main__':
    main()
