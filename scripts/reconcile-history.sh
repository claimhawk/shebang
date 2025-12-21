#!/usr/bin/env bash
# Shebang! - Automated Development Environment
# Public Domain - https://unlicense.org
#
# reconcile-history.sh
#
# Walk through git history from init, analyze each commit with Claude CLI,
# and rewrite commit messages with architect-level explanations.
#
# Uses git worktree to avoid interfering with main branch.
#
# Usage: ./scripts/reconcile-history.sh [--dry-run]

set -euo pipefail

# Configuration
BRANCH_NAME="reconcile"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_DIR="${SCRIPT_DIR}/.worktrees/reconcile"
PHILOSOPHY_FILE="PHILOSOPHY.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
fi

# Ensure we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Get the repo root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude CLI not found. Install with: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Shebang! Git History Reconciliation              ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║  Walking history from init, adding architect-level       ║${NC}"
echo -e "${CYAN}║  explanations to each commit message.                    ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}📍 Current branch: ${CURRENT_BRANCH}${NC}"

# Get the first commit
FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD)
echo -e "${BLUE}📜 First commit: ${FIRST_COMMIT:0:7}${NC}"

# Get all commits from first to HEAD (oldest first)
COMMITS=($(git rev-list --reverse "$FIRST_COMMIT"..HEAD))
COMMITS=("$FIRST_COMMIT" "${COMMITS[@]}")
TOTAL_COMMITS=${#COMMITS[@]}
echo -e "${BLUE}📊 Total commits to process: ${TOTAL_COMMITS}${NC}"
echo

# Read philosophy for context (if it exists)
PHILOSOPHY_CONTEXT=""
if [[ -f "$PHILOSOPHY_FILE" ]]; then
    PHILOSOPHY_CONTEXT=$(cat "$PHILOSOPHY_FILE")
    echo -e "${GREEN}✓ Loaded philosophy context from ${PHILOSOPHY_FILE}${NC}"
fi

# Create worktree for reconcile branch
# IMPORTANT: All work happens in the worktree. The main branch and working
# directory are UNTOUCHED until the final reconciliation step (with confirmation).
echo -e "${YELLOW}🌳 Creating isolated worktree at ${WORKTREE_DIR}...${NC}"
echo -e "${BLUE}   (Main branch will NOT be affected until you confirm reconciliation)${NC}"

# Ensure worktrees directory exists
mkdir -p "$(dirname "$WORKTREE_DIR")"

# Clean up any existing worktree at this path
if [[ -d "$WORKTREE_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Worktree already exists. Removing it...${NC}"
    git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || rm -rf "$WORKTREE_DIR"
fi

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    echo -e "${YELLOW}⚠️  Branch '${BRANCH_NAME}' already exists. Deleting it...${NC}"
    git branch -D "$BRANCH_NAME" 2>/dev/null || true
fi

# Create new branch from first commit and set up worktree
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$FIRST_COMMIT"
echo -e "${GREEN}✓ Worktree created${NC}"
echo

# Change to worktree
cd "$WORKTREE_DIR"

# Function to analyze a commit and generate explanation
analyze_commit() {
    local commit_hash="$1"
    local commit_num="$2"

    # Get original commit info
    local original_msg=$(git log -1 --format="%B" "$commit_hash")
    local author_date=$(git log -1 --format="%aI" "$commit_hash")
    local author_name=$(git log -1 --format="%an" "$commit_hash")
    local author_email=$(git log -1 --format="%ae" "$commit_hash")

    # Get the diff for this commit
    local diff=""
    local parent=$(git rev-parse "${commit_hash}^" 2>/dev/null || echo "")

    if [[ -z "$parent" ]]; then
        # First commit - show all files added
        diff=$(git show --stat --patch "$commit_hash" 2>/dev/null | head -500)
    else
        diff=$(git diff "$parent" "$commit_hash" 2>/dev/null | head -500)
    fi

    # Get file list
    local files_changed=""
    if [[ -z "$parent" ]]; then
        files_changed=$(git show --name-only --format="" "$commit_hash")
    else
        files_changed=$(git diff --name-only "$parent" "$commit_hash")
    fi

    echo -e "${BLUE}  📄 Files changed:${NC}"
    echo "$files_changed" | head -10 | sed 's/^/      /'
    if [[ $(echo "$files_changed" | wc -l) -gt 10 ]]; then
        echo "      ... and more"
    fi

    # Create prompt for Claude
    local prompt=$(cat <<EOF
You are analyzing a git commit for the Shebang! project - an automated development environment.

## Project Philosophy (Key Principles)
1. Terminal as Single Source of Truth - all UI state derives from terminal commands
2. Sandboxed Shell Customization - in-app aliases/functions that never touch system files
3. The Interface Gets Out of Your Way - natural language, not memorized commands
4. Knowledge Becomes Infrastructure - 60 years of hard-won wisdom, available instantly
5. Agentic by Design - built for AI agents to operate alongside humans
6. Built With Itself - dogfooding as a design constraint

## Original Commit Message
${original_msg}

## Files Changed
${files_changed}

## Diff (truncated to 500 lines)
${diff}

## Your Task
Write a new commit message that:
1. Keeps the original message as the first line (summary)
2. Adds a blank line, then a "## What Changed" section with 2-4 bullet points
3. Adds a "## Why" section explaining the architectural/strategic reasoning
4. References relevant philosophy principles if applicable
5. Is written for an architect or project manager, not just developers

Format:
<original summary line>

## What Changed
- <bullet 1>
- <bullet 2>

## Why
<1-2 paragraphs of strategic explanation>

## Philosophy
<which principles this embodies, if any>

Keep it concise but informative. No more than 20 lines total.
EOF
)

    # Call Claude CLI
    local new_message=""
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}  [DRY RUN] Would call Claude CLI here${NC}"
        new_message="$original_msg

## What Changed
- [Would be generated by Claude]

## Why
[Would be generated by Claude]

## Philosophy
[Would be generated by Claude]"
    else
        echo -e "${CYAN}  🤖 Analyzing with Claude...${NC}"
        new_message=$(echo "$prompt" | claude --print 2>/dev/null || echo "$original_msg")

        # Fallback if claude fails
        if [[ -z "$new_message" || "$new_message" == "$original_msg" ]]; then
            echo -e "${YELLOW}  ⚠️  Claude analysis failed, keeping original message${NC}"
            new_message="$original_msg"
        fi
    fi

    echo "$new_message"
}

# Function to cherry-pick and amend a commit
process_commit() {
    local commit_hash="$1"
    local commit_num="$2"

    # Get original timestamps
    local author_date=$(git log -1 --format="%aI" "$commit_hash")
    local committer_date=$(git log -1 --format="%cI" "$commit_hash")

    echo -e "${GREEN}[$commit_num/$TOTAL_COMMITS]${NC} Processing ${commit_hash:0:7}"

    # Get the new message
    local new_message=$(analyze_commit "$commit_hash" "$commit_num")

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}  [DRY RUN] Would cherry-pick and amend${NC}"
        echo -e "${YELLOW}  New message preview:${NC}"
        echo "$new_message" | head -10 | sed 's/^/    /'
        echo
        return
    fi

    # Cherry-pick the commit
    if [[ "$commit_num" -eq 1 ]]; then
        # First commit - we're already on it, just amend
        GIT_COMMITTER_DATE="$committer_date" git commit --amend --no-edit --date="$author_date" -m "$new_message"
    else
        # Cherry-pick subsequent commits
        git cherry-pick --no-commit "$commit_hash" 2>/dev/null || {
            echo -e "${YELLOW}  ⚠️  Cherry-pick conflict, attempting to resolve...${NC}"
            git checkout --theirs . 2>/dev/null || true
            git add -A
        }

        # Commit with preserved timestamps and new message
        GIT_COMMITTER_DATE="$committer_date" git commit --date="$author_date" -m "$new_message" --allow-empty
    fi

    echo -e "${GREEN}  ✓ Commit updated${NC}"
    echo
}

# Process all commits
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Starting reconciliation...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

COUNTER=1
for commit in "${COMMITS[@]}"; do
    process_commit "$commit" "$COUNTER"
    ((COUNTER++))
done

# Cleanup and summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Reconciliation complete!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
    echo -e "${YELLOW}Run without --dry-run to actually reconcile history.${NC}"
else
    echo -e "${BLUE}📍 Reconciled branch: ${BRANCH_NAME}${NC}"
    echo -e "${BLUE}📍 Worktree location: ${WORKTREE_DIR}${NC}"
    echo

    # Verify content matches
    echo -e "${CYAN}Verifying content integrity...${NC}"
    cd "$WORKTREE_DIR"
    RECONCILE_TREE=$(git rev-parse HEAD^{tree})
    cd "$REPO_ROOT"
    MAIN_TREE=$(git rev-parse HEAD^{tree})

    TREES_MATCH=false
    if [[ "$RECONCILE_TREE" == "$MAIN_TREE" ]]; then
        echo -e "${GREEN}✓ Content verified: reconcile tree matches main tree${NC}"
        TREES_MATCH=true
    else
        echo -e "${RED}⚠️  WARNING: Trees don't match! Content may have changed.${NC}"
        echo -e "${RED}   Main tree:      $MAIN_TREE${NC}"
        echo -e "${RED}   Reconcile tree: $RECONCILE_TREE${NC}"
    fi
    echo

    # Show sample of new commit messages
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}              Sample Reconciled Commits                     ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    cd "$WORKTREE_DIR"
    git log --oneline -10
    echo
    echo -e "${CYAN}Latest commit message:${NC}"
    git log -1 --format="%B" | head -20
    echo
    cd "$REPO_ROOT"

    # Ask to reconcile back to main
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                 Reconcile to Main                          ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    if [[ "$TREES_MATCH" == "false" ]]; then
        echo -e "${RED}Cannot auto-reconcile: trees don't match.${NC}"
        echo -e "${YELLOW}Review the worktree manually at: $WORKTREE_DIR${NC}"
        echo
        echo -e "${BLUE}To manually reconcile later:${NC}"
        echo "  cd $REPO_ROOT"
        echo "  git worktree remove $WORKTREE_DIR"
        echo "  git branch main-backup main"
        echo "  git checkout $BRANCH_NAME"
        echo "  git branch -D main"
        echo "  git branch -m main"
        echo
        echo -e "${BLUE}To abort and cleanup:${NC}"
        echo "  git worktree remove $WORKTREE_DIR"
        echo "  git branch -D $BRANCH_NAME"
    else
        echo -e "${GREEN}Trees match! Ready to reconcile.${NC}"
        echo
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  ⚠️  THIS IS THE ONLY STEP THAT MODIFIES YOUR MAIN BRANCH  ${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
        echo -e "${YELLOW}This will:${NC}"
        echo "  1. Create a backup branch 'main-backup' (safety net)"
        echo "  2. Remove the worktree"
        echo "  3. Replace 'main' with '${BRANCH_NAME}'"
        echo "  4. Delete the reconcile branch"
        echo
        echo -e "${YELLOW}This will NOT push to remote (you must do that manually).${NC}"
        echo -e "${GREEN}You can always restore from 'main-backup' if needed.${NC}"
        echo

        read -p "Proceed with reconciliation? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            echo -e "${CYAN}Reconciling...${NC}"

            # Step 1: Create backup
            echo -e "${BLUE}  Creating backup branch 'main-backup'...${NC}"
            git branch -f main-backup main

            # Step 2: Remove worktree
            echo -e "${BLUE}  Removing worktree...${NC}"
            git worktree remove "$WORKTREE_DIR" --force

            # Step 3: Switch to reconcile branch
            echo -e "${BLUE}  Switching to reconcile branch...${NC}"
            git checkout "$BRANCH_NAME"

            # Step 4: Delete main and rename
            echo -e "${BLUE}  Replacing main with reconcile...${NC}"
            git branch -D main
            git branch -m main

            # Step 5: Delete reconcile ref if it still exists
            git branch -D "$BRANCH_NAME" 2>/dev/null || true

            echo
            echo -e "${GREEN}✅ Reconciliation complete!${NC}"
            echo
            echo -e "${BLUE}Current branch: $(git branch --show-current)${NC}"
            echo -e "${BLUE}Backup branch:  main-backup${NC}"
            echo
            echo -e "${CYAN}To push to remote (DANGER: rewrites remote history):${NC}"
            echo "  git push --force-with-lease origin main"
            echo
            echo -e "${CYAN}To restore from backup if needed:${NC}"
            echo "  git checkout main-backup"
            echo "  git branch -D main"
            echo "  git branch -m main"
            echo
            echo -e "${CYAN}To delete backup after verification:${NC}"
            echo "  git branch -D main-backup"
        else
            echo
            echo -e "${YELLOW}Reconciliation cancelled.${NC}"
            echo
            echo -e "${BLUE}The worktree remains at: $WORKTREE_DIR${NC}"
            echo -e "${BLUE}You can review it and run the script again.${NC}"
            echo
            echo -e "${CYAN}To manually reconcile:${NC}"
            echo "  cd $REPO_ROOT"
            echo "  git worktree remove $WORKTREE_DIR"
            echo "  git branch main-backup main"
            echo "  git checkout $BRANCH_NAME"
            echo "  git branch -D main"
            echo "  git branch -m main"
            echo
            echo -e "${CYAN}To abort and cleanup:${NC}"
            echo "  git worktree remove $WORKTREE_DIR"
            echo "  git branch -D $BRANCH_NAME"
        fi
    fi
fi

echo
echo -e "${GREEN}Michael O'Neal + Shebang!${NC}"
