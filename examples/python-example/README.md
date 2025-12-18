# Example Python Project

This example demonstrates all the patterns from the Claude Autonomous Code Starter Kit.

## Structure

```
examples/python-example/
├── src/example/
│   ├── __init__.py
│   └── calculator.py       # Example module with quality patterns
├── tests/
│   └── test_calculator.py  # Example tests
├── .claude/
│   ├── communication/      # Inter-agent messaging
│   ├── plans/             # Implementation plans
│   ├── research/          # Research documents
│   ├── todos/             # Task tracking
│   └── implementation/    # Progress logs
├── pyproject.toml         # Python project configuration
└── README.md              # This file
```

## Running the Example

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

## Code Quality Patterns Demonstrated

### Type Hints

Every function has explicit type hints:

```python
def add(self, a: float, b: float) -> CalculationResult:
    ...
```

### Dataclasses for Results

Immutable result objects:

```python
@dataclass(frozen=True)
class CalculationResult:
    value: float
    operation: Operation
    operands: tuple[float, float]
```

### Enums for Discrete Values

```python
class Operation(Enum):
    ADD = "add"
    SUBTRACT = "subtract"
    ...
```

### Docstrings

Every function has a docstring with Args/Returns:

```python
def divide(self, a: float, b: float) -> CalculationResult:
    """Divide a by b.

    Args:
        a: Dividend.
        b: Divisor (must not be zero).

    Returns:
        CalculationResult with the quotient.

    Raises:
        ValueError: If b is zero.
    """
```

### Explicit Error Handling

Clear exceptions with informative messages:

```python
if b == 0:
    raise ValueError("Cannot divide by zero")
```
