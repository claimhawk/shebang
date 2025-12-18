#!/usr/bin/env bash
# Security sweep: Scan for potential secrets in the codebase
# Usage: ./scripts/security-sweep.sh [directory]

set -euo pipefail

target_dir="${1:-.}"

echo "Security sweep of: $target_dir"
echo "=========================================="

# Define patterns to search for
patterns=(
    # API Keys
    "sk-[a-zA-Z0-9]{48}"              # OpenAI
    "sk-ant-[a-zA-Z0-9-]{20,}"        # Anthropic
    "ghp_[a-zA-Z0-9]{36}"             # GitHub PAT
    "gho_[a-zA-Z0-9]{36}"             # GitHub OAuth
    "AKIA[0-9A-Z]{16}"                # AWS Access Key
    "AIza[0-9A-Za-z_-]{35}"           # Google API Key
    "hf_[a-zA-Z0-9]{34}"              # HuggingFace

    # Private Keys
    "BEGIN RSA PRIVATE KEY"
    "BEGIN PRIVATE KEY"
    "BEGIN OPENSSH PRIVATE KEY"
    "BEGIN EC PRIVATE KEY"

    # Connection Strings
    "mongodb\+srv://[^:]+:[^@]+@"
    "postgres://[^:]+:[^@]+@"
    "mysql://[^:]+:[^@]+@"

    # Common secret patterns
    "password\s*=\s*['\"][^'\"]{8,}"
    "secret\s*=\s*['\"][^'\"]{8,}"
    "api_key\s*=\s*['\"][^'\"]{8,}"
)

found_issues=0

for pattern in "${patterns[@]}"; do
    echo ""
    echo "Checking for: $pattern"
    echo "---"

    # Search for pattern, excluding common false positive locations
    matches=$(grep -rniE "$pattern" "$target_dir" \
        --include="*.py" \
        --include="*.js" \
        --include="*.ts" \
        --include="*.json" \
        --include="*.yaml" \
        --include="*.yml" \
        --include="*.toml" \
        --include="*.env*" \
        --exclude-dir=".git" \
        --exclude-dir="node_modules" \
        --exclude-dir=".venv" \
        --exclude-dir="venv" \
        --exclude-dir="__pycache__" \
        --exclude="*.lock" \
        --exclude="package-lock.json" \
        2>/dev/null || true)

    if [ -n "$matches" ]; then
        echo "⚠️  POTENTIAL SECRETS FOUND:"
        echo "$matches"
        found_issues=$((found_issues + 1))
    else
        echo "✓ None found"
    fi
done

echo ""
echo "=========================================="
if [ $found_issues -gt 0 ]; then
    echo "⚠️  Found $found_issues potential issues. Review above matches."
    exit 1
else
    echo "✓ Security sweep complete. No obvious secrets found."
    exit 0
fi
