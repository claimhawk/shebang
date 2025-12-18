#!/usr/bin/env bash
# Pre-commit quality checks for Python files
# Usage: ./scripts/pre-commit.sh [--all]
#   --all   Run checks against all tracked Python files instead of staged ones

set -euo pipefail

mode="${1:-staged}"

if [ "$mode" = "--help" ] || [ "$mode" = "-h" ]; then
  echo "Usage: $0 [--all]" >&2
  echo "  --all   Run checks against all tracked Python files instead of staged ones." >&2
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

copyright_file="$repo_root/COPYRIGHT.txt"

if [ ! -f "$copyright_file" ]; then
  echo "WARNING: COPYRIGHT.txt not found. Skipping copyright checks."
fi

if [ "$mode" = "--all" ]; then
  py_targets=$(git ls-files -- '*.py' || true)
  scope_label="tracked Python files"
else
  py_targets=$(git diff --cached --name-only --diff-filter=ACM -- '*.py' || true)
  scope_label="staged Python files"
fi

if [ -z "$py_targets" ]; then
  echo "No ${scope_label}. Skipping lint/type checks."
  exit 0
fi

python_bin="python"
if ! command -v "$python_bin" >/dev/null 2>&1; then
  python_bin="python3"
fi

if command -v ruff >/dev/null 2>&1; then
  ruff_cmd="ruff"
else
  ruff_cmd="$python_bin -m ruff"
fi

if command -v mypy >/dev/null 2>&1; then
  mypy_cmd="mypy"
else
  mypy_cmd="$python_bin -m mypy"
fi

echo "Running ruff (lexical checks) on ${scope_label}..."
printf '%s\n' "$py_targets" | xargs -r $ruff_cmd check

echo "Running ruff format check on ${scope_label}..."
printf '%s\n' "$py_targets" | xargs -r $ruff_cmd format --check

echo "Running mypy (syntax & types) on ${scope_label}..."
printf '%s\n' "$py_targets" | xargs -r $mypy_cmd

if [ -f "$copyright_file" ]; then
  echo "Checking copyright headers..."
  $python_bin scripts/check_copyright.py
fi

echo "All checks passed!"
