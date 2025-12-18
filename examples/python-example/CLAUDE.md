# CLAUDE.md

This file provides guidance to Claude Code when working with this example project.

## Project Overview

Example project demonstrating Claude Code starter kit patterns including:
- Type hints on all functions
- Immutable dataclasses for results
- Enums for discrete values
- Comprehensive docstrings
- Full test coverage

## Commands

```bash
# Install in development mode
pip install -e ".[dev]"

# Run tests
pytest

# Run type checking
mypy src tests

# Run linting
ruff check src tests
ruff format --check src tests
```

## Code Quality

- Python 3.12+
- All code must pass ruff, mypy checks
- Maximum cyclomatic complexity: 10
- All functions require type hints and docstrings
