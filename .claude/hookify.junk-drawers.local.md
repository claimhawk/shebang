---
name: block-junk-drawer-directories
enabled: true
event: file
action: block
conditions:
  - field: file_path
    operator: regex_match
    pattern: (utils|helpers|common|misc|shared)/(.*\.(py|ts|tsx|js|jsx))$
---

**Junk Drawer Directory Detected - BLOCKED**

Creating files in `utils/`, `helpers/`, `common/`, `misc/`, or `shared/` is prohibited.

**Why this is bad:**
1. These directories become grab-bags of unrelated code
2. No clear ownership or domain context
3. Encourages lazy organization
4. Makes code harder to find and maintain

**Instead, use domain-driven organization:**

```
# BAD
src/utils/formatDate.ts
src/helpers/validateEmail.ts
src/common/constants.ts

# GOOD
src/libs/date/format-date.ts
src/domain/users/validators/email-validator.ts
src/config/constants.ts
```

**Naming rules:**
1. Name directories for what they contain, not where you didn't know where to put things
2. Use parameterized filenames: `{domain}-{purpose}.{type}.ts`
3. Every file should have a clear, single responsibility

**See:** `BEST_PRACTICES.md` Section VII for complete directory structure guidelines.
