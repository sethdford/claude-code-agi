# Keyboard Shortcuts & Customization

Essential keyboard shortcuts for efficient Claude Code navigation and workflow control.

## Essential Shortcuts

| Shortcut | Action | Notes |
|----------|--------|-------|
| **Ctrl+C** | Cancel current operation | Stops tool execution, aborts response |
| **Ctrl+D** | Exit Claude Code | Graceful shutdown |
| **Ctrl+L** | Clear terminal | Clears visible output without losing context |
| **Ctrl+B** | Background a task | Move long-running task (tests, builds) to background |
| **Ctrl+R** | History search | Reverse search through command history |
| **Shift+Tab** (twice) | Enter plan mode | Separates analysis from execution, saves 40-50% tokens |

## Navigation & Workflow

| Shortcut | Action | Notes |
|----------|--------|-------|
| **Option+P** / **Alt+P** | Switch model | Cycles between Claude models (Opus, Sonnet, Haiku) |
| **Option+T** / **Alt+T** | Extended thinking | Enable extended reasoning for current task |
| **Cmd+K** / **Ctrl+K** | Command palette | Quick access to commands, routes, functions |
| **Option+Enter** | Multiline input | Start new line in prompt without sending |
| **Shift+Enter** | Multiline input | Alternative multiline start |
| **Ctrl+J** | Multiline input | Another multiline option |
| **\ + Enter** | Multiline input | Escape sequence for multiline (some terminals) |

## Input & Editing

| Shortcut | Action | Notes |
|----------|--------|-------|
| **Ctrl+V** / **Cmd+V** / **Alt+V** | Paste image | Paste screenshot or image directly into prompt |
| **@** | File mention | Start typing filename for autocomplete |
| **Ctrl+R** | Reverse history search | Search previous commands (bash history) |
| **Ctrl+A** | Select all | Select entire input line |
| **Ctrl+U** | Delete line | Clear from cursor to start of line |
| **Ctrl+K** | Delete to end | Clear from cursor to end of line |

## Background Tasks

| Shortcut | Action | Notes |
|----------|--------|-------|
| **Ctrl+B** | Background task | Move currently running task to background, continue working |
| **Ctrl+F** (twice) | Kill background agents | Terminate all background tasks |
| **/tasks** | List tasks | Show all running and completed background tasks |

## Plan Mode

Plan Mode separates thinking from execution, reducing token use by 40-50%.

**Enter plan mode:**
```
Shift+Tab twice
```

**What happens:**
1. Claude enters read-only mode
2. Explores the codebase (using Glob, Grep, Read only)
3. Presents a detailed plan for your approval
4. Waits for you to review and approve
5. Executes only after you confirm

**Best for:**
- Refactoring across many files
- Debugging unfamiliar code
- Architectural changes
- Large dependency updates

**Example:**
```
User: Refactor authentication
↓
[Shift+Tab twice]
↓
Claude: [Explores codebase]
Claude: Here's the plan:
  1. Extract auth logic to new service
  2. Update 5 route handlers
  3. Add integration tests
  4. Update type definitions
↓
User: Looks good, proceed
↓
Claude: [Executes plan, makes all changes, runs tests]
```

## Model Selection

Switch models mid-session:

| Shortcut | Action | Effect |
|----------|--------|--------|
| **Option+P** / **Alt+P** | Model selector | Interactive menu |
| **/model opus** | Switch to Opus | Claude Opus 4.6 (most capable) |
| **/model sonnet** | Switch to Sonnet | Claude Sonnet 4.6 (balanced) |
| **/model haiku** | Switch to Haiku | Claude Haiku 4.5 (fast, for exploration) |

**When to switch:**
- Use Opus for complex reasoning, refactoring, architecture
- Use Sonnet for balanced tasks (most efficient)
- Use Haiku for subagents, exploration, simple changes

## Extended Thinking

Enable deeper reasoning for a single task:

| Shortcut | Action |
|----------|--------|
| **Option+T** / **Alt+T** | Toggle extended thinking |

Extended thinking uses more tokens but produces better analysis. Best for:
- Bug investigation
- Code review
- Architectural decisions
- Test generation

## Special Modes

| Command | Action |
|---------|--------|
| **/vim** | Toggle Vim keybindings |
| **/fast** | Enable fast mode (2.5x faster Opus, higher cost) |
| **/context** | Visualize context usage as colored grid |

**Vim mode:**
If you're comfortable with Vim, toggle it on:
```
/vim
```

Then use standard Vim navigation (h/j/k/l, :/G, etc.).

## Terminal Setup

Configure Claude Code keybindings for your terminal:

```
/terminal-setup
```

This guides you through:
- Detecting your shell (zsh, bash, etc.)
- Recommending keybinding changes
- Adjusting escape sequences if needed
- Setting up push-to-talk (voice input)

## Custom Keybindings

Create a custom keybindings file at `~/.claude/keybindings.json`:

```json
{
  "keybindings": [
    {
      "key": "ctrl+shift+d",
      "command": "deploy",
      "description": "Quick deploy"
    },
    {
      "key": "ctrl+shift+t",
      "command": "test",
      "description": "Run tests"
    },
    {
      "key": "alt+a",
      "command": "/audit-codebase",
      "description": "Full codebase audit"
    }
  ]
}
```

Then reload:
```
/reload-plugins
```

## Output Styles

Change how Claude formats responses:

| Command | Style | Use When |
|---------|-------|----------|
| **/output-style default** | Standard | General use |
| **/output-style explanatory** | Detailed | Learning new concepts |
| **/output-style learning** | Educational | Teaching/documentation |

## Voice Input

Claude Code supports voice input with push-to-talk:

| Action | Default | Customizable |
|--------|---------|--------------|
| Push-to-talk | Space bar | Yes, in `/terminal-setup` |
| Languages | 20+ supported | See docs |
| Timeout | 30s of silence | Adjustable |

**Enable voice:**
```
/terminal-setup
```

Then hold space while speaking. Release to submit.

## Tips for Efficiency

1. **Combine shortcuts:**
   - `Shift+Tab` twice → `/plan` → think without execution
   - `Ctrl+B` → long task runs in background, you keep working
   - `Option+P` → switch to Haiku for fast exploration

2. **Use plan mode for expensive operations:**
   - Before refactoring across 10+ files
   - Before deploying to production
   - Before running migrations

3. **Customize for your workflow:**
   - Add shortcuts for frequent commands
   - Set your preferred model with `/model`
   - Bind complex recipes to single keys

4. **Background long-running tasks:**
   - Tests, builds, and deploys run in background
   - Check status anytime with `/tasks`
   - Continue working while they run
