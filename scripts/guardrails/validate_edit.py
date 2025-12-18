#!/usr/bin/env python3
"""PreToolUse hook: Validate file edit/write operations.

This script is called by Claude Code before Edit or Write tool operations.
It checks if the target file path matches any protected patterns and
either blocks the operation or issues a warning.

Input (JSON via stdin):
    {
        "file_path": "/path/to/file.py",
        "old_string": "...",  // For Edit
        "new_string": "...",  // For Edit
        "content": "..."      // For Write
    }

Output (JSON via stdout):
    {"decision": "allow"}
    {"decision": "allow", "warning": "..."}
    {"decision": "deny", "reason": "..."}

Usage:
    echo '{"file_path": ".env"}' | python validate_edit.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from utils import load_config, read_input, respond, deny, allow


def validate_file_path(file_path: str, config: dict) -> dict:
    """Validate a file path against protected patterns.

    Args:
        file_path: The file path to validate.
        config: Configuration dictionary with protected_paths.

    Returns:
        Response dictionary (allow or deny).
    """
    if not file_path:
        return allow(tool="Edit")

    protected = config.get("protected_paths", {})

    # Check blocked patterns first
    for pattern in protected.get("block", []):
        try:
            if re.search(pattern, file_path, re.IGNORECASE):
                return deny(
                    f"Protected file: '{file_path}' matches blocked pattern '{pattern}'",
                    tool="Edit",
                )
        except re.error:
            # Skip invalid regex patterns
            continue

    # Check warning patterns
    for pattern in protected.get("warn", []):
        try:
            if re.search(pattern, file_path, re.IGNORECASE):
                return allow(
                    warning=f"Editing sensitive file: {file_path}",
                    tool="Edit",
                )
        except re.error:
            continue

    return allow(tool="Edit")


def main() -> None:
    """Main entry point for the hook."""
    config = load_config()
    data = read_input()

    file_path = data.get("file_path", "")

    result = validate_file_path(file_path, config)
    respond(result)


if __name__ == "__main__":
    main()
