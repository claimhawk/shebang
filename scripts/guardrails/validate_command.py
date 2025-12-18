#!/usr/bin/env python3
"""PreToolUse hook: Validate shell commands.

This script is called by Claude Code before Bash tool operations.
It checks commands against patterns for dangerous operations
(destructive commands, force pushes, privilege escalation, etc.).

Input (JSON via stdin):
    {
        "command": "rm -rf /"
    }

Output (JSON via stdout):
    {"decision": "allow"}
    {"decision": "allow", "warning": "Potentially risky command..."}
    {"decision": "deny", "reason": "Blocked dangerous command..."}

Usage:
    echo '{"command": "rm -rf /"}' | python validate_command.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from utils import load_config, read_input, respond, deny, allow


def validate_command(command: str, config: dict) -> dict:
    """Validate a shell command against dangerous patterns.

    Args:
        command: The command to validate.
        config: Configuration dictionary with commands patterns.

    Returns:
        Response dictionary (allow or deny).
    """
    if not command:
        return allow(tool="Bash")

    commands_config = config.get("commands", {})

    # Check blocked patterns first
    for pattern in commands_config.get("block", []):
        try:
            if re.search(pattern, command, re.IGNORECASE):
                # Truncate command for display
                display_cmd = command[:60] + "..." if len(command) > 60 else command
                return deny(
                    f"Blocked dangerous command: '{display_cmd}' "
                    f"matches pattern '{pattern}'",
                    tool="Bash",
                )
        except re.error:
            # Skip invalid regex patterns
            continue

    # Check warning patterns
    for pattern in commands_config.get("warn", []):
        try:
            if re.search(pattern, command, re.IGNORECASE):
                display_cmd = command[:50] + "..." if len(command) > 50 else command
                return allow(
                    warning=f"Potentially risky command: {display_cmd}",
                    tool="Bash",
                )
        except re.error:
            continue

    return allow(tool="Bash")


def main() -> None:
    """Main entry point for the hook."""
    config = load_config()
    data = read_input()

    command = data.get("command", "")

    result = validate_command(command, config)
    respond(result)


if __name__ == "__main__":
    main()
