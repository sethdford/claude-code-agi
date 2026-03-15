# Claude Code — Autonomous Agent Operating Manual

This configuration transforms Claude Code from an interactive assistant into an autonomous agent with persistent memory, self-improvement, and production awareness.

## Model Selection

| Model             | ID                  | Best For                                    |
| ----------------- | ------------------- | ------------------------------------------- |
| Claude Opus 4.6   | `claude-opus-4-6`   | Complex tasks, agent teams, full 1M context |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | Balanced speed/quality, good default        |
| Claude Haiku 4.5  | `claude-haiku-4-5`  | Fast subagents, exploration, simple tasks   |

- Use `--model` flag or `/model` command to switch models mid-session
- Subagent model defaults to Haiku via `CLAUDE_CODE_SUBAGENT_MODEL=haiku`
- **Effort levels**: `CLAUDE_CODE_EFFORT_LEVEL=low/medium/high` for adaptive reasoning depth
- **Fast mode**: 2.5x faster Opus 4.6 — toggle with `/fast`
- **Fallback model**: `--fallback-model` for automatic model fallback when rate limited

## Subagent Strategy

| Subagent Type     | Tools Available              | Use For                                   |
| ----------------- | ---------------------------- | ----------------------------------------- |
| `Explore`         | Read-only (Glob, Grep, Read) | Fast codebase search, file discovery, Q&A |
| `Plan`            | Read-only                    | Architecture planning, research           |
| `general-purpose` | All tools                    | Multi-step tasks, code changes            |

Best practices:

- Use `Explore` (runs on Haiku) for quick searches
- Use `isolation: worktree` when a subagent needs to make changes without conflicts
- Use `background: true` for long-running agents (test suites, builds)
- Launch independent subagents in parallel, never sequentially
- Use `model: haiku` for exploration, `model: sonnet` for analysis, keep opus for orchestration

## Plan Mode

Use **Plan Mode** (Shift+Tab twice) before complex tasks:

- Reduces token consumption by 40-50% on analysis-heavy work
- Claude explores in read-only mode, then presents a plan for approval
- Ideal for: refactoring, architectural changes, debugging unfamiliar code
- Pattern: "Do not write code yet. Just give me a plan." → review → approve → execute

## Team Patterns

- Assign each agent **different files** to avoid merge conflicts
- Use `--worktree` for file isolation between agents
- Keep tasks self-contained (5-6 focused tasks per agent)
- Start with 3-5 teammates — more than 5-6 rarely helps
- Begin with research/review tasks before implementation
- Use `plan` permission mode for risky teammate work

## Modular Rules

Use `.claude/rules/*.md` for topic-specific instructions:

- Each `.md` file auto-loads as additional context every session
- Use for domain-specific conventions (e.g., `firebase.md`, `testing.md`)
- Keeps `CLAUDE.md` focused; rules handle specifics

## Key Environment Variables

| Variable                                        | Value   | Purpose                      |
| ----------------------------------------------- | ------- | ---------------------------- |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`          | `1`     | Enable multi-agent teams     |
| `CLAUDE_CODE_SUBAGENT_MODEL`                    | `haiku` | Default subagent model       |
| `CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY`          | `5`     | Parallel tool execution      |
| `CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE`          | `70`    | Trigger compaction at 70%    |
| `CLAUDE_CODE_GLOB_HIDDEN`                       | `1`     | Include hidden files in glob |
| `CLAUDE_CODE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | `1`     | Preserve CWD in bash         |
| `CLAUDE_CODE_EFFORT_LEVEL`                      | `high`  | Deeper reasoning             |
| `CLAUDE_CODE_EMIT_TOOL_USE_SUMMARIES`           | `1`     | Log tool summaries           |
| `ENABLE_TOOL_SEARCH`                            | `auto`  | MCP tool search              |

## Context Engineering (Token Optimization)

Opus 4.6 supports 1M tokens — but every token has a cost and dilutes attention:

- **Use Plan Mode first** — separates analysis from execution, cutting tokens 40-50%
- **Configure `.claudeignore`** — like `.gitignore` for context. Reduces tokens ~25%
- **Filter before injecting** — never dump raw tool output. Use subagents to pre-process
- **Batch independent tool calls** — parallel calls in one turn, not sequential round-trips
- **Delegate data-heavy work to subagents** — only the final summary enters your context
- **Minimize tool definition bloat** — only enable MCP tools you need
- **Prune context aggressively** — summarize completed work, discard intermediate artifacts
- **Prefer targeted reads** — specific line ranges, not entire files
- **Use structured output** — keep inter-agent communication concise
- **Avoid the last 20%** — divide work into context-sized chunks
- **Use `/context`** — visualize context usage as a colored grid

## Hooks Best Practices

- **PreToolUse** can modify tool inputs before execution
- **HTTP hooks** — POST JSON to URLs for webhooks, dashboards, Slack
- **Matchers** — filter events with patterns (e.g., `Edit|Write`)
- **Exit code 2** — dynamically block/allow actions
- **Prompt hooks** — LLM evaluation (Haiku by default)
- **Agent hooks** — multi-turn verification with tool access (50 turns, 60s timeout)

## MCP Configuration

- **Local scope** — `.mcp.json` in project root (shared via git)
- **User scope** — `~/.claude/mcp.json` (personal, cross-project)
- **MCP Tool Search** — auto-enables when tools exceed 10% of context
- **Managed MCP** — `managed-mcp.json` for policy-based control

## Input & Voice

- **Voice input**: Push-to-talk (space bar), 20 languages
- **Multiline**: `\` + Enter, Option+Enter, Shift+Enter, Ctrl+J
- **Bash shortcut**: `!` prefix for direct shell commands
- **Image paste**: Ctrl+V / Cmd+V / Alt+V
- **File mention**: `@` autocomplete
- **History search**: Ctrl+R

## Background Tasks

- **Ctrl+B** — background a running task
- **Ctrl+F** (press twice) — kill background agents
- **`/tasks`** — list and manage background tasks
- **`background: true`** in subagent definition
- Background agents get pre-approved permissions but can't ask questions

## Permission Modes

| Mode                | Behavior                                       |
| ------------------- | ---------------------------------------------- |
| `default`           | Standard prompts on first use                  |
| `auto`              | Claude makes permission decisions autonomously |
| `acceptEdits`       | Auto-accept file edits, prompt for others      |
| `plan`              | Read-only mode                                 |
| `dontAsk`           | Auto-deny unless pre-approved                  |
| `bypassPermissions` | Skip all checks (containers only)              |

## Failure Recovery

### When Tests Fail

1. Read the full test output — don't guess
2. Identify the failing assertion
3. Fix the code (not the test, unless the test is wrong)
4. Re-run the specific test first, then the full suite
5. Document what caused the failure

### When Merge Conflicts Arise

1. `git status` to see all conflicted files
2. Resolve one file at a time — read both versions first
3. Run the test suite after resolving
4. If unsure, ask before committing

### When Context Window Gets Tight

1. PreCompact hook saves context automatically
2. Summarize your progress before compaction
3. Break remaining work into smaller tasks
4. Use `/context` to visualize usage

### When a Deploy Fails

1. Check deploy history: `.claude/deploy-history.md`
2. Check recent commits: `git log --oneline -5`
3. Correlate: did a recent commit introduce the error?
4. Fix or rollback based on findings

## Agent Operating Principles

### 1. Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps)
- If something goes sideways, STOP and re-plan — don't keep pushing
- A plan that survives contact with reality is worth 10x one that doesn't

### 2. Subagent Strategy

- Use subagents liberally to keep main context clean
- One task per subagent for focused execution
- Launch independent subagents in parallel
- Background long-running agents and continue working

### 3. Self-Improvement Loop

- After ANY correction: update `.claude/lessons.md` with the pattern
- Write rules that prevent the same mistake
- Review lessons at session start
- Every incident is a lesson: document what happened, why, and the fix

### 4. Verification Before Done

- Never mark a task complete without proving it works
- Run tests, check logs, demonstrate correctness
- Typecheck, lint, and build BEFORE claiming success
- Ask: "Would a staff engineer approve this?"

### 5. Demand Elegance (Balanced)

- For non-trivial changes: "is there a more elegant way?"
- Skip this for simple, obvious fixes
- Prefer closing loops (outputs feed inputs) over isolated features

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user

## Task Management

1. **Plan First**: Write plan with checkable items
2. **Verify Plan**: Check in before starting
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section
6. **Capture Lessons**: Update lessons after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards
- **Production Safety**: Every query needs `.limit()`. Every scheduled function needs `timeoutSeconds`
- **Test Everything**: Unit tests for logic, integration tests for flows, smoke tests for deploys
- **Bound Everything**: Unbounded queries, loops, and retries are incidents waiting to happen
- **Close the Loop**: Every output should feed an input
- **Fail Closed**: Rate limiters block. Payment processors notify. Content gates require review
- **Idempotency**: Every operation safe to retry
- **Observe Everything**: Track execution, detect anomalies, alert on SLO breach
