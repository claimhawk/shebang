---
name: block-silent-exceptions
enabled: true
event: file
action: block
conditions:
  - field: content
    operator: regex_match
    pattern: "except[^:]*:\\s*\\n\\s*(pass|\\.\\.\\.)"
  - field: file_path
    operator: regex_match
    pattern: \.py$
---

**Silent Exception Handler Detected - BLOCKED**

Silently swallowing exceptions hides bugs and makes debugging impossible.

**Bad:**
```python
try:
    process_data(data)
except Exception:
    pass  # NEVER DO THIS
```

**Good - Log with context:**
```python
try:
    process_data(data)
except DataValidationError as e:
    logger.warning("Data validation failed", error=str(e), data_id=data.id)
    # Decide: re-raise, return default, or handle specifically
```

**Good - Specific exception handling:**
```python
try:
    result = external_api.fetch(resource_id)
except ConnectionError:
    logger.warning("API connection failed, using cached data")
    result = cache.get(resource_id)
except TimeoutError:
    logger.error("API timeout", resource_id=resource_id)
    raise ServiceUnavailableError("External API unavailable") from e
```

**Rules:**
1. Always specify the exception type you're catching
2. Log the error with relevant context
3. Either re-raise, return a sensible default, or convert to a domain exception
4. Never silently suppress exceptions
