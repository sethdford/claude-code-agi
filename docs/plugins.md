# Claude Code Plugins

Plugins extend Claude Code with specialized workflows and automations. Install them with the `/plugin` command, reload with `/reload-plugins`.

## Essential Plugins

### Superpowers (HIGHLY RECOMMENDED)

The most important plugin for autonomous development.

**What it does:**
- **Brainstorm** — Generate design options and trade-offs for technical decisions
- **TDD** — Test-driven development: write tests first, then implement
- **Debugging** — Structured debugging workflow: hypothesis → instrumentation → fix
- **Plans** — Create and verify implementation plans before coding
- **Code Review** — Multi-lens review (logic, bugs, quality, security, performance)
- **Parallel Agents** — Dispatch 5-7 agents to work on different files simultaneously

**When to use:**
- Starting a complex feature (use /plan)
- Stuck on a bug (use /debug)
- About to refactor large sections (use /code-review first)
- Working across many files (use /parallel-agents)
- Writing tests (use /tdd)

**Example workflow:**
```
/plan: Design the authentication refactor
[Review the plan]
/parallel-agents: Implement auth refactor across 8 files
[Agents work independently]
/code-review: Review all changes
[Push PR]
```

### Hookify

Prevent repeated mistakes by automating corrections.

**What it does:**
- Analyzes your conversation to find repeatable patterns
- Suggests creating hooks to catch mistakes automatically
- Generates hook code for PreToolUse, PostToolUse, or custom events

**Example:**
You keep forgetting to add rate limiting to API routes. Hookify suggests a PreToolUse hook that checks if every POST route has rate limiting before you write it.

**When to use:**
- After making the same correction 2+ times in a session
- When you notice a pattern you keep repeating
- To automate quality gates

### Commit Commands

Streamlined git workflow with `/commit`, `/commit-push-pr`.

**What it does:**
- `/commit` — Stage, write message (with AI help), and commit atomically
- `/commit-push-pr` — Commit, push, and open a PR in your browser

**Example:**
```
/commit
[Writes conventional commit message automatically]
/commit-push-pr
[Branch pushed, PR opened on GitHub]
```

### Claude MD Management

Keep `.claude/CLAUDE.md` and `.claude/rules/` synchronized with your project.

**What it does:**
- `/revise-claude-md` — Update the operating manual based on recent changes
- `/sync-rules` — Ensure all rules files are current and non-contradictory
- `/validate-rules` — Check for conflicting instructions across rules

**When to use:**
- After adding a major feature or changing architecture
- When standards drift from actual practice
- Before onboarding a new agent team member

### Skill Creator

Create custom `/skills` for repeated workflows.

**What it does:**
- Interactive skill builder (input, output, evaluation)
- Auto-generates skill code
- Runs evaluations to verify correctness

**Example:**
Create a `/deploy-preview` skill that:
1. Builds the preview
2. Deploys to staging
3. Runs smoke tests
4. Returns the preview URL

Then use `/deploy-preview` anytime you need a quick staging environment.

### MCP Tool Search (Built-in)

Dynamically load tools from MCP servers instead of preloading all definitions.

**What it does:**
- Reduces tool definition bloat by ~30%
- Tools load on-demand when you mention them
- Keeps context clean for analysis-heavy work

**Configure:**
```bash
ENABLE_TOOL_SEARCH=auto:10  # Enable at 10% context threshold
```

## Installation

### Install a plugin

```
/plugin
```

Then select from the list. Plugins install to `~/.claude/plugins/`.

### Reload plugins

After installing new plugins or updating code:

```
/reload-plugins
```

This loads pending changes without restarting Claude Code.

## Plugin Development

Plugins are YAML manifests + shell scripts or TypeScript. Create your own:

```bash
mkdir -p ~/.claude/plugins/my-plugin
cat > ~/.claude/plugins/my-plugin/plugin.yaml <<EOF
name: my-plugin
version: 1.0.0
commands:
  - name: my-command
    description: What this does
    handler: ./handler.sh
EOF
```

Then reload: `/reload-plugins`

## Recommended Plugin Combinations

### For Rapid Development
1. Superpowers (planning + TDD)
2. Commit Commands (quick git workflow)
3. Hookify (prevent mistakes)

### For Large Refactors
1. Superpowers (code review + parallel agents)
2. Claude MD Management (keep docs in sync)
3. Hookify (catch regressions)

### For Debugging Production Issues
1. Superpowers (debugging workflow)
2. MCP Tool Search (keep context small)

### For Autonomous Operation
1. Superpowers (parallel agents for exploration)
2. Hookify (auto-prevent mistakes)
3. Skill Creator (build tools for future Claude)
4. Claude MD Management (keep operating manual current)

## Tips

- **Plugins + Plan Mode** — Use `/plan` from Superpowers before any major change
- **Plugins + Lessons** — Hookify findings feed into `.claude/lessons.md`
- **Plugins + Hooks** — Create hooks for the patterns Hookify finds
- **Parallel Agents** — Best results when each agent owns distinct files
