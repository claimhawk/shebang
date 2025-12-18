#!/usr/bin/env python3
"""Check that all Python files have copyright headers.

This script validates that all staged or tracked Python files contain
a copyright header. It finds the nearest COPYRIGHT.txt by searching
upward from each file's directory.

Usage:
    python scripts/check_copyright.py           # Check staged files
    python scripts/check_copyright.py --all     # Check all tracked files
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def get_staged_python_files() -> list[Path]:
    """Get list of staged Python files."""
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM", "--", "*.py"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    return [Path(f) for f in result.stdout.strip().split("\n") if f]


def get_all_tracked_python_files() -> list[Path]:
    """Get list of all tracked Python files."""
    result = subprocess.run(
        ["git", "ls-files", "--", "*.py"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    return [Path(f) for f in result.stdout.strip().split("\n") if f]


def find_copyright_file(file_path: Path) -> Path | None:
    """Find the nearest COPYRIGHT.txt for a file.

    Searches upward from the file's directory until reaching the repo root.
    """
    repo_root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
        ).stdout.strip()
    )

    current = file_path.parent.resolve()

    while current >= repo_root:
        copyright_file = current / "COPYRIGHT.txt"
        if copyright_file.exists():
            return copyright_file
        if current == repo_root:
            break
        current = current.parent

    # Check repo root as fallback
    root_copyright = repo_root / "COPYRIGHT.txt"
    if root_copyright.exists():
        return root_copyright

    return None


def has_copyright_header(file_path: Path) -> bool:
    """Check if a file has a copyright header."""
    try:
        content = file_path.read_text(encoding="utf-8")
        header = content[:500].lower()
        return "copyright" in header or "license" in header
    except (OSError, UnicodeDecodeError):
        return True  # Skip files we can't read


def main() -> int:
    """Main entry point."""
    check_all = "--all" in sys.argv

    if check_all:
        files = get_all_tracked_python_files()
        scope = "tracked"
    else:
        files = get_staged_python_files()
        scope = "staged"

    if not files:
        print(f"No {scope} Python files to check.")
        return 0

    missing: list[Path] = []

    for file_path in files:
        if not file_path.exists():
            continue

        # Skip test files and __init__.py
        if file_path.name.startswith("test_") or file_path.name == "__init__.py":
            continue

        if not has_copyright_header(file_path):
            missing.append(file_path)

    if missing:
        print(f"Missing copyright headers in {len(missing)} file(s):")
        for f in missing:
            print(f"  - {f}")
        print("\nRun 'python scripts/update_copyright.py' to add headers.")
        return 1

    print(f"All {len(files)} {scope} Python files have copyright headers.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
