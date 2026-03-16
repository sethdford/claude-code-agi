# Template: ~/.claude/CLAUDE.md

Copy this file to `~/.claude/CLAUDE.md` and customize it for your workflow. This is your personal Claude Code configuration—used across all projects unless overridden by a project-specific `CLAUDE.md`.

---

# Your Project Name — Claude Code Workflow

This document defines your personal workflow, model preferences, subagent strategy, and agent operating principles. Customize sections below to match your team and project.

## Model Selection

| Model             | Cost Tier | Best For                                    | Speed |
| ----------------- | --------- | ------------------------------------------- | ----- |
| Claude Opus 4.6   | Premium   | Complex tasks, orchestration, decisions     | Slow  |
| Claude Sonnet 4.6 | Mid-tier  | Analysis, code generation, general purpose  | Fast  |
| Claude Haiku 4.5  | Budget    | Exploration, subagents, boilerplate         | Very Fast |

**Default behavior:**
- You (main session): Opus 4.6 (best reasoning)
- Subagents: Haiku 4.5 (cheap, fast iteration)
- Override: `Agent("name", { model: "sonnet" })` for complex tasks

**Usage by stage:**
```
Intake (exploration) → Haiku
Plan (analysis) → Haiku or Sonnet
Build (execution) → Sonnet or Opus
Test (verification) → Haiku
Review (synthesis) → Opus
```

## Subagent Strategy

Use subagents liberally to keep your context clean. Launch independent agents in parallel—never sequentially when they don't depend on each other.

| Agent Type | Model | Tool Access | Use For |
|-----------|-------|-------------|---------|
| Explorer | Haiku | Read-only | Fast codebase search, Q&A, discovery |
| Analyst | Sonnet | All tools | Architecture decisions, complex analysis |
| Builder | Sonnet | All tools | Code generation, multi-file changes |
| Tester | Haiku | All tools | Test generation, edge case exploration |
| Reviewer | Sonnet | Read-only | Code review, quality assessment |

**Example: Large refactor**
```
Orchestrator (Opus) ←→ Explorer (Haiku) — map files
                    ←→ Builder (Sonnet) — rewrite core
                    ←→ Builder (Sonnet) — update tests
                    ←→ Reviewer (Sonnet) — code review
```

**Best practices:**
- Keep main context for orchestration and final decisions
- Offload data-heavy work to subagents
- Use `maxTurns: 3-5` to keep exploration focused
- Pre-approve permissions for background agents

## Key Environment Variables

Set these in `~/.zshrc`, `~/.bashrc`, or equivalent:

```bash
# Model preferences
export CLAUDE_CODE_SUBAGENT_MODEL=haiku              # Cheap subagents by default
export CLAUDE_CODE_EFFORT_LEVEL=medium              # low/medium/high reasoning depth

# Context optimization
export CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE=70      # Trigger compaction at 70% (vs 95%)
export CLAUDE_CODE_GLOB_HIDDEN=1                    # Include hidden files in glob
export CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=5       # Parallel tool limit

# Recommended for large projects
export CLAUDE_CODE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1  # Keep CWD across bash calls

# Optional: disable features if needed
# export CLAUDE_CODE_DISABLE_FAST_MODE=1
# export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1
# export CLAUDE_CODE_DISABLE_1M_CONTEXT=1

# Secrets (never commit these)
export ANTHROPIC_API_KEY="sk-ant-oat01-..."         # Your OAuth token
export CLAUDE_MODEL="claude-opus-4-6"               # Override default model
```

## Context Engineering (Top 5 Token-Saving Techniques)

### 1. Configure `.claudeignore`

Create in project root (same format as `.gitignore`):

```
node_modules/
dist/
build/
.next/
.venv/
venv/
*.lock
*.min.js
large-data-files/
```

**Impact:** Saves ~25% tokens by excluding auto-loaded context.

### 2. Use Plan Mode

Press Shift+Tab twice before complex tasks:
- Separate analysis from execution
- Explore with Haiku (cheap) before building with Opus
- **Savings:** 40-50% tokens on analysis-heavy work

### 3. Delegate Data-Heavy Tasks to Subagents

Don't read 50K-line logs yourself. Spawn a subagent:

```typescript
Agent("log-analyzer", {
  task: "Summarize errors in this log",
  context: { logFile: "path/to/large.log" },
  model: "haiku",
  maxTurns: 3,
})
```

**Impact:** Your context gets a 2K summary instead of a 50K log.

### 4. Use Grep Before Read

```typescript
// Bad: Read entire file (30K tokens)
Read("/path/to/huge.ts")

// Good: Grep first, then targeted read (2K tokens)
Grep({ pattern: "function handleError", glob: "*.ts" })
Read("/path/to/file.ts", { offset: 150, limit: 50 })
```

### 5. Prune Completed Work

When a task finishes:
- Summarize in 2-3 lines
- Discard intermediate artifacts (full diffs, debug logs)
- Keep only the final commit/PR link

**Impact:** Frees 30-50K tokens for next task.

## Agent Operating Principles

Apply these principles in every session:

### 1. Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps, architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- A plan that survives contact with reality is worth 10x a plan that doesn't

### 2. Subagent Strategy

- Use subagents liberally to keep your context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution
- Launch independent subagents in parallel—never sequentially when they don't depend

### 3. Self-Improvement Loop

- After ANY correction from the user: update `.claude/lessons.md`
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on lessons until mistake rate drops
- Review lessons at session start for relevant projects
- Every production incident is a lesson: document what happened, why, and the fix

### 4. Verification Before Done

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Run tests, check logs, demonstrate correctness
- Typecheck, lint, and build BEFORE claiming success
- Ask yourself: "Would a staff engineer approve this?"

### 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes—don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it
- Point at logs, errors, failing tests—then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how
- If a deploy causes a production spike, delete the trigger first, then fix the code

## Core Principles

Follow these non-negotiable principles in every change:

1. **Simplicity First** — Make every change as simple as possible. Impact minimal code.
2. **No Laziness** — Find root causes. No temporary fixes. Senior developer standards.
3. **Production Safety** — Every query needs `.limit()`. Every scheduled function needs `timeoutSeconds`. Every trigger needs cascade analysis.
4. **Test Everything** — Unit tests for logic, integration tests for flows, smoke tests for deploys. If it's not tested, it's not done.
5. **Bound Everything** — Unbounded queries, unbounded loops, and unbounded retries are production incidents waiting to happen.
6. **Close the Loop** — Every output should feed an input. Reports delivered. Call outcomes trigger actions. Milestones generate artifacts.
7. **Fail Closed** — Rate limiters fail closed (block). Payment processors fail closed (notify). Content gates fail closed (require review).
8. **Idempotency** — Every operation should be safe to retry. Use claim tokens, dedup guards, and status checks.
9. **Observe Everything** — If a function runs in production, track its execution. If a metric changes, detect the anomaly. If an SLO breaches, alert the team.

## Cost Management

### Model Costs (per 1M tokens)

| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| Opus | $15 | $30 | Use for orchestration |
| Sonnet | $3 | $15 | Use for code & analysis |
| Haiku | $0.25 | $1.25 | Use for subagents |

### Budget Targets

- **Small task** (1-2 files): $0.05-0.20
- **Medium task** (3-5 files): $0.50-2.00
- **Large task** (10+ files): $5-20
- **Massive parallel work** (10 features): $50-100

### Cost Monitoring

```bash
/cost show                           # View spending dashboard
/stats                               # Session statistics
shipwright cost budget set 50        # Set daily limit ($50)
shipwright cost remaining-budget     # Check remaining
```

**Fast mode trade-off:** 2.5x faster at 1.5x cost. Use for time-sensitive tasks only.

## Failure Recovery

### When Tests Fail

1. Read the full test output—don't guess
2. Identify the failing test and assertion
3. Fix the code (not the test, unless the test is wrong)
4. Re-run the specific failing test first
5. Document what caused the failure in your task update

### When Context Gets Tight

1. The PreCompact hook automatically saves context before compaction
2. Summarize your progress and next steps
3. Break remaining work into smaller, self-contained tasks
4. Use `/context` to visualize current usage
5. Focus on completing the current task

### When a Pipeline Fails

1. Check pipeline state: `cat .claude/pipeline-state.md`
2. Review logs for the failed stage
3. Fix the issue, then resume: `shipwright pipeline resume`
4. Use `shipwright memory show` — previous failures may have relevant fixes

### Recovery Commands

```bash
shipwright pipeline resume          # Resume from last completed stage
shipwright memory show              # View captured failure patterns
shipwright doctor                   # Diagnose setup issues
shipwright cleanup --force          # Kill orphaned sessions
git stash                            # Temporarily save changes
```

## Project Standards

Before starting work on a project, check for these files:

- `.claude/CLAUDE.md` — Project-specific overrides (takes priority over this template)
- `docs/standards/` — Canonical standards (source of truth for any domain)
- `.claude/rules/` — Domain-specific conventions
- `.claude/lessons.md` — Captured failure patterns and fixes
- `.claude/deploy-history.md` — Recent deploy outcomes

Always prefer project standards over this template. If a project has `.claude/CLAUDE.md`, use that.

## Quick Commands

```bash
/fast                    # Toggle fast mode (2.5x faster, 1.5x cost)
/memory                  # View and manage auto-memory
/context                 # Visualize context usage as colored grid
/tasks                   # List background tasks
/copy                    # Interactive code block picker
/simplify                # Review changed code for reuse & efficiency
/diff                    # Interactive diff viewer
/loop 5m check deploy    # Run prompts on recurring intervals
/stats                   # Daily usage statistics
```

## Customization

Edit this template to match your team:

- [ ] Update model preferences (Opus vs. Sonnet default)
- [ ] Update subagent strategy (more/fewer agents)
- [ ] Add your project's key environment variables
- [ ] Add your team's core principles
- [ ] Update cost targets for your budget
- [ ] Add your team's failure recovery procedures
- [ ] Document any custom hooks or scripts

**Save to:** `~/.claude/CLAUDE.md`

**Used by:** All Claude Code sessions (unless overridden by project-specific `.claude/CLAUDE.md`)

---

## Additional Resources

- `docs/pipeline-workflow.md` — Intake → plan → build → test → review → PR workflow
- `docs/cost-management.md` — Token budgeting, model routing, context engineering
- `docs/quality-ceremonies.md` — Pre-commit, PR gate, weekly drift audit, release gate
- `docs/context-engineering.md` — Advanced token optimization techniques
- `docs/philosophy.md` — Why Claude Code works this way
