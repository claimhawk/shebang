#!/usr/bin/env python3
# Copyright (c) 2025 Tylt LLC. All rights reserved.
"""PreToolUse hook: Detect code quality anti-patterns.

This script is called by Claude Code before Edit or Write tool operations.
It scans code for anti-patterns specific to Python and TypeScript, enforcing
best practices from 30 years of software engineering wisdom.

Input (JSON via stdin):
    {
        "file_path": "/path/to/file.py",
        "content": "...",      // For Write
        "new_string": "..."    // For Edit
    }

Output (JSON via stdout):
    {"decision": "allow"}
    {"decision": "allow", "warning": "TODO comment found..."}
    {"decision": "deny", "reason": "Silent exception handler detected..."}

Usage:
    echo '{"file_path": "src/app.py", "content": "..."}' | python validate_quality.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from utils import load_config, read_input, respond, deny, allow


def get_file_type(file_path: str) -> str | None:
    """Determine the file type from path.

    Args:
        file_path: Path to the file.

    Returns:
        'python', 'typescript', or None if not supported.
    """
    if not file_path:
        return None

    path = Path(file_path)
    suffix = path.suffix.lower()

    if suffix == ".py":
        return "python"
    if suffix in {".ts", ".tsx", ".js", ".jsx"}:
        return "typescript"
    return None


def check_junk_drawer(file_path: str, config: dict) -> tuple[bool, str]:
    """Check if the file is in a junk drawer directory.

    Args:
        file_path: Path to the file.
        config: Configuration dictionary.

    Returns:
        Tuple of (is_junk_drawer, directory_name).
    """
    junk_drawers = config.get("junk_drawers", [])

    for drawer in junk_drawers:
        if drawer in file_path:
            return True, drawer

    return False, ""


def scan_anti_patterns(
    content: str, file_type: str, config: dict
) -> tuple[list[dict], list[dict]]:
    """Scan content for anti-patterns.

    Args:
        content: The content to scan.
        file_type: 'python' or 'typescript'.
        config: Configuration dictionary with anti_patterns.

    Returns:
        Tuple of (blocking_issues, warning_issues).
    """
    blocking_issues: list[dict] = []
    warning_issues: list[dict] = []

    if not content:
        return blocking_issues, warning_issues

    anti_patterns = config.get("anti_patterns", {})

    # Check language-specific patterns
    lang_patterns = anti_patterns.get(file_type, [])
    for pattern_def in lang_patterns:
        pattern = pattern_def.get("pattern", "")
        name = pattern_def.get("name", "Unknown anti-pattern")
        message = pattern_def.get("message", "")

        if not pattern:
            continue

        try:
            if re.search(pattern, content, re.MULTILINE):
                blocking_issues.append({"name": name, "message": message})
        except re.error:
            continue

    # Check warning patterns (language-agnostic)
    warn_patterns = anti_patterns.get("warn", [])
    for pattern_def in warn_patterns:
        pattern = pattern_def.get("pattern", "")
        name = pattern_def.get("name", "Unknown pattern")
        message = pattern_def.get("message", "")

        if not pattern:
            continue

        try:
            if re.search(pattern, content, re.MULTILINE):
                warning_issues.append({"name": name, "message": message})
        except re.error:
            continue

    return blocking_issues, warning_issues


def check_typescript_any(content: str) -> bool:
    """Check for problematic 'any' type usage in TypeScript.

    Args:
        content: The TypeScript content to check.

    Returns:
        True if problematic 'any' usage found.
    """
    # More sophisticated check - ignore comments and type guards
    lines = content.split("\n")

    for line in lines:
        # Skip comments
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("*"):
            continue

        # Check for : any type annotations
        if re.search(r":\s*any\b", line):
            # Skip if it's in a type guard or assertion
            if "as unknown" in line or "is any" in line:
                continue
            return True

    return False


def check_silent_except(content: str) -> bool:
    """Check for silent exception handlers in Python.

    Args:
        content: The Python content to check.

    Returns:
        True if silent exception handler found.
    """
    # Pattern: except (with optional type): followed by pass or ...
    pattern = r"except\s*(?:\([^)]+\)|[A-Za-z_][A-Za-z0-9_]*)?:\s*\n\s*(pass|\.\.\.)\s*\n"
    return bool(re.search(pattern, content))


def main() -> None:
    """Main entry point for the hook."""
    config = load_config()
    data = read_input()

    file_path = data.get("file_path", "")
    content = data.get("content", "") or data.get("new_string", "")

    # Determine file type
    file_type = get_file_type(file_path)

    # If not Python or TypeScript, allow
    if not file_type:
        respond(allow(tool="Write"))
        return

    # Check for junk drawer directories
    is_junk, drawer_name = check_junk_drawer(file_path, config)
    if is_junk:
        respond(
            deny(
                f"Junk drawer directory detected: '{drawer_name}'. "
                "Use domain-specific directories instead. "
                "See BEST_PRACTICES.md for proper file organization.",
                tool="Write",
            )
        )
        return

    # Scan for anti-patterns
    blocking, warnings = scan_anti_patterns(content, file_type, config)

    # If blocking issues found, deny
    if blocking:
        issue = blocking[0]
        respond(
            deny(
                f"Anti-pattern detected: {issue['name']}. {issue['message']}",
                tool="Write",
            )
        )
        return

    # If only warnings, allow with warning
    if warnings:
        warning_names = [w["name"] for w in warnings[:2]]  # Limit to first 2
        respond(
            allow(
                warning=f"Code quality notice: {', '.join(warning_names)}",
                tool="Write",
            )
        )
        return

    # All clear
    respond(allow(tool="Write"))


if __name__ == "__main__":
    main()
