---
name: document-sync
description: Synchronize text changes across multiple files. Use when updating taglines, brand text, version numbers, or any content that appears in multiple places.
---

# Document Sync

Automatically updates text across all relevant files when brand messaging, taglines, or repeated content changes.

## When to Use

- Tagline or slogan changes
- Version number updates
- Brand name changes
- Copyright year updates
- Any text that appears in multiple files

## Workflow

1. **Identify the change** - What text is being updated?
2. **Find all occurrences** - Use Grep to find all files containing the old text
3. **Review matches** - Show user what will be changed
4. **Apply changes** - Update all files consistently
5. **Verify** - Confirm all changes were applied

## Files to Check

When syncing brand/marketing text, always check:
- `README.md`
- `docs/index.md`
- `docs/BRAND.md`
- `BRAND.md`
- `docs/marketing/*.md`
- `web/*.html`
- Any file containing the old text

## Example

```
User: Change the tagline from "X" to "Y"

Agent:
1. grep -r "X" to find all occurrences
2. Show: "Found in 5 files: README.md, docs/index.md, ..."
3. Update each file
4. Report: "Updated 5 files with new tagline"
```

## Important

- Always show the user what files will be changed before making changes
- Preserve surrounding formatting and context
- Don't change text that looks similar but has different meaning
