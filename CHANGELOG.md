# Changelog

All notable changes to Claude Code AGI are documented here.

## [1.0.0] - 2026-03-17

### Added

#### Core Infrastructure
- Interactive setup script (`setup.sh`) with placeholder substitution
- User-level CLAUDE.md template for ~/.claude/CLAUDE.md
- Default settings.json with auto mode, preapproved tools, and MCP configuration
- Session memory hooks (session-start-context.sh, session-end-summary.sh)
- Self-improvement rules (capture corrections in lessons.md)
- Production monitoring rules (health checks, error recovery)
- Tool creation protocol (hooks, skills, scripts, rules)

#### Stack Presets (12 total)
- Firebase/Firestore
- Next.js/React
- Vitest (JavaScript testing)
- Google Cloud (GCP)
- Security & Compliance
- Python (FastAPI, Django)
- Rust (Actix, Tokio)
- Go (Gin, GORM)
- Docker & Kubernetes
- React Native
- Terraform & IaC
- Django & DRF

#### Documentation
- Agent teams guide (coordination, task distribution)
- Cost management guide (token optimization, model selection)
- Pipeline workflow guide (full delivery lifecycle)
- Context engineering guide (token optimization, compaction)
- Failure recovery guide (tests, conflicts, context limits)
- Permission modes guide (auto, dontAsk, plan, acceptEdits)
- Background tasks guide (parallel execution, task management)
- Hooks configuration guide (event types, examples)
- MCP configuration guide (servers, tool search)
- Troubleshooting guide (common issues and fixes)
- Setup validation guide (verifying installation)
- Model selection guide (when to use each model)

#### Workflow Recipes
- Audit codebase (identify issues, architecture, technical debt)
- Massive refactor (large-scale changes, parallel agents)
- Debug production (logs, errors, root cause analysis)

#### Custom Agents
- code-reviewer agent (architectural review, coverage gaps, performance)
- security-reviewer agent (injection attacks, secrets, access control)

#### Example Project
- Demo project in `examples/demo-project/` with:
  - Pre-configured .claude/CLAUDE.md
  - settings.json with auto mode enabled
  - Executable hooks for session management
  - Self-improvement rules
  - .claudeignore for context savings
  - .mcp.json with Context7 and Sequential Thinking
  - README.md with quick start guide

#### CI/CD
- GitHub Actions workflow (ci.yml) validating:
  - Setup script runs on Linux and macOS
  - All core files created with correct structure
  - Hooks are executable
  - JSON files are valid
  - Markdown files are readable
  - Shell script syntax is correct
  - Documentation structure is valid

#### Contributing
- CONTRIBUTING.md with guidelines for:
  - Adding new presets
  - Adding new hooks
  - Adding documentation
  - Writing workflow recipes
  - Testing changes
  - Code style and commit format
  - Pull request process
  - Code review standards

### Key Features

- **Autonomous Mode** — Default permission mode (auto) for hands-free operation
- **Session Memory** — Persistent across sessions via hooks and lessons.md
- **Self-Improvement** — Automatic capture of corrections and error patterns
- **Context Efficiency** — .claudeignore saves ~25% context on typical projects
- **Production Health** — Automatic health checks on session start
- **MCP Integration** — Context7 documentation search, Sequential Thinking
- **Modular Configuration** — Stack-specific presets, composable rules

### Initial Release

Transform Claude Code from an interactive assistant into an autonomous agent with persistent memory, self-improvement, and production awareness. Includes everything needed to set up AGI-capable Claude Code in any project.

## Roadmap

Planned for future releases:

- [ ] Shipwright integration (autonomous pipelines, fleet coordination)
- [ ] Dynamic model selection (route Haiku/Sonnet/Opus by task complexity)
- [ ] Cost forecasting (predict token usage, set daily budgets)
- [ ] Persistent task state (resume interrupted work across sessions)
- [ ] Team coordination (multi-agent task distribution, conflict resolution)
- [ ] Observability dashboard (session metrics, agent performance, cost tracking)
- [ ] Custom MCP servers (project-specific tools and integrations)
- [ ] Pre-built agents for common domains (DevOps, ML/Data, Web, Mobile)
