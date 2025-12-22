# Shebang! Marketing Screenshots

High-resolution screenshots of the Shebang! development portal for marketing materials.

## Files

| Screenshot | Description | Resolution | Size |
|------------|-------------|------------|------|
| `dashboard.png` | Main dashboard with kanban board, metrics, and quick start | 1920x1080 | 201KB |
| `features.png` | Features page showing all 145 implemented features | 1920x1080 | 425KB |
| `git-history.png` | Git history with AI-enriched commit messages | 1920x1080 | 258KB |
| `docs-index.png` | Documentation index with all available docs | 1920x1080 | 110KB |
| `roadmap.png` | Roadmap documentation with 5-phase plan | 1920x1080 | 1.6MB |
| `features-doc.png` | FEATURES.md documentation page | 1920x1080 | 2.4MB |

## Automation

Screenshots are captured using the automated script:

```bash
# Start the web portal first
python3 web/server.py

# In another terminal, run the screenshot script
python3 scripts/capture-screenshots.py
```

The script uses Playwright (or Selenium as fallback) for browser automation and captures full-page screenshots at 1920x1080 resolution with 2x device scale for retina quality.

## Usage Guidelines

These screenshots are intended for:
- Marketing website
- GitHub README
- Social media posts
- Presentations
- Documentation

All screenshots are under The Unlicense (public domain) and can be used freely.

## Regeneration

To update screenshots after UI changes:

1. Start the portal: `python3 web/server.py`
2. Run the automation: `python3 scripts/capture-screenshots.py`
3. Screenshots will be overwritten in this directory

The automation script is configured to capture:
- Dashboard (/)
- Features page (/features)
- Git history (/git-history)
- Docs index (/docs)
- Roadmap (/docs/ROADMAP.md)
- Features documentation (/docs/FEATURES.md)

To add new pages, edit the `PAGES` list in `scripts/capture-screenshots.py`.

---

Generated: 2025-12-21
