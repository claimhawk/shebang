# Copyright (c) 2025 Your Name. All rights reserved.
# Licensed under the MIT License.
"""Tests for the calculator module."""
from __future__ import annotations

import pytest

from example.calculator import Calculator, Operation


class TestCalculator:
    """Tests for Calculator class."""

    def setup_method(self) -> None:
        """Set up test fixtures."""
        self.calc = Calculator()

    def test_add_positive_numbers(self) -> None:
        """Test adding two positive numbers."""
        result = self.calc.add(2, 3)
        assert result.value == 5
        assert result.operation == Operation.ADD
        assert result.operands == (2, 3)

    def test_add_negative_numbers(self) -> None:
        """Test adding negative numbers."""
        result = self.calc.add(-2, -3)
        assert result.value == -5

    def test_subtract(self) -> None:
        """Test subtraction."""
        result = self.calc.subtract(5, 3)
        assert result.value == 2
        assert result.operation == Operation.SUBTRACT

    def test_multiply(self) -> None:
        """Test multiplication."""
        result = self.calc.multiply(4, 5)
        assert result.value == 20
        assert result.operation == Operation.MULTIPLY

    def test_divide(self) -> None:
        """Test division."""
        result = self.calc.divide(10, 2)
        assert result.value == 5
        assert result.operation == Operation.DIVIDE

    def test_divide_by_zero_raises(self) -> None:
        """Test that dividing by zero raises ValueError."""
        with pytest.raises(ValueError, match="Cannot divide by zero"):
            self.calc.divide(10, 0)

    def test_calculate_dispatch(self) -> None:
        """Test calculate method dispatches correctly."""
        result = self.calc.calculate(Operation.ADD, 1, 2)
        assert result.value == 3

        result = self.calc.calculate(Operation.MULTIPLY, 3, 4)
        assert result.value == 12
