# Demo Project — Claude Code AGI Configured

This project was set up with `claude-code-agi`. See https://github.com/sethdford/claude-code-agi

## Model Selection

| Model             | Best For                                    |
| ----------------- | ------------------------------------------- |
| Claude Opus 4.6   | Complex tasks, agent teams, full 1M context |
| Claude Sonnet 4.6 | Balanced speed/quality, good default        |
| Claude Haiku 4.5  | Fast subagents, exploration, simple tasks   |

Use `--model` flag or `/model` command to switch mid-session.

## Subagent Strategy

Choose the right subagent type:

| Type             | Tools                | Use For                                      |
| ---------------- | -------------------- | -------------------------------------------- |
| `Explore`        | Read-only            | Fast codebase search, Q&A                    |
| `Plan`           | Read-only            | Architecture planning, research              |
| `general-purpose`| All tools            | Multi-step tasks, code changes, operations   |

**Best practices:**
- Use `Explore` (runs on Haiku) for quick searches
- Use `isolation: worktree` for changes without conflicts
- Use `background: true` for long-running tasks (tests, linting, builds)
- Set `maxTurns` to cap iterations on exploratory agents

## Core Principles

1. **Plan Mode Default** — Enter plan mode for any non-trivial task. Use it for verification, not just building.
2. **Subagent Strategy** — Offload research and exploration to subagents. Keep main context clean.
3. **Self-Improvement** — After corrections, update `.claude/lessons.md` with patterns to prevent repeats.
4. **Verification Before Done** — Never mark tasks complete without proving they work. Run tests, check logs.
5. **Autonomous Bug Fixing** — When given a bug, just fix it. Point at logs, resolve them. Zero hand-holding.

## Key Commands

| Command           | Purpose                                                                 |
| ----------------- | ----------------------------------------------------------------------- |
| `/simplify`       | Review changed code for reuse, quality, and efficiency — then fix       |
| `/batch`          | Research and plan large-scale changes across isolated worktree agents   |
| `/copy`           | Interactive code block picker — copy full response or select blocks     |
| `/memory`         | View and manage auto-memory (persistent across sessions)                |
| `/fast`           | Toggle fast mode — same Opus 4.6 with faster output                    |
| `/loop`           | Run prompts on recurring intervals (e.g., `/loop 5m check deploy`)      |
| `/context`        | Visualize context window usage as colored grid                          |
| `/tasks`          | List and manage background tasks                                        |

## Hooks

This project includes session memory hooks that:
- Load context from previous sessions at startup
- Capture lessons from corrections automatically
- Run production health checks
- Preserve context before compaction

See `.claude/hooks/` for implementations.

## Permission Mode

This project defaults to `auto` permission mode — Claude makes autonomous decisions on common tasks. Override with `dontAsk`, `plan`, or `acceptEdits` as needed.
