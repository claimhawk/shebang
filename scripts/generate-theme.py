#!/usr/bin/env python3
"""
Generate theme files from master theme.yaml configuration.

Usage:
    python scripts/generate-theme.py

This script reads theme.yaml and generates:
    - CSS variables for web HTML files
    - CSS stylesheet for MkDocs
    - Swift Color definitions for macOS app
"""

import re
import sys
from pathlib import Path

import yaml

SCRIPT_DIR = Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent
THEME_FILE = ROOT_DIR / "theme.yaml"


def load_theme() -> dict:
    """Load theme configuration from YAML."""
    if not THEME_FILE.exists():
        print(f"Error: {THEME_FILE} not found")
        sys.exit(1)

    with open(THEME_FILE) as f:
        return yaml.safe_load(f)


def generate_css_variables(theme: dict) -> str:
    """Generate CSS :root variables from theme config."""
    colors = theme["colors"]

    lines = ["        :root {"]

    # Background colors
    lines.append(f"            --bg: {colors['bg']['primary']};")
    lines.append(f"            --card: {colors['bg']['secondary']};")
    lines.append(f"            --border: {colors['bg']['elevated']};")

    # Text colors
    lines.append(f"            --text: {colors['text']['primary']};")
    lines.append(f"            --text-muted: {colors['text']['muted']};")

    # Accent colors
    lines.append(f"            --accent: {colors['accent']['primary']};")
    lines.append(f"            --purple: {colors['accent']['light']};")

    # Semantic colors
    lines.append(f"            --success: {colors['semantic']['success']};")
    lines.append(f"            --warning: {colors['semantic']['warning']};")
    lines.append(f"            --error: {colors['semantic']['error']};")
    lines.append(f"            --orange: {colors['terminal']['orange']};")

    # Terminal colors
    lines.append(f"            --terminal-bg: {colors['bg']['primary']};")
    lines.append(f"            --terminal-green: {colors['terminal']['green']};")
    lines.append(f"            --terminal-yellow: {colors['terminal']['yellow']};")
    lines.append(f"            --terminal-red: {colors['terminal']['red']};")
    lines.append(f"            --terminal-blue: {colors['terminal']['blue']};")

    lines.append("        }")

    return "\n".join(lines)


def update_html_file(filepath: Path, css_vars: str) -> bool:
    """Update CSS variables in an HTML file."""
    if not filepath.exists():
        print(f"  Skip: {filepath} (not found)")
        return False

    content = filepath.read_text()

    # Pattern to match :root { ... } block
    pattern = r"(\s*):root\s*\{[^}]+\}"

    if not re.search(pattern, content):
        print(f"  Skip: {filepath} (no :root block found)")
        return False

    # Replace the :root block
    new_content = re.sub(pattern, css_vars, content, count=1)

    if new_content != content:
        filepath.write_text(new_content)
        print(f"  Updated: {filepath}")
        return True
    else:
        print(f"  No change: {filepath}")
        return False


def generate_mkdocs_css(theme: dict) -> str:
    """Generate MkDocs custom CSS from theme config."""
    colors = theme["colors"]

    return f"""/* Shebang Custom Theme - Auto-generated from theme.yaml */
/* DO NOT EDIT - Run: python scripts/generate-theme.py */

:root,
[data-md-color-scheme="slate"] {{
    /* Background colors */
    --md-default-bg-color: {colors['bg']['primary']};
    --md-default-bg-color--light: {colors['bg']['secondary']};
    --md-default-bg-color--lighter: {colors['bg']['tertiary']};
    --md-default-bg-color--lightest: {colors['bg']['elevated']};

    /* Primary accent - purple */
    --md-primary-fg-color: {colors['accent']['primary']};
    --md-primary-fg-color--light: {colors['accent']['light']};
    --md-primary-fg-color--dark: {colors['accent']['dark']};
    --md-primary-bg-color: {colors['bg']['primary']};
    --md-primary-bg-color--light: {colors['bg']['secondary']};

    /* Accent */
    --md-accent-fg-color: {colors['accent']['light']};
    --md-accent-fg-color--transparent: rgba(192, 132, 252, 0.1);
    --md-accent-bg-color: {colors['accent']['primary']};

    /* Text colors */
    --md-default-fg-color: {colors['text']['primary']};
    --md-default-fg-color--light: {colors['text']['secondary']};
    --md-default-fg-color--lighter: {colors['text']['muted']};
    --md-default-fg-color--lightest: {colors['text']['disabled']};

    /* Code colors */
    --md-code-bg-color: {colors['bg']['secondary']};
    --md-code-fg-color: {colors['text']['primary']};
    --md-code-hl-color: rgba(167, 139, 250, 0.2);

    /* Footer */
    --md-footer-bg-color: {colors['bg']['primary']};
    --md-footer-bg-color--dark: #06060e;

    /* Typeset */
    --md-typeset-color: {colors['text']['primary']};
    --md-typeset-a-color: {colors['accent']['primary']};

    /* Admonition colors */
    --md-admonition-bg-color: {colors['bg']['secondary']};
}}

/* Header styling */
.md-header {{
    background-color: {colors['bg']['primary']};
    border-bottom: 1px solid {colors['bg']['elevated']};
}}

/* Navigation tabs */
.md-tabs {{
    background-color: {colors['bg']['primary']};
}}

/* Sidebar */
.md-sidebar {{
    background-color: {colors['bg']['primary']};
}}

/* Code blocks */
.highlight code,
.highlighttable code,
code {{
    background-color: {colors['bg']['secondary']} !important;
    border-radius: 4px;
}}

/* Terminal-style code output */
.highlight .go {{
    color: {colors['terminal']['green']};
}}

.highlight .gp {{
    color: {colors['terminal']['yellow']};
}}

.highlight .c1,
.highlight .c {{
    color: {colors['text']['muted']};
}}

/* Links */
a {{
    color: {colors['accent']['primary']};
}}

a:hover {{
    color: {colors['accent']['light']};
}}

/* Tables */
.md-typeset table:not([class]) {{
    background-color: {colors['bg']['secondary']};
    border: 1px solid {colors['bg']['elevated']};
}}

.md-typeset table:not([class]) th {{
    background-color: {colors['bg']['tertiary']};
}}

/* Search */
.md-search__form {{
    background-color: {colors['bg']['secondary']};
    border: 1px solid {colors['bg']['elevated']};
}}

/* Cards/boxes */
.md-typeset .admonition,
.md-typeset details {{
    background-color: {colors['bg']['secondary']};
    border-color: {colors['bg']['elevated']};
}}

/* Semantic admonition colors */
.md-typeset .admonition.success,
.md-typeset details.success {{
    border-color: {colors['semantic']['success']};
}}

.md-typeset .admonition.info,
.md-typeset details.info {{
    border-color: {colors['semantic']['info']};
}}

.md-typeset .admonition.warning,
.md-typeset details.warning {{
    border-color: {colors['semantic']['warning']};
}}

.md-typeset .admonition.danger,
.md-typeset details.danger {{
    border-color: {colors['semantic']['error']};
}}
"""


def hex_to_rgb(hex_color: str) -> tuple[float, float, float]:
    """Convert hex color to RGB floats (0-1)."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0
    return (r, g, b)


def generate_swift_colors(theme: dict) -> str:
    """Generate Swift Color extensions from theme config."""
    colors = theme["colors"]

    lines = [
        "// Shebang Theme Colors - Auto-generated from theme.yaml",
        "// DO NOT EDIT - Run: python scripts/generate-theme.py",
        "",
        "import SwiftUI",
        "",
        "extension Color {",
        "    enum Shebang {",
        "        // Background colors",
    ]

    # Background colors
    for name, hex_val in colors["bg"].items():
        r, g, b = hex_to_rgb(hex_val)
        swift_name = name.replace("-", "")
        lines.append(
            f"        static let bg{swift_name.title()} = "
            f"Color(red: {r:.3f}, green: {g:.3f}, blue: {b:.3f})"
        )

    lines.append("")
    lines.append("        // Text colors")

    # Text colors
    for name, hex_val in colors["text"].items():
        r, g, b = hex_to_rgb(hex_val)
        swift_name = name.replace("-", "")
        lines.append(
            f"        static let text{swift_name.title()} = "
            f"Color(red: {r:.3f}, green: {g:.3f}, blue: {b:.3f})"
        )

    lines.append("")
    lines.append("        // Accent colors")

    # Accent colors
    for name, hex_val in colors["accent"].items():
        r, g, b = hex_to_rgb(hex_val)
        swift_name = name.replace("-", "")
        lines.append(
            f"        static let accent{swift_name.title()} = "
            f"Color(red: {r:.3f}, green: {g:.3f}, blue: {b:.3f})"
        )

    lines.append("")
    lines.append("        // Semantic colors")

    # Semantic colors
    for name, hex_val in colors["semantic"].items():
        r, g, b = hex_to_rgb(hex_val)
        lines.append(
            f"        static let {name} = "
            f"Color(red: {r:.3f}, green: {g:.3f}, blue: {b:.3f})"
        )

    lines.append("")
    lines.append("        // Terminal colors")

    # Terminal colors
    for name, hex_val in colors["terminal"].items():
        r, g, b = hex_to_rgb(hex_val)
        lines.append(
            f"        static let terminal{name.title()} = "
            f"Color(red: {r:.3f}, green: {g:.3f}, blue: {b:.3f})"
        )

    lines.append("    }")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def main():
    """Main entry point."""
    print("Loading theme.yaml...")
    theme = load_theme()
    print(f"Theme: {theme['name']} v{theme['version']}")
    print()

    # Generate CSS variables
    css_vars = generate_css_variables(theme)

    # Update web HTML files
    print("Updating web HTML files...")
    web_files = [
        ROOT_DIR / "web" / "index.html",
        ROOT_DIR / "web" / "features.html",
        ROOT_DIR / "web" / "git-history.html",
    ]
    for filepath in web_files:
        update_html_file(filepath, css_vars)

    # Generate MkDocs CSS
    print()
    print("Generating MkDocs CSS...")
    mkdocs_css = generate_mkdocs_css(theme)
    mkdocs_css_path = ROOT_DIR / "docs" / "stylesheets" / "shebang.css"
    mkdocs_css_path.parent.mkdir(parents=True, exist_ok=True)
    mkdocs_css_path.write_text(mkdocs_css)
    print(f"  Updated: {mkdocs_css_path}")

    # Generate Swift colors
    print()
    print("Generating Swift colors...")
    swift_colors = generate_swift_colors(theme)
    swift_colors_path = ROOT_DIR / "Sources" / "ShebangApp" / "Theme" / "Colors.swift"
    swift_colors_path.parent.mkdir(parents=True, exist_ok=True)
    swift_colors_path.write_text(swift_colors)
    print(f"  Updated: {swift_colors_path}")

    print()
    print("Theme generation complete!")


if __name__ == "__main__":
    main()
