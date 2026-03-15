# Claude Code Features Reference

A concise guide to the top 50 Claude Code features, organized by category.

## Environment Variables

Control Claude Code behavior via environment variables:

| Variable                                | Values       | Purpose                                           |
| --------------------------------------- | ------------ | ------------------------------------------------- |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`  | `0` or `1`   | Enable multi-agent team coordination              |
| `CLAUDE_CODE_SUBAGENT_MODEL`            | `haiku`      | Default model for subagents (cost-efficient)      |
| `CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY`  | `1-10`       | Parallel tool execution limit (default: 5)        |
| `CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE`  | `50-95`      | Trigger context compaction at N% (default: 95%)   |
| `CLAUDE_CODE_GLOB_HIDDEN`               | `0` or `1`   | Include hidden files in glob searches             |
| `CLAUDE_CODE_EMIT_TOOL_USE_SUMMARIES`   | `0` or `1`   | Log tool execution summaries                      |
| `CLAUDE_CODE_BASH_MAINTAIN_PROJECT_CWD` | `0` or `1`   | Preserve CWD in bash across tool calls            |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT`        | `1`          | Disable 1M context window (if memory constrained) |
| `CLAUDE_CODE_EFFORT_LEVEL`              | `low/med/hi` | Adaptive reasoning depth (Opus/Sonnet 4.6 only)   |
| `CLAUDE_CODE_DISABLE_FAST_MODE`         | `1`          | Disable fast mode option                          |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`  | `1`          | Disable background task operations                |
| `CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION`  | `true/false` | Toggle grayed-out prompt suggestions              |
| `MAX_MCP_OUTPUT_TOKENS`                 | `1-50000`    | Limit MCP tool output size (default: 50k)         |
| `ENABLE_TOOL_SEARCH`                    | `auto`       | MCP tool search behavior (auto/true/false)        |

**Example:**

```bash
export CLAUDE_CODE_EFFORT_LEVEL=high  # Use full Opus reasoning for this session
export CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE=70  # Trigger context compaction at 70%
```

## Hooks

Automate workflows at lifecycle events:

| Event                | Trigger                    | Use Case                     |
| -------------------- | -------------------------- | ---------------------------- |
| `SessionStart`       | Session begins             | Health checks, load context  |
| `SessionEnd`         | Session ends               | Save progress, cleanup       |
| `PreToolUse`         | Before any tool runs       | Validate inputs, modify args |
| `PostToolUse`        | After tool completes       | Log results, update memory   |
| `PreCompact`         | Before context compaction  | Save state before truncation |
| `InstructionsLoaded` | Rules files loaded         | Update derived rules         |
| `ConfigChange`       | Settings or config changes | Validate new config          |
| `WorktreeCreate`     | New worktree created       | Initialize isolation         |
| `WorktreeRemove`     | Worktree destroyed         | Cleanup                      |
| `TeammateIdle`       | Subagent becomes idle      | Check teammate status        |
| `TaskCompleted`      | Task finishes successfully | Record completion, plan next |
| `TaskFailed`         | Task fails                 | Error recovery, suggest fix  |

**Folder:** `.claude/hooks/` (bash scripts, must be executable)

**Example:**

```bash
#!/bin/bash
# .claude/hooks/post-deploy.sh
# Runs after every deploy

if [ -f ".deploy-history" ]; then
  echo "$(date): Deploy completed" >> .deploy-history
fi
```

## Permission Modes

Control how Claude Code asks for permission:

| Mode                | Behavior                                       |
| ------------------- | ---------------------------------------------- |
| `default`           | Standard prompts on first use of each tool     |
| `acceptEdits`       | Auto-accept file edits, prompt for other tools |
| `plan`              | Read-only mode (requires plan approval)        |
| `dontAsk`           | Auto-deny unless pre-approved in settings      |
| `bypassPermissions` | Skip all permission checks (dangerous!)        |

**Set per-subagent:**

```typescript
Agent('code-reviewer', { mode: 'plan' }); // Read-only for this agent
```

## Models & Tokens

Choose the right model for the task:

| Model         | ID                  | Best For                                    | Cost |
| ------------- | ------------------- | ------------------------------------------- | ---- |
| Claude Opus   | `claude-opus-4-6`   | Complex tasks, agent teams, full 1M context | High |
| Claude Sonnet | `claude-sonnet-4-6` | Balanced speed/quality, good default        | Med  |
| Claude Haiku  | `claude-haiku-4-5`  | Fast subagents, exploration, simple tasks   | Low  |

**Switch models mid-session:**

```
/model sonnet        # Switch to Sonnet
/fast                # Toggle fast mode (2.5x faster at higher cost)
/context             # Visualize context usage as colored grid
```

**Subagent model:**

```bash
export CLAUDE_CODE_SUBAGENT_MODEL=haiku  # Default to Haiku for cheap subagents
```

## Shortcuts & Commands

Quick workflows via `/` commands:

| Command           | Purpose                                                          |
| ----------------- | ---------------------------------------------------------------- |
| `/simplify`       | Review code for reuse, quality, and efficiency — then fix        |
| `/batch`          | Research and plan large-scale changes with isolated agents       |
| `/copy`           | Interactive code block picker — copy full response or selections |
| `/memory`         | View and manage auto-memory (persistent across sessions)         |
| `/fast`           | Toggle fast mode — same Opus 4.6 with faster output              |
| `/loop 5m <cmd>`  | Run command on recurring interval (e.g., `/loop 5m curl status`) |
| `/context`        | Visualize context window usage as colored grid                   |
| `/tasks`          | List and manage background tasks                                 |
| `/diff`           | Interactive diff viewer for current changes                      |
| `/output-style`   | Switch output styles: Default, Explanatory, or Learning          |
| `/stats`          | Daily usage statistics, streaks, model preferences               |
| `/insights`       | Generate analysis of your Claude Code sessions                   |
| `/terminal-setup` | Configure terminal keybindings                                   |
| `/reload-plugins` | Activate pending plugin changes without restart                  |
| `/plan`           | Enter plan mode (Shift+Tab twice)                                |

## Background Tasks

Run long operations without blocking:

| Action          | How                      | Purpose                              |
| --------------- | ------------------------ | ------------------------------------ |
| **Ctrl+B**      | While task is running    | Background the current task          |
| **Ctrl+F** (x2) | In foreground with tasks | Kill background agents               |
| `/tasks`        | Command                  | List and manage all background tasks |

**Background subagent:**

```typescript
Agent('tester', {
  background: true, // Always runs in background
  // ...
});
```

## MCP Configuration

Connect external tools via Model Context Protocol:

**MCP scopes:**

- `local` — `.mcp.json` in project root
- `user` — `~/.claude/mcp.json`

**MCP Tool Search:** Auto-enables when tool definitions exceed 10% of context. Dynamically loads tools on demand instead of preloading all.

**Managed MCP:** Use `managed-mcp.json` for policy-based server control with `allowedMcpServers`/`deniedMcpServers` and wildcard URL patterns.

**Custom file autocomplete:** Set `fileSuggestion` in settings to a command/script for custom `@` file mention suggestions.

## Input & Voice

**Keyboard shortcuts:**

- **Space** (default) — Push-to-talk for voice input
- **Ctrl+J** — Multiline input (also Option+Enter, Shift+Enter)
- **Ctrl+V / Cmd+V / Alt+V** — Paste image
- **@** — File mention with autocomplete
- **Ctrl+R** — Reverse history search
- **!** — Prefix to run bash command directly

**Voice input:**

- Supports 20 languages
- Customizable push-to-talk key (rebindable via `voice:pushToTalk`)

## Agent Teams

Coordinate multiple agents for complex tasks:

**Create a team:**

```bash
shipwright session <name> --template <tpl>
```

**Team patterns:**

- Assign each agent different files (avoid merge conflicts)
- Use `--worktree` for file isolation between agents
- Keep tasks self-contained (5-6 focused tasks per agent)
- Use task list for coordination
- Start with 3-5 teammates

**Agent roles:**

- **Explorer** — Read-only code search (Haiku, fast)
- **Planner** — Architecture decisions (read-only)
- **General Purpose** — Multi-step changes (all tools)

**Display modes:** Set `teamMateMode` to `auto`, `in-process`, or `tmux` (auto detects environment).

## Worktrees

Isolated branches for parallel work:

```bash
shipwright pipeline start --issue 42 --worktree   # Each gets isolated worktree
shipwright pipeline start --issue 43 --worktree

# Or manual:
git worktree add .claude/worktrees/feature-x
cd .claude/worktrees/feature-x
git checkout -b feature-x
```

**Benefits:**

- No merge conflicts between parallel agents
- Clean separation of work
- Easy rollback (just delete worktree)

## Rules

Modular conventions for domain-specific guidance:

**Location:** `.claude/rules/*.md` (auto-loaded every session)

**Examples:**

- `firebase.md` — Firebase conventions
- `testing.md` — Test patterns
- `security.md` — Security checklist
- `crm.md` — CRM data model

Rules are loaded after main CLAUDE.md and take precedence for specific patterns.

## File Operations

**Commands:**

- `pnpm install` — Install all workspace dependencies
- `pnpm dev:*` — Start dev servers for specific packages
- `pnpm build` — Build all packages
- `pnpm test` — Run all tests
- `./.scripts/deploy-*.sh` — Deploy via script (never raw commands)

**CI Quality Checks:**

- `pnpm format:check` — Prettier format check
- `pnpm audit --audit-level=high` — Security audit
- `pnpm typecheck` — TypeScript type checking
- Coverage thresholds in `vitest.config.ts` or CI

## File Mention & Search

**File mention:**

- Type `@` to autocomplete and mention files
- Supports glob patterns (e.g., `@src/**/*.ts`)

**Search:**

- `Glob` tool — Fast file pattern matching
- `Grep` tool — Content search with regex
- `Bash` tool — Direct shell commands (for complex patterns)

## Output Styles

Switch how Claude Code presents information:

- **Default** — Standard comprehensive explanations
- **Explanatory** — Detailed, educational approach
- **Learning** — Tutorial-like with examples

Use `/output-style` to switch mid-session.

## Caching & Performance

**Token cache:**

- Responses cached for 15 minutes by default
- Useful for repeated requests to same endpoint
- Automatically invalidates on code changes

**Context compaction:**

- Triggered at 95% (or custom threshold via env var)
- Automatically summarizes history
- Preserves important context

## Limits & Quotas

**Default limits:**

- Context window: 1M tokens (Opus 4.6)
- Tool execution: 5 parallel (configurable)
- MCP output: 50k tokens (configurable)
- Background tasks: unlimited
- Worktrees: no limit (git constraint)

**Session timeouts:**

- No fixed timeout; sessions can run indefinitely
- Background tasks continue across session boundaries
- Memory persists across restarts

## Tips & Tricks

1. **Combine tools strategically** — Use Glob to find files, Grep to search content, Bash for complex operations
2. **Batch independent calls** — Make parallel tool calls in one turn to save tokens
3. **Use subagents for exploration** — Delegate broad searches to Haiku agents (cheap)
4. **Reference files with @** — Mention files directly in prompts for autocomplete
5. **Check context with /context** — Visualize usage before context exhaustion
6. **Save progress to files** — Use `tasks/todo.md` and `.claude/lessons.md` for cross-session continuity
7. **Use hooks for automation** — Create `.claude/hooks/` scripts for recurring tasks
8. **Enable fast mode for speed** — `/fast` gives 2.5x output speed at higher cost
9. **Create rules for conventions** — Put domain knowledge in `.claude/rules/` instead of repeating
10. **Read CLAUDE.md first** — Project conventions and standards are in `CLAUDE.md` and `.claude/rules/`
