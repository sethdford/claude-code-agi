# Claude Code AGI

Transform Claude Code from an interactive assistant into an autonomous agent with persistent memory, self-improvement, and production awareness.

## What This Is

A starter kit that configures Claude Code for maximum autonomy. Drop it into any project and get:

- **Session Memory** — Claude remembers what happened in previous sessions
- **Self-Improvement** — Mistakes are captured and prevented from recurring
- **Production Awareness** — Every session starts with a live health check
- **Auto Mode** — Claude makes its own permission decisions
- **High Effort Reasoning** — Deeper analysis on every task
- **Context Optimization** — 25% less wasted tokens via .claudeignore
- **Modular Rules** — Domain knowledge auto-loaded every session
- **Deploy Tracking** — Every deploy outcome recorded for learning

## Quick Install

### Option A: Clone and run

```bash
git clone https://github.com/sethdford/claude-code-agi.git
cd claude-code-agi
bash setup.sh /path/to/your/project
```

### Option B: One-liner

```bash
bash <(curl -sL https://raw.githubusercontent.com/sethdford/claude-code-agi/main/setup.sh)
```

## What Gets Installed

| Component             | Location                                 | Purpose                                                |
| --------------------- | ---------------------------------------- | ------------------------------------------------------ |
| Operating Manual      | `.claude/CLAUDE.md`                      | Agent principles, model selection, context engineering |
| Settings              | `.claude/settings.json`                  | Auto mode, permissions, hooks, effort level            |
| Session Start Hook    | `.claude/hooks/session-start-context.sh` | Loads previous sessions + production health            |
| Session End Hook      | `.claude/hooks/session-end-summary.sh`   | Saves structured session summary                       |
| Deploy Feedback Hook  | `.claude/hooks/post-deploy-feedback.sh`  | Records deploy outcomes                                |
| Pre-Compact Hook      | `.claude/hooks/pre-compact-log.sh`       | Logs compaction events                                 |
| Self-Improvement Rule | `.claude/rules/self-improvement.md`      | Capture corrections, review at start                   |
| Tool Creation Rule    | `.claude/rules/tool-creation.md`         | When to build hooks vs scripts vs rules                |
| Monitoring Rule       | `.claude/rules/monitoring.md`            | Health checks, error investigation                     |
| Lessons File          | `.claude/lessons.md`                     | Persistent mistake/pattern knowledge                   |
| Deploy History        | `.claude/deploy-history.md`              | Deploy outcome tracking                                |
| Context Ignore        | `.claudeignore`                          | Exclude irrelevant files from context                  |
| MCP Config            | `.mcp.json`                              | Context7 + Sequential Thinking servers                 |

## Presets (Optional)

During setup, choose tech-stack-specific rules:

| Preset   | Rule File     | Covers                                              |
| -------- | ------------- | --------------------------------------------------- |
| Firebase | `firebase.md` | Collection naming, function groups, deploy patterns |
| Next.js  | `nextjs.md`   | API routes, middleware, proxy patterns              |
| Vitest   | `testing.md`  | Mock patterns, coverage thresholds, conventions     |
| GCloud   | `gcloud.md`   | Cloud Run, Cloud Functions, logging                 |
| Security | `security.md` | Rate limiting, auth, JSON safety, secrets           |

## Custom Agents (Optional)

| Agent               | Purpose                                            |
| ------------------- | -------------------------------------------------- |
| `code-reviewer`     | Reviews for bugs, logic errors, code quality       |
| `security-reviewer` | Reviews for OWASP top 10, auth gaps, data exposure |

## How It Works

```
Session Start
    |
    v
[Load previous 3 session summaries]
[Check open plans for unchecked items]
[Run production health check]
    |
    v
[Work autonomously in auto mode]
[High effort reasoning on every task]
[Rules auto-loaded for domain knowledge]
    |
    v
Session End
    |
    v
[Save structured summary with git state]
[Record deploy outcomes if deployed]
[Rotate session logs (keep 10)]
    |
    v
Next Session Starts With Full Context
```

## Customization

### Add your own rules

Create `.claude/rules/your-domain.md` — it auto-loads every session.

### Add your own hooks

Create scripts in `.claude/hooks/` and register them in `.claude/settings.json`.

### Modify permissions

Edit `.claude/settings.json` to add/remove allowed/denied bash patterns.

### Configure production URL

Edit the `{{PROJECT_URL}}` placeholder in hook scripts, or re-run `setup.sh`.

## Philosophy

This project implements 10 capabilities that push Claude Code toward autonomous operation:

1. **Session Memory** — previous context persists via hooks
2. **Self-Improvement** — corrections captured and prevented
3. **Proactive Action** — `/loop` scheduling for background monitoring
4. **Production Awareness** — live health checks at session start
5. **Tool Creation** — Claude builds tools for future Claude
6. **Cross-Project Learning** — lessons persist at user level
7. **Goal Persistence** — plans tracked across sessions
8. **Autonomous Error Recovery** — monitoring detects and responds
9. **Quality Feedback Loop** — deploy outcomes feed back into learning
10. **Collaborative Intelligence** — agent teams with shared context

Read the full philosophy: [docs/philosophy.md](docs/philosophy.md)

## Requirements

- Claude Code CLI installed
- macOS or Linux (bash required)
- Git (for session summaries)
- curl (for health checks)

## Contributing

PRs welcome. The most valuable contributions are:

- New preset rule files for popular frameworks
- New hook scripts for common workflows
- Improvements to the operating manual
- Bug fixes in the setup script

## License

MIT
