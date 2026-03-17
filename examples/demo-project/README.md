# Demo Project

This is a pre-configured example showing claude-code-agi in action. It includes all the infrastructure needed for autonomous Claude Code sessions with session memory, self-improvement rules, and production health checks.

## Quick Start

```bash
# Navigate to the demo project
cd examples/demo-project

# Start Claude Code
claude

# Claude starts in auto mode with full AGI capabilities enabled
```

## What's Configured

- **Auto Mode** — Autonomous permission decisions on common tasks (file edits, reads, runs)
- **Session Memory** — Previous sessions loaded at startup, recent plans displayed, production health checked
- **Self-Improvement Rules** — Corrections automatically captured in `.claude/lessons.md`
- **.claudeignore** — 25% context savings by excluding build artifacts, dependencies, and lock files
- **MCP Servers** — Context7 for documentation search, Sequential Thinking for complex reasoning
- **Hooks** — Session start loads history; session end saves summaries for continuity

## Project Structure

```
.claude/
├── CLAUDE.md                    # Model selection, subagent strategy, core principles
├── settings.json                # Auto mode, preapproved tools, environment config
├── hooks/
│   ├── session-start-context.sh # Load previous sessions and health checks
│   └── session-end-summary.sh   # Save session summary for next time
├── rules/
│   └── self-improvement.md      # Correction capture and error recovery
└── lessons.md                   # (Created as you work) Patterns to avoid repeating

.mcp.json                        # MCP server configuration (Context7, Thinking)
.claudeignore                    # Exclude build artifacts, dependencies, secrets
```

## Key Files to Know

- `.claude/CLAUDE.md` — AGI configuration. Read this to understand how Claude is set up.
- `.claude/settings.json` — Permission mode, preapproved tools, environment variables.
- `.claude/lessons.md` — Self-improvement log. Grows as you work; reviewed at session start.
- `.claude/session-logs/` — Timestamped session summaries. Loaded at startup.

## How It Works

### Session Start
When you run `claude`, the `session-start-context.sh` hook:
1. Loads the last 3 session summaries from `.claude/session-logs/`
2. Lists any unchecked items in plans
3. Does a quick production health check (5s timeout, non-blocking)

### During the Session
- You can use `/memory` to view and manage auto-memory
- Corrections are captured automatically in `.claude/lessons.md`
- Background tasks run with `Ctrl+B`
- Plan mode separates analysis from execution (Shift+Tab twice)

### Session End
The `session-end-summary.sh` hook:
1. Writes a timestamped summary to `.claude/session-logs/`
2. Keeps only the last 10 sessions
3. Preserves recent commits and file changes for continuity

## Try It Out

1. **Explore the codebase** — Use `/batch` to analyze structure across multiple agents
2. **Make a change** — Edit a file, run tests, see auto-captured corrections in lessons
3. **Use background tasks** — Run `pnpm test` in the background while you work
4. **Review memory** — Use `/memory` to see what lessons were captured
5. **Check production** — The session-start hook checks your project health

## Customization

To adapt this for your project:

1. Update `.claude/CLAUDE.md` with your project's core principles
2. Update `.claude/hooks/session-start-context.sh` — change `PROJECT_URL` to your site
3. Create `.claude/rules/` files for domain-specific conventions (testing, deployment, architecture)
4. Add lessons to `.claude/lessons.md` as you work and discover patterns

## Documentation

See the parent repo for detailed docs:
- `docs/` — Full guides on agent teams, cost management, pipeline workflow
- `docs/workflows/` — Step-by-step recipes for common tasks
- `presets/` — Stack-specific configurations (Firebase, Next.js, Terraform, etc.)

## More Info

- https://github.com/sethdford/claude-code-agi — Full AGI framework
- `.claude/CLAUDE.md` — Core principles and model selection
- `.mcp.json` — MCP server configuration
