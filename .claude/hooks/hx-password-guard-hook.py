#!/usr/bin/env python3
"""
Hook: Password Exposure Guard
Event: PreToolUse (Write, Edit)
Purpose: Prevent plaintext passwords from being written to non-vault files

This hook blocks the standard HX-Infrastructure password from appearing
in documentation, configuration, or other non-encrypted files.

Exit Codes:
  0 - Allow (no password exposure or vault file)
  2 - Block (plaintext password detected)
"""

import json
import sys
import re
import os

# Known passwords that should never appear in plaintext
PROTECTED_PASSWORDS = [
    'Major8859!',           # Standard service account password
    'HxInfra2025VaultPass!', # Ansible vault password
]

# Files that are allowed to contain passwords (encrypted or by design)
ALLOWED_FILES = [
    'credentials.yml',      # Ansible vault encrypted
    '.vault_password',      # Vault password file (should be gitignored)
    'defect-log.md',        # Documents the issue itself
    'lessons-learned.md',   # May reference the pattern
]

# Patterns that indicate password is referenced, not exposed
SAFE_PATTERNS = [
    r'\[SEE VAULT\]',
    r'$\{.*PASSWORD.*\}',
    r'$\{SAMBA_PASSWORD\}',
    r'vault\.credentials',
    r'ansible-vault',
]

def is_allowed_file(filepath: str) -> bool:
    """Check if file is allowed to contain passwords."""
    filename = os.path.basename(filepath)
    return filename in ALLOWED_FILES

def has_safe_pattern(content: str) -> bool:
    """Check if content uses safe password reference patterns."""
    for pattern in SAFE_PATTERNS:
        if re.search(pattern, content, re.IGNORECASE):
            return True
    return False

def check_password_exposure(content: str, filepath: str) -> list:
    """Check content for exposed passwords."""
    issues = []
    
    for password in PROTECTED_PASSWORDS:
        if password in content:
            # Find context around the password
            idx = content.find(password)
            start = max(0, idx - 40)
            end = min(len(content), idx + len(password) + 40)
            context = content[start:end].replace(password, '[PASSWORD]')
            
            issues.append({
                'password_hint': password[:4] + '****',
                'context': context,
                'filepath': filepath
            })
    
    return issues

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)
    
    tool_name = input_data.get('tool_name', '')
    tool_input = input_data.get('tool_input', {})
    
    # Only check Write and Edit operations
    if tool_name not in ['Write', 'Edit']:
        sys.exit(0)
    
    # Get file path
    filepath = tool_input.get('file_path', '')
    
    # Only check HX-Infrastructure files
    if 'HX-Infrastructure' not in filepath:
        sys.exit(0)
    
    # Allow specific files
    if is_allowed_file(filepath):
        sys.exit(0)
    
    # Get content to check
    content = ''
    if tool_name == 'Write':
        content = tool_input.get('content', '')
    elif tool_name == 'Edit':
        content = tool_input.get('new_string', '')
    
    if not content:
        sys.exit(0)
    
    # Check for password exposure
    issues = check_password_exposure(content, filepath)
    
    if issues:
        print("BLOCKED: Plaintext password detected in content", file=sys.stderr)
        print("", file=sys.stderr)
        print("This violates HX-Infrastructure security policy.", file=sys.stderr)
        print("", file=sys.stderr)
        for issue in issues:
            print(f"  Password starting with: {issue['password_hint']}", file=sys.stderr)
            print(f"  Context: ...{issue['context']}...", file=sys.stderr)
            print("", file=sys.stderr)
        
        print("Instead, use one of these approaches:", file=sys.stderr)
        print("  1. Reference vault: [SEE VAULT] or vault.credentials.samba_password", file=sys.stderr)
        print("  2. Use variable: \", file=sys.stderr)
        print("  3. Store in encrypted vault/credentials.yml", file=sys.stderr)
        print("", file=sys.stderr)
        print("Reference: standards/security-standards.md", file=sys.stderr)
        sys.exit(2)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
