# Shebang Philosophy

> **Shebang** — *A development environment that actually gets you*

*Built for agentic coding in the real world. From first principles, in the environment itself.*

## The Vision

Shebang is what happens when you combine **Emacs**, the **Unix philosophy**, and **Git** — filtered through 60 years of programming knowledge and delivered as a modern environment where **the interface gets out of your way**.

This isn't a text editor with AI tacked on. It's a new paradigm: an environment where you just *tell* it what you want, and six decades of software engineering wisdom becomes infrastructure.

## The Problem We're Solving

Programming has accumulated 60 years of hard-won wisdom:

- **Shell wizardry**: `find . -name "*.js" | xargs grep -l "TODO" | head -10`
- **Git acrobatics**: `git rebase -i HEAD~3`, `git reflog`, `git cherry-pick`
- **Build system archaeology**: Makefiles, CMake, Webpack, Vite, Turbopack
- **Coding standards**: PEP 8, ESLint configs, prettier, editorconfig
- **Deployment rituals**: Docker, Kubernetes, CI/CD pipelines, secrets management

This isn't tribal knowledge or gatekeeping. This is **hard-fought, hard-won expertise**:

- Long hours over years and years
- A hundred books to find a few good pieces
- Teams of pragmatic programmers asking first-principles questions
- Mentorship chains stretching back decades
- Battle scars from production incidents at 3am

Every piece of this wisdom took someone blood and sweat to discover. And now it's **distilled into the agent**.

## What Shebang Is

### Emacs, Without the Learning Curve

Emacs got it right: a self-modifying environment that adapts to you, where the tool and the work become one. But Emacs demands you learn its language first — keybindings, elisp, modes, buffers.

Shebang keeps the power, drops the curve. Natural language is the interface.

### Unix, Without the Memorization

The Unix philosophy got it right: small tools that compose, text streams, everything is a file. But Unix demands you memorize incantations — pipes, flags, obscure utilities.

Shebang keeps the philosophy, drops the memorization. The AI knows the incantations.

### Git, Without the Headaches

Git got it right: distributed version control, branches as cheap experiments, the reflog as a safety net. But Git demands you understand its mental model — DAGs, refs, the index.

Shebang keeps the power, handles the headaches. You say "undo that"; it figures out if that means reset, revert, or checkout.

### Screen/Tmux, Without the Keybindings

Tmux and Screen got it right: persistent sessions, multiplexing, the ability to detach and reattach. But they demand you memorize key sequences — `Ctrl-b %`, `Ctrl-a c`, prefix modes.

Shebang keeps the persistence, drops the keybindings. Sessions are visual. Click to switch. Type to create. The terminal multiplexer becomes invisible.

## Core Principles

### 1. The Interface Gets Out of Your Way

The best interface is the one you don't think about. The command bar is a conversation, not a command line. Say what you want; Shebang figures out how.

```
"make the tests pass"
"deploy to staging"
"what changed since yesterday"
"fix the build"
```

### 2. Terminal as Single Source of Truth

**The terminal is the single source of truth.** Not the file system API. Not a database. Not an abstraction layer. The terminal.

This is an architectural principle, not just a UI choice:

```
┌────────────────────────────────────────────────────────────┐
│                     The Terminal                           │
│                (Single Source of Truth)                    │
├────────────────────────────────────────────────────────────┤
│                          │                                 │
│    ┌─────────────────────┼─────────────────────┐          │
│    │                     │                     │          │
│    ▼                     ▼                     ▼          │
│ File Browser        Git Status          Working Dir       │
│  (via `ls`)       (via `git`)           (via `pwd`)       │
│    │                     │                     │          │
│    ▼                     ▼                     ▼          │
│   UI                    UI                    UI          │
└────────────────────────────────────────────────────────────┘
```

**Why this matters:**

- **File browser uses `ls`** — Not FileManager, not stat(). If `ls` shows it, the browser shows it. Consistency guaranteed.
- **Git status uses `git`** — Not libgit2, not some library. The real git binary.
- **State derives from commands** — Every piece of UI state traces back to a terminal command.

**The result:** What you see in the UI is *exactly* what you'd see if you typed the command yourself.

No "well, the API says this but the terminal shows that" debugging. No permission inconsistencies. No hidden state. **One source of truth.**

But here's the thing: **you don't need to know the incantations to use it.**

Everything flows through the terminal because:

- **Transparency**: Every action is auditable
- **Reproducibility**: Terminal history is a log of what happened
- **Escape hatch**: Power users can always drop down to shell
- **AI operates here**: Agents work in the terminal, not in some abstracted API layer
- **Consistency**: UI always matches terminal output

The terminal shows you what's happening. The command bar lets you talk to it in plain English. You don't need to memorize `grep -rn "pattern" --include="*.js" | xargs sed -i 's/old/new/g'` to do find-and-replace. You just say "replace old with new in all JavaScript files."

The terminal is there for those who want to see it. It's not required for those who don't.

### 3. Sandboxed Shell Customization

**Shebang NEVER touches your system settings.** No modifications to `~/.zshrc`, `~/.bashrc`, or any dotfiles. Ever.

Instead, Shebang provides an **in-app shell layer** — aliases, functions, and environment variables that only exist inside Shebang:

```swift
// Example: Agent-created aliases that live ONLY in Shebang
shebang.alias("gst", "git status")
shebang.alias("gco", "git checkout")
shebang.function("deploy", """
    git push origin main && ssh prod 'cd /app && ./deploy.sh'
""")
```

**Why this matters:**

- **Agents can automate workflows** — The agent creates aliases and functions as it works, building up a vocabulary of shortcuts
- **No system pollution** — Your terminal outside Shebang remains untouched
- **Portable sessions** — Aliases travel with the session, not with the machine
- **Safe experimentation** — Try anything without fear of breaking your shell

**The adapter pattern:**

```
┌─────────────────────────────────────────────────────────────┐
│                     Your System Shell                        │
│                   (~/.zshrc, ~/.bashrc)                     │
│                        UNTOUCHED                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Shebang   │
                    │  Adapter    │
                    │  Layer      │
                    └──────┬──────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   Shebang Shell Environment                  │
│                                                              │
│   In-App Aliases    │   Agent Functions   │   Session Env   │
│   (user-created)    │   (auto-generated)  │   (project)     │
└─────────────────────────────────────────────────────────────┘
```

The agent becomes more capable as it works — learning shortcuts, building functions, creating an **environment that evolves with you**.

### 4. Reactive, Not Project-Rooted

Traditional IDEs anchor to a project root. Shebang follows *you*.

`cd` somewhere? The file browser updates. Switch branches? The context shifts. Open a new terminal? Everything stays in sync.

The environment reflects your current reality, not a config file.

### 5. Knowledge Becomes Infrastructure

Every coding standard, every best practice, every "you should really..." becomes built-in behavior:

- Type safety isn't a lint rule — it's automatic
- Tests aren't an afterthought — they're suggested
- Security isn't a checklist — it's enforced
- Performance isn't optimization — it's the default

The AI has read the books. You don't have to.

### 6. Agentic by Design

Shebang isn't an IDE with an AI assistant. It's an **agentic environment** — built from the ground up for AI agents to operate alongside humans:

- The terminal is the execution layer for agents
- The command bar is the interface for both humans and AI
- Sessions can run autonomously or interactively
- Multiple agents can work in parallel across sessions

The architecture assumes agents. They're not bolted on — they're first-class citizens.

### 7. Claude Code as First-Class Citizen

**Claude Code** is integrated at the deepest level — not as a plugin, not as an extension, but as a core execution engine:

- Commands route to Claude Code when natural language is detected
- The terminal *is* Claude Code's native environment
- Sessions are designed around Claude Code's agentic workflow
- The system prompt (`system.md`) configures Claude Code behavior per-project

This isn't "Claude Code support." This is Claude Code **as the foundation**.

**Coming soon**: Integration with other AI CLIs:
- **Gemini CLI** — Google's agentic terminal interface
- **GitHub Copilot CLI** — `gh copilot` commands
- **Amazon Q** — AWS development assistant
- **Custom agents** — Bring your own via MCP servers

Shebang is the universal frontend for agentic development. The AI backend is pluggable.

### 8. Built With Itself

Shebang is built using Shebang. Not as a party trick, but as a constraint that forces good design:

- If the tool can't build itself, it's not good enough
- Every pain point we hit, we fix immediately
- The tool improves as we use it
- `/reload` makes iteration instant

This is the ultimate dogfooding: the environment *is* the development environment.

## What This Enables

### For New Developers

Start contributing on day one. No need to learn:
- The shell
- The build system
- The test framework
- The deployment pipeline
- The coding standards

Just describe what you want to accomplish.

### For Experienced Developers

Stop context-switching. Stop looking up flags. Stop writing boilerplate. Focus on the architecture, the design, the parts that actually need human judgment.

### For Teams

Onboarding becomes trivial. Consistency becomes automatic. Knowledge transfer happens through the AI, not tribal documentation.

## The Name

`#!` (shebang) is the Unix mechanism that tells the system how to execute a script. Two characters that bridge human intent and machine execution.

That's exactly what we're building: the bridge between "what I want" and "how it happens."

---

## Origin

Shebang was envisioned and created by **Michael O'Neal** — a software architect with 30 years of experience who now works in machine learning. Built from first principles, in the environment itself.

---

*60 years of programming knowledge, available to everyone.*

*The interface gets out of your way. The work remains.*
