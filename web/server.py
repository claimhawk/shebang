#!/usr/bin/env python3
"""
Shebang! Development Portal Server
Unified server for dashboard, git history, and documentation.
"""

import http.server
import socketserver
import os
import re
import webbrowser
import threading
import shutil
from pathlib import Path
from urllib.parse import unquote

PORT = 8080
PROJECT_ROOT = Path(__file__).parent.parent
PROJECTS_DIR = PROJECT_ROOT / 'projects'
TEMPLATES_DIR = PROJECT_ROOT / 'templates'
ACTIVE_PROJECT_FILE = PROJECT_ROOT / 'web/data/active_project.txt'

# MkDocs Material-inspired CSS for markdown rendering
MARKDOWN_CSS = """
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

    :root {
        --bg: #0d1117;
        --card: #161b22;
        --border: #30363d;
        --text: #e6edf3;
        --text-muted: #8b949e;
        --accent: #58a6ff;
        --success: #3fb950;
        --warning: #d29922;
        --purple: #a371f7;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        background: var(--bg);
        color: var(--text);
        line-height: 1.7;
        font-size: 16px;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
    }
    .header {
        position: sticky;
        top: 0;
        background: var(--bg);
        border-bottom: 1px solid var(--border);
        padding: 16px 24px;
        display: grid;
        grid-template-columns: 1fr auto 1fr;
        align-items: center;
        z-index: 100;
    }
    .logo { font-size: 20px; font-weight: 600; text-decoration: none; color: var(--text); }
    .logo span { color: var(--accent); }
    .nav { display: flex; gap: 24px; justify-content: center; }
    .header-right { display: flex; justify-content: flex-end; }
    .nav a {
        color: var(--text-muted);
        text-decoration: none;
        font-size: 14px;
        padding: 4px 8px;
        border-radius: 4px;
    }
    .nav a:hover { color: var(--accent); background: rgba(88, 166, 255, 0.1); }
    .nav a.active { color: var(--accent); background: rgba(88, 166, 255, 0.15); }
    .content {
        max-width: 900px;
        margin: 0 auto;
        padding: 48px 32px;
    }
    h1, h2, h3, h4 {
        color: var(--text);
        margin-top: 32px;
        margin-bottom: 16px;
        font-weight: 600;
        letter-spacing: -0.02em;
    }
    h1 {
        font-size: 2.2rem;
        border-bottom: 1px solid var(--border);
        padding-bottom: 12px;
        margin-top: 0;
    }
    h2 {
        font-size: 1.6rem;
        border-bottom: 1px solid var(--border);
        padding-bottom: 8px;
    }
    h3 { font-size: 1.3rem; }
    h4 { font-size: 1.1rem; }
    p {
        margin-bottom: 16px;
        letter-spacing: 0.01em;
    }
    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; }
    code {
        font-family: 'JetBrains Mono', 'SF Mono', Monaco, 'Cascadia Code', monospace;
        font-size: 0.875rem;
        background: var(--card);
        padding: 3px 8px;
        border-radius: 6px;
        border: 1px solid var(--border);
    }
    pre {
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 8px;
        padding: 20px;
        overflow-x: auto;
        margin-bottom: 20px;
        line-height: 1.5;
    }
    pre code {
        background: none;
        border: none;
        padding: 0;
        font-size: 0.9rem;
    }
    ul, ol { margin-bottom: 16px; padding-left: 24px; }
    li { margin-bottom: 8px; }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 16px;
    }
    th, td {
        border: 1px solid var(--border);
        padding: 8px 12px;
        text-align: left;
    }
    th { background: var(--card); font-weight: 600; }
    tr:nth-child(even) { background: rgba(22, 27, 34, 0.5); }
    blockquote {
        border-left: 4px solid var(--accent);
        padding-left: 16px;
        margin: 16px 0;
        color: var(--text-muted);
    }
    hr {
        border: none;
        border-top: 1px solid var(--border);
        margin: 24px 0;
    }
    .emoji { font-style: normal; }
    .breadcrumb {
        font-size: 12px;
        color: var(--text-muted);
        margin-bottom: 16px;
    }
    .breadcrumb a { color: var(--text-muted); }
    .breadcrumb a:hover { color: var(--accent); }
</style>
"""

NAV_HEADER = """
<div class="header">
    <a href="/" class="logo"><span>#!</span> Shebang!</a>
    <nav class="nav">
        <a href="/">Dashboard</a>
        <a href="/features">Features</a>
        <a href="/git-history">Git History</a>
        <a href="/docs" class="active">Docs</a>
        <a href="/docs/ROADMAP.md">Roadmap</a>
    </nav>
    <div class="header-right"></div>
</div>
"""


def get_active_project():
    """Get the currently active project name."""
    if ACTIVE_PROJECT_FILE.exists():
        return ACTIVE_PROJECT_FILE.read_text().strip()
    return 'shebang-dev'


def set_active_project(project_name: str):
    """Set the active project."""
    ACTIVE_PROJECT_FILE.write_text(project_name)


def get_project_path(project_name: str = None):
    """Get the .shebang directory path for a project."""
    if project_name is None:
        project_name = get_active_project()
    return PROJECTS_DIR / project_name / '.shebang'


def discover_projects():
    """Discover all projects in the projects directory."""
    import yaml
    projects = []
    if not PROJECTS_DIR.exists():
        return projects

    for project_dir in sorted(PROJECTS_DIR.iterdir()):
        if project_dir.is_dir():
            shebang_dir = project_dir / '.shebang'
            if shebang_dir.exists():
                config_file = shebang_dir / 'config.yaml'
                if config_file.exists():
                    try:
                        config = yaml.safe_load(config_file.read_text())
                        projects.append({
                            'id': project_dir.name,
                            'name': config.get('name', project_dir.name),
                            'description': config.get('description', ''),
                            'created': config.get('created', ''),
                            'tags': config.get('tags', [])
                        })
                    except Exception:
                        projects.append({
                            'id': project_dir.name,
                            'name': project_dir.name,
                            'description': '',
                            'created': '',
                            'tags': []
                        })
    return projects


def create_project(project_id: str, name: str, description: str = ''):
    """Create a new project from template."""
    import yaml
    from datetime import datetime

    project_dir = PROJECTS_DIR / project_id
    if project_dir.exists():
        return False, 'Project already exists'

    project_dir.mkdir(parents=True)
    shebang_dir = project_dir / '.shebang'
    shebang_dir.mkdir()

    template_dir = TEMPLATES_DIR / 'project' / '.shebang'

    shutil.copy(template_dir / 'kanban.json', shebang_dir / 'kanban.json')
    shutil.copy(template_dir / 'metrics.json', shebang_dir / 'metrics.json')

    config = {
        'name': name,
        'description': description,
        'created': datetime.now().isoformat(),
        'tags': []
    }
    (shebang_dir / 'config.yaml').write_text(yaml.dump(config, default_flow_style=False))

    kanban_data = {
        'lastUpdated': datetime.now().isoformat(),
        'columns': [
            {'id': 'backlog', 'name': 'BACKLOG', 'color': 'accent', 'tasks': []},
            {'id': 'in_progress', 'name': 'IN PROGRESS', 'color': 'warning', 'tasks': []},
            {'id': 'review', 'name': 'REVIEW', 'color': 'purple', 'tasks': []},
            {'id': 'done', 'name': 'DONE', 'color': 'success', 'tasks': []}
        ]
    }
    import json
    (shebang_dir / 'kanban.json').write_text(json.dumps(kanban_data, indent=2))

    return True, 'Project created successfully'


def simple_markdown_to_html(md_content: str) -> str:
    """Convert markdown to HTML with basic formatting."""
    html = md_content

    # Escape HTML entities first
    html = html.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

    # Headers
    html = re.sub(r'^#### (.+)$', r'<h4>\1</h4>', html, flags=re.MULTILINE)
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

    # Bold and italic
    html = re.sub(r'\*\*\*(.+?)\*\*\*', r'<strong><em>\1</em></strong>', html)
    html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
    html = re.sub(r'\*(.+?)\*', r'<em>\1</em>', html)

    # Code blocks
    html = re.sub(r'```(\w*)\n(.*?)```', r'<pre><code>\2</code></pre>', html, flags=re.DOTALL)

    # Inline code
    html = re.sub(r'`([^`]+)`', r'<code>\1</code>', html)

    # Links
    html = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', html)

    # Horizontal rules
    html = re.sub(r'^---+$', r'<hr>', html, flags=re.MULTILINE)

    # Tables
    def convert_table(match):
        lines = match.group(0).strip().split('\n')
        if len(lines) < 2:
            return match.group(0)

        result = ['<table>']
        # Header row
        headers = [cell.strip() for cell in lines[0].split('|') if cell.strip()]
        result.append('<thead><tr>')
        for h in headers:
            result.append(f'<th>{h}</th>')
        result.append('</tr></thead>')

        # Body rows (skip separator line)
        result.append('<tbody>')
        for line in lines[2:]:
            cells = [cell.strip() for cell in line.split('|') if cell.strip()]
            if cells:
                result.append('<tr>')
                for c in cells:
                    result.append(f'<td>{c}</td>')
                result.append('</tr>')
        result.append('</tbody></table>')
        return '\n'.join(result)

    html = re.sub(r'(\|.+\|\n)+', convert_table, html)

    # Unordered lists
    def convert_ul(match):
        items = match.group(0).strip().split('\n')
        result = ['<ul>']
        for item in items:
            text = re.sub(r'^[\s]*[-*] ', '', item)
            if text:
                result.append(f'<li>{text}</li>')
        result.append('</ul>')
        return '\n'.join(result)

    html = re.sub(r'(^[\s]*[-*] .+\n?)+', convert_ul, html, flags=re.MULTILINE)

    # Blockquotes
    html = re.sub(r'^> (.+)$', r'<blockquote>\1</blockquote>', html, flags=re.MULTILINE)

    # Paragraphs - wrap loose text
    lines = html.split('\n')
    result = []
    in_para = False
    for line in lines:
        stripped = line.strip()
        if not stripped:
            if in_para:
                result.append('</p>')
                in_para = False
            result.append('')
        elif stripped.startswith('<'):
            if in_para:
                result.append('</p>')
                in_para = False
            result.append(line)
        else:
            if not in_para:
                result.append('<p>')
                in_para = True
            result.append(line)
    if in_para:
        result.append('</p>')

    return '\n'.join(result)


class ShebangHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler for Shebang! portal."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(PROJECT_ROOT), **kwargs)

    def do_GET(self):
        path = unquote(self.path)

        # Route handling
        if path == '/':
            self.serve_file('web/index.html')
        elif path == '/features':
            self.serve_file('web/features.html')
        elif path == '/git-history':
            self.serve_file('web/git-history.html')
        elif path == '/docs':
            self.serve_docs_index()
        elif path.startswith('/docs/'):
            doc_path = path[6:]  # Remove '/docs/'
            self.serve_markdown(f'docs/{doc_path}')
        elif path.startswith('/web/data/') and path.endswith('.json'):
            self.serve_json(path[1:])  # Remove leading /
        elif path.startswith('/api/'):
            self.handle_api_get(path)
        elif path.startswith('/web/'):
            # Static files from web/
            super().do_GET()
        else:
            # Try to serve from project root
            super().do_GET()

    def do_POST(self):
        path = unquote(self.path)
        if path.startswith('/api/'):
            self.handle_api_post(path)
        else:
            self.send_error(405, 'Method not allowed')

    def serve_json(self, filepath: str):
        """Serve a JSON file."""
        full_path = PROJECT_ROOT / filepath
        if full_path.exists():
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(full_path.read_bytes())
        else:
            self.send_error(404, f'File not found: {filepath}')

    def handle_api_get(self, path: str):
        """Handle API GET requests."""
        import json
        if path == '/api/kanban':
            project_path = get_project_path()
            kanban_path = project_path / 'kanban.json'
            if kanban_path.exists():
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(kanban_path.read_bytes())
            else:
                self.send_error(404, 'Kanban data not found')
        elif path == '/api/metrics':
            project_path = get_project_path()
            metrics_path = project_path / 'metrics.json'
            if metrics_path.exists():
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(metrics_path.read_bytes())
            else:
                self.send_error(404, 'Metrics data not found')
        elif path == '/api/projects':
            projects = discover_projects()
            active = get_active_project()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                'projects': projects,
                'active': active
            }).encode())
        else:
            self.send_error(404, 'API endpoint not found')

    def handle_api_post(self, path: str):
        """Handle API POST requests."""
        import json
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')

        try:
            data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            self.send_error(400, 'Invalid JSON')
            return

        if path == '/api/kanban/task':
            self.add_kanban_task(data)
        elif path == '/api/kanban/move':
            self.move_kanban_task(data)
        elif path == '/api/kanban/update':
            self.update_kanban_task(data)
        elif path == '/api/projects':
            self.create_new_project(data)
        elif path == '/api/projects/select':
            self.select_project(data)
        else:
            self.send_error(404, 'API endpoint not found')

    def create_new_project(self, data: dict):
        """Create a new project."""
        import json
        import re

        name = data.get('name', '').strip()
        description = data.get('description', '').strip()

        if not name:
            self.send_error(400, 'Project name is required')
            return

        project_id = re.sub(r'[^a-z0-9-]', '', name.lower().replace(' ', '-'))

        success, message = create_project(project_id, name, description)

        if success:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'success': True, 'projectId': project_id}).encode())
        else:
            self.send_error(400, message)

    def select_project(self, data: dict):
        """Select the active project."""
        import json

        project_id = data.get('projectId', '').strip()

        if not project_id:
            self.send_error(400, 'Project ID is required')
            return

        project_path = get_project_path(project_id)
        if not project_path.exists():
            self.send_error(404, 'Project not found')
            return

        set_active_project(project_id)

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps({'success': True}).encode())

    def add_kanban_task(self, data: dict):
        """Add a new task to the kanban board."""
        import json
        from datetime import datetime

        project_path = get_project_path()
        kanban_path = project_path / 'kanban.json'
        kanban = json.loads(kanban_path.read_text())

        new_task = {
            'id': data.get('id', f"task-{datetime.now().strftime('%Y%m%d%H%M%S')}"),
            'title': data.get('title', 'New Task'),
            'description': data.get('description', ''),
            'category': data.get('category', 'feature'),
            'created': datetime.now().isoformat()
        }

        # Add to backlog by default
        target_col = data.get('column', 'backlog')
        for col in kanban['columns']:
            if col['id'] == target_col:
                col['tasks'].append(new_task)
                break

        kanban['lastUpdated'] = datetime.now().isoformat()
        kanban_path.write_text(json.dumps(kanban, indent=2))

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'success': True, 'task': new_task}).encode())

    def move_kanban_task(self, data: dict):
        """Move a task between columns."""
        import json
        from datetime import datetime

        task_id = data.get('taskId')
        target_col = data.get('targetColumn')

        if not task_id or not target_col:
            self.send_error(400, 'Missing taskId or targetColumn')
            return

        project_path = get_project_path()
        kanban_path = project_path / 'kanban.json'
        kanban = json.loads(kanban_path.read_text())

        # Find and remove task from current column
        task = None
        for col in kanban['columns']:
            for t in col['tasks']:
                if t['id'] == task_id:
                    task = t
                    col['tasks'].remove(t)
                    break
            if task:
                break

        if not task:
            self.send_error(404, 'Task not found')
            return

        # Add to target column
        for col in kanban['columns']:
            if col['id'] == target_col:
                col['tasks'].append(task)
                break

        kanban['lastUpdated'] = datetime.now().isoformat()
        kanban_path.write_text(json.dumps(kanban, indent=2))

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'success': True}).encode())

    def update_kanban_task(self, data: dict):
        """Update a task's details."""
        import json
        from datetime import datetime

        task_id = data.get('taskId')
        updates = data.get('updates', {})

        if not task_id:
            self.send_error(400, 'Missing taskId')
            return

        project_path = get_project_path()
        kanban_path = project_path / 'kanban.json'
        kanban = json.loads(kanban_path.read_text())

        # Find and update task
        found = False
        for col in kanban['columns']:
            for task in col['tasks']:
                if task['id'] == task_id:
                    task.update(updates)
                    found = True
                    break
            if found:
                break

        if not found:
            self.send_error(404, 'Task not found')
            return

        kanban['lastUpdated'] = datetime.now().isoformat()
        kanban_path.write_text(json.dumps(kanban, indent=2))

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'success': True}).encode())

    def serve_file(self, filepath: str):
        """Serve a file from the project root."""
        full_path = PROJECT_ROOT / filepath
        if full_path.exists():
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(full_path.read_bytes())
        else:
            self.send_error(404, f'File not found: {filepath}')

    def serve_docs_index(self):
        """Serve the documentation index page."""
        docs_dir = PROJECT_ROOT / 'docs'
        docs = []

        for md_file in sorted(docs_dir.rglob('*.md')):
            rel_path = md_file.relative_to(docs_dir)
            title = md_file.stem.replace('_', ' ').title()
            # Read first line for actual title
            try:
                first_line = md_file.read_text().split('\n')[0]
                if first_line.startswith('# '):
                    title = first_line[2:].strip()
            except:
                pass
            docs.append((str(rel_path), title, str(rel_path.parent)))

        # Group by directory
        grouped = {}
        for path, title, parent in docs:
            if parent == '.':
                parent = 'Core'
            else:
                parent = parent.replace('/', ' / ').title()
            if parent not in grouped:
                grouped[parent] = []
            grouped[parent].append((path, title))

        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shebang! Documentation</title>
    {MARKDOWN_CSS}
</head>
<body>
    {NAV_HEADER}
    <div class="content">
        <h1>Documentation</h1>
        <p>Complete documentation for the Shebang! Automated Development Environment.</p>
"""

        for group, files in sorted(grouped.items()):
            html += f'<h2>{group}</h2>\n<ul>\n'
            for path, title in sorted(files, key=lambda x: x[1]):
                html += f'<li><a href="/docs/{path}">{title}</a></li>\n'
            html += '</ul>\n'

        html += """
    </div>
</body>
</html>"""

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())

    def serve_markdown(self, filepath: str):
        """Render a markdown file as HTML."""
        full_path = PROJECT_ROOT / filepath

        if not full_path.exists() or not filepath.endswith('.md'):
            self.send_error(404, f'Document not found: {filepath}')
            return

        md_content = full_path.read_text()
        html_content = simple_markdown_to_html(md_content)

        # Extract title from first h1
        title = 'Shebang! Documentation'
        title_match = re.search(r'^# (.+)$', md_content, re.MULTILINE)
        if title_match:
            title = title_match.group(1)

        # Create breadcrumb
        parts = filepath.split('/')
        breadcrumb = '<a href="/">Home</a> / <a href="/docs">Docs</a>'
        for i, part in enumerate(parts[1:-1]):  # Skip 'docs' and filename
            path = '/'.join(parts[:i+2])
            breadcrumb += f' / <a href="/docs/{"/".join(parts[1:i+2])}">{part}</a>'
        breadcrumb += f' / {parts[-1]}'

        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - Shebang!</title>
    {MARKDOWN_CSS}
</head>
<body>
    {NAV_HEADER}
    <div class="content">
        <div class="breadcrumb">{breadcrumb}</div>
        {html_content}
    </div>
</body>
</html>"""

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())


def open_browser_delayed():
    """Open browser after a short delay to ensure server is ready."""
    import time
    time.sleep(0.5)
    webbrowser.open(f'http://localhost:{PORT}/')


def main():
    import subprocess
    os.chdir(PROJECT_ROOT)

    # Kill any existing process on the port
    try:
        result = subprocess.run(
            f"lsof -ti:{PORT} | xargs kill -9 2>/dev/null",
            shell=True,
            capture_output=True
        )
    except Exception:
        pass  # No process to kill

    # Open browser in background thread
    browser_thread = threading.Thread(target=open_browser_delayed, daemon=True)
    browser_thread.start()

    # Allow reuse of address to avoid "Address already in use" errors
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), ShebangHandler) as httpd:
        print(f"""
╔═══════════════════════════════════════════════════════════════╗
║                 SHEBANG! DEVELOPMENT PORTAL                   ║
╚═══════════════════════════════════════════════════════════════╝

  Dashboard:      http://localhost:{PORT}/
  Features:       http://localhost:{PORT}/features
  Git History:    http://localhost:{PORT}/git-history
  Documentation:  http://localhost:{PORT}/docs
  Roadmap:        http://localhost:{PORT}/docs/ROADMAP.md

  Browser opened automatically.
  Press Ctrl+C to stop
""")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down...")


if __name__ == '__main__':
    main()
