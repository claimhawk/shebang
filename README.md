<div align="center">
  <img src="Assets/AppIcon.png" alt="Shebang!" width="128" height="128">

  # Shebang!

  ### Automated Development Environment

  **1 hour with Shebang! = 1 day for a 2020 experienced, senior developer.**

  **60 years of programming knowledge, available to everyone.**

  **PUBLIC DOMAIN. No strings. No corporate BS. No gatekeeping.**
</div>

---

## Getting Started (Fork-and-Go)

**Fork this repo and you get the entire production-grade development environment:**

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/Shebang.git
cd Shebang

# 2. Install Python dependencies (for guardrails)
pip install pyyaml ruff mypy radon

# 3. Start the development portal (opens in browser automatically)
python3 web/server.py
```

**That's it.** The development portal opens at http://localhost:8080 with:
- Live dashboard with project metrics
- Multi-project support (manage multiple codebases from one install)
- Git history with AI-enriched commit explanations
- All documentation rendered as web pages
- Roadmap, features, and progress tracking

### What You Get Immediately

| Feature | Description |
|---------|-------------|
| **Guardrails** | PreToolUse/PostToolUse hooks that enforce code quality, block secrets, validate commands |
| **Hookify Rules** | Content-based blocking for anti-patterns, silent exceptions, junk drawer directories |
| **Agent Protocol** | `system.md` and `CLAUDE.md` templates for configuring Claude Code |
| **Dev Portal** | localhost:8080 dashboard with kanban, git history, docs, metrics |
| **Code Quality** | Python (ruff, mypy, radon) and TypeScript (ESLint, Prettier) enforcement |
| **Testing Docs** | 3000+ lines of testing best practices, anti-patterns, language guides |
| **macOS App** | Native Swift/SwiftUI development environment (optional, requires Xcode 16+) |

### Create Your Own Project

Once you've forked Shebang, use the `/new` command to create your own projects:

```
> /new

Claude will ask:
- Project name (required)
- Description (optional)

A new folder is created with:
- .shebang/ directory for project data
- README.md and .gitignore
- Empty kanban board ready for your tasks

The agent automatically detects your tech stack and generates
best practices tailored to your project.
```

### Run the Quality Checks

```bash
# Python quality checks
./scripts/pre-commit.sh

# Security sweep for secrets
./scripts/security-sweep.sh

# TypeScript checks (if using TS)
./scripts/pre-commit-ts.sh
```

---

## What This Is

Shebang is a native macOS development environment where you just *tell* it what you want. No memorizing commands. No looking up flags. No "actually you need to configure this first."

Say "make the tests pass" and it figures out the rest.

This is what happens when you combine **Emacs**, **Unix**, **Git**, and **Screen/Tmux** — then strip away 60 years of accumulated barriers and replace them with natural language.

Built from first principles. In Swift/SwiftUI. By practitioners. For practitioners.

## Why This Matters

Programming has accumulated six decades of "you had to be there" knowledge:

- Shell wizardry: `find . -name "*.js" | xargs grep -l "TODO" | head -10`
- Git archaeology: `git rebase -i HEAD~3`, `git reflog`, `git cherry-pick`
- Build system rituals: Makefiles, CMake, Webpack, Vite, Turbopack
- Deployment incantations: Docker, Kubernetes, CI/CD pipelines

Every one of these is hard-won knowledge. Every one creates a barrier. Every one is now **automatable**.

Shebang makes that knowledge infrastructure, not prerequisites.

## The Philosophy

### Terminal as First-Class Citizen (Hard-Won Wisdom, Available Instantly)

The terminal is front and center — not hidden, not "for advanced users only."

But here's the thing: **you don't need to know the incantations to use it.**

Everything flows through the terminal because that's where the work actually happens. Transparency. Reproducibility. Power users can drop to shell. AI agents operate here.

The terminal shows you what's happening. The command bar lets you talk to it in plain English.

You don't need to memorize `grep -rn "pattern" --include="*.js"` to do find-and-replace. You just say "replace old with new in all JavaScript files."

### Reactive, Not Project-Based

Traditional IDEs anchor to a project root. Shebang follows *you*.

`cd` somewhere? The file browser updates. Switch branches? The context shifts. Open a new terminal? Everything stays in sync.

The environment reflects your current reality, not a config file.

### Built With Itself

Shebang is built using Shebang. Not as a party trick, but as a forcing function:

- If the tool can't build itself, it's not good enough
- Every pain point we hit, we fix immediately
- The tool improves as we use it
- `/reload` makes iteration instant

This is the ultimate dogfooding.

### Claude Code as First-Class Citizen

**Claude Code** isn't an integration — it's the foundation. Shebang is built around Claude Code's agentic workflow:

- Natural language commands route directly to Claude Code
- The terminal *is* Claude Code's native environment
- Sessions are designed for autonomous agent work
- `system.md` configures Claude Code behavior per-project

**Coming soon**: Pluggable AI backends:
- Gemini CLI
- GitHub Copilot CLI
- Amazon Q
- Custom agents via MCP

Shebang is the universal frontend for agentic development.

## Quick Start

```bash
# Clone it
git clone https://github.com/MichaelONeal/Shebang.git
cd Shebang

# Build it (requires Xcode 16+, macOS 15+)
xcodebuild -scheme Shebang -configuration Release

# Run it
open build/Release/Shebang.app
```

Or just download the app and move it to Applications.

That's it. You're in.

## What You Can Do

### Tell It What You Want

```
"show me all the large files"
"what changed since yesterday?"
"deploy to staging"
"fix the build"
"make the tests pass"
```

### Navigate Without Thinking

- File browser updates automatically when you `cd`
- Git status shows in the prompt (✓2 ●3 +1)
- Sessions work like browser tabs — one click to switch
- Favorites let you jump to common folders instantly

### Work in Sessions

Multiple sessions running in parallel. Each with its own:
- Working directory
- Terminal history
- File browser state

Create a session for each project or task. Switch between them with one click.

### Use `/reload` During Development

Building Shebang *in* Shebang? Type `/reload` and the app rebuilds itself and restarts. Instant iteration loop.

### See Everything

Interactive mode: Live terminal, everything as it happens.
Block mode: Commands and output organized into readable blocks.

Switch between them with the toolbar.

## Key Features

- **Natural language input** — Describe what you want, it handles the how
- **Terminal-first** — Everything flows through the terminal, but you don't need to know the commands
- **Reactive** — Follows your current directory, branch, and context
- **Sessions** — Multiple workspaces, one click to switch
- **Git integration** — Status in the prompt, natural language for git operations
- **File browser** — Automatically syncs with your current location
- **Favorites** — Quick access to folders you visit often
- **Tab completion** — For file names and common commands
- **Built with itself** — `/reload` for instant iteration

## The Public Domain Commitment

Shebang is released under **The Unlicense** — completely public domain.

This means:
- Use it however you want
- Modify it however you want
- Sell it if you want
- No attribution required (though appreciated)
- No restrictions whatsoever

This isn't a product. This is knowledge made infrastructure. Power returned to the people.

The code is yours. The ideas are yours. The tools are yours.

## Who Built This

**Michael O'Neal** — 30 years as a software architect, now working in machine learning.

Built from first principles. In the environment itself. Because the tools we use shape the things we build.

## Contributing

It's public domain. Fork it. Change it. Make it yours.

**If you want to contribute back:**

1. **Fork the repo**
2. **Implement using Shebang** — dogfood it. If you're not building with the tool, you're not feeling the pain points.
3. **Use it for a week** — real-world testing. Does it actually work? Does it fit naturally into the workflow?
4. **Submit a PR** — only after you've lived with it.

**Your feature must match the spirit of the philosophy.** If it doesn't align with:
- Terminal as first-class citizen
- The interface getting out of your way
- Knowledge becoming infrastructure
- Agentic-first design

...it won't be included. Read [PHILOSOPHY.md](PHILOSOPHY.md) before proposing major features.

No CLA. No corporate approval. Just code that embodies the vision.

## What This Enables

### For New Developers

Start contributing on day one. No need to learn the shell, the build system, the test framework, the deployment pipeline, or the coding standards.

Just describe what you want to accomplish.

### For Experienced Developers

Stop context-switching. Stop looking up flags. Stop writing boilerplate.

Focus on the architecture, the design, the parts that actually need human judgment.

### For Teams

Onboarding becomes trivial. Consistency becomes automatic. Knowledge transfer happens through the AI, not tribal documentation.

## The Name

`#!` (shebang) is the Unix mechanism that tells the system how to execute a script. Two characters that bridge human intent and machine execution.

That's exactly what we're building: the bridge between "what I want" and "how it happens."

---

## License

**PUBLIC DOMAIN** — [The Unlicense](LICENSE)

This is free and unencumbered software released into the public domain. See LICENSE file for details.

---

## Links

- **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- **Philosophy**: [PHILOSOPHY.md](PHILOSOPHY.md)
- **Voice Guide**: [VOICE.md](VOICE.md)

---

*The interface gets out of your way. The work remains.*

*Built by practitioners, for practitioners. From first principles, in the environment itself.*

**Power to the people. No gatekeeping. No barriers. Just build.**

---

<div align="center">

### 🚀 We're Hiring

**ClaimHawk** builds computer-use agents that automate real work using vision-language models.

If you have a passion for machine learning (and some real background) and want to see the path to **100x developer** — we have open intern positions.

**No resumes.** Just shoot an email with your qualifications and passions to:

📧 **hello@claimhawk.app**

</div>
