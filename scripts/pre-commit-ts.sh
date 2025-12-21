#!/usr/bin/env bash
# Pre-commit quality checks for TypeScript/JavaScript files
# Usage: ./scripts/pre-commit-ts.sh [--all]
#   --all   Run checks against all tracked TS/JS files instead of staged ones

set -euo pipefail

mode="${1:-staged}"

if [ "$mode" = "--help" ] || [ "$mode" = "-h" ]; then
  echo "Usage: $0 [--all]" >&2
  echo "  --all   Run checks against all tracked TypeScript/JavaScript files." >&2
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

# Get TypeScript/JavaScript files
if [ "$mode" = "--all" ]; then
  ts_targets=$(git ls-files -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.cjs' | grep -v node_modules || true)
  scope_label="tracked TypeScript/JavaScript files"
else
  ts_targets=$(git diff --cached --name-only --diff-filter=ACM -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.cjs' | grep -v node_modules || true)
  scope_label="staged TypeScript/JavaScript files"
fi

if [ -z "$ts_targets" ]; then
  echo "No ${scope_label}. Skipping lint/type checks."
  exit 0
fi

# Check for package.json (indicates a Node.js project)
if [ ! -f "package.json" ]; then
  echo "No package.json found. Skipping TypeScript checks."
  exit 0
fi

# Check for node_modules
if [ ! -d "node_modules" ]; then
  echo "node_modules not found. Run 'npm install' first."
  exit 1
fi

echo "========================================"
echo "TypeScript/JavaScript Quality Checks"
echo "Scope: ${scope_label}"
echo "========================================"
echo ""

# ESLint check
if [ -f "node_modules/.bin/eslint" ] || command -v eslint >/dev/null 2>&1; then
  echo "Running ESLint..."
  if ! printf '%s\n' "$ts_targets" | xargs npx eslint --max-warnings 0; then
    echo ""
    echo "❌ ESLint failed. Fix the above errors before committing."
    exit 1
  fi
  echo "✓ ESLint passed"
  echo ""
else
  echo "⚠️  ESLint not found. Skipping lint check."
  echo ""
fi

# TypeScript type check (if tsconfig exists)
if [ -f "tsconfig.json" ]; then
  echo "Running TypeScript type check..."
  if ! npx tsc --noEmit; then
    echo ""
    echo "❌ TypeScript type check failed. Fix the above errors before committing."
    exit 1
  fi
  echo "✓ TypeScript passed"
  echo ""
else
  echo "⚠️  No tsconfig.json found. Skipping type check."
  echo ""
fi

# Prettier format check
if [ -f "node_modules/.bin/prettier" ] || command -v prettier >/dev/null 2>&1; then
  echo "Checking code formatting (Prettier)..."
  if ! printf '%s\n' "$ts_targets" | xargs npx prettier --check 2>/dev/null; then
    echo ""
    echo "❌ Prettier check failed. Run 'npx prettier --write <files>' to fix."
    exit 1
  fi
  echo "✓ Prettier passed"
  echo ""
else
  echo "⚠️  Prettier not found. Skipping format check."
  echo ""
fi

# Check for 'any' type usage (warning only)
echo "Checking for 'any' type usage..."
any_count=$(printf '%s\n' "$ts_targets" | xargs grep -l ':\s*any\b' 2>/dev/null | wc -l | tr -d ' ')
if [ "$any_count" -gt 0 ]; then
  echo "⚠️  Found 'any' type in $any_count file(s). Consider using proper types."
  printf '%s\n' "$ts_targets" | xargs grep -l ':\s*any\b' 2>/dev/null | head -5
  echo ""
else
  echo "✓ No 'any' types found"
  echo ""
fi

# Check for console.log statements (warning only)
echo "Checking for console.log statements..."
console_count=$(printf '%s\n' "$ts_targets" | xargs grep -l 'console\.log' 2>/dev/null | wc -l | tr -d ' ')
if [ "$console_count" -gt 0 ]; then
  echo "⚠️  Found console.log in $console_count file(s). Remove before production."
  printf '%s\n' "$ts_targets" | xargs grep -l 'console\.log' 2>/dev/null | head -5
  echo ""
else
  echo "✓ No console.log statements found"
  echo ""
fi

echo "========================================"
echo "✓ All TypeScript/JavaScript checks passed!"
echo "========================================"
