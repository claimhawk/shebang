#!/usr/bin/env python3
"""PreToolUse hook: Detect secrets in file content.

This script is called by Claude Code before Edit or Write tool operations.
It scans the content being written for patterns that match known secret types
(API keys, tokens, private keys, connection strings, etc.).

Input (JSON via stdin):
    {
        "file_path": "/path/to/file.py",
        "content": "...",      // For Write
        "new_string": "..."    // For Edit
    }

Output (JSON via stdout):
    {"decision": "allow"}
    {"decision": "deny", "reason": "Content contains GitHub PAT..."}

Usage:
    echo '{"content": "api_key = ghp_abc123..."}' | python validate_secrets.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from utils import load_config, read_input, respond, deny, allow


def scan_for_secrets(content: str, config: dict) -> tuple[bool, str]:
    """Scan content for secret patterns.

    Args:
        content: The content to scan.
        config: Configuration dictionary with secrets patterns.

    Returns:
        Tuple of (found_secret, secret_name).
    """
    if not content:
        return False, ""

    secrets = config.get("secrets", [])

    for secret in secrets:
        pattern = secret.get("pattern", "")
        name = secret.get("name", "unknown secret")

        if not pattern:
            continue

        try:
            if re.search(pattern, content):
                return True, name
        except re.error:
            # Skip invalid regex patterns
            continue

    return False, ""


def main() -> None:
    """Main entry point for the hook."""
    config = load_config()
    data = read_input()

    # Check both 'content' (Write) and 'new_string' (Edit)
    content = data.get("content", "") or data.get("new_string", "")

    if not content:
        respond(allow(tool="Write"))
        return

    found, secret_name = scan_for_secrets(content, config)

    if found:
        respond(
            deny(
                f"Content contains {secret_name}. "
                "Use environment variables or a secrets manager instead.",
                tool="Write",
            )
        )
    else:
        respond(allow(tool="Write"))


if __name__ == "__main__":
    main()
