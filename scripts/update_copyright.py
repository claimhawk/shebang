#!/usr/bin/env python3
"""Add copyright headers to Python files that don't have them.

This script automatically adds copyright headers to Python files.
It finds the nearest COPYRIGHT.txt by searching upward from each
file's directory.

Usage:
    python scripts/update_copyright.py           # Update staged files
    python scripts/update_copyright.py --all     # Update all tracked files
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
    """Find the nearest COPYRIGHT.txt for a file."""
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

    root_copyright = repo_root / "COPYRIGHT.txt"
    if root_copyright.exists():
        return root_copyright

    return None


def has_copyright_header(content: str) -> bool:
    """Check if content has a copyright header."""
    header = content[:500].lower()
    return "copyright" in header or "license" in header


def add_copyright_header(file_path: Path, copyright_text: str) -> bool:
    """Add copyright header to a file.

    Args:
        file_path: Path to the Python file.
        copyright_text: The copyright text to add.

    Returns:
        True if header was added, False otherwise.
    """
    try:
        content = file_path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return False

    if has_copyright_header(content):
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
        return True
    except OSError:
        return False


def main() -> int:
    """Main entry point."""
    update_all = "--all" in sys.argv

    if update_all:
        files = get_all_tracked_python_files()
        scope = "tracked"
    else:
        files = get_staged_python_files()
        scope = "staged"

    if not files:
        print(f"No {scope} Python files to update.")
        return 0

    updated = 0
    skipped = 0

    for file_path in files:
        if not file_path.exists():
            continue

        copyright_file = find_copyright_file(file_path)
        if not copyright_file:
            print(f"  No COPYRIGHT.txt found for {file_path}, skipping.")
            skipped += 1
            continue

        copyright_text = copyright_file.read_text().strip()

        if add_copyright_header(file_path, copyright_text):
            print(f"  Added copyright to {file_path}")
            updated += 1

    print(f"\nUpdated {updated} files, skipped {skipped} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
