---
name: warn-console-statements
enabled: true
event: file
action: warn
conditions:
  - field: content
    operator: regex_match
    pattern: (console\.(log|debug|info)\(|^\s*print\s*\()
  - field: file_path
    operator: regex_match
    pattern: \.(py|ts|tsx|js|jsx)$
---

**Console/Print Statement Detected - WARNING**

Using `console.log` or `print()` in production code is discouraged.

**Why:**
1. No log levels (can't filter by severity)
2. No structured data (hard to parse in log aggregators)
3. Often forgotten and shipped to production
4. Can leak sensitive data

**Instead, use proper logging:**

**Python:**
```python
import logging

logger = logging.getLogger(__name__)

# Instead of print()
logger.debug("Processing started", extra={"user_id": user_id})
logger.info("User authenticated", extra={"user_id": user_id})
logger.warning("Rate limit approaching", extra={"remaining": remaining})
logger.error("Operation failed", exc_info=True)
```

**TypeScript:**
```typescript
import { logger } from '@/libs/logging';

// Instead of console.log()
logger.debug('Processing started', { userId });
logger.info('User authenticated', { userId });
logger.warn('Rate limit approaching', { remaining });
logger.error('Operation failed', { error });
```

**Acceptable uses:**
- CLI tools where output IS the product
- Development-only debugging (remove before commit)
- Test files for debugging test failures
