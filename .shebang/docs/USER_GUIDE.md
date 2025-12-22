# Shebang User Guide

Welcome to **Shebang** — a truly intelligent development environment where you can simply tell the app what you want, and it figures out how to do it.

## What is Shebang?

Shebang is a macOS app that combines a terminal with AI assistance. Instead of memorizing complex commands, you can just talk to it naturally. Think of it as having an expert developer sitting next to you, ready to help with anything.

The name comes from `#!` (called "shebang" in Unix) — the symbol that tells computers how to run programs. That's exactly what this app does: it bridges the gap between what you want and how to make it happen.

## Getting Started

### Installation

```bash
# Clone the repository
git clone https://github.com/MichaelONeal/Shebang.git
cd Shebang

# Build it (requires Xcode 16+, macOS 15+)
./build.sh

# Run it
open Shebang.app
```

Or build manually with `xcodebuild -scheme Shebang -configuration Release`.

The app opens with a terminal running Claude Code. That's it! You're ready to go.

### First Look

When you open Shebang, you'll see:

- **Left sidebar**: Browse files in your current folder
- **Center**: A terminal with Claude Code running
- **Right panel**: Your active sessions (like browser tabs, but for work)

## Working with Claude Code

Claude Code runs directly in the terminal. Just type what you want to do:

```
what files are in this folder?
```

```
make a new folder called "my-project"
```

```
what changed since yesterday?
```

The AI will understand what you mean and do it for you.

## Talking to the AI

### Natural Language

You don't need to learn commands. Just ask naturally:

- "show me all the files"
- "what's taking up so much disk space?"
- "deploy this to the server"
- "run the tests"
- "fix the error in the terminal"

### Getting Help

If you're stuck, just ask:
- "how do I...?"
- "what does this error mean?"
- "what should I do next?"

## Working with Files

### File Browser (Left Sidebar)

Click the folder icon at the top left to show/hide the file browser.

- **Click a folder**: Opens/closes it to show what's inside
- **Click a file**: Opens a preview
- **Folders are blue**, files have colors based on their type

The file browser automatically updates when you change folders or switch branches.

### File Preview

When you click a file, it opens in a preview overlay. You can:
- Read the file contents
- Close it by clicking the X or clicking outside

## Sessions: Multiple Workspaces

Sessions are like tabs in a web browser, but for different projects or tasks.

### Creating Sessions

Click the **+ new** button in the right panel to create a new session.

Each session has its own:
- Working directory
- Terminal history
- File browser view

### Switching Sessions

Just click on a session in the right panel. The active session has a:
- Green pulsing indicator
- Blue highlight border
- Slightly larger appearance

### Closing Sessions

Hover over a session and click the **X** button that appears.

Don't worry — you can't close the last session. Shebang will always keep at least one open.

## Favorites: Quick Access to Folders

### Adding Favorites

Right-click on a folder in the sidebar and select "Add to Favorites" to save frequently-visited folders.

### Viewing Favorites

Click the star icon in the toolbar (or press **Cmd+Shift+F**) to open the favorites drawer at the bottom.

Your favorite folders appear as cards. Click a card to jump to that folder instantly.

### Removing Favorites

Hover over a favorite card and click the **X** that appears.

## Git Integration

Shebang detects when you're in a git repository. Ask Claude Code about your git status naturally:

- "what's the git status?"
- "show me the diff"
- "commit my changes"

Claude Code understands git and can help you with branches, merges, rebases, and more.

## Keyboard Shortcuts

### Terminal
- **Ctrl+C**: Stop the current command
- **Ctrl+D**: Send end-of-file signal
- **Ctrl+Z**: Pause the current command
- **Tab**: Auto-complete file names

### Panels
- **Cmd+B**: Show/hide file browser
- **Cmd+0**: Show/hide sessions panel
- **Cmd+Shift+F**: Show/hide favorites

### Tab Completion

Start typing a file name and press **Tab** to auto-complete:
```
cat README[Tab]  →  cat README.md
```

If there are multiple matches, press **Tab** again to see all options.

## Display Modes

Shebang has two ways to view your terminal:

### Interactive Mode (Terminal Icon)

Shows a live terminal where you can see everything as it happens. This is the default mode.

### Block Mode (Stacked Blocks Icon)

Shows your work organized into blocks:
- Commands you ran
- Output from those commands
- AI responses
- Errors

Switch between modes using the segmented control in the toolbar.

## Tips and Tricks

### Navigating Folders

You can navigate folders in several ways:

1. **Ask the AI**: "go to my projects folder"
2. **Type the command**: `cd ~/Projects`
3. **Use the file browser**: Click folders in the left sidebar
4. **Use favorites**: Click a favorite card to jump there instantly

The file browser automatically updates to show your new location.

### Undoing Mistakes

If something goes wrong, just tell the AI:
- "undo that"
- "go back to the previous version"
- "restore the file"

The AI understands context and will figure out what you mean.

### Working on Multiple Things

Create a new session for each project or task:
- Session 1: Your main project
- Session 2: Testing something new
- Session 3: Reading documentation

Switch between them with one click. Each session remembers where you were and what you were doing.

### Learning as You Go

When the AI runs a command for you, you can see exactly what it did in the terminal. Over time, you'll start recognizing patterns and learning the commands yourself — but you never have to memorize them.

## Common Questions

### "I don't know any commands. Can I still use this?"

Absolutely! That's the whole point. Just describe what you want to do in plain English.

### "What if I accidentally delete something important?"

Ask the AI to help you restore it. Git keeps a history of all changes, so you can usually get things back.

### "How do I know if the AI understood me?"

You'll see it run commands in the terminal. If it does something unexpected, just tell it "that wasn't what I meant" and explain again.

### "Can I use regular commands too?"

Yes! If you know commands like `ls`, `git status`, or `npm install`, you can type them directly. The AI automatically detects common commands and runs them.

## Getting More Help

- Ask Claude Code: "how do I...?"
- Check the terminal output to see what commands were run
- Try things! The AI can help you undo mistakes

---

**Remember**: You don't need to know "all the things" to get work done. Just describe what you want, and Shebang handles the details. The interface fades away, and you can focus on building.
