#!/usr/bin/env python3
"""PostToolUse hook: Auto-format and add copyright headers.

This script is called by Claude Code after Edit or Write tool operations.
It performs two automatic maintenance tasks:

1. Copyright Headers: Adds the appropriate copyright header to new Python
   files that don't already have one. Finds the nearest COPYRIGHT.txt
   by searching upward from the file's directory.

2. Code Formatting: Runs `ruff format` on Python files to maintain
   consistent code style.

Input (JSON via stdin):
    {
        "file_path": "/path/to/file.py",
        "tool_result": {...}
    }

Output (JSON via stdout):
    {"action": "none"}
    {"action": "context", "message": "Added copyright header; Auto-formatted"}

Usage:
    echo '{"file_path": "src/new_file.py"}' | python post_write.py
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from utils import read_input, respond, context_message, no_action, logger

# Repository root (two levels up from scripts/guardrails/)
REPO_ROOT = Path(__file__).resolve().parents[2]


def find_copyright(file_path: Path) -> str | None:
    """Find the nearest COPYRIGHT.txt for a file.

    Searches upward from the file's directory until reaching REPO_ROOT.

    Args:
        file_path: Path to the file being processed.

    Returns:
        Copyright header text, or None if not found.
    """
    current = file_path.parent.resolve()
    repo_root = REPO_ROOT.resolve()

    while current >= repo_root:
        copyright_file = current / "COPYRIGHT.txt"
        if copyright_file.exists():
            return copyright_file.read_text().strip()
        if current == repo_root:
            break
        current = current.parent

    # Fall back to repo root
    root_copyright = repo_root / "COPYRIGHT.txt"
    if root_copyright.exists():
        return root_copyright.read_text().strip()

    return None


def has_copyright(content: str) -> bool:
    """Check if content already has a copyright header.

    Args:
        content: File content to check.

    Returns:
        True if copyright header is present.
    """
    # Check first 500 chars for any copyright indicator
    header = content[:500].lower()
    return "copyright" in header or "license" in header


def add_copyright_if_missing(file_path: Path) -> bool:
    """Add copyright header if missing.

    Args:
        file_path: Path to the Python file.

    Returns:
        True if copyright was added, False otherwise.
    """
    if not file_path.exists():
        return False

    if file_path.suffix != ".py":
        return False

    try:
        content = file_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return False

    # Already has copyright
    if has_copyright(content):
        return False

    # Find appropriate copyright
    copyright_text = find_copyright(file_path)
    if not copyright_text:
        return False

    # Handle shebang line
    lines = content.split("\n", 1)
    if lines and lines[0].startswith("#!"):
        shebang = lines[0]
        rest = lines[1] if len(lines) > 1 else ""
        new_content = f"{shebang}\n{copyright_text}\n\n{rest}"
    else:
        new_content = f"{copyright_text}\n\n{content}"

    try:
        file_path.write_text(new_content, encoding="utf-8")
        logger.info(f"Added copyright header to {file_path}")
        return True
    except OSError as e:
        logger.error(f"Failed to add copyright to {file_path}: {e}")
        return False


def run_ruff_format(file_path: Path) -> bool:
    """Run ruff format on a Python file.

    Args:
        file_path: Path to the Python file.

    Returns:
        True if formatting was applied, False otherwise.
    """
    if file_path.suffix != ".py":
        return False

    if not file_path.exists():
        return False

    try:
        # Check if ruff is available
        result = subprocess.run(
            ["ruff", "format", str(file_path), "--quiet", "--check"],
            capture_output=True,
            timeout=10,
        )

        # If check passes (exit 0), file is already formatted
        if result.returncode == 0:
            return False

        # File needs formatting, apply it
        result = subprocess.run(
            ["ruff", "format", str(file_path), "--quiet"],
            capture_output=True,
            timeout=10,
        )

        if result.returncode == 0:
            logger.info(f"Formatted {file_path} with ruff")
            return True

        return False

    except subprocess.TimeoutExpired:
        logger.warning(f"Ruff format timed out for {file_path}")
        return False
    except FileNotFoundError:
        # Ruff not installed - silently skip
        return False
    except OSError as e:
        logger.error(f"Failed to run ruff on {file_path}: {e}")
        return False


def main() -> None:
    """Main entry point for the hook."""
    data = read_input()

    file_path_str = data.get("file_path", "")
    if not file_path_str:
        respond(no_action())
        return

    file_path = Path(file_path_str)

    # Skip non-Python files
    if file_path.suffix != ".py":
        respond(no_action())
        return

    messages: list[str] = []

    # Add copyright if missing
    if add_copyright_if_missing(file_path):
        messages.append("Added copyright header")

    # Run ruff format
    if run_ruff_format(file_path):
        messages.append("Auto-formatted with ruff")

    if messages:
        respond(context_message("; ".join(messages)))
    else:
        respond(no_action())


if __name__ == "__main__":
    main()
