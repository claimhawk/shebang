<div align="center">

# Claude Code Guardrails

### Development intelligence — commodified and distilled.

[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![TypeScript](https://img.shields.io/badge/typescript-5.0+-blue.svg)](https://www.typescriptlang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**30 years of software engineering wisdom, automatically enforced. Vibe code freely — the agent handles the rest.**

[The Idea](#-the-idea) •
[Heritage](#-heritage) •
[Quick Start](#-quick-start) •
[What Gets Caught](#-what-gets-caught)

</div>

---

## 💡 The Idea

You shouldn't need to know "all the things" to write great code.

This toolkit encodes **decades of hard-won lessons** into guardrails that run automatically. You focus on building. The agent obsesses over quality, security, and best practices in the background.

**The deal:**
- ✅ You vibe, experiment, move fast
- ✅ The agent catches anti-patterns before they ship
- ✅ Secrets get blocked before they leak
- ✅ Dangerous commands get intercepted
- ✅ Code gets auto-formatted on save
- ✅ You learn the "why" from the block messages

It's like pair programming with someone who's mass-read every post-mortem and style guide — except they never get tired and they're always watching.

---

## 📜 Heritage

Every rule here has a lineage. These aren't arbitrary style preferences — they're lessons extracted from languages and paradigms that shaped modern software:

| Principle | Origin | Era | What We Learned |
|-----------|--------|-----|-----------------|
| **Immutability** | LISP¹, Haskell² | 1958+ | Mutation causes bugs. Return new data instead. |
| **First-class functions** | LISP¹, Scheme³ | 1958+ | Pass behavior around like data. |
| **Strong typing** | ML⁴, Haskell², TypeScript | 1973+ | Catch errors at compile time, not 3am. |
| **Pure functions** | Haskell², Erlang⁵ | 1990+ | Same input → same output. No surprises. |
| **Fail fast** | Erlang⁵ | 1986+ | Crash early with context, don't hide errors. |
| **Composition over inheritance** | Gang of Four⁶, Effective Java⁷ | 1994+ | Small pieces that combine > deep hierarchies. |
| **Convention over configuration** | Ruby on Rails⁸ | 2004+ | Sensible defaults beat endless options. |

The full breakdown is in [`ANTI_PATTERNS.md`](ANTI_PATTERNS.md) — 14 sections covering everything from homoiconicity to dependency injection, with examples in Python and TypeScript.

---

## 📚 The Three Files That Matter

| File | What It Is | When To Read |
|------|------------|--------------|
| [**`ANTI_PATTERNS.md`**](ANTI_PATTERNS.md) | 14-section deep dive into programming wisdom from LISP to modern FP. The "why" behind every guardrail. | When you want to level up |
| [**`BEST_PRACTICES.md`**](BEST_PRACTICES.md) | Quick reference. Anti-patterns to avoid, code standards, security rules. | Before starting a project |
| [**`CODE_QUALITY.md`**](CODE_QUALITY.md) | Python-specific quality philosophy. Complexity limits, functional design, error handling. | When writing Python |

These documents aren't just rules — they're an education. Each pattern links back to the real-world failures that inspired it.

---

## ⚡ Quick Start

```bash
# Clone it
git clone https://github.com/your-org/claude-code-guardrails.git

# Copy to your project
cp -r claude-code-guardrails/* /path/to/your/project/

# Install deps
pip install pyyaml ruff mypy radon

# That's it. Guardrails activate automatically.
```

The moment Claude Code runs in your project, every operation gets validated. No configuration needed.

---

## 🚫 What Gets Caught

### Bad Code Patterns

The agent blocks these before they hit your codebase:

```python
# ❌ Silent exception — hides bugs for months
try:
    do_thing()
except:
    pass  # BLOCKED: "Never silently swallow exceptions"

# ❌ Print debugging — use logging
print("here")  # BLOCKED: "Use logging instead of print"
```

```typescript
// ❌ any type — defeats TypeScript's whole purpose
function process(data: any) { }  // BLOCKED: "Avoid 'any', use proper types"

// ❌ Console spam
console.log("debug")  // BLOCKED: "Remove console.log from production"
```

### Secrets (40+ Patterns)

```
❌ ghp_abc123...     → GitHub PAT detected
❌ sk-ant-xyz...     → Anthropic key detected
❌ AKIA0123...       → AWS access key detected
❌ -----BEGIN RSA... → Private key detected
```

### Dangerous Commands

```bash
❌ rm -rf /          # nope
❌ git push --force  # nope
❌ chmod 777         # nope
❌ curl ... | sh     # definitely nope
```

### Junk Drawer Directories

```
❌ utils/     → "Name it for what it IS"
❌ helpers/   → "Use domain-specific directories"
❌ common/    → "Everything has a proper home"
```

---

## 🔧 How It Works

```
┌────────────────────────────────────────────────┐
│           You write code freely                │
└────────────────────────────────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────────┐
│  PreToolUse Hooks (BEFORE it happens)          │
│  • Block protected files (.env, keys)          │
│  • Detect secrets in content                   │
│  • Catch dangerous commands                    │
│  • Flag anti-patterns                          │
│                                                │
│  → ALLOW or DENY with explanation              │
└────────────────────────────────────────────────┘
                       │
                       ▼ (if allowed)
┌────────────────────────────────────────────────┐
│  PostToolUse Hooks (AFTER it happens)          │
│  • Auto-format with ruff/prettier              │
│  • Add copyright headers                       │
│  • Apply auto-fixable lint rules               │
└────────────────────────────────────────────────┘
```

Everything happens automatically. You just code.

---

## 📊 Quality Standards

These limits exist because complexity kills projects:

### Python

| Metric | Limit | Why |
|--------|-------|-----|
| Cyclomatic complexity | ≤ 10 | Complex = buggy |
| Nesting depth | ≤ 3 | Deep = confusing |
| Function length | ≤ 50 lines | Long = doing too much |
| Parameters | ≤ 5 | Many = hidden complexity |

### TypeScript

| Metric | Limit | Why |
|--------|-------|-----|
| `any` types | **0** | Defeats the type system |
| JSX nesting | ≤ 4 | Component trees get wild |
| Nesting depth | ≤ 3 | Same as Python |

---

## ⚙️ Configuration

All patterns live in one file: `scripts/guardrails/config.yaml`

```yaml
# Secrets to detect
secrets:
  - pattern: 'ghp_[a-zA-Z0-9]{36}'
    name: GitHub Personal Access Token

# Commands to block
commands:
  block:
    - 'rm\s+-rf\s+[/~]'
    - 'git\s+push.*--force'

# Anti-patterns by language
anti_patterns:
  python:
    - pattern: 'except\s*:\s*\n\s*pass'
      name: Silent exception handler
  typescript:
    - pattern: ':\s*any\b'
      name: any type usage

# Directories that shouldn't exist
junk_drawers:
  - 'utils/'
  - 'helpers/'
```

Add your own patterns. Remove ones you disagree with. It's your codebase.

---

## 🏃 Commands

```bash
./scripts/pre-commit.sh        # Check Python (staged files)
./scripts/pre-commit.sh --all  # Check Python (all files)
./scripts/pre-commit-ts.sh     # Check TypeScript
./scripts/security-sweep.sh    # Scan for secrets
```

---

## 📄 License

MIT — do whatever you want with it.

---

## 📖 Credits & Influences

The ideas in this toolkit stand on the shoulders of giants:

<sup>**1**</sup> **LISP** (1958) — John McCarthy, MIT. The second-oldest high-level language still in use. Pioneered first-class functions, recursion, garbage collection, and the radical idea that code is data. *"Lisp is worth learning for the profound enlightenment experience you will have when you finally get it."* — Eric S. Raymond

<sup>**2**</sup> **Haskell** (1990) — Simon Peyton Jones, Philip Wadler, and the Haskell Committee. Pure functional programming, strong static typing, and the proof that side-effect-free code isn't just possible — it's practical.

<sup>**3**</sup> **Scheme** (1975) — Guy L. Steele Jr. and Gerald Jay Sussman, MIT. Lexical scoping and closures. The insight that functions can capture their environment changed everything.

<sup>**4**</sup> **ML** (1973) — Robin Milner, University of Edinburgh. Type inference and parametric polymorphism. The idea that the compiler can figure out types for you — and catch your mistakes.

<sup>**5**</sup> **Erlang** (1986) — Joe Armstrong, Ericsson. "Let it crash" philosophy. The revolutionary idea that failing fast with good error messages beats defensive programming that hides problems.

<sup>**6**</sup> **Design Patterns** (1994) — Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides (Gang of Four). "Favor composition over inheritance" — the antidote to deep class hierarchies.

<sup>**7**</sup> **Effective Java** (2001) — Joshua Bloch, Sun Microsystems. Practical wisdom for writing maintainable code. Item 18: "Favor composition over inheritance."

<sup>**8**</sup> **Ruby on Rails** (2004) — David Heinemeier Hansson (DHH). "Convention over configuration" — the insight that sensible defaults beat endless options.

**Additional influences:** Paul Graham (*On Lisp*, *Hackers & Painters*), Rich Hickey (Clojure, "Simple Made Easy"), Rob Pike & Ken Thompson (Go, Unix philosophy), Martin Fowler (*Refactoring*), Robert C. Martin (*Clean Code*).

---

<div align="center">

**You bring the creativity. The agent brings the discipline.**

*30 years of lessons. Zero lectures. Just better code.*

</div>
