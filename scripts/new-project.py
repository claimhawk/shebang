#!/usr/bin/env python3
"""
Create a new Shebang project in the specified directory.

Usage:
    python3 new-project.py --name "My Project" --description "Description" --path /path/to/create

This creates:
    <path>/<project-name>/
        .shebang/           - Full Shebang tooling layer (docs, web, templates, etc.)
        .claude/            - Claude Code configuration
        README.md           - Project readme
        CLAUDE.md           - Agent instructions
        .gitignore          - Git ignore file
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# Find Shebang root (where this script lives is scripts/)
SCRIPT_DIR = Path(__file__).parent
SHEBANG_ROOT = SCRIPT_DIR.parent
SHEBANG_DOCS_DIR = SHEBANG_ROOT / '.shebang'  # Full Shebang tooling layer
CLAUDE_DIR = SHEBANG_ROOT / '.claude'
TEMPLATES_DIR = SHEBANG_ROOT / 'templates' / 'project' / '.shebang'

# Files/folders to exclude when copying .shebang/
SHEBANG_EXCLUDE = [
    '*.local.*',      # Local-only files
    '__pycache__',    # Python cache
    '.DS_Store',      # macOS files
]


def slugify(name: str) -> str:
    """Convert project name to kebab-case slug."""
    slug = name.lower()
    slug = re.sub(r'[\s_]+', '-', slug)
    slug = re.sub(r'[^a-z0-9-]', '', slug)
    slug = re.sub(r'-+', '-', slug)
    slug = slug.strip('-')
    return slug or 'project'


def should_exclude(path: Path) -> bool:
    """Check if a path should be excluded from copying."""
    name = path.name
    for pattern in SHEBANG_EXCLUDE:
        if pattern.startswith('*'):
            if pattern[1:] in name:
                return True
        elif name == pattern:
            return True
    return False


def copy_shebang_folder(src_dir: Path, dest_dir: Path) -> None:
    """Copy .shebang folder, excluding local files."""
    if not src_dir.exists():
        return

    dest_dir.mkdir(parents=True, exist_ok=True)

    for item in src_dir.iterdir():
        if should_exclude(item):
            continue

        dest_path = dest_dir / item.name

        if item.is_dir():
            shutil.copytree(
                item,
                dest_path,
                ignore=shutil.ignore_patterns(*SHEBANG_EXCLUDE)
            )
        else:
            shutil.copy2(item, dest_path)


def create_project(
    name: str,
    description: str = '',
    project_type: str = '',
    tech_stack: str = '',
    target_path: str = '.'
) -> tuple[bool, str, Optional[Path]]:
    """Create a new project structure."""

    # Validate .shebang source exists
    if not SHEBANG_DOCS_DIR.exists():
        return False, f"Shebang docs not found at {SHEBANG_DOCS_DIR}", None

    # Generate slug
    project_slug = slugify(name)

    # Create project directory
    target = Path(target_path).resolve()
    project_dir = target / project_slug
    shebang_dir = project_dir / '.shebang'

    if project_dir.exists():
        return False, f"Directory already exists: {project_dir}", None

    try:
        # Create project directory
        project_dir.mkdir(parents=True)

        # Copy entire .shebang folder (docs, web, templates, examples, etc.)
        copy_shebang_folder(SHEBANG_DOCS_DIR, shebang_dir)

        # Copy template files (kanban.json, metrics.json) to overwrite with clean versions
        if TEMPLATES_DIR.exists():
            for template_file in ['kanban.json', 'metrics.json']:
                src = TEMPLATES_DIR / template_file
                if src.exists():
                    shutil.copy(src, shebang_dir / template_file)

        # Create config.yaml with project info
        config_content = f"""name: "{name}"
description: "{description}"
created: "{datetime.now().isoformat()}"
type: "{project_type}"
tech_stack: "{tech_stack}"
tags: {json.dumps([t.strip() for t in project_type.split(',') if t.strip()])}
"""
        (shebang_dir / 'config.yaml').write_text(config_content)

        # Initialize kanban with timestamp
        kanban_path = shebang_dir / 'kanban.json'
        if kanban_path.exists():
            kanban = json.loads(kanban_path.read_text())
            kanban['lastUpdated'] = datetime.now().isoformat()
            kanban_path.write_text(json.dumps(kanban, indent=2))

        # Initialize metrics with timestamp
        metrics_path = shebang_dir / 'metrics.json'
        if metrics_path.exists():
            metrics = json.loads(metrics_path.read_text())
            metrics['lastUpdated'] = datetime.now().isoformat()
            metrics['timeline'] = {
                'startDate': datetime.now().isoformat(),
                'activeHours': 0,
                'calendarHours': 0
            }
            metrics_path.write_text(json.dumps(metrics, indent=2))

        # Copy .claude folder with skills, commands, and hooks
        if CLAUDE_DIR.exists():
            project_claude_dir = project_dir / '.claude'
            shutil.copytree(
                CLAUDE_DIR,
                project_claude_dir,
                ignore=shutil.ignore_patterns('*.local.*', 'implementation', '__pycache__')
            )

        # Create README.md
        readme_content = f"""# {name}

{description}

---

## Getting Started

This project was created with [Shebang!](https://github.com/MichaelONeal/Shebang).

### Development

```bash
# Start the Shebang dashboard
python3 .shebang/web/server.py

# Open http://localhost:8080 to see your project
```

### Tech Stack

{tech_stack or 'Not specified'}

---

*Created: {datetime.now().strftime('%Y-%m-%d')}*
"""
        (project_dir / 'README.md').write_text(readme_content)

        # Create CLAUDE.md
        claude_md_content = f"""# CLAUDE.md — Agent Operating Manual

This file provides guidance to AI agents working in this repository.

## Project: {name}

{description}

## Quick Reference

| What | Where |
|------|-------|
| **Best practices** | `.shebang/BEST_PRACTICES.md` |
| **Anti-patterns** | `.shebang/ANTI_PATTERNS.md` |
| **Code standards** | `.shebang/CODE_QUALITY.md` |
| **Agent workflow** | `.shebang/system.md` |
| **Documentation** | `.shebang/docs/` |
| **Dashboard** | `.shebang/web/server.py` |

## Commands

```bash
# Start dashboard
python3 .shebang/web/server.py

# View at http://localhost:8080
```

## Code Standards

- Follow existing patterns in the codebase
- Write tests for new functionality
- Keep functions small and focused

## Git Commits

- Use conventional commit messages
- Keep commits atomic and focused
"""
        (project_dir / 'CLAUDE.md').write_text(claude_md_content)

        # Create .gitignore
        gitignore_content = """# Shebang local data
.shebang/*.local.*
.shebang/web/data/*.local.json

# Common ignores
node_modules/
__pycache__/
*.pyc
.env
.env.local
.DS_Store
*.log
dist/
build/
.venv/
venv/
"""
        (project_dir / '.gitignore').write_text(gitignore_content)

        # Copy PHILOSOPHY.md to root (the design contract)
        philosophy_src = SHEBANG_ROOT / 'PHILOSOPHY.md'
        if philosophy_src.exists():
            shutil.copy2(philosophy_src, project_dir / 'PHILOSOPHY.md')

        return True, f"Project created at {project_dir}", project_dir

    except Exception as e:
        # Clean up on failure
        if project_dir.exists():
            shutil.rmtree(project_dir)
        return False, f"Failed to create project: {e}", None


def main():
    parser = argparse.ArgumentParser(description='Create a new Shebang project')
    parser.add_argument('--name', required=True, help='Project name')
    parser.add_argument('--description', default='', help='Project description')
    parser.add_argument('--type', default='', help='Project type (Personal, Client, etc.)')
    parser.add_argument('--tech', default='', help='Technology stack')
    parser.add_argument('--path', default='.', help='Path where to create the project')
    parser.add_argument('--json', action='store_true', help='Output as JSON')

    args = parser.parse_args()

    success, message, project_path = create_project(
        name=args.name,
        description=args.description,
        project_type=args.type,
        tech_stack=args.tech,
        target_path=args.path
    )

    if args.json:
        result = {
            'success': success,
            'message': message,
            'projectPath': str(project_path) if project_path else None,
            'projectName': slugify(args.name),
            'techStack': args.tech
        }
        print(json.dumps(result))
    else:
        if success:
            print(f"✓ {message}")
            print()
            print("Created:")
            print(f"  {project_path}/")
            print(f"  ├── .shebang/        (full Shebang tooling)")
            print(f"  │   ├── docs/        (documentation)")
            print(f"  │   ├── web/         (dashboard server)")
            print(f"  │   ├── templates/   (project templates)")
            print(f"  │   └── *.md         (best practices, testing, etc.)")
            print(f"  ├── .claude/         (skills, commands, hooks)")
            print(f"  ├── CLAUDE.md        (agent instructions)")
            print(f"  ├── PHILOSOPHY.md    (design contract)")
            print(f"  ├── README.md")
            print(f"  └── .gitignore")
            print()
            print("Next steps:")
            print(f"  cd {project_path.name}")
            print(f"  git init")
            print(f"  python3 .shebang/web/server.py  # Start dashboard")
            print()
        else:
            print(f"✗ {message}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
