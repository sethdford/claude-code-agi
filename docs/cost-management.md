# Cost Management & Token Budgeting

This guide helps you understand AI model costs, make strategic model choices, and optimize token usage across your workflow. Token costs compound quickly at scale—smart budgeting prevents surprise bills and improves speed.

## Model Costs at a Glance

All prices are per 1 million tokens (as of March 2026):

| Model | Input | Output | Best For | Relative Cost |
|-------|-------|--------|----------|---------------|
| **Claude Opus 4.6** | $15 | $30 | Complex reasoning, orchestration | 1.0x (baseline) |
| **Claude Sonnet 4.6** | $3 | $15 | Balanced speed/quality, analysis | 0.25x |
| **Claude Haiku 4.5** | $0.25 | $1.25 | Exploration, subagents, simple tasks | 0.04x |

### Cost Examples

**Single 50K-token task (typical audit):**
- Opus: $2.25
- Sonnet: $0.56
- Haiku: $0.04

**Parallel 10-agent work (all Haiku for subagents):**
- 10 × 30K tokens per agent = 300K total
- Cost: $0.12 (vs. $9 for all Opus)

**Monthly budget example (small team):**
- Dev sessions: 5 developers × 10 sessions/week × 50K avg tokens = 25M tokens
- Cost: Opus only = $562/week; Mixed (Opus + Haiku) = $140/week
- **Monthly savings: ~1,700 USD**

## Model Routing Strategy

Choose the right model for the right task:

### Opus 4.6: Orchestration & Complex Decisions

Use Opus when:
- You need deep reasoning or multi-step planning
- The task affects multiple systems or has high blast radius
- You're reviewing and approving subagent work
- Context complexity is high (many files, nuanced architecture)

**Typical usage:** 2-5% of tokens

### Sonnet 4.6: Analysis & General Purpose

Use Sonnet when:
- You need good quality and reasonable speed
- Exploring a codebase with moderate complexity
- Writing or reviewing code with straightforward logic
- Analyzing data or logs for patterns

**Typical usage:** 20-40% of tokens

### Haiku 4.5: Exploration & Subagents

Use Haiku when:
- Exploring unfamiliar code (fast iteration loop)
- Running subagents for parallel tasks
- Simple refactoring or boilerplate generation
- Reading large files to extract specific info

**Typical usage:** 50-80% of tokens

**Example routing for a complex feature:**
```
Orchestrator (Opus) ←→ Plan Mode Explorer (Haiku)
                    ←→ Code Writer (Sonnet)
                    ←→ Test Generator (Haiku)
                    ←→ Reviewer (Sonnet)
```

## Default Model Configuration

Set in your shell or `.env`:

```bash
# Use Haiku for all subagents by default
export CLAUDE_CODE_SUBAGENT_MODEL=haiku

# Override on a per-agent basis
Agent("code-writer", { model: "sonnet" })  # for complex logic
Agent("test-bot", { model: "haiku" })      # for boilerplate
Agent("analyzer", { model: "opus" })       # for synthesis
```

**Cost impact:** Using Haiku subagents by default reduces spend by 60-70% vs. Opus-only.

## Token Budgeting

### Step 1: Estimate Session Scope

**Small session** (bug fix, simple feature):
- Intake: 2K tokens
- Plan mode exploration: 8K tokens
- Code writing: 5K tokens
- Testing: 3K tokens
- **Total: ~20K tokens**
- **Cost (mixed): $0.08**

**Medium session** (feature with 3-5 file changes):
- Intake: 5K tokens
- Plan mode: 15K tokens
- Parallel subagents (3 × 10K): 30K tokens
- Verification: 10K tokens
- **Total: ~60K tokens**
- **Cost (Opus + Haiku): $0.40**

**Large session** (refactor, architecture change, 10+ files):
- Intake: 10K tokens
- Plan mode: 30K tokens
- Parallel subagents (5 × 20K): 100K tokens
- Orchestration: 20K tokens
- Verification: 20K tokens
- **Total: ~180K tokens**
- **Cost (multi-model): $1.50**

**Massive parallel work** (10 independent features, 1 week):
- 10 features × 60K avg = 600K tokens
- At optimal routing (70% Haiku, 20% Sonnet, 10% Opus): ~$100 total
- vs. all Opus: ~$18 (much slower iteration)

### Step 2: Set a Budget

Use `shipwright cost budget set`:

```bash
# Set daily budget to $50
shipwright cost budget set 50

# Check remaining
shipwright cost remaining-budget
```

The daemon auto-scales workers to stay within budget:
- Queue grows → more workers
- Approaching daily limit → fewer workers
- No workers → queue pauses

### Step 3: Track Spending

Run at start and end of session:

```bash
# Show total spend and model breakdown
shipwright cost show

# View token usage by agent
/stats
```

**Typical velocity:**
- Small features: $0.50-2 per task
- Medium features: $2-10 per task
- Large features: $10-50 per task
- Emergency fixes: $0.10-0.50 per task

## Context Engineering (Token Optimization)

Reducing token bloat is the highest-ROI optimization. These techniques save 20-40% tokens per session:

### 1. Configure `.claudeignore`

Create `.claudeignore` in project root (same format as `.gitignore`):

```
node_modules/
dist/
build/
.next/
.venv/
venv/
*.min.js
*.lock
large-data-files/
third-party/
```

**Impact:** Saves ~25% tokens on typical Node/Python/Next.js projects by excluding auto-loaded context.

### 2. Use Plan Mode (Read-Only Exploration)

- Separate analysis from execution
- Use Haiku for exploration instead of Opus
- Saves 40-50% tokens by avoiding false starts

See `docs/pipeline-workflow.md` for details.

### 3. Delegate Data-Heavy Tasks to Subagents

Instead of reading a 50K-line log file yourself:

```typescript
Agent("log-analyzer", {
  task: "Summarize errors in this log file",
  context: { logFile: "path/to/large.log" },
  model: "haiku",
  maxTurns: 3,
})
```

**Impact:** Your context only gets the summary (2K tokens) instead of raw log (50K tokens).

### 4. Use Targeted Reads, Not Broad Scans

```typescript
// Bad: Read entire file, search mentally
Read("/path/to/huge-file.ts")  // 30K tokens

// Good: Grep first, then read specific lines
Grep({ pattern: "function handleError", glob: "*.ts" })
Read("/path/to/file.ts", { offset: 150, limit: 50 })  // 2K tokens
```

### 5. Prune Completed Work

When a task is done:
- Summarize progress in 2-3 lines
- Discard intermediate artifacts (full diffs, debug logs, temporary notes)
- Keep only the final commit/PR link

**Impact:** Frees 30-50K tokens for next task in same session.

### 6. Use Structured Output for Inter-Agent Comms

Instead of verbose status updates:

```json
// Bad: "I analyzed the file and found that the error occurs when..."
{
  "task": "analyze",
  "status": "done",
  "finding": "buffer_overflow",
  "location": "src/parse.ts:42",
  "fix_commit": "abc123"
}
```

**Impact:** Reduces teammate context overhead by 80%.

## Fast Mode: Speed vs. Cost Trade-Off

Claude Code offers **fast mode** — 2.5x faster output at 1.5x cost.

### When to Use Fast Mode

- Time-sensitive tasks (production incident)
- Rapid iteration needed (user waiting for review)
- Large refactors (avoids context churn from long thinking)

### When to Skip Fast Mode

- Async tasks (PR review, overnight testing)
- High-complexity tasks (use extra thinking time instead)
- Budget is constrained

### Toggle Fast Mode

```bash
/fast    # Toggle on/off
```

**Cost comparison for 100K-token task:**
- Normal mode: $0.50 (Opus input) + $1.50 (output) = $2.00
- Fast mode: $0.75 (input) + $2.25 (output) = $3.00
- Speedup: 2.5x
- Cost increase: 1.5x

## Effort Levels: Adaptive Reasoning Depth

For Opus/Sonnet 4.6 only. Controls how much Claude "thinks" about the problem:

```bash
export CLAUDE_CODE_EFFORT_LEVEL=low      # Fast, cheap (30% cost reduction)
export CLAUDE_CODE_EFFORT_LEVEL=medium   # Balanced (default)
export CLAUDE_CODE_EFFORT_LEVEL=high     # Deep reasoning (50% cost increase, better quality)
```

**Use cases:**
- `low` — trivial changes, known patterns, straightforward logic
- `medium` — typical features, moderate complexity
- `high` — novel algorithms, security-sensitive code, architectural decisions

## Autonomous Cost Governance

### Daemon Auto-Scaling

The pipeline daemon respects budget by controlling worker count:

```json
{
  "auto_scale": true,
  "max_workers": 8,
  "estimated_cost_per_job_usd": 5.0,
  "daily_budget_usd": 50.0
}
```

**Daemon logic:**
1. Queue grows → spawn workers (up to max)
2. Cost approaching limit → reduce workers
3. Budget exhausted → pause queue, wait for reset (midnight UTC)

### Cost Alerts

Set up notifications:

```bash
# Alert when daily spend exceeds $40
shipwright cost alert --threshold 40 --channel slack
```

## Token Leak Detection

Common sources of token waste:

| Leak | Symptom | Fix |
|------|---------|-----|
| Auto-loading huge files | Context grows fast, slow responses | Add to `.claudeignore` |
| Reading before grepping | 50K-token logs | Use Grep first, read results |
| Compaction overhead | Session slows after 70% context | Prune completed work proactively |
| Verbose logging in output | 10K-token error messages | Summarize, link to logs instead |
| Repeated explorations | Same question answered twice | Use `/memory` to store findings |
| Subagent sprawl | 20 parallel agents, slow coordination | Limit to 3-5 per orchestrator |

## Budget Approval Workflows

### For Small Teams (< 5 devs)

- **Daily budget:** $50-100
- **Per-developer limit:** Self-enforced via `shipwright cost show`
- **Review:** Weekly cost check (`/stats`)

### For Larger Teams (5-50 devs)

- **Daily budget:** $200-500
- **Per-developer limit:** $20-50/day via daemon auto-scale
- **Review:** Daily spend report (via Slack integration)
- **Governance:** Team lead approves high-cost tasks (>$10)

### For Enterprise

- **Daily budget:** $1,000+
- **Per-project limits:** Separate budgets for platform/product/infra
- **Review:** Real-time dashboard (`shipwright dashboard`)
- **Governance:** Finance approval for >$500 tasks; monthly audit trail

## Example: Full Cost Breakdown

**Task:** Implement new analytics dashboard (5 routes, 10 components, tests)

| Phase | Model | Tokens | Cost |
|-------|-------|--------|------|
| Intake | Haiku | 5K | $0.01 |
| Plan mode | Haiku | 15K | $0.02 |
| Routes (Agent) | Haiku | 40K | $0.01 |
| Components (Agent) | Sonnet | 60K | $0.15 |
| Tests (Agent) | Haiku | 30K | $0.01 |
| Orchestration | Opus | 25K | $0.38 |
| Review | Sonnet | 20K | $0.05 |
| **Total** | — | **195K** | **$0.63** |

**If all Opus:** ~$5.85 (9x more expensive)
**If all Haiku:** ~$0.10 (worse quality, slower iteration)

## Resources

- `/cost show` — view spending dashboard
- `/fast` — toggle fast mode
- `CLAUDE_CODE_EFFORT_LEVEL` — set reasoning depth
- `.claude/CLAUDE.md` — project-specific budget config
- `docs/pipeline-workflow.md` — plan mode saves 40-50% tokens
- `docs/context-engineering.md` — technical token optimization
