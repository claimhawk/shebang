#!/usr/bin/env python3
"""Shared utilities for guardrail scripts.

This module provides common functionality for all guardrail validation scripts:
- Configuration loading from config.yaml
- JSON input/output handling for Claude Code hooks
- Audit logging for tracking guardrail decisions
- Standard response helpers (allow/deny)

Usage:
    from utils import load_config, read_input, respond, deny, allow
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore[assignment]

SCRIPT_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPT_DIR / "config.yaml"
LOG_PATH = SCRIPT_DIR / "guardrails.log"

# Configure logging
logging.basicConfig(
    filename=str(LOG_PATH),
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def load_config() -> dict[str, Any]:
    """Load guardrail configuration from config.yaml.

    Returns:
        Configuration dictionary with patterns for protected_paths,
        secrets, and commands. Returns empty dict if file missing or
        yaml not installed.
    """
    if yaml is None:
        logger.warning("PyYAML not installed, using empty config")
        return {}

    if not CONFIG_PATH.exists():
        logger.warning(f"Config file not found: {CONFIG_PATH}")
        return {}

    try:
        return yaml.safe_load(CONFIG_PATH.read_text()) or {}
    except yaml.YAMLError as e:
        logger.error(f"Failed to parse config: {e}")
        return {}


def read_input() -> dict[str, Any]:
    """Read JSON input from stdin.

    Claude Code hooks pass tool parameters as JSON to stdin.
    This function safely parses that input.

    Returns:
        Parsed JSON dictionary, or empty dict if parsing fails.
    """
    try:
        if sys.stdin.isatty():
            # Interactive mode - no stdin
            return {}
        return json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return {}


def respond(data: dict[str, Any]) -> None:
    """Write JSON response to stdout.

    Claude Code hooks expect JSON responses on stdout.

    Args:
        data: Response dictionary to serialize.
    """
    print(json.dumps(data))


def log_action(tool: str, decision: str, reason: str = "") -> None:
    """Log guardrail decision for audit.

    All guardrail decisions are logged to guardrails.log for
    debugging and security auditing.

    Args:
        tool: Name of the tool being validated (Edit, Write, Bash).
        decision: The decision made (allow, deny).
        reason: Human-readable reason for the decision.
    """
    logger.info(f"tool={tool} decision={decision} reason={reason}")


def deny(reason: str, tool: str = "unknown") -> dict[str, Any]:
    """Create a deny response.

    Args:
        reason: Human-readable explanation of why the operation was denied.
        tool: Name of the tool being validated.

    Returns:
        Dictionary with decision="deny" and the reason.
    """
    log_action(tool, "deny", reason)
    return {"decision": "deny", "reason": reason}


def allow(warning: str = "", tool: str = "unknown") -> dict[str, Any]:
    """Create an allow response.

    Args:
        warning: Optional warning message to include.
        tool: Name of the tool being validated.

    Returns:
        Dictionary with decision="allow" and optional warning.
    """
    log_action(tool, "allow", warning or "passed")
    if warning:
        return {"decision": "allow", "warning": warning}
    return {"decision": "allow"}


def context_message(message: str) -> dict[str, Any]:
    """Create a context message response for PostToolUse hooks.

    Args:
        message: Message to add to the conversation context.

    Returns:
        Dictionary with action="context" and the message.
    """
    return {"action": "context", "message": message}


def no_action() -> dict[str, Any]:
    """Create a no-action response for PostToolUse hooks.

    Returns:
        Dictionary with action="none".
    """
    return {"action": "none"}
