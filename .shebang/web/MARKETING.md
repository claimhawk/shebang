# Shebang! Marketing Website

Production-ready marketing landing page designed to drive GitHub forks and showcase the power of Shebang!

---

## Files

| File | Purpose | Deployment |
|------|---------|------------|
| `/index.html` | Standalone marketing page | GitHub Pages, Vercel, Netlify |
| `/web/marketing.html` | Local development version | localhost:8080/marketing.html |

---

## Features

### Complete Marketing Package

1. **Hero Section**
   - Bold headline: "The Complexity Barrier Has Collapsed"
   - Primary tagline: "60 years of programming knowledge, available to everyone"
   - Productivity claim: "1 hour with Shebang! = 1 day for a 2020 senior developer"
   - Dual CTAs: Fork on GitHub (primary) + Read Docs (secondary)

2. **Stats Bar**
   - 19x productivity speedup
   - 145 features built
   - 13.6K lines of code
   - 3 days development time

3. **Problem Section**
   - Three audience segments: Experienced, New, Everyone
   - Pain points clearly articulated
   - Creates urgency and relatability

4. **Solution Section**
   - Four core value props:
     - Guardrails (wisdom encoded in milliseconds)
     - Terminal as Truth (single source)
     - Knowledge Infrastructure (not prerequisites)
     - Fork-and-Go (3 commands to production)

5. **Proof Section**
   - Real metrics from git history
   - Side-by-side comparison: 2020 vs Shebang!
   - Quote highlighting velocity change

6. **Features Grid**
   - Complete feature table
   - 3-command getting started
   - Immediate value proposition

7. **Philosophy Section**
   - 8 core principles in grid layout
   - Links to full PHILOSOPHY.md
   - Brand tagline

8. **Roadmap Section**
   - 5 phases visualized
   - Current phase highlighted
   - Clear progression path

9. **Final CTA**
   - "Fork. Clone. Build." messaging
   - Terminal-style command display
   - Dual buttons: Fork + View Source

10. **Footer**
    - Links to all docs
    - Public domain license
    - Creator attribution
    - Brand tagline

---

## Design System

### Colors (from theme.yaml)

```css
--bg-primary: #1e1e1e        /* Main background */
--bg-secondary: #252526      /* Cards, sections */
--bg-tertiary: #2d2d2d       /* Hover states */
--bg-elevated: #3c3c3c       /* Borders */

--text-primary: #cccccc      /* Main text */
--text-secondary: #9d9d9d    /* Subtitles */
--text-muted: #6e6e6e        /* Hints */

--accent-primary: #9d7cd8    /* Muted purple */
--accent-light: #bb9af7      /* Light purple */
--success: #4ade80           /* Green */
--error: #f87171             /* Red */
```

### Typography

- **Headlines**: System fonts (SF Pro Display on macOS)
- **Code**: Menlo, Monaco, Consolas (monospace)
- **Body**: -apple-system, BlinkMacSystemFont, Segoe UI

### Spacing

- Section padding: 80px vertical, 24px horizontal
- Max width: 1200px
- Grid gaps: 16-32px depending on density

---

## Deployment Options

### Option 1: GitHub Pages (Recommended)

The `/index.html` file is ready for GitHub Pages deployment:

```bash
# Enable GitHub Pages in repo settings
# Source: / (root)
# Branch: main

# Your site will be live at:
# https://MichaelONeal.github.io/Shebang/
```

**No build step required.** Just enable GitHub Pages and the site goes live.

### Option 2: Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy from root directory
cd /Users/michaeloneal/development/Shebang
vercel

# Follow prompts - it will auto-detect the static site
```

### Option 3: Netlify

```bash
# Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --dir=. --prod

# Or use the web UI and drag/drop the repo
```

### Option 4: Local Preview

```bash
# Start the Shebang dev server
python3 web/server.py

# Visit:
http://localhost:8080/marketing.html
```

---

## Customization

### Update GitHub Username

Search and replace `YOUR_USERNAME` with your actual GitHub username:

```bash
# In both files
sed -i '' 's/YOUR_USERNAME/YourActualUsername/g' index.html
sed -i '' 's/YOUR_USERNAME/YourActualUsername/g' web/marketing.html
```

### Update Metrics

Metrics are pulled from `/METRICS.md`. To update:

1. Run `./scripts/generate-metrics.sh`
2. Update the stats in the HTML files with new values

### Add Screenshots

When screenshots are ready:

1. Save to `/Assets/screenshots/`
2. Add `<img>` tags in appropriate sections
3. Update OG image meta tag to use a hero screenshot

---

## SEO & Social Media

### Open Graph Tags

Already included in `<head>`:

```html
<meta property="og:title" content="Shebang! - The Complexity Barrier Has Collapsed">
<meta property="og:description" content="1 hour with Shebang! = 1 day for a 2020 experienced, senior developer.">
<meta property="og:image" content="https://raw.githubusercontent.com/MichaelONeal/Shebang/main/Assets/AppIcon.png">
```

### Twitter Card

```html
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Shebang! - The Complexity Barrier Has Collapsed">
<meta name="twitter:image" content="https://raw.githubusercontent.com/MichaelONeal/Shebang/main/Assets/AppIcon.png">
```

When you share on Twitter, Reddit, HN, etc., the card will auto-populate.

---

## Performance

### Current Stats

- File size: ~33KB (single HTML file)
- No external dependencies
- No JavaScript frameworks
- Pure CSS animations
- Loads in <100ms on fast connections

### Optimization

Already optimized:

- Inline CSS (no external stylesheets)
- Minimal DOM
- CSS Grid for layouts (no heavy frameworks)
- Smooth scrolling with native `scroll-behavior`
- Responsive breakpoints for mobile

---

## Analytics (Optional)

To add analytics, insert before `</body>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>

<!-- OR Plausible (privacy-friendly) -->
<script defer data-domain="yourdomain.com" src="https://plausible.io/js/script.js"></script>
```

---

## Testing Checklist

- [ ] All links work (especially GitHub CTAs)
- [ ] Responsive on mobile (320px+)
- [ ] Responsive on tablet (768px+)
- [ ] Responsive on desktop (1200px+)
- [ ] Smooth scroll navigation works
- [ ] All sections load correctly
- [ ] OG tags display properly (use opengraph.xyz to test)
- [ ] Twitter card renders (use cards validator)
- [ ] Fast load time (<1s)
- [ ] No console errors

---

## Brand Alignment

This marketing page follows the brand guidelines in `/BRAND.md`:

- **Voice**: Direct, confident, slightly irreverent
- **Tone**: Real, not corporate
- **Style**: Short sentences, active voice, "you" not "users"
- **Colors**: VS Code dark theme with purple accents
- **Taglines**: All primary/secondary/tertiary taglines included

---

## Conversion Funnel

### Primary Path

1. **Land on hero** → See bold claim + productivity stat
2. **Scroll to stats** → Immediate proof (19x, 145, 13.6K, 3 days)
3. **Read problem** → Identify with pain points
4. **See solution** → Understand value props
5. **View proof** → Metrics + comparison table
6. **Check features** → Concrete deliverables
7. **Final CTA** → Fork on GitHub

### Secondary Paths

- **Skeptics**: Jump to Proof section via nav
- **Philosophers**: Jump to Philosophy section
- **Planners**: Jump to Roadmap
- **Builders**: Scroll to Features and CTAs

---

## A/B Test Ideas (Future)

1. **Headline variants**:
   - Current: "The Complexity Barrier Has Collapsed"
   - Alt 1: "60 Years of Programming Knowledge, Available to Everyone"
   - Alt 2: "1 Hour with Shebang! = 1 Day for a Senior Developer"

2. **CTA variants**:
   - Current: "Fork on GitHub"
   - Alt 1: "Get Started Free"
   - Alt 2: "Clone It Now"

3. **Hero image variants**:
   - Dashboard screenshot
   - Terminal in action
   - Metrics visualization

---

## Next Steps

1. **Deploy to GitHub Pages** (5 minutes)
2. **Test on mobile devices** (10 minutes)
3. **Share on social media** (Twitter, Reddit, HN)
4. **Add to README.md** as website link
5. **Update with screenshots** when available
6. **Monitor conversion rate** (GitHub stars, forks)

---

## Maintenance

### Update Frequency

- **Metrics**: Monthly (or after major milestones)
- **Roadmap phases**: When phases complete
- **Features table**: When new major features ship
- **Testimonials**: As they come in (future section)

### Version Control

Track major changes:

```bash
# Current version
Version: 1.0.0
Created: 2025-12-21
Updated: 2025-12-21
```

---

*Built with Shebang! Marketing website completed in 1 implementation session.*

*Michael O'Neal + Shebang!*
