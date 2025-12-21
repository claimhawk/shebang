#!/usr/bin/env python3
"""
Create a new Shebang project in the specified directory.

Usage:
    python3 new-project.py --name "My Project" --description "Description" --path /path/to/create

This creates:
    <path>/<project-name>/.shebang/
        kanban.json     - Empty kanban board
        metrics.json    - Zeroed metrics
        config.yaml     - Project configuration
"""

import argparse
import json
import os
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

# Find Shebang root (where this script lives is scripts/)
SCRIPT_DIR = Path(__file__).parent
SHEBANG_ROOT = SCRIPT_DIR.parent
TEMPLATES_DIR = SHEBANG_ROOT / 'templates' / 'project' / '.shebang'


def slugify(name: str) -> str:
    """Convert project name to kebab-case slug."""
    # Lowercase
    slug = name.lower()
    # Replace spaces and underscores with hyphens
    slug = re.sub(r'[\s_]+', '-', slug)
    # Remove non-alphanumeric (except hyphens)
    slug = re.sub(r'[^a-z0-9-]', '', slug)
    # Remove consecutive hyphens
    slug = re.sub(r'-+', '-', slug)
    # Strip leading/trailing hyphens
    slug = slug.strip('-')
    return slug or 'project'


def create_project(
    name: str,
    description: str = '',
    project_type: str = '',
    tech_stack: str = '',
    target_path: str = '.'
) -> tuple[bool, str, Path]:
    """Create a new project structure."""

    # Validate templates exist
    if not TEMPLATES_DIR.exists():
        return False, f"Templates not found at {TEMPLATES_DIR}", None

    # Generate slug
    project_slug = slugify(name)

    # Create project directory
    target = Path(target_path).resolve()
    project_dir = target / project_slug
    shebang_dir = project_dir / '.shebang'

    if project_dir.exists():
        return False, f"Directory already exists: {project_dir}", None

    try:
        # Create directories
        shebang_dir.mkdir(parents=True)

        # Copy template files
        for template_file in ['kanban.json', 'metrics.json']:
            src = TEMPLATES_DIR / template_file
            if src.exists():
                shutil.copy(src, shebang_dir / template_file)

        # Create config.yaml with project info
        config = {
            'name': name,
            'description': description,
            'created': datetime.now().isoformat(),
            'type': project_type,
            'tech_stack': tech_stack,
            'tags': [t.strip() for t in project_type.split(',') if t.strip()]
        }

        # Write config as YAML
        config_content = f"""name: "{name}"
description: "{description}"
created: "{config['created']}"
type: "{project_type}"
tech_stack: "{tech_stack}"
tags: {json.dumps(config['tags'])}
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

        # Create a README.md stub
        readme_content = f"""# {name}

{description}

---

## Getting Started

This project was created with [Shebang!](https://github.com/MichaelONeal/Shebang).

### Development

```bash
# Start the Shebang dashboard
python3 /path/to/Shebang/web/server.py

# Open http://localhost:8080 to see your project
```

### Tech Stack

{tech_stack or 'Not specified'}

---

*Created: {datetime.now().strftime('%Y-%m-%d')}*
"""
        (project_dir / 'README.md').write_text(readme_content)

        # Create .gitignore
        gitignore_content = """# Shebang local data
.shebang/*.local.*

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
"""
        (project_dir / '.gitignore').write_text(gitignore_content)

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
            print(f"  {project_path}/.shebang/kanban.json")
            print(f"  {project_path}/.shebang/metrics.json")
            print(f"  {project_path}/.shebang/config.yaml")
            print(f"  {project_path}/README.md")
            print(f"  {project_path}/.gitignore")
            print()
            print("Next steps:")
            print(f"  cd {project_path.name}")
            print(f"  git init")
            print()
        else:
            print(f"✗ {message}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
