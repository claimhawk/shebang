# Copyright (c) 2025 Your Name. All rights reserved.
# Licensed under the MIT License.
"""Example calculator module demonstrating code quality patterns.

This module shows:
- Type hints on all functions
- Docstrings with Args/Returns
- Low cyclomatic complexity
- Pure functions (no side effects)
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class Operation(Enum):
    """Supported calculator operations."""

    ADD = "add"
    SUBTRACT = "subtract"
    MULTIPLY = "multiply"
    DIVIDE = "divide"


@dataclass(frozen=True)
class CalculationResult:
    """Result of a calculation.

    Attributes:
        value: The calculated value.
        operation: The operation that was performed.
        operands: The input operands.
    """

    value: float
    operation: Operation
    operands: tuple[float, float]


class Calculator:
    """A simple calculator demonstrating code quality patterns.

    This class follows functional principles:
    - Methods are pure (no side effects)
    - Results are immutable dataclasses
    - All operations are type-safe
    """

    def add(self, a: float, b: float) -> CalculationResult:
        """Add two numbers.

        Args:
            a: First operand.
            b: Second operand.

        Returns:
            CalculationResult with the sum.
        """
        return CalculationResult(
            value=a + b,
            operation=Operation.ADD,
            operands=(a, b),
        )

    def subtract(self, a: float, b: float) -> CalculationResult:
        """Subtract b from a.

        Args:
            a: First operand.
            b: Second operand.

        Returns:
            CalculationResult with the difference.
        """
        return CalculationResult(
            value=a - b,
            operation=Operation.SUBTRACT,
            operands=(a, b),
        )

    def multiply(self, a: float, b: float) -> CalculationResult:
        """Multiply two numbers.

        Args:
            a: First operand.
            b: Second operand.

        Returns:
            CalculationResult with the product.
        """
        return CalculationResult(
            value=a * b,
            operation=Operation.MULTIPLY,
            operands=(a, b),
        )

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
        if b == 0:
            raise ValueError("Cannot divide by zero")

        return CalculationResult(
            value=a / b,
            operation=Operation.DIVIDE,
            operands=(a, b),
        )

    def calculate(self, operation: Operation, a: float, b: float) -> CalculationResult:
        """Perform a calculation based on the operation type.

        Args:
            operation: The operation to perform.
            a: First operand.
            b: Second operand.

        Returns:
            CalculationResult with the result.

        Raises:
            ValueError: If operation is unknown or division by zero.
        """
        operations = {
            Operation.ADD: self.add,
            Operation.SUBTRACT: self.subtract,
            Operation.MULTIPLY: self.multiply,
            Operation.DIVIDE: self.divide,
        }

        handler = operations.get(operation)
        if handler is None:
            raise ValueError(f"Unknown operation: {operation}")

        return handler(a, b)
